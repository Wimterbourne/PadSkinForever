local _, addon = ...
-- Only visual surfaces are owned here. Native frames, bindings and clicks remain native.
local alphaSaved = setmetatable({}, { __mode = "k" })
local fontSaved = setmetatable({}, { __mode = "k" })
local fontHooked = setmetatable({}, { __mode = "k" })
local barSaved = setmetatable({}, { __mode = "k" })
local cards = setmetatable({}, { __mode = "k" })
local rings = setmetatable({}, { __mode = "k" })
local watched = setmetatable({}, { __mode = "k" })
local minimapMask, minimapChanged
local minimapSockets = setmetatable({}, { __mode = "k" })
local minimapDock, minimapDockPanel, minimapDockLauncher
local minimapDocked = setmetatable({}, { __mode = "k" })
local minimapDockOpen = false
local white = "Interface\\Buttons\\WHITE8X8"
local grey = { .34, .37, .41 }

local function HasSecretColor(color)
    if not color or not issecretvalue then return false end
    for index = 1, 4 do
        if issecretvalue(color[index]) then return true end
    end
    return false
end

local function Hook(frame, method)
    if not frame or type(frame[method]) ~= "function" then return end
    watched[frame] = watched[frame] or {}
    if watched[frame][method] then return end
    watched[frame][method] = true
    hooksecurefunc(frame, method, function()
        if not addon.applyingSkin then addon:QueueRefresh() end
    end)
end

function addon:ThemeAlpha(object, enabled)
    if not object or not object.GetAlpha or not object.SetAlpha then return end
    self:DebugSurface(object, "Theme/chrome", "theme decoration")
    if enabled then
        if alphaSaved[object] == nil then alphaSaved[object] = object:GetAlpha() end
        object:SetAlpha(0)
    elseif alphaSaved[object] ~= nil then
        object:SetAlpha(alphaSaved[object]); alphaSaved[object] = nil
    end
end

function addon:ThemeFont(text, enabled, forceWhite)
    if not text or not text.GetFont then return end
    local saved = fontSaved[text]
    if enabled then
        if not saved then
            local path, size, flags = text:GetFont()
            if not path then return end
            saved = { path = path, size = size, flags = flags }
            if text.GetTextColor then saved.color = { text:GetTextColor() } end
            fontSaved[text] = saved
            if text.SetTextColor and not fontHooked[text] then
                fontHooked[text] = true
                hooksecurefunc(text, "SetTextColor", function()
                    local entry = fontSaved[text]
                    if entry and not addon.applyingSkin then
                        entry.color = { text:GetTextColor() }
                        addon:QueueRefresh()
                    end
                end)
            end
        end
        local path = self.db.themeFonts and (forceWhite and self:GetLegendHeaderFontPath() or self:GetFontPath()) or saved.path
        local size = saved.size
        if not (issecretvalue and issecretvalue(size)) and type(size) == "number" then
            size = math.max(size, forceWhite and 13 or 12)
        end
        if not text:SetFont(path, size, saved.flags) then text:SetFont(STANDARD_TEXT_FONT, size, saved.flags) end
        if text.SetShadowColor then text:SetShadowColor(0, 0, 0, .85) end
        if text.SetShadowOffset then text:SetShadowOffset(1, -1) end
        local color = saved.color
        -- Turn parchment-dark text white; retain item quality and semantic colors.
        -- Blizzard can return restricted colour channels for quest/nameplate
        -- text.  Never compare or replace them from addon code; the original
        -- font colour remains native and can still be restored unchanged.
        if color and not HasSecretColor(color)
            and (forceWhite or (color[1] < .5 and color[2] < .5 and color[3] < .5)) then
            text:SetTextColor(.94, .95, .97, color[4] or 1)
        end
        self:DebugSurface(text, "Theme/font", "theme font")
    elseif saved then
        text:SetFont(saved.path, saved.size, saved.flags)
        if saved.color then text:SetTextColor(unpack(saved.color)) end
        fontSaved[text] = nil
    end
end

local function Fonts(frame, enabled, depth)
    if not frame or not frame.GetRegions or depth > 6 then return end
    for _, region in ipairs({ frame:GetRegions() }) do
        if region:IsObjectType("FontString") then addon:ThemeFont(region, enabled) end
    end
    for _, child in ipairs({ frame:GetChildren() }) do
        -- Exclude our own chrome and unrelated nested UI from repeated walks.
        if not cards[frame] or child ~= cards[frame] then Fonts(child, enabled, depth + 1) end
    end
