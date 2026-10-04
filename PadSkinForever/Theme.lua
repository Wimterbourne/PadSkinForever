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
local white = "Interface\\Buttons\\WHITE8X8"
local grey = { .34, .37, .41 }

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
        local path = self.db.themeFonts and self:GetFontPath() or saved.path
        if not text:SetFont(path, saved.size, saved.flags) then text:SetFont(STANDARD_TEXT_FONT, saved.size, saved.flags) end
        local color = saved.color
        -- Turn parchment-dark text white; retain item quality and semantic colors.
        if color and (forceWhite or (color[1] < .5 and color[2] < .5 and color[3] < .5)) then
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
        addon:CreateRoundedPanel(card, palette or {
            fill = { .035, .043, .054, .88 },
            border = { .58, .63, .69, .28 },
        }, 10)
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
        map:SetMaskTexture(white); minimapChanged = true
    elseif minimapChanged then
        map:SetMaskTexture(minimapMask); minimapChanged = false
    end
    addon:ThemeCard(map, square, "Minimap", 2)
    addon:ThemeAlpha(MinimapCompassTextureUnderlay, enabled)
    -- Round and square are shape choices within the same independent skin.
    addon:Tint(MinimapCompassTexture, enabled and { .65, .68, .72 } or nil)
    -- Vertex tint restoration can also restore texture alpha: visibility goes last.
    addon:ThemeAlpha(MinimapCompassTexture, square)
    if MinimapCluster then
        addon:ThemeAlpha(MinimapCluster.BorderTop, enabled)
        Fonts(MinimapCluster.ZoneTextButton, enabled, 0)
    end
    addon:ThemeFont(MinimapZoneText, enabled, true)
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
