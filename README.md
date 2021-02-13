# GitHub Actions Runner

Built on `ubuntu:20.04`, configured for rootless dind 🎉, impossible without valuable advice from @kenichi-shibata and @sidick.
## Inspiration from
https://github.com/cruizba/ubuntu-dind
https://github.com/myoung34/docker-github-actions-runner
https://github.com/docker-library/docker/tree/master/20.10/dind

# Images
- [msyea/ubuntu-docker](https://hub.docker.com/repository/docker/msyea/ubuntu-docker)
- [msyea/ubuntu-dind](https://hub.docker.com/repository/docker/msyea/ubuntu-dind)
- [msyea/github-actions-runner](https://hub.docker.com/repository/docker/msyea/github-actions-runner)


```
# start container
docker run --privileged -it msyea/github-actions-runner bash

# start dockerd
dockerd-rootless.sh &

# test
docker ps
docker run hello-world
```