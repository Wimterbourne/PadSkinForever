local _, addon = ...
local queue, active, pool = {}, {}, {}
local root
local formats = { "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF_MULTIPLE",
    "LOOT_ITEM_CREATED_SELF_MULTIPLE", "LOOT_ITEM_SELF", "LOOT_ITEM_PUSHED_SELF", "LOOT_ITEM_CREATED_SELF" }
local function Literal(value) return value:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") end

-- Tokenize localized printf strings, including reordered %2$d / %1$s fields.
function addon:LootFormatPattern(format)
    if type(format) ~= "string" then return nil end
    local pieces, kinds, cursor = { "^" }, {}, 1
    while cursor <= #format do
        local a, b, position, kind = format:find("%%(%d+)%$([sd])", cursor)
        local c, d, simple = format:find("%%([sd])", cursor)
        if c and (not a or c < a) then a, b, kind = c, d, simple end
        if not a then pieces[#pieces + 1] = Literal(format:sub(cursor)); break end
        pieces[#pieces + 1] = Literal(format:sub(cursor, a - 1))
        pieces[#pieces + 1] = kind == "d" and "(%d+)" or "(.-)"
        kinds[#kinds + 1] = kind
        cursor = b + 1
    end
    pieces[#pieces + 1] = "$"
    return table.concat(pieces), kinds
end

function addon:ParseSelfLoot(message)
    if type(message) ~= "string" then return nil end
    -- The self templates avoid comparing player GUIDs or touching gamepad state.
    for _, name in ipairs(formats) do
        local pattern, kinds = self:LootFormatPattern(_G[name])
        if pattern then
            local ok, a, b = pcall(string.match, message, pattern)
            if ok and a then
                local fields, count, link = { a, b }, 1
                for index, value in ipairs(fields) do
                    if kinds[index] == "d" then count = tonumber(value) or 1
                    elseif type(value) == "string" then link = value:match("(|c%x+|Hitem:.-|h.-|h|r)") or value:match("(|Hitem:.-|h.-|h)") end
                end
                if link then return { link = link, count = count, key = link } end
            end
        end
    end
end

local function ItemVisual(data)
    local name, _, quality, _, _, _, _, _, _, icon
    if data.link and C_Item and C_Item.GetItemInfo then
        name, _, quality, _, _, _, _, _, _, icon = C_Item.GetItemInfo(data.link)
    end
    name = data.title or name or (data.link and data.link:match("|h%[(.-)%]|h")) or "Loot received"
    local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
    return name, data.icon or icon or 134400, color
end

local function Render(frame, data)
    local name, icon, color = ItemVisual(data)
    frame.icon:SetTexture(icon)
    frame.title:SetText(name)
    frame.count:SetText(data.count and data.count > 1 and ("×" .. data.count) or "")
    frame.title:SetTextColor(color and color.r or .94, color and color.g or .95, color and color.b or .97)
    frame.accent:SetVertexColor(color and color.r or .3, color and color.g or .65, color and color.b or .35, 1)
    local path = addon.db.themeFonts and addon:GetFontPath() or STANDARD_TEXT_FONT
    for _, text in ipairs({ frame.title, frame.count, frame.caption }) do
        if not text:SetFont(path, text == frame.title and 14 or 12, "") then text:SetFont(STANDARD_TEXT_FONT, 14, "") end
    end
end

local function CreateToast(index)
    local frame = CreateFrame("Frame", nil, root, "BackdropTemplate")
    frame:SetSize(290, 54)
    frame:SetPoint("TOPRIGHT", root, "TOPRIGHT", 0, -(index - 1) * 60)
    frame:EnableMouse(false)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(0, 0, 0, 0); frame:SetBackdropBorderColor(0, 0, 0, 0)
    addon:CreateRoundedPanel(frame, addon.design.floating, addon.design.cardRadius)
    frame.accent = frame:CreateTexture(nil, "ARTWORK")
    frame.accent:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.accent:SetPoint("TOPLEFT", 1, -12); frame.accent:SetPoint("BOTTOMLEFT", 1, 12)
    frame.accent:SetWidth(3)
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetSize(38, 38); frame.icon:SetPoint("LEFT", 8, 0)
    frame.icon:SetTexCoord(.07, .93, .07, .93)
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOPLEFT", 56, -9); frame.title:SetWidth(190); frame.title:SetJustifyH("LEFT")
    frame.caption = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.caption:SetPoint("TOPLEFT", 56, -31); frame.caption:SetText(LOOT or "Loot"); frame.caption:SetTextColor(.6, .63, .68)
    frame.count = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.count:SetPoint("RIGHT", -10, 0)
    frame.PSFLogo = addon:CreatePSFLogo(frame, 22)
    frame.PSFLogo:SetPoint("BOTTOMRIGHT", -10, 6)
    frame:Hide()
    return frame
end

local function Start(data, index)
    local frame = pool[index]
    active[index] = { data = data, life = 4.5, age = 0 }
    Render(frame, data); frame:SetAlpha(0); frame:Show()
end

function addon:TickToasts(elapsed)
    for index = 1, 3 do
        local entry = active[index]
        if entry then
            entry.life, entry.age = entry.life - elapsed, entry.age + elapsed
            if entry.life <= 0 then
                active[index] = nil; pool[index]:Hide()
            else
                pool[index]:SetAlpha(math.min(1, entry.age / .15, entry.life / .5))
            end
        end
        if not active[index] and #queue > 0 then Start(table.remove(queue, 1), index) end
    end
end

local function EnsureRoot()
    if root then return end
    root = CreateFrame("Frame", nil, UIParent)
    root:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -34, -390)
    root:SetSize(290, 180); root:SetFrameStrata("HIGH"); root:EnableMouse(false)
    for index = 1, 3 do pool[index] = CreateToast(index) end
    root:SetScript("OnUpdate", function(_, elapsed) addon:TickToasts(elapsed) end)
end

function addon:ShowLootToast(data)
    if not self.db or not self.db.lootToasts then return end
    EnsureRoot()
    root:Show()
    for index, entry in pairs(active) do
        if entry.data.key == data.key then
            entry.data.count = (entry.data.count or 1) + (data.count or 1)
            entry.life = 4.5; Render(pool[index], entry.data); return
        end
    end
    for _, pending in ipairs(queue) do
        if pending.key == data.key then pending.count = (pending.count or 1) + (data.count or 1); return end
    end
    -- Bounded queue protects against unbounded event storms. Chat still retains loot history.
    if #queue >= 50 then table.remove(queue, 1) end
    queue[#queue + 1] = data
end

function addon:RefreshToasts()
    if not self.db.lootToasts then
        wipe(queue); wipe(active)
        for _, frame in ipairs(pool) do frame:Hide() end
        if root then root:Hide() end
    elseif root then
        root:Show()
        for index, entry in pairs(active) do Render(pool[index], entry.data) end
    end
end

function addon:PreviewLootToasts()
    self:ShowLootToast({ key = "preview-herb", title = "Silverleaf", icon = 134190, count = 3 })
    self:ShowLootToast({ key = "preview-ore", title = "Copper Ore", icon = 134566, count = 2 })
end

local events = CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_LOOT")
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
events:SetScript("OnEvent", function(_, event, message)
    if not addon.db or not addon.db.lootToasts then return end
    if event == "CHAT_MSG_LOOT" then
        local ok, data = pcall(addon.ParseSelfLoot, addon, message)
        if ok and data then addon:ShowLootToast(data) end
    else
        for index, entry in pairs(active) do Render(pool[index], entry.data) end
    end
end)
