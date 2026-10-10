---
--- Atlas.lua - Main Atlas addon core functionality
---
--- This is the primary module of Atlas that handles the main Atlas frame,
--- map display, dropdown management, search functionality, and core UI logic.
--- It coordinates between different subsystems and manages the overall addon state.
---
--- Features:
--- • Interactive dungeon and raid map display
--- • Dynamic dropdown menus for instance selection
--- • Advanced search functionality with filtering
--- • Auto-selection based on player location
--- • Frame locking and positioning management
--- • Integration with loot and quest systems
--- • pfUI compatibility and tooltip enhancements
---
--- @compatible World of Warcraft 1.12
---

local _G = getfenv()
Atlas = _G.Atlas
Atlas.UI = Atlas.UI or {}

local L = Atlas.Localization.UI
local LZ = Atlas.Localization.Zones

local Atlas_Ints_Ent_DropDown = {}
local frame
local loadingStartTime -- Load time
local Colors = Atlas.Colors

Atlas.Version = GetAddOnMetadata(Atlas.Name, "Version")

---
--- Outputs debug information to chat if debug mode is enabled
--- @param info string The debug message to display
--- @return nil
--- @usage debug("Player entered instance")
---
local function debug(info)
	if Atlas.DEBUGMODE then
		PrintA(info)
	end
end

---
--- Performs search filtering on Atlas data and returns formatted results
--- Searches through reputation, keys, and bosses data with text matching
--- @param data table The Atlas data containing Reputation, Keys, and Bosses arrays
--- @param search_text string The search text to filter entries by (case-insensitive)
--- @return table Array of search results with line, name, and id fields
--- @usage local results = PerformSearch(AtlasSearchEditBox.Data, "blackrock")
---
local function PerformSearch(data, search_text)
	local function makeBossLineText(items, new, n, searchText, format_line)
		for _, item in ipairs(items or {}) do
			local name, id = item.name, item.id
			if name then
				local line = format_line(item)
				-- Показываем элемент только если он разрешен для текущего сервера
				local isVisible = Atlas.Server.IsVisible(item)

				-- Если поисковый запрос пустой, показываем все элементы
				if isVisible and (searchText == "" or string.find(string.lower(line), searchText) or (id and string.find(tostring(id), searchText))) then
					new[n] = {
						line = line,
						name = name,
						id = id,
					}
					n = n + 1
				end
			end
		end
		return n
	end

	local new = {}
	local n = 1
	n = makeBossLineText(data["Reputation"], new, n, search_text, function(item)
		return Colors.ORANGE .. L["Reputation"] .. ": " .. item.name
	end)
	n = makeBossLineText(data["Keys"], new, n, search_text, function(item)
		return Colors.GREEN .. L["Key"] .. ": " .. item.name .. (item.info and " <" .. item.info .. ">" or "")
	end)
	n = makeBossLineText(data["Bosses"], new, n, search_text, function(item)
		local color = item.color or Colors.WHITE
		local text = (item.prefix and (item.prefix .. " ") or "   ") ..
			item.name .. (item.postfix and (Colors.PURPLE .. " <" .. item.postfix) .. ">" or "")
		return color .. text
	end)
	return new
end

---
--- Handles click events on the instance type icon
--- Opens the World Map at the instance location
--- @return nil
--- @usage Atlas.OnInstanceTypeClick() -- Called by instance type icon click
---
function Atlas.OnInstanceTypeClick()
	local zoneID = Atlas.DropDowns[AtlasOptions.AtlasType][AtlasOptions.AtlasZone]
	if not zoneID then return end

	-- Find the marker data for this zone
	if Atlas.MapMarkers and Atlas.MapMarkers.FindMarkerByZoneID then
		local markerData = Atlas.MapMarkers.FindMarkerByZoneID(zoneID)
		if markerData then
			-- markerData = {continent, zone, x, y, ...}
			local continent, zone, x, y = unpack(markerData)

			-- Resolve locale-dependent zone ID
			if Atlas.MapMarkers.ResolveZoneID then
				zone = Atlas.MapMarkers.ResolveZoneID(continent, zone)
			end

			-- Close Atlas
			AtlasFrame:Hide()

			-- Open World Map
			ShowUIPanel(WorldMapFrame)
			SetMapZoom(continent, zone)
			-- We don't have a way to highlight or ping the map easily without Cartographer/TomTom,
			-- but opening the correct zone is the main request.
			return
		end
	end

	-- Fallback if no marker found (try to guess from data or just open map)
	-- This part is tricky without precise coordinates mapping for every instance
