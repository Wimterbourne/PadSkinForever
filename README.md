# PadSkinForever

Een zelfstandige skin voor de **native GamepadUI van World of Warcraft Forever**. Huidige testversie: **0.8.0-alpha**.

### Compacte unitframes — 0.8.0-alpha

Nieuwe PSF-weergavestijl: een vierkant playerportret met een healthbalk die even breed is als het portret, en een kleinere petvariant. Target en focus krijgen een horizontale healthregel met naam en portret; het native target-of-target krijgt dezelfde compacte balktaal. Mana en andere resources blijven in het centrale combatpaneel bij de swingtimers.

Onder `/psf` → Buttons → Unitframes kun je de compacte stijl aan/uit zetten en kiezen tussen 2D-portretten en een 3D PlayerModel. De laag bestaat uit muistransparante kinderen van de native unitbuttons; rootpositie, grootte, clicks, targeting en controllerbindings worden niet aangepast. **Edit Mode blijft de native roots verplaatsen.** De native selectierechthoek en clickruimte houden hun oorspronkelijke afmetingen; dit is nog geen nieuwe native compacte layout. Native contextual tekst/decoratie is in deze eerste compacte stijl verborgen; aparte PSF-statusiconen voor dood/offline/elite volgen nog. Party/raidframes vallen buiten deze stap.

Buff/debuff-iconen krijgen optioneel dezelfde sobere rand en font. Aanwezige native Essential/Utility/BuffIcon cooldown viewers kunnen eveneens geskind worden; ontbrekende viewers worden niet aangemaakt of geforceerd geladen. Indeling, cooldowns en bediening blijven native. Deze icon-skin is een eerste basis, geen herontwerp van de cooldownmanager.

**Herstart WoW volledig na ophalen**, vanwege de nieuwe Lua-module. Test 2D/3D, player/pet, vijand/vriendelijk target, target wisselen tijdens combat, target-of-target, native clicks/controller, Edit Mode, stijl uit/aan, buffs/debuffs, aanwezige cooldown viewers en BugSack. De ingame-test moet met name bevestigen dat de native chrome volledig is verdwenen en de compacte beelden op de gewenste posities staan. De lootwindow-verfijning blijft op de backlog.

### Gelijke resources en zichtbaarheid — 0.7.5-alpha

Player en pet gebruiken dezelfde 222 × 22 px health- en power-wells, identieke tekstmarges en een eigen portretkolom. Health blijft groen; power volgt het type (mana blauw, focus oranje, energy geel). De resourcefill gebruikt nu een native texturemask, zodat de afgeronde uiteinden ook werken zonder resource-geometrie in Lua uit te lezen. Waarden gaan rechtstreeks naar native FontString-formattering.

Buiten combat vervaagt het PSF-resourcepaneel standaard naar 20% alpha. Onder `/psf` → Buttons → Combat HUD kan dit worden gewisseld naar volledig verborgen of altijd zichtbaar. Tijdens combat en Edit Mode verschijnt het op volle sterkte. Dit geldt uitsluitend voor de PSF player/pet-resources; native swingtimer-zichtbaarheid blijft bij Blizzard.

Deze versie bevat een nieuwe texture. **Sluit WoW volledig en start opnieuw na het ophalen**, zodat de client die kan laden. Test gelijke afmetingen, ronde vullingen, waarden, pet oproepen/wegsturen, combat in/uit, alle drie zichtbaarheidstanden en Edit Mode buiten combat. Controleer BugSack.

### Centrale HUD-correcties — 0.7.4-alpha

De afgeronde vulling tekent nu op een eigen, muistransparante laag boven de native statusbar. Labels staan op een volgende laag, zodat kleurvulling geen tekst meer bedekt. De ronde uiteinden gebruiken de halve balkhoogte als radius; bij bijna lege vullingen krimpt die radius mee. De native geometrie en timerwaarden blijven leidend.

De uitstekende native swingtimer-pip is verborgen wanneer de PSF-skin actief is. Uitschakelen herstelt de oorspronkelijke pip-alpha en de oorspronkelijke ouders van de native labels. Range-dimming blijft via de gemeenschappelijke statusbar-parent werken. Edit Mode-posities blijven behouden.

