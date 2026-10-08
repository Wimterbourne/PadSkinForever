local _, addon = ...
local surfaces = setmetatable({}, { __mode = "k" })
local methods = { "SetAtlas", "SetTexture", "SetVertexColor", "SetDesaturation", "SetFont", "SetFontObject", "SetScale", "SetAlpha", "SetTextColor", "SetMaskTexture", "SetStatusBarTexture" }
local history = {}
local auraHistory = {}
local minimapHistory = {}
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
function addon:ClearDebugHistory() wipe(history); wipe(auraHistory) end

function addon:RecordTargetAuraDebug(entry)
    if type(entry) ~= "string" then return end
    table.insert(auraHistory, 1, entry)
    if #auraHistory > 16 then table.remove(auraHistory) end
end

local function ObjectType(object)
    if not object or not object.GetObjectType then return "[unknown]" end
    local ok, value = pcall(object.GetObjectType, object)
    return ok and Display(value) or "[unavailable]"
end

local function MinimapObjectLine(object, prefix)
    if not object then return nil end
    local parts = { prefix, "type=" .. ObjectType(object) }
    if object.GetName then parts[#parts + 1] = "name=" .. Read(object, "GetName") end
    if object.GetAtlas then parts[#parts + 1] = "atlas=" .. Read(object, "GetAtlas") end
    if object.GetTexture then parts[#parts + 1] = "texture=" .. Read(object, "GetTexture") end
    if object.GetAlpha then parts[#parts + 1] = "alpha=" .. Read(object, "GetAlpha") end
    if object.IsShown then parts[#parts + 1] = "shown=" .. Read(object, "IsShown") end
    if object.GetFrameLevel then parts[#parts + 1] = "level=" .. Read(object, "GetFrameLevel") end
    if object.GetFrameStrata then parts[#parts + 1] = "strata=" .. Read(object, "GetFrameStrata") end
    if object.GetDrawLayer then
        local layer, sublevel = Read(object, "GetDrawLayer")
        parts[#parts + 1] = "draw=" .. layer .. "/" .. sublevel
    end
    if object.GetText then parts[#parts + 1] = "text=" .. Read(object, "GetText") end
    if object.GetFont then
        local path, size, flags = Read(object, "GetFont")
        parts[#parts + 1] = "font=" .. path .. " size=" .. size .. " flags=" .. flags
    end
    if object.GetParent then
        local parent = object:GetParent()
        if parent and parent.GetName then parts[#parts + 1] = "parent=" .. Read(parent, "GetName") end
    end
    if object.GetPoint then
        local point, relativeTo, relativePoint, x, y = object:GetPoint(1)
        local relativeName = relativeTo and relativeTo.GetName and relativeTo:GetName() or tostring(relativeTo)
        parts[#parts + 1] = "point=" .. tostring(point) .. "/" .. tostring(relativeName) .. "/"
            .. tostring(relativePoint) .. "/" .. tostring(x) .. "/" .. tostring(y)
    end
    if object.GetSize then
        local width, height = object:GetSize()
        parts[#parts + 1] = "size=" .. tostring(width) .. "x" .. tostring(height)
    end
    return table.concat(parts, " | ")
end

function addon:CaptureMinimapDebug()
    wipe(minimapHistory)
    local roots = {
        { MinimapCluster, "MinimapCluster" },
        { Minimap, "Minimap" },
    }
    local seen = {}
    local function Walk(object, path, depth)
        if not object or seen[object] or depth > 3 then return end
        seen[object] = true
        local line = MinimapObjectLine(object, path)
        if line then minimapHistory[#minimapHistory + 1] = line end
        if object.GetRegions then
            local ok, regions = pcall(function() return { object:GetRegions() } end)
            if ok then
                for index, region in ipairs(regions) do
                    local regionLine = MinimapObjectLine(region, path .. "/region" .. index)
                    if regionLine then minimapHistory[#minimapHistory + 1] = regionLine end
                end
            end
        end
        if object.GetChildren then
            local ok, children = pcall(function() return { object:GetChildren() } end)
            if ok then
                for index, child in ipairs(children) do Walk(child, path .. "/child" .. index, depth + 1) end
            end
        end
    end
    for _, root in ipairs(roots) do Walk(root[1], root[2], 0) end
    -- Explicitly capture the three coordinate presentation layers so a single
    -- report distinguishes missing data from draw-order/frame-level problems.
    for _, named in ipairs({
        { _G["PadSkinForeverMinimapFooter"], "PSFCoordinate/footer" },
        { _G["PadSkinForeverMinimapCard"], "PSFCoordinate/card" },
    }) do
        local line = MinimapObjectLine(named[1], named[2])
        if line then minimapHistory[#minimapHistory + 1] = line end
        if named[1] and named[1].GetRegions then
            for index, region in ipairs({ named[1]:GetRegions() }) do
                local regionLine = MinimapObjectLine(region, named[2] .. "/region" .. index)
                if regionLine then minimapHistory[#minimapHistory + 1] = regionLine end
            end
        end
    end
    self:Print("Captured minimap diagnostics. Open /psf > Debug and copy the report.")
end


local gamepadHistory = {}

-- Inspect Blizzard-owned UI without reparenting or modifying any native glyph.
-- CharacterFrame and the currently visible controller legend are useful roots.
function addon:CaptureGamepadDebug()
    wipe(gamepadHistory)
    local seen, matches = {}, 0
    local function SafeShown(object)
        if not object then return false end
        local ok, shown = pcall(function()
            if object.IsForbidden and object:IsForbidden() then return false end
            return object.IsShown and object:IsShown()
        end)
        return ok and shown == true
    end
    local function SafeAccessible(object)
        if not object then return false end
        local ok, forbidden = pcall(function()
            return object.IsForbidden and object:IsForbidden()
        end)
        return ok and not forbidden
    end
    local function Walk(object, path, depth)
        if not SafeAccessible(object) or seen[object] or depth > 9 or matches >= 100 then return end
        seen[object] = true
        local name = object.GetName and Read(object, "GetName") or ""
        local atlas = object.GetAtlas and Read(object, "GetAtlas") or ""
        local texture = object.GetTexture and Read(object, "GetTexture") or ""
        local label = object.GetText and Read(object, "GetText") or ""
        local search = (name .. " " .. atlas .. " " .. texture .. " " .. label):lower()
        local hit = search:find("gamepad", 1, true) or search:find("shoulder", 1, true)
            or search:find("bumper", 1, true) or search:find("controller", 1, true)
            or search:find("padl", 1, true) or search:find("padr", 1, true)
            or label == "LB" or label == "RB"
        if hit then
            matches = matches + 1
            gamepadHistory[#gamepadHistory + 1] = MinimapObjectLine(object, path)
        end
        if object.GetRegions then
            local ok, regions = pcall(function() return { object:GetRegions() } end)
            if ok then
                for i, region in ipairs(regions) do Walk(region, path .. "/region" .. i, depth + 1) end
            end
        end
        if object.GetChildren then
            local ok, children = pcall(function() return { object:GetChildren() } end)
            if ok then
                for i, child in ipairs(children) do
                    if SafeShown(child) then
                        Walk(child, path .. "/child" .. i, depth + 1)
                    end
                end
            end
        end
    end
    local roots = { { _G.CharacterFrame, "CharacterFrame" },
                    { _G.PaperDollFrame, "PaperDollFrame" },
                    { _G.GamePadActionBar, "GamePadActionBar" } }
    for _, root in ipairs(roots) do Walk(root[1], root[2], 0) end
    -- The native legend can be parented outside CharacterFrame. Search visible
    -- top-level frames for gamepad-related names, but never descend all UIParent.
    if UIParent and UIParent.GetChildren then
        for _, child in ipairs({ UIParent:GetChildren() }) do
            if SafeShown(child) and child.GetName then
                local name = Read(child, "GetName"):lower()
                if name:find("gamepad") or name:find("controller") or name:find("legend") then
                    Walk(child, "UIParent/" .. name, 0)
                end
            end
        end
    end
    if #gamepadHistory == 0 then
        gamepadHistory[1] = "No named bumper glyphs found; native icons may use unnamed regions."
    end
    self:Print("Gamepad snapshot captured. Open /psf > Debug and copy the report.")
end

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
    local lines = { "PadSkinForever 0.9.9 alpha",
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
    lines[#lines + 1] = "\nMINIMAP SNAPSHOT"
    if #minimapHistory == 0 then lines[#lines + 1] = "No minimap snapshot captured yet. Use /psf minimapdebug." end
    for _, entry in ipairs(minimapHistory) do lines[#lines + 1] = entry end
    lines[#lines + 1] = "\nGAMEPAD GLYPH SNAPSHOT"
    if #gamepadHistory == 0 then lines[#lines + 1] = "Use /psf gamepaddebug with Character panel open." end
    for _, entry in ipairs(gamepadHistory) do lines[#lines + 1] = entry end
    lines[#lines + 1] = "\nTARGET AURA SCANS (maximum 16; newest first)"
    if #auraHistory == 0 then lines[#lines + 1] = "No target aura scan recorded yet." end
    for _, entry in ipairs(auraHistory) do lines[#lines + 1] = entry end
    lines[#lines + 1] = "\nRECENT SETTER CALLS (maximum 40; newest first)"
    for _, entry in ipairs(history) do lines[#lines + 1] = entry end
    return table.concat(lines, "\n\n")
end