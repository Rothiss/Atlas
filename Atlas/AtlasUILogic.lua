---
--- AtlasUILogic.lua - Atlas UI logic and minimap button functionality
---
--- This file contains UI logic functions for Atlas including minimap button
--- management, position handling, and UI interaction logic. It provides the
--- core functionality for Atlas UI components and user interface behavior.
---
--- Features:
--- - Minimap button initialization and positioning
--- - UI state management and updates
--- - Button interaction handling
--- - Position calculation and storage
---
--- @compatible World of Warcraft 1.12
---

local _G = getfenv()
Atlas = _G.Atlas or {}

local L = Atlas.Localization.UI

-- Minimap button logic
---
--- Sets the minimap button position
--- Updates the button position angle and refreshes the display
--- @param v number Position angle in degrees
--- @return nil
--- @usage AtlasButtonSetPosition(45) -- Set button to 45 degrees
---
local function AtlasButtonSetPosition(v)
	if v < 0 then
		v = v + 360
	end
	AtlasOptions.AtlasButtonPosition = v
	Atlas.MinimapButtonUpdatePosition()
end

---
--- Initializes the minimap button
--- Shows or hides the button based on settings and updates position
--- @return nil
--- @usage Atlas.MinimapButtonInit() -- Called during addon initialization
---
function Atlas.MinimapButtonInit()
	if AtlasOptions.AtlasButtonShown then
		AtlasButtonFrame:Show()
	else
		AtlasButtonFrame:Hide()
	end
	Atlas.MinimapButtonUpdatePosition()
end

---
--- Toggles minimap button visibility
--- Shows or hides the minimap button and saves the setting
--- @return nil
--- @usage Atlas.MinimapButtonOnClick() -- Called by button click
---
function Atlas.MinimapButtonOnClick()
	if AtlasButtonFrame:IsVisible() then
		AtlasButtonFrame:Hide()
		AtlasOptions.AtlasButtonShown = false
	else
		AtlasButtonFrame:Show()
		AtlasOptions.AtlasButtonShown = true
	end
	Atlas.OptionsInit()
end

---
--- Updates the minimap button position
--- Calculates and sets the button position based on radius and angle
--- @return nil
--- @usage Atlas.MinimapButtonUpdatePosition() -- Called when position changes
---
function Atlas.MinimapButtonUpdatePosition()
	local radius = AtlasOptions.AtlasButtonRadius
	local position = AtlasOptions.AtlasButtonPosition
	AtlasButtonFrame:SetPoint(
		"TOPLEFT",
		"Minimap",
		"TOPLEFT",
		54 - (radius * cos(position)),
		(radius * sin(position)) - 55
	)
	Atlas.OptionsInit()
end

-- Handles minimap button dragging
---
--- Handles minimap button dragging
--- Updates button position while being dragged around the minimap
--- @return nil
--- @usage Atlas.MinimapButtonBeingDragged() -- Called during drag events
---
function Atlas.MinimapButtonBeingDragged()
	local xpos, ypos = GetCursorPosition()
	local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom()
	local scale = UIParent:GetScale()
	xpos = xmin - xpos / scale + 70
	ypos = ypos / scale - ymin - 70
	AtlasButtonSetPosition(math.deg(math.atan2(ypos, xpos)))
end

-- Minimap button OnEnter handler
---
--- Handles mouse enter events for minimap button
--- Shows tooltip with Atlas information when hovering over button
--- @return nil
--- @usage Atlas.MinimapButtonOnEnter() -- Called on mouse enter
---
function Atlas.MinimapButtonOnEnter()
	GameTooltip:SetOwner(this, "ANCHOR_LEFT")
	GameTooltip:SetText(Atlas.Name)
	GameTooltip:AddLine(
		L["Left-click to open Atlas.\nMiddle-click for Atlas options.\nRight-click and drag to move this button."],
		1,
		1, 1, true)
	GameTooltip:Show()
end

-- Atlas logic
--Sets the transparency of the Atlas frame based on AtlasAlpha
---
--- Updates the Atlas frame transparency
--- Sets the frame alpha based on current option settings
--- @return nil
--- @usage Atlas.OptionsUpdateAlpha() -- Called when alpha setting changes
---
function Atlas.OptionsUpdateAlpha()
	AtlasFrame:SetAlpha(AtlasOptions.AtlasAlpha)
end

--Sets the scale of the Atlas frame based on AtlasScale
---
--- Updates the Atlas frame scale
--- Sets the frame scale based on current option settings
--- @return nil
--- @usage Atlas.OptionsUpdateScale() -- Called when scale setting changes
---
function Atlas.OptionsUpdateScale()
	AtlasFrame:SetScale(AtlasOptions.AtlasScale)
end

--Simple function to toggle the visibility of the Atlas frame
---
--- Toggles the Atlas frame visibility
--- Shows or hides the main Atlas frame
--- @return nil
--- @usage Atlas.ToggleAtlas() -- Called by slash command or button
---
function Atlas.ToggleAtlas()
	if AtlasFrame:IsVisible() then
		AtlasFrame:Hide()
	else
		AtlasFrame:Show()
	end
end

---
--- Shows the update marker on the main frame based on version state
--- @return nil
---
function Atlas.UpdateMarkerRefresh()
	local marker = _G["AtlasUpdateMarker"]
	if not marker then return end
	AtlasUpdateMarker:Show()
end

--Parses slash commands
--If an unrecognized command is given, toggle Atlas
---
--- Handles Atlas slash commands
--- Processes slash command arguments and executes appropriate actions
--- @param msg string Command arguments from slash command
--- @return nil
--- @usage Atlas.SlashCommand("toggle") -- Process slash command
---
---
function Atlas.SlashCommand(msg)
	msg = string.lower(msg or '')
	if msg == "options" or msg == "opt" then
		Atlas.OptionsOnClick()
	elseif msg == 'ver check' then
		Atlas.VersionCheck.publishVersion()
		PrintA(format(L["Version check sent to %s"], Atlas.VersionCheck.channelName))
	elseif msg == 'ver' then
		PrintA(format(L["Version: %s"], Atlas.VersionCheck.getLocalVersionString()))
	else
		Atlas.ToggleAtlas()
	end
end

--Begin moving the Atlas frame if it's unlocked
---
--- Starts moving the Atlas frame
--- Initiates frame dragging if not locked
--- @return nil
--- @usage Atlas.StartMoving() -- Called on drag start
---
function Atlas.StartMoving()
	if not AtlasOptions.AtlasLocked then
		AtlasFrame:StartMoving()
		AtlasFrame.isMoving = true
	end
end

--RightButton closes Atlas and open the World Map if the RightClick option is turned on
---
--- Handles Atlas frame click events
--- Processes mouse clicks on the Atlas frame
--- @return nil
--- @usage Atlas.OnClick() -- Called on frame click
---
function Atlas.OnClick()
	if arg1 == "RightButton" then
		if AtlasOptions.AtlasRightClick then
			Atlas.ToggleAtlas()
			ToggleWorldMap()
		end
	end
end
