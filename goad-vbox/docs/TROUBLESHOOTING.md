# Troubleshooting

Ordered by where it bites you in the pipeline.

## Host / prerequisites

**`vboxdrv` / `vboxnetadp` not loaded (Linux).**
```bash
sudo modprobe vboxdrv vboxnetadp
```
`vboxnetadp` is specifically what host-only interface creation needs.

**Host-only creation refused / address rejected.** VirtualBox ≥ 6.1.28 only
allows host-only ranges inside `192.168.56.0/21`. The lab already uses `.56`;
if you changed `GOAD_SUBNET` in `lab.conf`, move it back or add your range to
`/etc/vbox/networks.conf`:
```
* 192.168.0.0/16
```

**`pywinrm missing` from check-requirements.** Ansible can't speak WinRM
without it:
```bash
python3 -m pip install pywinrm
```

**A `microsoft.ad` / `ansible.windows` collection is missing.**
```bash
ansible-galaxy collection install ansible.windows microsoft.ad community.windows
```

## Unattended install

**Setup stops and asks which edition to install.** The edition name in
`lab.conf` (`IMAGE_win2019=...`) doesn't match your media. List what's actually
in the ISO and copy a name verbatim:
```bash
7z l WinServer2019.iso      # look at sources/install.wim
#   ...or on Windows:  dism /Get-WimInfo /WimFile:D:\sources\install.wim
```
Then set either the exact name or an index:
```
IMAGE_win2019="/IMAGE/INDEX=2"
```
Remember Desktop Experience is the confusingly-named plain `SERVERSTANDARD`;
`SERVERSTANDARDCORE` is the GUI-less one.

**Install hangs at a disk/partition step.** The template is BIOS/MBR. If you
switched the VM to EFI firmware, the MBR `DiskConfiguration` no longer matches —
revert the firmware, or replace the disk layout with a GPT one.

**`bootstrap.ps1` didn't run.** Read `C:\goad-bootstrap.log` inside the guest
(attach a console with `VBoxManage startvm <vm> --type separate`). Each step
logs `OK`/`FAIL`. The unattend runs it via a drive-letter sweep (`D:`…`J:`), so
it works regardless of which letter the unattend volume lands on.

## WinRM / reachability

**`wait-for-winrm.sh` times out.** It prints each VM's power state on timeout.
- VM `running` but `:5985` never opens → the install didn't finish or bootstrap
  failed; check `C:\goad-bootstrap.log`.
- VM `poweroff` → the install failed early; recreate it with
  `create-vms.sh --force`.

**`win_ping` fails but the port is open.** Almost always the lab password in
`lab.conf` (`GOAD_ADMIN_PASSWORD`) doesn't match what `autounattend.xml` baked
in — regenerate media (`build-unattend-iso.sh`) if you changed it after the
VMs were built.

**Can reach the DC but a member can't.** Confirm the member's DNS is the forest
root:
```bash
ansible -i inventory/hosts.ini srv02 -m ansible.windows.win_shell \
  -a 'Get-DnsClientServerAddress -AddressFamily IPv4'
```
It should list the root DC's `192.168.56.x`. bootstrap sets this; if it's wrong
the machine booted with stale media.

## Ansible provisioning

**Forest promotion "fails" on a re-run.** Promotion tasks are guarded, but if
you see it stop at "wait for AD Web Services", the DC is still rebooting. The
task retries 30×20s; if it exhausts that, give the DC longer and re-run —
playbooks are idempotent.

**Domain join fails with "cannot contact domain controller."** DNS again — see
above. `20-domain-join.yml` waits for the domain to resolve before trying, so a
failure here means DNS never became correct, not a transient miss.

**Everything is just slow (nested variant).** Expected. VirtualBox-in-
VirtualBox runs Windows guests several times slower than flat. If a nested
guest won't boot at all, confirm L1 actually received nesting:
```bash
grep -owE 'vmx|svm' /proc/cpuinfo   # run INSIDE L1 — must print something
```
Empty output means L1 was started without `--nested-hw-virt on`.

## Recovery

Re-run the failed step; don't tear down. The only thing worth destroying is a
VM whose Windows install itself broke:
```bash
scripts/create-vms.sh --variant <v> --force --iso-... 
```
Full reset:
```bash
scripts/cleanup-vms.sh --variant <v> --build --yes
```
