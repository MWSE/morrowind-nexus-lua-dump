return {

    -- The table is formatted this way so we can easily iterate through it using ipairs.
    -- This is needed so the regions and weather sliders will display in the correct order in the MCM.
    defaults = {
        {
            id = "Bitter Coast Region",
            weathers = {
                {
                    id = tostring(tes3.weather.clear),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.cloudy),
                    chance = 60,
                },
                {
                    id = tostring(tes3.weather.foggy),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.overcast),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.rain),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.thunder),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.ash),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blight),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.snow),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blizzard),
                    chance = 0,
                },
            },
        },
        {
            id = "Ascadian Isles Region",
            weathers = {
                {
                    id = tostring(tes3.weather.clear),
                    chance = 45,
                },
                {
                    id = tostring(tes3.weather.cloudy),
                    chance = 45,
                },
                {
                    id = tostring(tes3.weather.foggy),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.overcast),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.rain),
                    chance = 5,
                },
                {
                    id = tostring(tes3.weather.thunder),
                    chance = 5,
                },
                {
                    id = tostring(tes3.weather.ash),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blight),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.snow),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blizzard),
                    chance = 0,
                },
            },
        },
        {
            id = "West Gash Region",
            weathers = {
                {
                    id = tostring(tes3.weather.clear),
                    chance = 15,
                },
                {
                    id = tostring(tes3.weather.cloudy),
                    chance = 30,
                },
                {
                    id = tostring(tes3.weather.foggy),
                    chance = 15,
                },
                {
                    id = tostring(tes3.weather.overcast),
                    chance = 20,
                },
                {
                    id = tostring(tes3.weather.rain),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.thunder),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.ash),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blight),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.snow),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blizzard),
                    chance = 0,
                },
            },
        },
        {
            id = "Azura's Coast Region",
            weathers = {
                {
                    id = tostring(tes3.weather.clear),
                    chance = 25,
                },
                {
                    id = tostring(tes3.weather.cloudy),
                    chance = 45,
                },
                {
                    id = tostring(tes3.weather.foggy),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.overcast),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.rain),
                    chance = 5,
                },
                {
                    id = tostring(tes3.weather.thunder),
                    chance = 5,
                },
                {
                    id = tostring(tes3.weather.ash),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blight),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.snow),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blizzard),
                    chance = 0,
                },
            },
        },
        {
            id = "Grazelands Region",
            weathers = {
                {
                    id = tostring(tes3.weather.clear),
                    chance = 30,
                },
                {
                    id = tostring(tes3.weather.cloudy),
                    chance = 40,
                },
                {
                    id = tostring(tes3.weather.foggy),
                    chance = 5,
                },
                {
                    id = tostring(tes3.weather.overcast),
                    chance = 5,
                },
                {
                    id = tostring(tes3.weather.rain),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.thunder),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.ash),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blight),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.snow),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blizzard),
                    chance = 0,
                },
            },
        },
        {
            id = "Ashlands Region",
            weathers = {
                {
                    id = tostring(tes3.weather.clear),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.cloudy),
                    chance = 25,
                },
                {
                    id = tostring(tes3.weather.foggy),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.overcast),
                    chance = 25,
                },
                {
                    id = tostring(tes3.weather.rain),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.thunder),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.ash),
                    chance = 30,
                },
                {
                    id = tostring(tes3.weather.blight),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.snow),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blizzard),
                    chance = 0,
                },
            },
        },
        {
            id = "Molag Mar Region",
            weathers = {
                {
                    id = tostring(tes3.weather.clear),
                    chance = 5,
                },
                {
                    id = tostring(tes3.weather.cloudy),
                    chance = 15,
                },
                {
                    id = tostring(tes3.weather.foggy),
                    chance = 35,
                },
                {
                    id = tostring(tes3.weather.overcast),
                    chance = 25,
                },
                {
                    id = tostring(tes3.weather.rain),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.thunder),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.ash),
                    chance = 20,
                },
                {
                    id = tostring(tes3.weather.blight),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.snow),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blizzard),
                    chance = 0,
                },
            },
        },
        {
            id = "Sheogorad",
            weathers = {
                {
                    id = tostring(tes3.weather.clear),
                    chance = 15,
                },
                {
                    id = tostring(tes3.weather.cloudy),
                    chance = 40,
                },
                {
                    id = tostring(tes3.weather.foggy),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.overcast),
                    chance = 15,
                },
                {
                    id = tostring(tes3.weather.rain),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.thunder),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.ash),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blight),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.snow),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blizzard),
                    chance = 0,
                },
            },
        },
        {
            id = "Red Mountain Region",
            weathers = {
                {
                    id = tostring(tes3.weather.clear),
                    chance = 50,
                },
                {
                    id = tostring(tes3.weather.cloudy),
                    chance = 50,
                },
                {
                    id = tostring(tes3.weather.foggy),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.overcast),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.rain),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.thunder),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.ash),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blight),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.snow),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blizzard),
                    chance = 0,
                },
            },
        },
        {
            id = "Mournhold Region",
            weathers = {
                {
                    id = tostring(tes3.weather.clear),
                    chance = 25,
                },
                {
                    id = tostring(tes3.weather.cloudy),
                    chance = 35,
                },
                {
                    id = tostring(tes3.weather.foggy),
                    chance = 5,
                },
                {
                    id = tostring(tes3.weather.overcast),
                    chance = 20,
                },
                {
                    id = tostring(tes3.weather.rain),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.thunder),
                    chance = 5,
                },
                {
                    id = tostring(tes3.weather.ash),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blight),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.snow),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blizzard),
                    chance = 0,
                },
            },
        },
        {
            id = "Hirstaang Forest Region",
            weathers = {
                {
                    id = tostring(tes3.weather.clear),
                    chance = 20,
                },
                {
                    id = tostring(tes3.weather.cloudy),
                    chance = 40,
                },
                {
                    id = tostring(tes3.weather.foggy),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.overcast),
                    chance = 40,
                },
                {
                    id = tostring(tes3.weather.rain),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.thunder),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.ash),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blight),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.snow),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blizzard),
                    chance = 0,
                },
            },
        },
        {
            id = "Brodir Grove Region",
            weathers = {
                {
                    id = tostring(tes3.weather.clear),
                    chance = 20,
                },
                {
                    id = tostring(tes3.weather.cloudy),
                    chance = 25,
                },
                {
                    id = tostring(tes3.weather.foggy),
                    chance = 35,
                },
                {
                    id = tostring(tes3.weather.overcast),
                    chance = 20,
                },
                {
                    id = tostring(tes3.weather.rain),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.thunder),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.ash),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blight),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.snow),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blizzard),
                    chance = 0,
                },
            },
        },
        {
            id = "Isinfier Plains Region",
            weathers = {
                {
                    id = tostring(tes3.weather.clear),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.cloudy),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.foggy),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.overcast),
                    chance = 30,
                },
                {
                    id = tostring(tes3.weather.rain),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.thunder),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.ash),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blight),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.snow),
                    chance = 30,
                },
                {
                    id = tostring(tes3.weather.blizzard),
                    chance = 20,
                },
            },
        },
        {
            id = "Felsaad Coast Region",
            weathers = {
                {
                    id = tostring(tes3.weather.clear),
                    chance = 30,
                },
                {
                    id = tostring(tes3.weather.cloudy),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.foggy),
                    chance = 15,
                },
                {
                    id = tostring(tes3.weather.overcast),
                    chance = 15,
                },
                {
                    id = tostring(tes3.weather.rain),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.thunder),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.ash),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blight),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.snow),
                    chance = 20,
                },
                {
                    id = tostring(tes3.weather.blizzard),
                    chance = 10,
                },
            },
        },
        {
            id = "Thirsk Region",
            weathers = {
                {
                    id = tostring(tes3.weather.clear),
                    chance = 20,
                },
                {
                    id = tostring(tes3.weather.cloudy),
                    chance = 25,
                },
                {
                    id = tostring(tes3.weather.foggy),
                    chance = 35,
                },
                {
                    id = tostring(tes3.weather.overcast),
                    chance = 20,
                },
                {
                    id = tostring(tes3.weather.rain),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.thunder),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.ash),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blight),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.snow),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blizzard),
                    chance = 0,
                },
            },
        },
        {
            id = "Moesring Mountains Region",
            weathers = {
                {
                    id = tostring(tes3.weather.clear),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.cloudy),
                    chance = 10,
                },
                {
                    id = tostring(tes3.weather.foggy),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.overcast),
                    chance = 20,
                },
                {
                    id = tostring(tes3.weather.rain),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.thunder),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.ash),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blight),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.snow),
                    chance = 20,
                },
                {
                    id = tostring(tes3.weather.blizzard),
                    chance = 40,
                },
            },
        },
        {
            id = "Firemoth Region",
            weathers = {
                {
                    id = tostring(tes3.weather.clear),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.cloudy),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.foggy),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.overcast),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.rain),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.thunder),
                    chance = 100,
                },
                {
                    id = tostring(tes3.weather.ash),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blight),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.snow),
                    chance = 0,
                },
                {
                    id = tostring(tes3.weather.blizzard),
                    chance = 0,
                },
            },
        },
    },
}