using System;

namespace VulnLabWizard.Models
{
    public class DeploymentState
    {
        public string Mode { get; set; }
        public string DeploymentMethod { get; set; } // "iso" or "ova"
        public string LabPrefix { get; set; } = "VulnLab";
        public string NetworkIpStart { get; set; } = "192.168.56.100";
        public int PortRangeStart { get; set; } = 5100;
        public string DomainName { get; set; } = "hackossem.local";
        public string DomainAdminPassword { get; set; } = "P@ssw0rd!2024";
        public int VmMemoryMB { get; set; } = 2048;
        public int VmCpuCount { get; set; } = 2;
        public bool CreateSnapshots { get; set; } = true;
        public bool ValidateAfter { get; set; } = true;
        public int CurrentStep { get; set; } = 0;
        public DateTime StartTime { get; set; }
        public bool IsInProgress { get; set; } = false;

        // Flexible Deployment Configuration
        public int LabCount { get; set; } = 20;
        public int RamPerVmGB { get; set; } = 2;
        public bool IsSequentialDeployment { get; set; } = true;
    }
}
