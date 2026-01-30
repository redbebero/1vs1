---
description: Master workflow for Review and Analysis
---

# Code Review Workflow

1. **SOLID Audit**
    - Read `FighterController.gd` and Manager scripts.
    - Check for "God Class" symptoms (file size > 400 lines? Too many `if` statements?).

2. **Scalability Check**
    - Imagine adding "Character #45".
    - How many files need to be touched?
    - If > 2 (The Data file + The Visuals), FLAG it.

3. **Performance Check**
    - Are we instantiating Nodes in `_process`? (Bad)
    - Are we using `get_node` every frame? (Use `@onready` or Cache).

4. **Report**
    - Update `architecture_analysis.md` (Artifact) with findings.
