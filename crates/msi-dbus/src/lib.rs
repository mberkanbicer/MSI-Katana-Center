use msi_core::{
    BackendAvailability, BatteryStatus, CapabilitySet, DeviceProfile, EcStatus, FanReading,
    RuntimeCapability, SupportTier, SystemStatus,
};
use msi_device_db::DatabaseError;
use msi_hardware::{validate_battery_thresholds, FanModeError, HardwarePaths};
use serde::Serialize;
use std::collections::HashMap;
use std::fmt;
use std::io;
use std::path::PathBuf;
use std::sync::{Arc, RwLock};
use zbus::blocking::Connection;
use zbus::message::Header;
use zbus::object_server::SignalContext;
use zbus::zvariant::Value;

pub const BUS_NAME: &str = "org.msilinux.Center";
pub const ROOT_PATH: &str = "/org/msilinux/Center";
pub const SET_BATTERY_THRESHOLDS_ACTION: &str = "org.msilinux.Center.set-battery-thresholds";
pub const SET_FAN_MODE_ACTION: &str = "org.msilinux.Center.set-fan-mode";

#[derive(Debug)]
pub enum ServiceError {
    Io(io::Error),
    Database(DatabaseError),
    Bus(zbus::Error),
}

impl fmt::Display for ServiceError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Io(error) => write!(f, "hardware I/O error: {error}"),
            Self::Database(error) => error.fmt(f),
            Self::Bus(error) => write!(f, "D-Bus error: {error}"),
        }
    }
}

impl std::error::Error for ServiceError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Io(error) => Some(error),
            Self::Database(error) => Some(error),
            Self::Bus(error) => Some(error),
        }
    }
}

impl From<io::Error> for ServiceError {
    fn from(error: io::Error) -> Self {
        Self::Io(error)
    }
}

impl From<DatabaseError> for ServiceError {
    fn from(error: DatabaseError) -> Self {
        Self::Database(error)
    }
}

impl From<zbus::Error> for ServiceError {
    fn from(error: zbus::Error) -> Self {
        Self::Bus(error)
    }
}

pub fn collect_status() -> Result<SystemStatus, ServiceError> {
    collect_status_from(&HardwarePaths::default())
}

pub fn collect_status_at(root: impl Into<PathBuf>) -> Result<SystemStatus, ServiceError> {
    collect_status_from(&HardwarePaths::new(root))
}

pub fn request_battery_thresholds(start: u8, end: u8) -> Result<String, ServiceError> {
    let connection = Connection::system()?;
    let proxy = zbus::blocking::Proxy::new(
        &connection,
        BUS_NAME,
        ROOT_PATH,
        "org.msilinux.Center1.Device",
    )?;
    proxy
        .call("SetBatteryThresholds", &(start, end))
        .map_err(Into::into)
}

pub fn request_fan_mode(mode: &str) -> Result<String, ServiceError> {
    let connection = Connection::system()?;
    let proxy = zbus::blocking::Proxy::new(
        &connection,
        BUS_NAME,
        ROOT_PATH,
        "org.msilinux.Center1.Device",
    )?;
    proxy.call("SetFanMode", &(mode,)).map_err(Into::into)
}

fn collect_status_from(hw: &HardwarePaths) -> Result<SystemStatus, ServiceError> {
    let identity = hw.read_identity();
    let ec = hw.read_msi_ec();
    let fans = hw.read_msi_wmi_fans()?;
    let battery = hw.read_laptop_battery()?;
    let matched_profile = msi_device_db::match_device(&identity, ec.firmware.as_deref())?;
    let mut backends = hw.discover_backends()?;
    if let Some(profile) = &matched_profile {
        if let (Some(vendor), Some(product)) = (&profile.rgb_usb_vid, &profile.rgb_usb_pid) {
            backends.rgb_hid = hw.has_usb_device(vendor, product)?;
        }
    }
    let runtime_capabilities =
        runtime_capabilities(matched_profile.as_ref(), &backends, &ec, &fans, &battery);

    Ok(SystemStatus {
        identity,
        matched_profile,
        backends,
        runtime_capabilities,
        ec,
        fans,
        battery,
    })
}

