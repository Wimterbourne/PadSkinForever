local _, addon = ...

local menuButton

function addon:CreateGameMenuButton()
    if menuButton or not GameMenuFrame or not self.CreatePSFButton then return end

    -- Keep this button outside Blizzard's pooled GameMenuFrame.buttons list.
    -- Native SmartNavigation discovers visible child Buttons on its own.
    menuButton = self:CreatePSFButton(GameMenuFrame, "PadSkinForever", 0, 0, 200, function()
        if InCombatLockdown() then
            addon:Print("Open PadSkinForever after combat.")
            return
        end
        -- Deliberately leave GameMenuFrame open underneath. Calling its hide
        -- path from addon code can propagate taint into protected gamepad APIs.
        addon:ShowOptions()
    end)
    menuButton:ClearAllPoints()
    menuButton:SetPoint("TOPRIGHT", GameMenuFrame, "TOPLEFT", -14, -48)
    menuButton:SetSize(200, 36)
    menuButton:SetFrameLevel(GameMenuFrame:GetFrameLevel() + 10)
    menuButton.PSFText:ClearAllPoints()
    menuButton.PSFText:SetPoint("LEFT", 43, 0)

    local badge = CreateFrame("Frame", nil, menuButton, "BackdropTemplate")
    badge:SetPoint("LEFT", 7, 0); badge:SetSize(27, 22)
    badge:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    badge:SetBackdropColor(.055, .062, .073, 1)
    badge:SetBackdropBorderColor(unpack(self.uiColors.accent))
    local badgeText = badge:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    badgeText:SetPoint("CENTER"); badgeText:SetText("PSF")
    if not badgeText:SetFont(self:GetUIFontPath(true), 9, "") then
        badgeText:SetFont(STANDARD_TEXT_FONT, 9, "")
    end
    badgeText:SetTextColor(unpack(self.uiColors.accent))
    menuButton:Show()
end

function addon:GetGameMenuButton()
    return menuButton
end
