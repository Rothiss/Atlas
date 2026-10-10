---
--- Hewdrop menu construction and handlers for AtlasLoot
--- Provides dropdown registration and click handlers for loot browser navigation
---

-- Instance required libraries
local _G = getfenv()
Atlas = _G.Atlas

--Make the Hewdrop menu in the standalone loot browser accessible here
AtlasLoot_Hewdrop = _G.ATWHewdrop

local L = Atlas.Localization.UI
local LM = Atlas.Localization.MapData
local LS = Atlas.Localization.Spells
local LC = Atlas.Localization.Classes

Atlas.MenuData = Atlas.MenuData or {}

-- Cache for localized strings (optimization)
local LocalizedStrings = {
	DungeonsRaids = L["Dungeons & Raids"],
	World = L["World"],
	PvPRewards = L["PvP Rewards"],
	Collections = L["Collections"],
	Factions = L["Factions"],
	WorldEvents = L["World Events"],
	Crafting = L["Crafting"],
	WeaponSkills = L["Weapon Skills"],
	RareMobs = L["Rare Mobs"]
}

-- Menu key to meta-category mapping (used for parent resolution)
local MenuKeyToMetaCategory = {
	WorldEvents = LocalizedStrings.WorldEvents,
	Factions = LocalizedStrings.Factions,
	WorldBosses = LocalizedStrings.World,
	PVP = LocalizedStrings.PvPRewards,
	PVPSets = LocalizedStrings.PvPRewards,
	Sets = LocalizedStrings.Collections,
	-- Professions (all map to Crafting)
	Alchemy = LocalizedStrings.Crafting,
	Smithing = LocalizedStrings.Crafting,
	Enchanting = LocalizedStrings.Crafting,
	Engineering = LocalizedStrings.Crafting,
	Leatherworking = LocalizedStrings.Crafting,
	Mining = LocalizedStrings.Crafting,
	Tailoring = LocalizedStrings.Crafting,
	Jewelcrafting = LocalizedStrings.Crafting,
	Cooking = LocalizedStrings.Crafting,
	FirstAid = LocalizedStrings.Crafting,
	Poisons = LocalizedStrings.Crafting,
	Herbalism = LocalizedStrings.Crafting,
	Survival = LocalizedStrings.Crafting,
	Skinning = LocalizedStrings.Crafting,
	Fishing = LocalizedStrings.Crafting,
}

---
--- Gets the meta-category for a menu key or lootpage
--- @param key string - Menu key (e.g., "Alchemy") or lootpage identifier
--- @return string|nil - Localized meta-category name, or nil if not found
--- @usage local meta = Atlas_GetMetaCategoryForMenu("Alchemy") -- returns L["Crafting"]
---
function Atlas_GetMetaCategoryForMenu(key)
	if not key or not Atlas or not Atlas.MenuData then return nil end

	-- Direct menu key lookup
	if MenuKeyToMetaCategory[key] then
		return MenuKeyToMetaCategory[key]
	end

	-- Scan MenuData tables for the lootpage
	for menuKey, metaName in pairs(MenuKeyToMetaCategory) do
		local menuTable = Atlas.MenuData[menuKey]
		if type(menuTable) == "table" then
			local n = table.getn(menuTable)
			for i = 1, n do
				local entry = menuTable[i]
				if entry and entry.lootpage == key then
					return metaName
				end
			end
		end
	end

	return nil
end

--- Counts the maximum numeric index in a sparse array
--- @param tbl table The table to analyze for maximum numeric index
--- @return number The highest numeric key found in the table
--- @usage local max = GetMaxNumericIndex({[1] = "a", [5] = "b"}) -- returns 5

local function GetMaxNumericIndex(tbl)
	local maxIndex = 0
	for k, v in pairs(tbl) do
		if type(k) == "number" and k > maxIndex and v then
			maxIndex = k
		end
	end
	return maxIndex
end

--- Processes category data for loot configuration
--- @param data table The raw category data to process
--- @param categoryName string The name of the category being processed
--- @param specialHandler function|nil Optional special handler function
--- @return table|nil Processed category data structure
--- @usage local category = ProcessCategoryData(dungeonData, "Dungeons", nil)

local function ProcessCategoryData(data, categoryName, specialHandler)
	if not data then return nil end

	local category = {}
	category[categoryName] = {}
	local categoryList = category[categoryName]

	if specialHandler then
		return specialHandler(data, category, categoryList)
	else
		-- Standard processing with sparse array support
		local maxIndex = GetMaxNumericIndex(data)
		for i = 1, maxIndex do
			local item = data[i]
			if item and item.name and item.lootpage and Atlas.Server.IsVisible(item) then
				table.insert(categoryList, { { item.name, item.lootpage } })
			end
		end
	end

	return category
