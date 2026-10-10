---
--- Sets.lua - Item sets and collections management
---
--- This module provides comprehensive set browsing functionality for all WoW item sets
--- in Atlas. It organizes and displays various equipment sets including dungeon sets,
--- raid sets, PvP sets, and crafted sets with detailed information and requirements.
---
--- Features:
--- • Complete item set catalogs
--- • Set bonus information display
--- • Level and source requirement tracking
--- • Cross-set comparison tools
--- • Integration with Babble localization
---
--- @compatible World of Warcraft 1.12
---

local _G = getfenv()

Atlas = _G.Atlas

Atlas.MenuData = Atlas.MenuData or {}

local L = Atlas.Localization.UI
local LMD = Atlas.Localization.MapData
local LIS = Atlas.Localization.ItemSets
local LC = Atlas.Localization.Classes
local LZ = Atlas.Localization.Zones
local LF = Atlas.Localization.Factions

local Colors = Atlas.Colors

local data = AtlasLoot_Data

Atlas.MenuData.Sets = {
    { name = L["Pre 60 Sets"],                         icon = "Interface\\Icons\\INV_Sword_43",                 lootpage = "AtlasLootPRE60SetMenu" },
    { name = L["Zul'Gurub Sets"],                      icon = "Interface\\Icons\\INV_Sword_55",                 lootpage = "AtlasLootZGSetMenu" },
    { name = L["Ruins of Ahn'Qiraj Sets"],             icon = "Interface\\Icons\\INV_Axe_15",                   lootpage = "AtlasLootAQ20SetMenu" },
    { name = LZ["Timbermaw Hold"] .. " " .. L["Sets"], icon = "Interface\\Icons\\INV_Chest_Plate01",            lootpage = "TimbermawHoldSets",         servers = { Atlas.Server.TURTLE } },
    { name = L["Temple of Ahn'Qiraj Sets"],            icon = "Interface\\Icons\\INV_Sword_59",                 lootpage = "AtlasLootAQ40SetMenu" },
    { name = LMD["Tower of Karazhan Sets"],            icon = "Interface\\Icons\\INV_Staff_Medivh",             lootpage = "AtlasLootT35SetMenu",    servers = { Atlas.Server.TURTLE } },
    { name = L["Tier 0/0.5 Sets"],                     icon = "Interface\\Icons\\INV_Chest_Chain_03",           lootpage = "AtlasLootT0SetMenu" },
    { name = L["Tier 1 Sets"],                         icon = "Interface\\Icons\\INV_Pants_Mail_03",            lootpage = "AtlasLootT1SetMenu",     servers = { Atlas.Server.NOT_VANILLA_PLUS } },
    { name = L["Tier 1 Sets" .. " (V+)"],              icon = "Interface\\Icons\\INV_Pants_Mail_03",            lootpage = "AtlasLootT1VPSetMenu",   servers = { Atlas.Server.VANILLA_PLUS } },
    { name = L["Tier 2 Sets"],                         icon = "Interface\\Icons\\INV_Shoulder_32",              lootpage = "AtlasLootT2SetMenu" },
    { name = L["Tier 3 Sets"],                         icon = "Interface\\Icons\\INV_Chest_Plate02",            lootpage = "AtlasLootT3SetMenu" },
    {},
    { name = L["World Blues"],                         icon = "Interface\\Icons\\INV_Box_01",                   lootpage = "AtlasLootWorldBluesMenu" },
    { name = L["World Epics"],                         icon = "Interface\\Icons\\INV_Box_04",                   lootpage = "WorldEpics" },
    { name = L["World Enchants"],                      icon = "Interface\\Icons\\INV_Misc_Book_11",             lootpage = "WorldEnchants" },
    { name = L["Legendary Items"],                     icon = "Interface\\Icons\\INV_Staff_Medivh",             lootpage = "Legendaries" },
    { name = L["Artifact Items"],                      icon = "Interface\\Icons\\INV_Sword_07",                 lootpage = "Artifacts" },
    { name = L["Rare Pets"],                           icon = "Interface\\Icons\\Ability_Seal",                 lootpage = "RarePets" },
    { name = L["Rare Mounts"],                         icon = "Interface\\Icons\\INV_Misc_QirajiCrystal_05",    lootpage = "RareMounts" },
    { name = L["Old Mounts"],                          icon = "Interface\\Icons\\Ability_Mount_RidingHorse",    lootpage = "OldMounts" },
    { name = L["Tabards"],                             icon = "Interface\\Icons\\INV_Shirt_GuildTabard_01",     lootpage = "Tabards" },
    {},
    { name = Colors.Priest .. L["Priest Sets"],        icon = "Interface\\Icons\\Spell_Holy_PowerWordShield",   lootpage = "AtlasLootPriestSetMenu" },
    { name = Colors.Mage .. L["Mage Sets"],            icon = "Interface\\Icons\\Spell_Frost_IceStorm",         lootpage = "AtlasLootMageSetMenu" },
    { name = Colors.Warlock .. L["Warlock Sets"],      icon = "Interface\\Icons\\Spell_Shadow_CurseOfTounges",  lootpage = "AtlasLootWarlockSetMenu" },
    { name = Colors.Rogue .. L["Rogue Sets"],          icon = "Interface\\Icons\\Ability_BackStab",             lootpage = "AtlasLootRogueSetMenu" },
    { name = Colors.Druid .. L["Druid Sets"],          icon = "Interface\\Icons\\Spell_Nature_Regeneration",    lootpage = "AtlasLootDruidSetMenu" },
    { name = Colors.Hunter .. L["Hunter Sets"],        icon = "Interface\\Icons\\Ability_Hunter_RunningShot",   lootpage = "AtlasLootHunterSetMenu" },
    { name = Colors.Shaman .. L["Shaman Sets"],        icon = "Interface\\Icons\\Spell_FireResistanceTotem_01", lootpage = "AtlasLootShamanSetMenu" },
    { name = Colors.Paladin .. L["Paladin Sets"],      icon = "Interface\\Icons\\Spell_Holy_SealOfMight",       lootpage = "AtlasLootPaladinSetMenu" },
    { name = Colors.Warrior .. L["Warrior Sets"],      icon = "Interface\\Icons\\INV_Shield_05",                lootpage = "AtlasLootWarriorSetMenu" },
}

