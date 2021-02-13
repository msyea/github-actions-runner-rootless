# GitHub Actions Runner

Built on `ubuntu:20.04`, configured for rootless dind 🎉, impossible without valuable advice from @kenichi-shibata and @sidick and work by @myoung34.
## Inspiration from
* https://github.com/cruizba/ubuntu-dind showed me it was possible on ubuntu
* https://github.com/myoung34/docker-github-actions-runner showed it running docker outside docker - inspired API and wrote some README - rights theirs
* https://github.com/docker-library/docker/tree/master/20.10/dind-rootless for their outstanding work

# Images
- [msyea/ubuntu-docker](https://hub.docker.com/repository/docker/msyea/ubuntu-docker)
- [msyea/ubuntu-dind](https://hub.docker.com/repository/docker/msyea/ubuntu-dind)
- [msyea/github-actions-runner](https://hub.docker.com/repository/docker/msyea/github-actions-runner)

Docker Github Actions Runner
============================

[![Docker Pulls](https://img.shields.io/docker/pulls/msyea/github-actions-runner.svg)](https://hub.docker.com/r/msyea/github-actions-runner)

This will run the [new self-hosted github actions runners](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/hosting-your-own-runners).
## Environment Variables ##

| Environment Variable | Description |
| --- | --- |
| `RUNNER_NAME` | The name of the runner to use. Supercedes (overrides) `RUNNER_NAME_PREFIX` |
| `RUNNER_NAME_PREFIX` | A prefix for a randomly generated name (followed by a random 13 digit string). You must not also provide `RUNNER_NAME`. Defaults to `github-runner` |
| `ACCESS_TOKEN` | A [github PAT](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token) to use to generate `RUNNER_TOKEN` dynamically at container start. Not using this requires a valid `RUNNER_TOKEN` |
| `ORG_RUNNER` | Only valid if using `ACCESS_TOKEN`. This will set the runner to an org runner. Default is 'false'. Valid values are 'true' or 'false'. If this is set to true you must also set `ORG_NAME` and makes `REPO_URL` unneccesary |
| `ORG_NAME` | The organization name for the runner to register under. Requires `ORG_RUNNER` to be 'true'. No default value. |
| `LABELS` | A comma separated string to indicate the labels. Default is 'default' |
| `REPO_URL` | If using a non-organization runner this is the full repository url to register under such as 'https://github.com/myoung34/repo' |
| `RUNNER_TOKEN` | If not using a PAT for `ACCESS_TOKEN` this will be the runner token provided by the Add Runner UI (a manual process). Note: This token is short lived and will change frequently. `ACCESS_TOKEN` is likely preferred. |
| `RUNNER_WORKDIR` | The working directory for the runner. Runners on the same host should not share this directory. Default is '/_work'. This must match the source path for the bind-mounted volume at RUNNER_WORKDIR, in order for container actions to access files. |
| `RUNNER_GROUP` | Name of the runner group to add this runner to (defaults to the default runner group) |
| `GITHUB_HOST` | Optional URL of the Github Enterprise server e.g github.mycompany.com. Defaults to `github.com`. |

## Examples ##

### Note ###

If you're using a RHEL based OS with SELinux, add `--security-opt=label=disable` to prevent [permission denied](https://github.com/myoung34/docker-github-actions-runner/issues/9)

### Manual ###

```shell
# org runner
docker run -d --restart always --name github-runner \
  -e RUNNER_NAME_PREFIX="myrunner" \
  -e ACCESS_TOKEN="footoken" \
  -e RUNNER_WORKDIR="/tmp/github-runner-your-repo" \
  -e RUNNER_GROUP="my-group" \
  -e ORG_RUNNER="true" \
  -e ORG_NAME="octokode" \
  -e LABELS="my-label,other-label" \
  msyea/github-actions-runner:latest
# per repo
docker run -d --restart always --name github-runner \
  -e REPO_URL="https://github.com/myoung34/repo" \
  -e RUNNER_NAME="foo-runner" \
  -e RUNNER_TOKEN="footoken" \
  -e RUNNER_WORKDIR="/tmp/github-runner-your-repo" \
  -e RUNNER_GROUP="my-group" \
  msyea/github-actions-runner:latest
```

Or shell wrapper:

```shell
function github-runner {
    name=github-runner-${1//\//-}
    org=$(dirname $1)
    repo=$(basename $1)
    tag=${3:-latest}
    docker rm -f $name
    docker run -d --restart=always \
        -e REPO_URL="https://github.com/${org}/${repo}" \
        -e RUNNER_TOKEN="$2" \
        -e RUNNER_NAME="linux-${repo}" \
        -e RUNNER_WORKDIR="/tmp/github-runner-${repo}" \
        -e RUNNER_GROUP="my-group" \
        -e LABELS="my-label,other-label" \
        --name $name ${org}/github-runner:${tag}
}

github-runner your-account/your-repo       AARGHTHISISYOURGHACTIONSTOKEN
github-runner your-account/some-other-repo ARGHANOTHERGITHUBACTIONSTOKEN ubuntu-xenial
```

Or `docker-compose.yml`:

```yml
version: '2.3'

services:
  worker:
    image: msyea/github-actions-runner:latest
    environment:
      REPO_URL: https://github.com/example/repo
      RUNNER_NAME: example-name
      RUNNER_TOKEN: someGithubTokenHere
      RUNNER_GROUP: my-group
      ORG_RUNNER: 'false'
      LABELS: linux,x64,gpu
```
## Usage From GH Actions Workflow ##

```yml
name: Package

on:
  release:
    types: [created]

jobs:
  build:
    runs-on: self-hosted
    steps:
    - uses: actions/checkout@v1
    - name: build packages
      run: make all
```

## Automatically Acquiring a Runner Token  ##

A runner token can be automatically acquired at runtime if `ACCESS_TOKEN` (a GitHub personal access token) is a supplied. This uses the [GitHub Actions API](https://developer.github.com/v3/actions/self_hosted_runners/#create-a-registration-token). e.g.:

```shell
docker run -d --restart always --name github-runner \
  -e ACCESS_TOKEN="footoken" \
  -e RUNNER_NAME="foo-runner" \
  -e RUNNER_WORKDIR="/tmp/github-runner-your-repo" \
  -e RUNNER_GROUP="my-group" \
  -e ORG_RUNNER="true" \
  -e ORG_NAME="octokode" \
  -e LABELS="my-label,other-label" \
  msyea/github-actions-runner:latest
```

## Create GitHub personal access token  ##

Creating GitHub personal access token (PAT) for using by self-hosted runner make sure the following scopes are selected:

* repo (all)
* admin:org (all) **_(mandatory for organization-wide runner)_**
* admin:public_key - read:public_key
* admin:repo_hook - read:repo_hook
* admin:org_hook
* notifications
* workflow

Also, when creating a PAT for self-hosted runner which will process events from several repositories of the particular organization, create the PAT using organization owner account. Otherwise your new PAT will not have sufficient privileges for all repositories.