local config = require("DynamicMusicPause.config")
local unpauseTimer = nil

local function registerModConfig()
    require("DynamicMusicPause.mcm")
end
event.register("modConfigReady", registerModConfig)

local function dbg(msg, ...)
    local out = string.format("[DMP DEBUG] " .. msg, ...)
    mwse.log(out)
    tes3ui.logToConsole(out)
end

local function getRandomPause()
    local min = config.minPause or 0
    local max = config.maxPause or min
    if max < min then
        max = min
    end
    return math.random(min, max)
end

local function waitForMusicAndPause(delay)
    local audio = tes3.worldController.audioController

    if not audio.isMusicPlaying then
        timer.start{
            duration = 0.1,
            type = timer.real,
            callback = function()
                waitForMusicAndPause(delay)
            end
        }
        return
    end

    audio:pauseMusic()
    if unpauseTimer ~= nil and unpauseTimer.state == timer.active then
        unpauseTimer:cancel()
    end

    unpauseTimer = timer.start{
        duration = delay,
        type = timer.real,
        callback = function()
            dbg("Unpausing music now.")
            audio:unpauseMusic()
        end
    }
end

event.register("musicChangeTrack", function(e)

    if e.context == 'combat' then
        return
    end

    if tes3.onMainMenu() then
        return
    end

    local roll = math.random(100)
    if roll > config.pauseChance then
        return
    end

    local delay = getRandomPause()
    waitForMusicAndPause(delay)
end)

