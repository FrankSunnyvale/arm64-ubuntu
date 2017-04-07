FROM scratch
MAINTAINER Frank <frank.wzuo@gmail.com>

# References:
# https://github.com/tianon/docker-brew-ubuntu-core/blob/master/update.sh
# https://registry.hub.docker.com/u/ericvh/arm64-ubuntu/

# We base the system on an aarch64 image.
#ADD http://cdimage.ubuntu.com/ubuntu-core/releases/15.04/release/ubuntu-core-15.04-core-arm64.tar.gz /
#ADD ubuntu-core-15.04-core-arm64.tar.gz /
ADD ubuntu-core-16.04-core-arm64.tar.gz /

# We need qemu user emulation to run aarch64 binaries on x86 host.
# This requires binfmt setup on host.
# See https://wiki.debian.org/QemuUserEmulation.
#
# Yes, we copy the qemu binary (x86) into our aarch64 rootfs so it can be
# found and used inside docker. We'll also keep it around so dependent images
# don't need to add it. Confusing, perhaps. Unfortunately this is required.
#
# To be clear, this will be the one and only x86 binary included in our
# aarch64 rootfs. When this image is docker-export'ed, this binary can
# and should be removed.
ADD qemu-aarch64-static /usr/bin/qemu-aarch64-static
RUN chmod +x /usr/bin/qemu-aarch64-static

# a few minor docker-specific tweaks
# see https://github.com/docker/docker/blob/master/contrib/mkimage/debootstrap
RUN echo '#!/bin/sh' > /usr/sbin/policy-rc.d \
    && echo 'exit 101' >> /usr/sbin/policy-rc.d \
    && chmod +x /usr/sbin/policy-rc.d \
    \
    && dpkg-divert --local --rename --add /sbin/initctl \
    && cp -a /usr/sbin/policy-rc.d /sbin/initctl \
    && sed -i 's/^exit.*/exit 0/' /sbin/initctl \
    \
    && echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup \
    \
    && echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > /etc/apt/apt.conf.d/docker-clean \
    && echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> /etc/apt/apt.conf.d/docker-clean \
    && echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' >> /etc/apt/apt.conf.d/docker-clean \
    \
    && echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/docker-no-languages \
    \
    && echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/docker-gzip-indexes

# enable the universe
RUN sed -i 's/^#\s*\(deb.*universe\)$/\1/g' /etc/apt/sources.list

# Let's upgrade the packages, since the world has moved on since the
# tarball release.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y \
    && rm -rf /var/lib/apt/lists/*

# overwrite this with 'CMD []' in a dependent Dockerfile
CMD ["/bin/bash"]


