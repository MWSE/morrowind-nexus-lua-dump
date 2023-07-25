local config = require("OEA.OEA5 Bash.config")

local logging = require("OEA.OEA5 Bash.logging")
local log = logging.createLogger("main")

---@param type number
---@return number? skill
local function getSkillByType(type)
	log:trace("getSkillByType(%s)", type)
	local skills = {
		[tes3.weaponType.shortBladeOneHand] = tes3.skill.shortBlade,
		[tes3.weaponType.longBladeOneHand] = tes3.skill.longBlade,
		[tes3.weaponType.longBladeTwoClose] = tes3.skill.longBlade,
		[tes3.weaponType.bluntOneHand] = tes3.skill.bluntWeapon,
		[tes3.weaponType.bluntTwoClose] = tes3.skill.bluntWeapon,
		[tes3.weaponType.bluntTwoWide] = tes3.skill.bluntWeapon,
		[tes3.weaponType.spearTwoWide] = tes3.skill.spear,
		[tes3.weaponType.axeOneHand] = tes3.skill.axe,
		[tes3.weaponType.axeTwoHand] = tes3.skill.axe,
	}
	return skills[type]
end

---@return number? type 
---@return number? lockType
---@return number? skill
local function getData()
	local type ---@type number?
	local lockType ---@type number?
	local skill ---@type number?
	local mobilePlayer = tes3.mobilePlayer
	local readiedWeapon = mobilePlayer.readiedWeapon
	if readiedWeapon then
		local weapon = readiedWeapon.object ---@cast weapon tes3weapon
		type = weapon.type
		if (type >= 9) then return end -- not ranged weapon
		if (string.sub(weapon.name, 1, 5) == "Bound") then return end
		if (readiedWeapon.itemData.condition <= 0) then
			tes3.messageBox("Your weapon is broken. You will need another to bash.")
			return
		end
		if type == tes3.weaponType.shortBladeOneHand then
			skill = mobilePlayer.shortBlade.current
			lockType = type + 1 -- 1
		elseif type == tes3.weaponType.longBladeOneHand or type == tes3.weaponType.longBladeTwoClose then
			skill = mobilePlayer.longBlade.current
			lockType = type + 1 -- 2/3
		elseif type == tes3.weaponType.bluntOneHand or type == tes3.weaponType.bluntTwoClose or type == tes3.weaponType.bluntTwoWide then
			skill = mobilePlayer.bluntWeapon.current
			lockType = (type + 1) * (4 / 5) -- 3.2/4/4.8
		elseif type == tes3.weaponType.spearTwoWide then
			skill = mobilePlayer.spear.current
			lockType = 2
		elseif type == tes3.weaponType.axeOneHand or type == tes3.weaponType.axeTwoHand then
			skill = mobilePlayer.axe.current
			lockType = type - 3 -- 4/5
		end
	else -- hand to hand
		type = -1
		lockType = 0.5
		skill = mobilePlayer.handToHand.current
	end
	return type, lockType, skill
end

local function triggerCrime()
	local trespassFine = tes3.findGMST("iCrimeTresspass").value ---@cast trespassFine number
	tes3.triggerCrime({ type = tes3.crimeType.trespass, value = trespassFine })
end

---@param target tes3reference
local function triggerTrap(target)
	local trap = tes3.getTrap({ reference = target })
	if trap then
		tes3.cast({ reference = target, target = tes3.mobilePlayer, spell = trap })
		target.lockNode.trap = nil
	end
end

---@param type number
---@return boolean
local function exerciseSkill(type)
	log:trace("exerciseSkill(%s)", type)
	local mobilePlayer = tes3.mobilePlayer
	local skillId = getSkillByType(type)
	if not skillId then return false end
	local skill = tes3.getSkill(skillId)
	mobilePlayer:exerciseSkill(skillId, skill.actions[1])
	return true
end

---@param e attackEventData
local function onAttack(e)
	local mobilePlayer = tes3.mobilePlayer
	local target = tes3.getPlayerTarget()
	if (e.reference ~= tes3.player) then return end
	local readiedWeapon = mobilePlayer.readiedWeapon
	if not readiedWeapon and not config.Hand then return end
	if (tes3.getLockLevel({ reference = target }) == nil) then return end
	if (target.lockNode.locked == false) then
		tes3.messageBox("It's already unlocked.")
		return
	end
	local type, lockType, skill = getData()
	if not type then return end
	if not skill then return end
	log:trace("getData(): %s, %s, %s", type, lockType, skill)

	triggerCrime()
	triggerTrap(target)
	if readiedWeapon then
		local conditionDamage = mobilePlayer.strength.current * config.OldMult
		readiedWeapon.itemData.condition = readiedWeapon.itemData.condition - conditionDamage
		if (readiedWeapon.itemData.condition < 0) then readiedWeapon.itemData.condition = 0 end
	end

	local x1 = mobilePlayer.agility.current + (mobilePlayer.luck.current * 0.1) + skill
	local x2 = tes3.findGMST("fFatigueBase").value - (tes3.findGMST("fFatigueMult").value * (1 - mobilePlayer.fatigue.normalized))
	local x3 = tes3.findGMST("fPickLockMult").value * tes3.getLockLevel({ reference = target })
	local Chance = (x1 * x2) + x3
	local Roll = math.random(100)

	if not readiedWeapon then
		local handDamage = math.floor(mobilePlayer.strength.current / 10)
		tes3.applyMagicSource({
			reference = mobilePlayer,
			name = "Hand to Hand Lockbashing",
			effects = { { id = tes3.effect.drainSkill, skill = tes3.skill.handToHand, duration = handDamage, min = handDamage, max = handDamage } },
		})
		tes3.playSound({ sound = "Health Damage" })
	end

	if (target.data.OEA5 == nil) then target.data.OEA5 = {} end
	if (target.data.OEA5.hits == nil) then target.data.OEA5.hits = 0 end

	if (Chance < 0) then
		tes3.messageBox("The lock is too sturdy.")
		tes3.playSound({ sound = "Heavy Armor Hit" })
		return
	end

	if (Roll > Chance) then
		tes3.messageBox("The lock-bash has failed.")
		tes3.playSound({ sound = "Light Armor Hit" })
		target.data.OEA5.hits = target.data.OEA5.hits + 1
		return
	end

	if (Roll <= Chance) then
		local result = exerciseSkill(skill)
		if not result then return end
		local newLockLevel = math.floor(tes3.getLockLevel({ reference = target }) - (0.1 * mobilePlayer.strength.current * lockType))
		tes3.setLockLevel({ reference = target, level = newLockLevel })
		if (newLockLevel <= 0) then
			tes3.setLockLevel({ reference = target, level = 1 })
			tes3.unlock({ reference = target })
			tes3.messageBox("The lock has been bashed open!")
			tes3.playSound({ sound = "critical damage" })
			target.data.OEA5.hits = target.data.OEA5.hits + 1
		elseif (newLockLevel > 0) then
			tes3.messageBox("The lock has been partially bashed.")
			tes3.playSound({ sound = "Medium Armor Hit" })
			target.data.OEA5.hits = target.data.OEA5.hits + 1
		end
	end
end

event.register("initialized", function() event.register("attack", onAttack) end)

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function() require("OEA.OEA5 Bash.mcm") end)
