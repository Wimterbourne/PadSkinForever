local _, addon = ...

-- Shared PSF presentation primitives. These only create addon-owned frames;
-- Blizzard frames, bindings and navigation tables are never modified here.
local WHITE = "Interface\\Buttons\\WHITE8X8"
local CORNER = "Interface\\AddOns\\PadSkinForever\\Media\\LegendCorner"
local PANEL_RADIUS = 12

-- PSF 1.0 design-system foundation. Keep these tokens semantic: modules
-- should request a role (surface, rail, identity, focus) rather than inventing
-- local colors and geometry. 1920x1080 at UI scale 0.9-1.0 is the baseline.
addon.design = {
    baseline = { width = 1920, height = 1080, minScale = .9, maxScale = 1.0 },
    radius = { card = 12, compact = 9, socket = 7, rail = 5 },
    spacing = { hairline = 1, inset = 3, gap = 2, group = 6, section = 10 },
    depth = { peripheral = .78, standard = .90, combat = .96 },
    surface = {
        -- Spatial glass keeps the world visible. Edges/highlights define shape;
        -- opaque fills are reserved for wells and readability-critical surfaces.
        glass = { fill = { .030, .040, .055, .34 }, border = { .78, .84, .92, .34 } },
        strong = { fill = { .020, .026, .034, .88 }, border = { .66, .71, .77, .30 } },
        peripheral = { fill = { .028, .038, .052, .26 }, border = { .72, .79, .87, .24 } },
        well = { fill = { .010, .014, .020, .72 }, border = { .52, .58, .65, .16 } },
        wellSoft = { fill = { .010, .014, .020, .54 }, border = { .52, .58, .65, .10 } },
        rail = { fill = { .018, .024, .032, .66 }, border = { .62, .67, .73, .18 } },
        floating = { fill = { .034, .046, .064, .42 }, border = { .80, .86, .94, .36 } },
    },
    identity = {
        edgeAlpha = .92,
        edgeSoftAlpha = .42,
        neutral = { .62, .67, .73, 1 },
    },
    focus = { color = { .34, .86, .49, 1 }, bracketAlpha = .96 },
    type = {
        title = { size = 15, weight = "semibold" },
        name = { size = 13, weight = "semibold" },
        body = { size = 13, weight = "regular" },
        label = { size = 12, weight = "semibold" },
        value = { size = 11, weight = "semibold" },
        world = { size = 12, weight = "semibold", flags = "OUTLINE" },
    },
}
-- Compatibility aliases while existing 0.9 components migrate to semantic
-- primitives. Remove these only after every module uses design.surface/radius.
addon.design.cardRadius = addon.design.radius.card
addon.design.compactRadius = addon.design.radius.compact
addon.design.inset = addon.design.spacing.inset
addon.design.gap = addon.design.spacing.gap
addon.design.card = addon.design.surface.glass
addon.design.cardStrong = addon.design.surface.strong
addon.design.well = addon.design.surface.well
addon.design.wellSoft = addon.design.surface.wellSoft
addon.design.rail = addon.design.surface.rail
addon.design.floating = addon.design.surface.floating

addon.uiColors = {
    fill = addon.design.surface.strong.fill,
    raised = { .065, .076, .091, .98 },
    border = { .42, .47, .53, .82 },
    borderSoft = { .32, .37, .43, .62 },
    accent = addon.design.focus.color,
    text = { .94, .95, .96, 1 },
    muted = { .64, .67, .71, 1 },
}

-- One semantic palette for every PSF bar family. Resource/status color is
-- deliberately separate from class identity and Xbox input color.
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

-- Identity color is intentionally not selection color. Player units use their
-- own class color; NPC/pet identity falls back to a neutral glass edge.
function addon:GetIdentityColor(unit)
    if unit and UnitIsPlayer and UnitIsPlayer(unit) and UnitClass then
        local _, class = UnitClass(unit)
        local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if color then return { color.r, color.g, color.b, 1 } end
    end
    return self.design.identity.neutral
end

function addon:GetSurfacePalette(role)
    return self.design.surface[role or "glass"] or self.design.surface.glass
end

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

