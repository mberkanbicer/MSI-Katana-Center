//! Read-only diagnostic report for community/upstream support (Phase 9).
//!
//! A report collects the kernel/module context around a `SystemStatus` so
//! an issue can be filed without re-asking for basics. Everything here is
//! read-only. Privacy rule AGENTS §31: serial numbers and UUIDs are never
//! included — the RGB controller serial is dropped from the device JSON.

use msi_core::SystemStatus;
use serde::Serialize;
use std::path::{Path, PathBuf};

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
}

/// sysroot override, matching `msi-hardware::HardwarePaths` resolution.
pub fn sysroot() -> PathBuf {
    std::env::var_os("MSI_LINUX_CENTER_SYSROOT")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("/"))
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

/// Device JSON with serial numbers removed (AGENTS §31).
pub fn device_json(status: &SystemStatus) -> serde_json::Value {
    let mut value = serde_json::to_value(status).expect("SystemStatus serializes");
    if let Some(rgb) = value.get_mut("rgb").and_then(|rgb| rgb.as_object_mut()) {
        rgb.remove("controller_serial");
    }
    value
}

/// Full JSON report: tool version, system context, redacted device state.
pub fn report_json(status: &SystemStatus) -> serde_json::Value {
    serde_json::json!({
        "msicenter_version": env!("CARGO_PKG_VERSION"),
        "system": system_info(&sysroot()),
        "device": device_json(status),
    })
}

fn show(value: Option<&str>) -> &str {
    value.unwrap_or("unavailable")
}

/// Human-readable report (no serial numbers, AGENTS §31).
pub fn print_report(status: &SystemStatus) {
    let info = system_info(&sysroot());
    let identity = &status.identity;
    let profile = status.matched_profile.as_ref();

    println!(
        "MSI Linux Center report (msicenter {})",
        env!("CARGO_PKG_VERSION")
    );
    println!();
    println!("System");
    println!("  Kernel      : {}", show(info.osrelease.as_deref()));
    println!("  Version     : {}", show(info.kernel_version.as_deref()));
    for module in &info.modules {
        println!(
            "  Module      : {:<16} state: {:<6} version: {}",
            module.name,
            module.state.as_deref().unwrap_or("unavailable"),
            module.version.as_deref().unwrap_or("unavailable")
        );
    }

    println!();
    println!("Device");
    println!("  Model       : {}", show(identity.product_name.as_deref()));
    println!("  Board       : {}", show(identity.board_name.as_deref()));
    println!("  BIOS        : {}", show(identity.bios_version.as_deref()));
    println!("  EC firmware : {}", show(status.ec.firmware.as_deref()));
    println!(
        "  Profile     : {}",
        profile
            .map(|p| p.marketing_name.as_str())
            .unwrap_or("unmatched")
    );
    println!(
        "  Support     : {}",
        profile
            .map(|p| p.support_tier.to_string())
            .unwrap_or_else(|| "unknown".into())
    );
    let backend_names = [
        ("msi_ec", status.backends.msi_ec),
        ("msi_wmi_platform", status.backends.msi_wmi_platform),
        ("power_supply_battery", status.backends.power_supply_battery),
        ("rgb hid", status.backends.rgb_hid),
    ];
    let detected: Vec<&str> = backend_names
        .iter()
        .filter(|(_, present)| *present)
        .map(|(name, _)| *name)
        .collect();
    println!("  Backends    : {}", detected.join(", "));

    println!();
    println!("MSI EC");
    println!("  Shift mode  : {}", show(status.ec.shift_mode.as_deref()));
    println!("  Fan mode    : {}", show(status.ec.fan_mode.as_deref()));
    println!(
        "  Fan modes   : {}",
        if status.ec.available_fan_modes.is_empty() {
            "unavailable".to_string()
        } else {
            status.ec.available_fan_modes.join(", ")
        }
    );
    println!(
        "  CoolerBoost : {}",
        status
            .ec
            .cooler_boost
            .map(|enabled| if enabled { "on" } else { "off" }.to_string())
            .unwrap_or_else(|| "unavailable".into())
    );
    println!(
        "  SuperBattery: {}",
        status
            .ec
            .super_battery
            .map(|enabled| if enabled { "on" } else { "off" }.to_string())
            .unwrap_or_else(|| "unavailable".into())
    );
    println!(
        "  CPU temp    : {}",
        status
            .ec
            .cpu_temperature_c
            .map(|value| format!("{value} C"))
            .unwrap_or_else(|| "unavailable".into())
    );
    println!(
        "  GPU temp    : {}",
        status
            .ec
            .gpu_temperature_c
            .map(|value| format!("{value} C"))
            .unwrap_or_else(|| "unavailable".into())
    );

    println!();
    println!("Fan RPM (unmapped channels)");
    if status.fans.is_empty() {
        println!("  unavailable");
    } else {
        for fan in &status.fans {
            println!("  {:<10}: {} RPM ({})", fan.channel, fan.rpm, fan.source);
        }
    }

    println!();
    println!("Battery");
    println!("  Device      : {}", show(status.battery.name.as_deref()));
    println!("  Status      : {}", show(status.battery.status.as_deref()));
    println!(
        "  Capacity    : {}",
        status
            .battery
            .capacity_percent
            .map(|value| format!("{value}%"))
            .unwrap_or_else(|| "unavailable".into())
    );
    println!(
        "  Start limit : {}",
        status
            .battery
            .charge_start_percent
            .map(|value| format!("{value}%"))
            .unwrap_or_else(|| "unavailable".into())
    );
    println!(
        "  End limit   : {}",
        status
            .battery
            .charge_end_percent
            .map(|value| format!("{value}%"))
            .unwrap_or_else(|| "unavailable".into())
    );

    println!();
    println!("RGB (serial redacted)");
    println!(
        "  Controller  : {}",
        show(status.rgb.controller_name.as_deref())
    );

    println!();
    println!("Runtime capabilities");
    for capability in &status.runtime_capabilities {
        println!(
            "  {:<18}: {} (model: {}, backend: {}, readable: {}, confidence: {})",
            capability.feature.replace('_', " "),
            capability.availability(),
            if capability.declared_by_model {
                "yes"
            } else {
                "no"
            },
            if capability.backend_detected {
                "yes"
            } else {
                "no"
            },
            if capability.readable { "yes" } else { "no" },
            capability.support_tier,
        );
    }
    println!();
    println!("Privacy: serial numbers and UUIDs are not included (AGENTS §31).");
    println!("For the machine-readable form run: msicenter report --json");
}

