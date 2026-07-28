#!/usr/bin/env bash
# Send or dry-run a Jarvis research digest via SMTP env (names in jarvis-profile .env.template).
# Usage:
#   jarvis-send-digest.sh --file path/to/digest.md [--dry-run]
# Exit 2 if required email env missing and not dry-run.
#
# Google Workspace / Gmail: JARVIS_DIGEST_FROM may be an alias while JARVIS_SMTP_USER is
# the primary mailbox. The provider will rewrite From → SMTP user unless that alias is
# authorized as "Send mail as" for the authenticated account. This script cannot bypass
# that server-side policy; it only sets correct MIME headers.
set -euo pipefail

FILE=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file) FILE="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help)
      echo "Usage: $0 --file DIGEST.md [--dry-run]"
      exit 0
      ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$FILE" && -f "$FILE" ]] || { echo "error: --file required and must exist" >&2; exit 2; }

need=(JARVIS_SMTP_HOST JARVIS_SMTP_PORT JARVIS_SMTP_USER JARVIS_SMTP_PASSWORD JARVIS_DIGEST_TO JARVIS_DIGEST_FROM)
missing=0
for v in "${need[@]}"; do
  if [[ -z "${!v:-}" ]]; then
    echo "missing env: $v" >&2
    missing=1
  fi
done

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "dry-run: would send $(basename "$FILE")"
  echo "dry-run: From=${JARVIS_DIGEST_FROM:-?}  To=${JARVIS_DIGEST_TO:-?}  (SMTP auth user=${JARVIS_SMTP_USER:-?})"
  echo "dry-run: path=$FILE bytes=$(wc -c <"$FILE" | tr -d ' ')"
  if [[ -n "${JARVIS_DIGEST_FROM:-}" && -n "${JARVIS_SMTP_USER:-}" \
    && "${JARVIS_DIGEST_FROM,,}" != "${JARVIS_SMTP_USER,,}" ]]; then
    echo "dry-run: note: From ≠ SMTP user — Workspace/Gmail rewrites From unless the alias is Send-as authorized" >&2
  fi
  exit 0
fi

if [[ "$missing" -eq 1 ]]; then
  echo "error: email capability incomplete — set SMTP + digest env or pass --dry-run" >&2
  exit 2
fi

export JARVIS_DIGEST_FILE="$FILE"
python3 - <<'PY'
import html
import os
import re
import smtplib
import ssl
import sys
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.utils import formataddr, parseaddr
from pathlib import Path

host = os.environ["JARVIS_SMTP_HOST"]
port = int(os.environ.get("JARVIS_SMTP_PORT", "587"))
user = os.environ["JARVIS_SMTP_USER"]
password = os.environ["JARVIS_SMTP_PASSWORD"]
to_addr = os.environ["JARVIS_DIGEST_TO"]
from_raw = os.environ["JARVIS_DIGEST_FROM"]
from_name = os.environ.get("JARVIS_DIGEST_FROM_NAME", "Jarvis").strip() or "Jarvis"
starttls = os.environ.get("JARVIS_SMTP_STARTTLS", "1") not in ("0", "false", "no")
body_md = Path(os.environ["JARVIS_DIGEST_FILE"]).read_text(encoding="utf-8")
day = Path(os.environ["JARVIS_DIGEST_FILE"]).stem

# Normalize From: allow bare address or already-formatted "Name <addr>"
_name, from_email = parseaddr(from_raw)
if not from_email:
    from_email = from_raw.strip()
if not _name:
    _name = from_name
from_header = formataddr((_name, from_email))

user_email = parseaddr(user)[1] or user.strip()
if from_email.lower() != user_email.lower():
    print(
        "note: From address differs from SMTP auth user. "
        "Google Workspace/Gmail will show the SMTP user as From unless "
        f"{from_email!r} is authorized as Send mail as for {user_email!r}.",
        file=sys.stderr,
    )


def inline(s: str) -> str:
    s = html.escape(s)
    s = re.sub(
        r"\[([^\]]+)\]\((https?://[^)\s]+)\)",
        r'<a href="\2">\1</a>',
        s,
    )
    s = re.sub(
        r'(?<!["\>])(https?://[^\s<]+)',
        r'<a href="\1">\1</a>',
        s,
    )
    s = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    return s


