# `trainWaterTankCurriculumDDPG.m`

## Purpose

`trainWaterTankCurriculumDDPG.m` is the main training script.

It performs the complete workflow:

1. Initializes random seed.
2. Opens the Simulink model.
3. Creates the RL environment.
4. Creates the DDPG agent.
5. Starts a parallel pool if enabled.
6. Runs the four curriculum training stages.
7. Saves the agent and training statistics after each stage.
8. Simulates the final trained agent.
9. Saves the final agent and validation experiences.

## When to Edit This File

Edit this file when you want to change the overall training workflow, for example:

- enable or disable parallel training,
- change how stages are looped through,
- add validation after each stage,
- load an existing agent before curriculum training,
- change save behavior globally.

Most tuning should happen in `makeStageConfig.m`, not here.

## Key Sections

### Setup

```matlab
previousRngState = rng(0,"twister");
cfg = makeStageConfig();
```

This fixes the random seed and loads the training configuration.

### Simulink Setup

```matlab
open_system(mdl);
set_param(mdl, FastRestart="on", SimulationMode="accelerator");
```

This opens the model and enables faster simulation.

### Observation Specification

```matlab
obsInfo = rlNumericSpec([3 1], ...
    LowerLimit=[-inf -inf 0]', ...
    UpperLimit=[ inf  inf inf]');
```

The observation vector is:

```text
[integrated error; error; measured height]
```

### Action Specification

```matlab
actInfo = rlNumericSpec([1 1], LowerLimit=0, UpperLimit=1);
```

The action is the normalized flow command.

For the water tank, this constrains the agent output to:

```text
0 <= u <= 1
```

### Curriculum Loop

```matlab
for k = 1:numel(cfg.Stages)
    stage = cfg.Stages(k);
    assignin("base","curriculumParams",stage.Reset);
    assignin("base","rewardParams",stage.Reward);
    agent = configureAgentForStage(agent, stage);
    trainingStats = train(agent, env, trainOpts, Evaluator=evl);
end
```

Before each stage, the script updates:

- `curriculumParams` for the reset function,
- `rewardParams` for the reward function,
- agent exploration and replay-buffer behavior.

## Important Variables

| Variable | Meaning |
|---|---|
| `cfg` | Global configuration struct from `makeStageConfig.m` |
| `stage` | Current curriculum stage configuration |
| `env` | Simulink RL environment |
| `agent` | DDPG agent |
| `trainingStats` | Training output from MATLAB RL Toolbox |
| `experiences` | Final simulation data |

## Common Modifications

### Disable Parallel Training

In `makeStageConfig.m`, set:

```matlab
cfg.UseParallel = false;
```

### Disable Training Plot

In `makeStageConfig.m`, set:

```matlab
cfg.PlotMode = "none";
```

### Run Fewer Episodes

Edit each stage in `makeStageConfig.m`:

```matlab
stages(1).MaxEpisodes = 200;
```

### Load an Existing Agent

Add before the curriculum loop:

```matlab
load("myAgent.mat","agent");
```

## Expected Outputs

The script saves one file per stage and one final file.

Example:

```text
WaterTankDDPG_curriculum_stage_01_local.mat
WaterTankDDPG_curriculum_final.mat
```