end

--- Special handler to process World category (ensures Rare Mobs entry is placed last)
--- @param data table Raw world bosses data
--- @param category table Output category table reference
--- @param categoryList table Output list reference inside category
--- @return table category The processed category table
--- @usage local cat = ProcessWorldCategory(MenuData.WorldBosses, {}, {})
---
local function ProcessWorldCategory(data, category, categoryList)
	local rareMobsEntry = nil
	local maxIndex = GetMaxNumericIndex(data)

	for i = 1, maxIndex do
		local boss = data[i]
		if boss and boss.name and boss.lootpage and Atlas.Server.IsVisible(boss) then
			if boss.name == LocalizedStrings.RareMobs then
				rareMobsEntry = { { boss.name, boss.lootpage } }
			else
				table.insert(categoryList, { { boss.name, boss.lootpage } })
			end
		end
	end

	if rareMobsEntry then
		table.insert(categoryList, rareMobsEntry)
	end

	return category
end

--- Special handler to process Dungeons & Raids category
--- @param menuData table Raw dungeon menu data
--- @return table|nil category The processed category or nil when input is invalid
--- @usage local cat = ProcessDungeonsCategory(MenuData.Dungeons)
---
local function ProcessDungeonsCategory(menuData)
	if not menuData then return nil end

	local category = {}
	category[LocalizedStrings.DungeonsRaids] = {}
	local categoryList = category[LocalizedStrings.DungeonsRaids]

	-- Combine processing of two arrays into one loop with sparse array support
	local totalCount = GetMaxNumericIndex(menuData)
	for i = 1, totalCount do
		local dung = menuData[i]
		if dung and dung.name and dung.lootpage and Atlas.Server.IsVisible(dung) then
			table.insert(categoryList, { { dung.name, dung.lootpage } }) --dung.name_orig or
		end
	end
	return category
end

--- Generates the dropdown menu structure for AtlasLoot
--- Creates optimized menu categories for dungeons, world, PvP, collections, etc.
--- @return table Complete dropdown menu structure for AtlasLoot
--- @usage local menu = GenerateHewdropDown()

local function GenerateHewdropDown()
	local MenuData = Atlas.MenuData
	local hewdropDown = {}
	local category

	-- 1. Dungeons & Raids (optimized processing)
	category = ProcessDungeonsCategory(MenuData.Dungeons)
	if category then
		table.insert(hewdropDown, category)
	end

	-- 2. World (optimized processing)
	category = ProcessCategoryData(MenuData.WorldBosses, LocalizedStrings.World, ProcessWorldCategory)
	if category then
		table.insert(hewdropDown, category)
	end

	-- 3. PvP Rewards (optimized processing)
	category = ProcessCategoryData(MenuData.PVP, LocalizedStrings.PvPRewards)
	if category then
		table.insert(hewdropDown, category)
	end

	-- 4. Collections (optimized processing)
	category = ProcessCategoryData(MenuData.Sets, LocalizedStrings.Collections)
	if category then
		table.insert(hewdropDown, category)
	end

	-- 5. Factions (optimized processing)
	category = ProcessCategoryData(MenuData.Factions, LocalizedStrings.Factions)
	if category then
		table.insert(hewdropDown, category)
	end

	-- 6. World Events (optimized processing)
	category = ProcessCategoryData(MenuData.WorldEvents, LocalizedStrings.WorldEvents)
	if category then
		table.insert(hewdropDown, category)
	end

	-- 7. Crafting (optimized processing)
	category = ProcessCategoryData(MenuData.Crafting, LocalizedStrings.Crafting)
	if category then
		table.insert(hewdropDown, category)
	end

	return hewdropDown
end

-- Generate data on load (with lazy initialization)
do
	if not AtlasLoot_HewdropDown then
		AtlasLoot_HewdropDown = GenerateHewdropDown()
	end
end

