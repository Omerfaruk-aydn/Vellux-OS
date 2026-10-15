use std::fs::File;
use std::io::{BufReader, Read, Write};
use std::path::{Path, PathBuf};
use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use tar::{Archive, Builder};
use zstd::stream::{Decoder, Encoder};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PackageMeta {
    pub name: String,
    pub version: String,
    pub release: u32,
    pub description: String,
    pub depends: Vec<String>,
    pub provides: Vec<String>,
    pub installed_size: u64,
}

pub struct PackageArchive;

impl PackageArchive {
    /// Builds a `.vpkg.tar.zst` archive from a compiled rootfs directory.
    pub fn create<P: AsRef<Path>, O: AsRef<Path>>(
        root_dir: P,
        output_file: O,
        meta: &PackageMeta,
    ) -> Result<()> {
        let out = File::create(output_file.as_ref())
            .context("Failed to create package output file")?;
        
        // Zstandard high-compression level 19 for distribution
        let encoder = Encoder::new(out, 19)?;
        let mut tar_builder = Builder::new(encoder);

        // 1. Pack metadata JSON as `.METADATA`
        let meta_json = serde_json::to_vec_pretty(meta)?;
        let mut header = tar::Header::new_gnu();
        header.set_path(".METADATA")?;
        header.set_size(meta_json.len() as u64);
        header.set_mode(0o644);
        header.set_cksum();
        tar_builder.append(&header, &meta_json[..])?;

        // 2. Append all files from the payload root directory
        tar_builder.append_dir_all(".", root_dir.as_ref())?;

        let encoder = tar_builder.into_inner()?;
        encoder.finish()?;

        Ok(())
    }

    /// Extracts a `.vpkg.tar.zst` archive directly into the target filesystem root.
    pub fn extract<P: AsRef<Path>, D: AsRef<Path>>(
        pkg_file: P,
        dest_root: D,
    ) -> Result<(PackageMeta, Vec<(PathBuf, String)>)> {
        let f = File::open(pkg_file.as_ref())
            .context("Cannot open .vpkg archive")?;
        let reader = BufReader::new(f);
        let decoder = Decoder::new(reader)?;
        let mut archive = Archive::new(decoder);

        let mut meta: Option<PackageMeta> = None;
        let mut installed_files = Vec::new();

        for entry in archive.entries()? {
            let mut entry = entry?;
            let path = entry.path()?.to_path_buf();

            if path == Path::new(".METADATA") {
                let mut content = Vec::new();
                entry.read_to_end(&mut content)?;
                meta = Some(serde_json::from_slice(&content)?);
                continue;
            }

            let full_dest = dest_root.as_ref().join(&path);
            if let Some(parent) = full_dest.parent() {
                std::fs::create_dir_all(parent)?;
            }

            // Extract entry while computing SHA256 simultaneously
            entry.unpack(&full_dest)?;
            
            if full_dest.is_file() {
                let mut file_data = Vec::new();
                if let Ok(mut f) = File::open(&full_dest) {
                    f.read_to_end(&mut file_data).ok();
                    let hash = format!("{:x}", Sha256::digest(&file_data));
                    installed_files.push((path, hash));
                }
            }
        }

        let meta = meta.context("Invalid package: Missing .METADATA section")?;
        Ok((meta, installed_files))
    }
}