fn runtime_capabilities(
    profile: Option<&DeviceProfile>,
    backends: &BackendAvailability,
    ec: &EcStatus,
    fans: &[FanReading],
    battery: &BatteryStatus,
) -> Vec<RuntimeCapability> {
    let declared = profile.map(|profile| &profile.capabilities);
    let tier = profile
        .map(|profile| profile.support_tier)
        .unwrap_or(SupportTier::Unknown);
    let capability =
        |feature: &str, declared: bool, backend_detected: bool, readable: bool| RuntimeCapability {
            feature: feature.into(),
            declared_by_model: declared,
            backend_detected,
            readable,
            support_tier: if declared { tier } else { SupportTier::Unknown },
        };
    let has = |select: fn(&CapabilitySet) -> bool| declared.is_some_and(select);

    vec![
        capability(
            "ec_firmware",
            has(|c| c.ec_firmware),
            backends.msi_ec,
            ec.firmware.is_some(),
        ),
        capability(
            "ec_temperatures",
            has(|c| c.ec_temperatures),
            backends.msi_ec,
            ec.cpu_temperature_c.is_some() || ec.gpu_temperature_c.is_some(),
        ),
        capability(
            "fan_rpm",
            has(|c| c.fan_rpm),
            backends.msi_wmi_platform,
            !fans.is_empty(),
        ),
        capability(
            "fan_level",
            has(|c| c.fan_level),
            backends.msi_ec,
            ec.cpu_fan_level.is_some() || ec.gpu_fan_level.is_some(),
        ),
        capability(
            "fan_mode",
            has(|c| c.fan_mode),
            backends.msi_ec,
            ec.fan_mode.is_some(),
        ),
        capability(
            "cooler_boost",
            has(|c| c.cooler_boost),
            backends.msi_ec,
            ec.cooler_boost.is_some(),
        ),
        capability(
            "performance_mode",
            has(|c| c.performance_mode),
            backends.msi_ec,
            ec.shift_mode.is_some(),
        ),
        capability(
            "super_battery",
            has(|c| c.super_battery),
            backends.msi_ec,
            ec.super_battery.is_some(),
        ),
        capability(
            "battery_threshold",
            has(|c| c.battery_threshold),
            backends.power_supply_battery,
            battery.charge_start_percent.is_some() || battery.charge_end_percent.is_some(),
        ),
        capability("rgb", has(|c| c.rgb), backends.rgb_hid, false),
        capability(
            "custom_fan_curve",
            has(|c| c.custom_fan_curve),
            false,
            false,
        ),
        capability("mux", has(|c| c.mux), false, false),
    ]
}

type SharedStatus = Arc<RwLock<SystemStatus>>;

struct DeviceInterface {
    status: SharedStatus,
    hardware: HardwarePaths,
    connection: zbus::Connection,
}

#[zbus::interface(name = "org.msilinux.Center1.Device")]
impl DeviceInterface {
    #[zbus(property, name = "Identity")]
    fn identity(&self) -> zbus::fdo::Result<String> {
        to_json(&snapshot(&self.status)?.identity)
    }

    #[zbus(property, name = "MatchedProfile")]
    fn matched_profile(&self) -> zbus::fdo::Result<String> {
        Ok(snapshot(&self.status)?
            .matched_profile
            .map(|profile| profile.id)
            .unwrap_or_default())
    }

    #[zbus(property, name = "SupportTier")]
    fn support_tier(&self) -> zbus::fdo::Result<String> {
        Ok(snapshot(&self.status)?
            .matched_profile
            .map(|profile| profile.support_tier.to_string())
            .unwrap_or_else(|| "unknown".into()))
    }

    #[zbus(property, name = "RuntimeCapabilities")]
    fn runtime_capabilities(&self) -> zbus::fdo::Result<String> {
        to_json(&snapshot(&self.status)?.runtime_capabilities)
    }

    async fn refresh(
        &self,
        #[zbus(signal_context)] context: SignalContext<'_>,
    ) -> zbus::fdo::Result<()> {
        let status = collect_status_from(&self.hardware).map_err(fdo_error)?;
        *self
            .status
            .write()
            .map_err(|_| zbus::fdo::Error::Failed("status lock poisoned".into()))? = status;
        Self::state_changed(&context)
            .await
            .map_err(|error| zbus::fdo::Error::Failed(error.to_string()))
    }

