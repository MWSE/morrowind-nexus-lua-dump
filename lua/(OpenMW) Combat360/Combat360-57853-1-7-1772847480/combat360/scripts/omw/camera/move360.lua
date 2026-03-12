local core = require('openmw.core')
local camera = require('openmw.camera')
local input = require('openmw.input')
local self = require('openmw.self')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local types = require('openmw.types')

local Actor = require('openmw.types').Actor
local Player = require('openmw.types').Player
local async = require('openmw.async')
local nearby = require('openmw.nearby')
local storage = require('openmw.storage')
local v3 = util.vector3


local MODE = camera.MODE
local doInstantTransition = false
local active = false

local M = {
    enabled = false,
    turnSpeed = 5,
    alwaysAim = false,
}

-- ADDITIONAL SETTING
local move360CombatGroup = 'SettingsOMWCameraMove360Combat'
I.Settings.registerGroup({
    key = move360CombatGroup,
    page = 'OMWCamera',
    l10n = 'none',
    name = 'Move 360 Combat',
    permanentStorage = true,
    order = 2,
    settings = {
        {
            key = 'alwaysAim',
            renderer = 'checkbox',
            name = 'Melee aiming',
            description = 'Aim even with melee weapons, not just with ranged weapons or spells',
            default = false,
        },
    },
})
local move360Combat = storage.playerSection(move360CombatGroup)
M.alwaysAim = move360Combat:get('alwaysAim')
move360Combat:subscribe(async:callback(function()
    M.alwaysAim = move360Combat:get('alwaysAim')
end))
-- /SETTING

local function turnOn()
    I.Camera.disableStandingPreview()
    self.controls.pitchChange = camera.getPitch() - self.rotation:getPitch()
    active = true
	
	doInstantTransition = true
end

local function turnOff()
    I.Camera.enableStandingPreview()
    active = false
    -- snap character to camera
    self.controls.yawChange = camera.getYaw() - self.rotation:getYaw()
    self.controls.pitchChange = camera.getPitch() - self.rotation:getPitch()
    if camera.getMode() == MODE.Preview then
		changeModeNextFrame = MODE.ThirdPerson
    end
end

local function processZoom3rdPerson()
    if
        not Player.getControlSwitch(self, Player.CONTROL_SWITCH.ViewMode) or
        not Player.getControlSwitch(self, Player.CONTROL_SWITCH.Controls) or
        input.getBooleanActionValue('TogglePOV') or
        not I.Camera.isModeControlEnabled() or
        not I.Camera.isZoomEnabled()
    then
        return
    end
    local Zoom3rdPerson = input.getNumberActionValue('Zoom3rdPerson')
    if Zoom3rdPerson > 0 and camera.getMode() == MODE.Preview
        and I.Camera.getBaseThirdPersonDistance() == 30 then
        self.controls.yawChange = camera.getYaw() - self.rotation:getYaw()
        self.controls.pitchChange = camera.getPitch() - self.rotation:getPitch()
        camera.setMode(MODE.FirstPerson)
    elseif Zoom3rdPerson < 0 and camera.getMode() == MODE.FirstPerson then
        camera.setMode(MODE.Preview)
        I.Camera.setBaseThirdPersonDistance(30)
    end
end

local spellDB = {}
local function getSpellType(spell)
	if not spell then return 0 end
	local spellId = spell.id
	if spellDB[spellId] == nil then
		spellDB[spellId] = 0
		local s = spellDB[spellId]
		for _,effect in pairs(spell.effects) do
			if effect.range == core.magic.RANGE.Target then
				spellDB[spellId] = 3
			elseif effect.range == core.magic.RANGE.Touch then
				spellDB[spellId] = math.max(spellDB[spellId], 2)
			elseif effect.range == core.magic.RANGE.Self then
				spellDB[spellId] = math.max(spellDB[spellId], 1)
			end
		end
	end
	return spellDB[spellId]
end

local isUsing

