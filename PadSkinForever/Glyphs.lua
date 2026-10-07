local _, addon = ...
local originals = setmetatable({}, { __mode = "k" })
local face = { PAD1 = "buttona", PAD2 = "buttonb", PAD3 = "buttonx", PAD4 = "buttony" }
local dpad = { PADDUP = "dpadup", PADDDOWN = "dpaddown", PADDLEFT = "dpadleft", PADDRIGHT = "dpadright",
               DIRPAD = "dpadall", DIRPADHORIZONTAL = "dpadleftright", DIRPADVERTICAL = "dpadupdown" }
local states = { "normal", "over", "down", "focus", "disabled" }
local colors = { PAD1 = { .12, 1, .12 }, PAD2 = { 1, .12, .12 }, PAD3 = { .12, .5, 1 }, PAD4 = { 1, .9, .05 } }
addon.xboxColors = colors
function addon:IsDpadKey(key) return dpad[key] ~= nil end
addon.faceStyles = { "native", "xbox", "xboxColor" }
addon.faceStyleLabels = { "Blizzard default", "Xbox monochrome", "Xbox colored" }
addon.dpadStyles = { "native", "xbox", "xboxAccent" }
addon.dpadStyleLabels = { "Blizzard default", "Xbox monochrome", "Xbox blue" }

-- Canonical PSF input presentation. This does not bind keys or alter Blizzard's
-- controller stack; it only gives modules one place to resolve glyph language.
function addon:GetInputGlyphStyle(key)
    if face[key] then return self.design.input.glyph.face end
    if dpad[key] then return self.design.input.glyph.dpad end
    return "native"
end

function addon:GetInputGlyphColor(key)
    if face[key] then return colors[key] end
    if dpad[key] then return self:GetInputFocusColor() end
end

local function CaptureAtlases(icon, original)
    for state, texture in pairs(icon.textureStateTextures or {}) do
        original.atlases[state] = texture:GetAtlas()
    end
end

local function Points(icon)
    local points = {}
    for index = 1, icon:GetNumPoints() do points[index] = { icon:GetPoint(index) } end
    return points
end

function addon:SkinGlyph(icon, enabled, label, button, sizeMultiplier)
    if not icon then return end
    self:DebugSurface(icon, label, "glyph frame")
    local original = originals[icon]
    if not original then
        original = { scale = icon:GetScale(), atlases = {}, points = Points(icon) }
        CaptureAtlases(icon, original)
        originals[icon] = original
        hooksecurefunc(icon, "SetPoint", function()
            if addon.applyingSkin then return end
            original.points = Points(icon)
            original.positioned = false
            addon:QueueRefresh()
        end)
        hooksecurefunc(icon, "RefreshIconTextures", function()
            -- Blizzard just supplied current device/key art. Save that art,
            -- not our previous replacement, for future restoration.
            CaptureAtlases(icon, original)
            original.overridden = false
            addon:QueueRefresh()
        end)
    end
    local key = icon.mappedButtonKey
    local isFace, isDpad = face[key] ~= nil, dpad[key] ~= nil
    local style = isFace and self.db.faceGlyphStyle or isDpad and self.db.dpadGlyphStyle or "native"
    local scale = isFace and self.db.faceGlyphScale or isDpad and self.db.dpadGlyphScale or 1
    scale = scale * (sizeMultiplier or 1)
    if not enabled then style, scale = "native", 1 end
    local desiredScale = original.scale * scale
    if enabled then
        if icon:GetScale() ~= desiredScale then icon:SetScale(desiredScale) end
        original.scaled = scale ~= 1
    elseif original.scaled then
        icon:SetScale(original.scale)
        original.scaled = false
    end
    -- Preserve the native side/corner rather than moving every prompt to one corner.
    -- Compensate for added width/height so the inner edge stays at its native position.
    if enabled and button and self.db.glyphOutside and (isFace or isDpad) then
        local width, height = icon:GetSize()
        local growX = math.max(0, desiredScale - original.scale) * width
        local growY = math.max(0, desiredScale - original.scale) * height
        icon:ClearAllPoints()
        for _, anchor in ipairs(original.points) do
            local point, relative, relativePoint, x, y = unpack(anchor)
            local dx = point:find("RIGHT") and 1 or point:find("LEFT") and -1 or 0
            local dy = point:find("TOP") and 1 or point:find("BOTTOM") and -1 or 0
            icon:SetPoint(point, relative or button, relativePoint,
                ((x or 0) * original.scale + dx * growX) / desiredScale,
                ((y or 0) * original.scale + dy * growY) / desiredScale)
        end
        original.positioned = true
    elseif original.positioned then
        icon:ClearAllPoints()
        for _, point in ipairs(original.points) do icon:SetPoint(unpack(point)) end
        original.positioned = false
    end
    local overriding = false
    for state, texture in pairs(icon.textureStateTextures or {}) do
        self:DebugSurface(texture, label .. "/state" .. state, "glyph texture")
        if style ~= "native" then
            local symbol = face[key] or dpad[key]
            local suffix = states[state]
            local atlas = symbol and suffix and ("gamepad-xbox1-" .. symbol .. "-" .. suffix)
            if atlas and C_Texture.GetAtlasInfo(atlas) then
                if texture:GetAtlas() ~= atlas then texture:SetAtlas(atlas) end
                overriding = true
            end
        elseif original.overridden and original.atlases[state] then
            texture:SetAtlas(original.atlases[state])
        end
        local color = style == "xboxColor" and colors[key] or style == "xboxAccent" and self.db.accent or nil
        if color and texture == icon.DisabledTexture then
            color = { color[1] * self.db.disabledGlyphIntensity, color[2] * self.db.disabledGlyphIntensity, color[3] * self.db.disabledGlyphIntensity }
        end
        self:Tint(texture, color, color and self.db.vividGlyphs and 1 or nil)
    end
    original.overridden = overriding
end
