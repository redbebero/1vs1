---
description: Master workflow for Implementing Code
---

# Feature Implementation Workflow

1. **Review Plan**
    - Read `implementation_plan.md`.
    - Do NOT deviate without a Task Boundary update.

2. **Create/Modify Core Scripts First**
    - Implement [NEW] Resources or Managers first (Dependencies).
    - Example: Create `Passive.gd` before adding `passives` array to `FighterController.gd`.

3. **Implement Logic**
    - Follow SOLID.
    - Use `write_to_file` or `replace_file_content`.
    - **Code Style**: GDScript static typing (`: float`, `-> void`) is MUST.

4. **Self-Correction**
    - Run `view_file` on your result to verify formatting.
    - Check for syntax errors (Agent cannot compile, but can double-check logic).

5. **Mark Progress**
    - Update `task.md` items to `[/]` or `[x]`.