end

---
--- Removes articles from map names for proper alphabetic sorting
--- For example: "The Deadmines" becomes "Deadmines" to sort under D instead of T
--- @param text string The map name to sanitize
--- @return string The sanitized map name without articles
--- @usage local sanitized = atlas_SanitizeName("The Deadmines")
---
local function atlas_SanitizeName(text)
	text = string.lower(text)
	if AtlasSortIgnore then
		for _, v in pairs(AtlasSortIgnore) do
			local match
			if string.gmatch then
				match = string.gmatch(text, v)()
			else
				match = string.gfind(text, v)()
			end
			if match and (string.len(text) - string.len(match)) <= 4 then
				return match
			end
		end
	end
	return text
end

---
--- Comparator function for alphabetic sorting of Atlas maps
--- Sorts zone names alphabetically after sanitizing them
--- @param a string First zone identifier to compare
--- @param b string Second zone identifier to compare
--- @return boolean True if first zone should come before second zone
--- @usage table.sort(Atlas.DropDowns[n], atlas_SortZonesAlpha)
---
local function atlas_SortZonesAlpha(a, b)
	local aa = atlas_SanitizeName(Atlas.InstanceData[a].Name)
	local bb = atlas_SanitizeName(Atlas.InstanceData[b].Name)

	return aa < bb
end

---
--- Updates the appearance of the lock button based on the Atlas lock status
--- Changes button textures to reflect current locked/unlocked state
--- @return nil
--- @usage Atlas.UpdateLock()
---
function Atlas.UpdateLock()
	local locked = AtlasOptions and AtlasOptions.AtlasLocked
	local status = locked and "Locked" or "Unlocked"
	local textureUp = Atlas.PATH .. "Images\\LockButton-" .. status .. "-Up"
	local textureDown = Atlas.PATH .. "Images\\LockButton-" .. status .. "-Down"

	if AtlasLockNorm then
		AtlasLockNorm:SetTexture(textureUp)
	end
	if AtlasLockPush then
		AtlasLockPush:SetTexture(textureDown)
	end

	-- Also update the button directly in case pfUI or other mods changed the texture objects
	if AtlasLockButton then
		-- If we have the specific texture objects, prefer using them as NormalTexture/PushedTexture
		-- This ensures we don't create duplicate textures or lose the layout properties (SetAllPoints)
		if AtlasLockNorm then
			AtlasLockButton:SetNormalTexture(AtlasLockNorm)
		else
			AtlasLockButton:SetNormalTexture(textureUp)
		end

		if AtlasLockPush then
			AtlasLockButton:SetPushedTexture(AtlasLockPush)
		else
			AtlasLockButton:SetPushedTexture(textureDown)
		end
	end
end

---
--- Initializes Atlas addon components and saved variables
--- Sets up UI frames, validates options, populates dropdowns and applies settings
--- Should be called ONLY when saved variables are loaded into memory
--- @return nil
--- @usage Atlas_Init() -- Called automatically on ADDON_LOADED
---
local function Atlas_Init()
	-- Initialize UI frames
	AtlasLoot_InitializeUI()

	--clear saved vars for a new ver (or a new install!)
	if AtlasOptions == nil or AtlasCharDB.FirstTime then -- or AtlasOptions["AtlasVersion"] ~= Atlas.Version
		Atlas.OptionDefaultSettings()
	end

	--populate the dropdown lists

	Atlas.PopulateDropdowns()

	if Atlas.DropDowns[AtlasOptions.AtlasType] == nil then
		AtlasOptions.AtlasType = 1
		AtlasOptions.AtlasZone = 1
	end

	--Now that saved variables have been loaded, update everything accordingly
	Atlas.Refresh()
	Atlas.UpdateLock()
	Atlas.OptionsUpdateAlpha()
	AtlasFrame:SetClampedToScreen(AtlasOptions.AtlasClamped)
	Atlas.MinimapButtonUpdatePosition()
	Atlas.OptionsInit()
end

