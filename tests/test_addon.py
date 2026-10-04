"""Logic checks with Lua 5.1 mocks; these cannot reproduce WoW's taint model."""
from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
MOCKS = r'''
unpack = unpack or table.unpack
addon = {}
function wipe(t) for key in pairs(t) do t[key] = nil end end
function debugstack() return "[FontManager/FontManager.lua]:10: SetFont" end
C_Texture = { GetAtlasInfo = function(atlas) return { width = 24, height = 24 } end }
combat = false
messages = {}
timers = {}
frames = {}
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
SlashCmdList = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, text) table.insert(messages, text) end }
function InCombatLockdown() return combat end
C_Timer = { After = function(_, callback) table.insert(timers, callback) end }
function drain()
    local callbacks = timers
    timers = {}
    for _, callback in ipairs(callbacks) do callback() end
end
function CreateFrame()
    local frame = { events = {} }
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:SetScript(script, callback) self[script] = callback end
    table.insert(frames, frame)
    return frame
end
function fire(event, name) frames[1].OnEvent(frames[1], event, name) end
function hooksecurefunc(object, method, callback)
    local original = object[method]
    object[method] = function(self, ...)
        local result = original(self, ...)
        callback(self, ...)
        return result
    end
end
function forbidden() error("Protected interaction or binding call invoked") end
SetPreferredGamepadInteractTarget = forbidden
SetOverrideBinding = forbidden
SetOverrideBindingClick = forbidden
SetBinding = forbidden
legendVisible = true
cvarAllowed = true
function GetCVarBool() return legendVisible end
C_CVar = { SetCVar = function(_, value)
    if not cvarAllowed then return false end
    legendVisible = value == "1"
    return true
end }
function texture(atlas)
    local t = { atlas = atlas, rgba = {1, 1, 1, 0.8}, desaturation = 0 }
    function t:GetTexture() return self.file end
    function t:SetTexture(value) assert(not combat); self.file = value; self.atlas = nil end
    function t:GetTexCoord() return 0, 1, 0, 1 end
    function t:SetTexCoord(...) self.coords = {...} end
    function t:GetAtlas() return self.atlas end
    function t:SetAtlas(value) assert(not combat); self.atlas = value end
    function t:GetVertexColor() return unpack(self.rgba) end
    function t:GetDesaturation() return self.desaturation end
    function t:SetDesaturation(value) assert(not combat); self.desaturation = value end
    function t:SetVertexColor(...) assert(not combat); self.rgba = {...} end
    return t
end
function font()
    local f = { values = { STANDARD_TEXT_FONT, 12, "" } }
    function f:GetFont() return unpack(self.values) end
    function f:SetFont(...) assert(not combat); self.values = {...}; return true end
    return f
end
normal = texture("gamepad-xbox1-buttona-normal")
disabled = texture("gamepad-xbox1-buttona-disabled")
icon = { scale = 1, mappedButtonKey = "PAD1", DisabledTexture = disabled,
         textureStateTextures = {normal, disabled}, RefreshIconTextures = function() end }
icon.points = { {"TOPRIGHT", nil, "TOPRIGHT", 0, 0} }
function icon:GetNumPoints() return #self.points end
function icon:GetPoint(i) return unpack(self.points[i]) end
function icon:ClearAllPoints() assert(not combat); self.points = {} end
function icon:SetPoint(...) assert(not combat); table.insert(self.points, {...}) end
function icon:GetSize() return 20, 20 end
function icon:GetScale() return self.scale end
function icon:SetScale(scale) assert(not combat); self.scale = scale end
countdown = font()
button = { ButtonIcon = icon, SlotArt = texture("slot"),
           normal = texture("border"), pushed = texture("pushed"),
           cooldown = { GetCountdownFontString = function() return countdown end },
           SetShapeToCircle = function() end, SetShapeToSquare = function() end,
           UpdateEmptySlotBackgroundTexture = function() end, UpdateButtonArt = function() end }
function button:GetNormalTexture() return self.normal end
function button:GetPushedTexture() return self.pushed end
GamepadMainActionBarFrame = { PageUnit = { TopCenteredAnchor = { Bar = { Right = { ActionButton1 = button } } } } }
'''

THEME_MOCKS = r'''
UIParent = {}
uiwidgets = {}
local function Surface(kind, parent)
    local w = { kind = kind or "Frame", parent = parent, children = {}, regions = {}, alpha = 1,
        visible = true, scripts = {}, values = {STANDARD_TEXT_FONT, 12, ""}, color = {.2,.2,.2,1}, level = 5 }
    if parent and parent.children then table.insert(parent.children, w) end
    function w:GetRegions() return unpack(self.regions) end
    function w:GetChildren() return unpack(self.children) end
    function w:IsObjectType(value) return value == self.kind end
    function w:GetFrameLevel() return self.level end
    function w:SetFrameLevel(value) self.level = value end
    function w:SetToplevel(value) self.toplevel = value end
    function w:GetAlpha() return self.alpha end
    function w:SetAlpha(value) self.alpha = value end
    function w:SetSize(width, height) self.size = {width, height}; self.width = width; self.height = height end
    function w:SetWidth(value) self.width = value end
    function w:SetHeight(value) self.height = value end
    function w:GetWidth() return self.width or (self.size and self.size[1]) or 0 end
    function w:GetHeight() return self.height or (self.size and self.size[2]) or 0 end
    function w:GetScale() return self.scale or 1 end
    function w:GetCenter() return unpack(self.center or {0, 0}) end
    function w:SetPoint(...) self.point = {...}; self.clearCount = self.clearCount or 0 end
    function w:GetPoint() return unpack(self.point or {}) end
    function w:ClearAllPoints() self.point = nil; self.clearCount = (self.clearCount or 0) + 1 end
    function w:SetAllPoints() self.allPoints = true end
    function w:EnableMouse(value) self.mouse = value end
    function w:SetBackdrop(value) self.backdrop = value end
    function w:SetBackdropColor(...) self.bg = {...} end
    function w:SetBackdropBorderColor(...) self.border = {...} end
    function w:SetFrameStrata(value) self.strata = value end
    function w:SetScript(key, value) self.scripts[key] = value end
    function w:HookScript(key, value) self.scripts[key] = value end
    function w:SetShown(value) self.visible = value end
    function w:IsShown() return self.visible end
    function w:Show() self.visible = true end
    function w:Hide() self.visible = false end
    function w:SetTexture(value) self.file = value; self.atlas = nil end
    function w:GetTexture() return self.file end
    function w:SetAtlas(value) self.atlas = value end
    function w:GetAtlas() return self.atlas end
    function w:SetTexCoord(...) self.coords = {...} end
    function w:GetTexCoord() return unpack(self.coords or {0,1,0,1}) end
    function w:SetVertexColor(...) self.rgba = {...} end
    function w:GetVertexColor() return unpack(self.rgba or {1,1,1,1}) end
    function w:SetDesaturation(value) self.desaturation = value end
    function w:GetDesaturation() return self.desaturation or 0 end
    function w:GetFont() return unpack(self.values) end
    function w:SetFont(...) self.values = {...}; return true end
    function w:GetTextColor() return unpack(self.color) end
    function w:SetTextColor(...) self.color = {...} end
    function w:SetText(value) self.text = value end
    function w:SetJustifyH(value) self.justify = value end
    function w:SetClampedToScreen(value) self.clamped = value end
    function w:SetMovable(value) self.movable = value end
    function w:RegisterForDrag(...) self.dragButtons = {...} end
    function w:StartMoving() self.moving = true end
    function w:StopMovingOrSizing() self.moving = false end
    function w:CreateFontString()
        local region = Surface("FontString"); table.insert(self.regions, region); return region
    end
    function w:CreateTexture()
        local region = Surface("Texture"); table.insert(self.regions, region); return region
    end
    function w:GetStatusBarTexture() return self.barTexture end
    function w:SetStatusBarTexture(value)
        if not self.barTexture then self.barTexture = Surface("Texture"); table.insert(self.regions, self.barTexture) end
        self.barTexture:SetTexture(value)
    end
    function w:SetStatusBarColor(...) self.barColor = {...} end
    function w:GetStatusBarColor() return unpack(self.barColor or {1,1,1,1}) end
    function w:SetMinMaxValues(minimum, maximum) self.minimum, self.maximum = minimum, maximum end
    function w:SetValue(value) self.value = value end
    table.insert(uiwidgets, w)
    return w
end
surface = Surface
CreateFrame = function(_, name, parent)
    local frame = Surface("Frame", parent)
    if name then _G[name] = frame end
    return frame
end
'''

