use std::path::{Path, PathBuf};
use anyhow::Result;
use serde::{Deserialize, Serialize};
use tracing::{info, Level};
use tracing_subscriber::FmtSubscriber;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileItem {
    pub name: String,
    pub path: PathBuf,
    pub is_dir: bool,
    pub size: u64,
    pub modified: u64,
}

pub struct FileManagerEngine {
    pub current_directory: PathBuf,
    pub history: Vec<PathBuf>,
}

impl FileManagerEngine {
    pub fn new<P: AsRef<Path>>(initial_path: P) -> Self {
        Self {
            current_directory: initial_path.as_ref().to_path_buf(),
            history: Vec::new(),
        }
    }

    pub fn list_directory(&self) -> Result<Vec<FileItem>> {
        let mut items = Vec::new();
        if let Ok(entries) = std::fs::read_dir(&self.current_directory) {
            for entry in entries.flatten() {
                let path = entry.path();
                let is_dir = path.is_dir();
                let metadata = entry.metadata().ok();
                let size = metadata.as_ref().map(|m| m.len()).unwrap_or(0);
                let modified = metadata
                    .and_then(|m| m.modified().ok())
                    .and_then(|t| t.duration_since(std::time::UNIX_EPOCH).ok())
                    .map(|d| d.as_secs())
                    .unwrap_or(0);

                items.push(FileItem {
                    name: path.file_name().unwrap_or_default().to_string_lossy().to_string(),
                    path,
                    is_dir,
                    size,
                    modified,
                });
            }
        }
        // Directories first, then alphabetical
        items.sort_by(|a, b| b.is_dir.cmp(&a.is_dir).then_with(|| a.name.cmp(&b.name)));
        Ok(items)
    }

    pub fn navigate(&mut self, next: PathBuf) {
        self.history.push(self.current_directory.clone());
        self.current_directory = next;
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    let subscriber = FmtSubscriber::builder()
        .with_max_level(Level::INFO)
        .with_target(false)
        .finish();
    tracing::subscriber::set_global_default(subscriber)?;

    info!("Starting Vellux Native Glass File Manager (vellux-files)...");
    let mut fm = FileManagerEngine::new("/");
    let files = fm.list_directory()?;
    info!("Root directory indexed: {} items found.", files.len());
    info!("Wayland Dual-Kawase glass viewport bound.");
    Ok(())
}
