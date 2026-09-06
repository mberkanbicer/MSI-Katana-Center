//! MysticLight MS-1565 (1462:1601) keyboard RGB.
//!
//! Two layers:
//!
//! * packet building — pure, Linux-independent (zone-select + set-effect),
//!   no device I/O;
//! * device probing — hidapi over the libusb backend (usbfs), used by the
//!   root daemon. Only read-only probing is wired up so far; sending
//!   feature reports stays a separate, gated step (AGENTS §24).
//!
//! The wire format is documented in `docs/phase7-rgb-protocol.md` and was
//! cross-verified field-for-field against `msi-katana-rgb` and OpenRGB RC3
//! (`MSIMysticLightKBController`, `FeaturePacket_MS1565`).
//!
//! Only temporary (non-persistent) packets are built here. Flash-save
//! (0xA0) is intentionally absent: AGENTS §24 requires non-persistent
//! testing first, and flash writes stay a separate gated action.

/// HID feature-report write id.
pub const REPORT_ID_WRITE: u8 = 2;
/// Feature report size in bytes.
pub const PACKET_SIZE: usize = 64;
/// Packet id: select zones.
pub const PACKET_SELECT_ZONES: u8 = 1;
/// Packet id: set effect.
pub const PACKET_SET_EFFECT: u8 = 2;

/// Zone bitmask values (bits 0-3, left to right).
pub const ZONE_1: u8 = 0b0001;
pub const ZONE_2: u8 = 0b0010;
pub const ZONE_3: u8 = 0b0100;
pub const ZONE_4: u8 = 0b1000;
pub const ZONE_ALL: u8 = 0b1111;

/// Effect types (matches `MS_1565_MODE` / msi-katana-rgb `EFFECT_*`).
pub const EFFECT_OFF: u8 = 0;
pub const EFFECT_STEADY: u8 = 1;
pub const EFFECT_BREATHING: u8 = 2;
pub const EFFECT_COLOR_CYCLE: u8 = 3;
pub const EFFECT_COLOR_WAVE: u8 = 4;

/// Wave directions.
pub const WAVE_RIGHT_TO_LEFT: u8 = 0;
pub const WAVE_LEFT_TO_RIGHT: u8 = 1;

/// Maximum keyframes (matches OpenRGB `MAX_MS_1565_KEYFRAMES`).
pub const MAX_KEYFRAMES: usize = 10;

/// One animation keyframe: time (0-100) plus an RGB color.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct RgbKeyframe {
    pub time: u8,
    pub r: u8,
    pub g: u8,
    pub b: u8,
}

#[derive(Debug, PartialEq, Eq)]
pub enum RgbPacketError {
    InvalidZones(u8),
    InvalidMode(u8),
    InvalidWaveDirection(u8),
    KeyframeTimeOutOfRange { index: usize, time: u8 },
    TooManyKeyframes(usize),
}

impl std::fmt::Display for RgbPacketError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::InvalidZones(zones) => {
                write!(
                    f,
                    "invalid RGB zone mask {zones:#04x}; only bits 0-3 are valid"
                )
            }
            Self::InvalidMode(mode) => write!(f, "invalid RGB effect mode {mode}; expected 0-4"),
            Self::InvalidWaveDirection(direction) => {
                write!(f, "invalid RGB wave direction {direction}; expected 0 or 1")
            }
            Self::KeyframeTimeOutOfRange { index, time } => {
                write!(f, "RGB keyframe {index} has time {time}; expected 0-100")
            }
            Self::TooManyKeyframes(count) => write!(
                f,
                "too many RGB keyframes ({count}); maximum is {MAX_KEYFRAMES}"
            ),
        }
    }
}

impl std::error::Error for RgbPacketError {}

/// Identity of an opened RGB controller (read-only probe).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RgbControllerInfo {
    pub name: String,
    pub serial: Option<String>,
}

#[derive(Debug)]
pub enum RgbSendError {
    InvalidZones(u8),
    InvalidPacket(String),
    NotFound,
    Open(hidapi::HidError),
    Send(hidapi::HidError),
}

impl std::fmt::Display for RgbSendError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::InvalidZones(zones) => {
                write!(
                    f,
                    "invalid RGB zone mask {zones:#04x}; only bits 0-3 are valid"
                )
            }
            Self::InvalidPacket(reason) => write!(f, "invalid RGB packet: {reason}"),
            Self::NotFound => write!(f, "RGB controller not found"),
            Self::Open(error) => write!(f, "RGB controller open error: {error}"),
            Self::Send(error) => write!(f, "RGB feature report send error: {error}"),
        }
    }
}

