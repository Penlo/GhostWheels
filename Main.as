// PB Ghost Wheel Lines — OpenPlanet Plugin Entry Point

Line_Renderer g_renderer;
Ghost_Tracker g_ghostTracker;

uint dbgCounter = 0;

void Main()
{
    int lastRaceTime = -1;
    bool wasRacing = false;
    string currentMapUid = "";

    while (true)
    {
        yield();
        dbgCounter++;

        auto app = cast<CTrackMania>(GetApp());
        if (app is null)
            continue;

        auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
        if (playground is null)
        {
            if (wasRacing)
            {
                g_ghostTracker.ClearAll();
                wasRacing = false;
                lastRaceTime = -1;
            }
            if (currentMapUid.Length > 0)
            {
                g_renderer.ClearGhostTrails();
                currentMapUid = "";
            }
            continue;
        }

        auto map = playground.Map;
        if (map is null || map.MapInfo is null)
            continue;

        string mapUid = map.MapInfo.MapUid;

        if (mapUid != currentMapUid)
        {
            if (wasRacing)
            {
                g_ghostTracker.ClearAll();
                wasRacing = false;
                lastRaceTime = -1;
            }
            g_renderer.ClearGhostTrails();
            currentMapUid = mapUid;
        }

        // Get player
        if (playground.GameTerminals.Length == 0)
            continue;
        auto terminal = playground.GameTerminals[0];
        auto player = cast<CSmPlayer>(terminal.GUIPlayer);
        if (player is null)
            continue;

        // Compute race time
        auto playgroundScript = app.PlaygroundScript;
        int raceTime = -1;
        if (playgroundScript !is null && player.StartTime >= 0)
        {
            int now = playgroundScript.Now;
            raceTime = now - player.StartTime;
        }

        // Run start detection — keep previous trail data for "trail ahead"
        if (raceTime > 0 && (lastRaceTime <= 0 || raceTime < lastRaceTime))
        {
            // Don't clear trails — previous run's ghost data is still valid
            // for showing the path ahead. Just restart tracking to capture fresh data.
            g_ghostTracker.StartTracking();
            wasRacing = true;
        }

        // Tick ghost tracker each frame to capture all ghost positions
        if (raceTime > 0 && g_ghostTracker.isTracking)
        {
            g_ghostTracker.Tick(uint32(raceTime));
        }

        // Pass trails to renderer
        g_renderer.SetGhostTrails(g_ghostTracker.trails);

        // Detect finish — stop tracking but keep trails visible
        auto uiSequence = terminal.UISequence_Current;
        if (wasRacing && uiSequence == CGamePlaygroundUIConfig::EUISequence::Finish)
        {
            g_ghostTracker.StopTracking();
            wasRacing = false;
        }

        if (raceTime <= 0 && wasRacing)
            wasRacing = false;

        g_renderer.currentRaceTime = raceTime;
        lastRaceTime = raceTime;
    }
}

bool g_showUI = false;

void Render()
{
    g_renderer.enabled = Setting_Enabled;
    g_renderer.lineWidth = Setting_LineWidth;
    g_renderer.opacity = Setting_Opacity;
    g_renderer.trailBehind = int(Setting_TrailBehind * 1000);
    g_renderer.trailAhead = int(Setting_TrailAhead * 1000);
    g_renderer.fadeZone = int(Setting_FadeZone * 1000);
    g_renderer.colorMode = Setting_ColorMode;
    g_renderer.maxDelta = Setting_MaxDelta;
    g_renderer.Render();
}

// Adds a menu item under Plugins > PB Ghost Wheel Lines to toggle the settings panel
void RenderMenu()
{
    if (UI::MenuItem("\\$0f0\\$s" + Icons::Road + "\\$z Ghost Wheels", "", g_showUI))
        g_showUI = !g_showUI;
}

// The settings panel — only shown when toggled via the menu
void RenderInterface()
{
    if (!g_showUI)
        return;

    UI::SetNextWindowSize(320, 380, UI::Cond::FirstUseEver);
    if (UI::Begin("Ghost Wheels", g_showUI, UI::WindowFlags::NoCollapse))
    {
        Setting_Enabled = UI::Checkbox("Enabled", Setting_Enabled);
        UI::Separator();
        Setting_LineWidth = UI::SliderFloat("Line Width", Setting_LineWidth, 0.5, 10.0);
        Setting_Opacity = UI::SliderFloat("Opacity", Setting_Opacity, 0.0, 1.0);
        Setting_TrailBehind = UI::SliderFloat("Trail Behind (s)", Setting_TrailBehind, 0.5, 30.0);
        Setting_TrailAhead = UI::SliderFloat("Trail Ahead (s)", Setting_TrailAhead, 0.5, 30.0);
        Setting_FadeZone = UI::SliderFloat("Fade Zone (s)", Setting_FadeZone, 0.0, 10.0);
        UI::Separator();
        UI::Text("Color Mode");
        if (UI::RadioButton("Speed", Setting_ColorMode == 0))
            Setting_ColorMode = 0;
        UI::SameLine();
        if (UI::RadioButton("Time Delta", Setting_ColorMode == 1))
            Setting_ColorMode = 1;
        UI::SameLine();
        if (UI::RadioButton("Both", Setting_ColorMode == 2))
            Setting_ColorMode = 2;
        if (Setting_ColorMode >= 1)
            Setting_MaxDelta = UI::SliderFloat("Delta Range (ms)", Setting_MaxDelta, 500.0, 10000.0);
    }
    UI::End();
}
