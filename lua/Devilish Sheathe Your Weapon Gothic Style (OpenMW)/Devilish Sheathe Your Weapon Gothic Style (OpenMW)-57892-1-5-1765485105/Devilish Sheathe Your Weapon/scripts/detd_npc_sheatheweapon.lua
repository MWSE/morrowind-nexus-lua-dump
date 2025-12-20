local self = require('openmw.self')
local types = require('openmw.types')
local time = require('openmw_aux.time')
local AI = require('openmw.interfaces').AI
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')
local stopTimer
------------------------------------------------------------
-- MAGIC VISIBILITY CHECK (Invisibility + Chameleon)
------------------------------------------------------------

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

local function playerIsMagicallyHidden(player)
    local eff = types.Actor.activeEffects(player)
    if not eff then return false end

    -- Invisibility
    local invis = eff:getEffect("invisibility")
    if invis and invis.magnitude and invis.magnitude > 0 then
        return true
    end

    -- Chameleon (full invisibility if >= 100)
    local cham = eff:getEffect("chameleon")
    if cham and cham.magnitude and cham.magnitude >= 70 then
        return true
    end

    return false
end


------------------------------------------------------------
-- LOS HELPERS
------------------------------------------------------------

local vEye   = util.vector3(0, 0, 90)
local vChest = util.vector3(0, 0, 60)

local function clearRay(from, to, ignoreActor)
    local result = nearby.castRay(from, to, {
        collisionType = 3,
        ignore = {ignoreActor, self}
    })
    return not result.hit
end

local function npcIsNearPlayer(npc, player)
    if not npc or not npc:isValid() then return false end
    if types.Actor.isDead(npc) then return false end
    if npc.cell ~= player.cell then return false end

    local toPlayer = player.position - npc.position
    local dist = toPlayer:length()
    if dist > 300 then return false end

    -- Vision cone
    local npcForward = npc.rotation:apply(util.vector3(0, 1, 0))
    local angle = npcForward:dot(toPlayer:normalize())
    if angle < math.cos(math.rad(60)) then
        return false
    end

    -- Raycast
    local npcEye = npc.position + vEye
    local playerChest = player.position + vChest

    return clearRay(npcEye, playerChest, npc)
end


------------------------------------------------------------
-- MAIN LOGIC
------------------------------------------------------------

local savedPackage = nil
local aiWasRemoved = false

stopTimer = time.runRepeatedly(function()

    local player = nearby.players[1]
    if not player then return end

    local playerWeaponDrawn = player.type.getStance(player, 1) == 1

    --  NEW: magical invisibility/chameleon
    local magicallyHidden = playerIsMagicallyHidden(player)
    if magicallyHidden then
        -- If hidden, NPC ALWAYS lowers weapon + restores AI
        self.type.setStance(self, 0)
        if aiWasRemoved then
            aiWasRemoved = false
            if savedPackage then AI.startPackage(savedPackage) end
            savedPackage = nil
        end
        return
    end
	
	local shouldBeEnabled = npcIsNearPlayer(self, player)
	
	if shouldBeEnabled then
		local isCompanion
		AI.forEachPackage(function(p)
			if p and p.type == "Follow" and p.target == player then
				isCompanion = true
			end
		end)
		shouldBeEnabled = shouldBeEnabled and not isCompanion
	end
	
	if shouldBeEnabled then
		shouldBeEnabled = shouldBeEnabled 
	end

    if playerWeaponDrawn and shouldBeEnabled then
        
        if not aiWasRemoved then
            savedPackage = AI.getActivePackage(self)
            aiWasRemoved = true
            AI.removePackages("Wander")
        end

        if self.type.getStance(self) ~= 1 then
            self.type.setStance(self, 1)
        end

    else
        -- Restore normal behavior
        if aiWasRemoved then
            aiWasRemoved = false
            if savedPackage then AI.startPackage(savedPackage) end
            savedPackage = nil
            self.type.setStance(self, 0)
        end
    end

end, 0.5 * time.second, { initialDelay = math.random() * time.second })


------------------------------------------------------------
-- INACTIVE HANDLER
------------------------------------------------------------

local function onInactive()
	if savedPackage then AI.startPackage(savedPackage) end
	stopTimer()
    core.sendGlobalEvent('detd_npc_sheatheweapon_Unhook', { object = self })
end

return {
    engineHandlers = {
        onInactive = onInactive,
    },
}
