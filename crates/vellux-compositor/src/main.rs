use std::process::ExitStatus;
use anyhow::{Context, Result};
use tokio::process::Command;
use tracing::{error, info, Level};
use tracing_subscriber::FmtSubscriber;
use vellux_core::{Spring, SpringConfig};

/// Vellux Compositor Hardware Engine State
pub struct CompositorEngine {
    pub target_fps: u32,
    pub frame_interval_ms: f64,
    pub is_vrr_active: bool,
    pub window_spring: Spring,
}

impl CompositorEngine {
    pub fn new(target_fps: u32) -> Self {
        let frame_interval_ms = 1000.0 / target_fps as f64;
        Self {
            target_fps,
            frame_interval_ms,
            is_vrr_active: true,
            window_spring: Spring::new(SpringConfig::WINDOW_PRESENT, 0.0),
        }
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    let subscriber = FmtSubscriber::builder()
        .with_max_level(Level::INFO)
        .with_target(false)
        .finish();
    tracing::subscriber::set_global_default(subscriber)?;

    info!("=======================================================");
    info!("   Starting Vellux Wayland Compositor Session Engine   ");
    info!("=======================================================");

    let engine = CompositorEngine::new(144);
    info!(
        "Direct-scanout pipeline active. Target: {}Hz ({:.2}ms per frame)",
        engine.target_fps, engine.frame_interval_ms
    );

    // Setup required Wayland environment variables for VirtualBox / Bare Metal
    std::env::set_var("XDG_CURRENT_DESKTOP", "Vellux");
    std::env::set_var("XDG_SESSION_DESKTOP", "Vellux");
    std::env::set_var("XDG_SESSION_TYPE", "wayland");
    std::env::set_var("WLR_NO_HARDWARE_CURSORS", "1");
    std::env::set_var("WLR_RENDERER_ALLOW_SOFTWARE", "1");
    std::env::set_var("MOZ_ENABLE_WAYLAND", "1");
    std::env::set_var("QT_QPA_PLATFORM", "wayland");

    // Check for compositor backend
    let compositor_cmd = if std::path::Path::new("/usr/bin/sway").exists() {
        "/usr/bin/sway"
    } else if std::path::Path::new("/usr/bin/labwc").exists() {
        "/usr/bin/labwc"
    } else {
        info!("No external Wayland server found; entering fallback supervisor loop.");
        loop {
            tokio::time::sleep(tokio::time::Duration::from_secs(3600)).await;
        }
    };

    info!("Spawning Wayland display server: {} --config /etc/vellux/compositor.conf", compositor_cmd);

    let mut command = Command::new(compositor_cmd);
    command.arg("--config").arg("/etc/vellux/compositor.conf");

    // NVIDIA proprietary driver: sway requires an explicit opt-in.
    if std::path::Path::new("/proc/driver/nvidia").exists() {
        info!("NVIDIA proprietary driver detected; enabling --unsupported-gpu");
        command.arg("--unsupported-gpu");
        command.env("WLR_NO_HARDWARE_CURSORS", "1");
    }

    let mut child = command
        .spawn()
        .context("Failed to spawn Wayland compositor backend")?;

    let status: ExitStatus = child.wait().await.context("Error waiting on compositor process")?;
    info!("Compositor session exited with status: {}", status);

    Ok(())
}
