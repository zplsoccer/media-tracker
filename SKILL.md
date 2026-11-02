---
name: media-tracker
description: "Track TV shows and movies you watch, stored as .md files in your Obsidian vault, with natural-language Telegram control and TMDB data integration."
version: "1.0.0"
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [Media, TMDB, TV Shows, Movies, Tracker]
    related_skills: [obsidian, tmdb-api]
---

# Media Tracker

A Hermes skill that tracks TV shows and movies you're watching, stored as .md files in your Obsidian vault. It pulls data from TMDB, lets you update status via natural-language Telegram messages, and can alert you about upcoming seasons.

## Mandatory: Media Index Update

**Every single add, update, or status change for a TV show or movie MUST update `Media Index.md` immediately after the per-title .md file is written.** No exceptions, no skipping, no "I'll get to it later." The index is the dashboard the user checks, and a stale index is worse than no index.

To update it:
1. Read all .md files in `TV_Shows/` and `Movies/`.
2. Group by `status` (watching, completed, planning, dropped).
3. Rewrite `Media Index.md` with the current `updated` date and a one-line summary per title under the matching heading.

## Completed / Finished-Airing Shows
When a show has finished airing (TMDB `next_episode_to_air` is null / no `next_season_number`), set `seasons_aired = seasons_total`, `status = completed`, and `next_season_air_date = null`. Confirm with TMDB `status: Returning Series` or `Ended` before recording — do not assume a restart if no new season is confirmed.

## Data Model

Each title is stored as a `.md` file with TMDB ID and personal status tracking:

```yaml
---
type: tv_show              # or "movie"
tmdb_id: 1402            # TMDB's unique ID
title: "Stranger Things"
status: completed        # planning | watching | completed | dropped
added: 2026-11-01
last_updated: 2026-11-01
seasons_total: 4
seasons_aired: 4
next_season_air_date: null
next_season_number: null
genres: [Sci-Fi, Horror]
poster_path: /somePoster.jpg
---

Body can include notes, ratings, watch logs, or anything else you want to remember.
```

**Status values:**
- `planning` – You want to watch it later
- `watching` – Currently watching or actively planning to start
- `completed` – You've finished watching it (including shows with no upcoming seasons)
- `dropped` – You stopped watching or lost interest

## File Organization

The skill stores files in your Obsidian vault at:

```
obsidian/vault/hermes-data/
├── Media/
│   ├── TV_Shows/         # TV show .md files (no spaces/slashes in folder name)
│   │   ├── Stranger Things.md
│   │   └── ...
│   ├── Movies/            # Movie .md files
│   │   ├── The Batman.md
│   │   └── ...
│   └── Media Index.md     # Optional: quick summary dashboard (must be inside Media/)
└── ...
```

- The skill automatically creates the directory structure on first use.

## Pitfalls

- Do NOT use `[[Title]].md` bracket notation for filenames — the user prefers plain filenames (`Stranger Things.md`). Brackets are for Obsidian wiki-links in note bodies, not filenames.
- Folder names should not contain spaces (use `TV_Shows`, not `TV Shows`) so paths stay simple and escape-free.

## Core Functions

### a) Add/Update Title
- **Trigger:** Natural language like "I want to watch [Title]" or "Add [Title] to my list."
- **What it does:**
  1. Searches TMDB for the title.
  2. Pulls TMDB data (seasons, air dates, genres, poster).
  3. Creates or updates the .md file (plain filenames like `Stranger Things.md`, never `[[Stranger Things]].md`).
  4. Updates `Media Index.md` with the latest status summary (always — never skip).
  5. Sets status based on your intent:
     - "I want to watch" → status=planning (or to‑watch if you prefer)
     - "I finished" / "Just watched" → status=completed
     - "I'm watching" / "Started" → status=watching
  6. Replies with the pulled info and a confirmation.

### b) Update Status
- **Trigger:** "Watching [Title] now", "Dropped [Title]", "Completed [Title]".
- **What it does:** Finds the .md file, updates the `status` + `last_updated` fields, then updates `Media Index.md`.

### c) List by Status
- **Trigger:** "What am I watching?", "What haven't I watched?".
- **What it does:** Reads all .md files, filters by status, and returns formatted lists.

