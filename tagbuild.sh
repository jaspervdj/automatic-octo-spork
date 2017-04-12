#!/bin/bash
set -o errexit -o nounset -o pipefail

# Checking that things are set.
true "$GITHUB_TOKEN"

if [[ "$TRAVIS" == "true" ]]; then
  CI_BUILD="$TRAVIS_BUILD_NUMBER"
  TAG_COMMIT="$TRAVIS_COMMIT"
  GITHUB_SLUG="$TRAVIS_REPO_SLUG"
fi

TAG_NAME="r$RANDOM"
TAG_MESSAGE="hi there"
TAG_DATE="$(date --iso-8601=seconds)"

function errlog() {
  echo "$@" >&2
}

TAG_RESPONSE_FILE="$(mktemp)"

errlog "Creating tag $TAG_NAME..."
curl \
  --silent \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -o "$TAG_RESPONSE_FILE" \
  --data '@-' \
  https://api.github.com/repos/$GITHUB_SLUG/git/tags <<HERE
    {
      "tag": "$TAG_NAME",
      "message": "initial version\n",
      "object": "$TAG_COMMIT",
      "type": "commit",
      "tagger": {
        "name": "Jasper Van der Jeugt",
        "email": "jaspervdj@gmail.com",
        "date": "$TAG_DATE"
      }
    }
HERE

cat "$TAG_RESPONSE_FILE"
TAG_SHA="$(jq -r '.sha' <"$TAG_RESPONSE_FILE")"
rm "$TAG_RESPONSE_FILE"

REF_RESPONSE_FILE="$(mktemp)"

errlog "Creating ref to tag $TAG_SHA..."
curl \
  --silent \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -o "$REF_RESPONSE_FILE" \
  --data '@-' \
  https://api.github.com/repos/$GITHUB_SLUG/git/refs <<HERE
    {
      "ref": "refs/tags/$TAG_NAME",
      "sha": "$TAG_SHA"
    }
HERE

cat "$REF_RESPONSE_FILE"
rm "$REF_RESPONSE_FILE"
