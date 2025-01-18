local core = require('openmw.core')
local nearby = require('openmw.nearby')
local input = require('openmw.input')
local self = require('openmw.self')
local animation = require('openmw.animation')
local async = require('openmw.async')
local types = require('openmw.types')
local util = require('openmw.util')
local camera = require("openmw.camera")
local ambient = require('openmw.ambient')


--[[
Known issues: None groundbreaking, but the vfx is slow to load onto the target sometimes. It is periodical and probably based upon enemy type, and the engine itself, 
but it's also possible that the nif file is still accounting for the part of the vfx I removed (the red electric pentagons) if so, we might be able to try and edit the 
nif file more but I am inexperienced with nif creation and editing

--]]


-- settings functions

local function boolSetting(sKey, sDef)
  return {
    key = sKey,
    renderer = 'checkbox',
    name = sKey .. '_name',
    description = sKey .. '_desc',
    default = sDef,
  }
end

local function numbSetting(sKey, sDef, sInt, sMin, sMax, sDis)
  return {
    key = sKey,
    renderer = 'number',
    name = sKey .. '_name',
    description = sKey .. '_desc',
    default = sDef,
    argument = {
      integer = sInt,
      min = sMin,
      max = sMax,
	  disabled = sDis
    },
  }
end



--settings
local storage = require('openmw.storage')
local interface = require('openmw.interfaces')
interface.Settings.registerPage({
  key = 'SlayAssassinMark',
  l10n = 'SlayAssassinMark',
  name = 'name',
  description = 'description',
})

-- default values
--I would like these default values to be 0.0 for those that are not shortsword or h2h, but the text box for settings doesn't accept decimals if there isn't one already there by default
--this also means if someone trys to set it below 0 that they'd have to reset all the stats to get a decimal back, not sure if its an openmw thing or something i'm doing wrong
local baseMultShort = 0.25
local baseMultHand = 0.15
local baseMultLongOne = 0.1
local baseMultLongTwo = 0.1
local baseMultSpear = 0.1
local baseMultBluntOne = 0.1
local baseMultBluntTwoClose = 0.1
local baseMultBluntTwoWide = 0.1
local baseMultAxeOne = 0.1
local baseMultAxeTwo = 0.1
local baseMultOther = 0.1
local allowAllWeapons = false
local sneakSkillCapBool = true
local sneakSkillCapVal = 100
local enabledStrengthBuff = true
local enableStrengthBuffOtherWeapons = false
local strengthBuffCapBool = true
local strengthBuffCapVal = 150
local strengthBuffPerLevelVal = 5


interface.Settings.registerGroup({
  key = 'Settings_SlayAssassinMark',
  page = 'SlayAssassinMark',
  l10n = 'SlayAssassinMark',
  name = 'group_name',
  permanentStorage = false,
  settings = {
	numbSetting('baseMultShort', baseMultShort, false, 0.0, 0.5, false),
	numbSetting('baseMultHand', baseMultHand, false, 0.0, 0.5, false),
	boolSetting('allowAllWeapons', allowAllWeapons),
	numbSetting('baseMultLongOne', baseMultLongOne, false, 0.0, 0.5, not allowAllWeapons),
	numbSetting('baseMultLongTwo', baseMultLongTwo, false, 0.0, 0.5, not allowAllWeapons),
	numbSetting('baseMultSpear', baseMultSpear, false, 0.0, 0.5, not allowAllWeapons),
	numbSetting('baseMultBluntOne', baseMultBluntOne, false, 0.0, 0.5, not allowAllWeapons),
	numbSetting('baseMultBluntTwoClose', baseMultBluntTwoClose, false, 0.0, 0.5, not allowAllWeapons),
	numbSetting('baseMultBluntTwoWide', baseMultBluntTwoWide, false, 0.0, 0.5, not allowAllWeapons),
	numbSetting('baseMultAxeOne', baseMultAxeOne, false, 0.0, 0.5, not allowAllWeapons),
	numbSetting('baseMultAxeTwo', baseMultAxeTwo, false, 0.0, 0.5, not allowAllWeapons),
	numbSetting('baseMultOther', baseMultOther, false, 0.0, 0.5, not allowAllWeapons),
	boolSetting('sneakSkillCapBool', sneakSkillCapBool),
	numbSetting('sneakSkillCapVal', sneakSkillCapVal, true, 1, 1000, false),
	boolSetting('enabledStrengthBuff', enabledStrengthBuff),
	boolSetting('enableStrengthBuffOtherWeapons', enableStrengthBuffOtherWeapons),
	boolSetting('strengthBuffCapBool', strengthBuffCapBool),
	numbSetting('strengthBuffCapVal', strengthBuffCapVal, true, 1, 1000, false),
	numbSetting('strengthBuffPerLevelVal', strengthBuffPerLevelVal, true, 0, 50, false),
	
  },
})
local settingsGroup = storage.playerSection('Settings_SlayAssassinMark')


