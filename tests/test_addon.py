"""Logic checks with Lua 5.1 mocks; these cannot reproduce WoW's taint model."""
from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
MOCKS = r'''
unpack = unpack or table.unpack
addon = {}
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
    function t:GetAtlas() return self.atlas end
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
icon = { mappedButtonKey = "PAD1", DisabledTexture = disabled,
         textureStateTextures = {normal, disabled}, RefreshIconTextures = function() end }
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
        for name in ("Core.lua", "Fonts.lua", "Skin.lua", "Options.lua"):
            source = (ROOT / "PadSkinForever" / name).read_text()
            self.lua.execute('assert(loadstring(...))("PadSkinForever", addon)', source)
        self.lua.execute('fire("ADDON_LOADED", "PadSkinForever"); drain()')

    def check(self, source):
        self.lua.execute(source)

    def test_xbox_colors_and_disabled_feedback(self):
        self.check('''
            assert(normal.rgba[1] == 0.25 and normal.rgba[2] == 1)
            assert(normal.rgba[4] == 0.8)
            assert(disabled.rgba[1] == 1 and disabled.desaturation == 0)
            icon.mappedButtonKey = "PAD2"
            icon:RefreshIconTextures(); drain()
            assert(normal.rgba[1] == 1 and normal.rgba[2] == 0.25)
            normal.atlas = "gamepad-ps4-cross-normal"
            icon:RefreshIconTextures(); drain()
            assert(normal.rgba[1] == 1 and normal.desaturation == 0)
        ''')

    def test_disable_restores_original_visual_properties(self):
        self.check('''
            addon.db.skinButtons = false; addon.db.colorGlyphs = false
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
