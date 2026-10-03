local _, addon = ...
local originals = setmetatable({}, { __mode = "k" })
local face = { PAD1 = "buttona", PAD2 = "buttonb", PAD3 = "buttonx", PAD4 = "buttony" }
local dpad = { PADDUP = "dpadup", PADDDOWN = "dpaddown", PADDLEFT = "dpadleft", PADDRIGHT = "dpadright",
               DIRPAD = "dpadall", DIRPADHORIZONTAL = "dpadleftright", DIRPADVERTICAL = "dpadupdown" }
local states = { "normal", "over", "down", "focus", "disabled" }
local colors = { PAD1 = { .25, 1, .25 }, PAD2 = { 1, .25, .25 }, PAD3 = { .25, .55, 1 }, PAD4 = { 1, .85, .15 } }
addon.faceStyles = { "native", "xbox", "xboxColor" }
addon.faceStyleLabels = { "Blizzard default", "Xbox monochrome", "Xbox colored" }
addon.dpadStyles = { "native", "xbox", "xboxAccent" }
addon.dpadStyleLabels = { "Blizzard default", "Xbox monochrome", "Xbox blue" }

local function CaptureAtlases(icon, original)
    for state, texture in pairs(icon.textureStateTextures or {}) do
        original.atlases[state] = texture:GetAtlas()
    end
end

function addon:SkinGlyph(icon, enabled, label)
    if not icon then return end
    self:DebugSurface(icon, label, "glyph frame")
    local original = originals[icon]
    if not original then
        original = { scale = icon:GetScale(), atlases = {} }
        CaptureAtlases(icon, original)
        originals[icon] = original
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
    if not enabled then style, scale = "native", 1 end
    local desiredScale = original.scale * scale
    if enabled then
        if icon:GetScale() ~= desiredScale then icon:SetScale(desiredScale) end
        original.scaled = scale ~= 1
    elseif original.scaled then
        icon:SetScale(original.scale)
        original.scaled = false
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
            color = { color[1] * .45, color[2] * .45, color[3] * .45 }
        end
        self:Tint(texture, color)
    end
    original.overridden = overriding
end
