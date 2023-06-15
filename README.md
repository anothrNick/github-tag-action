# github-tag-action

A Github Action to automatically bump and tag master, on merge, with the latest SemVer formatted version.

> **IMPORTANT:** This is a fork of [anothrNick/github-tag-action](https://github.com/anothrNick/github-tag-action), and is branched fo development from tag [1.36.0](https://github.com/anothrNick/github-tag-action/releases/tag/1.36.0) (commit hash [ce4b5ffa38e072fa7a901e417253c438fcc2ccce](https://github.com/anothrNick/github-tag-action/tree/ce4b5ffa38e072fa7a901e417253c438fcc2ccce)).


### Usage

```Dockerfile
name: Bump version
on:
  push:
    branches:
      - master
jobs:
  build:
    runs-on: self-hosted
    steps:
    - uses: actions/checkout@v2
      with:
        fetch-depth: '0'
    - name: Bump version and push tag
      uses: ext-fork-github-tag-action@1.0.0
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        WITH_V: true
```

_NOTE: set the fetch-depth for `actions/checkout@v2` to be sure you retrieve all commits to look for the semver commit message._

#### Options

**Environment Variables**

- **GITHUB_TOKEN** **_(required)_** - Required for permission to tag the repo.
- **DEFAULT_BUMP** _(optional)_ - Which type of bump to use when none explicitly provided (default: `minor`).
- **WITH_V** _(optional)_ - Tag version with `v` character.
- **RELEASE_BRANCHES** _(optional)_ - Comma separated list of branches (bash reg exp accepted) that will generate the release tags. Other branches and pull-requests generate versions postfixed with the commit hash and do not generate any tag. Examples: `master` or `.*` or `release.*,hotfix.*,master` ...
- **CUSTOM_TAG** _(optional)_ - Set a custom tag, useful when generating tag based on f.ex FROM image in a docker image. **Setting this tag will invalidate any other settings set!**
- **SOURCE** _(optional)_ - Operate on a relative path under $GITHUB_WORKSPACE.
- **DRY_RUN** _(optional)_ - Determine the next version without tagging the branch. The workflow can use the outputs `new_tag` and `tag` in subsequent steps. Possible values are `true` and `false` (default).
- **INITIAL_VERSION** _(optional)_ - Set initial version before bump. Default `0.0.0`.
- **TAG_CONTEXT** _(optional)_ - Set the context of the previous tag. Possible values are `repo` (default) or `branch`.
- **PRERELEASE_SUFFIX** _(optional)_ - Suffix for your prerelease versions, `beta` by default. Note this will only be used if a prerelease branch.
- **VERBOSE** _(optional)_ - Print git logs. For some projects these logs may be very large. Possible values are `true` (default) and `false`.

#### Outputs

- **new_tag** - The value of the newly created tag.

- **tag** - The value of the latest tag after running this action.
- **part** - The part of version which was bumped.

> **_Note:_** This action creates a [lightweight tag](https://developer.github.com/v3/git/refs/#create-a-reference).

### Bumping

**Manual Bumping:** Any commit message that includes `#major`, `#minor`, `#patch`, or `#none` will trigger the respective version bump. If two or more are present, the highest-ranking one will take precedence.
If `#none` is contained in the commit message, it will skip bumping regardless `DEFAULT_BUMP`.

**Automatic Bumping:** If no `#major`, `#minor` or `#patch` tag is contained in the commit messages, it will bump whichever `DEFAULT_BUMP` is set to (which is `minor` by default). Disable this by setting `DEFAULT_BUMP` to `none`.

> **_Note:_** This action **will not** bump the tag if the `HEAD` commit has already been tagged.

### Workflow

- Add this action to your repo
- Commit some changes
- Either push to master or open a PR
- On push (or merge), the action will:
  - Get latest tag
  - Bump tag with minor version unless any commit message contains `#major` or `#patch`
  - Pushes tag to github
  - If triggered on your repo's default branch (`master` or `main` if unchanged), the bump version will be a release tag.
  - If triggered on any other branch, a prerelease will be generated, depending on the bump, starting with `*-<PRERELEASE_SUFFIX>.1`, `*-<PRERELEASE_SUFFIX>.2`, ...

### Credits

[fsaintjacques/semver-tool](https://github.com/fsaintjacques/semver-tool)