---
--- Performs a search through Atlas data based on input text
--- Filters Atlas entries and updates the scroll list with matching results
--- @param text string|nil The search text to filter Atlas entries by
--- @return nil Updates Atlas.ScrollList and Atlas.CurrentLine globals
--- @usage Atlas.Search("blackrock") -- Search for Blackrock instances
---
function Atlas.Search(text)
	if not text then text = "" end
	local search_text = string.lower(text)
	search_text = string.gsub(search_text, "([%^%$%(%)%%%.%[%]%+%-%?])", "%%%1")
	search_text = string.gsub(search_text, "%*", ".*")
	local data = PerformSearch(AtlasSearchEditBox.Data, search_text)

	--populate the scroll frame entries list, the update func will do the rest
	local i = 1
	while (data and data[i] and data[i].line ~= nil) do
		Atlas.ScrollList[i] = { line = data[i].line, name = data[i].name, id = data[i].id }
		i = i + 1
	end
	Atlas.CurrentLine = i - 1
end

---
--- Main Atlas event handler for ADDON_LOADED and other WoW events
--- Initializes the addon when loaded and detects player faction
--- @return nil
--- @usage Automatically called by WoW event system
---
function Atlas.OnEvent()
	if arg1 == Atlas.Name then
		Atlas_Init()

		-- Compatibility hooks for AtlasFu2 and other Atlas-dependent addons
		if not Atlas_Toggle then
			Atlas_Toggle = Atlas.ToggleAtlas
		end
		if not AtlasOptions_Toggle then
			AtlasOptions_Toggle = Atlas.OptionsOnClick
		end
		if not Atlas_Refresh then
			Atlas_Refresh = Atlas.Refresh
		end
	elseif not arg1 or event == "PLAYER_ENTERING_WORLD" then
		Atlas.isHorde = UnitFactionGroup("player") == "Horde"
		Atlas.Faction = Atlas.isHorde and "Horde" or "Alliance"
		Atlas.PlayerClass = UnitClass("player")
	end
	if event == "ADDON_LOADED" then
		if not loadingStartTime then
			loadingStartTime = GetTime()
		end
	elseif event == "PLAYER_ENTERING_WORLD" and loadingStartTime then
		local loadingTime = (GetTime() - loadingStartTime) * 1000
		--PrintA(string.format("Load time: %.2f ", loadingTime))
		loadingStartTime = nil
	end
end

---
--- Populates dropdown menus with Atlas instance data based on current sort order
--- Organizes instances into categories and applies alphabetic sorting where appropriate
--- @return nil Updates Atlas.DropDowns global table
--- @usage Atlas.PopulateDropdowns() -- Called during initialization
---
function Atlas.PopulateDropdowns()
	local sortType = Atlas_DropDownSortOrder[AtlasOptions.AtlasSortBy]
	local subcatOrder = Atlas_DropDownGetLayoutOrder(sortType)
	local layouts = Atlas_DropDownGetLayout(sortType)
	local m = getn(subcatOrder)
	for n = 1, m do
		local subcatItems = layouts[subcatOrder[n]]
		Atlas.DropDowns[n] = {}
		for _, v in pairs(subcatItems) do
			-- Filter instance by server compatibility
			if Atlas.Server.IsVisible(Atlas.InstanceData[v]) then
				table.insert(Atlas.DropDowns[n], v)
			end
		end
		if subcatOrder[n] ~= L["Instances"] and subcatOrder[n] ~= L["World"] then
			table.sort(Atlas.DropDowns[n], atlas_SortZonesAlpha)
		end
	end
end

---
--- Toggles the Atlas frame's lock status and updates button appearance
--- Prevents or allows frame dragging based on current lock state
--- @return nil
--- @usage Atlas.ToggleLock() -- Called by lock button click
---
function Atlas.ToggleLock()
	AtlasOptions.AtlasLocked = not AtlasOptions.AtlasLocked
	Atlas.UpdateLock()
end

---
--- Sets the selected index for the Atlas switch dropdown
--- @param index number The index to set as selected
--- @return nil
--- @usage atlasSwitchDD_Set(2)
---
local function atlasSwitchDD_Set(index)
	for k, v in pairs(Atlas.DropDowns) do
		for k2, v2 in pairs(v) do
			if v2 == Atlas_Ints_Ent_DropDown[index] then
				AtlasOptions.AtlasType = k
				AtlasOptions.AtlasZone = k2
			end
		end
	end
	Atlas.UpdateDropdownLabels()
	Atlas.Refresh()
