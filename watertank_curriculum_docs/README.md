# Water Tank Curriculum DDPG Training — User Guide

This branch extends the MathWorks `rlwatertank` DDPG example into a staged curriculum-learning training framework for nonlinear control. The original example is useful as a compact demonstration of replacing a PI controller with a DDPG agent, but this version focuses more on controller-development concerns: steady-state tracking quality, reward scaling, exploration control, replay-buffer management, staged initial-condition difficulty, and reuse for future nonlinear systems.

The goal of the structure is to train a continuous-control RL agent in multiple stages instead of asking it to solve the full nonlinear control problem at once. The same pattern can later be adapted to other systems, such as an inverted pendulum.

## What Changed Compared to the Base MathWorks Example?

The base MathWorks example trains a DDPG agent on the water tank model with a simple tolerance-based reward, randomized initial conditions, and a single training run. This branch keeps the same general plant and DDPG idea, but changes the training structure significantly.

The main improvements are:

| Area | Base Example | This Branch |
|---|---|---|
| Training structure | Single training run | Four-stage curriculum training |
| Reward | Mostly boolean/tolerance-based | Continuous normalized tracking reward with optional control penalties |
| Tracking objective | Enter and stay inside an error band | Reduce tracking error more directly, including steady-state error |
| Initial conditions | Randomized around nominal height | Stage-dependent reset distributions with increasing difficulty |
| Exploration | One exploration setting | Stage-specific exploration noise |
| Replay buffer | Standard single-run usage | Replay buffer can be reset between stages |
| Saving | Final/pretrained agent workflow | Agent and training statistics can be saved after every stage |
| Reusability | Example-specific script | Modular files intended for later adaptation to other nonlinear systems |
| Action limits | Depends on the example/model setup | Explicit normalized action range `0 <= u <= 1` in the action specification |

## Why These Changes Were Made

### 1. The original reward does not necessarily force zero steady-state error

The original reward is based on whether the absolute error is inside a tolerance band. Conceptually, it behaves like:

$$
r = 10\mathbf{1}_{|e| < 0.1} - \mathbf{1}_{|e| \ge 0.1} - 100\mathbf{1}_{\text{unsafe}}
$$

This is effective for teaching the agent to enter the acceptable tracking region, but once the agent is inside the tolerance band, it receives the same reward for many different errors. For example, an error of `0.09`, `0.02`, and `0.0` may all be treated as successful. This means the reward does not strongly distinguish between "acceptable tracking" and "near-zero tracking error."

For a control task where the goal is to compare against a PI controller or achieve low steady-state error, this is a limitation. A continuous reward based on tracking error gives the agent more information about whether it is improving:

$$
r = -e^2
$$

However, directly replacing the original reward with `-e^2` creates another problem: the scale and meaning of the return changes drastically.

### 2. A drastic reward change can destabilize a pretrained DDPG agent

In DDPG, the critic learns an estimate of the expected future return:

$$
Q(s,a) \approx \mathbb{E}\left[\sum_{k=0}^{\infty} \gamma^k r_{t+k}\right]
$$

If the original reward produces episode returns around hundreds or thousands, the critic learns Q-values on that approximate scale. If the reward is then changed to a squared-error penalty, the return may become mostly negative and much smaller in magnitude. The already-trained critic is then no longer calibrated to the new learning objective.

This matters because the actor is updated using gradients from the critic. If the critic is wrong after the reward change, the actor may receive misleading gradients. The result can be oscillatory control, unstable learning, or degradation of a previously working policy.

For that reason, when changing from the base example reward to the curriculum-based reward, the agent should usually be retrained. At minimum, the replay buffer should be reset. In many cases, the critic should also be reinitialized, especially if the new reward function is very different from the original one. Keeping the actor as an initialization can sometimes be useful, but keeping an old critic after a large reward change is risky.

### 3. Reward normalization keeps the critic scale more consistent

Instead of using only:

$$
r = -e^2
$$

this branch uses a normalized error term:

$$
r_e = -\left(\frac{e}{e_{\text{scale}}}\right)^2
$$

The parameter `e_scale` is chosen based on the expected error range of the current curriculum stage. For example:

| Stage | Expected error range | Typical `e_scale` |
|---|---:|---:|
| Local correction | up to about 2 | `2.0` |
| Medium transient | up to about 5 | `5.0` |
| Global robustness | larger operating range | `10.0` |
| Precision fine-tuning | small final errors | `1.0` or smaller |

This prevents the critic from seeing reward magnitudes that change too violently just because the curriculum stage changed. It also makes the reward parameters easier to tune because the tracking-error term stays in a more predictable numerical range.

### 4. Control effort and action smoothness are part of the control objective

