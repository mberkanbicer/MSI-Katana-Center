use msi_core::SystemStatus;
use msi_dbus::{
    collect_status, request_battery_thresholds, request_cooler_boost, request_fan_mode,
    request_rgb_color, request_rgb_effect, request_rgb_save, request_super_battery,
};
use std::process::ExitCode;

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();

    match run(&args) {
        Ok(()) => ExitCode::SUCCESS,
        Err(err) => {
            eprintln!("msicenter: {err}");
            ExitCode::FAILURE
        }
    }
}

fn run(args: &[String]) -> Result<(), Box<dyn std::error::Error>> {
    let command = args.first().map(String::as_str).unwrap_or("status");

    match command {
        "status" => {
            let status = collect_status()?;
            if args.iter().any(|arg| arg == "--json") {
                println!("{}", serde_json::to_string_pretty(&status)?);
            } else {
                print_status(&status);
            }
        }
        "capabilities" => print_capabilities(&collect_status()?),
        "battery-thresholds" => {
            if args.len() != 3 {
                return Err("usage: msicenter battery-thresholds START END".into());
            }
            let start = args[1].parse::<u8>()?;
            let end = args[2].parse::<u8>()?;
            println!("{}", request_battery_thresholds(start, end)?);
        }
        "fan-mode" => {
            if args.len() != 2 {
                return Err("usage: msicenter fan-mode MODE".into());
            }
            println!("{}", request_fan_mode(&args[1])?);
        }
        "cooler-boost" => {
            if args.len() != 2 {
                return Err("usage: msicenter cooler-boost on|off".into());
            }
            let enabled = match args[1].as_str() {
                "on" | "1" | "true" => true,
                "off" | "0" | "false" => false,
                other => return Err(format!("invalid cooler-boost value: {other}").into()),
            };
            println!("{}", request_cooler_boost(enabled)?);
        }
        "super-battery" => {
            if args.len() != 2 {
                return Err("usage: msicenter super-battery on|off".into());
            }
            let enabled = match args[1].as_str() {
                "on" | "1" | "true" => true,
                "off" | "0" | "false" => false,
                other => return Err(format!("invalid super-battery value: {other}").into()),
            };
            println!("{}", request_super_battery(enabled)?);
        }
        "rgb-color" => {
            if args.len() != 3 {
                return Err("usage: msicenter rgb-color ZONE_MASK RRGGBB (non-persistent)".into());
            }
            let zones = u8::from_str_radix(&args[1], 16)
                .map_err(|_| format!("invalid zone mask: {}", args[1]))?;
            let color = args[2].as_bytes();
            if color.len() != 6 || !color.iter().all(u8::is_ascii_hexdigit) {
                return Err(format!("invalid color: {} (expected RRGGBB)", args[2]).into());
            }
            let channel = |range: std::ops::Range<usize>| {
                u8::from_str_radix(&args[2][range], 16).expect("validated hex")
            };
            println!(
                "{}",
                request_rgb_color(zones, channel(0..2), channel(2..4), channel(4..6))?
            );
        }
        "rgb-effect" => {
            if args.len() != 5 {
                return Err(
                    "usage: msicenter rgb-effect ZONE_MASK MODE SPEED_S COLORS (non-persistent)\n       MODE: off|steady|breath|cycle|wave, COLORS: RRGGBB[,RRGGBB...]"
                        .into(),
                );
            }
            let zones = u8::from_str_radix(&args[1], 16)
                .map_err(|_| format!("invalid zone mask: {}", args[1]))?;
            let mode = match args[2].as_str() {
                "off" => 0u8,
                "steady" => 1,
                "breath" | "breathing" => 2,
                "cycle" => 3,
                "wave" => 4,
                other => return Err(format!("invalid mode: {other}").into()),
            };
            let speed_seconds: u16 = args[3]
                .parse()
                .map_err(|_| format!("invalid speed: {}", args[3]))?;
            if speed_seconds > 600 {
                return Err("speed too large (max 600 s)".into());
            }
            let mut colors = Vec::new();
            for part in args[4].split(',') {
                let bytes = part.as_bytes();
                if bytes.len() != 6 || !bytes.iter().all(u8::is_ascii_hexdigit) {
                    return Err(format!("invalid color: {part} (expected RRGGBB)").into());
                }
                let channel = |range: std::ops::Range<usize>| {
                    u8::from_str_radix(&part[range], 16).expect("validated hex")
                };
                colors.push((channel(0..2), channel(2..4), channel(4..6)));
            }
            if colors.len() > 10 {
                return Err("too many colors (max 10)".into());
            }
            println!(
                "{}",
                request_rgb_effect(zones, mode, speed_seconds * 100, 1, colors)?
            );
        }
        "rgb-save" => {
            if args.len() != 1 {
                return Err("usage: msicenter rgb-save (persistent flash save)".into());
            }
            println!("{}", request_rgb_save()?);
        }
        "version" | "--version" | "-V" => {
            println!("msicenter {}", env!("CARGO_PKG_VERSION"));
        }
        "help" | "--help" | "-h" => print_help(),
        other => return Err(format!("unknown command: {other}").into()),
    }

    Ok(())
}

