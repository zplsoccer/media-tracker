# TMDB Lookup Patterns for Media Tracker

Always include the `Authorization: Bearer $TMDB_BEARER_TOKEN` header.
Always include `accept: application/json`.

## Find a Title

Search multi (movie + TV):

```bash
curl -s 'https://api.themoviedb.org/3/search/multi?query=Stranger%20Things' \
  -H "Authorization: Bearer $TMDB_BEARER_TOKEN" \
  -H 'accept: application/json'
```

Search TV only:

```bash
curl -s 'https://api.themoviedb.org/3/search/tv?query=Stranger%20Things' \
  -H "Authorization: Bearer $TMDB_BEARER_TOKEN" \
  -H 'accept: application/json'
```

Search movie only:

```bash
curl -s 'https://api.themoviedb.org/3/search/movie?query=The%20Batman' \
  -H "Authorization: Bearer $TMDB_BEARER_TOKEN" \
  -H 'accept: application/json'
```

## Get Details

TV details (seasons, next episode, content ratings):

```bash
curl -s 'https://api.themoviedb.org/3/tv/{tmdb_id}?append_to_response=content_ratings,episode_groups' \
  -H "Authorization: Bearer $TMDB_BEARER_TOKEN" \
  -H 'accept: application/json'
```

Movie details (release dates):

```bash
curl -s 'https://api.themoviedb.org/3/movie/{tmdb_id}?append_to_response=release_dates' \
  -H "Authorization: Bearer $TMDB_BEARER_TOKEN" \
  -H 'accept: application/json'
```

## Key Fields from TMDB

- `name` (TV) / `title` (Movie) — official title
- `id` — TMDB ID (store in `tmdb_id`)
- `genres` — array of objects with `.name`
- `first_air_date` — start date
- `last_air_date` — most recent season's end date
- `number_of_seasons` — total season count
- `next_episode_to_air` — upcoming episode info (if available)
- `episode_groups` — season group info (includes `air_date` for future seasons)
- `poster_path` — image path (prepend `https://image.tmdb.org/t/p/w500/`)
- `release_date` — for movies

When checking for new seasons, compare `episode_groups[].air_date` and `next_episode_to_air` with what is stored in the `.md` file.