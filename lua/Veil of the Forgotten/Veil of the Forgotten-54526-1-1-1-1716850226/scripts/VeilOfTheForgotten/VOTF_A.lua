local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")
local types = require("openmw.types")
local async = require("openmw.async")
local nearby = require("openmw.nearby")
if core.API_REVISION < 59 then
    return {}
end
local guideState = nil
local isPendingCapture = false
local expireDt = 0
local isPawn = false
local frozen = false
local myOrb
local anim = require('openmw.animation')
local function isCaptured()
    return types.Actor.activeSpells(self):isSpellActive("zhac_soulcapture_shock")
end
local function onRelease()
    types.Actor.stats.ai.fight(self).base = 0
    types.Actor.stats.ai.hello(self).base = 0
    types.Actor.stats.ai.alarm(self).base = 0
    I.AI.removePackages()
    types.Actor.setStance(self, types.Actor.STANCE.Nothing)
    async:newUnsavableSimulationTimer(3, function()
        types.Actor.stats.ai.fight(self).base = 0
        types.Actor.stats.ai.hello(self).base = 0
        types.Actor.stats.ai.alarm(self).base = 0
        I.AI.removePackages()
        types.Actor.setStance(self, types.Actor.STANCE.Nothing)
        I.AI.startPackage({ type = "Follow", target = nearby.players[1] })
    end)
end
local function makeIntoDoll(id)
    myOrb = id
    self:enableAI(false)
    onRelease()
    frozen = true
end
local function checkForCapture()
    isPendingCapture = true
    expireDt = core.getSimulationTime() + 10
end
local function onUpdate(dt)
    if isPendingCapture then
        if core.getSimulationTime() < expireDt then
            if isCaptured() then
                core.sendGlobalEvent("captureComplete", self)
                isPendingCapture = false
                isPawn = true
            end
        else
            isPendingCapture = false
        end
    end
    if frozen then
        anim.skipAnimationThisFrame(self)
        if myOrb then
            local orb
            for index, value in ipairs(nearby.items) do
                if value.recordId == myOrb then
                    orb = value
                    break
                end
            end
            if not orb then
                self:enableAI(true)
                core.sendGlobalEvent("putBackInCell", self)
                frozen = false
            end
        end
    end
end
return {
    eventHandlers = {
        checkForCapture = checkForCapture,
        onRelease = onRelease,
        makeIntoDoll = makeIntoDoll,
    },
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = function()
            return {
                isPawn = isPawn,
                frozen = frozen,
                myOrb = myOrb,
            }
        end,
        onLoad = function(data)
            if data then
                isPawn = data.isPawn
                frozen = data.frozen
                myOrb = data.myOrb
            end
            if frozen then
                self:enableAI(false)
                core.sendGlobalEvent("fixScale", { actor = self, scale = 0.1 })
            end
        end
    }
}
