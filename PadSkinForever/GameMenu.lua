local _, addon = ...

local menuButton

function addon:CreateGameMenuButton()
    if menuButton or not GameMenuFrame or not self.CreatePSFButton then return end

    -- Keep this button outside Blizzard's pooled GameMenuFrame.buttons list.
    -- Native SmartNavigation discovers visible child Buttons geometrically.
    -- Never add routes to Blizzard-owned buttons: those route tables feed the
    -- protected gamepad binding stack when the native menu closes.
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
    -- The card sits beside the red column so directional navigation can find
    -- it without PSF writing to GameMenuFrame.buttons or their route tables.
    menuButton:SetPoint("TOPRIGHT", GameMenuFrame, "TOPLEFT", -14, -46)
    menuButton:SetSize(232, 58)
    menuButton:SetFrameLevel(GameMenuFrame:GetFrameLevel() + 10)
    menuButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    menuButton:SetBackdropColor(0, 0, 0, 0)
    menuButton:SetBackdropBorderColor(0, 0, 0, 0)
    self:CreateRoundedPanel(menuButton, self.design.cardStrong, self.design.cardRadius)
    menuButton.PSFText:ClearAllPoints()
    menuButton.PSFText:SetPoint("TOPLEFT", 53, -11)
    menuButton.PSFText:SetTextColor(.95, .98, .96, 1)
    menuButton.PSFIndicator:ClearAllPoints()
    menuButton.PSFIndicator:SetPoint("TOPLEFT", 1, -12)
    menuButton.PSFIndicator:SetPoint("BOTTOMLEFT", 1, 12)
    menuButton.PSFIndicator:SetWidth(3)

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
            menuButton.PSFIndicator:Show()
            subtitle:SetTextColor(.76, .86, .79, 1)
        else
            menuButton.PSFIndicator:Hide()
            subtitle:SetTextColor(.58, .66, .61, 1)
        end
    end
    menuButton:SetScript("OnEnter", function() SetMenuState(true) end)
    menuButton:SetScript("OnLeave", function() SetMenuState(false) end)

    menuButton.PSFLogo = self:CreatePSFLogo(menuButton, 36)
    menuButton.PSFLogo:SetPoint("LEFT", 10, 0)
    SetMenuState(false)
    menuButton:Show()
end

function addon:GetGameMenuButton()
    return menuButton
end
