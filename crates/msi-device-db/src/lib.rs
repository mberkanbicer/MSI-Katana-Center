use msi_core::{DeviceIdentity, DeviceProfile, LocalVerification, SupportTier};
use std::fmt;

const KATANA_17_B13VGK: &str = include_str!(concat!(
    env!("CARGO_MANIFEST_DIR"),
    "/../../data/devices/msi-katana-17-b13vgk.json"
));

#[derive(Debug)]
pub enum DatabaseError {
    Parse(serde_json::Error),
    InvalidProfile { profile: String, reason: String },
}

impl fmt::Display for DatabaseError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Parse(error) => write!(f, "device database parse error: {error}"),
            Self::InvalidProfile { profile, reason } => {
                write!(f, "invalid device profile {profile}: {reason}")
            }
        }
    }
}

impl std::error::Error for DatabaseError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Parse(error) => Some(error),
            Self::InvalidProfile { .. } => None,
        }
    }
}

impl From<serde_json::Error> for DatabaseError {
    fn from(error: serde_json::Error) -> Self {
        Self::Parse(error)
    }
}

pub fn profiles() -> Result<Vec<DeviceProfile>, DatabaseError> {
    let profiles = vec![serde_json::from_str(KATANA_17_B13VGK)?];
    for profile in &profiles {
        validate_profile(profile)?;
    }
    Ok(profiles)
}

pub fn validate_profile(profile: &DeviceProfile) -> Result<(), DatabaseError> {
    let invalid = |reason: &str| DatabaseError::InvalidProfile {
        profile: profile.id.clone(),
        reason: reason.into(),
    };

    if profile.id.trim().is_empty() || profile.marketing_name.trim().is_empty() {
        return Err(invalid("identity fields must not be empty"));
    }
    if profile.product_names.is_empty() && profile.board_names.is_empty() {
        return Err(invalid("at least one product or board name is required"));
    }
    if profile.provenance.is_empty() {
        return Err(invalid("provenance is required"));
    }
    for entry in &profile.provenance {
        if entry.feature.trim().is_empty()
            || entry.model_firmware_scope.trim().is_empty()
            || entry.sources.is_empty()
            || entry.sources.iter().any(|source| source.trim().is_empty())
        {
            return Err(invalid("provenance fields must not be empty"));
        }
        if entry.writes_tested && entry.local_verification != LocalVerification::VerifiedWrite {
            return Err(invalid(
                "write-tested provenance must use verified_write local verification",
            ));
        }
    }
    Ok(())
}

pub fn match_device(
    identity: &DeviceIdentity,
    ec_firmware: Option<&str>,
) -> Result<Option<DeviceProfile>, DatabaseError> {
    for mut profile in profiles()? {
        let product_match = identity.product_name.as_deref().is_some_and(|name| {
            profile
                .product_names
                .iter()
                .any(|candidate| candidate == name)
        });
        let board_match = identity.board_name.as_deref().is_some_and(|name| {
            profile
                .board_names
                .iter()
                .any(|candidate| candidate == name)
        });

        if !product_match && !board_match {
            continue;
        }

        match ec_firmware {
            Some(fw)
                if profile
                    .exact_verified_firmware
                    .iter()
                    .any(|value| value == fw) => {}
            Some(fw)
                if profile
                    .ec_firmware_prefixes
                    .iter()
                    .any(|prefix| fw.starts_with(prefix)) =>
            {
                profile.support_tier = SupportTier::Experimental;
            }
            Some(_) => continue,
            None => profile.support_tier = SupportTier::Unknown,
        }

        return Ok(Some(profile));
    }

    Ok(None)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn matching_and_profile_validation() {
        let exact_identity = DeviceIdentity {
            product_name: Some("Katana 17 B13VGK".into()),
            board_name: Some("MS-17L5".into()),
            ..Default::default()
        };

        let profile = match_device(&exact_identity, Some("17L5EMS1.115"))
            .unwrap()
            .expect("profile should match");
        assert_eq!(profile.id, "msi-katana-17-b13vgk-ms17l5");
        assert_eq!(profile.support_tier, SupportTier::Verified);

        let board_only = DeviceIdentity {
            product_name: Some("wrong product".into()),
            board_name: Some("MS-17L5".into()),
            ..Default::default()
        };
        assert!(match_device(&board_only, Some("17L5EMS1.115"))
            .unwrap()
            .is_some());
        assert!(match_device(&exact_identity, Some("WRONG.001"))
            .unwrap()
            .is_none());
        assert_eq!(
            match_device(&exact_identity, Some("17L5EMS1.999"))
                .unwrap()
                .unwrap()
                .support_tier,
            SupportTier::Experimental
        );
        assert_eq!(
            match_device(&exact_identity, None)
                .unwrap()
                .unwrap()
                .support_tier,
            SupportTier::Unknown
        );

        let mut invalid = profile;
        invalid.provenance.clear();
        assert!(matches!(
            validate_profile(&invalid),
            Err(DatabaseError::InvalidProfile { .. })
        ));
    }
}
