//! Human-readable Phase 9 report. JSON lives in `msi_dbus::report_json`.

use msi_core::SystemStatus;
use msi_dbus::system_info;
use std::path::PathBuf;

fn show(value: Option<&str>) -> &str {
    value.unwrap_or("unavailable")
}

fn sysroot() -> PathBuf {
    std::env::var_os("MSI_LINUX_CENTER_SYSROOT")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("/"))
}

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
    if profile.is_none() {
        println!("  Note        : unmatched model — attach this report when asking for support");
    }
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
        "  Webcam      : {}",
        status
            .ec
            .webcam
            .map(|enabled| if enabled { "on" } else { "off" }.to_string())
            .unwrap_or_else(|| "unavailable".into())
    );
    println!(
        "  Webcam block: {}",
        status
            .ec
            .webcam_block
            .map(|enabled| if enabled { "on" } else { "off" }.to_string())
            .unwrap_or_else(|| "unavailable".into())
    );
    println!(
        "  Fn key      : {}",
        status.ec.fn_key.as_deref().unwrap_or("unavailable")
    );
    println!(
        "  Win key     : {}",
        status.ec.win_key.as_deref().unwrap_or("unavailable")
    );
    println!(
        "  EC date     : {}",
        status.ec.firmware_date.as_deref().unwrap_or("unavailable")
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
