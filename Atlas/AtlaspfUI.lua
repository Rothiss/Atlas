---
--- AtlaspfUI.lua - pfUI Integration for Atlas
---
--- This file contains pfUI styling integration for Atlas frames and components.
--- It applies pfUI's CreateBackdrop and CreateBackdropShadow functions to all Atlas
--- frames when pfUI is detected, creating a unified visual style.
---
--- Features:
--- - Automatic detection of pfUI addon
--- - Application of pfUI backdrops to main Atlas frame
--- - Styling of dropdown menus and buttons
--- - Integration with pfUI's border and color system
--- - Styling of loot panel and quest frames
--- - pfUI tooltip integration
---
--- @compatible World of Warcraft 1.12
--- @requires pfUI addon
---

local _G = getfenv()
Atlas = _G.Atlas

-- Initialize pfUI integration module
Atlas.pfUI = {}

---
--- Checks if pfUI addon is loaded and available
--- @return boolean - true if pfUI is loaded
---
local function IsPfUIBaseLoaded()
    return (IsAddOnLoaded("pfUI") and pfUI)
end

---
--- Checks if pfUI addon is loaded and styling is enabled in Atlas options
--- @return boolean - true if pfUI is loaded and styling is enabled
---
local function IsPfUIStylingEnabled()
    if not IsPfUIBaseLoaded() or not pfUI.api or not pfUI.api.CreateBackdrop then
        return false
    end

    -- Check if user has disabled pfUI styling in options
    if AtlasOptions and AtlasOptions.pfUIEnabled == false then
        return false
    end

    return true
end

---
--- Gets the pfUI border background color safely
--- @return number, number, number, number - r, g, b, a
---
local function GetPfUIBackgroundColor()
    if pfUI_config and pfUI_config.appearance and pfUI_config.appearance.border and pfUI_config.appearance.border.background then
        return pfUI.api.GetStringColor(pfUI_config.appearance.border.background)
    end
    return 0, 0, 0, 0.8 -- Default fallback
end

---
--- Applies pfUI styling to the main Atlas frame
--- Removes default textures and applies pfUI backdrop
---
local function StyleMainFrame()
    if not AtlasFrame then return end

    -- Hide default Atlas textures
    -- Note: We keep the border textures visible as they define the Atlas window shape
    -- Only hide background if user wants full pfUI integration

    local textures = {
        "AtlasFrameTop",
        "AtlasFrameLeft",
        "AtlasFrameBottom",
        "AtlasFrameBottom2",
        "AtlasFrameRight"
    }

    for _, texName in ipairs(textures) do
        local tex = _G[texName]
        if tex then
            tex:Hide()
        end
    end

    -- Create pfUI backdrop
    if pfUI.api.CreateBackdrop then
        pfUI.api.CreateBackdrop(AtlasFrame, nil, nil, 0.9)
        pfUI.api.CreateBackdropShadow(AtlasFrame)

        -- Apply border color if available
        if AtlasFrame.backdrop then
            local r, g, b, a = GetPfUIBackgroundColor()
            AtlasFrame.backdrop:SetBackdropColor(r, g, b, 0.9)
        end
    end

    -- Adjust frame strata to work with pfUI
    if AtlasFrame.backdrop then
        AtlasFrame.backdrop:SetFrameStrata("HIGH")
        AtlasFrame.backdrop:SetFrameLevel(AtlasFrame:GetFrameLevel() - 1)

        -- Ensure backdrop doesn't capture mouse if main frame is mouse-disabled (locked)
        AtlasFrame.backdrop:EnableMouse(false)
    end

    -- Style the close button (X button)
    if AtlasCloseButton then
        -- Close button needs special handling - it's a UIPanelCloseButton template
        -- User requested no large black contour. pfUI might auto-skin it, so we hide its backdrop.
        if AtlasCloseButton.backdrop then
            AtlasCloseButton.backdrop:Hide()
        end

        AtlasCloseButton:SetNormalTexture("")
        AtlasCloseButton:SetPushedTexture("")
        AtlasCloseButton:SetHighlightTexture("")

        -- Create custom X texture
        if not AtlasCloseButton.customX then
            local customX = AtlasCloseButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            customX:SetPoint("CENTER", 0, 0)
            customX:SetText("×")
            customX:SetTextColor(1, 0.2, 0.2)
            customX:SetFont("Fonts\\ARIALN.TTF", 20, "OUTLINE")
            AtlasCloseButton.customX = customX
        end

        -- Set fixed size to avoid wide background if any
        AtlasCloseButton:SetWidth(20)
        AtlasCloseButton:SetHeight(20)
        AtlasCloseButton:ClearAllPoints()
        AtlasCloseButton:SetPoint("TOPRIGHT", AtlasFrame, "TOPRIGHT", -1, -14)

        -- Hover effect
        AtlasCloseButton:SetScript("OnEnter", function()
            if this.customX then
                this.customX:SetTextColor(1, 0.4, 0.4)
                this.customX:SetFont("Fonts\\ARIALN.TTF", 22, "OUTLINE")
            end
        end)
        AtlasCloseButton:SetScript("OnLeave", function()
            if this.customX then
                this.customX:SetTextColor(1, 0.2, 0.2)
                this.customX:SetFont("Fonts\\ARIALN.TTF", 20, "OUTLINE")
            end
        end)

        AtlasCloseButton.pfui_skinned = true
    end

    -- Style the lock button
    if AtlasLockButton then
        -- No backdrop for lock button as requested. Hide pfUI auto-backdrop if present.
        if AtlasLockButton.backdrop then
            AtlasLockButton.backdrop:Hide()
        end

        -- Use textures instead of text for better reliability
        AtlasLockButton:SetWidth(20)
        AtlasLockButton:SetHeight(20)
        AtlasLockButton:ClearAllPoints()
        AtlasLockButton:SetPoint("RIGHT", AtlasCloseButton, "LEFT", 0, 0)

        -- Hook the toggle function to update display
        local originalOnClick = AtlasLockButton:GetScript("OnClick")
        AtlasLockButton:SetScript("OnClick", function()
            if originalOnClick then originalOnClick() end
            if Atlas.UpdateLock then
                Atlas.UpdateLock()
            end
        end)

        if Atlas.UpdateLock then
            Atlas.UpdateLock()
        end
        AtlasLockButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")

        AtlasLockButton.pfui_skinned = true
    end
