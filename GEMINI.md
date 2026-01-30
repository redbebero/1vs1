# Godot 1-vs-1 Neon Fighter (GDScript) - Master Plan

## Current Focus: The Knight & Prototype Arena

### 1. Prototype Arena (`game.tscn`)
*   **Visuals:** Dark background, Neon floor line.
*   **Physics:** StaticBody floor at Y=500.
*   **Camera:** Center focused, slightly zoomed out to fit both fighters.

### 2. Character Architecture (`StickmanFighter`)
To support 45 characters easily via CLI, we separate Data, Visuals, and Logic.

*   **`FighterController.gd` (Logic):**
    *   Handles Input (P1/P2 separation).
    *   Manages State Machine (Idle, Run, Jump, Attack, Stun).
    *   **Command System:** Checks directional input buffer when Skill button is pressed to select: `Neutral`, `Side`, `Up`, `Down`.
*   **`StickmanVisuals.gd` (Visuals):**
    *   Procedurally generates `Line2D` limbs (Head, Body, Arms, Legs).
    *   **Weapon Points:** Hand markers to attach `Sword` or `Shield` sprites/lines dynamically based on `CharacterData`.
    *   Uses `Tween` for animations (Attack swings, Walking bob).
*   **`CharacterData.gd` (Data):**
    *   Holds Stats (HP, Speed, Poise).
    *   **MoveSet Dictionary:** Maps `[SkillSlot][Direction]` -> `SkillData`.

### 3. VFX Architecture (The "Particle Bus")
To support 45+ characters with unique visual flairs without melting the CPU, we adopt a **Data-Driven GPU Pooling** strategy.

*   **`VFXManager` (Autoload/Singleton):**
    *   **Role:** The central "Bus" for all visual effects.
    *   **Object Pooling:** Pre-allocates a pool of `GPUParticles2D` nodes at startup. Reuses them cyclically to avoid `instantiate/free` cost (GC spikes).
    *   **API:** `VFXManager.spawn("effect_name", position, color, direction)`
*   **`VFXRegistry` (Static Data):**
    *   **Role:** Single Source of Truth (SSOT). A pure Dictionary file containing the "recipe" for every effect.
    *   **Structure:** Key-Value pairs defining Amount, Spread, Velocity, Gravity, Scale Curve, etc.
    *   **Benefit:** Designers (or AI) can tweak effect feels just by editing numbers in one file, complying with OCP (Open-Closed Principle).

### 4. The Knight (Implementation Detail)
**Stats:** HP 155, Speed 250, Poise 40%.
**Visuals:** Silver Color, Sword (Right Hand), Shield (Left Hand).

**MoveSet:**
*   **Skill A (Sword):**
    *   Neutral: Horizontal Slash (Fast)
    *   Side: Dash Slash (Knockback)
    *   Down: Low Stab (Low hit)
    *   Up: Rising Slash (Anti-air)
*   **Skill B (Shield):**
    *   Neutral: Bash (Stun)
    *   Side: Guard Dash (Projectile Break)
    *   Down: Iron Wall (Defense Buff)
    *   Up: Shield Uppercut
*   **Ult (S):** Grand Cross (AOE Stun)

---
**File Structure Plan:**
*   `Scenes/game.tscn`
*   `Scenes/Player.tscn`
*   `Scripts/Core/GameManager.gd`
*   `Scripts/Core/VFXManager.gd` (New: The Effect Engine)
*   `Scripts/Data/VFXRegistry.gd` (New: The Effect Database)
*   `Scripts/Characters/FighterController.gd`
*   `Scripts/Characters/StickmanVisuals.gd`
*   `Scripts/Resources/Skill.gd`
*   `Scripts/Resources/CharacterData.gd`

## Ignored Paths
- build/
- docs/
