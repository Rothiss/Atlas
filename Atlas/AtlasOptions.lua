---
--- AtlasOptions.lua - Atlas configuration and options management
---
--- This file contains the options and configuration system for Atlas.
--- It handles user preferences, settings persistence, UI customization,
--- and provides the interface for configuring Atlas behavior and appearance.
---
--- Features:
--- - Options frame and UI management
--- - Settings persistence and loading
--- - User preference handling
--- - Configuration validation
--- - Default settings management
---
--- @compatible World of Warcraft 1.12
---

-- Local references to global functions for performance
local _G                            = getfenv()
local Atlas                      = _G.Atlas

local L                             = Atlas.Localization.UI

local uIDropDownMenu_SetSelectedID  = UIDropDownMenu_SetSelectedID

---------------
--- COLOURS ---
---------------
local red                           = Atlas.Colors.RED
local blue                          = Atlas.Colors.BLUE

-- Local variables for frequently used UI elements
local atlasOptionsFrame, atlasFrame = AtlasOptionsFrame, AtlasFrame

--- Rounds a number to specified decimal places
--- @param num number The number to round
--- @param idp number|nil Number of decimal places (default: 0)
--- @return number The rounded number
--- @usage local rounded = round(3.14159, 2) -- returns 3.14
local function round(num, idp)
    local mult = 10 ^ (idp or 0)
    return math.floor(num * mult + 0.5) / mult
end



--- Toggles the bottom loot panel visibility
--- Updates AtlasOptions.LootShowPanel and shows/hides AtlasLootPanel
--- @return nil
--- @usage Atlas.OptionShowPanelOnClick()
---
function Atlas.OptionShowPanelOnClick()
    local showPanelStatus = AtlasOptions.LootShowPanel
    AtlasOptions.LootShowPanel = not showPanelStatus
    if showPanelStatus then
        AtlasLootPanel:Hide()
    else
        AtlasLootPanel:Show()
    end
    AtlasOptionShowPanel:SetChecked(AtlasOptions.LootShowPanel)
    Atlas.OptionsInit()
end

--- Toggles loot filtering mode
--- Cycles through 0: All, 1: My Class, 2: Available
--- @return nil
function Atlas.OptionFilterModeOnClick()
    if not AtlasOptions.LootFilterMode then
        AtlasOptions.LootFilterMode = 0
    end
    AtlasOptions.LootFilterMode = math.mod(AtlasOptions.LootFilterMode + 1, 3)

    -- Update UI if button exists
    if AtlasLootFilterButton then
        local filterText = ""
        if AtlasOptions.LootFilterMode == 0 then
            filterText = L["Filter: No Filter"]
        elseif AtlasOptions.LootFilterMode == 1 then
            filterText = L["Filter: My Class"]
        elseif AtlasOptions.LootFilterMode == 2 then
            filterText = L["Filter: Available"]
        end
        AtlasLootFilterButton:SetText(filterText)
    end

    -- Refresh loot display
    if Atlas.LootBrowserUI and Atlas.LootBrowserUI.ScrollBarLootUpdate then
        Atlas.LootBrowserUI.ScrollBarLootUpdate()
        Atlas.Quest.UI.InsideAtlasFrame:Hide()
    end
end

---
--- Toggles the visibility of the Atlas options frame
--- Shows or hides the options panel and refreshes tooltip settings
--- @return nil
--- @usage Atlas.OptionsOnClick() -- Called by options button click
---
function Atlas.OptionsOnClick()
    if atlasOptionsFrame:IsVisible() then
        atlasOptionsFrame:Hide()
    else
        atlasOptionsFrame:Show()
    end
end

---
--- Toggles the auto-select feature for Atlas maps
--- Enables or disables automatic map selection based on player location
--- @return nil
--- @usage Atlas.OptionsAutoSelectOnClick() -- Called by checkbox click
---
function Atlas.OptionsAutoSelectOnClick()
    AtlasOptions.AtlasAutoSelect = not AtlasOptions.AtlasAutoSelect
    Atlas.OptionsInit()
end