---
--- Main sets menu function
--- @return nil
--- @usage AtlasLootSetMenu()
---
function AtlasLootSetMenu()
    Atlas.LootBrowserUI.PrepMenu(L["Collections"], Atlas.MenuData.Sets)
end

Atlas.MenuData.WorldBlues = {
    {},
    { name = L["Head"],                             icon = "Interface\\Icons\\INV_Helmet_01",           lootpage = "WorldBluesHead" },
    { name = L["Neck"],                             icon = "Interface\\Icons\\INV_Jewelry_Necklace_21", lootpage = "WorldBluesNeck" },
    { name = L["Shoulder"],                         icon = "Interface\\Icons\\INV_Shoulder_02",         lootpage = "WorldBluesShoulder" },
    { name = L["BackEquip"],                        icon = "Interface\\Icons\\INV_Misc_Cape_19",        lootpage = "WorldBluesBack" },
    { name = L["Chest"],                            icon = "Interface\\Icons\\INV_Chest_Cloth_51",      lootpage = "WorldBluesChest" },
    { name = L["Wrist"],                            icon = "Interface\\Icons\\INV_Bracer_01",           lootpage = "WorldBluesWrist" },
    { name = L["Hands"],                            icon = "Interface\\Icons\\INV_Gauntlets_14",        lootpage = "WorldBluesHands" },
    { name = L["Waist"],                            icon = "Interface\\Icons\\INV_Belt_02",             lootpage = "WorldBluesWaist" },
    { name = L["Legs"],                             icon = "Interface\\Icons\\INV_Pants_01",            lootpage = "WorldBluesLegs" },
    { name = L["Feet"],                             icon = "Interface\\Icons\\INV_Boots_01",            lootpage = "WorldBluesFeet" },
    { name = L["Rings"],                            icon = "Interface\\Icons\\INV_Jewelry_Ring_13",     lootpage = "WorldBluesRing" },
    { name = L["Trinkets"],                         icon = "Interface\\Icons\\INV_Misc_EngGizmos_12",   lootpage = "WorldBluesTrinket" },
    { name = L["Wands"],                            icon = "Interface\\Icons\\INV_Wand_05",             lootpage = "WorldBluesWand" },
    { name = L["Off Hand"] .. " & " .. L["Relics"], icon = "Interface\\Icons\\INV_Misc_Book_06",        lootpage = "WorldBluesHeldInOffhand" },
    {},
    { name = L["One-Handed Axes"],                  icon = "Interface\\Icons\\INV_ThrowingAxe_01",      lootpage = "WorldBlues1HAxes" },
    { name = L["One-Handed Maces"],                 icon = "Interface\\Icons\\INV_Hammer_15",           lootpage = "WorldBlues1HMaces" },
    { name = L["One-Handed Swords"],                icon = "Interface\\Icons\\INV_Sword_05",            lootpage = "WorldBlues1HSwords" },
    { name = L["Two-Handed Axes"],                  icon = "Interface\\Icons\\INV_ThrowingAxe_06",      lootpage = "WorldBlues2HAxes" },
    { name = L["Two-Handed Maces"],                 icon = "Interface\\Icons\\INV_Hammer_17",           lootpage = "WorldBlues2HMaces" },
    { name = L["Two-Handed Swords"],                icon = "Interface\\Icons\\INV_Sword_23",            lootpage = "WorldBlues2HSwords" },
    { name = L["Daggers"],                          icon = "Interface\\Icons\\INV_Sword_33",            lootpage = "WorldBluesDaggers" },
    { name = L["Fist Weapons"],                     icon = "Interface\\Icons\\INV_Gauntlets_04",        lootpage = "WorldBluesFistWeapons" },
    { name = L["Polearms"],                         icon = "Interface\\Icons\\INV_Spear_05",            lootpage = "WorldBluesPolearms" },
    { name = L["Staves"],                           icon = "Interface\\Icons\\INV_Staff_29",            lootpage = "WorldBluesStaves" },
    { name = L["Bows"],                             icon = "Interface\\Icons\\INV_Weapon_Bow_02",       lootpage = "WorldBluesBows" },
    { name = L["Crossbows"],                        icon = "Interface\\Icons\\INV_Weapon_Crossbow_02",  lootpage = "WorldBluesCrossbows" },
    { name = L["Guns"],                             icon = "Interface\\Icons\\INV_Weapon_Rifle_07",     lootpage = "WorldBluesGuns" },
    { name = L["Shields"],                          icon = "Interface\\Icons\\INV_Shield_04",           lootpage = "WorldBluesShields" },
}

