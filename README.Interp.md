needrestart - interpreter support
=================================

Needrestart checks running processes for using obsolete binaries. If no
obsolete binary was found needrestart scans for known interpreters.
There are special packages (NeedRestart::Interp::*) implementing the
source code file list extraction. The executable (`/proc/<pid>/exec`) is
used to detect the running interpreter.

Whenever source files where located their ctime values are retrieved. If
any of the source files has been changed after process creation time
a restart of the pid is triggered. This is no perfect valuation since
there are no inode information like for loaded binary objects nor has
needrestart any chance to get a verified list of sourced files..


NeedRestart::Interp::Java
-------------------------

Recognized binaries:	/.+/bin/java
Find source file by:	n/a

Try to detected loaded \.(class|jar) files by looking at open files. This
approach will not reliably detect loaded java files. Finding the original
command used to launch a java program is not that easy. Since there is no
shebang we will not find any data about the original command in /proc/$PID.

Running on systemd will allow us to find the service name due to the
cgroup name - seems to work for java daemons like tomcat6.


NeedRestart::Interp::Perl
-------------------------

Recognized binaries:	/usr/(local/)?bin/perl
Find source file by:	command line interpretation

The source file is scanned only for 'use' lines, other module loading
mechanisms will not be recognized.

*This function used the Module::ScanDeps package to get the used Perl packages
until needrestart 3.7. Module::ScanDeps is not used any more as it seems not
to be designed to work with untrustworthy perl sources which would allow an
attacker to use needrestart for local privilege escalation.*


NeedRestart::Interp::Python
---------------------------

Recognized binaries:	/usr/(local/)?bin/python.*
Find source file by:	command line interpretation

The source file is scanned for 'import' and 'from' lines. All paths in
`sys.path` are scanned for the module files. This should work on any
static loaded modules.


NeedRestart::Interp::Ruby
-------------------------

Recognized binaries:	/usr/(local/)?bin/ruby.*
Find source file by:	command line interpretation

The source file is scanned for 'load' and 'require' lines. All paths in
`$:` are scanned for the module files. This should work on any
static loaded modules.