end

---
--- Handles click events on the Atlas switch dropdown
--- Updates the selected option and refreshes the display
--- @return nil
--- @usage Called automatically by UI dropdown system
---
local function atlasSwitchDD_OnClick()
	atlasSwitchDD_Set(this:GetID())
end

---
--- Initializes the Atlas switch dropdown on load
--- Sets up the dropdown options and default selection
--- @return nil
--- @usage Called automatically during UI initialization
---
local function atlasSwitchDD_OnLoad()
	local info
	for _, v in pairs(Atlas_Ints_Ent_DropDown) do
		info = {
			text = Atlas.InstanceData[v].Name,
			func = atlasSwitchDD_OnClick
		}
		UIDropDownMenu_AddButton(info)
	end
end

---
--- Sorting function for Atlas switch dropdown items
--- Compares two dropdown items for alphabetical ordering
--- @param a table First dropdown item to compare
--- @param b table Second dropdown item to compare
--- @return boolean True if a should come before b in sort order
--- @usage Used internally by table.sort for dropdown ordering
---
local function atlasSwitchDD_Sort(a, b)
	local aa = Atlas.InstanceData[a].Name
	local bb = Atlas.InstanceData[b].Name
	return aa < bb
end

--Refreshes the Atlas frame, usually because a new map needs to be displayed
---
--- Refreshes the Atlas display with current map selection
--- Updates map texture, boss information, quest frame and info panel
--- The zoneID variable represents the internal name used for each map
--- @return nil
--- @usage Atlas.Refresh() -- Called after changing maps or options
---
function Atlas.Refresh()
	local dropDownCategory = Atlas.DropDowns[AtlasOptions.AtlasType]
	if not dropDownCategory then
		return -- DropDowns not populated yet
	end

	-- If current zone index is invalid for this category (e.g. after server switch), reset to first
	if not dropDownCategory[AtlasOptions.AtlasZone] then
		if table.getn(dropDownCategory) > 0 then
			AtlasOptions.AtlasZone = 1
			Atlas.UpdateDropdownLabels()
		else
			-- If category is completely empty, we can't show anything here
			AtlasMap:SetTexture("")
			AtlasZoneText:SetText(L["No Maps Available"])
			Atlas.CurrentMap = ""
			Atlas.Quest.Update()
			return
		end
	end

	local zoneID = dropDownCategory[AtlasOptions.AtlasZone]
	if not zoneID then
		return -- No zone selected
	end

	local data = Atlas.InstanceData
	local base = {}

	--If a first time user, set up options
	if AtlasCharDB.FirstTime == nil or AtlasCharDB.FirstTime == true then
		StaticPopup_Show("AtlasLoot_SETUP")
		AtlasCharDB.FirstTime = false
	end

	--Reset which loot page is 'current'
	AtlasLootItemsFrame.activeElement = nil

	--Get boss name information
	for key, value in pairs(data[zoneID] or {}) do --TODO REMAKE
		base[key] = value
	end

	--Display the selected texture
	AtlasMap:SetTexture(zoneID and Atlas.MAPPATH .. zoneID or "")

	--Update the quest frame
	Atlas.CurrentMap = zoneID
	Atlas.Quest.Update()

	--Setup info panel above boss listing
	local function SetAtlasText(frame2, label, value, color)
		local text = color or ""
		if value then
			if label then
				text = text .. L[label] .. ": "
			end
			if type(value) == "table" then
				text = text .. value[1] .. "-" .. value[2]
			else
				text = text .. value
			end
		end
		frame2:SetText(text)
	end

	local zoneName = base.Name
	if AtlasOptions.AtlasAcronyms and base.Acronym ~= nil then
		zoneName = zoneName .. Colors.RED .. " [" .. base.Acronym .. "]"
	end
	AtlasZoneText:SetText(zoneName)
	SetAtlasText(AtlasLocationText, "Location", base.Location)
	SetAtlasText(AtlasLevelRangeText, "Level", base.Level)
	SetAtlasText(AtlasPlayerLimitText, "Player Limit", base.MaxPlayers)
	SetAtlasText(AtlasAttunText, nil, base.Attunement and L["Attunement Required"], Colors.RED)
	SetAtlasText(AtlasDamageTypeText, "Damage", base.DamageType, Colors.RED)
	local entranceText = {}
	for i, entranceData in ipairs(base.Entrances or {}) do
		if entranceData and entranceData.letter then
			entranceText[i] = entranceData.letter
			if entranceData.info then
				entranceText[i] = entranceText[i] .. " (" .. entranceData.info .. ")"
			end
		end
	end
	AtlasTextentr:SetText("")
	for i = 1, 5 do
		SetAtlasText(_G["AtlasTextentr" .. i], nil, entranceText[i], Colors.BLUE)
		if entranceText[i] then
			AtlasTextentr:SetText(L["Entrances"])
		end
	end

	-- Add/Update entrance icon next to the "Entrances" label
	if AtlasInstanceTypeButton then
		-- Removed the check for AtlasTextentr:GetText() so icons show even without entrances (e.g. World Bosses)
		local mapData = Atlas.InstanceData[zoneID]
		local isRaid = false
		local isWorldBoss = false
		local isValid = false

		-- Determine type
		if mapData then
			-- Check for Dungeon/Raid
			if mapData.MaxPlayers then
				isValid = true -- Has player limit, likely an instance
				if mapData.MaxPlayers > 5 then
					if mapData.Name == LZ["Stratholme"] or mapData.Name == LZ["Scholomance"] or mapData.Name == LZ["Lower Blackrock Spire"] or mapData.Name == LZ["Upper Blackrock Spire"] then
						isRaid = false
					elseif string.sub(zoneID, 1, 2) == "BG" then
						isRaid = false -- Force BGs to be dungeons
					else
						isRaid = true
					end
				end
			end

			-- World Boss check
			if type(mapData.Level) == "table" and mapData.Level[1] == 1 and string.sub(zoneID, 1, 2) ~= "BG" then
				isWorldBoss = true
				isRaid = false
				isValid = true
			end
		end

		if isValid then
			-- Use textures from Images/Markers/
			local texture = Atlas.PATH .. "Images\\Markers\\dungeon"
			local tooltip = L["Dungeons"]

			if isRaid then
				texture = Atlas.PATH .. "Images\\Markers\\raid"
				tooltip = L["Raids"]
			elseif isWorldBoss then
				texture = Atlas.PATH .. "Images\\Markers\\worldboss"
				tooltip = L["World"]
			elseif string.sub(zoneID, 1, 2) == "BG" then
				tooltip = L["Battlegrounds"]
			end

			local icon = _G["AtlasInstanceTypeIcon"]
			if icon then
				icon:SetTexture(texture)
			end

			-- Set tooltip text
			if AtlasInstanceTypeButton then
				AtlasInstanceTypeButton.tooltipText = tooltip
			end

			AtlasInstanceTypeButton:Show()
		else
			AtlasInstanceTypeButton:Hide()
		end
	end

	if (data.Search ~= false) then
		AtlasSearchEditBox:Show()
		AtlasNoSearch:Hide()
	else
		AtlasSearchEditBox:Hide()
		AtlasNoSearch:Show()
		ATLAS_SEARCH_METHOD = nil
	end

	--Store zoneLines for search
	AtlasSearchEditBox.Data = base

	--populate the scroll frame entries list, the update func will do the rest
	Atlas.Search("")
	AtlasSearchEditBox:SetText("")
	AtlasSearchEditBox:ClearFocus()

	--create and align any new entry buttons that we need
	for i = 1, Atlas.CurrentLine do
		if not _G["AtlasBossLine" .. i] then
			frame = AtlasLoot_CreateButtonFromTemplate("AtlasBossLine" .. i, AtlasFrame,
				"AtlasLootNewBossLineTemplate")
			if i ~= 1 then
				frame:SetPoint("TOPLEFT", "AtlasBossLine" .. (i - 1), "BOTTOMLEFT")
			else
				frame:SetPoint("TOPLEFT", "AtlasScrollBar", "TOPLEFT", 16, -3)
			end
			frame:SetAlpha(.8)
			-- Limit buttons to the scrollbar's visible area (24 lines * 15 pixels = 360 pixels)
			if i > 24 then
				frame:EnableMouse(false)
				frame:Hide()
			end
		else
			_G["AtlasBossLine" .. i .. "_Loot"]:Hide()
			_G["AtlasBossLine" .. i .. "_Selected"]:Hide()
			-- Also limit existing buttons accordingly
			if i > 24 then
				_G["AtlasBossLine" .. i]:EnableMouse(false)
				_G["AtlasBossLine" .. i]:Hide()
			end
		end
	end

	--Hide the loot frame now that a pristine Atlas instance is created
	AtlasLootItemsFrame:Hide()

	-- Update the scrollbar after creating elements
	Atlas.LootBrowserUI.ScrollBarUpdate()

	--see if we should display the entrance/instance button or not, and decide what it should say
	local matchFound = {}
	local sayEntrance = nil
	for k, v in pairs(Atlas.EntToInstMatches) do
		if k == zoneID then
			matchFound = v
			sayEntrance = false
		end
	end
	if not matchFound[1] then
		for k, v in pairs(Atlas.InstToEntMatches) do
			if k == zoneID then
				matchFound = v
				sayEntrance = true
			end
		end
	end

	--set the button's text, populate the dropdown menu, and show or hide the button
	if matchFound[1] ~= nil then
		Atlas_Ints_Ent_DropDown = {}
		for _, v in pairs(matchFound) do
			table.insert(Atlas_Ints_Ent_DropDown, v)
		end
		table.sort(Atlas_Ints_Ent_DropDown, atlasSwitchDD_Sort)
		if sayEntrance then
			AtlasSwitchButton:SetText(L["Entrance"])
		else
			AtlasSwitchButton:SetText(L["Instance"])
		end
		AtlasSwitchButton:Show()

		-- Hewdrop menu is now opened on-demand in SwitchButtonOnClick
	else
		AtlasSwitchButton:Hide()
	end

	-- Update map markers if visible
	if Atlas.MapMarkers and Atlas.MapMarkers.UpdateMarkers then
		Atlas.MapMarkers.UpdateMarkers()
	end