impl std::error::Error for RgbSendError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Open(error) | Self::Send(error) => Some(error),
            _ => None,
        }
    }
}

/// Opens the HID controller with the given vendor/product ids.
fn open_rgb_controller(vendor_id: u16, product_id: u16) -> Result<hidapi::HidDevice, RgbSendError> {
    use hidapi::HidApi;

    let api = HidApi::new().map_err(RgbSendError::Open)?;
    for device in api.device_list() {
        if device.vendor_id() == vendor_id && device.product_id() == product_id {
            return device.open_device(&api).map_err(RgbSendError::Open);
        }
    }
    Err(RgbSendError::NotFound)
}

/// Sends a **non-persistent** steady color to the selected zones.
///
/// Two 64-byte feature reports: zone select, then a steady effect with a
/// single color keyframe. No flash-save (0xA0) is ever sent (AGENTS §24).
/// There is no read-back for this device; physical verification is visual.
pub fn send_steady_color(
    vendor_id: u16,
    product_id: u16,
    zones: u8,
    r: u8,
    g: u8,
    b: u8,
) -> Result<(), RgbSendError> {
    send_effect(
        vendor_id,
        product_id,
        zones,
        EFFECT_STEADY,
        300,
        WAVE_LEFT_TO_RIGHT,
        &[RgbKeyframe { time: 0, r, g, b }],
    )
}

/// Distributes colors into evenly spaced keyframes: first at time 0, last
/// at time 100 (matches msi-katana-rgb and OpenRGB behavior).
pub fn keyframes_from_colors(colors: &[(u8, u8, u8)]) -> Vec<RgbKeyframe> {
    let count = colors.len();
    colors
        .iter()
        .enumerate()
        .map(|(index, &(r, g, b))| {
            let time = if count == 1 {
                0
            } else if index == count - 1 {
                100
            } else {
                ((index * 100) / (count - 1)) as u8
            };
            RgbKeyframe { time, r, g, b }
        })
        .collect()
}

/// Rotates a color's hue by `degrees` (RGB -> HSL -> rotate -> RGB).
/// Used to derive harmonious companion colors for effects from a single
/// user-chosen color (cycle: +180, wave: +120/+240).
pub fn rotate_hue(color: (u8, u8, u8), degrees: f64) -> (u8, u8, u8) {
    let (r, g, b) = (
        f64::from(color.0) / 255.0,
        f64::from(color.1) / 255.0,
        f64::from(color.2) / 255.0,
    );
    let max = r.max(g).max(b);
    let min = r.min(g).min(b);
    let lightness = (max + min) / 2.0;
    let delta = max - min;
    if delta < 1e-9 {
        // Grayscale: no hue to rotate; return unchanged.
        return color;
    }
    let saturation = delta / (1.0 - (2.0 * lightness - 1.0).abs());
    let hue = if max == r {
        60.0 * (((g - b) / delta).rem_euclid(6.0))
    } else if max == g {
        60.0 * (((b - r) / delta) + 2.0)
    } else {
        60.0 * (((r - g) / delta) + 4.0)
    };
    let hue = (hue + degrees).rem_euclid(360.0);

    let chroma = (1.0 - (2.0 * lightness - 1.0).abs()) * saturation;
    let x = chroma * (1.0 - ((hue / 60.0).rem_euclid(2.0) - 1.0).abs());
    let m = lightness - chroma / 2.0;
    let (rr, gg, bb) = match hue {
        h if h < 60.0 => (chroma, x, 0.0),
        h if h < 120.0 => (x, chroma, 0.0),
        h if h < 180.0 => (0.0, chroma, x),
        h if h < 240.0 => (0.0, x, chroma),
        h if h < 300.0 => (x, 0.0, chroma),
        _ => (chroma, 0.0, x),
    };
    let channel = |value: f64| ((value + m) * 255.0).round().clamp(0.0, 255.0) as u8;
    (channel(rr), channel(gg), channel(bb))
}

/// Sends a **non-persistent** effect to the selected zones: zone select
/// plus one set-effect feature report. Never sends flash-save; see
/// [`save_to_flash`] for the separate persistent path.
pub fn send_effect(
    vendor_id: u16,
    product_id: u16,
    zones: u8,
    mode: u8,
    speed_centiseconds: u16,
    wave_direction: u8,
    keyframes: &[RgbKeyframe],
) -> Result<(), RgbSendError> {
    let select = zone_select_packet(zones).map_err(|error| match error {
        RgbPacketError::InvalidZones(zones) => RgbSendError::InvalidZones(zones),
        _ => unreachable!("zone_select_packet only fails on invalid zones"),
    })?;
    let effect = effect_packet(mode, speed_centiseconds, wave_direction, keyframes)
        .map_err(|error| RgbSendError::InvalidPacket(error.to_string()))?;

    let device = open_rgb_controller(vendor_id, product_id)?;
    device
        .send_feature_report(&select)
        .map_err(RgbSendError::Send)?;
    device
        .send_feature_report(&effect)
        .map_err(RgbSendError::Send)
}

