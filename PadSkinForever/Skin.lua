local _, addon = ...
-- Keep our bookkeeping outside Blizzard frame tables.
local textureOriginals = setmetatable({}, { __mode = "k" })
local fontOriginals = setmetatable({}, { __mode = "k" })
local hooked = setmetatable({}, { __mode = "k" })
local anchors = { "TopCenteredAnchor", "BottomCenteredAnchor", "LeftCenteredAnchor", "RightCenteredAnchor" }
function addon:Tint(texture, color, alpha)
    if not texture or not texture.SetVertexColor then return end
    local original = textureOriginals[texture]
    if color then
        if not original then
            local r, g, b, a = texture:GetVertexColor()
            original = { r, g, b, a, texture:GetDesaturation() }
            textureOriginals[texture] = original
        end
        texture:SetDesaturation(1)
        texture:SetVertexColor(color[1], color[2], color[3], alpha or original[4])
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
    hooksecurefunc(object, method, function()
        if not addon.applyingSkin then addon:QueueRefresh() end
    end)
end

local function SkinButton(button, label)
    local db = addon.db
    addon:SkinButtonAssets(button)
    local color = db.skinButtons and db.accent or nil
    local minimal = db.skinButtons and db.buttonStyle == "minimal"
    if minimal then
        local key = button.ButtonIcon and button.ButtonIcon.mappedButtonKey
        color = addon.xboxColors[key] or addon:IsDpadKey(key) and { .65, .68, .72 } or db.accent
    end
    -- Empty slot assets stay dark and neutral; only the borders use button colors.
    local slotColor = minimal and { 1, 1, 1 } or color
    addon:DebugSurface(button:GetNormalTexture(), label .. "/border", "button border")
    addon:DebugSurface(button:GetPushedTexture(), label .. "/pushed", "button border")
    addon:DebugSurface(button.SlotArt, label .. "/slot", "empty slot")
    addon:Tint(button:GetNormalTexture(), color)
    addon:Tint(button:GetPushedTexture(), color)
    addon:Tint(button.SlotArt, slotColor)
    addon:Tint(button.SlotBackground, slotColor)
    addon:SkinGlyph(button.ButtonIcon, true, label .. "/glyph", button)
    for _, name in ipairs({ "cooldown", "chargeCooldown", "lossOfControlCooldown" }) do
        local cooldown = button[name]
        if cooldown and cooldown.GetCountdownFontString then
            local text = cooldown:GetCountdownFontString()
            addon:DebugSurface(text, label .. "/" .. name, "cooldown font")
            Font(text, db.cooldownFont, db.fontSize, db.fontFlags)
        end
    end
    Hook(button, "SetShapeToCircle")
    Hook(button, "SetShapeToSquare")
    Hook(button, "UpdateEmptySlotBackgroundTexture")
    Hook(button, "UpdateButtonArt")
end

-- Only walk the legend's decorative background, never arbitrary UI frames.
local function Background(frame, color, depth, label)
    if not frame or depth > 5 then return end
    for index, region in ipairs({ frame:GetRegions() }) do
        if region:IsObjectType("Texture") then
            addon:DebugSurface(region, label .. "/region" .. index, "legend background")
            addon:Tint(region, color)
        end
    end
    for index, child in ipairs({ frame:GetChildren() }) do
        Background(child, color, depth + 1, label .. "/child" .. index)
    end
end

local function RefreshSkin(self)
    if not self.db or InCombatLockdown() then return end
    self:ObserveSharedMedia()
    self:RefreshTheme()
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
                        if button then SkinButton(button, name .. "/" .. side .. index) end
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
        for name, group in pairs(legend.groups or {}) do
            for index, frame in ipairs(group) do
                local label = "Legend/" .. name .. "/" .. index
                self:SkinGlyph(frame.InputIcon1, self.db.skinLegend, label .. "/icon1")
                self:SkinGlyph(frame.InputIcon2, self.db.skinLegend, label .. "/icon2")
                local text = frame.ControlDescText and frame.ControlDescText.FontString
                -- Preserve native legend text size and positioning.
                self:DebugSurface(text, label .. "/text", "legend font")
                Font(text, self.db.skinLegend)
                Background(frame.Background, self.db.skinLegend and self.db.accent or nil, 0, label .. "/background")
                addon:Tint(frame.HeaderTrim, self.db.skinLegend and self.db.accent or nil)
            end
        end
    end
end

function addon:RefreshSkin()
    self.applyingSkin = true
    local ok, message = pcall(RefreshSkin, self)
    self.applyingSkin = false
    if not ok then error(message, 0) end
end
