FROM node:16-alpine

LABEL "repository"="https://github.com/anothrnick/github-tag-action"
LABEL "homepage"="https://github.com/anothrnick/github-tag-action"
LABEL "maintainer"="Nick Sjostrom"

# hadolint ignore=DL3016,DL3018
RUN apk --no-cache add bash git curl jq && npm install -g semver

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
