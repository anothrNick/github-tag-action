#!/bin/bash

# shellcheck disable=SC2153,2164,2129

set -o pipefail

# config
default_semvar_bump=${DEFAULT_BUMP:-minor}
default_branch=${DEFAULT_BRANCH:-$GITHUB_BASE_REF} # get the default branch from github runner env vars
with_v=${WITH_V}
prefix=${PREFIX:-}
release_branches=${RELEASE_BRANCHES:-master,main}
custom_tag=${CUSTOM_TAG:-}
source=${SOURCE:-.}
dryrun=${DRY_RUN:-false}
initial_version=${INITIAL_VERSION:-0.0.0}
tag_context=${TAG_CONTEXT:-repo}
prerelease=${PRERELEASE:-false}
suffix=${PRERELEASE_SUFFIX:-beta}
verbose=${VERBOSE:-true}
branch_latest_commit=${BRANCH_LATEST_COMMIT}
use_last_commit_only=${USE_LAST_COMMIT_ONLY:-true}
major_string_token=${MAJOR_STRING_TOKEN:-#major}
minor_string_token=${MINOR_STRING_TOKEN:-#minor}
patch_string_token=${PATCH_STRING_TOKEN:-#patch}
none_string_token=${NONE_STRING_TOKEN:-#none}
branch_history=${BRANCH_HISTORY:-compare}
# since https://github.blog/2022-04-12-git-security-vulnerability-announced/ runner uses?
git config --global --add safe.directory /github/workspace

cd "${GITHUB_WORKSPACE}/${source}" || exit 1

echo "*** CONFIGURATION ***"
echo -e "\tDEFAULT_BUMP: ${default_semvar_bump}"
echo -e "\tDEFAULT_BRANCH: ${default_branch}"
echo -e "\tWITH_V: ${with_v}"
echo -e "\tPREFIX: ${prefix}"
echo -e "\tRELEASE_BRANCHES: ${release_branches}"
echo -e "\tCUSTOM_TAG: ${custom_tag}"
echo -e "\tSOURCE: ${source}"
echo -e "\tDRY_RUN: ${dryrun}"
echo -e "\tINITIAL_VERSION: ${initial_version}"
echo -e "\tTAG_CONTEXT: ${tag_context}"
echo -e "\tPRERELEASE: ${prerelease}"
echo -e "\tPRERELEASE_SUFFIX: ${suffix}"
echo -e "\tVERBOSE: ${verbose}"
echo -e "\tBRANCH_LATEST_COMMIT: ${branch_latest_commit}"
echo -e "\tUSE_LAST_COMMIT_ONLY: ${use_last_commit_only}"
echo -e "\tMAJOR_STRING_TOKEN: ${major_string_token}"
echo -e "\tMINOR_STRING_TOKEN: ${minor_string_token}"
echo -e "\tPATCH_STRING_TOKEN: ${patch_string_token}"
echo -e "\tNONE_STRING_TOKEN: ${none_string_token}"
echo -e "\tBRANCH_HISTORY: ${branch_history}"

# verbose, show everything
if $verbose
then
    set -x
fi

push_new_tag_if_not_dry_run() {

    # use dry run to determine the next tag
    if $dryrun; then
        echo "!!!! DRY_RUN set to true, tag will not be updated !!!!"
        exit 0
    fi

    git tag "$1"
    # push new tag ref to github
    dt=$(date '+%Y-%m-%dT%H:%M:%SZ')
    full_name=$GITHUB_REPOSITORY
    git_refs_url=$(jq .repository.git_refs_url "$GITHUB_EVENT_PATH" | tr -d '"' | sed 's/{\/sha}//g')

    echo "$dt: **pushing tag $1 to repo $full_name"

    git_refs_response=$(
        curl -s -X POST "$git_refs_url" \
            -H "Authorization: token $GITHUB_TOKEN" \
            -d @- <<EOF

{
  "ref": "refs/tags/$1",
  "sha": "$commit"
}
EOF
    )

    git_ref_posted=$(echo "${git_refs_response}" | jq .ref | tr -d '"')

    echo "::debug::${git_refs_response}"
    if [ "${git_ref_posted}" = "refs/tags/$1" ]; then
        exit 0
    else
        echo "::error::Tag was not created properly."
        exit 1
    fi
}

echo_previous_tags() {
    if $verbose; then
        echo -e "\n******************************************"
        echo -e "$1"
        echo -e "latest_tag: ${tag}"
        echo -e "pre_tag: ${pre_tag}"
        echo -e "********************************************\n"
    fi
}

set_number_of_found_keywords() {

    if [[ "${1}" == "${2}" ]]; then # handle the case of a repo with a single commit
        commit_messages_taken_into_account=$(git log "$1"..."$2" --pretty=format:%B | awk 'NF')
        number_of_major=$(git log "$1"..."$2" --pretty=format:%B | grep -E "${major_string_token}" -c)
        number_of_minor=$(git log "$1"..."$2" --pretty=format:%B | grep -E "${minor_string_token}" -c)
        number_of_patch=$(git log "$1"..."$2" --pretty=format:%B | grep -E "${patch_string_token}" -c)
        number_of_commits=$(git log "$1"..."$2" --pretty=format:%B | awk 'NF' | grep "" -c)
    else
        commit_messages_taken_into_account=$(git log "$1"..."$2"~1 --pretty=format:%B | awk 'NF')
        number_of_major=$(git log "$1"..."$2"~1 --pretty=format:%B | grep -E "${major_string_token}" -c)
        number_of_minor=$(git log "$1"..."$2"~1 --pretty=format:%B | grep -E "${minor_string_token}" -c)
        number_of_patch=$(git log "$1"..."$2"~1 --pretty=format:%B | grep -E "${patch_string_token}" -c)
        number_of_commits=$(git log "$1"..."$2"~1 --pretty=format:%B | awk 'NF' | grep "" -c)
    fi

    if $verbose; then
        echo -e "\n********************************************"
        echo -e "Commit messages taken into account:\n"
        echo "${commit_messages_taken_into_account}"
        echo -e "\n"
        echo "number of major_string_token tag occurrences ${number_of_major}"
        echo "number of minor_string_token tag occurrences ${number_of_minor}"
        echo "number of patch_string_token tag occurrences ${number_of_patch}"
        echo "number of commits taken into account ${number_of_commits}"
        echo -e "********************************************\n"
    fi
}

bump_version() {
    new=$tagWithoutPrefix

    eval count_var_name=number_of_"$1"
    # shellcheck disable=SC2154
    count="${!count_var_name}"

    if $use_last_commit_only; then
        echo -e "USE_LAST_COMMIT_ONLY set to: '${use_last_commit_only}'. $1 will be incremented only by 1"
        eval number_of_"$1"=1
        count=1
    else
        echo -e "USE_LAST_COMMIT_ONLY set to: '${use_last_commit_only}'. $1 will be incremented by ${count}"
    fi

    for ((c = 1; c <= count; c++)); do
        new=$(semver -i "$1" "$new")
        part=$1
    done
}

setOutput() {
    echo "${1}=${2}" >> "${GITHUB_OUTPUT}"
}

current_branch=$(git rev-parse --abbrev-ref HEAD)

pre_release="$prerelease"
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

tagFmt="^$prefix?[0-9]+\.[0-9]+\.[0-9]+$"
preTagFmt="^$prefix?[0-9]+\.[0-9]+\.[0-9]+(-$suffix\.[0-9]+)$"

# get latest tag that looks like a semver (with or without prefix)
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

# as defined in readme if CUSTOM_TAG is used any semver calculations are irrelevant.
if [ -n "$custom_tag" ]; then
    echo "!!! Custom tag has been provided, so it'll be used instead of a calculated tag !!!"

    # set outputs
    echo -e "\nSetting outputs"

    newCustomTag="$prefix$custom_tag"
    newCustomTagWithoutPrefix="$custom_tag"

    echo -e "\tNew tag without prefix: $newCustomTagWithoutPrefix"
    echo -e "\tNew tag: $newCustomTag"
    echo -e "\tPrefix: $prefix"
    echo -e "\tPart incremented: [none - custom tag was created]\n\n"

    setOutput new_tag_without_prefix "$newCustomTagWithoutPrefix"
    setOutput new_tag "$newCustomTag"

    # set the old tag value as an output
    setOutput tag "$tag"

    push_new_tag_if_not_dry_run "$newCustomTag"
fi

# Handle deprecated WITH_V parameter
if [ -n "$with_v" ]; then
    echo -e "WARNING: WITH_V parameter field has been deprecated. Use PREFIX instead."
    if [ -n "$prefix" ]; then
        echo -e "WARNING: Both WITH_V and PREFIX parameters have been set. Value of WITH_V will be ignored"
    else
        if $with_v; then
            echo -e "WITH_V is set to true and PREFIX parameter have not been set. PREFIX will be set to 'v'"
            prefix="v"
        fi
    fi
fi

# if there are none, start tags at INITIAL_VERSION
if [ -z "$tag" ]; then
    echo_previous_tags "No tag was found. INITIAL_VERSION will be used instead."

    semver_pattern_with_prefix="^${prefix}[0-9]+\.[0-9]+\.[0-9]+$"
    if [[ $initial_version =~ $semver_pattern_with_prefix ]]; then
        initial_version=${initial_version#"$prefix"}
    fi

    semver_pattern="^[0-9]+\.[0-9]+\.[0-9]+$"
    if ! [[ $initial_version =~ $semver_pattern ]]; then
        echo "::error::Provided INITIAL_VERSION has incorrect format"
        exit 1
    fi

    tag="$initial_version"
    echo "tag to be created: $tag"
    echo "tag to be created, pre_release: $pre_release"
    echo "tag to be created, pre_tag: $pre_tag"
    if [ -z "$pre_tag" ] && $pre_release; then
        pre_tag="${prefix}$initial_version"
    fi
else
    echo_previous_tags "Previous tag was found."
fi

# get current commit hash for tag

if [ "$tag" = "$initial_version" ] || [ "$tag" = "${prefix}${initial_version}" ]; then
    first_commit_of_repo=$(git rev-list --max-parents=0 HEAD)
    tag_commit=first_commit_of_repo
else
    tag_commit=$(git rev-list -n 1 "$tag")
fi

# get current commit hash
commit=$(git rev-parse HEAD)

if [ "$tag_commit" == "$commit" ]; then
    echo "No new commits since previous tag. Skipping..."
    setOutput "new_tag" "$tag"
    setOutput "tag" "$tag"
    exit 0
fi

# sanitize that the default_branch is set (via env var when running on PRs) else find it natively
if [ -z "${default_branch}" ] && [ "$branch_history" == "full" ]
then
    echo "The DEFAULT_BRANCH should be autodetected when tag-action runs on on PRs else must be defined, See: https://github.com/anothrNick/github-tag-action/pull/230, since is not defined we find it natively"
    default_branch=$(git branch -rl '*/master' '*/main' | cut -d / -f2)
    echo "default_branch=${default_branch}"
    # re check this
    if [ -z "${default_branch}" ]
    then
        echo "::error::DEFAULT_BRANCH must not be null, something has gone wrong."
        exit 1
    fi
fi

# calculate new tag

# Get number of occurrences of bump key words in
# all commits between the "branch_latest_commit" and the last tag
# or in all commits of a current branch if the are no tags with
# a given prefix in the repository

if $verbose; then
    echo -e "\n******************************************"
    echo -e "current branch: ${current_branch}"
    echo -e "commit for last found tag: ${tag_commit}"
    echo -e "current commit: ${commit}"
    echo -e "branch_latest_commit: ${branch_latest_commit}"
    echo -e "********************************************\n"
fi

if [ "$tag" = "$initial_version" ] || [ "$tag" = "${prefix}${initial_version}" ]; then #TODO: Comment each branch
    first_commit_of_repo=$(git rev-list --max-parents=0 HEAD)

    if [ -z "$branch_latest_commit" ]; then
        set_number_of_found_keywords "$first_commit_of_repo" "$commit"
    else
        set_number_of_found_keywords "$branch_latest_commit" "$first_commit_of_repo"
    fi
else

    if [ -z "$branch_latest_commit" ]; then
        next_commit_after_current_tag=$(git log --pretty=format:"%H" --reverse --ancestry-path "$tag".."$commit" | sed -n 1p)
        if $verbose; then
            echo "next commit after current tag commit ${next_commit_after_current_tag}"
        fi
        set_number_of_found_keywords "$commit" "$next_commit_after_current_tag"
    else
        base_branch_commit_on_parent_branch=$(diff -u <(git rev-list --first-parent "$branch_latest_commit") <(git rev-list --first-parent "$commit") | sed -ne 's/^ //p' | head -1)
        first_separate_commit_on_branch=$(git log --pretty=format:"%H" --reverse --ancestry-path "$base_branch_commit_on_parent_branch".."$branch_latest_commit" | sed -n 1p)

        if $verbose; then
            echo -e "\n********************************************"
            echo "base branch commit on parent branch ${base_branch_commit_on_parent_branch}"
            echo "first separate commit on branch ${first_separate_commit_on_branch}"
            echo -e "********************************************\n"
        fi
        set_number_of_found_keywords "$branch_latest_commit" "$first_separate_commit_on_branch"
    fi
fi

# get the merge commit message looking for #bumps
declare -A history_type=( 
    ["last"]="$(git show -s --format=%B)" \
    ["full"]="$(git log "${default_branch}"..HEAD --format=%B)" \
    ["compare"]="$(git log "${tag_commit}".."${commit}" --format=%B)" \
)
log=${history_type[${branch_history}]}
printf "History:\n---\n%s\n---\n" "$log"

tagWithoutPrefix=${tag#"$prefix"}

if [ "$number_of_major" != 0 ]; then
    bump_version "major"
fi

if [ "$number_of_major" == 0 ] && [ "$number_of_minor" != 0 ] && [ -z "$new" ]; then
    bump_version "minor"
fi

if [ "$number_of_major" == 0 ] && [ "$number_of_minor" == 0 ] && [ "$number_of_patch" != 0 ] && [ -z "$new" ]; then
    bump_version "patch"
fi

if [ -z "$new" ]; then
    if [ "$default_semvar_bump" == "${none_string_token}" ]; then
        echo "Default bump was set to none. Skipping..."
    else
        new=$tagWithoutPrefix
        if [ "$tag" = "$initial_version" ] || [ "$tag" = "${prefix}${initial_version}" ]; then
            echo "Initial version will be used"
            new=$tag
        elif $use_last_commit_only; then
            echo -e "USE_LAST_COMMIT_ONLY set to: '${use_last_commit_only}'. default_semvar_bump=${default_semvar_bump} will be incremented only by 1"
            new=$(semver -i "${default_semvar_bump}" "$new")
            part=$default_semvar_bump
        else
            echo -e "USE_LAST_COMMIT_ONLY set to: '${use_last_commit_only}'. default_semvar_bump=${default_semvar_bump} will be incremented by ${number_of_commits}"

            for ((c = 1; c <= number_of_commits; c++)); do
                new=$(semver -i "${default_semvar_bump}" "$new")
                part=$default_semvar_bump
            done
        fi
    fi
fi

if $pre_release; then
    # get current commit hash for tag
    pre_tag_commit=$(git rev-list -n 1 "$pre_tag")
    # skip if there are no new commits for pre_release
    if [ "$pre_tag_commit" == "$commit" ]
    then
        echo "No new commits since previous pre_tag. Skipping..."
        setOutput "new_tag" "$pre_tag"
        setOutput "tag" "$pre_tag"
        exit 0
    fi
    # already a pre-release available, bump it
    if [[ "$pre_tag" =~ $new ]] && [[ "$pre_tag" =~ $suffix ]]; then
        if [ -n "${prefix}" ]; then
            new=${prefix}$(semver -i prerelease "${pre_tag}" --preid "${suffix}")
        else
            new=$(semver -i prerelease "${pre_tag}" --preid "${suffix}")
        fi
        echo -e "Bumping ${suffix} pre-tag ${pre_tag}. New pre-tag ${new}"
    else
        if [ -n "${prefix}" ]; then
            new="${prefix}$new-$suffix.0"
        else
            new="$new-$suffix.0"
        fi
        echo -e "Setting ${suffix} pre-tag ${pre_tag} - With pre-tag ${new}"
    fi
    part="pre-$part"
else
    if [ -n "${prefix}" ]; then
        new="${prefix}${new}"
    fi
    echo -e "Bumping tag ${tag} - New tag ${new}"
fi

# as defined in readme if CUSTOM_TAG is used any semver calculations are irrelevant.
if [ -n "$custom_tag" ]
then
    new="$custom_tag"
fi

# set outputs
echo -e "\nSetting outputs"

new_tag_without_prefix=${new#"$prefix"}
echo -e "\tNew tag without prefix: $new_tag_without_prefix"
echo -e "\tNew tag: $new"
echo -e "\tPrefix: $prefix"
echo -e "\tPart incremented: $part\n\n"

setOutput new_tag "$new"
setOutput new_tag_without_prefix "$new_tag_without_prefix"
setOutput part "$part"
setOutput tag "$new" # this needs to go in v2 is breaking change
setOutput old_tag "$tag"

# use dry run to determine the next tag
if $dryrun; then
    setOutput tag "$tag"
    exit 0
fi

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
