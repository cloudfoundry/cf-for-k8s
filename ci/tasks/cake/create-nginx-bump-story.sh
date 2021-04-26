#!/usr/bin/env bash

set -euo pipefail

# ENV
: "${TRACKER_TOKEN:?}"

project_id=1382120
template_story_id=177917976

echo "Fetching Template Story..."

template_story=`curl -s -X GET -H "X-TrackerToken: $TRACKER_TOKEN" "https://www.pivotaltracker.com/services/v5/projects/$project_id/stories/$template_story_id" | sed -E "s|YYYY/MM/DD|$(date '+%Y/%m/%d')|" | jq '. + {"current_state": "started"}'`
template_tasks=`curl -s -X GET -H "X-TrackerToken: $TRACKER_TOKEN" "https://www.pivotaltracker.com/services/v5/projects/$project_id/stories/$template_story_id/tasks"`

echo "Creating story..."

story_id=`curl -s -X POST -H "X-TrackerToken: $TRACKER_TOKEN" -H "Content-Type: application/json" -d "$template_story" "https://www.pivotaltracker.com/services/v5/projects/$project_id/stories" | jq .id`
curl -s -X PUT -H "X-TrackerToken: $TRACKER_TOKEN" -H "Content-Type: application/json" -d '{"current_state":"unstarted"}' "https://www.pivotaltracker.com/services/v5/projects/$project_id/stories/$story_id" > /dev/null
echo $template_tasks | jq -c '(.[])' | xargs -n1 -I{} curl -s -X POST -H "X-TrackerToken: $TRACKER_TOKEN" -H "Content-Type: application/json" -d '{}' "https://www.pivotaltracker.com/services/v5/projects/$project_id/stories/$story_id/tasks" > /dev/null

echo "Created Story id $story_id"

if [[ $story_id == "null" ]]; then
    exit 1
fi