---
--- World blues menu function
--- @return nil
--- @usage AtlasLootWorldBluesMenu()
---
function AtlasLootWorldBluesMenu()
    Atlas.LootBrowserUI.PrepMenu(L["World Blues"], Atlas.MenuData.WorldBlues, L["Collections"])
end

---
--- Creates class-specific set menu data
--- @param class string - The class name (e.g., "Priest", "Mage")
--- @param color string - Color code for the class
--- @param icon string - Icon path for the class
--- @return table - Menu data table for the class
--- @usage local priestMenu = createClassSetMenu("Priest", Colors.Priest, "Interface\\Icons\\Spell_Holy_PowerWordShield")
---
local function createClassSetMenu(class, color, icon)
    local menuData = {
        { name = color .. class .. " " .. L["Tier 0/0.5 Sets"],          icon = icon, lootpage = "T0" .. class },
        { name = color .. class .. " " .. L["Tier 1 Sets"],              icon = icon, lootpage = "T1" .. class,   servers = { Atlas.Server.NOT_VANILLA_PLUS } },
        { name = color .. class .. " " .. L["Tier 1 Sets"] .. " (V+)",   icon = icon, lootpage = "T1VP" .. class, servers = { Atlas.Server.VANILLA_PLUS } },
        { name = color .. class .. " " .. L["Zul'Gurub Sets"],           icon = icon, lootpage = "ZG" .. class },
        { name = color .. class .. " " .. L["Ruins of Ahn'Qiraj Sets"],  icon = icon, lootpage = "AQ20" .. class },
        { name = color .. class .. " " .. L["Tier 2 Sets"],              icon = icon, lootpage = "T2" .. class },
        { name = color .. class .. " " .. L["Temple of Ahn'Qiraj Sets"], icon = icon, lootpage = "AQ40" .. class },
        { name = color .. class .. " " .. L["Tier 3 Sets"],              icon = icon, lootpage = "T3" .. class },
        { name = color .. class .. " " .. LMD["Tower of Karazhan Sets"], icon = icon, lootpage = "T35" .. class,  servers = { Atlas.Server.TURTLE } },
    }
    return menuData