Test na `/reload`: zichtbare resource-labels en waarden, ronde uiteinden bij volle/halfvolle/bijna lege balken, ranged tijdens aanvallen, range-dimming, en swingtimerskin uit/aan. De visuele uitkomst moet ingame worden bevestigd.

### Centrale HUD-balken — 0.7.3-alpha

Player/pet-resources en de drie native swingtimers krijgen nu ook **afgeronde vullingen**. Ze volgen de afmetingen van de bestaande statusbartexture, met vaste hoekstukken die bij een bijna lege balk automatisch kleiner worden. Een lege balk toont alleen de donkere achtergrond. De native statusbar blijft waarden en interpolatie berekenen; range-dimming van swingtimers blijft via de native statusbar-alpha werken. Uitschakelen van de swingtimerskin herstelt de oorspronkelijke texture-alpha.

De playerregel krijgt 22 px hoge wells, de compactere petregel 20 px. Beide gebruiken 8 px tekstmarges en afzonderlijke ruimte voor labels en waarden. Health, mana en petresources behouden hun semantische kleuren. De gecombineerde PSF-module blijft selecteerbaar en verplaatsbaar via Edit Mode; de drie swingtimers behouden hun eigen native posities en afmetingen.

Na ophalen volstaat `/reload`. Test volle, halfvolle, bijna lege en lege resources, pet oproepen/wegsturen, Edit Mode, een echte swing/ranged-aanval, out-of-range-dimming en swingtimerskin uit/aan. Controleer BugSack en het behoud van de layout na reload. Deze stap betreft het centrale HUD-blok; unitframes, nameplates en overige balken volgen nadat deze basis ingame is bevestigd.

### Native selectie en raster — 0.7.2-alpha

Het PSF player/pet-resourcepaneel gebruikt in Edit Mode nu Blizzards eigen selectie-artwork. Klik of tik het paneel om het daadwerkelijk te selecteren en sleep het daarna zoals een normaal Edit Mode-element. Wanneer **Snap to grid** in Edit Mode aan staat, wordt het midden van het paneel bij loslaten op de dichtstbijzijnde zichtbare rasterlijn vastgezet. Elke actieve Edit Mode-layout krijgt een eigen opgeslagen PSF-positie; bestaande 0.7.1-posities blijven als uitgangspunt behouden.

PSF registreert nog steeds geen nieuw systeem in Blizzards private layouttabellen en roept geen gamepadfocus- of protected interact-functies aan. De selectie en rasterafronding beheren uitsluitend het PSF-frame.

Dezelfde versie introduceert de vaste semantische balktaal uit het HUD-concept: zachte antraciete capsules met een subtiele, transparante rand. Swingtimers zijn neutraal zilvergrijs; health is groen, mana blauw, energy geel, rage rood, focus oranje en verwante resources volgen dezelfde centrale PSF-palette. De player/pet-module en de drie losse swingtimers horen daardoor zichtbaar bij één familie zonder hun zelfstandige Edit Mode-posities te verliezen. Ook de generieke themepanelen gebruiken nu de zachtere afgeronde rand in plaats van een harde rechthoek.

### Eerste Edit Mode-selectie — 0.7.1-alpha

De eerste versie gaf het PSF player/pet-resourcepaneel een eigen groene sleeplaag. In 0.7.2 is die vervangen door native selectie-artwork, een geselecteerde toestand, raster-snapping en posities per actieve Edit Mode-layout.

PSF registreert het paneel niet met Blizzards private `EditModeManagerFrame:RegisterSystemFrame()` en schrijft niet naar de native layouttabellen. Daarmee vermijden we taint en de eerder aangetroffen protected-actionproblemen. Het paneel wordt dus binnen Edit Mode beheerd, maar verschijnt niet in Blizzards eigen systeeminstellingendialoog.

### Combat HUD en Edit Mode — 0.7.0-alpha

De drie native swingtimers krijgen nu één uniforme PSF-skin met een donker afgerond paneel, vlakke groene timerbalk en PSF-font. **Main Hand, Off Hand en Ranged blijven drie zelfstandige Blizzard Edit Mode-systemen**: PSF verandert hun volgorde, positie, schaal, breedte, hoogte, titel, tijd of zichtbaarheid niet. Native range-dimming en timerberekening blijven behouden. De skin kan afzonderlijk worden uitgeschakeld en herstelt dan de Blizzard-presentatie.