#[cfg(test)]
mod tests {
    use super::*;
    use msi_core::{BackendAvailability, DeviceIdentity, RgbStatus, SystemStatus};

    fn sample_status() -> SystemStatus {
        SystemStatus {
            identity: DeviceIdentity {
                sys_vendor: Some("Micro-Star International".into()),
                product_name: Some("Katana 17 B13VGK".into()),
                ..Default::default()
            },
            matched_profile: None,
            backends: BackendAvailability {
                msi_ec: true,
                msi_wmi_platform: true,
                power_supply_battery: true,
                rgb_hid: false,
            },
            runtime_capabilities: vec![],
            ec: Default::default(),
            fans: vec![],
            battery: Default::default(),
            rgb: RgbStatus {
                controller_name: Some("MysticLight MS-1565".into()),
                controller_serial: Some("4062C8A28000".into()),
            },
        }
    }

    #[test]
    fn device_json_drops_rgb_serial() {
        let value = device_json(&sample_status());
        assert_eq!(value["rgb"]["controller_name"], "MysticLight MS-1565");
        assert!(value["rgb"].get("controller_serial").is_none());
    }

    #[test]
    fn module_info_reads_state_and_version() {
        let root = std::env::temp_dir().join("msicenter-report-test");
        let base = root.join("sys/module/msi_ec");
        std::fs::create_dir_all(&base).unwrap();
        std::fs::write(base.join("initstate"), "live\n").unwrap();
        std::fs::write(base.join("version"), "0.13\n").unwrap();

        let info = module_info("msi_ec", &root).expect("module present");
        assert_eq!(info.state.as_deref(), Some("live"));
        assert_eq!(info.version.as_deref(), Some("0.13"));
        assert!(module_info("not_a_module", &root).is_none());

        std::fs::remove_dir_all(&root).ok();
    }
}
