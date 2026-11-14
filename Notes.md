# macOS vs Linux — Notes

I ran `check-tools.sh` on two machines:

- **Mac:** MacBook Pro, macOS (Darwin), arm64, Bash 3.2.57
- **Linux:** Ubuntu 24.04, x86_64, Bash 5.2.21

## 1. Bash version
- **Observed:** macOS ships Bash 3.2.57; Ubuntu ships Bash 5.2.21.
- **Why:** Bash 4+ is licensed under GPLv3. Apple doesn't ship GPLv3 software, so macOS
  is stuck on 3.2 and switched its default shell to zsh.
- **Impact:** Scripts that use Bash 4+ features (`declare -A`, `mapfile`) break on macOS.
  I kept this script 3.2-compatible so it runs on both.

## 2. Docker: client vs daemon
- **Observed:** Both machines report Docker 29.x.
- **Why:** `docker --version` only shows the CLI version. On Linux the daemon runs directly
  on the host kernel. On macOS it runs inside a Linux VM, because containers depend on
  Linux kernel features (namespaces, cgroups).
- **Impact:** "Installed" doesn't mean "running". A real health check has to query the
  daemon (`docker version --format '{{.Server.Version}}'`).

## 3. TLS libraries
- **Observed:** On macOS, `curl` and `ssh` are built against LibreSSL 3.3.6. On Ubuntu
  they use OpenSSL 3.0.13.
- **Why:** OpenSSL is the default chosen by Ubuntu/Debian. It's a distribution choice,
  not part of Linux itself. Apple stopped shipping OpenSSL as a system library because it
  didn't keep a stable ABI between versions. macOS apps use Apple's own crypto frameworks,
  and the bundled command-line tools use LibreSSL, a fork of OpenSSL that OpenBSD created
  in 2014 after Heartbleed.
- **Impact:** The two systems keep trusted certificates in different places: Ubuntu in
  `/etc/ssl/certs`, macOS in the Keychain. A company root CA added on my Mac doesn't exist
  on a Linux server or inside a container, so the same request can work locally and fail
  elsewhere with `certificate signed by unknown authority`. Even `openssl` on macOS is
  actually LibreSSL, so flags and error messages don't always match.

## 4. Universal binaries
- **Observed:** The Mac is arm64, but `curl --version` reports `x86_64-apple-darwin24.0`.
- **Why:** `/usr/bin/curl` is a universal (fat) Mach-O binary that contains both x86_64
  and arm64 code. macOS runs the part that matches the CPU, so no Rosetta is involved.
  The `x86_64` string is a label baked in when curl was built; it doesn't show what is
  running now. `file /usr/bin/curl` lists both architectures.
- **Impact:** Linux has no universal binaries; each architecture gets its own package
  (amd64, arm64). The same applies to container images: an image built on an Apple
  Silicon Mac is arm64 by default and fails on an x86_64 server with `exec format error`.
  Fix: `docker buildx build --platform linux/amd64`, or publish a multi-arch image.

## 5. Which python3?
- **Observed:** `python3` is 3.14 on the Mac and 3.12 on Ubuntu.
- **Why:** macOS has more than one `python3`: Apple's `/usr/bin/python3` (older, from the
  Command Line Tools) and Homebrew's `/opt/homebrew/bin/python3`. The shell searches
  `PATH` left to right and runs the first match, and Homebrew puts its directory first
  (`which -a python3` shows all of them). On Ubuntu, `/usr/bin/python3` is the system
  Python that OS tools like apt depend on.
- **Impact:** `#!/usr/bin/python3` and `#!/usr/bin/env python3` can run different
  interpreters on the same machine, and packages installed for one aren't visible to the
  other. Ubuntu blocks `pip install` into the system Python (`externally-managed-environment`,
  PEP 668). Use a virtual environment per project.

## 6. Version drift
- **Observed:** kubectl 1.37.2 on the Mac vs 1.36.1 on Linux; Helm 4 only on the Mac;
  jq 1.8.2 vs 1.7; Docker CLI 29.3.1 vs 29.9.3.
- **Why:** The tools were installed at different times from different sources (Homebrew
  on the Mac; apt, snap and Docker's own repository on Linux), and each one updates on its
  own. Nothing pins the versions.
- **Impact:** A command or flag that works on one machine can fail on the other: the
  classic "works on my machine". kubectl is only supported within ±1 minor version of the
  cluster's API server, so drift can also break cluster access. In a team this gets worse
  with every laptop. Fixes: pin versions in a `.tool-versions` file (mise/asdf), or use a
  devcontainer or container image with fixed tool versions.

## Takeaways
- "Installed", "running" and "same version" are three different checks.
- Write scripts for the oldest target you support (Bash 3.2 on macOS).
- Build and test for the architecture you deploy to.

MACBOOK 
System : Darwin arm64 — Burak-ve-MacBook-Pro.local
Bash   : 3.2.57(1)-release

git        git version 2.39.5 (Apple Git-154)
curl       curl 8.7.1 (x86_64-apple-darwin24.0) libcurl/8.7.1 (SecureTransport) LibreSSL/3.3.6 zlib/1.2.12 nghttp2/1.62.0
ssh        OpenSSH_9.8p1, LibreSSL 3.3.6
python3    Python 3.14.10
docker     Docker version 29.3.1, build c2be9cc
multipass  MISSING
virsh      MISSING
kubectl    Client Version: v1.37.2
helm       v4.3.2+g8346aaa
terraform  MISSING
ansible    MISSING
jq         jq-1.8.2

Missing tool: 4

LINUX

System : Linux x86_64 — LinuxBurak
Bash   : 5.2.21(1)-release

git        git version 2.43.0
curl       curl 8.5.0 (x86_64-pc-linux-gnu) libcurl/8.5.0 OpenSSL/3.0.13 zlib/1.3 brotli/1.1.0 zstd/1.5.5 libidn2/2.3.7 libpsl/0.21.2 (+libidn2/2.3.7) libssh/0.10.6/openssl/zlib nghttp2/1.59.0 librtmp/2.3 OpenLDAP/2.6.10
ssh        OpenSSH_9.6p1 Ubuntu-3ubuntu13.20, OpenSSL 3.0.13 30 Jan 2024
python3    Python 3.12.3
docker     Docker version 29.9.3, build 5457199
multipass  multipass   1.17.0
virsh      10.0.0
kubectl    Client Version: v1.36.1
helm       MISSING
terraform  MISSING
ansible    MISSING
jq         jq-1.7


