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
ignore the unused image files.

### RPi 1 or RPi 1B

```shell
$ cat << 'EOF' > /etc/needrestart/conf.d/kernel.conf
# Filter kernel image filenames by regex. This is required on Raspian having
# multiple kernel image variants installed in parallel.
$nrconf{kernelfilter} = qr(vmlinuz-.*-v6$);
EOF
```

### RPi 2 or RPi 3

```shell
$ cat << 'EOF' > /etc/needrestart/conf.d/kernel.conf
# Filter kernel image filenames by regex. This is required on Raspian having
# multiple kernel image variants installed in parallel.
$nrconf{kernelfilter} = qr(kernel7\.img);
EOF
```

### RPi 5

RPi 5 has the ability to switch between 16KB and 4KB page size kernels. Run `uname -r` to get the currently used kernel. By default, it should be `6.1.0-rpi8-rpi-2712` (16KB page size).

```shell
$ cat << 'EOF' > /etc/needrestart/conf.d/kernel.conf
# Filter kernel image filenames by regex. This is required on Raspian having
# multiple kernel image variants installed in parallel.
# 6.1.0-rpi8-rpi-v8 (4KB page size)
# $nrconf{kernelfilter} = qr(vmlinuz-.*-v8$);
# 6.1.0-rpi8-rpi-2712 (16KB page size)
$nrconf{kernelfilter} = qr(vmlinuz-.*-2712$);
EOF
```
