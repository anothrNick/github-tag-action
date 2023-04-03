#!/bin/bash

set -o pipefail

# Configurations
default_semver_bump=${DEFAULT_BUMP:-minor}
default_branch=${DEFAULT_BRANCH:-$GITHUB_BASE_REF}
with_v=${WITH_V:-false}
release_branches=${RELEASE_BRANCHES:-master,main}
custom_tag=${CUSTOM_TAG:-}
source_dir=${SOURCE:-.}
dryrun=${DRY_RUN:-false}
initial_version=${INITIAL_VERSION:-0.0.0}
tag_context=${TAG_CONTEXT:-repo}
prerelease=${PRERELEASE:-false}
prerelease_suffix=${PRERELEASE_SUFFIX:-beta}
verbose=${VERBOSE:-false}
major_string_token=${MAJOR_STRING_TOKEN:-#major}
minor_string_token=${MINOR_STRING_TOKEN:-#minor}
patch_string_token=${PATCH_STRING_TOKEN:-#patch}
none_string_token=${NONE_STRING_TOKEN:-#none}
branch_history=${BRANCH_HISTORY:-compare}
git config --global --add safe.directory /github/workspace

cd "${GITHUB_WORKSPACE}/${source_dir}" || exit 1

# Display configurations
echo "*** CONFIGURATION ***"
config_vars=(
    "DEFAULT_BUMP" "DEFAULT_BRANCH" "WITH_V" "RELEASE_BRANCHES"
    "CUSTOM_TAG" "SOURCE" "DRY_RUN" "INITIAL_VERSION" "TAG_CONTEXT"
    "PRERELEASE" "PRERELEASE_SUFFIX" "VERBOSE" "MAJOR_STRING_TOKEN"
    "MINOR_STRING_TOKEN" "PATCH_STRING_TOKEN" "NONE_STRING_TOKEN"
    "BRANCH_HISTORY"
)
for var in "${config_vars[@]}"; do
    echo -e "\t${var}: ${!var}"
done

if $verbose; then
    set -x
fi

setOutput() {
    echo "${1}=${2}" >>"${GITHUB_OUTPUT}"
}

current_branch=$(git rev-parse --abbrev-ref HEAD)

# Determine if pre-release
pre_release="$prerelease"
IFS=',' read -ra branches <<<"$release_branches"
for branch in "${branches[@]}"; do
    if [[ $current_branch == "$branch" ]] || [[ $current_branch =~ $branch ]]; then
        pre_release="false"
    fi
done
echo "pre_release = $pre_release"

# Fetch tags
git fetch --tags

tag_fmt="^v?[0-9]+\.[0-9]+\.[0-9]+$"
pre_tag_fmt="^v?[0-9]+\.[0-9]+\.[0-9]+(-$prerelease_suffix\.[0-9]+)$"

# Get latest tags
get_latest_tag() {
    local pattern=$1
    local latest_tag

    if [ -z "$pattern" ]; then
        echo "Error: No pattern provided."
        exit 1
    fi

    case "$tag_context" in
    *repo*)
        latest_tag=$(git for-each-ref --sort=-v:refname --format '%(refname:lstrip=2)' 2>/dev/null | grep -E "$pattern" | head -n 1)
        ;;
    *branch*)
        latest_tag=$(git tag --list --merged HEAD --sort=-v:refname 2>/dev/null | grep -E "$pattern" | head -n 1)
        ;;
    *)
        echo "Error: Unrecognised context."
        exit 1
        ;;
    esac

    if [ -z "$latest_tag" ]; then
        echo "Error: No matching tags found."
        exit 1
    else
        echo "$latest_tag"
    fi
}


tag=$(get_latest_tag "$tag_fmt")
pre_tag=$(get_latest_tag "$pre_tag_fmt")

# Set initial tag if no tags found
if [ -z "$tag" ]; then
    tag=$([[ $with_v ]] && echo "v$initial_version" || echo "$initial_version")
    if [ -z "$pre_tag" ] && $pre_release; then
        pre_tag=$tag
    fi
fi

# Check for new commits
tag_commit=$(git rev-list -n 1 "$tag")
commit=$(git rev-parse HEAD)

if [ "$tag_commit" == "$commit" ]; then
    echo "No new commits since previous tag. Skipping..."
    setOutput "new_tag" "$tag"
    setOutput "tag" "$tag"
    exit 0
fi

# Set default branch if necessary
if [ -z "${default_branch}" ] && [ "$branch_history" == "full" ]; then
    default_branch=$(git branch -rl '*/master' '*/main' | cut -d / -f2)
    if [ -z "${default_branch}" ]; then
        echo "::error::DEFAULT_BRANCH must not be null, something has gone wrong."
        exit 1
    fi
fi

# Get commit messages for history
declare -A history_type=(
    ["last"]="$(git show -s --format=%B)"
    ["full"]="$(git log "${default_branch}"..HEAD --format=%B)"
    ["compare"]="$(git log "${tag_commit}".."${commit}" --format=%B)"
)
log=${history_type[${branch_history}]}

printf "History:\n---\n%s\n---\n" "$log"

# Determine semver bump
determine_bump() {
    local bump_type

    case "$log" in
    *$major_string_token*)
        bump_type="major"
        ;;
    *$minor_string_token*)
        bump_type="minor"
        ;;
    *$patch_string_token*)
        bump_type="patch"
        ;;
    *$none_string_token*)
        return 1
        ;;
    *)
        if [ "$default_semver_bump" == "none" ]; then
            return 1
        else
            bump_type="${default_semver_bump}"
        fi
        ;;
    esac

    semver -i "${bump_type}" "$tag"
}


