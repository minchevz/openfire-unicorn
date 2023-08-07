#!/usr/bin/env sh
set -e -x

ARTEFACT_NAME=$(python -c 'from xml.etree.ElementTree import ElementTree; print ElementTree(file="pom.xml").findtext("{http://maven.apache.org/POM/4.0.0}artifactId")')
VERSION=$(python -c 'from xml.etree.ElementTree import ElementTree; print ElementTree(file="pom.xml").findtext("{http://maven.apache.org/POM/4.0.0}version")')
VERSION=${VERSION%%-*}

export DEBUG=gojira:*

JIRA_INSTANCE=https://jira.gamesys.co.uk

# Unicorn atrm can be used if required
# npx community-gojira deploy -a $ARTEFACT_NAME -n $APP_NAME -v $VERSION -j $JIRA_INSTANCE -e ${PROD_ENVIRONMENT:-live-eu}

AUTHOR=$(git show -s --format="%ae" HEAD)
AUTHOR=${AUTHOR%@*}
# Unicorn atrm can be used if required
#TICKET=$(cat ticket.txt)

# Unicorn atrm can be used if required
# if [ $AUTHOR != "go" ]; then
# 	npx community-gojira assign -t $TICKET -u $AUTHOR -j $JIRA_INSTANCE
# fi
