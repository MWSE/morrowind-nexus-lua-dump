local self = require('openmw.self')
local types = require('openmw.types')
local AI = require('openmw.interfaces').AI
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')
local time = require('openmw_aux.time')

local savedPackage = nil
local aiWasRemoved = false
local updateInterval = 1

local dispositionModified = false
local DISPOSITION_PENALTY = -25

local playerWeaponDrawn = false

local VEC_FORWARD = util.vector3(0, 1, 0)

local HEAD_OFFSET = util.vector3(0, 0, 95)
local CHEST_OFFSET = util.vector3(0, 0, 60)

local trackTimer = nil

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

local function angleDifference(a, b)
    local diff = b - a
    return math.atan2(math.sin(diff), math.cos(diff))
end

local function stopTracking()
    if trackTimer then
        trackTimer()
        trackTimer = nil
    end
    self.controls.yawChange = 0
end

local function stopTrackingAndUnhook()
    stopTracking()
    core.sendGlobalEvent('detd_npc_sheatheweapon_Unhook', {object = self})
end

local function startTracking(player)
    if trackTimer then
        return
    end

    trackTimer = time.runRepeatedly(function()
        if not self:isValid() or types.Actor.isDead(self) then
            stopTrackingAndUnhook()
            return
        end

        if not player or not player:isValid() or types.Actor.isDead(player) then
            stopTrackingAndUnhook()
            return
        end

        if self.cell ~= player.cell then
            stopTracking()
            return
        end

        local toPlayer = player.position - self.position
        local distance = toPlayer:length()

        -- keep this reasonably close to your visibility/reaction radius
        if distance > 700 then
            stopTracking()
            return
        end

        if distance <= 1 then
            self.controls.yawChange = 0
            return
        end

        local targetYaw = math.atan2(toPlayer.x, toPlayer.y)
        local currentYaw = self.rotation:getYaw()

        self.controls.yawChange = angleDifference(currentYaw, targetYaw) / 6
    end, 0.03 * time.second)
end

local function detd_pcWeaponState(value)
    playerWeaponDrawn = (value == 1)
    --print(self.recordId, "| EVENT RECEIVED detd_pcWeaponState =", value, "| playerWeaponDrawn =", playerWeaponDrawn)
end

local function modifyDisposition(player, applyPenalty)
    if not player then return end
    if not types.NPC.objectIsInstance(self) then return end

    if applyPenalty then
        if not dispositionModified then
            types.NPC.modifyBaseDisposition(self, player, DISPOSITION_PENALTY)
            dispositionModified = true
        end
    else
        if dispositionModified then
            types.NPC.modifyBaseDisposition(self, player, -DISPOSITION_PENALTY)
            dispositionModified = false
        end
    end
end

local function restoreAI()
    if aiWasRemoved then
        if savedPackage and savedPackage.type ~= "Unknown" then
            pcall(function() AI.startPackage(savedPackage) end)
        end
        aiWasRemoved = false
        savedPackage = nil
    end
end

local function canSeePlayer(npc, player)
    local toPlayer = player.position - npc.position
    if toPlayer:length() > 600 then return false end

    local npcForward = npc.rotation:apply(VEC_FORWARD)
    local angle = npcForward:dot(toPlayer:normalize())
    if angle < math.cos(math.rad(100)) then return false end

    local fromPos = npc.position + HEAD_OFFSET
    local toPos = player.position + CHEST_OFFSET

    local result = nearby.castRay(fromPos, toPos, {
        collisionType = 3,
        ignore = {npc}
    })

    return not result.hit
end

local function updateLogic()
    if not self:isValid() or types.Actor.isDead(self) then
        stopTrackingAndUnhook()
        return
    end

    local player = nearby.players[1]

    if not player or types.Actor.isDead(player) or self.cell ~= player.cell then
        if not player or types.Actor.isDead(player) then
            stopTrackingAndUnhook()
        else
            stopTracking()
        end
        restoreAI()
        modifyDisposition(player, false)
        if self.type.getStance(self) ~= 0 then self.type.setStance(self, 0) end
        return
    end

    local inAnyCombat = false
    AI.forEachPackage(function(p)
        if p and p.type == "Combat" then inAnyCombat = true end
    end)

    if inAnyCombat then
        stopTracking()
        aiWasRemoved = false
        savedPackage = nil
        return
    end

    local eff = types.Actor.activeEffects(player)
    local invis = eff and eff:getEffect("invisibility")
    local cham = eff and eff:getEffect("chameleon")
    if (invis and invis.magnitude and invis.magnitude > 0) or (cham and cham.magnitude and cham.magnitude >= 85) then
        stopTracking()
        if self.type.getStance(self) ~= 0 then self.type.setStance(self, 0) end
        restoreAI()
        modifyDisposition(player, false)
        return
    end

    local shouldReact = canSeePlayer(self, player)
    if shouldReact then
        AI.forEachPackage(function(p)
            if p and p.type == "Follow" and p.target == player then shouldReact = false end
        end)
    end

    local carriedRight = types.Actor.getEquipment(player, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if carriedRight then
        if carriedRight.type == types.Lockpick or carriedRight.type == types.Probe then
            shouldReact = false
        end
    end

    --print(self.recordId, "| playerWeaponDrawn =", playerWeaponDrawn, "| shouldReact =", shouldReact)

 local disp = types.NPC.getDisposition(self, player) 


    if playerWeaponDrawn and shouldReact and disp < 90 then
        if not aiWasRemoved then
            local currentPkg = AI.getActivePackage(self)
            if currentPkg and currentPkg.type ~= "Unknown" then
                savedPackage = currentPkg
            end
            aiWasRemoved = true
            AI.removePackages("Wander")
        end

        startTracking(player)

        if self.type.getStance(self) ~= 1 then
            self.type.setStance(self, 1)
        end
        modifyDisposition(player, true)
    else
        stopTracking()

        if aiWasRemoved then
            restoreAI()
            if self.type.getStance(self) ~= 0 then self.type.setStance(self, 0) end
        end
        modifyDisposition(player, false)
    end
end

local function onInactive()
    stopTrackingAndUnhook()
    if self:isValid() and not types.Actor.isDead(self) then
        restoreAI()
    end
    local player = nearby.players[1]
    if player then
        modifyDisposition(player, false)
    end
end

time.runRepeatedly(updateLogic, updateInterval * time.second, {
    initialDelay = math.random() * updateInterval * time.second
})

return {
    eventHandlers = { detd_pcWeaponState = detd_pcWeaponState },
    engineHandlers = { onInactive = onInactive }
}