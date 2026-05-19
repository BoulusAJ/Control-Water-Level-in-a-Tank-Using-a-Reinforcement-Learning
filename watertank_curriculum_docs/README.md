# Water Tank Curriculum DDPG Training — User Guide

This documentation describes the curriculum-learning MATLAB/Simulink training structure for the `rlwatertank` DDPG controller.

The goal of the structure is to train a continuous-control RL agent in multiple stages instead of training everything at once. The same pattern can later be adapted to other nonlinear systems, such as an inverted pendulum.

## File Overview

| File | Purpose |
|---|---|
| `trainWaterTankCurriculumDDPG.m` | Main script. Creates the environment, creates the agent, loops through the curriculum stages, trains, saves results, and validates the final agent. |
| `makeStageConfig.m` | Defines all global settings and the four curriculum stages. This is the main file to edit when tuning the training strategy. |
| `createDDPGAgent.m` | Builds the actor network, critic network, and DDPG agent options. |
| `configureAgentForStage.m` | Applies stage-specific agent settings such as exploration noise and replay-buffer reset behavior. |
| `localResetFcnCurriculum.m` | Reset function used by the Simulink environment. It changes the reference and initial tank height according to the active curriculum stage. |
| `rewardFcn.m` | Computes reward and termination signal. Supports boolean reward, normalized squared-error reward, and full control-oriented reward. |

## Required Simulink Setup

The scripts assume the following names from the MathWorks water tank example:

```matlab
mdl = "rlwatertank";
agentBlock = "rlwatertank/RL Agent";
referenceBlock = sprintf("rlwatertank/Desired \nWater Level");
heightBlock = "rlwatertank/Water-Tank System/H";
```

Your Simulink model must also call the reward function using the base workspace variable `rewardParams`, for example:

```matlab
[r,isDone] = rewardFcn(e,u,u_prev,h,rewardParams);
```

The environment reset function expects the base workspace variable `curriculumParams` to exist. The main training script creates this variable automatically before each stage.

## Basic Usage

1. Place all `.m` files in the same folder as `rlwatertank.slx`, or add the folder to the MATLAB path.
2. Make sure the Simulink reward block calls `rewardFcn` with `rewardParams`.
3. Run:

```matlab
trainWaterTankCurriculumDDPG
```

The script will train four stages:

1. Local correction
2. Medium transient
3. Global robustness
4. Precision fine-tuning

After each stage, the script saves the agent and optionally the training statistics.

## Curriculum Concept

The curriculum progressively increases task difficulty:

| Stage | Reset Distribution | Goal |
|---|---|---|
| 1 — Local | Initial height close to reference | Learn basic local correction and stabilization |
| 2 — Medium | Larger initial error | Learn stronger transient behavior |
| 3 — Global | Independent reference and initial height | Learn robustness over the operating range |
| 4 — Precision | Deployment-like distribution | Fine-tune low steady-state error and smooth control |

## Reward Concept

The final reward form is:

```text
r = -(e/e_scale)^2 - lambda_u*u^2 - lambda_du*(u-u_prev)^2 + tolerance bonus - unsafe penalty
```

This reward encourages:

- small tracking error,
- limited actuator effort,
- smooth control changes,
- safe tank height,
- precise tracking near zero error.

## Most Important Parameters to Tune

Start by tuning these in `makeStageConfig.m`:

```matlab
stages(k).Reward.e_scale
stages(k).Reward.lambda_u
stages(k).Reward.lambda_du
stages(k).NoiseStd
stages(k).Reset.minInitialError
stages(k).Reset.maxInitialError
stages(k).MaxEpisodes
```

For oscillatory behavior, first try:

- decreasing `NoiseStd`,
- increasing `lambda_du`,
- lowering actor learning rate,
- checking action saturation.

For slow convergence, try:

- increasing `NoiseStd` slightly,
- reducing `lambda_u`,
- increasing `MaxEpisodes`,
- widening the curriculum more gradually.

## Saved Outputs

The main script saves files like:

```text
WaterTankDDPG_curriculum_stage_01_local.mat
WaterTankDDPG_curriculum_stage_02_medium.mat
WaterTankDDPG_curriculum_stage_03_global.mat
WaterTankDDPG_curriculum_stage_04_precision.mat
WaterTankDDPG_curriculum_final.mat
```

Each stage file contains at least:

```matlab
agent
stage
```

and, if enabled:

```matlab
trainingStats
```

## Adapting to Another Nonlinear System

To reuse this structure for another plant:

1. Replace model and block names in `makeStageConfig.m`.
2. Update `localResetFcnCurriculum.m` so it sets the new plant initial conditions.
3. Update observation and action specifications in the main script.
4. Update `rewardFcn.m` inputs if the new system uses different signals.
5. Keep the stage-loop structure unchanged.

For an inverted pendulum, for example, the reset function would randomize angle and angular velocity instead of tank height.

## Recommended Development Workflow

1. Run only Stage 1 first.
2. Inspect tracking response and action signal.
3. Tune `NoiseStd`, `lambda_du`, and `e_scale`.
4. Continue to Stage 2 only when Stage 1 is stable.
5. Repeat for each stage.
6. Validate the final agent using deterministic simulation without exploration noise.

## Practical Warning

A DDPG agent can output poor actions outside its training distribution. Always validate the final policy on initial conditions and references that represent deployment conditions.

For safety-critical systems, use action limits, termination logic, and preferably compare against a classical baseline controller.
