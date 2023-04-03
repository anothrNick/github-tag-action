# Code of Conduct - GitHub Tag Action

A GitHub Action to automatically bump and tag the master branch on merge, with the latest SemVer formatted version.

[![Build Status](https://github.com/anothrNick/github-tag-action/workflows/Bump%20version/badge.svg)](https://github.com/anothrNick/github-tag-action/actions) [![Stable Version](https://img.shields.io/github/v/tag/anothrNick/github-tag-action)](https://github.com/anothrNick/github-tag-action/tags) [![Latest Release](https://img.shields.io/github/v/release/anothrNick/github-tag-action?color=%233D9970)](https://github.com/anothrNick/github-tag-action/releases)

> 📖 Blog Post: [Creating A Github Action to Tag Commits](https://itnext.io/creating-a-github-action-to-tag-commits-2722f1560dec)

[<img src="https://miro.medium.com/max/1200/1*_4Ex1uUhL93a3bHyC-TgPg.png" width="400">](https://itnext.io/creating-a-github-action-to-tag-commits-2722f1560dec)

> 📣 [This project is seeking maintainers!](https://github.com/anothrNick/github-tag-action/issues/238) 📣

## 🚀 Usage

_Note: We don't recommend using the @master version unless you're happy to test the latest changes._

### 📝 Example 1: On push to master

```yaml
# example 1: on push to master
name: Bump version
on:
  push:
    branches:
      - master
jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: "0"

      - name: Bump version and push tag
        uses: anothrNick/github-tag-action@1.61.0 # Don't use @master unless you're happy to test the latest version
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          WITH_V: true
```

### 📝 Example 2: On merge to master

```yaml
# example 2: on merge to master
name: Bump version
on:
  pull_request:
    types:
      - closed
    branches:
      - master
jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v3
        with:
          ref: ${{ github.sha }}
          fetch-depth: "0"

      - name: Bump version and push tag
        uses: anothrNick/github-tag-action@1.61.0 # Don't use @master unless you're happy to test the latest version
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          WITH_V: true
```

> 🚨 It is recommended to use the action on `pull_request` instead of on commit to master/main.

_NOTE: Set the fetch-depth for `actions/checkout@v2` or newer to ensure you retrieve all commits for proper semver commit message detection._

## ⚙️ Options

### Environment Variables

- **GITHUB_TOKEN** _(required)_ - Required for permission to tag the repo.
- **DEFAULT_BUMP** _(optional)_ - Which type of bump to use when none explicitly provided (default: `minor`).
- **DEFAULT_BRANCH** _(optional)_ - Overwrite the default branch read from Github Runner env var (default: `$GITHUB_BASE_REF`). Strongly recommended to set this var if using anything other than `master` or `main` as the default branch. Otherwise, in combination with full history, it may cause errors.
- **WITH_V** _(optional)_ - Tag version with `v`character.

- **RELEASE_BRANCHES** _(optional)_ - Comma-separated list of branches (bash regex accepted) that will generate release tags. Other branches and pull-requests generate versions postfixed with the commit hash and do not generate any tag. Examples: `master`, `.*`, or `release.*,hotfix.*,master`...
- **CUSTOM_TAG** _(optional)_ - Set a custom tag, useful when generating tag based on, for example, the `FROM` image in a Docker image. **Setting this tag will invalidate any other settings set!**
- **SOURCE** _(optional)_ - Operate on a relative path under `$GITHUB_WORKSPACE`.
- **DRY_RUN** _(optional)_ - Determine the next version without tagging the branch. The workflow can use the outputs `new_tag` and `tag` in subsequent steps. Possible values are `true` and `false` (default).
- **INITIAL_VERSION** _(optional)_ - Set initial version before bump. Default `0.0.0`.
- **TAG_CONTEXT** _(optional)_ - Set the context of the previous tag. Possible values are `repo` (default) or `branch`.
- **PRERELEASE** _(optional)_ - Define if the workflow runs in prerelease mode, `false` by default. Note this will be overwritten if using complex suffix release branches.
- **PRERELEASE_SUFFIX** _(optional)_ - Suffix for your prerelease versions, `beta` by default. Note this will only be used if a prerelease branch.
- **VERBOSE** _(optional)_ - Print git logs. For some projects, these logs may be very large. Possible values are `true` (default) and `false`.
- **MAJOR_STRING_TOKEN** _(optional)_ - Change the default `#major` commit message string tag.
- **MINOR_STRING_TOKEN** _(optional)_ - Change the default `#minor` commit message string tag.
- **PATCH_STRING_TOKEN** _(optional)_ - Change the default `#patch` commit message string tag.
- **NONE_STRING_TOKEN** _(optional)_ - Change the default `#none` commit message string tag.
- **BRANCH_HISTORY** _(optional)_ - Set the history of the branch for finding `#bumps`. Possible values are `last`, `full`, and `compare`. The default is `compare`.
  - `full`: Attempt to show all history; does not work on rebase and squash due to missing HEAD. [This should be deprecated in v2 as it is breaking many workflows.]
  - `last`: Show the single last commit.
  - `compare`: Show all commits since the previous repo tag number.

### Outputs

- **new_tag** - The value of the newly created tag.
- **tag** - The value of the latest tag after running this action.
- **part** - The part of the version which was bumped.

> **_Note:_** This action creates a [lightweight tag](https://developer.github.com/v3/git/refs/#create-a-reference).

### Bumping

**Manual Bumping:** Any commit message that includes `#major`, `#minor`, `#patch`, or `#none` will trigger the respective version bump. If two or more are present, the highest-ranking one will take precedence. If `#none` is contained in the merge commit message, it will skip bumping regardless of the `DEFAULT_BUMP`.

**Automatic Bumping:** If no `#major`, `#minor`, or `#patch` tag is contained in the merge commit message, it will bump whichever `DEFAULT_BUMP` is set to (which is `minor` by default). Disable this by setting `DEFAULT_BUMP` to `none`.

### Workflow

- Add this action to your repo
- Commit some changes
- Either push to master or open a PR
- On push (or merge), the action will:
  - Get latest tag
  - Bump tag with minor version unless the merge commit message contains `#major` or `#patch`
  - Pushes tag to github
  - If triggered on your repo's default branch (`master` or `main` if unchanged), the bump version will be a release tag.
  - If triggered on any other branch, a prerelease will be generated, depending on the bump, starting with `*-<PRERELEASE_SUFFIX>.1`, `*-<PRERELEASE_SUFFIX>.2`, ...

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Credits

- [fsaintjacques/semver-tool](https://github.com/fsaintjacques/semver-tool)
- [Contributors to this project](https://github.com/anothrNick/github-tag-action/graphs/contributors)

## Projects using github-tag-action

Examples of projects using github-tag-action for reference.

- another/github-tag-action (uses itself to create tags)
- [anothrNick/json-tree-service](https://github.com/anothrNick/json-tree-service)

  > Access JSON structure with HTTP path parameters as keys/indices to the JSON.
