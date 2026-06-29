# Lith Simulator

A Processing sketch that simulates lith-style development dynamics from an input image.

## What the simulation does

The loaded image is converted into a per-pixel tone seed (`t`) from brightness:

- brighter pixels -> lower `t`
- darker pixels -> higher `t`

Each simulation step updates three main per-pixel state values:

- developer activity (`dev`)
- exhaustion (`exhausted`)
- developed density (`developed`)

The rendered output maps density from white -> sepia -> black.

## Parameters

All of these are exposed as sliders in the UI.

### seedRate (0..1)
Base spontaneous activation rate.

- Higher values cause more development to start without needing nearby developed neighbors.
- Strongest effect in darker areas (higher tone seed).

### infectionRate (0..1)
Neighbor-driven spread strength.

- Controls how much development propagates from nearby high-`dev` pixels.
- Higher values produce faster lateral spread and stronger clustering.

### developRate (0..1)
Conversion rate from active developer into final developed density.

- Higher values darken the image more quickly.
- Increases the speed at which pixels approach fully developed black.

### exhaustionRate (0..1)
How quickly activity consumes fresh capacity and raises exhaustion.

- Higher values suppress sustained activity sooner.
- Can prevent runaway spread by exhausting active regions faster.

### exhaustionRecovery (0..1)
Recovery rate of exhausted pixels.

- Higher values let exhausted pixels become active again sooner.
- Supports repeated/local reactivation over time.

### autocatalyticRate (0..1)
Self-reinforcement from already developed density.

- Higher values make developed regions accelerate their own continued growth.
- Increases contrast and can push dark regions deeper/faster.

### lightHue (0..360)
Hue for the mid-tone paper anchor color in rendering.

- Does not change simulation dynamics.
- Only changes visual tint of lighter-to-mid densities.

### lightSaturation (0..100)
Saturation for the same light-tone anchor color.

- Does not change simulation dynamics.
- Lower values look more neutral/gray-beige; higher values look more chromatic.

### noiseAmount (0..0.5)
Amount of static per-pixel random tone perturbation.

- Adds grain/texture to tone seed before each step.
- Higher values create more stochastic variation in where development starts/spreads.

### verticalBanding (0..1)
Vertical band modulation strength applied to `noiseAmount`.

- Uses a smoothed random profile across x.
- Higher values create stronger column-wise differences in effective noise, producing subtle to strong vertical bands.

### horizontalBanding (0..1)
Horizontal band modulation strength applied to `noiseAmount`.

- Uses a smoothed random profile across y.
- Higher values create stronger row-wise differences in effective noise, producing subtle to strong horizontal bands.

## Equations

For each pixel index `i` at position `(x, y)`, one simulation step computes:

Input tone and modulation:

- `verticalBand = verticalBandProfile[x] * verticalBanding`
- `horizontalBand = horizontalBandProfile[y] * horizontalBanding`
- `localNoiseAmount = noiseAmount * (1 + verticalBand) * (1 + horizontalBand)`
- `t = clamp(toneSeed[i] + toneNoise[i] * localNoiseAmount, 0, 1)`

Neighborhood activity:

- `neighborDev = weightedMean(devA of 8-neighborhood)`

Fresh capacity:

- `fresh = 1 - exhaustedA[i]`

Growth terms:

- `seed = seedRate * t * fresh * (1 - developedA[i])`
- `autocatalysis = autocatalyticRate * developedA[i] * t * fresh`
- `infection = infectionRate * max(0, neighborDev - devA[i]) * fresh`

Developer activity update:

- `devGain = seed + autocatalysis + infection`
- `devLoss = exhaustionRate * devA[i]`
- `devNext = clamp(devA[i] + devGain - devLoss, 0, 1)`

Developed density update:

- `dDevelop = developRate * devNext * t * (1 - developedA[i])`
- `developedNext = clamp(developedA[i] + dDevelop, 0, 1)`

Exhaustion update:

- `exhaustGain = exhaustionRate * (devNext + 0.5 * dDevelop)`
- `exhaustLoss = exhaustionRecovery * (1 - devNext)`
- `exhaustedNext = clamp(exhaustedA[i] + exhaustGain - exhaustLoss, 0, 1)`

Buffer swap after full image pass:

- `devA <- devNext`
- `developedA <- developedNext`
- `exhaustedA <- exhaustedNext`

Where `clamp(v, 0, 1)` means constraining to the `[0, 1]` range.

## Buttons / controls

### Load Image
Opens a file picker and loads an image from disk.

- On success: resets and starts simulation from that image.
- On cancel/failure: status text reports the result.

### Reset
Reinitializes the simulation using the currently loaded image.

### Pause / Run
Toggles simulation stepping.

### Save Image
Writes the current rendered image to the sketch folder in TIFF format as:

- `lith_YYYYMMDD_HHMMSS.tif`

## Practical tuning tips

- Faster spread: increase `infectionRate`.
- More self-darkening: increase `autocatalyticRate` and `developRate`.
- More restrained growth: increase `exhaustionRate` or lower `seedRate`.
- More texture/grain: increase `noiseAmount`.
- Add vertical striping: increase `verticalBanding`.
- Add horizontal striping: increase `horizontalBanding`.

## Requirements

- Processing (Java mode)
- `controlP5` library
