# PadSkinForever

Een kleine, zelfstandige skin voor de **native GamepadUI van World of Warcraft Forever**. Eerste testversie: **0.1.0-alpha**.

## Wat zit erin?

- Een blauwe tint voor de bestaande randen en lege slots van de vier native controller-actionbars.
- Xbox-glyphs: **A groen, B rood, X blauw, Y geel**. De native disabled-weergave blijft intact; PlayStation-glyphs worden niet ingekleurd.
- Een cooldownfont naar keuze, met grootte en outline. Fonts uit **LibSharedMedia** en **Font Manager** verschijnen in de fontlijst. Een werkend geregistreerd `.otf`-font kan direct worden gekozen.
- Een tint voor de bestaande achtergrond/randen van de native inputlegenda, gekleurde Xbox-glyphs en het geselecteerde font. De oorspronkelijke tekstgrootte en plaatsing blijven behouden.
- Een eigen, standaard ongebonden keybinding om de native legenda aan/uit te zetten.
- Instellingen via **`/psf`** of **`/padskin`**; **`/psf legend`** schakelt de legenda om.

De addon verandert geen actionbar-indeling, spells, targeting, lootvensters of native navigatie. De blauwe skin gebruikt Blizzard's bestaande textures; het is geen kopie van Inked's custom artwork en geen Masque-plugin.

## Installeren

1. Download deze repository via **Code → Download ZIP**.
2. Kopieer de binnenste map **`PadSkinForever`** naar de `Interface/AddOns`-map van je **Forever-client**.
3. Controleer dat het pad eindigt op `Interface/AddOns/PadSkinForever/PadSkinForever.toc`.
4. Start WoW opnieuw, schakel PadSkinForever in en open **`/psf`**.

Geen libraries verplicht. Font Manager en een beschikbare LibSharedMedia-library zijn optioneel. Font Manager 1.1.1 levert zelf geen LibSharedMedia mee; daarom leest de fontkiezer ook zijn fontlijst en opgeslagen custom bestandsnamen. Fontbestanden worden niet meegeleverd.

Selecteer je bestaande **FOT-Rodin Pro DB** in de lijst. Als je een font toevoegt terwijl je speelt, open `/psf` opnieuw om de lijst te vernieuwen. Een ontbrekend of niet laadbaar geselecteerd font valt terug op het Blizzard-font. Font Manager kan bij een globale fontoverride opnieuw fonts wijzigen; controleer zijn instellingen als je selectie niet blijft staan.

## Legenda met de controller

Zoek **PadSkinForever → Toggle native input legend** in de keybindings en kies zelf een vrije controllerknop. De addon bindt geen toetsen automatisch en installeert geen override bindings.

De toggle gebruikt uitsluitend Blizzard's CVar **`GamepadShowPersistentInputLegend`**. Blizzard bepaalt vervolgens wanneer de legenda zichtbaar mag zijn. In bijvoorbeeld native menu's kan die verborgen blijven, ook wanneer de instelling aan staat.

De native gamepad-bindingstack kan voorrang hebben op gewone addonbindings. Deze eerste versie garandeert daarom nog niet dat de gekozen controllerbinding in elke context doorkomt. Test eerst `/psf legend`, vervolgens je gekozen knop in gameplay en menu's. De toggle wordt tijdens combat geweigerd met een chatbericht.

## Status en testen

Gebouwd na broncodecontrole van Forever **1.60.1 (70205)**, [Gethe/wow-ui-source, commit e3ecc27](https://github.com/Gethe/wow-ui-source/commit/e3ecc27). TOC-interface: **16001**.

Lokaal gecontroleerd: Lua 5.1-syntax, XML en zeven logictests voor glyphkleuren, disabled-weergave, herstel van visuals, combat-uitstel, Font Manager `.otf`-paden, late LibSharedMedia-registratie en de legendatoggle. **Nog niet in een echte WoW-client getest.** Mocks kunnen Blizzard's secure/taint-model niet reproduceren.

Skinwijzigingen worden buiten combat toegepast. Post-hooks op de betrokken frames vragen alleen een latere visuele refresh aan; native functies worden niet vervangen. Dit is een conservatieve aanpak, geen bewijs dat de addon taintvrij is.

Test deze alpha eerst met alleen **PadSkinForever**, eventueel **Font Manager**, **BugGrabber** en **BugSack**:

1. Controleer de vier bars, A/B/X/Y-kleuren en disabled/range-feedback.
2. Selecteer je font en test cooldowns, charges en een herlaadbeurt.
3. Zet skins afzonderlijk uit en controleer dat de oorspronkelijke visuals terugkomen.
4. Test de legenda via `/psf legend` en je controllerbinding.
5. Test combat, pagina-/modifierwissels, ESC, loot openen/sluiten, daadwerkelijk looten en chatmenu's.
6. Meld bij een fout: clientbuild, addonversie, actieve addons, handeling en de volledige BugSack-stack. De eerder gemelde `SetPreferredGamepadInteractTarget()`-fout is een belangrijk regressiepunt.

Deze versie toont eigen instellingen in een klein muisbediend venster. Native controllernavigatie voor dit instellingenvenster is nog niet ingebouwd.

## Ontwikkeling

```sh
python -m pip install -r tests/requirements.txt
python tests/test_addon.py
```

Runtimecode staat in `PadSkinForever/`. De tests en Python-dependency hoeven niet in je AddOns-map.

Referenties: Blizzard's `Blizzard_GamepadActionBars`, `Blizzard_Gamepad/UI/PersistentInputLegend` en `Blizzard_SharedXML/Shared/InputIcons`. Inked4GamePadUI is onderzocht voor de skin-aanpak; deze repository bevat geen gekopieerde Inked- of Font Manager-code/assets.

MIT-licentie, zie [LICENSE](LICENSE).
