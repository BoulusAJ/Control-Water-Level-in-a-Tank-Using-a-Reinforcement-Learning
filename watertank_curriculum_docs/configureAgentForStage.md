# `configureAgentForStage.m`

## Purpose

`configureAgentForStage.m` applies the settings that change from one curriculum stage to the next.

This keeps the main training loop simple.

## Function Signature

```matlab
agent = configureAgentForStage(agent, stage)
```

## Inputs

| Input | Meaning |
|---|---|
| `agent` | Current DDPG agent |
| `stage` | Current stage configuration from `cfg.Stages(k)` |

## Output

| Output | Meaning |
|---|---|
| `agent` | Agent with updated stage-specific settings |

## What It Changes

### Exploration Noise

```matlab
agent.AgentOptions.NoiseOptions.StandardDeviation = stage.NoiseStd;
agent.AgentOptions.NoiseOptions.StandardDeviationDecayRate = stage.NoiseDecay;
```

Large noise encourages exploration.

Small noise helps precision fine-tuning.

Recommended behavior:

| Stage | Noise |
|---|---|
| Local | small |
| Medium | moderate |
| Global | larger |
| Precision | very small |

### Replay Buffer Reset

```matlab
agent.AgentOptions.ResetExperienceBufferBeforeTraining = stage.ResetBuffer;
```

Usually set this to `true` between curriculum stages.

Reason:

```text
The reset distribution and reward scale may change between stages, so old experience can become misleading.
```

## When to Edit This File

Edit this file if you want stage-specific changes to:

- actor learning rate,
- critic learning rate,
- minibatch size,
- discount factor,
- target smoothing options,
- replay buffer behavior.

## Example Extension

You could add:

```matlab
agent.AgentOptions.ActorOptimizerOptions.LearnRate = stage.ActorLearnRate;
agent.AgentOptions.CriticOptimizerOptions.LearnRate = stage.CriticLearnRate;
```

Then add those values to each stage in `makeStageConfig.m`.
