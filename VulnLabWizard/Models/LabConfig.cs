using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Text.Json;

namespace VulnLabWizard.Models
{
    public class LabConfig
    {
        public List<LabDefinition> Labs { get; set; }

        public static LabConfig LoadFromEmbeddedResource()
        {
            try
            {
                Assembly assembly = Assembly.GetExecutingAssembly();
                using (Stream stream = assembly.GetManifestResourceStream("VulnLabWizard.Resources.lab-config.json"))
                {
                    using (StreamReader reader = new StreamReader(stream))
                    {
                        string json = reader.ReadToEnd();
                        var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
                        var data = JsonSerializer.Deserialize<dynamic>(json, options);
                        return new LabConfig { Labs = new List<LabDefinition>() };
                    }
                }
            }
            catch
            {
                return new LabConfig { Labs = new List<LabDefinition>() };
            }
        }
    }
}
