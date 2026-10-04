local _, addon = ...

local WHITE = "Interface\\Buttons\\WHITE8X8"
local swingStates = setmetatable({}, { __mode = "k" })
local swingHooks = setmetatable({}, { __mode = "k" })
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
    addon:CreateRoundedPanel(card, {
        fill = { .025, .03, .038, .90 },
        border = { .67, .72, .78, .30 },
    }, 9)
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
        statusBar:SetStatusBarColor(unpack(addon.barColors.neutral))
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
    local well = CreateFrame("Frame", nil, parent)
    well:SetSize(width, height)
    addon:CreateRoundedPanel(well, {
        fill = { .018, .022, .028, .78 },
        border = { .55, .60, .66, .24 },
    }, math.floor(height / 2))
    local bar = CreateFrame("StatusBar", nil, well)
    bar:SetPoint("TOPLEFT", 3, -3)
    bar:SetPoint("BOTTOMRIGHT", -3, 3)
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
    frame:SetSize(460, 58)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetFrameStrata("MEDIUM")
    frame:EnableMouse(false)
    addon:CreateRoundedPanel(frame, {
        fill = { .025, .03, .038, .90 },
        border = { .55, .60, .66, .28 },
    }, 12)
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
