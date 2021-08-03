#!/bin/bash

set -o pipefail

# config
default_semvar_bump=${DEFAULT_BUMP:-minor}
with_v=${WITH_V}
prefix=${PREFIX}
release_branches=${RELEASE_BRANCHES:-master,main}
custom_tag=${CUSTOM_TAG}
source=${SOURCE:-.}
dryrun=${DRY_RUN:-false}
initial_version=${INITIAL_VERSION:-0.0.0}
tag_context=${TAG_CONTEXT:-repo}
suffix=${PRERELEASE_SUFFIX:-beta}
verbose=${VERBOSE:-true}
head_commit=$HEAD_COMMIT
use_last_commit_only=${USE_LAST_COMMIT_ONLY:-true}

cd ${GITHUB_WORKSPACE}/${source}

echo "*** CONFIGURATION ***"
echo -e "\tDEFAULT_BUMP: ${default_semvar_bump}"
echo -e "\tWITH_V: ${with_v}"
echo -e "\tPREFIX: ${prefix}"
echo -e "\tRELEASE_BRANCHES: ${release_branches}"
echo -e "\tCUSTOM_TAG: ${custom_tag}"
echo -e "\tSOURCE: ${source}"
echo -e "\tDRY_RUN: ${dryrun}"
echo -e "\tINITIAL_VERSION: ${initial_version}"
echo -e "\tTAG_CONTEXT: ${tag_context}"
echo -e "\tPRERELEASE_SUFFIX: ${suffix}"
echo -e "\tVERBOSE: ${verbose}"
echo -e "\tHEAD_COMMIT: ${head_commit}"
echo -e "\tUSE_LAST_COMMIT_ONLY: ${use_last_commit_only}"
echo -e "*********************\n"

# Handle deprecated WITH_V parameter
if [ ! -z "$with_v" ];
then
    echo -e "WARNING: WITH_V parameter field has been deprecated. Use PREFIX instead."
	if [ ! -z "$prefix" ];
	then
		echo -e "WARNING: Both WITH_V and PREFIX parameters have been set. Value of WITH_V will be ignored"
    else 
        if $with_v; 
        then
            echo -e "WITH_V is set to true and PREFIX parameter have not been set. PREFIX will be set to 'v'"
            prefix="v"
        fi
	fi
fi

current_branch=$(git rev-parse --abbrev-ref HEAD)

pre_release="true"
IFS=',' read -ra branch <<< "$release_branches"
for b in "${branch[@]}"; do
    echo -e "\n\nIs $b a match for ${current_branch}"
    if [[ "${current_branch}" =~ $b ]];
    then
        pre_release="false"
    fi
done
echo "pre_release = $pre_release"

# fetch tags
git fetch --tags

# get latest tag that looks like a semver (with or without prefix)
case "$tag_context" in
    *repo*) 
        tag=$(git for-each-ref --sort=-v:refname --format '%(refname:lstrip=2)' | grep -E "^v?[0-9]+\.[0-9]+\.[0-9]+$" | head -n1)
        pre_tag=$(git for-each-ref --sort=-v:refname --format '%(refname:lstrip=2)' | grep -E "^v?[0-9]+\.[0-9]+\.[0-9]+(-$suffix\.[0-9]+)?$" | head -n1)
        ;;
    *branch*) 
        tag=$(git tag --list --merged HEAD --sort=-v:refname | grep -E "^v?[0-9]+\.[0-9]+\.[0-9]+$" | head -n1)
        pre_tag=$(git tag --list --merged HEAD --sort=-v:refname | grep -E "^v?[0-9]+\.[0-9]+\.[0-9]+(-$suffix\.[0-9]+)?$" | head -n1)
        ;;
    * ) echo "Unrecognised context"; exit 1;;
esac

echo_previous_tags() {
    if $verbose;
    then
        echo -e "\n******************************************"
        echo -e $1
        echo -e "tag: ${tag}"
        echo -e "pre_tag: ${pre_tag}"
        echo -e "********************************************\n"
    fi
}

# if there are none, start tags at INITIAL_VERSION which defaults to 0.0.0
if [ -z "$tag" ];
then
    log=$(git log --pretty='%B')
    tag="$initial_version"
    pre_tag="$initial_version"
    echo_previous_tags "No tag was found. INITIAL_VERSION will be used instead."
else
    echo_previous_tags "Previous tag was found."
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

