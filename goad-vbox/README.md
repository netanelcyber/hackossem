# GOAD on VirtualBox — unattended, Ansible-provisioned, no Vagrant

Stand up a [Game of Active Directory](https://github.com/Orange-Cyberdefense/GOAD)–style
lab on **VirtualBox** with **one command** and **no GUI interaction**. VMs are
created with `VBoxManage`, Windows installs itself from a generated
`autounattend.xml`, and Active Directory is promoted by Ansible.

No Vagrant. No manual Windows setup. No clicking through OOBE.

```bash
# after ISOs are in place:
scripts/deploy-all.sh --variant full \
  --iso-win2016 /isos/WinServer2016.iso \
  --iso-win2019 /isos/WinServer2019.iso
```

That single command runs: prerequisite check → host-only network → per-VM
unattend media → VM creation → boot → wait for WinRM → Ansible provisioning →
health check.

---

## How it works

GOAD has three stages; this project automates all three on VirtualBox:

| Stage | What happens here |
|-------|-------------------|
| **Templating** | A per-VM `autounattend.xml` + `bootstrap.ps1` are generated and packed into a tiny ISO (`build-unattend-iso.sh`). |
| **Providing** | `VBoxManage` creates each VM and attaches the Windows ISO **and** the unattend ISO (`create-vms.sh`). |
| **Provisioning** | Windows self-installs; `bootstrap.ps1` sets a static IP, DNS and WinRM; then Ansible promotes AD and joins members (`playbooks/`). |

The trick that removes all manual Windows work: Windows Setup scans the root of
**every** attached volume for `autounattend.xml`. Attaching a second small ISO
means the Windows media itself is never modified.

```
generate autounattend.xml + bootstrap.ps1   ──▶  pack into unattend.iso
create VM, attach [Windows.iso] + [unattend.iso]
        │
        ▼
Windows installs unattended ──▶ first logon runs bootstrap.ps1
        │                             (static IP, DNS→root DC, WinRM on)
        ▼
host waits for :5985 ──▶ Ansible: promote forest ▶ join members ▶ seed content
```

---

## Variants

Defined in [`lab.conf`](lab.conf) — one table, edited in one place.

| Variant | Machines | Notes |
|---------|----------|-------|
| `full`  | dc01, dc02 (2016) · srv02, srv03 (2019) · ws01 (Win10) | Two-DC forest. |
| `light` | dc01 (2016) · srv02 (2019) · ws01 (Win10) | Minimal, laptop-friendly. |
| `nested`| dc01 (Server 2022) · ws01–ws03 (Win10) | Runs **inside** one portable L1 VM — see [Nested topology](#nested-topology). |

All machines share a host-only network on **192.168.56.0/24** (host at
`.1`), addressed statically from the table.

> **Why host-only, not internal?** A VirtualBox *internal* network (`intnet`)
> is isolated from the host, so an Ansible controller on the host could never
> reach the guests. Host-only gives host↔guest and guest↔guest with no
> internet exposure. Since VirtualBox 6.1.28 host-only addresses must fall in
> `192.168.56.0/21` unless `/etc/vbox/networks.conf` says otherwise — hence
> `.56`.

---

## Prerequisites

- **VirtualBox 6.1+** (7.0+ for a native `Windows2022_64` OS type; older falls back automatically)
- **Ansible** with `pywinrm` and the `ansible.windows`, `microsoft.ad`, `community.windows` collections
- **An ISO writer** — `xorriso`/`genisoimage`/`mkisofs`/`hdiutil`, or none: a
  pure-Python fallback (`scripts/lib/mkiso.py`) is bundled
- **Windows evaluation ISOs** for the editions your variant uses
- Enough RAM/disk for the variant (checked for you)

Verify everything, scaled to your chosen variant:

```bash
scripts/check-requirements.sh --variant full \
  --iso-win2016 /isos/WinServer2016.iso --iso-win2019 /isos/WinServer2019.iso
```

Install the Ansible side:

```bash
python3 -m pip install pywinrm
ansible-galaxy collection install ansible.windows microsoft.ad community.windows
```

---

## Usage

### One-shot (recommended)

```bash
scripts/deploy-all.sh --variant light \
  --iso-win2016 /isos/WinServer2016.iso \
  --iso-win2019 /isos/WinServer2019.iso
```

Add `--yes` to skip the confirmation prompt, `--skip-provision` to build and
boot the VMs but stop before Ansible.

### Step by step

Every step is also a standalone script if you want control or to re-run one:

```bash
scripts/network-setup.sh                       # host-only interface on .56.1
scripts/build-unattend-iso.sh --variant full   # build/<vm>/unattend.iso
scripts/create-vms.sh        --variant full --iso-win2016 ... --iso-win2019 ...
# boot them (deploy-all does this for you):
#   VBoxManage startvm dc01 --type headless   # etc.
scripts/wait-for-winrm.sh    --variant full    # blocks until :5985 answers
scripts/apply-provisioning.sh --variant full   # regenerates inventory, runs site.yml
scripts/health-check.sh      --variant full
```

### Verify / tear down

```bash
scripts/health-check.sh  --variant full
scripts/cleanup-vms.sh   --variant full            # add --build to wipe build/
```

---

## Nested topology

`--variant nested` targets a single Server 2022 DC plus three Windows 10
endpoints running **inside one L1 VM**, so the whole lab is a portable unit.

```
physical host
└── goad-l1                    Linux, nested-hw-virt ON, runs VirtualBox
    ├── dc01                   Windows Server 2022  (forest root)
    ├── ws01 / ws02 / ws03     Windows 10
```

```bash
# on the physical host — build the L1 shell:
scripts/create-l1-host.sh --iso /isos/debian-12.iso
# then, inside L1:
sudo bash templates/l1-provision.sh          # installs VirtualBox + Ansible
scripts/deploy-all.sh --variant nested \
  --iso-win2022 /isos/WinServer2022.iso --iso-win10 /isos/Win10.iso
```

> **Honest caveat:** VirtualBox-inside-VirtualBox is **not** supported by
> Oracle. It generally works on AMD-V and is flakier on Intel VT-x, and nested
> Windows guests run several times slower than flat ones. `create-l1-host.sh`
> tunes L1 for the best chance (nested paging, IOAPIC, KVM paravirt) and
> refuses early if the host exposes no virtualisation extensions — but if a
> nested guest won't boot, that's the known trade-off of this choice. The flat
> `full`/`light` variants remain the reliable path.

---

## Layout

```
lab.conf                     Single source of truth: VMs, network, creds, ISOs
ansible.cfg                  WinRM-friendly Ansible defaults
scripts/
  deploy-all.sh              End-to-end orchestrator
  check-requirements.sh      Host readiness, scaled to the variant
  network-setup.sh           Host-only interface
  build-unattend-iso.sh      Generate per-VM unattend media
  create-vms.sh              Create + configure the VMs
  create-l1-host.sh          Build the nested L1 host
  wait-for-winrm.sh          Block until installs finish
  generate-inventory.sh      Inventory from lab.conf (never hand-edited)
  apply-provisioning.sh      Run the playbooks
  health-check.sh            Post-build verification
  cleanup-vms.sh             Tear down
  lib/common.sh              Shared helpers
  lib/mkiso.py               Dependency-free ISO9660 writer
templates/
  autounattend.xml.tmpl      Unattended-install answer file
  bootstrap.ps1.tmpl         First-logon: IP, DNS, WinRM, role binaries
  l1-provision.sh            Sets up VirtualBox+Ansible inside L1
playbooks/
  site.yml                   preflight → forest → join → content
  00-preflight / 10-forest-root / 20-domain-join / 30-lab-content
docs/
  ARCHITECTURE.md            Design & data flow
  TROUBLESHOOTING.md         Failure modes and fixes
```

`build/` (generated media) and `inventory/hosts.ini` (generated) are
gitignored.

---

## Security note

This is a **deliberately insecure lab**. WinRM runs over HTTP with Basic auth
and a shared lab password (`lab.conf`), Defender realtime and Windows Update
are disabled, and `30-lab-content.yml` plants a kerberoastable service account
on purpose. Keep it on the isolated host-only network. Do not reuse any of it
anywhere reachable.

---

## Status

Built and verified on this repo:

- All shell scripts pass `shellcheck -S warning` and were run against a mocked
  `VBoxManage` (create / idempotent-skip / `--force` / full `deploy-all` chain).
- `mkiso.py` output is verified by re-parsing the image and by `file(1)`;
  payloads round-trip by SHA-256.
- Generated `autounattend.xml` is XML-validated for every VM; playbook YAML
  parses.

Not yet exercised here (needs real hardware): the actual Windows installs,
live WinRM, and the Ansible AD promotion. Those steps are wired and validated
as far as is possible without a hypervisor, but have not been run against real
guests.
