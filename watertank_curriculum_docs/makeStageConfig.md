# `makeStageConfig.m`

## Purpose

`makeStageConfig.m` defines all global settings and all four curriculum stages.

This is the main file to edit when tuning the training strategy.

## What It Returns

The function returns a struct:

```matlab
cfg = makeStageConfig();
```

`cfg` contains:

- Simulink model names,
- sample time and final simulation time,
- parallel training settings,
- save settings,
- stage definitions.

## Global Configuration

### Model Names

```matlab
cfg.ModelName = "rlwatertank";
cfg.AgentBlock = "rlwatertank/RL Agent";
```

Change these when adapting the script to another Simulink model.

### Timing

```matlab
cfg.Ts = 1.0;
cfg.Tf = 200;
```

This gives:

```text
200 decision steps per episode
```

because:

```matlab
MaxStepsPerEpisode = ceil(cfg.Tf/cfg.Ts)
```

### Parallel Training

```matlab
cfg.UseParallel = true;
cfg.RequestedWorkers = 12;
```

Use fewer workers if your machine becomes overloaded.

### Save Settings

```matlab
cfg.SaveReplayBuffer = false;
cfg.SaveTrainingStats = true;
```

Usually keep `SaveReplayBuffer = false` for curriculum learning because the replay buffer is intentionally reset between stages.

## Stage Structure

Each stage has these important fields:

```matlab
stages(k).Name
stages(k).MaxEpisodes
stages(k).Reset
stages(k).Reward
stages(k).NoiseStd
stages(k).NoiseDecay
stages(k).ResetBuffer
```

## The Four Stages

### Stage 1 — Local Correction

```matlab
0.5 <= |h0 - hRef| <= 2.0
```

Goal:

```text
Learn basic local correction and stabilization.
```

### Stage 2 — Medium Transient

```matlab
0.5 <= |h0 - hRef| <= 5.0
```

Goal:

```text
Learn larger transient behavior without becoming unstable.
```

### Stage 3 — Global Robustness

```matlab
h0 and hRef sampled independently
```

Goal:

```text
Learn robust behavior across the broader operating range.
```

### Stage 4 — Precision Fine-Tuning

Uses deployment-like reset distribution with smaller exploration.

Goal:

```text
Reduce steady-state error and smooth the control action.
```

## Reward Settings

Each stage has:

```matlab
stages(k).Reward.e_scale
stages(k).Reward.lambda_u
stages(k).Reward.lambda_du
stages(k).Reward.tol
stages(k).Reward.tolBonus
```

The main normalized reward is:

```text
-(e/e_scale)^2
```

This keeps reward magnitudes comparable between stages.

## Parameters to Tune First

### If the agent oscillates

Increase:

```matlab
lambda_du
```

Decrease:

```matlab
NoiseStd
```

### If the agent is too slow

Decrease:

```matlab
lambda_u
lambda_du
```

or increase:

```matlab
NoiseStd
```

slightly.

### If the critic becomes unstable

Try:

```matlab
Reward.e_scale
Critic LearnRate
MiniBatchSize
```

## Adapting to Another Plant

For a new nonlinear system, keep the stage idea but replace:

```matlab
Reset.hRefMean
Reset.hRefStd
Reset.minInitialError
Reset.maxInitialError
```

with variables meaningful for the new system.

For an inverted pendulum, for example, stages might gradually increase the initial angle range.
