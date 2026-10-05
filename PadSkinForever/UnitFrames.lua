local _, addon = ...

-- Presentation-only children of native unit buttons. No replacement buttons,
-- bindings, root anchors or Edit Mode registrations are installed.
local views = setmetatable({}, { __mode = "k" })
local iconBorders = setmetatable({}, { __mode = "k" })
local WHITE = "Interface\\Buttons\\WHITE8X8"
local CIRCLE_FILL = "Interface\\AddOns\\PadSkinForever\\Media\\CircleEmpty.tga"

local powerColors = {
    MANA = addon.barColors.mana, RAGE = addon.barColors.rage,
    FOCUS = addon.barColors.focus, ENERGY = addon.barColors.energy,
    RUNIC_POWER = addon.barColors.runic, LUNAR_POWER = addon.barColors.lunar,
}

local function UnitPowerColor(unit)
    if UnitPowerType then
        local index, token, r, g, b = UnitPowerType(unit)
        local semantic = powerColors[token]
        if semantic then return semantic end
        local native = PowerBarColor and (PowerBarColor[token] or PowerBarColor[index])
        if native then return { native.r, native.g, native.b, 1 } end
        if r then return { r, g, b, 1 } end
    end
    return addon.barColors.mana
end

local function ValueBar(parent, width, height, color)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:EnableMouse(false)
    bar:SetSize(width, height)
    bar:SetStatusBarTexture(WHITE)
    -- The shared renderer builds the fill from fixed-size corner pieces and a
    -- stretchable centre. Wide target bars therefore keep the same end radius
    -- as compact resource and swing-timer bars.
    addon:SetRoundedBar(bar, true, color or addon.barColors.health)
    local textLayer = CreateFrame("Frame", nil, bar)
    textLayer:EnableMouse(false)
    textLayer:SetAllPoints(bar)
    textLayer:SetFrameLevel(bar:GetFrameLevel() + 1)
    bar.valueText = textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.valueText:SetAllPoints(bar)
    bar.valueText:SetJustifyH("CENTER")
    return bar
end

local function MakeView(root, unit, compact)
    local view = views[root]
    if view then return view end
    view = CreateFrame("Frame", nil, root)
    view:EnableMouse(false)
    view:SetFrameLevel(root:GetFrameLevel() + 5)
    local small = unit == "pet"
    local targetOfTarget = unit == "targettarget"
    local portraitSize = compact and (small and 50 or 68) or (targetOfTarget and 30 or 46)
    local width = compact and (small and 200 or 238) or (targetOfTarget and 190 or 460)
    local height = compact and (small and 58 or 76) or (targetOfTarget and 34 or 50)
    view:SetSize(width, height)
    if compact then
        view:SetPoint("TOPLEFT", root, "TOPLEFT", 0, 0)
    elseif targetOfTarget then
        -- The native ToT root sits inside the target layout. Put our compact
        -- secondary tag just below it so a wide target bar never overlaps it.
        view:SetPoint("TOPLEFT", root, "BOTTOMLEFT", 0, -2)
    else
        -- Grow around the native target/focus center. Their native roots and
        -- Edit Mode anchors remain untouched and stay the interaction owners.
        view:SetPoint("TOP", root, "TOP", 0, 0)
    end
    view.unit, view.root, view.compact = unit, root, compact
    view.chrome = {}

    -- The dark card begins halfway under the portrait.  That overlap and the
    -- uninterrupted negative space are the defining shapes of the concept.
    view.card = CreateFrame("Frame", nil, view)
    view.card:EnableMouse(false)
    view.card:SetFrameLevel(math.max(0, view:GetFrameLevel() - 1))
    view.card:SetPoint("TOPLEFT", view, "TOPLEFT", math.floor(portraitSize * .45), 0)
    view.card:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 0)
    addon:CreateRoundedPanel(view.card, addon.design.cardStrong,
        targetOfTarget and addon.design.compactRadius or addon.design.cardRadius)

    view.portraitBackground = view:CreateTexture(nil, "BACKGROUND")
    view.portraitBackground:SetTexture(CIRCLE_FILL)
    view.portraitBackground:SetVertexColor(1, 1, 1, .98)
    view.portrait = view:CreateTexture(nil, "ARTWORK")
    view.portrait:SetTexCoord(.08, .92, .08, .92)
    view.model = CreateFrame("PlayerModel", nil, view)
    view.model:EnableMouse(false)
    view.portrait:SetSize(portraitSize, portraitSize)
    view.portrait:SetPoint("LEFT", view, "LEFT", 0, 0)
    local inset = 1
    view.model:SetPoint("TOPLEFT", view.portrait, "TOPLEFT", inset, -inset)
    view.model:SetPoint("BOTTOMRIGHT", view.portrait, "BOTTOMRIGHT", -inset, inset)
    view.portraitBackground:SetAllPoints(view.portrait)
    view.portraitMask = view:CreateMaskTexture(nil, "ARTWORK")
    view.portraitMask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    view.portraitMask:SetAllPoints(view.portrait)
    view.portrait:AddMaskTexture(view.portraitMask)
    view.portraitRingFrame = CreateFrame("Frame", nil, view)
    view.portraitRingFrame:EnableMouse(false)
    view.portraitRingFrame:SetFrameLevel(view:GetFrameLevel() + 3)
    view.portraitRingFrame:SetAllPoints(view.portrait)
    view.portraitRing = view.portraitRingFrame:CreateTexture(nil, "OVERLAY")
    view.portraitRing:SetTexture("Interface\\AddOns\\PadSkinForever\\Media\\CircleBorder.tga")
    view.portraitRing:SetPoint("CENTER")
    view.portraitRing:SetSize(portraitSize + 4, portraitSize + 4)

    local contentLeft = portraitSize + (compact and 8 or 12)
    local contentRight = 10
    local barWidth = width - contentLeft - contentRight
    local function Well(height, y, color)
        local well = CreateFrame("Frame", nil, view)
        well:EnableMouse(false)
        well:SetSize(barWidth, height)
        well:SetPoint("TOPLEFT", view, "TOPLEFT", contentLeft, y)
        addon:CreateRoundedPanel(well, addon.design.well, math.floor(height / 2))
        local bar = ValueBar(well, barWidth - 4, height - 4, color)
        bar:SetPoint("CENTER")
        return well, bar
    end
    if compact then
        local healthHeight = small and 14 or 16
        local powerHeight = small and 12 or 13
        view.healthWell, view.health = Well(healthHeight, small and -25 or -32, addon.barColors.health)
        view.powerWell, view.power = Well(powerHeight, small and -41 or -51, addon.barColors.mana)
    else
        view.barWell, view.health = Well(targetOfTarget and 12 or 15,
            targetOfTarget and -17 or -29, addon.barColors.health)
    end
    view.nameText = view:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    view.nameText:SetPoint("TOPLEFT", view, "TOPLEFT", contentLeft + 2, compact and -8 or -7)
    view.nameText:SetWidth(barWidth - 4)
    view.nameText:SetJustifyH("LEFT")
    views[root] = view
    return view
