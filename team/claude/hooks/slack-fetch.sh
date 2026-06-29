#!/bin/bash
# Slack digest — fetches ALL channels + DMs Michael is member of
# Free: uses Slack Web API directly, no claude -p

TOKEN=$(cat ~/.slack_token 2>/dev/null)
if [ -z "$TOKEN" ]; then
  echo "No Slack token at ~/.slack_token" >&2
  exit 1
fi

OUTPUT="/home/korm85/projects/work/slack-digest.md"
DATE=$(date '+%Y-%m-%d %H:%M')
MY_USER_ID="U0B8A4UNP4H"

# Fetch and format messages from a channel
fetch_messages() {
  local channel=$1
  local limit=${2:-20}
  curl -s "https://slack.com/api/conversations.history?channel=${channel}&limit=${limit}" \
    -H "Authorization: Bearer $TOKEN" | \
    python3 -c "
import json, sys, datetime

USERS = {
  'U0B0XG9UD09': 'Roy',
  'U0B1CTYT96C': 'Matan',
  'U0B8A4UNP4H': 'Michael',
  'U0BB9S528KA': 'Yael',
  'U0BBFV64R46': 'May',
  'USLACKBOT': 'Slackbot',
}

d = json.load(sys.stdin)
if not d.get('ok'):
    print('  [error]', d.get('error','unknown'))
    sys.exit(0)
msgs = d.get('messages', [])
if not msgs:
    print('  (no messages)')
    sys.exit(0)
for m in reversed(msgs):
    if m.get('subtype') in ('channel_join','channel_leave','bot_message'): continue
    ts = float(m.get('ts', 0))
    dt = datetime.datetime.fromtimestamp(ts).strftime('%m-%d %H:%M')
    uid = m.get('user', '')
    name = USERS.get(uid, uid[:8])
    text = m.get('text', '').replace('\n', ' ')[:300]
    print(f'  [{dt}] {name}: {text}')
"
}

{
  echo "# Slack Digest — $DATE"
  echo ""

  # Get all conversations dynamically
  CONVOS=$(curl -s "https://slack.com/api/users.conversations?types=im,mpim,public_channel,private_channel&limit=100" \
    -H "Authorization: Bearer $TOKEN")

  echo "$CONVOS" | python3 -c "
import json, sys
USERS = {
  'U0B0XG9UD09': 'Roy',
  'U0B1CTYT96C': 'Matan',
  'U0B8A4UNP4H': 'Michael',
  'U0BB9S528KA': 'Yael',
  'U0BBFV64R46': 'May',
  'U0BAHH3HH7G': '_BOT_',
  'U0BBB60GHG8': '_BOT_',
  'U0B8N9T0D4K': '_BOT_',
  'U0B0JM8CZPU': '_BOT_',
  'U0B1CU988TA': '_BOT_',
  'U0BC89FB7LH': '_BOT_',
  'USLACKBOT':   '_BOT_',
  'USLACK':      '_BOT_',
}
d = json.load(sys.stdin)
channels = d.get('channels', [])
for c in channels:
    cid = c.get('id','')
    name = c.get('name', '')
    user = c.get('user', '')
    if cid.startswith('D'):
        ctype = 'dm'
        label = USERS.get(user, user)
    elif name.startswith('mpdm'):
        ctype = 'mpim'
        label = name
    else:
        ctype = 'channel'
        label = name
    print(f'{ctype}|{cid}|{label}')
" | while IFS='|' read -r ctype cid cname; do
    case "$ctype" in
      channel)
        echo "## #${cname}"
        fetch_messages "$cid" 20
        ;;
      mpim)
        # Group DM — strip mpdm- prefix and clean up name
        label=$(echo "$cname" | sed 's/mpdm-//;s/-[0-9]*$//' | tr '-' ' ')
        echo "## Group DM: ${label}"
        fetch_messages "$cid" 15
        ;;
      dm)
        # Skip bots and self
        [ "$cname" = "_BOT_" ] && continue
        [ "$cid" = "D0B867QGGMC" ] && continue  # self-DM
        echo "## DM: ${cname}"
        fetch_messages "$cid" 15
        ;;
    esac
    echo ""
  done

} > "$OUTPUT"

echo "Slack digest written to $OUTPUT at $DATE"
