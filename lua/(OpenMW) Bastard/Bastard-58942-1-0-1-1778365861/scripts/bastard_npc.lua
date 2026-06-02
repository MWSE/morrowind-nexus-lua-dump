local self  = require('openmw.self')
local types = require('openmw.types')
local core  = require('openmw.core')
local async = require('openmw.async')
local anim  = require('openmw.animation')
local I     = require('openmw.interfaces')
local AI    = I.AI

local shared = require('scripts.bastard_shared')

local GIVE_IN_ANIM           = 'give02'
local GIVE_IN_ANIM_DURATION  = 2.0

-- ======================================================================================================
-- detd compatibility

local function detdIgnore(value)
    self.object:sendEvent('detd_SetIgnoreWeaponReaction', value and true or false)
end

-- ======================================================================================================
-- Give-in: hands-up animation, AI off during anim, AI back on when done

local function Bastard_PlayGiveIn(data)
    if types.Actor.isDead(self) then return end
    -- ensure not stuck in weapon stance
    self.type.setStance(self, 0)
    -- detd: keep weapon-react logic out of our way during the anim
    detdIgnore(true)

    self:enableAI(false)
    I.AnimationController.playBlendedAnimation(GIVE_IN_ANIM, {
        startKey = 'start',
        stopKey  = 'stop',
        priority = anim.PRIORITY.Scripted,
        speed    = 1,
    })

    async:newUnsavableSimulationTimer(GIVE_IN_ANIM_DURATION, function()
        if self:isActive() and not types.Actor.isDead(self) then
            self:enableAI(true)
            -- pacified victim
        end
        core.sendGlobalEvent('Bastard_RequestRemoval', self.object)
    end)
end

-- ======================================================================================================
-- fight: open combat against the player

local function Bastard_StartFight(data)
    if types.Actor.isDead(self) then return end
    local player = data.player
    if not player or not player:isValid() then return end

    -- Make sure AI is on, draw weapon, then queue Combat
    self:enableAI(true)
    self.type.setStance(self, 1)
    detdIgnore(false)

    AI.startPackage({ type = 'Combat', target = player })

    core.sendGlobalEvent('Bastard_RequestRemoval', self.object)
end

-- ======================================================================================================
-- Pursue for guards so they can arrest player

local function Bastard_StartPursue(data)
    if types.Actor.isDead(self) then return end
    local player = data.player
    if not player or not player:isValid() then return end

    self:enableAI(true)
    self.type.setStance(self, 1)
    detdIgnore(false)

    AI.startPackage({ type = 'Pursue', target = player })

    core.sendGlobalEvent('Bastard_RequestRemoval', self.object)
end

-- ======================================================================================================
-- clean it up

local function onInactive()
    if not types.Actor.isDead(self) then
        self:enableAI(true)
    end
    detdIgnore(false)
    core.sendGlobalEvent('Bastard_RequestRemoval', self.object)
end

return {
    engineHandlers = {
        onInactive = onInactive,
    },
    eventHandlers = {
        Bastard_PlayGiveIn = Bastard_PlayGiveIn,
        Bastard_StartFight = Bastard_StartFight,
        Bastard_StartPursue = Bastard_StartPursue,
    },
}