end

function addon:ThemeCard(frame, enabled, label, padding, palette)
    if not frame then return end
    local card = cards[frame]
    if enabled and not card then
        card = CreateFrame("Frame", nil, frame)
        card:EnableMouse(false)
        card:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))
        card:SetPoint("TOPLEFT", frame, "TOPLEFT", -(padding or 4), padding or 4)
        card:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", padding or 4, -(padding or 4))
        addon:CreateRoundedPanel(card, palette or addon.design.card, addon.design.cardRadius)
        cards[frame] = card
        self:DebugSurface(card, label .. "/card", "theme panel")
    end
    if card then card:SetShown(enabled) end
    if frame.HookScript and not watched[frame] then
        watched[frame] = {}
        frame:HookScript("OnShow", function() addon:QueueRefresh() end)
    end
end

local function Chrome(frame, enabled)
    if not frame then return end
    for _, key in ipairs({ "NineSlice", "Bg", "Background", "BG", "TitleBg" }) do
        addon:ThemeAlpha(frame[key], enabled)
    end
    local inset = frame.Inset
    if inset then addon:ThemeAlpha(inset.Bg, enabled); addon:ThemeAlpha(inset.NineSlice, enabled) end
end

local function Panel(frame, enabled, label)
    if not frame then return end
    addon:ThemeCard(frame, enabled, label)
    Chrome(frame, enabled)
    Fonts(frame, enabled, 0)
end

local function FlatBar(bar, enabled)
    if not bar or not bar.GetStatusBarTexture then return end
    local saved = barSaved[bar]
    if enabled then
        local texture = bar:GetStatusBarTexture()
        if not saved and texture then
            saved = { atlas = texture:GetAtlas(), file = texture:GetTexture(), coords = { texture:GetTexCoord() } }
            barSaved[bar] = saved
        end
        addon:DebugSurface(bar, "Theme/bar", "theme status bar")
        bar:SetStatusBarTexture(white)
        if bar:GetStatusBarTexture() then bar:GetStatusBarTexture():SetTexCoord(0, 1, 0, 1) end
    elseif saved then
        bar:SetStatusBarTexture(saved.file or white)
        local texture = bar:GetStatusBarTexture()
        if saved.atlas then texture:SetAtlas(saved.atlas) end
        texture:SetTexCoord(unpack(saved.coords)); barSaved[bar] = nil
    end
end

local function Portrait(texture, frame, enabled)
    if not texture or not frame then return end
    local ring = rings[texture]
    if enabled and not ring then
        ring = frame:CreateTexture(nil, "OVERLAY")
        ring:SetPoint("TOPLEFT", texture, "TOPLEFT", -2, 2)
        ring:SetPoint("BOTTOMRIGHT", texture, "BOTTOMRIGHT", 2, -2)
        ring:SetTexture("Interface\\AddOns\\PadSkinForever\\Media\\CircleBorder.tga")
        ring:SetVertexColor(.65, .68, .72, 1)
        rings[texture] = ring
    end
    if ring then ring:SetShown(enabled) end
end

local function Units(enabled)
    local player = PlayerFrame
    if player then
        local container = player.PlayerFrameContainer
        local content = player.PlayerFrameContent
        local main = content and content.PlayerFrameContentMain
        local health = main and main.HealthBarsContainer
        local mana = main and main.ManaBarArea
        addon:ThemeCard(player, enabled, "PlayerFrame", -12)
        if container then
            addon:ThemeAlpha(container.FrameTexture, enabled)
            -- Vehicle/class-resource alternate borders remain functional.
            Portrait(container.PlayerPortrait, container, enabled)
        end
        FlatBar(health and health.HealthBar, enabled)
        FlatBar(mana and mana.ManaBar, enabled)
        Fonts(content, enabled, 0)
        addon:ThemeFont(PlayerName, enabled, true)
    end
    for _, frame in pairs({ TargetFrame = TargetFrame, FocusFrame = FocusFrame }) do
        local container = frame.TargetFrameContainer
        local content = frame.TargetFrameContent
        local main = content and content.TargetFrameContentMain
        addon:ThemeCard(frame, enabled, "UnitFrame", -12)
        if container then
            addon:ThemeAlpha(container.FrameTexture, enabled)
            Portrait(container.Portrait, container, enabled)
        end
        local health = main and main.HealthBarsContainer
        local mana = main and main.ManaBar
        FlatBar(health and health.HealthBar or main and main.HealthBar, enabled)
        FlatBar(mana, enabled)
        Fonts(content, enabled, 0)
    end
    if PetFrame then
        addon:ThemeCard(PetFrame, enabled, "PetFrame", -5)
        addon:ThemeAlpha(PetFrameTexture, enabled)
        Portrait(PetFrame.Portrait or PetPortrait, PetFrame, enabled)
        FlatBar(PetFrameHealthBar, enabled); FlatBar(PetFrameManaBar, enabled)
        addon:ThemeFont(PetName, enabled, true)
        Fonts(PetFrame, enabled, 0)
    end
