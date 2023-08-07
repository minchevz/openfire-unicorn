#!/usr/bin/env sh
set -e -x

# Sets these vars: IMAGE_VERSION, PACKAGE_NAME, BRANCH_NAME
source ./ci-tools/openfire-get-build-info.sh

ENVIRONMENTS=$@

if [ -z ${ENVIRONMENTS+x} ] || [[ $ENVIRONMENTS == '' ]]; then
    if [ -z ${DEPLOY_ENV+x} ] || [[ $DEPLOY_ENV == '' ]]; then
        if [ "$BRANCH_NAME" == "master" ]; then
            ENVIRONMENTS=pp2
        else
            ENVIRONMENTS=int03
        fi
    else
        ENVIRONMENTS=$DEPLOY_ENV
    fi
fi

# Unicorn atrm can be used if required
# if [ -f ticket.txt ]; then
#     JIRA_INSTANCE=https://jira.gamesys.co.uk
#     TICKET=$(cat ticket.txt)

#     export DEBUG=gojira:*
# fi

# Unicorn atrm can be used if required
# if [ $TICKET ]; then
#     npx community-gojira transition -t $TICKET -s PP_DEPLOY -j $JIRA_INSTANCE
#     npx community-gojira assign -t $TICKET -u sys_community_automa -j $JIRA_INSTANCE
# else
#     echo "No ticket specified - Not transitioning to PP_DEPLOY"
# fi

for ENV in $ENVIRONMENTS
do
    echo "Running deploy script for: $ENV"

    TOWER_PASSWORD=$TOWER_INT_PASSWORD
    TOWER_HOST=$TOWER_INT_HOST

    if [[ $ENV =~ 'pp' ]]; then
	    TOWER_PASSWORD=$TOWER_STG_PASSWORD
	    TOWER_HOST=$TOWER_STG_HOST
    fi

    TEMPLATE_NAME="Deploy $APP_NAME - $ENV"
    EXTRA_VARS="$VERSION_KEY=$IMAGE_VERSION app_version=${IMAGE_VERSION}"

    if [ $DEPLOY_HOST ]; then
        EXTRA_VARS="${EXTRA_VARS} host=${DEPLOY_HOST} app_hosts=${DEPLOY_HOST}_notifications"
    fi

    if [ $DEPLOY_VENTURE ]; then
        EXTRA_VARS="${EXTRA_VARS} host=${DEPLOY_VENTURE} app_hosts=${DEPLOY_VENTURE}_notifications"
    fi

    tower-cli job launch \
        -u $TOWER_USERNAME \
        -p $TOWER_PASSWORD \
        -h $TOWER_HOST \
        --job-template "$TEMPLATE_NAME" \
        --extra-vars "$EXTRA_VARS" \
        --monitor
done

# Unicorn atrm can be used if required
# if [ $TICKET ]; then
#     npx community-gojira transition -t $TICKET -s COMPLETED_PP_DEPLOYMENT -j $JIRA_INSTANCE
# else
#     echo "No ticket specified - Not transitioning to COMPLETED_PP_DEPLOYMENT"
# fi
