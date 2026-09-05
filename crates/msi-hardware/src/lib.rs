use msi_core::{BackendAvailability, BatteryStatus, DeviceIdentity, EcStatus, FanReading};
use std::fmt;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};

#[derive(Debug)]
pub enum BatteryThresholdError {
    InvalidRange {
        start: u8,
        end: u8,
    },
    Unavailable,
    Parse {
        path: PathBuf,
        value: String,
    },
    Io(io::Error),
    Verification {
        start: u8,
        end: u8,
    },
    Rollback {
        operation: String,
        rollback: io::Error,
    },
}

impl fmt::Display for BatteryThresholdError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InvalidRange { start, end } => {
                write!(
                    f,
                    "invalid battery thresholds: start {start} must be below end {end}"
                )
            }
            Self::Unavailable => f.write_str("writable battery threshold interface unavailable"),
            Self::Parse { path, value } => {
                write!(f, "invalid threshold value {value:?} in {}", path.display())
            }
            Self::Io(error) => write!(f, "battery threshold I/O error: {error}"),
            Self::Verification { start, end } => write!(
                f,
                "battery threshold verification failed: driver reported {start}/{end}"
            ),
            Self::Rollback {
                operation,
                rollback,
            } => write!(
                f,
                "battery threshold operation failed ({operation}); rollback also failed: {rollback}"
            ),
        }
    }
}

impl std::error::Error for BatteryThresholdError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Io(error) => Some(error),
            Self::Rollback { rollback, .. } => Some(rollback),
            _ => None,
        }
    }
}

impl From<io::Error> for BatteryThresholdError {
    fn from(error: io::Error) -> Self {
        Self::Io(error)
    }
}

pub fn validate_battery_thresholds(start: u8, end: u8) -> Result<(), BatteryThresholdError> {
    if start > 100 || end > 100 || start >= end {
        Err(BatteryThresholdError::InvalidRange { start, end })
    } else {
        Ok(())
    }
}

#[derive(Debug, Clone)]
pub struct HardwarePaths {
    root: PathBuf,
}

impl Default for HardwarePaths {
    fn default() -> Self {
        let root = std::env::var_os("MSI_LINUX_CENTER_SYSROOT")
            .map(PathBuf::from)
            .unwrap_or_else(|| PathBuf::from("/"));
        Self { root }
    }
}

impl HardwarePaths {
    pub fn new(root: impl Into<PathBuf>) -> Self {
        Self { root: root.into() }
    }

    fn rooted(&self, absolute: &str) -> PathBuf {
        let relative = absolute.trim_start_matches('/');
        self.root.join(relative)
    }

    pub fn read_identity(&self) -> DeviceIdentity {
        let base = "/sys/class/dmi/id";
        DeviceIdentity {
            sys_vendor: self.read_trimmed(format!("{base}/sys_vendor")),
            product_name: self.read_trimmed(format!("{base}/product_name")),
            product_version: self.read_trimmed(format!("{base}/product_version")),
            board_name: self.read_trimmed(format!("{base}/board_name")),
            board_version: self.read_trimmed(format!("{base}/board_version")),
            bios_version: self.read_trimmed(format!("{base}/bios_version")),
            bios_date: self.read_trimmed(format!("{base}/bios_date")),
        }
    }

    pub fn read_msi_ec(&self) -> EcStatus {
        let base = "/sys/devices/platform/msi-ec";
        EcStatus {
            firmware: self.read_trimmed(format!("{base}/fw_version")),
            shift_mode: self.read_trimmed(format!("{base}/shift_mode")),
            available_shift_modes: self.read_words(format!("{base}/available_shift_modes")),
            fan_mode: self.read_trimmed(format!("{base}/fan_mode")),
            available_fan_modes: self.read_words(format!("{base}/available_fan_modes")),
            cooler_boost: self.read_on_off(format!("{base}/cooler_boost")),
            super_battery: self.read_on_off(format!("{base}/super_battery")),
            cpu_temperature_c: self.read_num(format!("{base}/cpu/realtime_temperature")),
            gpu_temperature_c: self.read_num(format!("{base}/gpu/realtime_temperature")),
            cpu_fan_level: self.read_num(format!("{base}/cpu/realtime_fan_speed")),
            gpu_fan_level: self.read_num(format!("{base}/gpu/realtime_fan_speed")),
        }
    }

    pub fn read_msi_wmi_fans(&self) -> io::Result<Vec<FanReading>> {
        let mut out = Vec::new();

        for path in self.msi_wmi_hwmon_paths()? {
            for index in 1..=8 {
                let fan_path = path.join(format!("fan{index}_input"));
                if let Some(rpm) = read_num_path::<u32>(&fan_path) {
                    out.push(FanReading {
                        channel: format!("fan{index}"),
                        rpm,
                        source: "msi_wmi_platform/hwmon".into(),
                    });
                }
            }
        }

        Ok(out)
    }

