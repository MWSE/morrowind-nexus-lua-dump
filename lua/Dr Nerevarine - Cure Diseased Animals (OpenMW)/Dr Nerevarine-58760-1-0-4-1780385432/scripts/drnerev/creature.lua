local types = require("openmw.types")
local core = require("openmw.core")
local nearby = require('openmw.nearby')
local self = require("openmw.self")
local AI = require('openmw.interfaces').AI
local time = require('openmw_aux.time')

local idleTable = {
    idle2 = 60,
    idle3 = 50,
    idle4 = 40,
    idle5 = 30,
    idle6 = 20,
    idle7 = 10,
    idle8 = 0,
    idle9 = 25
}

local calmUntil = nil
local followUntil = nil

local stopCalm = nil


local function calcRestTime()
    local timeToCalm = 0
    local timeToFollow = 0

    if calmUntil then
        timeToCalm = calmUntil - core.getGameTime()
        if timeToCalm < 0 then
            timeToCalm = 0
            calmUntil = nil
        end
    end

    if followUntil then
        timeToFollow = followUntil - core.getGameTime()
        if timeToFollow < 0 then
            timeToFollow = 0
            followUntil = nil
        end
    end

    return timeToCalm, timeToFollow
end

local function startWander(timeToCalm)
    AI.startPackage({
        type = 'Wander',
        distance = 5000,
        duration = timeToCalm,
        idle = idleTable,
        isRepeat = true
    })
end


local function startCalm(timeToCalm)
    print("startCalm", self.recordId)
    if stopCalm then
        stopCalm()
    end

    stopCalm = time.runRepeatedly(function()
        if not self:isValid() then
            return
        end

        if not types.Actor.activeSpells(self):isSpellActive('calm creature') then
            types.Actor.activeSpells(self):add({
                id = 'calm creature',
                effects = {0},
                stackable = false,
                quiet = true
            })
        end

        if types.Actor.stats.ai.fight(self).base > 0 then
            types.Actor.stats.ai.fight(self).base = 0
        end

        local currentPackage = AI.getActivePackage()
        if currentPackage and currentPackage.type == 'Combat' then
            AI.removePackages('Combat')

            if not followUntil then
                startWander(timeToCalm)
            end
        end
    end, 0.5 * time.second)

    time.newGameTimer(timeToCalm, time.registerTimerCallback("drnrStopCalm" .. self.id, function()
        if stopCalm then
            stopCalm()
            stopCalm = nil
            calmUntil = nil
        end
    end))

end

local function startFollow(timeToFollow)
    print("startFollow", self.recordId)
    AI.startPackage({
        type = 'Follow',
        target = nearby.players[1],
        duration = timeToFollow,
        distance = 5000,
        isRepeat = false
    })

    local callback = time.registerTimerCallback("drnrUnFollow" .. self.id, function()
        print("stopFollow", self.recordId)
        AI.removePackages('Follow')
        followUntil = nil
        local timeToCalm, _ = calcRestTime()
        startCalm(timeToCalm)
    end)
    time.newGameTimer(timeToFollow, callback)
end

local function startAI()
    local timeToCalm, timeToFollow = calcRestTime()

    if timeToFollow > 0 then
        startFollow(timeToFollow)
    end
    if timeToCalm > 0 then
        startCalm(timeToCalm, timeToFollow)
    end
end

return {
    eventHandlers = {
        drnrCalm = function(data)
            local simTime = core.getGameTime()
            calmUntil = simTime + 72 * 3600 -- 72 часов спокойствия

            -- 5% шанс на добавление Follow
            if math.random(1, 100) <= 5 then
                followUntil = simTime + 5 * 3600 -- 5 часов следования
            else 
                followUntil = nil
            end

            startAI()
        end
    },

    engineHandlers = {
        onSave = function()
            return {
                calmUntil = calmUntil,
                followUntil = followUntil
            }
        end,
        onLoad = function(data)
            if data then
                calmUntil = data.calmUntil
                followUntil = data.followUntil
            end

            startAI()
        end
    }
}
