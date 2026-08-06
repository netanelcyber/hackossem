# Lab Index - 110 Vagrantfiles

## Quick Navigation

### By Base Lab Type
- [AD Basics (labs 1-21)](###-active-directory-basics)
- [LDAP Enumeration (labs 22-42)](###-ldap-enumeration)
- [Kerberos (labs 43-63)](###-kerberos)
- [Privilege Escalation (labs 64-84)](###-privilege-escalation)
- [Golden Ticket (labs 85-105)](###-golden-ticket)

### By Difficulty
- [Easy Labs (1-35)](###-easy-labs)
- [Medium Labs (36-70)](###-medium-labs)
- [Hard Labs (71-105)](###-hard-labs)

### By Scenario Type
- [Standard Scenarios](###-standard-scenarios)
- [Advanced Scenarios](###-advanced-scenarios)
- [Hardened Scenarios](###-hardened-scenarios)
- [Stress Test Scenarios](###-stress-test-scenarios)

## Launch Examples

```bash
# Single lab
vagrant up training-001

# Multiple labs
vagrant up training-001 training-002 training-003

# By difficulty
vagrant up training-{001..007}   # Easy labs
vagrant up training-{015..021}   # Hard labs

# All AD Basics variations
vagrant up training-{001..021}
```

## File Listing

```
Vagrantfile.training-001 through Vagrantfile.training-105
```

See `LAB_INVENTORY.txt` for complete details.
