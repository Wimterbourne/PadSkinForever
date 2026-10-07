# PadSkinForever Design Philosophy

## North Star

PadSkinForever is a controller-first presentation layer for World of Warcraft: Forever.

The visual target is a deliberate mash-up of **WoW Forever** and the **physical/form language of an Xbox controller**, reduced through a minimalist mindset. It should feel as if Forever had shipped with a purpose-built modern console UI: unmistakably Warcraft in information and world presence, unmistakably Xbox in interaction language, geometry and hierarchy.

PSF enhances presentation; Blizzard/Forever remains authoritative for native layout, secure gameplay, controller navigation, targeting, loot interaction, bindings and protected behavior wherever a native solution exists.

## Baseline constraints

- Design for the real game at **1920x1080**.
- Assume WoW UI scale is approximately **0.9–1.0**. Never depend on unusually low UI scaling to create space.
- Preserve a large, quiet world viewport. The character, target and environment must remain the visual center.
- Prefer Blizzard Edit Mode/native anchors for placement. PSF should perfect component appearance rather than hard-code a mockup layout.
- Information gets one dominant home; avoid redundant large readouts.

## Screen hierarchy

### Top left — identity/status
Player and pet frames are compact identity/status frames, not primary resource displays.
- compact square/soft-square portrait;
- name/level where useful;
- buffs/debuffs attached cleanly;
- pet happiness/status icon is skinned and integrated into the same component;
- no large player/pet health or power bars here.

Party frames continue downward using the same compact visual language.

### Top center — target
Target presentation borrows the hierarchy of a minimalist boss-health bar:
- long, very thin horizontal health bar;
- small portrait integrated at one end;
- target name and level/status kept restrained;
- buffs/debuffs in a compact row directly below;
- target-of-target is substantially smaller and secondary.

The target frame must never become a large traditional WoW unit card.

### Bottom center — combat cockpit
This is the primary combat-information block and the visual bridge to native GamepadUI.
- PSF player/pet health and resource rows are the authoritative glanceable self-status display;
- native swing timers sit with them as one coherent central block;
- action bars/controller glyphs continue immediately below;
- spacing and silhouettes should make the whole area read as one controller-inspired cockpit without turning it into one giant panel.

### Top right — navigation/objectives
Minimap and objectives form one quiet right-side information column. Reduce chrome and vertical bulk while preserving native information and interaction.

### Bottom corners
Chat lives bottom-left and damage/details-style information bottom-right. Both are peripheral, dark/translucent and visually subordinate to gameplay.

### Bottom edge
XP/progress is extremely thin and low-profile across the bottom edge.

## Xbox form language

Do not merely add Xbox button icons to a WoW skin. The **controller itself is a shape reference**.

- Rounded controller-shell curves inspire panel corners and outer silhouettes.
- Thumbstick/button wells inspire recessed resource wells, aura sockets and compact circular status elements.
- Shoulder/trigger geometry inspires short edge caps, grouped action areas and subtle stepped transitions.
- D-pad geometry can inspire directional/focus affordances, but should not become decorative clutter.
- Components should use soft, continuous curves with purposeful breaks rather than generic rounded rectangles everywhere.
- Thin lines, restrained edge highlights and small illuminated accents should suggest molded controller seams.
- Group related controls visually the way physical controls are grouped on a controller.

The result must remain flat enough to belong in WoW: no photorealistic plastic, fake 3D controller shell or excessive neon.

## Color language

Color communicates meaning through three separate layers:

1. **Class color = identity.** Glass-edge accents on player-owned identity surfaces use the player's class color. For other player units, use that unit's class color where known. NPCs do not inherit the player's class color.
2. **Resource/status color = state.** Health green, mana blue, focus orange, energy yellow, rage red, neutral timers/rails silver/graphite. Reaction, threat and encounter states keep their own semantic meaning.
3. **Xbox ABXY color = input.** A green, B red, X blue, Y yellow. These colors belong to controller actions and must not become general decoration.

PSF focus/selection remains a distinct controlled mint cue where a controller focus state needs to be communicated. Class-colored glass edges are identity, not selection.

## Spatial glass language

PSF borrows the useful visual principles of modern spatial Xbox UI without copying a floating-window layout.

