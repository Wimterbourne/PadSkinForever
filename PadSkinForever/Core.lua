local addonName, addon = ...
PadSkinForever = addon -- Used only by our Bindings.xml command.
addon.name = addonName
addon.defaults = {
    skinButtons = true,
    themeMinimap = true,
    squareMinimap = true,
    themeUnits = true,
    themeQuests = true,
    themeChat = true,
    themeTooltip = true,
    themeLoot = true,
    themeSwingTimers = true,
    resourceDisplay = true,
    resourceOutOfCombat = "dim",
    resourceAnchor = { "BOTTOM", "BOTTOM", 0, 228 },
    resourceAnchors = {},
    lootToasts = true,
    themeFonts = true,
    buttonStyle = "minimal",
    glyphOutside = true,
    disabledGlyphIntensity = .7,
    vividGlyphs = true,
    colorGlyphs = true, -- Legacy setting, migrated to faceGlyphStyle.
    faceGlyphScale = 1,
    dpadGlyphScale = 1,
    dpadGlyphStyle = "native",
    skinLegend = true,
    legendFontSize = 14,
    legendGlyphScale = 1,
    legendRowGap = 10,
    legendPadding = 16,
    cooldownFont = true,
    font = "Blizzard default",
    fontSize = 18,
    fontFlags = "OUTLINE",
    accent = { 0.35, 0.75, 1 },
}

function addon:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff59bfffPadSkinForever:|r " .. message)
end

-- Native gamepad binding sets can take priority over a regular addon binding.
-- Deliberately do not install any override bindings or choose a key for the user.
BINDING_HEADER_PADSKINFOREVER = "PadSkinForever"
BINDING_NAME_PADSKINFOREVER_TOGGLE_LEGEND = "Toggle native input legend"

function addon:ToggleLegend()
    if InCombatLockdown() then
        self:Print("Toggle the legend after combat.")
        return false
    end
    local desired = not GetCVarBool("GamepadShowPersistentInputLegend")
    local ok, success = pcall(C_CVar.SetCVar, "GamepadShowPersistentInputLegend", desired and "1" or "0")
    if not ok or success == false or GetCVarBool("GamepadShowPersistentInputLegend") ~= desired then
        self:Print("The client did not allow changing GamepadShowPersistentInputLegend.")
        return false
    end
    return true
end

local pending, queued = false, false
function addon:QueueRefresh()
    pending = true
    if queued or not self.db or InCombatLockdown() then return end
    queued = true
    C_Timer.After(0, function()
        queued = false
        if InCombatLockdown() then return end
        if pending then
            pending = false
            addon:RefreshSkin()
        end
    end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("UPDATE_BINDINGS")
events:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
events:RegisterEvent("QUEST_LOG_UPDATE")
events:RegisterEvent("LOOT_OPENED")
events:RegisterEvent("LOOT_SLOT_CLEARED")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("CVAR_UPDATE")
events:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        if type(PadSkinForeverDB) ~= "table" then PadSkinForeverDB = {} end
        addon.db = PadSkinForeverDB
        if addon.db.faceGlyphStyle == nil then
            addon.db.faceGlyphStyle = addon.db.colorGlyphs == false and "native" or "xboxColor"
        end
        for key, value in pairs(addon.defaults) do
            if addon.db[key] == nil then
                if type(value) == "table" then
                    addon.db[key] = { unpack(value) }
                else
                    addon.db[key] = value
                end
            end
        end
        for _, key in ipairs({ "faceGlyphScale", "dpadGlyphScale", "legendGlyphScale" }) do
            addon.db[key] = math.max(.5, math.min(2, tonumber(addon.db[key]) or 1))
        end
        if addon.db.buttonStyle ~= "minimal" and addon.db.buttonStyle ~= "native" then addon.db.buttonStyle = "native" end
        addon.db.disabledGlyphIntensity = math.max(.2, math.min(1, tonumber(addon.db.disabledGlyphIntensity) or .7))
        for key, limits in pairs({ legendFontSize = {10, 28}, legendRowGap = {4, 24}, legendPadding = {8, 32} }) do
            addon.db[key] = math.max(limits[1], math.min(limits[2], tonumber(addon.db[key]) or addon.defaults[key]))
        end
        local faceStyle, dpadStyle = addon.db.faceGlyphStyle, addon.db.dpadGlyphStyle
        if faceStyle ~= "native" and faceStyle ~= "xbox" and faceStyle ~= "xboxColor" then addon.db.faceGlyphStyle = "native" end
        if dpadStyle ~= "native" and dpadStyle ~= "xbox" and dpadStyle ~= "xboxAccent" then addon.db.dpadGlyphStyle = "native" end
        if type(addon.db.font) ~= "string" then addon.db.font = addon.defaults.font end
        local size = tonumber(addon.db.fontSize) or addon.defaults.fontSize
        addon.db.fontSize = math.max(8, math.min(40, size))
        local flags = addon.db.fontFlags
        if flags ~= "" and flags ~= "OUTLINE" and flags ~= "THICKOUTLINE" and flags ~= "MONOCHROME,OUTLINE" then
            addon.db.fontFlags = addon.defaults.fontFlags
        end
        local color = addon.db.accent
        if type(color) ~= "table" or type(color[1]) ~= "number" or type(color[2]) ~= "number" or type(color[3]) ~= "number" then
            addon.db.accent = { unpack(addon.defaults.accent) }
        end
        local anchor = addon.db.resourceAnchor
        if type(anchor) ~= "table" or type(anchor[1]) ~= "string" or type(anchor[2]) ~= "string"
            or type(anchor[3]) ~= "number" or type(anchor[4]) ~= "number" then
            addon.db.resourceAnchor = { unpack(addon.defaults.resourceAnchor) }
        end
        if type(addon.db.resourceAnchors) ~= "table" then addon.db.resourceAnchors = {} end
    end
    -- Blizzard_GameMenu normally exists before regular addons, but retry on
    -- later events as well in case its load order changes in a beta build.
    if addon.db and addon.CreateGameMenuButton then addon:CreateGameMenuButton() end
    addon:QueueRefresh()
end)

SLASH_PADSKINFOREVER1 = "/psf"
SLASH_PADSKINFOREVER2 = "/padskin"
SlashCmdList.PADSKINFOREVER = function(message)
    if message:lower():match("^legend%s*$") then
        addon:ToggleLegend()
    else
        addon:ShowOptions()
    end
end
