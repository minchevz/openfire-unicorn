#!/usr/bin/env sh
set -e -x
BRANCH_NAME=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)

if [ "$BRANCH_NAME" == "master" ]; then
    SNAPSHOT_SUFFIX="-SNAPSHOT"
    MAVEN_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
    IMAGE_VERSION=${MAVEN_VERSION/%$SNAPSHOT_SUFFIX}
else
    IMAGE_VERSION=$(cat pom_snapshot_version.txt)
fi
