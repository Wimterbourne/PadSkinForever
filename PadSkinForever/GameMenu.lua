local _, addon = ...

local menuButton

function addon:CreateGameMenuButton()
    if menuButton or not GameMenuFrame or not self.CreatePSFButton then return end

    -- Keep this button outside Blizzard's pooled GameMenuFrame.buttons list.
    -- Native SmartNavigation discovers visible child Buttons on its own.
    menuButton = self:CreatePSFButton(GameMenuFrame, "PADSKINFOREVER", 0, 0, 232, function()
        if InCombatLockdown() then
            addon:Print("Open PadSkinForever after combat.")
            return
        end
        -- Deliberately leave GameMenuFrame open underneath. Calling its hide
        -- path from addon code can propagate taint into protected gamepad APIs.
        addon:ShowOptions()
    end)
    menuButton:ClearAllPoints()
    -- Visually attach the card to the menu, but keep it outside Blizzard's
    -- pooled red-button column. Up from Options reaches it naturally.
    menuButton:SetPoint("BOTTOM", GameMenuFrame, "TOP", 0, 14)
    menuButton:SetSize(232, 58)
    menuButton:SetFrameLevel(GameMenuFrame:GetFrameLevel() + 10)
    menuButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    menuButton.PSFText:ClearAllPoints()
    menuButton.PSFText:SetPoint("TOPLEFT", 53, -11)
    menuButton.PSFText:SetTextColor(.95, .98, .96, 1)

    local subtitle = menuButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    subtitle:SetPoint("TOPLEFT", 53, -32)
    subtitle:SetText("ADDON SETTINGS")
    if not subtitle:SetFont(self:GetUIFontPath(false), 10, "") then
        subtitle:SetFont(STANDARD_TEXT_FONT, 10, "")
    end
    subtitle:SetTextColor(.58, .66, .61, 1)
    menuButton.PSFSubtitle = subtitle

    local openHint = menuButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    openHint:SetPoint("RIGHT", -11, 0)
    openHint:SetText("A  OPEN")
    if not openHint:SetFont(self:GetUIFontPath(true), 10, "") then
        openHint:SetFont(STANDARD_TEXT_FONT, 10, "")
    end
    openHint:SetTextColor(unpack(self.uiColors.accent))
    menuButton.PSFOpenHint = openHint

    local function SetMenuState(focused)
        if focused then
            menuButton:SetBackdropColor(.08, .18, .11, .99)
            menuButton:SetBackdropBorderColor(.38, 1, .57, 1)
            subtitle:SetTextColor(.76, .86, .79, 1)
        else
            menuButton:SetBackdropColor(.04, .075, .055, .99)
            menuButton:SetBackdropBorderColor(.24, .68, .38, 1)
            subtitle:SetTextColor(.58, .66, .61, 1)
        end
    end
    menuButton:SetScript("OnEnter", function() SetMenuState(true) end)
    menuButton:SetScript("OnLeave", function() SetMenuState(false) end)

    local badge = CreateFrame("Frame", nil, menuButton, "BackdropTemplate")
    badge:SetPoint("LEFT", 10, 0); badge:SetSize(32, 32)
    badge:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    badge:SetBackdropColor(.055, .062, .073, 1)
    badge:SetBackdropBorderColor(unpack(self.uiColors.accent))
    local badgeText = badge:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    badgeText:SetPoint("CENTER"); badgeText:SetText("PSF")
    if not badgeText:SetFont(self:GetUIFontPath(true), 10, "") then
        badgeText:SetFont(STANDARD_TEXT_FONT, 10, "")
    end
    badgeText:SetTextColor(unpack(self.uiColors.accent))
    SetMenuState(false)
    menuButton:Show()
end

function addon:GetGameMenuButton()
    return menuButton
end
