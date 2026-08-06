using System;
using System.Diagnostics;

namespace VulnLabWizard.Services
{
    public class VirtualBoxService
    {
        private Action<string> logCallback;

        public VirtualBoxService(Action<string> log)
        {
            logCallback = log;
        }

        public bool IsInstalled()
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
                    logCallback?.Invoke($"VirtualBox version: {output.Trim()}");
                    return process.ExitCode == 0;
                }
            }
            catch (Exception ex)
            {
                logCallback?.Invoke($"ERROR: VirtualBox check failed: {ex.Message}");
                return false;
            }
        }

        public bool CreateVM(string vmName, string networkName, int memory, int cpus, int diskSize)
        {
            try
            {
                string arguments = $"createvm --name \"{vmName}\" --ostype \"Windows2022_64\" --register";

                ProcessStartInfo psi = new ProcessStartInfo
                {
                    FileName = "VBoxManage",
                    Arguments = arguments,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    CreateNoWindow = true
                };

                using (Process process = Process.Start(psi))
                {
                    process.WaitForExit();
                    if (process.ExitCode == 0)
                    {
                        logCallback?.Invoke($"✓ Created VM: {vmName}");
                        return true;
                    }
                    else
                    {
                        logCallback?.Invoke($"ERROR: Failed to create VM: {vmName}");
                        return false;
                    }
                }
            }
            catch (Exception ex)
            {
                logCallback?.Invoke($"ERROR: {ex.Message}");
                return false;
            }
        }

        public bool StartVM(string vmName)
        {
            try
            {
                string arguments = $"startvm \"{vmName}\" --type headless";

                ProcessStartInfo psi = new ProcessStartInfo
                {
                    FileName = "VBoxManage",
                    Arguments = arguments,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using (Process process = Process.Start(psi))
                {
                    process.WaitForExit();
                    return process.ExitCode == 0;
                }
            }
            catch (Exception ex)
            {
                logCallback?.Invoke($"ERROR: {ex.Message}");
                return false;
            }
        }

        public bool StopVM(string vmName)
        {
            try
            {
                string arguments = $"controlvm \"{vmName}\" poweroff";

                ProcessStartInfo psi = new ProcessStartInfo
                {
                    FileName = "VBoxManage",
                    Arguments = arguments,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using (Process process = Process.Start(psi))
                {
                    process.WaitForExit();
                    return process.ExitCode == 0;
                }
            }
            catch (Exception ex)
            {
                logCallback?.Invoke($"ERROR: {ex.Message}");
                return false;
            }
        }
    }
}