/// Saves the current (last sent) effect to flash — **persistent** across
/// reboots, kept separate from the non-persistent path (AGENTS §24).
pub fn save_to_flash(vendor_id: u16, product_id: u16) -> Result<(), RgbSendError> {
    let mut packet = [0u8; PACKET_SIZE];
    packet[0] = REPORT_ID_WRITE;
    packet[1] = 0xa0; // flash-save
    let device = open_rgb_controller(vendor_id, product_id)?;
    device
        .send_feature_report(&packet)
        .map_err(RgbSendError::Send)
}

/// Opens the HID controller with the given vendor/product ids and reads its
/// product and serial strings. Read-only: no feature report is sent.
/// Requires usbfs access (root, or udev rules) — the daemon runs as root.
pub fn probe_rgb_controller(vendor_id: u16, product_id: u16) -> Option<RgbControllerInfo> {
    use hidapi::HidApi;

    let api = HidApi::new().ok()?;
    for device in api.device_list() {
        if device.vendor_id() != vendor_id || device.product_id() != product_id {
            continue;
        }
        let opened = device.open_device(&api).ok()?;
        let name = opened
            .get_product_string()
            .ok()
            .flatten()
            .unwrap_or_default();
        let name = if name.is_empty() {
            format!("{vendor_id:#06x}:{product_id:#06x}")
        } else {
            name
        };
        let serial = opened
            .get_serial_number_string()
            .ok()
            .flatten()
            .filter(|serial| !serial.is_empty());
        return Some(RgbControllerInfo { name, serial });
    }
    None
}

/// Builds a zone-select packet: `[report 2][packet 1][zone mask]` padded to 64.
pub fn zone_select_packet(zones: u8) -> Result<[u8; PACKET_SIZE], RgbPacketError> {
    if zones & !ZONE_ALL != 0 {
        return Err(RgbPacketError::InvalidZones(zones));
    }
    let mut packet = [0u8; PACKET_SIZE];
    packet[0] = REPORT_ID_WRITE;
    packet[1] = PACKET_SELECT_ZONES;
    packet[2] = zones;
    Ok(packet)
}