end

-- Party and boss frames stay Blizzard-owned.  This broad first pass gives
-- their common containers the same material and typography without replacing
-- unit buttons, changing anchors or registering extra Edit Mode systems.
local function SupplementalUnits(enabled)
    local function Style(frame, label)
        if not frame then return end
        addon:ThemeCard(frame, enabled, label, 2, addon.design.card)
        Fonts(frame, enabled, 0)
        for _, bar in pairs({ frame.HealthBar, frame.healthBar, frame.healthbar,
            frame.ManaBar, frame.manaBar, frame.manabar, frame.PowerBar, frame.powerBar }) do
            FlatBar(bar, enabled)
        end
    end
    for index = 1, 5 do
        Style(_G["CompactPartyFrameMember" .. index], "PartyFrame" .. index)
        Style(_G["Boss" .. index .. "TargetFrame"], "BossFrame" .. index)
    end
end

-- Minimap Complete collects minimap controls into one PSF-owned visual dock.
-- The original buttons remain the interaction layer: their scripts, tooltips and
-- addon/Blizzard ownership are never replaced.
local function MinimapDecoration(region)
    if not region or not region.IsObjectType or not region:IsObjectType("Texture") then return false end
    local atlas = region.GetAtlas and region:GetAtlas()
    local texture = region.GetTexture and region:GetTexture()
    local value = type(atlas) == "string" and atlas or type(texture) == "string" and texture or ""
    value = value:lower()
    return value:find("minimap%-trackingborder")
        or value:find("ui%-minimap%-background")
        or value:find("minimap_trackingborder")
end

local function MinimapControlSocket(control, enabled, label, thirdParty)
    if not control then return end
    local socket = minimapSockets[control]
    if enabled and not socket then
        socket = CreateFrame("Frame", nil, control)
        socket:EnableMouse(false)
        socket:SetFrameLevel(math.max(0, control:GetFrameLevel() - 1))
        socket:SetPoint("TOPLEFT", control, "TOPLEFT", -1, 1)
        socket:SetPoint("BOTTOMRIGHT", control, "BOTTOMRIGHT", 1, -1)
        addon:CreateRoundedPanel(socket, addon.design.surface.floating, addon.design.radius.socket)
        minimapSockets[control] = socket
        addon:DebugSurface(socket, "Minimap/" .. label .. "/socket",
            thirdParty and "third-party minimap dock item" or "native minimap dock item")
    end
    if socket then socket:SetShown(enabled) end
    for _, key in ipairs({ "Border", "Background", "BG", "Ring", "Circle", "HighlightRing" }) do
        addon:ThemeAlpha(control[key], enabled)
    end
    if control.GetRegions then
        for _, region in ipairs({ control:GetRegions() }) do
            if MinimapDecoration(region) then addon:ThemeAlpha(region, enabled) end
        end
    end
end

local DOCK_VISIBLE_LIMIT, DOCK_ITEM, DOCK_HEIGHT = 5, 28, 30