fn print_help() {
    println!("MSI Linux Center");
    println!();
    println!("Usage:");
    println!("  msicenter status [--json]");
    println!("  msicenter capabilities");
    println!("  msicenter battery-thresholds START END");
    println!("  msicenter fan-mode MODE");
    println!("  msicenter cooler-boost on|off");
    println!("  msicenter super-battery on|off");
    println!("  msicenter rgb-color ZONE_MASK RRGGBB  (non-persistent)");
    println!("  msicenter rgb-effect ZONE_MASK MODE SPEED_S COLORS  (non-persistent)");
    println!("  msicenter rgb-save  (persistent flash save)");
    println!("  msicenter --version");
    println!();
    println!("Testing:");
    println!("  MSI_LINUX_CENTER_SYSROOT=/path/to/fixture msicenter status");
}

fn print_status(status: &SystemStatus) {
    let identity = &status.identity;
    let profile = status.matched_profile.as_ref();

    println!("MSI Linux Center");
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

    println!();
    println!("MSI EC");
    println!("  Shift mode  : {}", show(status.ec.shift_mode.as_deref()));
    println!("  Fan mode    : {}", show(status.ec.fan_mode.as_deref()));
    println!("  CoolerBoost : {}", show_bool(status.ec.cooler_boost));
    println!("  SuperBattery: {}", show_bool(status.ec.super_battery));
    println!("  CPU temp    : {}", show_temp(status.ec.cpu_temperature_c));
    println!("  GPU temp    : {}", show_temp(status.ec.gpu_temperature_c));
    println!("  CPU fan lvl : {}", show_num(status.ec.cpu_fan_level));
    println!("  GPU fan lvl : {}", show_num(status.ec.gpu_fan_level));

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
    println!("RGB");
    println!(
        "  Controller  : {}",
        show(status.rgb.controller_name.as_deref())
    );
    println!(
        "  Serial      : {}",
        show(status.rgb.controller_serial.as_deref())
    );

    println!();
    println!("Battery");
    println!("  Device      : {}", show(status.battery.name.as_deref()));
    println!("  Status      : {}", show(status.battery.status.as_deref()));
    println!(
        "  Capacity    : {}",
        show_percent(status.battery.capacity_percent)
    );
    println!(
        "  Start limit : {}",
        show_percent(status.battery.charge_start_percent)
    );
    println!(
        "  End limit   : {}",
        show_percent(status.battery.charge_end_percent)
    );
}

fn print_capabilities(status: &SystemStatus) {
    println!(
        "Runtime capabilities for {}",
        status
            .matched_profile
            .as_ref()
            .map(|profile| profile.marketing_name.as_str())
            .unwrap_or("unmatched device")
    );
    for capability in &status.runtime_capabilities {
        println!(
            "  {:<18}: {} (model: {}, backend: {}, readable: {}, confidence: {})",
            capability.feature.replace('_', " "),
            capability.availability(),
            yes(capability.declared_by_model),
            yes(capability.backend_detected),
            yes(capability.readable),
            capability.support_tier,
        );
    }
    println!("Write features remain disabled.");
}

fn show(value: Option<&str>) -> &str {
    value.unwrap_or("unavailable")
}

fn show_bool(value: Option<bool>) -> &'static str {
    match value {
        Some(true) => "on",
        Some(false) => "off",
        None => "unavailable",
    }
}

fn show_temp(value: Option<i32>) -> String {
    value
        .map(|v| format!("{v} °C"))
        .unwrap_or_else(|| "unavailable".into())
}

fn show_num<T: std::fmt::Display>(value: Option<T>) -> String {
    value
        .map(|v| v.to_string())
        .unwrap_or_else(|| "unavailable".into())
}

fn show_percent(value: Option<u8>) -> String {
    value
        .map(|v| format!("{v}%"))
        .unwrap_or_else(|| "unavailable".into())
}

fn yes(value: bool) -> &'static str {
    if value {
        "yes"
    } else {
        "no"
    }
}

#[cfg(test)]
mod tests {
    use std::path::PathBuf;

    fn fixture(name: &str) -> PathBuf {
        PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .join("../../tests/fixtures")
            .join(name)
    }

    #[test]
    fn fixture_status_and_missing_interfaces() {
        let status = msi_dbus::collect_status_at(fixture("katana17-b13vgk")).unwrap();
        assert_eq!(status.ec.shift_mode.as_deref(), Some("unknown (192)"));
        assert!(status.backends.msi_ec);
        assert!(status.backends.msi_wmi_platform);
        assert!(status.backends.power_supply_battery);
        assert_eq!(status.fans.len(), 3);
        assert_eq!(status.fans[2].channel, "fan3");
        assert_eq!(status.fans[2].rpm, 0);
        assert_eq!(status.battery.name.as_deref(), Some("BAT1"));
        assert_eq!(status.battery.charge_start_percent, Some(90));
        assert_eq!(status.battery.charge_end_percent, Some(100));
        assert_eq!(
            status
                .runtime_capabilities
                .iter()
                .find(|capability| capability.feature == "fan_rpm")
                .unwrap()
                .availability()
                .to_string(),
            "available now"
        );

        let json = serde_json::to_value(&status).unwrap();
        assert_eq!(json["ec"]["shift_mode"], "unknown (192)");
        assert!(json["runtime_capabilities"].is_array());

        let missing = msi_dbus::collect_status_at(fixture("missing-interfaces")).unwrap();
        assert!(!missing.backends.msi_ec);
        assert!(!missing.backends.msi_wmi_platform);
        assert!(missing.backends.power_supply_battery);
        assert_eq!(missing.battery.name.as_deref(), Some("BAT0"));
        assert_eq!(missing.battery.charge_start_percent, None);
        assert_eq!(missing.battery.charge_end_percent, None);
    }
}
