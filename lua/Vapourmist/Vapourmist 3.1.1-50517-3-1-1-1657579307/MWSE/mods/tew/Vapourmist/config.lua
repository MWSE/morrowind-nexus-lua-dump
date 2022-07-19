return mwse.loadConfig(
    "Vapourmist",
    {
        debugLogOn = false,
        interiorFog = true,
        cloudyWeathers = {
            ["Cloudy"]=true,
            ["Foggy"]=true,
            ["Rain"]=true,
            ["Snow"]=true,
            ["Thunderstorm"]=true,
        },
        mistyWeathers={
            ["Foggy"]=true,
        },
        blockedCloud = {
            ["Ash"]=true,
            ["Blight"]=true
        },
        blockedMist={
            ["Ash"]=true,
            ["Blight"]=true,
            ["Snow"] = true,
            ["Blizzard"] = true,
            ["Rain"] = true,
            ["Thunderstorm"] = true
        }
    }
)