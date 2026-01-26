# Godot 1-vs-1 Neon Fighter (C#) - Master Plan

## Current Focus: The Knight & Prototype Arena

### 1. Prototype Arena (`World.tscn`)
*   **Visuals:** Dark background, Neon floor line.
*   **Physics:** StaticBody floor at Y=500.
*   **Camera:** Center focused, slightly zoomed out to fit both fighters.

### 2. Character Architecture (`StickmanFighter`)
To support 45 characters easily via CLI, we separate Data, Visuals, and Logic.

*   **`FighterController.cs` (Logic):**
    *   Handles Input (P1/P2 separation).
    *   Manages State Machine (Idle, Run, Jump, Attack, Stun).
    *   **Command System:** Checks directional input buffer when Skill button is pressed to select: `Neutral`, `Side`, `Up`, `Down`.
*   **`StickmanVisuals.cs` (Visuals):**
    *   Procedurally generates `Line2D` limbs (Head, Body, Arms, Legs).
    *   **Weapon Points:** Hand markers to attach `Sword` or `Shield` sprites/lines dynamically based on `CharacterData`.
    *   Uses `Tween` for animations (Attack swings, Walking bob).
*   **`CharacterData.cs` (Data):**
    *   Holds Stats (HP, Speed, Poise).
    *   **MoveSet Dictionary:** Maps `[SkillSlot][Direction]` -> `SkillData`.

### 3. The Knight (Implementation Detail)
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
*   `Scenes/World.tscn`
*   `Scenes/Fighter.tscn`
*   `Scripts/Core/GameManager.cs`
*   `Scripts/Characters/FighterController.cs`
*   `Scripts/Characters/StickmanVisuals.cs`
*   `Scripts/Resources/SkillData.cs` (Updated)
*   `Scripts/Resources/CharacterData.cs`
