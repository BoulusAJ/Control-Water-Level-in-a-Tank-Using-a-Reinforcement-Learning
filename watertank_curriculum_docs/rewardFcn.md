# `rewardFcn.m`

## Purpose

`rewardFcn.m` computes the reinforcement learning reward and the termination flag `isDone`.

It supports multiple reward modes so the same Simulink model can be reused for different training phases.

## Function Signature

```matlab
function [r, isDone] = rewardFcn(e, u, u_prev, h, params)
```

## Inputs

| Input | Meaning |
|---|---|
| `e` | Tracking error, usually `hRef - h` |
| `u` | Current control action / flow command |
| `u_prev` | Previous control action |
| `h` | Current tank height |
| `params` | Reward parameter struct, usually `rewardParams` from base workspace |

## Outputs

| Output | Meaning |
|---|---|
| `r` | Scalar reward |
| `isDone` | Boolean termination flag |

## Required Simulink Usage

Inside the MATLAB Function block in Simulink, call:

```matlab
[r,isDone] = rewardFcn(e,u,u_prev,h,rewardParams);
```

The main training script assigns `rewardParams` before each stage.

## Termination Logic

```matlab
isDone = (h <= params.h_min) || (h >= params.h_max);
```

For the tank:

```text
unsafe if h <= 0 or h >= 20
```

If unsafe, the reward receives an additional penalty.

## Reward Modes

### Mode 1 — Original Boolean Reward

```text
+10 if |e| < threshold
-1 otherwise
-100 if unsafe
```

This is useful for demonstration but does not encourage exact zero error inside the tolerance band.

### Mode 2 — Normalized Squared Error

```text
r = -(e/e_scale)^2
```

This gives dense feedback and encourages smaller error.

### Mode 3 — Control-Oriented Reward

```text
r = -(e/e_scale)^2
    - lambda_u*u^2
    - lambda_du*(u-u_prev)^2
    + tolBonus if |e| < tol
    - unsafePenalty if unsafe
```

This is the recommended mode for final training.

## Important Parameters

| Parameter | Meaning |
|---|---|
| `mode` | Reward mode: 1, 2, or 3 |
| `e_scale` | Error normalization scale |
| `lambda_u` | Control effort penalty weight |
| `lambda_du` | Action-change penalty weight |
| `tol` | Precision tolerance band |
| `tolBonus` | Small bonus for being inside the precision band |
| `unsafePenalty` | Penalty for unsafe tank level |
| `h_min` | Minimum safe tank height |
| `h_max` | Maximum safe tank height |

## Why Normalize Error?

Without normalization:

```text
r = -e^2
```

larger-error stages produce much larger reward magnitudes than smaller-error stages.

This can destabilize the critic.

Using:

```text
r = -(e/e_scale)^2
```

keeps reward scales more comparable across curriculum stages.

## Tuning Advice

### If the action oscillates

Increase:

```matlab
lambda_du
```

or decrease exploration noise in `makeStageConfig.m`.

### If the controller is too weak

Decrease:

```matlab
lambda_u
lambda_du
```

### If tracking is not precise enough

Decrease:

```matlab
e_scale
```

or increase:

```matlab
tolBonus
```

slightly.

Do not make `tolBonus` too large, otherwise the agent may again only care about entering a band instead of minimizing error.
