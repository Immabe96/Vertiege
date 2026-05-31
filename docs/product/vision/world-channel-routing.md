# World channel routing

World channels are opened at:

```text
/explore/{worldId}/{channelName}?id={channelId}
```

## Reserved path segments

These segments under `/explore/{worldId}/` are **screens**, not channels:

- `settings`, `members`, `marketplace`, `polls`, `treasury`, `challenges`, `jobs`, `discover`, `archive`

Do not create a channel whose `name` equals one of these values — navigation will open the economy/governance screen instead of chat.

Use `worldChannelPath()` from `lib/router/world_navigation.dart` for all channel links.
