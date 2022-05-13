# needrestart - Restart daemons after library updates.
#
# This shell script is sourced in /usr/lib/needrestart/iucode-scan-versions
# before calling iucode_tool to detect microcode updates for Intel CPUs.
#
# If required you may exec iucode_tool with customized parameters. You should
# keep the `-l $filter` option and add a final exit statement in case the
# exec call fails.

# Example (generic):
# exec iucode_tool -l $filter --ignore-broken -tb /lib/firmware/intel-ucode -ta /usr/share/misc/intel-microcode* 2>&1
# exit $?

# Example (RHEL and derivatives):
# lsinitrd -f kernel/x86/microcode/GenuineIntel.bin | iucode_tool -t b -l -
# exit $?
