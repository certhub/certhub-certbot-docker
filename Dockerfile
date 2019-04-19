ARG alpine_version=3.9.3

FROM alpine:${alpine_version} as base
RUN apk update && apk upgrade

#
# git-gau build stage
#
FROM base as gitgau-build

RUN apk add --no-cache make

RUN mkdir /src /dist

ARG gitgau_ref=v1.1.0
ENV gitgau_ref ${gitgau_ref}

ADD "https://codeload.github.com/znerol/git-gau/tar.gz/${gitgau_ref}" /src/git-gau-src.tar.gz
RUN tar -o -C /src -xf /src/git-gau-src.tar.gz
RUN make -C /src/git-gau-* prefix=/dist install-bin

#
# certhub build stage
#
FROM base as certhub-build

RUN apk add --no-cache make

RUN mkdir /src /dist

ARG certhub_ref=v1.0.0-beta6
ENV certhub_ref ${certhub_ref}

ADD "https://codeload.github.com/certhub/certhub/tar.gz/${certhub_ref}" /src/certhub-src.tar.gz
RUN tar -o -C /src -xf /src/certhub-src.tar.gz
RUN make -C /src/certhub-* prefix=/dist install-bin

#
# certbot build stage
#
FROM base as certbot-build

RUN apk add --no-cache alpine-sdk python3-dev libffi-dev openssl-dev

RUN mkdir /src /dist

ARG certbot_ref=v0.33.1
ENV certbot_ref ${certbot_ref}

ADD "https://codeload.github.com/certbot/certbot/tar.gz/${certbot_ref}" /src/certbot-src.tar.gz
RUN tar -o -C /src -xf /src/certbot-src.tar.gz

ARG lexicon_ref=v3.2.3
ENV lexicon_ref ${lexicon_ref}

ADD "https://codeload.github.com/AnalogJ/lexicon/tar.gz/${lexicon_ref}" /src/lexicon-src.tar.gz
RUN tar -o -C /src -xf /src/lexicon-src.tar.gz

ENV PIP_DISABLE_PIP_VERSION_CHECK 1
RUN pip3 install --install-option="--prefix=/dist" /src/certbot-*/acme/ /src/certbot-*/ /src/lexicon-*/

#
# runtime image stage
#
FROM base

RUN apk add --no-cache ca-certificates curl git openssh-client openssl python3 tini

COPY --from=gitgau-build /dist /usr
COPY --from=certhub-build /dist /usr
COPY --from=certbot-build /dist /usr

RUN addgroup -S certhub && adduser -S certhub -G certhub && \
    mkdir -p /etc/letsencrypt /var/log/letsencrypt /var/lib/letsencrypt && \
    chown certhub.certhub /etc/letsencrypt /var/log/letsencrypt /var/lib/letsencrypt

USER certhub

ENTRYPOINT [ \
    "/sbin/tini", \
    "--", \
    "/usr/bin/ssh-agent", \
    "/usr/lib/git-gau/docker-entry", \
    "/usr/lib/git-gau/docker-entry.d" \
]
