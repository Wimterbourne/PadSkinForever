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

Color communicates meaning.

- PSF focus/selection: mint green.
- Health: green.
- Mana: blue.
- Focus: orange.
- Energy: yellow.
- Rage: red.
- Neutral timers/rails: silver/graphite.
- Xbox face buttons retain their learned semantics: **A green, B red, X blue, Y yellow**.

Xbox colors belong primarily to input/action language. They must not turn the entire UI into four-color decoration.

## Surfaces and lines

- Base surfaces: dark anthracite/graphite, translucent where world readability permits.
- Borders: thin neutral grey, low contrast.
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

## Concept-image prompt

Use this as the canonical visual-generation prompt and update this document when the design direction changes:

> Create a 1920x1080 in-game concept for PadSkinForever, a minimalist controller-first UI for World of Warcraft: Forever. Preserve the recognizable WoW world and native GamepadUI composition, but translate the visual language through the forms and lines of a modern Xbox controller. The Xbox controller is a geometry reference, not a decorative object: use soft controller-shell curves, recessed thumbstick/button-like wells, thin molded seam lines, restrained shoulder/trigger-inspired edge shapes, circular status sockets and clear grouped controls. Use dark translucent anthracite/graphite surfaces, thin neutral borders, mint-green PSF focus accents, Inter-style clean typography, and semantic resource colors. Xbox A/B/X/Y retain green/red/blue/yellow only as input language.

> Design for real WoW at 1920x1080 with UI scale 0.9–1.0, so elements must be genuinely compact and readable without relying on tiny scaling. Keep the center/world view open. Top-left: compact player and pet identity frames with square/soft-square portraits, names and attached buffs/debuffs; do not put large health/resource bars there. Integrate and skin the pet happiness/status icon. Party frames continue compactly below. Top-center: a Breath-of-the-Wild-like boss hierarchy for the target — a long, very thin health bar, small integrated portrait, restrained name/level, with compact buffs/debuffs directly underneath; target-of-target is much smaller. Bottom-center: preserve the actual PSF architecture — player/pet health and resource rows form one central combat-status block with the native swing timers, and the native controller action bars/glyph cluster sits immediately below. Make this read as one clean Xbox-inspired combat cockpit without enclosing everything in one giant box. Top-right: compact minimap and objectives column. Bottom-left: quiet translucent chat. Bottom-right: quiet damage meter. Bottom edge: extremely thin XP/progress bar. Use negative space aggressively. Avoid redundant information, oversized panels, generic addon-box aesthetics, excessive neon, photorealistic controller plastic and decorative clutter. The final impression is WoW Forever reimagined as a first-party Xbox interface: immersive, controller-native, minimal, coherent and immediately readable.

## Review test

A proposed PSF component is on-design when:
- it remains readable at 1080p and 0.9–1.0 scale;
- it reduces rather than increases visual competition with the world;
- its shape plausibly belongs to the same Xbox-inspired component family;
- its colors communicate state/input rather than decoration;
- it does not duplicate a stronger information source elsewhere;
- it preserves native secure/controller behavior wherever practical.
