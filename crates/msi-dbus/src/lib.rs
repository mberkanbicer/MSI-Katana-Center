use msi_core::{
    BackendAvailability, BatteryStatus, CapabilitySet, DeviceProfile, EcStatus, FanReading,
    RgbStatus, RuntimeCapability, SupportTier, SystemStatus,
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
pub const SET_COOLER_BOOST_ACTION: &str = "org.msilinux.Center.set-cooler-boost";
pub const SET_SUPER_BATTERY_ACTION: &str = "org.msilinux.Center.set-super-battery";
pub const SET_RGB_COLOR_ACTION: &str = "org.msilinux.Center.set-rgb-color";
pub const SET_RGB_SAVE_ACTION: &str = "org.msilinux.Center.set-rgb-save";

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

pub fn request_cooler_boost(enabled: bool) -> Result<String, ServiceError> {
    let connection = Connection::system()?;
    let proxy = zbus::blocking::Proxy::new(
        &connection,
        BUS_NAME,
        ROOT_PATH,
        "org.msilinux.Center1.Device",
    )?;
    proxy
        .call("SetCoolerBoost", &(enabled,))
        .map_err(Into::into)
}

pub fn request_super_battery(enabled: bool) -> Result<String, ServiceError> {
    let connection = Connection::system()?;
    let proxy = zbus::blocking::Proxy::new(
        &connection,
        BUS_NAME,
        ROOT_PATH,
        "org.msilinux.Center1.Device",
    )?;
    proxy
        .call("SetSuperBattery", &(enabled,))
        .map_err(Into::into)
}

pub fn request_rgb_color(zones: u8, r: u8, g: u8, b: u8) -> Result<String, ServiceError> {
    let connection = Connection::system()?;
    let proxy = zbus::blocking::Proxy::new(
        &connection,
        BUS_NAME,
        ROOT_PATH,
        "org.msilinux.Center1.Device",
    )?;
    proxy
        .call("SetRgbColor", &(zones, r, g, b))
        .map_err(Into::into)
}

pub fn request_rgb_effect(
    zones: u8,
    mode: u8,
    speed_centiseconds: u16,
    wave_direction: u8,
    colors: Vec<(u8, u8, u8)>,
) -> Result<String, ServiceError> {
    let connection = Connection::system()?;
    let proxy = zbus::blocking::Proxy::new(
        &connection,
        BUS_NAME,
        ROOT_PATH,
        "org.msilinux.Center1.Device",
    )?;
    proxy
        .call(
            "SetRgbEffect",
            &(zones, mode, speed_centiseconds, wave_direction, colors),
        )
        .map_err(Into::into)
}

pub fn request_rgb_save() -> Result<String, ServiceError> {
    let connection = Connection::system()?;
    let proxy = zbus::blocking::Proxy::new(
        &connection,
        BUS_NAME,
        ROOT_PATH,
        "org.msilinux.Center1.Device",
    )?;
    proxy.call("SaveRgbState", &()).map_err(Into::into)
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
    let rgb = rgb_status(&matched_profile);
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
        rgb,
    })
}

