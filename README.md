needrestart
===========

about
-----

*needrestart* checks which daemons need to be restarted after library
upgrades. It is inspired by ```checkrestart(1)``` from the *debian-goodies*
package.

There are some hook scripts in the ``ex/`` directory (to be used with
```apt(1)``` and ```dpkg(1)```). The scripts will call *needrestart*
after any package installation/upgrades.


package managers
----------------

*needrestart* uses hooks to identify the corresponding rc script of
binaries requiring a restart. The shipped hooks support the following
package managers:

* dpkg
* rpm
* pacman


frontends
---------

*needrestart* uses a modular aproach based on perl packages providing
the user interface. The following frontends are shipped:

* ``NeedRestart::UI::Debconf`` uses ```debconf(1)```
* ``NeedRestart::UI::Debconf`` uses ```UI::Dialog(3pm)```
* ``NeedRestart::UI::stdio`` fallback using stdio interaction
