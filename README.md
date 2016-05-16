needrestart
===========

about
-----

*needrestart* checks which daemons need to be restarted after library
upgrades. It is inspired by *checkrestart* from the *debian-goodies*
package.

There are some hook scripts in the ``ex/`` directory (to be used with
*apt* and *dpkg*. The scripts will call *needrestart*
after any package installation/upgrades.

*needrestart* should work on GNU/Linux. It has limited functionality on
GNU/kFreeBSD since /proc/<pid>/maps does not show removed file links.


restarting services
-------------------

*needrestart* supports but does not require systemd (available since v0.6).
If systemd is not available or does not return a service name *needrestart*
uses hooks to identify the corresponding System V init script. The shipped
hooks support the following package managers:

* *dpkg*
* *rpm*
* *pacman*

The *service* command is used to run the tradiditional System V init script.


frontends
---------

*needrestart* uses a modular aproach based on perl packages providing
the user interface. The following frontends are shipped:

* *NeedRestart::UI::Debconf* using *debconf*
* *NeedRestart::UI::stdio* fallback using stdio interaction


interpreters
------------

*needrestart* 0.8 brings an interpreter scanning feature. Interpreters
not only map binary (shared) objects but also use plaintext source files.
The interpreter detection tries to check for outdated source files since
they may contain security issues, too. This is only a heuristic and might
fail to detect all relevant source files. The following interpreter
scanners are shipped:

* *NeedRestart::Interp::Java*
* *NeedRestart::Interp::Perl*
* *NeedRestart::Interp::Python*
* *NeedRestart::Interp::Ruby*


containers
----------

*needrestart* 2.1 detects some container technologies. If a process is
part of a container it might not be possible to restart it using
Sys-V/systemd.

There are special packages (NeedRestart::CONT::*) implementing the
container detection and restarting. The following container detectors
are shipped:

* *NeedRestart::CONT::docker*
* *NeedRestart::CONT::LXC*
* *NeedRestart::CONT::machined*
