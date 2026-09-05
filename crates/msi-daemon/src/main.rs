use std::process::ExitCode;

fn main() -> ExitCode {
    match msi_dbus::run_system_daemon() {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("msi-daemon: {error}");
            ExitCode::FAILURE
        }
    }
}