---
--- Opens a specific loot menu category
--- Maps menu names to their corresponding functions and executes them
--- @param menuName string Name of the menu to open
--- @return nil
--- @usage AtlasLoot_OpenMenu("Crafting") -- Opens crafting menu
---
function AtlasLoot_OpenMenu(menuName)
	AtlasLoot_QuickLooks:Hide()
	AtlasLootQuickLooksButton:Hide()
	AtlasLootItemsFrame_SelectedCategory:SetText(Atlas.LootUtils.TruncateText(menuName, 30))
	local menuMapping = {
		[LocalizedStrings.Crafting] = "AtlasLoot_CraftingMenu",
		[LocalizedStrings.World] = "AtlasLoot_WorldMenu",
		[LocalizedStrings.PvPRewards] = "AtlasLootPvPMenu",
		[LocalizedStrings.WorldEvents] = "AtlasLootWorldEventMenu",
		[LocalizedStrings.WeaponSkills] = "AtlasLootWeaponSkillsMenu",
		[LocalizedStrings.Collections] = "AtlasLootSetMenu",
		[LocalizedStrings.Factions] = "AtlasLootRepMenu",
		[LocalizedStrings.DungeonsRaids] = "AtlasLoot_DungeonsMenu",
		[LS["Alchemy"]] = "AtlasLoot_AlchemyMenu",
		[LS["Blacksmithing"]] = "AtlasLoot_SmithingMenu",
		[LS["Enchanting"]] = "AtlasLoot_EnchantingMenu",
		[LS["Engineering"]] = "AtlasLoot_EngineeringMenu",
		[LS["Leatherworking"]] = "AtlasLoot_LeatherworkingMenu",
		[LS["Mining"]] = "AtlasLoot_MiningMenu",
		[LS["First Aid"]] = "AtlasLoot_FirstAidMenu",
		[LS["Survival"]] = "AtlasLoot_SurvivalMenu",
		[LS["Tailoring"]] = "AtlasLoot_TailoringMenu",
		[LS["Jewelcrafting"]] = "AtlasLoot_JewelcraftingMenu",
		[LS["Cooking"]] = "AtlasLoot_CookingMenu",
		[LS["Poisons"]] = "AtlasLoot_PoisonsMenu",
		[LC["Rogue"] .. " " .. L["Special"]] = "AtlasLoot_PoisonsMenu",
		[LS["Herbalism"]] = "AtlasLoot_HerbalismMenu",
		[LS["Fishing"]] = "AtlasLoot_FishingMenu",
		[LS["Skinning"]] = "AtlasLoot_SkinningMenu",
		[L["Crafted Sets"]] = "AtlasLootCraftedSetMenu",
		[L["PvP Armor Sets"]] = "AtlasLootPVPSetMenu",
		[L["Priest Sets"]] = "AtlasLootPriestSetMenu",
		[L["Mage Sets"]] = "AtlasLootMageSetMenu",
		[L["Warrior Sets"]] = "AtlasLootWarriorSetMenu",
		[L["Rogue Sets"]] = "AtlasLootRogueSetMenu",
		[L["Shaman Sets"]] = "AtlasLootShamanSetMenu",
		[L["Paladin Sets"]] = "AtlasLootPaladinSetMenu",
		[L["Druid Sets"]] = "AtlasLootDruidSetMenu",
		[L["Hunter Sets"]] = "AtlasLootHunterSetMenu",
		[L["Warlock Sets"]] = "AtlasLootWarlockSetMenu",
		[L["Pre 60 Sets"]] = "AtlasLootPRE60SetMenu",
		[L["Zul'Gurub Sets"]] = "AtlasLootZGSetMenu",
		[L["Temple of Ahn'Qiraj Sets"]] = "AtlasLootAQ40SetMenu",
		[L["Ruins of Ahn'Qiraj Sets"]] = "AtlasLootAQ20SetMenu",
		[L["Tower of Karazhan Sets"]] = "AtlasLootT35SetMenu",
		[L["Tier 0/0.5 Sets"]] = "AtlasLootT0SetMenu",
		[L["Tier 1 Sets"]] = "AtlasLootT1SetMenu",
		[L["Tier 1 Sets"] .. " (V+)"] = "AtlasLootT1VPSetMenu",
		[L["Tier 2 Sets"]] = "AtlasLootT2SetMenu",
		[L["Tier 3 Sets"]] = "AtlasLootT3SetMenu",
		[L["World Blues"]] = "AtlasLootWorldBluesMenu",
	}

	local lootTable = menuMapping[menuName]
	if lootTable then
		AtlasLootItemsFrame.StoredElement = { menuName = menuName }
		AtlasLootItemsFrame.StoredMenu = lootTable
		-- Call menu function
		if type(_G[lootTable]) == "function" then
			_G[lootTable]()
		else
			Atlas.LootBrowserUI.ScrollBarLootUpdate()
		end
	end
	if AtlasLoot_Hewdrop and AtlasLoot_Hewdrop.Close then
		AtlasLoot_Hewdrop:Close(1)
	end
	CloseDropDownMenus()
end

