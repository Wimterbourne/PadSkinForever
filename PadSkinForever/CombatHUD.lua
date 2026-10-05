local _, addon = ...

local WHITE = "Interface\\Buttons\\WHITE8X8"
local swingStates = setmetatable({}, { __mode = "k" })
local swingHooks = setmetatable({}, { __mode = "k" })
local swingLabels = setmetatable({}, { __mode = "k" })
local swingCards = setmetatable({}, { __mode = "k" })
local resourceFrame
local editModeHooked
local nativeSelectionHooked
local powerColors = {
    MANA = addon.barColors.mana,
    RAGE = addon.barColors.rage,
    FOCUS = addon.barColors.focus,
    ENERGY = addon.barColors.energy,
    RUNIC_POWER = addon.barColors.runic,
    LUNAR_POWER = addon.barColors.lunar,
    INSANITY = addon.barColors.lunar,
    FURY = addon.barColors.lunar,
    PAIN = addon.barColors.focus,
}

local function SetValueText(text, current, maximum)
    -- Native FontString formatting accepts values directly; Lua arithmetic and
    -- string.format would discard or reject secret resource values.
    local ok = pcall(text.SetFormattedText, text, "%d / %d", current, maximum)
    if not ok then text:SetText("—") end
    text:Show()
end

local function PowerColor(unit)
    if not UnitPowerType then return .16, .48, 1 end
    local _, token, r, g, b = UnitPowerType(unit)
    local semantic = powerColors[token]
    if semantic then return semantic[1], semantic[2], semantic[3] end
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
    local pip = frame:GetStatusBarPip()
    if pip then pip:SetAlpha(0) end
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
    addon:CreateRoundedPanel(card, addon.design.card, addon.design.compactRadius)
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
                pipAlpha = frame:GetStatusBarPip() and frame:GetStatusBarPip():GetAlpha(),
                typeParent = frame:GetTypeLabel():GetParent(),
                timeParent = frame:GetTimeLabel():GetParent(),
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
        statusBar:SetStatusBarColor(unpack(addon.barColors.neutral))
        local texture = statusBar:GetStatusBarTexture()
        if texture then texture:SetTexCoord(0, 1, 0, 1) end
        addon:SetRoundedBar(statusBar, true, addon.barColors.neutral)
        local labels = swingLabels[frame]
        if not labels then
            labels = CreateFrame("Frame", nil, statusBar)
            labels:EnableMouse(false)
            labels:SetAllPoints(statusBar)
            labels:SetFrameLevel(statusBar:GetFrameLevel() + 2)
            swingLabels[frame] = labels
        end
        frame:GetTypeLabel():SetParent(labels)
        frame:GetTimeLabel():SetParent(labels)
        addon:ThemeFont(frame:GetTypeLabel(), true, true)
        addon:ThemeFont(frame:GetTimeLabel(), true, true)
        addon:ApplyPSFFont(frame:GetTypeLabel(), "label")
        addon:ApplyPSFFont(frame:GetTimeLabel(), "value")
        addon:DebugSurface(frame, "CombatHUD/SwingTimer", "native Edit Mode swing timer")
        addon:DebugSurface(statusBar, "CombatHUD/SwingTimerBar", "native swing timer status bar")
        HookSwingTimer(frame)
    elseif state then
        addon:SetRoundedBar(statusBar, false)
        local card = swingCards[frame]
        if card then card:Hide() end
        local pip = frame:GetStatusBarPip()
        if pip then pip:SetAlpha(state.pipAlpha or 1) end
        frame:GetTypeLabel():SetParent(state.typeParent)
        frame:GetTimeLabel():SetParent(state.timeParent)
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
    local well = CreateFrame("Frame", nil, parent)
    well:SetSize(width, height)
    addon:CreateRoundedPanel(well, addon.design.well, math.floor(height / 2))
    local bar = CreateFrame("StatusBar", nil, well)
    bar:SetPoint("TOPLEFT", 2, -2)
    bar:SetPoint("BOTTOMRIGHT", -2, 2)
    bar:SetStatusBarTexture(WHITE)
    -- A native texture mask follows protected fill geometry without reading it.
    -- This also works when combat resource dimensions are secret values.
    bar.fillMask = bar:CreateMaskTexture(nil, "ARTWORK")
    bar.fillMask:SetTexture("Interface\\AddOns\\PadSkinForever\\Media\\ResourceFillMask.tga", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    bar.fillMask:SetAllPoints(bar:GetStatusBarTexture())
    bar:GetStatusBarTexture():AddMaskTexture(bar.fillMask)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar.labels = CreateFrame("Frame", nil, bar)
    bar.labels:SetAllPoints(bar)
    bar.labels:SetFrameLevel(bar:GetFrameLevel() + 2)
    bar.labels:EnableMouse(false)
    bar.left = bar.labels:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.left:SetPoint("LEFT", well, "LEFT", 8, 0)
    bar.left:SetHeight(height - 4)
    bar.left:SetJustifyH("LEFT")
    bar.right = bar.labels:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.right:SetPoint("RIGHT", well, "RIGHT", -8, 0)
    bar.right:SetWidth(math.floor(width * .46))
    bar.right:SetHeight(height - 4)
    bar.right:SetJustifyH("RIGHT")
    bar.left:SetPoint("RIGHT", bar.right, "LEFT", -6, 0)
    bar.left:SetTextColor(unpack(addon.uiColors.text))
    bar.right:SetTextColor(unpack(addon.uiColors.text))
    return well, bar
end

local function ActiveLayoutKey()
    if C_EditMode and C_EditMode.GetLayouts then
        local layouts = C_EditMode.GetLayouts()
        if layouts and layouts.activeLayout then return tostring(layouts.activeLayout) end
    end
    return "default"
end

local function ResourceAnchor()
    local anchors = addon.db.resourceAnchors
    return type(anchors) == "table" and anchors[ActiveLayoutKey()] or addon.db.resourceAnchor
end

local function ApplyResourceAnchor(frame)
    local anchor = ResourceAnchor()
    frame:ClearAllPoints()
    frame:SetPoint(anchor[1], UIParent, anchor[2], anchor[3], anchor[4])
end

local function SaveResourceAnchor(frame)
    local point, relative, relativePoint, x, y = frame:GetPoint(1)
    if relative and relative ~= UIParent then return end
    local anchor = { point or "BOTTOM", relativePoint or "BOTTOM", x or 0, y or 228 }
    addon.db.resourceAnchor = anchor
    addon.db.resourceAnchors = addon.db.resourceAnchors or {}
    addon.db.resourceAnchors[ActiveLayoutKey()] = { unpack(anchor) }
end

local function SetSelectionState(selected)
    local selection = resourceFrame and resourceFrame.editSelection
    if not selection then return end
    selection.isSelected = selected and true or nil
    if selected and selection.ShowSelected then
        selection:ShowSelected(true)
    elseif selection.ShowHighlighted then
        selection:ShowHighlighted()
    end
end

local function SnapResourceToGrid(frame)
    local manager = EditModeManagerFrame
    if not manager or not manager.IsSnapEnabled or not manager:IsSnapEnabled() then return end
    local grid = manager.Grid
    if grid and grid.IsShown and not grid:IsShown() then return end
    local spacing = grid and tonumber(grid.gridSpacing)
    if not spacing or spacing <= 0 or not frame.GetCenter or not UIParent.GetCenter then return end
    local centerX, centerY = frame:GetCenter()
    local parentX, parentY = UIParent:GetCenter()
    if not centerX or not centerY or not parentX or not parentY then return end
    local x = math.floor((centerX - parentX) / spacing + .5) * spacing
    local y = math.floor((centerY - parentY) / spacing + .5) * spacing
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)
end

