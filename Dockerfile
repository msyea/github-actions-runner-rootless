FROM msyea/ubuntu-dind

RUN apt-get -y install curl

# Docker compose installation
RUN curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
	&& chmod +x /usr/local/bin/docker-compose

RUN adduser --disabled-password runner
USER runner
WORKDIR /actions-runner
RUN curl -O -L https://github.com/actions/runner/releases/download/v2.277.1/actions-runner-linux-x64-2.277.1.tar.gz
RUN tar xzf ./actions-runner-linux-x64-2.277.1.tar.gz
USER root
RUN ./bin/installdependencies.sh

# ENTRYPOINT ["startup.sh"]
# CMD ["sh"]