new_tag=$(determine_bump)
if [ $? -eq 1 ]; then
    echo "Default bump was set to none. Skipping..."
    setOutput "new_tag" "$tag"
    setOutput "tag" "$tag"
    exit 0
fi

if $pre_release; then
    if [[ $pre_tag =~ $new_tag ]] && [[ $pre_tag =~ $prerelease_suffix ]]; then
        new_tag=$([[ $with_v ]] && echo "v$(semver -i prerelease "${pre_tag}" --preid "${prerelease_suffix}")" || echo "$(semver -i prerelease "${pre_tag}" --preid "${prerelease_suffix}")")
        echo -e "Bumping ${prerelease_suffix} pre-tag ${pre_tag}. New pre-tag ${new_tag}"
    else
        new_tag=$([[ $with_v ]] && echo "v$new_tag-$prerelease_suffix.0" || echo "$new_tag-$prerelease_suffix.0")
        echo -e "Setting ${prerelease_suffix} pre-tag ${pre_tag} - With pre-tag ${new_tag}"
    fi
else
    new_tag=$([[ $with_v ]] && echo "v$new_tag" || echo "$new_tag")
    echo -e "Bumping tag ${tag} - New tag ${new_tag}"
fi

if [ -n "$custom_tag" ]; then
    new_tag="$custom_tag"
fi

# Set outputs
setOutput "new_tag" "$new_tag"
setOutput "tag" "$new_tag"
setOutput "old_tag" "$tag"

if $dryrun; then
    exit 0
fi

# Create and push new tag
git tag "$new_tag"
dt=$(date '+%Y-%m-%dT%H:%M:%SZ')
full_name=$GITHUB_REPOSITORY
git_refs_url=$(jq .repository.git_refs_url "$GITHUB_EVENT_PATH" | tr -d '"' | sed 's/{/sha}//g')

echo "$dt: **pushing tag $new_tag to repo $full_name"

git_refs_response=$(
curl -s -X POST "$git_refs_url"
-H "Authorization: token $GITHUB_TOKEN"
-d @- <<EOF
{
"ref": "refs/tags/$new_tag",
"sha": "$commit"
}
EOF
)

git_ref_posted=$(echo "${git_refs_response}" | jq .ref | tr -d '"')

echo "::debug::${git_refs_response}"
if [ "${git_ref_posted}" = "refs/tags/${new_tag}" ]; then
exit 0
else
echo "::error::Tag was not created properly."
exit 1
fi
