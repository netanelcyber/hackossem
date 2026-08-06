namespace VulnLabWizard.Models
{
    public class LabDefinition
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string Difficulty { get; set; } // Easy, Medium, Hard
        public string VmName { get; set; }
        public string IpAddress { get; set; }
        public int RdpPort { get; set; }
        public int WinrmPort { get; set; }
        public string VulnerabilityType { get; set; }
        public string Description { get; set; }
        public string[] Tags { get; set; }
    }
}
