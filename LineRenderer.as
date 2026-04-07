// PB Ghost Wheel Lines — Line_Renderer: draws speed-colored wheel lines on the track surface
// Color modes: 0=Speed, 1=Time Delta, 2=Both (speed color + width varies by delta)

class Line_Renderer
{
    bool enabled;
    float lineWidth;
    float opacity;
    array<Sample_Point@>@ pbSamples;
    float minSpeed;
    float maxSpeed;

    int trailBehind;
    int trailAhead;
    int fadeZone;
    int currentRaceTime;

    array<Ghost_Trail@>@ ghostTrails;

    // Color mode: 0=Speed, 1=TimeDelta, 2=Both
    int colorMode;
    float maxDelta;

    Line_Renderer()
    {
        enabled = true;
        lineWidth = 2.0f;
        opacity = 0.8f;
        @pbSamples = null;
        minSpeed = 0.0f;
        maxSpeed = 0.0f;
        trailBehind = 3000;
        trailAhead = 2000;
        fadeZone = 1500;
        currentRaceTime = -1;
        @ghostTrails = null;
        colorMode = 0;
        maxDelta = 2000.0f;
    }

    void SetPBData(array<Sample_Point@>@ samples, float minSpd, float maxSpd)
    {
        @pbSamples = samples;
        minSpeed = minSpd;
        maxSpeed = maxSpd;
    }

    void ClearPBData() { @pbSamples = null; minSpeed = 0.0f; maxSpeed = 0.0f; }
    void SetGhostTrails(array<Ghost_Trail@>@ trails) { @ghostTrails = trails; }
    void ClearGhostTrails() { @ghostTrails = null; }

    // Find the sample index closest to a world position (for distance-based anchoring)
    uint FindNearestByPosition(array<Sample_Point@>@ samples, vec3 pos)
    {
        float bestDist = 999999999.0f;
        uint bestIdx = 0;
        // Search around the time-based estimate first for performance
        uint timeGuess = FindStartByTime(samples, currentRaceTime);
        uint searchStart = (timeGuess > 300) ? timeGuess - 300 : 0;
        uint searchEnd = timeGuess + 300;
        if (searchEnd > samples.Length) searchEnd = samples.Length;

        for (uint i = searchStart; i < searchEnd; i++)
        {
            // Use the average of FL and FR as the center position
            vec3 center = (samples[i].wheelFL + samples[i].wheelFR) * 0.5f;
            vec3 diff = center - pos;
            float dist = diff.x * diff.x + diff.y * diff.y + diff.z * diff.z;
            if (dist < bestDist)
            {
                bestDist = dist;
                bestIdx = i;
            }
        }
        return bestIdx;
    }

    // Binary search by time
    uint FindStartByTime(array<Sample_Point@>@ samples, int targetTime)
    {
        uint lo = 0;
        uint hi = samples.Length;
        while (lo < hi)
        {
            uint mid = (lo + hi) / 2;
            if (int(samples[mid].raceTime) < targetTime)
                lo = mid + 1;
            else
                hi = mid;
        }
        return lo;
    }

