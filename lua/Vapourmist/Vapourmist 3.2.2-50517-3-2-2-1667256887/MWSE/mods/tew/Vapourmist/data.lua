local this = {}

local config = require("tew.Vapourmist.config")

this.baseTimerDuration = 0.5
this.minimumSpeed = 15
this.minStaticCount = 5
this.fogDistance = 12500

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
        height = 5100,
        initialSize = { 650, 700, 780, 800, 900, 980, 1000, 1100 },
        isAvailable = function(_, weather)

            if config.blockedCloud[weather.name] and config.blockedCloud[weather.name] ~= nil then
                return false
            end

            if config.cloudyWeathers[weather.name] and config.cloudyWeathers[weather.name] ~= nil then
                return true
            end

            return false
        end
    },
    ["mist"] = {
        name = "mist",
        mesh = "tew\\Vapourmist\\vapourmist.nif",
        height = 550,
        initialSize = { 400, 420, 450, 500, 520, 550 },
        wetWeathers = { ["Rain"] = true, ["Thunderstorm"] = true },
        isAvailable = function(gameHour, weather)

            if config.blockedMist[weather.name] and config.blockedMist[weather.name] ~= nil then
                return false
            end

            local WtC = tes3.worldController.weatherController
            if (
                (
                    (gameHour > WtC.sunriseHour - 1 and gameHour < WtC.sunriseHour + 1.5)
                        or (gameHour >= WtC.sunsetHour - 0.4 and gameHour < WtC.sunsetHour + 2))
                    and not (this.fogTypes["mist"].wetWeathers[weather.name])
                ) then
                return true
            end

            if config.mistyWeathers[weather.name] and config.mistyWeathers[weather.name] ~= nil then
                return true
            end

            return false
        end
    },
}

this.interiorFog = {
    name = "interior",
    mesh = "tew\\Vapourmist\\vapourint.nif",
    height = -1300,
    initialSize = { 300, 400, 450, 500, 510, 550 },
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
    end
}


return this
