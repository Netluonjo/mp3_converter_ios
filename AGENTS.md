# AGENTS.md

Welcome to ProCam iOS. This repository adheres to **Andrej Karpathy's Coding Principles** and **GitHub Spec Kit (Spec-Driven Development)**.

---

## 🧠 Andrej Karpathy's Core Guidelines

### 1. Think Before Coding
- **Don't assume. Don't hide confusion. Surface tradeoffs.**
- State your assumptions explicitly before implementing. If uncertain, ask.
- If multiple interpretations exist, present them rather than picking silently.
- Push back with simpler alternatives when an approach is over-engineered.

### 2. Simplicity First
- **Minimum code that solves the problem. Nothing speculative.**
- No unused abstractions, premature generalizations, or speculative flexibility.
- If you write 200 lines and it could be 50, rewrite it.

### 3. Surgical Changes
- **Touch only what you must. Clean up only your own mess.**
- Never touch unrelated code, comments, or formatting.
- Match existing project style. Clean up your own unused imports/variables.

### 4. Goal-Driven Execution
- **Define success criteria. Loop until verified.**
- Turn instructions into verifiable checks.
- Verify each step before moving on to the next.

---

## 📋 Spec Kit (Spec-Driven Development)

This project uses the **GitHub Spec Kit** framework located in `.specify/`.
When planning, designing, or implementing new features, use the installed Spec Kit skills:

- `/speckit-specify`: Create or update feature specifications from requirements in `specs/<feature>/spec.md`.
- `/speckit-plan`: Create architectural implementation plans in `specs/<feature>/plan.md`.
- `/speckit-tasks`: Break plans into actionable, ordered tasks in `specs/<feature>/tasks.md`.
- `/speckit-implement`: Execute implementation tasks incrementally with continuous verification.
- `/speckit-clarify`: Identify gaps and ask structured questions before writing code.
- `/speckit-analyze`: Verify consistency across specifications, plans, and code.
- `/speckit-checklist`: Generate quality checklists for requirements.
- `/speckit-constitution`: Update project core principles in `.specify/memory/constitution.md`.