A reward based only on error can encourage aggressive or oscillatory actions. In a real control system, it is usually not enough to reach the reference; the controller should also avoid unnecessary actuator effort and rapid control changes.

The final reward form therefore includes additional penalties:

$$
r =
-\left(\frac{e}{e_{\text{scale}}}\right)^2
-\lambda_u u^2
-\lambda_{\Delta u}(u-u_{\text{prev}})^2
+b_{\text{tol}}\mathbf{1}_{|e| < e_{\text{tol}}}
-p_{\text{unsafe}}\mathbf{1}_{\text{unsafe}}
$$

where:

| Term | Meaning |
|---|---|
| $e$ | tracking error |
| $e_{\text{scale}}$ | error normalization scale for the current stage |
| $u$ | current control action / flow command |
| $u_{\text{prev}}$ | previous control action |
| $\lambda_u$ | weight on control effort |
| $\lambda_{\Delta u}$ | weight on action-rate/smoothness penalty |
| $b_{\text{tol}}$ | optional small bonus for being inside a tight tolerance band |
| $p_{\text{unsafe}}$ | penalty for unsafe tank height |

In plain terms, the reward penalizes normalized tracking error, excessive action, sudden action changes, and unsafe tank levels, while optionally giving a small bonus for very accurate tracking.

## What Is Curriculum Training?

Curriculum training means training the agent on easier versions of the task first, then gradually increasing the difficulty. The idea is similar to how a human would learn a control task: first learn small corrections, then larger transients, then full-range operation, and finally fine tracking.

For this water tank, the curriculum is not meant to make the first stages trivial. The initial height should not always start exactly at the reference, because then the agent could receive good rewards by doing almost nothing. Instead, the early stages use small but nonzero initial errors so that the agent still has to learn meaningful control action.

The progression is:

$$
\text{small correction}
\rightarrow
\text{medium transient}
\rightarrow
\text{global robustness}
\rightarrow
\text{precision fine-tuning}
$$

The four stages are:

| Stage | Reset Distribution | Main Goal | Main Training Idea |
|---|---|---|---|
| 1 — Local correction | Initial height close to reference, for example `0.5 <= |h0 - hRef| <= 2` | Learn basic direction, local correction, and stabilization | Small exploration, normalized local error reward |
| 2 — Medium transient | Larger initial errors, for example up to about 5 units | Learn stronger approach behavior without excessive overshoot | Slightly wider reset distribution and moderate exploration |
| 3 — Global robustness | Reference and initial height sampled more broadly | Learn behavior across the operating range | Broader state distribution and larger error scale |
| 4 — Precision fine-tuning | Deployment-like distribution with small exploration | Reduce steady-state error and smooth the action | Lower exploration, stronger smoothness penalty, precision reward |

Between stages, the replay buffer is typically reset because the data from an earlier stage may no longer represent the current training objective. For example, Stage 1 contains mostly small-error local corrections, while Stage 3 contains wider operating conditions. Mixing those experiences without care can slow down or destabilize learning.

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

The detailed explanation of the curriculum is given above in [What Is Curriculum Training?](#what-is-curriculum-training).

## Reward Concept

The final reward form is:

$$
r =
-\left(\frac{e}{e_{\text{scale}}}\right)^2
-\lambda_u u^2
-\lambda_{\Delta u}(u-u_{\text{prev}})^2
+b_{\text{tol}}\mathbf{1}_{|e| < e_{\text{tol}}}
-p_{\text{unsafe}}\mathbf{1}_{\text{unsafe}}
$$

This reward encourages:

- small tracking error,
- limited actuator effort,
- smooth control changes,
- safe tank height,
- precise tracking near zero error.

The error scale `e_scale` should be selected based on the expected error range of the current stage. For example, if the reset function creates initial errors mostly between `0.5` and `2.0`, then `e_scale = 2.0` is a reasonable starting point. If the stage includes errors up to about `5.0`, then `e_scale = 5.0` is more appropriate.

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

A similar curriculum idea can be used by gradually increasing the initial angle range, angular velocity range, or disturbance magnitude.

## Recommended Development Workflow

1. Run only Stage 1 first.
2. Inspect tracking response and action signal.
3. Tune `NoiseStd`, `lambda_du`, and `e_scale`.
4. Continue to Stage 2 only when Stage 1 is stable.
5. Repeat for each stage.
6. Validate the final agent using deterministic simulation without exploration noise.

If you change the reward function drastically after training, do not assume the previous critic is still useful. Reset the replay buffer, and consider reinitializing the critic or retraining the agent from scratch.

## Practical Warning

A DDPG agent can output poor actions outside its training distribution. Always validate the final policy on initial conditions and references that represent deployment conditions.

For safety-critical systems, use action limits, termination logic, and preferably compare against a classical baseline controller.
