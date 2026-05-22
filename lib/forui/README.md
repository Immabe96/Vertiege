# Forui components (Vertiege)

Vertiege uses **[Forui](https://forui.dev)** (`forui: ^0.21.3`) — Flutter widgets modeled after **shadcn/ui**.

## Package widget index

Installed source (browse when implementing):

`%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\forui-0.21.3\lib\widgets\`

| Area | Widgets |
|------|---------|
| Layout | `FScaffold`, `FHeader`, `FHeader.nested`, `FHeaderAction` |
| Navigation | `FTabs`, `FBottomNavigationBar`, `FBreadcrumb` |
| Lists (shadcn “settings” rows) | `FTile`, `FTileGroup` |
| Data | `FCard`, `FBadge`, `FAvatar` |
| Forms | `FButton`, `FTextField`, `FSelect`, `FSwitch`, `FCheckbox`, `FRadio` |
| Feedback | `FAlert`, `FDialog`, `FSheet`, `FToast`, `FProgress` |

Theme: `lib/theme/forui_theme.dart` (`VertiegeForuiTheme`), wrapped in `app.dart` via `FTheme`.

## Project wrappers

| File | Purpose |
|------|---------|
| `lib/widgets/v_section_list.dart` | Settings/More section lists → `FTileGroup` + `FTile` |
| `lib/forui/v_hub_page.dart` | Hub sub-pages → `FScaffold` + `FHeader` |

Prefer **Forui** over raw `ListTile` / `AppBar` / `FilledButton` on new UI. Legacy `lib/ui/*` bridges older screens until migrated.
