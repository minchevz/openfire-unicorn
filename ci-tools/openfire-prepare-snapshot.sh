#!/usr/bin/env sh
set -e -x

PACKAGE_NAME=$(mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout)
IMAGE_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)

MODULE_NAME_CAPS=$(echo $PACKAGE_NAME | tr '[:lower:]' '[:upper:]' | tr '-' '_')
BRANCH_NAME=$(eval "echo \$GO_SCM_${MODULE_NAME_CAPS}_SNAPSHOT_SCM_CURRENT_BRANCH")

SNAPSHOT_VERSION="$IMAGE_VERSION-$BRANCH_NAME"

mvn versions:set -DnewVersion=${SNAPSHOT_VERSION}
rm -f pom_snapshot_version.txt
echo "$SNAPSHOT_VERSION" >> pom_snapshot_version.txt
