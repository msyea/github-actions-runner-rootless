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

RUN set -eux; \
	\
	arch="$(uname --m)"; \
	case "$arch" in \
		'x86_64') \
			url='https://download.docker.com/linux/static/stable/x86_64/docker-rootless-extras-20.10.3.tgz'; \
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

RUN apt-get -y install jq curl

WORKDIR /actions-runner
RUN chown rootless:rootless /actions-runner
USER rootless
RUN wget -O actions-runner-linux-x64-2.277.1.tar.gz https://github.com/actions/runner/releases/download/v2.277.1/actions-runner-linux-x64-2.277.1.tar.gz
RUN tar xzf ./actions-runner-linux-x64-2.277.1.tar.gz
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