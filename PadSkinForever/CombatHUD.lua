local _, addon = ...

local WHITE = "Interface\\Buttons\\WHITE8X8"
local swingStates = setmetatable({}, { __mode = "k" })
local swingHooks = setmetatable({}, { __mode = "k" })
local swingCards = setmetatable({}, { __mode = "k" })
local resourceFrame
local editModeHooked

local function SafeNumber(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return type(value) == "number" and value or nil
end

local function ValueText(current, maximum)
    current, maximum = SafeNumber(current), SafeNumber(maximum)
    if not current or not maximum then return "" end
    return string.format("%d / %d", current, maximum)
end

local function PowerColor(unit)
    if not UnitPowerType then return .16, .48, 1 end
    local _, token, r, g, b = UnitPowerType(unit)
    local color = PowerBarColor and (PowerBarColor[token] or PowerBarColor[select(1, UnitPowerType(unit))])
    if color then return color.r, color.g, color.b end
    if r then return r, g, b end
    return .16, .48, 1
end

local function PowerLabel(unit)
    if not UnitPowerType then return POWER or "Power" end
    local _, token = UnitPowerType(unit)
    return token and (_G[token] or token:gsub("_", " "):lower():gsub("^%l", string.upper)) or (POWER or "Power")
end

local function SaveFont(fontString)
    if not fontString or not fontString.GetFont then return nil end
    local path, size, flags = fontString:GetFont()
    local r, g, b, a = fontString:GetTextColor()
    return { path = path, size = size, flags = flags, color = { r, g, b, a } }
end

local function RestoreFont(fontString, saved)
    if not fontString or not saved then return end
    fontString:SetFont(saved.path, saved.size, saved.flags)
    fontString:SetTextColor(unpack(saved.color))
end

local function KeepNativeSwingChromeHidden(frame)
    if not addon.db or not addon.db.themeSwingTimers then return end
    if frame.Background then frame.Background:SetAlpha(0) end
    if frame.Border then frame.Border:SetAlpha(0) end
end

local function HookSwingTimer(frame)
    if swingHooks[frame] then return end
    swingHooks[frame] = true
    if type(frame.ApplyRangePresentation) == "function" then
        hooksecurefunc(frame, "ApplyRangePresentation", function(self)
            KeepNativeSwingChromeHidden(self)
        end)
    end
    if frame.HookScript then
        frame:HookScript("OnShow", function() addon:QueueRefresh() end)
    end
end

local function SwingCard(frame)
    local card = swingCards[frame]
    if card then return card end
    card = CreateFrame("Frame", nil, frame)
    card:EnableMouse(false)
    card:SetAllPoints(frame)
    card:SetFrameLevel(math.max(0, frame:GetFrameLevel()))
    addon:CreateRoundedPanel(card)
    swingCards[frame] = card
    return card
end

local function SkinSwingTimer(frame, enabled)
    if not frame or not frame.GetStatusBar then return end
    local statusBar = frame:GetStatusBar()
    if not statusBar then return end
    local state = swingStates[frame]
    if enabled then
        if not state then
            state = {
                backgroundAlpha = frame.Background and frame.Background:GetAlpha(),
                borderAlpha = frame.Border and frame.Border:GetAlpha(),
                shadowAlpha = frame.GetTypeLabelShadow and frame:GetTypeLabelShadow():GetAlpha(),
                typeFont = SaveFont(frame:GetTypeLabel()),
                timeFont = SaveFont(frame:GetTimeLabel()),
                barColor = { statusBar:GetStatusBarColor() },
            }
            swingStates[frame] = state
        end
        SwingCard(frame):Show()
        KeepNativeSwingChromeHidden(frame)
        local shadow = frame:GetTypeLabelShadow()
        if shadow then shadow:SetAlpha(0) end
        statusBar:SetStatusBarTexture(WHITE)
        statusBar:SetStatusBarColor(unpack(addon.uiColors.accent))
        local texture = statusBar:GetStatusBarTexture()
        if texture then texture:SetTexCoord(0, 1, 0, 1) end
        addon:Tint(frame:GetStatusBarPip(), { .92, .94, .96 })
        addon:ThemeFont(frame:GetTypeLabel(), true, true)
        addon:ThemeFont(frame:GetTimeLabel(), true, true)
        addon:DebugSurface(frame, "CombatHUD/SwingTimer", "native Edit Mode swing timer")
        addon:DebugSurface(statusBar, "CombatHUD/SwingTimerBar", "native swing timer status bar")
        HookSwingTimer(frame)
    elseif state then
        local card = swingCards[frame]
        if card then card:Hide() end
        addon:Tint(frame:GetStatusBarPip(), nil)
        addon:ThemeFont(frame:GetTypeLabel(), false)
        addon:ThemeFont(frame:GetTimeLabel(), false)
        RestoreFont(frame:GetTypeLabel(), state.typeFont)
        RestoreFont(frame:GetTimeLabel(), state.timeFont)
        if frame.InitializeBarPresentation then frame:InitializeBarPresentation() end
        if state.barColor then statusBar:SetStatusBarColor(unpack(state.barColor)) end
        if frame.Background then frame.Background:SetAlpha(state.backgroundAlpha or 1) end
        if frame.Border then frame.Border:SetAlpha(state.borderAlpha or 1) end
        local shadow = frame.GetTypeLabelShadow and frame:GetTypeLabelShadow()
        if shadow then shadow:SetAlpha(state.shadowAlpha or 1) end
        swingStates[frame] = nil
        if frame.ApplyRangePresentation then frame:ApplyRangePresentation() end
    end
end

local function CreateBar(parent, width, height)
    local well = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    well:SetSize(width, height)
    well:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    well:SetBackdropColor(.018, .022, .028, .95)
    well:SetBackdropBorderColor(unpack(addon.uiColors.borderSoft))
    local bar = CreateFrame("StatusBar", nil, well)
    bar:SetPoint("TOPLEFT", 2, -2)
    bar:SetPoint("BOTTOMRIGHT", -2, 2)
    bar:SetStatusBarTexture(WHITE)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar.left = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.left:SetPoint("LEFT", 5, 0)
    bar.left:SetJustifyH("LEFT")
    bar.right = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.right:SetPoint("RIGHT", -5, 0)
    bar.right:SetJustifyH("RIGHT")
    return well, bar
end

local function ApplyResourceAnchor(frame)
    local anchor = addon.db.resourceAnchor
    frame:ClearAllPoints()
    frame:SetPoint(anchor[1], UIParent, anchor[2], anchor[3], anchor[4])
end

local function SaveResourceAnchor(frame)
    local point, relative, relativePoint, x, y = frame:GetPoint(1)
    if relative and relative ~= UIParent then return end
    addon.db.resourceAnchor = { point or "BOTTOM", relativePoint or "BOTTOM", x or 0, y or 228 }
end

local function SetResourceEditMode(enabled)
    if not resourceFrame then return end
    resourceFrame.editMode = enabled and true or nil
    resourceFrame:EnableMouse(resourceFrame.editMode)
    if resourceFrame.editMode then resourceFrame:RegisterForDrag("LeftButton")
    else resourceFrame:RegisterForDrag() end
    resourceFrame.editLabel:SetShown(resourceFrame.editMode)
    resourceFrame.editShade:SetShown(resourceFrame.editMode)
    if addon.db and addon.db.resourceDisplay then resourceFrame:Show() end
    if addon.db then addon:UpdateResourceDisplay() end
end

local function HookEditMode()
    if editModeHooked or not EditModeManagerFrame then return end
    editModeHooked = true
    EditModeManagerFrame:HookScript("OnShow", function() SetResourceEditMode(true) end)
    EditModeManagerFrame:HookScript("OnHide", function()
        SetResourceEditMode(false)
        addon:QueueRefresh()
    end)
end

local function EnsureResourceFrame()
    if resourceFrame or not UIParent or not UnitHealth then return resourceFrame end
    local frame = CreateFrame("Frame", "PadSkinForeverResourceDisplay", UIParent)
    frame:SetSize(460, 58)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetFrameStrata("MEDIUM")
    addon:CreateRoundedPanel(frame)
    ApplyResourceAnchor(frame)

    frame.playerHealthWell, frame.playerHealth = CreateBar(frame, 222, 18)
    frame.playerHealthWell:SetPoint("TOPLEFT", 6, -6)
    frame.playerPowerWell, frame.playerPower = CreateBar(frame, 222, 18)
    frame.playerPowerWell:SetPoint("TOPRIGHT", -6, -6)
    frame.petHealthWell, frame.petHealth = CreateBar(frame, 262, 18)
    frame.petHealthWell:SetPoint("BOTTOMLEFT", 30, 6)
    frame.petPowerWell, frame.petPower = CreateBar(frame, 156, 18)
    frame.petPowerWell:SetPoint("BOTTOMRIGHT", -6, 6)
    frame.petPortrait = frame:CreateTexture(nil, "ARTWORK")
    frame.petPortrait:SetSize(20, 20)
    frame.petPortrait:SetPoint("BOTTOMLEFT", 6, 5)
    frame.petPortrait:SetTexCoord(.08, .92, .08, .92)

    frame.editShade = frame:CreateTexture(nil, "OVERLAY")
    frame.editShade:SetAllPoints()
    frame.editShade:SetTexture(WHITE)
    frame.editShade:SetVertexColor(addon.uiColors.accent[1], addon.uiColors.accent[2], addon.uiColors.accent[3], .12)
    frame.editLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.editLabel:SetPoint("BOTTOM", frame, "TOP", 0, 4)
    frame.editLabel:SetText("PSF PLAYER & PET RESOURCES — DRAG TO MOVE")
    frame.editLabel:SetTextColor(unpack(addon.uiColors.accent))
    frame.editLabel:Hide(); frame.editShade:Hide()

    frame:SetScript("OnDragStart", function(self)
        if self.editMode then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveResourceAnchor(self)
    end)
    resourceFrame = frame
    HookEditMode()
    if EditModeManagerFrame and EditModeManagerFrame:IsShown() then SetResourceEditMode(true) end
    return frame
end

local function SetBar(bar, unit, kind)
    local current, maximum
    if kind == "health" then
        current, maximum = UnitHealth(unit), UnitHealthMax(unit)
        bar:SetStatusBarColor(.18, .82, .31)
    else
        current, maximum = UnitPower(unit), UnitPowerMax(unit)
        bar:SetStatusBarColor(PowerColor(unit))
    end
    bar:SetMinMaxValues(0, maximum)
    bar:SetValue(current)
    return current, maximum
end

function addon:UpdateResourceDisplay()
    local frame = resourceFrame
    if not frame or not self.db.resourceDisplay then return end
    local current, maximum = SetBar(frame.playerHealth, "player", "health")
    frame.playerHealth.left:SetText(HEALTH or "Health")
    frame.playerHealth.right:SetText(ValueText(current, maximum))
    current, maximum = SetBar(frame.playerPower, "player", "power")
    frame.playerPower.left:SetText(PowerLabel("player"))
    frame.playerPower.right:SetText(ValueText(current, maximum))

    local hasPet = UnitExists and UnitExists("pet")
    frame.petHealthWell:SetShown(hasPet or frame.editMode)
    frame.petPowerWell:SetShown(hasPet or frame.editMode)
    frame.petPortrait:SetShown(hasPet or frame.editMode)
    if hasPet then
        current, maximum = SetBar(frame.petHealth, "pet", "health")
        frame.petHealth.left:SetText(UnitName("pet") or (PET or "Pet"))
        frame.petHealth.right:SetText(ValueText(current, maximum))
        current, maximum = SetBar(frame.petPower, "pet", "power")
        frame.petPower.left:SetText(PowerLabel("pet"))
        frame.petPower.right:SetText(ValueText(current, maximum))
        if SetPortraitTexture then SetPortraitTexture(frame.petPortrait, "pet") end
    elseif frame.editMode then
        frame.petHealth:SetMinMaxValues(0, 1); frame.petHealth:SetValue(.72)
        frame.petPower:SetMinMaxValues(0, 1); frame.petPower:SetValue(.55)
        frame.petHealth.left:SetText(PET or "Pet"); frame.petHealth.right:SetText("")
        frame.petPower.left:SetText(POWER or "Power"); frame.petPower.right:SetText("")
        frame.petPortrait:SetTexture("Interface\\AddOns\\PadSkinForever\\Media\\PSFLogo.tga")
    end
    frame:SetHeight((hasPet or frame.editMode) and 58 or 30)
    local font = self:GetUIFontPath(false)
    for _, bar in ipairs({ frame.playerHealth, frame.playerPower, frame.petHealth, frame.petPower }) do
        if not bar.left:SetFont(font, 10, "") then bar.left:SetFont(STANDARD_TEXT_FONT, 10, "") end
        if not bar.right:SetFont(font, 10, "") then bar.right:SetFont(STANDARD_TEXT_FONT, 10, "") end
    end
end

function addon:RefreshCombatHUD()
    local enabled = self.db.themeSwingTimers
    for _, frame in ipairs({ SwingTimerMainHandFrame, SwingTimerOffHandFrame, SwingTimerRangedFrame }) do
        SkinSwingTimer(frame, enabled)
    end
    local frame = EnsureResourceFrame()
    if frame then
        ApplyResourceAnchor(frame)
        frame:SetShown(self.db.resourceDisplay and true or false)
        self:UpdateResourceDisplay()
        self:DebugSurface(frame, "CombatHUD/Resources", "PSF player and pet resource display")
    end
    HookEditMode()
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "UNIT_HEALTH", "UNIT_MAXHEALTH",
    "UNIT_POWER_FREQUENT", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_PET", "PET_UI_UPDATE" }) do
    events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, unit)
    if unit and unit ~= "player" and unit ~= "pet" then return end
    if addon.db then addon:UpdateResourceDisplay() end
end)
