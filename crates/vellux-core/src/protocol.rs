use serde::{Deserialize, Serialize};

/// IPC Message protocol between Vellux Compositor and Vellux Shell
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", content = "payload")]
pub enum ShellMessage {
    ToggleControlCenter,
    ToggleSpotlight,
    AppLaunched { id: String },
    BrightnessChanged { percentage: u8 },
    VolumeChanged { percentage: u8 },
    ActiveWindowChanged { app_name: String, title: String },
}