local function EnsureMinimapDock()
    if minimapDock or not Minimap then return minimapDock end
    minimapDock = CreateFrame("Frame", "PadSkinForeverMinimapDock", Minimap)
    minimapDock:EnableMouse(false)
    minimapDock:SetFrameLevel(math.max(0, Minimap:GetFrameLevel() + 2))
    minimapDock:SetHeight(DOCK_HEIGHT)
    minimapDock:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -4)
    addon:CreateRoundedPanel(minimapDock, addon.design.surface.peripheral, addon.design.radius.compact)
    addon:DebugSurface(minimapDock, "Minimap/IconDock", "collected minimap controls")

    minimapDockPanel = CreateFrame("Frame", "PadSkinForeverMinimapDockPanel", Minimap)
    minimapDockPanel:EnableMouse(false)
    minimapDockPanel:SetFrameLevel(minimapDock:GetFrameLevel() + 1)
    minimapDockPanel:SetPoint("TOPRIGHT", minimapDock, "BOTTOMRIGHT", 0, -4)
    addon:CreateRoundedPanel(minimapDockPanel, addon.design.surface.glass, addon.design.radius.compact)
    addon:DebugSurface(minimapDockPanel, "Minimap/IconDock/Overflow", "overflow minimap controls")
    minimapDockPanel:Hide()

    minimapDockLauncher = CreateFrame("Button", "PadSkinForeverMinimapDockLauncher", minimapDock)
    minimapDockLauncher:SetSize(24, 24)
    minimapDockLauncher:SetPoint("CENTER", minimapDock, "CENTER", 0, 0)
    local mark = minimapDockLauncher:CreateFontString(nil, "OVERLAY")
    mark:SetPoint("CENTER")
    -- A newly-created FontString has no inherited font. Theme it before assigning
    -- text; WoW raises "Font not set" if SetText is called first.
    addon:ThemeFont(mark, true, true)
    mark:SetText("•••")
    minimapDockLauncher:SetScript("OnClick", function()
        minimapDockOpen = not minimapDockOpen
        addon:QueueRefresh()
    end)
    minimapDockLauncher:Hide()
    addon:DebugSurface(minimapDockLauncher, "Minimap/IconDock/Launcher", "overflow launcher")
    return minimapDock
end

