# RISC-V CoVE Threat Model (STPA-Sec)

This directory contains the threat model for RISC-V CoVE (Confidential VM Extensions) developed using the **STPA-Sec** (System-Theoretic Process Analysis for Security) methodology. The model was created within the Capella MBSE tool using the STPA Add-On.

## STPA Process Phases

As outlined in the *User Guide for the STPA Add-On to Capella*, the analysis follows four primary phases:

### 1. Define Purpose of the Analysis
The initial phase establishes the goals and boundaries of the security analysis.
*   **Identify Stakeholders and Stakes:** Define project stakeholders with their relevant assets (stakes).
*   **Identify Losses (L):** Define the high-level negative outcomes that must be avoided (e.g., loss of confidentiality, loss of integrity of VM data, loss of availability of the TEE).
*   **Identify System-Level Hazards (H):** Determine the system states or conditions that, in combination with environmental factors, lead to a loss.
*   **Identify System-Level Constraints (SC):** Establish the security requirements the system must satisfy to prevent hazards and mitigate losses.
*   **Refine Hazards:** Decompose high-level hazards into more granular, specific sub-hazards.

> ![Placeholder: System Analysis Diagram]

### 2. Model the Control Structure
This phase involves creating a functional model of the system as a set of interacting feedback loops.
*   **Identify Controllers:** Define the entities (e.g., Security Manager, Hypervisor, CoVE-capable Hardware) that exert control over system processes.
*   **Identify Responsibilities:** Assign high-level security duties to each controller.
*   **Identify Control Actions (CA):** Specify the commands or signals sent by controllers to influence system state.
*   **Identify Process Models:** Define the internal state tracking required by controllers to make safe/secure decisions.
*   **Identify Feedback:** Map the information returned to controllers to update their process models.

> ![Hierarchical Control Structure Diagram](./[HCS]%20Hierarchical%20Control%20Structure%20Diagram.jpg)
> *Placeholder: Additional Control Structure Details*

### 3. Identify Unsafe Control Actions (UCA)
In this phase, we analyze how control actions can lead to hazards. A Control Action is considered unsafe if:
1.  Not providing the action leads to a hazard.
2.  Providing the action leads to a hazard.
3.  Providing the action too early, too late, or in the wrong order leads to a hazard.
4.  The action is stopped too soon or applied for too long.

**Controller Constraints** are then derived to specifically prohibit these UCAs.

> ![Placeholder: UCA Table or Diagram]

### 4. Identify Loss Scenarios
The final phase identifies the causal factors that could lead to Unsafe Control Actions or improperly executed control actions.
*   **Causal Factors:** Investigate potential failures, environmental disturbances, or adversarial actions (e.g., compromised feedback, corrupted process models, malicious inputs).
*   **Loss Scenarios:** Develop detailed narratives explaining how combinations of causal factors result in UCAs and, ultimately, system losses.

> ![Placeholder: Loss Scenario / Causal Factor Diagram]

## Project Structure
*   `ThreatModel_RISCV.capella`: The main Capella project file.
*   `ThreatModel_RISCV.aird`: The representations (diagrams) file.
*   `[HCS] Hierarchical Control Structure Diagram.jpg`: Exported view of the system's control architecture.
