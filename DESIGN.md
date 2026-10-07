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

## Review test

A proposed PSF component is on-design when:
- it remains readable at 1080p and 0.9–1.0 scale;
- it reduces rather than increases visual competition with the world;
- its shape plausibly belongs to the same Xbox-inspired component family;
- its colors communicate identity/state/input without mixing those roles;
- it does not duplicate a stronger information source elsewhere;
- its information density matches the gameplay relevance of the unit;
- it preserves native secure/controller behavior wherever practical.
