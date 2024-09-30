FROM alpine:3
LABEL "repository"="https://github.com/anothrNick/github-tag-action"
LABEL "homepage"="https://github.com/anothrNick/github-tag-action"
LABEL "maintainer"="Nick Sjostrom"

RUN apk --no-cache add bash git curl jq && \
  wget -qO /usr/local/bin/semver \
    https://raw.githubusercontent.com/fsaintjacques/semver-tool/master/src/semver && \
  chmod +x /usr/local/bin/semver

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
