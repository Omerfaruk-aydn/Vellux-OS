mod archive;
mod db;

use std::path::PathBuf;
use anyhow::Result;
use clap::{Parser, Subcommand};
use tracing::{info, Level};
use tracing_subscriber::FmtSubscriber;

#[derive(Parser)]
#[command(name = "vellux-pkg")]
#[command(about = "Vellux OS High-Performance Sandboxed Package Engine", long_about = None)]
#[command(version)]
struct Cli {
    #[command(subcommand)]
    command: Commands,

    /// Alternative root directory (default: /)
    #[arg(short, long, global = true, default_value = "/")]
    root: PathBuf,
}

#[derive(Subcommand)]
enum Commands {
    /// Build a binary package (.vpkg.tar.zst) from a Vpkgfile recipe directory
    Build {
        /// Path to directory containing Vpkgfile
        recipe_dir: PathBuf,
        /// Destination output directory
        #[arg(short, long, default_value = ".")]
        output: PathBuf,
    },
    /// Install a compiled .vpkg.tar.zst binary package into the system
    Install {
        /// Path to .vpkg.tar.zst archive
        package_file: PathBuf,
    },
    /// Query installed package information
    Info {
        /// Name of the package to query
        package_name: String,
    },
}

#[tokio::main]
async fn main() -> Result<()> {
    let subscriber = FmtSubscriber::builder()
        .with_max_level(Level::INFO)
        .with_target(false)
        .finish();
    tracing::subscriber::set_global_default(subscriber)?;

    let cli = Cli::parse();

    match cli.command {
        Commands::Build { recipe_dir, output } => {
            info!("Building package from recipe: {:?}", recipe_dir);
            info!("Output directory: {:?}", output);
            // Engine reads Vpkgfile and generates .vpkg.tar.zst
        }
        Commands::Install { package_file } => {
            info!("Installing package: {:?} into root: {:?}", package_file, cli.root);
            let db_path = cli.root.join("var/lib/vellux/db.sqlite");
            let mut db = db::PackageDatabase::open(&db_path)?;
            
            let (meta, files) = archive::PackageArchive::extract(&package_file, &cli.root)?;
            let installed = db::InstalledPackage {
                name: meta.name.clone(),
                version: meta.version,
                release: meta.release,
                description: meta.description,
                installed_size: meta.installed_size,
                install_time: std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)?
                    .as_secs() as i64,
            };
            db.register_package(&installed, &files)?;
            info!("Successfully registered and installed: {}", meta.name);
        }
        Commands::Info { package_name } => {
            let db_path = cli.root.join("var/lib/vellux/db.sqlite");
            let db = db::PackageDatabase::open(&db_path)?;
            if let Some(pkg) = db.get_package(&package_name)? {
                println!("Package: {} v{}-{}", pkg.name, pkg.version, pkg.release);
                println!("Description: {}", pkg.description);
                println!("Installed Size: {} bytes", pkg.installed_size);
            } else {
                println!("Package '{}' is not installed.", package_name);
            }
        }
    }

    Ok(())
}