function addon:CreateGlassPanel(parent, palette, radius)
    if parent.PSFGlassPanel then return parent.PSFGlassPanel end
    palette = palette or self.design.surface.glass
    radius = radius or self.design.radius.card

    -- Start with the normal rounded translucent surface, then add restrained
    -- lighting cues. WoW has no backdrop blur here, so depth must come from
    -- layered edge contrast rather than a heavier opaque fill.
    self:CreateRoundedPanel(parent, palette, radius)

    local regions = parent.PSFRoundedRegions
    if not regions then return parent end
    regions.glass = regions.glass or {}

    -- Soft inner top light: enough to read as a reflective surface without
    -- becoming a bright frame or competing with class identity.
    local top = parent:CreateTexture(nil, "BORDER", nil, 1)
    top:SetTexture("Interface\\Buttons\\WHITE8X8")
    top:SetPoint("TOPLEFT", parent, "TOPLEFT", radius, -1)
    top:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -radius, -1)
    top:SetHeight(1)
    top:SetVertexColor(.92, .96, 1, .30)
    table.insert(regions.glass, top)

    -- Side glints establish thickness on dark scenes while remaining quieter
    -- than the outer identity seam.
    for _, side in ipairs({ "LEFT", "RIGHT" }) do
        local edge = parent:CreateTexture(nil, "BORDER", nil, 1)
        edge:SetTexture("Interface\\Buttons\\WHITE8X8")
        edge:SetPoint("TOP" .. side, parent, "TOP" .. side, side == "LEFT" and 1 or -1, -radius)
        edge:SetPoint("BOTTOM" .. side, parent, "BOTTOM" .. side, side == "LEFT" and 1 or -1, radius)
        edge:SetWidth(1)
        edge:SetVertexColor(.78, .86, .96, .14)
        table.insert(regions.glass, edge)
    end

    -- A low inner shade separates the glass from bright world/map content and
    -- gives the panel a shallow floating depth without a fake drop shadow.
    local bottom = parent:CreateTexture(nil, "BORDER", nil, 1)
    bottom:SetTexture("Interface\\Buttons\\WHITE8X8")
    bottom:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", radius, 1)
    bottom:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -radius, 1)
    bottom:SetHeight(1)
    bottom:SetVertexColor(.01, .015, .025, .30)
    table.insert(regions.glass, bottom)

    parent.PSFGlassPanel = parent
    return parent
end

function addon:CreateRoundedPanel(parent, palette, radius)
    if parent.PSFRoundedPanel then return parent.PSFRoundedPanel end
    -- Draw directly on the owner so its child controls and header regions stay
    -- above the background without adding another focusable frame layer.
    local panel = parent
    local colors = self.uiColors
    radius = radius or PANEL_RADIUS
    palette = palette or self.design.card
    local fill = palette.fill or colors.fill
    local border = palette.border or colors.border
    parent.PSFRoundedRegions = parent.PSFRoundedRegions or { fill = {}, border = {} }
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
            table.insert(parent.PSFRoundedRegions[asset == "Fill" and "fill" or "border"], texture)
        end
        if asset == "Fill" then
            table.insert(parent.PSFRoundedRegions.fill, Rect(panel, drawLayer, color, "TOPLEFT", "BOTTOMRIGHT", radius, 0, -radius, 0))
            table.insert(parent.PSFRoundedRegions.fill, Rect(panel, drawLayer, color, "TOPLEFT", "BOTTOMLEFT", 0, -radius, radius, radius))
            table.insert(parent.PSFRoundedRegions.fill, Rect(panel, drawLayer, color, "TOPRIGHT", "BOTTOMRIGHT", 0, -radius, -radius, radius))
        else
            table.insert(parent.PSFRoundedRegions.border, Rect(panel, drawLayer, color, "TOPLEFT", "TOPRIGHT", radius, 0, -radius, -1))
            table.insert(parent.PSFRoundedRegions.border, Rect(panel, drawLayer, color, "BOTTOMLEFT", "BOTTOMRIGHT", radius, 0, -radius, 1))
            table.insert(parent.PSFRoundedRegions.border, Rect(panel, drawLayer, color, "TOPLEFT", "BOTTOMLEFT", 0, -radius, 1, radius))
            table.insert(parent.PSFRoundedRegions.border, Rect(panel, drawLayer, color, "TOPRIGHT", "BOTTOMRIGHT", 0, -radius, -1, radius))
        end
    end
    parent.PSFRoundedPanel = panel
    return panel
end

function addon:SetRoundedPanelVisualAlpha(parent, fillAlpha, borderAlpha)
    local regions = parent and parent.PSFRoundedRegions
    if not regions then return end
    for _, region in ipairs(regions.fill) do region:SetAlpha(fillAlpha or 1) end
    for _, region in ipairs(regions.border) do region:SetAlpha(borderAlpha or fillAlpha or 1) end
end

-- Follow the native fill texture declaratively instead of reading its width.
-- WoW can mark target health geometry as secret; anchoring a clipping frame to
-- that texture remains permitted and keeps the fixed-size caps available.
local roundedBars = setmetatable({}, { __mode = "k" })
local function PaintRoundedBar(data)
    local color = data.color or addon.barColors.neutral
    local alpha = (color[4] or 1) * (data.visualAlpha or 1)
    for _, region in ipairs(data.regions) do region:SetVertexColor(color[1], color[2], color[3], alpha) end
end
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
    data.color = color or self.barColors.neutral
    PaintRoundedBar(data)
    data.updater:Show()
    UpdateRoundedBar(data)
end


function addon:SetRoundedBarVisualAlpha(bar, alpha)
    local data = roundedBars[bar]
    if not data then return end
    data.visualAlpha = alpha or 1
    PaintRoundedBar(data)
end

function addon:ApplyPSFFont(text, role)
    if not text or not text.SetFont then return end
    local style = self.design.type[role or "body"] or self.design.type.body
    local path = self:GetUIFontPath(style.weight == "semibold")
    if not text:SetFont(path, style.size, style.flags or "") then
        text:SetFont(STANDARD_TEXT_FONT, style.size, style.flags or "")
    end
    if text.SetTextColor then text:SetTextColor(unpack(self.uiColors.text)) end
    if text.SetShadowColor then text:SetShadowColor(0, 0, 0, .85) end
    if text.SetShadowOffset then text:SetShadowOffset(1, -1) end
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
