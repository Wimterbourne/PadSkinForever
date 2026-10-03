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
    function w:GetAlpha() return self.alpha end
    function w:SetAlpha(value) self.alpha = value end
    function w:SetSize(...) self.size = {...} end
    function w:SetPoint(...) self.point = {...} end
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
    function w:SetWidth(value) self.width = value end
    function w:SetJustifyH(value) self.justify = value end
    function w:CreateFontString()
        local region = Surface("FontString"); table.insert(self.regions, region); return region
    end
    function w:CreateTexture()
        local region = Surface("Texture"); table.insert(self.regions, region); return region
    end
    function w:GetStatusBarTexture() return self.barTexture end
    function w:SetStatusBarTexture(value) self.barTexture:SetTexture(value) end
    table.insert(uiwidgets, w)
    return w
end
surface = Surface
CreateFrame = function(_, _, parent) return Surface("Frame", parent) end
'''


class AddonTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCKS)
        for name in ("Core.lua", "Fonts.lua", "Debug.lua", "Glyphs.lua", "Buttons.lua", "Theme.lua", "Toasts.lua", "Skin.lua", "Options.lua"):
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
            addon:QueueRefresh(); drain()
            assert(Minimap.mask:find("WHITE8X8", 1, true))
            assert(MinimapCompassTexture.alpha == 0)
            Minimap:SetMaskTexture("updated-native-circle"); drain()
            assert(Minimap.mask:find("WHITE8X8", 1, true))
            addon.db.squareMinimap = false; addon:QueueRefresh(); drain()
            assert(Minimap.mask == "updated-native-circle")
            assert(MinimapCompassTexture.alpha == 1)
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
            frames[2].OnEvent(frames[2], "CHAT_MSG_LOOT", "You receive loot: " .. link .. "x2.")
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
            click("Buttons")
            click("Theme")
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
