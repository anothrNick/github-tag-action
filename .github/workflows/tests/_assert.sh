#!/usr/bin/env bash

OUTPUT_NEWTAG=$1
CORRECT_TAG=$2

if [[ $OUTPUT_NEWTAG == "${CORRECT_TAG}" ]]; then
    echo "The tag was created correctly" >>"$GITHUB_STEP_SUMMARY"
    rm -rf test-repo
else
    echo "The tag was not created correctly, expected $CORRECT_TAG got $OUTPUT_NEWTAG" >>"$GITHUB_STEP_SUMMARY"
    rm -rf test-repo
    exit 1
fi
