// PB Ghost Wheel Lines — Sample_Point data structure and serialization helpers

class Sample_Point
{
    vec3 wheelFL;    // front-left wheel world position
    vec3 wheelFR;    // front-right wheel world position
    vec3 wheelRL;    // rear-left wheel world position
    vec3 wheelRR;    // rear-right wheel world position
    float speed;     // car speed in km/h
    uint32 raceTime; // race clock in milliseconds

    Sample_Point()
    {
        speed = 0.0f;
        raceTime = 0;
    }

    Sample_Point(vec3 fl, vec3 fr, vec3 rl, vec3 rr, float spd, uint32 t)
    {
        wheelFL = fl;
        wheelFR = fr;
        wheelRL = rl;
        wheelRR = rr;
        speed = spd;
        raceTime = t;
    }

    Json::Value@ ToJson()
    {
        Json::Value@ obj = Json::Object();
        obj["wFL"] = Vec3ToJson(wheelFL);
        obj["wFR"] = Vec3ToJson(wheelFR);
        obj["wRL"] = Vec3ToJson(wheelRL);
        obj["wRR"] = Vec3ToJson(wheelRR);
        obj["spd"] = speed;
        obj["t"] = raceTime;
        return obj;
    }
}

Sample_Point@ SamplePointFromJson(Json::Value@ json)
{
    if (json is null)
        return null;

    Sample_Point@ sp = Sample_Point();
    sp.wheelFL = Vec3FromJson(json["wFL"]);
    sp.wheelFR = Vec3FromJson(json["wFR"]);
    sp.wheelRL = Vec3FromJson(json["wRL"]);
    sp.wheelRR = Vec3FromJson(json["wRR"]);
    sp.speed = float(json["spd"]);
    sp.raceTime = uint32(int(json["t"]));
    return sp;
}

Json::Value@ Vec3ToJson(vec3 v)
{
    Json::Value@ arr = Json::Array();
    arr.Add(v.x);
    arr.Add(v.y);
    arr.Add(v.z);
    return arr;
}

vec3 Vec3FromJson(Json::Value@ json)
{
    if (json is null || json.Length < 3)
        return vec3(0, 0, 0);

    return vec3(float(json[0]), float(json[1]), float(json[2]));
}
