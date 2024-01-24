FROM ubuntu:focal

ENV DEB_VERSION 9.16.1-0ubuntu2
ENV LC_ALL C.UTF-8
ENV BIND_DATA_DIR /data/bind

RUN DEBIAN_FRONTEND=noninteractive apt-get -qqy update
RUN DEBIAN_FRONTEND=noninteractive apt-get -qqy install bind9=1:$DEB_VERSION* bind9utils=1:$DEB_VERSION* dnsutils
RUN rm -rf /var/lib/apt/lists/*

RUN mkdir -p $BIND_DATA_DIR \
    && rm -rf /etc/bind \
    && ln -sf $BIND_DATA_DIR/etc /etc/bind \
    && chmod -R 0775 $BIND_DATA_DIR \
    && chown -R bind:bind $BIND_DATA_DIR
RUN mkdir -p /var/cache/bind && chmod 0755 /var/cache/bind && chown bind:bind /var/cache/bind
RUN mkdir -p /var/run/named && chmod 0755 /var/run/named && chown root:bind /var/run/named

#EXPOSE 53/udp 53/tcp

CMD ["/usr/sbin/named", "-f", "-g", "-u", "bind"]
