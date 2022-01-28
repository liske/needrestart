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
NEEDRESTART-SESS: metabase @ user manager service
NEEDRESTART-SESS: root @ session #28017
```

Batch mode can be used to use the results of needrestart in other scripts.
While needrestart is run in batch mode it will never show any UI dialogs
nor restart anything. The output format is compliant with the
*apt-dater protocol*[1].

[1] https://github.com/DE-IBH/apt-dater-host/blob/master/doc/


The kernel status (`NEEDRESTART-KSTA`) value has the following meaning:

- *0*: unknown or failed to detect
- *1*: no pending upgrade
- *2*: ABI compatible upgrade pending
- *3*: version upgrade pending
