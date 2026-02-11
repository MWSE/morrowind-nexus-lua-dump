local self = require('openmw.self')
local types = require('openmw.types')
local AI = require('openmw.interfaces').AI
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')
local time = require('openmw_aux.time')

local savedPackage = nil
local aiWasRemoved = false
local updateInterval = 1.5


local VEC_FORWARD = util.vector3(0, 1, 0)


local HEAD_OFFSET = util.vector3(0, 0, 95)
local CHEST_OFFSET = util.vector3(0, 0, 60)

local allowedAnims = {
    ["meshes/"] = true,
    ["meshes/base_anim.nif"] = true,
    ["meshes/base_anim_female.nif"] = true,
    ["meshes/base_animkna.nif"] = true,
    ["meshes/epos_kha_upr_anim_f.nif"] = true,
    ["meshes/epos_kha_upr_anim_m.nif"] = true,
    ["meshes/pi_tsa_base_anim.nif"] = true,
}

if not allowedAnims[self.type.records[self.recordId].model or ""] then
    return
end

------------------------------------------------------------
-- RESTORATION SYSTEM
------------------------------------------------------------
local function restoreAI()
    if aiWasRemoved then
        if savedPackage and savedPackage.type ~= "Unknown" then
            pcall(function() AI.startPackage(savedPackage) end)
        end
        aiWasRemoved = false
        savedPackage = nil
    end
end

------------------------------------------------------------
-- RAYCAST
------------------------------------------------------------
local function canSeePlayer(npc, player)
    -- 1. Distance
    local toPlayer = player.position - npc.position
    if toPlayer:length() > 600 then return false end

    -- 2. FOV
    local npcForward = npc.rotation:apply(VEC_FORWARD)
    local angle = npcForward:dot(toPlayer:normalize())
    if angle < math.cos(math.rad(100)) then return false end

    -- 3. Raycast
    local fromPos = npc.position + HEAD_OFFSET
    local toPos = player.position + CHEST_OFFSET
    
    local result = nearby.castRay(fromPos, toPos, {
        collisionType = 3,
        ignore = {npc}
    })
    
    return not result.hit
end

------------------------------------------------------------
-- MAIN LOGIC
------------------------------------------------------------
local function updateLogic()
    -- Death check
    if not self:isValid() or types.Actor.isDead(self) then 
        return 
    end

    local player = nearby.players[1]
    
    -- Player death check and cell
    if not player or types.Actor.isDead(player) or self.cell ~= player.cell then
        restoreAI()
        if self.type.getStance(self) ~= 0 then self.type.setStance(self, 0) end
        return
    end

    -- Combat state
    local inAnyCombat = false
    AI.forEachPackage(function(p)
        if p and p.type == "Combat" then inAnyCombat = true end
    end)
    
    if inAnyCombat then
        aiWasRemoved = false
        savedPackage = nil
        return
    end

    -- Magic
    local eff = types.Actor.activeEffects(player)
    local invis = eff and eff:getEffect("invisibility")
    local cham = eff and eff:getEffect("chameleon")
    if (invis and invis.magnitude and invis.magnitude > 0) or (cham and cham.magnitude and cham.magnitude >= 75) then
        if self.type.getStance(self) ~= 0 then self.type.setStance(self, 0) end
        restoreAI()
        return
    end

    -- Companions
    local shouldReact = canSeePlayer(self, player)
    if shouldReact then
        AI.forEachPackage(function(p)
            if p and p.type == "Follow" and p.target == player then shouldReact = false end
        end)
    end

    -- Weapon reaction
    local playerWeaponDrawn = player.type.getStance(player, 1) == 1
    
    if playerWeaponDrawn and shouldReact then
        if not aiWasRemoved then
            local currentPkg = AI.getActivePackage(self)
            if currentPkg and currentPkg.type ~= "Unknown" then
                savedPackage = currentPkg
            end
            aiWasRemoved = true
            AI.removePackages("Wander")
        end
        if self.type.getStance(self) ~= 1 then self.type.setStance(self, 1) end
    else
        if aiWasRemoved then
            restoreAI()
            if self.type.getStance(self) ~= 0 then self.type.setStance(self, 0) end
        end
    end
end

time.runRepeatedly(updateLogic, updateInterval * time.second, {
    initialDelay = math.random() * updateInterval * time.second
})

return {
    engineHandlers = {
        onInactive = function()
            restoreAI()
            if self:isValid() and not types.Actor.isDead(self) then 
                if self.type.getStance(self) ~= 0 then self.type.setStance(self, 0) end
            end
        end
    },
}