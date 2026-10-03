local _, addon = ...
local panel
local ShowTab
local outlines = { "", "OUTLINE", "THICKOUTLINE", "MONOCHROME,OUTLINE" }
local outlineLabels = { "None", "Outline", "Thick outline", "Monochrome + outline" }

local function Label(parent, text, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(text)
    return label
end

local function Button(parent, text, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", x, y)
    button:SetSize(width, 24)
    button:SetText(text)
    button:SetScript("OnClick", callback)
    return button
end

local function Checkbox(parent, text, key, y)
    local check = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
    check:SetPoint("TOPLEFT", 20, y)
    check.Text:SetText(text)
    check:SetChecked(addon.db[key])
    check:SetScript("OnClick", function(self)
        addon.db[key] = self:GetChecked() and true or false
        addon:QueueRefresh()
    end)
    parent.checks[key] = check
end

local function RefreshFontList()
    local fonts = addon:GetFonts()
    local names = {}
    for name in pairs(fonts) do names[#names + 1] = name end
    table.sort(names)
    panel.fontRows = panel.fontRows or {}
    panel.fontContent:SetHeight(math.max(180, #names * 24))
    for index, name in ipairs(names) do
        local row = panel.fontRows[index]
        if not row then
            row = CreateFrame("Button", nil, panel.fontContent)
            row:SetSize(420, 24)
            row:SetPoint("TOPLEFT", 0, -(index - 1) * 24)
            row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            row.label = Label(row, "", 4, -4)
            row.label:SetWidth(410)
            row.label:SetJustifyH("LEFT")
            panel.fontRows[index] = row
        end
        row.label:SetText((name == addon.db.font and "|cff59bfff> " or "|cffffffff") .. name .. "|r")
        -- Names only: opening the list must not load every registered asset.
        row.label:SetFont(STANDARD_TEXT_FONT, 14, "")
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
        panel:SetSize(510, 700)
        panel:SetPoint("CENTER")
        panel:SetFrameStrata("DIALOG")
        panel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        panel:SetBackdropColor(0.04, 0.05, 0.07, 0.97)
        panel:SetBackdropBorderColor(0.35, 0.75, 1, 1)
        panel:EnableMouse(true)
        panel:SetMovable(true)
        panel:RegisterForDrag("LeftButton")
        panel:SetScript("OnDragStart", panel.StartMoving)
        panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
        Label(panel, "PadSkinForever — 0.5.0 alpha", 22, -20)
        Button(panel, "Close", 408, -14, 80, function() panel:Hide() end)
        panel.pages = {}
        panel.settings = CreateFrame("Frame", nil, panel)
        panel.settings:SetPoint("TOPLEFT", 0, -36)
        panel.settings:SetPoint("BOTTOMRIGHT")
        panel.pages.general = panel.settings
        Button(panel, "General", 22, -50, 82, function() ShowTab("general") end)
        Button(panel, "Glyphs", 110, -50, 82, function() ShowTab("glyphs") end)
        Button(panel, "Buttons", 198, -50, 82, function() ShowTab("buttons") end)
        Button(panel, "Theme", 286, -50, 82, function() ShowTab("theme") end)
        Button(panel, "Debug", 374, -50, 82, function() ShowTab("debug") end)
        Label(panel.settings, "Blizzard layout and gamepad behavior remain native.", 22, -56)
        panel.checks = {}
        panel.settings.checks = panel.checks
        Checkbox(panel.settings, "Tint action button borders and empty slots", "skinButtons", -85)
        Button(panel.settings, "Glyph style and size...", 22, -113, 230, function() ShowTab("glyphs") end)
        Checkbox(panel.settings, "Theme native legend (off: hand control to another addon)", "skinLegend", -141)
        Checkbox(panel.settings, "Use selected font for cooldown text", "cooldownFont", -169)
        panel.selected = Label(panel.settings, "", 22, -214)
        Label(panel.settings, "Fonts from LibSharedMedia and Font Manager (scroll to select):", 22, -244)
        local scroll = CreateFrame("ScrollFrame", nil, panel.settings, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 22, -273)
        scroll:SetSize(438, 180)
        panel.fontContent = CreateFrame("Frame", nil, scroll)
        panel.fontContent:SetSize(438, 180)
        scroll:SetScrollChild(panel.fontContent)
        panel.sizeText = Label(panel.settings, "", 22, -480)
        Button(panel.settings, "−", 205, -474, 36, function()
            addon.db.fontSize = math.max(8, addon.db.fontSize - 1)
            panel.sizeText:SetText("Cooldown font size: " .. addon.db.fontSize)
            addon:QueueRefresh()
        end)
        Button(panel.settings, "+", 245, -474, 36, function()
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
        Button(panel.settings, "Toggle native legend", 22, -557, 210, function() addon:ToggleLegend() end)
        local help = Label(panel.settings, "Controller toggle: assign a free key in Key Bindings > PadSkinForever.\nNative gamepad bindings can take priority. Changes apply after combat.", 22, -596)
        help:SetWidth(460)
        help:SetJustifyH("LEFT")
        local glyphPage = CreateFrame("Frame", nil, panel)
        glyphPage:SetPoint("TOPLEFT", 0, -90)
        glyphPage:SetPoint("BOTTOMRIGHT")
        panel.pages.glyphs = glyphPage
        Label(glyphPage, "Styles use Blizzard assets. Size applies to bars and themed legend.", 22, -10)
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
        local glyphHelp = Label(glyphPage, "Size range: 50–200%. Changes wait until combat ends.\nDisabled glyphs stay dimmed. Native input state remains with Blizzard.\nLegend theming off also restores its native glyph style and size.", 22, -454)
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
        local buttonHelp = Label(buttonPage, "Grey D-pad borders; A/B/X/Y borders in Xbox colors.\nDark empty slots. Native button shapes remain.\nEnable button skinning on General to apply this style.\nCooldowns, spell highlights and input behavior stay with Blizzard.", 22, -108)
        buttonHelp:SetWidth(465); buttonHelp:SetJustifyH("LEFT")

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
        local themeHelp = Label(themePage, "Modules restore their visual changes when disabled.\nSquare map changes the actual map mask.\nNative layout, quest actions and loot clicks stay with WoW.\nToasts observe received items, including gathering/autoloot.\nTheme changes wait until combat ends.", 22, -410)
        themeHelp:SetWidth(465); themeHelp:SetJustifyH("LEFT")
        themePage:SetScript("OnShow", function()
            for key, check in pairs(themePage.checks) do check:SetChecked(addon.db[key]) end
        end)

        Button(themePage, "Input legend settings...", 274, -365, 210, function() ShowTab("legend") end)
        Button(panel.settings, "Legend style and spacing...", 266, -113, 218, function() ShowTab("legend") end)
        local legendPage = CreateFrame("Frame", nil, panel)
        legendPage:SetPoint("TOPLEFT", 0, -90); legendPage:SetPoint("BOTTOMRIGHT")
        legendPage.checks = {}; panel.pages.legend = legendPage
        Label(legendPage, "Input legend — modern Xbox theme", 22, -10)
        Checkbox(legendPage, "Theme native input legend", "skinLegend", -44)
        Label(legendPage, "Uses the selected font from General.", 22, -90)
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
        Button(legendPage, "Glyph style and size...", 22, -344, 240, function() ShowTab("glyphs") end)
        Button(legendPage, "Toggle native legend", 22, -384, 240, function() addon:ToggleLegend() end)
        local legendHelp = Label(legendPage, "Row heights follow actual glyph and text sizes.\nPanel height and column widths follow the content.\nNative prompts, modifiers and dimmed states remain.\nTheming off restores native layout and appearance.\nChanges wait until combat ends.", 22, -436)
        legendHelp:SetWidth(465); legendHelp:SetJustifyH("LEFT")
        legendPage:HookScript("OnShow", function() legendPage.checks.skinLegend:SetChecked(addon.db.skinLegend) end)

        local debugPage = CreateFrame("Frame", nil, panel)
        debugPage:SetPoint("TOPLEFT", 0, -90)
        debugPage:SetPoint("BOTTOMRIGHT")
        panel.pages.debug = debugPage
        local debugHelp = Label(debugPage, "Current values and optional tracing of future visual changes.\nStacks show involved code, not a complete ownership/conflict history.", 22, -10)
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
    end
    for key, check in pairs(panel.checks) do check:SetChecked(self.db[key]) end
    panel.selected:SetText("Selected font: " .. self.db.font)
    panel.sizeText:SetText("Cooldown font size: " .. self.db.fontSize)
    for index, flags in ipairs(outlines) do
        if flags == self.db.fontFlags then panel.outline:SetText("Cooldown: " .. outlineLabels[index]) end
    end
    RefreshFontList()
    ShowTab("general")
    panel:Show()
end

ShowTab = function(name)
    for key, page in pairs(panel.pages) do page:SetShown(key == name) end
end