- Surfaces feel lightly suspended over the world through translucency, restrained depth and selective edge light.
- Prefer floating components and connected rails over stacks of rectangular panels.
- Borders may fade or strengthen along a contour instead of outlining every surface uniformly.
- Thin luminous edge segments should resemble molded controller seams.
- Depth establishes hierarchy: combat-critical elements are visually nearer/clearer; peripheral chat/objective information is quieter.
- Do not use heavy blur, excessive glow, fake glass reflections or photorealistic plastic.
- At 1080p the treatment must remain crisp and readable; spatial styling may never depend on tiny text or excessive transparency.

## Unit Frames & Nameplates

### Core information rule

**Information is shown by relevance, and every piece of information should have one dominant home.**

Unit frames communicate identity and important unit state. Nameplates communicate immediate tactical world information. The target frame bridges the two.

### Player frame

The player frame at top-left is an identity/status component, not a second combat dashboard.

Show:
- square/soft-square portrait as the dominant shape;
- player name;
- level only where useful;
- relevant buffs/debuffs attached as compact icon sockets;
- class-colored glass-edge accent.

Do not show prominent health or power bars. The central combat HUD is the primary source for the player's health/resources.

### Pet frame

The pet frame uses the same compact identity language.

Show:
- portrait;
- name;
- relevant buffs/debuffs;
- pet happiness/status.

The native pet happiness icon should be skinned/integrated as a small controller-like status socket rather than floating as an unrelated Blizzard icon. Pet identity should not blindly inherit the player's class-color accent.

### Party frames

Party frames continue vertically from the identity area but must carry more state because party health is not represented in the central HUD.

Show:
- compact portrait;
- name;
- one thin health rail;
- relevant debuffs/status.

Power is optional and should only appear where it provides useful gameplay information. Debuffs take priority over decorative/full buff lists.

The glance test is: **who is this, how healthy are they, and is something wrong?**

### Target frame

The target frame is a minimalist boss-health hierarchy rather than a conventional WoW unit card.

Show:
- small portrait/socket at one end;
- target name;
- level/elite/boss status where relevant;
- long, very thin health rail;
- compact buffs/debuffs directly below.

Own player/pet/vehicle debuffs receive priority, followed by other relevant effects. Target-of-target is substantially smaller and secondary.

Normal targets remain sparse. Elite/boss targets may reveal additional encounter-relevant state without changing into a different visual system.

### Nameplates

Nameplates belong in the world and must be more aggressively minimal than unit frames.

A normal hostile nameplate primarily shows:
- name;
- thin health rail;
- only immediately relevant state.

Do not add portraits, large background cards, resource bars, full aura grids or redundant metadata by default.

Information scales with relevance:
- neutral/unimportant NPC: name, and health only if useful;
- hostile unit: name + thin health rail;
- current target: stronger rail + controller focus brackets;
- quest unit: small quest-status indicator;
- elite/boss: name + health + elite/boss status;
- casting enemy: temporary cast rail becomes prominent;
- important debuff: compact relevant aura indicator only;
- friendly player: name + class identity, health where relevant;
- party member in world: restrained group indicator;
- dead unit: heavily reduced/dimmed presentation.

Twenty nearby enemies must not create twenty full UI panels.

### Controller target/focus language

Selection should use compact geometric **focus brackets** around or adjacent to the health rail, inspired by Xbox focus/navigation geometry. Avoid a thick glowing rectangle around the entire nameplate.

The bracket can strengthen while actively controller-targeted and recede when not selected.

Class color is never a universal target-selection color. Class color communicates identity; reaction/threat/health/focus retain their own semantics.

### Casts and auras

For world nameplates, casts are generally more important than aura volume.

- Enemy casts appear as a second thin rail associated with the health rail.
- Interruptibility must be immediately distinguishable without excessive color/glow.
- Nameplate aura display is deliberately filtered.
- Player-owned combat-relevant effects may appear as compact icons/status sockets.
- Do not reproduce a full target-frame aura grid on every nameplate.

### Shared component grammar

Unit frames, target frames and nameplates use the same visual vocabulary at different information densities:

- **portrait/socket** = identity;
- **thin rail** = measurable state;
- **small socket/icon** = status;
- **class-colored glass edge** = class identity;
- **semantic fill color** = resource/reaction/threat/status;
- **focus bracket** = controller selection;
- **ABXY color** = controller action only.

This shared grammar should make the HUD feel like one system without forcing every component into the same box.

## Surfaces and lines

