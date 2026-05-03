---
name: world-server design principle
description: Each world functions as a Discord-like server with full feature parity
type: project
originSessionId: 9ee6c920-c8e7-4d28-a7c9-831cb9e64cf4
---
**Rule:** Every world in Vertiege must function like a Discord server/guild.

**Why:** User's core vision — worlds are not just content feeds, they are full servers with gated entry, internal hierarchy, and sub-features.

**How to apply:** When building features, ask: "Does Discord servers have this?" Each world should eventually support:

- **Channels/rooms** — topic-based sub-spaces within a world (not just a single post feed)
- **Roles & permissions** — the standing system (Visitor → Council) should gate actions within the world
- **Member directory** — see all residents, their standings, roles
- **Announcements** — sovereign/admin broadcast posts
- **Invite system** — residents can invite others (tied to Patron standing)
- **Moderation** — sovereign + council can remove posts, mute, ban
- **Prestige/boosting** — worlds level up with activity (prestige system already exists)
- **World settings** — constitution, entry rules, content types allowed
- **Events** — scheduled happenings within a world
