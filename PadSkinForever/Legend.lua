local _, addon = ...
-- Visual layout only. Native groups, prompt states and input bindings stay intact.
local saved = setmetatable({}, { __mode = "k" })
local panels = setmetatable({}, { __mode = "k" })
local hooked = setmetatable({}, { __mode = "k" })
local WHITE = "Interface\\Buttons\\WHITE8X8"

local function Points(frame)
    local result = {}
    for i = 1, frame:GetNumPoints() do result[i] = { frame:GetPoint(i) } end
    return result
end
local function Capture(frame)
    if not frame or not frame.GetNumPoints then return end
    if not saved[frame] then
        local w, h = frame:GetSize()
        saved[frame] = { points = Points(frame), width = w, height = h,
            color = frame.GetTextColor and { frame:GetTextColor() } }
    end
    return saved[frame]
end
local function Position(frame, relative, x, y)
    Capture(frame)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", relative, "TOPLEFT", x, -y)
end
local function Restore(frame)
    local original = saved[frame]
    if not original then return end
    frame:ClearAllPoints()
    for _, point in ipairs(original.points) do frame:SetPoint(unpack(point)) end
    frame:SetSize(original.width, original.height)
    if original.alpha then frame:SetAlpha(original.alpha) end
    if original.color then frame:SetTextColor(unpack(original.color)) end
    saved[frame] = nil
end
local function Watch(frame)
    if hooked[frame] then return end
    hooked[frame] = true

    -- Follow native hover/focus-capable prompt frames without creating a new
    -- navigation owner. Mouse hover is also useful as a deterministic visual
    -- validation of the same PSF focus language.
    if frame.HookScript then
        frame:HookScript("OnEnter", function(self)
            addon:SetInputFocusTreatment(self, "focused")
        end)
        frame:HookScript("OnLeave", function(self)
            addon:SetInputFocusTreatment(self, "normal")
        end)
        frame:HookScript("OnMouseDown", function(self)
            addon:SetInputFocusTreatment(self, "pressed")
        end)
        frame:HookScript("OnMouseUp", function(self)
            addon:SetInputFocusTreatment(self, self.IsMouseOver and self:IsMouseOver() and "focused" or "normal")
        end)
    end
    for _, method in ipairs({ "SetPromptText", "SetPromptFont", "SetInputIconSize" }) do
        if type(frame[method]) == "function" then
            hooksecurefunc(frame, method, function()
                if not addon.applyingSkin then addon:QueueRefresh() end
            end)
        end
    end
end

local function Panel(background)
    if panels[background] then return panels[background] end
    local panel = CreateFrame("Frame", nil, background)
    panel:EnableMouse(false)
    panel:SetAllPoints(background)
    addon:CreateRoundedPanel(panel, {
        fill = addon.design.cardStrong.fill,
        border = { .40, .43, .47, .72 },
    }, addon.design.cardRadius)
    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    panel.PSFLogo = addon:CreatePSFLogo(panel, 28)
    panel.PSFLogo:SetPoint("TOPLEFT", 16, -14)
    panel.title:SetPoint("TOPLEFT", 52, -14); panel.title:SetText("Controller")
    panel.line = panel:CreateTexture(nil, "ARTWORK")
    panel.line:SetTexture(WHITE); panel.line:SetVertexColor(.33, .38, .43, .75)
    panel.line:SetHeight(1)
    panels[background] = panel
    addon:DebugSurface(panel, "Legend/panel", "legend theme panel")
    return panel
end

