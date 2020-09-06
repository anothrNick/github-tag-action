#!/bin/bash

set -o pipefail

# config
default_semvar_bump=${DEFAULT_BUMP:-minor}
with_v=${WITH_V:-false}
release_branches=${RELEASE_BRANCHES:-master}
custom_tag=${CUSTOM_TAG}
source=${SOURCE:-.}
dryrun=${DRY_RUN:-false}
initial_version=${INITIAL_VERSION:-0.0.0}
tag_context=${TAG_CONTEXT:-repo}
suffix=${PRERELEASE_SUFFIX:-beta}

cd ${GITHUB_WORKSPACE}/${source}

current_branch=$(git rev-parse --abbrev-ref HEAD)

pre_release="true"
IFS=',' read -ra branch <<< "$release_branches"
for b in "${branch[@]}"; do
    echo "Is $b a match for ${current_branch}"
    if [[ "${current_branch}" =~ $b ]]
    then
        pre_release="false"
    fi
done
echo "pre_release = $pre_release"

# fetch tags
git fetch --tags

# get latest tag that looks like a semver (with or without v)
case "$tag_context" in
    *repo*) tag=$(git for-each-ref --sort=-v:refname --format '%(refname)' | cut -d / -f 3- | grep -E "^v?[0-9]+.[0-9]+.[0-9]+(-$suffix.[0-9]+)?$" | head -n1);;
    *branch*) tag=$(git tag --list --merged HEAD --sort=-committerdate | grep -E "^v?[0-9]+.[0-9]+.[0-9]+(-$suffix.[0-9]+)?$" | head -n1);;
    * ) echo "Unrecognised context"; exit 1;;
esac

# if there are none, start tags at INITIAL_VERSION which defaults to 0.0.0
if [ -z "$tag" ]
then
    log=$(git log --pretty='%B')
    tag="$initial_version"
else
    log=$(git log $tag..HEAD --pretty='%B')
fi

# get current commit hash for tag
tag_commit=$(git rev-list -n 1 $tag)

# get current commit hash
commit=$(git rev-parse HEAD)

if [ "$tag_commit" == "$commit" ]; then
    echo "No new commits since previous tag. Skipping..."
    echo ::set-output name=tag::$tag
    exit 0
fi

echo $log

if [[ "$tag" == *"$suffix"* ]] && [ $pre_release ]
then
    # there's a pre-release version, bump it
    new=$(semver -i prerelease $tag --preid $suffix); part="prerelease"
else
    # get commit logs and determine home to bump the version
    # supports #major, #minor, #patch (anything else will be 'minor')
    case "$log" in
        *#major* ) new=$(semver -i major $tag); part="major";;
        *#minor* ) new=$(semver -i minor $tag); part="minor";;
        *#patch* ) new=$(semver -i patch $tag); part="patch";;
        * ) 
            if [ "$default_semvar_bump" == "none" ]; then
                echo "Default bump was set to none. Skipping..."; exit 0 
            else 
                new=$(semver -i "${default_semvar_bump}" $tag); part=$default_semvar_bump 
            fi 
            ;;
    esac

    # if pre-release, add suffix
    if [ $pre_release ]
    then
        new="$new.$suffix-1"; part="prerelease"
    fi
fi

echo $part

# did we get a new tag?
if [ ! -z "$new" ]
then
	# prefix with 'v'
	if $with_v
	then
		new="v$new"
	fi
fi

if [ ! -z $custom_tag ]
then
    new="$custom_tag"
fi

echo $new

# set outputs
echo ::set-output name=new_tag::$new
echo ::set-output name=part::$part

# use dry run to determine the next tag
if $dryrun
then
    echo ::set-output name=tag::$tag
    exit 0
fi 

echo ::set-output name=tag::$new

# create local git tag
git tag $new

# push new tag ref to github
dt=$(date '+%Y-%m-%dT%H:%M:%SZ')
full_name=$GITHUB_REPOSITORY
git_refs_url=$(jq .repository.git_refs_url $GITHUB_EVENT_PATH | tr -d '"' | sed 's/{\/sha}//g')

echo "$dt: **pushing tag $new to repo $full_name"

git_refs_response=$(
curl -s -X POST $git_refs_url \
-H "Authorization: token $GITHUB_TOKEN" \
-d @- << EOF

{
  "ref": "refs/tags/$new",
  "sha": "$commit"
}
EOF
)

git_ref_posted=$( echo "${git_refs_response}" | jq .ref | tr -d '"' )

echo "::debug::${git_refs_response}"
if [ "${git_ref_posted}" = "refs/tags/${new}" ]; then
  exit 0
else
  echo "::error::Tag was not created properly."
  exit 1
fi
