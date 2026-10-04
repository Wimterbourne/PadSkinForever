local _, addon = ...
local surfaces = setmetatable({}, { __mode = "k" })
local methods = { "SetAtlas", "SetTexture", "SetVertexColor", "SetDesaturation", "SetFont", "SetFontObject", "SetScale", "SetAlpha", "SetTextColor", "SetMaskTexture", "SetStatusBarTexture" }
local history = {}
local enabled = false

-- Never concatenate, format or compare secret values returned by native UI getters.
local function Display(value)
    if issecretvalue and issecretvalue(value) then return "[restricted]" end
    local ok, result = pcall(tostring, value)
    if not ok then return "[unavailable]" end
    if issecretvalue and issecretvalue(result) then return "[restricted]" end
    return result
end

local function Read(object, method)
    local ok, a, b, c = pcall(object[method], object)
    if not ok then return "[unavailable]", "[unavailable]", "[unavailable]" end
    return Display(a), Display(b), Display(c)
end

local function Install(object, entry)
    if entry.hooked then return end
    entry.hooked = true
    for _, method in ipairs(methods) do
        if type(object[method]) == "function" then
            hooksecurefunc(object, method, function()
                if not enabled then return end
                local source = (addon.applyingSkin and "[PadSkinForever visual refresh]\n" or "") .. Display(debugstack(3, 8, 0))
                entry.lastMethod, entry.lastSource = method, source
                table.insert(history, 1, entry.label .. ": " .. method .. "\n" .. source)
                if #history > 40 then table.remove(history) end
            end)
        end
    end
end

function addon:DebugSurface(object, label, kind)
    if not object then return end
    local entry = surfaces[object]
    if not entry then
        entry = { label = label, kind = kind }
        surfaces[object] = entry
    end
    if enabled then Install(object, entry) end
end

function addon:SetDebugTracing(value)
    enabled = value and true or false
    if enabled then
        for object, entry in pairs(surfaces) do Install(object, entry) end
    end
end

function addon:IsDebugTracing() return enabled end
function addon:ClearDebugHistory() wipe(history) end

local function Snapshot(object)
    local parts = {}
    for _, field in ipairs({ { "GetName", "name" }, { "GetAtlas", "atlas" },
        { "GetAlpha", "alpha" }, { "GetScale", "scale" } }) do
        if object[field[1]] then parts[#parts + 1] = field[2] .. "=" .. Read(object, field[1]) end
    end
    if object.GetFont then
        local path, size, flags = Read(object, "GetFont")
        parts[#parts + 1] = "font=" .. path .. " size=" .. size .. " flags=" .. flags
    end
    if object.GetVertexColor then
        local r, g, b = Read(object, "GetVertexColor")
        parts[#parts + 1] = "RGB=" .. r .. "/" .. g .. "/" .. b
    end
    return table.concat(parts, " | ")
end

function addon:GetDebugReport()
    local lines = { "PadSkinForever 0.8.1 alpha",
        "Tracing: " .. (enabled and "ON" or "OFF"),
        "Legend theming: " .. (self.db.skinLegend and "ON" or "OFF"),
        "Selected font: " .. self.db.font,
        "Snapshots show current values. Tracing observes future setter calls only.",
        "Call stacks show involved code; they are not proof of ownership or a conflict.",
        "Calls before tracing and unobserved/native changes cannot be attributed.", "", "SURFACES" }
    local entries = {}
    for object, entry in pairs(surfaces) do
        entries[#entries + 1] = entry.label .. " [" .. entry.kind .. "]\n" .. Snapshot(object)
    end
    table.sort(entries)
    for _, entry in ipairs(entries) do lines[#lines + 1] = entry end
    lines[#lines + 1] = "\nRECENT SETTER CALLS (maximum 40; newest first)"
    for _, entry in ipairs(history) do lines[#lines + 1] = entry end
    return table.concat(lines, "\n\n")
end
