using System;
using System.Drawing;
using System.Windows.Forms;
using VulnLabWizard.Models;

namespace VulnLabWizard.Forms
{
    public partial class StudentDashboardForm : Form
    {
        private DataGridView labsGrid;
        private LabConfig labConfig;
        private Panel detailsPanel;

        public StudentDashboardForm()
        {
            InitializeComponent();
        }

        private void InitializeComponent()
        {
            this.Text = "Student Lab Dashboard - Select & Control Labs";
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = AutoScaleMode.Font;
            this.Dock = DockStyle.Fill;

            // Load lab configuration
            labConfig = new LabConfig();

            // Main layout
            SplitContainer splitContainer = new SplitContainer
            {
                Dock = DockStyle.Fill,
                Orientation = Orientation.Vertical,
                SplitterDistance = 500
            };

            // Left side: Lab list
            labsGrid = new DataGridView
            {
                Dock = DockStyle.Fill,
                AutoGenerateColumns = false,
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                ReadOnly = true,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                BackgroundColor = Color.White,
                AlternatingRowsDefaultCellStyle = new DataGridViewCellStyle { BackColor = Color.LightGray }
            };

            // Add columns
            labsGrid.Columns.Add("LabId", "Lab ID");
            labsGrid.Columns.Add("LabName", "Lab Name");
            labsGrid.Columns.Add("Difficulty", "Difficulty");
            labsGrid.Columns.Add("Status", "Status");
            labsGrid.Columns.Add("RDPPort", "RDP Port");

            labsGrid.Columns["LabId"].Width = 100;
            labsGrid.Columns["LabName"].Width = 200;
            labsGrid.Columns["Difficulty"].Width = 80;
            labsGrid.Columns["Status"].Width = 80;
            labsGrid.Columns["RDPPort"].Width = 80;

            // Populate grid with labs
            if (labConfig?.Labs != null)
            {
                foreach (var lab in labConfig.Labs)
                {
                    string status = "Stopped"; // TODO: Query actual VM status
                    labsGrid.Rows.Add(lab.Id, lab.Name, lab.Difficulty, status, lab.RdpPort);
                }
            }

            labsGrid.SelectionChanged += LabsGrid_SelectionChanged;
            splitContainer.Panel1.Controls.Add(labsGrid);

            // Right side: Lab details and controls
            detailsPanel = new Panel
            {
                Dock = DockStyle.Fill,
                BackColor = Color.WhiteSmoke,
                Padding = new Padding(10)
            };

            CreateDetailsPanel();
            splitContainer.Panel2.Controls.Add(detailsPanel);

            this.Controls.Add(splitContainer);
        }

        private void CreateDetailsPanel()
        {
            detailsPanel.Controls.Clear();

            // Title
            Label titleLabel = new Label
            {
                Text = "Select a lab to view details and controls",
                Font = new Font("Arial", 12, FontStyle.Bold),
                Dock = DockStyle.Top,
                Height = 30,
                AutoSize = false
            };
            detailsPanel.Controls.Add(titleLabel);

            // Details would be populated when lab is selected
        }

        private void LabsGrid_SelectionChanged(object sender, EventArgs e)
        {
            if (labsGrid.SelectedRows.Count == 0) return;

            int selectedIndex = labsGrid.SelectedRows[0].Index;
            if (selectedIndex >= labConfig?.Labs.Count) return;

            var lab = labConfig.Labs[selectedIndex];
            ShowLabDetails(lab);
        }