local function SaveDockAnchor(control)
    if minimapDocked[control] then return minimapDocked[control] end
    local saved = { points = {}, shown = control.IsShown and control:IsShown() }
    local count = control.GetNumPoints and control:GetNumPoints() or 1
    if control.GetPoint then
        for index = 1, math.max(1, count) do
            local point, relativeTo, relativePoint, x, y = control:GetPoint(index)
            if point then saved.points[#saved.points + 1] = { point, relativeTo, relativePoint, x, y } end
        end
    end
    minimapDocked[control] = saved
    return saved
end

local function RestoreDockAnchor(control)
    local saved = minimapDocked[control]
    if not saved then return end
    control:ClearAllPoints()
    for _, point in ipairs(saved.points) do control:SetPoint(unpack(point)) end
    if control.SetShown and saved.shown ~= nil then control:SetShown(saved.shown) end
    minimapDocked[control] = nil
end

local function DockMinimapControl(control, parent, index, columns, enabled, label, thirdParty)
    if not control then return end
    MinimapControlSocket(control, enabled, label, thirdParty)
    if enabled then
        SaveDockAnchor(control)
        control:ClearAllPoints()
        local column = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        control:SetPoint("CENTER", parent, "TOPLEFT",
            6 + DOCK_ITEM / 2 + column * DOCK_ITEM,
            -6 - DOCK_ITEM / 2 - row * DOCK_ITEM)
        if control.Show then control:Show() end
    else
        RestoreDockAnchor(control)
    end
end

local function MinimapControls(enabled)
    local cluster = MinimapCluster
    local candidates = {
        { cluster and cluster.Tracking, "Tracking" },
        { cluster and cluster.TrackingButton, "Tracking" },
        { cluster and cluster.ZoomIn, "ZoomIn" },
        { cluster and cluster.ZoomOut, "ZoomOut" },
        { Minimap and Minimap.ZoomIn, "ZoomIn" },
        { Minimap and Minimap.ZoomOut, "ZoomOut" },
        { _G["MiniMapTracking"], "Tracking" },
        { _G["GameTimeFrame"], "DayNight" },
        { _G["QueueStatusButton"], "QueueStatus" },
        { _G["ExpansionLandingPageMinimapButton"], "ExpansionLandingPage" },
        { _G["MiniMapMailFrame"], "Mail" },
    }
    local controls, seen = {}, {}
    local function Add(control, label, thirdParty)
        if not control or seen[control] then return end
        seen[control] = true
        -- Hidden native status controls (mail/queue/etc.) do not consume dock
        -- space until Blizzard actually presents them.
        if control.IsShown and not control:IsShown() and not minimapDocked[control] then return end
        controls[#controls + 1] = { control, label, thirdParty }
    end
    for _, entry in ipairs(candidates) do Add(entry[1], entry[2], false) end

    -- Third-party minimap launchers conventionally parent their Button directly
    -- to Minimap (LibDBIcon does this). Collect every visible direct button,
    -- without maintaining an addon allowlist.
    if Minimap and Minimap.GetChildren then
        for _, control in ipairs({ Minimap:GetChildren() }) do
            if control ~= minimapDock and control ~= minimapDockPanel and not seen[control]
                and control.IsObjectType and control:IsObjectType("Button") then
                local name = control.GetName and control:GetName()
                Add(control, type(name) == "string" and name or "AddonButton", true)
            end
        end
    end

    local dock = EnsureMinimapDock()
    if not dock then return end
    local overflow = enabled and #controls > DOCK_VISIBLE_LIMIT
    if enabled and #controls > 0 then
        dock:SetWidth(overflow and 32 or (8 + #controls * DOCK_ITEM))
        dock:Show()
    else
        dock:Hide()
    end
    minimapDockLauncher:SetShown(overflow)
    if not overflow then minimapDockOpen = false end

    if overflow then
        local columns = math.min(DOCK_VISIBLE_LIMIT, #controls)
        local rows = math.ceil(#controls / columns)
        minimapDockPanel:SetSize(12 + columns * DOCK_ITEM, 12 + rows * DOCK_ITEM)
        minimapDockPanel:SetShown(minimapDockOpen)
        for index, entry in ipairs(controls) do
            if minimapDockOpen then
                DockMinimapControl(entry[1], minimapDockPanel, index, columns, true, entry[2], entry[3])
            else
                -- Keep the original button and behavior intact, but remove it
                -- visually until the PSF overflow launcher is opened.
                MinimapControlSocket(entry[1], true, entry[2], entry[3])
                SaveDockAnchor(entry[1])
                entry[1]:Hide()
            end
        end
    else
        minimapDockPanel:Hide()
        for index, entry in ipairs(controls) do
            DockMinimapControl(entry[1], dock, index, math.max(1, #controls), enabled, entry[2], entry[3])
        end
    end

    -- Restore controls no longer discovered, and restore everything when the
    -- theme is disabled. This also restores each button's prior shown state.
    local active = {}
    if enabled then for _, entry in ipairs(controls) do active[entry[1]] = true end end
    local restore = {}
    for control in pairs(minimapDocked) do
        if not active[control] then restore[#restore + 1] = control end
    end
    for _, control in ipairs(restore) do
        MinimapControlSocket(control, false, "Restored", true)
        RestoreDockAnchor(control)
    end
    if not enabled then
        minimapDockOpen = false
        minimapDockPanel:Hide()
        minimapDockLauncher:Hide()
    end
end

local function Map(enabled)
    local map = Minimap
    if not map then return end
    addon:DebugSurface(map, "Minimap", "minimap mask")
    local square = enabled and addon.db.squareMinimap
    if not minimapMask then
        -- Forever's native minimap has no GetMaskTexture API. Its source supplies
        -- this mask; subsequent native mask changes are recorded by the post-hook.
        minimapMask = "ui-hud-minimap-frame-generic-mask"
        hooksecurefunc(map, "SetMaskTexture", function(_, mask)
            if addon.applyingSkin then return end
            minimapMask = mask
            minimapChanged = false
            addon:QueueRefresh()
        end)
    end
    if square then
        -- Minimap Base: the native map remains authoritative, but its actual
        -- rendered map fills the square instead of sitting behind a round mask.
        map:SetMaskTexture(white); minimapChanged = true
    elseif minimapChanged then
        map:SetMaskTexture(minimapMask); minimapChanged = false
    end

    -- The PSF surface is deliberately only a thin frame around the native map.
    -- Position, size, pins, zoom, clicks and minimap buttons remain Blizzard-owned.
    addon:ThemeCard(map, square, "Minimap", 1, addon.design.surface.rail or addon.design.card)
    addon:ThemeAlpha(MinimapCompassTextureUnderlay, enabled)
    addon:ThemeAlpha(MinimapCompassTexture, square)

    if MinimapCluster then
        -- Remove Blizzard's remaining circular/top chrome without touching the
        -- cluster itself or its child buttons.
        addon:ThemeAlpha(MinimapCluster.BorderTop, enabled)
        addon:ThemeAlpha(MinimapCluster.Border, enabled)
        addon:ThemeAlpha(MinimapCluster.Background, enabled)
        addon:ThemeAlpha(MinimapCluster.MinimapBorder, enabled)
        addon:ThemeAlpha(MinimapCluster.MinimapBorderTop, enabled)
        Fonts(MinimapCluster.ZoneTextButton, enabled, 0)
    end
    addon:ThemeAlpha(MinimapBorder, enabled)
    addon:ThemeAlpha(MinimapBorderTop, enabled)
    addon:ThemeFont(MinimapZoneText, enabled, true)

    -- Complete collects native and third-party controls into one compact PSF dock.
    -- Original buttons remain clickable; only their presentation/placement changes.
    MinimapControls(enabled)
end

local function Chat(enabled)
    for index = 1, NUM_CHAT_WINDOWS or 10 do
        local frame = _G["ChatFrame" .. index]
        if frame then
            addon:ThemeCard(frame, enabled, "ChatFrame" .. index, 5)
            addon:ThemeFont(frame, enabled)
            for _, part in ipairs({ "Background", "TopLeftTexture", "TopRightTexture", "BottomLeftTexture", "BottomRightTexture", "TopTexture", "BottomTexture", "LeftTexture", "RightTexture" }) do
                addon:ThemeAlpha(_G["ChatFrame" .. index .. part], enabled)
            end
            local tab = _G["ChatFrame" .. index .. "Tab"]
            Fonts(tab, enabled, 0)
            local edit = _G["ChatFrame" .. index .. "EditBox"]
            addon:ThemeCard(edit, enabled, "ChatInput" .. index, 0)
            addon:ThemeFont(edit, enabled)
            for _, part in ipairs({ "Left", "Mid", "Right" }) do addon:ThemeAlpha(_G["ChatFrame" .. index .. "EditBox" .. part], enabled) end
        end
    end
end

local function Loot(enabled)
    local frame = LootFrame
    if not frame then return end
    Panel(frame, enabled, "LootFrame")
    Hook(frame, "Open")
    local scroll = frame.ScrollBox
    if scroll then
        Hook(scroll, "SetDataProvider")
        Hook(scroll, "FullUpdate")
        if scroll.ForEachFrame then
            scroll:ForEachFrame(function(row)
                Panel(row, enabled, "LootRow")
                addon:ThemeAlpha(row.NameFrame, enabled)
                addon:Tint(row.BorderFrame, enabled and grey or nil)
                addon:Tint(row.HighlightNameFrame, enabled and { .25, .9, .3 } or nil)
                -- Preserve quality stripes, icons, focus, hover and native loot clicks.
            end)
        end
    end
end

-- Walk only the quest pane, never the map canvas or its pins/input handlers.
local function QuestDecorations(frame, enabled, depth)
    if not frame or depth > 8 or not frame.GetRegions then return end
    Chrome(frame, enabled)
    for _, key in ipairs({ "Border", "TopDetail", "Shadow", "Divider", "Top", "Bottom", "SealMaterialBG" }) do
        addon:ThemeAlpha(frame[key], enabled)
    end
    local header = frame.GetNormalTexture and frame.CollapseButton
    if header then
        addon:ThemeCard(frame, enabled, "QuestHeader", 0)
        addon:ThemeAlpha(frame:GetNormalTexture(), enabled)
        for _, key in ipairs({ "Left", "Middle", "Right" }) do addon:ThemeAlpha(frame[key], enabled) end
        addon:ThemeFont(frame.ButtonText or frame.Text, enabled, true)
    end
    if frame.GetNormalTexture and not header and not frame.Checkbox then
        addon:Tint(frame:GetNormalTexture(), enabled and grey or nil)
        if frame.GetPushedTexture then addon:Tint(frame:GetPushedTexture(), enabled and { .2, .3, .24 } or nil) end
    end
    if frame.GetHighlightTexture then addon:Tint(frame:GetHighlightTexture(), enabled and { .2, .85, .3 } or nil) end
    -- Retain native visibility/selection of highlights, checkbox and quest tags.
    for _, key in ipairs({ "HighlightTexture", "SelectedHighlight", "SelectedTexture" }) do
        addon:Tint(frame[key], enabled and { .2, .85, .3 } or nil)
    end
    if frame.Checkbox then addon:Tint(frame.Checkbox.CheckMark, enabled and { .2, .95, .3 } or nil) end
    for _, region in ipairs({ frame:GetRegions() }) do
        if region:IsObjectType("FontString") then addon:ThemeFont(region, enabled) end
    end
    for _, child in ipairs({ frame:GetChildren() }) do
        if child ~= cards[frame] then QuestDecorations(child, enabled, depth + 1) end
    end
end

local questHooks = {}
local function Quests(enabled)
    for _, frame in pairs({ QuestLogFrame = QuestLogFrame, QuestMapFrame = QuestMapFrame,
        QuestLogPopupDetailFrame = QuestLogPopupDetailFrame }) do
        Panel(frame, enabled, "QuestLog")
        QuestDecorations(frame, enabled, 0)
        local quests = frame.QuestsFrame
        local scroll = quests and quests.ScrollFrame
        if scroll then
            addon:ThemeCard(scroll, enabled, "QuestList", 0)
            addon:ThemeAlpha(scroll.BorderFrame, enabled)
            addon:ThemeCard(scroll.SearchBox, enabled, "QuestSearch", 0)
            if scroll.SearchBox then
                for _, key in ipairs({ "Left", "Middle", "Right" }) do addon:ThemeAlpha(scroll.SearchBox[key], enabled) end
            end
            Hook(scroll, "UpdateBackground")
        end
        local details = frame.DetailsFrame or (quests and quests.DetailsFrame)
        if details then
            Panel(details, enabled, "QuestDetails")
            addon:ThemeAlpha(details.BorderFrame, enabled)
            local container = details.RewardsFrameContainer
            if container then Panel(container.RewardsFrame, enabled, "QuestRewards") end
        end
    end
    -- Style the surrounding window chrome without traversing ScrollContainer.
    local border = WorldMapFrame and WorldMapFrame.BorderFrame
    if border then
        -- BorderFrame sits above the map canvas. Keep this rounded card
        -- transparent so only its soft outline is drawn over the map.
        addon:ThemeCard(border, enabled, "MapQuestWindow", 0, {
            fill = { 0, 0, 0, 0 },
            border = { .58, .63, .69, .28 },
        })
        Chrome(border, enabled)
        addon:ThemeFont(border.TitleText or (border.TitleContainer and border.TitleContainer.TitleText), enabled, true)
        -- The native portrait remains; only its decorative gold ring is neutralized.
        addon:Tint(border.PortraitContainer and border.PortraitContainer.PortraitRing, enabled and grey or nil)
    end
    for _, name in ipairs({ "QuestMapFrame_UpdateAll", "QuestLogQuests_Update", "QuestMapFrame_ShowQuestDetails" }) do
        if type(_G[name]) == "function" and not questHooks[name] then
            questHooks[name] = true
            hooksecurefunc(name, function() if not addon.applyingSkin then addon:QueueRefresh() end end)
        end
    end
end

function addon:RefreshTheme()
    if not self.db or InCombatLockdown() then return end
    self:RefreshCombatHUD()
    Map(self.db.themeMinimap)
    Units(self.db.themeUnits and not self.db.compactUnits)
    SupplementalUnits(self.db.themeUnits)
    self:RefreshUnitFrames()
    self:RefreshUnitIcons()
    Quests(self.db.themeQuests)
    Panel(ObjectiveTrackerFrame, self.db.themeQuests, "QuestTracker")
    Hook(ObjectiveTrackerFrame, "Update")
    Chat(self.db.themeChat)
    for _, tooltip in pairs({ GameTooltip = GameTooltip, ItemRefTooltip = ItemRefTooltip,
        ShoppingTooltip1 = ShoppingTooltip1, ShoppingTooltip2 = ShoppingTooltip2 }) do
        Panel(tooltip, self.db.themeTooltip, "Tooltip")
        FlatBar(tooltip.StatusBar, self.db.themeTooltip)
        Hook(tooltip, "SetText"); Hook(tooltip, "AddLine"); Hook(tooltip, "AddDoubleLine")
    end
    Loot(self.db.themeLoot)
    self:RefreshToasts()
end
