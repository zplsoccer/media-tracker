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
seasons_total: 5
seasons_aired: 4
next_season_air_date: 2027-03-15
next_season_number: 5
genres: [Sci-Fi, Horror]
poster_path: /somePoster.jpg
---

Body can include notes, ratings, watch logs, or anything else you want to remember.
```

**Status values:**
- `planning` – You want to watch it later
- `watching` – Currently watching or actively planning to start
- `completed` – You've finished watching it
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

The skill automatically creates the directory structure on first use.

## Core Functions

### a) Add/Update Title
- **Trigger:** Natural language like "I want to watch [Title]" or "Add [Title] to my list."
- **What it does:**
  1. Searches TMDB for the title.
  2. Pulls TMDB data (seasons, air dates, genres, poster).
  3. Creates or updates the .md file.
  4. Sets status based on your intent:
     - "I want to watch" → status=planning (or to‑watch if you prefer)
     - "I finished" / "Just watched" → status=completed
     - "I'm watching" / "Started" → status=watching
  5. Replies with the pulled info and a confirmation.

### b) Update Status
- **Trigger:** "Watching [Title] now", "Dropped [Title]", "Completed [Title]".
- **What it does:** Finds the .md file and updates the `status` + `last_updated` fields.

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

## Setup Checklist

- [ ] TMDB bearer token in `~/.hermes/.env` (if not present, add `TMDB_BEARER_TOKEN=***`).
- [ ] Hermes TMDB `tmdb-api` skill is loaded.
- [ ] Hermes Obsidian `obsidian` skill is loaded.
- [ ] Media tracker skill is loaded (this file).
- [ ] Vault path is accessible (default is `~/obsidian/vault/hermes-data`).
- [ ] (Optional) Cron job for upcoming season alerts (set up via `cronjob` tool).

Once ready, just start sending natural‑language Telegram messages with titles you want to track!