end

local function HideNative(view, enabled)
    local root = view.root
    local objects = {}
    for _, region in ipairs({ root:GetRegions() }) do table.insert(objects, region) end
    for _, object in pairs({ root.PlayerFrameContainer, root.PlayerFrameContent,
        root.TargetFrameContainer, root.TargetFrameContent, root.Portrait,
        root.HealthBar, root.ManaBar, root.healthbar, root.manabar, root.Name }) do
        table.insert(objects, object)
    end
    if view.unit == "pet" then
        for _, object in pairs({ PetFrameHealthBar, PetFrameManaBar, PetName, PetPortrait, PetFrameTexture }) do table.insert(objects, object) end
    end
    if enabled then
        for _, object in ipairs(objects) do
            view.chrome[object] = true
            addon:ThemeAlpha(object, true)
        end
    else
        for object in pairs(view.chrome) do addon:ThemeAlpha(object, false) end
        wipe(view.chrome)
    end
end

local function UpdateView(view)
    if not view.active then return end
    local unit = view.unit
    local exists = UnitExists and UnitExists(unit)
    if issecretvalue and issecretvalue(exists) then return end
    view:SetShown(exists and true or false)
    if not exists then return end
    view.nameText:SetText(UnitName(unit))
    local current, maximum = UnitHealth(unit), UnitHealthMax(unit)
    view.health:SetMinMaxValues(0, maximum)
    view.health:SetValue(current)
    local color = addon.barColors.health
    if unit == "target" or unit == "focus" then
        color = addon.barColors.enemy
        if UnitReaction then
            local reaction = UnitReaction(unit, "player")
            if not (issecretvalue and issecretvalue(reaction)) and type(reaction) == "number" and reaction >= 5 then color = addon.barColors.health end
        end
    end
    view.health:SetStatusBarColor(unpack(color))
    addon:SetRoundedBar(view.health, true, color)
    if view.portraitRing then view.portraitRing:SetVertexColor(unpack(color)) end
    local ok = pcall(view.health.valueText.SetFormattedText, view.health.valueText, "%d / %d", current, maximum)
    if not ok then view.health.valueText:SetText("—") end
    if view.power and UnitPower and UnitPowerMax then
        local power, maximumPower = UnitPower(unit), UnitPowerMax(unit)
        local powerColor = UnitPowerColor(unit)
        view.power:SetMinMaxValues(0, maximumPower)
        view.power:SetValue(power)
        view.power:SetStatusBarColor(unpack(powerColor))
        addon:SetRoundedBar(view.power, true, powerColor)
        local powerOK = pcall(view.power.valueText.SetFormattedText, view.power.valueText, "%d / %d", power, maximumPower)
        if not powerOK then view.power.valueText:SetText("—") end
    end
    local model = addon.db.unitPortraitMode == "3d"
    view.model:SetShown(model)
    view.portrait:SetShown(not model)
    -- Models update only on unit/model changes, not on every health event.
    if model then
        if view.modelDirty then
            view.model:SetUnit(unit)
            view.model:SetPortraitZoom(1)
            if view.model.SetCamDistanceScale then view.model:SetCamDistanceScale(view.compact and .82 or .72) end
            -- PlayerModel reapplies unit-specific fog when SetUnit runs. That
            -- fog becomes an opaque disc behind boss-style target portraits.
            if view.model.ClearFog then view.model:ClearFog() end
            view.modelDirty = nil
        end
    elseif SetPortraitTexture then SetPortraitTexture(view.portrait, unit) end