Omdat Forever de Personal Resource Display voor deze spelmodus niet beschikbaar stelt, voegt PSF een uitsluitend informatief player/pet-resourcepaneel toe. Het toont player health en power plus, wanneer aanwezig, pet health, power en portret. Het voert geen targeting, clicks of beschermde acties uit. Open Blizzard Edit Mode om dit PSF-eigen paneel met muis of touch te verslepen; de positie wordt in `PadSkinForeverDB` bewaard. PSF registreert het paneel bewust niet in Blizzards interne Edit Mode-systeemlijst.

Open `/psf` → **Buttons** → **Combat HUD** om de swingtimerskin en resourceweergave afzonderlijk aan of uit te zetten. Een wijziging van een native Edit Mode-layout vraagt alleen een nieuwe visuele refresh aan; PSF roept geen `SetPoint` of `SetScale` aan op de swingtimerframes.

### Logo en focus — 0.6.6-alpha

Het vaste PSF-logo is concept 03: de platte infinity-controller met geïntegreerde P en S. De echte vector-master staat in `PadSkinForever/Media/PSFLogo.svg` (uitsluitend paden, transparant, geen ingebedde bitmap). De addon gebruikt de meegeleverde transparante TGA in het instellingenvenster, de ESC-kaart, de eigen legendakop en loot-toasts. `python tools/generate_brand_assets.py` rendert de textures opnieuw met Inkscape en Pillow.

De geïsoleerde controllerbediening heeft nu een eigen mintgroene focuschevron. Die volgt de geselecteerde PSF-control, inclusief gescrolde fontregels, en verdwijnt bij sluiten of combat. Blizzards gele focuscursor blijft ongewijzigd; PSF roept geen native focus- of gamepadbindingmanager aan. De launcher blijft bewust **naast** de rode menukolom. Een mockup met een knop in de rode kolom was geen weergave van de implementatie.

## Wat zit erin?

- Een **Modern minimal** knopstijl: eigen dunne borders (grijs voor D-pad, Xbox-kleuren voor A/B/X/Y) en donkere neutrale lege slots, in de bestaande ronde/vierkante vorm. **Blizzard borders** behoudt de oorspronkelijke textures met blauwe tint. Beide vallen onder de schakelaar voor button skinning.
- In 0.3.3 zijn alleen de ronde borders dikker: 3 texturepixels in plaats van 1,5. Dat geeft bij circa 48 px knopgrootte ongeveer 1 px extra; de zichtbare dikte hangt af van je UI-schaal. Vierkante borders blijven gelijk.
- Actionbar-glyphs behouden de native kant/hoek. Bij vergroten schuiven ze mee zodat de binnenrand op zijn oorspronkelijke positie blijft; alle glyphs naar dezelfde rechterbovenhoek verplaatsen veroorzaakte overlap in 0.3.0. Zet **Move enlarged glyphs outward from their native anchor** uit om de native positie terug te krijgen. Legenda-glyphs krijgen een eigen uitgelijnde layout wanneer legendatheming aan staat.
- **Vivid glyph colors** gebruikt de gekleurde glyphtextures met volledige opacity, naast meer verzadigde Xbox-kleurtinten. Dit is afzonderlijk uit te zetten; native status en disabled-artwork blijven behouden.
- Disabled-glyphhelderheid naar keuze: **45%, 70% of 100%** van de tint (standaard 70%). De native disabled-status en artwork blijven bestaan.
- A/B/X/Y-glyphkeuze: **Blizzard standaard**, **Xbox monochroom** of **Xbox gekleurd** (A groen, B rood, X blauw, Y geel). De gekleurde disabled-toestand blijft gedimd; Blizzard bepaalt de interactiestatus.
- D-pad-iconkeuze: **Blizzard standaard**, **Xbox monochroom** of **Xbox blauw**.
- Onafhankelijke groottes voor A/B/X/Y en D-pad: **50–200%**. Deze keuzes gelden voor de vier actionbars én voor de legenda wanneer legendatheming aan staat.
- Een cooldownfont naar keuze, met grootte en outline. Fonts uit **LibSharedMedia** en **Font Manager** verschijnen in de fontlijst. Een werkend geregistreerd `.otf`-font kan direct worden gekozen.
- Een donkere inputlegenda met afgeronde hoeken, grijze rand, geselecteerd font en instelbare tekstgrootte, glyphschaal, regelafstand en binnenmarge. De rijhoogte en paneelafmetingen volgen de inhoud.
- **Legendatheming aan/uit**: uit herstelt onze wijzigingen één keer, waarna de legenda niet opnieuw wordt gestyled. De native legendatoggle blijft apart bruikbaar.
- Een **Debug-tab** met huidige atlas-/font-/kleur-/schaalwaarden en optionele tracing van toekomstige visuele wijzigingen.
- Een eigen, standaard ongebonden keybinding om de native legenda aan/uit te zetten.
- Een eigen, controllerbedienbaar PSF-instellingenvenster in dezelfde donkere vormentaal als de inputlegenda.
- Instellingen via de veilige **PadSkinForever-knop naast het ESC-menu**, **`/psf`** of **`/padskin`**; **`/psf legend`** schakelt de legenda om.