---
--- Handles clicks on AtlasLoot Hewdrop menu items
--- Opens the appropriate loot table or submenu based on selection type
--- @param tablename string Internal loot table key or submenu identifier
--- @param text string Display text of the menu item for UI updates
--- @param tabletype string Type of the item ("Boss", "Submenu", "Table")
--- @return nil
--- @usage AtlasLoot_HewdropClick("MC_Ragnaros", "Ragnaros", "Boss")
---
function AtlasLoot_HewdropClick(tablename, text, tabletype)
	-- Reset scroll to top, as in clicks on dungeon page items
	FauxScrollFrame_SetOffset(AtlasLootScrollBar, 0)
	AtlasLootScrollBarScrollBar:SetValue(0)

	if not tablename then return end

	-- Save parent menu for "Back" button
	local prevStored = AtlasLootItemsFrame.StoredElement
	if type(prevStored) == "table" and prevStored.menuName then
		AtlasLootItemsFrame.StoredBackMenuName = prevStored.menuName
	end

	-- Initialize table source and page name
	local TableSource = tablename
	local pagename = text

	-- If item from Dungeons, try to determine instance and first boss
	local effectiveInstanceKey, effectiveFirstBoss
	if type(tablename) == "string" and Atlas and Atlas.MenuData and Atlas.MenuData.Dungeons then
		for _, entry in ipairs(Atlas.MenuData.Dungeons) do
			if entry and (entry.lootpage == tablename or entry.lootpage == tablename) then
				effectiveInstanceKey = entry.lootpage
				effectiveFirstBoss = entry.firstBoss
				break
			end
		end
	end

	if effectiveInstanceKey and effectiveFirstBoss then
		TableSource = effectiveInstanceKey
		pagename = effectiveFirstBoss
		AtlasLootItemsFrame.StoredCurrentInstance = effectiveInstanceKey

		-- Set current instance in Atlas dropdown lists
		local function FindAndSetAtlasIndicesByInstance(instKey)
			if not (Atlas and Atlas.DropDowns and instKey) then return false end
			local ddCount = table.getn(Atlas.DropDowns)
			for typeIndex = 1, ddCount do
				local dropDownData = Atlas.DropDowns[typeIndex]
				if type(dropDownData) == "table" then
					local m = table.getn(dropDownData)
					for zoneIndex = 1, m do
						if dropDownData[zoneIndex] == instKey then
							AtlasOptions.AtlasType = typeIndex
							AtlasOptions.AtlasZone = zoneIndex
							Atlas.Refresh()
							Atlas.FrameDropDownTypeOnShow()
							Atlas.FrameDropDownOnShow()
							return true
						end
					end
				end
			end
			return false
		end
		local matched = FindAndSetAtlasIndicesByInstance(effectiveInstanceKey)
		if not matched then
			if Atlas and Atlas.PopulateDropdowns then Atlas.PopulateDropdowns() end
			matched = FindAndSetAtlasIndicesByInstance(effectiveInstanceKey)
		end
		-- After changing instance, select first boss in right list if it exists
		if effectiveFirstBoss then
			AtlasLootItemsFrame.activeElement = nil
			if Atlas and Atlas.ScrollList and Atlas.CurrentLine then
				for i = 1, Atlas.CurrentLine do
					local e = Atlas.ScrollList[i]
					if e then
						if e.id == effectiveFirstBoss or (type(effectiveFirstBoss) == "string" and (e.name == effectiveFirstBoss or e.line == effectiveFirstBoss)) then
							AtlasLootItemsFrame.activeElement = i
							break
						end
					end
				end
			end
			Atlas.LootBrowserUI.ScrollBarUpdate()
		end
	end
	-- Special handling for Rare Mobs
	if pagename == LocalizedStrings.RareMobs then
		pagename = LM["Shade Mage"]
	end

	-- Remove color codes from text if available
	pagename = Atlas.LootUtils.StripFormatting(pagename)

	-- Display and loading
	AtlasLootItemsFrame:Show()
	Atlas.LootBrowserUI.ShowScrollBarLoading()

	AtlasLootItemsFrame.StoredElement = pagename
	AtlasLootItemsFrame.StoredMenu = TableSource

	local newTable = nil
	if type(TableSource) == "table" then
		newTable = TableSource
	elseif type(TableSource) == "string" then
		newTable = AtlasLoot_Data[TableSource]
		if not newTable and type(pagename) == "string" then
			newTable = Atlas.DataResolver.GetLootByElemName(pagename, TableSource)
		end
		if not newTable and type(pagename) == "string" then
			newTable = Atlas.DataResolver.GetLootByElemName(pagename)
		end
		if not newTable then
			newTable = Atlas.DataResolver.GetLootByElemName(TableSource)
		end
	end

	Atlas.LootCache.CacheAllItems(newTable, function()
		Atlas.LootBrowserUI.HideScrollBarLoading()
		Atlas.LootBrowserUI.ScrollBarLootUpdate()
	end)

	AtlasLootItemsFrame_SelectedCategory:SetText(Atlas.LootUtils.TruncateText(pagename, 30))
	AtlasLootItemsFrame_SelectedCategory:Show()
	AtlasLoot_Hewdrop:Close(1)