def md_to_branded_html(md: str) -> str:
    """Stdlib-only markdown → branded HTML for Jarvis brief schema."""
    lines = md.replace("\r\n", "\n").split("\n")
    out: list[str] = []
    # pending open card: {"kind": "ol"|"ul", "title_html": str, "metas": [str]}
    card: dict | None = None
    list_kind: str | None = None  # "ol" | "ul"

    def flush_card() -> None:
        nonlocal card
        if not card:
            return
        metas = "".join(f'<div class="meta-row">{m}</div>' for m in card["metas"])
        out.append(
            f'<li class="card"><div class="card-title">{card["title_html"]}</div>'
            f'{metas}</li>'
        )
        card = None

    def close_list() -> None:
        nonlocal list_kind
        flush_card()
        if list_kind:
            out.append(f"</{list_kind}>")
            list_kind = None

    def open_list(kind: str) -> None:
        nonlocal list_kind
        if list_kind != kind:
            close_list()
            out.append(f'<{kind} class="item-list">')
            list_kind = kind

    for raw in lines:
        line = raw.rstrip()
        if not line.strip():
            continue
        if line.startswith("> "):
            close_list()
            out.append(f'<p class="lede">{inline(line[2:].strip())}</p>')
            continue
        if line.startswith("### "):
            close_list()
            out.append(f"<h3>{inline(line[4:].strip())}</h3>")
            continue
        if line.startswith("## "):
            close_list()
            title = line[3:].strip()
            out.append(
                f'<h2><span class="h2-bar"></span><span class="h2-text">{inline(title)}</span></h2>'
            )
            continue
        if line.startswith("# "):
            close_list()
            out.append(f'<h1 class="doc-title">{inline(line[2:].strip())}</h1>')
            continue
        m = re.match(r"^(\d+)\.\s+(.*)$", line)
        if m:
            open_list("ol")
            flush_card()
            card = {"title_html": inline(m.group(2)), "metas": []}
            continue
        m = re.match(r"^[-*]\s+(.*)$", line)
        if m and not re.match(r"^\s", raw):
            open_list("ul")
            flush_card()
            card = {"title_html": inline(m.group(1)), "metas": []}
            continue
        m = re.match(r"^\s{2,}[-*]\s+(.*)$", line)
        if m and card is not None:
            card["metas"].append(inline(m.group(1)))
            continue
        close_list()
        out.append(f"<p>{inline(line)}</p>")

    close_list()
    body = "\n".join(out)
    # Brand: deep navy + amber accent (matches Jarvis Slack-ish #1a1a2e family)
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<meta name="color-scheme" content="light"/>
<title>Morning brief — {html.escape(day)}</title>
</head>
<body style="margin:0;padding:0;background:#eef0f4;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#eef0f4;padding:24px 12px;">
<tr><td align="center">
<table role="presentation" width="640" cellspacing="0" cellpadding="0" style="max-width:640px;width:100%;background:#ffffff;border-radius:12px;overflow:hidden;border:1px solid #dde1e8;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;color:#1a1a2e;">
  <tr>
    <td style="background:linear-gradient(135deg,#1a1a2e 0%,#16213e 55%,#0f3460 100%);padding:22px 28px;">
      <div style="font-size:11px;letter-spacing:0.14em;text-transform:uppercase;color:#e8c547;font-weight:600;">Daily signal</div>
      <div style="font-size:22px;font-weight:700;color:#ffffff;margin-top:6px;line-height:1.25;">Morning brief</div>
      <div style="font-size:13px;color:#b8c0d4;margin-top:4px;">{html.escape(day)}</div>
    </td>
  </tr>
  <tr>
    <td style="padding:8px 28px 28px 28px;font-size:15px;line-height:1.55;color:#1a1a2e;">
      <style>
        .doc-title {{ display:none; }}
        h2 {{ margin: 1.4rem 0 0.65rem; font-size: 12px; font-weight: 700; letter-spacing: 0.08em;
              text-transform: uppercase; color: #0f3460; border: 0; padding: 0; }}
        h2 .h2-bar {{ display:inline-block; width:4px; height:0.95em; background:#e8c547;
              margin-right:8px; vertical-align:-1px; border-radius:1px; }}
        h3 {{ font-size: 1rem; margin: 1rem 0 0.4rem; color: #1a1a2e; }}
        .lede {{ background: #f7f5ee; border-left: 4px solid #e8c547; margin: 1rem 0 0.5rem;
              padding: 12px 14px; color: #2a2a3a; font-size: 15px; border-radius: 0 8px 8px 0; }}
        .item-list {{ list-style: none; padding: 0; margin: 0.4rem 0 0.2rem; }}
        .card {{ background: #f8f9fc; border: 1px solid #e6e9f0; border-radius: 10px;
              padding: 12px 14px; margin: 0 0 10px; }}
        .card-title {{ font-size: 15px; font-weight: 600; color: #1a1a2e; line-height: 1.4; }}
        .meta-row {{ font-size: 13px; color: #5a6275; margin-top: 4px; line-height: 1.4; }}
        a {{ color: #1a4fbf; text-decoration: none; }}
        p {{ margin: 0.55rem 0; color: #2a2a3a; }}
        code {{ font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 0.9em;
              background: #eef1f6; padding: 0.1em 0.35em; border-radius: 3px; }}
      </style>
{body}
    </td>
  </tr>
  <tr>
    <td style="padding:14px 28px 20px;background:#f4f5f8;border-top:1px solid #e6e9f0;font-size:13px;line-height:1.45;">
      <!--DIGEST_FOOTER-->
    </td>
  </tr>
</table>
</td></tr>
</table>
</body>
</html>
"""


def resolve_slack_deep_link() -> str | None:
    """Operator deep-link into the CoS Slack surface (home channel / DM).

    Prefer explicit JARVIS_DIGEST_SLACK_URL. Else build from SLACK_HOME_CHANNEL
    (+ team when known) so the footer can open the Slack app/client.
    """
    explicit = (os.environ.get("JARVIS_DIGEST_SLACK_URL") or "").strip()
    if explicit:
        return explicit
    channel = (os.environ.get("SLACK_HOME_CHANNEL") or "").strip()
    if not channel:
        return None
    team = (os.environ.get("SLACK_TEAM_ID") or "").strip()
    # Best-effort team id via bot token so app.slack.com/client links work offline
    if not team and (os.environ.get("SLACK_BOT_TOKEN") or "").strip():
        try:
            import json
            import urllib.request

            req = urllib.request.Request(
                "https://slack.com/api/auth.test",
                headers={
                    "Authorization": f"Bearer {os.environ['SLACK_BOT_TOKEN']}",
                },
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=8) as resp:
                data = json.loads(resp.read().decode())
            if data.get("ok") and data.get("team_id"):
                team = str(data["team_id"])
        except Exception:
            team = ""
    if team:
        # Opens workspace client focused on the home DM/channel (desktop/web/app).
        return f"https://app.slack.com/client/{team}/{channel}"
    # Universal redirect — Slack opens the channel in the installed client when possible.
    return f"https://slack.com/app_redirect?channel={channel}"


slack_url = resolve_slack_deep_link()
html_body = md_to_branded_html(body_md)

# Inject footer deep-link (replace placeholder stamped in template)
if slack_url:
    footer_html = (
        f'<a href="{html.escape(slack_url, quote=True)}" '
        f'style="color:#1a4fbf;text-decoration:none;font-weight:600;">'
        f"Discuss this brief in Slack</a>"
        f'<span style="color:#7a8294;"> · tune interests, projects, or coverage</span>'
    )
    footer_plain = f"Discuss this brief in Slack: {slack_url}"
else:
    footer_html = (
        '<span style="color:#7a8294;">Discuss this brief in Slack '
        "(set SLACK_HOME_CHANNEL or JARVIS_DIGEST_SLACK_URL for a deep link)</span>"
    )
    footer_plain = (
        "Discuss this brief in Slack "
        "(set SLACK_HOME_CHANNEL or JARVIS_DIGEST_SLACK_URL for a deep link)."
    )

html_body = html_body.replace("<!--DIGEST_FOOTER-->", footer_html)
plain_body = body_md.rstrip() + "\n\n---\n" + footer_plain + "\n"

# multipart/alternative: plain first, HTML preferred by capable clients
# Subject: no agent name — operator-facing product language only.
msg = MIMEMultipart("alternative")
msg["Subject"] = f"Morning brief — {day}"
msg["From"] = from_header
msg["To"] = to_addr
msg["X-Mailer"] = "jarvis-send-digest"
# Help some providers associate alias with authenticated session
if from_email.lower() != user_email.lower():
    msg["Sender"] = user_email

msg.attach(MIMEText(plain_body, "plain", "utf-8"))
msg.attach(MIMEText(html_body, "html", "utf-8"))

# Envelope from: use digest From when possible so providers that honor MAIL FROM
# keep the alias; Gmail often still rewrites display From without Send-as.
envelope_from = from_email

if starttls:
    ctx = ssl.create_default_context()
    with smtplib.SMTP(host, port, timeout=60) as s:
        s.ehlo()
        s.starttls(context=ctx)
        s.ehlo()
        s.login(user, password)
        s.send_message(msg, from_addr=envelope_from, to_addrs=[to_addr])
else:
    with smtplib.SMTP_SSL(host, port, timeout=60) as s:
        s.login(user, password)
        s.send_message(msg, from_addr=envelope_from, to_addrs=[to_addr])

print(f"sent digest From={from_header!r} To={to_addr!r}", file=sys.stderr)
PY
