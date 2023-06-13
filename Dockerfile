ARG image_tag=latest
#^ TODO: @sammcj pass this through the action, test and document and make sure old images around for a period of time

# hadolint ignore=DL3007
FROM ghcr.io/anothrnick/github-tag-action:$image_tag

LABEL "repository"="https://github.com/anothrnick/github-tag-action"
LABEL "homepage"="https://github.com/anothrnick/github-tag-action"
LABEL "maintainer"="Nick Sjostrom"

# This Dockerfile is empty, it simply pulls a prebuilt image to speed up the Action.
