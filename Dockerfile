FROM msyea/ubuntu-dind

RUN apt-get -y install curl supervisor

RUN adduser --disabled-password runner
WORKDIR /actions-runner
RUN chown runner:runner /actions-runner
# USER runner
# RUN curl -O -L https://github.com/actions/runner/releases/download/v2.277.1/actions-runner-linux-x64-2.277.1.tar.gz
# RUN tar xzf ./actions-runner-linux-x64-2.277.1.tar.gz
# USER root
# RUN ./bin/installdependencies.sh

COPY supervisor/ /etc/supervisor/conf.d/
COPY logger.sh /opt/bash-utils/logger.sh

# note https://github.com/docker-library/docker/issues/200#issuecomment-550089770
COPY startup.sh /usr/local/bin/

# "/run/user/UID" will be used by default as the value of XDG_RUNTIME_DIR
RUN mkdir /run/user && chmod 1777 /run/user

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

# RUN groupadd docker \
#   && usermod -aG docker runner

COPY github-actions-entrypoint.sh runner.sh token.sh dockerd-rootless.sh dockerd-rootless-setup-tool.sh /usr/local/bin/

USER rootless
RUN dockerd-rootless-setup-tool.sh install
ENV XDG_RUNTIME_DIR=/home/rootless/.docker/run \
 PATH=/usr/local/bin:$PATH \
 DOCKER_HOST=unix:///home/rootless/.docker/run/docker.sock

ENTRYPOINT [""]