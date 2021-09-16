ARG REGISTRY=msyea
ARG TAG=latest
FROM ${REGISTRY}/ubuntu-dind:${TAG}

# "/run/user/UID" will be used by default as the value of XDG_RUNTIME_DIR
RUN mkdir /run/user && chmod 1777 /run/user

# look into guid !!!
RUN adduser --disabled-password runner

# create a default user preconfigured for running rootless dockerd
RUN set -eux; \
	adduser --home /home/rootless --gecos 'Rootless' --disabled-password rootless; \
	echo 'rootless:100000:65536' >> /etc/subuid; \
	echo 'rootless:100000:65536' >> /etc/subgid

ENV DOCKER_CHANNEL=stable \
  DOCKER_VERSION=20.10.8

# Ubuntu focal (20.04) has git v2.25, but GitHub Actions require higher. We
# build git from source instead.
ARG GIT_VERSION="2.33.0"
ARG GH_RUNNER_VERSION="2.282.1"

# Root URL and version for Docker compose releases
ARG COMPOSE_ROOT=https://github.com/docker/compose/releases/download
ARG COMPOSE_VERSION=1.29.2

RUN set -eux; \
	\
	arch="$(uname --m)"; \
	case "$arch" in \
		'x86_64') \
			url="https://download.docker.com/linux/static/${DOCKER_CHANNEL}/x86_64/docker-rootless-extras-${DOCKER_VERSION}.tgz"; \
			;; \
		*) echo >&2 "error: unsupported architecture ($arch)"; exit 1 ;; \
	esac; \
	\
	wget -O rootless.tgz "$url"; \
	\
	tar --extract \
		--file rootless.tgz \
		--strip-components 1 \
		--directory /usr/local/bin/ \
		'docker-rootless-extras/rootlesskit' \
		'docker-rootless-extras/rootlesskit-docker-proxy' \
		'docker-rootless-extras/vpnkit' \
	; \
	rm rootless.tgz; \
	\
	rootlesskit --version; \
	vpnkit --version

# pre-create "/var/lib/docker" for our rootless user and arrange for .local
# directory to be owned by rootless so default XDG locations associated to this
# directory (XDG_STATE_HOME and XDG_DATA_HOME) can be used.
RUN set -eux; \
	mkdir -p /home/rootless/.local/share/docker; \
	mkdir -p /home/rootless/.local/state; \
	chown -R rootless:rootless /home/rootless/.local
VOLUME /home/rootless/.local/share/docker

RUN apt-get update \
		&& apt-get -y install \
					jq \
					curl \
					awscli \
					software-properties-common \
					build-essential \
					zlib1g-dev \
					zstd \
					gettext \
					libcurl4-openssl-dev \
		&& curl -L "${COMPOSE_ROOT%/}/${COMPOSE_VERSION#v*}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
		&& chmod a+x /usr/local/bin/docker-compose \
		&& docker-compose --version \
		&& cd /tmp \
		&& curl -sL https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz -o git.tgz \
		&& tar zxf git.tgz \
		&& cd git-${GIT_VERSION} \
		&& ./configure --prefix=/usr \
		&& make \
		&& make install \
		&& rm -rf /var/lib/apt/lists/* \
		&& rm -rf /tmp/* \
		&& git --version

WORKDIR /actions-runner
RUN chown rootless:rootless /actions-runner
USER rootless
RUN wget -O actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz https://github.com/actions/runner/releases/download/v${GH_RUNNER_VERSION}/actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz \
		&& tar xzf ./actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz \
		&& rm -f ./actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz
USER root
RUN ./bin/installdependencies.sh

COPY logger.sh /opt/bash-utils/
COPY github-actions-entrypoint.sh runner.sh token.sh dockerd-rootless.sh dockerd-rootless-setup-tool.sh /usr/local/bin/

USER rootless
RUN dockerd-rootless-setup-tool.sh install
ENV XDG_RUNTIME_DIR=/home/rootless/.docker/run \
 PATH=/usr/local/bin:$PATH \
 DOCKER_HOST=unix:///home/rootless/.docker/run/docker.sock

ENTRYPOINT ["github-actions-entrypoint.sh"]