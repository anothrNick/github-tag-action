FROM node:16-alpine

LABEL org.opencontainers.image.source="https://github.com/anothrNick/github-tag-action" \
    org.opencontainers.image.title="github-tag-action" \
    org.opencontainers.image.description="A GitHub action to automatically bump and tag the repository based on commit messages" \
    org.opencontainers.image.url="https://github.com/anothrNick/github-tag-action" \
    org.opencontainers.image.documentation="https://github.com/anothrNick/github-tag-action/blob/master/README.md" \
    org.opencontainers.image.vendor="Nick Sjostrom" \
    org.opencontainers.image.maintainer="Nick Sjostrom"

WORKDIR /app

RUN apk --no-cache add --update \
    bash \
    git \
    curl \
    jq \
    && npm install -g semver \
    && rm -rf /var/cache/apk/*

COPY entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
