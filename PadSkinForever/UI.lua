local _, addon = ...

-- Shared PSF presentation primitives. These only create addon-owned frames;
-- Blizzard frames, bindings and navigation tables are never modified here.
local WHITE = "Interface\\Buttons\\WHITE8X8"
local CORNER = "Interface\\AddOns\\PadSkinForever\\Media\\LegendCorner"
local PANEL_RADIUS = 12

addon.uiColors = {
    fill = { .055, .062, .073, .97 },
    raised = { .085, .095, .11, .98 },
    border = { .31, .34, .38, .96 },
    borderSoft = { .23, .26, .30, .88 },
    accent = { .34, .86, .49, 1 },
    text = { .94, .95, .96, 1 },
    muted = { .64, .67, .71, 1 },
}

-- One semantic palette for every PSF bar family. Native bars keep their own
-- values and behavior; these colors only define presentation.
addon.barColors = {
    neutral = { .67, .72, .78, 1 },
    health = { .18, .82, .31, 1 },
    mana = { .16, .48, 1, 1 },
    enemy = { .92, .18, .18, 1 },
    energy = { 1, .78, .12, 1 },
    rage = { .92, .20, .18, 1 },
    focus = { 1, .48, .12, 1 },
    runic = { .12, .78, 1, 1 },
    lunar = { .64, .36, 1, 1 },
    experience = { .52, .25, .88, 1 },
}

local function Color(region, color)
    region:SetVertexColor(unpack(color))
end

function addon:CreatePSFLogo(parent, width)
    local logo = parent:CreateTexture(nil, "OVERLAY")
    logo:SetTexture("Interface\\AddOns\\PadSkinForever\\Media\\PSFLogo.tga")
    logo:SetSize(width, width / 2)
    logo:SetVertexColor(1, 1, 1, 1)
    return logo
end

local function Rect(parent, layer, color, a, b, x1, y1, x2, y2)
    local texture = parent:CreateTexture(nil, layer)
    texture:SetTexture(WHITE)
    Color(texture, color)
    if a:find("TOP") and b:find("TOP") or a:find("BOTTOM") and b:find("BOTTOM") then
        texture:SetHeight(math.abs(y2 - y1)); y2 = y1
    elseif a:find("LEFT") and b:find("LEFT") or a:find("RIGHT") and b:find("RIGHT") then
        texture:SetWidth(math.abs(x2 - x1)); x2 = x1
    end
    texture:SetPoint(a, parent, a, x1, y1)
    texture:SetPoint(b, parent, b, x2, y2)
    return texture
end

function addon:CreateRoundedPanel(parent, palette, radius)
    if parent.PSFRoundedPanel then return parent.PSFRoundedPanel end
    -- Draw directly on the owner so its child controls and header regions stay
    -- above the background without adding another focusable frame layer.
    local panel = parent
    local colors = self.uiColors
    radius = radius or PANEL_RADIUS
    palette = palette or colors
    local fill = palette.fill or colors.fill
    local border = palette.border or colors.border
    for _, layerInfo in ipairs({ { "BACKGROUND", fill, "Fill" }, { "BORDER", border, "Border" } }) do
        local drawLayer, color, asset = unpack(layerInfo)
        for _, corner in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
            local texture = panel:CreateTexture(nil, drawLayer)
            texture:SetTexture(CORNER .. asset .. ".tga")
            texture:SetSize(radius, radius)
            texture:SetPoint(corner, panel, corner)
            local right, bottom = corner:find("RIGHT"), corner:find("BOTTOM")
            texture:SetTexCoord(right and 1 or 0, right and 0 or 1, bottom and 1 or 0, bottom and 0 or 1)
            Color(texture, color)
        end
        if asset == "Fill" then
            Rect(panel, drawLayer, color, "TOPLEFT", "BOTTOMRIGHT", radius, 0, -radius, 0)
            Rect(panel, drawLayer, color, "TOPLEFT", "BOTTOMLEFT", 0, -radius, radius, radius)
            Rect(panel, drawLayer, color, "TOPRIGHT", "BOTTOMRIGHT", 0, -radius, -radius, radius)
        else
            Rect(panel, drawLayer, color, "TOPLEFT", "TOPRIGHT", radius, 0, -radius, -1)
            Rect(panel, drawLayer, color, "BOTTOMLEFT", "BOTTOMRIGHT", radius, 0, -radius, 1)
            Rect(panel, drawLayer, color, "TOPLEFT", "BOTTOMLEFT", 0, -radius, 1, radius)
            Rect(panel, drawLayer, color, "TOPRIGHT", "BOTTOMRIGHT", 0, -radius, -1, radius)
        end
    end
    parent.PSFRoundedPanel = panel
    return panel
end

