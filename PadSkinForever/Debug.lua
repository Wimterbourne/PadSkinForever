local _, addon = ...
local surfaces = setmetatable({}, { __mode = "k" })
local methods = { "SetAtlas", "SetTexture", "SetVertexColor", "SetDesaturation", "SetFont", "SetFontObject", "SetScale", "SetAlpha", "SetTextColor", "SetMaskTexture", "SetStatusBarTexture" }
local history = {}
local enabled = false

local function Install(object, entry)
    if entry.hooked then return end
    entry.hooked = true
    for _, method in ipairs(methods) do
        if type(object[method]) == "function" then
            hooksecurefunc(object, method, function()
                if not enabled then return end
                local source = (addon.applyingSkin and "[PadSkinForever visual refresh]\n" or "") .. debugstack(3, 8, 0)
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
    if object.GetName then parts[#parts + 1] = "name=" .. (object:GetName() or "unnamed") end
    if object.GetAtlas then parts[#parts + 1] = "atlas=" .. tostring(object:GetAtlas()) end
    if object.GetFont then
        local path, size, flags = object:GetFont()
        parts[#parts + 1] = "font=" .. tostring(path) .. " size=" .. tostring(size) .. " flags=" .. tostring(flags)
    end
    if object.GetAlpha then parts[#parts + 1] = "alpha=" .. tostring(object:GetAlpha()) end
    if object.GetScale then parts[#parts + 1] = "scale=" .. string.format("%.2f", object:GetScale()) end
    if object.GetVertexColor then
        local r, g, b = object:GetVertexColor()
        parts[#parts + 1] = string.format("RGB=%.2f/%.2f/%.2f", r, g, b)
    end
    return table.concat(parts, " | ")
end

function addon:GetDebugReport()
    local lines = { "PadSkinForever 0.4.0 alpha",
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
