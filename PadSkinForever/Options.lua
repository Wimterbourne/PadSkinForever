local _, addon = ...
local panel
local ShowTab
local controllerOwner
local controllerButtons = {}
local controllerFocus
local controllerActive

local function ControlIsVisible(control)
    if not control then return false end
    if control.IsVisible then return control:IsVisible() end
    return not control.IsShown or control:IsShown()
end

local function ControlIsUsable(control)
    if not ControlIsVisible(control) then return false end
    return not control.IsEnabled or control:IsEnabled()
end

local function EnsureControlVisible(control)
    local scroll = control and control.PSFScrollFrame
    local index = control and control.PSFScrollIndex
    if not scroll or not index or not scroll.GetVerticalScroll or not scroll.SetVerticalScroll then return end
    local rowHeight = control.PSFScrollRowHeight or 24
    local rowTop, rowBottom = (index - 1) * rowHeight, index * rowHeight
    local offset = scroll:GetVerticalScroll() or 0
    local viewport = scroll.GetHeight and scroll:GetHeight() or 0
    if rowTop < offset then
        scroll:SetVerticalScroll(rowTop)
    elseif viewport > 0 and rowBottom > offset + viewport then
        scroll:SetVerticalScroll(rowBottom - viewport)
    end
end

local function SetControllerFocus(control)
    if controllerFocus == control then return end
    if controllerFocus and controllerFocus.SetPSFControllerFocused then
        controllerFocus:SetPSFControllerFocused(false)
    end
    controllerFocus = ControlIsUsable(control) and control or nil
    if controllerFocus and controllerFocus.SetPSFControllerFocused then
        controllerFocus:SetPSFControllerFocused(true)
        EnsureControlVisible(controllerFocus)
    end
    -- PSF owns this marker. Never move or reconfigure Blizzard's focus cursor.
    local arrow = panel and panel.PSFFocusArrow
    if arrow then
        arrow:Hide()
        if controllerFocus then
            arrow:ClearAllPoints()
            arrow:SetPoint("RIGHT", controllerFocus, "LEFT", -4, 0)
            arrow:Show()
        end
    end
end

