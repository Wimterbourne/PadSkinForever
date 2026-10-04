local _, addon = ...

-- Presentation-only children of native unit buttons. No replacement buttons,
-- bindings, root anchors or Edit Mode registrations are installed.
local views = setmetatable({}, { __mode = "k" })
local iconBorders = setmetatable({}, { __mode = "k" })
local WHITE = "Interface\\Buttons\\WHITE8X8"
local MASK = "Interface\\AddOns\\PadSkinForever\\Media\\ResourceFillMask.tga"

local function HealthBar(parent, width, height)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:EnableMouse(false)
    bar:SetSize(width, height)
    bar:SetStatusBarTexture(WHITE)
    local mask = bar:CreateMaskTexture(nil, "ARTWORK")
    mask:SetTexture(MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(bar:GetStatusBarTexture())
    bar:GetStatusBarTexture():AddMaskTexture(mask)
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
    local size = small and 60 or 92
    local width = compact and size + 12 or (targetOfTarget and 170 or 460)
    local height = compact and size + 40 or (targetOfTarget and 28 or 40)
    view:SetSize(width, height)
    if compact then
        view:SetPoint("TOPLEFT", root, "TOPLEFT", 0, 0)
        addon:CreateRoundedPanel(view, { fill = { .025, .03, .038, .95 }, border = { .55, .60, .66, .28 } }, 8)
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
    view.portrait = view:CreateTexture(nil, "ARTWORK")
    view.portrait:SetTexCoord(.08, .92, .08, .92)
    view.model = CreateFrame("PlayerModel", nil, view)
    view.model:EnableMouse(false)
    local portraitSize = compact and size or (targetOfTarget and 24 or 40)
    view.portrait:SetSize(portraitSize, portraitSize)
    view.portrait:SetPoint(compact and "TOPLEFT" or "RIGHT", view, compact and "TOPLEFT" or "RIGHT", compact and 6 or -1, compact and -6 or 0)
    view.model:SetAllPoints(view.portrait)
    if not compact then
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
    end
    local barWidth = compact and size or width - portraitSize - (targetOfTarget and 8 or 12)
    if compact then
        view.health = HealthBar(view, barWidth, 12)
        view.health:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", 6, 6)
    else
        view.barWell = CreateFrame("Frame", nil, view)
        view.barWell:EnableMouse(false)
        view.barWell:SetSize(barWidth, targetOfTarget and 12 or 14)
        view.barWell:SetPoint("BOTTOMLEFT", view, "BOTTOMLEFT", 0, targetOfTarget and 3 or 4)
        addon:CreateRoundedPanel(view.barWell, {
            fill = { .018, .022, .028, .92 }, border = { .55, .60, .66, .24 },
        }, targetOfTarget and 6 or 7)
        view.health = HealthBar(view.barWell, barWidth - 4, targetOfTarget and 8 or 10)
        view.health:SetPoint("CENTER")
    end
    view.nameText = view:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    view.nameText:SetPoint(compact and "BOTTOMLEFT" or "TOPLEFT", view, compact and "BOTTOMLEFT" or "TOPLEFT", compact and 6 or 0, compact and 22 or -1)
    view.nameText:SetWidth(compact and size or barWidth)
    view.nameText:SetJustifyH(compact and "LEFT" or "CENTER")
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
    if view.portraitRing then view.portraitRing:SetVertexColor(unpack(color)) end
    local ok = pcall(view.health.valueText.SetFormattedText, view.health.valueText, "%d / %d", current, maximum)
    if not ok then view.health.valueText:SetText("—") end
    local model = addon.db.unitPortraitMode == "3d"
    view.model:SetShown(model)
    view.portrait:SetShown(not model)
    -- Models update only on unit/model changes, not on every health event.
    if model then
        if view.modelDirty then view.model:SetUnit(unit); view.model:SetPortraitZoom(1); view.modelDirty = nil end
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
                    local font = self:GetUIFontPath(false)
                    view.nameText:SetFont(font, 11, "")
                    view.health.valueText:SetFont(font, 9, "")
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
    "UNIT_NAME_UPDATE", "PLAYER_REGEN_ENABLED", "UNIT_AURA", "ADDON_LOADED" }) do events:RegisterEvent(event) end
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