-- update settings
local function updateSettings()
  baseMultShort = settingsGroup:get('baseMultShort')
  baseMultHand = settingsGroup:get('baseMultHand')
  baseMultLongOne = settingsGroup:get('baseMultLongOne')
  baseMultLongTwo = settingsGroup:get('baseMultLongTwo')
  baseMultSpear = settingsGroup:get('baseMultSpear')
  baseMultBluntOne = settingsGroup:get('baseMultBluntOne')
  baseMultBluntTwoClose = settingsGroup:get('baseMultBluntTwoClose')
  baseMultBluntTwoWide = settingsGroup:get('baseMultBluntTwoWide')
  baseMultAxeOne = settingsGroup:get('baseMultAxeOne')
  baseMultAxeTwo = settingsGroup:get('baseMultAxeTwo')
  baseMultOther = settingsGroup:get('baseMultOther')
  allowAllWeapons = settingsGroup:get('allowAllWeapons')
  sneakSkillCapBool = settingsGroup:get('sneakSkillCapBool')
  sneakSkillCapVal = settingsGroup:get('sneakSkillCapVal')
  enabledStrengthBuff = settingsGroup:get('enabledStrengthBuff')
  enableStrengthBuffOtherWeapons = settingsGroup:get('enableStrengthBuffOtherWeapons')
  strengthBuffCapBool = settingsGroup:get('strengthBuffCapBool')
  strengthBuffCapVal = settingsGroup:get('strengthBuffCapVal')
  strengthBuffPerLevelVal = settingsGroup:get('strengthBuffPerLevelVal')
  
end

local function init()
  updateSettings()
end

settingsGroup:subscribe(async:callback(updateSettings))



--start of script


local isSneaking = false
local isAttacking = false
local isNPC = types.NPC.objectIsInstance
local isCreature = types.Creature.objectIsInstance
local npcRecord
local confirmedTarget
local playerYaw
local targetYaw
local attributes = types.Actor.stats.attributes
local strengthBuff = 0
local hasAttacked = false --toggle to make sure we aren't repeating everything while the player continuously charges an attack


local function stopHeartSound()
	ambient.stopSoundFile("Sound\\slay\\SLAY_heartbeat.mp3")
	
end

local function startHeartSound()
	--play looping sound effect
	local params2 = {
		timeOffset=0.1,
		volume=0.7,
		scale=false,
		pitch=1.0,
		loop=true
												};
		ambient.playSoundFile("Sound\\slay\\SLAY_heartbeat.mp3", params2)

end

local function playWhooshSound()
--play initial sound effect
	local params = {
		timeOffset=0.1,
		volume=0.7,
		scale=false,
		pitch=1.0,
		loop=false
					};
		ambient.playSoundFile("Sound\\slay\\SLAY_assassin_time.mp3", params) --sound is playing even without a mark being placed need to update
end

local function getSneaking()
	if self.controls.sneak then
		isSneaking = true
		--print('getting sneak status')
		return isSneaking
		else return false
	end
	
end

local function getAttacking()
	if input.isActionPressed(input.ACTION.Use) then
		isAttacking = true
		return isAttacking
		else return false
	end
end


