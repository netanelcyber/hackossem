# 🏫 VulnLab AD Labs - Multi-VM Setup

## יצירת כל מעבדה ב-VM נפרד

### אפשרות 1: הפעל את כל ה-VMs (מומלץ)

```bash
cd lab-vms-vagrant
vagrant up
```

זה יהיה:
- יוצר 5 VMs בו-זמנית
- מחבר כל אחד לפורט שונה
- מתקין את כל התלויות

### אפשרות 2: הפעל מעבדה ספציפית

```bash
cd lab-vms-vagrant
vagrant up ad-lab-1
```

### גישה למעבדות

| Lab | Name | Port | IP |
|-----|------|------|-------|
| Lab 1 | Active Directory Basics | 5001 | 192.168.56.11 |
| Lab 2 | LDAP Enumeration | 5002 | 192.168.56.12 |
| Lab 3 | Kerberos & ASREProast | 5003 | 192.168.56.13 |
| Lab 4 | Privilege Escalation | 5004 | 192.168.56.14 |
| Lab 5 | Golden Ticket | 5005 | 192.168.56.15 |

גשת לאתר: http://localhost:5001 (עבור Lab 1)

### פקודות שימושיות

```bash
# הפעל Lab ספציפי
vagrant up ad-lab-1

# SSH לתוך Lab
vagrant ssh ad-lab-1

# עצור Lab
vagrant halt ad-lab-1

# מחק Lab
vagrant destroy ad-lab-1

# בדוק סטטוס
vagrant status
```

### דרישות

- VirtualBox
- Vagrant
- 10GB RAM (2GB לכל Lab)
- 100GB דיסק

### ייצוא לקבצי OVA

```bash
# עצור את ה-VMs
vagrant halt

# ייצא
VBoxManage export "VulnLab-ad-lab-1" -o lab-ad-lab-1.ova
```

