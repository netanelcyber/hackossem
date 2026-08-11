# Architecture

## The one idea

Windows Setup scans the **root of every mounted volume** for `autounattend.xml`
and applies the first one it finds. So a fully unattended install needs no
modification of the Windows ISO at all — you attach a *second*, tiny ISO
carrying the answer file, and Setup picks it up.

Everything else follows from that.

## Data flow

```
lab.conf ── the single source of truth ──────────────────────────────────┐
  VM table: name:os:ram:cpu:disk:octet:role                              │
  domain, credentials, network, ISO edition names                        │
        │                                                                 │
        ├─▶ generate-inventory.sh ──▶ inventory/hosts.ini (for Ansible)   │
        │                                                                 │
        └─▶ build-unattend-iso.sh                                         │
              render templates/autounattend.xml.tmpl  (per VM)            │
              render templates/bootstrap.ps1.tmpl      (per VM)           │
              pack → build/<vm>/unattend.iso                              │
                        │                                                 │
create-vms.sh ─────────┘                                                  │
  VBoxManage createvm / createmedium / storagectl                        │
  attach SATA port 1 = Windows.iso, port 2 = unattend.iso                │
  NIC = host-only (reachable from the Ansible controller)                │
        │                                                                 │
        ▼                                                                 │
boot (headless)                                                          │
  Windows installs unattended from autounattend.xml                     │
  first logon → FirstLogonCommands → bootstrap.ps1:                      │
     • static IP from the table                                          │
     • DNS → forest root (or self, on the root)                          │
     • WinRM: HTTP + Basic (lab-grade), firewall opened                  │
     • DCs: pre-install ADDS+DNS role binaries (free wall-clock)         │
        │                                                                 │
        ▼                                                                 │
wait-for-winrm.sh  — polls :5985 until every VM answers ◀────────────────┘
        │
        ▼
apply-provisioning.sh → playbooks/site.yml
  00-preflight     identity + reachability
  10-forest-root   promote forest (serial), wait for AD Web Services
  20-domain-join   members join (DNS already points at the DC)
  30-lab-content   OUs, users, a kerberoastable SPN
        │
        ▼
health-check.sh — domain reachable, users present, members joined
```

## Why each non-obvious choice

**Host-only, not internal networking.** An `intnet` is isolated from the host;
the Ansible controller runs on the host, so it must be host-only. VirtualBox
6.1.28+ restricts host-only to `192.168.56.0/21`, so the lab lives on
`192.168.56.0/24`.

**DNS is set in bootstrap, before Ansible.** The most common failure in a
hand-built AD lab is a member trying to join while its DNS still points
somewhere that can't resolve the domain. Here every non-root machine is born
pointing at the forest root, and the root points at itself.

**AD promotion is in Ansible, not bootstrap.** Promotion has ordering
constraints (root before child before members) and long reboot/settle cycles
that Ansible expresses cleanly with `serial`, `until` retries, and
`microsoft.ad`. Bootstrap only pre-installs the *role binaries* on DCs, which
is free because it happens while other VMs are still installing Windows.

**BIOS/MBR firmware.** `autounattend.xml` contains an MBR disk layout, and
VirtualBox defaults Windows guests to BIOS. The two must agree; switching to
EFI means switching both.

**One VM table, read everywhere.** `lab.conf` holds the only copy of the VM
list. Inventory, unattend media, resource checks, boot order and cleanup all
derive from it, so there is nothing to keep in sync by hand. (The previous
iteration of this project hardcoded the VM list separately in three scripts —
that class of drift is designed out.)

## `mkiso.py`

A lab machine may not have `xorriso`/`genisoimage`. The payload is two small
files at a volume root — comfortably inside a flat, single-directory ISO9660
Level 2 image — so a ~250-line stdlib writer removes the dependency entirely.
It emits a Primary Volume Descriptor, a one-sector root directory, and L/M path
tables; `--verify` re-parses the image from bytes and hashes each file so the
output is checked, not assumed. Native writers are still preferred when present.

## Idempotency

Every layer is safe to re-run:

- `create-vms.sh` skips existing VMs unless `--force`.
- The playbooks use idempotent modules; the SPN task tolerates a duplicate.
- A broken run is recovered by fixing the cause and running again, not by
  tearing down — with the sole exception of a VM whose Windows install itself
  failed, which `cleanup-vms.sh --force`-style recreation handles.
