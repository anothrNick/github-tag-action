FROM prontotools/alpine-git-curl
LABEL "com.github.actions.name"="Auto-Tag Release"
LABEL "com.github.actions.description"="Automatically bump semantic version tags"
LABEL "com.github.actions.icon"="git-merge"
LABEL "com.github.actions.color"="purple"

LABEL "repository"="https://github.com/reececomo/auto-tag-release"
LABEL "homepage"="https://github.com/reececomo/auto-tag-release"
LABEL "maintainer"="Reece Como"

COPY ./contrib/semver ./contrib/semver
RUN install ./contrib/semver /usr/local/bin
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
