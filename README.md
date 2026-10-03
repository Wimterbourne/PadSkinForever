# PadSkinForever

Een zelfstandige skin voor de **native GamepadUI van World of Warcraft Forever**. Huidige testversie: **0.4.3-alpha**.

## Wat zit erin?

- Een **Modern minimal** knopstijl: eigen dunne borders (grijs voor D-pad, Xbox-kleuren voor A/B/X/Y) en donkere neutrale lege slots, in de bestaande ronde/vierkante vorm. **Blizzard borders** behoudt de oorspronkelijke textures met blauwe tint. Beide vallen onder de schakelaar voor button skinning.
- In 0.3.3 zijn alleen de ronde borders dikker: 3 texturepixels in plaats van 1,5. Dat geeft bij circa 48 px knopgrootte ongeveer 1 px extra; de zichtbare dikte hangt af van je UI-schaal. Vierkante borders blijven gelijk.
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

De addon verandert geen actionbar-indeling, spells, targeting, loot-acties of native navigatie. De Theme-modules stylen de bestaande vensters; native schermposities blijven behouden. De minimalistische knopstijl gebruikt zes eigen gegenereerde TGA-assets. Glyphs gebruiken Blizzard-atlases. Geen Masque-installatie nodig; bestaande Masque-skinpakketten worden niet ingelezen.

## Installeren

1. Download deze repository via **Code → Download ZIP**.
2. Kopieer de binnenste map **`PadSkinForever`** naar de `Interface/AddOns`-map van je **Forever-client**.
3. Controleer dat het pad eindigt op `Interface/AddOns/PadSkinForever/PadSkinForever.toc`.
4. Start WoW opnieuw, schakel PadSkinForever in en open **`/psf`**.

Geen libraries verplicht. Font Manager en een beschikbare LibSharedMedia-library zijn optioneel. Font Manager 1.1.1 levert zelf geen LibSharedMedia mee; daarom leest de fontkiezer ook zijn opgeslagen custom bestandsnamen. Fontbestanden worden niet meegeleverd.

De lijst toont fontnamen zonder previews; openen ervan laadt geen fontbestanden. De optionele Font Manager-placeholder `Custom.ttf` wordt niet automatisch toegevoegd.

Selecteer je bestaande **FOT-Rodin Pro DB** in de lijst. Als je een font toevoegt terwijl je speelt, open `/psf` opnieuw om de lijst te vernieuwen. Een ontbrekend of niet laadbaar geselecteerd font valt terug op het Blizzard-font. Font Manager kan bij een globale fontoverride opnieuw fonts wijzigen; controleer zijn instellingen als je selectie niet blijft staan.

## Glyphs en debug

`/psf` heeft vijf tabs: **General**, **Glyphs**, **Buttons**, **Theme** en **Debug**. In Glyphs klik je op de stijlknop om door de beschikbare stijlen te kiezen. Met plus/min en 100% verander of herstel je de grootte. De face-glyphstijl neemt de oude kleurinstelling over; fonts en andere bestaande instellingen blijven bewaard.

De Xbox-keuzes gebruiken Blizzard-atlases, ook als je actieve device-iconset anders is. **Blizzard default** volgt de native devicekeuze. Een niet beschikbare atlas wordt niet geforceerd. Native hover/pressed/active/disabled-states blijven bestaan; de addon verandert de status zelf niet. Aanpassingen wachten tot combat voorbij is.

In Debug toont **Refresh** de actuele waarden van de door PSF ontdekte oppervlakken. **Start tracing** registreert toekomstige setter-calls op die oppervlakken (bijvoorbeeld SetFont, SetAtlas, SetVertexColor en SetScale) met call stacks. Maximaal 40 recente calls worden in geheugen bewaard. **Stop tracing** stopt registratie; de veilige post-hooks blijven bestaan maar registreren niets. Tracing is standaard uit en wordt niet opgeslagen na reload.

Een stack toont code die bij een call betrokken is, geen volledige eigenaarshistorie en geen bewijs van een conflict. Wijzigingen vóór tracing, calls buiten de gevolgde setters en sommige native veranderingen kunnen niet worden toegeschreven. Debug verandert geen bindings, targeting of functies van andere addons. De tekst kan worden geselecteerd/gekopieerd voor diagnose.

In **Buttons** kies je Modern minimal of Blizzard borders. De toggle voor button skinning in General schakelt beide uit en herstelt de oorspronkelijke assets. Glyphs, cooldownfont en legendatheming zijn afzonderlijke instellingen. Instelbare **border-types van de legenda** staan op de lijst voor een volgende versie. Handmatige glyph-offsets en automatische ruimte in de legenda volgen afzonderlijk; zie issue #4.

## Questlog en minimapwissel — 0.4.3 alpha

De questskin bereikt nu ook de geneste detail-/rewardsvensters, zoekveld, categorieheaders en omlijsting van Map & Quest Log. Donkere panels, neutrale borders/knoppen en groene highlights gebruiken de bestaande native regels en controls. Questtags, objectives, tracking en selectie blijven native. De kaartcanvas, kaartpins en kaartbesturing worden niet gestyled of vervangen.

Bij ronde → vierkante minimap wordt zichtbaarheid na de kleurherstelling toegepast. Dat voorkomt dat het herstel van de ronde borderkleur diens alpha terugzet boven de vierkante kaart. Test meerdere rond/vierkantwissels met minimapskin voortdurend aan.

