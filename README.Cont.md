needrestart - container support
===============================

If needrestart has found a process using obsolete binaries it checks if
the process is part of a container. If the process is part of a container
it might not be possible to restart it using Sys-V/systemd.

There are special packages (NeedRestart::CONT::*) implementing the
container detection and restarting.


NeedRestart::CONT::docker
-------------------------

Recognized by:	cgroup path (`/system.slice/docker-*.scope`)

For each container which should be restarted needrestart calls
`docker restart $NAME`.


NeedRestart::CONT::LXC
----------------------

Recognized by:	cgroup path (`/lxc/*`)

For each container which should be restarted needrestart calls
`lxc-stop --reboot --name $NAME`.