-- Follow the native fill texture declaratively instead of reading its width.
-- WoW can mark target health geometry as secret; anchoring a clipping frame to
-- that texture remains permitted and keeps the fixed-size caps available.
local roundedBars = setmetatable({}, { __mode = "k" })
local function UpdateRoundedBar(data)
    local texture = data.bar:GetStatusBarTexture()
    if not texture then return end
    if data.texture ~= texture then
        if data.texture then data.texture:SetAlpha(data.alpha or 1) end
        data.texture, data.alpha = texture, texture:GetAlpha()
        data.updater:ClearAllPoints()
        data.updater:SetPoint("TOPLEFT", texture, "TOPLEFT")
        data.updater:SetPoint("BOTTOMRIGHT", texture, "BOTTOMRIGHT")
    end
    -- Also suppress the StatusBar renderer's color alpha: it may reapply its
    -- own tint when values interpolate, independently of Texture:SetAlpha.
    local r, g, b, a = data.bar:GetStatusBarColor()
    if a ~= 0 then data.bar:SetStatusBarColor(r, g, b, 0) end
    if texture:GetAlpha() ~= 0 then texture:SetAlpha(0) end
    for _, region in ipairs(data.regions) do region:Show() end
end

function addon:SetRoundedBar(bar, enabled, color)
    if not bar then return end
    local data = roundedBars[bar]
    if not enabled then
        if data then
            data.updater:Hide()
            for _, region in ipairs(data.regions) do region:Hide() end
            if data.texture then data.texture:SetAlpha(data.alpha or 1) end
            local r, g, b = bar:GetStatusBarColor()
            bar:SetStatusBarColor(r, g, b, data.colorAlpha or 1)
        end
        return
    end
    if not data then
        data = { bar = bar, regions = {}, colorAlpha = select(4, bar:GetStatusBarColor()) }
        -- StatusBar's native fill can render above regions on the bar itself.
        -- A clipped child follows the native texture without exposing secret
        -- dimensions to Lua. Its children retain fixed cap geometry.
        data.updater = CreateFrame("Frame", nil, bar)
        data.updater:SetFrameLevel(bar:GetFrameLevel() + 1)
        data.updater:EnableMouse(false)
        if data.updater.SetClipsChildren then data.updater:SetClipsChildren(true) end
        local height = bar:GetHeight()
        local radius = type(height) == "number" and height / 2 or 5
        for _, corner in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
            local region = data.updater:CreateTexture(nil, "BACKGROUND")
            region:SetTexture(CORNER .. "Fill.tga")
            local right, bottom = corner:find("RIGHT"), corner:find("BOTTOM")
            region:SetTexCoord(right and 1 or 0, right and 0 or 1, bottom and 1 or 0, bottom and 0 or 1)
            region:SetPoint(corner, data.updater, corner)
            region:SetSize(radius, radius)
            table.insert(data.regions, region)
        end
        for i = 1, 3 do
            local region = data.updater:CreateTexture(nil, "BACKGROUND")
            region:SetTexture(WHITE)
            table.insert(data.regions, region)
        end
        local middle, left, right = data.regions[5], data.regions[6], data.regions[7]
        middle:SetPoint("TOPLEFT", data.updater, "TOPLEFT", radius, 0)
        middle:SetPoint("BOTTOMRIGHT", data.updater, "BOTTOMRIGHT", -radius, 0)
        left:SetPoint("TOPLEFT", data.updater, "TOPLEFT", 0, -radius)
        left:SetPoint("BOTTOMRIGHT", data.updater, "BOTTOMLEFT", radius, radius)
        right:SetPoint("TOPLEFT", data.updater, "TOPRIGHT", -radius, -radius)
        right:SetPoint("BOTTOMRIGHT", data.updater, "BOTTOMRIGHT", 0, radius)
        data.updater:SetScript("OnUpdate", function() UpdateRoundedBar(data) end)
        roundedBars[bar] = data
    end
    for _, region in ipairs(data.regions) do region:SetVertexColor(unpack(color or self.barColors.neutral)) end
    data.updater:Show()
    UpdateRoundedBar(data)
end

function addon:CreatePSFLabel(parent, text, x, y, emphasized, size)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(text)
    label:SetTextColor(unpack(self.uiColors.text))
    local path = self:GetUIFontPath(emphasized)
    size = size or (emphasized and 15 or 13)
    if not label:SetFont(path, size, "") then label:SetFont(STANDARD_TEXT_FONT, size, "") end
    return label
end

