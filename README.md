# Mecha Survivors

Mecha Survivors is a lightweight 3D arena-survival prototype built with Godot 4.7. Pilot a combat mech, survive escalating enemy waves, collect experience, and shape each run with upgrades.

The project currently uses clean placeholder geometry so movement, combat, camera behavior, collisions, enemy AI, and navigation can be validated before final art production begins.

## Features

- Fast top-down 3D movement and mouse aiming
- Automatic wave scaling with melee, ranged, and heavy enemies
- Enemy spawn telegraphs with native Godot particles and lighting
- Player and enemy projectile collision layers
- Experience pickups, leveling, and randomized upgrade choices
- Health, XP, timer, level, and kill-count HUD
- Pause, restart, game-over, and persistent settings menus
- Desktop and Android touch controls
- Modular test arena with baked navigation around corridors and cover
- Automated gameplay and navigation smoke tests

## Requirements

- Godot Engine `4.7.1` or a compatible Godot 4.7 release
- Forward+ renderer support for the current desktop configuration
- Android export templates, Android SDK, and JDK only when producing Android builds

## Getting Started

1. Clone the repository:

   ```bash
   git clone https://github.com/ArnavNah/MechaSurvivors-Godot.git
   cd MechaSurvivors-Godot
   ```

2. Import `project.godot` in Godot 4.7.
3. Press `F6` to run the current scene or `F5` to start from the main menu.

No third-party assets or plugins are required.

## Controls

### Desktop

| Action | Input |
| --- | --- |
| Move | `W`, `A`, `S`, `D` |
| Aim | Mouse |
| Fire | Left mouse button |
| Pause | `Esc` |

### Android

- Drag the left control pad to move.
- Drag the right control pad to aim and fire.
- Tap the pause button at the top of the screen to pause.

## Project Structure

```text
autoloads/       Global events and run-state management
components/      Reusable health, hurtbox, hitbox, weapon, and XP logic
resources/       Typed resources and gameplay data
scenes/
  dungeon/       Modular testing arena and baked navigation mesh
  enemies/       Base, melee, ranged, and heavy enemy scenes
  game/          Main gameplay composition
  pickups/       Experience pickups
  player/        Player, weapon pivot, and camera-follow setup
  projectile/    Shared faction-aware projectile
  spawning/      Enemy spawner and spawn telegraph effect
  ui/            HUD, menus, upgrade cards, and touch controls
tests/           Headless smoke and arena-navigation validation scenes
```

## Verification

Run the general gameplay smoke test:

```bash
godot --headless --path . res://tests/SmokeTest.tscn
```

Run the arena and navigation validation:

```bash
godot --headless --path . res://tests/ArenaValidation.tscn
```

The arena test verifies all modular static colliders, the baked navigation mesh, and paths through each narrow corridor and across the combat space.

## Android Export Checklist

1. Install the matching Godot Android export templates.
2. Configure Android SDK and JDK paths in Godot Editor Settings.
3. Create an Android export preset with a unique package identifier.
4. Configure version code, version name, orientation, icons, and a release keystore.
5. Test touch controls, safe areas, performance, pause/resume, and audio on physical devices.
6. Export an AAB for Google Play or an APK for direct testing.

## Current Status

This is a gameplay-validation build, not the final dungeon or final art pass. Placeholder primitive meshes and simple materials are intentional. The next major milestones are final environment art, character presentation, audio, device playtesting, and store-ready Android export configuration.
