FROM msyea/ubuntu-dind

RUN apt-get -y install curl supervisor

RUN adduser --disabled-password runner
USER runner
WORKDIR /actions-runner
RUN curl -O -L https://github.com/actions/runner/releases/download/v2.277.1/actions-runner-linux-x64-2.277.1.tar.gz
RUN tar xzf ./actions-runner-linux-x64-2.277.1.tar.gz
USER root
RUN ./bin/installdependencies.sh


COPY supervisor/ /etc/supervisor/conf.d/
COPY logger.sh /opt/bash-utils/logger.sh

# note https://github.com/docker-library/docker/issues/200#issuecomment-550089770
COPY startup.sh /usr/local/bin/

RUN groupadd docker \
  && usermod -aG docker runner

ENTRYPOINT ["startup.sh"]
CMD [""]