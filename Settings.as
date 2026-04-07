// PB Ghost Wheel Lines — Plugin Settings
// Uses OpenPlanet's [Setting] attribute for automatic persistence to Settings.ini.

[Setting name="Display Enabled" description="Toggle wheel line display on/off"]
bool Setting_Enabled = true;

[Setting name="Line Width" description="Width of the wheel lines" min=0.5 max=10.0]
float Setting_LineWidth = 2.0;

[Setting name="Line Opacity" description="Opacity of the wheel lines" min=0.0 max=1.0]
float Setting_Opacity = 0.8;

[Setting name="Trail Behind (seconds)" description="How many seconds of trail to show behind your current position" min=0.5 max=30.0]
float Setting_TrailBehind = 3.0;

[Setting name="Trail Ahead (seconds)" description="How many seconds of trail to show ahead of your current position" min=0.5 max=30.0]
float Setting_TrailAhead = 2.0;

[Setting name="Fade Zone (seconds)" description="How many seconds at the leading edge fade out" min=0.0 max=10.0]
float Setting_FadeZone = 1.5;

[Setting name="Color Mode" description="0 = Speed, 1 = Time Delta, 2 = Both (speed color + width pulse)" min=0 max=2]
int Setting_ColorMode = 0;

[Setting name="Time Delta Range (ms)" description="Max time delta for full color saturation in Time Delta mode" min=500 max=10000]
float Setting_MaxDelta = 2000.0;
