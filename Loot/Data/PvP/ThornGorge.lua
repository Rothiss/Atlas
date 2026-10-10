---
--- ThornGorge.lua - Thorn Gorge battleground PvP data
---
--- This module contains comprehensive PvP data for the Thorn Gorge
--- battleground. It includes resource control objectives, strategic nodes,
--- capture points, and battleground-specific rewards.
---
--- Features:
--- • PvP rewards and marks
---
--- @compatible World of Warcraft 1.12
---

local _G = getfenv()
Atlas = _G.Atlas or {}

local LZ = Atlas.Localization.Zones
local LF = Atlas.Localization.Factions
local LMD = Atlas.Localization.MapData

Atlas.InstanceData = Atlas.InstanceData or {}

-- Thorn Gorge battleground database
Atlas.InstanceData.BGThornGorge = {
    servers = { Atlas.Server.TURTLE },
    Name = LZ["Thorn Gorge"],
    Location = LZ["Thousand Needles"], --TODO check
    Level = { 20, 60 },                --TODO check
    Acronym = "TG",
    MaxPlayers = 15,
    Reputation = {
        -- { name = LF["The League of Arathor"].." \\ "..LF["The Defilers"], loot = "ArathorDefilers" },
    },
    Entrances = {
        -- { letter = "A)", info = LMD["Trollbane Hall"] .. " (A)" },
        -- { letter = "B)", info = LMD["Defiler's Den"] .. " (H)" }
    },
    Bosses = {}
}
