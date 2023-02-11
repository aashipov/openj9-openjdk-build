# -O3 (/O2) optimized vanilla OpenJ9 openJDK #

## Why? ##

Around 10% faster than conventional one which is relevant for 'low-end' devices

## How ? ##

x86_64 Linux with docker, user with UID 10001, a member of GID 10001 and docker groups, enough disk space to store openJDK source and build dir in ```${HOME}```

[Windows host](win.txt) 

### Linux ###

```shell
DISTRO=opensuse JAVA_VERSION=8 docker-compose -f docker-compose.yml run --rm jdk
```

```shell
DISTRO=opensuse JAVA_VERSION=11 docker-compose -f docker-compose.yml run --rm jdk
```

```shell
DISTRO=opensuse JAVA_VERSION=17 docker-compose -f docker-compose.yml run --rm jdk
```

### Windows ###

Clone, cd, run ```bash entrypoint8.bash```, ```bash entrypoint9plus.bash 11``` or ```bash entrypoint9plus.bash 17```

## Troubleshooting ##

```
error: RPC failed; curl 56 GnuTLS recv error (-54): Error in the pull function.
fatal: The remote end hung up unexpectedly
fatal: early EOF
fatal: index-pack failed
```

On the host ```git config --global http.postBuffer 1048576000``` and ```git clone ...```

## License ##

Perl "Artistic License"