# calculate new tag

    # Get number of occurrences of bump key words in 
    # all commits between the "head_commit" and the last tag
    # or in all commits of a current branch if the are no tags with
    # a given prefix in the repository

if [ -z $head_commit ]; then
    head_commit=$commit
fi

if $verbose;
then
    echo -e "\n******************************************"
    echo -e "current branch: ${current_branch}"
    echo -e "commit for last found tag: ${tag_commit}"
    echo -e "current commit: ${commit}"
    echo -e "HEAD_COMMIT: ${head_commit}"
    echo -e "********************************************\n"
fi

set_number_of_found_keywords() {
   if $verbose;
   then
      echo -e "\n********************************************"
      echo -e "Commit messages taken into account"
      if $3;
      then
        echo "First commit: $2"
        git log $2 --pretty=format:%B | awk 'NF'
      else
        git log $head_commit...$tag --pretty=format:%B | awk 'NF'
      fi
      echo -e "********************************************\n"
   fi

    number_of_major=$(git log $1...$2 --pretty=format:%B | grep -E "#major" -c)
    number_of_minor=$(git log $1...$2 --pretty=format:%B | grep -E "#minor" -c)
    number_of_patch=$(git log $1...$2 --pretty=format:%B | grep -E "#patch" -c)
    number_of_commits=$(git log $1...$2 --pretty=format:%B | awk 'NF' | grep "" -c)   

    if $verbose;
    then
        echo -e "\n********************************************"
        echo "number of #major tag occurrences ${number_of_major}"
        echo "number of #minor tag occurrences ${number_of_minor}"
        echo "number of #patch tag occurrences ${number_of_patch}"
        echo "number of commits taken into account ${number_of_commits}"
        echo -e "********************************************\n"
    fi
}

if [ $tag = $initial_version ]; then
   first_commit_of_repo=$(git rev-list --max-parents=0 HEAD)
   is_first_commit_used=true
   set_number_of_found_keywords $head_commit $first_commit_of_repo $is_first_commit_used
else 
   is_first_commit_used=false
   set_number_of_found_keywords $head_commit $tag $is_first_commit_used
fi

tagWithoutPrefix=${tag#"$prefix"}
case "$log" in
    *#major* ) new=$(semver -i major $tag); part="major";;
    *#minor* ) new=$(semver -i minor $tag); part="minor";;
    *#patch* ) new=$(semver -i patch $tag); part="patch";;
    *#none* ) 
        echo "Default bump was set to none. Skipping..."; echo ::set-output name=new_tag::$tag; echo ::set-output name=tag::$tag; exit 0;;
    * ) 
        if [ "$default_semvar_bump" == "none" ]; then
            echo "Default bump was set to none. Skipping..."; echo ::set-output name=new_tag::$tag; echo ::set-output name=tag::$tag; exit 0 
        else 
            new=$(semver -i "${default_semvar_bump}" $tagWithoutPrefix); part=$default_semvar_bump 
        fi 
        ;;
esac

if $pre_release;
then
    # Already a prerelease available, bump it
    if [[ "$pre_tag" == *"$new"* ]]; then
        new=$(semver -i prerelease $pre_tag --preid $suffix); part="pre-$part"
    else
        new="$new-$suffix.1"; part="pre-$part"
    fi
fi

# did we get a new tag?
if [ ! -z "$new" ];
then
	# prefix with 'prefix'
	if [ ! -z "$prefix" ]
	then
		new="$prefix$new"
	fi
fi

# set a new tag to a provided CUSTOM_TAG - discard calculated tag
if [ ! -z $custom_tag ];
then
    new="$custom_tag"
fi

if $pre_release;
then
    echo -e "\nBumping tag\n\told tag: ${pre_tag}\n\tnew tag: ${new}"
else
    echo -e "\nBumping tag\n\told tag: ${tag}\n\tnew tag: ${new}"
fi

# set outputs
echo -e "\nSetting outputs"

new_tag_without_prefix=${new#"$prefix"}
echo -e "\tNew tag without prefix: $new_tag_without_prefix"
echo -e "\tNew tag: $new"
echo -e "\tPrefix: $prefix"
echo -e "\tPart incremented: $part\n\n"

echo ::set-output name=new_tag::$new
echo ::set-output name=new_tag_without_prefix::$new_tag_without_prefix
echo ::set-output name=part::$part

# set the old tag value as an output
echo ::set-output name=tag::$tag


# use dry run to determine the next tag
if $dryrun;
then
    exit 0
fi 


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