        private void ShowLabDetails(LabDefinition lab)
        {
            detailsPanel.Controls.Clear();

            TableLayoutPanel table = new TableLayoutPanel
            {
                Dock = DockStyle.Top,
                ColumnCount = 2,
                RowCount = 8,
                AutoSize = true,
                Padding = new Padding(10)
            };

            table.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 35));
            table.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 65));

            // Lab info
            table.Controls.Add(new Label { Text = "Lab Name:", Font = new Font("Arial", 10, FontStyle.Bold) }, 0, 0);
            table.Controls.Add(new Label { Text = lab.Name, Font = new Font("Arial", 10) }, 1, 0);

            table.Controls.Add(new Label { Text = "Difficulty:", Font = new Font("Arial", 10, FontStyle.Bold) }, 0, 1);
            Color diffColor = lab.Difficulty == "Easy" ? Color.Green : (lab.Difficulty == "Medium" ? Color.Orange : Color.Red);
            Label diffLabel = new Label { Text = lab.Difficulty, Font = new Font("Arial", 10), ForeColor = diffColor };
            table.Controls.Add(diffLabel, 1, 1);

            table.Controls.Add(new Label { Text = "Vulnerability:", Font = new Font("Arial", 10, FontStyle.Bold) }, 0, 2);
            table.Controls.Add(new Label { Text = lab.VulnerabilityType, Font = new Font("Arial", 10) }, 1, 2);

            table.Controls.Add(new Label { Text = "IP Address:", Font = new Font("Arial", 10, FontStyle.Bold) }, 0, 3);
            table.Controls.Add(new Label { Text = lab.IpAddress, Font = new Font("Arial", 10) }, 1, 3);

            table.Controls.Add(new Label { Text = "RDP Port:", Font = new Font("Arial", 10, FontStyle.Bold) }, 0, 4);
            table.Controls.Add(new Label { Text = lab.RdpPort.ToString(), Font = new Font("Arial", 10) }, 1, 4);

            table.Controls.Add(new Label { Text = "WinRM Port:", Font = new Font("Arial", 10, FontStyle.Bold) }, 0, 5);
            table.Controls.Add(new Label { Text = lab.WinrmPort.ToString(), Font = new Font("Arial", 10) }, 1, 5);

            table.Controls.Add(new Label { Text = "Description:", Font = new Font("Arial", 10, FontStyle.Bold) }, 0, 6);
            table.Controls.Add(new Label { Text = lab.Description, Font = new Font("Arial", 10), AutoSize = false, Height = 40 }, 1, 6);

            detailsPanel.Controls.Add(table);

            // Control buttons
            FlowLayoutPanel buttonPanel = new FlowLayoutPanel
            {
                Dock = DockStyle.Top,
                AutoSize = true,
                Padding = new Padding(10),
                FlowDirection = FlowDirection.TopDown
            };

            Button startBtn = new Button { Text = "Start Lab", Width = 120, Height = 35 };
            startBtn.Click += (s, e) => StartLab(lab);

            Button stopBtn = new Button { Text = "Stop Lab", Width = 120, Height = 35 };
            stopBtn.Click += (s, e) => StopLab(lab);

            Button resetBtn = new Button { Text = "Reset to Snapshot", Width = 120, Height = 35 };
            resetBtn.Click += (s, e) => ResetLab(lab);

            Button rdpBtn = new Button { Text = "RDP Connect", Width = 120, Height = 35, BackColor = Color.LightBlue };
            rdpBtn.Click += (s, e) => RDPConnect(lab);

            Button credsBtn = new Button { Text = "View Credentials", Width = 120, Height = 35 };
            credsBtn.Click += (s, e) => ViewCredentials(lab);

            Button guideBtn = new Button { Text = "View Guide", Width = 120, Height = 35 };
            guideBtn.Click += (s, e) => ViewGuide(lab);

            buttonPanel.Controls.AddRange(new Control[] { startBtn, stopBtn, resetBtn, rdpBtn, credsBtn, guideBtn });
            detailsPanel.Controls.Add(buttonPanel);
        }

        private void StartLab(LabDefinition lab)
        {
            MessageBox.Show($"Starting lab: {lab.Name}\n\nVM: {lab.VmName}\nIP: {lab.IpAddress}", "Lab Started");
        }

        private void StopLab(LabDefinition lab)
        {
            MessageBox.Show($"Stopping lab: {lab.Name}", "Lab Stopped");
        }

        private void ResetLab(LabDefinition lab)
        {
            if (MessageBox.Show($"Reset {lab.Name} to clean snapshot?\n\nThis will discard all changes.", "Confirm Reset", MessageBoxButtons.YesNo) == DialogResult.Yes)
            {
                MessageBox.Show($"Lab {lab.Name} reset to snapshot", "Lab Reset");
            }
        }

        private void RDPConnect(LabDefinition lab)
        {
            try
            {
                string cmdArgs = $"/v:127.0.0.1:{lab.RdpPort} /prompt";
                System.Diagnostics.Process.Start("mstsc.exe", cmdArgs);
                MessageBox.Show($"Connecting to {lab.Name} via RDP...\n\nIP: 127.0.0.1:{lab.RdpPort}", "RDP Connect");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to launch RDP: {ex.Message}", "Error");
            }
        }

        private void ViewCredentials(LabDefinition lab)
        {
            MessageBox.Show($"Lab: {lab.Name}\n\nUsername: administrator\nPassword: P@ssw0rd!2024\n\nDomain: hackossem.local", "Lab Credentials");
        }

        private void ViewGuide(LabDefinition lab)
        {
            MessageBox.Show($"Exploitation Guide for {lab.Name}\n\nVulnerability: {lab.VulnerabilityType}\n\n1. Enumerate the system\n2. Identify the vulnerability\n3. Exploit and gain access\n4. Document findings", "Exploitation Guide");
        }
    }
}
