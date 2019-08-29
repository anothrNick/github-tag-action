FROM ubuntu:18.04
LABEL "com.github.actions.name"="Github Tag Bump"
LABEL "com.github.actions.description"="Bump and push git tag on merge"
LABEL "com.github.actions.icon"="git-branch"
LABEL "com.github.actions.color"="gray-dark"

LABEL "repository"="https://github.com/anothrNick/github-tag-action"
LABEL "maintainer"="Nick Sjostrom"

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y git && \
    apt-get install -y curl

COPY ./contrib/semver ./contrib/semver
RUN chmod +x ./contrib/semver
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