/// Read-only hidapi probe of the RGB controller declared by the profile.
/// Returns an empty status when no profile/vendor-product pair is declared
/// or the device cannot be opened (no usbfs access, device absent).
fn rgb_status(profile: &Option<DeviceProfile>) -> RgbStatus {
    let Some(profile) = profile else {
        return RgbStatus::default();
    };
    let (Some(vendor), Some(product)) = (&profile.rgb_usb_vid, &profile.rgb_usb_pid) else {
        return RgbStatus::default();
    };
    let Ok(vendor_id) = u16::from_str_radix(vendor, 16) else {
        return RgbStatus::default();
    };
    let Ok(product_id) = u16::from_str_radix(product, 16) else {
        return RgbStatus::default();
    };
    match msi_hardware::rgb::probe_rgb_controller(vendor_id, product_id) {
        Some(info) => RgbStatus {
            controller_name: Some(info.name),
            controller_serial: info.serial,
        },
        None => RgbStatus::default(),
    }
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

    #[zbus(property, name = "RgbController")]
    fn rgb_controller(&self) -> zbus::fdo::Result<String> {
        to_json(&snapshot(&self.status)?.rgb)
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

    async fn set_cooler_boost(
        &self,
        enabled: bool,
        #[zbus(header)] header: Header<'_>,
        #[zbus(signal_context)] context: SignalContext<'_>,
    ) -> zbus::fdo::Result<String> {
        let current = snapshot(&self.status)?;
        require_cooler_boost_write_support(&current, cooler_boost_writes_enabled())?;
        let sender = header
            .sender()
            .ok_or_else(|| zbus::fdo::Error::AccessDenied("missing D-Bus sender".into()))?;
        authorize(&self.connection, sender.as_str(), SET_COOLER_BOOST_ACTION).await?;

        let applied = self
            .hardware
            .set_cooler_boost(enabled)
            .map_err(|error| zbus::fdo::Error::Failed(error.to_string()))?;
        {
            let mut status = self
                .status
                .write()
                .map_err(|_| zbus::fdo::Error::Failed("status lock poisoned".into()))?;
            status.ec.cooler_boost = applied.cooler_boost;
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

    async fn set_super_battery(
        &self,
        enabled: bool,
        #[zbus(header)] header: Header<'_>,
        #[zbus(signal_context)] context: SignalContext<'_>,
    ) -> zbus::fdo::Result<String> {
        let current = snapshot(&self.status)?;
        require_super_battery_write_support(&current, super_battery_writes_enabled())?;
        let sender = header
            .sender()
            .ok_or_else(|| zbus::fdo::Error::AccessDenied("missing D-Bus sender".into()))?;
        authorize(&self.connection, sender.as_str(), SET_SUPER_BATTERY_ACTION).await?;

        let applied = self
            .hardware
            .set_super_battery(enabled)
            .map_err(|error| zbus::fdo::Error::Failed(error.to_string()))?;
        {
            let mut status = self
                .status
                .write()
                .map_err(|_| zbus::fdo::Error::Failed("status lock poisoned".into()))?;
            status.ec.super_battery = applied.super_battery;
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

    async fn set_rgb_color(
        &self,
        zones: u8,
        r: u8,
        g: u8,
        b: u8,
        #[zbus(header)] header: Header<'_>,
    ) -> zbus::fdo::Result<String> {
        let current = snapshot(&self.status)?;
        require_rgb_write_support(&current, rgb_writes_enabled())?;
        let sender = header
            .sender()
            .ok_or_else(|| zbus::fdo::Error::AccessDenied("missing D-Bus sender".into()))?;
        authorize(&self.connection, sender.as_str(), SET_RGB_COLOR_ACTION).await?;
        let (vendor, product) = rgb_vid_pid(&current)?;

        msi_hardware::rgb::send_steady_color(vendor, product, zones, r, g, b)
            .map_err(rgb_fdo_error)?;

        let applied = serde_json::json!({
            "zone_mask": format!("{zones:#04x}"),
            "color": [r, g, b],
            "persistent": false,
        });
        Ok(applied.to_string())
    }

    async fn set_rgb_effect(
        &self,
        zones: u8,
        mode: u8,
        speed_centiseconds: u16,
        wave_direction: u8,
        colors: Vec<(u8, u8, u8)>,
        #[zbus(header)] header: Header<'_>,
    ) -> zbus::fdo::Result<String> {
        if colors.is_empty() {
            return Err(zbus::fdo::Error::InvalidArgs(
                "RGB effect needs at least one color".into(),
            ));
        }
        let current = snapshot(&self.status)?;
        require_rgb_write_support(&current, rgb_writes_enabled())?;
        let sender = header
            .sender()
            .ok_or_else(|| zbus::fdo::Error::AccessDenied("missing D-Bus sender".into()))?;
        authorize(&self.connection, sender.as_str(), SET_RGB_COLOR_ACTION).await?;
        let (vendor, product) = rgb_vid_pid(&current)?;

        let keyframes = msi_hardware::rgb::keyframes_from_colors(&colors);
        msi_hardware::rgb::send_effect(
            vendor,
            product,
            zones,
            mode,
            speed_centiseconds,
            wave_direction,
            &keyframes,
        )
        .map_err(rgb_fdo_error)?;

        let applied = serde_json::json!({
            "zone_mask": format!("{zones:#04x}"),
            "mode": mode,
            "speed_centiseconds": speed_centiseconds,
            "wave_direction": wave_direction,
            "colors": colors,
            "persistent": false,
        });
        Ok(applied.to_string())
    }

    async fn save_rgb_state(
        &self,
        #[zbus(header)] header: Header<'_>,
    ) -> zbus::fdo::Result<String> {
        let current = snapshot(&self.status)?;
        require_rgb_save_support(&current, rgb_flash_writes_enabled())?;
        let sender = header
            .sender()
            .ok_or_else(|| zbus::fdo::Error::AccessDenied("missing D-Bus sender".into()))?;
        authorize(&self.connection, sender.as_str(), SET_RGB_SAVE_ACTION).await?;
        let (vendor, product) = rgb_vid_pid(&current)?;

        msi_hardware::rgb::save_to_flash(vendor, product).map_err(rgb_fdo_error)?;

        let applied = serde_json::json!({ "saved_to_flash": true });
        Ok(applied.to_string())
    }

    async fn set_rgb_preset_effect(
        &self,
        zones: u8,
        mode: u8,
        speed_centiseconds: u16,
        color_hex: String,
        #[zbus(header)] header: Header<'_>,
    ) -> zbus::fdo::Result<String> {
        // Semantic preset: one user color; the daemon derives companions
        // (cycle: +180, wave: +120/+240) so clients never marshal a(yyy).
        if !(1..=4).contains(&mode) {
            return Err(zbus::fdo::Error::InvalidArgs(
                "mode must be 1 (steady), 2 (breathing), 3 (cycle) or 4 (wave)".into(),
            ));
        }
        let base = parse_hex_color(&color_hex).ok_or_else(|| {
            zbus::fdo::Error::InvalidArgs(format!("invalid color {color_hex:?} (expected RRGGBB)"))
        })?;
        let colors = match mode {
            1 | 2 => vec![base],
            3 => vec![base, msi_hardware::rgb::rotate_hue(base, 180.0)],
            _ => vec![
                base,
                msi_hardware::rgb::rotate_hue(base, 120.0),
                msi_hardware::rgb::rotate_hue(base, 240.0),
            ],
        };

        let current = snapshot(&self.status)?;
        require_rgb_write_support(&current, rgb_writes_enabled())?;
        let sender = header
            .sender()
            .ok_or_else(|| zbus::fdo::Error::AccessDenied("missing D-Bus sender".into()))?;
        authorize(&self.connection, sender.as_str(), SET_RGB_COLOR_ACTION).await?;
        let (vendor, product) = rgb_vid_pid(&current)?;

        let keyframes = msi_hardware::rgb::keyframes_from_colors(&colors);
        msi_hardware::rgb::send_effect(
            vendor,
            product,
            zones,
            mode,
            speed_centiseconds,
            1,
            &keyframes,
        )
        .map_err(rgb_fdo_error)?;

        let applied = serde_json::json!({
            "zone_mask": format!("{zones:#04x}"),
            "mode": mode,
            "speed_centiseconds": speed_centiseconds,
            "colors": colors,
            "persistent": false,
        });
        Ok(applied.to_string())
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

fn cooler_boost_writes_enabled() -> bool {
    std::env::var("MSI_LINUX_CENTER_ENABLE_COOLER_BOOST_WRITES").as_deref() == Ok("1")
}

fn super_battery_writes_enabled() -> bool {
    std::env::var("MSI_LINUX_CENTER_ENABLE_SUPER_BATTERY_WRITES").as_deref() == Ok("1")
}

fn rgb_writes_enabled() -> bool {
    std::env::var("MSI_LINUX_CENTER_ENABLE_RGB_WRITES").as_deref() == Ok("1")
}

fn rgb_flash_writes_enabled() -> bool {
    std::env::var("MSI_LINUX_CENTER_ENABLE_RGB_FLASH_WRITES").as_deref() == Ok("1")
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

fn require_cooler_boost_write_support(
    status: &SystemStatus,
    enabled: bool,
) -> zbus::fdo::Result<()> {
    if !enabled {
        return Err(zbus::fdo::Error::NotSupported(
            "cooler-boost writes disabled; set MSI_LINUX_CENTER_ENABLE_COOLER_BOOST_WRITES=1 for local validation"
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
    if !profile.capabilities.cooler_boost
        || !profile
            .exact_verified_firmware
            .iter()
            .any(|verified| verified == firmware)
        || !status.backends.msi_ec
    {
        return Err(zbus::fdo::Error::NotSupported(
            "cooler-boost writes require exact verified firmware and the msi-ec backend".into(),
        ));
    }
    Ok(())
}

fn require_super_battery_write_support(
    status: &SystemStatus,
    enabled: bool,
) -> zbus::fdo::Result<()> {
    if !enabled {
        return Err(zbus::fdo::Error::NotSupported(
            "super-battery writes disabled; set MSI_LINUX_CENTER_ENABLE_SUPER_BATTERY_WRITES=1 for local validation"
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
    if !profile.capabilities.super_battery
        || !profile
            .exact_verified_firmware
            .iter()
            .any(|verified| verified == firmware)
        || !status.backends.msi_ec
    {
        return Err(zbus::fdo::Error::NotSupported(
            "super-battery writes require exact verified firmware and the msi-ec backend".into(),
        ));
    }
    Ok(())
}

fn require_rgb_write_support(status: &SystemStatus, enabled: bool) -> zbus::fdo::Result<()> {
    if !enabled {
        return Err(zbus::fdo::Error::NotSupported(
            "RGB writes disabled; set MSI_LINUX_CENTER_ENABLE_RGB_WRITES=1 for local validation"
                .into(),
        ));
    }
    let profile = status
        .matched_profile
        .as_ref()
        .ok_or_else(|| zbus::fdo::Error::NotSupported("device profile unmatched".into()))?;
    if !profile.capabilities.rgb || profile.rgb_usb_vid.is_none() || profile.rgb_usb_pid.is_none() {
        return Err(zbus::fdo::Error::NotSupported(
            "RGB writes require a profile with a declared RGB controller".into(),
        ));
    }
    if !status.backends.rgb_hid {
        return Err(zbus::fdo::Error::NotSupported(
            "RGB controller backend not detected".into(),
        ));
    }
    Ok(())
}

/// Parses an RRGGBB hex color string into (r, g, b).
fn parse_hex_color(hex: &str) -> Option<(u8, u8, u8)> {
    let bytes = hex.as_bytes();
    if bytes.len() != 6 || !bytes.iter().all(u8::is_ascii_hexdigit) {
        return None;
    }
    let channel = |range: std::ops::Range<usize>| u8::from_str_radix(&hex[range], 16).ok();
    Some((channel(0..2)?, channel(2..4)?, channel(4..6)?))
}

/// Resolves the RGB VID/PID pair from the matched profile.
fn rgb_vid_pid(status: &SystemStatus) -> zbus::fdo::Result<(u16, u16)> {
    let profile = status
        .matched_profile
        .as_ref()
        .ok_or_else(|| zbus::fdo::Error::NotSupported("device profile unmatched".into()))?;
    let parse = |value: Option<&String>, what: &str| -> zbus::fdo::Result<u16> {
        let value = value
            .ok_or_else(|| zbus::fdo::Error::NotSupported(format!("no RGB {what} declared")))?;
        u16::from_str_radix(value, 16)
            .map_err(|_| zbus::fdo::Error::NotSupported(format!("invalid RGB {what}")))
    };
    Ok((
        parse(profile.rgb_usb_vid.as_ref(), "VID")?,
        parse(profile.rgb_usb_pid.as_ref(), "PID")?,
    ))
}

/// Maps a hardware RGB send error to a D-Bus error: argument problems are
/// InvalidArgs, everything else Failed.
fn rgb_fdo_error(error: msi_hardware::rgb::RgbSendError) -> zbus::fdo::Error {
    match error {
        msi_hardware::rgb::RgbSendError::InvalidZones(_)
        | msi_hardware::rgb::RgbSendError::InvalidPacket(_) => {
            zbus::fdo::Error::InvalidArgs(error.to_string())
        }
        other => zbus::fdo::Error::Failed(other.to_string()),
    }
}

fn require_rgb_save_support(status: &SystemStatus, enabled: bool) -> zbus::fdo::Result<()> {
    if !enabled {
        return Err(zbus::fdo::Error::NotSupported(
            "RGB flash-save disabled; set MSI_LINUX_CENTER_ENABLE_RGB_FLASH_WRITES=1 for local validation"
                .into(),
        ));
    }
    require_rgb_write_support(status, true)?;
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
    // JSON keeps the surface small while the CLI is the only client; switch
    // to typed D-Bus records when additional clients (GUI, SDK) need them.
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

    #[test]
    fn cooler_boost_write_gate_requires_opt_in_and_exact_firmware() {
        let mut status = collect_status_at(
            PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../tests/fixtures/katana17-b13vgk"),
        )
        .unwrap();
        assert!(require_cooler_boost_write_support(&status, false).is_err());
        assert!(require_cooler_boost_write_support(&status, true).is_ok());

        status.ec.firmware = Some("17L5EMS1.999".into());
        assert!(require_cooler_boost_write_support(&status, true).is_err());
    }

    #[test]
    fn super_battery_write_gate_requires_opt_in_and_exact_firmware() {
        let mut status = collect_status_at(
            PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../tests/fixtures/katana17-b13vgk"),
        )
        .unwrap();
        assert!(require_super_battery_write_support(&status, false).is_err());
        assert!(require_super_battery_write_support(&status, true).is_ok());

        status.ec.firmware = Some("17L5EMS1.999".into());
        assert!(require_super_battery_write_support(&status, true).is_err());
    }

    #[test]
    fn rgb_write_gate_requires_opt_in_profile_and_backend() {
        let mut status = collect_status_at(
            PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../tests/fixtures/katana17-b13vgk"),
        )
        .unwrap();
        assert!(require_rgb_write_support(&status, false).is_err());
        // The fixture has no USB RGB backend.
        assert!(require_rgb_write_support(&status, true).is_err());
        status.backends.rgb_hid = true;
        assert!(require_rgb_write_support(&status, true).is_ok());
        status.matched_profile.as_mut().unwrap().rgb_usb_vid = None;
        assert!(require_rgb_write_support(&status, true).is_err());
    }

    #[test]
    fn rgb_save_gate_requires_flash_opt_in() {
        let mut status = collect_status_at(
            PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../tests/fixtures/katana17-b13vgk"),
        )
        .unwrap();
        // Flash-save needs its own opt-in even when the RGB backend exists.
        assert!(require_rgb_save_support(&status, false).is_err());
        status.backends.rgb_hid = true;
        assert!(require_rgb_save_support(&status, false).is_err());
    }
}
