using System;
using System.Diagnostics;
using System.Windows.Forms;

namespace VulnLabWizard
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            // Check for administrator privileges
            if (!IsRunningAsAdministrator())
            {
                MessageBox.Show(
                    "This application must run as Administrator.\n\n" +
                    "Please run the application with administrator privileges.",
                    "Administrator Required",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Warning);
                return;
            }

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new Forms.WizardForm());
        }

        private static bool IsRunningAsAdministrator()
        {
            try
            {
                var identity = System.Security.Principal.WindowsIdentity.GetCurrent();
                var principal = new System.Security.Principal.WindowsPrincipal(identity);
                return principal.IsInRole(System.Security.Principal.WindowsBuiltInRole.Administrator);
            }
            catch
            {
                return false;
            }
        }
    }
}
