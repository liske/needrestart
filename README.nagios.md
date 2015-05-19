needrestart - nagios plugin mode
================================

Needrestart can be used as a nagios plugin:

```console
# needrestart -p
CRIT - Kernel: 3.16.0-4-amd64, Services: none, Containers: 1 (!), Sessions: none|Kernel=0;0;;0;2 Services=0;;0;0 Containers=1;;0;0 Sessions=0;0;;0
```

Since needrestart requires root privileges to scan processes of other
users you should use sudo. Needrestart ships some example files to run
needrestart as nagios plugin using sudo:

- `ex/nagios/check_needrestart` - calls sudo to invoke needrestart
- `ex/nagios/needrestart` - sudo(8) config allowing nagios to run needrestart as root
- `ex/nagios/check_needrestart.conf` - nagios(8) integration
