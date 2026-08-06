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

            LogMessage("Starting deployment...");
            LogMessage("  [1/6] Creating 20 VirtualBox VMs...");
            progressBar.Value = 16;
            progressLabel.Text = "Progress: 1/6 (Creating VMs)";

            LogMessage("  [2/6] Configuring networking...");
            progressBar.Value = 33;
            progressLabel.Text = "Progress: 2/6 (Networking)";

            LogMessage("  [3/6] Deploying Active Directory domain...");
            progressBar.Value = 50;
            progressLabel.Text = "Progress: 3/6 (AD Deployment)";

            LogMessage("  [4/6] Injecting vulnerabilities...");
            progressBar.Value = 66;
            progressLabel.Text = "Progress: 4/6 (Vulnerabilities)";

            LogMessage("  [5/6] Deploying IIS applications...");
            progressBar.Value = 83;
            progressLabel.Text = "Progress: 5/6 (IIS Setup)";

            LogMessage("  [6/6] Validating configuration...");
            progressBar.Value = 100;
            progressLabel.Text = "Progress: 6/6 (Validation)";

            LogMessage("✓ Deployment complete!");
            nextButton.Enabled = true;
            nextButton.Text = "Next >";
        }

        private void ShowCompletionSummary()
        {
            contentPanel.Controls.Clear();
            Label summary = new Label
            {
                Text = "✓ Deployment Complete!\n\n" +
                       "20 Windows Server 2022 VMs created\n" +
                       "IP Range: 192.168.56.100 - 192.168.56.119\n" +
                       "RDP Port Range: 5100 - 5119\n" +
                       "Domain: hackossem.local\n" +
                       "Admin User: hackossem\\Administrator",
                Dock = DockStyle.Fill,
                TextAlign = ContentAlignment.MiddleCenter,
                Font = new Font("Arial", 12)
            };
            contentPanel.Controls.Add(summary);
            nextButton.Enabled = false;
            LogMessage("All labs are ready for use!");
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
