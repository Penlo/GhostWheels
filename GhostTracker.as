// PB Ghost Wheel Lines — GhostTracker: captures trails from ghost vehicles in the scene

class Ghost_Trail
{
    array<Sample_Point@> samples;
    float minSpeed;
    float maxSpeed;
    bool complete;  // true once a full run has been captured

    Ghost_Trail()
    {
        minSpeed = 999999.0f;
        maxSpeed = -999999.0f;
        complete = false;
    }

    void AddSample(Sample_Point@ sp)
    {
        samples.InsertLast(sp);
        if (sp.speed < minSpeed) minSpeed = sp.speed;
        if (sp.speed > maxSpeed) maxSpeed = sp.speed;
    }

    void Clear()
    {
        samples.RemoveRange(0, samples.Length);
        minSpeed = 999999.0f;
        maxSpeed = -999999.0f;
        complete = false;
    }
}

class Ghost_Tracker
{
    array<Ghost_Trail@> trails;
    bool isTracking;

    Ghost_Tracker()
    {
        isTracking = false;
    }

    // Start a new tracking session. If trails already have complete data
    // from a previous run, keep them (they provide trail-ahead).
    // Only clear if they're incomplete fragments.
    void StartTracking()
    {
        for (uint i = 0; i < trails.Length; i++)
        {
            if (!trails[i].complete)
                trails[i].Clear();
        }
        isTracking = true;
    }

    // Mark current trails as complete (full run captured)
    void StopTracking()
    {
        for (uint i = 0; i < trails.Length; i++)
        {
            if (trails[i].samples.Length > 50)
                trails[i].complete = true;
        }
        isTracking = false;
    }

    void ClearAll()
    {
        trails.RemoveRange(0, trails.Length);
        isTracking = false;
    }

    void Tick(uint32 raceTime)
    {
        if (!isTracking)
            return;

        auto app = cast<CTrackMania>(GetApp());
        if (app is null || app.GameScene is null)
            return;

        auto sceneVis = app.GameScene;
        auto allVis = VehicleState::GetAllVis(sceneVis);
        if (allVis is null)
            return;

        CSceneVehicleVis@ playerVisHandle = null;
        auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
        if (playground !is null && playground.GameTerminals.Length > 0)
        {
            auto player = cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
            if (player !is null)
                @playerVisHandle = VehicleState::GetVis(sceneVis, player);
        }

        // Collect ghost states (exclude player)
        array<CSceneVehicleVisState@> ghostStates;
        for (uint v = 0; v < allVis.Length; v++)
        {
            auto vis = allVis[v];
            if (vis is null)
                continue;
            if (playerVisHandle !is null && vis is playerVisHandle)
                continue;
            auto state = vis.AsyncState;
            if (state is null)
                continue;
            ghostStates.InsertLast(state);
        }

        // Ensure we have enough trail slots
        while (trails.Length < ghostStates.Length)
            trails.InsertLast(Ghost_Trail());

        // Record each ghost — skip trails that are already complete
        for (uint g = 0; g < ghostStates.Length; g++)
        {
            if (trails[g].complete)
                continue;

            auto state = ghostStates[g];
            vec3 pos = state.Position;
            vec3 left = state.Left;
            vec3 up = state.Up;
            vec3 dir = state.Dir;

            float halfTrack = 0.75f;
            float frontAxle = 1.3f;
            float rearAxle = 1.1f;
            float groundDrop = 0.3f;

            vec3 groundOffset = up * (-groundDrop);
            vec3 fl = pos + dir * frontAxle + left * halfTrack + groundOffset;
            vec3 fr = pos + dir * frontAxle - left * halfTrack + groundOffset;
            vec3 rl = pos - dir * rearAxle + left * halfTrack + groundOffset;
            vec3 rr = pos - dir * rearAxle - left * halfTrack + groundOffset;

            Sample_Point@ sp = Sample_Point(fl, fr, rl, rr, state.FrontSpeed * 3.6f, raceTime);
            trails[g].AddSample(sp);
        }
    }
}
