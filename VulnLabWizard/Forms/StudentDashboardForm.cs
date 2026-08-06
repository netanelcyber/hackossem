using System;
using System.Windows.Forms;

namespace VulnLabWizard.Forms
{
    public partial class StudentDashboardForm : Form
    {
        public StudentDashboardForm()
        {
            InitializeComponent();
        }

        private void InitializeComponent()
        {
            this.Text = "Student Lab Dashboard";
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = AutoScaleMode.Font;
            this.Dock = DockStyle.Fill;

            // Create lab list
            DataGridView labsGrid = new DataGridView
            {
                Dock = DockStyle.Fill,
                AutoGenerateColumns = false,
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                ReadOnly = false
            };

            // Add columns
            labsGrid.Columns.Add("LabName", "Lab Name");
            labsGrid.Columns.Add("Difficulty", "Difficulty");
            labsGrid.Columns.Add("Status", "Status");
            labsGrid.Columns.Add("Action", "Action");

            // Add sample data
            for (int i = 1; i <= 20; i++)
            {
                string difficulty = i <= 6 ? "Easy" : (i <= 13 ? "Medium" : "Hard");
                labsGrid.Rows.Add($"AD-WS-{difficulty}-{i}", difficulty, "Stopped", "Connect");
            }

            this.Controls.Add(labsGrid);
        }
    }
}
