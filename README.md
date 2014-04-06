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
* *NeedRestart::UI::Debconf* using *UI::Dialog*
* *NeedRestart::UI::stdio* fallback using stdio interaction
