using System;
using System.Windows.Forms;

namespace VulnLabWizard.Forms
{
    public partial class ModeSelectorForm : Form
    {
        public event Action<string> OnModeSelected;

        public ModeSelectorForm()
        {
            InitializeComponent();
        }

        private void InitializeComponent()
        {
            this.Text = "Select Mode";
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = AutoScaleMode.Font;

            TableLayoutPanel table = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                ColumnCount = 2,
                RowCount = 4,
                Padding = new System.Windows.Forms.Padding(20)
            };

            // Instructor mode
            Button instructorBtn = new Button
            {
                Text = "Instructor Mode",
                Width = 150,
                Height = 60,
                Font = new System.Drawing.Font("Arial", 11, System.Drawing.FontStyle.Bold)
            };
            instructorBtn.Click += (s, e) => OnModeSelected?.Invoke("instructor");
            Label instructorLabel = new Label
            {
                Text = "Complete fresh deployment of all 20 labs",
                Dock = DockStyle.Fill,
                AutoSize = false
            };

            // Student mode
            Button studentBtn = new Button
            {
                Text = "Student Mode",
                Width = 150,
                Height = 60,
                Font = new System.Drawing.Font("Arial", 11, System.Drawing.FontStyle.Bold)
            };
            studentBtn.Click += (s, e) => OnModeSelected?.Invoke("student");
            Label studentLabel = new Label
            {
                Text = "Access and manage existing labs",
                Dock = DockStyle.Fill,
                AutoSize = false
            };

            // Admin mode
            Button adminBtn = new Button
            {
                Text = "Admin Mode",
                Width = 150,
                Height = 60,
                Font = new System.Drawing.Font("Arial", 11, System.Drawing.FontStyle.Bold)
            };
            adminBtn.Click += (s, e) => OnModeSelected?.Invoke("admin");
            Label adminLabel = new Label
            {
                Text = "Clone labs, snapshots, team setup",
                Dock = DockStyle.Fill,
                AutoSize = false
            };

            // Auto mode
            Button autoBtn = new Button
            {
                Text = "Automated Mode",
                Width = 150,
                Height = 60,
                Font = new System.Drawing.Font("Arial", 11, System.Drawing.FontStyle.Bold)
            };
            autoBtn.Click += (s, e) => OnModeSelected?.Invoke("auto");
            Label autoLabel = new Label
            {
                Text = "Silent deployment via configuration file",
                Dock = DockStyle.Fill,
                AutoSize = false
            };

            table.Controls.Add(instructorBtn, 0, 0);
            table.Controls.Add(instructorLabel, 1, 0);
            table.Controls.Add(studentBtn, 0, 1);
            table.Controls.Add(studentLabel, 1, 1);
            table.Controls.Add(adminBtn, 0, 2);
            table.Controls.Add(adminLabel, 1, 2);
            table.Controls.Add(autoBtn, 0, 3);
            table.Controls.Add(autoLabel, 1, 3);

            this.Controls.Add(table);
        }
    }
}
