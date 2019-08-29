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

Be sure to set the *REPO_OWNER* environment variable so that your tag your repo.

### Credits

[fsaintjacques/semver-tool](https://github.com/fsaintjacques/semver-tool)
