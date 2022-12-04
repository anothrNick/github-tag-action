# hadolint ignore=DL3007
FROM ghcr.io/anothrnick/github-tag-action:latest

LABEL "repository"="https://github.com/anothrnick/github-tag-action"
LABEL "homepage"="https://github.com/anothrnick/github-tag-action"
LABEL "maintainer"="Nick Sjostrom"

# This Dockerfile is empty, it simply pulls a prebuilt image to speed up the Action.
