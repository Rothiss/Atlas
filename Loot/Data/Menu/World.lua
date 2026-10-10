---
--- World.lua - World boss loot system
---
--- This module handles world boss loot tables and menu systems for Atlas.
--- It provides access to outdoor raid bosses, world dragons, and other rare
--- spawns with their unique loot tables and spawn information.
---
--- Features:
--- • World boss loot catalogs
--- • Spawn location information
--- • Rare drop tracking
--- • Cross-zone boss organization
--- • Integration with Babble localization
---
--- @compatible World of Warcraft 1.12
---

local _G = getfenv()

Atlas = _G.Atlas
Atlas.MenuData = Atlas.MenuData or {}

local L = Atlas.Localization.UI
local LB = Atlas.Localization.Bosses

Atlas.MenuData.WorldBosses = {
    { name = LB["Azuregos"],                extra = "Azshara",                       icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Blue",     lootpage = "Azuregos" },
    { name = LB["Emeriss"],                 Extra = L["Various Locations"],          icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Green",    lootpage = "FourDragons" },
    { name = LB["Lethon"],                  Extra = L["Various Locations"],          icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Green",    lootpage = "FourDragons" },
    { name = LB["Taerar"],                  Extra = L["Various Locations"],          icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Green",    lootpage = "FourDragons" },
    { name = LB["Ysondre"],                 Extra = L["Various Locations"],          icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Green",    lootpage = "FourDragons" },
    {},
    { name = LB["Lord Kazzak"],             extra = "Blasted Lands",                 icon = "Interface\\Icons\\warlock_summon_doomguard",      lootpage = "LordKazzak" },
    { name = LB["Lady Hederine"],           extra = "Winterspring",                  icon = "Interface\\Icons\\spell_shadow_summonsuccubus",   lootpage = "LadyHederine",       servers = { Atlas.Server.VANILLA_PLUS } },
    { name = LB["Kurinnaxx"],               extra = "Silithus",                      icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath",  lootpage = "Kurinnaxx",          servers = { Atlas.Server.VANILLA_PLUS } },
    { name = LB["King Mosh"],               extra = "Un'goro Crater",                icon = "Interface\\Icons\\Ability_Druid_FerociousBite",   lootpage = "KingMosh",           servers = { Atlas.Server.VANILLA_PLUS } },
    { name = LB["Teremus the Devourer"],    extra = "Blasted Lands",                 icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",    lootpage = "TeremustheDevourer", servers = { Atlas.Server.VANILLA_PLUS } },
    { name = LB["Nerubian Overseer"],       extra = "Eastern Plaguelands",           icon = "Interface\\Icons\\Spell_Nature_Web",              lootpage = "Nerubian",           servers = { Atlas.Server.TURTLE1 } },
    { name = LB["Dark Reaver of Karazhan"], extra = "Deadwind Pass",                 icon = "Interface\\Icons\\Ability_Mount_Dreadsteed",      lootpage = "Reaver",             servers = { Atlas.Server.TURTLE1 } },
    { name = LB["Ostarius"],                extra = "Tanaris",                       icon = "Interface\\Icons\\INV_Misc_Platnumdisks",         lootpage = "Ostarius",           servers = { Atlas.Server.TURTLE1 } },
    { name = LB["Concavius"],               extra = "Desolace",                      icon = "Interface\\Icons\\Spell_Shadow_SummonVoidWalker", lootpage = "Concavius",          servers = { Atlas.Server.TURTLE1 } },
    {},
    { name = LB["Moo"],                     extra = "Moomoo Grove",                  icon = "Interface\\Icons\\Spell_Nature_Polymorph_Cow",    lootpage = "CowKing",            servers = { Atlas.Server.TURTLE1 } },
    { name = LB["Cla'ckora"],               extra = "Azshara",                       icon = "Interface\\Icons\\INV_Misc_Birdbeck_02",          lootpage = "Clackora",           servers = { Atlas.Server.TURTLE } },
    { name = L["Rare Mobs"],                Extra = L["Various Locations"],          icon = "Interface\\Icons\\INV_Misc_Head_Undead_01",       lootpage = "RareMobs",           servers = { Atlas.Server.TURTLE1 } },
    { name = L["Weapon Skills"],            icon = "Interface\\Icons\\INV_Sword_04", lootpage = "AtlasLootWeaponSkillsMenu" },
}

---
-- Display the World Bosses menu in AtlasLoot
-- @function AtlasLoot_WorldMenu
-- @usage AtlasLoot_WorldMenu()
---
function AtlasLoot_WorldMenu()
    Atlas.LootBrowserUI.PrepMenu(L["World"], Atlas.MenuData.WorldBosses)
end
