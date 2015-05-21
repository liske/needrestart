needrestart - batch mode
========================

Needrestart can be run in batch mode:

```console
# needrestart -b
NEEDRESTART-VER: 2.1
NEEDRESTART-KCUR: 3.19.3-tl1+
NEEDRESTART-KEXP: 3.19.3-tl1+
NEEDRESTART-KSTA: 1
NEEDRESTART-SVC: systemd-journald.service
NEEDRESTART-SVC: systemd-machined.service
NEEDRESTART-CONT: LXC web1
```

Batch mode can be used to use the results of needrestart in other scripts.
While needrestart is run in batch mode it will never show any UI dialogs
nor restart anything. The output format is complient to the
*apt-dater protocol*[1].

[1] https://github.com/DE-IBH/apt-dater-host/blob/master/doc/ADP-0.7
