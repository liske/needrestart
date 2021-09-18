needrestart - Raspberry Pi
==========================

Raspbian and other linux distros are installing multiple kernel images in
parallel:

- `kernel.img`
- `kernel7.img`
- `kernel7l.img`
- `kernel8.img`

This might result in a continuous pending kernel update false positive. There
is a configuration option in needrestart to filter the kernel image filenames to
ignore the unused image files. To filter the kernel image on a RPi 2 or RPi 3:

```shell
$ cat << EOF > /etc/needrestart/conf.d/kernel.conf
# Filter kernel image filenames by regex. This is required on Raspian having
# multiple kernel image variants installed in parallel.
$nrconf{kernelfilter} = qr(kernel7\.img);
EOF
```
