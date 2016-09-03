needrestart - nagios plugin mode
================================

Needrestart can be used as a nagios plugin:

```console
# needrestart -p
CRIT - Kernel: 4.6.0-1-amd64, Services: 1 (!), Containers: none, Sessions: 2 (!)|Kernel=0;0;;0;2 Services=1;;0;0 Containers=0;;0;0 Sessions=2;0;;0
Services:
- NetworkManager.service
Sessions:
- thomas @ session #16
- thomas @ user manager service
```

Since needrestart requires root privileges to scan processes of other
users you should use sudo. Needrestart ships some example files to run
needrestart as nagios plugin using sudo:

- `ex/nagios/check_needrestart` - calls sudo to invoke needrestart
- `ex/nagios/needrestart-nagios` - sudo(8) config allowing nagios to run needrestart as root
- `ex/nagios/plugin.conf` - nagios(8) integration
