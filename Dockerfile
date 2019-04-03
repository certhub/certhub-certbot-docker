ARG alpine_version=edge

FROM alpine:${alpine_version} as base
RUN apk update && apk upgrade

#
# git-gau build stage
#
FROM base as gitgau-build

RUN apk add --no-cache make

RUN mkdir /src /dist

ARG gitgau_ref=master
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

ARG certhub_ref=master
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

ARG certbot_ref=master
ENV certbot_ref ${certbot_ref}

ADD "https://codeload.github.com/certbot/certbot/tar.gz/${certbot_ref}" /src/certbot-src.tar.gz
RUN tar -o -C /src -xf /src/certbot-src.tar.gz

ARG lexicon_ref=master
ENV lexicon_ref ${lexicon_ref}

ADD "https://codeload.github.com/AnalogJ/lexicon/tar.gz/${lexicon_ref}" /src/lexicon-src.tar.gz
RUN tar -o -C /src -xf /src/lexicon-src.tar.gz

ENV PIP_DISABLE_PIP_VERSION_CHECK 1
RUN pip3 install --install-option="--prefix=/dist" /src/certbot-*/acme/ /src/certbot-*/ /src/lexicon-*/

#
# runtime image stage
#
FROM base

RUN apk add --no-cache ca-certificates git openssh-client openssl tini

COPY --from=gitgau-build /dist /usr
COPY --from=certhub-build /dist /usr
COPY --from=certbot-build /dist /usr

RUN addgroup -S certhub && adduser -S certhub -G certhub

USER certhub

ENTRYPOINT [ \
    "/sbin/tini", \
    "--", \
    "/usr/bin/ssh-agent", \
    "/usr/lib/git-gau/docker-entry", \
    "/usr/lib/git-gau/docker-entry.d" \
]
