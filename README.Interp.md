needrestart - interpreter support
=================================

Needrestart checks running processes for using obsolete binaries. If no
obsolete binary was found needrestart scans for known interpreters.
There are special packages (NeedRestart::Interp::*) implementing the
source code file list extraction. The executable (/proc/<pid>/exec) is
used to detect the running interpreter.

Whenever source files where located their ctime values are retrieved. If
any of the source files has been changed after process creation time
a restart of the pid is triggered. This is no perfect valuation since
there are no inode informations like for loaded binary objects nor has
needrestart any chance to get a verified list of sourced files..


NeedRestart::Interp::Perl
-------------------------

Recognized binaries:	/usr/(local/)?bin/perl
Find source file by:	command line interpretation

We are using Module::ScanDeps to find used packages. This should work on
any static loaded packages, dynamic stuff will fail.


NeedRestart::Interp::Python
-------------------------

Recognized binaries:	/usr/(local/)?bin/python.*
Find source file by:	command line interpretation

The source file is scanned for 'import' and 'from' lines. All paths in
*sys.path* are scanned for the module files. This should work on any
static loaded modules.
