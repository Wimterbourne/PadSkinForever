local _, addon = ...
-- Keep our bookkeeping outside Blizzard frame tables.
local textureOriginals = setmetatable({}, { __mode = "k" })
local fontOriginals = setmetatable({}, { __mode = "k" })
local hooked = setmetatable({}, { __mode = "k" })
local anchors = { "TopCenteredAnchor", "BottomCenteredAnchor", "LeftCenteredAnchor", "RightCenteredAnchor" }
local glyphColors = { PAD1 = { 0.25, 1, 0.25 }, PAD2 = { 1, 0.25, 0.25 },
                      PAD3 = { 0.25, 0.55, 1 }, PAD4 = { 1, 0.85, 0.15 } }

local function Tint(texture, color)
    if not texture or not texture.SetVertexColor then return end
    local original = textureOriginals[texture]
    if color then
        if not original then
            local r, g, b, a = texture:GetVertexColor()
            original = { r, g, b, a, texture:GetDesaturation() }
            textureOriginals[texture] = original
        end
        texture:SetDesaturation(1)
        texture:SetVertexColor(color[1], color[2], color[3], original[4])
    elseif original then
        texture:SetDesaturation(original[5])
        texture:SetVertexColor(original[1], original[2], original[3], original[4])
        textureOriginals[texture] = nil
    end
end

local function Font(text, enabled, size, flags)
    if not text then return end
    local original = fontOriginals[text]
    if enabled then
        if not original then
            local path, oldSize, oldFlags = text:GetFont()
            if not path then return end
            original = { path, oldSize, oldFlags }
            fontOriginals[text] = original
        end
        local path = addon:GetFontPath()
        if not text:SetFont(path, size or original[2], flags or original[3]) then
            text:SetFont(STANDARD_TEXT_FONT, size or original[2], flags or original[3])
        end
    elseif original then
        text:SetFont(unpack(original))
        fontOriginals[text] = nil
    end
end

local function Hook(object, method)
    if not object or type(object[method]) ~= "function" then return end
    local methods = hooked[object]
    if not methods then methods = {}; hooked[object] = methods end
    if methods[method] then return end
    methods[method] = true
    -- A post-hook only requests a later visual refresh; it does not replace
    -- Blizzard's method or run protected interaction/navigation calls.
    hooksecurefunc(object, method, function() addon:QueueRefresh() end)
end

local function Glyph(icon, enabled)
    if not icon then return end
    Hook(icon, "RefreshIconTextures")
    for _, texture in pairs(icon.textureStateTextures or {}) do
        local atlas = texture:GetAtlas()
        local color = enabled and glyphColors[icon.mappedButtonKey]
        -- Preserve disabled feedback and PlayStation/other-device artwork.
        if not atlas or not atlas:find("gamepad%-xbox1%-button") or texture == icon.DisabledTexture then
            color = nil
        end
        Tint(texture, color)
    end
end

local function SkinButton(button)
    local db = addon.db
    local color = db.skinButtons and db.accent or nil
    Tint(button:GetNormalTexture(), color)
    Tint(button:GetPushedTexture(), color)
    Tint(button.SlotArt, color)
    Tint(button.SlotBackground, color)
    Glyph(button.ButtonIcon, db.colorGlyphs)
    for _, name in ipairs({ "cooldown", "chargeCooldown", "lossOfControlCooldown" }) do
        local cooldown = button[name]
        if cooldown and cooldown.GetCountdownFontString then
            Font(cooldown:GetCountdownFontString(), db.cooldownFont, db.fontSize, db.fontFlags)
        end
    end
    Hook(button, "SetShapeToCircle")
    Hook(button, "SetShapeToSquare")
    Hook(button, "UpdateEmptySlotBackgroundTexture")
    Hook(button, "UpdateButtonArt")
end

-- Only walk the legend's decorative background, never arbitrary UI frames.
local function Background(frame, color, depth)
    if not frame or depth > 5 then return end
    for _, region in ipairs({ frame:GetRegions() }) do
        if region:IsObjectType("Texture") then Tint(region, color) end
    end
    for _, child in ipairs({ frame:GetChildren() }) do
        Background(child, color, depth + 1)
    end
end

function addon:RefreshSkin()
    if not self.db or InCombatLockdown() then return end
    self:ObserveSharedMedia()
    local main = GamepadMainActionBarFrame
    local page = main and main.PageUnit
    if page then
        for _, name in ipairs(anchors) do
            local anchor = page[name]
            local bar = anchor and anchor.Bar
            if bar then
                for _, side in ipairs({ "Left", "Right" }) do
                    local quad = bar[side]
                    for index = 1, 4 do
                        local button = quad and quad["ActionButton" .. index]
                        if button then SkinButton(button) end
                    end
                end
            end
        end
    end
    local legend = GamepadPersistentInputLegend
    if legend then
        Hook(legend, "PostVariableSetUp")
        Hook(legend, "CreateEntry")
        Hook(legend, "CreateBackground")
        for _, group in pairs(legend.groups or {}) do
            for _, frame in ipairs(group) do
                Glyph(frame.InputIcon1, self.db.skinLegend and self.db.colorGlyphs)
                Glyph(frame.InputIcon2, self.db.skinLegend and self.db.colorGlyphs)
                local text = frame.ControlDescText and frame.ControlDescText.FontString
                -- Preserve native legend text size and positioning.
                Font(text, self.db.skinLegend)
                Background(frame.Background, self.db.skinLegend and self.db.accent or nil, 0)
                Tint(frame.HeaderTrim, self.db.skinLegend and self.db.accent or nil)
            end
        end
    end
end