function addon:LayoutLegend(legend)
    if InCombatLockdown() then return end
    for name, group in pairs(legend.groups or {}) do
        local background, entries = nil, {}
        for _, frame in ipairs(group) do
            if frame.Background then background = frame
            elseif frame.ControlDescText and frame.GetNumPoints then entries[#entries + 1] = frame end
        end
        if not self.db.skinLegend then
            for _, frame in ipairs(entries) do
                addon:ClearInputFocusTreatment(frame)
                Restore(frame)
                for _, part in ipairs({ "InputIcon1", "InputIcon2", "IconDivider1", "ControlDescText" }) do Restore(frame[part]) end
                local text = frame.ControlDescText.FontString
                -- FontString itself need not have size/anchor methods in older clients.
                local original = saved[text]
                if original and original.color then text:SetTextColor(unpack(original.color)); saved[text] = nil end
                if frame.RefreshInputPromptSize then
                    frame.ControlDescText:SetWidth(text:GetStringWidth())
                    frame:RefreshInputPromptSize()
                end
            end
            if background then
                Restore(background); Restore(background.Background); Restore(background.HeaderTrim)
                if panels[background] then panels[background]:Hide() end
            end
        elseif background and #entries > 0 then
            local pad, gap = self.db.legendPadding, self.db.legendRowGap
            local header = legend.DoesGroupUseHeader and legend:DoesGroupUseHeader(name)
            local columnWidth = legend.GetColumnWidth and legend:GetColumnWidth(name) or 300
            if columnWidth <= 0 then columnWidth = 300 end
            local rows, columns, iconColumns, count = {}, {}, {}, 1
            for _, frame in ipairs(entries) do
                local original = Capture(frame)
                local anchor = original.points[1]
                local x, y = anchor and anchor[4] or 20, anchor and anchor[5] or -20
                local col = math.max(0, math.floor((x - 20) / columnWidth + .5))
                local row = math.max(0, math.floor((-y - 20 - (header and y < -20 and 10 or 0)) / 24 + .5))
                count = math.max(count, col + 1)
                local text = frame.ControlDescText.FontString
                if text.GetTextColor and not saved[text] then saved[text] = { color = { text:GetTextColor() } } end
                text:SetTextColor(.94, .95, .96, 1)
                if header and row == 0 then
                    text:SetFont(self:GetLegendHeaderFontPath(), self.db.legendFontSize + 2, "")
                end
                local height = math.max(self.db.legendFontSize, text:GetStringHeight())
                local iconWidth = 0
                for _, part in ipairs({ "InputIcon1", "IconDivider1", "InputIcon2" }) do
                    local icon = frame[part]
                    if icon then
                        Capture(icon)
                        local w, h = icon:GetSize(); local scale = icon:GetScale()
                        height = math.max(height, h * scale)
                        iconWidth = iconWidth + w * scale + (iconWidth > 0 and 5 or 0)
                    end
                end
                rows[row] = math.max(rows[row] or 0, math.ceil(height))
                local width = text:GetStringWidth()
                local layoutCol = header and row == 0 and -1 or col
                columns[layoutCol] = math.max(columns[layoutCol] or 0, width)
                iconColumns[layoutCol] = math.max(iconColumns[layoutCol] or 0, iconWidth)
                original.row, original.col, original.iconWidth = row, col, iconWidth
                original.layoutCol = layoutCol
                Watch(frame)
                self:DebugSurface(frame, "Legend/" .. name .. "/row" .. row .. "/col" .. col, "legend row layout")
            end
            local offsets, height = {}, pad + (header and 0 or self.db.legendFontSize + 18)
            local last = 0; for row in pairs(rows) do last = math.max(last, row) end
            for row = 0, last do
                offsets[row] = height
                height = height + (rows[row] or self.db.legendFontSize) + (row < last and gap or 0)
                if header and row == 0 then height = height + 12 end
            end
            height = height + pad
            local colX, width = {}, pad
            for col = 0, count - 1 do
                colX[col] = width
                width = width + math.ceil((columns[col] or columnWidth) + (iconColumns[col] or 0) + 12) + (col < count - 1 and 24 or 0)
            end
            width = math.max(240, width + pad, (columns[-1] or 0) + (iconColumns[-1] or 0) + 12 + pad * 2)
            for _, frame in ipairs(entries) do
                local original = saved[frame]
                local rowHeight = rows[original.row]
                Position(frame, legend, colX[original.col], offsets[original.row])
                local cursor = 0
                for _, part in ipairs({ "InputIcon1", "IconDivider1", "InputIcon2" }) do
                    local icon = frame[part]
                    if icon then
                        local w, h = icon:GetSize(); local scale = icon:GetScale()
                        Position(icon, frame, cursor / scale, (rowHeight - h * scale) / (2 * scale))
                        cursor = cursor + w * scale + 5
                    end
                end
                local textFrame, text = frame.ControlDescText, frame.ControlDescText.FontString
                Position(textFrame, frame, iconColumns[original.layoutCol] + 12, (rowHeight - text:GetStringHeight()) / 2)
                textFrame:SetSize(text:GetStringWidth(), text:GetStringHeight())
                frame:SetSize(iconColumns[original.layoutCol] + 12 + text:GetStringWidth(), rowHeight)
            end
            Capture(background); background:SetSize(width, height)
            local decoration = Capture(background.Background)
            if decoration.alpha == nil then decoration.alpha = background.Background:GetAlpha() end
            background.Background:SetAlpha(0)
            if background.HeaderTrim then
                local trim = Capture(background.HeaderTrim)
                if trim.alpha == nil then trim.alpha = background.HeaderTrim:GetAlpha() end
                background.HeaderTrim:SetAlpha(0)
            end
            local panel = Panel(background)
            panel.title:SetShown(not header)
            panel.PSFLogo:SetShown(not header)
            if not header then panel.title:SetFont(self:GetLegendHeaderFontPath(), self.db.legendFontSize + 2, "") end
            local lineY = header and offsets[0] + rows[0] + 6 or pad + self.db.legendFontSize + 7
            panel.line:ClearAllPoints()
            panel.line:SetPoint("TOPLEFT", panel, "TOPLEFT", pad, -lineY)
            panel.line:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -pad, -lineY)
            panel:SetShown(true)
        end
    end
end
