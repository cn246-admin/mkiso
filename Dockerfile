# syntax=docker/dockerfile:1
# escape=\

FROM debian:stable-slim

ENV TERM=xterm-256color
ENV DEBIAN_FRONTEND=noninteractive

# hadolint ignore=DL3008
RUN <<EOR
apt-get update
apt-get upgrade -y
apt-get install --no-install-recommends -y \
  cpio \
  gettext \
  vim-tiny \
  whois \
  xorriso

rm -rf /var/lib/apt/lists/*
EOR

WORKDIR /opt/mkiso

CMD ["/bin/bash"]

# ENTRYPOINT ["/opt/mkiso/mkiso"]

# vim: ft=dockerfile ts=2 sts=2 sw=2 sr et
