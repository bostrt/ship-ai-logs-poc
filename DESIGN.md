# Ship AI — Small LLM Game Experiments

## Overview

This project explores building a **small interactive game that runs a local LLM as the ship's AI**.

The focus is on **small language models (SLMs)** that can run locally on consumer hardware, such as:

* Granite 350M
* Granite 1B
* other small GGUF models compatible with `llama.cpp`

The player interacts with the **Ship AI** to solve mysteries, diagnose system problems, and interpret sensor data.

The goal is to design gameplay where the **LLM is part of the puzzle mechanics**, not just a chat interface.

---

# Design Goals

### 1. Local Inference

The game must run **fully offline**.

Requirements:

* No internet required
* LLM runs locally
* Game bundles everything needed

Likely stack:

* `llama.cpp` server
* OpenAI-compatible API

---

### 2. Small Model Friendly

All mechanics should work well with models:

* 350M–1B parameters
* small context windows
* limited reasoning

Therefore gameplay must rely on:

* pattern recognition
* summarization
* structured reasoning

Avoid:

* long story generation
* world knowledge
* creative writing dependency

---

### 3. Prevent Hallucinations

The AI should reason only from **explicit game data**.

Design rules:

1. Provide structured inputs (logs, sensors, reports).
2. Restrict questions to analytical tasks.
3. Prefer tool calls when possible.
4. Keep context small.

Good prompt tasks:

* analyze
* summarize
* compare
* diagnose
* infer

Avoid open-ended questions like:

> "What do you think happened?"

Instead use:

> "Based on the logs, why did the reactor shut down?"

---

### 4. Low Development Overhead

This project should be feasible with **1–2 hours of development per week**.

Design priorities:

* minimal art requirements
* simple UI
* terminal-style interfaces
* modular gameplay experiments

---

# Core Technology Stack

## Game Engine

**Godot**

Reasons:

* native Linux + Windows support
* lightweight
* good UI tools
* easy HTTP requests

---

## LLM Runtime

`llama.cpp`

Reasons:

* small footprint
* easy distribution
* OpenAI-compatible server mode
* works well with GGUF models

Possible runtime:

```
game/
  godot/
  models/
    granite-350m.gguf
  llm/
    llama-server
```

---

## Communication Model

Godot communicates with the LLM through an **OpenAI-compatible API**.

Example flow:

```
Player Input
     ↓
Godot UI
     ↓
HTTP Request
     ↓
llama.cpp server
     ↓
LLM response
     ↓
Game UI update
```

---

# Game Concept

The player controls a **damaged spacecraft**.

The ship contains an onboard AI system that:

* interprets logs
* runs diagnostics
* analyzes sensors
* helps solve mysteries

However:

* the AI may be incomplete
* logs may be corrupted
* the player must interpret results

The gameplay loop becomes:

```
explore
   ↓
find data
   ↓
ask AI questions
   ↓
interpret AI response
   ↓
solve puzzle
```

---

# Proof-of-Concept Experiments

The first stage of development focuses on **small gameplay demos**.

Each demo tests one mechanic.

---

# Demo 1 — Ship Log Interpreter

## Purpose

Test whether a small model can analyze system logs.

---

## Gameplay

Player receives ship logs:

```
[12:01] Reactor output: 88%
[12:02] Cooling pump 3 offline
[12:03] Hull temperature rising
[12:04] Reactor output: 104%
[12:05] Automatic SCRAM triggered
```

Player asks the AI:

> Why did the reactor shut down?

Expected answer:

> Cooling pump 3 failed, causing overheating.

---

## Mechanics Tested

* summarization
* causal reasoning
* structured input prompts

---

## UI Concept

```
┌───────────────────────────┐
│ SHIP LOG                  │
│                           │
│ [scrollable logs]         │
│                           │
├───────────────────────────┤
│ Ask Ship AI               │
│ > why reactor shutdown?   │
└───────────────────────────┘
```

---

# Demo 2 — Ship Diagnostic Tools

## Purpose

Test **tool-calling gameplay**.

Instead of guessing, the AI must run diagnostics.

---

## Example

Player:

> Run diagnostic on life support.

AI calls:

```
diagnostic("life_support")
```

Tool returns:

```
oxygen_mix: 17%
recommended: 21%
cause: filter_clog
```

AI replies:

> Oxygen levels are low. The filter appears clogged.

---

## Mechanics Tested

* tool calling
* deterministic responses
* structured reasoning

---

# Demo 3 — Alien Pattern Analysis

## Purpose

Use the LLM for pattern recognition puzzles.

---

## Example Input

```
KOR VALEN TRI
KOR VALEN TRI
VALEN TRI
KOR TRI
```

Player asks:

> What pattern do you see?

AI:

> The phrase "VALEN TRI" appears in every line.

---

## Mechanics Tested

* token pattern recognition
* simple linguistic puzzles

---

# Demo 4 — AI Personality Drift

## Purpose

Experiment with narrative behavior.

The AI changes personality during the game.

---

## Possible States

```
stable
curious
suspicious
erratic
```

Injected into system prompt:

```
You are the ship AI.
Current psychological state: suspicious.
```

Example:

Player:

> Open cargo bay.

Stable AI:

> Opening cargo bay.

Suspicious AI:

> Why do you need access to the cargo bay?

---

## Mechanics Tested

* system prompt changes
* character arc
* narrative tension

---

# Demo 5 — Sensor Triangulation

## Purpose

Test approximate reasoning.

---

## Example Sensor Data

```
Sensor A: anomaly bearing 210°
Sensor B: anomaly bearing 260°
Sensor C: anomaly bearing 235°
```

Player asks:

> Where is the anomaly?

AI:

> Approximately southwest of the ship.

---

## Mechanics Tested

* spatial reasoning
* noisy data interpretation

---

# Demo 6 — Memory Reconstruction

## Purpose

Test inference from incomplete data.

---

## Example Logs

```
[12:01] --- DATA LOST ---
[12:02] thruster overload warning
[12:03] autopilot disengaged
```

Player asks:

> What probably happened?

AI:

> A maneuver may have occurred before the overload.

---

## Mechanics Tested

* inference
* incomplete data reasoning

---

# Recommended First Prototype

Start with:

**Demo 1 — Ship Log Interpreter**

Reasons:

* simplest implementation
* deterministic inputs
* strong puzzle potential
* ideal for small models

---

# Long-Term Gameplay Vision

Eventually combine these mechanics into a full gameplay loop.

Example:

```
explore ship
      ↓
discover logs
      ↓
analyze with AI
      ↓
run diagnostics
      ↓
solve ship malfunction
      ↓
unlock story progression
```

---

# Key Design Principle

The AI should be treated as:

**an analysis tool, not a storyteller.**

Good uses of small models:

* interpreting logs
* analyzing signals
* summarizing data
* diagnosing problems

Bad uses:

* generating long narrative
* world lore
* open-ended speculation

---

# Future Possibilities

Potential expansions:

* rogue AI storyline
* hidden alien signals
* corrupted memory banks
* player vs AI disagreements
* emergent puzzles using logs

---

# Development Strategy

1. Build small isolated demos.
2. Validate gameplay mechanics.
3. Combine working pieces later.

Keep experiments:

* small
* fast
* modular
* replaceable.

---

# Success Criteria

A successful prototype should demonstrate:

* local LLM integration
* fun player interaction
* puzzles solvable through AI dialogue
* minimal hallucination issues

---

