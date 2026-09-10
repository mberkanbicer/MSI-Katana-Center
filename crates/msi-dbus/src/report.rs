//! Read-only diagnostic report for community/upstream support (Phase 9).
//!
//! Privacy (AGENTS §31): serial numbers and UUIDs are never included.
//! The RGB controller serial is stripped from the device JSON.

use crate::SystemStatus;
use msi_hardware::HardwarePaths;
use serde::Serialize;
use serde_json::Value;
use std::path::Path;

#[derive(Debug, Clone, Serialize)]
pub struct ModuleInfo {
    pub name: String,
    pub state: Option<String>,
    pub version: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
pub struct SystemInfo {
    pub osrelease: Option<String>,
    pub kernel_version: Option<String>,
    pub modules: Vec<ModuleInfo>,
}

fn read_trimmed(path: &Path) -> Option<String> {
    std::fs::read_to_string(path)
        .ok()
        .map(|text| text.trim().to_string())
        .filter(|text| !text.is_empty())
}

pub fn module_info(name: &str, sysroot: &Path) -> Option<ModuleInfo> {
    let base = sysroot.join("sys/module").join(name);
    if !base.is_dir() {
        return None;
    }
    Some(ModuleInfo {
        name: name.to_string(),
        state: read_trimmed(&base.join("initstate")),
        version: read_trimmed(&base.join("version")),
    })
}

pub fn system_info(sysroot: &Path) -> SystemInfo {
    let rooted = |absolute: &str| sysroot.join(absolute.trim_start_matches('/'));
    let mut modules = Vec::new();
    for name in ["msi_ec", "msi_wmi_platform"] {
        if let Some(info) = module_info(name, sysroot) {
            modules.push(info);
        }
    }
    SystemInfo {
        osrelease: read_trimmed(&rooted("/proc/sys/kernel/osrelease")),
        kernel_version: read_trimmed(&rooted("/proc/version")),
        modules,
    }
}

pub fn device_json(status: &SystemStatus) -> Value {
    let mut value = serde_json::to_value(status).expect("SystemStatus serializes");
    if let Some(rgb) = value.get_mut("rgb").and_then(|rgb| rgb.as_object_mut()) {
        rgb.remove("controller_serial");
    }
    value
}

pub fn report_json(status: &SystemStatus, hardware: &HardwarePaths) -> Value {
    serde_json::json!({
        "msicenter_version": env!("CARGO_PKG_VERSION"),
        "system": system_info(hardware.sysroot()),
        "device": device_json(status),
        "unmatched": status.matched_profile.is_none(),
    })
}

pub fn report_json_default(status: &SystemStatus) -> Value {
    report_json(status, &HardwarePaths::default())
}

#[cfg(test)]
mod tests {
    use super::*;
    use msi_core::{BackendAvailability, DeviceIdentity, RgbStatus, SystemStatus};

    #[test]
    fn device_json_drops_rgb_serial() {
        let status = SystemStatus {
            identity: DeviceIdentity {
                product_name: Some("Katana 17 B13VGK".into()),
                ..Default::default()
            },
            matched_profile: None,
            backends: BackendAvailability::default(),
            runtime_capabilities: vec![],
            ec: Default::default(),
            fans: vec![],
            battery: Default::default(),
            rgb: RgbStatus {
                controller_name: Some("MysticLight MS-1565".into()),
                controller_serial: Some("4062C8A28000".into()),
            },
            cpu_cores: vec![],
            gpus: vec![],
        };
        let value = device_json(&status);
        assert_eq!(value["rgb"]["controller_name"], "MysticLight MS-1565");
        assert!(value["rgb"].get("controller_serial").is_none());
        assert!(
            report_json(&status, &HardwarePaths::new("/")).get("unmatched")
                == Some(&Value::Bool(true))
        );
    }
}
