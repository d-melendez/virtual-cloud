FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Horizon from Ubuntu Cloud Archive (caracal / 2024.1)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        software-properties-common \
        ca-certificates \
        curl \
        apache2 \
        libapache2-mod-wsgi-py3 \
        tzdata \
    && add-apt-repository -y cloud-archive:caracal \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        openstack-dashboard \
    && a2enmod wsgi headers rewrite \
    && a2enconf openstack-dashboard \
    && rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=5 \
    CMD curl -fsS http://localhost/ || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2ctl", "-D", "FOREGROUND"]


