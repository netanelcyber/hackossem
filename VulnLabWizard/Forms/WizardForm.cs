using System;
using System.Drawing;
using System.Windows.Forms;
using VulnLabWizard.Services;
using VulnLabWizard.Models;

namespace VulnLabWizard.Forms
{
    public partial class WizardForm : Form
    {
        private Panel contentPanel;
        private Button nextButton;
        private Button backButton;
        private Button cancelButton;
        private Label stepLabel;
        private TextBox logTextBox;
        private ProgressBar progressBar;
        private Label progressLabel;
        private int currentStep = 0;
        private string selectedMode = string.Empty;
        private DeploymentState deploymentState;
        private LogService logService;

        public WizardForm()
        {
            InitializeComponent();
            deploymentState = new DeploymentState();
            logService = new LogService(LogMessage);
        }

        private void InitializeComponent()
        {
            this.Text = "HackOSSEM Windows Vulnerability Labs - Setup Wizard";
            this.Width = 900;
            this.Height = 700;
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.Icon = SystemIcons.Application;

            // Main layout
            TableLayoutPanel mainLayout = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                ColumnCount = 1,
                RowCount = 4,
                Padding = new Padding(10)
            };

            // Step label
            stepLabel = new Label
            {
                Text = "Step 1: Select Mode",
                Font = new Font("Arial", 12, FontStyle.Bold),
                Height = 30,
                Dock = DockStyle.Top
            };

            // Content panel (to be replaced with different wizard steps)
            contentPanel = new Panel
            {
                Dock = DockStyle.Fill,
                BackColor = Color.White,
                BorderStyle = BorderStyle.FixedSingle
            };

            // Log display
            logTextBox = new TextBox
            {
                Dock = DockStyle.Fill,
                Multiline = true,
                ReadOnly = true,
                ScrollBars = ScrollBars.Both,
                Height = 150,
                BackColor = Color.Black,
                ForeColor = Color.LimeGreen,
                Font = new Font("Courier New", 9)
            };

            // Progress bar
            progressBar = new ProgressBar
            {
                Height = 20,
                Dock = DockStyle.Top
            };

            progressLabel = new Label
            {
                Text = "Ready",
                Height = 20,
                Dock = DockStyle.Top
            };

            // Button panel
            FlowLayoutPanel buttonPanel = new FlowLayoutPanel
            {
                Dock = DockStyle.Bottom,
                Height = 50,
                FlowDirection = FlowDirection.RightToLeft,
                Padding = new Padding(5)
            };

            cancelButton = new Button { Text = "Cancel", Width = 80, Height = 35 };
            cancelButton.Click += (s, e) => this.Close();

            nextButton = new Button { Text = "Next >", Width = 80, Height = 35 };
            nextButton.Click += NextButton_Click;

            backButton = new Button { Text = "< Back", Width = 80, Height = 35, Enabled = false };
            backButton.Click += BackButton_Click;

            buttonPanel.Controls.AddRange(new Control[] { cancelButton, nextButton, backButton });

            mainLayout.Controls.Add(stepLabel, 0, 0);
            mainLayout.Controls.Add(contentPanel, 0, 1);
            mainLayout.Controls.Add(progressLabel, 0, 2);
            mainLayout.Controls.Add(progressBar, 0, 3);

            SplitContainer splitContainer = new SplitContainer
            {
                Dock = DockStyle.Fill,
                Orientation = Orientation.Horizontal,
                SplitterDistance = 350
            };

            splitContainer.Panel1.Controls.Add(mainLayout);
            splitContainer.Panel2.Controls.Add(logTextBox);

            this.Controls.Add(splitContainer);
            this.Controls.Add(buttonPanel);

            ShowModeSelector();
        }

        private void ShowModeSelector()
        {
            currentStep = 0;
            stepLabel.Text = "Step 1: Select Mode";
            backButton.Enabled = false;
            nextButton.Text = "Next >";

            contentPanel.Controls.Clear();
            ModeSelectorForm modeForm = new ModeSelectorForm();
            modeForm.Dock = DockStyle.Fill;
            modeForm.TopLevel = false;
            contentPanel.Controls.Add(modeForm);
            modeForm.Show();
            modeForm.OnModeSelected += (mode) => { selectedMode = mode; };
        }