end

Atlas.MenuData.Priest = createClassSetMenu("Priest", Colors.Priest, "Interface\\Icons\\Spell_Holy_PowerWordShield")
Atlas.MenuData.Mage = createClassSetMenu("Mage", Colors.Mage, "Interface\\Icons\\Spell_Frost_IceStorm")
Atlas.MenuData.Warlock = createClassSetMenu("Warlock", Colors.Warlock, "Interface\\Icons\\Spell_Shadow_CurseOfTounges")
Atlas.MenuData.Rogue = createClassSetMenu("Rogue", Colors.Rogue, "Interface\\Icons\\Ability_BackStab")
Atlas.MenuData.Druid = createClassSetMenu("Druid", Colors.Druid, "Interface\\Icons\\Spell_Nature_Regeneration")
Atlas.MenuData.Hunter = createClassSetMenu("Hunter", Colors.Hunter, "Interface\\Icons\\Ability_Hunter_RunningShot")
Atlas.MenuData.Shaman = createClassSetMenu("Shaman", Colors.Shaman, "Interface\\Icons\\Spell_FireResistanceTotem_01")
Atlas.MenuData.Paladin = createClassSetMenu("Paladin", Colors.Paladin, "Interface\\Icons\\Spell_Holy_SealOfMight")
Atlas.MenuData.Warrior = createClassSetMenu("Warrior", Colors.Warrior, "Interface\\Icons\\INV_Shield_05")

---
--- Priest sets menu function
--- @return nil
--- @usage AtlasLootPriestSetMenu()
---
function AtlasLootPriestSetMenu()
    Atlas.LootBrowserUI.PrepMenu(L["Priest Sets"], Atlas.MenuData.Priest, L["Collections"])
end

---
--- Mage sets menu function
--- @return nil
--- @usage AtlasLootMageSetMenu()
---
function AtlasLootMageSetMenu()
    Atlas.LootBrowserUI.PrepMenu(L["Mage Sets"], Atlas.MenuData.Mage, L["Collections"])
end

---
--- Warlock sets menu function
--- @return nil
--- @usage AtlasLootWarlockSetMenu()
---
function AtlasLootWarlockSetMenu()
    Atlas.LootBrowserUI.PrepMenu(L["Warlock Sets"], Atlas.MenuData.Warlock, L["Collections"])
end

---
--- Rogue sets menu function
--- @return nil
--- @usage AtlasLootRogueSetMenu()
---
function AtlasLootRogueSetMenu()
    Atlas.LootBrowserUI.PrepMenu(L["Rogue Sets"], Atlas.MenuData.Rogue, L["Collections"])
end

---
--- Druid sets menu function
--- @return nil
--- @usage AtlasLootDruidSetMenu()
---
function AtlasLootDruidSetMenu()
    Atlas.LootBrowserUI.PrepMenu(L["Druid Sets"], Atlas.MenuData.Druid, L["Collections"])
end