end

---
--- Handles switch button clicks to toggle between entrance and instance maps
--- Automatically switches if only one match exists, otherwise shows dropdown menu
--- @return nil
--- @usage Atlas.SwitchButtonOnClick() -- Called by switch button OnClick
---
function Atlas.SwitchButtonOnClick()
	if getn(Atlas_Ints_Ent_DropDown) == 1 then
		--one link, so we can just go there right away
		atlasSwitchDD_Set(1)
	else
		--more than one link, so use Hewdrop menu
		Atlas.HewdropMenus:OpenSwitchMenu(AtlasSwitchButton, Atlas_Ints_Ent_DropDown, atlasSwitchDD_Set)
	end
end

---
--- Handles map type dropdown menu item clicks
--- Updates the main dropdown menu contents to reflect the selected map category
--- @return nil
--- @usage Called automatically by dropdown menu system
---
local function atlasFrameDropDownType_OnClick()
	local thisID = this:GetID()
	UIDropDownMenu_SetSelectedID(AtlasFrameDropDownType, thisID)
	AtlasOptions.AtlasType = thisID
	AtlasOptions.AtlasZone = 1
	Atlas.FrameDropDownOnShow()
	Atlas.Refresh()
end

---
--- Initializes the map type dropdown menu with category options
--- Populates dropdown with sorted category names based on current sort settings
--- @return nil
--- @usage UIDropDownMenu_Initialize(AtlasFrameDropDownType, atlasFrameDropDownType_Initialize)
---
local function atlasFrameDropDownType_Initialize()
	local info
	local sortType = Atlas_DropDownSortOrder[AtlasOptions.AtlasSortBy]
	local subcatOrder = Atlas_DropDownGetLayoutOrder(sortType)
	local m = getn(subcatOrder)
	for i = 1, m do
		info = {
			text = subcatOrder[i],
			func = atlasFrameDropDownType_OnClick
		}
		UIDropDownMenu_AddButton(info)
	end
