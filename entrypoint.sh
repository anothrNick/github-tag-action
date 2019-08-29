#!/bin/bash

# get latest tag
t=$(git describe --tags `git rev-list --tags --max-count=1`)

# get current commit hash for tag
commit=$(git rev-parse HEAD)

# if there are none, start tags at 0.0.0
if [ -z "$t" ]
then
    log=$(git log --pretty=oneline)
    t=0.0.0
else
    log=$(git log $t..HEAD --pretty=oneline)
fi

# get commit logs and determine home to bump the version
# supports #major, #minor, #patch (anything else will be 'minor')
case "$log" in
    *#major* ) new=$(./contrib/semver bump major $t);;
    *#patch* ) new=$(./contrib/semver bump patch $t);;
    * ) new=$(./contrib/semver bump minor $t);;
esac

echo $new
echo $GITHUB_TOKEN

dt=$(date '+%Y-%m-%dT%H:%M:%SZ')
repo=$(basename -s .git `git config --get remote.origin.url`)

echo "pushing tag $new to repo $REPO_OWNER/$repo"

curl -0 -v -X POST https://api.github.com/repos/$REPO_OWNER/$repo/git/tags \
-H "Authorization: token $ACCESS_TOKEN" \
-d @- << EOF

{
  "tag": "$new",
  "message": "Bump version to $new",
  "object": "$commit",
  "type": "commit",
  "tagger": {
    "name": "anothrNick/github-tag-action",
    "date": "$dt"
  }
}
EOF