local function getWeaponType()
	local playerWeapon = types.Actor.equipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
	local damageMultiplier = 0
	local sneakSkill = types.NPC.stats.skills.sneak(self).base
	
	if sneakSkillCapBool == true then
		if sneakSkill > sneakSkillCapVal then
			sneakSkill = sneakSkillCapVal
		end
	end
	
	if not playerWeapon then --using hand to hand
		damageMultiplier = baseMultHand + (sneakSkill * 0.0025) --print('You are using hand-to-hand')
		return damageMultiplier
	end
	
	
	if types.Actor.stance(self) == types.Actor.STANCE.Weapon then
	
		local playerWeaponRecord = types.Weapon.record(playerWeapon)
		local playerWeaponType = playerWeaponRecord.type
	
		--print(tostring(sneakSkill))
	
		if  not types.Lockpick.objectIsInstance(playerWeapon) and not types.Probe.objectIsInstance(playerWeapon) then --if not using a lockpick/probe, determine weapon type and set damage mult
			if (playerWeaponType == types.Weapon.TYPE.ShortBladeOneHand) then -- short blade
				damageMultiplier = baseMultShort + (sneakSkill * 0.0025)
			elseif allowAllWeapons == true then --if drain is allowed for all weapons
				if (playerWeaponType == types.Weapon.TYPE.AxeOneHand) then --axe, 1h
					damageMultiplier = baseMultAxeOne + (sneakSkill * 0.0025)
				elseif (playerWeaponType == types.Weapon.TYPE.AxeTwoHand) then --axe, 2h
					damageMultiplier = baseMultAxeTwo + (sneakSkill * 0.0025)
				elseif (playerWeaponType == types.Weapon.TYPE.BluntOneHand) then --blunt, 1h
					damageMultiplier = baseMultBluntOne + (sneakSkill * 0.0025)
				elseif (playerWeaponType == types.Weapon.TYPE.BluntTwoClose) then -- blunt,2h, close (not staff)
					damageMultiplier = baseMultBluntTwoClose + (sneakSkill * 0.0025)
				elseif (playerWeaponType == types.Weapon.TYPE.BluntTwoWide) then -- blunt,2h, wide, staff
					damageMultiplier = baseMultBluntTwoWide + (sneakSkill * 0.0025)
				elseif (playerWeaponType == types.Weapon.TYPE.LongBladeOneHand) then -- long blade, 1h
					damageMultiplier = baseMultLongOne + (sneakSkill * 0.0025)
				elseif (playerWeaponType == types.Weapon.TYPE.LongBladeTwoHand) then -- longblade, 2h
					damageMultiplier = baseMultLongTwo + (sneakSkill * 0.0025)
				elseif (playerWeaponType == types.Weapon.TYPE.SpearTwoWide) then -- spear
					damageMultiplier = baseMultSpear + (sneakSkill * 0.0025)
				end
			else
				damageMultiplier = 0
				--print('Damage Mult was catch all 0')
			end
			
			return damageMultiplier
			
        end
		
		if types.Lockpick.objectIsInstance(playerWeapon) or types.Probe.objectIsInstance(playerWeapon) then --just in case, don't want to drain with a lockpick
			damageMultiplier = 0
			return damageMultiplier
		end
      
    end 
 
	
end

local function checkFacing(playerYaw, targetYaw)
    local difference = math.abs(playerYaw - targetYaw)
    -- Normalize the difference to account for wrap-around (e.g., 0 and 2π), not sure if needed necessarily but just in case
    if difference > math.pi then
        difference = 2 * math.pi - difference
    end
    return difference <= (math.pi / 3) --player needs to be within a 60 degree angle behind a target for the effect to happen
end


--onSave and onLoad functions to make sure a strengthbuff isn't saved for any reason. Not sure if this is needed but is a fail safe. 
local function onSave()
  return {
    strengthBuff = 0
  }
end

local function onLoad(data)
  if data then
    strengthBuff = 0
  end
end



