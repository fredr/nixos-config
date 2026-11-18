import html
import json
import math
import os
import re
import time
from datetime import datetime, timedelta
from pathlib import Path

import gi

gi.require_version("ECal", "2.0")
gi.require_version("EDataServer", "1.2")
gi.require_version("ICalGLib", "3.0")
from gi.repository import ECal, EDataServer, GLib, ICalGLib  # noqa: E402

LINK_FILE = Path(os.environ["XDG_RUNTIME_DIR"]) / "waybar-calendar-link"
REFRESH_EVERY = 300
SOON = timedelta(minutes=5)
# Google puts its Meet link in X-GOOGLE-CONFERENCE, other services only
# leave theirs somewhere in the location or description.
MEETING_URL = re.compile(
    r"https://(meet\.google\.com|[\w.-]*zoom\.us|teams\.microsoft\.com)/\S*"
)

registry = EDataServer.SourceRegistry.new_sync(None)
clients = {}
# Wall clock, not monotonic, so waking from suspend refreshes right away.
last_refresh = 0.0


def client_for(source):
    uid = source.get_uid()
    if uid not in clients:
        # -1 opens the cached copy without waiting for the backend to
        # reach the server; local calendars never report being connected,
        # so any wait would be spent in full.
        client = ECal.Client.connect_sync(
            source, ECal.ClientSourceType.EVENTS, GLib.MAXUINT32, None
        )
        # Floating times are meant as local time.
        client.set_default_timezone(ECal.util_get_system_timezone())
        clients[uid] = client
    return clients[uid]


def declined(comp, me):
    return any(
        a.get_value().lower() == f"mailto:{me}".lower()
        and a.get_partstat() == ICalGLib.ParameterPartstat.DECLINED
        for a in comp.get_attendees()
    )


def meeting_link(icomp):
    conference = ECal.util_component_dup_x_property(
        icomp, "X-GOOGLE-CONFERENCE"
    )
    if conference:
        return conference
    for text in (icomp.get_location(), icomp.get_description()):
        match = MEETING_URL.search(text or "")
        if match:
            return match.group(0)
    return ""


def to_datetime(t):
    return datetime.fromtimestamp(
        t.as_timet_with_zone(t.get_timezone())
    ).astimezone()


def instances(client, start, end):
    _, me = client.get_backend_property_sync(
        ECal.BACKEND_PROPERTY_CAL_EMAIL_ADDRESS, None
    )
    events = []

    def add(icomp, instance_start, instance_end, *_):
        # All-day events aren't meetings.
        if instance_start.is_date():
            return True
        comp = ECal.Component.new_from_icalcomponent(icomp.clone())
        if me and declined(comp, me):
            return True
        events.append({
            "title": icomp.get_summary() or "(No title)",
            "start": to_datetime(instance_start),
            "end": to_datetime(instance_end),
            "link": meeting_link(icomp),
        })
        return True

    client.generate_instances_sync(
        int(start.timestamp()), int(end.timestamp()), None, add, None
    )
    return events


def short(title):
    return title if len(title) <= 30 else title[:29] + "…"


def render(events, errors, now):
    # The same meeting shows up once per calendar and account it's on.
    unique = {(e["start"], e["end"], e["title"]): e for e in events}
    upcoming = sorted(
        (e for e in unique.values() if e["end"] > now),
        key=lambda e: e["start"],
    )
    ongoing = [e for e in upcoming if e["start"] <= now]
    later = [e for e in upcoming if e["start"] > now]
    current = ongoing[-1] if ongoing else None
    following = later[0] if later else None

    parts = []
    classes = []
    if current:
        hours, minutes = divmod(
            math.ceil((current["end"] - now).total_seconds() / 60), 60
        )
        if not hours:
            left = f"{minutes}m"
        elif not minutes:
            left = f"{hours}h"
        else:
            left = f"{hours}h {minutes}m"
        parts.append(f"{short(current['title'])} ({left} left)")
    if following:
        title = short(following["title"])
        if following["start"] - now <= timedelta(hours=1):
            until = math.ceil((following["start"] - now).total_seconds() / 60)
            parts.append(f"{title} in {until}m")
        else:
            parts.append(f"{title} {following['start']:%H:%M}")

    # The click joins whichever meeting is next up to need it.
    shown = None
    if following and following["start"] - now <= SOON:
        shown = following
        classes.append("soon")
    elif current:
        shown = current
        classes.append("ongoing")
    elif following:
        shown = following
        classes.append("upcoming")
    text = " · ".join(parts)

    tooltip = [
        f"{e['start']:%H:%M}–{e['end']:%H:%M}  {e['title']}" for e in upcoming
    ]
    if errors:
        classes.append("error")
        text = text or "calendar error"
        tooltip += [f"{name}: {err}" for name, err in errors.items()]

    LINK_FILE.write_text(shown["link"] if shown else "")
    return {
        "text": html.escape(text, quote=False),
        "tooltip": html.escape("\n".join(tooltip), quote=False),
        "class": classes,
    }


def tick():
    global last_refresh
    now = datetime.now().astimezone()
    midnight = (now + timedelta(days=1)).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    refresh = time.time() - last_refresh >= REFRESH_EVERY

    events = []
    errors = {}
    sources = registry.list_enabled(EDataServer.SOURCE_EXTENSION_CALENDAR)
    for source in sources:
        try:
            client = client_for(source)
            events += instances(client, now, midnight)
            # evolution-data-server syncs on its own, but only every half
            # hour or so.
            if refresh and client.check_refresh_supported():
                client.refresh_sync(None)
        except GLib.Error as e:
            errors[source.get_display_name()] = e.message
    if refresh:
        last_refresh = time.time()

    print(json.dumps(render(events, errors, now)), flush=True)
    return True


tick()
GLib.timeout_add_seconds(30, tick)
# The registry only sees accounts added later while the main loop runs.
GLib.MainLoop().run()
