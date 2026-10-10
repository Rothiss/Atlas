---
--- Concavius.lua - Concavius world boss loot data
---
--- This module contains comprehensive loot data for Concavius, a special
--- world boss encounter. It includes unique drops, rare equipment,
--- and boss-specific rewards from this elite encounter.
---
--- Features:
--- • Complete Concavius loot table
--- • Rare and epic drops
--- • Boss-specific equipment
--- • Unique world boss rewards
--- • Encounter mechanics data
---
--- @compatible World of Warcraft 1.12
---

local _G = getfenv()
Atlas = _G.Atlas or {}

local L = Atlas.Localization.UI
local LZ = Atlas.Localization.Zones
local LB = Atlas.Localization.Bosses

Atlas.InstanceData = Atlas.InstanceData or {}

-- World bosses data
Atlas.InstanceData.Concavius = {
    Servers = { Atlas.Server.TURTLE1 },
    Name = LB["Concavius"],
    Location = LZ["Desolace"],
    Level = { 1, 60 },
    Acronym = "Concavius",
    MaxPlayers = 40,
    DamageType = L["Shadow"],
    Bosses = {
        {
            id = "WBConcavius",
            prefix = "1)",
            name = LB["Concavius"],
            defaults = { dropRate = 17 },
            loot = {
                { id = 83233 },                                                                                                -- Charm of Dark Domination
                { id = 83234 },                                                                                                -- Voidclaw Choker
                { id = 83237 },                                                                                                -- Band of Ancient Lethality
                { id = 83238 },                                                                                                -- Ring of the Abyss Watcher
                { id = 83239 },                                                                                                -- Signet of the Voidwalker
                { id = 83240 },                                                                                                -- Ring of the Whispering Mist
                {},
                {
                    id = 83236,
                    disc = L["Container"],
                    dropRate = 100,
                    container = { 7076, 7078, 7080, 7082, 7971, 12361, 12363,                                                  -- Void-Linked Satchel of Goods
                        12364, 12800, 11370, 13468, 14256, 15416, 20520 }
                },                                                                                                             -- Void-Linked Satchel of Goods
            }
        }
    }
}

-- Item initialization for all bosses
for _, bossData in ipairs(Atlas.InstanceData.Concavius.Bosses) do
    bossData.items = bossData.items or Atlas.CreateItemsFromLootTable(bossData)
    bossData.loot = nil -- Clear temporary data
end
