needrestart
===========

About
-----

*needrestart* checks which daemons need to be restarted after library
upgrades. It is inspired by *checkrestart* from the *debian-goodies*
package.

There are some hook scripts in the ``ex/`` directory (to be used with
*apt* and *dpkg*. The scripts will call *needrestart*
after any package installation/upgrades.

*needrestart* should work on GNU/Linux. It has limited functionality on
GNU/kFreeBSD since `/proc/<pid>/maps` does not show removed file links.


Restarting Services
-------------------

*needrestart* supports but does not require systemd (available since v0.6).
If systemd is used you should use libpam-systemd, too. If needrestart detects
systemd it will assume that libpam-systemd is used and relies on cgroup names
to detect if a process belongs to a user session or a daemon. If you do not
use libpam-systemd you should set $nrconf{has_pam_systemd} to 0 within
needrestart.conf.

If systemd is not available or does not return a service name *needrestart*
uses hooks to identify the corresponding System V init script. The shipped
hooks support the following package managers:

* *dpkg*
* *rpm*
* *pacman*

The *service* command is used to run the traditional System V init script.


Frontends
---------

*needrestart* uses a modular approach based on perl packages providing
the user interface. The following frontends are shipped:

* *NeedRestart::UI::Debconf* using *debconf*
* *NeedRestart::UI::stdio* fallback using stdio interaction


Kernel & Microcode
------------------

*needrestart* 0.8 brings a obsolete kernel detection feature. Since
*needrestart* 3.5 it is possible to filter kernel image filenames (required on
[Raspberry Pi](README.raspberry.md)).

In *needrestart* 3.0 a [processor microcode update detection
feature](README.uCode.md) for Intel CPUs has been added. Since *needrestart* 3.5
the AMD CPU support has been added.


Interpreters
------------

*needrestart* 0.8 brings an [interpreter scanning feature](README.Interp.md).
Interpreters not only map binary (shared) objects but also use plaintext
source files. The interpreter detection tries to check for outdated source
files since they may contain security issues, too. This is only a heuristic
and might fail to detect all relevant source files. The following interpreter
scanners are shipped:

* *NeedRestart::Interp::Java*
* *NeedRestart::Interp::Perl*
* *NeedRestart::Interp::Python*
* *NeedRestart::Interp::Ruby*


Containers
----------

*needrestart* 2.1 [detects some container technologies](README.Cont.md). If a
process is part of a container it might not be possible to restart it using
Sys-V/systemd.

There are special perl packages (NeedRestart::CONT::*) implementing the
container detection and restarting. The following container detectors
are shipped:

* *NeedRestart::CONT::docker*
* *NeedRestart::CONT::LXC*
* *NeedRestart::CONT::machined*


Batch Mode
----------

*needrestart* can be run in [batch mode](README.batch.md) to use the results
within other programs or scripts.

There is also a [nagios plugin mode](README.nagios.md) available.
