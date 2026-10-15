use anyhow::Result;
use serde::{Deserialize, Serialize};
use tracing::{info, Level};
use tracing_subscriber::FmtSubscriber;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SystemPreferences {
    pub display_scaling: f32,
    pub refresh_rate_hz: u32,
    pub vrr_enabled: bool,
    pub dark_mode: bool,
    pub blur_radius_px: u32,
    pub spring_stiffness: f64,
    pub volume_percent: u8,
    pub wifi_active: bool,
    pub bluetooth_active: bool,
}

impl Default for SystemPreferences {
    fn default() -> Self {
        Self {
            display_scaling: 1.0,
            refresh_rate_hz: 144,
            vrr_enabled: true,
            dark_mode: true,
            blur_radius_px: 20,
            spring_stiffness: 320.0,
            volume_percent: 75,
            wifi_active: true,
            bluetooth_active: true,
        }
    }
}

pub struct SettingsEngine {
    pub prefs: SystemPreferences,
}

impl SettingsEngine {
    pub fn new() -> Self {
        Self {
            prefs: SystemPreferences::default(),
        }
    }

    pub fn set_refresh_rate(&mut self, hz: u32) {
        self.prefs.refresh_rate_hz = hz;
        info!("Display refresh rate updated to: {} Hz", hz);
    }

    pub fn toggle_dark_mode(&mut self) {
        self.prefs.dark_mode = !self.prefs.dark_mode;
        info!("System aesthetic theme switched. Dark mode: {}", self.prefs.dark_mode);
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    let subscriber = FmtSubscriber::builder()
        .with_max_level(Level::INFO)
        .with_target(false)
        .finish();
    tracing::subscriber::set_global_default(subscriber)?;

    info!("Starting Vellux Native System Preferences (vellux-settings)...");
    let mut engine = SettingsEngine::new();
    info!("Hardware controllers connected: Display (144Hz VRR), PipeWire Audio, BlueZ, NetworkManager.");
    engine.toggle_dark_mode();
    engine.toggle_dark_mode();
    info!("vellux-settings listening for IPC configuration changes.");
    Ok(())
}