-- this was for touch type spells (when using quick spell cast)
--I.AnimationController.addTextKeyHandler('spellcast', function(groupName, key)
--	if key:find("start") then
--		if camera.getMode() == MODE.Preview and getSpellType(Player.getSelectedSpell(self)) == 2 then
--            local playerBox = self:getBoundingBox()
--			local playerPos = self.position
--            playerPos = v3(playerPos.x, playerPos.y, playerBox.center.z+playerBox.halfSize.z*0.75)
--		    local playerZ = playerPos.z
--            local playerRotation = self.rotation
--            
--            local lookDirection = playerRotation * util.vector3(0, 1, 0)
--            lookDirection = v3(lookDirection.x,lookDirection.y,0)
--            local MAX_ANGLE = math.rad(75)
--            local MAX_DISTANCE = 200
--            local minCosAngle = math.cos(MAX_ANGLE)
--            
--            local bestScore = -999999
--            local bestTarget = nil
--            local bestPos = nil
--		    
--            for _, actor in pairs(nearby.actors) do
--                if actor ~= self.object then
--		    		local actorBounds = actor:getBoundingBox()
--		    		local actorPos = actorBounds.center
--					
--		    		if actorPos.x~=0 and not types.Actor.isDead(actor) then
--						local actorPos2 = actor.position
--						actorPos = v3(actorPos2.x,actorPos2.y,actorPos.z)
--		    			--print(actorPos)
--		    			-- fix collision boxes being detached from actual position
--		    			local halfHeight = actorBounds.halfSize.z
--		    			local actorZ = actorPos.z
--		    			if actorZ-10 > playerZ then
--		    				if actorZ-halfHeight*0.7 > playerZ then
--		    					actorPos = actorPos - v3(0,0,halfHeight*0.8)
--		    				else
--		    					actorPos = actorPos - v3(0,0,halfHeight*0.4)
--		    				end
--		    			elseif actorZ+10 < playerZ then
--		    				if actorZ+halfHeight*0.7 < playerZ then
--		    					actorPos = actorPos + v3(0,0,halfHeight*0.8)
--		    				else
--		    					actorPos = actorPos + v3(0,0,halfHeight*0.4)
--		    				end
--		    			end
--		    			
--		    			
--		    			local toActor = actorPos - playerPos
--		    			local distance = toActor:length()
--		    			
--		    			if distance < MAX_DISTANCE and distance > 0 then
--		    				local dirToActor, _ = toActor:normalize()
--		    				local dot = lookDirection:dot(dirToActor)
--		    				
--		    				if dot > minCosAngle then
--		    					local angleScore = dot
--		    					local distanceScore = 1 - (distance / MAX_DISTANCE)
--		    					local score = angleScore * 0.55 + distanceScore * 0.45
--		    					--print(distance)
--		    					if score > bestScore then
--		    						bestScore = score
--		    						bestTarget = actor
--		    						bestPos= actorPos
--		    					end
--		    				end
--		    			end
--		    		end
--                end
--            end
--            
--            if bestTarget then
--                
--                -- Snap to face target immediately
--                local toTarget = bestPos - playerPos
--                local horizontalDist = util.vector2(toTarget.x, toTarget.y):length()
--                
--                local targetYaw = math.atan2(toTarget.x, toTarget.y)
--                local currentYaw = self.rotation:getYaw()
--                self.controls.yawChange = util.normalizeAngle(targetYaw - currentYaw)
--                
--                local targetPitch = -math.atan2(toTarget.z, horizontalDist)
--                local currentPitch = self.rotation:getPitch()
--		    	--print(playerPos,bestPos)
--		    	--print(currentPitch, targetPitch)
--                self.controls.pitchChange = targetPitch - currentPitch
--                --print("Locked target: " .. bestTarget.id, self.controls.pitchChange)
--		    	skipOnFrame = true
--		    	
--            end
--		end
--	end
--end)

