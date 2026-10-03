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


class AddonTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCKS)
        for name in ("Core.lua", "Fonts.lua", "Debug.lua", "Glyphs.lua", "Buttons.lua", "Skin.lua", "Options.lua"):
            source = (ROOT / "PadSkinForever" / name).read_text()
            self.lua.execute('assert(loadstring(...))("PadSkinForever", addon)', source)
        self.lua.execute('fire("ADDON_LOADED", "PadSkinForever"); drain()')

    def check(self, source):
        self.lua.execute(source)

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
            assert(icon.points[1][1] == "BOTTOMLEFT" and icon.points[1][2] == button)
            addon.db.faceGlyphScale = 2; addon:QueueRefresh(); drain()
            assert(icon.points[1][4] == 1 and icon.points[1][5] == 1)
            addon.db.glyphOutside = false; addon:QueueRefresh(); drain()
            assert(icon.points[1][1] == "TOPRIGHT")
            icon:ClearAllPoints(); icon:SetPoint("LEFT", button, "RIGHT", 7, 3); drain()
            addon.db.glyphOutside = true; addon:QueueRefresh(); drain()
            addon.db.glyphOutside = false; addon:QueueRefresh(); drain()
            assert(icon.points[1][1] == "LEFT" and icon.points[1][4] == 7)
            assert(#timers == 0)
        ''')

    def test_xbox_colors_and_disabled_feedback(self):
        self.check('''
            assert(normal.rgba[1] == 0.25 and normal.rgba[2] == 1)
            assert(normal.rgba[4] == 0.8)
            assert(disabled.rgba[1] < normal.rgba[1] and disabled.desaturation == 1)
            icon.mappedButtonKey = "PAD2"
            icon:RefreshIconTextures(); drain()
            assert(normal.rgba[1] == 1 and normal.rgba[2] == 0.25)
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

    def test_options_tabs_build_and_open(self):
        self.check('''
            widgets = {}
            local function widget()
                local w = { scripts = {}, visible = false, text = "" }
                for _, method in ipairs({"SetPoint", "SetSize", "SetFrameStrata", "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor", "EnableMouse", "SetMovable", "RegisterForDrag", "StartMoving", "StopMovingOrSizing", "SetWidth", "SetHeight", "SetJustifyH", "SetHighlightTexture", "SetScrollChild", "SetFontObject", "SetMultiLine", "SetAutoFocus", "SetCursorPosition", "ClearFocus", "SetVerticalScroll"}) do
                    w[method] = function() end
                end
                function w:SetScript(name, callback) self.scripts[name] = callback end
                function w:HookScript(name, callback)
                    local before = self.scripts[name]
                    self.scripts[name] = function(...) if before then before(...) end; callback(...) end
                end
                function w:SetShown(value)
                    local changed = self.visible ~= value
                    self.visible = value
                    if changed and value and self.scripts.OnShow then self.scripts.OnShow(self) end
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
                function w:CreateFontString() return widget() end
                w.Text = { SetText = function() end }
                table.insert(widgets, w)
                return w
            end
            CreateFrame = function() return widget() end
            addon:ShowOptions()
            local function click(text)
                for _, w in ipairs(widgets) do if w.text == text then w.scripts.OnClick(w); return end end
                error("Missing button: " .. text)
            end
            click("Glyphs")
            click("Debug")
            click("Start tracing")
            assert(addon:IsDebugTracing())
            click("Refresh")
            click("General")
        ''')

    def test_legend_toggle_success_and_rejection(self):
        self.check('''
            assert(addon:ToggleLegend() and not legendVisible)
            assert(addon:ToggleLegend() and legendVisible)
            cvarAllowed = false
            assert(not addon:ToggleLegend() and legendVisible)
            assert(#messages == 1)
        ''')

    def test_legend_preserves_font_size_and_restores(self):
        self.check('''
            local text = font()
            GamepadPersistentInputLegend = { groups = { HUD = { { ControlDescText = { FontString = text }, InputIcon1 = icon } } } }
            addon:QueueRefresh(); drain()
            assert(text.values[2] == 12)
            addon.db.skinLegend = false; addon:QueueRefresh(); drain()
            assert(text.values[1] == STANDARD_TEXT_FONT and text.values[2] == 12)
        ''')


if __name__ == "__main__":
    unittest.main()
