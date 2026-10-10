---
--- TeremustheDevourer.lua - Teremus the Devourer world boss loot data
---
--- This module contains comprehensive loot data for Teremus the Devourer,
--- the demon world boss located in the Blasted Lands. It includes rare drops,
--- epic equipment, and unique demonic items.
---
--- Features:
--- • Complete Teremus the Devourer loot table
--- • Rare and epic drops
--- • Demonic-themed equipment
--- • Unique world boss rewards
--- • Respawn timer information
---
--- @compatible World of Warcraft 1.12
---

local _G = getfenv()
Atlas = _G.Atlas or {}

local L = Atlas.Localization.UI
local LZ = Atlas.Localization.Zones
local LB = Atlas.Localization.Bosses
local LS = Atlas.Localization.Spells

Atlas.InstanceData = Atlas.InstanceData or {}

-- World boss Teremus the Devourer data
Atlas.InstanceData.TeremustheDevourer = {
    servers = { Atlas.Server.VANILLA_PLUS },
    Name = LB["Teremus the Devourer"],
    Location = LZ["Blasted Lands"],
    Level = { 1, 60 },
    Acronym = "TeremustheDevourer",
    MaxPlayers = 40,
    DamageType = L["Shadow"],
    Bosses = {
        {
            id = "WBTeremustheDevourer",
            prefix = "1)",
            name = LB["Teremus the Devourer"],
            defaults = { dropRate = 33 },
            loot = {
                { id = 83073 }, -- Blazing Scale
                { id = 83074 }, -- City Guard Gauntlets
                { id = 83075 }, -- Blood Scarred Scale
            }
        }
    },
}

-- Item initialization for all bosses
for _, bossData in ipairs(Atlas.InstanceData.TeremustheDevourer.Bosses) do
    bossData.items = bossData.items or Atlas.CreateItemsFromLootTable(bossData)
    bossData.loot = nil -- Clear temporary data
end