end

---
--- Re-applies pfUI styling to a button
--- @param buttonName string - Name of the button to restyle
---
function Atlas.pfUI.RestyleButton(buttonName)
    if not IsPfUIStylingEnabled() then return end
    local button = _G[buttonName]
    if not button then return end

    if pfUI.api.SkinButton then
        -- If not already skinned, skin it
        if not button.pfui_skinned then
            pfUI.api.SkinButton(button)
            button.pfui_skinned = true
        end

        -- If it was already skinned but textures became visible (e.g. after Show/SetText)
        -- we just hide them instead of re-skinning to avoid multiple backdrops
        if button:GetNormalTexture() and button:GetNormalTexture():IsShown() then
            button:GetNormalTexture():Hide()
        end
        if button:GetPushedTexture() and button:GetPushedTexture():IsShown() then
            button:GetPushedTexture():Hide()
        end
        if button:GetDisabledTexture() and button:GetDisabledTexture():IsShown() then
            button:GetDisabledTexture():Hide()
        end
    end
end

function Atlas.pfUI.SkinCollapseAllButton(button)
    if not IsPfUIStylingEnabled() then return end
    if not button then return end

    if pfUI.api.SkinCollapseButton and not button.pfui_collapse_base then
        pfUI.api.SkinCollapseButton(button, true)
        button.pfui_collapse_base = true
    end

    if not button.icon then return end

    if button.icon.EnableMouse then
        button.icon:EnableMouse(false)
    end
    button.icon:ClearAllPoints()
    button.icon:SetPoint("LEFT", button, "LEFT", 2, 0)
    button:SetHitRectInsets(0, 0, 0, 0)

    if button.text then
        button.text:ClearAllPoints()
        button.text:SetPoint("LEFT", button, "LEFT", 18, 0)
    end

    if not button.pfui_set_normaltexture then
        button.pfui_set_normaltexture = button.SetNormalTexture
    end
    if not button.pfui_set_pushedtexture then
        button.pfui_set_pushedtexture = button.SetPushedTexture
    end

    local normalTexture = button:GetNormalTexture()
    local currentTexture = normalTexture and normalTexture:GetTexture()

    local function UpdateCollapseIcon(self, texture)
        if not self.icon or not self.icon.text then return end
        if not texture or texture == "" then
            self.icon:Hide()
            return
        end
        self.icon.text:SetText(strfind(texture, "MinusButton") and "-" or "+")
        self.icon:Show()
    end

    button.pfui_set_normaltexture(button, nil)
    button.pfui_set_pushedtexture(button, nil)
    button.SetNormalTexture = UpdateCollapseIcon
    button.SetPushedTexture = UpdateCollapseIcon
    button:SetNormalTexture(currentTexture)
end

---
--- Skins an arrow button with pfUI style but keeps arrow indication
--- @param button Button - The button to skin
--- @param direction string - Direction of arrow ("left", "right", "up", "down")
---
function Atlas.pfUI.SkinArrowButton(button, direction)
    if not IsPfUIStylingEnabled() then return end
    if not button then return end

    -- Fix button size (increase clickbox size, was 18)
    button:SetWidth(24)
    button:SetHeight(24)

    -- Ensure no backdrop is applied (pfUI arrows are floating textures)
    if button.backdrop then
        button.backdrop:Hide()
    end
    button.pfui_skinned = true

    -- Set pfUI arrow textures
    -- Note: We assume standard pfUI directory structure
    local texturePath = "Interface\\AddOns\\pfUI\\img\\"

    -- Helper to constrain texture size
    local function SkinTexture(tex)
        if tex then
            tex:ClearAllPoints()
            tex:SetPoint("CENTER", 0, 0)
            tex:SetWidth(16)
            tex:SetHeight(16)
        end
    end

    if direction == "left" or direction == "right" or direction == "up" or direction == "down" then
        local tex = texturePath .. direction
        button:SetNormalTexture(tex)
        button:SetPushedTexture(tex)
        button:SetDisabledTexture(tex)

        SkinTexture(button:GetNormalTexture())
        SkinTexture(button:GetPushedTexture())
        SkinTexture(button:GetDisabledTexture())
    end

    -- Adjust Pushed/Disabled visual feedback
    if button:GetPushedTexture() then
        button:GetPushedTexture():SetVertexColor(0.5, 0.5, 0.5)
        button:GetPushedTexture():SetPoint("CENTER", 1, -1) -- Simulate button press offset
    end

    if button:GetDisabledTexture() then
        button:GetDisabledTexture():SetDesaturated(true)
        button:GetDisabledTexture():SetAlpha(0.5)
    end

    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
end

