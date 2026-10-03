# PadSkinForever

Een kleine, zelfstandige skin voor de **native GamepadUI van World of Warcraft Forever**. Huidige testversie: **0.3.2-alpha**.

## Wat zit erin?

- Een **Modern minimal** knopstijl: eigen dunne borders (grijs voor D-pad, Xbox-kleuren voor A/B/X/Y) en donkere neutrale lege slots, in de bestaande ronde/vierkante vorm. **Blizzard borders** behoudt de oorspronkelijke textures met blauwe tint. Beide vallen onder de schakelaar voor button skinning.
- Actionbar-glyphs behouden de native kant/hoek. Bij vergroten schuiven ze mee zodat de binnenrand op zijn oorspronkelijke positie blijft; alle glyphs naar dezelfde rechterbovenhoek verplaatsen veroorzaakte overlap in 0.3.0. Zet **Move enlarged glyphs outward from their native anchor** uit om de native positie terug te krijgen. Legenda-glyphs houden hun eigen native anchors.
- **Vivid glyph colors** gebruikt de gekleurde glyphtextures met volledige opacity, naast meer verzadigde Xbox-kleurtinten. Dit is afzonderlijk uit te zetten; native status en disabled-artwork blijven behouden.
- Disabled-glyphhelderheid naar keuze: **45%, 70% of 100%** van de tint (standaard 70%). De native disabled-status en artwork blijven bestaan.
- A/B/X/Y-glyphkeuze: **Blizzard standaard**, **Xbox monochroom** of **Xbox gekleurd** (A groen, B rood, X blauw, Y geel). De gekleurde disabled-toestand blijft gedimd; Blizzard bepaalt de interactiestatus.
- D-pad-iconkeuze: **Blizzard standaard**, **Xbox monochroom** of **Xbox blauw**.
- Onafhankelijke groottes voor A/B/X/Y en D-pad: **50–200%**. Deze keuzes gelden voor de vier actionbars én voor de legenda wanneer legendatheming aan staat.
- Een cooldownfont naar keuze, met grootte en outline. Fonts uit **LibSharedMedia** en **Font Manager** verschijnen in de fontlijst. Een werkend geregistreerd `.otf`-font kan direct worden gekozen.
- Een tint voor de bestaande achtergrond/randen van de native inputlegenda en het geselecteerde font. De native tekstgrootte en frame-anchors blijven behouden. Grotere glyphs kunnen meer ruimte vragen; controleer de leesbaarheid.
- **Legendatheming aan/uit**: uit herstelt onze wijzigingen één keer, waarna de legenda niet opnieuw wordt gestyled. De native legendatoggle blijft apart bruikbaar.
- Een **Debug-tab** met huidige atlas-/font-/kleur-/schaalwaarden en optionele tracing van toekomstige visuele wijzigingen.
- Een eigen, standaard ongebonden keybinding om de native legenda aan/uit te zetten.
- Instellingen via **`/psf`** of **`/padskin`**; **`/psf legend`** schakelt de legenda om.

De addon verandert geen actionbar-indeling, spells, targeting, lootvensters of native navigatie. De minimalistische knopstijl gebruikt zes eigen gegenereerde TGA-assets. Glyphs gebruiken Blizzard-atlases. Geen Masque-installatie nodig; bestaande Masque-skinpakketten worden niet ingelezen.

## Installeren

1. Download deze repository via **Code → Download ZIP**.
2. Kopieer de binnenste map **`PadSkinForever`** naar de `Interface/AddOns`-map van je **Forever-client**.
3. Controleer dat het pad eindigt op `Interface/AddOns/PadSkinForever/PadSkinForever.toc`.
4. Start WoW opnieuw, schakel PadSkinForever in en open **`/psf`**.

Geen libraries verplicht. Font Manager en een beschikbare LibSharedMedia-library zijn optioneel. Font Manager 1.1.1 levert zelf geen LibSharedMedia mee; daarom leest de fontkiezer ook zijn opgeslagen custom bestandsnamen. Fontbestanden worden niet meegeleverd.

De lijst toont fontnamen zonder previews; openen ervan laadt geen fontbestanden. De optionele Font Manager-placeholder `Custom.ttf` wordt niet automatisch toegevoegd.

Selecteer je bestaande **FOT-Rodin Pro DB** in de lijst. Als je een font toevoegt terwijl je speelt, open `/psf` opnieuw om de lijst te vernieuwen. Een ontbrekend of niet laadbaar geselecteerd font valt terug op het Blizzard-font. Font Manager kan bij een globale fontoverride opnieuw fonts wijzigen; controleer zijn instellingen als je selectie niet blijft staan.

## Glyphs en debug

`/psf` heeft vier tabs: **General**, **Glyphs**, **Buttons** en **Debug**. In Glyphs klik je op de stijlknop om door de beschikbare stijlen te kiezen. Met plus/min en 100% verander of herstel je de grootte. De face-glyphstijl neemt de oude kleurinstelling over; fonts en andere bestaande instellingen blijven bewaard.

De Xbox-keuzes gebruiken Blizzard-atlases, ook als je actieve device-iconset anders is. **Blizzard default** volgt de native devicekeuze. Een niet beschikbare atlas wordt niet geforceerd. Native hover/pressed/active/disabled-states blijven bestaan; de addon verandert de status zelf niet. Aanpassingen wachten tot combat voorbij is.

