// PB Ghost Wheel Lines — Speed_Color_Map: pure function mapping speed to RGB color

// Maps a speed value to a color on a red → yellow → green gradient.
//
// Normalizes speed into [0, 1] using minSpeed and maxSpeed.
//   t = 0.0 → red   (1, 0, 0)
//   t = 0.5 → yellow (1, 1, 0)
//   t = 1.0 → green  (0, 1, 0)
//
// For t in [0, 0.5]:   red = 1,              green = t * 2
// For t in [0.5, 1]:   red = 1 - (t-0.5)*2, green = 1
// Blue is always 0.
//
// Clamps out-of-range values to nearest bound.
// Returns yellow midpoint when minSpeed == maxSpeed (avoids division by zero).
// Deterministic: same inputs always produce the same output.

vec4 SpeedToColor(float speed, float minSpeed, float maxSpeed, float opacity)
{
    float t;

    if (minSpeed >= maxSpeed)
    {
        // Avoid division by zero; return yellow midpoint
        t = 0.5f;
    }
    else
    {
        t = (speed - minSpeed) / (maxSpeed - minSpeed);
    }

    // Clamp t to [0, 1]
    if (t < 0.0f) t = 0.0f;
    if (t > 1.0f) t = 1.0f;

    float r;
    float g;

    if (t <= 0.5f)
    {
        r = 1.0f;
        g = t * 2.0f;
    }
    else
    {
        r = 1.0f - (t - 0.5f) * 2.0f;
        g = 1.0f;
    }

    return vec4(r, g, 0.0f, opacity);
}

// Time delta color: maps time difference to a color.
// timeDelta = playerRaceTime - pbSampleTime at the same track position
//   positive = player is behind PB (slower) → warm orange-red
//   negative = player is ahead of PB (faster) → cool cyan-green
//   zero = even → white
//
// maxDelta controls the saturation range (ms). Beyond this, color is fully saturated.
vec4 TimeDeltaToColor(float timeDeltaMs, float maxDeltaMs, float opacity)
{
    if (maxDeltaMs <= 0.0f)
        maxDeltaMs = 2000.0f;

    float t = timeDeltaMs / maxDeltaMs;
    if (t < -1.0f) t = -1.0f;
    if (t > 1.0f) t = 1.0f;

    float r, g, b;

    if (t > 0.0f)
    {
        // Behind PB: warm orange → red
        // t=0: white (1,1,1) → t=1: orange-red (1, 0.3, 0.1)
        r = 1.0f;
        g = 1.0f - t * 0.7f;
        b = 1.0f - t * 0.9f;
    }
    else
    {
        // Ahead of PB: cool cyan → green
        // t=0: white (1,1,1) → t=-1: cyan-green (0.1, 1, 0.6)
        float at = -t;
        r = 1.0f - at * 0.9f;
        g = 1.0f;
        b = 1.0f - at * 0.4f;
    }

    return vec4(r, g, b, opacity);
}
