local _, addon = ...
local assets = "Interface\\AddOns\\PadSkinForever\\Media\\"
local saved = setmetatable({}, { __mode = "k" })
local hidden = setmetatable({}, { __mode = "k" })

local function Asset(texture, file)
    if not texture then return end
    local original = saved[texture]
    if file then
        if not original then
            original = { atlas = texture:GetAtlas(), texture = texture:GetTexture(), coords = { texture:GetTexCoord() } }
            saved[texture] = original
        end
        -- A native shape change supplies a fresh atlas. Restore that latest art.
        if texture:GetAtlas() then
            original.atlas = texture:GetAtlas()
            original.coords = { texture:GetTexCoord() }
        end
        texture:SetTexture(assets .. file .. ".tga")
        texture:SetTexCoord(0, 1, 0, 1)
    elseif original then
        if original.atlas then texture:SetAtlas(original.atlas)
        else texture:SetTexture(original.texture) end
        texture:SetTexCoord(unpack(original.coords))
        saved[texture] = nil
    end
end

local function HideDecoration(texture, enabled)
    if not texture then return end
    if enabled then
        if hidden[texture] == nil then hidden[texture] = texture:GetAlpha() end
        texture:SetAlpha(0)
    elseif hidden[texture] ~= nil then
        texture:SetAlpha(hidden[texture]); hidden[texture] = nil
    end
end

function addon:SkinButtonAssets(button)
    local minimal = self.db.skinButtons and self.db.buttonStyle == "minimal"
    local circle = button.CircleMask and button.CircleMask:IsShown()
    local shape = circle and "Circle" or "Square"
    Asset(button:GetNormalTexture(), minimal and shape .. "Border" or nil)
    Asset(button:GetPushedTexture(), minimal and shape .. "Pressed" or nil)
    Asset(button.SlotArt, minimal and shape .. "Empty" or nil)
    for _, name in ipairs({ "Border", "CircleShadow", "SquareShadow", "SlotBackground" }) do
        HideDecoration(button[name], minimal)
    end
end
