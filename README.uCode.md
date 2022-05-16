needrestart - microcode support
===============================

Some CPU architectures supports microcode updates to mitigate hardware-level
bugs. Needrestart checks if the current running microcode signature matches
the most recent version available on the host.

The detection is currently only supported for AMD and Intel CPUs.


AMD
---

Needrestart decodes the AMD ucode firmware files to check for updates. This
requires to know the cpu's CPUID value. The most reliable way is to use the
cpuid kernel module (modprobe cpuid).

As a fallback the CPUID is calculated from /proc/cpuinfo. The calculation
might be wrong and should be avoided by loading the cpuinfo kernel module.


Intel
-----

Needrestart uses `iucode-tool`[1] to test for pending microcode updates. On
Debian GNU/Linux it should be sufficient to install the `intel-microcode`
package:

```console
# apt-get install intel-microcode
```

[1] https://gitlab.com/iucode-tool/iucode-tool/wikis/home