LEGEND_MOCKS = r'''
local function Widget(kind, parent)
    local w = surface(kind, parent)
    w.points = {}; w.width = 18; w.height = 18; w.scale = 1
    function w:GetSize() return self.width, self.height end
    function w:GetNumPoints() return #self.points end
    function w:GetPoint(i) return unpack(self.points[i]) end
    function w:ClearAllPoints() self.points = {} end
    function w:SetPoint(...) self.points[#self.points + 1] = {...} end
    function w:SetSize(x, y) self.width = x; self.height = y end
    function w:SetWidth(x) self.width = x end
    function w:SetHeight(y) self.height = y end
    function w:GetScale() return self.scale end
    function w:SetScale(value) self.scale = value end
    function w:SetAllPoints() end
    function w:GetStringHeight() return self.values[2] end
    function w:GetStringWidth() return #(self.text or "Native label") * self.values[2] * .5 end
    function w:RefreshIconTextures() end
    function w:CreateTexture() return Widget("Texture", self) end
    function w:CreateFontString() return Widget("FontString", self) end
    return w
end
CreateFrame = function(_, _, parent) return Widget("Frame", parent) end
GamepadMainActionBarFrame = nil
legend = Widget("Frame")
function legend:GetColumnWidth() return 300 end
function legend:DoesGroupUseHeader() return self.header or false end
function legend:ShowGroup() end
background = Widget("Frame", legend); background:SetSize(320, 130)
background:SetPoint("TOPLEFT", legend, "TOPLEFT", 0, 0)
background.Background = Widget("Frame", background)
background.HeaderTrim = Widget("Texture", background)
function Entry(col, row, key, label)
    local frame = Widget("Frame", legend)
    frame:SetSize(150, 18)
    frame:SetPoint("TOPLEFT", legend, "TOPLEFT", 20 + col * 300, -20 - row * 24 - (legend.header and row > 0 and 10 or 0))
    frame.InputIcon1 = Widget("Frame", frame); frame.InputIcon1.mappedButtonKey = key
    frame.InputIcon1:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.ControlDescText = Widget("Frame", frame)
    frame.ControlDescText:SetPoint("LEFT", frame.InputIcon1, "RIGHT", 4, 0)
    frame.ControlDescText.FontString = Widget("FontString", frame.ControlDescText)
    frame.ControlDescText.FontString:SetText(label)
    function frame:SetPromptText(value) self.ControlDescText.FontString:SetText(value) end
    return frame
end
entry1 = Entry(0, 0, "PAD1", "First")
entry2 = Entry(0, 1, "PADDUP", "Second")
legend.groups = { GAMEPLAY = { background, entry1, entry2 } }
GamepadPersistentInputLegend = legend
'''


class AddonTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCKS)
        for name in ("Core.lua", "Fonts.lua", "UI.lua", "Debug.lua", "Glyphs.lua", "Buttons.lua", "Theme.lua", "CombatHUD.lua", "Toasts.lua", "Legend.lua", "Skin.lua", "Options.lua", "GameMenu.lua"):
            source = (ROOT / "PadSkinForever" / name).read_text()
            self.lua.execute('assert(loadstring(...))("PadSkinForever", addon)', source)
        self.lua.execute('fire("ADDON_LOADED", "PadSkinForever"); drain()')

    def check(self, source):
        self.lua.execute(source)

    def legend_setup(self):
        self.lua.execute(THEME_MOCKS)
        self.lua.execute(LEGEND_MOCKS)

    def test_legend_rows_resize_without_drift_and_restore(self):
        self.legend_setup()
        self.check('''
            entry2.ControlDescText:SetAlpha(.5)
            addon.db.faceGlyphScale = 2
            addon.db.dpadGlyphScale = .5
            addon:QueueRefresh(); drain()
            local firstY = entry1.points[1][5]
            assert(entry2.points[1][5] == firstY - 36 - addon.db.legendRowGap)
            local height = background.height
            addon:QueueRefresh(); drain()
            assert(background.height == height and entry1.points[1][5] == firstY)
            addon.db.faceGlyphScale = .5; addon:QueueRefresh(); drain()
            assert(background.height < height)
            assert(entry2.ControlDescText.alpha == .5)
            addon.db.skinLegend = false; addon:QueueRefresh(); drain()
            assert(background.width == 320 and background.height == 130)
            assert(background.Background.alpha == 1 and background.HeaderTrim.alpha == 1)
            assert(entry1.points[1][4] == 20 and entry2.points[1][5] == -44)
            assert(entry1.InputIcon1.scale == 1)
            assert(entry2.ControlDescText.alpha == .5)
            addon.db.skinLegend = true; addon:QueueRefresh(); drain()
            assert(background.height < height and background.Background.alpha == 0)
        ''')

    def test_legend_border_edges_have_explicit_one_unit_thickness(self):
        self.legend_setup()
        self.check(r'''
            addon:QueueRefresh(); drain()
            local panel = background.children[#background.children]
            local edges = 0
            for _, region in ipairs(panel.children) do
                if region.file == "Interface\\Buttons\\WHITE8X8" and region.rgba and region.rgba[1] == .40 then
                    edges = edges + 1
                    assert(region.width == 1 or region.height == 1)
                    local a, b = region.points[1], region.points[2]
                    if region.height == 1 then assert(a[5] == b[5]) end
                    if region.width == 1 then assert(a[4] == b[4]) end
                end
            end
            assert(edges == 4)
        ''')

    def test_legend_two_icon_header_does_not_indent_body_labels(self):
        self.legend_setup()
        self.check('''
            legend.header = true
            local header = Entry(0, 0, "PADLSHOULDER", "Shortcut actions")
            header.InputIcon2 = CreateFrame("Frame", nil, header)
            header.InputIcon2:SetPoint("LEFT", header.InputIcon1, "RIGHT", 4, 0)
            header.InputIcon2.mappedButtonKey = "PADRSHOULDER"
            header.IconDivider1 = CreateFrame("Frame", nil, header)
            header.IconDivider1:SetSize(16, 16)
            header.IconDivider1:SetPoint("LEFT", header.InputIcon1, "RIGHT", 4, 0)
            local left = Entry(0, 1, "PADDUP", "Next action page")
            legend.groups.GAMEPLAY = {background, header, left}
            addon:QueueRefresh(); drain()
            assert(header.ControlDescText.points[1][4] == 18 + 16 + 18 + 10 + 12)
            assert(left.ControlDescText.points[1][4] == 18 + 12)
            assert(header.ControlDescText.points[1][4] > left.ControlDescText.points[1][4])
        ''')

    def test_legend_global_size_scales_shoulders_and_combines_face_setting(self):
        self.legend_setup()
        self.check('''
            entry1.InputIcon1.mappedButtonKey = "PADLSHOULDER"
            addon.db.legendGlyphScale = 1.5
            addon.db.dpadGlyphScale = 2
            addon:QueueRefresh(); drain()
            assert(entry1.InputIcon1.scale == 1.5 and entry2.InputIcon1.scale == 3)
            assert(entry2.height == 54)
            addon.db.skinLegend = false; addon:QueueRefresh(); drain()
            assert(entry1.InputIcon1.scale == 1 and entry2.InputIcon1.scale == 1)
        ''')

    def test_legend_columns_two_icons_headers_and_text_changes(self):
        self.legend_setup()
        self.check('''
            legend.header = true
            local header = Entry(0, 0, "PAD1", "Friendly targeting")
            local left = Entry(0, 1, "PADDUP", "Target group")
            local right = Entry(1, 1, "PAD4", "Target marker")
            right.InputIcon2 = CreateFrame("Frame", nil, right)
            right.InputIcon2:SetPoint("LEFT", right.InputIcon1, "RIGHT", 4, 0)
            right.InputIcon2.mappedButtonKey = "PAD2"
            right.IconDivider1 = CreateFrame("Frame", nil, right)
            right.IconDivider1:SetSize(16, 16)
            right.IconDivider1:SetPoint("LEFT", right.InputIcon1, "RIGHT", 4, 0)
            legend.groups.GAMEPLAY = { background, header, left, right }
            addon.db.faceGlyphScale = 2; addon.db.dpadGlyphScale = .5
            addon:QueueRefresh(); drain()
            assert(left.points[1][5] == right.points[1][5])
            assert(right.ControlDescText.points[1][4] >= 36 + 16 + 36 + 10 + 12)
            assert(left.points[1][5] < header.points[1][5] - 36)
            local width = background.width
            right:SetPromptText("A much longer localized contextual legend label"); drain()
            assert(background.width > width)
            assert(background.Background.alpha == 0)
        ''')

    def test_legend_layout_and_settings_defer_during_combat(self):
        self.legend_setup()
        self.check('''
            addon:QueueRefresh(); drain()
            local height = background.height
            combat = true; addon.db.faceGlyphScale = 2; addon.db.legendRowGap = 20
            addon:QueueRefresh(); drain()
            assert(background.height == height)
            combat = false; fire("PLAYER_REGEN_ENABLED"); drain()
            assert(background.height > height)
        ''')

    def test_bundled_inter_is_available_without_libraries(self):
        self.check(r'''
            LibStub = nil; FontManagerDB = nil
            local fonts = addon:GetFonts()
            assert(fonts["PSF Inter Regular"] == "Interface\\AddOns\\PadSkinForever\\Media\\Fonts\\Inter-Regular.ttf")
            addon.db.font = "PSF Inter Regular"
            addon:QueueRefresh(); drain()
            assert(countdown.values[1] == fonts["PSF Inter Regular"])
            assert(addon:GetLegendHeaderFontPath() == fonts["PSF Inter SemiBold"])
            addon.db.font = "Blizzard default"
            assert(addon:GetLegendHeaderFontPath() == STANDARD_TEXT_FONT)
        ''')

    def test_bundled_inter_registers_when_shared_media_loads_late(self):
        self.check('''
            local media = { fonts = {}, registrations = 0 }
            function media:List() local names = {}; for name in pairs(self.fonts) do names[#names+1] = name end; return names end
            function media:Fetch(_, name) return self.fonts[name] end
            function media:Register(kind, name, path)
                assert(kind == "font"); self.fonts[name] = path
                self.registrations = self.registrations + 1
                self.callback("LibSharedMedia_Registered", kind, name)
            end
            function media.RegisterCallback(_, _, callback) media.callback = callback end
            LibStub = function() return media end
            addon:QueueRefresh(); drain(); drain()
            assert(media.fonts["PSF Inter Regular"] and media.fonts["PSF Inter SemiBold"])
            addon:QueueRefresh(); drain()
            assert(media.registrations == 2)
        ''')

    def test_minimal_assets_and_native_restore(self):
        self.check('''
            assert(button.normal.file:find("SquareBorder", 1, true))
            assert(button.SlotArt.file:find("SquareEmpty", 1, true))
            addon.db.buttonStyle = "native"; addon:QueueRefresh(); drain()
            assert(button.normal:GetAtlas() == "border")
            assert(button.SlotArt:GetAtlas() == "slot")
            button.CircleMask = { IsShown = function() return true end }
            addon.db.buttonStyle = "minimal"; addon:QueueRefresh(); drain()
            assert(button.normal.file:find("CircleBorder", 1, true))
        ''')

    def test_minimal_restores_latest_native_shape_and_alpha(self):
        self.check('''
            local decoration = { alpha = .8 }
            function decoration:GetAlpha() return self.alpha end
            function decoration:SetAlpha(value) self.alpha = value end
            button.Border = decoration
            addon:QueueRefresh(); drain(); assert(decoration.alpha == 0)
            button.normal:SetAtlas("new-native-circle")
            button.CircleMask = { IsShown = function() return true end }
            button:SetShapeToCircle(); drain()
            addon.db.skinButtons = false; addon:QueueRefresh(); drain()
            assert(button.normal:GetAtlas() == "new-native-circle")
            assert(decoration.alpha == .8)
        ''')

    def test_outside_glyph_anchors_restore_and_native_update(self):
        self.check('''
            assert(icon.points[1][1] == "TOPRIGHT" and icon.points[1][4] == 0)
            addon.db.faceGlyphScale = 2; addon:QueueRefresh(); drain()
            assert(icon.points[1][4] == 10 and icon.points[1][5] == 10)
            addon.db.glyphOutside = false; addon:QueueRefresh(); drain()
            assert(icon.points[1][1] == "TOPRIGHT")
            icon:ClearAllPoints(); icon:SetPoint("LEFT", button, "RIGHT", 7, 3); drain()
            addon.db.glyphOutside = true; addon:QueueRefresh(); drain()
            addon.db.glyphOutside = false; addon:QueueRefresh(); drain()
            assert(icon.points[1][1] == "LEFT" and icon.points[1][4] == 7)
            assert(#timers == 0)
        ''')

    def test_glyph_growth_follows_all_native_anchor_directions(self):
        self.check('''
            local directions = { LEFT = {-1, 0}, RIGHT = {1, 0}, TOP = {0, 1}, BOTTOM = {0, -1}, TOPRIGHT = {1, 1} }
            addon.db.glyphOutside = false; addon:QueueRefresh(); drain()
            for point, direction in pairs(directions) do
                icon:ClearAllPoints(); icon:SetPoint(point, button, point, -1, -3); drain()
                addon.db.faceGlyphScale = 1.5; addon.db.glyphOutside = true
                addon:QueueRefresh(); drain()
                assert(icon.points[1][1] == point)
                assert(math.abs(icon.points[1][4] - (-1 + direction[1] * 10)/1.5) < .001)
                assert(math.abs(icon.points[1][5] - (-3 + direction[2] * 10)/1.5) < .001)
                addon.db.glyphOutside = false; addon:QueueRefresh(); drain()
                assert(icon.points[1][4] == -1 and icon.points[1][5] == -3)
            end
        ''')

    def test_minimal_border_palette_and_neutral_slots(self):
        self.check('''
            for key, color in pairs(addon.xboxColors) do
                icon.mappedButtonKey = key; addon:QueueRefresh(); drain()
                for channel = 1, 3 do assert(button.normal.rgba[channel] == color[channel]) end
                assert(button.SlotArt.rgba[1] == 1 and button.SlotArt.rgba[2] == 1)
            end
            icon.mappedButtonKey = "PADDUP"; addon:QueueRefresh(); drain()
            assert(button.normal.rgba[1] == .65 and button.normal.rgba[2] == .68 and button.normal.rgba[3] == .72)
            addon.db.buttonStyle = "native"; addon:QueueRefresh(); drain()
            assert(button.normal.rgba[1] == addon.db.accent[1])
        ''')

    def test_vivid_glyph_alpha_toggle_and_native_restore(self):
        self.check('''
            assert(normal.rgba[4] == 1 and disabled.rgba[4] == 1)
            addon.db.vividGlyphs = false; addon:QueueRefresh(); drain()
            assert(normal.rgba[4] == .8)
            addon.db.vividGlyphs = true; addon.db.faceGlyphStyle = "native"
            addon:QueueRefresh(); drain()
            assert(normal.rgba[4] == .8 and normal.rgba[1] == 1)
        ''')

    def test_square_minimap_real_mask_and_restoration(self):
        self.lua.execute(THEME_MOCKS)
        self.check('''
            Minimap = surface(); Minimap.mask = "native-circle"
            function Minimap:SetMaskTexture(value) self.mask = value end
            MinimapCompassTexture = surface("Texture")
            function MinimapCompassTexture:SetVertexColor(r,g,b,a)
                self.rgba = {r,g,b,a}; self.alpha = a
            end
            addon:QueueRefresh(); drain()
            assert(Minimap.mask:find("WHITE8X8", 1, true))
            assert(MinimapCompassTexture.alpha == 0)
            Minimap:SetMaskTexture("updated-native-circle"); drain()
            assert(Minimap.mask:find("WHITE8X8", 1, true))
            addon.db.squareMinimap = false; addon:QueueRefresh(); drain()
            assert(Minimap.mask == "updated-native-circle")
            assert(MinimapCompassTexture.alpha == 1)
            assert(MinimapCompassTexture.rgba[1] == .65)
            addon.db.squareMinimap = true; addon:QueueRefresh(); drain()
            assert(MinimapCompassTexture.alpha == 0)
            assert(Minimap.mask:find("WHITE8X8", 1, true))
            addon.db.squareMinimap = false; addon:QueueRefresh(); drain()
            addon:QueueRefresh(); drain()
            assert(MinimapCompassTexture.alpha == 1)
            addon.db.themeMinimap = false; addon:QueueRefresh(); drain()
            assert(MinimapCompassTexture.rgba[1] == 1)
        ''')

    def test_quest_details_and_border_skin_do_not_touch_map_canvas(self):
        self.lua.execute(THEME_MOCKS)
        self.check('''
            WorldMapFrame = surface()
            WorldMapFrame.BorderFrame = surface(nil, WorldMapFrame)
            WorldMapFrame.BorderFrame.NineSlice = surface(nil, WorldMapFrame.BorderFrame)
            WorldMapFrame.ScrollContainer = surface(nil, WorldMapFrame)
            local mapText = WorldMapFrame.ScrollContainer:CreateFontString()
            QuestMapFrame = surface()
            QuestMapFrame.QuestsFrame = surface(nil, QuestMapFrame)
            local quests = QuestMapFrame.QuestsFrame
            quests.ScrollFrame = surface(nil, quests)
            quests.ScrollFrame.BorderFrame = surface(nil, quests.ScrollFrame)
            quests.DetailsFrame = surface(nil, quests)
            quests.DetailsFrame.Bg = surface("Texture", quests.DetailsFrame)
            local description = quests.DetailsFrame:CreateFontString()
            local click = function() end
            quests.DetailsFrame.scripts.OnClick = click
            addon:QueueRefresh(); drain()
            assert(WorldMapFrame.BorderFrame.NineSlice.alpha == 0)
            for _, child in ipairs(WorldMapFrame.BorderFrame.children) do
                if child.backdrop then assert(child.backdrop.bgFile == nil) end
            end
            assert(quests.ScrollFrame.BorderFrame.alpha == 0)
            assert(quests.DetailsFrame.Bg.alpha == 0)
            assert(description.color[1] == .94)
            assert(mapText.color[1] == .2 and WorldMapFrame.ScrollContainer.alpha == 1)
            assert(quests.DetailsFrame.scripts.OnClick == click)
            addon.db.themeQuests = false; addon:QueueRefresh(); drain()
            assert(quests.DetailsFrame.Bg.alpha == 1)
            assert(WorldMapFrame.BorderFrame.NineSlice.alpha == 1)
            assert(description.color[1] == .2)
        ''')

    def test_theme_font_panel_and_full_restore(self):
        self.lua.execute(THEME_MOCKS)
        self.check('''
            QuestLogFrame = surface()
            QuestLogFrame.Background = surface("Texture")
            local title = QuestLogFrame:CreateFontString()
            local originalClick = function() end
            QuestLogFrame.scripts.OnClick = originalClick
            addon:QueueRefresh(); drain()
            assert(QuestLogFrame.Background.alpha == 0)
            assert(title.color[1] == .94)
            assert(QuestLogFrame.scripts.OnClick == originalClick)
            addon.db.themeQuests = false; addon:QueueRefresh(); drain()
            assert(QuestLogFrame.Background.alpha == 1 and title.color[1] == .2)
            assert(QuestLogFrame.children[1].visible == false)
        ''')

    def test_unitbar_texture_restore_preserves_values_and_portrait(self):
        self.lua.execute(THEME_MOCKS)
        self.check('''
            local bar = surface("StatusBar"); bar.barTexture = surface("Texture")
            bar.barTexture.atlas = "health-atlas"; bar.barTexture.file = 123
            bar.value = 376
            PlayerFrame = surface()
            PlayerFrame.PlayerFrameContainer = surface("Frame", PlayerFrame)
            local container = PlayerFrame.PlayerFrameContainer
            container.FrameTexture = surface("Texture")
            container.PlayerPortrait = surface("Texture")
            container.PlayerPortrait.file = "portrait"
            PlayerFrame.PlayerFrameContent = surface("Frame", PlayerFrame)
            PlayerFrame.PlayerFrameContent.PlayerFrameContentMain = { HealthBarsContainer = {HealthBar = bar} }
            addon:QueueRefresh(); drain()
            assert(bar.barTexture.file:find("WHITE8X8", 1, true))
            assert(bar.value == 376 and container.PlayerPortrait.file == "portrait")
            addon.db.themeUnits = false; addon:QueueRefresh(); drain()
            assert(bar.barTexture.atlas == "health-atlas" and bar.value == 376)
            assert(container.FrameTexture.alpha == 1)
        ''')

    def test_loot_parser_self_quantity_and_localized_reorder(self):
        self.check('''
            local link = "|cffffffff|Hitem:2770:0|h[Copper Ore]|h|r"
            LOOT_ITEM_SELF = "You receive loot: %s."
            LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %sx%d."
            local item = addon:ParseSelfLoot("You receive loot: " .. link .. "x4.")
            assert(item.link == link and item.count == 4)
            assert(addon:ParseSelfLoot("Otherplayer receives loot: " .. link .. ".") == nil)
            LOOT_ITEM_SELF_MULTIPLE = "Reçu %2$d exemplaires de %1$s."
            item = addon:ParseSelfLoot("Reçu 3 exemplaires de " .. link .. ".")
            assert(item.link == link and item.count == 3)
        ''')

    def test_toast_merge_expiry_disable_and_gathering_event(self):
        self.lua.execute(THEME_MOCKS)
        self.check('''
            C_Item = {GetItemInfo = function() return "Copper Ore", nil, 1, nil, nil, nil, nil, nil, nil, 134566 end}
            ITEM_QUALITY_COLORS = {[1] = {r=1,g=1,b=1}}
            local link = "|cffffffff|Hitem:2770:0|h[Copper Ore]|h|r"
            LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %sx%d."
            local lootEvents
            for _, frame in ipairs(frames) do
                if frame.events.CHAT_MSG_LOOT then lootEvents = frame end
            end
            assert(lootEvents)
            lootEvents.OnEvent(lootEvents, "CHAT_MSG_LOOT", "You receive loot: " .. link .. "x2.")
            addon:TickToasts(.1)
            local visibleToast
            for _, w in ipairs(uiwidgets) do if w.icon and w.visible then visibleToast = w end end
            assert(visibleToast and visibleToast.title.text == "Copper Ore")
            addon:ShowLootToast({link=link,key=link,count=3})
            assert(visibleToast.count.text == "×5")
            addon:TickToasts(5); assert(not visibleToast.visible)
            addon:PreviewLootToasts(); addon:TickToasts(.1)
            addon.db.lootToasts = false; addon:RefreshToasts()
            for _, w in ipairs(uiwidgets) do if w.icon then assert(not w.visible) end end
        ''')

    def test_native_loot_click_untouched_and_skin_restore(self):
        self.lua.execute(THEME_MOCKS)
        self.check('''
            LootFrame = surface(); LootFrame.Background = surface("Texture")
            local row = surface(); row.NameFrame = texture("loot-bg"); row.NameFrame.alpha = .9
            function row.NameFrame:GetAlpha() return self.alpha end
            function row.NameFrame:SetAlpha(value) self.alpha = value end
            local click = function() error("Native click should not run during skinning") end
            row.Item = { OnClick = click }
            LootFrame.ScrollBox = {ForEachFrame = function(_, callback) callback(row) end}
            addon:QueueRefresh(); drain()
            assert(row.Item.OnClick == click and row.NameFrame.alpha == 0)
            addon.db.themeLoot = false; addon:QueueRefresh(); drain()
            assert(row.NameFrame.alpha == .9 and row.Item.OnClick == click)
        ''')

    def test_xbox_colors_and_disabled_feedback(self):
        self.check('''
            assert(normal.rgba[1] == 0.12 and normal.rgba[2] == 1)
            assert(normal.rgba[4] == 1)
            assert(disabled.rgba[1] < normal.rgba[1] and disabled.desaturation == 1)
            icon.mappedButtonKey = "PAD2"
            icon:RefreshIconTextures(); drain()
            assert(normal.rgba[1] == 1 and normal.rgba[2] == 0.12)
            addon.db.faceGlyphStyle = "native"
            normal.atlas = "gamepad-ps4-cross-normal"
            icon:RefreshIconTextures(); drain()
            assert(normal.rgba[1] == 1 and normal.desaturation == 0)
        ''')

    def test_disable_restores_original_visual_properties(self):
        self.check('''
            addon.db.skinButtons = false; addon.db.faceGlyphStyle = "native"
            addon.db.cooldownFont = false
            addon:QueueRefresh(); drain()
            assert(button.normal.rgba[1] == 1 and button.normal.desaturation == 0)
            assert(normal.rgba[1] == 1 and normal.desaturation == 0)
            assert(countdown.values[2] == 12 and countdown.values[3] == "")
        ''')

    def test_combat_deferral_including_already_scheduled_work(self):
        self.check('''
            addon.db.fontSize = 22; addon:QueueRefresh()
            combat = true; drain()
            assert(countdown.values[2] == 18)
            assert(not addon:ToggleLegend() and legendVisible)
            icon:RefreshIconTextures(); assert(#timers == 0)
            combat = false; fire("PLAYER_REGEN_ENABLED"); drain()
            assert(countdown.values[2] == 22)
        ''')

    def test_fontmanager_otf_without_shared_media(self):
        self.check(r'''
            FontManagerDB = { userFonts = { "FOT-Rodin Pro DB.otf" } }
            addon.db.font = "FOT-Rodin Pro DB"
            addon:QueueRefresh(); drain()
            assert(countdown.values[1] == "Interface\\AddOns\\FontManager\\Fonts\\FOT-Rodin Pro DB.otf")
            addon.db.font = "Missing font"; addon:QueueRefresh(); drain()
            assert(countdown.values[1] == STANDARD_TEXT_FONT)
        ''')

    def test_optional_fontmanager_placeholder_is_not_offered(self):
        self.check(r'''
            FontManager_Files = { { name = "Custom", file = "Custom.ttf" } }
            FontManagerDB = { userFonts = { "FOT-Rodin Pro DB.otf" } }
            local fonts = addon:GetFonts()
            assert(fonts.Custom == nil)
            assert(fonts["FOT-Rodin Pro DB"] ~= nil)
        ''')

    def test_shared_media_font_added_after_login(self):
        self.check('''
            local media = { fonts = {} }
            function media:List() local names = {}; for name in pairs(self.fonts) do names[#names+1] = name end; return names end
            function media:Fetch(_, name) return self.fonts[name] end
            function media.RegisterCallback(target, event, callback)
                assert(target == addon and event == "LibSharedMedia_Registered")
                media.callback = callback
            end
            LibStub = function() return media end
            fire("ADDON_LOADED", "AnotherAddon"); drain()
            media.fonts.Custom = "Fonts/Custom.otf"
            addon.db.font = "Custom"
            media.callback("LibSharedMedia_Registered", "font", "Custom"); drain()
            assert(countdown.values[1] == "Fonts/Custom.otf")
        ''')

    def test_independent_glyph_scale_and_style(self):
        self.check('''
            addon.db.faceGlyphScale = 1.8
            addon.db.dpadGlyphScale = .7
            addon.db.dpadGlyphStyle = "xboxAccent"
            addon:QueueRefresh(); drain()
            assert(icon:GetScale() == 1.8)
            icon.mappedButtonKey = "PADDUP"
            icon:RefreshIconTextures(); drain()
            assert(icon:GetScale() == .7)
            assert(normal:GetAtlas() == "gamepad-xbox1-dpadup-normal")
            assert(normal.rgba[1] == addon.db.accent[1])
        ''')

    def test_legend_theme_off_restores_glyphs(self):
        self.check('''
            GamepadMainActionBarFrame = nil
            addon.db.faceGlyphScale = 1.8
            GamepadPersistentInputLegend = { groups = { HUD = { { InputIcon1 = icon } } } }
            addon:QueueRefresh(); drain()
            assert(icon:GetScale() == 1.8)
            addon.db.skinLegend = false; addon:QueueRefresh(); drain()
            assert(icon:GetScale() == 1)
            assert(normal.rgba[1] == 1)
            icon:SetScale(1.4); normal:SetVertexColor(.8, .6, .4, 1)
            addon:QueueRefresh(); drain()
            assert(icon:GetScale() == 1.4 and normal.rgba[1] == .8)
        ''')

    def test_debug_tracing_is_opt_in_and_bounded(self):
        self.check('''
            normal:SetVertexColor(.1, .2, .3, 1)
            assert(not addon:GetDebugReport():find("FontManager.lua"))
            addon:SetDebugTracing(true)
            for i = 1, 100 do normal:SetVertexColor(.1, .2, .3, 1) end
            local report = addon:GetDebugReport()
            assert(report:find("FontManager.lua"))
            assert(report:find("SetVertexColor"))
            local _, count = report:gsub("FontManager.lua", "")
            assert(count == 40)
            addon:SetDebugTracing(false)
            addon:ClearDebugHistory()
            normal:SetVertexColor(.3, .2, .1, 1)
            assert(not addon:GetDebugReport():find("FontManager.lua"))
        ''')

    def test_debug_redacts_secret_getters_before_string_conversion(self):
        self.check(r'''
            local secret = setmetatable({}, { __tostring = function() error("Secret converted") end })
            function issecretvalue(value) return rawequal(value, secret) end
            local object = {
                GetName = function() return "RestrictedSurface" end,
                GetAlpha = function() return secret end,
                GetScale = function() error("Unavailable getter") end,
                GetFont = function() return secret, 18, "OUTLINE" end,
                GetVertexColor = function() return .5, secret, .8 end,
            }
            addon:DebugSurface(object, "Restricted test", "test")
            local report = addon:GetDebugReport()
            assert(report:find("alpha=%[restricted%]"))
            assert(report:find("scale=%[unavailable%]"))
            assert(report:find("font=%[restricted%] size=18 flags=OUTLINE"))
            assert(report:find("RestrictedSurface"))
        ''')

    def test_options_cannot_open_during_combat(self):
        self.check('''
            combat = true
            addon:ShowOptions()
            assert(messages[#messages]:find("after combat"))
        ''')

    def test_options_tabs_build_and_open(self):
        self.check('''
            widgets = {}
            namedWidgets = {}
            local function widget(frameType, name, parent, template)
                local w = { scripts = {}, events = {}, visible = true, text = "", frameType = frameType,
                    name = name, parent = parent, template = template, attrs = {}, width = 100, height = 28 }
                function w:RegisterEvent(event) self.events[event] = true end
                function w:IsShown() return self.visible end
                function w:IsVisible() return self.visible and (not self.parent or not self.parent.IsVisible or self.parent:IsVisible()) end
                function w:IsEnabled() return self.enabled ~= false end
                function w:SetPoint(_, a, b, c, d)
                    self.anchorTarget = type(a) == "table" and a or nil
                    if type(a) == "number" then self.x, self.y = a, b
                    else self.x, self.y = c or 0, d or 0 end
                end
                function w:GetCenter() return 500 + (self.x or 0) + self.width / 2, 500 + (self.y or 0) - self.height / 2 end
                function w:SetSize(width, height) self.width, self.height = width, height end
                function w:SetWidth(width) self.width = width end
                function w:SetHeight(height) self.height = height end
                function w:GetHeight() return self.height end
                function w:SetVerticalScroll(value) self.scroll = value end
                function w:GetVerticalScroll() return self.scroll or 0 end
                for _, method in ipairs({"SetFrameStrata", "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor", "EnableMouse", "SetMovable", "RegisterForDrag", "StartMoving", "StopMovingOrSizing", "SetJustifyH", "SetHighlightTexture", "SetScrollChild", "SetFontObject", "SetMultiLine", "SetAutoFocus", "SetCursorPosition", "ClearFocus", "SetAllPoints", "ClearAllPoints", "SetFrameLevel", "SetFontString", "SetTextColor", "SetCheckedTexture", "SetVertexColor", "SetTexture", "SetTexCoord"}) do
                    w[method] = function() end
                end
                function w:GetFrameLevel() return 5 end
                function w:GetName() return self.name end
                function w:SetScript(name, callback) self.scripts[name] = callback end
                function w:HookScript(name, callback)
                    local before = self.scripts[name]
                    self.scripts[name] = function(...) if before then before(...) end; callback(...) end
                end
                function w:SetShown(value)
                    local changed = self.visible ~= value
                    self.visible = value
                    if changed and value and self.scripts.OnShow then self.scripts.OnShow(self) end
                    if changed and not value and self.scripts.OnHide then self.scripts.OnHide(self) end
                end
                function w:Show() self:SetShown(true) end
                function w:Hide() self:SetShown(false) end
                function w:SetText(text)
                    self.text = text
                    if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
                end
                function w:GetNumLines() local _, count = self.text:gsub("\\n", ""); return count + 1 end
                function w:SetFont() return true end
                function w:SetChecked(value) self.checked = value end
                function w:GetChecked() return self.checked end
                function w:ClearBindings() self.bindings = {} end
                function w:SetBindingClick(priority, key, target, button)
                    self.bindings = self.bindings or {}
                    self.bindings[key] = { priority, target, button }
                end
                function w:SetAttribute(key, value)
                    self.attrs[key] = value
                    if key ~= "_onattributechanged" and self.attrs._onattributechanged then
                        local handler = assert(loadstring("return function(self, name, value) " .. self.attrs._onattributechanged .. " end"))()
                        handler(self, key, value)
                    end
                end
                function w:GetAttribute(key) return self.attrs[key] end
                function w:Click(button)
                    if self.frameType == "CheckButton" then self.checked = not self.checked end
                    if self.scripts.OnClick then self.scripts.OnClick(self, button or "LeftButton") end
                end
                function w:CreateFontString() return widget("FontString", nil, self) end
                function w:CreateTexture() return widget("Texture", nil, self) end
                w.Text = { SetText = function() end }
                table.insert(widgets, w)
                if name then namedWidgets[name] = w end
                return w
            end
            CreateFrame = function(frameType, name, parent, template) return widget(frameType, name, parent, template) end
            local stateDrivers = 0
            function RegisterStateDriver(frame, state, values)
                stateDrivers = stateDrivers + 1
                assert(state == "combat" and values == "[combat] combat; nocombat")
                frame:SetAttribute("state-combat", "nocombat")
            end
            addon:ShowOptions()
            local focused = namedWidgets.PadSkinForeverOptions
            local bindingOwner = namedWidgets.PadSkinForeverControllerBindings
            assert(focused and focused:IsShown())
            assert(bindingOwner and bindingOwner.template == "SecureHandlerAttributeTemplate")
            assert(bindingOwner.attrs["psf-active"] == true and stateDrivers == 1)
            assert(bindingOwner.bindings.PADDUP[2] == "PadSkinForeverControllerUp")
            assert(bindingOwner.bindings.PADDDOWN[2] == "PadSkinForeverControllerDown")
            assert(bindingOwner.bindings.PAD1[2] == "PadSkinForeverControllerAccept")
            assert(bindingOwner.bindings.PAD2[2] == "PadSkinForeverControllerBack")
            assert(bindingOwner.attrs._onattributechanged:find("self:ClearBindings", 1, true))
            assert(bindingOwner.attrs._onattributechanged:find("self:SetBindingClick", 1, true))
            assert(not bindingOwner.attrs._onattributechanged:find("SetPreferredGamepadInteractTarget", 1, true))
            local general
            for _, w in ipairs(widgets) do if w.text == "General" then general = w end end
            assert(general and general.PSFControllerFocused)
            assert(focused.PSFLogo and focused.PSFFocusArrow:IsShown())
            assert(focused.PSFFocusArrow.anchorTarget == general)
            local function click(text)
                for _, w in ipairs(widgets) do if w.text == text then w.scripts.OnClick(w); return end end
                error("Missing button: " .. text)
            end
            click("Glyphs")
            click("Buttons")
            click("Theme")
            click("Input legend settings...")
            click("Toggle native legend")
            click("Debug")
            click("Start tracing")
            assert(addon:IsDebugTracing())
            click("Refresh")
            click("General")
            assert(general.PSFControllerFocused)
            namedWidgets.PadSkinForeverControllerDown:Click()
            local moved = false
            for _, w in ipairs(widgets) do if w ~= general and w.PSFControllerFocused then moved = true end end
            assert(moved)
            assert(focused.PSFFocusArrow:IsShown())
            assert(focused.PSFFocusArrow.anchorTarget.PSFControllerFocused)
            namedWidgets.PadSkinForeverControllerBack:Click()
            assert(not focused:IsShown() and bindingOwner.attrs["psf-active"] == false)
            assert(not focused.PSFFocusArrow:IsShown())
            assert(next(bindingOwner.bindings) == nil)
            addon:ShowOptions()
            assert(focused:IsShown() and bindingOwner.attrs["psf-active"] == true and stateDrivers == 1)
            bindingOwner:SetAttribute("state-combat", "combat")
            assert(bindingOwner.attrs["psf-active"] == false and next(bindingOwner.bindings) == nil)
            combat = true
            focused.scripts.OnEvent(focused, "PLAYER_REGEN_DISABLED")
            assert(not focused:IsShown())
            assert(not focused.PSFFocusArrow:IsShown())
            combat = false
            bindingOwner:SetAttribute("state-combat", "nocombat")
            assert(next(bindingOwner.bindings) == nil)
            addon:ShowOptions()
            GameMenuFrame = widget("Frame", "GameMenuFrame", UIParent)
            GameMenuFrame.visible = true
            GameMenuFrame.buttons = { widget("Button"), widget("Button") }
            function GameMenuFrame:InitButtons() end
            addon:CreateGameMenuButton()
            local gameMenuButton = addon:GetGameMenuButton()
            assert(gameMenuButton and gameMenuButton.text == "PADSKINFOREVER")
            assert(gameMenuButton.PSFSubtitle and gameMenuButton.PSFSubtitle.text == "ADDON SETTINGS")
            assert(gameMenuButton.PSFLogo)
            assert(GameMenuFrame.buttons[1].routes == nil)
            assert(GameMenuFrame.buttons[2].routes == nil)
            assert(GameMenuFrame.scripts.OnHide == nil)
            gameMenuButton:Click()
            assert(focused:IsShown() and bindingOwner.attrs["psf-active"] == true)
        ''')

    def test_legend_toggle_success_and_rejection(self):
        self.check('''
            assert(addon:ToggleLegend() and not legendVisible)
            assert(addon:ToggleLegend() and legendVisible)
            cvarAllowed = false
            assert(not addon:ToggleLegend() and legendVisible)
            assert(#messages == 1)
        ''')

    def test_combat_hud_skins_each_native_timer_without_moving_it_and_updates_resources(self):
        self.lua.execute(THEME_MOCKS)
        self.check('''
            UIParent = surface("Frame"); UIParent.center = {960, 540}
            EditModeManagerFrame = surface("Frame", UIParent); EditModeManagerFrame:Hide()
            EditModeManagerFrame.Grid = {gridSpacing = 20}
            function EditModeManagerFrame:IsSnapEnabled() return true end
            function EditModeManagerFrame:SelectSystem() end
            C_EditMode = { GetLayouts = function() return {activeLayout = 4} end }
            HEALTH, POWER, FOCUS = "Health", "Power", "Focus"
            PowerBarColor = { FOCUS = {r=1, g=.5, b=.1}, [2] = {r=1, g=.5, b=.1} }
            function UnitHealth(unit) return unit == "pet" and 80 or 406 end
            function UnitHealthMax(unit) return unit == "pet" and 100 or 406 end
            function UnitPower(unit) return unit == "pet" and 60 or 375 end
            function UnitPowerMax(unit) return unit == "pet" and 100 or 375 end
            function UnitPowerType() return 2, "FOCUS" end
            function UnitExists(unit) return unit == "player" or unit == "pet" end
            function UnitName(unit) return unit == "pet" and "Ghostfang" or "Vaelith" end
            function SetPortraitTexture(texture, unit) texture.portraitUnit = unit end

            local function Swing(nativeTexture)
                local frame = surface("Frame", UIParent)
                frame.Background = surface("Texture", frame); frame.Background:SetAlpha(.7)
                frame.Border = surface("Texture", frame); frame.Border:SetAlpha(.8)
                frame.StatusBar = surface("StatusBar", frame)
                frame.StatusBar:SetStatusBarTexture(nativeTexture)
                frame.StatusBar.Pip = surface("Texture", frame.StatusBar)
                frame.StatusBar.Pip:SetAtlas("native-pip")
                frame.StatusBar.TypeLabel = surface("FontString", frame.StatusBar)
                frame.StatusBar.TimeLabel = surface("FontString", frame.StatusBar)
                frame.StatusBar.TypeLabelShadow = surface("Texture", frame.StatusBar)
                frame.StatusBar.TypeLabelShadow:SetAlpha(.6)
                function frame:GetStatusBar() return self.StatusBar end
                function frame:GetStatusBarPip() return self.StatusBar.Pip end
                function frame:GetTypeLabel() return self.StatusBar.TypeLabel end
                function frame:GetTimeLabel() return self.StatusBar.TimeLabel end
                function frame:GetTypeLabelShadow() return self.StatusBar.TypeLabelShadow end
                function frame:InitializeBarPresentation() self.StatusBar:SetStatusBarTexture(nativeTexture) end
                function frame:ApplyRangePresentation()
                    self.Background:SetAlpha(.4); self.Border:SetAlpha(.4); self.StatusBar:SetAlpha(.4)
                end
                frame:SetPoint("TOP", UIParent, "TOP", 13, -27)
                return frame
            end
            SwingTimerMainHandFrame = Swing("native-main")
            SwingTimerOffHandFrame = Swing("native-off")
            SwingTimerRangedFrame = Swing("native-ranged")
            local originalPoint = {SwingTimerMainHandFrame:GetPoint()}

            addon:RefreshCombatHUD()
            for _, frame in ipairs({SwingTimerMainHandFrame, SwingTimerOffHandFrame, SwingTimerRangedFrame}) do
                assert(frame.Background.alpha == 0 and frame.Border.alpha == 0, "native chrome")
                assert(frame.StatusBar.barTexture.file == [[Interface\\Buttons\\WHITE8X8]], "bar texture")
                assert(frame.StatusBar.barColor[1] == addon.barColors.neutral[1], "neutral timer color")
                local card
                for _, child in ipairs(frame.children) do if child.PSFRoundedPanel then card = child end end
                assert(card and card.visible, "rounded skin")
                assert(frame.clearCount == 0, "native anchor changed")
            end
            local point = {SwingTimerMainHandFrame:GetPoint()}
            assert(point[1] == originalPoint[1] and point[4] == originalPoint[4] and point[5] == originalPoint[5])
            SwingTimerMainHandFrame:ApplyRangePresentation()
            assert(SwingTimerMainHandFrame.Background.alpha == 0 and SwingTimerMainHandFrame.StatusBar.alpha == .4)

            local resources = PadSkinForeverResourceDisplay
            assert(resources and resources.visible and resources.height == 58)
            assert(resources.playerHealth.value == 406 and resources.playerPower.value == 375)
            assert(resources.playerHealth.barColor[2] == addon.barColors.health[2])
            assert(resources.playerPower.barColor[1] == addon.barColors.focus[1])
            assert(resources.petHealth.value == 80 and resources.petPower.value == 60)
            assert(resources.petHealth.left.text == "Ghostfang" and resources.petPortrait.portraitUnit == "pet")
            EditModeManagerFrame.scripts.OnShow()
            assert(resources.editMode and resources.editSelection.visible)
            assert(resources.editSelection.mouse and resources.editSelection.level == 1000)
            resources.editSelection.scripts.OnMouseDown(resources.editSelection, "LeftButton")
            assert(resources.editSelection.isSelected)
            resources.editSelection.scripts.OnDragStart()
            assert(resources.moving)
            resources.center = {973, 793}
            resources:SetPoint("BOTTOM", UIParent, "BOTTOM", 13, 253)
            resources.editSelection.scripts.OnDragStop()
            assert(addon.db.resourceAnchor[1] == "CENTER")
            assert(addon.db.resourceAnchor[3] == 20 and addon.db.resourceAnchor[4] == 260)
            assert(addon.db.resourceAnchors["4"][3] == 20 and addon.db.resourceAnchors["4"][4] == 260)
            resources.editSelection.isSelected = true
            EditModeManagerFrame:SelectSystem()
            assert(not resources.editSelection.isSelected)
            EditModeManagerFrame.scripts.OnHide()
            assert(not resources.editSelection.visible)

            addon.db.themeSwingTimers = false
            addon:RefreshCombatHUD()
            assert(SwingTimerMainHandFrame.StatusBar.barTexture.file == "native-main")
            assert(SwingTimerMainHandFrame.Background.alpha == .4)
            local hiddenCard
            for _, child in ipairs(SwingTimerMainHandFrame.children) do if child.PSFRoundedPanel then hiddenCard = child end end
            assert(hiddenCard and not hiddenCard.visible)
        ''')

    def test_legend_preserves_font_size_and_restores(self):
        self.check('''
            local text = font()
            GamepadPersistentInputLegend = { groups = { HUD = { { ControlDescText = { FontString = text }, InputIcon1 = icon } } } }
            addon:QueueRefresh(); drain()
            assert(text.values[2] == 14)
            addon.db.skinLegend = false; addon:QueueRefresh(); drain()
            assert(text.values[1] == STANDARD_TEXT_FONT and text.values[2] == 12)
        ''')


if __name__ == "__main__":
    unittest.main()
