# Changelog

All notable changes to VESSL are listed here.

## [2.1.0] - 2026-09-26

### Added

- When port 80 is busy, VESSL asks how to continue instead of only offering to stop the owner:
  - stop the systemd service or Docker container for a few seconds, as before,
  - **webroot** (`--webroot [dir]`): the running web server serves the challenge files, no downtime,
  - **another local port** (`--httpport <port>`): the web server forwards the challenge to VESSL, no downtime,
  - **TLS-ALPN on port 443** (`--alpn`), offered when 443 is free,
  - **show the commands** to do it by hand, changing nothing.
- nginx, Apache and Caddy are detected, the config file that names the domain is located, and the exact lines to add are shown with a safe test-then-reload command.
- Self-test before contacting Let's Encrypt: a test file is fetched through the web server, so a wrong config never costs a request.
- `vessl --ports` explains the options and prints owner-specific commands when port 80 is busy: `systemctl stop/start`, `docker stop/start`, or `kill` with SIGTERM for unmanaged processes.
- The certificate list shows the renewal method for webroot, forwarded port and TLS-ALPN certificates, and Renew reuses the same method.

### Changed

- With `-y` or without a terminal, a busy port 80 held by an unmanaged process now stops with clear instructions instead of a generic error.

## [2.0.2] - 2026-09-26

### Added

- Links to the GitHub repository and the Daily Digital Skills YouTube channel: under the menu, after a certificate is issued, in `--help`, in `--version` and after uninstalling.
- GitHub stars and YouTube badges, and a "Support the project" section in the README.

## [2.0.1] - 2026-09-26

### Fixed

- Running VESSL with the one-line `bash -c "$(curl ...)"` command opened the menu but did not install the `vessl` command. Opening the menu now installs `/usr/local/bin/vessl`, or updates it when the installed copy is older, and says so under the status box.
- Pressing Ctrl+C at a menu prompt now exits with "Bye." instead of an "Interrupted" error. The error is kept for when a running task is interrupted.

## [2.0.0] - 2026-09-25

A complete rewrite. The script is now `vessl.sh` and installs as the `vessl` command.

### Added

- Interactive menu with a server status box: public IP, installed engines, who holds port 80, certificate count and saved Cloudflare credentials.
- Full command-line interface covering every menu action, for scripts and automation.
- Preflight checks before every request: Let's Encrypt API, public IP, A/AAAA records, CAA records, nameservers, port 80, port 443, ufw and firewalld.
- Free staging test against Let's Encrypt staging (`--check`, `--test`), with a clear yes/no result.
- Port inspector (`--ports`) that shows the process, systemd service or Docker container behind each listening port.
- Automatic port 80 handling: services and containers are stopped for a few seconds and started again, and the same stop and start is registered for automatic renewals.
- Wildcard certificates through Cloudflare API token, Cloudflare Global API Key or manual DNS TXT records.
- Cloudflare checks: token or key validity, zone lookup, and whether the domain uses Cloudflare nameservers.
- Manual DNS helper that shows the records to add and waits until the authoritative nameserver serves them.
- Certificate list (`--list`) with lifetime bars, expiry dates, wildcard tags and renewal method.
- Renew, remove and revoke from the menu.
- Uninstall with optional removal of certificates, acme.sh and certbot (`--uninstall`, `--purge`).
- Self-update from GitHub (`--update`).
- Settings: default email, default destination, verbose output and log viewer.
- Progress bars, spinners and a log file at `/var/log/vessl.log`. On failure, the last lines of output and a likely cause are shown.
- Panel shortcuts for Marzneshin, PasarGuard, Rebecca and OV-Panel.

### Changed

- Certificates are always saved as `privkey.pem` and `fullchain.pem` in a folder named after the first domain.
- Custom paths accept an optional trailing slash, and repeated slashes are cleaned up.
- acme.sh certificates are registered with `--install-cert`, so renewed certificates are copied to the destination automatically.
- Certificates use ECDSA P-256 keys and Let's Encrypt as the certificate authority.
- A wildcard certificate always covers both `example.com` and `*.example.com`.
- The existing destination folder is no longer deleted before issuing.
- Uninstall keeps certificates, acme.sh and certbot unless you ask for them to be removed.

### Removed

- Automatic installation on `pacman` systems. Install the required tools yourself on those systems.

## [1.0.0]

- First VESSL release, forked from [ESSL](https://github.com/erfjab/ESSL) by erfjab.
- Single-domain, multi-domain and wildcard certificates with acme.sh, certbot and the Cloudflare API.
- Renewal, revoke and uninstall options.
