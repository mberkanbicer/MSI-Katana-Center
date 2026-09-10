use msi_core::{
    BackendAvailability, BatteryStatus, CoolerBoostState, CpuCoreReading, DeviceIdentity, EcStatus,
    FanModeState, FanReading, FnWinState, GpuReading, SuperBatteryState, WebcamBlockState,
    WebcamState,
};
use std::fmt;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use std::time::Instant;

pub mod rgb;

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

#[derive(Debug)]
pub enum FanModeError {
    Unavailable,
    InvalidMode {
        mode: String,
        available: Vec<String>,
    },
    Io(io::Error),
    Verification {
        applied: Option<String>,
        expected: String,
    },
    Rollback {
        operation: String,
        rollback: io::Error,
    },
}

impl fmt::Display for FanModeError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Unavailable => f.write_str("writable msi-ec fan-mode interface unavailable"),
            Self::InvalidMode { mode, available } => write!(
                f,
                "invalid fan mode {mode:?}; available modes: {}",
                available.join(", ")
            ),
            Self::Io(error) => write!(f, "fan-mode I/O error: {error}"),
            Self::Verification { applied, expected } => write!(
                f,
                "fan-mode verification failed: driver reported {applied:?}, expected {expected:?}"
            ),
            Self::Rollback {
                operation,
                rollback,
            } => write!(
                f,
                "fan-mode operation failed ({operation}); rollback also failed: {rollback}"
            ),
        }
    }
}

impl std::error::Error for FanModeError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Io(error) => Some(error),
            Self::Rollback { rollback, .. } => Some(rollback),
            _ => None,
        }
    }
}

impl From<io::Error> for FanModeError {
    fn from(error: io::Error) -> Self {
        Self::Io(error)
    }
}

#[derive(Debug)]
pub enum CoolerBoostError {
    Unavailable,
    Io(io::Error),
    Verification {
        applied: Option<bool>,
        expected: bool,
    },
    Rollback {
        operation: String,
        rollback: io::Error,
    },
}

impl fmt::Display for CoolerBoostError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Unavailable => f.write_str("writable msi-ec cooler-boost interface unavailable"),
            Self::Io(error) => write!(f, "cooler-boost I/O error: {error}"),
            Self::Verification { applied, expected } => write!(
                f,
                "cooler-boost verification failed: driver reported {applied:?}, expected {expected:?}"
            ),
            Self::Rollback {
                operation,
                rollback,
            } => write!(
                f,
                "cooler-boost operation failed ({operation}); rollback also failed: {rollback}"
            ),
        }
    }
}

impl std::error::Error for CoolerBoostError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Io(error) => Some(error),
            Self::Rollback { rollback, .. } => Some(rollback),
            _ => None,
        }
    }
}

impl From<io::Error> for CoolerBoostError {
    fn from(error: io::Error) -> Self {
        Self::Io(error)
    }
}

#[derive(Debug)]
pub enum SuperBatteryError {
    Unavailable,
    Io(io::Error),
    Verification {
        applied: Option<bool>,
        expected: bool,
    },
    Rollback {
        operation: String,
        rollback: io::Error,
    },
}

impl fmt::Display for SuperBatteryError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Unavailable => f.write_str("writable msi-ec super-battery interface unavailable"),
            Self::Io(error) => write!(f, "super-battery I/O error: {error}"),
            Self::Verification { applied, expected } => write!(
                f,
                "super-battery verification failed: driver reported {applied:?}, expected {expected:?}"
            ),
            Self::Rollback {
                operation,
                rollback,
            } => write!(
                f,
                "super-battery operation failed ({operation}); rollback also failed: {rollback}"
            ),
        }
    }
}

impl std::error::Error for SuperBatteryError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Io(error) => Some(error),
            Self::Rollback { rollback, .. } => Some(rollback),
            _ => None,
        }
    }
}

impl From<io::Error> for SuperBatteryError {
    fn from(error: io::Error) -> Self {
        Self::Io(error)
    }
}

