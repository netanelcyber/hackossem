using System;
using System.Windows.Forms;

namespace VulnLabWizard.Forms
{
    public partial class AdminUtilitiesForm : Form
    {
        public AdminUtilitiesForm()
        {
            InitializeComponent();
        }

        private void InitializeComponent()
        {
            this.Text = "Admin Utilities";
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = AutoScaleMode.Font;
            this.Dock = DockStyle.Fill;

            TabControl tabControl = new TabControl { Dock = DockStyle.Fill };

            // VM Management tab
            TabPage vmTab = new TabPage { Text = "VM Management" };
            GroupBox vmGroup = new GroupBox { Dock = DockStyle.Fill, Text = "VM Operations" };
            Button cloneBtn = new Button { Text = "Clone Lab", Top = 20, Left = 20, Width = 100, Height = 30 };
            Button snapshotBtn = new Button { Text = "Create Snapshot", Top = 60, Left = 20, Width = 100, Height = 30 };
            Button restoreBtn = new Button { Text = "Restore Snapshot", Top = 100, Left = 20, Width = 100, Height = 30 };
            vmGroup.Controls.AddRange(new Control[] { cloneBtn, snapshotBtn, restoreBtn });
            vmTab.Controls.Add(vmGroup);

            // Team Setup tab
            TabPage teamTab = new TabPage { Text = "Team Setup" };
            GroupBox teamGroup = new GroupBox { Dock = DockStyle.Fill, Text = "Team Operations" };
            Button createTeamBtn = new Button { Text = "Create Team Set", Top = 20, Left = 20, Width = 120, Height = 30 };
            Button assignCredsBtn = new Button { Text = "Assign Credentials", Top = 60, Left = 20, Width = 120, Height = 30 };
            teamGroup.Controls.AddRange(new Control[] { createTeamBtn, assignCredsBtn });
            teamTab.Controls.Add(teamGroup);

            // Maintenance tab
            TabPage maintTab = new TabPage { Text = "Maintenance" };
            GroupBox maintGroup = new GroupBox { Dock = DockStyle.Fill, Text = "Maintenance Operations" };
            Button backupBtn = new Button { Text = "Backup Config", Top = 20, Left = 20, Width = 120, Height = 30 };
            Button updateBtn = new Button { Text = "Update Vulns", Top = 60, Left = 20, Width = 120, Height = 30 };
            Button cleanBtn = new Button { Text = "Database Cleanup", Top = 100, Left = 20, Width = 120, Height = 30 };
            maintGroup.Controls.AddRange(new Control[] { backupBtn, updateBtn, cleanBtn });
            maintTab.Controls.Add(maintGroup);

            tabControl.TabPages.AddRange(new TabPage[] { vmTab, teamTab, maintTab });
            this.Controls.Add(tabControl);
        }
    }
}