---
--- Toggles the world map right-click integration feature
--- Enables or disables Atlas opening on world map right-click
--- @return nil
--- @usage Atlas.OptionsWorldMapOnClick() -- Called by checkbox click
---
function Atlas.OptionsWorldMapOnClick()
    AtlasOptions.AtlasRightClick = not AtlasOptions.AtlasRightClick
    Atlas.OptionsInit()
end

---
--- Toggles the display of instance acronyms in Atlas
--- Shows or hides abbreviated instance names and refreshes display
--- @return nil
--- @usage Atlas.OptionsAcronymsOnClick() -- Called by checkbox click
---
function Atlas.OptionsAcronymsOnClick()
    AtlasOptions.AtlasAcronyms = not AtlasOptions.AtlasAcronyms
    Atlas.OptionsInit()
    Atlas.Refresh()
end

--- Toggles clamping Atlas frame to the screen
--- Updates AtlasOptions.AtlasClamped and refreshes the UI
--- @return nil
--- @usage Atlas.OptionsClampedOnClick()
---
function Atlas.OptionsClampedOnClick()
    AtlasOptions.AtlasClamped = not AtlasOptions.AtlasClamped
    atlasFrame:SetClampedToScreen(AtlasOptions.AtlasClamped)
    Atlas.OptionsInit()
    Atlas.Refresh()
end

---
--- Toggles showing cursor coordinates on the Atlas map
--- Updates AtlasOptions.AtlasCursorCoords and shows/hides the overlay
--- @return nil
--- @usage Atlas.OptionsCursorCoordsOnClick() -- Called by checkbox click
---
function Atlas.OptionsCursorCoordsOnClick()
    AtlasOptions.AtlasCursorCoords = not AtlasOptions.AtlasCursorCoords
    -- Cursor coordinate overlay is rendered by the World Map OnUpdate in AtlasUI.lua
    if AtlasOptionCursorCoords then
        AtlasOptionCursorCoords:SetChecked(AtlasOptions.AtlasCursorCoords)
    end
end

---
--- Handles toggle of pfUI styling option
--- Enables or disables pfUI integration styling
--- @return nil
--- @usage Called when user clicks pfUI styling checkbox
---
function Atlas.OptionsPfUIOnClick()
    AtlasOptions.pfUIEnabled = not AtlasOptions.pfUIEnabled
    if AtlasOptionPfUI then
        AtlasOptionPfUI:SetChecked(AtlasOptions.pfUIEnabled)
    end

    -- Inform user that UI reload is required
    if AtlasOptions.pfUIEnabled then
        PrintA(L["pfUI styling enabled. Type /reload to apply changes."])
    else
        PrintA(L["pfUI styling disabled. Type /reload to apply changes."])
    end
end

---
--- Toggles map markers display
--- Enables or disables icons on the World Map
--- @return nil
--- @usage Atlas.OptionMapMarkersOnClick() -- Called by checkbox click
---
function Atlas.OptionMapMarkersOnClick()
    AtlasOptions.ShowMapMarkers = not AtlasOptions.ShowMapMarkers
    if AtlasOptionMapMarkers then
        AtlasOptionMapMarkers:SetChecked(AtlasOptions.ShowMapMarkers)
    end

    if Atlas.MapMarkers and Atlas.MapMarkers.UpdateMarkers then
        Atlas.MapMarkers.UpdateMarkers()
    end
end

