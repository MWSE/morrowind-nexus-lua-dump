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
local isFollowing = false
local calmTimer = nil

local function startWander()
    AI.startPackage({
        type = 'Wander',
        distance = 5000,
        duration = 6 * time.hour,
        idle = idleTable,
        isRepeat = true
    })
end

local function startCalmTimer()
    if calmTimer then calmTimer() end

    calmTimer = time.runRepeatedly(function()
        if not self:isValid() then return end
        
        if types.Actor.stats.ai.fight(self).base > 0 
           or not types.Actor.activeSpells(self):isSpellActive('calm creature') then
            
            types.Actor.activeSpells(self):add({
                id = 'calm creature',
                effects = { 0 },
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
            startWander()
        end
    end, 0.5 * time.second)

    calmUntil = core.getSimulationTime() + 7 * 3600

    time.newGameTimer(7 * time.hour, time.registerTimerCallback("drnrStopCalm" .. self.id, function()
        if calmTimer then calmTimer() end
        calmTimer = nil
        calmUntil = nil
        isFollowing = false
    end))

    if isFollowing then
        AI.startPackage({
            type = 'Follow',
            target = nearby.players[1],
            duration = 6 * time.hour,
            distance = 5000,
            isRepeat = false
        })

        local callback = time.registerTimerCallback("drnrUnFollow" .. self.id, function()
            AI.removePackages('Follow')
            startWander()
            isFollowing = false
        end)
        time.newGameTimer(6 * time.hour, callback)
    end
end


return {
    eventHandlers = {
        drnrCalm = function(data)

            isFollowing = math.random(1, 100) <= 5
            startCalmTimer()

            if not isFollowing then
                startWander()
            end
        end
    },
    engineHandlers = {
        onSave = function()
            return {
                calmUntil = calmUntil,
                isFollowing = isFollowing
            }
        end,
        onLoad = function(saved)
            if saved and saved.calmUntil then
                calmUntil = saved.calmUntil
                if core.getSimulationTime() < calmUntil then
                    isFollowing = saved.isFollowing
                    startCalmTimer()
                else
                    calmUntil = nil
                    isFollowing = false
                end
            end
        end
    }
}