local function SetResourceEditMode(enabled)
    if not resourceFrame then return end
    resourceFrame.editMode = enabled and true or nil
    resourceFrame.editSelection:SetShown(resourceFrame.editMode)
    if resourceFrame.editMode then SetSelectionState(false) end
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
    if not nativeSelectionHooked and type(EditModeManagerFrame.SelectSystem) == "function" then
        nativeSelectionHooked = true
        hooksecurefunc(EditModeManagerFrame, "SelectSystem", function() SetSelectionState(false) end)
    end
end

local function EnsureResourceFrame()
    if resourceFrame or not UIParent or not UnitHealth then return resourceFrame end
    local frame = CreateFrame("Frame", "PadSkinForeverResourceDisplay", UIParent)
    -- Two equal 22 px rows, 6 px outer padding and exactly 2 px between
    -- player and pet. This keeps the resources visually one compact block.
    frame:SetSize(486, 58)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetFrameStrata("MEDIUM")
    frame:EnableMouse(false)
    addon:CreateRoundedPanel(frame, addon.design.card, addon.design.cardRadius)
    ApplyResourceAnchor(frame)

    frame.playerHealthWell, frame.playerHealth = CreateBar(frame, 222, 22)
    frame.playerHealthWell:SetPoint("TOPLEFT", 30, -6)
    frame.playerPowerWell, frame.playerPower = CreateBar(frame, 222, 22)
    frame.playerPowerWell:SetPoint("TOPRIGHT", -6, -6)
    frame.petHealthWell, frame.petHealth = CreateBar(frame, 222, 22)
    frame.petHealthWell:SetPoint("BOTTOMLEFT", 30, 6)
    frame.petPowerWell, frame.petPower = CreateBar(frame, 222, 22)
    frame.petPowerWell:SetPoint("BOTTOMRIGHT", -6, 6)
    frame.playerPortrait = frame:CreateTexture(nil, "ARTWORK")
    frame.playerPortrait:SetSize(20, 20)
    frame.playerPortrait:SetPoint("TOPLEFT", 6, -7)
    frame.playerPortrait:SetTexCoord(.08, .92, .08, .92)
    frame.petPortrait = frame:CreateTexture(nil, "ARTWORK")
    frame.petPortrait:SetSize(20, 20)
    frame.petPortrait:SetPoint("BOTTOMLEFT", 6, 7)
    frame.petPortrait:SetTexCoord(.08, .92, .08, .92)

    -- Use Blizzard's native selection artwork without registering a new system
    -- in its private Edit Mode layout tables. Registration would expose protected
    -- gamepad paths to addon taint; this selection owns only PSF's frame.
    local ok, selection = pcall(CreateFrame, "Frame", nil, frame, "EditModeSystemSelectionTemplate")
    frame.editSelection = ok and selection or CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.editSelection:SetAllPoints(frame)
    frame.editSelection:SetFrameStrata("MEDIUM")
    frame.editSelection:SetFrameLevel(1000)
    if frame.editSelection.SetToplevel then frame.editSelection:SetToplevel(true) end
    frame.editSelection:EnableMouse(true)
    frame.editSelection:RegisterForDrag("LeftButton")
    frame.editSelection.system = {
        GetSystemName = function() return "PSF Player & Pet Resources" end,
    }
    if not frame.editSelection.ShowHighlighted then
        frame.editSelection:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 2 })
        frame.editSelection:SetBackdropColor(addon.uiColors.accent[1], addon.uiColors.accent[2], addon.uiColors.accent[3], .12)
        frame.editSelection:SetBackdropBorderColor(unpack(addon.uiColors.accent))
    end
    frame.editSelection:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and frame.editMode and not InCombatLockdown() then
            SetSelectionState(true)
        end
    end)
    frame.editSelection:SetScript("OnDragStart", function()
        if frame.editMode and not InCombatLockdown() then
            SetSelectionState(true)
            frame:StartMoving()
        end
    end)
    frame.editSelection:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        SnapResourceToGrid(frame)
        SaveResourceAnchor(frame)
    end)
    frame.editSelection:Hide()
    resourceFrame = frame
    HookEditMode()
    if EditModeManagerFrame and EditModeManagerFrame:IsShown() then SetResourceEditMode(true) end
    return frame