---
--- Skins an editbox with pfUI style
--- @param editbox EditBox - The editbox to skin
---
function Atlas.pfUI.SkinEditBox(editbox)
    if not IsPfUIStylingEnabled() then return end
    if not editbox then return end
    if editbox.pfui_skinned then return end

    -- Hide standard WoW editbox textures to prevent "strange border" look
    local name = editbox:GetName()
    if name then
        local left = _G[name .. "Left"]
        local middle = _G[name .. "Middle"]
        local right = _G[name .. "Right"]

        if left then left:Hide() end
        if middle then middle:Hide() end
        if right then right:Hide() end
    end

    -- Also hide any textures attached directly to regions if they are standard borders
    -- (This is a fallback if names don't match or for anonymous frames)
    for _, region in ipairs({ editbox:GetRegions() }) do
        if region:GetObjectType() == "Texture" then
            local texture = region:GetTexture()
            if texture then
                -- Check for standard editbox textures
                if string.find(texture, "Interface\\Common\\Common-Input-Border") or
                    string.find(texture, "Interface\\ChatFrame\\UI-Chat-") then
                    region:Hide()
                end
            end
        end
    end

    if pfUI.api.CreateBackdrop then
        pfUI.api.CreateBackdrop(editbox, nil, true)
    end
    editbox.pfui_skinned = true
end

---
--- Applies pfUI styling to dropdown buttons
--- Styles the category and map selection dropdowns
---
local function StyleDropdowns()
    local dropdowns = {
        AtlasFrameDropDownType,
        AtlasFrameDropDown,
    }

    for _, dropdown in ipairs(dropdowns) do
        if dropdown then
            -- Apply pfUI backdrop
            pfUI.api.CreateBackdrop(dropdown, nil, true, 0.8)

            -- Adjust colors to match pfUI
            if dropdown.backdrop then
                local r, g, b, a = pfUI.api.GetStringColor(pfUI_config.appearance.border.background)
                dropdown.backdrop:SetBackdropColor(r, g, b, a)
            end
        end
    end
end

---
--- Applies pfUI styling to buttons
--- Styles all major buttons in the Atlas interface using pfUI.api.SkinButton
---
local function StyleButtons()
    -- Use pfUI's SkinButton function for proper button styling
    if not pfUI.api.SkinButton then return end

    -- Direct named buttons
    local namedButtons = {
        "AtlasSwitchButton",
        "AtlasLootFilterButton",
    }

    for _, buttonName in ipairs(namedButtons) do
        local button = _G[buttonName]
        if button then
            if not button.pfui_skinned then
                pfUI.api.SkinButton(button)
                button.pfui_skinned = true
            end
        end
    end

    -- Find and style all button children of AtlasFrame
    if AtlasFrame then
        for _, child in ipairs({ AtlasFrame:GetChildren() }) do
            if not child.pfui_skinned then
                if child:GetObjectType() == "Button" then
                    -- Skip close and lock buttons as they are handled separately
                    if child ~= AtlasCloseButton and child ~= AtlasLockButton then
                        pfUI.api.SkinButton(child)
                        child.pfui_skinned = true
                    end
                elseif child:GetObjectType() == "CheckButton" and pfUI.api.SkinCheckbox then
                    pfUI.api.SkinCheckbox(child)
                    child.pfui_skinned = true
                end
            end
        end
    end

    -- Style search buttons in main frame
    if AtlasSearchEditBox then
        -- The search and clear buttons are children of the edit box, not siblings!
        for _, child in ipairs({ AtlasSearchEditBox:GetChildren() }) do
            if child:GetObjectType() == "Button" and not child.pfui_skinned then
                pfUI.api.SkinButton(child)
                child.pfui_skinned = true
            end
        end
    end
end

---
--- Applies pfUI styling to search box
--- Styles the loot search editbox WITHOUT backdrop (editboxes shouldn't have backdrop)
---
local function StyleSearchBox()
    -- Style the main Atlas search editbox
    if not AtlasSearchEditBox then return end

    Atlas.pfUI.SkinEditBox(AtlasSearchEditBox)
    AtlasSearchEditBox:SetHeight(20) -- Fix height for pfUI style

    if pfUI.api.SkinButton and AtlasNoticeBox then
        Atlas.pfUI.SkinEditBox(AtlasNoticeBox)
    end
    -- Also style the search button in the loot panel (handled in StyleLootPanel, but just in case)
    if pfUI.api.SkinButton and AtlasLootSearchBox then
        Atlas.pfUI.SkinEditBox(AtlasLootSearchBox)
    end
end

---
--- Skins a scrollbar with pfUI style
--- @param scrollFrame ScrollFrame - The scrollframe to skin
---
function Atlas.pfUI.SkinScrollBar(scrollFrame)
    if not IsPfUIStylingEnabled() then return end
    if not scrollFrame then return end
    if scrollFrame.pfui_skinned then return end

    -- Detect if this is a FauxScrollFrame or similar wrapper where the actual scrollbar is a child
    local scrollBarWidget = scrollFrame
    local name = scrollFrame:GetName()
    if name then
        -- Check for "ScrollBar" suffix child, which is standard for FauxScrollFrameTemplate
        local childScrollBar = _G[name .. "ScrollBar"]
        if childScrollBar then
            scrollBarWidget = childScrollBar
        end
    end

    -- Use pfUI's built-in scrollbar skinner if available
    if pfUI.api.SkinScrollbar then
        -- Wrap in pcall to prevent errors if the scrollbar structure is unexpected
        -- Pass the widget that is likely the slider/scrollbar
        local success, err = pcall(pfUI.api.SkinScrollbar, scrollBarWidget)
        -- if not success then PrintA("Atlas: pfUI SkinScrollbar error: " .. tostring(err)) end
    else
        -- Manual fallback if pfUI doesn't expose SkinScrollbar
        local sbName = scrollBarWidget:GetName()
        if sbName then
            local upButton = _G[sbName .. "ScrollUpButton"]
            local downButton = _G[sbName .. "ScrollDownButton"]

            if upButton then Atlas.pfUI.SkinArrowButton(upButton, "up") end
            if downButton then Atlas.pfUI.SkinArrowButton(downButton, "down") end
        end
    end

    scrollFrame.pfui_skinned = true
    -- Also mark the child as skinned to prevent double skinning if called directly later
    if scrollBarWidget ~= scrollFrame then
        scrollBarWidget.pfui_skinned = true
    end
end

---
--- Applies pfUI styling to the scrollbar frame
--- Styles the loot items scrollbar
---
local function StyleScrollBar()
    if AtlasScrollBar then
        -- Style scrollbar background
        pfUI.api.CreateBackdrop(AtlasScrollBar, nil, nil, 0.3)
        Atlas.pfUI.SkinScrollBar(AtlasScrollBar)
    end

    if AtlasLootScrollBar then
        Atlas.pfUI.SkinScrollBar(AtlasLootScrollBar)
    end
end

---
--- Applies pfUI styling to loot items frame
--- Styles the main loot display area with black background
---
local function StyleLootItemsFrame()
    if not AtlasLootItemsFrame then return end

    -- Apply backdrop to loot items frame
    pfUI.api.CreateBackdrop(AtlasLootItemsFrame, nil, nil, 1.0)

    -- Use pfUI background color if available
    local r, g, b, a = GetPfUIBackgroundColor()
    if AtlasLootItemsFrame.backdrop then
        -- Make the backdrop background transparent so we don't double-draw with the texture
        AtlasLootItemsFrame.backdrop:SetBackdropColor(r, g, b, 0)
    end

    -- Style the original background texture
    -- We use the original texture but color it to match pfUI
    local backTexture = _G["AtlasLootItemsFrame_Back"]
    if backTexture then
        -- Restore it if it was hidden
        backTexture.Show = nil -- Remove the dummy function if present
        backTexture:Show()

        -- Reset vertex color to white so it doesn't tint our texture black
        -- (LootUI.lua sets it to 0,0,0,0.7 which causes the "always black" issue)
        backTexture:SetVertexColor(1, 1, 1, 1)

        -- Set the texture to the pfUI background color
        backTexture:SetTexture(r, g, b, a)
        backTexture:SetAlpha(a)
    end

    -- Fallback: iterate and fix any other background textures if the named one wasn't found
    -- (This part is just a safety measure)
    if not backTexture then
        for _, region in ipairs({ AtlasLootItemsFrame:GetRegions() }) do
            if region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
                local p1, p2, p3, p4, p5 = region:GetPoint()
                if p1 == "TOPLEFT" or p1 == "BOTTOMLEFT" or p1 == "TOPRIGHT" or p1 == "BOTTOMRIGHT" or p1 == "CENTER" or p1 == "ALL" then
                    region:SetVertexColor(1, 1, 1, 1)
                    region:SetTexture(r, g, b, a)
                    region:SetAlpha(a)
                end
            end
        end
    end

    -- Style the loot items frame close button
    local itemsCloseButton = _G["AtlasLootItemsFrame_CloseButton"]
    if itemsCloseButton then
        -- Hide pfUI auto-backdrop if present.
        if itemsCloseButton.backdrop then
            itemsCloseButton.backdrop:Hide()
        end

        itemsCloseButton:SetNormalTexture("")
        itemsCloseButton:SetPushedTexture("")
        itemsCloseButton:SetHighlightTexture("")

        -- Create custom X texture
        if not itemsCloseButton.customX then
            local customX = itemsCloseButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            customX:SetPoint("CENTER", 0, 0)
            customX:SetText("×")
            customX:SetTextColor(1, 0.2, 0.2)
            customX:SetFont("Fonts\\ARIALN.TTF", 20, "OUTLINE")
            itemsCloseButton.customX = customX
        end

        -- Position and size to match main frame buttons
        itemsCloseButton:SetWidth(20)
        itemsCloseButton:SetHeight(20)
        itemsCloseButton:ClearAllPoints()
        itemsCloseButton:SetPoint("TOPRIGHT", AtlasLootItemsFrame, "TOPRIGHT", -15, -3)

        -- Hover effect
        itemsCloseButton:SetScript("OnEnter", function()
            if this.customX then
                this.customX:SetTextColor(1, 0.4, 0.4)
                this.customX:SetFont("Fonts\\ARIALN.TTF", 22, "OUTLINE")
            end
        end)
        itemsCloseButton:SetScript("OnLeave", function()
            if this.customX then
                this.customX:SetTextColor(1, 0.2, 0.2)
                this.customX:SetFont("Fonts\\ARIALN.TTF", 20, "OUTLINE")
            end
        end)

        itemsCloseButton.pfui_skinned = true
    end

    -- Style all item buttons in the loot frame
    for i = 1, 30 do
        local button = _G["AtlasLootItem" .. i]
        if button and not button.pfui_styled then
            -- Item buttons should have subtle backdrop
            pfUI.api.CreateBackdrop(button, nil, true, 0.3)
            button.pfui_styled = true
        end
    end

    -- Style Select Loot Table button
    if AtlasLootItemsFrame_Menu and not AtlasLootItemsFrame_Menu.pfui_skinned then
        pfUI.api.SkinButton(AtlasLootItemsFrame_Menu)
        AtlasLootItemsFrame_Menu.pfui_skinned = true
    end

    -- Style Back/Prev/Next buttons and QuickLooks button
    local navButtons = {
        "AtlasLootItemsFrame_BACK",
        "AtlasLootItemsFrame_PREV",
        "AtlasLootItemsFrame_NEXT",
        "AtlasLootQuickLooksButton"
    }

    for _, btnName in ipairs(navButtons) do
        local btn = _G[btnName]
        if btn and not btn.pfui_skinned then
            if btnName == "AtlasLootItemsFrame_BACK" then
                pfUI.api.SkinButton(btn)
            elseif btnName == "AtlasLootItemsFrame_PREV" then
                Atlas.pfUI.SkinArrowButton(btn, "left")
            elseif btnName == "AtlasLootItemsFrame_NEXT" then
                Atlas.pfUI.SkinArrowButton(btn, "right")
            elseif btnName == "AtlasLootQuickLooksButton" then
                Atlas.pfUI.SkinArrowButton(btn, "down")
            end
            btn.pfui_skinned = true
        end
    end
end

---
--- Applies pfUI styling to loot panel
--- Styles the bottom panel with navigation buttons
---
local function StyleLootPanel()
    if not AtlasLootPanel then return end

    -- Position Loot Panel relative to AtlasFrame for pfUI
    AtlasLootPanel:ClearAllPoints()
    AtlasLootPanel:SetPoint("TOP", "AtlasFrame", "BOTTOM", 0, 1)

    -- Apply pfUI backdrop
    pfUI.api.CreateBackdrop(AtlasLootPanel, nil, nil, 1.0)
    pfUI.api.CreateBackdropShadow(AtlasLootPanel)

    -- Use pfUI background color if available, otherwise pure black
    if AtlasLootPanel.backdrop then
        local r, g, b, a = GetPfUIBackgroundColor()
        AtlasLootPanel.backdrop:SetBackdropColor(r, g, b, 1)
    end

    -- Style the original background texture to match the backdrop in loot panel
    for _, region in ipairs({ AtlasLootPanel:GetRegions() }) do
        if region:GetObjectType() == "Texture" then
            local r, g, b, a = 0, 0, 0, 1
            if AtlasLootPanel.backdrop then
                r, g, b, a = AtlasLootPanel.backdrop:GetBackdropColor()
            end
            region:SetTexture(r, g, b, 1) -- Set alpha to 1 for "completely black"
            region:SetAlpha(1)
        end
    end

    -- Style all named loot panel buttons
    local panelButtons = {
        "AtlasLootPanel_Instances",   -- World
        "AtlasLootPanel_WorldEvents", -- World Events
        "AtlasLootPanel_Sets",        -- Collections
        "AtlasLootPanel_Reputation",  -- Factions
        "AtlasLootPanel_PvP",         -- PvP Rewards
        "AtlasLootPanel_Crafting",    -- Crafting
        "AtlasLootPanel_Dungeons",    -- Dungeons & Raids
    }

    if pfUI.api.SkinButton then
        for _, buttonName in ipairs(panelButtons) do
            local button = _G[buttonName]
            if button and not button.pfui_skinned then
                pfUI.api.SkinButton(button)
                button.pfui_skinned = true
            end
        end
    end

    -- Style menu item buttons (numbered buttons in panel)
    if pfUI.api.SkinButton then
        for i = 1, 20 do
            local button = _G["AtlasLootMenuItem" .. i]
            if button and not button.pfui_skinned then
                pfUI.api.SkinButton(button)
                button.pfui_skinned = true
            end
        end
    end

    -- Style all button children of the loot panel (includes Search, Clear, Last Result, WishList, etc)
    if pfUI.api.SkinButton and AtlasLootPanel then
        for _, child in ipairs({ AtlasLootPanel:GetChildren() }) do
            if child:GetObjectType() == "Button" and not child.pfui_skinned then
                pfUI.api.SkinButton(child)
                child.pfui_skinned = true
            end
        end
    end

    -- Style checkboxes in loot panel if any (like "Safe Links" etc are in options, but maybe some here)
    if pfUI.api.SkinCheckbox and AtlasLootPanel then
        for _, child in ipairs({ AtlasLootPanel:GetChildren() }) do
            if child:GetObjectType() == "CheckButton" and not child.pfui_skinned then
                pfUI.api.SkinCheckbox(child)
                child.pfui_skinned = true
            end
        end
    end

    -- Also style buttons that are children of the search box
    if pfUI.api.SkinButton and AtlasLootSearchBox then
        -- Style the search box itself
        Atlas.pfUI.SkinEditBox(AtlasLootSearchBox)

        for _, child in ipairs({ AtlasLootSearchBox:GetChildren() }) do
            if child:GetObjectType() == "Button" and not child.pfui_skinned then
                pfUI.api.SkinButton(child)
                child.pfui_skinned = true
            end
        end

        -- Style children of button children (for searchOptionsButton which is child of searchButton)
        for _, child in ipairs({ AtlasLootSearchBox:GetChildren() }) do
            if child:GetObjectType() == "Button" then
                for _, subchild in ipairs({ child:GetChildren() }) do
                    if subchild:GetObjectType() == "Button" and not subchild.pfui_skinned then
                        -- Check if this is the search options arrow button
                        local normalTexture = subchild:GetNormalTexture()
                        local texPath = normalTexture and normalTexture:GetTexture() or ""
                        if string.find(texPath, "NextPage") then
                            Atlas.pfUI.SkinArrowButton(subchild, "right")
                        elseif string.find(texPath, "PrevPage") then
                            Atlas.pfUI.SkinArrowButton(subchild, "left")
                        else
                            pfUI.api.SkinButton(subchild)
                        end
                        subchild.pfui_skinned = true
                    end
                end
            end
        end
    end
end

---
--- Applies pfUI styling to container window
--- Styles the item set/container popup
---
local function StyleContainerFrame()
    if not AtlasLootItemsFrameContainer then return end

    -- Apply pfUI backdrop to container
    pfUI.api.CreateBackdrop(AtlasLootItemsFrameContainer, nil, nil, 0.9)
    pfUI.api.CreateBackdropShadow(AtlasLootItemsFrameContainer)

    -- Style container item buttons
    for i = 1, 50 do
        local button = _G["AtlasLootItemsFrameContainerButton" .. i]
        if button and not button.pfui_styled then
            -- Container item buttons get subtle backdrop
            pfUI.api.CreateBackdrop(button, nil, true, 0.5)
            button.pfui_styled = true
        end
    end
end

---
--- Applies pfUI styling to quest frame
--- Styles the quest display panel
---
local function StyleQuestFrame()
    -- Get the quest frame reference
    local questFrame = Atlas.Quest and Atlas.Quest.UI_Main and Atlas.Quest.UI_Main.Frame
    if not questFrame then return end

    -- Position Quest frame relative to AtlasFrame for pfUI
    -- We adjust this here because pfUI styling changes the visual borders
    if questFrame:IsVisible() then
        questFrame:ClearAllPoints()
        if AtlasOptions and AtlasOptions.QuestCurrentSide then -- true is Left
            questFrame:SetPoint("TOPRIGHT", "AtlasFrame", "TOPLEFT", -1, 0)
        else
            questFrame:SetPoint("TOPLEFT", "AtlasFrame", "TOPRIGHT", 1, 0)
        end
    end

    -- Clear existing backdrop if any (QuestUI.lua sets a DialogBox backdrop)
    questFrame:SetBackdrop(nil)

    -- Apply pfUI backdrop
    pfUI.api.CreateBackdrop(questFrame, nil, nil, 1.0)
    pfUI.api.CreateBackdropShadow(questFrame)

    -- Use pfUI background color if available, otherwise pure black
    if questFrame.backdrop then
        local r, g, b, a = GetPfUIBackgroundColor()
        questFrame.backdrop:SetBackdropColor(r, g, b, 1) -- Ensure alpha is 1 for "completely black"
    end

    -- Style the close button
    if Atlas.Quest.UI_Main.CloseButton then
        local closeButton = Atlas.Quest.UI_Main.CloseButton

        -- User requested no large black contour. Hide pfUI auto-backdrop if present.
        if closeButton.backdrop then
            closeButton.backdrop:Hide()
        end

        closeButton:SetNormalTexture("")
        closeButton:SetPushedTexture("")
        closeButton:SetHighlightTexture("")

        -- Create custom X texture
        if not closeButton.customX then
            local customX = closeButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            customX:SetPoint("CENTER", 0, 0)
            customX:SetText("×")
            customX:SetTextColor(1, 0.2, 0.2)
            customX:SetFont("Fonts\\ARIALN.TTF", 20, "OUTLINE")
            closeButton.customX = customX
        end

        -- Position and size
        closeButton:SetWidth(20)
        closeButton:SetHeight(20)
        closeButton:ClearAllPoints()
        closeButton:SetPoint("TOPRIGHT", questFrame, "TOPRIGHT", -3, -3)

        -- Hover effect
        closeButton:SetScript("OnEnter", function()
            if this.customX then
                this.customX:SetTextColor(1, 0.4, 0.4)
                this.customX:SetFont("Fonts\\ARIALN.TTF", 22, "OUTLINE")
            end
        end)
        closeButton:SetScript("OnLeave", function()
            if this.customX then
                this.customX:SetTextColor(1, 0.2, 0.2)
                this.customX:SetFont("Fonts\\ARIALN.TTF", 20, "OUTLINE")
            end
        end)
    end

    -- Style the Story button
    if Atlas.Quest.UI_Main.StoryButton and pfUI.api.SkinButton then
        pfUI.api.SkinButton(Atlas.Quest.UI_Main.StoryButton)
    end

    -- Style the Check Completed Quests button
    if Atlas.Quest.UI_Main.CheckCompletedQuestsButton and pfUI.api.SkinButton then
        pfUI.api.SkinButton(Atlas.Quest.UI_Main.CheckCompletedQuestsButton)
    end

    -- Style all quest buttons
    if Atlas.Quest.UI_Main.QuestButtons and pfUI.api.SkinButton then
        for i, questBtn in ipairs(Atlas.Quest.UI_Main.QuestButtons) do
            if questBtn.Button and not questBtn.Button.pfui_styled then
                pfUI.api.CreateBackdrop(questBtn.Button, nil, true, 0.3)
                questBtn.Button.pfui_styled = true
            end
        end
    end
end

---
--- Styles the embedded quest display (InsideAtlasFrame)
---
local function StyleInsideAtlasFrame()
    if not Atlas.Quest or not Atlas.Quest.UI or not Atlas.Quest.UI.InsideAtlasFrame then return end
    local frame = Atlas.Quest.UI.InsideAtlasFrame

    -- Apply pfUI backdrop
    pfUI.api.CreateBackdrop(frame, nil, nil, 1.0)
    pfUI.api.CreateBackdropShadow(frame)

    -- Use pfUI background color if available, otherwise pure black
    if frame.backdrop then
        local r, g, b, a = GetPfUIBackgroundColor()
        frame.backdrop:SetBackdropColor(r, g, b, 1) -- Ensure alpha is 1 for "completely black"
    end

    -- Hide or style the original background texture if it exists
    -- In QuestUIinAtlas.lua, it's an anonymous texture created with CreateTexture(nil, "BACKGROUND")
    -- We can iterate through regions to find it or just set all textures to match
    for _, region in ipairs({ frame:GetRegions() }) do
        if region:GetObjectType() == "Texture" then
            local r, g, b, a = 0, 0, 0, 1
            if frame.backdrop then
                r, g, b, a = frame.backdrop:GetBackdropColor()
            end
            region:SetTexture(r, g, b, 1) -- Set alpha to 1 for "completely black"
            region:SetAlpha(1)
        end
    end

    -- Style the close button on InsideAtlasFrame
    if Atlas.Quest.UI.CloseButton then
        local closeButton = Atlas.Quest.UI.CloseButton

        -- Hide pfUI auto-backdrop if present.
        if closeButton.backdrop then
            closeButton.backdrop:Hide()
        end

        closeButton:SetNormalTexture("")
        closeButton:SetPushedTexture("")
        closeButton:SetHighlightTexture("")

        -- Create custom X texture
        if not closeButton.customX then
            local customX = closeButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            customX:SetPoint("CENTER", 0, 0)
            customX:SetText("×")
            customX:SetTextColor(1, 0.2, 0.2)
            customX:SetFont("Fonts\\ARIALN.TTF", 20, "OUTLINE")
            closeButton.customX = customX
        end

        -- Position and size to match main frame buttons
        closeButton:SetWidth(20)
        closeButton:SetHeight(20)
        closeButton:ClearAllPoints()
        closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)

        -- Hover effect
        closeButton:SetScript("OnEnter", function()
            if this.customX then
                this.customX:SetTextColor(1, 0.4, 0.4)
                this.customX:SetFont("Fonts\\ARIALN.TTF", 22, "OUTLINE")
            end
        end)
        closeButton:SetScript("OnLeave", function()
            if this.customX then
                this.customX:SetTextColor(1, 0.2, 0.2)
                this.customX:SetFont("Fonts\\ARIALN.TTF", 20, "OUTLINE")
            end
        end)
    end

    -- Style navigation buttons if they exist
    if Atlas.Quest.UI.NextPageButtonRight and not Atlas.Quest.UI.NextPageButtonRight.pfui_skinned then
        Atlas.Quest.UI.NextPageButtonRight:SetNormalTexture("Interface\\Glues\\Common\\Glue-RightArrow-Button-Up")
        Atlas.Quest.UI.NextPageButtonRight:SetPushedTexture("Interface\\Glues\\Common\\Glue-RightArrow-Button-Down")
        Atlas.Quest.UI.NextPageButtonRight:SetHighlightTexture(
            "Interface\\Glues\\Common\\Glue-RightArrow-Button-Highlight", "ADD")
        Atlas.Quest.UI.NextPageButtonRight.pfui_skinned = true
    end

    if Atlas.Quest.UI.NextPageButtonLeft and not Atlas.Quest.UI.NextPageButtonLeft.pfui_skinned then
        Atlas.Quest.UI.NextPageButtonLeft:SetNormalTexture("Interface\\Glues\\Common\\Glue-LeftArrow-Button-Up")
        Atlas.Quest.UI.NextPageButtonLeft:SetPushedTexture("Interface\\Glues\\Common\\Glue-LeftArrow-Button-Down")
        Atlas.Quest.UI.NextPageButtonLeft:SetHighlightTexture(
            "Interface\\Glues\\Common\\Glue-LeftArrow-Button-Highlight", "ADD")
        Atlas.Quest.UI.NextPageButtonLeft.pfui_skinned = true
    end
end

---
--- Adds comparison support to Atlas tooltips
--- Works regardless of pfUI styling setting if pfUI is loaded
---
local function SetupTooltipComparison()
    if not IsPfUIBaseLoaded() then return end

    if AtlasLootTooltip then
        -- Add comparison support
        if pfUI.eqcompare and pfUI.eqcompare.GameTooltipShow then
            -- Check if comparison is enabled in pfUI settings
            -- In pfUI, if the module is active, eqcompare.GameTooltipShow exists.
            -- We hook it directly.
            local origOnShow = AtlasLootTooltip:GetScript("OnShow")
            AtlasLootTooltip:SetScript("OnShow", function()
                if origOnShow then origOnShow() end
                pfUI.eqcompare.GameTooltipShow()
            end)

            local origOnHide = AtlasLootTooltip:GetScript("OnHide")
            AtlasLootTooltip:SetScript("OnHide", function()
                if origOnHide then origOnHide() end
                if ShoppingTooltip1 then ShoppingTooltip1:Hide() end
                if ShoppingTooltip2 then ShoppingTooltip2:Hide() end
            end)
        end
    end
end

---
--- Applies pfUI styling to tooltips
--- This function ensures consistency if tooltips are created later
---
local function StyleTooltips()
    if not IsPfUIStylingEnabled() then return end

    if AtlasLootTooltip then
        pfUI.api.CreateBackdrop(AtlasLootTooltip)
        pfUI.api.CreateBackdropShadow(AtlasLootTooltip)
    end

    if AtlasLootTooltip2 then
        pfUI.api.CreateBackdrop(AtlasLootTooltip2)
        pfUI.api.CreateBackdropShadow(AtlasLootTooltip2)
    end
end

---
--- Skins a Hewdrop menu level with pfUI style
--- @param level number - The level number to skin
---
function Atlas.pfUI.StyleHewdropLevel(level)
    if not IsPfUIStylingEnabled() then return end

    local frame = _G["Hewdrop20Level" .. level]
    if frame and not frame.pfui_styled then
        -- The backdrop is a child frame created in AcquireLevel
        -- It's the first child that is a frame and has a backdrop
        for _, child in ipairs({ frame:GetChildren() }) do
            if child:GetObjectType() == "Frame" and child.SetBackdrop then
                -- Apply pfUI backdrop
                pfUI.api.CreateBackdrop(child, nil, true, 0.95)
                pfUI.api.CreateBackdropShadow(child)

                -- Adjust color to match pfUI standard
                if child.backdrop then
                    local r, g, b, a = GetPfUIBackgroundColor()
                    child.backdrop:SetBackdropColor(r, g, b, 0.95)
                end
                break
            end
        end
        frame.pfui_styled = true
    end
end

---
--- Applies pfUI styling to Hewdrop menu frames
--- Styles dropdown menu popups
---
local function StyleHewdropMenus()
    -- Hewdrop menus are created dynamically
    -- We mainly rely on the hook in AtlasHewdrop.lua calling Atlas.pfUI.StyleHewdropLevel
    -- But we check existing ones here just in case

    for i = 1, 10 do
        Atlas.pfUI.StyleHewdropLevel(i)
    end
end

---
--- Applies pfUI styling to checkboxes
--- Styles all checkboxes in Atlas using pfUI.api.SkinCheckbox
---
local function StyleCheckboxes()
    if not pfUI.api.SkinCheckbox then return end

    -- Style checkboxes in options frame
    if AtlasOptionsFrame then
        local function SkinCheckboxesRecursive(frame)
            for _, child in ipairs({ frame:GetChildren() }) do
                if child:GetObjectType() == "CheckButton" then
                    if not child.pfui_skinned then
                        pfUI.api.SkinCheckbox(child)
                        child.pfui_skinned = true
                    end
                end
                SkinCheckboxesRecursive(child)
            end
        end
        SkinCheckboxesRecursive(AtlasOptionsFrame)
    end

    -- Style "Finished Quest" checkbox in embedded quest display
    if Atlas.Quest and Atlas.Quest.UI and Atlas.Quest.UI.FinishedQuestCheckbox then
        local finishedCheck = Atlas.Quest.UI.FinishedQuestCheckbox
        if not finishedCheck.pfui_skinned then
            pfUI.api.SkinCheckbox(finishedCheck)
            finishedCheck.pfui_skinned = true
        end
    end
end

---
--- Applies pfUI styling to options frame
--- Styles the options/settings window
---
local function StyleOptionsFrame()
    if not AtlasOptionsFrame then return end

    -- Apply pfUI backdrop
    pfUI.api.CreateBackdrop(AtlasOptionsFrame, nil, nil, 0.85)
    pfUI.api.CreateBackdropShadow(AtlasOptionsFrame)

    -- Style all buttons and checkboxes in options frame using SkinButton/SkinCheckbox
    if pfUI.api.SkinButton then
        local function SkinElementsRecursive(frame)
            for _, child in ipairs({ frame:GetChildren() }) do
                if not child.pfui_skinned then
                    if child:GetObjectType() == "Button" then
                        pfUI.api.SkinButton(child)
                        child.pfui_skinned = true
                    elseif child:GetObjectType() == "CheckButton" and pfUI.api.SkinCheckbox then
                        pfUI.api.SkinCheckbox(child)
                        child.pfui_skinned = true
                    end
                end
                SkinElementsRecursive(child)
            end
        end
        SkinElementsRecursive(AtlasOptionsFrame)
    end

    -- Style checkboxes (calls the dedicated function for any missed or external ones)
    StyleCheckboxes()
end

---
--- Applies pfUI styling to profession frames and their Atlas components
---
function Atlas.pfUI.StyleProfessionFrames()
    if not IsPfUIStylingEnabled() then return end

    -- Style Atlas buttons in profession frames
    if TradeSkillFrameAtlasButton then
        Atlas.pfUI.RestyleButton("TradeSkillFrameAtlasButton")
    end
    if CraftFrameAtlasButton then
        Atlas.pfUI.RestyleButton("CraftFrameAtlasButton")
    end


    if AtlasCraftCategories and not AtlasCraftCategories.pfui_skinned then
        pfUI.api.SkinCheckbox(AtlasCraftCategories)
        AtlasCraftCategories.pfui_skinned = true
    end
    if AtlasCraftShowSkillLevels and not AtlasCraftShowSkillLevels.pfui_skinned then
        pfUI.api.SkinCheckbox(AtlasCraftShowSkillLevels)
        AtlasCraftShowSkillLevels.pfui_skinned = true
    end
    if AtlasTradeSkillShowLevels and not AtlasTradeSkillShowLevels.pfui_skinned then
        pfUI.api.SkinCheckbox(AtlasTradeSkillShowLevels)
        AtlasTradeSkillShowLevels.pfui_skinned = true
    end

    local allBtn = _G["AtlasCraftCollapseAll"]
    if allBtn then
        Atlas.pfUI.SkinCollapseAllButton(allBtn)
        allBtn.pfui_skinned = true
    end

    -- Style search boxes
    if AtlasTradeSkillSearchBox then
        Atlas.pfUI.SkinEditBox(AtlasTradeSkillSearchBox)
    end
    if AtlasCraftSearchBox then
        Atlas.pfUI.SkinEditBox(AtlasCraftSearchBox)
    end

    -- Style side tabs
    for i = 1, 20 do -- Scan up to 20 potential tabs
        local tab = _G["AtlasProfessionTab" .. i]
        if tab then
            if not tab.pfui_skinned then
                if pfUI.api.CreateBackdrop then
                    pfUI.api.CreateBackdrop(tab, nil, true)
                end

                -- Hide original background texture/textures
                if tab.bg then tab.bg:Hide() end

                -- The template uses these textures
                local textures = {
                    tab:GetNormalTexture(),
                    tab:GetPushedTexture(),
                    tab:GetHighlightTexture(),
                    tab:GetDisabledTexture(),
                    tab:GetCheckedTexture(),
                }

                for _, tex in ipairs(textures) do
                    if tex then
                        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                        tex:ClearAllPoints()
                        tex:SetPoint("TOPLEFT", tab, "TOPLEFT", 2, -2)
                        tex:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -2, 2)
                    end
                end

                tab.pfui_skinned = true
            end
        end
    end
