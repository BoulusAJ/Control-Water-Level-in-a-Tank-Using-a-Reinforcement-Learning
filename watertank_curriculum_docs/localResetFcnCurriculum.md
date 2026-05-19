# `localResetFcnCurriculum.m`

## Purpose

`localResetFcnCurriculum.m` randomizes the water tank reference height and initial height at the start of each episode.

It reads the active curriculum stage settings from the MATLAB base workspace variable:

```matlab
curriculumParams
```

The main training script updates this variable before each stage.

## Function Signature

```matlab
function in = localResetFcnCurriculum(in)
```

This function is assigned to the environment using:

```matlab
env.ResetFcn = @localResetFcnCurriculum;
```

## Required Simulink Blocks

The function assumes these block paths:

```matlab
blkRef = sprintf("rlwatertank/Desired \nWater Level");
blkH   = "rlwatertank/Water-Tank System/H";
```

Change these paths if your model uses different names.

## Reset Modes

### `offset` Mode

Used in early curriculum stages.

It samples a reference height first:

```matlab
hRef = hRefStd*randn + hRefMean;
```

Then it samples an initial height near the reference:

```text
minInitialError <= |h0 - hRef| <= maxInitialError
```

This ensures the agent must do something, but the task is not too difficult.

### `independent` Mode

Used in later stages.

It samples reference and initial height independently:

```text
hRef ~ truncated Gaussian
h0   ~ truncated Gaussian
```

This is closer to the original MathWorks setup.

## Important Parameters

Defined in `makeStageConfig.m`:

```matlab
Reset.mode
Reset.hRefMean
Reset.hRefStd
Reset.hMin
Reset.hMax
Reset.minInitialError
Reset.maxInitialError
```

## Why This Matters

The reset distribution defines the training distribution.

If the agent never trains near a condition, it may behave poorly there during inference.

For example, if the agent only trains near:

```text
h0 ≈ hRef
```

then it may not learn strong transient behavior from large initial errors.

## Adapting to Another Plant

For an inverted pendulum, this function would randomize states such as:

```text
theta0
omega0
cart position
cart velocity
```

The same curriculum idea applies:

```text
small initial angle -> larger angle -> full operating range
```
