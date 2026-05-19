# Control Water Level in a Tank Using a Reinforcement Learning Agent

## Overview

This branch contains a complete example demonstrating how to use reinforcement learning to control the water level in a tank using a **DDPG (Deep Deterministic Policy Gradient) agent**, replacing the conventional PI controller. The implementation includes:

- A modified Simulink® model (`rlwatertank.slx`) with an RL agent block
- A trained DDPG agent (`WaterTankDDPG.mat`)
- Complete step-by-step documentation and code

## Full Example

For the complete implementation guide, detailed explanations, and step-by-step instructions, see:
- **📄 [CreateSimulinkEnvironmentAndTrainAgentExample.md](CreateSimulinkEnvironmentAndTrainAgentExample.md)** — Markdown export of the full example
- **📊 [CreateSimulinkEnvironmentAndTrainAgentExample.mlx](CreateSimulinkEnvironmentAndTrainAgentExample.mlx)** — MATLAB Live Script with executable code and visualizations

## File Contents

- `rlwatertank.slx` — Modified Simulink model with RL Agent block
- `WaterTankDDPG.mat` — Pre-trained DDPG agent
- `CreateSimulinkEnvironmentAndTrainAgentExample.md` — Markdown documentation of the example
- `CreateSimulinkEnvironmentAndTrainAgentExample.mlx` — MATLAB Live Script
- `CreateSimulinkEnvironmentAndTrainAgentExample_media/` — Supporting images and media files

## Credits and License

This work is based on the MathWorks® official reinforcement learning example:

**Original Source:** [Control Water Level in a Tank Using a DDPG Agent](https://ch.mathworks.com/help/reinforcement-learning/ug/control-water-level-using-ddpg-agent.html)

**Copyright © The MathWorks, Inc.** All rights reserved.

The original example and associated documentation are provided under the **MathWorks Standard License Agreement**. The files in this branch are derivatives of the official MathWorks example and maintain the same licensing terms. Redistribution and use of these materials must comply with MathWorks licensing requirements.

For more information on MathWorks licensing, visit: [MathWorks License Center](https://www.mathworks.com/licensecenter)

### Key Acknowledgments

- **Simulink®** — Simulation and modeling environment
- **Reinforcement Learning Toolbox** — RL algorithms and environment creation tools
- **MATLAB®** — Computation and visualization platform

All product names and trademarks are the property of their respective owners.