end

local function SetBar(bar, unit, kind)
    local current, maximum
    if kind == "health" then
        current, maximum = UnitHealth(unit), UnitHealthMax(unit)
        bar:SetStatusBarColor(unpack(addon.barColors.health))
    else
        current, maximum = UnitPower(unit), UnitPowerMax(unit)
        bar:SetStatusBarColor(PowerColor(unit))
    end
    bar:SetMinMaxValues(0, maximum)
    bar:SetValue(current)
    return current, maximum
end

function addon:UpdateResourceVisibility()
    local frame = resourceFrame
    if not frame or not self.db then return end
    local active = frame.editMode or InCombatLockdown()
    local mode = self.db.resourceOutOfCombat or "dim"
    frame:SetShown(self.db.resourceDisplay and (active or mode ~= "hide"))
    frame:SetAlpha(1)
    local full = active or mode == "show"
    self:SetRoundedPanelVisualAlpha(frame, full and 1 or .34, full and 1 or .48)
    for _, well in ipairs({ frame.playerHealthWell, frame.playerPowerWell,
        frame.petHealthWell, frame.petPowerWell }) do
        self:SetRoundedPanelVisualAlpha(well, full and 1 or .42, full and 1 or .52)
    end
    for _, bar in ipairs({ frame.playerHealth, frame.playerPower, frame.petHealth, frame.petPower }) do
        local texture = bar:GetStatusBarTexture()
        if texture then texture:SetAlpha(full and 1 or .48) end
        bar.labels:SetAlpha(1)
    end
    frame.playerPortrait:SetAlpha(full and 1 or .58)
    frame.petPortrait:SetAlpha(full and 1 or .58)