-- idk why this doesnt overwrite the over the shoulder tweak.. but whatever
input.bindAction('Use', async:callback(function(dt, use, sneak, run)
	local flipFlop = false
    if use and not isUsing then
        isUsing = true
		flipFlop = true
	elseif not use and isUsing then
        isUsing = false
		flipFlop = true
	end
	if flipFlop and camera.getMode() == MODE.Preview and not I.UI.getMode() and Actor.getStance(self) ~= Actor.STANCE.Nothing then
	
        local playerBox = self:getBoundingBox()
		local playerPos = self.position
        playerPos = v3(playerPos.x, playerPos.y, playerBox.center.z+playerBox.halfSize.z*0.75)
	    local playerZ = playerPos.z
        local playerRotation = self.rotation
        
        local lookDirection = playerRotation * util.vector3(0, 1, 0)
        lookDirection = v3(lookDirection.x,lookDirection.y,0)
        local MAX_ANGLE = math.rad(75)
        local MAX_DISTANCE = 200
        local minCosAngle = math.cos(MAX_ANGLE)
        
        local bestScore = -999999
        local bestTarget = nil
        local bestPos = nil
	    
        for _, actor in pairs(nearby.actors) do
            if actor ~= self.object then
	    		local actorBounds = actor:getBoundingBox()
	    		local actorPos = actorBounds.center
				
	    		if actorPos.x~=0 and not types.Actor.isDead(actor) then
					local actorPos2 = actor.position
					actorPos = v3(actorPos2.x,actorPos2.y,actorPos.z)
	    			--print(actorPos)
	    			-- fix collision boxes being detached from actual position
	    			local halfHeight = actorBounds.halfSize.z
	    			local actorZ = actorPos.z
	    			if actorZ-10 > playerZ then
	    				if actorZ-halfHeight*0.7 > playerZ then
	    					actorPos = actorPos - v3(0,0,halfHeight*0.8)
	    				else
	    					actorPos = actorPos - v3(0,0,halfHeight*0.4)
	    				end
	    			elseif actorZ+10 < playerZ then
	    				if actorZ+halfHeight*0.7 < playerZ then
	    					actorPos = actorPos + v3(0,0,halfHeight*0.8)
	    				else
	    					actorPos = actorPos + v3(0,0,halfHeight*0.4)
	    				end
	    			end
	    			
	    			
	    			local toActor = actorPos - playerPos
	    			local distance = toActor:length()
	    			
	    			if distance < MAX_DISTANCE and distance > 0 then
	    				local dirToActor, _ = toActor:normalize()
	    				local dot = lookDirection:dot(dirToActor)
	    				
	    				if dot > minCosAngle then
	    					local angleScore = dot
	    					local distanceScore = 1 - (distance / MAX_DISTANCE)
	    					local score = angleScore * 0.55 + distanceScore * 0.45
	    					--print(distance)
	    					if score > bestScore then
	    						bestScore = score
	    						bestTarget = actor
	    						bestPos= actorPos
	    					end
	    				end
	    			end
	    		end
            end
        end
        
        if bestTarget then
            
            -- Snap to face target immediately
            local toTarget = bestPos - playerPos
            local horizontalDist = util.vector2(toTarget.x, toTarget.y):length()
            
            local targetYaw = math.atan2(toTarget.x, toTarget.y)
            local currentYaw = self.rotation:getYaw()
            self.controls.yawChange = util.normalizeAngle(targetYaw - currentYaw)
            
            local targetPitch = -math.atan2(toTarget.z, horizontalDist)
            local currentPitch = self.rotation:getPitch()
	    	--print(playerPos,bestPos)
	    	--print(currentPitch, targetPitch)
            self.controls.pitchChange = targetPitch - currentPitch
            --print("Locked target: " .. bestTarget.id, targetPitch)
	    	skipOnFrame = true
	    	
        end
	end
    return use
end), {})
--]]

-- Helper: Check if we should defer to vanilla aiming controls
local function shouldUseVanillaAiming()
    if Actor.getStance(self) == Actor.STANCE.Weapon then
        local equippedWeapon = Actor.getEquipment(self)[Actor.EQUIPMENT_SLOT.CarriedRight]
        if equippedWeapon then
            local weaponRecord = types.Weapon.record(equippedWeapon.recordId)
            if weaponRecord then
                local t = weaponRecord.type
                return t == types.Weapon.TYPE.MarksmanBow
                    or t == types.Weapon.TYPE.MarksmanCrossbow
                    or t == types.Weapon.TYPE.MarksmanThrown
            end
        end
    elseif Actor.getStance(self) == Actor.STANCE.Spell then
        if getSpellType(Player.getSelectedSpell(self)) >= 2 then
            return true
        end
    end
    return false