### d) Quick Details
- **Trigger:** "Status of [Title]?", "How's [Title] progressing?"
- **What it does:** Displays the TMDB data and status from the .md file.

### e) Monthly Upcoming Season Alert (Cron)
A cron job runs once per month:
- Checks all your `watching` shows for new season air date updates from TMDB.
- If a show has a new `next_season_air_date` (earlier than existing) or new season count, it sends a Telegram message to your DM.
- Example notification:

```
🚀 Upcoming Season Alert
Stranger Things: Season 5 starts March 15, 2027 (was previously March 20)
```

## Telegram Integration

All interactions happen through your Hermes gateway Telegram DM (`8599973508`). The skill:
- Listens for messages containing titles or status keywords.
- Uses Hermes's AI to interpret natural language intent.
- Sends replies back to the same DM.

No new Telegram bot or complex command syntax is required.

## AI Context Understanding

Because the skill runs within Hermes's AI, it understands common intent phrases:

- Completion: "Finished it", "Just watched", "Binge‑watched", "Completed"
- Planning: "Want to watch", "Add to list", "Should check out"
- Progress: "Started", "Watching", "On episode 3"
- Abandonment: "Dropped", "Gave up on", "Not interested anymore"

The AI connects the phrases to specific titles and updates the status accordingly.

## TMDB Integration

The skill uses the `tmdb-api` skill for:
- Searching for titles (use `curl` commands with the TMDB template)
- Getting TV details: includes season counts and next air dates
- Getting movie details: includes release dates

Example TMDB lookup (done by the skill):

```bash
curl --request GET \
  --url 'https://api.themoviedb.org/3/search/multi?query=Stranger%20Things' \
  --header "Authorization: Bearer $TMDB_BEARER_TOKEN" \
  --header 'accept: application/json'
```

After getting the TMDB ID, the skill uses the details endpoint with `append_to_response=content_ratings,episode_groups` for TV or `append_to_response=release_dates` for movies.

## How to Use

1. Ensure your TMDB bearer token is in `~/.hermes/.env` as `TMDB_BEARER_TOKEN`.
2. Tell the skill to add your first title: "I want to watch The Crown".
3. The skill will create the .md file and pull TMDB data.
4. Update status as you go: "I'm watching The Crown now" / "Finished The Crown".
5. Ask for lists or details at any time.

## Cron Job: Automated Weekly Watch Tracking

A cron job runs every 2 weeks (day 1 and 15 of each month at 3am):

**Script:** `/root/.hermes/skills/note-taking/media-tracker/cron-check.sh`

**What it does:**
1. Finds all TV show `.md` files in `TV_Shows/`.
2. Passes them to Hermes agent for AI analysis (using the skill as context).
3. Uses Hermes's AI to understand the MD content, track status changes, and detect new season information.
4. Queries TMDB for any `watching` shows to check for new season air dates.
5. Sends Telegram notifications to your DM if there are changes:
   - New season just started (e.g., "The Gilded Age Season 4 starts 2026-11-08")
   - Show just completed (e.g., "The Diplomat completed all seasons")
   - Upcoming season announcements (new `next_season_air_date` for a show)
   - Shows that need attention based on status in the MD files

**Example notifications:**
```
🚀 New Season Started!
The Gilded Age Season 4 just aired 2026-11-08

✅ Show Completed!
The Diplomat finished all 4 seasons (2026-10-15)

⚠️ Upcoming Season!
Stranger Things Season 5 starting 2027-03-15 (was previously delayed)
```

The Hermes agent uses the MD files as context to understand show progression and interprets the TMDB API results intelligently, ensuring notifications are meaningful and actionable.

---
## Setup Checklist

- [x] TMDB bearer token in `~/.hermes/.env` as `TMDB_BEARER_TOKEN`
- [x] Hermes TMDB `tmdb-api` skill loaded
- [x] Hermes Obsidian `obsidian` skill loaded
- [x] Media tracker skill loaded
- [x] Vault path accessible: `/root/obsidian/vault/hermes-data`
- [x] Cron job set up: `cron-check.sh` runs every 2 weeks at 3am (days 1 & 15), uses Hermes agent to read MD file context

The cron uses Hermes agent so it understands the context in each `.md` file (status, seasons aired, notes) rather than just parsing raw text.
