# auto-tag-release

A Github Action to automatically bump and tag master, on merge, with the latest semver formatted version.

* Modified version of [anothrNick/github-tag-action](https://github.com/anothrNick/github-tag-action)

[![Build Status](https://github.com/reececomo/auto-tag-release/workflows/Bump%20version/badge.svg)](https://github.com/reececomo/auto-tag-release/workflows/Bump%20version/badge.svg)
[![Stable Version](https://img.shields.io/github/v/tag/reececomo/auto-tag-release)](https://img.shields.io/github/v/tag/reececomo/auto-tag-release)
[![Latest Release](https://img.shields.io/github/v/release/reececomo/auto-tag-release?color=%233D9970)](https://img.shields.io/github/v/release/reececomo/auto-tag-release?color=%233D9970)

> Medium Post: [Creating A Github Action to Tag Commits](https://itnext.io/creating-a-github-action-to-tag-commits-2722f1560dec)

[<img src="https://miro.medium.com/max/1200/1*_4Ex1uUhL93a3bHyC-TgPg.png" width="400">](https://itnext.io/creating-a-github-action-to-tag-commits-2722f1560dec)

### Usage

```Dockerfile
name: Tag Release
on:
  push:
    branches:
      - master
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: Tag Release
      uses: reececomo/auto-tag-release@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        REPO_OWNER: reececomo
        DEFAULT_BUMP: major
```

### Options

* `REPO_OWNER` **[Required]** - Be sure to set the *REPO_OWNER* environment variable so that the action tags your repo.
* `GITHUB_TOKEN` **[Required]** - Used to authorize the tag
* `DEFAULT_BUMP` _[Optional]_ - Which type of version bump to default to if no override is supplied. Default is `minor`.

*NOTE:* This creates a [lightweight tag](https://developer.github.com/v3/git/refs/#create-a-reference)

### Prevent Duplicate Tags/Commits

It will not bump the tag version if an existing tag already exists for the HEAD commit.

### Override Bumping

Any commit message with `#major`, `#minor`, or `#patch` in the commit message will trigger the respective version bump.

### Workflow

* Add this action to your repo
* Commit some changes
* Either push to master or open a PR
* On push(or merge) to master, Action will:
  * Get latest tag
  * Bump tag with minor version unless any commit message contains `#major` or `#patch`
  * Pushes tag to GitHub

### Credits

* [fsaintjacques/semver-tool](https://github.com/fsaintjacques/semver-tool)
* [anothrNick/github-tag-action](https://github.com/anothrNick/github-tag-action)
