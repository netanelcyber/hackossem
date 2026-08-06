using System;
using System.IO;

namespace VulnLabWizard.Services
{
    public class LogService
    {
        private Action<string> logCallback;
        private StreamWriter logFile;
        private string logPath;

        public LogService(Action<string> log)
        {
            logCallback = log;
            logPath = Path.Combine(Path.GetTempPath(), "VulnLabWizard_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".log");

            try
            {
                logFile = new StreamWriter(logPath, true);
                logFile.AutoFlush = true;
            }
            catch { }
        }

        public void Log(string message)
        {
            string timestampedMessage = $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {message}";
            logCallback?.Invoke(timestampedMessage);

            try
            {
                logFile?.WriteLine(timestampedMessage);
            }
            catch { }
        }

        public void Close()
        {
            logFile?.Close();
            logFile?.Dispose();
        }

        public string GetLogPath()
        {
            return logPath;
        }
    }
}
