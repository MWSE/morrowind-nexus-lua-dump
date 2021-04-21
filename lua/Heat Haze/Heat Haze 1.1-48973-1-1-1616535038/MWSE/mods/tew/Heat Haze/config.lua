return mwse.loadConfig("Heat Haze", {
    debugLogOn=false,
    overrideHours=false,
    hazeStartHour=6,
    hazeEndHour=21,
    heatRegions={
        ["Red Mountain Region"]=true,
        ["Ashlands Region"]=true,
        ["Armun Ashlands Region"]=true,
        ["Molag Mar Region"]=true
    },
    heatWeathers={
        ["Clear"]=true,
        ["Cloudy"]=true,
        ["Overcast"]=true
    }
})