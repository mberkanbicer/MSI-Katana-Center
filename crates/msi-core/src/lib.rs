use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SupportTier {
    Unknown,
    Documented,
    Experimental,
    Verified,
}

impl std::fmt::Display for SupportTier {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let s = match self {
            Self::Unknown => "unknown",
            Self::Documented => "documented",
            Self::Experimental => "experimental",
            Self::Verified => "verified",
        };
        f.write_str(s)
    }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct DeviceIdentity {
    pub sys_vendor: Option<String>,
    pub product_name: Option<String>,
    pub product_version: Option<String>,
    pub board_name: Option<String>,
    pub board_version: Option<String>,
    pub bios_version: Option<String>,
    pub bios_date: Option<String>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct EcStatus {
    pub firmware: Option<String>,
    pub shift_mode: Option<String>,
    pub available_shift_modes: Vec<String>,
    pub fan_mode: Option<String>,
    pub available_fan_modes: Vec<String>,
    pub cooler_boost: Option<bool>,
    pub super_battery: Option<bool>,
    pub webcam: Option<bool>,
    pub webcam_block: Option<bool>,
    /// Fn key position from msi-ec (`left` / `right`); preserved verbatim.
    pub fn_key: Option<String>,
    /// Win key position from msi-ec (`left` / `right`); preserved verbatim.
    pub win_key: Option<String>,
    pub firmware_date: Option<String>,
    pub cpu_temperature_c: Option<i32>,
    pub gpu_temperature_c: Option<i32>,
    /// Value exported by msi-ec. This is kept semantically separate from RPM.
    pub cpu_fan_level: Option<u32>,
    pub gpu_fan_level: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FanReading {
    pub channel: String,
    pub rpm: u32,
    pub source: String,
}

/// One CPU temperature sensor row (typically `coretemp` `Core N` or
/// `Package id 0`). `core` is the parsed core number when the label
/// carries one; load needs two samples, so it is `None` on first read.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CpuCoreReading {
    pub id: String,
    pub core: Option<u32>,
    pub temp_c: Option<f32>,
    pub load_percent: Option<f32>,
}

/// One DRM card with a backing device. Temp/load stay `None` when the
/// kernel exposes no source (e.g. Intel i915 on this kernel, or a
/// hung/absent `nvidia-smi`).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GpuReading {
    pub name: String,
    pub vendor: String,
    pub temp_c: Option<i32>,
    pub load_percent: Option<f32>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct BatteryStatus {
    pub name: Option<String>,
    pub status: Option<String>,
    pub capacity_percent: Option<u8>,
    pub charge_start_percent: Option<u8>,
    pub charge_end_percent: Option<u8>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct FanModeState {
    pub fan_mode: Option<String>,
    pub available_fan_modes: Vec<String>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct CoolerBoostState {
    pub cooler_boost: Option<bool>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct SuperBatteryState {
    pub super_battery: Option<bool>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct WebcamState {
    pub webcam: Option<bool>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct WebcamBlockState {
    pub webcam_block: Option<bool>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct FnWinState {
    pub fn_key: Option<String>,
    pub win_key: Option<String>,
}

/// Read-only identity of the detected RGB HID controller (if any).
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RgbStatus {
    pub controller_name: Option<String>,
    pub controller_serial: Option<String>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct CapabilitySet {
    pub ec_firmware: bool,
    pub ec_temperatures: bool,
    pub fan_rpm: bool,
    pub fan_level: bool,
    pub fan_mode: bool,
    pub cooler_boost: bool,
    pub performance_mode: bool,
    pub super_battery: bool,
    pub battery_threshold: bool,
    pub rgb: bool,
    pub custom_fan_curve: bool,
    pub mux: bool,
    #[serde(default)]
    pub webcam: bool,
    #[serde(default)]
    pub fn_win: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HardwareProvenance {
    pub feature: String,
    pub model_firmware_scope: String,
    pub sources: Vec<String>,
    pub local_verification: LocalVerification,
    pub writes_tested: bool,
    pub confidence: SupportTier,
    pub notes: Option<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum LocalVerification {
    Unverified,
    Documented,
    VerifiedReadOnly,
    VerifiedWrite,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct BackendAvailability {
    pub msi_ec: bool,
    pub msi_wmi_platform: bool,
    pub power_supply_battery: bool,
    pub rgb_hid: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CapabilityAvailability {
    Unavailable,
    SupportedByModel,
    BackendDetected,
    Experimental,
    AvailableNow,
}

impl std::fmt::Display for CapabilityAvailability {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(match self {
            Self::Unavailable => "unavailable",
            Self::SupportedByModel => "supported by model",
            Self::BackendDetected => "backend detected",
            Self::Experimental => "experimental",
            Self::AvailableNow => "available now",
        })
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RuntimeCapability {
    pub feature: String,
    pub declared_by_model: bool,
    pub backend_detected: bool,
    pub readable: bool,
    pub support_tier: SupportTier,
}

impl RuntimeCapability {
    pub fn availability(&self) -> CapabilityAvailability {
        if self.readable {
            CapabilityAvailability::AvailableNow
        } else if self.declared_by_model && self.support_tier == SupportTier::Experimental {
            CapabilityAvailability::Experimental
        } else if self.backend_detected {
            CapabilityAvailability::BackendDetected
        } else if self.declared_by_model {
            CapabilityAvailability::SupportedByModel
        } else {
            CapabilityAvailability::Unavailable
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeviceProfile {
    pub id: String,
    pub marketing_name: String,
    pub product_names: Vec<String>,
    pub board_names: Vec<String>,
    pub ec_firmware_prefixes: Vec<String>,
    pub exact_verified_firmware: Vec<String>,
    pub support_tier: SupportTier,
    pub rgb_usb_vid: Option<String>,
    pub rgb_usb_pid: Option<String>,
    pub capabilities: CapabilitySet,
    #[serde(default)]
    pub provenance: Vec<HardwareProvenance>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SystemStatus {
    pub identity: DeviceIdentity,
    pub matched_profile: Option<DeviceProfile>,
    pub backends: BackendAvailability,
    pub runtime_capabilities: Vec<RuntimeCapability>,
    pub ec: EcStatus,
    pub fans: Vec<FanReading>,
    pub battery: BatteryStatus,
    pub rgb: RgbStatus,
    pub cpu_cores: Vec<CpuCoreReading>,
    pub gpus: Vec<GpuReading>,
}

#[cfg(test)]
mod tests {
    use super::*;

    fn cap(readable: bool, declared: bool, detected: bool, tier: SupportTier) -> RuntimeCapability {
        RuntimeCapability {
            feature: "x".into(),
            declared_by_model: declared,
            backend_detected: detected,
            readable,
            support_tier: tier,
        }
    }

    #[test]
    fn availability_priority() {
        assert!(matches!(
            cap(true, false, false, SupportTier::Unknown).availability(),
            CapabilityAvailability::AvailableNow
        ));
        assert!(matches!(
            cap(false, true, false, SupportTier::Experimental).availability(),
            CapabilityAvailability::Experimental
        ));
        assert!(matches!(
            cap(false, false, true, SupportTier::Documented).availability(),
            CapabilityAvailability::BackendDetected
        ));
        assert!(matches!(
            cap(false, true, false, SupportTier::Verified).availability(),
            CapabilityAvailability::SupportedByModel
        ));
        assert!(matches!(
            cap(false, false, false, SupportTier::Unknown).availability(),
            CapabilityAvailability::Unavailable
        ));
        // Readable wins even over an experimental declaration.
        assert!(matches!(
            cap(true, true, true, SupportTier::Experimental).availability(),
            CapabilityAvailability::AvailableNow
        ));
    }

    #[test]
    fn sensor_row_json_contract() {
        // The Qt client reads these exact keys; renaming breaks the UI.
        let core = CpuCoreReading {
            id: "Core 0".into(),
            core: Some(0),
            temp_c: Some(59.0),
            load_percent: None,
        };
        let value = serde_json::to_value(&core).unwrap();
        assert_eq!(value["id"], "Core 0");
        assert_eq!(value["temp_c"], 59.0);
        assert!(value["load_percent"].is_null());
        let gpu = GpuReading {
            name: "Intel integrated graphics".into(),
            vendor: "intel".into(),
            temp_c: None,
            load_percent: None,
        };
        let value = serde_json::to_value(&gpu).unwrap();
        assert_eq!(value["vendor"], "intel");
        assert!(value["temp_c"].is_null());
    }
}
