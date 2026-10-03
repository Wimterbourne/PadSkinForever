local _, addon = ...

-- Shared PSF presentation primitives. These only create addon-owned frames;
-- Blizzard frames, bindings and navigation tables are never modified here.
local WHITE = "Interface\\Buttons\\WHITE8X8"
local CORNER = "Interface\\AddOns\\PadSkinForever\\Media\\LegendCorner"

addon.uiColors = {
    fill = { .055, .062, .073, .97 },
    raised = { .085, .095, .11, .98 },
    border = { .40, .43, .47, 1 },
    borderSoft = { .27, .30, .34, 1 },
    accent = { .34, .86, .49, 1 },
    text = { .94, .95, .96, 1 },
    muted = { .64, .67, .71, 1 },
}

local function Color(region, color)
    region:SetVertexColor(unpack(color))
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
            texture:SetSize(8, 8)
            texture:SetPoint(corner, panel, corner)
            local right, bottom = corner:find("RIGHT"), corner:find("BOTTOM")
            texture:SetTexCoord(right and 1 or 0, right and 0 or 1, bottom and 1 or 0, bottom and 0 or 1)
            Color(texture, color)
        end
        if asset == "Fill" then
            Rect(panel, drawLayer, color, "TOPLEFT", "BOTTOMRIGHT", 8, 0, -8, 0)
            Rect(panel, drawLayer, color, "TOPLEFT", "BOTTOMLEFT", 0, -8, 8, 8)
            Rect(panel, drawLayer, color, "TOPRIGHT", "BOTTOMRIGHT", 0, -8, -8, 8)
        else
            Rect(panel, drawLayer, color, "TOPLEFT", "TOPRIGHT", 8, 0, -8, -1)
            Rect(panel, drawLayer, color, "BOTTOMLEFT", "BOTTOMRIGHT", 8, 0, -8, 1)
            Rect(panel, drawLayer, color, "TOPLEFT", "BOTTOMLEFT", 0, -8, 1, 8)
            Rect(panel, drawLayer, color, "TOPRIGHT", "BOTTOMRIGHT", 0, -8, -1, 8)
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
    local selected = button.PSFSelected or button.PSFHovered
    if selected then
        button:SetBackdropColor(.09, .14, .11, .98)
        button:SetBackdropBorderColor(unpack(colors.accent))
    else
        button:SetBackdropColor(unpack(colors.raised))
        button:SetBackdropBorderColor(unpack(colors.borderSoft))
    end
    if button.PSFText then
        button.PSFText:SetTextColor(unpack(selected and colors.text or colors.muted))
    end
end

function addon:CreatePSFButton(parent, text, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetPoint("TOPLEFT", x, y)
    button:SetSize(width, 28)
    button:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
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
    SetButtonState(button)
    return button
end

function addon:CreatePSFCheckbox(parent, text, x, y, callback)
    local check = CreateFrame("CheckButton", nil, parent, "BackdropTemplate")
    check:SetPoint("TOPLEFT", x, y)
    check:SetSize(460, 28)
    check:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    check:SetBackdropColor(unpack(self.uiColors.raised))
    check:SetBackdropBorderColor(unpack(self.uiColors.borderSoft))
    local mark = check:CreateTexture(nil, "ARTWORK")
    mark:SetTexture(WHITE); mark:SetSize(14, 14); mark:SetPoint("LEFT", 7, 0)
    mark:SetVertexColor(unpack(self.uiColors.accent))
    check:SetCheckedTexture(mark)
    check.Text = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    check.Text:SetPoint("LEFT", 30, 0)
    if not check.Text:SetFont(self:GetUIFontPath(false), 13, "") then check.Text:SetFont(STANDARD_TEXT_FONT, 13, "") end
    check.Text:SetTextColor(unpack(self.uiColors.text))
    check.Text:SetText(text)
    check:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(addon.uiColors.accent))
    end)
    check:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(addon.uiColors.borderSoft))
    end)
    check:SetScript("OnClick", callback)
    return check
end
