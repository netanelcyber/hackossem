using System;
using System.Diagnostics;
using System.IO;

namespace VulnLabWizard.Services
{
    public class EnvironmentValidator
    {
        private Action<string> logCallback;

        public EnvironmentValidator(Action<string> log)
        {
            logCallback = log;
        }

        public bool ValidateEnvironment()
        {
            logCallback?.Invoke("Validating system environment...");

            bool isValid = true;

            // Check VirtualBox
            if (!CheckVirtualBox())
            {
                logCallback?.Invoke("ERROR: VirtualBox not installed or not accessible");
                isValid = false;
            }
            else
            {
                logCallback?.Invoke("✓ VirtualBox installed and accessible");
            }

            // Check disk space (dynamic based on lab count)
            if (!CheckDiskSpace(20, 10))
            {
                logCallback?.Invoke("ERROR: Insufficient disk space");
                isValid = false;
            }
            else
            {
                logCallback?.Invoke("✓ Sufficient disk space available");
            }

            // Check RAM (dynamic based on lab count and deployment strategy)
            if (!CheckMemory(20, 2, false))
            {
                logCallback?.Invoke("ERROR: Insufficient RAM");
                isValid = false;
            }
            else
            {
                logCallback?.Invoke("✓ Sufficient RAM available");
            }

            return isValid;
        }

        public bool ValidateEnvironmentForDeployment(int labCount, int ramPerVmGB, bool isSequentialDeployment)
        {
            logCallback?.Invoke("Validating environment for flexible deployment...");
            logCallback?.Invoke($"Configuration: {labCount} labs × {ramPerVmGB}GB RAM per VM | Strategy: {(isSequentialDeployment ? "Sequential" : "Simultaneous")}");

            bool isValid = true;

            // Check VirtualBox
            if (!CheckVirtualBox())
            {
                logCallback?.Invoke("ERROR: VirtualBox not installed or not accessible");
                isValid = false;
            }
            else
            {
                logCallback?.Invoke("✓ VirtualBox installed and accessible");
            }

            // Check disk space
            long diskPerVM = 10;
            if (!CheckDiskSpace(labCount, diskPerVM))
            {
                logCallback?.Invoke($"ERROR: Insufficient disk space (need {labCount * diskPerVM}GB+)");
                isValid = false;
            }
            else
            {
                logCallback?.Invoke("✓ Sufficient disk space available");
            }

            // Check RAM with deployment strategy
            if (!CheckMemory(labCount, ramPerVmGB, isSequentialDeployment))
            {
                long effectiveRamNeeded = isSequentialDeployment ? (ramPerVmGB * 2) : (labCount * ramPerVmGB);
                logCallback?.Invoke($"ERROR: Insufficient RAM (need {effectiveRamNeeded}GB+)");
                isValid = false;
            }
            else
            {
                logCallback?.Invoke("✓ Sufficient RAM available for deployment strategy");
            }

            return isValid;
        }

        private bool CheckVirtualBox()
        {
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo
                {
                    FileName = "VBoxManage",
                    Arguments = "--version",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    CreateNoWindow = true
                };

                using (Process process = Process.Start(psi))
                {
                    string output = process.StandardOutput.ReadToEnd();
                    process.WaitForExit();
                    return process.ExitCode == 0 && !string.IsNullOrEmpty(output);
                }
            }
            catch
            {
                return false;
            }
        }

        private bool CheckDiskSpace(int labCount = 20, long diskPerVmGB = 10)
        {
            try
            {
                // Check free space on C: drive
                DriveInfo drive = new DriveInfo("C");
                long requiredSpace = labCount * diskPerVmGB * 1024 * 1024 * 1024; // Calculate based on lab count
                long availableGB = drive.AvailableFreeSpace / (1024 * 1024 * 1024);
                logCallback?.Invoke($"Available disk space: {availableGB} GB | Required: {labCount * diskPerVmGB} GB");
                return drive.AvailableFreeSpace > requiredSpace;
            }
            catch
            {
                return false;
            }
        }

        private bool CheckMemory(int labCount = 20, int ramPerVmGB = 2, bool isSequentialDeployment = false)
        {
            try
            {
                // Get available RAM
                System.Diagnostics.PerformanceCounter ramCounter =
                    new System.Diagnostics.PerformanceCounter("Memory", "Available MBytes");
                float availableRAM = ramCounter.NextValue() / 1024f; // Convert to GB

                long requiredRAM;
                if (isSequentialDeployment)
                {
                    // Sequential: only need RAM for simultaneous VMs + buffer
                    requiredRAM = ramPerVmGB * 2; // 2 VMs at a time maximum
                }
                else
                {
                    // Simultaneous: need RAM for all VMs
                    requiredRAM = labCount * ramPerVmGB;
                }

                logCallback?.Invoke($"Available RAM: {availableRAM:F1} GB | Required: {requiredRAM} GB ({(isSequentialDeployment ? "Sequential" : "Simultaneous")})");
                return availableRAM > requiredRAM;
            }
            catch
            {
                // If we can't check, assume OK
                return true;
            }
        }
    }
}