end

---
--- Constructs and registers the main category menu
--- Creates tiered dropdown menu structure for loot browsing with Hewdrop-2.0
--- @return nil
--- @usage AtlasLoot_HewdropRegister()
---
function AtlasLoot_HewdropRegister()
	AtlasLoot_Hewdrop:Register(AtlasLootItemsFrame_Menu,
		'point', function()
			return "TOP", "BOTTOM"
		end,
		'children', function(level, value)
			if level == 1 then
				if AtlasLoot_HewdropDown then
					for _, v in ipairs(AtlasLoot_HewdropDown) do
						--If a link to show a submenu
						if type(v[1]) == "table" and type(v[1][1]) == "string" then
							if v[1][3] == "Submenu" then
								AtlasLoot_Hewdrop:AddLine(
									'text', v[1][1],
									'textR', 1,
									'textG', 0.82,
									'textB', 0,
									'func', AtlasLoot_HewdropClick,
									'arg1', v[1][2],
									'arg2', v[1][1],
									'arg3', v[1][3],
									'notCheckable', true
								)
							end
						else
							local lock = 0
							--If an entry linked to a subtable
							for i, j in pairs(v) do
								if lock == 0 then
									AtlasLoot_Hewdrop:AddLine(
										'text', i,
										'textR', 1,
										'textG', 0.82,
										'textB', 0,
										'hasArrow', true,
										'value', j,
										'func', AtlasLoot_OpenMenu,
										'arg1', i,
										'notCheckable', true
									)
									lock = 1
								end
							end
						end
					end
				end
			elseif level == 2 then
				if value then
					for _, v in ipairs(value) do
						if type(v) == "table" then
							if type(v[1]) == "table" and type(v[1][1]) == "string" then
								--If an entry to show a submenu
								if v[1][3] == "Submenu" then
									AtlasLoot_Hewdrop:AddLine(
										'text', v[1][1],
										'textR', 1,
										'textG', 0.82,
										'textB', 0,
										'func', AtlasLoot_HewdropClick,
										'arg1', v[1][2],
										'arg2', v[1][1],
										'arg3', v[1][3],
										'notCheckable', true
									)
									--An entry to show a specific loot page
								else
									AtlasLoot_Hewdrop:AddLine(
										'text', v[1][1],
										'textR', 1,
										'textG', 0.82,
										'textB', 0,
										'func', AtlasLoot_HewdropClick,
										'arg1', v[1][2],
										'arg2', v[1][1],
										'arg3', v[1][3] or "Table",
										'notCheckable', true
									)
								end
							else
								local lock = 0
								--Entry to link to a sub table
								for i, j in pairs(v) do
									if lock == 0 then
										AtlasLoot_Hewdrop:AddLine(
											'text', i,
											'textR', 1,
											'textG', 0.82,
											'textB', 0,
											'hasArrow', true,
											'value', j,
											'notCheckable', true
										)
										lock = 1
									end
								end
							end
						end
					end
				end
			elseif level == 3 then
				--Essentially the same as level == 2
				if value then
					for k, v in pairs(value) do
						if type(v[1]) == "string" then
							if v[3] == "Submenu" then
								AtlasLoot_Hewdrop:AddLine(
									'text', v[1],
									'textR', 1,
									'textG', 0.82,
									'textB', 0,
									'func', AtlasLoot_HewdropClick,
									'arg1', v[2],
									'arg2', v[1],
									'arg3', v[3],
									'notCheckable', true
								)
							else
								AtlasLoot_Hewdrop:AddLine(
									'text', v[1],
									'textR', 1,
									'textG', 0.82,
									'textB', 0,
									'func', AtlasLoot_HewdropClick,
									'arg1', v[2],
									'arg2', v[1],
									'arg3', v[3] or "Table",
									'notCheckable', true
								)
							end
						elseif type(v) == "table" then
							AtlasLoot_Hewdrop:AddLine(
								'text', k,
								'textR', 1,
								'textG', 0.82,
								'textB', 0,
								'hasArrow', true,
								'value', v,
								'notCheckable', true
							)
						end
					end
				end
			end
		end,
		'dontHook', true
	)
end