---
--- Hunter sets menu function
--- @return nil
--- @usage AtlasLootHunterSetMenu()
---
function AtlasLootHunterSetMenu()
    Atlas.LootBrowserUI.PrepMenu(L["Hunter Sets"], Atlas.MenuData.Hunter, L["Collections"])
end

---
--- Shaman sets menu function
--- @return nil
--- @usage AtlasLootShamanSetMenu()
---
function AtlasLootShamanSetMenu()
    Atlas.LootBrowserUI.PrepMenu(L["Shaman Sets"], Atlas.MenuData.Shaman, L["Collections"])
end

---
--- Paladin sets menu function
--- @return nil
--- @usage AtlasLootPaladinSetMenu()
---
function AtlasLootPaladinSetMenu()
    Atlas.LootBrowserUI.PrepMenu(L["Paladin Sets"], Atlas.MenuData.Paladin, L["Collections"])
end

---
--- Warrior sets menu function
--- @return nil
--- @usage AtlasLootWarriorSetMenu()
---
function AtlasLootWarriorSetMenu()
    Atlas.LootBrowserUI.PrepMenu(L["Warrior Sets"], Atlas.MenuData.Warrior, L["Collections"])
end

Atlas.MenuData.Pre60Sets = {
    { name = LIS["Defias Leather"],                 extra = "The Deadmines",         icon = "Interface\\Icons\\INV_Pants_12",                 lootpage = "Deadmines" },
    { name = LIS["Embrace of the Viper"],           extra = "Wailing Caverns",       icon = "Interface\\Icons\\INV_Shirt_16",                 lootpage = "Wailing" },
    { name = LIS["Sacred Windhorn Attire"],         extra = "Windhorn Canyon",       icon = "Interface\\Icons\\INV_Shoulder_07",              lootpage = "SacredWindhorn",       servers = { Atlas.Server.TURTLE } },
    { name = LIS["Dragonmaw Battlegarb"],           extra = "Dragonmaw Retreat",     icon = "Interface\\Icons\\INV_misc_bone_taurenskull_01", lootpage = "DragonmawBattlegarb",  servers = { Atlas.Server.TURTLE } },
    { name = LIS["Chain of the Scarlet Crusade"],   extra = "Scarlet Monastery",     icon = "Interface\\Icons\\INV_Gauntlets_19",             lootpage = "Scarlet" },
    { name = LIS["Stormreaver Attire"],             extra = "Stormwrought Ruins",    icon = "Interface\\Icons\\INV_Gauntlets_09",             lootpage = "Stormreaver",          servers = { Atlas.Server.TURTLE } },
    { name = LIS["Greymane Armor"],                 extra = "Gilneas City",          icon = "Interface\\Icons\\inv_helmet_02",                lootpage = "GreymaneArmor",        servers = { Atlas.Server.TURTLE1 } },
    { name = LIS["Incendosaur Skin Armor"],         extra = "Hateforge Quarry",      icon = "Interface\\Icons\\INV_Shoulder_23",              lootpage = "IncendosaurSkinArmor", servers = { Atlas.Server.TURTLE1 } },
    { name = LIS["The Gladiator"],                  extra = "Blackrock Depths",      icon = "Interface\\Icons\\INV_Helmet_01",                lootpage = "TheGladiator" },
    { name = LIS["Ironweave Battlesuit"],           Extra = L["Various Locations"],  icon = "Interface\\Icons\\INV_Boots_Cloth_05",           lootpage = "Ironweave" },
    { name = LIS["The Postmaster"],                 extra = "Stratholme",            icon = "Interface\\Icons\\INV_Boots_02",                 lootpage = "Strat" },
    { name = LZ["Scholomance"] .. " " .. L["Sets"], extra = "Scholomance",           icon = "Interface\\Icons\\INV_Shoulder_02",              lootpage = "Scholo" },
    { name = L["Scourge Invasion"],                 Extra = L["Various Locations"],  icon = "Interface\\Icons\\INV_Jewelry_Talisman_13",      lootpage = "ScourgeInvasion" },
    { name = LIS["Arms of Thaurissan"],             Extra = L["Various Locations"],  icon = "Interface\\Icons\\spell_fire_flametounge",       lootpage = "ArmsofThaurissan",     servers = { Atlas.Server.TURTLE } }, --MoltenCore and BRD
    {},
    { name = LIS["Spider's Kiss"],                  extra = "Lower Blackrock Spire", icon = "Interface\\Icons\\INV_Weapon_ShortBlade_16",     lootpage = "SpiderKiss" },
    { name = LIS["Dal'Rend's Arms"],                extra = "Upper Blackrock Spire", icon = "Interface\\Icons\\INV_Sword_43",                 lootpage = "DalRend" },
    { name = LIS["Shard of the Gods"],              Extra = L["Various Locations"],  icon = "Interface\\Icons\\INV_Misc_MonsterScales_15",    lootpage = "ShardOfGods" },
    { name = LIS["Spirit of Eskhandar"],            Extra = L["Various Locations"],  icon = "Interface\\Icons\\INV_Misc_MonsterClaw_04",      lootpage = "SpiritofEskhandar" },
}