end

---
--- Handles click events on main dropdown menu items
--- Sets the newly selected map as current and refreshes the Atlas frame
--- @return nil
--- @usage Called automatically by UI dropdown system
---
local function atlasFrameDropDown_OnClick()
	local i = this:GetID()
	UIDropDownMenu_SetSelectedID(AtlasFrameDropDown, i)
	AtlasOptions.AtlasZone = i
	Atlas.Refresh()
end

---
--- Initializes the main dropdown menu with instance/map options
--- Populates dropdown based on current AtlasType selection
--- @return nil
--- @usage UIDropDownMenu_Initialize(AtlasFrameDropDown, atlasFrameDropDown_Initialize)
---
local function atlasFrameDropDown_Initialize()
	local info
	for _, v in pairs(Atlas.DropDowns[AtlasOptions.AtlasType]) do
		info = {
			text = Atlas.InstanceData[v].Name,
			func = atlasFrameDropDown_OnClick
		}
		UIDropDownMenu_AddButton(info)
	end
end

---
--- Gets the current zone text with Atlas naming convention fixes applied
--- Always use this function instead of GetRealZoneText within Atlas
--- @return string The corrected zone name or original if no substitution exists
--- @usage local zone = atlas_GetFixedZoneText()
---
local function atlas_GetFixedZoneText()
	local currentZone = GetRealZoneText()
	local subs = AtlasZoneSubstitutions
	if subs and subs[currentZone] then
		return subs[currentZone]
	end
	return currentZone