end

function addon:UpdateResourceDisplay()
    local frame = resourceFrame
    if not frame or not self.db.resourceDisplay then return end
    local current, maximum = SetBar(frame.playerHealth, "player", "health")
    frame.playerHealth.left:SetText(HEALTH or "Health")
    SetValueText(frame.playerHealth.right, current, maximum)
    current, maximum = SetBar(frame.playerPower, "player", "power")
    frame.playerPower.left:SetText(PowerLabel("player"))
    SetValueText(frame.playerPower.right, current, maximum)

    local hasPet = UnitExists and UnitExists("pet")
    frame.petHealthWell:SetShown(hasPet or frame.editMode)
    frame.petPowerWell:SetShown(hasPet or frame.editMode)
    frame.petPortrait:SetShown(hasPet or frame.editMode)
    if hasPet then
        current, maximum = SetBar(frame.petHealth, "pet", "health")
        frame.petHealth.left:SetText(UnitName("pet") or (PET or "Pet"))
        SetValueText(frame.petHealth.right, current, maximum)
        current, maximum = SetBar(frame.petPower, "pet", "power")
        frame.petPower.left:SetText(PowerLabel("pet"))
        SetValueText(frame.petPower.right, current, maximum)
        if SetPortraitTexture then SetPortraitTexture(frame.petPortrait, "pet") end
    elseif frame.editMode then
        frame.petHealth:SetMinMaxValues(0, 1); frame.petHealth:SetValue(.72)
        frame.petPower:SetMinMaxValues(0, 1); frame.petPower:SetValue(.55)
        frame.petHealth.left:SetText(PET or "Pet"); frame.petHealth.right:SetText("")
        frame.petPower.left:SetText(POWER or "Power"); frame.petPower.right:SetText("")
        frame.petHealth:SetStatusBarColor(unpack(addon.barColors.health))
        frame.petPower:SetStatusBarColor(unpack(addon.barColors.focus))
        frame.petPortrait:SetTexture("Interface\\AddOns\\PadSkinForever\\Media\\PSFLogo.tga")
    end
    if SetPortraitTexture then SetPortraitTexture(frame.playerPortrait, "player") end
    frame:SetHeight((hasPet or frame.editMode) and 58 or 34)
    self:UpdateResourceVisibility()
    for _, bar in ipairs({ frame.playerHealth, frame.playerPower, frame.petHealth, frame.petPower }) do
        self:ApplyPSFFont(bar.left, "label")
        self:ApplyPSFFont(bar.right, "value")
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
    "UNIT_POWER_FREQUENT", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_PET", "PET_UI_UPDATE",
    "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
    events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, unit)
    if unit and unit ~= "player" and unit ~= "pet" then return end
    if addon.db then addon:UpdateResourceDisplay() end
end)