De addon verandert geen actionbar-indeling, spells, targeting, loot-acties of native navigatie. De Theme-modules stylen de bestaande vensters; native schermposities blijven behouden. De minimalistische knopstijl gebruikt zes eigen gegenereerde knoptextures en twee legenda-hoektextures. Glyphs gebruiken Blizzard-atlases. Geen Masque-installatie nodig; bestaande Masque-skinpakketten worden niet ingelezen.

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

## Kaartoverlay en ronde rand — 0.4.4 alpha

De buitenrand van Map & Quest Log heeft nu uitsluitend een outline, zonder donkere vulling die boven de kaartcanvas terechtkwam. Questpaneelachtergronden blijven afzonderlijk. De minimap bewaart dezelfde kleurregistratie bij beide vormen, zodat herhaalde refreshes in ronde modus de compassrand niet opnieuw op alpha 0 zetten. Beide regressies zijn opgenomen in de bestaande tests; runtimecontrole blijft nodig.

## Questlog en minimapwissel — 0.4.3 alpha

De questskin bereikt nu ook de geneste detail-/rewardsvensters, zoekveld, categorieheaders en omlijsting van Map & Quest Log. Donkere panels, neutrale borders/knoppen en groene highlights gebruiken de bestaande native regels en controls. Questtags, objectives, tracking en selectie blijven native. De kaartcanvas, kaartpins en kaartbesturing worden niet gestyled of vervangen.

Bij ronde → vierkante minimap wordt zichtbaarheid na de kleurherstelling toegepast. Dat voorkomt dat het herstel van de ronde borderkleur diens alpha terugzet boven de vierkante kaart. Test meerdere rond/vierkantwissels met minimapskin voortdurend aan.

36 logictests slagen, inclusief alpha-reset door vertexkleuren, questdetails/herstel zonder kaartcanvaswijziging en de Edit Mode-veilige swingtimer/resourceweergave. De controllerfocus van het PSF-venster is in WoW bevestigd. Radial theming en overige conceptafwerking blijven op de lijst.

## Ronde minimap — 0.4.2 alpha

Square minimap uit behoudt nu de minimapskin: de native ronde kaartmasker blijft, met een gedesatureerde grijze kompasrand. Minimap skin uit herstelt ook de oorspronkelijke randkleur en onderlaag. De ronde skin is een eerste uitvoering; decoratie rond de overige minimapknoppen wordt later afgewerkt.

## Debug-fix — 0.4.1 alpha

De Debug-tab controleert getterwaarden met `issecretvalue` voordat ze als tekst worden verwerkt. Afgeschermde waarden verschijnen als `[restricted]`; getters die niet gelezen kunnen worden als `[unavailable]`. Dit herstelt de gemelde concat-fout uit 0.4.0. De themavormgeving blijft in deze patch gelijk.

## Xbox-thema — 0.4.4 alpha

De **Theme-tab** schakelt ieder onderdeel apart: minimap, vierkante minimapvorm, player/pet/target/focus, questlog en tracker, chat en invoer, tooltips, lootvenster, item-loottoasts en het geselecteerde font voor deze vensters. De eerste themaversie gebruikt donkere antracietpanelen, dunne grijze randen en lichte tekst. De native indeling blijft staan; het conceptbeeld is een visuele richting, geen exacte schermreconstructie.

