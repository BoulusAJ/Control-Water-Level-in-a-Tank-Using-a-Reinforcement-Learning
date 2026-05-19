# `createDDPGAgent.m`

## Purpose

`createDDPGAgent.m` creates the DDPG actor, critic, and agent options.

It separates neural-network construction from the main training script so the main script stays clean.

## Inputs

```matlab
agent = createDDPGAgent(obsInfo, actInfo, cfg)
```

| Input | Meaning |
|---|---|
| `obsInfo` | Observation specification |
| `actInfo` | Action specification |
| `cfg` | Global configuration struct |

## Output

| Output | Meaning |
|---|---|
| `agent` | Configured `rlDDPGAgent` |

## Critic Network

The critic estimates:

```text
Q(observation, action)
```

It has two input paths:

1. Observation input
2. Action input

These are concatenated and passed through fully connected layers.

```matlab
obsPath = featureInputLayer(obsInfo.Dimension(1), Name="obsInLyr");
actPath = featureInputLayer(actInfo.Dimension(1), Name="actInLyr");
```

The critic output is a single scalar:

```matlab
fullyConnectedLayer(1,Name="QValue")
```

## Actor Network

The actor maps:

```text
observation -> action
```

The final `sigmoidLayer` bounds the actor output between 0 and 1:

```matlab
sigmoidLayer(Name="boundedAction")
```

This matches the tank flow constraint:

```text
0 <= u <= 1
```

## Agent Options

Important options:

```matlab
agent.AgentOptions.SampleTime = cfg.Ts;
agent.AgentOptions.DiscountFactor = 0.99;
agent.AgentOptions.MiniBatchSize = 256;
agent.AgentOptions.ExperienceBufferLength = 1e5;
```

## Learning Rates

Actor:

```matlab
LearnRate = 1e-4
```

Critic:

```matlab
LearnRate = 1e-3
```

If the policy becomes unstable, reduce the critic learning rate first.

## Common Modifications

### Larger Networks

For more complex systems, increase layer sizes:

```matlab
fullyConnectedLayer(64)
fullyConnectedLayer(64)
```

### Different Action Range

If the action is not normalized to `[0,1]`, change the actor output layer.

For example, if using `[-1,1]`, use:

```matlab
tanhLayer
```

and make sure `actInfo` matches.

### Switching to TD3 Later

This file is the right place to later replace:

```matlab
rlDDPGAgent
```

with a TD3 agent creation function.
