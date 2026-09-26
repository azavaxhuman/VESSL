<div align="center">

# VESSL

**Very Easy SSL** — free Let's Encrypt certificates for your server and panels, from one friendly menu.

[![Version](https://img.shields.io/badge/version-2.0.0-2ea44f)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-4EAA25)](vessl.sh)

VESSL is a fork of [ESSL by erfjab](https://github.com/erfjab/ESSL).

</div>

```
  ██╗   ██╗███████╗███████╗███████╗██╗
  ██║   ██║██╔════╝██╔════╝██╔════╝██║
  ██║   ██║█████╗  ███████╗███████╗██║
  ╚██╗ ██╔╝██╔══╝  ╚════██║╚════██║██║
   ╚████╔╝ ███████╗███████║███████║███████╗
    ╚═══╝  ╚══════╝╚══════╝╚══════╝╚══════╝
  Very Easy SSL  v2.0.0
  forked from ESSL by erfjab

  ╭─ Server ─────────────────────────────────────────────────────────────────╮
  │ Host      vps-de-01             IP          203.0.113.10                 │
  │ Engines   ✓ acme.sh  ✓ certbot  Port 80     ● free                       │
  │ Certs     3 found               Cloudflare  ● saved                      │
  ╰──────────────────────────────────────────────────────────────────────────╯

  [1]    Issue certificate           one or more domains, HTTP
  [2]    Issue wildcard certificate  *.domain, DNS
  [3]    Check domain                preflight + staging test
  [4]    Show ports                  who is listening where
  [5]    My certificates             list with expiry
  [6]    Renew certificate           force renew an existing one
  [7]    Remove certificate          delete, revoke, stop renew
  [8]    Settings                    defaults and log
  [9]    Update VESSL                install or update from GitHub
  [10]   Uninstall VESSL             remove VESSL from this server
  [0]    Exit

  ❯ Select an option:
```

---

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [The menu](#the-menu)
- [Single and multi-domain certificates](#single-and-multi-domain-certificates)
- [Wildcard certificates](#wildcard-certificates)
- [Where certificates are saved](#where-certificates-are-saved)
- [Checking a domain before issuing](#checking-a-domain-before-issuing)
- [Port 80 and running services](#port-80-and-running-services)
- [Renewal](#renewal)
- [Removing and revoking a certificate](#removing-and-revoking-a-certificate)
- [Command-line reference](#command-line-reference)
- [Files VESSL uses](#files-vessl-uses)
- [Uninstalling](#uninstalling)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Upgrading from VESSL 1.x](#upgrading-from-vessl-1x)
- [Credits](#credits)
- [License](#license)

---

## Features

- **Interactive menu.** Type a number to open a section. Every step asks for input, shows a summary and waits for your confirmation.
- **Full command line.** Every menu action can also be run from the command line, so VESSL works in scripts and cron jobs.
- **Single, multi-domain and wildcard certificates.** Wildcards are validated through Cloudflare's API or through DNS TXT records you add by hand.
- **Preflight checks.** VESSL checks the Let's Encrypt API, your DNS records, CAA records, nameservers, port 80, the firewall and your Cloudflare credentials before it asks for a certificate.
- **Free staging test.** A test certificate from Let's Encrypt's staging server tells you whether the real request will succeed. It does not use up your rate limit.
- **Port inspector.** Shows every listening TCP port with the process, systemd service or Docker container behind it.
- **Automatic port 80 handling.** If a service or container holds port 80, VESSL can stop it for a few seconds and start it again. It sets up the same stop and start for every automatic renewal.
- **Two engines.** acme.sh is used first and certbot is the fallback. Certificates use ECDSA P-256 keys.
- **Ready-made panel paths** for Marzban, Marzneshin, PasarGuard, Rebecca, X-UI, 3X-UI, S-UI, Hiddify and OV-Panel, plus any custom folder.
- **Certificate overview.** Lists every certificate with a lifetime bar, the expiry date, whether it is a wildcard and how it renews.
- **Renew, remove, revoke and uninstall** from the same menu.
- **Clean output.** Progress bars and spinners replace the raw tool output. The full output is kept in a log file, and the last lines are shown when something fails, together with a likely cause.
- **Self-update** from this repository.

## Requirements

| | |
|---|---|
| Access | root |
| Shell | bash 4 or newer |
| Package manager | `apt` (Debian, Ubuntu) or `dnf` / `yum` (RHEL, CentOS, AlmaLinux, Rocky, Fedora) |
| Network | outbound HTTPS to Let's Encrypt, and inbound port 80 for HTTP validation |
| Optional | systemd and Docker, which VESSL uses to free port 80 temporarily |

VESSL installs what it needs on first use: `curl`, `socat`, `openssl`, `cron`, `certbot`, `dig` (from `dnsutils` or `bind-utils`), `ss` (from `iproute2`) and acme.sh.
On other distributions, install these tools yourself first, then run VESSL.

## Installation

Install VESSL as the `vessl` command:

```bash
sudo curl -fsSL https://raw.githubusercontent.com/azavaxhuman/VESSL/main/vessl.sh -o /usr/local/bin/vessl
sudo chmod +x /usr/local/bin/vessl
sudo vessl
```

Or run it once without installing:

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/azavaxhuman/VESSL/main/vessl.sh)"
```

To update, use menu option **9**, or run:

```bash
sudo vessl --update
```

## Quick start

1. Point your domain's **A record** (and its AAAA record, if you have one) to the server's IP address.
   If the domain is on Cloudflare, set the record to **DNS only** (grey cloud).
2. Run `sudo vessl`.
3. Choose **1** to issue a certificate, then enter your email, your domain and where the certificate should be saved.
4. Point your panel to the two files VESSL prints at the end:

   ```
   Private key /var/lib/marzban/certs/example.com/privkey.pem
   Full chain  /var/lib/marzban/certs/example.com/fullchain.pem
   ```

The same thing in a single command:

```bash
sudo vessl you@example.com example.com marzban
```

## The menu

Run `vessl` with no arguments. The box at the top shows the server's hostname and public IP, whether acme.sh and certbot are installed, who holds port 80, how many certificates were found (and how many expire within 15 days), and whether Cloudflare credentials are saved.

| # | Option | What it does |
|---|---|---|
| 1 | Issue certificate | Gets a certificate for one or more domains, validated over HTTP on port 80 |
| 2 | Issue wildcard certificate | Gets a certificate for `example.com` and `*.example.com`, validated through DNS |
| 3 | Check domain | Runs every preflight check and a staging test. Nothing real is issued |
| 4 | Show ports | Lists every listening TCP port with its process, service or container |
| 5 | My certificates | Lists certificates with a lifetime bar, the expiry date and how each one renews |
| 6 | Renew certificate | Renews a certificate now, even if it is not due yet |
| 7 | Remove certificate | Deletes a certificate, stops its auto-renew, and optionally revokes it |
| 8 | Settings | Sets your default email and destination, turns verbose output on or off, and shows the log |
| 9 | Update VESSL | Compares your version with GitHub and installs the latest one |
| 10 | Uninstall VESSL | Removes VESSL and, if you choose, its certificates, acme.sh and certbot |
| 0 | Exit | |

Type `0` at any prompt to go back. VESSL remembers the last email and destination you used and offers them as defaults.

## Single and multi-domain certificates

Menu option **1**, or on the command line:

```bash
sudo vessl you@example.com example.com marzban
sudo vessl you@example.com example.com www.example.com api.example.com /root/certs
```

Separate multiple domains with spaces (or with commas in the menu). One certificate covers all of them, and its folder is named after the first domain.

Issuing runs these steps, and each one shows a progress bar:

1. **Preparing dependencies.** Installs any missing tools.
2. **Preflight checks.** See [Checking a domain before issuing](#checking-a-domain-before-issuing).
3. **Freeing port 80.** See [Port 80 and running services](#port-80-and-running-services).
4. **Staging test**, only if you asked for one with `--test` or answered yes in the menu.
5. **Requesting certificate.** acme.sh is tried first and certbot is used if acme.sh fails.
6. **Finishing up.** Restarts anything that was stopped, records the certificate and shows a summary.

If the preflight checks only produce warnings, VESSL asks whether to continue. If they produce errors, it stops.

## Wildcard certificates

Menu option **2**, or `vessl --wildcard`. A wildcard certificate always covers the bare domain **and** every subdomain, for example `example.com` and `*.example.com`.
Wildcards need **DNS validation**, so port 80 is not used at all. VESSL uses acme.sh for wildcards and offers three ways to validate.

### Option A: Cloudflare API token (recommended)

The certificate **renews automatically**. The token can only edit DNS, so it cannot touch anything else in your account.

1. Open [dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens) → **Create Token**.
2. Pick the **Edit zone DNS** template, or create a custom token with these permissions:

   | Permission | Access |
   |---|---|
   | Zone → DNS | Edit |
   | Zone → Zone | Read |

3. Under **Zone Resources**, select your domain (or all zones), then create the token and copy it.
4. In VESSL choose **2 → Cloudflare API token** and paste it. The input is hidden.

```bash
sudo vessl --wildcard you@example.com example.com marzban --cf-token YOUR_TOKEN
```

Before requesting anything, VESSL checks that the token is active, that the zone exists in your account and that the domain uses Cloudflare nameservers.
acme.sh stores the token in `~/.acme.sh/account.conf` so the certificate can renew. After that, the menu offers **Cloudflare, saved** and you don't need to enter the token again.

### Option B: Cloudflare Global API Key

This also renews automatically, but the key has full access to your Cloudflare account. Use a token (option A) if you can.

```bash
sudo vessl --wildcard you@example.com example.com marzban --cf-key YOUR_KEY --cf-email you@cloudflare-login.com
```

You can find the key at **My Profile → API Tokens → Global API Key → View**.

### Option C: Manual DNS records (any DNS provider)

This works with any DNS provider, but **it cannot renew by itself**.

1. VESSL asks Let's Encrypt for a challenge and shows the TXT records to add, usually two of them with the same name:

   ```
   Record 1 of 2
     Type  TXT
     Name  _acme-challenge.example.com
           in most DNS panels just: _acme-challenge
     Value AbCdEf1234567890abcdef1234567890abcdefGHIJ
   ```

2. Add **every** record at your DNS provider. They share one name, so add both and don't replace one with the other.
3. Press Enter. VESSL checks your domain's authoritative nameserver for up to 10 minutes until the records appear, then completes validation.

```bash
sudo vessl --wildcard you@example.com example.com marzban --manual
```

> [!WARNING]
> Manual certificates must be renewed by hand before they expire. Open **VESSL → 6 Renew certificate** every ~60 days and add the new TXT records it shows. The certificate list marks these certificates as `manual renew`.

### Keeping tokens out of your shell history

Instead of passing a token on the command line, you can use environment variables, which acme.sh also understands:

```bash
export CF_Token="YOUR_TOKEN"
sudo -E vessl --wildcard you@example.com example.com /root/certs -y
```

VESSL never writes tokens to its own log or config files.

## Where certificates are saved

Every certificate goes into **its own folder named after the first domain**, and the folder always contains two files:

| File | Contents |
|---|---|
| `privkey.pem` | private key |
| `fullchain.pem` | certificate plus intermediate chain |

### Panel shortcuts

| Name | Folder |
|---|---|
| `marzban` | `/var/lib/marzban/certs/<domain>/` |
| `marzneshin` | `/var/lib/marzneshin/certs/<domain>/` |
| `pasarguard` | `/var/lib/pasarguard/certs/<domain>/` |
| `rebecca` | `/var/lib/rebecca/certs/<domain>/` |
| `x-ui`, `3x-ui`, `s-ui`, `hiddify` | `/certs/<domain>/` |
| `ovpanel` | `/opt/ov-panel/data/<domain>/` |

### Custom path

Any absolute path works. **A trailing slash makes no difference**: `/root/certs` and `/root/certs/` are the same, and repeated slashes are cleaned up as well. VESSL creates the domain folder inside the path you give:

```
/root/certs   →   /root/certs/example.com/privkey.pem
                  /root/certs/example.com/fullchain.pem
```

The menu shows the final folder right after you type the path, and the summary shows it again before anything starts.

### Example: Marzban

In `/opt/marzban/.env`:

```
UVICORN_SSL_CERTFILE = "/var/lib/marzban/certs/example.com/fullchain.pem"
UVICORN_SSL_KEYFILE = "/var/lib/marzban/certs/example.com/privkey.pem"
```

Then run `marzban restart`. For other panels, enter the same two paths in the panel's certificate settings.

## Checking a domain before issuing

Menu option **3**, or:

```bash
sudo vessl --check example.com www.example.com
```

A check never issues a real certificate and never touches the certificates you already have. It runs the preflight checks, frees port 80 if needed, and then requests a **test certificate from Let's Encrypt staging**. At the end you get a clear answer:

```
  ╭─ Result ──────────────────────────────────────────╮
  │ ✓ A certificate can be obtained for example.com   │
  ╰───────────────────────────────────────────────────╯
```

### What the preflight checks look at

| Check | Result if it fails |
|---|---|
| Let's Encrypt API is reachable | **error**, stops |
| The server's public IPv4 and IPv6 addresses | warning |
| A and AAAA records point to this server | warning, because NAT and load balancers can be fine |
| CAA records allow `letsencrypt.org` | warning |
| Who holds port 80 and port 443 | information |
| ufw or firewalld allows port 80 | warning |

Wildcard issuing runs its own checks: the Let's Encrypt API, the domain's nameservers (and whether they belong to Cloudflare), the CAA `issuewild` record, your Cloudflare credentials and the Cloudflare zone.

`--check` exit codes: `0` a certificate can be obtained, `1` it cannot, `2` the test could not run completely.

## Port 80 and running services

HTTP validation needs port 80 for a few seconds. Menu option **4** (or `vessl --ports`) shows who is using each port:

```
  PORT    ADDRESS                    PROCESS            PID       OWNER
  ────────────────────────────────────────────────────────────────────────
  80      0.0.0.0                    nginx              812       service:nginx.service
  443     0.0.0.0                    docker-proxy       1290      container:marzban
  8000    127.0.0.1                  python3            1402      -
```

When port 80 is busy during issuing:

- If a **systemd service** or a **Docker container** holds it, VESSL asks whether it may stop that service. It stops it, gets the certificate, and starts it again, even if something fails along the way or you press Ctrl+C.
- The same stop and start is registered as a pre-hook and post-hook, so **automatic renewals free port 80 the same way**.
- If some other process holds the port, VESSL shows it and asks you to stop it yourself.

## Renewal

| Certificate type | How it renews |
|---|---|
| HTTP, issued with acme.sh | automatically, by the acme.sh cron job |
| HTTP, issued with certbot | automatically, by the certbot timer |
| Wildcard with Cloudflare | automatically, by the acme.sh cron job through the Cloudflare API |
| Wildcard with manual DNS | **by hand**, with VESSL → 6 Renew certificate |

Renewed files are copied into the same folder automatically, so your panel keeps using the same paths.
If your panel only reads the certificate at startup, restart the panel after a renewal.

To renew right now, choose menu option **6** and pick the certificate, or run the original command again with `--force`:

```bash
sudo vessl you@example.com example.com marzban --force
```

Menu option **5** (or `vessl --list`) shows how long each certificate has left:

```
  [1]    example.com                 ███████████████░  84 days left · 2026-12-18
         /var/lib/marzban/certs/example.com/ · auto-renew · HTTP
  [2]    example.org                 ██████████░░░░░░  55 days left · 2026-11-19
         /root/certs/example.org/ · wildcard · auto-renew · Cloudflare DNS
```

## Removing and revoking a certificate

Menu option **7**. VESSL shows what it will delete and asks for confirmation. Removing a certificate:

- deletes `privkey.pem` and `fullchain.pem`, and the folder if it is left empty,
- removes the certificate from acme.sh or certbot, so it stops renewing,
- removes it from the VESSL certificate list.

VESSL can also **revoke** the certificate at Let's Encrypt. You only need to revoke if the private key was exposed or you no longer control the domain.

> [!NOTE]
> A panel that still points to deleted files will fail to start until you give it another certificate.

## Command-line reference

```
vessl                                          open the interactive menu
vessl <email> <domain...> <destination> [options]
vessl --wildcard <email> <domain> <destination> [dns options]
vessl --check [email] <domain...>
vessl --ports | --list
vessl --install | --update | --uninstall | --help | --version
```

### Commands

| Command | Description |
|---|---|
| *(none)* / `-m`, `--menu` | Open the interactive menu |
| `<email> <domain...> <destination>` | Issue a certificate over HTTP |
| `-w`, `--wildcard <email> <domain> <destination>` | Issue a wildcard certificate for `domain` and `*.domain` |
| `-c`, `--check [email] <domain...>` | Run the preflight checks and a staging test |
| `-p`, `--ports` | Show listening TCP ports and who owns them |
| `-l`, `--list` | Show certificates and their expiry |
| `-u`, `--update` | Download the latest VESSL from GitHub (`--upgrade` also works) |
| `--install` | Install the running file as `/usr/local/bin/vessl` |
| `--uninstall` | Remove VESSL |
| `-h`, `--help` | Show help |
| `-v`, `--version` | Show the version |

### Options

| Option | Description |
|---|---|
| `--test` | Run a staging test before the real request (HTTP only) |
| `--skip-check` | Skip the preflight checks |
| `--force` | Renew even if the current certificate is still valid |
| `--verbose` | Show the raw acme.sh and certbot output instead of spinners |
| `-y`, `--yes` | Answer yes to every prompt |
| `--purge` | With `--uninstall`: also delete certificates, acme.sh and certbot |

### Wildcard DNS options

| Option | Description |
|---|---|
| `--cf-token <token>` | Cloudflare API token |
| `--cf-key <key>` and `--cf-email <email>` | Cloudflare Global API Key and the account's email |
| `--manual` | Show TXT records to add by hand (needs a terminal) |

If you give none of these, VESSL looks for the `CF_Token` environment variable, then for `CF_Key` together with `CF_Email`, then for credentials already saved in acme.sh. If it finds nothing and a terminal is available, it asks.

### Examples

```bash
vessl --check example.com
vessl you@example.com example.com marzban
vessl you@example.com example.com www.example.com /root/certs --test
vessl you@example.com sub.example.com 3x-ui -y
vessl --wildcard you@example.com example.com marzban --cf-token XXXX
vessl --wildcard you@example.com example.com /root/certs --manual
vessl --list
vessl --uninstall
```

### Running without a terminal

When VESSL's output goes to a file or a pipe, colors and spinners are turned off automatically and the raw tool output is printed instead. Setting `NO_COLOR=1` also turns colors off.
Combine with `-y` to skip the prompts, for example in a provisioning script:

```bash
vessl you@example.com example.com marzban -y >> /var/log/provision.log 2>&1
```

## Files VESSL uses

| Path | Contents |
|---|---|
| `/usr/local/bin/vessl` | the script |
| `/etc/vessl/config` | default email, default destination, verbose setting |
| `/etc/vessl/certs.db` | certificates issued with VESSL: domains, folder, email, engine, validation method |
| `/var/log/vessl.log` | full output of every acme.sh, certbot and package-manager run |
| `~/.acme.sh/` | acme.sh, its certificates and its saved Cloudflare credentials |
| `/etc/letsencrypt/` | certbot data |

Menu option **8 → Show recent log** prints the last 40 lines of the log.

## Uninstalling

Menu option **10**, or:

```bash
sudo vessl --uninstall
```

These are always removed:

- `/usr/local/bin/vessl`
- `/etc/vessl`
- `/var/log/vessl.log`

VESSL then asks about each of the following. By default all of them are **kept**:

- the certificates issued with VESSL, which also stops their auto-renew,
- acme.sh, which stops renewal of **every** certificate acme.sh manages,
- certbot and `/etc/letsencrypt`, which may also hold certificates from other tools.

You confirm by typing `uninstall`. With `-y`, only VESSL itself is removed. With `--purge`, everything listed above is removed as well.
Shared tools such as curl, socat, openssl, dig and cron are never removed.

## Troubleshooting

When a request fails, VESSL shows the last lines of the tool's output with a likely cause, and the complete output is in `/var/log/vessl.log`. Run `vessl --check <domain>` for a full diagnosis.

| Message or symptom | Likely cause | Fix |
|---|---|---|
| `… does not match this server` | The A or AAAA record points to another IP, or Cloudflare's proxy is on | Fix the record and turn the orange cloud off. A wrong **AAAA** record is a common cause, because Let's Encrypt prefers IPv6 |
| `Another server answered on port 80` | The domain points to a CDN or to another server | Point the domain directly to this server |
| `Let's Encrypt could not reach port 80` | The provider's firewall or security group blocks port 80 | Open inbound TCP 80 in the provider's panel and in `ufw` or `firewalld` |
| `Port 80 is held by a process that is not a systemd service or a docker container` | Something was started by hand | Find it with `vessl --ports`, stop it, and try again |
| `CAA record … does not allow Let's Encrypt` | A CAA record allows only another certificate authority | Add `0 issue "letsencrypt.org"`, plus `0 issuewild "letsencrypt.org"` for wildcards |
| `Rate limit reached` | Too many failed or duplicate requests | Wait, and use `--check` or `--test` while you experiment, because staging requests don't count |
| `Cloudflare rejected the API token` | Wrong token or missing permissions | Create a token with **Zone → DNS → Edit** and **Zone → Zone → Read** |
| `No Cloudflare zone was found` | The domain is not in that Cloudflare account, or the token is limited to other zones | Add the domain to Cloudflare or change the token's zone resources |
| `… does not use Cloudflare nameservers` | The domain's DNS is hosted elsewhere | Change the nameservers to Cloudflare, or use manual DNS |
| `The records are not visible yet` (manual DNS) | The TXT records were not added yet, or DNS is still updating | Check the name and value, wait a minute, and answer yes to try anyway |
| `refuses to issue for this domain name by policy` | The name is reserved or blocked by Let's Encrypt | Use a domain you own |
| `acme.sh could not be installed` | GitHub cannot be reached from this server | Certbot is used instead for HTTP certificates. Wildcards need acme.sh |

## FAQ

**Can one certificate cover several different domains?**
Yes. List them all: `vessl you@example.com a.com b.net c.org /root/certs`. The folder is named after the first one.

**Does a wildcard cover the bare domain?**
Yes. VESSL always requests `example.com` and `*.example.com` together. Note that `*.example.com` does not cover deeper names such as `a.b.example.com`.

**Which key type do the certificates use?**
acme.sh issues ECDSA P-256 certificates, and certbot 2.x also uses ECDSA by default. Current browsers, Xray and the common panels all accept them.

**Can I use VESSL behind a NAT or a load balancer?**
Yes. The DNS check then gives a warning, and you can continue. Port 80 on the public address must still reach this server for HTTP validation. Otherwise use a wildcard certificate with DNS validation.

**My panel runs in Docker. Can it read the files?**
Only if the container mounts the folder. Marzban, for example, mounts `/var/lib/marzban`, so its certificate folder is visible inside the container. If you use a custom path, add it to the container's volumes.

**Where do I report a bug?**
[Open an issue](https://github.com/azavaxhuman/VESSL/issues/new/choose) and include the output of `vessl --version`, `vessl --check <domain>`, and the relevant part of `/var/log/vessl.log` with any tokens removed.

## Upgrading from VESSL 1.x

VESSL 2 is a complete rewrite. Things to know when you upgrade:

- The command is now `vessl`, installed at `/usr/local/bin/vessl`. The old `essl` / `essl.sh` files can be deleted.
- **File names changed.** VESSL 1 saved acme.sh certificates as `fullchain.cer` and `privkey.key`. VESSL 2 always saves `fullchain.pem` and `privkey.pem`. **Update the paths in your panel** after you issue a new certificate with VESSL 2.
- **Re-issue your old certificates with VESSL 2.** VESSL 1 copied the files into the panel folder only once, so when acme.sh or certbot renewed a certificate, the new copy never reached your panel. VESSL 2 registers the folder with acme.sh or certbot, so every renewal is copied there automatically.
- VESSL 2 lists certificates from its own list and any `fullchain.pem` inside the panel folders, so files named `fullchain.cer` do not appear in the list.
- Wildcards with Cloudflare now work with a scoped API token as well as the Global API Key, and they renew automatically.
- Uninstall no longer deletes everything by default. You choose what goes.

See [CHANGELOG.md](CHANGELOG.md) for the full list of changes.

## Credits

- [ESSL](https://github.com/erfjab/ESSL) by **erfjab**, the project VESSL is forked from.
- [acme.sh](https://github.com/acmesh-official/acme.sh) and [Certbot](https://certbot.eff.org/), which do the actual work.
- [Let's Encrypt](https://letsencrypt.org/), for free certificates for everyone.

## License

VESSL is released under the [GNU General Public License v3.0](LICENSE).
