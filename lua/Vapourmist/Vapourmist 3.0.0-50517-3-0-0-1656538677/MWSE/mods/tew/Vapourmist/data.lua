local this = {}

local config = require("tew.Vapourmist.config")

this.baseTimerDuration = 0.4
this.lerpTime = 0.012
this.speedCoefficient = 25
this.minimumSpeed = 20
this.minStaticCount = 5

local interiorStatics = {
    "in_moldcave",
    "in_mudcave",
    "in_lavacave",
    "in_pycave",
    "in_bonecave",
    "in_bc_cave",
    "in_m_sewer",
    "in_sewer",
    "ab_in_kwama",
    "ab_in_lava",
    "ab_in_mvcave",
    "t_cyr_cavegc",
    "t_glb_cave",
    "t_mw_cave",
    "t_sky_cave",
    "bm_ic_",
    "bm_ka",
}

local interiorNames = {
    "cave",
    "cavern",
    "tomb",
    "burial",
    "crypt",
    "catacomb",
}


this.fogTypes = {
    ["cloud"] = {
        name = "cloud",
        mesh = "tew\\Vapourmist\\vapourcloud.nif",
        height = 4500,
        initialSize = {420, 450, 500, 510, 550, 600, 640},
        isAvailable = function(_, weather)

            if math.random(1, 100) <= config.randomCloudChance then
                return false
            end

            if config.cloudyWeathers[weather.name] and config.cloudyWeathers[weather.name] ~= nil then
                return true
            end

            if math.random(1, 100) <= config.randomCloudChance then
                return true
            end

            return false
        end,
        colours = {
            ["dawn"] = {
                r = 0.02,
                g = 0.01,
                b = 0.01
            },
            ["day"] = {
                r = 0.01,
                g = 0.01,
                b = 0.011,
            },
            ["dusk"] = {
                r = 0.02,
                g = 0.01,
                b = 0.012
            },
            ["night"] = {
                r = 0.035,
                g = 0.035,
                b = 0.042
            },
        }
    },
    ["mist"] = {
        name = "mist",
        mesh = "tew\\Vapourmist\\vapourmist.nif",
        height = 550,
        initialSize = {200, 250, 260, 300, 325, 350, 400, 450, 500},
        isAvailable = function(gameHour, weather)

            local WtC = tes3.worldController.weatherController
            if (
                (
                (gameHour > WtC.sunriseHour - 1 and gameHour < WtC.sunriseHour + 1.5)
                or (gameHour >= WtC.sunsetHour - 0.4 and gameHour < WtC.sunsetHour + 2))
                and not (this.fogTypes["mist"].wetWeathers[weather.name] or weather.name == "Ash" or weather.name == "Blight" or weather.name == "Snow" or weather.name == "Blizzard")
                ) then
                return true
            end

            if math.random(1, 100) <= config.randomCloudChance then
                return false
            end

            if config.mistyWeathers[weather.name] and config.mistyWeathers[weather.name] ~= nil then
                return true
            end

            if math.random(1, 100) <= config.randomMistChance then
                return true
            end

            return false
        end,
        wetWeathers = {["Rain"] = true, ["Thunderstorm"] = true},
        colours = {
            ["dawn"] = {
                r = 0.07,
                g = 0.05,
                b = 0.05
            },
            ["day"] = {
                r = 0.02,
                g = 0.02,
                b = 0.02
            },
            ["dusk"] = {
                r = 0.07,
                g = 0.05,
                b = 0.05
            },
            ["night"] = {
                r = 0.02,
                g = 0.02,
                b = 0.024
            },
        }
    },
}

this.interiorFog = {
    name = "interior",
    mesh = "tew\\Vapourmist\\vapourint.nif",
    height = -1300,
    initialSize = {100, 150, 200, 300, 360},
    isAvailable = function(cell)

        for _, namePattern in ipairs(interiorNames) do
            if string.find(cell.name:lower(), namePattern) then
                return true
            end
        end

        local count = 0
        for stat in cell:iterateReferences(tes3.objectType.static) do
            for _, statName in ipairs(interiorStatics) do
                if string.startswith(stat.object.id:lower(), statName) then
                    count = count + 1
                    if count >= this.minStaticCount then
                        return true
                    end
                end
            end
        end

        if count == 0 then return false end

    return false
    end,
    colours = {
        r = -0.3,
        g = -0.3,
        b = -0.3
    },
}


return this