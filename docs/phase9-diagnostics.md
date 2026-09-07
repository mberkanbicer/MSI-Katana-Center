# Phase 9 — Community diagnostics and unmatched-model workflow

Status: CLI `msicenter report` and UI Diagnostics copy-report implemented.
Read-only. No hardware writes.

## What a report contains

JSON (`msicenter report --json` or D-Bus `Device.DiagnosticReport`):

- tool version
- kernel `osrelease` / `version`
- `msi_ec` and `msi_wmi_platform` module state/version if present
- device identity (no DMI serial/UUID)
- matched profile or `unmatched: true`
- backends, EC semantic state (unknown shift values kept verbatim), fans, battery, RGB **without** controller serial
- runtime capabilities

AGENTS §31: serial numbers and UUIDs are never included.

## Unmatched model

If the laptop is not in `data/devices/`, `status` still works (read-only) and
the report sets `unmatched: true`. Attach that JSON when requesting support.
Do not send `dmidecode` dumps that include serials; the report is enough for
board name, product, BIOS, and EC firmware.

## UI

Diagnostics page shows the redacted JSON and **Copy report**. The GUI never
reads `/sys`; the daemon builds the report.

## CLI

    msicenter report
    msicenter report --json