---
--- Pre-60 sets menu function
--- @return nil
--- @usage AtlasLootPRE60SetMenu()
---
function AtlasLootPRE60SetMenu()
    Atlas.LootBrowserUI.PrepMenu(L["Pre 60 Sets"], Atlas.MenuData.Pre60Sets, L["Collections"])
end

---
--- Creates dungeon-specific set menu data for all classes
--- @param dungeonName string - The dungeon prefix (e.g., "ZG", "AQ40", "T1")
--- @return table - Menu data table with class-specific entries
--- @usage local zgMenu = CreateDungeonSetMenu("ZG")
---
local function CreateDungeonSetMenu(dungeonName)
    local menuData = {}
    local classData = {
        {},
        {},
        { name = "Priest",  color = Colors.Priest,  icon = "Interface\\Icons\\Spell_Holy_PowerWordShield" },
        { name = "Mage",    color = Colors.Mage,    icon = "Interface\\Icons\\Spell_Frost_IceStorm" },
        { name = "Warlock", color = Colors.Warlock, icon = "Interface\\Icons\\Spell_Shadow_CurseOfTounges" },
        { name = "Rogue",   color = Colors.Rogue,   icon = "Interface\\Icons\\Ability_BackStab" },
        { name = "Druid",   color = Colors.Druid,   icon = "Interface\\Icons\\Spell_Nature_Regeneration" },
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        {},
        { name = "Hunter",  color = Colors.Hunter,  icon = "Interface\\Icons\\Ability_Hunter_RunningShot" },
        { name = "Shaman",  color = Colors.Shaman,  icon = "Interface\\Icons\\Spell_FireResistanceTotem_01" },
        { name = "Paladin", color = Colors.Paladin, icon = "Interface\\Icons\\Spell_Holy_SealOfMight" },
        { name = "Warrior", color = Colors.Warrior, icon = "Interface\\Icons\\INV_Shield_05" },
    }

    for i, classInfo in ipairs(classData) do
        if classInfo.name then
            local lootpage = dungeonName .. classInfo.name
            -- local container = data[lootpage .. "C"]
            if data[lootpage] then
                menuData[i] = {
                    name = classInfo.color .. LC[classInfo.name],
                    icon = classInfo.icon,
                    lootpage = lootpage,
                    -- container = container
                }
            end
        end
    end
    return menuData
