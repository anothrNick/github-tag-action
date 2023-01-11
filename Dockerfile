FROM node:16-bullseye-slim
LABEL "repository"="https://github.com/anothrNick/github-tag-action"
LABEL "homepage"="https://github.com/anothrNick/github-tag-action"
LABEL "maintainer"="Nick Sjostrom"

RUN apt-get update -y \
    && apt-get install bash=5.1-2+deb11u1 git=1:2.30.2-1 curl=7.74.0-1.3+deb11u3 jq=1.6-2.1 --no-install-recommends -y \ 
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g semver

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