    void DrawTrail(array<Sample_Point@>@ samples, float globalMin, float globalMax)
    {
        if (samples.Length < 2)
            return;

        int windowStart = currentRaceTime - trailBehind;
        int windowEnd = currentRaceTime + trailAhead;
        int fadeStart = currentRaceTime + trailAhead - fadeZone;

        uint startIdx = FindStartByTime(samples, windowStart);

        // Local min/max speed pass (for speed color mode)
        float localMin = 999999.0f;
        float localMax = -999999.0f;
        for (uint j = startIdx; j < samples.Length; j++)
        {
            int t = int(samples[j].raceTime);
            if (t > windowEnd) break;
            float s = samples[j].speed;
            if (s < localMin) localMin = s;
            if (s > localMax) localMax = s;
        }
        if (localMin >= localMax)
        {
            localMin = globalMin;
            localMax = globalMax;
        }

        // Draw pass
        for (uint i = startIdx; i < samples.Length - 1; i++)
        {
            Sample_Point@ a = samples[i];
            int sampleTime = int(a.raceTime);
            if (sampleTime > windowEnd) break;

            Sample_Point@ b = samples[i + 1];

            if (Camera::IsBehind(a.wheelFL) || Camera::IsBehind(a.wheelFR) ||
                Camera::IsBehind(a.wheelRL) || Camera::IsBehind(a.wheelRR) ||
                Camera::IsBehind(b.wheelFL) || Camera::IsBehind(b.wheelFR) ||
                Camera::IsBehind(b.wheelRL) || Camera::IsBehind(b.wheelRR))
                continue;

            // Fade at leading edge
            float segOpacity = opacity;
            if (sampleTime > fadeStart && fadeZone > 0)
            {
                float fadeFrac = float(sampleTime - fadeStart) / float(fadeZone);
                if (fadeFrac > 1.0f) fadeFrac = 1.0f;
                segOpacity = opacity * (1.0f - fadeFrac);
            }
            if (segOpacity < 0.01f) continue;

            // Compute time delta for this sample
            float timeDelta = float(currentRaceTime - sampleTime);

            // Choose color based on mode
            vec4 color;
            float segWidth = lineWidth;

            if (colorMode == 0)
            {
                // Speed mode: red=slow, green=fast
                color = SpeedToColor(a.speed, localMin, localMax, segOpacity);
            }
            else if (colorMode == 1)
            {
                // Time Delta mode: cyan-green=ahead, orange-red=behind, white=even
                color = TimeDeltaToColor(timeDelta, maxDelta, segOpacity);
            }
            else
            {
                // Both mode: speed color + line width varies by delta
                color = SpeedToColor(a.speed, localMin, localMax, segOpacity);
                // Width: thinner when ahead (good), thicker when behind (warning)
                float deltaFrac = timeDelta / maxDelta;
                if (deltaFrac < -1.0f) deltaFrac = -1.0f;
                if (deltaFrac > 1.0f) deltaFrac = 1.0f;
                // Range: 0.5x to 2x of base line width
                segWidth = lineWidth * (1.0f + deltaFrac * 0.5f);
                if (segWidth < 0.5f) segWidth = 0.5f;
            }

            nvg::StrokeWidth(segWidth);
            nvg::StrokeColor(color);

            vec2 sFL_a = Camera::ToScreenSpace(a.wheelFL);
            vec2 sFR_a = Camera::ToScreenSpace(a.wheelFR);
            vec2 sRL_a = Camera::ToScreenSpace(a.wheelRL);
            vec2 sRR_a = Camera::ToScreenSpace(a.wheelRR);
            vec2 sFL_b = Camera::ToScreenSpace(b.wheelFL);
            vec2 sFR_b = Camera::ToScreenSpace(b.wheelFR);
            vec2 sRL_b = Camera::ToScreenSpace(b.wheelRL);
            vec2 sRR_b = Camera::ToScreenSpace(b.wheelRR);

            nvg::BeginPath(); nvg::MoveTo(sFL_a); nvg::LineTo(sFL_b); nvg::Stroke();
            nvg::BeginPath(); nvg::MoveTo(sFR_a); nvg::LineTo(sFR_b); nvg::Stroke();
            nvg::BeginPath(); nvg::MoveTo(sRL_a); nvg::LineTo(sRL_b); nvg::Stroke();
            nvg::BeginPath(); nvg::MoveTo(sRR_a); nvg::LineTo(sRR_b); nvg::Stroke();
        }
    }

    void Render()
    {
        if (!enabled)
            return;

        if (currentRaceTime <= 0)
            return;

        nvg::StrokeWidth(lineWidth);

        if (ghostTrails !is null)
        {
            for (uint g = 0; g < ghostTrails.Length; g++)
            {
                auto trail = ghostTrails[g];
                if (trail !is null && trail.samples.Length >= 2)
                    DrawTrail(trail.samples, trail.minSpeed, trail.maxSpeed);
            }
        }
    }
}
