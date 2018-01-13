needrestart - microcode support
===============================

Some CPU architectures supports microcode updates to mitigate hardware-level
bugs. Needrestart checks if the current running microcode signature matches
the most recent version available on the host.

The detection is currently only supported for Intel CPUs.


Intel
-----

Needrestart uses `iucode-tool`[1] to test for pending microcode updates. On
Debian GNU/Linux it should be sufficient to install the `intel-microcode`
package:

```console
# apt-get install intel-microcode
```

[1] https://gitlab.com/iucode-tool/iucode-tool/wikis/home
