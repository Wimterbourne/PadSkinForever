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

function addon:CreateRoundedPanel(parent)
    if parent.PSFRoundedPanel then return parent.PSFRoundedPanel end
    -- Draw directly on the owner so its child controls and header regions stay
    -- above the background without adding another focusable frame layer.
    local panel = parent
    local colors = self.uiColors
    for _, layerInfo in ipairs({ { "BACKGROUND", colors.fill, "Fill" }, { "BORDER", colors.border, "Border" } }) do
        local drawLayer, color, asset = unpack(layerInfo)
        for _, corner in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
            local texture = panel:CreateTexture(nil, drawLayer)
            texture:SetTexture(CORNER .. asset .. ".tga")
            texture:SetSize(PANEL_RADIUS, PANEL_RADIUS)
            texture:SetPoint(corner, panel, corner)
            local right, bottom = corner:find("RIGHT"), corner:find("BOTTOM")
            texture:SetTexCoord(right and 1 or 0, right and 0 or 1, bottom and 1 or 0, bottom and 0 or 1)
            Color(texture, color)
        end
        if asset == "Fill" then
            Rect(panel, drawLayer, color, "TOPLEFT", "BOTTOMRIGHT", PANEL_RADIUS, 0, -PANEL_RADIUS, 0)
            Rect(panel, drawLayer, color, "TOPLEFT", "BOTTOMLEFT", 0, -PANEL_RADIUS, PANEL_RADIUS, PANEL_RADIUS)
            Rect(panel, drawLayer, color, "TOPRIGHT", "BOTTOMRIGHT", 0, -PANEL_RADIUS, -PANEL_RADIUS, PANEL_RADIUS)
        else
            Rect(panel, drawLayer, color, "TOPLEFT", "TOPRIGHT", PANEL_RADIUS, 0, -PANEL_RADIUS, -1)
            Rect(panel, drawLayer, color, "BOTTOMLEFT", "BOTTOMRIGHT", PANEL_RADIUS, 0, -PANEL_RADIUS, 1)
            Rect(panel, drawLayer, color, "TOPLEFT", "BOTTOMLEFT", 0, -PANEL_RADIUS, 1, PANEL_RADIUS)
            Rect(panel, drawLayer, color, "TOPRIGHT", "BOTTOMRIGHT", 0, -PANEL_RADIUS, -1, PANEL_RADIUS)
        end
    end
    parent.PSFRoundedPanel = panel
    return panel
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
