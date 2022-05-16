needrestart - container support
===============================

If needrestart has found a process using obsolete binaries it checks if
the process is part of a container. If the process is part of a container
it might not be possible to restart it using Sys-V/systemd.

There are special packages (NeedRestart::CONT::*) implementing the
container detection and restarting.


NeedRestart::CONT::docker
-------------------------

Recognized by:	cgroup path (`/system.slice/docker-*.scope` || `/docker/*`)

Docker containers are ignored (needrestart 2.12+) since there are no updates
within docker containers by design.


NeedRestart::CONT::LXC
----------------------

Recognized by:	cgroup path (`/lxc/*` || `/lxc.payload/*`)

For each container which should be restarted needrestart calls
`lxc-stop --reboot --name $NAME`.

This package also supports LXD containers, which are restarted by `lxc restart
$NAME` or `lxc restart --project=$PROJECT $NAME` for containers in projects.

NeedRestart::CONT::machined
---------------------------

Recognized by:	cgroup path (`/machine.slice/machine-*.scope`)

For each container which should be restarted needrestart calls
`machinectl reboot $NAME`.
