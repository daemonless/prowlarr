ARG BASE_VERSION=15
FROM ghcr.io/daemonless/arr-base:${BASE_VERSION}

ARG FREEBSD_ARCH=amd64
ARG PACKAGES="prowlarr"
ARG PROWLARR_BRANCH="master"
ARG UPSTREAM_URL="https://prowlarr.servarr.com/v1/update/master/changes?os=bsd&runtime=netcore"
ARG UPSTREAM_JQ=".[0].version"
ARG HEALTHCHECK_ENDPOINT="http://localhost:9696/ping"

ENV HEALTHCHECK_URL="${HEALTHCHECK_ENDPOINT}"

LABEL org.opencontainers.image.title="Prowlarr" \
    org.opencontainers.image.description="Prowlarr indexer management on FreeBSD" \
    org.opencontainers.image.source="https://github.com/daemonless/prowlarr" \
    org.opencontainers.image.url="https://prowlarr.com/" \
    org.opencontainers.image.documentation="https://wiki.servarr.com/prowlarr" \
    org.opencontainers.image.licenses="GPL-3.0-only" \
    org.opencontainers.image.vendor="daemonless" \
    org.opencontainers.image.authors="daemonless" \
    io.daemonless.port="9696" \
    io.daemonless.arch="${FREEBSD_ARCH}" \
    org.freebsd.jail.allow.mlock="required" \
    io.daemonless.category="Media Management" \
    io.daemonless.upstream-url="${UPSTREAM_URL}" \
    io.daemonless.upstream-jq="${UPSTREAM_JQ}" \
    io.daemonless.healthcheck-url="${HEALTHCHECK_ENDPOINT}" \
    io.daemonless.packages="${PACKAGES}"

# Install Prowlarr from FreeBSD packages
RUN pkg update && \
    pkg install -y ${PACKAGES} && \
    pkg clean -ay && \
    rm -rf /var/cache/pkg/* /var/db/pkg/repos/* && \
    mkdir -p /usr/local/share/prowlarr /config && \
    PROWLARR_VERSION=$(fetch -qo - "https://prowlarr.servarr.com/v1/update/${PROWLARR_BRANCH}/changes?os=bsd&runtime=netcore" | \
    grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4) && \
    fetch -qo - "https://prowlarr.servarr.com/v1/update/${PROWLARR_BRANCH}/updatefile?os=bsd&arch=x64&runtime=netcore" | \
    tar xzf - -C /usr/local/share/prowlarr --strip-components=1 && \
    rm -rf /usr/local/share/prowlarr/Prowlarr.Update && \
    chmod +x /usr/local/share/prowlarr/Prowlarr && \
    chmod -R o+rX /usr/local/share/prowlarr && \
    printf "UpdateMethod=docker\nBranch=${PROWLARR_BRANCH}\nPackageVersion=%s\nPackageAuthor=[daemonless](https://github.com/daemonless/daemonless)\n" "$PROWLARR_VERSION" > /usr/local/share/prowlarr/package_info && \
    mkdir -p /app && echo "$PROWLARR_VERSION" > /app/version && \
    chown -R bsd:bsd /usr/local/share/prowlarr /config

# Copy service definition and init scripts
COPY root/ /

# Make scripts executable
RUN chmod +x /etc/services.d/prowlarr/run /etc/cont-init.d/* 2>/dev/null || true

EXPOSE 9696
VOLUME /config