---
--- Initializes all Atlas option settings and UI elements
--- Sets checkbox states, slider values, and frame visibility based on saved options
--- @return nil
--- @usage Atlas.OptionsInit() -- Called after option changes
---
function Atlas.OptionsInit()
    if not AtlasOptions then
        PrintA("Failed to initialize local references.")
        return
    end

    -- Ensure Reagent options exist for old configs
    if AtlasOptions.ReagentRows == nil then AtlasOptions.ReagentRows = 20 end
    if AtlasOptions.ReagentProfessions == nil then
        AtlasOptions.ReagentProfessions = {
            ["Alchemy"] = true,
            ["Blacksmithing"] = true,
            ["Enchanting"] = true,
            ["Engineering"] = true,
            ["Leatherworking"] = true,
            ["Tailoring"] = true,
            ["Cooking"] = true,
            ["First Aid"] = true,
            ["Jewelcrafting"] = true,
            ["Poisons"] = true,
            ["Mining"] = true,
            ["Survival"] = true,
        }
    end
    if AtlasOptions.ProfessionInfo == nil then AtlasOptions.ProfessionInfo = false end

    if AtlasOptions.QuestWithAtlas then
        Atlas.Quest.UI_Main.Frame:Show()
    else
        Atlas.Quest.UI_Main.Frame:Hide()
    end
    -- Consult the saved variable table to see whether to show the bottom panel
    if AtlasOptions.LootShowPanel then
        AtlasLootPanel:Show()
    else
        AtlasLootPanel:Hide()
    end
    -- Set values on load
    if AtlasOptionToggleButton then AtlasOptionToggleButton:SetChecked(AtlasOptions.AtlasButtonShown) end
    if AtlasOptionAutoSelect then AtlasOptionAutoSelect:SetChecked(AtlasOptions.AtlasAutoSelect) end
    if AtlasOptionRightClick then AtlasOptionRightClick:SetChecked(AtlasOptions.AtlasRightClick) end
    if AtlasOptionAcronyms then AtlasOptionAcronyms:SetChecked(AtlasOptions.AtlasAcronyms) end
    if AtlasOptionClamped then AtlasOptionClamped:SetChecked(AtlasOptions.AtlasClamped) end
    if AtlasOptionCursorCoords then AtlasOptionCursorCoords:SetChecked(AtlasOptions.AtlasCursorCoords) end

    -- pfUI option (only show if pfUI is loaded)
    if IsAddOnLoaded("pfUI") and AtlasOptionPfUI then
        AtlasOptionPfUI:SetChecked(AtlasOptions.pfUIEnabled)
    elseif AtlasOptionPfUI then
        -- Hide the checkbox if pfUI is not loaded
        AtlasOptionPfUI:Hide()
        _G[AtlasOptionPfUI:GetName() .. "Text"]:Hide()
    end

    if AtlasOptionSliderButtonPos then AtlasOptionSliderButtonPos:SetValue(AtlasOptions.AtlasButtonPosition) end
    if AtlasOptionSliderButtonRad then AtlasOptionSliderButtonRad:SetValue(AtlasOptions.AtlasButtonRadius) end
    if AtlasOptionSliderAlpha then AtlasOptionSliderAlpha:SetValue(AtlasOptions.AtlasAlpha) end
    if AtlasOptionSliderScale then AtlasOptionSliderScale:SetValue(AtlasOptions.AtlasScale) end

    if AtlasOptionMapMarkers then AtlasOptionMapMarkers:SetChecked(AtlasOptions.ShowMapMarkers) end

    -- Quest Options
    if AtlasOptionAutoshow then AtlasOptionAutoshow:SetChecked(AtlasOptions.QuestWithAtlas) end
    if AtlasOptionLeftSide then AtlasOptionLeftSide:SetChecked(AtlasOptions.QuestCurrentSide) end

    local function IsPfUIStylingEnabled()
        return IsAddOnLoaded("pfUI") and pfUI and (not AtlasOptions or AtlasOptions.pfUIEnabled ~= false)
    end

    if IsPfUIStylingEnabled() then
        Atlas.Quest.UI_Main.Frame:ClearAllPoints()
        if AtlasOptionLeftSide and AtlasOptionLeftSide:GetChecked() then
            Atlas.Quest.UI_Main.Frame:SetPoint("TOPRIGHT", "AtlasFrame", "TOPLEFT", -1, 0)
        else
            Atlas.Quest.UI_Main.Frame:SetPoint("TOPLEFT", "AtlasFrame", "TOPRIGHT", 1, 0)
        end
    else
        if AtlasOptionLeftSide and AtlasOptionLeftSide:GetChecked() then
            Atlas.Quest.UI_Main.Frame:SetPoint("TOP", "AtlasFrame", -556, -36)
        else
            Atlas.Quest.UI_Main.Frame:SetPoint("TOP", "AtlasFrame", 567, -36)
        end
    end
    if AtlasOptionColor then AtlasOptionColor:SetChecked(AtlasOptions.QuestColourCheck) end
    if AtlasOptionQuestlog then AtlasOptionQuestlog:SetChecked(AtlasOptions.QuestCheckQuestlog) end
    if AtlasOptionAutoQuery then AtlasOptionAutoQuery:SetChecked(AtlasOptions.QuestAutoQuery) end

    -- Loot Options
    if AtlasOptionShowSource then AtlasOptionShowSource:SetChecked(AtlasOptions.LootShowSource) end
    if AtlasOptionEquipCompare then AtlasOptionEquipCompare:SetChecked(AtlasOptions.LootEquipCompare) end
    if AtlasOptionOpaque then AtlasOptionOpaque:SetChecked(AtlasOptions.LootOpaque) end
    if AtlasOptionShowPanel then AtlasOptionShowPanel:SetChecked(AtlasOptions.LootShowPanel) end
    if AtlasOptionTooltipID then AtlasOptionTooltipID:SetChecked(AtlasOptions.TooltipShowID) end
    if AtlasOptionTooltipIcon then AtlasOptionTooltipIcon:SetChecked(AtlasOptions.TooltipShowIcon) end

    -- Update Loot Filter button text
    if AtlasLootFilterButton then
        local filterText = ""
        local mode = AtlasOptions.LootFilterMode or 0
        if mode == 0 then
            filterText = L["Filter: No Filter"]
        elseif mode == 1 then
            filterText = L["Filter: My Class"]
        elseif mode == 2 then
            filterText = L["Filter: Available"]
        end
        AtlasLootFilterButton:SetText(filterText)
    end

    -- Update Server label
    if Atlas.HewdropMenus and Atlas.HewdropMenus.UpdateServerLabel then
        Atlas.HewdropMenus.UpdateServerLabel()
    end
