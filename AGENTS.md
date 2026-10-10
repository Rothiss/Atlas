# AGENTS.md

Atlas: a WoW 1.12 (Classic/Vanilla) addon — dungeon map browser + loot browser + quest module. Pure Lua + Blizzard XML. No build system, tests, lint, or CI. Code only runs inside a WoW 1.12 client installed to `Interface\AddOns\Atlas`; verify with `/reload` and `/atlas`.

## Golden rules

- **Every `.lua` file must be registered in an XML include** (`Atlas\AtlasInit.xml`, `Loot\LootInit.xml`, `Quest\QuestInit.xml`, `Loot\Data\DataInit.xml`, or `Locales\locales.xml`). Files not listed never load. This is the most common mistake when adding data.
- **WoW 1.12 Lua only.** Script handlers rely on implicit `this`, `arg1..argN`. Use `table.getn` (not `#`), `math.mod` (not `%`), `string.gfind` (not `gmatch`), `unpack` (not `table.unpack`), and string aliases (`strfind`, `strsub`, `strlen`, `strlower`). Modern Lua will silently break the addon.
- Start every file with `local _G = getfenv(); Atlas = _G.Atlas or {}`. Access everything via the global `Atlas` table.

## Layout & load order (do not reorder)

`Atlas.toc` loads three XMLs in order: `AtlasInit.xml`, `LootInit.xml`, `QuestInit.xml`. Effective dependency chain:

1. `AtlasConfig.lua` — defines `Atlas`, `Colors`, `PrintA`, and a Localization stub
2. `AtlasServer.lua` — server detection/whitelist logic
3. `Locales\locales.xml` — all 5 locale sets (enUS is fallback)
4. Loot Core `Utils.lua`/`Cache.lua`/`ItemDB.lua` (pulled in via `AtlasInit.xml`)
5. `Data\DataInit.xml` — instance/world/PvP/info/Tables/Menu data (must load before `DataIndex`/`DataResolver` index it)
6. Atlas UI files, then Loot processing, quests last

## Data model

- **Instance loot**: `Loot\Data\Instances\<Key>.lua` defines `Atlas.InstanceData.<Key>` (e.g. `TheDeadmines.lua` → `...InstanceData.TheDeadmines`). Register in `Data\DataInit.xml`; needs a matching `Images\Maps\<Key>.blp` to render.
- **Quests**: monolithic `Locales\<locale>\QuestData.lua` sets `Atlas.Quest.DataBase = kQuestInstanceData`; each locale file early-returns unless it matches `GetLocale()`. Add/update quests in all 5 locales (enUS is the source of truth; others copy or translate).
- **Other content** (world bosses, PvP, professions, menus): `Loot\Data\{World,PvP,Info,Tables,Menu}`.
- **Localization**: per-locale files call `Atlas.Localization:RegisterNamespace("Bosses", "enUS", {...})`; UI reads via `L["Key"]` (`L = Atlas.Localization.UI`). New locale files/modules must be added to `Locales\locales.xml`.

## Server gating

Servers: `TURTLE1` (Turtle 1.17.2), `TURTLE` (Turtle 1.18.1, inherits TURTLE1 content unless overridden), `VANILLA_PLUS`, `CLASSIC`. Tag server-specific entries with `servers = { Atlas.Server.<X> }`; `"!Server"` / `Atlas.Server.NOT_*` = exclude; `"="` prefix = strict (no inheritance). `Atlas.Server.IsVisible(entry)` gates visibility everywhere — untagged Turtle-only loot will show on all servers.

## Quirks

- **Brand**: this addon presents as plain `Atlas` (`Atlas.toc`, global table `Atlas.*`, saved vars `AtlasOptions`/`AtlasCharDB`, `/atlas`). It is a personal fork of the original Atlas addon — the frame/global names now intentionally match the originals, so it must **not** be installed alongside genuine Atlas, AtlasLoot, or TWLoot. Keep the upstream link (`byCFM2/Atlas-CFM`) and `ATW` version-abbrev references intact.
- **Dual Localization implementations**: both `AtlasConfig.lua` and `Locales\LocalizationFramework.lua` define `RegisterNamespace`/`GetNamespace`; the framework (loaded later) wins at runtime.
- **Versioning**: bump `## Version` in `Atlas.toc` (read via `GetAddOnMetadata`). The version-check module federates `ATW:<n>:v` chat over the `LFT` channel — keep the `abbrev` stable.
- Saved variables: `AtlasOptions` (account-wide), `AtlasCharDB` (per-char).
- Debug: set `Atlas.DEBUGMODE = true` in `AtlasConfig.lua`; messages print via `PrintA()`.
- `Locales\...\QuestData.lua` files carry `-- TODO translate` markers; `AtlasServer.lua` has Russian comments — preserve language.

## Git

Local default branch is `master`, which is identical to `origin/main` (remote HEAD). Keep working on `master`.