---
--- LocalizationFramework.lua - Core Localization System
---
--- Simplified and robust localization system.
---

local _G = getfenv()

Atlas = _G.Atlas or {}

if not Atlas.Localization then
    Atlas.Localization = {
        currentLocale = (GetLocale and GetLocale() or "enUS"),
        namespaces = {}
    }
end

---
--- Debug function to check loaded translations
---
function Atlas.Localization:DebugPrint()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Atlas Localization Debug:|r")
    DEFAULT_CHAT_FRAME:AddMessage("Current Locale: " .. tostring(self.currentLocale))

    for name, data in pairs(self.namespaces) do
        local enCount = 0
        local curCount = 0
        if data.enUS then
            for _ in pairs(data.enUS) do enCount = enCount + 1 end
        end
        if data.current then
            for _ in pairs(data.current) do curCount = curCount + 1 end
        end
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  - %s: enUS=%d, current=%d", name, enCount, curCount))
    end
end

function Atlas.Localization:DebugMissing(limit)
    local frame = DEFAULT_CHAT_FRAME
    local out = function(msg) if frame then frame:AddMessage(msg) else PrintA(msg) end end
    limit = tonumber(limit) or 40
    out("|cff00ff00Atlas Missing Keys:|r " .. tostring(self.currentLocale))
    for name, ns in pairs(self.namespaces) do
        local missing = {}
        local en = ns.enUS or {}
        local cur = ns.current or {}
        for k, _ in pairs(en) do
            if cur[k] == nil then table.insert(missing, k) end
        end
        out("  " .. name .. ": missing=" .. tostring(table.getn(missing)))
        if table.getn(missing) > 0 then
            local list = {}
            local n = math.min(limit, table.getn(missing))
            for i = 1, n do list[i] = missing[i] end
            out("    " .. table.concat(list, ", "))
        end
    end
end

---
--- Register a new localization namespace
---
function Atlas.Localization:RegisterNamespace(namespace, locale, translations)
    if not self.namespaces[namespace] then
        self.namespaces[namespace] = {
            enUS = {},
            current = {}
        }
    end

    local ns = self.namespaces[namespace]

    -- Always load enUS as fallback
    if locale == "enUS" then
        for k, v in pairs(translations) do
            ns.enUS[k] = v
        end
    end

    -- Load current locale if it matches
    if locale == self.currentLocale then
        for k, v in pairs(translations) do
            ns.current[k] = v
        end
    end
end

---
--- Get a namespace for use
---
function Atlas.Localization:GetNamespace(namespace)
    if not self.namespaces[namespace] then
        -- Initialize if accessed before registration
        self:RegisterNamespace(namespace, "enUS", {})
    end

    local t = {}
    local ns_data = self.namespaces[namespace]

    setmetatable(t, {
        __index = function(tab, key)
            -- 1. Try current locale
            local val = ns_data.current[key]
            if val then
                if val == true then return key end
                return val
            end

            -- 2. Try enUS fallback
            val = ns_data.enUS[key]
            if val then
                if val == true then return key end
                return val
            end

            -- 3. Return key (fallback)
            return key
        end
    })

    return t
end

-- Define standard namespaces
Atlas.Localization.UI = Atlas.Localization:GetNamespace("UI")
Atlas.Localization.Zones = Atlas.Localization:GetNamespace("Zones")
Atlas.Localization.Bosses = Atlas.Localization:GetNamespace("Bosses")
Atlas.Localization.Classes = Atlas.Localization:GetNamespace("Classes")
Atlas.Localization.Factions = Atlas.Localization:GetNamespace("Factions")
Atlas.Localization.Spells = Atlas.Localization:GetNamespace("Spells")
Atlas.Localization.ItemSets = Atlas.Localization:GetNamespace("ItemSets")
Atlas.Localization.MapData = Atlas.Localization:GetNamespace("MapData")
