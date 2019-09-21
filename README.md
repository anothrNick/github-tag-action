# github-tag-action

A Github Action to automatically bump and tag master, on merge, with the latest SemVer formatted version.

[![Build Status](https://github.com/anothrNick/github-tag-action/workflows/Bump%20version/badge.svg)](https://github.com/anothrNick/github-tag-action/workflows/Bump%20version/badge.svg)
[![Stable Version](https://img.shields.io/github/v/tag/anothrNick/github-tag-action)](https://img.shields.io/github/v/tag/anothrNick/github-tag-action)
[![Latest Release](https://img.shields.io/github/v/release/anothrNick/github-tag-action?color=%233D9970)](https://img.shields.io/github/v/release/anothrNick/github-tag-action?color=%233D9970)

> Medium Post: [Creating A Github Action to Tag Commits](https://itnext.io/creating-a-github-action-to-tag-commits-2722f1560dec)

[<img src="https://miro.medium.com/max/1200/1*_4Ex1uUhL93a3bHyC-TgPg.png" width="400">](https://itnext.io/creating-a-github-action-to-tag-commits-2722f1560dec)

### Usage

```Dockerfile
name: Bump version
on:
  push:
    branches:
      - master
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: Bump version and push tag
      uses: anothrNick/github-tag-action@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        REPO_OWNER: anothrNick
```

#### Options

* **REPO_OWNER** ***(required)*** - Required so the action knows which repo to tag.
* **GITHUB_TOKEN** ***(required)*** - Required for permission permissions.
* **DEFAULT_BUMP** *(optional)* - (default: `minor`) Which type of SemVar bump to use if none provided.

*NOTE:* This creates a [lightweight tag](https://developer.github.com/v3/git/refs/#create-a-reference)

### Bumping

Any commit message with `#major`, `#minor`, or `#patch` will trigger the respective version bump. If two or more are present, the biggest one will take preference.

### Workflow

* Add this action to your repo
* Commit some changes
* Either push to master or open a PR
* On push(or merge) to master, Action will:
  * Get latest tag
  * Bump tag with minor version unless any commit message contains `#major` or `#patch`
  * Pushes tag to github

### Credits

[fsaintjacques/semver-tool](https://github.com/fsaintjacques/semver-tool)

### Projects using github-tag-action

A list of projects using github-tag-action for reference.

* another/github-tag-action (uses itself to create tags)

* [anothrNick/json-tree-service](https://github.com/anothrNick/json-tree-service)

  > Access JSON structure with HTTP path parameters as keys/indices to the JSON.