    async fn set_battery_thresholds(
        &self,
        start: u8,
        end: u8,
        #[zbus(header)] header: Header<'_>,
        #[zbus(signal_context)] context: SignalContext<'_>,
    ) -> zbus::fdo::Result<String> {
        validate_battery_thresholds(start, end)
            .map_err(|error| zbus::fdo::Error::InvalidArgs(error.to_string()))?;
        let current = snapshot(&self.status)?;
        require_battery_write_support(&current, battery_writes_enabled())?;
        let sender = header
            .sender()
            .ok_or_else(|| zbus::fdo::Error::AccessDenied("missing D-Bus sender".into()))?;
        authorize(
            &self.connection,
            sender.as_str(),
            SET_BATTERY_THRESHOLDS_ACTION,
        )
        .await?;

        let applied = self
            .hardware
            .set_battery_thresholds(start, end)
            .map_err(|error| zbus::fdo::Error::Failed(error.to_string()))?;
        {
            let mut status = self
                .status
                .write()
                .map_err(|_| zbus::fdo::Error::Failed("status lock poisoned".into()))?;
            status.battery = applied.clone();
            status.runtime_capabilities = runtime_capabilities(
                status.matched_profile.as_ref(),
                &status.backends,
                &status.ec,
                &status.fans,
                &status.battery,
            );
        }
        Self::state_changed(&context)
            .await
            .map_err(|error| zbus::fdo::Error::Failed(error.to_string()))?;
        to_json(&applied)
    }

    async fn set_fan_mode(
        &self,
        mode: String,
        #[zbus(header)] header: Header<'_>,
        #[zbus(signal_context)] context: SignalContext<'_>,
    ) -> zbus::fdo::Result<String> {
        let current = snapshot(&self.status)?;
        require_fan_mode_write_support(&current, fan_mode_writes_enabled())?;
        let sender = header
            .sender()
            .ok_or_else(|| zbus::fdo::Error::AccessDenied("missing D-Bus sender".into()))?;
        authorize(&self.connection, sender.as_str(), SET_FAN_MODE_ACTION).await?;

        let applied = self
            .hardware
            .set_fan_mode(&mode)
            .map_err(|error| match error {
                FanModeError::InvalidMode { .. } => {
                    zbus::fdo::Error::InvalidArgs(error.to_string())
                }
                other => zbus::fdo::Error::Failed(other.to_string()),
            })?;
        {
            let mut status = self
                .status
                .write()
                .map_err(|_| zbus::fdo::Error::Failed("status lock poisoned".into()))?;
            status.ec.fan_mode = applied.fan_mode.clone();
            status.ec.available_fan_modes = applied.available_fan_modes.clone();
            status.runtime_capabilities = runtime_capabilities(
                status.matched_profile.as_ref(),
                &status.backends,
                &status.ec,
                &status.fans,
                &status.battery,
            );
        }
        Self::state_changed(&context)
            .await
            .map_err(|error| zbus::fdo::Error::Failed(error.to_string()))?;
        to_json(&applied)
    }

    #[zbus(signal, name = "StateChanged")]
    async fn state_changed(context: &SignalContext<'_>) -> zbus::Result<()>;
}

struct SensorsInterface {
    status: SharedStatus,
}

#[zbus::interface(name = "org.msilinux.Center1.Sensors")]
impl SensorsInterface {
    #[zbus(property, name = "EcState")]
    fn ec_state(&self) -> zbus::fdo::Result<String> {
        to_json(&snapshot(&self.status)?.ec)
    }

    #[zbus(property, name = "FanRpm")]
    fn fan_rpm(&self) -> zbus::fdo::Result<String> {
        to_json(&snapshot(&self.status)?.fans)
    }