local function onUpdate(dt)
    -- Check if the player is sneaking, if so get weapon type and return a damageMultiplier based on weapon type. Then check if the player is attacking, if so shoot a ray and grab
	--the target, then we check to make sure the target is an NPC or Creature. If it is, grab their yaw. Then we check to make sure the player is facing behind the target by comparing their Yaws, 
	--if the yaw is less than 60 degree difference we consider them to be behind the target. If all these things are true send the drain health event to the confirmedtarget. Then add str buff,
	
	--print('beginning sneak check')
	
	sneakstatus = getSneaking()
	isAttacking = getAttacking()
     
	
	if sneakstatus == true then
        local damageMultiplier = getWeaponType()
		--print('We got the damageMultiplier: ' .. tostring(damageMultiplier))
			if types.Actor.stance(self) == types.Actor.STANCE.Weapon and damageMultiplier > 0 then --ensures that a lockpick/probe, or other disabled weapon, isn't being used
				--print('We made it into the if statement about stance, damageMultiplier >0')
								
				local pos = camera.getPosition()
				local targ = pos + camera.viewportToWorldVector(util.vector2(0.5, 0.5)) * 100 --the larger this number the further away you can be for the draining effect, default: 100, not mutable right now 
				local possibletarget = nearby.castRay(pos, targ, {ignore = self, collisionShape = nearby.COLLISION_SHAPE_TYPE.RotatingBox, collisionType = nearby.COLLISION_TYPE.Actor}).hitObject
				if possibletarget ~= nil then
					if isNPC(possibletarget) then 
						npcRecord = types.NPC.record(possibletarget)
						targetYaw = possibletarget.rotation:getYaw()
						confirmedTarget = possibletarget
					elseif isCreature(possibletarget) then
						npcRecord = types.Creature.record(possibletarget)
						targetYaw = possibletarget.rotation:getYaw()
						confirmedTarget = possibletarget
					end
					
					--print(tostring(npcRecord)..tostring(targetYaw))
					playerYaw = self.rotation:getYaw()
					
					if checkFacing(playerYaw, targetYaw) then
						--print('You are behind the target')
						if isAttacking == true and types.Actor.stats.dynamic.health(possibletarget).current > 0 and hasAttacked == false then
							hasAttacked = true
								--print('You are attacking')
							
							confirmedTarget:sendEvent("applyHealthDrain", {mult = damageMultiplier, player = self})

							if enabledStrengthBuff == true then
								--add strength buff based on player level for the strike, default is 5 per level,
								strengthBuff = types.Actor.stats.level(self).current * strengthBuffPerLevelVal
							
								if strengthBuffCapBool == true then
									if strengthBuff > strengthBuffCapVal then --check against strengthbuff cap, lower to cap if over
										strengthBuff = strengthBuffCapVal
									end
								end 	
								attributes.strength(self).modifier = attributes.strength(self).modifier + strengthBuff
								--print(tostring(attributes.strength(self)))
							end
						end
						
					end --checkfacing end
				end	--possible target end
			end --stance & damagemult end
			
			if types.Actor.stance(self) == types.Actor.STANCE.Weapon and damageMultiplier == 0 then 
				--print('we made it inside mult 0 if statement')
				if enableStrengthBuffOtherWeapons == true then
				--print('we made it inside enablebuffotherweapons statement')
					local pos = camera.getPosition()
					local targ = pos + camera.viewportToWorldVector(util.vector2(0.5, 0.5)) * 100 --the larger this number the further away you can be for the draining effect, default: 100, not mutable right now 
					local possibletarget = nearby.castRay(pos, targ, {ignore = self, collisionShape = nearby.COLLISION_SHAPE_TYPE.RotatingBox, collisionType = nearby.COLLISION_TYPE.Actor}).hitObject
					if possibletarget ~= nil then
						if isNPC(possibletarget) then 
							npcRecord = types.NPC.record(possibletarget)
							targetYaw = possibletarget.rotation:getYaw()
							confirmedTarget = possibletarget
						elseif isCreature(possibletarget) then
							npcRecord = types.Creature.record(possibletarget)
							targetYaw = possibletarget.rotation:getYaw()
							confirmedTarget = possibletarget
						end
					
						--print(tostring(npcRecord)..tostring(targetYaw))
						playerYaw = self.rotation:getYaw()
					
						if checkFacing(playerYaw, targetYaw) then
							--print('You are behind the target')
							--print(tostring(hasAttacked))
							--print(tostring(hasAttacked))
							if isAttacking == true and types.Actor.stats.dynamic.health(confirmedTarget).current > 0 and hasAttacked == false then
								hasAttacked = true
								--print('You are attacking')
							
								if enabledStrengthBuff == true then
									--add strength buff based on player level for the strike, default is 5 per level,
									strengthBuff = types.Actor.stats.level(self).current * strengthBuffPerLevelVal
									--print('strength buff applied')
									if strengthBuffCapBool == true then
										if strengthBuff > strengthBuffCapVal then --check against strengthbuff cap, lower to cap if over
										strengthBuff = strengthBuffCapVal
										end
									end
									playWhooshSound()
									attributes.strength(self).modifier = attributes.strength(self).modifier + strengthBuff
									--print(tostring(attributes.strength(self)))
								end
							end
						
						end --checkfacing end
					end	--possible target end
				end --strengthbuff other weapons check
			end --end damagemult == 0
			
			
	
	end	--sneakStatus end
		  

	
	
	 
	if strengthBuff > 0 and isAttacking == false then --reset strength buff when no longer needed/attacking
		attributes.strength(self).modifier = attributes.strength(self).modifier - strengthBuff
		strengthBuff = 0
		hasAttacked = false
		--print('Strength is reset')
	elseif enabledStrengthBuff == false then
		hasAttacked = false --not sure if this is really doing anything but resetting hasAttacked here when strengthbuff is disabled
	end --str buff reset end
	
end --onupdate end



return {
    engineHandlers = {
        onUpdate = onUpdate,
		onActive = init,
		onSave = onSave,
		onLoad = onLoad,
	},
	
	eventHandlers = {
		stopHeartSound = stopHeartSound,
		startHeartSound = startHeartSound,
		playWhooshSound = playWhooshSound,
    
	
	}
}