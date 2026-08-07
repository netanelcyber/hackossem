#!/usr/bin/env python3
"""
Active Directory Training Environment Manager
Manages 10 VirtualBox VMs for Active Directory training

Usage:
    python ad_vm_manager.py --action create-all
    python ad_vm_manager.py --action start-all
    python ad_vm_manager.py --action stop-all
    python ad_vm_manager.py --action status
"""

import json
import subprocess
import sys
import argparse
from pathlib import Path
from typing import Dict, List, Optional
import time


class ADVMManager:
    """Manager for Active Directory training VMs"""

    def __init__(self, config_file: str = "machines_config.json"):
        """Initialize manager with configuration"""
        self.config_file = Path(config_file)
        self.config = self._load_config()
        self.machines = self.config.get("machines", [])
        self.vbox_path = self._find_vboxmanage()

    def _load_config(self) -> Dict:
        """Load configuration from JSON file"""
        if not self.config_file.exists():
            raise FileNotFoundError(f"Configuration file not found: {self.config_file}")

        with open(self.config_file, "r", encoding="utf-8") as f:
            return json.load(f)

    def _find_vboxmanage(self) -> str:
        """Find VBoxManage executable"""
        candidates = [
            "C:\\Program Files\\Oracle\\VirtualBox\\VBoxManage.exe",
            "C:\\Program Files (x86)\\Oracle\\VirtualBox\\VBoxManage.exe",
            "VBoxManage.exe",
            "VBoxManage",
        ]

        for candidate in candidates:
            try:
                subprocess.run(
                    [candidate, "--version"],
                    capture_output=True,
                    check=True,
                )
                return candidate
            except (FileNotFoundError, subprocess.CalledProcessError):
                continue

        raise RuntimeError(
            "VBoxManage not found. Please ensure VirtualBox is installed."
        )

    def _run_vbox_command(self, *args, **kwargs) -> tuple:
        """Execute VBoxManage command"""
        cmd = [self.vbox_path] + list(args)
        try:
            result = subprocess.run(
                cmd, capture_output=True, text=True, **kwargs
            )
            return result.returncode, result.stdout, result.stderr
        except Exception as e:
            return 1, "", str(e)

    def get_vm_status(self, vm_name: str) -> str:
        """Get status of a VM"""
        code, stdout, _ = self._run_vbox_command("showvminfo", vm_name, "--machinereadable")

        if code != 0:
            return "Not Found"

        for line in stdout.split("\n"):
            if line.startswith("VMState="):
                return line.split("=", 1)[1].strip('"')

        return "Unknown"

    def create_vm(self, machine: Dict) -> bool:
        """Create a single VM"""
        vm_name = machine["name"]
        print(f"Creating {vm_name}...", end=" ", flush=True)

        try:
            # Create VM
            code, _, err = self._run_vbox_command(
                "createvm",
                "--name", vm_name,
                "--ostype", "Windows2022_64",
                "--basefolder", self.config["environment"]["vboxBase"],
                "--register",
            )

            if code != 0:
                print(f"✗ Failed: {err}")
                return False

            # Configure resources
            code, _, err = self._run_vbox_command(
                "modifyvm", vm_name,
                "--memory", str(machine["resources"]["memory_mb"]),
                "--cpus", str(machine["resources"]["cpus"]),
                "--vram", "128",
            )

            if code != 0:
                print(f"✗ Failed: {err}")
                return False

            # Configure network
            code, _, err = self._run_vbox_command(
                "modifyvm", vm_name,
                "--nic1", "bridged",
                "--bridgeadapter1", self.config["networkSettings"]["adapterName"],
                "--nictype1", "82540EM",
            )

            if code != 0:
                print(f"✗ Failed: {err}")
                return False

            # Create and attach disk
            vm_base = Path(self.config["environment"]["vboxBase"]) / vm_name
            vm_base.mkdir(parents=True, exist_ok=True)

            disk_path = vm_base / f"{vm_name}.vdi"
            code, _, err = self._run_vbox_command(
                "createmedium", "disk",
                "--filename", str(disk_path),
                "--size", str(machine["resources"]["disk_mb"]),
                "--format", "VDI",
            )

            if code != 0:
                print(f"✗ Failed to create disk: {err}")
                return False

            # Attach storage controller and disk
            code, _, err = self._run_vbox_command(
                "storagectl", vm_name,
                "--name", "SATA Controller",
                "--add", "sata",
                "--controller", "IntelAhci",
            )

            if code != 0:
                print(f"✗ Failed to create storage controller: {err}")
                return False

            code, _, err = self._run_vbox_command(
                "storageattach", vm_name,
                "--storagectl", "SATA Controller",
                "--port", "0",
                "--device", "0",
                "--type", "hdd",
                "--medium", str(disk_path),
            )

            if code != 0:
                print(f"✗ Failed to attach disk: {err}")
                return False

            print("✓")
            return True

        except Exception as e:
            print(f"✗ Error: {e}")
            return False

    def create_all_vms(self) -> int:
        """Create all VMs"""
        print(f"\nCreating {len(self.machines)} Active Directory training VMs")
        print("=" * 60)

        successful = 0
        failed = 0

        for machine in self.machines:
            if self.create_vm(machine):
                successful += 1
            else:
                failed += 1
            time.sleep(0.5)

        print(f"\nResults: {successful} created, {failed} failed")
        return 0 if failed == 0 else 1

    def start_vm(self, vm_name: str) -> bool:
        """Start a single VM"""
        print(f"Starting {vm_name}...", end=" ", flush=True)

        code, _, err = self._run_vbox_command(
            "startvm", vm_name, "--type", "headless"
        )

        if code != 0:
            print(f"✗ Failed: {err}")
            return False

        print("✓")
        return True

    def start_all_vms(self) -> int:
        """Start all VMs"""
        print(f"\nStarting {len(self.machines)} VMs")
        print("=" * 60)

        successful = 0
        for machine in self.machines:
            if self.start_vm(machine["name"]):
                successful += 1
            time.sleep(1)

        print(f"\nStarted: {successful}/{len(self.machines)}")
        return 0

    def stop_vm(self, vm_name: str) -> bool:
        """Stop a single VM"""
        print(f"Stopping {vm_name}...", end=" ", flush=True)

        code, _, err = self._run_vbox_command("controlvm", vm_name, "poweroff")

        if code != 0:
            print(f"✗ Failed: {err}")
            return False

        print("✓")
        return True

    def stop_all_vms(self) -> int:
        """Stop all VMs"""
        print(f"\nStopping {len(self.machines)} VMs")
        print("=" * 60)

        successful = 0
        for machine in self.machines:
            if self.stop_vm(machine["name"]):
                successful += 1
            time.sleep(1)

        print(f"\nStopped: {successful}/{len(self.machines)}")
        return 0

    def show_status(self) -> int:
        """Show status of all VMs"""
        print("\nActive Directory Training Environment Status")
        print("=" * 80)
        print(f"Domain: {self.config['environment']['domain']}")
        print(f"Network: {self.config['environment']['baseNetwork']}")
        print("=" * 80)

        print(f"\n{'Name':<15} {'Role':<15} {'IP':<18} {'Status':<15} {'Memory':<10} {'CPUs':<5}")
        print("-" * 80)

        for machine in self.machines:
            status = self.get_vm_status(machine["name"])
            print(
                f"{machine['name']:<15} "
                f"{machine['role']:<15} "
                f"{machine['ip']:<18} "
                f"{status:<15} "
                f"{machine['resources']['memory_mb']}MB{'':<4} "
                f"{machine['resources']['cpus']:<5}"
            )

        print()
        return 0


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Active Directory Training Environment Manager",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python ad_vm_manager.py --action create-all
  python ad_vm_manager.py --action start-all
  python ad_vm_manager.py --action stop-all
  python ad_vm_manager.py --action status
  python ad_vm_manager.py --action start --vm AD-DC01
        """,
    )

    parser.add_argument(
        "--action",
        required=True,
        choices=[
            "create-all",
            "start-all",
            "stop-all",
            "start",
            "stop",
            "status",
        ],
        help="Action to perform",
    )

    parser.add_argument(
        "--vm",
        help="VM name (required for single VM actions)",
    )

    parser.add_argument(
        "--config",
        default="machines_config.json",
        help="Path to configuration file",
    )

    args = parser.parse_args()

    try:
        manager = ADVMManager(args.config)

        if args.action == "create-all":
            return manager.create_all_vms()
        elif args.action == "start-all":
            return manager.start_all_vms()
        elif args.action == "stop-all":
            return manager.stop_all_vms()
        elif args.action == "start":
            if not args.vm:
                print("Error: --vm required for this action")
                return 1
            return 0 if manager.start_vm(args.vm) else 1
        elif args.action == "stop":
            if not args.vm:
                print("Error: --vm required for this action")
                return 1
            return 0 if manager.stop_vm(args.vm) else 1
        elif args.action == "status":
            return manager.show_status()

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