- Base surfaces: dark anthracite/graphite, translucent where world readability permits.
- Borders: thin neutral grey, low contrast.
- Identity surfaces: selective glass-edge accent using the appropriate class color.
- Active/focused state: controlled mint highlight, not a glowing frame around everything.
- Resource/status wells: dark recessed rails with semantic fill.
- Use negative space before adding another container.
- Avoid stacks of independent black boxes.
- Avoid heavy Warcraft ornamental frames unless native context requires them.
- The PSF infinity mark is identity branding, not a repeated watermark.
- **Branding rule:** use the canonical `PadSkinForever/Media/PSFLogo.svg` artwork (and its runtime TGA export) wherever a PSF brandmark is needed. Never substitute an Xbox logo or a text-only `PSF` approximation. The logo itself remains flat/clean and does **not** receive glass, glow, class-color edge, or spatial-surface treatment.

## Typography

Inter is the PSF UI voice where safe/available.
- concise labels;
- strong numeric readability;
- restrained hierarchy;
- no oversized headings in gameplay;
- readable at 1080p and UI scale 0.9–1.0.

## Controller interaction language

The UI should be understandable from the controller before reading help text.
- glyphs are primary input cues;
- A = confirm/action, B = back/cancel, X/Y = contextual actions as assigned by native GamepadUI;
- PSF focus is visibly distinct from Blizzard's native yellow focus where both exist;
- controller navigation remains native unless PSF owns the interface being navigated.

## Minimalism rules

1. The world is the hero.
2. Every large element must earn its screen area.
3. Do not duplicate information at equal visual weight.
4. Use one component family across HUD, menus and notifications.
5. Color has semantic purpose.
6. Prefer a line, well or icon over another panel.
7. Preserve native behavior before replacing it.
8. At 1080p/0.9–1.0 scale, readability wins over fitting more elements.
9. Information density increases only with gameplay relevance.

## Concept-image prompt

Use this as the canonical visual-generation prompt and update this document when the design direction changes:

> Create a 1920x1080 in-game concept for PadSkinForever, a minimalist controller-first UI for World of Warcraft: Forever. Preserve the recognizable WoW world and native GamepadUI composition, but translate the visual language through the forms and lines of a modern Xbox controller. The Xbox controller is a geometry reference, not a decorative object: use soft controller-shell curves, recessed thumbstick/button-like wells, thin molded seam lines, restrained shoulder/trigger-inspired edge shapes, circular status sockets and clear grouped controls. Add a restrained modern spatial-Xbox surface language: translucent graphite glass, selective luminous edge segments, floating connected rails and subtle depth hierarchy without heavy blur or fake plastic. Class-colored glass edges communicate identity; resource colors communicate state; Xbox A/B/X/Y green/red/blue/yellow communicate input. Keep these color systems separate.

> Design for real WoW at 1920x1080 with UI scale 0.9–1.0, so elements must be genuinely compact and readable without relying on tiny scaling. Keep the center/world view open. Top-left: compact player and pet identity frames with square/soft-square portraits, names and attached buffs/debuffs; do not put large health/resource bars there. Integrate and skin the pet happiness/status icon. Party frames continue compactly below with portrait, name, thin health rail and relevant debuffs. Top-center: a Breath-of-the-Wild-like boss hierarchy for the target — a long, very thin health bar, small integrated portrait, restrained name/level, with compact buffs/debuffs directly underneath; target-of-target is much smaller. Bottom-center: preserve the actual PSF architecture — player/pet health and resource rows form one central combat-status block with the native swing timers, and the native controller action bars/glyph cluster sits immediately below. Make this read as one clean Xbox-inspired combat cockpit without enclosing everything in one giant box. Top-right: compact minimap and objectives column. Bottom-left: quiet translucent chat. Bottom-right: quiet damage meter. Bottom edge: extremely thin XP/progress bar. World nameplates are exceptionally minimal: name + thin health rail, controller-focus brackets only on the current target, a second thin rail for casts, and only highly relevant aura/status icons. Use negative space aggressively. Avoid redundant information, oversized panels, generic addon-box aesthetics, excessive neon, photorealistic controller plastic and decorative clutter. The final impression is WoW Forever reimagined as a first-party Xbox interface: immersive, controller-native, spatially light, minimal, coherent and immediately readable.

## Implementation foundation

The visual system is implemented through shared semantic tokens before individual modules are migrated. Modules should request roles instead of inventing local styling.

- **surface:** glass, strong, peripheral, well, soft well, rail, floating;
- **geometry:** card, compact, socket and rail radii plus shared spacing;
- **depth:** peripheral, standard and combat hierarchy;
- **identity:** per-unit class color where applicable, otherwise neutral;
- **focus:** PSF mint selection/focus, separate from identity;
- **status:** semantic health/power/reaction/threat colors;
- **input:** Xbox ABXY colors remain controller-only.

