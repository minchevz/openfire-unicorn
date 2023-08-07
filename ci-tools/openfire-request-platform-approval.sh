#!/usr/bin/env sh
set -e -x


if [ ! -f ticket.txt ]; then
	echo "Ticket not found. Not requesting platform approval on unknown ticket."

	exit 1
fi

export DEBUG=gojira:*

TICKET=$(cat ticket.txt)
JIRA_INSTANCE=https://jira.gamesys.co.uk

# Unicorn teams group can be used if required
# TICKET_URL=$JIRA_INSTANCE/browse/$TICKET
# URL=https://outlook.office.com/webhook/57da451a-e85e-4ca9-a061-f6f329b1ea3b@a2fb1bdc-71c6-43b3-b80d-de077d817707/IncomingWebhook/36f7b0ab92fe4f1babb72372f6b7861c/a56371b9-c92f-4571-868a-44295b0a6686
# MESSAGE="Platform Approval Please: [$TICKET_URL]($TICKET_URL)"

# Unicorn atrm can be used if required
#npx community-gojira comment -t $TICKET -c "This has been tested on PP" -j $JIRA_INSTANCE

# Unicorn atrm can be used if required
#npx community-gojira transition -t $TICKET -s PLATFORM_APPROVAL -j $JIRA_INSTANCE

# Unicorn teams group can be used if required
# curl \
# 	--header "Content-Type: application/json" \
# 	--request POST \
# 	--data "{\"text\": \"$MESSAGE\", \"themeColor\": \"#43a7ff\"}" \
# 	$URL

AUTHOR=$(git show -s --format="%ae" HEAD)
AUTHOR=${AUTHOR%@*}
TICKET=$(cat ticket.txt)

if [ $AUTHOR != "go" ]; then
	# Unicorn atrm can be used if required
	#npx community-gojira reporter -t $TICKET -u $AUTHOR -j $JIRA_INSTANCE
fi
