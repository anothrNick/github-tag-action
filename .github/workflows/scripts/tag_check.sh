#!/bin/bash

set -euo pipefail

MAIN_OUTPUT_TAG=$1
MAIN_OUTPUT_NEWTAG=$2
MAIN_OUTPUT_PART=$3
PRE_OUTPUT_TAG=$4
PRE_OUTPUT_NEWTAG=$5
PRE_OUTPUT_PART=$6

echo "Outputs from running the action:" >>"$GITHUB_STEP_SUMMARY"
echo "MAIN Tag: $MAIN_OUTPUT_TAG" >>"$GITHUB_STEP_SUMMARY"
echo "MAIN New tag: $MAIN_OUTPUT_NEWTAG" >>"$GITHUB_STEP_SUMMARY"
echo "MAIN Part: $MAIN_OUTPUT_PART" >>"$GITHUB_STEP_SUMMARY"
echo "PRE Tag: $PRE_OUTPUT_TAG" >>"$GITHUB_STEP_SUMMARY"
echo "PRE New tag: $PRE_OUTPUT_NEWTAG" >>"$GITHUB_STEP_SUMMARY"
echo "PRE Part: $PRE_OUTPUT_PART" >>"$GITHUB_STEP_SUMMARY"

verlte() {
    [ "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
}
verlt() {
    [ "$1" = "$2" ] && return 1 || verlte "$1" "$2"
}

main="$(verlt "$MAIN_OUTPUT_TAG" "$MAIN_OUTPUT_NEWTAG" && true || false)"
pre="$(verlt "$PRE_OUTPUT_TAG" "$PRE_OUTPUT_NEWTAG" && true || false)"

if $main && $pre; then
    echo "The tags were created correctly" >>"$GITHUB_STEP_SUMMARY"
else
    echo "Tags not created correctly" >>"$GITHUB_STEP_SUMMARY"
    exit 1
fi

# Test for #none bump
if [[ "$MAIN_OUTPUT_PART" == "none" ]]; then
    if [[ "$MAIN_OUTPUT_TAG" == "$MAIN_OUTPUT_NEWTAG" ]]; then
        echo "None bump test passed" >>"$GITHUB_STEP_SUMMARY"
    else
        echo "None bump test failed" >>"$GITHUB_STEP_SUMMARY"
        exit 1
    fi
fi