end

---
--- Automatically selects the appropriate Atlas map based on player's current location
--- Checks zone and subzone data to find the best matching map and displays it
--- @return nil Updates AtlasOptions.AtlasType and AtlasOptions.AtlasZone if match found
--- @usage atlasAutoSelect() -- Called when auto-select is enabled
---
local function atlasAutoSelect()
	local currentZone = atlas_GetFixedZoneText()
	local currentSubZone = GetSubZoneText()
	debug("Using auto-select to open the best map.")

	if Atlas.AssocDefaults[currentZone] then
		debug("You're in a zone where SubZone data is relevant.")
		if Atlas.SubZoneData[currentSubZone] then
			debug("There's data for your current SubZone.")
			for ka, va in pairs(Atlas.DropDowns) do
				for kb, vb in pairs(va) do
					if Atlas.SubZoneData[currentSubZone] == vb then
						AtlasOptions.AtlasType = ka
						AtlasOptions.AtlasZone = kb
						Atlas.Refresh()
						debug("Map changed directly based on SubZone data.")
						return
					end
				end
			end
		else
			debug("No applicable SubZone data exists.")
			if currentZone == Atlas.SubZoneAssoc[Atlas.DropDowns[AtlasOptions.AtlasType][AtlasOptions.AtlasZone]] then
				debug("You're in the same instance as the former map. Doing nothing.")
				return
			else
				for ka, va in pairs(Atlas.DropDowns) do
					for kb, vb in pairs(va) do
						if Atlas.AssocDefaults[currentZone] == vb then
							AtlasOptions.AtlasType = ka
							AtlasOptions.AtlasZone = kb
							Atlas.Refresh()
							debug("You just arrived here. Using the default map.")
							return
						end
					end
				end
			end
		end
	else
		debug("SubZone data isn't relevant here.")
		if Atlas.OutdoorZoneToAtlas[currentZone] then
			debug("This world zone is associated with a map.")
			for ka, va in pairs(Atlas.DropDowns) do
				for kb, vb in pairs(va) do
					if Atlas.OutdoorZoneToAtlas[currentZone] == vb then
						AtlasOptions.AtlasType = ka
						AtlasOptions.AtlasZone = kb
						Atlas.Refresh()
						debug("Map changed to the associated map.")
						return
					end
				end
			end
		elseif Atlas.InstToEntMatches[Atlas.DropDowns[AtlasOptions.AtlasType][AtlasOptions.AtlasZone]] then
			for _, va in pairs(Atlas.InstToEntMatches[Atlas.DropDowns[AtlasOptions.AtlasType][AtlasOptions.AtlasZone]]) do
				if currentZone == Atlas.InstanceData[va].Name then
					debug("Instance/entrance pair found. Doing nothing.")
					return
				end
			end
		elseif Atlas.EntToInstMatches[Atlas.DropDowns[AtlasOptions.AtlasType][AtlasOptions.AtlasZone]] then
			for _, va in pairs(Atlas.EntToInstMatches[Atlas.DropDowns[AtlasOptions.AtlasType][AtlasOptions.AtlasZone]]) do
				if currentZone == Atlas.InstanceData[va].Name then
					debug("Instance/entrance pair found. Doing nothing.")
					return
				end
			end
		end
		debug("Searching through all maps for a Name match.")
		for ka, va in pairs(Atlas.DropDowns) do
			for kb, vb in pairs(va) do
				-- Compare the currentZone to the new substr of ZoneName
				if currentZone == strsub(Atlas.InstanceData[vb].Name, strlen(Atlas.InstanceData[vb].Name) - strlen(currentZone) + 1) then
					AtlasOptions.AtlasType = ka
					AtlasOptions.AtlasZone = kb
					Atlas.Refresh()
					debug("Found a match. Map has been changed.")
					return
				end
			end
		end
	end
	debug("Nothing changed because no match was found.")