    pub fn read_laptop_battery(&self) -> io::Result<BatteryStatus> {
        let Some(path) = self.laptop_battery_path()? else {
            return Ok(BatteryStatus::default());
        };

        Ok(BatteryStatus {
            name: path
                .file_name()
                .and_then(|n| n.to_str())
                .map(str::to_string),
            status: read_trimmed_path(&path.join("status")),
            capacity_percent: read_num_path(&path.join("capacity")),
            charge_start_percent: read_num_path(&path.join("charge_control_start_threshold"))
                .or_else(|| read_num_path(&path.join("charge_start_threshold"))),
            charge_end_percent: read_num_path(&path.join("charge_control_end_threshold"))
                .or_else(|| read_num_path(&path.join("charge_stop_threshold"))),
        })
    }

    pub fn set_battery_thresholds(
        &self,
        start: u8,
        end: u8,
    ) -> Result<BatteryStatus, BatteryThresholdError> {
        validate_battery_thresholds(start, end)?;

        let battery = self
            .laptop_battery_path()?
            .ok_or(BatteryThresholdError::Unavailable)?;
        let start_path = first_existing(
            &battery,
            &["charge_control_start_threshold", "charge_start_threshold"],
        )
        .ok_or(BatteryThresholdError::Unavailable)?;
        let end_path = first_existing(
            &battery,
            &["charge_control_end_threshold", "charge_stop_threshold"],
        )
        .ok_or(BatteryThresholdError::Unavailable)?;
        let old_start = read_threshold(&start_path)?;
        let old_end = read_threshold(&end_path)?;

        if let Err(operation) = write_threshold_pair(&start_path, &end_path, old_start, start, end)
        {
            return Err(rollback_error(
                &start_path,
                &end_path,
                old_start,
                old_end,
                BatteryThresholdError::Io(operation),
            ));
        }

        let applied_start = match read_threshold(&start_path) {
            Ok(value) => value,
            Err(error) => {
                return Err(rollback_error(
                    &start_path,
                    &end_path,
                    old_start,
                    old_end,
                    error,
                ));
            }
        };
        let applied_end = match read_threshold(&end_path) {
            Ok(value) => value,
            Err(error) => {
                return Err(rollback_error(
                    &start_path,
                    &end_path,
                    old_start,
                    old_end,
                    error,
                ));
            }
        };
        if applied_start > 100 || applied_end > 100 || applied_start >= applied_end {
            return Err(rollback_error(
                &start_path,
                &end_path,
                old_start,
                old_end,
                BatteryThresholdError::Verification {
                    start: applied_start,
                    end: applied_end,
                },
            ));
        }

        self.read_laptop_battery().map_err(Into::into)
    }

    pub fn discover_backends(&self) -> io::Result<BackendAvailability> {
        Ok(BackendAvailability {
            msi_ec: self.rooted("/sys/devices/platform/msi-ec").is_dir(),
            msi_wmi_platform: !self.msi_wmi_hwmon_paths()?.is_empty(),
            power_supply_battery: self.laptop_battery_path()?.is_some(),
            rgb_hid: false,
        })
    }

    pub fn has_usb_device(&self, vendor: &str, product: &str) -> io::Result<bool> {
        let root = self.rooted("/sys/bus/usb/devices");
        let entries = match fs::read_dir(root) {
            Ok(entries) => entries,
            Err(err) if err.kind() == io::ErrorKind::NotFound => return Ok(false),
            Err(err) => return Err(err),
        };

        Ok(entries.flatten().any(|entry| {
            let path = entry.path();
            read_trimmed_path(&path.join("idVendor"))
                .is_some_and(|value| value.eq_ignore_ascii_case(vendor))
                && read_trimmed_path(&path.join("idProduct"))
                    .is_some_and(|value| value.eq_ignore_ascii_case(product))
        }))
    }

    fn msi_wmi_hwmon_paths(&self) -> io::Result<Vec<PathBuf>> {
        let entries = match fs::read_dir(self.rooted("/sys/class/hwmon")) {
            Ok(entries) => entries,
            Err(err) if err.kind() == io::ErrorKind::NotFound => return Ok(Vec::new()),
            Err(err) => return Err(err),
        };
        let mut paths: Vec<_> = entries
            .flatten()
            .map(|entry| entry.path())
            .filter(|path| {
                read_trimmed_path(&path.join("name")).as_deref() == Some("msi_wmi_platform")
            })
            .collect();
        paths.sort();
        Ok(paths)
    }

