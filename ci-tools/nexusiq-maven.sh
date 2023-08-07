#!/usr/bin/env sh
set -e -x

NAME=$(python -c 'from xml.etree.ElementTree import ElementTree; print ElementTree(file="pom.xml").findtext("{http://maven.apache.org/POM/4.0.0}artifactId")')
NAME_CAPS=$(echo $NAME | tr '[:lower:]' '[:upper:]' | tr '-' '_')
BRANCH=$(eval "echo \$GO_SCM_${NAME_CAPS}_SNAPSHOT_CURRENT_BRANCH")

echo "Running NexusIQ analysis"

if [ "$BRANCH" == "" ]; then
    NEXUSIQ_STAGE=release
else
    NEXUSIQ_STAGE=build
fi

NEXUSIQ_APP_ID=$NAME

MAVEN_PROPERTIES_ELEMENT=$(python -c 'from xml.etree.ElementTree import ElementTree; print ElementTree(file="pom.xml").find("{http://maven.apache.org/POM/4.0.0}properties")')

if [ "$MAVEN_PROPERTIES_ELEMENT" != 'None' ]; then
    NEXUSIQ_APP_ID_ELEMENT=$(python -c 'from xml.etree.ElementTree import ElementTree; print ElementTree(file="pom.xml").find("{http://maven.apache.org/POM/4.0.0}properties").find("{http://maven.apache.org/POM/4.0.0}clm.applicationId")')

    if [ "$NEXUSIQ_APP_ID_ELEMENT" != 'None' ]; then
        NEXUSIQ_APP_ID=$(python -c 'from xml.etree.ElementTree import ElementTree; print ElementTree(file="pom.xml").find("{http://maven.apache.org/POM/4.0.0}properties").find("{http://maven.apache.org/POM/4.0.0}clm.applicationId").text')
    fi
fi

mvn com.sonatype.clm:clm-maven-plugin:evaluate -Dclm.serverUrl=$NEXUSIQ_SERVER_URL -Dclm.username=$NEXUSIQ_USERNAME -Dclm.password=$NEXUSIQ_PASSWORD -Dclm.applicationId=$NEXUSIQ_APP_ID -Dclm.stage=$NEXUSIQ_STAGE

