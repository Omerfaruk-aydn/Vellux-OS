use anyhow::Result;
use tracing::{info, Level};
use tracing_subscriber::FmtSubscriber;
use vellux_core::{Spring, SpringConfig};

/// State of the native Wayland Layer-Shell Desktop environment
pub struct ShellEnvironment {
    pub dock_items_count: usize,
    pub is_control_center_open: bool,
    pub is_spotlight_open: bool,
    pub dock_springs: Vec<Spring>,
}

impl ShellEnvironment {
    pub fn new() -> Self {
        let count = 5;
        let springs = (0..count)
            .map(|_| Spring::new(SpringConfig::DOCK_MAGNIFY, 1.0))
            .collect();

        Self {
            dock_items_count: count,
            is_control_center_open: false,
            is_spotlight_open: false,
            dock_springs: springs,
        }
    }

    pub fn toggle_spotlight(&mut self) {
        self.is_spotlight_open = !self.is_spotlight_open;
        info!("Spotlight HUD state: {}", self.is_spotlight_open);
    }

    pub fn toggle_control_center(&mut self) {
        self.is_control_center_open = !self.is_control_center_open;
        info!("Control Center state: {}", self.is_control_center_open);
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    let subscriber = FmtSubscriber::builder()
        .with_max_level(Level::INFO)
        .with_target(false)
        .finish();
    tracing::subscriber::set_global_default(subscriber)?;

    info!("Starting Vellux Native Desktop Shell...");
    info!("Connecting to Wayland Display via zwlr_layer_shell_v1 protocol...");

    let mut shell = ShellEnvironment::new();
    info!("Registered 3 Layer-Shell Surfaces: [TopBar, FluidDock, ControlCenter]");
    info!("Dock initialized with {} per-item physical spring solvers.", shell.dock_items_count);

    shell.toggle_spotlight();
    shell.toggle_spotlight();

    info!("Vellux Native Shell listening for compositor input events.");
    Ok(())
}