local function RegisterControl(control)
    if not panel or not control then return control end
    panel.PSFControls = panel.PSFControls or {}
    panel.PSFControls[#panel.PSFControls + 1] = control
    return control
end

local function IsDescendantOf(control, ancestor)
    local current = control
    while current do
        if current == ancestor then return true end
        current = (current.GetParent and current:GetParent()) or current.parent
    end
    return false
end

local function FirstUsableControl(page)
    if not page then return nil end
    for _, control in ipairs(panel.PSFControls or {}) do
        if IsDescendantOf(control, page) and ControlIsUsable(control) then return control end
    end
end

local function MoveControllerFocus(direction)
    if not panel or not panel:IsShown() then return end
    if not ControlIsUsable(controllerFocus) then
        SetControllerFocus(panel.tabs and panel.tabs.general)
        return
    end
    local fromX, fromY = controllerFocus:GetCenter()
    if not fromX or not fromY then return end
    local best, bestScore
    for _, candidate in ipairs(panel.PSFControls or {}) do
        if candidate ~= controllerFocus and ControlIsUsable(candidate) then
            local x, y = candidate:GetCenter()
            if x and y then
                local dx, dy = x - fromX, y - fromY
                local primary, cross
                if direction == "UP" and dy > 2 then primary, cross = dy, math.abs(dx)
                elseif direction == "DOWN" and dy < -2 then primary, cross = -dy, math.abs(dx)
                elseif direction == "LEFT" and dx < -2 then primary, cross = -dx, math.abs(dy)
                elseif direction == "RIGHT" and dx > 2 then primary, cross = dx, math.abs(dy) end
                if primary then
                    -- Prefer the closest control in the requested direction,
                    -- strongly favoring controls that share the same row/column.
                    local score = primary + cross * 2.75
                    if cross > primary * 2.5 then score = score + cross * 4 end
                    if not bestScore or score < bestScore then best, bestScore = candidate, score end
                end
            end
        end
    end
    if best then SetControllerFocus(best) end
end

local function ActivateControllerFocus()
    if ControlIsUsable(controllerFocus) and controllerFocus.Click then
        controllerFocus:Click("LeftButton")
    end
end

local function SetControllerActive(active)
    controllerActive = active and true or nil
    if not controllerActive then SetControllerFocus(nil) end
    if InCombatLockdown() or not controllerOwner then return end
    controllerOwner:SetAttribute("psf-active", controllerActive and true or false)
end

local function CreateControllerBindings()
    if controllerOwner then return true end
    if not RegisterStateDriver then
        addon:Print("Controller navigation is unavailable in this client build.")
        return false
    end

    controllerOwner = CreateFrame("Frame", "PadSkinForeverControllerBindings", UIParent, "SecureHandlerAttributeTemplate")
    local actions = {
        UP = { "PadSkinForeverControllerUp", function() MoveControllerFocus("UP") end },
        DOWN = { "PadSkinForeverControllerDown", function() MoveControllerFocus("DOWN") end },
        LEFT = { "PadSkinForeverControllerLeft", function() MoveControllerFocus("LEFT") end },
        RIGHT = { "PadSkinForeverControllerRight", function() MoveControllerFocus("RIGHT") end },
        ACCEPT = { "PadSkinForeverControllerAccept", ActivateControllerFocus },
        BACK = { "PadSkinForeverControllerBack", function() if panel then panel:Hide() end end },
    }
    for action, data in pairs(actions) do
        local button = CreateFrame("Button", data[1], UIParent)
        button:SetScript("OnClick", data[2])
        controllerButtons[action] = button
    end

    -- This restricted snippet owns PSF's temporary overrides. It never calls
    -- Blizzard's gamepad binding stack. Combat clears the bindings securely
    -- before insecure addon code could be blocked from doing so.
    controllerOwner:SetAttribute("_onattributechanged", [[
        if name == "psf-active" or name == "state-combat" then
            self:ClearBindings()
            local active = self:GetAttribute("psf-active")
            local combat = self:GetAttribute("state-combat") == "combat"
            if active and not combat then
                self:SetBindingClick(true, "PADDUP", "PadSkinForeverControllerUp", "LeftButton")
                self:SetBindingClick(true, "PADDDOWN", "PadSkinForeverControllerDown", "LeftButton")
                self:SetBindingClick(true, "PADDLEFT", "PadSkinForeverControllerLeft", "LeftButton")
                self:SetBindingClick(true, "PADDRIGHT", "PadSkinForeverControllerRight", "LeftButton")
                self:SetBindingClick(true, "PAD1", "PadSkinForeverControllerAccept", "LeftButton")
                self:SetBindingClick(true, "PAD2", "PadSkinForeverControllerBack", "LeftButton")
            elseif combat and active then
                self:SetAttribute("psf-active", false)
            end
        end
    ]])
    controllerOwner:SetAttribute("psf-active", false)
    RegisterStateDriver(controllerOwner, "combat", "[combat] combat; nocombat")
    return true
end

local function CloseOptions()
    if not panel or not panel:IsShown() then return end
    SetControllerActive(false)
    panel:Hide()
end
local outlines = { "", "OUTLINE", "THICKOUTLINE", "MONOCHROME,OUTLINE" }
local outlineLabels = { "None", "Outline", "Thick outline", "Monochrome + outline" }

local function Label(parent, text, x, y, emphasized, size)
    return addon:CreatePSFLabel(parent, text, x, y, emphasized, size)
end

local function Button(parent, text, x, y, width, callback)
    return RegisterControl(addon:CreatePSFButton(parent, text, x, y, width, callback))
end

local function FlatButton(parent, text, x, y, width, callback)
    local button = Button(parent, text, x, y, width, callback)
    button:SetPSFStyle("flat")
    return button
end

local function Hint(parent, text, x, y, size)
    local label = Label(parent, text, x, y, false, size)
    label:SetTextColor(unpack(addon.uiColors.muted))
    return label
end

local function Checkbox(parent, text, key, y)
    local check = addon:CreatePSFCheckbox(parent, text, 20, y, function(self)
        addon.db[key] = self:GetChecked() and true or false
        addon:QueueRefresh()
    end)
    check:SetChecked(addon.db[key])
    parent.checks[key] = check
    RegisterControl(check)
end

local function RefreshFontList()
    local fonts = addon:GetFonts()
    local names = {}
    for name in pairs(fonts) do names[#names + 1] = name end
    table.sort(names)
    panel.fontRows = panel.fontRows or {}
    panel.fontContent:SetHeight(math.max(180, #names * 24))
    local uiFont = fonts["PSF Inter Regular"] or STANDARD_TEXT_FONT
    for index, name in ipairs(names) do
        local row = panel.fontRows[index]
        if not row then
            row = addon:CreatePSFButton(panel.fontContent, "", 0, -(index - 1) * 24, 410, function() end)
            row:SetSize(420, 24)
            row:SetPSFStyle("list")
            row.PSFText:ClearAllPoints()
            row.PSFText:SetPoint("LEFT", 8, 0)
            row.label = row.PSFText
            row.label:SetWidth(410)
            row.label:SetJustifyH("LEFT")
            panel.fontRows[index] = row
            RegisterControl(row)
            row.PSFScrollFrame = panel.fontScroll
            row.PSFScrollIndex = index
            row.PSFScrollRowHeight = 24
        end
        row:SetText(name)
        row:SetPSFSelected(name == addon.db.font)
        -- Names only: opening the list must not load every registered asset.
        row.label:SetFont(uiFont, 13, "")
        row:SetScript("OnClick", function()
            addon.db.font = name
            panel.selected:SetText("Selected font: " .. name)
            addon:QueueRefresh()
            RefreshFontList()
        end)
        row:Show()
    end
    for index = #names + 1, #panel.fontRows do panel.fontRows[index]:Hide() end
end

function addon:ShowOptions()
    if InCombatLockdown() then
        self:Print("Open /psf after combat.")
        return
    end
    if not self.db then return end
    if not panel then
        panel = CreateFrame("Frame", "PadSkinForeverOptions", UIParent, "BackdropTemplate")
        panel:Hide()
        panel.PSFControls = {}
        panel:SetSize(510, 700)
        panel:SetPoint("CENTER")
        panel:SetFrameStrata("FULLSCREEN_DIALOG")
        panel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        panel:SetBackdropColor(0, 0, 0, 0)
        panel:SetBackdropBorderColor(0, 0, 0, 0)
        addon:CreateRoundedPanel(panel)
        panel:EnableMouse(true)
        panel:SetMovable(true)
        panel:RegisterForDrag("LeftButton")
        panel:SetScript("OnDragStart", panel.StartMoving)
        panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
        panel.PSFLogo = addon:CreatePSFLogo(panel, 36)
        panel.PSFLogo:SetPoint("TOPLEFT", 22, -18)
        Label(panel, "PadSkinForever", 66, -18, true, 17)
        local version = Label(panel, "0.9.4 alpha", 230, -20, false, 12)
        version:SetTextColor(unpack(addon.uiColors.muted))
        panel.PSFFocusArrow = panel:CreateTexture(nil, "OVERLAY")
        panel.PSFFocusArrow:SetTexture("Interface\\AddOns\\PadSkinForever\\Media\\PSFFocusChevron.tga")
        panel.PSFFocusArrow:SetSize(12, 24)
        panel.PSFFocusArrow:SetVertexColor(unpack(addon.uiColors.accent))
        panel.PSFFocusArrow:Hide()
        Button(panel, "Close", 408, -14, 80, CloseOptions)
        panel.pages = {}
        panel.tabs = {}
        panel.settings = CreateFrame("Frame", nil, panel)
        panel.settings:SetPoint("TOPLEFT", 0, -36)
        panel.settings:SetPoint("BOTTOMRIGHT")
        panel.pages.general = panel.settings
        panel.tabs.general = Button(panel, "General", 22, -50, 82, function() ShowTab("general") end)
        panel.tabs.glyphs = Button(panel, "Glyphs", 110, -50, 82, function() ShowTab("glyphs") end)
        panel.tabs.buttons = Button(panel, "Buttons", 198, -50, 82, function() ShowTab("buttons") end)
        panel.tabs.theme = Button(panel, "Theme", 286, -50, 82, function() ShowTab("theme") end)
        panel.tabs.debug = Button(panel, "Debug", 374, -50, 82, function() ShowTab("debug") end)
        for _, tab in pairs(panel.tabs) do tab:SetPSFStyle("tab") end
        local navLine = panel:CreateTexture(nil, "ARTWORK")
        navLine:SetTexture("Interface\\Buttons\\WHITE8X8")
        navLine:SetVertexColor(.24, .28, .25, 1)
        navLine:SetHeight(1)
        navLine:SetPoint("TOPLEFT", panel, "TOPLEFT", 22, -84)
        navLine:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -22, -84)
        Hint(panel.settings, "Blizzard layout and gamepad behavior remain native.", 22, -56)
        panel.checks = {}
        panel.settings.checks = panel.checks
        Checkbox(panel.settings, "Tint action button borders and empty slots", "skinButtons", -85)
        FlatButton(panel.settings, "Glyph style and size...", 22, -113, 230, function() ShowTab("glyphs") end)
        Checkbox(panel.settings, "Theme native legend (off: hand control to another addon)", "skinLegend", -141)
        Checkbox(panel.settings, "Use selected font for cooldown text", "cooldownFont", -169)
        panel.selected = Label(panel.settings, "", 22, -214)
        Hint(panel.settings, "Fonts from LibSharedMedia and Font Manager (scroll to select):", 22, -244)
        local fontWell = CreateFrame("Frame", nil, panel.settings, "BackdropTemplate")
        fontWell:SetPoint("TOPLEFT", 20, -269)
        fontWell:SetSize(442, 186)
        fontWell:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        fontWell:SetBackdropColor(.035, .04, .05, .68)
        fontWell:SetBackdropBorderColor(unpack(addon.uiColors.borderSoft))
        local scroll = CreateFrame("ScrollFrame", nil, panel.settings, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 22, -273)
        scroll:SetSize(438, 180)
        panel.fontScroll = scroll
        panel.fontContent = CreateFrame("Frame", nil, scroll)
        panel.fontContent:SetSize(438, 180)
        scroll:SetScrollChild(panel.fontContent)
        panel.sizeText = Label(panel.settings, "", 22, -480)
        panel.sizeMinus = Button(panel.settings, "−", 205, -474, 36, function()
            addon.db.fontSize = math.max(8, addon.db.fontSize - 1)
            panel.sizeText:SetText("Cooldown font size: " .. addon.db.fontSize)
            addon:QueueRefresh()
        end)
        panel.sizePlus = Button(panel.settings, "+", 245, -474, 36, function()
            addon.db.fontSize = math.min(40, addon.db.fontSize + 1)
            panel.sizeText:SetText("Cooldown font size: " .. addon.db.fontSize)
            addon:QueueRefresh()
        end)
        panel.outline = Button(panel.settings, "", 22, -516, 260, function()
            local current = 1
            for i, flags in ipairs(outlines) do if flags == addon.db.fontFlags then current = i end end
            current = current % #outlines + 1
            addon.db.fontFlags = outlines[current]
            panel.outline:SetText("Cooldown: " .. outlineLabels[current])
            addon:QueueRefresh()
        end)
        panel.toggleLegend = Button(panel.settings, "Toggle native legend", 22, -557, 210, function() addon:ToggleLegend() end)
        local help = Hint(panel.settings, "D-pad navigates PSF; A selects and B returns to the Game Menu.\nPSF uses isolated bindings and releases them automatically before combat.", 22, -596)
        help:SetWidth(460)
        help:SetJustifyH("LEFT")
        local glyphPage = CreateFrame("Frame", nil, panel)
        glyphPage:SetPoint("TOPLEFT", 0, -90)
        glyphPage:SetPoint("BOTTOMRIGHT")
        panel.pages.glyphs = glyphPage
        Hint(glyphPage, "Styles use Blizzard assets. Size applies to bars and themed legend.", 22, -10)
        local controls = {}
        local function Group(title, styleKey, scaleKey, styles, labels, y)
            Label(glyphPage, title, 22, y)
            local styleButton
            local function Update()
                for index, style in ipairs(styles) do
                    if addon.db[styleKey] == style then styleButton:SetText(labels[index]) end
                end
                controls[scaleKey]:SetText("Size: " .. math.floor(addon.db[scaleKey] * 100 + .5) .. "%")
            end
            styleButton = Button(glyphPage, "", 22, y - 32, 330, function()
                local current = 1
                for index, style in ipairs(styles) do if addon.db[styleKey] == style then current = index end end
                addon.db[styleKey] = styles[current % #styles + 1]
                Update(); addon:QueueRefresh()
            end)
            controls[scaleKey] = Label(glyphPage, "", 22, y - 76)
            Button(glyphPage, "−", 168, y - 70, 36, function()
                addon.db[scaleKey] = math.max(.5, addon.db[scaleKey] - .1)
                Update(); addon:QueueRefresh()
            end)
            Button(glyphPage, "+", 210, y - 70, 36, function()
                addon.db[scaleKey] = math.min(2, addon.db[scaleKey] + .1)
                Update(); addon:QueueRefresh()
            end)
            Button(glyphPage, "100%", 258, y - 70, 94, function()
                addon.db[scaleKey] = 1; Update(); addon:QueueRefresh()
            end)
            glyphPage:HookScript("OnShow", Update)
        end
        Group("A / B / X / Y", "faceGlyphStyle", "faceGlyphScale", addon.faceStyles, addon.faceStyleLabels, -56)
        Group("D-pad", "dpadGlyphStyle", "dpadGlyphScale", addon.dpadStyles, addon.dpadStyleLabels, -202)
        glyphPage.checks = {}
        Checkbox(glyphPage, "Vivid glyph colors (full texture opacity)", "vividGlyphs", -404)
        Checkbox(glyphPage, "Move enlarged glyphs outward from their native anchor", "glyphOutside", -325)
        local intensity
        intensity = Button(glyphPage, "", 22, -367, 330, function()
            local current = addon.db.disabledGlyphIntensity
            addon.db.disabledGlyphIntensity = current < .6 and .7 or current < .9 and 1 or .45
            intensity:SetText("Disabled glyph brightness: " .. math.floor(addon.db.disabledGlyphIntensity * 100 + .5) .. "%")
            addon:QueueRefresh()
        end)
        glyphPage:HookScript("OnShow", function()
            glyphPage.checks.vividGlyphs:SetChecked(addon.db.vividGlyphs)
            glyphPage.checks.glyphOutside:SetChecked(addon.db.glyphOutside)
            intensity:SetText("Disabled glyph brightness: " .. math.floor(addon.db.disabledGlyphIntensity * 100 + .5) .. "%")
        end)
        local glyphHelp = Hint(glyphPage, "Size range: 50–200%. Changes wait until combat ends.\nDisabled glyphs stay dimmed. Native input state remains with Blizzard.\nLegend theming off also restores its native glyph style and size.", 22, -454)
        glyphHelp:SetWidth(465); glyphHelp:SetJustifyH("LEFT")

        local buttonPage = CreateFrame("Frame", nil, panel)
        buttonPage:SetPoint("TOPLEFT", 0, -90)
        buttonPage:SetPoint("BOTTOMRIGHT")
        panel.pages.buttons = buttonPage
        Label(buttonPage, "Modern minimalistic Xbox controls", 22, -10)
        local buttonStyle
        local function UpdateButtonStyle()
            buttonStyle:SetText(addon.db.buttonStyle == "minimal" and "Modern minimal" or "Blizzard borders")
        end
        buttonStyle = Button(buttonPage, "", 22, -56, 330, function()
            addon.db.buttonStyle = addon.db.buttonStyle == "minimal" and "native" or "minimal"
            UpdateButtonStyle(); addon:QueueRefresh()
        end)
        buttonPage:HookScript("OnShow", UpdateButtonStyle)
        local buttonHelp = Hint(buttonPage, "Grey D-pad borders; A/B/X/Y borders in Xbox colors.\nDark empty slots. Native button shapes remain.\nEnable button skinning on General to apply this style.\nCooldowns, spell highlights and input behavior stay with Blizzard.", 22, -108)
        buttonHelp:SetWidth(465); buttonHelp:SetJustifyH("LEFT")
        buttonPage.checks = {}
        Label(buttonPage, "Combat HUD", 22, -218)
        Checkbox(buttonPage, "Theme native swing timers", "themeSwingTimers", -252)
        Checkbox(buttonPage, "Show PSF player and pet resources", "resourceDisplay", -286)
        local visibilityLabels = { dim = "Out of combat: dim (20%)", hide = "Out of combat: hidden", show = "Out of combat: visible" }
        local visibilityButton
        local function UpdateVisibilityLabel()
            visibilityButton:SetText(visibilityLabels[addon.db.resourceOutOfCombat] or visibilityLabels.dim)
        end
        visibilityButton = Button(buttonPage, "", 22, -320, 340, function()
            local nextMode = { dim = "hide", hide = "show", show = "dim" }
            addon.db.resourceOutOfCombat = nextMode[addon.db.resourceOutOfCombat or "dim"] or "dim"
            UpdateVisibilityLabel()
            addon:UpdateResourceVisibility()
        end)
        buttonPage:HookScript("OnShow", UpdateVisibilityLabel)
        local combatHelp = Hint(buttonPage, "Swing timer order, position and dimensions remain in Blizzard Edit Mode.\nThe PSF resource display can be dragged while Edit Mode is open.", 22, -368)
        combatHelp:SetWidth(465); combatHelp:SetJustifyH("LEFT")
        buttonPage:HookScript("OnShow", function()
            for key, check in pairs(buttonPage.checks) do check:SetChecked(addon.db[key]) end
        end)

        Label(buttonPage, "Unitframes", 22, -420)
        Checkbox(buttonPage, "Compact player/pet and target presentation", "compactUnits", -450)
        local portraitButton
        local function PortraitLabel() portraitButton:SetText("Portrait: " .. (addon.db.unitPortraitMode == "3d" and "3D" or "2D")) end
        portraitButton = Button(buttonPage, "", 22, -484, 200, function()
            addon.db.unitPortraitMode = addon.db.unitPortraitMode == "3d" and "2d" or "3d"
            PortraitLabel(); addon:QueueRefresh()
        end)
        buttonPage:HookScript("OnShow", PortraitLabel)
        Checkbox(buttonPage, "Theme native buff/debuff icons", "themeUnitAuras", -522)
        Checkbox(buttonPage, "Theme available native cooldown viewers", "themeCooldownManager", -556)

        local themePage = CreateFrame("Frame", nil, panel)
        themePage:SetPoint("TOPLEFT", 0, -90); themePage:SetPoint("BOTTOMRIGHT")
        themePage.checks = {}; panel.pages.theme = themePage
        Label(themePage, "Xbox-inspired native UI theme", 22, -10)
        for index, entry in ipairs({
            { "Minimap skin", "themeMinimap" }, { "Square minimap", "squareMinimap" },
            { "Player, pet, target and focus frames", "themeUnits" },
            { "Quest log and objective tracker", "themeQuests" },
            { "Chat and input panels", "themeChat" }, { "Tooltips", "themeTooltip" },
            { "Compact native loot window skin", "themeLoot" },
            { "Received item loot toasts", "lootToasts" },
            { "Use selected font in themed windows", "themeFonts" },
        }) do Checkbox(themePage, entry[1], entry[2], -44 - (index - 1) * 34) end
        Button(themePage, "Preview loot toasts", 22, -365, 240, function() addon:PreviewLootToasts() end)
        local themeHelp = Hint(themePage, "Modules restore their visual changes when disabled.\nSquare map changes the actual map mask.\nNative layout, quest actions and loot clicks stay with WoW.\nToasts observe received items, including gathering/autoloot.\nTheme changes wait until combat ends.", 22, -410)
        themeHelp:SetWidth(465); themeHelp:SetJustifyH("LEFT")
        themePage:SetScript("OnShow", function()
            for key, check in pairs(themePage.checks) do check:SetChecked(addon.db[key]) end
        end)

        FlatButton(themePage, "Input legend settings...", 274, -365, 210, function() ShowTab("legend") end)
        FlatButton(panel.settings, "Legend style and spacing...", 266, -113, 218, function() ShowTab("legend") end)
        local legendPage = CreateFrame("Frame", nil, panel)
        legendPage:SetPoint("TOPLEFT", 0, -90); legendPage:SetPoint("BOTTOMRIGHT")
        legendPage.checks = {}; panel.pages.legend = legendPage
        Label(legendPage, "Input legend — modern Xbox theme", 22, -10)
        Checkbox(legendPage, "Theme native input legend", "skinLegend", -44)
        Hint(legendPage, "Uses the selected font from General.", 22, -90)
        local function LegendNumber(title, key, low, high, y, step)
            step = step or 1
            local label = Label(legendPage, "", 22, y)
            local function Update()
                local value = key == "legendGlyphScale" and (math.floor(addon.db[key] * 100 + .5) .. "%") or addon.db[key]
                label:SetText(title .. ": " .. value)
            end
            Button(legendPage, "−", 280, y + 6, 36, function()
                addon.db[key] = math.max(low, addon.db[key] - step); Update(); addon:QueueRefresh()
            end)
            Button(legendPage, "+", 324, y + 6, 36, function()
                addon.db[key] = math.min(high, addon.db[key] + step); Update(); addon:QueueRefresh()
            end)
            legendPage:HookScript("OnShow", Update)
        end
        LegendNumber("All legend glyphs", "legendGlyphScale", .5, 2, -132, .1)
        LegendNumber("Text size", "legendFontSize", 10, 28, -186)
        LegendNumber("Space between rows", "legendRowGap", 4, 24, -240)
        LegendNumber("Panel padding", "legendPadding", 8, 32, -294)
        FlatButton(legendPage, "Glyph style and size...", 22, -344, 240, function() ShowTab("glyphs") end)
        Button(legendPage, "Toggle native legend", 22, -384, 240, function() addon:ToggleLegend() end)
        local legendHelp = Hint(legendPage, "Row heights follow actual glyph and text sizes.\nPanel height and column widths follow the content.\nNative prompts, modifiers and dimmed states remain.\nTheming off restores native layout and appearance.\nChanges wait until combat ends.", 22, -436)
        legendHelp:SetWidth(465); legendHelp:SetJustifyH("LEFT")
        legendPage:HookScript("OnShow", function() legendPage.checks.skinLegend:SetChecked(addon.db.skinLegend) end)

        local debugPage = CreateFrame("Frame", nil, panel)
        debugPage:SetPoint("TOPLEFT", 0, -90)
        debugPage:SetPoint("BOTTOMRIGHT")
        panel.pages.debug = debugPage
        local debugHelp = Hint(debugPage, "Current values and optional tracing of future visual changes.\nStacks show involved code, not a complete ownership/conflict history.", 22, -10)
        debugHelp:SetWidth(465); debugHelp:SetJustifyH("LEFT")
        local debugScroll = CreateFrame("ScrollFrame", nil, debugPage, "UIPanelScrollFrameTemplate")
        debugScroll:SetPoint("TOPLEFT", 22, -108)
        debugScroll:SetSize(438, 448)
        local report = CreateFrame("EditBox", nil, debugScroll)
        report:SetMultiLine(true); report:SetAutoFocus(false)
        report:SetFontObject(ChatFontNormal); report:SetWidth(430); report:SetHeight(448)
        report:SetScript("OnTextChanged", function(self)
            self:SetHeight(math.max(448, self:GetNumLines() * 18 + 24))
        end)
        report:SetScript("OnEscapePressed", report.ClearFocus)
        debugScroll:SetScrollChild(report)
        local function RefreshReport()
            report:SetText(addon:GetDebugReport())
            report:SetCursorPosition(0); report:ClearFocus()
            debugScroll:SetVerticalScroll(0)
        end
        local traceButton
        traceButton = Button(debugPage, "Start tracing", 22, -64, 150, function()
            addon:SetDebugTracing(not addon:IsDebugTracing())
            traceButton:SetText(addon:IsDebugTracing() and "Stop tracing" or "Start tracing")
            RefreshReport()
        end)
        Button(debugPage, "Refresh", 180, -64, 120, RefreshReport)
        Button(debugPage, "Clear history", 308, -64, 150, function()
            addon:ClearDebugHistory(); RefreshReport()
        end)
        debugPage:SetScript("OnShow", RefreshReport)

        panel:SetScript("OnHide", function()
            SetControllerActive(false)
        end)
        panel:RegisterEvent("PLAYER_REGEN_DISABLED")
        panel:SetScript("OnEvent", function(self, event)
            if event == "PLAYER_REGEN_DISABLED" and self:IsShown() then
                controllerActive = nil
                SetControllerFocus(nil)
                self:Hide()
            end
        end)
    end
    for key, check in pairs(panel.checks) do check:SetChecked(self.db[key]) end
    panel.selected:SetText("Selected font: " .. self.db.font)
    panel.sizeText:SetText("Cooldown font size: " .. self.db.fontSize)
    for index, flags in ipairs(outlines) do
        if flags == self.db.fontFlags then panel.outline:SetText("Cooldown: " .. outlineLabels[index]) end
    end
    RefreshFontList()
    panel:Show()
    ShowTab("general")
    if CreateControllerBindings() then
        SetControllerActive(true)
        SetControllerFocus(panel.tabs.general)
    end
end

ShowTab = function(name)
    for key, page in pairs(panel.pages) do page:SetShown(key == name) end
    for key, tab in pairs(panel.tabs or {}) do tab:SetPSFSelected(key == name) end
    panel.currentPage = name
    if controllerActive then
        -- Secondary pages such as Legend have no top tab. Hand controller
        -- focus directly to their first control instead of dropping it.
        SetControllerFocus((panel.tabs and panel.tabs[name]) or FirstUsableControl(panel.pages[name]))
    end
end