**Square minimap** verandert de daadwerkelijke kaartmasker naar vierkant, inclusief de hoeken. Uitschakelen herstelt de native ronde mask en kompasrand. De minimapskin moet hiervoor aan staan.

Het lootvenster krijgt compacte donkere itemkaarten in dezelfde stijl. Het gebruikt WoW's bestaande itemknoppen, kwaliteitsindicaties en controllerselectie. Dit is onze eigen skin van het native venster, geen overgenomen Plumber-code of nieuwe fast-lootfunctie.

De **eigen loot-toaster** leest ontvangen item-lootberichten, ook bij autoloot en gathering/mining. Maximaal drie kaarten verschijnen rechts met icoon, itemnaam, kwaliteit en aantal. Gelijke items worden kort samengevoegd. Gebruik **Preview item loot toasts** om de weergave te testen. Deze versie toont items; geld, XP, reputatie en valuta horen nog niet bij deze toaster. De native meldingen worden niet onderdrukt. De toaster is niet klikbaar en de positie is voorlopig vast.

Theming uit herstelt de opgeslagen visuals van de ontdekte elementen. Afzonderlijke ingebouwde status-/voertuig-/class-resource-elementen blijven native. Nieuwe of afwijkende vensters kunnen nog ongestylede onderdelen hebben. De skins vervangen geen native klikfuncties en voeren geen loot- of gamepad-interactie uit. **De volledige themaversie moet nog in de echte client worden getest**, inclusief secure/taintgedrag.

Na deze update **WoW volledig afsluiten en opnieuw starten**: de TOC laadt nieuwe Lua-bestanden. Open daarna `/psf` → Theme, test de vierkante kaart, elk venster, het uitschakelen per onderdeel, handmatig looten, autoloot en mining. Controleer daarna reload, combat en BugSack. De bestaande glyph-, cooldownfont- en legendatests blijven relevant.

## PSF-menu — 0.6.5-alpha

Het `/psf`-venster gebruikt dezelfde antracietvulling, afgeronde grijze 1px-rand, groene focusaccenten en Inter-typografie als de vernieuwde inputlegenda. De rustige toestand is vlak: tabs gebruiken een groene onderstreep, instellingen tonen alleen onder focus een groene zijstrook en de fontlijst vormt één doorlopend vlak. Alleen echte actieknoppen behouden een compacte omlijning. Tabs, knoppen, vinkjes en fontregels zijn addon-eigen controls en worden door PSF's geïsoleerde controllerlaag bediend.

Naast het native ESC-menu staat een brede **PadSkinForever**-kaart met PSF-badge, `ADDON SETTINGS` en een groen `A OPEN`-label. De sterkere groene rand licht verder op onder controllerfocus. De kaart staat bewust buiten de rode kolom en buiten `GameMenuFrame.buttons`: die lijst en de navigatieroutes van zijn knoppen worden door Blizzard gepoold en zijn gekoppeld aan de beschermde gamepadbindingstack. Vanaf 0.6.4 schrijft PSF daarom geen enkele route, hook of waarde meer naar een Blizzard-knop. SmartNavigation vindt de zichtbare PSF-kaart uitsluitend op basis van zijn positie naast het menu.

Vanaf 0.6.5 registreert PSF zijn instellingenvenster nadrukkelijk **niet** als Blizzard-UIPanel. De Forever-bèta liet zowel `FrameShown/FrameHidden` als `ShowUIPanel/HideUIPanel` uiteindelijk via de native bindingstack bij `SetPreferredGamepadInteractTarget()` uitkomen en schreef die beschermde call aan PSF toe. PSF raakt daarom geen `FrameControlsManager`, SmartNavigation-routes of native bindinggroep meer aan.

In plaats daarvan routeert een eigen secure binding-owner alleen D-pad, A en B tijdelijk naar zes PSF-knoppen. De focus beweegt uitsluitend over zichtbare PSF-controls; de fontlijst scrollt mee. B sluit PSF en geeft de controller direct terug aan het rode menu. Een secure combat-state-driver wist de tijdelijke routes vóór addoncode door combat lockdown kan worden geblokkeerd. Tijdens combat weigert de kaart het openen. De bestaande `/psf`-route blijft beschikbaar.