Migration rule: preserve compatibility aliases while existing 0.9 components move onto these semantic roles. First centralize the vocabulary, then migrate component families one at a time. Do not mix unrelated feature expansion into the visual migration.

## Module architecture

PSF is organized as a presentation layer with clear, product-owned module names. The module map describes responsibility; existing Lua files may migrate toward it incrementally rather than through a disruptive rewrite.

| Module | Responsibility |
| --- | --- |
| **Foundation** | Design tokens, surfaces, typography, colors, geometry and shared visual primitives. |
| **Input** | Controller glyphs, focus states and input legend while native GamepadUI remains behaviorally authoritative. |
| **Combat** | Central player/pet resources, native swing-timer presentation and the visual bridge to GamepadUI. |
| **Units** | Player, pet, target, focus, target-of-target, party/raid and aura presentation. |
| **Nameplates** | Minimal tactical presentation attached to units in the world. |
| **Minimap** | Native minimap presentation and, after the base skin is complete, controller access and minimap-button support. |
| **Moments** | Temporary cinematic world/event text: zones, subzones, quests, achievements, level-ups, boss emotes, scenarios/delves and similar meaningful events. |
| **Quests** | Persistent objective tracker, quest log and longer-lived quest presentation. |
| **Chat** | Chat frames and chat input. |
| **Loot** | Loot window, loot presentation and loot notifications. |
| **Interface** | Game menu, settings, tooltips and other general Blizzard UI presentation. |
| **Diagnostics** | Debugging, compatibility probes and development tooling. |

These are PSF concepts. External addon module names are references for research only and do not define PSF architecture.

### Module development rule

**Base → complete → extend.**

Every module first becomes the smallest complete PSF skin over native Blizzard/Forever behavior. Only after that base is stable should PSF add functionality.

1. **Base:** establish the module's visual language while preserving native behavior.
2. **Complete:** cover the normal native states, scaling, layout and interaction expected from that component.
3. **Extend:** add PSF-owned behavior only where it meaningfully improves the controller-first experience or fills a demonstrated native gap.

This rule prevents a visual migration from silently becoming a replacement framework.

### Minimap progression

The Minimap module is deliberately called **Minimap**: its responsibility should be obvious in code.

- **Base:** keep the native Blizzard/Forever minimap, remove the circular Blizzard presentation/overlay and present the map as a clean square PSF component. Do not replace minimap behavior.
- **Complete:** integrate the useful native minimap information and states into the square PSF language and validate it at the 1080p/0.9–1.0 baseline.
- **Extend:** add controller focus/navigation and controller-accessible minimap buttons while retaining native functionality wherever practical.

**Gauge** is reserved as a possible Foundation component term for measurable-state presentation (health, resources, casts, swing timers), not as the name of the minimap module.

### Moments progression

Moments is PSF's temporary cinematic text layer, not a persistent HUD panel. When inactive it should leave no visual footprint in the world viewport.

The base is a single reusable presentation path: a moment has a type, title and optional subtitle, enters cleanly, holds briefly, exits, and yields to the next item in a small queue. Event providers plug into that presentation rather than implementing their own visual systems.

The intended Moments family includes:
- zone and subzone changes;
- quest accepted, progress and completion;
- achievements and achievement progress where useful;
- level-up;
- boss/emote moments where appropriate;
- scenario/delve start, progress and completion;
- other future events only when they qualify as meaningful temporary moments.

The base presentation and queue come first. Individual event families are then added and validated incrementally so the module remains one coherent system rather than a collection of notification implementations.

### Ownership rule

**PSF owns presentation; Blizzard/Forever owns behavior.**

PSF may skin native frames, add informational presentation and suppress or replace redundant visual chrome when safe. Native controller navigation, targeting, protected actions, bindings, timers and secure state remain authoritative wherever a usable native path exists. PSF takes over behavior only when a native alternative demonstrably does not exist and the controller-first experience requires it.

## Review test

A proposed PSF component is on-design when:
- it remains readable at 1080p and 0.9–1.0 scale;
- it reduces rather than increases visual competition with the world;
- its shape plausibly belongs to the same Xbox-inspired component family;
- its colors communicate identity/state/input without mixing those roles;
- it does not duplicate a stronger information source elsewhere;
- its information density matches the gameplay relevance of the unit;
- it preserves native secure/controller behavior wherever practical.