/// Builds a set-effect packet matching `FeaturePacket_MS1565`:
/// `[2][2][mode][speed LE][00 00 0F 01][wave dir][time,r,g,b xN]` padded to 64.
pub fn effect_packet(
    mode: u8,
    speed_centiseconds: u16,
    wave_direction: u8,
    keyframes: &[RgbKeyframe],
) -> Result<[u8; PACKET_SIZE], RgbPacketError> {
    if mode > EFFECT_COLOR_WAVE {
        return Err(RgbPacketError::InvalidMode(mode));
    }
    if wave_direction > WAVE_LEFT_TO_RIGHT {
        return Err(RgbPacketError::InvalidWaveDirection(wave_direction));
    }
    if keyframes.len() > MAX_KEYFRAMES {
        return Err(RgbPacketError::TooManyKeyframes(keyframes.len()));
    }
    for (index, keyframe) in keyframes.iter().enumerate() {
        if keyframe.time > 100 {
            return Err(RgbPacketError::KeyframeTimeOutOfRange {
                index,
                time: keyframe.time,
            });
        }
    }

    let mut packet = [0u8; PACKET_SIZE];
    packet[0] = REPORT_ID_WRITE;
    packet[1] = PACKET_SET_EFFECT;
    packet[2] = mode;
    packet[3] = speed_centiseconds as u8;
    packet[4] = (speed_centiseconds >> 8) as u8;
    packet[5] = 0x00;
    packet[6] = 0x00;
    packet[7] = 0x0f;
    packet[8] = 0x01;
    packet[9] = wave_direction;

    for (index, keyframe) in keyframes.iter().enumerate() {
        let offset = 10 + index * 4;
        packet[offset] = keyframe.time;
        packet[offset + 1] = keyframe.r;
        packet[offset + 2] = keyframe.g;
        packet[offset + 3] = keyframe.b;
    }
    Ok(packet)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn builds_steady_color_packets() {
        // Zone select for zones 1+3.
        let select = zone_select_packet(ZONE_1 | ZONE_3).unwrap();
        assert_eq!(&select[..3], &[2, 1, 0b0101]);
        assert!(select[3..].iter().all(|byte| *byte == 0));

        // Steady red, 3.00 s cycle, full keyboard.
        let effect = effect_packet(
            EFFECT_STEADY,
            300,
            WAVE_LEFT_TO_RIGHT,
            &[RgbKeyframe {
                time: 0,
                r: 255,
                g: 0,
                b: 0,
            }],
        )
        .unwrap();
        assert_eq!(
            &effect[..10],
            &[2, 2, 1, 0x2c, 0x01, 0x00, 0x00, 0x0f, 0x01, 0x01]
        );
        assert_eq!(&effect[10..14], &[0, 255, 0, 0]);
        assert!(effect[14..].iter().all(|byte| *byte == 0));

        // Multiple keyframes are laid out back to back.
        let wave = effect_packet(
            EFFECT_COLOR_WAVE,
            100,
            WAVE_RIGHT_TO_LEFT,
            &[
                RgbKeyframe {
                    time: 0,
                    r: 255,
                    g: 0,
                    b: 0,
                },
                RgbKeyframe {
                    time: 100,
                    r: 0,
                    g: 0,
                    b: 255,
                },
            ],
        )
        .unwrap();
        assert_eq!(wave[2], EFFECT_COLOR_WAVE);
        assert_eq!(&wave[10..18], &[0, 255, 0, 0, 100, 0, 0, 255]);
    }

    #[test]
    fn rejects_invalid_inputs() {
        assert_eq!(
            zone_select_packet(0b1_0000),
            Err(RgbPacketError::InvalidZones(0b1_0000))
        );
        assert_eq!(
            effect_packet(9, 300, 0, &[]),
            Err(RgbPacketError::InvalidMode(9))
        );
        assert_eq!(
            effect_packet(EFFECT_STEADY, 300, 2, &[]),
            Err(RgbPacketError::InvalidWaveDirection(2))
        );
        assert_eq!(
            effect_packet(
                EFFECT_STEADY,
                300,
                0,
                &[RgbKeyframe {
                    time: 101,
                    r: 1,
                    g: 2,
                    b: 3,
                }],
            ),
            Err(RgbPacketError::KeyframeTimeOutOfRange {
                index: 0,
                time: 101,
            })
        );
        let too_many = vec![
            RgbKeyframe {
                time: 0,
                r: 1,
                g: 2,
                b: 3,
            };
            MAX_KEYFRAMES + 1
        ];
        assert_eq!(
            effect_packet(EFFECT_COLOR_WAVE, 300, 0, &too_many),
            Err(RgbPacketError::TooManyKeyframes(MAX_KEYFRAMES + 1))
        );
    }

    #[test]
    fn distributes_colors_into_keyframes() {
        // Single color -> time 0.
        let one = keyframes_from_colors(&[(255, 0, 0)]);
        assert_eq!(one.len(), 1);
        assert_eq!(one[0].time, 0);

        // Two colors -> 0 and 100.
        let two = keyframes_from_colors(&[(255, 0, 0), (0, 0, 255)]);
        assert_eq!(two[0].time, 0);
        assert_eq!(two[1].time, 100);

        // Three colors -> 0, 50, 100.
        let three = keyframes_from_colors(&[(255, 0, 0), (0, 255, 0), (0, 0, 255)]);
        assert_eq!(three[0].time, 0);
        assert_eq!(three[1].time, 50);
        assert_eq!(three[2].time, 100);
    }

    #[test]
    fn rotates_hue() {
        // Red +120° -> green-ish, +180° -> cyan, +240° -> blue-ish.
        let greenish = rotate_hue((255, 0, 0), 120.0);
        assert!(greenish.1 > greenish.0 && greenish.1 > greenish.2);
        let cyan = rotate_hue((255, 0, 0), 180.0);
        assert!(cyan.1 > 200 && cyan.2 > 200 && cyan.0 < 50);
        let blueish = rotate_hue((255, 0, 0), 240.0);
        assert!(blueish.2 > blueish.0 && blueish.2 > blueish.1);
        // Grayscale stays grayscale.
        assert_eq!(rotate_hue((120, 120, 120), 90.0), (120, 120, 120));
        // Round trip: full rotation returns the original color.
        let original = (200, 60, 40);
        let back = rotate_hue(rotate_hue(original, 137.0), 360.0 - 137.0);
        assert_eq!(back, original);
    }
}