    #[zbus(property, name = "Battery")]
    fn battery(&self) -> zbus::fdo::Result<String> {
        to_json(&snapshot(&self.status)?.battery)
    }
}

pub fn run_system_daemon() -> Result<(), ServiceError> {
    let hardware = HardwarePaths::default();
    let status = Arc::new(RwLock::new(collect_status_from(&hardware)?));
    let connection = Connection::system()?;
    let authorization_connection = connection.inner().clone();
    connection.object_server().at(
        ROOT_PATH,
        DeviceInterface {
            status: Arc::clone(&status),
            hardware,
            connection: authorization_connection,
        },
    )?;
    connection
        .object_server()
        .at(ROOT_PATH, SensorsInterface { status })?;
    connection.request_name(BUS_NAME)?;

    loop {
        std::thread::park();
    }
}

fn battery_writes_enabled() -> bool {
    std::env::var("MSI_LINUX_CENTER_ENABLE_BATTERY_WRITES").as_deref() == Ok("1")
}

fn fan_mode_writes_enabled() -> bool {
    std::env::var("MSI_LINUX_CENTER_ENABLE_FAN_MODE_WRITES").as_deref() == Ok("1")
}

fn require_battery_write_support(status: &SystemStatus, enabled: bool) -> zbus::fdo::Result<()> {
    if !enabled {
        return Err(zbus::fdo::Error::NotSupported(
            "battery writes disabled; set MSI_LINUX_CENTER_ENABLE_BATTERY_WRITES=1 for local validation"
                .into(),
        ));
    }
    let profile = status
        .matched_profile
        .as_ref()
        .ok_or_else(|| zbus::fdo::Error::NotSupported("device profile unmatched".into()))?;
    let firmware = status
        .ec
        .firmware
        .as_ref()
        .ok_or_else(|| zbus::fdo::Error::NotSupported("EC firmware unavailable".into()))?;
    if !profile.capabilities.battery_threshold
        || !profile
            .exact_verified_firmware
            .iter()
            .any(|verified| verified == firmware)
        || !status.backends.power_supply_battery
    {
        return Err(zbus::fdo::Error::NotSupported(
            "battery writes require exact verified firmware and power_supply thresholds".into(),
        ));
    }
    Ok(())
}

fn require_fan_mode_write_support(status: &SystemStatus, enabled: bool) -> zbus::fdo::Result<()> {
    if !enabled {
        return Err(zbus::fdo::Error::NotSupported(
            "fan-mode writes disabled; set MSI_LINUX_CENTER_ENABLE_FAN_MODE_WRITES=1 for local validation"
                .into(),
        ));
    }
    let profile = status
        .matched_profile
        .as_ref()
        .ok_or_else(|| zbus::fdo::Error::NotSupported("device profile unmatched".into()))?;
    let firmware = status
        .ec
        .firmware
        .as_ref()
        .ok_or_else(|| zbus::fdo::Error::NotSupported("EC firmware unavailable".into()))?;
    if !profile.capabilities.fan_mode
        || !profile
            .exact_verified_firmware
            .iter()
            .any(|verified| verified == firmware)
        || !status.backends.msi_ec
    {
        return Err(zbus::fdo::Error::NotSupported(
            "fan-mode writes require exact verified firmware and the msi-ec backend".into(),
        ));
    }
    Ok(())
}

async fn authorize(
    connection: &zbus::Connection,
    sender: &str,
    action: &str,
) -> zbus::fdo::Result<()> {
    let proxy = zbus::Proxy::new(
        connection,
        "org.freedesktop.PolicyKit1",
        "/org/freedesktop/PolicyKit1/Authority",
        "org.freedesktop.PolicyKit1.Authority",
    )
    .await
    .map_err(|error| zbus::fdo::Error::Failed(error.to_string()))?;
    let subject = (
        "system-bus-name",
        HashMap::from([("name", Value::from(sender))]),
    );
    let details = HashMap::<&str, &str>::new();
    let (authorized, _, _): (bool, bool, HashMap<String, String>) = proxy
        .call("CheckAuthorization", &(subject, action, details, 1u32, ""))
        .await
        .map_err(|error| zbus::fdo::Error::Failed(error.to_string()))?;
    if authorized {
        Ok(())
    } else {
        Err(zbus::fdo::Error::AccessDenied(
            "battery threshold change not authorized".into(),
        ))
    }
}

fn snapshot(status: &SharedStatus) -> zbus::fdo::Result<SystemStatus> {
    status
        .read()
        .map(|status| status.clone())
        .map_err(|_| zbus::fdo::Error::Failed("status lock poisoned".into()))
}

fn to_json(value: &impl Serialize) -> zbus::fdo::Result<String> {
    // ponytail: JSON keeps the current phase small; use typed D-Bus records when client compatibility demands it.
    serde_json::to_string(value).map_err(|error| zbus::fdo::Error::Failed(error.to_string()))
}

fn fdo_error(error: ServiceError) -> zbus::fdo::Error {
    zbus::fdo::Error::Failed(error.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn battery_write_gate_requires_opt_in_and_exact_firmware() {
        let mut status = collect_status_at(
            PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../tests/fixtures/katana17-b13vgk"),
        )
        .unwrap();
        assert!(require_battery_write_support(&status, false).is_err());
        assert!(require_battery_write_support(&status, true).is_ok());

        status.ec.firmware = Some("17L5EMS1.999".into());
        assert!(require_battery_write_support(&status, true).is_err());
    }

    #[test]
    fn fan_mode_write_gate_requires_opt_in_and_exact_firmware() {
        let mut status = collect_status_at(
            PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../tests/fixtures/katana17-b13vgk"),
        )
        .unwrap();
        assert!(require_fan_mode_write_support(&status, false).is_err());
        assert!(require_fan_mode_write_support(&status, true).is_ok());

        status.ec.firmware = Some("17L5EMS1.999".into());
        assert!(require_fan_mode_write_support(&status, true).is_err());
    }
}