In Debug toont **Refresh** de actuele waarden van de door PSF ontdekte oppervlakken. **Start tracing** registreert toekomstige setter-calls op die oppervlakken (bijvoorbeeld SetFont, SetAtlas, SetVertexColor en SetScale) met call stacks. Maximaal 40 recente calls worden in geheugen bewaard. **Stop tracing** stopt registratie; de veilige post-hooks blijven bestaan maar registreren niets. Tracing is standaard uit en wordt niet opgeslagen na reload.

Een stack toont code die bij een call betrokken is, geen volledige eigenaarshistorie en geen bewijs van een conflict. Wijzigingen vóór tracing, calls buiten de gevolgde setters en sommige native veranderingen kunnen niet worden toegeschreven. Debug verandert geen bindings, targeting of functies van andere addons. De tekst kan worden geselecteerd/gekopieerd voor diagnose.

In **Buttons** kies je Modern minimal of Blizzard borders. De toggle voor button skinning in General schakelt beide uit en herstelt de oorspronkelijke assets. Glyphs, cooldownfont en legendatheming zijn afzonderlijke instellingen. Instelbare **border-types van de legenda** staan op de lijst voor een volgende versie. Handmatige glyph-offsets en automatische ruimte in de legenda volgen afzonderlijk; zie issue #4.

## Legenda met de controller

Zoek **PadSkinForever → Toggle native input legend** in de keybindings en kies zelf een vrije controllerknop. De addon bindt geen toetsen automatisch en installeert geen override bindings.

De toggle gebruikt uitsluitend Blizzard's CVar **`GamepadShowPersistentInputLegend`**. Blizzard bepaalt vervolgens wanneer de legenda zichtbaar mag zijn. In bijvoorbeeld native menu's kan die verborgen blijven, ook wanneer de instelling aan staat.

De native gamepad-bindingstack kan voorrang hebben op gewone addonbindings. Deze eerste versie garandeert daarom nog niet dat de gekozen controllerbinding in elke context doorkomt. Test eerst `/psf legend`, vervolgens je gekozen knop in gameplay en menu's. De toggle wordt tijdens combat geweigerd met een chatbericht.

## Status en testen

Gebouwd na broncodecontrole van Forever **1.60.1 (70205)**, [Gethe/wow-ui-source, commit e3ecc27](https://github.com/Gethe/wow-ui-source/commit/e3ecc27). TOC-interface: **16001**.

Lokaal gecontroleerd: Lua 5.1-syntax, XML en achttien logictests, waaronder native assetherstel na vormwissels, glyphplaatsing/herstel, combat-uitstel, fonts, legenda en debug. De tester heeft in 0.2.0 de glyphkleuren en vergroting bevestigd, inclusief behoud van 150%/170% na reload. Legendatoggle, blauwe randen en FOT-Rodin-Pro-B.otf-cooldownfont waren eerder bevestigd; zie [issue #1](https://github.com/Wimterbourne/PadSkinForever/issues/1). **De tester heeft de verbeterde glyphposities en minimalistische borders in 0.3.1 bevestigd. De nieuwe borderkleuren en vivid-glyphweergave van 0.3.2 moeten nog in WoW worden getest.** Mocks kunnen Blizzard's secure/taint-model niet reproduceren.

Skinwijzigingen worden buiten combat toegepast. Post-hooks op de betrokken frames vragen alleen een latere visuele refresh aan; native functies worden niet vervangen. Dit is een conservatieve aanpak, geen bewijs dat de addon taintvrij is.

Test deze alpha eerst met alleen **PadSkinForever**, eventueel **Font Manager**, **BugGrabber** en **BugSack**:

1. Controleer de vier bars, A/B/X/Y-kleuren en disabled/range-feedback.
2. Test de drie stijlen en groottebereiken afzonderlijk voor A/B/X/Y en D-pad, op actionbars en legenda. Controleer na reload het behoud van keuzes.
3. Selecteer je font en test cooldowns, charges en een herlaadbeurt.
4. Zet skins afzonderlijk uit en controleer dat de oorspronkelijke visuals terugkomen.
5. Test de legenda via `/psf legend` en je controllerbinding.
6. Test combat, pagina-/modifierwissels, ESC, loot openen/sluiten, daadwerkelijk looten en chatmenu's.
7. Test de Debug-tab: snapshots verversen, tracing starten, een PSF-instelling wijzigen, tracing stoppen en geschiedenis wissen.
8. Meld bij een fout: clientbuild, addonversie, actieve addons, handeling en de volledige BugSack-stack. De eerder gemelde `SetPreferredGamepadInteractTarget()`-fout is een belangrijk regressiepunt.

Deze versie toont eigen instellingen in een klein muisbediend venster. Native controllernavigatie voor dit instellingenvenster is nog niet ingebouwd.

## Ontwikkeling

```sh
python -m pip install -r tests/requirements.txt
python tests/test_addon.py
```

Eigen knoptextures opnieuw genereren: `python tools/generate_button_assets.py` (geen extra dependencies).

Runtimecode staat in `PadSkinForever/`. De tests en Python-dependency hoeven niet in je AddOns-map.

Referenties: Blizzard's `Blizzard_GamepadActionBars`, `Blizzard_Gamepad/UI/PersistentInputLegend` en `Blizzard_SharedXML/Shared/InputIcons`. Inked4GamePadUI is onderzocht voor de skin-aanpak; deze repository bevat geen gekopieerde Inked- of Font Manager-code/assets.

MIT-licentie, zie [LICENSE](LICENSE).