#[derive(Debug)]
pub enum EcAttrError {
    Unavailable {
        attr: &'static str,
    },
    InvalidValue {
        attr: &'static str,
        value: String,
    },
    Io {
        attr: &'static str,
        error: io::Error,
    },
    Verification {
        attr: &'static str,
        applied: Option<String>,
        expected: String,
    },
    Rollback {
        attr: &'static str,
        operation: String,
        rollback: io::Error,
    },
}

impl fmt::Display for EcAttrError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Unavailable { attr } => {
                write!(f, "writable msi-ec {attr} interface unavailable")
            }
            Self::InvalidValue { attr, value } => {
                write!(f, "invalid {attr} value {value:?}")
            }
            Self::Io { attr, error } => write!(f, "{attr} I/O error: {error}"),
            Self::Verification {
                attr,
                applied,
                expected,
            } => write!(
                f,
                "{attr} verification failed: driver reported {applied:?}, expected {expected:?}"
            ),
            Self::Rollback {
                attr,
                operation,
                rollback,
            } => write!(
                f,
                "{attr} operation failed ({operation}); rollback also failed: {rollback}"
            ),
        }
    }
}

impl std::error::Error for EcAttrError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Io { error, .. } => Some(error),
            Self::Rollback { rollback, .. } => Some(rollback),
            _ => None,
        }
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
    /// Previous /proc/stat counters for per-thread load. Interior mutability
    /// keeps `collect_status_from(&hw)` snapshot-shaped; first read yields
    /// `load_percent: None` until a second sample exists.
    cpu_prev: Arc<Mutex<Option<CpuStatSnapshot>>>,
    /// `nvidia-smi` is the only subprocess on the refresh path, so GPU rows
    /// are cached for 2s (the UI polls at the same rate).
    gpu_cache: Arc<Mutex<GpuCache>>,
}

/// Aggregate + per-thread (idle, total) jiffy counters from /proc/stat.
#[derive(Debug, Clone)]
struct CpuStatSnapshot {
    aggregate: (u64, u64),
    cores: Vec<(u32, u64, u64)>,
}

/// Cached GPU rows with their sample time (see `HardwarePaths::read_gpus`).
type GpuCache = Option<(Instant, Vec<GpuReading>)>;

impl Default for HardwarePaths {
    fn default() -> Self {
        let root = std::env::var_os("MSI_LINUX_CENTER_SYSROOT")
            .map(PathBuf::from)
            .unwrap_or_else(|| PathBuf::from("/"));
        Self {
            root,
            cpu_prev: Arc::new(Mutex::new(None)),
            gpu_cache: Arc::new(Mutex::new(None)),
        }
    }
}

impl HardwarePaths {
    pub fn new(root: impl Into<PathBuf>) -> Self {
        Self {
            root: root.into(),
            cpu_prev: Arc::new(Mutex::new(None)),
            gpu_cache: Arc::new(Mutex::new(None)),
        }
    }

