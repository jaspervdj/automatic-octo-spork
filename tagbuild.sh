#!/bin/bash
set -o errexit -o nounset -o pipefail

# Checking that things are set.
true "$GITHUB_TOKEN"

if [[ "$TRAVIS" == "true" ]]; then
  CI_BUILD="$TRAVIS_BUILD_NUMBER"
  CI_BRANCH="$TRAVIS_BRANCH"
  TAG_COMMIT="$TRAVIS_COMMIT"
  GITHUB_SLUG="$TRAVIS_REPO_SLUG"
fi

echo $CI_BRANCH
if [[ "$CI_BRANCH" =~ ^release/.*$ ]]; then
  RELEASE="$(echo "$CI_BRANCH" | sed 's/^release\///')"
  TAG_NAME="v$RELEASE-$CI_BUILD"
  TAG_MESSAGE="Releasing $TAG_NAME today yo"
else
  echo "This is not a release branch, skipping..."
  exit 0
fi

TAG_DATE="$(date -u '+%FT%T+00:00')"

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