26 logictests slagen, inclusief alpha-reset door vertexkleuren en questdetails/herstel zonder kaartcanvaswijziging. De nieuwe questvormgeving en echte controllerfocus moeten nog in WoW worden getest. Radial theming en overige conceptafwerking blijven op de lijst.

## Ronde minimap — 0.4.2 alpha

Square minimap uit behoudt nu de minimapskin: de native ronde kaartmasker blijft, met een gedesatureerde grijze kompasrand. Minimap skin uit herstelt ook de oorspronkelijke randkleur en onderlaag. De ronde skin is een eerste uitvoering; decoratie rond de overige minimapknoppen wordt later afgewerkt.

## Debug-fix — 0.4.1 alpha

De Debug-tab controleert getterwaarden met `issecretvalue` voordat ze als tekst worden verwerkt. Afgeschermde waarden verschijnen als `[restricted]`; getters die niet gelezen kunnen worden als `[unavailable]`. Dit herstelt de gemelde concat-fout uit 0.4.0. De themavormgeving blijft in deze patch gelijk.

## Xbox-thema — 0.4.3 alpha

De **Theme-tab** schakelt ieder onderdeel apart: minimap, vierkante minimapvorm, player/pet/target/focus, questlog en tracker, chat en invoer, tooltips, lootvenster, item-loottoasts en het geselecteerde font voor deze vensters. De eerste themaversie gebruikt donkere antracietpanelen, dunne grijze randen en lichte tekst. De native indeling blijft staan; het conceptbeeld is een visuele richting, geen exacte schermreconstructie.

**Square minimap** verandert de daadwerkelijke kaartmasker naar vierkant, inclusief de hoeken. Uitschakelen herstelt de native ronde mask en kompasrand. De minimapskin moet hiervoor aan staan.

Het lootvenster krijgt compacte donkere itemkaarten in dezelfde stijl. Het gebruikt WoW's bestaande itemknoppen, kwaliteitsindicaties en controllerselectie. Dit is onze eigen skin van het native venster, geen overgenomen Plumber-code of nieuwe fast-lootfunctie.

De **eigen loot-toaster** leest ontvangen item-lootberichten, ook bij autoloot en gathering/mining. Maximaal drie kaarten verschijnen rechts met icoon, itemnaam, kwaliteit en aantal. Gelijke items worden kort samengevoegd. Gebruik **Preview item loot toasts** om de weergave te testen. Deze versie toont items; geld, XP, reputatie en valuta horen nog niet bij deze toaster. De native meldingen worden niet onderdrukt. De toaster is niet klikbaar en de positie is voorlopig vast.

Theming uit herstelt de opgeslagen visuals van de ontdekte elementen. Afzonderlijke ingebouwde status-/voertuig-/class-resource-elementen blijven native. Nieuwe of afwijkende vensters kunnen nog ongestylede onderdelen hebben. De skins vervangen geen native klikfuncties en voeren geen loot- of gamepad-interactie uit. **De volledige themaversie moet nog in de echte client worden getest**, inclusief secure/taintgedrag.

Na deze update **WoW volledig afsluiten en opnieuw starten**: de TOC laadt nieuwe Lua-bestanden. Open daarna `/psf` → Theme, test de vierkante kaart, elk venster, het uitschakelen per onderdeel, handmatig looten, autoloot en mining. Controleer daarna reload, combat en BugSack. De bestaande glyph-, cooldownfont- en legendatests blijven relevant.

## Legenda met de controller

Zoek **PadSkinForever → Toggle native input legend** in de keybindings en kies zelf een vrije controllerknop. De addon bindt geen toetsen automatisch en installeert geen override bindings.

De toggle gebruikt uitsluitend Blizzard's CVar **`GamepadShowPersistentInputLegend`**. Blizzard bepaalt vervolgens wanneer de legenda zichtbaar mag zijn. In bijvoorbeeld native menu's kan die verborgen blijven, ook wanneer de instelling aan staat.

De native gamepad-bindingstack kan voorrang hebben op gewone addonbindings. Deze eerste versie garandeert daarom nog niet dat de gekozen controllerbinding in elke context doorkomt. Test eerst `/psf legend`, vervolgens je gekozen knop in gameplay en menu's. De toggle wordt tijdens combat geweigerd met een chatbericht.

## Status en testen

Gebouwd na broncodecontrole van Forever **1.60.1 (70205)**, [Gethe/wow-ui-source, commit e3ecc27](https://github.com/Gethe/wow-ui-source/commit/e3ecc27). TOC-interface: **16001**.

Lokaal gecontroleerd: Lua 5.1-syntax, XML en 26 logictests, waaronder native assetherstel na vormwissels, glyphplaatsing/herstel, combat-uitstel, fonts, legenda en debug. De tester heeft in 0.2.0 de glyphkleuren en vergroting bevestigd, inclusief behoud van 150%/170% na reload. Legendatoggle, blauwe randen en FOT-Rodin-Pro-B.otf-cooldownfont waren eerder bevestigd; zie [issue #1](https://github.com/Wimterbourne/PadSkinForever/issues/1). **De tester heeft de verbeterde glyphposities, minimalistische borders en Xbox-borderkleuren bevestigd. De dikkere ronde borders uit 0.3.3 en de nieuwe themamodules uit 0.4.0 wachten nog op een test in WoW.** Mocks kunnen Blizzard's secure/taint-model niet reproduceren.

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