    pub fn sysroot(&self) -> &Path {
        &self.root
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
            webcam: self.read_on_off(format!("{base}/webcam")),
            webcam_block: self.read_on_off(format!("{base}/webcam_block")),
            fn_key: self.read_trimmed(format!("{base}/fn_key")),
            win_key: self.read_trimmed(format!("{base}/win_key")),
            firmware_date: self.read_trimmed(format!("{base}/fw_release_date")),
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

    /// Per-core temperatures from `coretemp` hwmon joined with per-thread
    /// load from /proc/stat deltas. Empty when no `coretemp` driver exists;
    /// load is `None` until a second sample has been taken.
    pub fn read_cpu_cores(&self) -> Vec<CpuCoreReading> {
        let temps = self.coretemp_readings();
        if temps.is_empty() {
            return Vec::new();
        }
        let (loads, aggregate) = self.cpu_load_percent();
        let mut cores: Vec<CpuCoreReading> = temps
            .into_iter()
            .map(|(id, core, temp_c)| {
                let load_percent = match core {
                    // The package row carries whole-CPU load.
                    None if id.starts_with("Package") => aggregate,
                    Some(n) => loads.get(&n).copied(),
                    None => None,
                };
                CpuCoreReading {
                    id,
                    core,
                    temp_c: Some(temp_c),
                    load_percent,
                }
            })
            .collect();
        cores.sort_by_key(|core| core_sort_key(&core.id));
        cores
    }

    /// One row per DRM card with a backing device (virtual outputs skipped).
    /// NVIDIA temp/load come from `nvidia-smi`; Intel i915 exposes neither a
    /// hwmon node nor engine busy counters on this kernel, so its row stays
    /// `None`/`None` by design rather than via a second subprocess scraper.
    pub fn read_gpus(&self) -> Vec<GpuReading> {
        if let Ok(cache) = self.gpu_cache.lock() {
            if let Some((at, gpus)) = cache.as_ref() {
                if at.elapsed().as_secs() < 2 {
                    return gpus.clone();
                }
            }
        }
        let gpus = self.probe_gpus();
        if let Ok(mut cache) = self.gpu_cache.lock() {
            *cache = Some((Instant::now(), gpus.clone()));
        }
        gpus
    }

    fn coretemp_readings(&self) -> Vec<(String, Option<u32>, f32)> {
        let mut out = Vec::new();
        let entries = match fs::read_dir(self.rooted("/sys/class/hwmon")) {
            Ok(entries) => entries,
            Err(_) => return out,
        };
        let mut hwmons: Vec<_> = entries.flatten().map(|entry| entry.path()).collect();
        hwmons.sort();
        for hwmon in hwmons {
            if read_trimmed_path(&hwmon.join("name")).as_deref() != Some("coretemp") {
                continue;
            }
            let mut inputs: Vec<_> = match fs::read_dir(&hwmon) {
                Ok(entries) => entries
                    .flatten()
                    .map(|entry| entry.path())
                    .filter(|path| {
                        path.file_name().and_then(|n| n.to_str()).is_some_and(|n| {
                            n.starts_with("temp")
                                && n.ends_with("_input")
                                && n["temp".len()..n.len() - "_input".len()]
                                    .chars()
                                    .all(|c| c.is_ascii_digit())
                        })
                    })
                    .collect(),
                Err(_) => continue,
            };
            inputs.sort();
            for input in inputs {
                let stem = input
                    .file_name()
                    .and_then(|name| name.to_str())
                    .and_then(|name| name.strip_suffix("_input"))
                    .unwrap_or("");
                let label = read_trimmed_path(&hwmon.join(format!("{stem}_label")))
                    .unwrap_or_else(|| stem.to_string());
                if let Some(millidegrees) = read_num_path::<i64>(&input) {
                    let core = label.strip_prefix("Core ").and_then(|n| n.parse().ok());
                    out.push((label, core, millidegrees as f32 / 1000.0));
                }
            }
        }
        out
    }

    fn cpu_load_percent(&self) -> (std::collections::HashMap<u32, f32>, Option<f32>) {
        use std::collections::HashMap;
        let current = self.proc_stat_snapshot();
        let mut loads = HashMap::new();
        let mut aggregate = None;
        if let (Some(curr), Ok(mut prev)) = (current, self.cpu_prev.lock()) {
            if let Some(p) = prev.as_ref() {
                aggregate = load_fraction(
                    p.aggregate.0,
                    p.aggregate.1,
                    curr.aggregate.0,
                    curr.aggregate.1,
                );
                for (thread, idle, total) in &curr.cores {
                    if let Some((prev_idle, prev_total)) = p
                        .cores
                        .iter()
                        .find(|(t, _, _)| t == thread)
                        .map(|(_, i, t)| (*i, *t))
                    {
                        if let Some(pct) = load_fraction(prev_idle, prev_total, *idle, *total) {
                            loads.insert(*thread, pct);
                        }
                    }
                }
            }
            *prev = Some(curr);
        }
        (loads, aggregate)
    }

    fn proc_stat_snapshot(&self) -> Option<CpuStatSnapshot> {
        fs::read_to_string(self.rooted("/proc/stat"))
            .ok()
            .map(|content| parse_proc_stat(&content))
    }

    fn probe_gpus(&self) -> Vec<GpuReading> {
        let entries = match fs::read_dir(self.rooted("/sys/class/drm")) {
            Ok(entries) => entries,
            Err(_) => return Vec::new(),
        };
        let mut paths: Vec<_> = entries.flatten().map(|entry| entry.path()).collect();
        paths.sort();
        let mut vendors: Vec<String> = Vec::new();
        for path in paths {
            let name = path.file_name().and_then(|n| n.to_str()).unwrap_or("");
            let Some(index) = name.strip_prefix("card") else {
                continue;
            };
            if index.is_empty() || !index.chars().all(|c| c.is_ascii_digit()) {
                continue;
            }
            // Cards without a device link are virtual outputs.
            let Some(vendor) = read_trimmed_path(&path.join("device/vendor")) else {
                continue;
            };
            vendors.push(vendor);
        }
        // Mirror the rgb_status hermeticity rule: no subprocesses under a
        // fake sysroot, so tests never execute the real nvidia-smi.
        let mut smi = if self.sysroot() == Path::new("/") {
            query_nvidia_smi().into_iter()
        } else {
            Vec::new().into_iter()
        };
        vendors
            .into_iter()
            .map(|vendor| match vendor.as_str() {
                "0x10de" => match smi.next() {
                    Some((name, temp_c, load_percent)) => GpuReading {
                        name,
                        vendor: "nvidia".into(),
                        temp_c: Some(temp_c),
                        load_percent: Some(load_percent),
                    },
                    None => GpuReading {
                        name: "NVIDIA discrete graphics".into(),
                        vendor: "nvidia".into(),
                        temp_c: None,
                        load_percent: None,
                    },
                },
                "0x8086" => GpuReading {
                    name: "Intel integrated graphics".into(),
                    vendor: "intel".into(),
                    temp_c: None,
                    load_percent: None,
                },
                other => GpuReading {
                    name: format!("Unknown GPU ({other})"),
                    vendor: "unknown".into(),
                    temp_c: None,
                    load_percent: None,
                },
            })
            .collect()
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

    pub fn set_fan_mode(&self, mode: &str) -> Result<FanModeState, FanModeError> {
        let base = "/sys/devices/platform/msi-ec";
        let dir = self.rooted(base);
        let mode_path = dir.join("fan_mode");
        let available = self.read_words(format!("{base}/available_fan_modes"));
        if !mode_path.is_file() || available.is_empty() {
            return Err(FanModeError::Unavailable);
        }
        if !available.iter().any(|candidate| candidate == mode) {
            return Err(FanModeError::InvalidMode {
                mode: mode.to_owned(),
                available,
            });
        }
        let previous = self.read_trimmed(format!("{base}/fan_mode"));

        if let Err(operation) = fs::write(&mode_path, format!("{mode}\n")) {
            return Err(fan_mode_rollback_error(
                &dir,
                previous,
                FanModeError::Io(operation),
            ));
        }

        let applied = self.read_trimmed(format!("{base}/fan_mode"));
        if applied.as_deref() != Some(mode) {
            return Err(fan_mode_rollback_error(
                &dir,
                previous,
                FanModeError::Verification {
                    applied,
                    expected: mode.to_owned(),
                },
            ));
        }

        Ok(FanModeState {
            fan_mode: applied,
            available_fan_modes: available,
        })
    }

    pub fn set_cooler_boost(&self, enabled: bool) -> Result<CoolerBoostState, CoolerBoostError> {
        let base = "/sys/devices/platform/msi-ec";
        let dir = self.rooted(base);
        let boost_path = dir.join("cooler_boost");
        if !boost_path.is_file() {
            return Err(CoolerBoostError::Unavailable);
        }
        let previous = self.read_on_off(format!("{base}/cooler_boost"));
        let value = if enabled { "on" } else { "off" };

        if let Err(operation) = fs::write(&boost_path, format!("{value}\n")) {
            return Err(cooler_boost_rollback_error(
                &dir,
                previous,
                CoolerBoostError::Io(operation),
            ));
        }

        let applied = self.read_on_off(format!("{base}/cooler_boost"));
        if applied != Some(enabled) {
            return Err(cooler_boost_rollback_error(
                &dir,
                previous,
                CoolerBoostError::Verification {
                    applied,
                    expected: enabled,
                },
            ));
        }

        Ok(CoolerBoostState {
            cooler_boost: applied,
        })
    }

    pub fn set_super_battery(&self, enabled: bool) -> Result<SuperBatteryState, SuperBatteryError> {
        let base = "/sys/devices/platform/msi-ec";
        let dir = self.rooted(base);
        let battery_path = dir.join("super_battery");
        if !battery_path.is_file() {
            return Err(SuperBatteryError::Unavailable);
        }
        let previous = self.read_on_off(format!("{base}/super_battery"));
        let value = if enabled { "on" } else { "off" };

        if let Err(operation) = fs::write(&battery_path, format!("{value}\n")) {
            return Err(super_battery_rollback_error(
                &dir,
                previous,
                SuperBatteryError::Io(operation),
            ));
        }

        let applied = self.read_on_off(format!("{base}/super_battery"));
        if applied != Some(enabled) {
            return Err(super_battery_rollback_error(
                &dir,
                previous,
                SuperBatteryError::Verification {
                    applied,
                    expected: enabled,
                },
            ));
        }

        Ok(SuperBatteryState {
            super_battery: applied,
        })
    }

    pub fn set_webcam(&self, enabled: bool) -> Result<WebcamState, EcAttrError> {
        let value = if enabled { "on" } else { "off" };
        self.set_ec_text("webcam", value, &["on", "off"])?;
        Ok(WebcamState {
            webcam: self.read_on_off("/sys/devices/platform/msi-ec/webcam"),
        })
    }

    pub fn set_webcam_block(&self, enabled: bool) -> Result<WebcamBlockState, EcAttrError> {
        let value = if enabled { "on" } else { "off" };
        self.set_ec_text("webcam_block", value, &["on", "off"])?;
        Ok(WebcamBlockState {
            webcam_block: self.read_on_off("/sys/devices/platform/msi-ec/webcam_block"),
        })
    }

    pub fn set_fn_key(&self, position: &str) -> Result<FnWinState, EcAttrError> {
        self.set_ec_text("fn_key", position, &["left", "right"])?;
        Ok(FnWinState {
            fn_key: self.read_trimmed("/sys/devices/platform/msi-ec/fn_key"),
            win_key: self.read_trimmed("/sys/devices/platform/msi-ec/win_key"),
        })
    }

    fn set_ec_text(
        &self,
        attr: &'static str,
        value: &str,
        allowed: &[&str],
    ) -> Result<String, EcAttrError> {
        let dir = self.rooted("/sys/devices/platform/msi-ec");
        let path = dir.join(attr);
        if !path.is_file() {
            return Err(EcAttrError::Unavailable { attr });
        }
        if !allowed.contains(&value) {
            return Err(EcAttrError::InvalidValue {
                attr,
                value: value.to_owned(),
            });
        }
        let previous = self.read_trimmed(format!("/sys/devices/platform/msi-ec/{attr}"));
        if let Err(error) = fs::write(&path, format!("{value}\n")) {
            return Err(ec_attr_rollback(
                &dir,
                attr,
                previous,
                EcAttrError::Io { attr, error },
            ));
        }
        let applied = self.read_trimmed(format!("/sys/devices/platform/msi-ec/{attr}"));
        if applied.as_deref() != Some(value) {
            return Err(ec_attr_rollback(
                &dir,
                attr,
                previous,
                EcAttrError::Verification {
                    attr,
                    applied,
                    expected: value.to_owned(),
                },
            ));
        }
        Ok(value.to_owned())
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

fn restore_fan_mode(dir: &Path, previous: Option<String>) -> io::Result<()> {
    match previous {
        Some(previous) => fs::write(dir.join("fan_mode"), format!("{previous}\n")),
        None => Ok(()),
    }
}

fn fan_mode_rollback_error(
    dir: &Path,
    previous: Option<String>,
    operation: FanModeError,
) -> FanModeError {
    match restore_fan_mode(dir, previous) {
        Ok(()) => operation,
        Err(rollback) => FanModeError::Rollback {
            operation: operation.to_string(),
            rollback,
        },
    }
}

fn restore_cooler_boost(dir: &Path, previous: Option<bool>) -> io::Result<()> {
    match previous {
        Some(previous) => {
            let value = if previous { "on" } else { "off" };
            fs::write(dir.join("cooler_boost"), format!("{value}\n"))
        }
        None => Ok(()),
    }
}

fn cooler_boost_rollback_error(
    dir: &Path,
    previous: Option<bool>,
    operation: CoolerBoostError,
) -> CoolerBoostError {
    match restore_cooler_boost(dir, previous) {
        Ok(()) => operation,
        Err(rollback) => CoolerBoostError::Rollback {
            operation: operation.to_string(),
            rollback,
        },
    }
}

fn restore_ec_attr(dir: &Path, attr: &str, previous: Option<String>) -> io::Result<()> {
    match previous {
        Some(previous) => fs::write(dir.join(attr), format!("{previous}\n")),
        None => Ok(()),
    }
}

fn ec_attr_rollback(
    dir: &Path,
    attr: &'static str,
    previous: Option<String>,
    operation: EcAttrError,
) -> EcAttrError {
    match restore_ec_attr(dir, attr, previous) {
        Ok(()) => operation,
        Err(rollback) => EcAttrError::Rollback {
            attr,
            operation: operation.to_string(),
            rollback,
        },
    }
}

fn restore_super_battery(dir: &Path, previous: Option<bool>) -> io::Result<()> {
    match previous {
        Some(previous) => {
            let value = if previous { "on" } else { "off" };
            fs::write(dir.join("super_battery"), format!("{value}\n"))
        }
        None => Ok(()),
    }
}

fn super_battery_rollback_error(
    dir: &Path,
    previous: Option<bool>,
    operation: SuperBatteryError,
) -> SuperBatteryError {
    match restore_super_battery(dir, previous) {
        Ok(()) => operation,
        Err(rollback) => SuperBatteryError::Rollback {
            operation: operation.to_string(),
            rollback,
        },
    }
}

/// Sorts sensor rows package-first, then numerically: glob order would
/// put `temp10` before `temp2`.
fn core_sort_key(id: &str) -> (u8, u32) {
    if id.starts_with("Package") {
        (0, 0)
    } else if let Some(number) = id.strip_prefix("Core ").and_then(|n| n.parse().ok()) {
        (1, number)
    } else {
        (2, 0)
    }
}

/// Parses aggregate + per-thread (idle, total) jiffy counters from
/// /proc/stat text. idle = idle + iowait, total = all fields.
fn parse_proc_stat(content: &str) -> CpuStatSnapshot {
    let mut aggregate = (0u64, 0u64);
    let mut cores = Vec::new();
    for line in content.lines() {
        let mut fields = line.split_whitespace();
        let label = fields.next().unwrap_or("");
        let numbers: Vec<u64> = fields.filter_map(|field| field.parse().ok()).collect();
        if numbers.is_empty() {
            continue;
        }
        let total: u64 = numbers.iter().sum();
        let idle = numbers.get(3).copied().unwrap_or(0) + numbers.get(4).copied().unwrap_or(0);
        if label == "cpu" {
            aggregate = (idle, total);
        } else if let Some(thread) = label
            .strip_prefix("cpu")
            .and_then(|n| n.parse::<u32>().ok())
        {
            cores.push((thread, idle, total));
        }
    }
    CpuStatSnapshot { aggregate, cores }
}

/// Busy fraction between two counter samples as 0-100. `None` when the
/// counters did not advance, so a stuck clock never reports a fake load.
fn load_fraction(prev_idle: u64, prev_total: u64, idle: u64, total: u64) -> Option<f32> {
    let delta_idle = idle.saturating_sub(prev_idle);
    let delta_total = total.saturating_sub(prev_total);
    if delta_total == 0 {
        return None;
    }
    Some((delta_total - delta_idle) as f32 / delta_total as f32 * 100.0)
}

/// One nvidia-smi call with a hard 3s timeout. A hung driver must never
/// hang the D-Bus refresh path, so every failure mode yields no rows.
fn query_nvidia_smi() -> Vec<(String, i32, f32)> {
    let (tx, rx) = std::sync::mpsc::channel();
    std::thread::spawn(move || {
        let output = std::process::Command::new("nvidia-smi")
            .args([
                "--query-gpu=name,temperature.gpu,utilization.gpu",
                "--format=csv,noheader,nounits",
            ])
            .output()
            .ok();
        let _ = tx.send(output);
    });
    let Ok(Some(output)) = rx.recv_timeout(std::time::Duration::from_secs(3)) else {
        return Vec::new();
    };
    if !output.status.success() {
        return Vec::new();
    }
    String::from_utf8_lossy(&output.stdout)
        .lines()
        .filter_map(|line| {
            // "NVIDIA GeForce RTX 4070 Laptop GPU, 47, 0"
            let (head, util) = line.trim_end().rsplit_once(',')?;
            let (name, temp) = head.rsplit_once(',')?;
            Some((
                name.trim().to_string(),
                temp.trim().parse().ok()?,
                util.trim().parse().ok()?,
            ))
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::{SystemTime, UNIX_EPOCH};

    #[test]
    fn cpu_cores_join_temps_and_load() {
        let root = std::env::temp_dir().join(format!(
            "msi-linux-center-cpucores-{}-{}",
            std::process::id(),
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        let hwmon = root.join("sys/class/hwmon/hwmon3");
        fs::create_dir_all(&hwmon).unwrap();
        fs::write(hwmon.join("name"), "coretemp\n").unwrap();
        fs::write(hwmon.join("temp1_label"), "Package id 0\n").unwrap();
        fs::write(hwmon.join("temp1_input"), "65000\n").unwrap();
        fs::write(hwmon.join("temp2_label"), "Core 0\n").unwrap();
        fs::write(hwmon.join("temp2_input"), "59000\n").unwrap();
        // A decoy driver must not leak into the rows.
        let other = root.join("sys/class/hwmon/hwmon4");
        fs::create_dir_all(&other).unwrap();
        fs::write(other.join("name"), "acpitz\n").unwrap();
        fs::write(other.join("temp1_label"), "acpitz\n").unwrap();
        fs::write(other.join("temp1_input"), "27000\n").unwrap();
        let proc = root.join("proc");
        fs::create_dir_all(&proc).unwrap();
        fs::write(
            proc.join("stat"),
            "cpu  100 0 100 800 0 0 0 0 0 0\ncpu0 50 0 50 400 0 0 0 0 0 0\n",
        )
        .unwrap();

        let hardware = HardwarePaths::new(&root);
        let first = hardware.read_cpu_cores();
        assert_eq!(first.len(), 2);
        assert!(first.iter().all(|core| core.load_percent.is_none()));

        fs::write(
            proc.join("stat"),
            "cpu  110 0 110 830 0 0 0 0 0 0\ncpu0 55 0 55 410 0 0 0 0 0 0\n",
        )
        .unwrap();
        let second = hardware.read_cpu_cores();
        assert_eq!(second[0].id, "Package id 0");
        // Aggregate: total 1000->1050, idle 800->830: busy 20/50 = 40%.
        assert!((second[0].load_percent.unwrap() - 40.0).abs() < 0.01);
        assert_eq!(second[1].id, "Core 0");
        assert!((second[1].temp_c.unwrap() - 59.0).abs() < 0.01);
        // cpu0: total 500->520, idle 400->410: busy 10/20 = 50%.
        assert!((second[1].load_percent.unwrap() - 50.0).abs() < 0.01);

        fs::remove_dir_all(&root).unwrap();
    }

    #[test]
    fn cpu_cores_and_gpus_degrade_gracefully() {
        let root = std::env::temp_dir().join(format!(
            "msi-linux-center-cpucores-bad-{}-{}",
            std::process::id(),
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        let proc = root.join("proc");
        fs::create_dir_all(&proc).unwrap();
        fs::write(proc.join("stat"), "not a stat file\n").unwrap();

        let hardware = HardwarePaths::new(&root);
        assert!(hardware.read_cpu_cores().is_empty());
        // Fake sysroot: no DRM tree, and nvidia-smi is never executed.
        assert!(hardware.read_gpus().is_empty());

        fs::remove_dir_all(&root).unwrap();
    }

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

    #[test]
    fn writes_and_validates_fan_mode() {
        let root = std::env::temp_dir().join(format!(
            "msi-linux-center-fanmode-{}-{}",
            std::process::id(),
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        let msi_ec = root.join("sys/devices/platform/msi-ec");
        fs::create_dir_all(&msi_ec).unwrap();
        fs::write(
            msi_ec.join("available_fan_modes"),
            "auto\nsilent\nadvanced\n",
        )
        .unwrap();
        fs::write(msi_ec.join("fan_mode"), "auto\n").unwrap();

        let hardware = HardwarePaths::new(&root);
        let applied = hardware.set_fan_mode("silent").unwrap();
        assert_eq!(applied.fan_mode.as_deref(), Some("silent"));
        assert_eq!(
            applied.available_fan_modes,
            vec!["auto", "silent", "advanced"]
        );
        assert!(matches!(
            hardware.set_fan_mode("turbo"),
            Err(FanModeError::InvalidMode { .. })
        ));
        assert_eq!(
            fs::read_to_string(msi_ec.join("fan_mode")).unwrap().trim(),
            "silent"
        );

        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn writes_and_validates_cooler_boost() {
        let root = std::env::temp_dir().join(format!(
            "msi-linux-center-coolerboost-{}-{}",
            std::process::id(),
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        let msi_ec = root.join("sys/devices/platform/msi-ec");
        fs::create_dir_all(&msi_ec).unwrap();
        fs::write(msi_ec.join("cooler_boost"), "off\n").unwrap();

        let hardware = HardwarePaths::new(&root);
        let applied = hardware.set_cooler_boost(true).unwrap();
        assert_eq!(applied.cooler_boost, Some(true));
        assert_eq!(
            fs::read_to_string(msi_ec.join("cooler_boost"))
                .unwrap()
                .trim(),
            "on"
        );
        assert!(matches!(
            hardware.set_cooler_boost(false).unwrap().cooler_boost,
            Some(false)
        ));

        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn writes_and_validates_super_battery() {
        let root = std::env::temp_dir().join(format!(
            "msi-linux-center-superbattery-{}-{}",
            std::process::id(),
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        let msi_ec = root.join("sys/devices/platform/msi-ec");
        fs::create_dir_all(&msi_ec).unwrap();
        fs::write(msi_ec.join("super_battery"), "off\n").unwrap();

        let hardware = HardwarePaths::new(&root);
        let applied = hardware.set_super_battery(true).unwrap();
        assert_eq!(applied.super_battery, Some(true));
        assert_eq!(
            fs::read_to_string(msi_ec.join("super_battery"))
                .unwrap()
                .trim(),
            "on"
        );
        assert!(matches!(
            hardware.set_super_battery(false).unwrap().super_battery,
            Some(false)
        ));

        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn writes_and_validates_webcam_and_fn_key() {
        let root = std::env::temp_dir().join(format!(
            "msi-linux-center-periph-{}-{}",
            std::process::id(),
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        let msi_ec = root.join("sys/devices/platform/msi-ec");
        fs::create_dir_all(&msi_ec).unwrap();
        fs::write(msi_ec.join("webcam"), "on\n").unwrap();
        fs::write(msi_ec.join("webcam_block"), "off\n").unwrap();
        fs::write(msi_ec.join("fn_key"), "right\n").unwrap();
        fs::write(msi_ec.join("win_key"), "left\n").unwrap();

        let hardware = HardwarePaths::new(&root);
        assert_eq!(hardware.set_webcam(false).unwrap().webcam, Some(false));
        assert_eq!(
            hardware.set_webcam_block(true).unwrap().webcam_block,
            Some(true)
        );
        let keys = hardware.set_fn_key("left").unwrap();
        assert_eq!(keys.fn_key.as_deref(), Some("left"));
        assert!(matches!(
            hardware.set_fn_key("up"),
            Err(EcAttrError::InvalidValue { .. })
        ));

        fs::remove_dir_all(root).unwrap();
    }
}
