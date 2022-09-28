#!/bin/bash

set -o pipefail

# config
default_semvar_bump=${DEFAULT_BUMP:-minor}
with_v=${WITH_V:-false}
release_branches=${RELEASE_BRANCHES:-master,main}
custom_tag=${CUSTOM_TAG:-}
source=${SOURCE:-.}
dryrun=${DRY_RUN:-false}
initial_version=${INITIAL_VERSION:-0.0.0}
tag_context=${TAG_CONTEXT:-repo}
suffix=${PRERELEASE_SUFFIX:-beta}
verbose=${VERBOSE:-true}
verbose=${VERBOSE:-true}
# since https://github.blog/2022-04-12-git-security-vulnerability-announced/ runner uses?
git config --global --add safe.directory /github/workspace

cd "${GITHUB_WORKSPACE}/${source}" || exit 1

echo "*** CONFIGURATION ***"
echo -e "\tDEFAULT_BUMP: ${default_semvar_bump}"
echo -e "\tWITH_V: ${with_v}"
echo -e "\tRELEASE_BRANCHES: ${release_branches}"
echo -e "\tCUSTOM_TAG: ${custom_tag}"
echo -e "\tSOURCE: ${source}"
echo -e "\tDRY_RUN: ${dryrun}"
echo -e "\tINITIAL_VERSION: ${initial_version}"
echo -e "\tTAG_CONTEXT: ${tag_context}"
echo -e "\tPRERELEASE_SUFFIX: ${suffix}"
echo -e "\tVERBOSE: ${verbose}"

current_branch=$(git rev-parse --abbrev-ref HEAD)

pre_release="true"
IFS=',' read -ra branch <<< "$release_branches"
for b in "${branch[@]}"; do
    # check if ${current_branch} is in ${release_branches} | exact branch match
    if [[ "$current_branch" == "$b" ]]
    then
        pre_release="false"
    fi
    # verify non specific branch names like  .* release/* if wildcard filter then =~
    if [ "$b" != "${b//[\[\]|.? +*]/}" ] && [[ "$current_branch" =~ $b ]]
    then
        pre_release="false"
    fi
done
echo "pre_release = $pre_release"

# fetch tags
git fetch --tags

tagFmt="^v?[0-9]+\.[0-9]+\.[0-9]+$"
preTagFmt="^v?[0-9]+\.[0-9]+\.[0-9]+(-$suffix\.[0-9]+)$"

# get latest tag that looks like a semver (with or without v)
case "$tag_context" in
    *repo*) 
        tag="$(git for-each-ref --sort=-v:refname --format '%(refname:lstrip=2)' | grep -E "$tagFmt" | head -n 1)"
        pre_tag="$(git for-each-ref --sort=-v:refname --format '%(refname:lstrip=2)' | grep -E "$preTagFmt" | head -n 1)"
        ;;
    *branch*) 
        tag="$(git tag --list --merged HEAD --sort=-v:refname | grep -E "$tagFmt" | head -n 1)"
        pre_tag="$(git tag --list --merged HEAD --sort=-v:refname | grep -E "$preTagFmt" | head -n 1)"
        ;;
    * ) echo "Unrecognised context"
        exit 1;;
esac

# if there are none, start tags at INITIAL_VERSION which defaults to 0.0.0
if [ -z "$tag" ]
then
    log=$(git log --pretty='%B' --)
    if $with_v
    then
        tag="v$initial_version"
    else
        tag="$initial_version"
    fi
    if [ -z "$pre_tag" ] && $pre_release
    then
        if $with_v
        then
            pre_tag="v$initial_version"
        else
            pre_tag="$initial_version"
        fi
    fi
else
    log=$(git log "$tag"..HEAD --pretty='%B' --)
fi

# get current commit hash for tag
tag_commit=$(git rev-list -n 1 "$tag")

# get current commit hash
commit=$(git rev-parse HEAD)

if [ "$tag_commit" == "$commit" ]
then
    echo "No new commits since previous tag. Skipping..."
    echo "::set-output name=new_tag::$tag"
    echo "::set-output name=tag::$tag"
    exit 0
fi

# echo log if verbose is wanted
if $verbose
then
  echo "$log"
fi

case "$log" in
    *#major* ) new=$(semver -i major "$tag"); part="major";;
    *#minor* ) new=$(semver -i minor "$tag"); part="minor";;
    *#patch* ) new=$(semver -i patch "$tag"); part="patch";;
    *#none* ) 
        echo "Default bump was set to none. Skipping..."
        echo "::set-output name=new_tag::$tag"
        echo "::set-output name=tag::$tag"
        exit 0;;
    * ) 
        if [ "$default_semvar_bump" == "none" ]
        then
            echo "Default bump was set to none. Skipping..."
            echo "::set-output name=new_tag::$tag"
            echo "::set-output name=tag::$tag"
            exit 0 
        else 
            new=$(semver -i "${default_semvar_bump}" "$tag")
            part=$default_semvar_bump 
        fi 
        ;;
esac

if $pre_release
then
    # Already a prerelease available, bump it
    if [[ "$pre_tag" =~ $new ]] && [[ "$pre_tag" =~ $suffix ]]
    then
        if $with_v
        then
            new=v$(semver -i prerelease "${pre_tag}" --preid "${suffix}")
        else
            new=$(semver -i prerelease "${pre_tag}" --preid "${suffix}")
        fi
        echo -e "Bumping ${suffix} pre-tag ${pre_tag}. New pre-tag ${new}"
    else
        if $with_v
        then
            new="v$new-$suffix.0"
        else
            new="$new-$suffix.0"
        fi
        echo -e "Setting ${suffix} pre-tag ${pre_tag}. With pre-tag ${new}"
    fi
    part="pre-$part"
else
    echo -e "Bumping tag $tag. New tag ${new}"
    if $with_v
    then
        new="v$new"
    fi
fi

# as defined in readme if CUSTOM_TAG is used any semver calculations are irrelevant.
if [ -n "$custom_tag" ]
then
    new="$custom_tag"
fi

# set outputs
echo "::set-output name=new_tag::$new"
echo "::set-output name=part::$part"

# use dry run to determine the next tag
if $dryrun
then
    echo "::set-output name=tag::$tag"
    exit 0
fi 

echo "::set-output name=tag::$new"

# create local git tag
git tag "$new"

# push new tag ref to github
dt=$(date '+%Y-%m-%dT%H:%M:%SZ')
full_name=$GITHUB_REPOSITORY
git_refs_url=$(jq .repository.git_refs_url "$GITHUB_EVENT_PATH" | tr -d '"' | sed 's/{\/sha}//g')

echo "$dt: **pushing tag $new to repo $full_name"

git_refs_response=$(
curl -s -X POST "$git_refs_url" \
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
if [ "${git_ref_posted}" = "refs/tags/${new}" ]
then
  exit 0
else
  echo "::error::Tag was not created properly."
  exit 1
fi
