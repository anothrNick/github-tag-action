# github-tag-action

A Github Action to automatically bump and tag master, on merge, with the latest SemVer formatted version.

[![Build Status](https://github.com/anothrNick/github-tag-action/workflows/Bump%20version/badge.svg)](https://github.com/anothrNick/github-tag-action/workflows/Bump%20version/badge.svg)
[![Stable Version](https://img.shields.io/github/v/tag/anothrNick/github-tag-action)](https://img.shields.io/github/v/tag/anothrNick/github-tag-action)
[![Latest Release](https://img.shields.io/github/v/release/anothrNick/github-tag-action?color=%233D9970)](https://img.shields.io/github/v/release/anothrNick/github-tag-action?color=%233D9970)

> Medium Post: [Creating A Github Action to Tag Commits](https://itnext.io/creating-a-github-action-to-tag-commits-2722f1560dec)

[<img src="https://miro.medium.com/max/1200/1*_4Ex1uUhL93a3bHyC-TgPg.png" width="400">](https://itnext.io/creating-a-github-action-to-tag-commits-2722f1560dec)

> 📣 [This project is seeking maintainers!](https://github.com/anothrNick/github-tag-action/issues/238) 📣

## Usage

_Note: We don't recommend using the @master version unless you're happy to test the latest changes._

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
        fetch-depth: '0'

    - name: Bump version and push tag
      uses: anothrNick/github-tag-action@1.55.0 # Don't use @master unless you're happy to test the latest version
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        PREFIX: myprefix-
```

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
        fetch-depth: '0'

    - name: Bump version and push tag
      uses: anothrNick/github-tag-action@1.55.0 # Don't use @master unless you're happy to test the latest version
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        PREFIX: myprefix-
```

Depending if you choose example 1 or example 2 is how crafted version bumps operate when reading the commit log.

Is recommended to use on `pull_request` instead of on commit to master/main.

_NOTE: set the fetch-depth for `actions/checkout@v2` or newer to be sure you retrieve all commits to look for the semver commit message._

### Options

**Environment Variables**

- **GITHUB_TOKEN** ***(required)*** - Required for permission to tag the repo.
- **DEFAULT_BUMP** *(optional)* - Which type of bump to use when none explicitly provided (default: `minor`).
- **DEFAULT_BRANCH** _(optional)_ - Overwrite the default branch its read from Github Runner env var but can be overwritten (default: `$GITHUB_BASE_REF`). Strongly recommended to set this var if using anything else than master or main as default branch otherwise in combination with history full will error.
- **WITH_V** **(deprecated)** *(optional)* - Tag version with `v` character. Deprecated variable - use `PREFIX` instead.
- **PREFIX** *(optional)* - Adds a prefix before version number.
- **RELEASE_BRANCHES** *(optional)* - Comma separated list of branches (bash reg exp accepted) that will generate the release tags. Other branches and pull-requests generate versions postfixed with the commit hash and do not generate any tag. Examples: `master` or `.*` or `release.*,hotfix.*,master` ...
- **CUSTOM_TAG** *(optional)* - Set a custom tag, useful when generating tag based on f.ex FROM image in a docker image. **Setting this tag will invalidate any other settings set!**
- **SOURCE** *(optional)* - Operate on a relative path under $GITHUB_WORKSPACE.
- **DRY_RUN** *(optional)* - Determine the next version without tagging the branch. The workflow can use the outputs `new_tag` and `tag` in subsequent steps. Possible values are ```true``` and ```false``` (default).
- **INITIAL_VERSION** *(optional)* - Set initial version before bump. Default `0.0.0`. It must be in a valid semver version format (optionally it can also be prefixed with PREFIX param, but it's not necessary even if PREFIX is specified). If the format is incorrect error is thrown.
- **TAG_CONTEXT** *(optional)* - Set the context of the previous tag. Possible values are `repo` (default) or `branch`.
- **PRERELEASE** _(optional)_ - Define if workflow runs in prerelease mode, `false` by default. Note this will be overwritten if using complex suffix release branches.
- **PRERELEASE_SUFFIX** *(optional)* - Suffix for your prerelease versions, `beta` by default. Note this will only be used if a prerelease branch.
- **VERBOSE** *(optional)* - Print git logs. For some projects these logs may be very large. Possible values are ```true``` (default) and ```false```. 
- **BRANCH_LATEST_COMMIT** *(optional)* - Commit messages for commits of a given branch will be taken into account while calculating a new tag. Specifying branch is useful when using this action for pull requests - one can set environment variable as follows: `BRANCH_LATEST_COMMIT: ${{ github.event.pull_request.head.sha }}` to calculate a new version basing on commits from a given PR.  If not specified the current commit is used.
- **USE_LAST_COMMIT_ONLY** *(optional)* - True by default. If true only last commit is taken into account while bumping the version, otherwise all commits from the branch with the latest tag contribute to new tag calculation
- **MAJOR_STRING_TOKEN** _(optional)_ - Change the default `#major` commit message string tag.
- **MINOR_STRING_TOKEN** _(optional)_ - Change the default `#minor` commit message string tag.
- **PATCH_STRING_TOKEN** _(optional)_ - Change the default `#patch` commit message string tag.
- **NONE_STRING_TOKEN** _(optional)_ - Change the default `#none` commit message string tag.
- **BRANCH_HISTORY** _(optional)_ - Set the history of the branch for finding `#bumps`. Possible values `last`, `full` and `compare` defaults to `compare`.
  - `full`: attempt to show all history, does not work on rebase and squash due missing HEAD [should be deprecated in v2 is breaking many workflows]
  - `last`: show the single last commit
  - `compare`: show all commits since previous repo tag number

### Outputs

- **new_tag** - The value of the newly created tag, e.g. my-prefix-1.2.3
- **new_tag_without_prefix** - The value of the newly created tag without specified prefix, e.g 1.2.3
- **tag** - The value of the latest tag before bumping it by running this action, e.g. my-prefix-1.2.2
- **part** - The part of version which was bumped, e.g. minor

> **_Note:_** This action creates a [lightweight tag](https://developer.github.com/v3/git/refs/#create-a-reference).

### Bumping

**Manual Bumping:** Any commit message that includes `#major`, `#minor`, `#patch`, or `#none` will trigger the respective version bump. If two or more are present, the highest-ranking one will take precedence.
If `#none` is contained in the merge commit message, it will skip bumping regardless `DEFAULT_BUMP`.

**Automatic Bumping:** If no `#major`, `#minor` or `#patch` tag is contained in the merge commit message, it will bump whichever `DEFAULT_BUMP` is set to (which is `minor` by default). Disable this by setting `DEFAULT_BUMP` to `none`.

> **_Note:_** This action **will not** bump the tag if the `HEAD` commit has already been tagged.

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
