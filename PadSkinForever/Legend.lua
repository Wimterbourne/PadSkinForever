local _, addon = ...
-- Visual layout only. Native groups, prompt states and input bindings stay intact.
local saved = setmetatable({}, { __mode = "k" })
local panels = setmetatable({}, { __mode = "k" })
local hooked = setmetatable({}, { __mode = "k" })
local WHITE = "Interface\\Buttons\\WHITE8X8"
local CORNER = "Interface\\AddOns\\PadSkinForever\\Media\\LegendCorner"

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
    -- Fixed-size corner pieces avoid stretched corner radii as the content grows.
    for _, layer in ipairs({ "Fill", "Border" }) do
        local color = layer == "Fill" and { .055, .062, .073, .96 } or { .40, .43, .47, 1 }
        for _, corner in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
            local t = panel:CreateTexture(nil, "BACKGROUND")
            t:SetTexture(CORNER .. layer .. ".tga")
            t:SetSize(8, 8); t:SetPoint(corner, panel, corner)
            local right, bottom = corner:find("RIGHT"), corner:find("BOTTOM")
            t:SetTexCoord(right and 1 or 0, right and 0 or 1, bottom and 1 or 0, bottom and 0 or 1)
            t:SetVertexColor(unpack(color))
        end
        local function Rect(a, b, x1, y1, x2, y2)
            local t = panel:CreateTexture(nil, "BACKGROUND")
            t:SetTexture(WHITE); t:SetVertexColor(unpack(color))
            -- Anchors along one edge constrain only the long axis. Explicitly
            -- size the short axis; WHITE8X8 otherwise remains eight pixels thick.
            if a:find("TOP") and b:find("TOP") or a:find("BOTTOM") and b:find("BOTTOM") then
                t:SetHeight(math.abs(y2 - y1)); y2 = y1
            elseif a:find("LEFT") and b:find("LEFT") or a:find("RIGHT") and b:find("RIGHT") then
                t:SetWidth(math.abs(x2 - x1)); x2 = x1
            end
            t:SetPoint(a, panel, a, x1, y1); t:SetPoint(b, panel, b, x2, y2)
        end
        if layer == "Fill" then
            Rect("TOPLEFT", "BOTTOMRIGHT", 8, 0, -8, 0)
            Rect("TOPLEFT", "BOTTOMLEFT", 0, -8, 8, 8)
            Rect("TOPRIGHT", "BOTTOMRIGHT", 0, -8, -8, 8)
        else
            Rect("TOPLEFT", "TOPRIGHT", 8, 0, -8, -1)
            Rect("BOTTOMLEFT", "BOTTOMRIGHT", 8, 0, -8, 1)
            Rect("TOPLEFT", "BOTTOMLEFT", 0, -8, 1, 8)
            Rect("TOPRIGHT", "BOTTOMRIGHT", 0, -8, -1, 8)
        end
    end
    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    panel.title:SetPoint("TOPLEFT", 16, -14); panel.title:SetText("Controller")
    panel.line = panel:CreateTexture(nil, "ARTWORK")
    panel.line:SetTexture(WHITE); panel.line:SetVertexColor(.24, .28, .25, 1)
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
            if not header then panel.title:SetFont(self:GetFontPath(), self.db.legendFontSize + 2, "") end
            local lineY = header and offsets[0] + rows[0] + 6 or pad + self.db.legendFontSize + 7
            panel.line:ClearAllPoints()
            panel.line:SetPoint("TOPLEFT", panel, "TOPLEFT", pad, -lineY)
            panel.line:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -pad, -lineY)
            panel:SetShown(true)
        end
    end
end
