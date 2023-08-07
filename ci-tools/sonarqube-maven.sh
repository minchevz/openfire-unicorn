#!/usr/bin/env sh
set -e -x

NAME=$(python -c 'from xml.etree.ElementTree import ElementTree; print ElementTree(file="pom.xml").findtext("{http://maven.apache.org/POM/4.0.0}artifactId")')
NAME_CAPS=$(echo $NAME | tr '[:lower:]' '[:upper:]' | tr '-' '_')
BRANCH=$(eval "echo \$GO_SCM_${NAME_CAPS}_SNAPSHOT_CURRENT_BRANCH")
COMMIT_ID=$(eval "echo \$GO_SCM_${NAME_CAPS}_SNAPSHOT_LABEL")
MODULE_URL=$(eval "echo \$GO_SCM_${NAME_CAPS}_SNAPSHOT_URL")
GET_PRS=$(git ls-remote $MODULE_URL "pull/*/head" |sed 's/ /,/g')

echo "Running SonarQube analysis"

prs_array=($GET_PRS)

len=${#prs_array[@]}

for ((i = 0 ; i < $len; i++)); do
  val="${prs_array[$i]}"

  if [[ $COMMIT_ID == $val ]]; then
    PR="${prs_array[$i+1]}"

	break;
  fi
done

PR_ID="$(cut -d'/' -f3 <<<"$PR")"

SONARQUBE_APP_ID=$NAME

MAVEN_PROPERTIES_ELEMENT=$(python -c 'from xml.etree.ElementTree import ElementTree; print ElementTree(file="pom.xml").find("{http://maven.apache.org/POM/4.0.0}properties")')

if [ "$MAVEN_PROPERTIES_ELEMENT" != 'None' ]; then
    SONARQUBE_APP_ID_ELEMENT=$(python -c 'from xml.etree.ElementTree import ElementTree; print ElementTree(file="pom.xml").find("{http://maven.apache.org/POM/4.0.0}properties").find("{http://maven.apache.org/POM/4.0.0}sonar.projectKey")')

    if [ "$SONARQUBE_APP_ID_ELEMENT" != 'None' ]; then
        SONARQUBE_APP_ID=$(python -c 'from xml.etree.ElementTree import ElementTree; print ElementTree(file="pom.xml").find("{http://maven.apache.org/POM/4.0.0}properties").find("{http://maven.apache.org/POM/4.0.0}sonar.projectKey").text')
    fi
fi

if [[ -n "$BRANCH" ]]; then
        # GoCD 'Git Branch Poller' plugin has some known issues with master origin branch that cause code coverage and duplication calculation
        # for new code not to be shown. This block is a fix for it.
        git checkout $BRANCH
        git branch --force master origin/master
fi

if [[ -n "$PR_ID" ]]; then
        echo "Found matching pull request ID $PR_ID"
        echo "Running Pull Request Analysis"
        EXTRA_SONAR_OPTS="-Dsonar.pullrequest.key=$PR_ID -Dsonar.pullrequest.branch=$BRANCH -Dsonar.pullrequest.base=master"
        echo $EXTRA_SONAR_OPTS

elif [[ -n "$BRANCH" ]]; then
        echo "Running Branch Analysis"
        EXTRA_SONAR_OPTS="-Dsonar.branch.name=$BRANCH"
        echo $EXTRA_SONAR_OPTS
fi

mvn -s ../tools/ci-tools/settings.xml clean verify
export JAVA_HOME=/etc/alternatives/java_sdk_11
mvn sonar:sonar -Dsonar.host.url=$SONARQUBE_SERVER_URL -Dsonar.login=$SONARQUBE_TOKEN -Dsonar.projectKey=$SONARQUBE_APP_ID -Dsonar.qualitygate.wait=true -Dsonar.qualitygate.timeout=300 $EXTRA_SONAR_OPTS
