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

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct BatteryStatus {
    pub name: Option<String>,
    pub status: Option<String>,
    pub capacity_percent: Option<u8>,
    pub charge_start_percent: Option<u8>,
    pub charge_end_percent: Option<u8>,
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
}