end

---
--- Main initialization function
--- Applies all pfUI styling when pfUI is detected
--- Idempotent: runs once per session to avoid restyling/re-registering on
--- repeated ADDON_LOADED / PLAYER_ENTERING_WORLD triggers.
---
local pfUIStyled = false

function Atlas.pfUI.Initialize()
    if pfUIStyled then return end
    pfUIStyled = true

    if not IsPfUIBaseLoaded() then
        return
    end

    -- Setup tooltip comparison (works even if styling is disabled)
    SetupTooltipComparison()

    -- Apply styling only if enabled in options
    if not IsPfUIStylingEnabled() then
        return
    end

    -- Apply styling to all components
    StyleMainFrame()
    StyleDropdowns()
    StyleButtons()
    StyleSearchBox()
    StyleScrollBar()
    StyleLootItemsFrame()
    StyleLootPanel()
    StyleContainerFrame()
    StyleQuestFrame()
    StyleInsideAtlasFrame()
    StyleTooltips()
    StyleHewdropMenus()
    StyleOptionsFrame()
    StyleCheckboxes()
    Atlas.pfUI.StyleProfessionFrames()

    -- Create a delayed hook for dynamically created frames
    -- Some frames are created after ADDON_LOADED
    local delayedStyle = CreateFrame("Frame")
    delayedStyle:RegisterEvent("PLAYER_ENTERING_WORLD")
    delayedStyle:SetScript("OnEvent", function()
        -- Restyle components that might be created late
        StyleLootPanel()
        StyleContainerFrame()
        StyleQuestFrame()
        StyleInsideAtlasFrame()
        StyleButtons()
        StyleCheckboxes()
        StyleHewdropMenus()
        this:UnregisterAllEvents()
    end)
end

local init = CreateFrame("Frame")
init:RegisterEvent("ADDON_LOADED")
init:RegisterEvent("PLAYER_ENTERING_WORLD")
init:SetScript("OnEvent", function()
    if arg1 == Atlas.Name then
        this.atlasLoaded = true
    elseif arg1 == "pfUI" then
        this.pfuiLoaded = true
    elseif arg1 == "Blizzard_TradeSkillUI" or arg1 == "Blizzard_CraftUI" then
        if Atlas.pfUI and Atlas.pfUI.Initialize then
            Atlas.pfUI.Initialize()
        end
    end

    if (this.atlasLoaded or IsAddOnLoaded(Atlas.Name)) and (this.pfuiLoaded or IsAddOnLoaded("pfUI")) then
        this:SetScript("OnUpdate", function()
            Atlas.pfUI.Initialize()
            this:SetScript("OnUpdate", nil)
        end)
        this:UnregisterAllEvents()
    end
end)
