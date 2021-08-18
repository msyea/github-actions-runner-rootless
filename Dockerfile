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
  DOCKER_VERSION=20.10.6

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

# pre-create "/var/lib/docker" for our rootless user
RUN set -eux; \
	mkdir -p /home/rootless/.local/share/docker; \
	chown -R rootless:rootless /home/rootless/.local/share/docker
VOLUME /home/rootless/.local/share/docker

RUN apt-get -y install awscli

COPY packages.txt .
RUN xargs -a packages.txt apt-get -y install

RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
RUN apt-get install -y nodejs

ENV COMPOSE_VERSION=1.29.2

RUN curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose; \
	chmod +x /usr/local/bin/docker-compose

ENV RUNNER_VERSION=2.280.2

WORKDIR /actions-runner
RUN chown rootless:rootless /actions-runner
USER rootless
RUN wget -O actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
RUN tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
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
