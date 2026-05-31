# Season 1: The Big Bang

**Not** weekly league brackets. This is the first global season of Vertiege: empty worlds get occupied, councils and sovereigns emerge, and worlds grow through earned prestige.

## Product pillars

1. Unclaimed worlds find sovereigns  
2. Veteran councils emerge from standing  
3. World prestige unlocks lounge, treasury, governance  
4. Growth is earned, not purchased  

## Technical

- Client: [`lib/config/season_catalog.dart`](../../lib/config/season_catalog.dart), [`SeasonService`](../../lib/services/season_service.dart), [`SeasonScreen`](../../lib/screens/season_screen.dart)  
- DB: `global_seasons` row `season_1` in migration `20260530170000_season_1_big_bang.sql`  
- World challenges use `scope = 'world'` (season-scoped challenges later)

## Treasury (Season 1 rules)

Only **council** (5k+ rep) and **sovereign** may withdraw from treasury. No member withdrawal requests.
