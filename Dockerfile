FROM msyea/ubuntu-dind

RUN apt-get -y install curl

RUN adduser --disabled-password runner
USER runner
WORKDIR /actions-runner
RUN curl -O -L https://github.com/actions/runner/releases/download/v2.277.1/actions-runner-linux-x64-2.277.1.tar.gz
RUN tar xzf ./actions-runner-linux-x64-2.277.1.tar.gz
USER root
RUN ./bin/installdependencies.sh

# ENTRYPOINT ["startup.sh"]
# CMD ["sh"]