Kom je van een versie ouder dan 0.6.0, sluit WoW dan volledig af omdat `UI.lua` en `GameMenu.lua` nieuwe bestanden zijn. Vanaf 0.6.0 of 0.6.1 volstaat ophalen en `/reload`. Test daarna:

1. Na `/reload` eerst ESC openen en direct een native rode knop zoals **Options** activeren; controleer dat BugSack stil blijft.
2. ESC opnieuw openen, zijwaarts naar **PadSkinForever** navigeren en bevestigen.
3. Met D-pad door tabs, vinkjes, de fontlijst, plus/min, **Cooldown: Outline** en **Toggle native legend** navigeren; A moet elke focusbare regel activeren.
4. PSF met B sluiten, ESC opnieuw openen en weer een native rode knop activeren.
5. Herhalen na meerdere open-/sluitcycli en vóór/na combat. Als combat start terwijl PSF open is, moet PSF sluiten en de tijdelijke controllerroute loslaten. Controleer vooral op `ADDON_ACTION_FORBIDDEN` en `SetPreferredGamepadInteractTarget()`.

## Meegeleverd font — 0.5.2-alpha

**PSF Inter Regular** en **PSF Inter SemiBold** zijn direct beschikbaar in General, ook zonder Font Manager of LibSharedMedia. Als LibSharedMedia aanwezig is, worden beide daar geregistreerd. Kies Regular voor de regels; de legenda gebruikt dan automatisch SemiBold voor de titel en native groepskoppen. Andere fontkeuzes blijven behouden en gebruiken hun eigen font voor de kop.