    fn laptop_battery_path(&self) -> io::Result<Option<PathBuf>> {
        let entries = match fs::read_dir(self.rooted("/sys/class/power_supply")) {
            Ok(entries) => entries,
            Err(err) if err.kind() == io::ErrorKind::NotFound => return Ok(None),
            Err(err) => return Err(err),
        };
        let mut candidates: Vec<_> = entries
            .flatten()
            .map(|entry| entry.path())
            .filter(|path| {
                let name = path
                    .file_name()
                    .and_then(|name| name.to_str())
                    .unwrap_or_default();
                !name.starts_with("hidpp_")
                    && read_trimmed_path(&path.join("type")).as_deref() == Some("Battery")
            })
            .collect();
        candidates.sort();
        Ok(candidates.into_iter().next())
    }

    fn read_trimmed(&self, path: impl AsRef<str>) -> Option<String> {
        read_trimmed_path(&self.rooted(path.as_ref()))
    }

    fn read_words(&self, path: impl AsRef<str>) -> Vec<String> {
        self.read_trimmed(path)
            .map(|s| s.split_whitespace().map(str::to_owned).collect())
            .unwrap_or_default()
    }

    fn read_on_off(&self, path: impl AsRef<str>) -> Option<bool> {
        match self.read_trimmed(path)?.to_ascii_lowercase().as_str() {
            "on" | "1" | "true" | "enabled" => Some(true),
            "off" | "0" | "false" | "disabled" => Some(false),
            _ => None,
        }
    }

    fn read_num<T: std::str::FromStr>(&self, path: impl AsRef<str>) -> Option<T> {
        self.read_trimmed(path)?.parse().ok()
    }
}

fn read_trimmed_path(path: &Path) -> Option<String> {
    fs::read_to_string(path)
        .ok()
        .map(|s| s.trim().to_owned())
        .filter(|s| !s.is_empty())
}

fn read_num_path<T: std::str::FromStr>(path: &Path) -> Option<T> {
    read_trimmed_path(path)?.parse().ok()
}

fn first_existing(root: &Path, names: &[&str]) -> Option<PathBuf> {
    names
        .iter()
        .map(|name| root.join(name))
        .find(|path| path.is_file())
}

fn read_threshold(path: &Path) -> Result<u8, BatteryThresholdError> {
    let value = fs::read_to_string(path)?;
    value
        .trim()
        .parse()
        .map_err(|_| BatteryThresholdError::Parse {
            path: path.to_owned(),
            value: value.trim().into(),
        })
}

fn write_threshold(path: &Path, value: u8) -> io::Result<()> {
    fs::write(path, format!("{value}\n"))
}

fn write_threshold_pair(
    start_path: &Path,
    end_path: &Path,
    current_start: u8,
    start: u8,
    end: u8,
) -> io::Result<()> {
    if end <= current_start {
        write_threshold(start_path, start)?;
        write_threshold(end_path, end)
    } else {
        write_threshold(end_path, end)?;
        write_threshold(start_path, start)
    }
}

fn rollback_error(
    start_path: &Path,
    end_path: &Path,
    old_start: u8,
    old_end: u8,
    operation: BatteryThresholdError,
) -> BatteryThresholdError {
    let current_start = read_threshold(start_path).unwrap_or(old_start);
    match write_threshold_pair(start_path, end_path, current_start, old_start, old_end) {
        Ok(()) => operation,
        Err(rollback) => BatteryThresholdError::Rollback {
            operation: operation.to_string(),
            rollback,
        },
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::{SystemTime, UNIX_EPOCH};

    #[test]
    fn writes_and_validates_battery_thresholds() {
        let root = std::env::temp_dir().join(format!(
            "msi-linux-center-battery-{}-{}",
            std::process::id(),
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        let battery = root.join("sys/class/power_supply/BAT0");
        fs::create_dir_all(&battery).unwrap();
        fs::write(battery.join("type"), "Battery\n").unwrap();
        fs::write(battery.join("charge_control_start_threshold"), "90\n").unwrap();
        fs::write(battery.join("charge_control_end_threshold"), "100\n").unwrap();

        let hardware = HardwarePaths::new(&root);
        let applied = hardware.set_battery_thresholds(50, 80).unwrap();
        assert_eq!(applied.charge_start_percent, Some(50));
        assert_eq!(applied.charge_end_percent, Some(80));
        assert!(matches!(
            hardware.set_battery_thresholds(90, 80),
            Err(BatteryThresholdError::InvalidRange { .. })
        ));
        assert_eq!(
            read_threshold(&battery.join("charge_control_start_threshold")).unwrap(),
            50
        );
        assert_eq!(
            read_threshold(&battery.join("charge_control_end_threshold")).unwrap(),
            80
        );

        fs::remove_dir_all(root).unwrap();
    }
}