end

---
--- Resets Atlas frame position and related settings to defaults
--- Clears frame anchors and restores default button position, radius, alpha, and scale
--- @return nil
--- @usage Atlas.OptionResetPosition() -- Called by reset button
---
function Atlas.OptionResetPosition()
    atlasFrame:ClearAllPoints()
    atlasFrame:SetPoint("TOP", 0, -104)

    -- Reset settings to default values
    AtlasOptions.AtlasButtonPosition = 305
    AtlasOptions.AtlasButtonRadius = 76
    AtlasOptions.AtlasAlpha = 1.0
    AtlasOptions.AtlasScale = 1.0

    Atlas.OptionsInit()
end

---
--- Updates slider display text with current value
--- Shows the slider label with current rounded value in parentheses
--- @param text string The base text label for the slider
--- @param frame table Optional frame to update, defaults to 'this'
--- @return nil
--- @usage AtlasOptions_UpdateSlider("Scale") -- Called by slider OnValueChanged
---
function AtlasOptions_UpdateSlider(text, frame)
    local slider = frame or this
    if not slider or type(slider.GetValue) ~= "function" then
        return
    end
    local sliderName = slider:GetName()
    local textElement = _G[sliderName .. "Text"]
    if textElement then
        textElement:SetText(text .. " (" .. round(slider:GetValue(), 2) .. ")")
    end
end

--- Sets default configuration options for Atlas
--- Initializes all addon settings to their default values
--- @return nil
--- @usage Atlas.OptionDefaultSettings() -- Reset to defaults
function Atlas.OptionDefaultSettings()
    AtlasOptions = {
        AtlasButtonPosition = 305,
        AtlasButtonRadius = 76,
        AtlasButtonShown = true,
        AtlasRightClick = false,
        AtlasType = 1,
        AtlasScale = 1,
        AtlasVersion = Atlas.Version,
        AtlasZone = 1,
        AtlasSortBy = 1,
        AtlasServer = "Auto",
        AtlasAutoSelect = false,
        AtlasLocked = false,
        AtlasAlpha = 1.0,
        AtlasAcronyms = true,
        AtlasClamped = true,
        AtlasCursorCoords = true,
        QuestCurrentSide = "Left",
        QuestWithAtlas = true,
        QuestColourCheck = true,
        QuestCheckQuestlog = true,
        QuestAutoQuery = true,
        LootShowSource = true,
        LootEquipCompare = false,
        LootOpaque = true,
        LootShowPanel = true,
        LootFilterMode = 0,
        ReagentRows = 20,
        ReagentProfessions = {
            ["Alchemy"] = true,
            ["Blacksmithing"] = true,
            ["Enchanting"] = true,
            ["Engineering"] = true,
            ["Leatherworking"] = true,
            ["Tailoring"] = true,
            ["Cooking"] = true,
            ["First Aid"] = true,
            ["Jewelcrafting"] = true,
            ["Poisons"] = true,
            ["Mining"] = true,
            ["Survival"] = true,
        },
        TooltipShowID = true,
        TooltipShowIcon = true,
        pfUIEnabled = true
    }
    AtlasCharDB.PartialMatching = true
    AtlasCharDB["QuickLooks"] = {}
    AtlasCharDB["WishList"] = {}
    Atlas.QuickLook.RefreshButtons()
    Atlas.OptionsInit()
    PrintA(red .. L["Default settings applied!"])