De twee ongewijzigde statische TTF-bestanden komen uit [Inter 4.1](https://github.com/rsms/inter/releases/tag/v4.1), door The Inter Project Authors. Ze vallen onder de SIL Open Font License 1.1, meegeleverd in `PadSkinForever/Media/Fonts/LICENSE-Inter.txt`. Het MIT-licentiebeleid van de addon geldt niet voor deze fonts. Er worden geen variabele fonts, Windows-systeemfonts of fonts van de gebruiker meegeleverd.

Na ophalen: start WoW volledig opnieuw voor de nieuwe fontbestanden, kies **PSF Inter Regular** in `/psf` → General en controleer de legenda, modifierkoppen, cooldowns, theming uit/aan en `/reload`. Bestaande FOT-Rodin-instellingen worden niet automatisch vervangen.

## Inputlegenda — 0.5.1-alpha

Screenshotcorrecties na 0.5.0: rechte randstukken krijgen expliciet een dikte van 1 UI-eenheid, passend bij de afgeronde hoeken. De gecombineerde LB+RB-kop bepaalt niet langer de inspringing van de labels eronder. De tester heeft de interne uitlijning en het meegroeien bij 170%/150% glyphs bevestigd. Een eigen PSF-icoon in de kop is een volgende ontwerpstap.

Open `/psf` → General → **Legend style and spacing...** (ook bereikbaar via Theme).

De legenda gebruikt een eigen donker paneel met afgeronde hoeken en een grijze rand. De tekst gebruikt het geselecteerde SharedMedia/Font Manager-font, met een eigen tekstgrootte. **All legend glyphs** schaalt ook de schouder- en stickiconen, uitsluitend in de legenda. Dit vermenigvuldigt de A/B/X/Y- en D-pad-grootte uit Glyphs. Elke regel reserveert ruimte voor de grootste geschaalde glyph, divider of tekst op die regel, plus de instelbare regelafstand. De binnenmarge, achtergrondhoogte en kolombreedtes groeien mee. Tekstlabels zijn per kolom uitgelijnd.

Blizzard houdt controle over de inhoud, modifiergroepen, disabled-alpha en zichtbaarheid. Theming uit herstelt de native geometrie, fonts en decoraties. Geen nieuwe controllerbinding of promptactie. Wijzigingen wachten tot combat voorbij is.

**WoW volledig opnieuw starten** om `Legend.lua` en de nieuwe textures te laden. Test:

1. Normale legenda en groepen bij LB, RB, LB+RB en HUD/menucontext.
2. Alle legendaglyphs op 50%, 100% en 200%; combineer met A/B/X/Y- en D-pad-groottes. Controleer regelafstand, kolommen en glyph/tekst-overlap.
3. Verander tekstgrootte, regelafstand en binnenmarge, telkens groter én kleiner.
4. Controleer twee-iconenregels, lange labels en native gedimde prompts.
5. Zet theming uit en weer aan, daarna `/reload`: geen maatdrift, oorspronkelijke opmaak bij uitschakelen en behoud van keuzes.
6. Houd een modifier vast tijdens combat. Controleer dat native prompts blijven werken en uitgestelde stijlwijzigingen na combat worden toegepast.
7. Controleer BugSack op nieuwe fouten. De Lua-mocks testen layoutlogica en herstel, niet Blizzard's secure/taint-model.

## Legenda met de controller

Zoek **PadSkinForever → Toggle native input legend** in de keybindings en kies zelf een vrije controllerknop. De addon bindt geen toetsen automatisch en installeert geen override bindings.

De toggle gebruikt uitsluitend Blizzard's CVar **`GamepadShowPersistentInputLegend`**. Blizzard bepaalt vervolgens wanneer de legenda zichtbaar mag zijn. In bijvoorbeeld native menu's kan die verborgen blijven, ook wanneer de instelling aan staat.

De native gamepad-bindingstack kan voorrang hebben op gewone addonbindings. Deze eerste versie garandeert daarom nog niet dat de gekozen controllerbinding in elke context doorkomt. Test eerst `/psf legend`, vervolgens je gekozen knop in gameplay en menu's. De toggle wordt tijdens combat geweigerd met een chatbericht.

## Status en testen

Gebouwd na broncodecontrole van Forever **1.60.1 (70205)**, [Gethe/wow-ui-source, commit e3ecc27](https://github.com/Gethe/wow-ui-source/commit/e3ecc27). TOC-interface: **16001**.

Lokaal gecontroleerd: Lua 5.1-syntax, XML en 36 logictests, waaronder native assetherstel na vormwissels, glyphplaatsing/herstel, combat-uitstel, fonts, legenda, debug en behoud van native swingtimerankers. De tester heeft in 0.2.0 de glyphkleuren en vergroting bevestigd, inclusief behoud van 150%/170% na reload. Legendatoggle, blauwe randen en FOT-Rodin-Pro-B.otf-cooldownfont waren eerder bevestigd; zie [issue #1](https://github.com/Wimterbourne/PadSkinForever/issues/1). Mocks kunnen Blizzard's secure/taint-model niet reproduceren; test deze nieuwe Combat HUD daarom ook ingame met BugSack.

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

Vanaf **0.6.5-alpha** blijft het instellingenvenster volledig buiten Blizzards UIPanel-, `FrameControlsManager`- en SmartNavigation-stack. Een PSF-eigen secure binding-owner onderschept D-pad, A en B alleen zolang het venster open is en wist zijn routes automatisch bij sluiten of combat. De visuele focus wordt door PSF zelf over uitsluitend eigen zichtbare controls verplaatst. Dit vervangt de 0.6.4-route via `ShowUIPanel`/`HideUIPanel`, die in de Forever-bèta alsnog de beschermde `SetPreferredGamepadInteractTarget()` liet uitvoeren onder PSF-attributie.

Test `/psf` → je bestaande interfacefocusknop; navigeer naar tabs, vinkjes, plus/min-knoppen en fontlijst, bevestig een keuze en sluit met B. Herhaal openen/sluiten en controleer andere native vensters en BugSack, met name `SetPreferredGamepadInteractTarget()`.

## Ontwikkeling

```sh
python -m pip install -r tests/requirements.txt
python tests/test_addon.py
```

Eigen knoptextures opnieuw genereren: `python tools/generate_button_assets.py` (geen extra dependencies).

Runtimecode staat in `PadSkinForever/`. De tests en Python-dependency hoeven niet in je AddOns-map.

Referenties: Blizzard's `Blizzard_GamepadActionBars`, `Blizzard_Gamepad/UI/PersistentInputLegend` en `Blizzard_SharedXML/Shared/InputIcons`. Inked4GamePadUI is onderzocht voor de skin-aanpak; deze repository bevat geen gekopieerde Inked- of Font Manager-code/assets.

MIT-licentie, zie [LICENSE](LICENSE).
