use std::path::{Path, PathBuf};
use anyhow::{Context, Result};
use rusqlite::{params, Connection};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InstalledPackage {
    pub name: String,
    pub version: String,
    pub release: u32,
    pub description: String,
    pub installed_size: u64,
    pub install_time: i64,
}

pub struct PackageDatabase {
    conn: Connection,
}

impl PackageDatabase {
    pub fn open<P: AsRef<Path>>(db_path: P) -> Result<Self> {
        if let Some(parent) = db_path.as_ref().parent() {
            std::fs::create_dir_all(parent).ok();
        }

        let conn = Connection::open(db_path.as_ref())
            .context("Failed to open local package database SQLite file")?;

        // Initialize schema
        conn.execute_batch(
            "
            PRAGMA journal_mode = WAL;
            PRAGMA synchronous = NORMAL;

            CREATE TABLE IF NOT EXISTS packages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE,
                version TEXT NOT NULL,
                release INTEGER NOT NULL,
                description TEXT,
                installed_size INTEGER NOT NULL,
                install_time INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS package_files (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                package_name TEXT NOT NULL,
                file_path TEXT NOT NULL,
                sha256 TEXT NOT NULL,
                FOREIGN KEY(package_name) REFERENCES packages(name) ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_files_path ON package_files(file_path);
            ",
        )?;

        Ok(Self { conn })
    }

    pub fn register_package(&mut self, pkg: &InstalledPackage, files: &[(PathBuf, String)]) -> Result<()> {
        let tx = self.conn.transaction()?;

        tx.execute(
            "INSERT OR REPLACE INTO packages (name, version, release, description, installed_size, install_time)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
            params![
                pkg.name,
                pkg.version,
                pkg.release,
                pkg.description,
                pkg.installed_size,
                pkg.install_time
            ],
        )?;

        tx.execute("DELETE FROM package_files WHERE package_name = ?1", params![pkg.name])?;

        {
            let mut stmt = tx.prepare(
                "INSERT INTO package_files (package_name, file_path, sha256) VALUES (?1, ?2, ?3)"
            )?;
            for (path, hash) in files {
                stmt.execute(params![pkg.name, path.to_string_lossy(), hash])?;
            }
        }

        tx.commit()?;
        Ok(())
    }

    pub fn get_package(&self, name: &str) -> Result<Option<InstalledPackage>> {
        let mut stmt = self.conn.prepare(
            "SELECT name, version, release, description, installed_size, install_time FROM packages WHERE name = ?1"
        )?;

        let mut rows = stmt.query(params![name])?;
        if let Some(row) = rows.next()? {
            Ok(Some(InstalledPackage {
                name: row.get(0)?,
                version: row.get(1)?,
                release: row.get(2)?,
                description: row.get(3)?,
                installed_size: row.get(4)?,
                install_time: row.get(5)?,
            }))
        } else {
            Ok(None)
        }
    }
}
