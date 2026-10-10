---
--- LadyHederine.lua - Lady Hederine world boss loot data
---
--- This module contains comprehensive loot data for Lady Hederine, the demon
--- world boss located in the Winterspring. It includes rare drops,
--- epic equipment, and unique demonic items.
---
--- Features:
--- • Complete Lady Hederine loot table
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

-- World boss Lady Hederine data
Atlas.InstanceData.LadyHederine = {
    servers = { Atlas.Server.VANILLA_PLUS },
    Name = LB["Lady Hederine"],
    Location = LZ["Winterspring"],
    Level = { 1, 60 },
    Acronym = "LadyHederine",
    MaxPlayers = 40,
    DamageType = L["Nature"],
    Bosses = {
        {
            id = "WBLadyHederine",
            prefix = "1)",
            name = LB["Lady Hederine"],
            defaults = { dropRate = 17 },
            loot = {
                { id = 26127 }, -- Soul Shard Pendant
                { id = 26128 }, -- Hederine Whipping Belt
                { id = 26129 }, -- Helm of the Fallen Hero
                { id = 26130 }, -- Hederine Shackles
                { id = 26131 }, -- Gyves of Perdition
                { id = 26132 }, -- Sayaad Wings
                { id = 26133 }, -- Ring of Suffering
                { id = 26134 }, -- Demonic Claw
            }
        }
    },
}

-- Item initialization for all bosses
for _, bossData in ipairs(Atlas.InstanceData.LadyHederine.Bosses) do
    bossData.items = bossData.items or Atlas.CreateItemsFromLootTable(bossData)
    bossData.loot = nil -- Clear temporary data
end