end
Atlas.MenuData.ZGSet = CreateDungeonSetMenu("ZG")
Atlas.MenuData.ZGSet[23] = {
    name = L["Zul'Gurub Rings"],
    icon = "Interface\\Icons\\INV_Jewelry_Ring_46",
    lootpage =
    "ZGRings"
}
Atlas.MenuData.ZGSet[24] = {
    name = LIS["Primal Blessing"],
    icon = "Interface\\Icons\\INV_Weapon_Hand_01",
    lootpage =
    "PrimalBlessing"
}
Atlas.MenuData.ZGSet[25] = {
    name = LIS["The Twin Blades of Hakkari"],
    icon = "Interface\\Icons\\INV_Sword_55",
    lootpage =
    "HakkariBlades"
}
Atlas.MenuData.AQ40Set = CreateDungeonSetMenu("AQ40")
Atlas.MenuData.AQ20Set = CreateDungeonSetMenu("AQ20")
Atlas.MenuData.T0Set = CreateDungeonSetMenu("T0")
Atlas.MenuData.T1Set = CreateDungeonSetMenu("T1")
Atlas.MenuData.T1VPSet = CreateDungeonSetMenu("T1VP")
Atlas.MenuData.T1VPSet[23] = {
    name = LF["Thorium Brotherhood"],
    icon = "Interface\\Icons\\INV_Ingot_Mithril",
    lootpage =
    "ThoriumBrotherhood"
}
Atlas.MenuData.T2Set = CreateDungeonSetMenu("T2")
Atlas.MenuData.T3Set = CreateDungeonSetMenu("T3")
Atlas.MenuData.T35Set = CreateDungeonSetMenu("T35")

---
--- Zul'Gurub sets menu function
--- @return nil
--- @usage AtlasLootZGSetMenu()
---
function AtlasLootZGSetMenu()
    Atlas.LootBrowserUI.PrepMenu(L["Zul'Gurub Sets"], Atlas.MenuData.ZGSet, L["Collections"])
end

---
--- Temple of Ahn'Qiraj sets menu function
--- @return nil
--- @usage AtlasLootAQ40SetMenu()
---
function AtlasLootAQ40SetMenu()
    Atlas.LootBrowserUI.PrepMenu(L["Temple of Ahn'Qiraj Sets"], Atlas.MenuData.AQ40Set, L["Collections"])
end

---
--- Ruins of Ahn'Qiraj sets menu function
--- @return nil
--- @usage AtlasLootAQ20SetMenu()
---
function AtlasLootAQ20SetMenu()
    Atlas.LootBrowserUI.PrepMenu(L["Ruins of Ahn'Qiraj Sets"], Atlas.MenuData.AQ20Set, L["Collections"])
end

---
--- Tier 0/0.5 sets menu function
--- @return nil
--- @usage AtlasLootT0SetMenu()
---
function AtlasLootT0SetMenu()
    Atlas.LootBrowserUI.PrepMenu(L["Tier 0/0.5 Sets"], Atlas.MenuData.T0Set, L["Collections"])
end

---
--- Tier 1 sets menu function
--- @return nil
--- @usage AtlasLootT1SetMenu()
---
function AtlasLootT1SetMenu()
    Atlas.LootBrowserUI.PrepMenu(L["Tier 1 Sets"], Atlas.MenuData.T1Set, L["Collections"])
end

---
--- Tier 1 Vanilla+ sets menu function
--- @return nil
--- @usage AtlasLootT1VPSetMenu()
---
function AtlasLootT1VPSetMenu()
    Atlas.LootBrowserUI.PrepMenu(L["Tier 1 Sets"] .. " (V+)", Atlas.MenuData.T1VPSet, L["Collections"])
end

---
--- Tier 2 sets menu function
--- @return nil
--- @usage AtlasLootT2SetMenu()
---
function AtlasLootT2SetMenu()
    Atlas.LootBrowserUI.PrepMenu(L["Tier 2 Sets"], Atlas.MenuData.T2Set, L["Collections"])
end

---
--- Tier 3 sets menu function
--- @return nil
--- @usage AtlasLootT3SetMenu()
---
function AtlasLootT3SetMenu()
    Atlas.LootBrowserUI.PrepMenu(L["Tier 3 Sets"], Atlas.MenuData.T3Set, L["Collections"])
end

---
--- Tower of Karazhan sets menu function
--- @return nil
--- @usage AtlasLootT35SetMenu()
---
function AtlasLootT35SetMenu()
    Atlas.LootBrowserUI.PrepMenu(LMD["Tower of Karazhan Sets"], Atlas.MenuData.T35Set, L["Collections"])
end