end

---
--- Initializes and displays the map type dropdown menu
--- Now uses Hewdrop - just updates button text label
--- @return nil
--- @usage Called automatically when dropdown is shown
---
function Atlas.FrameDropDownTypeOnShow()
	Atlas.UpdateDropdownLabels()
end

---
--- Initializes and displays the main instance dropdown menu
--- Now uses Hewdrop - just updates button text label
--- @return nil
--- @usage Called automatically when dropdown is shown
---
function Atlas.FrameDropDownOnShow()
	Atlas.UpdateDropdownLabels()
end

---
--- Handles Atlas frame show event and initializes display components
--- Sets up tooltips, auto-selection, dropdowns and shows loot frame if needed
--- @return nil
--- @usage Called automatically when Atlas frame is shown
---
-- Helper to find boss index
local function FindBossIndexInScrollList(bossIdOrName)
	if not (Atlas and Atlas.ScrollList) or not bossIdOrName then return nil end
	for i = 1, table.getn(Atlas.ScrollList) do
		local entry = Atlas.ScrollList[i]
		if entry and (entry.id == bossIdOrName or entry.name == bossIdOrName) then
			return i
		end
	end
	return nil
end

function Atlas.OnShow()
	if (AtlasOptions.AtlasAutoSelect) then
		atlasAutoSelect()
	end

	-- Restore Last Opened State
	-- Only restore if not explicitly opening a specific page (e.g. from World Map)
	if not Atlas.SkipRestore and AtlasCharDB and AtlasCharDB.LastOpened and AtlasCharDB.LastOpened.StoredElement then
		local stored = AtlasCharDB.LastOpened

		-- Restore Map Choice if valid
		if stored.AtlasType and stored.AtlasZone and AtlasOptions then
			AtlasOptions.AtlasType = stored.AtlasType
			AtlasOptions.AtlasZone = stored.AtlasZone
		end
	end

	-- Reset the skip flag
	Atlas.SkipRestore = nil

	Atlas.UpdateDropdownLabels()
	Atlas.Refresh()

	-- Restore Loot Page State
	if AtlasCharDB and AtlasCharDB.LastOpened and AtlasCharDB.LastOpened.StoredElement then
		local stored = AtlasCharDB.LastOpened

		if AtlasLootItemsFrame then
			AtlasLootItemsFrame.StoredElement = stored.StoredElement
			AtlasLootItemsFrame.StoredMenu = stored.StoredMenu

			-- Restore left-side selection
			local bossIndex = FindBossIndexInScrollList(stored.StoredElement)
			if bossIndex then
				AtlasLootItemsFrame.activeElement = bossIndex
				if Atlas.LootBrowserUI.ScrollBarUpdate then Atlas.LootBrowserUI.ScrollBarUpdate() end
			end

			-- Show Loot Frame
			AtlasLootItemsFrame:Show()

			-- Load Content (with caching)
			local lootTable = Atlas.DataResolver.GetLootByElemName(stored.StoredElement, stored.StoredMenu)
			if lootTable and Atlas.LootCache and Atlas.LootCache.CacheAllItems then
				Atlas.LootBrowserUI.ShowScrollBarLoading()
				Atlas.LootCache.CacheAllItems(lootTable, function()
					Atlas.LootBrowserUI.HideScrollBarLoading()
					Atlas.LootBrowserUI.ScrollBarLootUpdate()
				end)
			else
				Atlas.LootBrowserUI.ScrollBarLootUpdate()
			end
		end
		--If a boss has been selected (e.g. from AutoSelect or previous session without full restore), show the loot frame
	elseif AtlasLootItemsFrame.activeElement then
		AtlasLootItemsFrame:Show()
	end
end
