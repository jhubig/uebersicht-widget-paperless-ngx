#-----------------------------------------------------------------------#
# paperless-ngx widget for Übersicht
# Created August 2025 by Johannes Hubig

# DISCLAIMER:
# This is an unofficial widget for use with Übersicht.
# It is NOT affiliated with or endorsed by the paperless-ngx project.

# Configuration
TOKEN="yourtoken" # token can be found on your paperless instance inside the profile section
BASE='http://xxx.xxx.xxx.xxx:8000' # enter your ip address of your paperless-ngx instance
lang = 'de'  # 'de' for German, 'en' for English

# Widget position on screen
pos_top = '180px'
pos_right = '300px'

# Color and transparency settings
font_color = '#000'
bg_color = '#ffffff'
opacity = 0.5

refreshFrequency: 30000  # widget refresh interval in milliseconds
#-----------------------------------------------------------------------#

# Helper function: Convert hex color to RGB array
hexToRgb = (hex) ->
  hex = hex.replace('#', '')
  if hex.length == 3
    hex = hex.split('').map((c) -> c + c).join('')
  r = parseInt(hex.substr(0, 2), 16)
  g = parseInt(hex.substr(2, 2), 16)
  b = parseInt(hex.substr(4, 2), 16)
  return [r, g, b]

[r, g, b] = hexToRgb(bg_color)

# Language-dependent UI labels
labels =
  de:
    documents: "📄 Dokumente"
    today: "🕒 Heute"
    correspondents: "👤 Korrespondenten"
    tags: "📎 Tags"
    last: "📝 Letztes"
  en:
    documents: "📄 Documents"
    today: "🕒 Today"
    correspondents: "👤 Correspondents"
    tags: "📎 Tags"
    last: "📝 Last"

# Data fetching and parsing
command: """
set -e

# API availability check
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Token #{TOKEN}" "#{BASE}/api/documents/?page_size=1")
if [ "$STATUS" != "200" ]; then
  echo "ERROR"
  exit 0
fi

# API queries
COUNT=$(curl -s -H "Authorization: Token #{TOKEN}" "#{BASE}/api/documents/?page_size=1" | jq '.count')
TODAY=$(curl -s -H "Authorization: Token #{TOKEN}" "#{BASE}/api/documents/?added__gte=$(date -u +%F)T00:00:00Z&page_size=1" | jq '.count')
CORR=$(curl -s -H "Authorization: Token #{TOKEN}" "#{BASE}/api/correspondents/?page_size=1" | jq '.count')
TAGS=$(curl -s -H "Authorization: Token #{TOKEN}" "#{BASE}/api/tags/?page_size=1" | jq '.count')
LAST_TITLE=$(curl -s -H "Authorization: Token #{TOKEN}" "#{BASE}/api/documents/?page_size=1&ordering=-created" | jq -r '.results[0].title // "Unknown"')

# Output values separated by semicolons
echo "$COUNT;$TODAY;$CORR;$TAGS;$LAST_TITLE"
"""

# Render HTML structure
render: -> """
  <div class="paperless-widget">
    <img class="logo" src="paperless-ngx.widget/Paperless-ngx-logo.svg" />
    <div class="label">#{labels[lang].documents}</div>
    <div class="count">...</div>
    <div class="meta">
      <div>#{labels[lang].today}: <span class="today">...</span></div>
      <div>#{labels[lang].correspondents}: <span class="correspondents">...</span></div>
      <div>#{labels[lang].tags}: <span class="tags">...</span></div>
      <div>#{labels[lang].last}: <span class="last-title">...</span></div>
    </div>
  </div>
"""

# CSS styles
style: """
  top: #{pos_top}
  right: #{pos_right}

  .logo {
    width: 200px;
    height: auto;
    margin-bottom: 5px;
    display: block;
  }

  .paperless-widget {
    font-family: system-ui, sans-serif;
    padding: 10px;
    color: #{font_color};
    background-color: rgba(#{r}, #{g}, #{b}, #{opacity});
    border-radius: 8px;
    min-width: 200px;
    box-shadow: 0 2px 5px rgba(0,0,0,0.1);
  }

  .label {
    font-size: 14px;
    opacity: 0.7;
  }

  .count {
    font-size: 24px;
    font-weight: bold;
  }

  .meta {
    margin-top: 8px;
    font-size: 12px;
    line-height: 1.4;
  }

  .last-title {
    font-style: italic;
  }
"""

# Output update logic
update: (output, domEl) ->
  if !output or typeof output != 'string'
    domEl.querySelector('.count').innerText = "⚠️ No Output"
    return

  if output.trim() == "ERROR"
    domEl.querySelector('.count').innerText = "⚠️ API Error"
    domEl.querySelector('.today').innerText = "-"
    domEl.querySelector('.correspondents').innerText = "-"
    domEl.querySelector('.tags').innerText = "-"
    domEl.querySelector('.last-title').innerText = "-"
    return

  try
    [documents, today, correspondents, tags, lastTitle] = output.trim().split(";")
    domEl.querySelector('.count').innerText = documents or "?"
    domEl.querySelector('.today').innerText = today or "?"
    domEl.querySelector('.correspondents').innerText = correspondents or "?"
    domEl.querySelector('.tags').innerText = tags or "?"
    domEl.querySelector('.last-title').innerText = lastTitle or "?"
  catch error
    domEl.querySelector('.count').innerText = "❌ Error"
    domEl.querySelector('.today').innerText = "-"
    domEl.querySelector('.correspondents').innerText = "-"
    domEl.querySelector('.tags').innerText = "-"
    domEl.querySelector('.last-title').innerText = "-"