end

function M.onFrame(dt)
    if skipOnFrame then
        skipOnFrame = false
        return
    end
    if changeModeNextFrame then
        camera.setMode(changeModeNextFrame)
        changeModeNextFrame = nil
        return
    end
    if core.isWorldPaused() then return end
    
    local useVanillaAiming = false
    if active and M.enabled and camera.getMode() ~= MODE.FirstPerson
        and Player.getControlSwitch(self, Player.CONTROL_SWITCH.Controls)
        and Player.getControlSwitch(self, Player.CONTROL_SWITCH.ViewMode) then
        if M.alwaysAim and (Actor.getStance(self) == Actor.STANCE.Weapon or Actor.getStance(self) == Actor.STANCE.Spell) then
            useVanillaAiming = true
        elseif Actor.getStance(self) == Actor.STANCE.Weapon then
            local equippedWeapon = Actor.getEquipment(self)[Actor.EQUIPMENT_SLOT.CarriedRight]
            if equippedWeapon then
                local weaponRecord = types.Weapon.record(equippedWeapon.recordId)
                if weaponRecord then
                    local t = weaponRecord.type
                    if t == types.Weapon.TYPE.MarksmanBow
                        or t == types.Weapon.TYPE.MarksmanCrossbow
                        or t == types.Weapon.TYPE.MarksmanThrown
                    then
                        useVanillaAiming = true
                    end
                end
            end
        elseif Actor.getStance(self) == Actor.STANCE.Spell then
            if getSpellType(Player.getSelectedSpell(self)) >= 2 then
                useVanillaAiming = true
            end
        end
    end
    
    if useVanillaAiming then
        self.controls.yawChange = camera.getYaw() - self.rotation:getYaw()
        self.controls.pitchChange = camera.getPitch() - self.rotation:getPitch()
        camera.showCrosshair(true)
    end
    if doInstantTransition then
		doInstantTransition = false
		camera.instantTransition()
	end
	
    local newActive = M.enabled and camera.getMode() ~= MODE.FirstPerson
    if newActive and not active then
        turnOn()
    elseif not newActive and active then
        turnOff()
    end
    
    if not active then return end
    
    processZoom3rdPerson()
    
    if useVanillaAiming then
		--bugfix after guard dialogue
        if camera.getMode() == MODE.ThirdPerson then
            self.controls.pitchChange = camera.getPitch() - self.rotation:getPitch()
            camera.setMode(MODE.Preview)
        end
        return
    end
    
    if camera.getMode() == MODE.Static then return end
    if camera.getMode() == MODE.ThirdPerson then
        self.controls.pitchChange = camera.getPitch() - self.rotation:getPitch()
        camera.setMode(MODE.Preview)
    end
    
    if camera.getMode() == MODE.Preview and not input.getBooleanActionValue('TogglePOV') then
        camera.showCrosshair(camera.getFocalPreferredOffset():length() > 5)
        local move = util.vector2(self.controls.sideMovement, self.controls.movement)
        local yawDelta = camera.getYaw() - self.rotation:getYaw()
        move = move:rotate(-yawDelta)
        self.controls.sideMovement = move.x
        self.controls.movement = move.y
        self.controls.pitchChange = camera.getPitch() * math.cos(yawDelta) - self.rotation:getPitch()
        if move:length() > 0.05 then
            local speed = types.NPC.stats.attributes.speed(self).modified
            if self.controls.sneak then
                speed = speed / 2.5
            end
            speed = 1 + speed / 200
            local delta = math.atan2(move.x, move.y)
            local maxDelta = math.max(delta, 1) * M.turnSpeed * speed * dt
            self.controls.yawChange = util.clamp(delta, -maxDelta, maxDelta)
        else
            self.controls.yawChange = 0
        end
    end
end

return M