end

function addon:RefreshUnitFrames()
    if not self.db or InCombatLockdown() then return end
    local enabled = self.db.themeUnits and self.db.compactUnits
    for _, entry in ipairs({ { PlayerFrame, "player", true }, { PetFrame, "pet", true },
        { TargetFrame, "target", false }, { FocusFrame, "focus", false },
        { TargetFrameToT, "targettarget", false } }) do
        local root, unit, compact = unpack(entry)
        if root then
            local view = views[root]
            if enabled then view = MakeView(root, unit, compact) end
            if view then
                view.active = enabled
                HideNative(view, enabled)
                view:SetShown(enabled)
                if enabled then
                    view.modelDirty = true
                    self:ApplyPSFFont(view.nameText, view.compact and "name" or "label")
                    self:ApplyPSFFont(view.health.valueText, "value")
                    if view.power then self:ApplyPSFFont(view.power.valueText, "value") end
                    UpdateView(view)
                    self:DebugSurface(view, "Units/" .. unit, "PSF visual layer on native unit button")
                end
            end
        end
    end
end

-- Aura and cooldown icons retain native cooldowns, hover, ordering and layout.
local function SkinIcons(frame, enabled, depth)
    if not frame or not frame.GetChildren or depth > 5 then return end
    local icon = frame.Icon or frame.icon
    if icon and icon.SetTexCoord and icon.GetTexCoord then
        local data = iconBorders[icon]
        if enabled and not data then
            local border = frame:CreateTexture(nil, "OVERLAY")
            border:SetTexture("Interface\\AddOns\\PadSkinForever\\Media\\SquareBorder.tga")
            border:SetAllPoints(icon)
            border:SetVertexColor(.55, .60, .66, .65)
            data = { border = border, coords = { icon:GetTexCoord() } }
            iconBorders[icon] = data
        end
        if data then
            data.border:SetShown(enabled)
            if enabled then icon:SetTexCoord(.08, .92, .08, .92) else icon:SetTexCoord(unpack(data.coords)) end
        end
        addon:ThemeAlpha(frame.IconBorder, enabled)
        addon:ThemeFont(frame.Duration or frame.duration, enabled, true)
        addon:ThemeFont(frame.Count or frame.count, enabled, true)
    end
    for _, child in ipairs({ frame:GetChildren() }) do SkinIcons(child, enabled, depth + 1) end
end

function addon:RefreshUnitIcons()
    if not self.db or InCombatLockdown() then return end
    SkinIcons(BuffFrame, self.db.themeUnitAuras, 0)
    SkinIcons(DebuffFrame, self.db.themeUnitAuras, 0)
    -- Forever builds can omit a viewer; existing viewers alone are skinned.
    for _, viewer in pairs({ EssentialCooldownViewer = EssentialCooldownViewer,
        UtilityCooldownViewer = UtilityCooldownViewer, BuffIconCooldownViewer = BuffIconCooldownViewer }) do
        SkinIcons(viewer, self.db.themeCooldownManager, 0)
        self:DebugSurface(viewer, "CooldownManager", "native cooldown viewer icon skin")
    end
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED",
    "UNIT_TARGET", "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_PET", "UNIT_PORTRAIT_UPDATE", "UNIT_MODEL_CHANGED",
    "UNIT_NAME_UPDATE", "UNIT_POWER_FREQUENT", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
    "PLAYER_REGEN_ENABLED", "UNIT_AURA", "ADDON_LOADED" }) do events:RegisterEvent(event) end
events:SetScript("OnEvent", function(_, event)
    if not addon.db then return end
    for _, view in pairs(views) do
        if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" or event == "UNIT_TARGET"
            or event == "UNIT_PET" or event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_MODEL_CHANGED"
            or event == "PLAYER_ENTERING_WORLD" then view.modelDirty = true end
        UpdateView(view)
    end
    if event == "PLAYER_REGEN_ENABLED" or event == "UNIT_AURA" or event == "ADDON_LOADED" then addon:QueueRefresh() end
end)
