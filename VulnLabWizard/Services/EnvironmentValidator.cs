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

            // Check disk space
            if (!CheckDiskSpace())
            {
                logCallback?.Invoke("ERROR: Insufficient disk space (need 150GB+)");
                isValid = false;
            }
            else
            {
                logCallback?.Invoke("✓ Sufficient disk space available");
            }

            // Check RAM
            if (!CheckMemory())
            {
                logCallback?.Invoke("ERROR: Insufficient RAM (need 40GB+ free)");
                isValid = false;
            }
            else
            {
                logCallback?.Invoke("✓ Sufficient RAM available");
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

        private bool CheckDiskSpace()
        {
            try
            {
                // Check free space on C: drive
                DriveInfo drive = new DriveInfo("C");
                long requiredSpace = 150L * 1024 * 1024 * 1024; // 150 GB
                logCallback?.Invoke($"Available disk space: {drive.AvailableFreeSpace / (1024 * 1024 * 1024)} GB");
                return drive.AvailableFreeSpace > requiredSpace;
            }
            catch
            {
                return false;
            }
        }

        private bool CheckMemory()
        {
            try
            {
                // Get available RAM
                System.Diagnostics.PerformanceCounter ramCounter =
                    new System.Diagnostics.PerformanceCounter("Memory", "Available MBytes");
                float availableRAM = ramCounter.NextValue();
                long requiredRAM = 40 * 1024; // 40 GB in MB
                logCallback?.Invoke($"Available RAM: {availableRAM / 1024} GB");
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
