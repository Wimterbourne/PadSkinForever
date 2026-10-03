local _, addon = ...

local bundled = {
    ["PSF Inter Regular"] = "Interface\\AddOns\\PadSkinForever\\Media\\Fonts\\Inter-Regular.ttf",
    ["PSF Inter SemiBold"] = "Interface\\AddOns\\PadSkinForever\\Media\\Fonts\\Inter-SemiBold.ttf",
}

local function SharedMedia()
    return LibStub and LibStub("LibSharedMedia-3.0", true)
end

function addon:GetFonts()
    local fonts = { ["Blizzard default"] = STANDARD_TEXT_FONT }
    for name, path in pairs(bundled) do fonts[name] = path end
    local media = SharedMedia()
    if media then
        for _, name in ipairs(media:List("font")) do
            fonts[name] = media:Fetch("font", name, true)
        end
    end

    -- Font Manager 1.1.1 has no bundled LSM. Its saved filenames are also
    -- available when there is no shared-media library, or it loaded later.
    -- Read its public data only; do not change its settings or copy its code.
    local directory = "Interface\\AddOns\\FontManager\\Fonts\\"
    -- Do not import FontManager_Files: it includes the optional Custom.ttf
    -- placeholder even when that file does not exist. Bundled fonts are
    -- discovered through LSM; only explicitly added user filenames are fallback.
    local manager = FontManagerDB
    for _, file in ipairs(type(manager) == "table" and manager.userFonts or {}) do
        if type(file) == "string" then
            local name = file:gsub("%.%w+$", "")
            fonts[name] = fonts[name] or directory .. file
        end
    end
    return fonts
end

function addon:GetFontPath()
    return self:GetFonts()[self.db.font] or STANDARD_TEXT_FONT
end

function addon:GetLegendHeaderFontPath()
    if self.db.font == "PSF Inter Regular" then return bundled["PSF Inter SemiBold"] end
    return self:GetFontPath()
end

function addon:GetUIFontPath(emphasized)
    return bundled[emphasized and "PSF Inter SemiBold" or "PSF Inter Regular"]
end

local observedMedia
function addon:ObserveSharedMedia()
    local media = SharedMedia()
    if media and media ~= observedMedia then
        observedMedia = media
        media.RegisterCallback(addon, "LibSharedMedia_Registered", function(_, mediaType)
            if mediaType == "font" then addon:QueueRefresh() end
        end)
        if media.Register then
            for name, path in pairs(bundled) do media:Register("font", name, path) end
        end
    end
end
