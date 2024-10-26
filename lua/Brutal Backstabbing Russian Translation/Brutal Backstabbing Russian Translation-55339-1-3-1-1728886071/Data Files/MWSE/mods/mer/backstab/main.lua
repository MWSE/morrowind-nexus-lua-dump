--[[
	Double Backstab Damage
	This mod allows for backstabs when using short blades.
]]--

--register MCM
local configController = require("mer.backstab.config")
local mcm = require("mer.backstab.mcm")
local multiMin = 1.5
local multiMax = 3.0
local backstabDegrees = 80
local backstabAngle = (2 * math.pi) * (backstabDegrees / 360)

local debugMode = false
local function debugMessage(message, ...)
    if debugMode then
        mwse.log(message, ...)
		tes3.messageBox(string.format(message, ...))
	end
end

local targetList = {}

local function onCombatStopped()
	targetList = {}
end

local function onDamage(e)
    local config = configController:get()
	for i=1, #targetList do
		if targetList[i] and targetList[i].attackerRef then
			local targetRef = e.reference
			local attackerRef = targetList[i].attackerRef
			if targetRef == targetList[i]["targetRef"] then
				-- Check that target is facing away from attacker orientation is between -Pi and Pi. 
				-- We get the difference between attacker and target angles, and if it's greater than pie, 
				-- we've got the obtuse angle, so subtract 2*pi to get the acute angle.
				local attackerAngle = attackerRef.orientation.z
				local targetAngle = targetRef.orientation.z
				local diff = math.abs (attackerAngle - targetAngle )
				if diff > math.pi then
					diff = math.abs ( diff - ( 2 * math.pi ) )
				end
				-- If the player and attacker have the same orientation, then the attacker must be behind the target
				table.remove(targetList, i)
				if ( diff < backstabAngle ) then
					tes3.playSound({ reference = e.reference, sound = "critical damage" })
					if attackerRef == tes3.getPlayerRef() and config.showBackStabMsg then 
						tes3.messageBox("Удар в спину!")
					end
				end
			end
		end
	end
end

local function isAllowedWeapon(thisWeaponType)
    local config = configController:get()
    for weaponTypeName, _ in pairs(config.enabledWeaponTypes) do
        if mcm.weaponList[weaponTypeName][thisWeaponType] then
            return true
        end
    end
    return false
end

local function onAttack(e)
    local config = configController:get()
	local attackerMobile = e.mobile
	local attackerRef = e.reference
	local targetRef = e.targetReference
	
	--Exit conditions
	local weapon = attackerMobile.readiedWeapon
	if not weapon then 
		debugMessage("No weapon")
		return 
    end 
    if not config.enableBrutalBackstabbing then
        debugMessage("Brutal Backstabbing is disabled")
        return
    end 
    if not isAllowedWeapon(weapon.object.type) then
		debugMessage("Weapon type not allowed. Attacker: %s", attackerRef.object.name)
		return 	
    end 
    if not targetRef then
		debugMessage("No target")
		return
    end 
    if attackerMobile.actionData.attackDirection ~= 3 and weapon.object.type < 9 and config.stabAttacksOnly then
		debugMessage("Not a stab")
		return
    end
    debugMessage("Got through limitations")
	--/exit conditions

	-- Check that target is facing away from attacker orientation is between -Pi and Pi. 
	-- We get the difference between attacker and target angles, and if it's greater than pie, 
	-- we've got the obtuse angle, so subtract 2*pi to get the acute angle.
	local attackerAngle = attackerRef.orientation.z
	local targetAngle = targetRef.orientation.z
	local diff = math.abs (attackerAngle - targetAngle )
	if diff > math.pi then
		diff = math.abs ( diff - ( 2 * math.pi ) )
	end
	-- If the player and attacker have the same orientation, then the attacker must be behind the target
	if ( diff < backstabAngle and attackerMobile.actionData.physicalDamage > 0 ) then
		--get the damage multi from attacker stats
		local sneak = attackerMobile.sneak.current < 100 and attackerMobile.sneak.current or 100
		local agility = attackerMobile.agility.current < 100 and attackerMobile.agility.current or 100
		local damageMultiplier = multiMin + ( ( multiMax - multiMin ) * ( sneak / 100 ) * ( agility / 100 ) )
		attackerMobile.actionData.physicalDamage = attackerMobile.actionData.physicalDamage * damageMultiplier

		table.insert(targetList, { targetRef = targetRef, attackerRef = attackerRef})
	end
end
event.register( "attack", onAttack )
event.register( "damage", onDamage )
event.register( "combatStopped", onCombatStopped )

