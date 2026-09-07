//! Scene loading and validation for `msicenter scene` (Phase 8).
//!
//! Scenes are user-owned files (`~/.config/msi-linux-center/scenes.json`);
//! the daemon never reads them. Applying a scene issues the same gated
//! per-setting D-Bus calls the individual commands make, so every write
//! still passes the daemon's opt-in/firmware/Polkit gates. RGB is never
//! persisted by a scene (no flash-save). See `docs/phase8-scenes-design.md`.

use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Default, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct RgbScene {
    /// Zone bitmask, bits 0-3.
    pub zones: u8,
    /// RRGGBB hex color.
    pub color: String,
    /// Optional effect: `steady` (default), `breath`, `cycle`, `wave`.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub mode: Option<String>,
    /// Effect period in seconds (default 3). Used only for breath/cycle/wave.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub speed: Option<u16>,
    /// Wave direction: 1 left-to-right (default), 0 right-to-left.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub wave_direction: Option<u8>,
}

#[derive(Debug, Clone, Default, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]
pub struct SceneSettings {
    pub fan_mode: Option<String>,
    pub cooler_boost: Option<bool>,
    pub super_battery: Option<bool>,
    pub webcam: Option<bool>,
    pub webcam_block: Option<bool>,
    pub fn_key: Option<String>,
    pub battery_start: Option<u8>,
    pub battery_end: Option<u8>,
    pub rgb: Option<RgbScene>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Scene {
    pub name: String,
    #[serde(default)]
    pub settings: SceneSettings,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct SceneFile {
    pub scenes: Vec<Scene>,
}

/// Default scene file location: `$XDG_CONFIG_HOME/msi-linux-center/scenes.json`
/// or `~/.config/msi-linux-center/scenes.json`.
pub fn scenes_path() -> PathBuf {
    let base = std::env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| {
            PathBuf::from(std::env::var_os("HOME").unwrap_or_default()).join(".config")
        });
    base.join("msi-linux-center").join("scenes.json")
}

/// Loads and parses the scene file.
pub fn load(path: &Path) -> Result<SceneFile, String> {
    let text = std::fs::read_to_string(path)
        .map_err(|error| format!("cannot read {}: {error}", path.display()))?;
    serde_json::from_str(&text)
        .map_err(|error| format!("invalid scene file {}: {error}", path.display()))
}

/// Per-scene validation. Returns human-readable problems; a scene with
/// problems is reported and skipped, never guessed.
pub fn validate_scene(scene: &Scene) -> Vec<String> {
    let mut problems = Vec::new();
    if scene.name.trim().is_empty() {
        problems.push("scene name must not be empty".into());
    }
    let settings = &scene.settings;
    if settings.battery_start.is_some() != settings.battery_end.is_some() {
        problems.push("battery_start and battery_end must be set together".into());
    }
    if let Some(position) = &settings.fn_key {
        if position != "left" && position != "right" {
            problems.push(format!("invalid fn_key {position:?} (left|right)"));
        }
    }
    if let (Some(start), Some(end)) = (settings.battery_start, settings.battery_end) {
        if start >= end || end > 100 {
            problems.push(format!(
                "invalid battery pair {start}/{end}: need 0 <= start < end <= 100"
            ));
        }
    }
    if let Some(rgb) = &settings.rgb {
        if rgb.zones & !0x0f != 0 {
            problems.push(format!("invalid rgb zone mask {:#04x}", rgb.zones));
        }
        let hex = rgb.color.as_bytes();
        if hex.len() != 6 || !hex.iter().all(u8::is_ascii_hexdigit) {
            problems.push(format!(
                "invalid rgb color {:?} (expected RRGGBB)",
                rgb.color
            ));
        }
        if let Err(error) = rgb_mode_id(rgb.mode.as_deref()) {
            problems.push(error);
        }
        if let Some(speed) = rgb.speed {
            if speed == 0 || speed > 600 {
                problems.push(format!("invalid rgb speed {speed} (need 1..=600 s)"));
            }
        }
        if let Some(direction) = rgb.wave_direction {
            if direction > 1 {
                problems.push("invalid rgb wave_direction (0 or 1)".into());
            }
        }
    }
    problems
}

/// Preset mode id: 1 steady, 2 breath, 3 cycle, 4 wave. Missing mode is steady.
pub fn rgb_mode_id(mode: Option<&str>) -> Result<u8, String> {
    match mode.unwrap_or("steady") {
        "steady" => Ok(1),
        "breath" | "breathing" => Ok(2),
        "cycle" => Ok(3),
        "wave" => Ok(4),
        other => Err(format!(
            "invalid rgb mode {other:?} (steady|breath|cycle|wave)"
        )),
    }
}

/// Parses an RRGGBB hex color.
pub fn color_to_rgb(hex: &str) -> Option<(u8, u8, u8)> {
    let bytes = hex.as_bytes();
    if bytes.len() != 6 || !bytes.iter().all(u8::is_ascii_hexdigit) {
        return None;
    }
    let channel = |range: std::ops::Range<usize>| u8::from_str_radix(&hex[range], 16).ok();
    Some((channel(0..2)?, channel(2..4)?, channel(4..6)?))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn loads_and_validates_a_scene_file() {
        let dir = std::env::temp_dir().join(format!("msicenter-scene-{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let path = dir.join("scenes.json");
        std::fs::write(
            &path,
            r#"{
                "scenes": [
                    {
                        "name": "Gaming",
                        "settings": {
                            "fan_mode": "auto",
                            "cooler_boost": false,
                            "battery_start": 80,
                            "battery_end": 100,
                            "rgb": { "zones": 15, "color": "ff0000" }
                        }
                    },
                    {
                        "name": "Broken",
                        "settings": { "battery_start": 90, "battery_end": 80 }
                    }
                ]
            }"#,
        )
        .unwrap();

        let file = load(&path).unwrap();
        assert_eq!(file.scenes.len(), 2);
        assert!(validate_scene(&file.scenes[0]).is_empty());
        let problems = validate_scene(&file.scenes[1]);
        assert_eq!(problems.len(), 1);
        assert!(problems[0].contains("invalid battery pair"));

        std::fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn parses_colors() {
        assert_eq!(color_to_rgb("ff0000"), Some((255, 0, 0)));
        assert_eq!(color_to_rgb("00ff80"), Some((0, 255, 128)));
        assert_eq!(color_to_rgb("f00"), None);
        assert_eq!(color_to_rgb("gggggg"), None);
    }

    #[test]
    fn validates_rgb_effect_mode() {
        let ok = Scene {
            name: "Wave".into(),
            settings: SceneSettings {
                rgb: Some(RgbScene {
                    zones: 15,
                    color: "e2a35b".into(),
                    mode: Some("wave".into()),
                    speed: Some(4),
                    wave_direction: Some(0),
                }),
                ..Default::default()
            },
        };
        assert!(validate_scene(&ok).is_empty());
        assert_eq!(rgb_mode_id(Some("wave")).unwrap(), 4);
        assert_eq!(rgb_mode_id(None).unwrap(), 1);

        let bad = Scene {
            name: "Bad".into(),
            settings: SceneSettings {
                rgb: Some(RgbScene {
                    zones: 15,
                    color: "ff0000".into(),
                    mode: Some("rainbow".into()),
                    speed: None,
                    wave_direction: None,
                }),
                ..Default::default()
            },
        };
        let problems = validate_scene(&bad);
        assert_eq!(problems.len(), 1);
        assert!(problems[0].contains("invalid rgb mode"));
    }
}
