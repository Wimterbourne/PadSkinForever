local _, addon = ...
local panel
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
        panel:SetSize(510, 650)
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
        Label(panel, "PadSkinForever — 0.1.1 alpha", 22, -20)
        Button(panel, "Close", 408, -14, 80, function() panel:Hide() end)
        Label(panel, "Blizzard layout and gamepad behavior remain native.", 22, -56)
        panel.checks = {}
        Checkbox(panel, "Tint action button borders and empty slots", "skinButtons", -85)
        Checkbox(panel, "Color Xbox A / B / X / Y glyphs", "colorGlyphs", -113)
        Checkbox(panel, "Skin the native input legend", "skinLegend", -141)
        Checkbox(panel, "Use selected font for cooldown text", "cooldownFont", -169)
        panel.selected = Label(panel, "", 22, -214)
        Label(panel, "Fonts from LibSharedMedia and Font Manager (scroll to select):", 22, -244)
        local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 22, -273)
        scroll:SetSize(438, 180)
        panel.fontContent = CreateFrame("Frame", nil, scroll)
        panel.fontContent:SetSize(438, 180)
        scroll:SetScrollChild(panel.fontContent)
        panel.sizeText = Label(panel, "", 22, -480)
        Button(panel, "−", 205, -474, 36, function()
            addon.db.fontSize = math.max(8, addon.db.fontSize - 1)
            panel.sizeText:SetText("Cooldown font size: " .. addon.db.fontSize)
            addon:QueueRefresh()
        end)
        Button(panel, "+", 245, -474, 36, function()
            addon.db.fontSize = math.min(40, addon.db.fontSize + 1)
            panel.sizeText:SetText("Cooldown font size: " .. addon.db.fontSize)
            addon:QueueRefresh()
        end)
        panel.outline = Button(panel, "", 22, -516, 260, function()
            local current = 1
            for i, flags in ipairs(outlines) do if flags == addon.db.fontFlags then current = i end end
            current = current % #outlines + 1
            addon.db.fontFlags = outlines[current]
            panel.outline:SetText("Cooldown: " .. outlineLabels[current])
            addon:QueueRefresh()
        end)
        Button(panel, "Toggle native legend", 22, -557, 210, function() addon:ToggleLegend() end)
        local help = Label(panel, "Controller toggle: assign a free key in Key Bindings > PadSkinForever.\nNative gamepad bindings can take priority. Changes apply after combat.", 22, -596)
        help:SetWidth(460)
        help:SetJustifyH("LEFT")
    end
    for key, check in pairs(panel.checks) do check:SetChecked(self.db[key]) end
    panel.selected:SetText("Selected font: " .. self.db.font)
    panel.sizeText:SetText("Cooldown font size: " .. self.db.fontSize)
    for index, flags in ipairs(outlines) do
        if flags == self.db.fontFlags then panel.outline:SetText("Cooldown: " .. outlineLabels[index]) end
    end
    RefreshFontList()
    panel:Show()
end