end

--- Shows and initializes the categories dropdown menu
--- Sets up the dropdown with available sort categories and selects current option
--- @return nil
--- @usage Atlas.OptionFrameDropDownCatsOnShow() -- Called by dropdown OnShow event
---
function Atlas.OptionFrameDropDownCatsOnShow()
    if Atlas.HewdropMenus and Atlas.HewdropMenus.UpdateSortByLabel then
        Atlas.HewdropMenus.UpdateSortByLabel()
    end
end

-----------------------------------------------------------------------------
-- Option handlers
-----------------------------------------------------------------------------
---
--- Toggles automatic quest panel display feature
--- Shows or hides quest panel when Atlas is opened and updates UI state
--- @return nil
--- @usage Atlas.OptionAutoshowOnClick() -- Called by checkbox click
---
function Atlas.OptionAutoshowOnClick()
    AtlasOptions.QuestWithAtlas = not AtlasOptions.QuestWithAtlas
    AtlasOptionAutoshow:SetChecked(AtlasOptions.QuestWithAtlas)
    Atlas.OptionsInit()
end

---
--- Toggles quest panel position between left and right side
--- Moves the quest UI frame and updates settings
--- @return nil
--- @usage Atlas.OptionLeftSideOnClick() -- Called by checkbox click
---
function Atlas.OptionLeftSideOnClick()
    AtlasOptions.QuestCurrentSide = not AtlasOptions.QuestCurrentSide
    if not AtlasOptions.QuestCurrentSide then
        Atlas.Quest.UI_Main.Frame:ClearAllPoints()
        Atlas.Quest.UI_Main.Frame:SetPoint("TOP", "AtlasFrame", -556, -36)
    end
    Atlas.OptionsInit()
end

---
--- Toggles quest color coding feature
--- Enables or disables color-coded quest display and updates quest buttons
--- @return nil
--- @usage Atlas.OptionColorOnClick() -- Called by checkbox click
---
function Atlas.OptionColorOnClick()
    AtlasOptions.QuestColourCheck = not AtlasOptions.QuestColourCheck
    AtlasOptionColor:SetChecked(AtlasOptions.QuestColourCheck)
    Atlas.OptionsInit()
    Atlas.Quest.SetQuestButtons()
end

---
--- Toggles questlog integration feature
--- Enables or disables checking against player's questlog and updates quest buttons
--- @return nil
--- @usage Atlas.OptionQuestlogOnClick() -- Called by checkbox click
---
function Atlas.OptionQuestlogOnClick()
    AtlasOptions.QuestCheckQuestlog = not AtlasOptions.QuestCheckQuestlog
    AtlasOptionQuestlog:SetChecked(AtlasOptions.QuestCheckQuestlog)
    Atlas.OptionsInit()
    Atlas.Quest.SetQuestButtons()
end

---
--- Toggles automatic quest query feature
--- Enables or disables automatic querying of quest information
--- @return nil
--- @usage Atlas.OptionAutoQueryOnClick() -- Called by checkbox click
---
function Atlas.OptionAutoQueryOnClick()
    AtlasOptions.QuestAutoQuery = not AtlasOptions.QuestAutoQuery
    AtlasOptionAutoQuery:SetChecked(AtlasOptions.QuestAutoQuery)
    Atlas.OptionsInit()
