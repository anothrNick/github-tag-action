# github-tag-action

A Github Action to automatically bump and tag a github repository, on merge, with the latest semver formatted version.

### Usage

```Dockerfile
name: Bump version
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: Bump version and push tag
      uses: anothrNick/github-tag-action@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Credits

[fsaintjacques/semver-tool](https://github.com/fsaintjacques/semver-tool)