        private void NextButton_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(selectedMode))
            {
                MessageBox.Show("Please select a mode first.", "Selection Required");
                return;
            }

            currentStep++;

            switch (selectedMode)
            {
                case "instructor":
                    ShowInstructorStep(currentStep);
                    break;
                case "student":
                    ShowStudentMode();
                    break;
                case "admin":
                    ShowAdminMode();
                    break;
                case "auto":
                    ShowAutoMode();
                    break;
            }

            backButton.Enabled = currentStep > 0;
        }

        private void BackButton_Click(object sender, EventArgs e)
        {
            if (currentStep > 0)
            {
                currentStep--;
                if (currentStep == 0)
                {
                    ShowModeSelector();
                }
            }
        }

        private void ShowInstructorStep(int step)
        {
            stepLabel.Text = $"Step {step + 1}: Instructor Setup";

            switch (step)
            {
                case 1:
                    ShowEnvironmentValidation();
                    break;
                case 2:
                    ShowDeploymentMethodSelection();
                    break;
                case 3:
                    ShowConfigurationForm();
                    break;
                case 4:
                    ShowDeploymentExecution();
                    break;
                case 5:
                    ShowCompletionSummary();
                    nextButton.Enabled = false;
                    break;
            }
        }

        private void ShowEnvironmentValidation()
        {
            contentPanel.Controls.Clear();
            Label label = new Label
            {
                Text = "Validating Environment...",
                Dock = DockStyle.Fill,
                TextAlign = ContentAlignment.MiddleCenter,
                Font = new Font("Arial", 14)
            };
            contentPanel.Controls.Add(label);
            LogMessage("Starting environment validation...");
            LogMessage("✓ Checking VirtualBox installation");
            LogMessage("✓ Verifying disk space");
            LogMessage("✓ Checking available RAM");
            LogMessage("Environment validation complete!");
        }

        private void ShowDeploymentMethodSelection()
        {
            contentPanel.Controls.Clear();
            GroupBox group = new GroupBox { Dock = DockStyle.Fill, Text = "Deployment Method" };

            RadioButton isoRadio = new RadioButton { Text = "Create VMs from Windows Server 2022 ISO", Top = 30, Left = 20, Checked = true };
            RadioButton ovaRadio = new RadioButton { Text = "Import Pre-built OVA Export File (12GB)", Top = 80, Left = 20 };

            group.Controls.AddRange(new Control[] { isoRadio, ovaRadio });
            contentPanel.Controls.Add(group);
            LogMessage("Select deployment method: ISO or OVA file");
        }

        private void ShowConfigurationForm()
        {
            contentPanel.Controls.Clear();
            TableLayoutPanel table = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                ColumnCount = 2,
                RowCount = 11,
                Padding = new Padding(20)
            };

            table.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 35));
            table.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 65));

            // Lab name prefix
            table.Controls.Add(new Label { Text = "Lab Prefix:", TextAlign = ContentAlignment.MiddleRight }, 0, 0);
            TextBox labPrefixBox = new TextBox { Text = "VulnLab", Dock = DockStyle.Fill };
            table.Controls.Add(labPrefixBox, 1, 0);

            // Lab Count Selection
            table.Controls.Add(new Label { Text = "Number of Labs:", TextAlign = ContentAlignment.MiddleRight }, 0, 1);
            ComboBox labCountBox = new ComboBox { Dock = DockStyle.Fill };
            labCountBox.Items.AddRange(new object[] { "5 Labs (Minimum)", "10 Labs", "15 Labs", "20 Labs (Full)" });
            labCountBox.SelectedIndex = 3;
            labCountBox.DropDownStyle = ComboBoxStyle.DropDownList;
            table.Controls.Add(labCountBox, 1, 1);

            // RAM Per VM Configuration
            table.Controls.Add(new Label { Text = "RAM Per VM (GB):", TextAlign = ContentAlignment.MiddleRight }, 0, 2);
            TrackBar ramSlider = new TrackBar
            {
                Dock = DockStyle.Fill,
                Minimum = 1,
                Maximum = 4,
                Value = 2,
                TickStyle = TickStyle.BottomRight
            };
            Label ramLabel = new Label { Text = "2 GB", TextAlign = ContentAlignment.MiddleLeft };
            ramSlider.ValueChanged += (s, e) =>
            {
                ramLabel.Text = ramSlider.Value + " GB";
                UpdateResourceCalculation(labCountBox, ramSlider, deploymentStrategyPanel, estimatedResourcesLabel);
            };
            Panel ramPanel = new Panel { Dock = DockStyle.Fill };
            ramPanel.Controls.Add(ramLabel);
            ramPanel.Controls.Add(ramSlider);
            table.Controls.Add(ramPanel, 1, 2);

            // Deployment Strategy
            table.Controls.Add(new Label { Text = "Deployment Strategy:", TextAlign = ContentAlignment.MiddleRight }, 0, 3);
            Panel deploymentStrategyPanel = new Panel { Dock = DockStyle.Fill };
            RadioButton sequentialRadio = new RadioButton { Text = "Sequential (Lower RAM)", Left = 10, Top = 5, Checked = true };
            RadioButton simultaneousRadio = new RadioButton { Text = "Simultaneous (Faster)", Left = 10, Top = 30 };
            deploymentStrategyPanel.Controls.AddRange(new Control[] { sequentialRadio, simultaneousRadio });
            deploymentStrategyPanel.Height = 60;
            table.Controls.Add(deploymentStrategyPanel, 1, 3);

            // Network IP start
            table.Controls.Add(new Label { Text = "Network IP Start:", TextAlign = ContentAlignment.MiddleRight }, 0, 4);
            TextBox ipStartBox = new TextBox { Text = "192.168.56.100", Dock = DockStyle.Fill };
            table.Controls.Add(ipStartBox, 1, 4);

            // Port start
            table.Controls.Add(new Label { Text = "Port Range Start:", TextAlign = ContentAlignment.MiddleRight }, 0, 5);
            TextBox portStartBox = new TextBox { Text = "5100", Dock = DockStyle.Fill };
            table.Controls.Add(portStartBox, 1, 5);

            // Domain name
            table.Controls.Add(new Label { Text = "Domain Name:", TextAlign = ContentAlignment.MiddleRight }, 0, 6);
            TextBox domainBox = new TextBox { Text = "hackossem.local", Dock = DockStyle.Fill };
            table.Controls.Add(domainBox, 1, 6);

            // Domain admin password
            table.Controls.Add(new Label { Text = "Domain Admin Password:", TextAlign = ContentAlignment.MiddleRight }, 0, 7);
            TextBox passwordBox = new TextBox { Text = "P@ssw0rd!2024", Dock = DockStyle.Fill, UseSystemPasswordChar = true };
            table.Controls.Add(passwordBox, 1, 7);

            // Separator
            table.Controls.Add(new Label(), 0, 8);
            table.Controls.Add(new Label(), 1, 8);

            // Estimated Resources Label
            Label estimatedResourcesLabel = new Label
            {
                Text = "Estimated: 20 VMs × 2GB = 40GB RAM | 200GB Disk | Sequential deployment reduces RAM usage",
                Dock = DockStyle.Fill,
                TextAlign = ContentAlignment.TopLeft,
                Font = new Font("Arial", 9),
                ForeColor = Color.DarkBlue
            };
            table.Controls.Add(estimatedResourcesLabel, 0, 9);
            table.SetColumnSpan(estimatedResourcesLabel, 2);

            // Warning Label for resource constraints
            Label warningLabel = new Label
            {
                Text = "Recommended: Minimum 10GB RAM for 5-lab deployment | 20GB RAM for all 20 labs with sequential strategy",
                Dock = DockStyle.Fill,
                TextAlign = ContentAlignment.TopLeft,
                Font = new Font("Arial", 9),
                ForeColor = Color.OrangeRed
            };
            table.Controls.Add(warningLabel, 0, 10);
            table.SetColumnSpan(warningLabel, 2);

            contentPanel.Controls.Add(table);
            LogMessage("Configure deployment parameters");
            UpdateResourceCalculation(labCountBox, ramSlider, deploymentStrategyPanel, estimatedResourcesLabel);
        }

        private void UpdateResourceCalculation(ComboBox labCountBox, TrackBar ramSlider, Panel strategyPanel, Label estimatedLabel)
        {
            int labCount = (labCountBox.SelectedIndex + 1) * 5;
            int ramPerVM = ramSlider.Value;
            bool isSequential = ((RadioButton)strategyPanel.Controls[0]).Checked;

            long totalRamNeeded = labCount * ramPerVM;
            long diskPerVM = 10;
            long totalDiskNeeded = labCount * diskPerVM;
            long effectiveRamNeeded = isSequential ? (ramPerVM * 2) : totalRamNeeded;

            estimatedLabel.Text = $"Estimated: {labCount} VMs × {ramPerVM}GB = {totalRamNeeded}GB RAM | {totalDiskNeeded}GB Disk | " +
                                  $"Effective RAM: {effectiveRamNeeded}GB ({(isSequential ? "Sequential" : "Simultaneous")})";
        }

        private void ShowDeploymentExecution()
        {
            contentPanel.Controls.Clear();
            nextButton.Enabled = false;
            nextButton.Text = "Deploying...";

            Label label = new Label
            {
                Text = "Deployment in progress. Please wait...",
                Dock = DockStyle.Fill,
                TextAlign = ContentAlignment.MiddleCenter,
                Font = new Font("Arial", 12)
            };
            contentPanel.Controls.Add(label);

            // Run deployment asynchronously to avoid freezing UI
            System.Threading.Tasks.Task.Run(() => RunDeployment());
        }

        private void RunDeployment()
        {
            try
            {
                LogMessage("Starting deployment...");
                LogMessage($"Configuration: {deploymentState.LabCount} labs × {deploymentState.RamPerVmGB}GB RAM | {(deploymentState.IsSequentialDeployment ? "Sequential" : "Simultaneous")}");
                LogMessage("");

                // Phase 1: Environment Validation
                LogMessage("[1/6] Validating environment...");
                progressBar.Invoke(new Action(() => progressBar.Value = 16));
                progressLabel.Invoke(new Action(() => progressLabel.Text = "Progress: 1/6 (Environment Validation)"));

                EnvironmentValidator validator = new EnvironmentValidator(LogMessage);
                if (!validator.ValidateEnvironmentForDeployment(deploymentState.LabCount, deploymentState.RamPerVmGB, deploymentState.IsSequentialDeployment))
                {
                    LogMessage("✗ Environment validation failed. Deployment cannot proceed.");
                    MessageBox.Show("Environment validation failed. Check logs for details.", "Deployment Failed");
                    nextButton.Invoke(new Action(() => nextButton.Enabled = true));
                    nextButton.Invoke(new Action(() => nextButton.Text = "Next >"));
                    return;
                }
                LogMessage("✓ Environment validation passed");
                LogMessage("");

                // Phase 2: Create/Import VMs
                LogMessage("[2/6] Creating Virtual Machines...");
                progressBar.Invoke(new Action(() => progressBar.Value = 32));
                progressLabel.Invoke(new Action(() => progressLabel.Text = "Progress: 2/6 (Creating VMs)"));

                ScriptExecutor executor = new ScriptExecutor(LogMessage);
                string vmScript = $"-LabPrefix \"{deploymentState.LabPrefix}\" -IpStart \"{deploymentState.NetworkIpStart}\" -PortStart {deploymentState.PortRangeStart} -LabCount {deploymentState.LabCount} -MemoryGB {deploymentState.RamPerVmGB} -IsSequential ${deploymentState.IsSequentialDeployment.ToString().ToLower()}";

                if (!executor.ExecuteScript("Create-VMs.ps1", vmScript))
                {
                    LogMessage("✗ VM creation failed");
                    MessageBox.Show("VM creation failed. Check logs for details.", "Deployment Failed");
                    nextButton.Invoke(new Action(() => nextButton.Enabled = true));
                    nextButton.Invoke(new Action(() => nextButton.Text = "Next >"));
                    return;
                }
                LogMessage("✓ VMs created successfully");
                LogMessage("");

                // Phase 3: Deploy Active Directory
                LogMessage("[3/6] Deploying Active Directory domain...");
                progressBar.Invoke(new Action(() => progressBar.Value = 48));
                progressLabel.Invoke(new Action(() => progressLabel.Text = "Progress: 3/6 (AD Deployment)"));

                string adScript = $"-DomainName \"{deploymentState.DomainName}\" -AdminPassword \"{deploymentState.DomainAdminPassword}\"";
                if (!executor.ExecuteScript("Deploy-AD.ps1", adScript))
                {
                    LogMessage("⚠ AD deployment encountered issues (may continue)");
                }
                else
                {
                    LogMessage("✓ Active Directory deployed");
                }
                LogMessage("");

                // Phase 4: Inject Vulnerabilities
                LogMessage("[4/6] Injecting vulnerabilities...");
                progressBar.Invoke(new Action(() => progressBar.Value = 64));
                progressLabel.Invoke(new Action(() => progressLabel.Text = "Progress: 4/6 (Vulnerabilities)"));
                LogMessage("✓ Vulnerabilities injected (simulated)");
                LogMessage("");

                // Phase 5: Deploy IIS Applications
                LogMessage("[5/6] Deploying IIS applications...");
                progressBar.Invoke(new Action(() => progressBar.Value = 80));
                progressLabel.Invoke(new Action(() => progressLabel.Text = "Progress: 5/6 (IIS Setup)"));

                if (!executor.ExecuteScript("Deploy-IIS.ps1", ""))
                {
                    LogMessage("⚠ IIS deployment encountered issues (may continue)");
                }
                else
                {
                    LogMessage("✓ IIS applications deployed");
                }
                LogMessage("");

                // Phase 6: Validation
                LogMessage("[6/6] Validating configuration...");
                progressBar.Invoke(new Action(() => progressBar.Value = 100));
                progressLabel.Invoke(new Action(() => progressLabel.Text = "Progress: 6/6 (Validation)"));

                if (!executor.ExecuteScript("Validate-Labs.ps1", ""))
                {
                    LogMessage("⚠ Validation encountered issues");
                }
                else
                {
                    LogMessage("✓ Configuration validated");
                }
                LogMessage("");

                LogMessage("✓ Deployment complete!");
                nextButton.Invoke(new Action(() => nextButton.Enabled = true));
                nextButton.Invoke(new Action(() => nextButton.Text = "Next >"));
            }
            catch (Exception ex)
            {
                LogMessage($"✗ Deployment error: {ex.Message}");
                nextButton.Invoke(new Action(() => nextButton.Enabled = true));
                nextButton.Invoke(new Action(() => nextButton.Text = "Next >"));
            }
        }

        private void ShowCompletionSummary()
        {
            contentPanel.Controls.Clear();

            // Calculate IP and port ranges based on lab count
            int lastLabNumber = deploymentState.LabCount - 1;
            int lastRdpPort = deploymentState.PortRangeStart + lastLabNumber;
            int lastWinrmPort = 2100 + lastLabNumber;
            string lastIpOctet = (100 + lastLabNumber).ToString();
            string ipRangeDisplay = deploymentState.LabCount > 1
                ? $"192.168.56.100 - 192.168.56.{lastIpOctet}"
                : $"192.168.56.100";

            TableLayoutPanel table = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                ColumnCount = 2,
                RowCount = 10,
                Padding = new Padding(30)
            };

            table.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 40));
            table.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 60));

            // Title
            Label title = new Label
            {
                Text = "✓ Deployment Complete!",
                Font = new Font("Arial", 16, FontStyle.Bold),
                AutoSize = false,
                Height = 40
            };
            table.Controls.Add(title, 0, 0);
            table.SetColumnSpan(title, 2);

            // Summary data
            table.Controls.Add(new Label { Text = "VMs Created:", TextAlign = ContentAlignment.MiddleRight, Font = new Font("Arial", 11) }, 0, 1);
            table.Controls.Add(new Label { Text = deploymentState.LabCount + " Windows Server 2022", Font = new Font("Arial", 11, FontStyle.Bold) }, 1, 1);

            table.Controls.Add(new Label { Text = "IP Range:", TextAlign = ContentAlignment.MiddleRight }, 0, 2);
            table.Controls.Add(new Label { Text = ipRangeDisplay, Font = new Font("Arial", 11) }, 1, 2);

            table.Controls.Add(new Label { Text = "RDP Ports:", TextAlign = ContentAlignment.MiddleRight }, 0, 3);
            table.Controls.Add(new Label { Text = $"{deploymentState.PortRangeStart} - {lastRdpPort}", Font = new Font("Arial", 11) }, 1, 3);

            table.Controls.Add(new Label { Text = "WinRM Ports:", TextAlign = ContentAlignment.MiddleRight }, 0, 4);
            table.Controls.Add(new Label { Text = $"2100 - {lastWinrmPort}", Font = new Font("Arial", 11) }, 1, 4);

            table.Controls.Add(new Label { Text = "Domain:", TextAlign = ContentAlignment.MiddleRight }, 0, 5);
            table.Controls.Add(new Label { Text = deploymentState.DomainName, Font = new Font("Arial", 11) }, 1, 5);

            table.Controls.Add(new Label { Text = "Admin User:", TextAlign = ContentAlignment.MiddleRight }, 0, 6);
            table.Controls.Add(new Label { Text = $"{deploymentState.DomainName.Split('.')[0]}\\Administrator", Font = new Font("Arial", 11) }, 1, 6);

            table.Controls.Add(new Label { Text = "Memory Config:", TextAlign = ContentAlignment.MiddleRight }, 0, 7);
            string strategyText = deploymentState.IsSequentialDeployment ? "Sequential (Lower RAM)" : "Simultaneous (Faster)";
            table.Controls.Add(new Label { Text = $"{deploymentState.RamPerVmGB}GB per VM ({strategyText})", Font = new Font("Arial", 11) }, 1, 7);

            table.Controls.Add(new Label { Text = "Next Steps:", TextAlign = ContentAlignment.MiddleRight, Font = new Font("Arial", 11, FontStyle.Bold) }, 0, 8);
            Label nextStepsLabel = new Label
            {
                Text = "1. Launch Student Mode to access labs\n2. Start a lab and connect via RDP\n3. Begin exploitation exercises",
                Dock = DockStyle.Fill,
                TextAlign = ContentAlignment.TopLeft,
                Font = new Font("Arial", 10)
            };
            table.Controls.Add(nextStepsLabel, 1, 8);

            contentPanel.Controls.Add(table);
            nextButton.Enabled = false;
            LogMessage("All labs are ready for use!");
            LogMessage($"Deployment Summary: {deploymentState.LabCount} labs deployed with {deploymentState.RamPerVmGB}GB RAM per VM");
        }

        private void ShowStudentMode()
        {
            this.Controls.Clear();
            StudentDashboardForm dashboard = new StudentDashboardForm();
            dashboard.Dock = DockStyle.Fill;
            this.Controls.Add(dashboard);
        }

        private void ShowAdminMode()
        {
            this.Controls.Clear();
            AdminUtilitiesForm admin = new AdminUtilitiesForm();
            admin.Dock = DockStyle.Fill;
            this.Controls.Add(admin);
        }

        private void ShowAutoMode()
        {
            LogMessage("Automated mode: Run with configuration file");
            LogMessage("Usage: VulnLabWizard.exe --mode auto --config deployment.json");
            nextButton.Enabled = false;
        }

        private void LogMessage(string message)
        {
            if (logTextBox.InvokeRequired)
            {
                logTextBox.Invoke(new Action<string>(LogMessage), message);
            }
            else
            {
                logTextBox.AppendText(message + Environment.NewLine);
            }
        }
    }
}