end

---
--- Toggles loot source display feature
--- Shows or hides the source information for loot items
--- @return nil
--- @usage Atlas.OptionShowSourceOnClick() -- Called by checkbox click
---
function Atlas.OptionShowSourceOnClick()
    AtlasOptions.LootShowSource = not AtlasOptions.LootShowSource
    Atlas.OptionsInit()
end

---
--- Toggles EquipCompare addon integration
--- Registers or unregisters Atlas tooltips with EquipCompare/EQCompare addons
--- @return nil
--- @usage Atlas.OptionEquipCompareOnClick() -- Called by checkbox click
---
function Atlas.OptionEquipCompareOnClick()
    if Atlas.Integrations and Atlas.Integrations.ToggleEquipCompare then
        Atlas.Integrations.ToggleEquipCompare()
    else
        AtlasOptions.LootEquipCompare = not AtlasOptions.LootEquipCompare
    end
    Atlas.OptionsInit()
end

---
--- Toggles loot frame opacity setting
--- Changes the background transparency of the loot items frame
--- @return nil
--- @usage Atlas.OptionOpaqueOnClick() -- Called by checkbox click
---
function Atlas.OptionOpaqueOnClick()
    AtlasOptions.LootOpaque = AtlasOptionOpaque:GetChecked()
    if AtlasOptions.LootOpaque then
        AtlasLootItemsFrame_Back:SetTexture(0, 0, 0, 1)
    else
        AtlasLootItemsFrame_Back:SetTexture(0, 0, 0, 0.65)
    end
    Atlas.OptionsInit()
end

---
--- Toggles universal tooltip item ID display
--- @return nil
---
function Atlas.OptionTooltipIDOnClick()
    AtlasOptions.TooltipShowID = not AtlasOptions.TooltipShowID
    Atlas.OptionsInit()
end

---
--- Toggles universal tooltip item icon display
--- @return nil
---
function Atlas.OptionTooltipIconOnClick()
    AtlasOptions.TooltipShowIcon = not AtlasOptions.TooltipShowIcon
    Atlas.OptionsInit()
end

---
--- Toggles the Profession Info feature
--- Enables or disables displaying skill levels in profession frames
--- @return nil
--- @usage Atlas.OptionProfessionInfoOnClick() -- Called by checkbox click
---
function Atlas.OptionProfessionInfoOnClick()
    AtlasOptions.ProfessionInfo = not AtlasOptions.ProfessionInfo

    -- Trigger cache build if enabled
    if AtlasOptions.ProfessionInfo and Atlas.ProfessionHooks and Atlas.ProfessionHooks.BuildCache then
        Atlas.ProfessionHooks.BuildCache()
    end

    -- Update visibility of buttons immediately
    if Atlas.ProfessionHooks and Atlas.ProfessionHooks.CreateAtlasButton then
        if AtlasOptions.ProfessionInfo then
            -- Re-create/Update buttons if frames exist
            if TradeSkillFrame then Atlas.ProfessionHooks.CreateAtlasButton(TradeSkillFrame) end
            if CraftFrame then Atlas.ProfessionHooks.CreateAtlasButton(CraftFrame) end
        else
            -- Hide buttons if they exist
            if _G["TradeSkillFrameAtlasButton"] then _G["TradeSkillFrameAtlasButton"]:Hide() end
            if _G["CraftFrameAtlasButton"] then _G["CraftFrameAtlasButton"]:Hide() end
        end
    end

    -- Refresh UI
    if Atlas.ProfessionHooks then
        if TradeSkillFrame and TradeSkillFrame:IsVisible() and Atlas.ProfessionHooks.OnTradeSkillUpdate then
            Atlas.ProfessionHooks.OnTradeSkillUpdate()
        end
        if CraftFrame and CraftFrame:IsVisible() then
            CraftFrame_Update()
        end
    end

    Atlas.OptionsInit()
end

-- Popup Box for first time users
StaticPopupDialogs["AtlasLoot_SETUP"] = {
    text = L["Welcome to Atlas. Please take a moment to set your preferences."],
    button1 = L["Setup"],
    OnAccept = function()
        Atlas.OptionsOnClick()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
}
