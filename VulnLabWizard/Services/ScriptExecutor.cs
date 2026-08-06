using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Text;

namespace VulnLabWizard.Services
{
    public class ScriptExecutor
    {
        private Action<string> logCallback;

        public ScriptExecutor(Action<string> log)
        {
            logCallback = log;
        }

        public bool ExecutePowerShellScript(string scriptName, string arguments = "")
        {
            try
            {
                // Extract PowerShell script from embedded resources
                string scriptContent = ExtractEmbeddedResource($"VulnLabWizard.Resources.{scriptName}");
                if (string.IsNullOrEmpty(scriptContent))
                {
                    logCallback?.Invoke($"ERROR: Could not find script: {scriptName}");
                    return false;
                }

                // Write script to temporary file
                string tempScriptPath = Path.Combine(Path.GetTempPath(), scriptName);
                File.WriteAllText(tempScriptPath, scriptContent);

                // Execute PowerShell script
                return ExecutePowerShell(tempScriptPath, arguments);
            }
            catch (Exception ex)
            {
                logCallback?.Invoke($"ERROR: {ex.Message}");
                return false;
            }
        }

        private bool ExecutePowerShell(string scriptPath, string arguments)
        {
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo
                {
                    FileName = "powershell.exe",
                    Arguments = $"-NoProfile -ExecutionPolicy Bypass -File \"{scriptPath}\" {arguments}",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true
                };

                using (Process process = Process.Start(psi))
                {
                    // Read output
                    string output = process.StandardOutput.ReadToEnd();
                    string error = process.StandardError.ReadToEnd();

                    process.WaitForExit();

                    if (!string.IsNullOrEmpty(output))
                    {
                        logCallback?.Invoke(output);
                    }

                    if (!string.IsNullOrEmpty(error))
                    {
                        logCallback?.Invoke($"ERROR: {error}");
                    }

                    return process.ExitCode == 0;
                }
            }
            catch (Exception ex)
            {
                logCallback?.Invoke($"ERROR: Failed to execute PowerShell: {ex.Message}");
                return false;
            }
        }

        private string ExtractEmbeddedResource(string resourceName)
        {
            try
            {
                Assembly assembly = Assembly.GetExecutingAssembly();
                using (Stream stream = assembly.GetManifestResourceStream(resourceName))
                {
                    if (stream == null)
                        return null;

                    using (StreamReader reader = new StreamReader(stream))
                    {
                        return reader.ReadToEnd();
                    }
                }
            }
            catch (Exception ex)
            {
                logCallback?.Invoke($"ERROR: Failed to extract resource {resourceName}: {ex.Message}");
                return null;
            }
        }

        public bool ExecuteCommand(string command, string arguments = "")
        {
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo
                {
                    FileName = command,
                    Arguments = arguments,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true
                };

                using (Process process = Process.Start(psi))
                {
                    string output = process.StandardOutput.ReadToEnd();
                    string error = process.StandardError.ReadToEnd();

                    process.WaitForExit();

                    if (!string.IsNullOrEmpty(output))
                    {
                        logCallback?.Invoke(output);
                    }

                    if (!string.IsNullOrEmpty(error))
                    {
                        logCallback?.Invoke($"ERROR: {error}");
                    }

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
