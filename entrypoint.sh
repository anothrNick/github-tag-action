#!/bin/bash

# get latest tag
t=$(git describe --tags `git rev-list --tags --max-count=1`)

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
echo $TEST_SECRET

# git tag $new
# git push origin $new
