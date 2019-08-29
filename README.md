# github-tag-action

A Github Action to automatically bump and tag master, on merge, with the latest semver formatted version.

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

Be sure to set the *REPO_OWNER* environment variable so that the action tags your repo.

*NOTE:* This creates a [lightweight tag](https://developer.github.com/v3/git/refs/#create-a-reference)

### Credits

[fsaintjacques/semver-tool](https://github.com/fsaintjacques/semver-tool)