local function SetButtonState(button)
    local colors = addon.uiColors
    local active = button.PSFSelected or button.PSFHovered or button.PSFControllerFocused
    local style = button.PSFStyle or "action"
    if style == "tab" then
        button:SetBackdropColor(.06, .075, .07, button.PSFSelected and .72 or button.PSFHovered and .48 or 0)
        button:SetBackdropBorderColor(0, 0, 0, 0)
        button.PSFIndicator:SetShown(active and true or false)
        button.PSFIndicator:SetVertexColor(unpack(colors.accent))
    elseif style == "flat" or style == "list" then
        button:SetBackdropColor(.08, .10, .095, active and .78 or style == "list" and .24 or .12)
        button:SetBackdropBorderColor(0, 0, 0, 0)
        button.PSFIndicator:SetShown(active and true or false)
        button.PSFIndicator:SetVertexColor(unpack(colors.accent))
    elseif active then
        button:SetBackdropColor(.09, .14, .11, .98)
        button:SetBackdropBorderColor(unpack(colors.accent))
        button.PSFIndicator:Hide()
    else
        button:SetBackdropColor(unpack(colors.raised))
        button:SetBackdropBorderColor(unpack(colors.borderSoft))
        button.PSFIndicator:Hide()
    end
    if button.PSFText then
        button.PSFText:SetTextColor(unpack(active and colors.text or colors.muted))
    end
end

function addon:CreatePSFButton(parent, text, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetPoint("TOPLEFT", x, y)
    button:SetSize(width, 28)
    button:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    button.PSFIndicator = button:CreateTexture(nil, "ARTWORK")
    button.PSFIndicator:SetTexture(WHITE)
    button.PSFIndicator:SetVertexColor(unpack(self.uiColors.accent))
    button.PSFIndicator:Hide()
    button.PSFText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.PSFText:SetPoint("CENTER")
    if not button.PSFText:SetFont(self:GetUIFontPath(true), 13, "") then
        button.PSFText:SetFont(STANDARD_TEXT_FONT, 13, "")
    end
    button:SetFontString(button.PSFText)
    button:SetText(text)
    button:SetScript("OnEnter", function(self) self.PSFHovered = true; SetButtonState(self) end)
    button:SetScript("OnLeave", function(self) self.PSFHovered = nil; SetButtonState(self) end)
    button:SetScript("OnClick", callback)
    button.SetPSFSelected = function(self, selected)
        self.PSFSelected = selected and true or nil
        SetButtonState(self)
    end
    button.SetPSFControllerFocused = function(self, focused)
        self.PSFControllerFocused = focused and true or nil
        SetButtonState(self)
    end
    button.SetPSFStyle = function(self, style)
        self.PSFStyle = style or "action"
        self.PSFIndicator:ClearAllPoints()
        if self.PSFStyle == "tab" then
            self.PSFIndicator:SetPoint("BOTTOMLEFT", 8, 0)
            self.PSFIndicator:SetPoint("BOTTOMRIGHT", -8, 0)
            self.PSFIndicator:SetHeight(2)
        else
            self.PSFIndicator:SetPoint("TOPLEFT", 0, -5)
            self.PSFIndicator:SetPoint("BOTTOMLEFT", 0, 5)
            self.PSFIndicator:SetWidth(2)
        end
        SetButtonState(self)
    end
    button.PSFStyle = "action"
    SetButtonState(button)
    return button
end

function addon:CreatePSFCheckbox(parent, text, x, y, callback)
    local check = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
    check:SetPoint("TOPLEFT", x, y)
    check:SetSize(460, 28)
    check:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    check:SetBackdropColor(.08, .09, .105, .18)
    check:SetBackdropBorderColor(0, 0, 0, 0)
    local focusBar = check:CreateTexture(nil, "ARTWORK")
    focusBar:SetTexture(WHITE); focusBar:SetWidth(2)
    focusBar:SetPoint("TOPLEFT", 0, -5); focusBar:SetPoint("BOTTOMLEFT", 0, 5)
    focusBar:SetVertexColor(unpack(self.uiColors.accent)); focusBar:Hide()
    local mark = check:CreateTexture(nil, "ARTWORK")
    mark:SetTexture(WHITE); mark:SetSize(14, 14); mark:SetPoint("LEFT", 7, 0)
    mark:SetVertexColor(unpack(self.uiColors.accent))
    check:SetCheckedTexture(mark)
    check.Text = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    check.Text:SetPoint("LEFT", 30, 0)
    if not check.Text:SetFont(self:GetUIFontPath(false), 13, "") then check.Text:SetFont(STANDARD_TEXT_FONT, 13, "") end
    check.Text:SetTextColor(unpack(self.uiColors.text))
    check.Text:SetText(text)
    local function SetCheckboxState(self)
        local focused = self.PSFHovered or self.PSFControllerFocused
        self:SetBackdropColor(focused and .09 or .08, focused and .14 or .09, focused and .11 or .105, focused and .76 or .18)
        self:SetBackdropBorderColor(0, 0, 0, 0)
        focusBar:SetShown(focused and true or false)
    end
    check:SetScript("OnEnter", function(self)
        self.PSFHovered = true
        SetCheckboxState(self)
    end)
    check:SetScript("OnLeave", function(self)
        self.PSFHovered = nil
        SetCheckboxState(self)
    end)
    check.SetPSFControllerFocused = function(self, focused)
        self.PSFControllerFocused = focused and true or nil
        SetCheckboxState(self)
    end
    check:SetScript("OnClick", callback)
    return check
end
