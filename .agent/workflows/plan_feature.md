---
description: Master workflow for Planning High-Level Features or Characters
---

# Feature Planning Workflow

This workflow guides the AI and User through the planning phase for complex features (e.g., New Character, New System).

1. **Analyze Requirements**
    - Read the `task.md` and user request.
    - Identify core components involved (Logic, Visuals, Data).

2. **Architecture Check (SOLID)**
    - **SRP**: Does this feature belong in an existing script, or does it need a new Component/Resource?
    - **OCP**: Can I implement this *without* changing the core `FighterController`? (Use Passives/Signals).

3. **Draft `implementation_plan.md`**
    - Define [NEW] files strictly.
    - Define [MODIFY] impacts.
    - **Crucial**: If adding a Character, define the 3 Skills and 3 Passives as Resources.

4. **Verify Scalability**
    - Ask: "If I do this 45 times, will it break?"
    - If yes -> Refactor into a Data-Driven solution (Registry/Loop).

5. **Request Review**
    - Use `notify_user` to present the Plan.
    - Do NOT write code until Plan is approved for complex tasks.