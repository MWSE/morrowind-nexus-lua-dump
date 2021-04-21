local config = require("OEA.OEA5 Bash.config")

local LockData
if (tes3.getFileExists("MWSE\\mods\\adituV\\DetectTrap\\main.lua")) then
	LockData = require("adituV.DetectTrap.LockData")
end

local OPMPconfig
if tes3.getFileExists("MWSE\\mods\\OEA\\OEA9 Fail\\main.lua") then
	if tes3.getFileExists("MWSE\\mods\\OEA\\OEA9 Fail\\config.lua") then
		OPMPconfig = require("OEA.OEA9 Fail.config")
	end
end

local function BreakThings(Ref)
	local broken = 0
	local degCount = 0

	local hits = Ref.data.OEA5.hits

	local breakChance = math.min(config.MinChance + hits, config.MaxChance)

	if (Ref.object.inventory == nil) then
		return
	end

	Ref.object.inventory:resolveLeveledItems()
	local tes3iterator = Ref.object.inventory

	for _, node in pairs(tes3iterator) do
		if (node.object.objectType == tes3.objectType.weapon) or (node.object.objectType == tes3.objectType.armor) then
			degCount = degCount + node.count
		elseif (node.object.objectType == tes3.objectType.alchemy) or (node.object.objectType == tes3.objectType.ammunition) or (node.object.objectType == tes3.objectType.ingredient) then	
			local lost = 0
			for i = 1, node.count do
				local chance = (config.ConstChance / node.count)
				local breakRoll = math.random(1, 100)
				if (chance > breakRoll) then
					lost = lost + 1
				end
			end
			if ( lost > 0) then
				tes3.removeItem({ reference = Ref, item = node.object.id, count = lost })
				broken = broken + 1
				if (broken >= config.MaxItems) then
					break
				end
			end
		else
			for i = 1, node.count do
				local breakRoll = math.random(1, 100)
				if (breakChance > breakRoll) then
					tes3.removeItem({ reference = Ref, item = node.object.id, count = 1 })
					broken = broken + 1
					if (broken >= config.MaxItems) then
						break
					end
				end
			end
		end
	end

	for _, stack in pairs(tes3iterator) do
		if (stack.object.objectType == tes3.objectType.weapon) or (stack.object.objectType == tes3.objectType.armor) then
			local pristineItems = stack.count - (stack.variables and #stack.variables or 0)
			for i = 1, pristineItems do
				local itemData = tes3.addItemData({ to = Ref, item = stack.object })
				itemData.condition = math.floor(itemData.condition * (1 - ((hits * config.DegMult / degCount) / 100)))
			end
			if (stack.variables) then
				for i = 1, #stack.variables do
					stack.variables[i].condition = math.floor(stack.variables[i].condition * (1 - ((hits * config.DegMult / degCount) / 100)))
				end
			end
		end
	end

	if (broken > 0) then
		tes3.messageBox("Your bashing against the container has broken something valuable.")
	end
end

local function OnAttack(e)
	local Ref = tes3.getPlayerTarget()
	local type
	local lockType
	local temp
	local skill

	if (e.reference ~= tes3.player) then
		return
	end

	if (tes3.mobilePlayer.readiedWeapon == nil) and (config.Hand == false) then
		return
	end

	if (tes3.getLockLevel({ reference = Ref }) == nil) then
		return
	end

	if (Ref.lockNode.locked == false) then
		tes3.messageBox("This container is already unlocked.")
		return
	end

	if (tes3.mobilePlayer.readiedWeapon ~= nil) then
		type = tes3.mobilePlayer.readiedWeapon.object.type + 1

		if (type > 9) then
			return
		end

		if (string.sub(tes3.mobilePlayer.readiedWeapon.object.name, 1, 5) == "Bound") then
			return
		end

		if (tes3.mobilePlayer.readiedWeapon.variables.condition <= 0) then
			tes3.messageBox("Your weapon is broken. You will need another to bash.")
			return
		end

		if (type < 2) then
			skill = tes3.mobilePlayer.shortBlade.current
			lockType = type
		elseif ( type < 4 ) then
			skill = tes3.mobilePlayer.longBlade.current
			lockType = type
		elseif ( type == 7 ) then
			skill = tes3.mobilePlayer.spear.current
			lockType = 2
		elseif ( type > 7 ) then
			skill = tes3.mobilePlayer.axe.current
			lockType = type - 4
		else
			skill = tes3.mobilePlayer.bluntWeapon.current
			lockType = type * (4 / 5)
		end
	else
		type = -1
		lockType = 0.5
		skill = tes3.mobilePlayer.handToHand.current
	end

	if (Ref.data.OEA5 == nil) then
		Ref.data.OEA5 = {}
	end
	if (Ref.data.OEA5.hits == nil) then
		Ref.data.OEA5.hits = 0
	end

	tes3.triggerCrime({type = tes3.crimeType.trespass, value = tes3.findGMST("iCrimeTresspass").value})

	if (tes3.getTrap({ reference = Ref }) ~= nil) then
		local Trap = tes3.getTrap({ reference = Ref })
		tes3.cast({ reference = Ref, target = tes3.mobilePlayer, spell = Trap })
		Ref.lockNode.trap = nil
	end

	if (tes3.mobilePlayer.readiedWeapon ~= nil) then
		local WeaponDamage = tes3.mobilePlayer.strength.current * config.OldMult
		tes3.mobilePlayer.readiedWeapon.variables.condition = tes3.mobilePlayer.readiedWeapon.variables.condition - WeaponDamage
		if (tes3.mobilePlayer.readiedWeapon.variables.condition < 0) then
			tes3.mobilePlayer.readiedWeapon.variables.condition = 0
		end
	end

	local x1 = tes3.mobilePlayer.agility.current + (tes3.mobilePlayer.luck.current * 0.1) + skill
	local x2 = tes3.findGMST("fFatigueBase").value - (tes3.findGMST("fFatigueMult").value * (1 - tes3.mobilePlayer.fatigue.normalized))
	local x3 = tes3.findGMST("fPickLockMult").value * tes3.getLockLevel({ reference = Ref })
	local Chance = (x1 * x2) + x3
	local Roll = math.random(100)

	if (tes3.mobilePlayer.readiedWeapon == nil) then
		local handDamage = math.floor(tes3.mobilePlayer.strength.current / 10)
		tes3.modStatistic({
			reference = tes3.mobilePlayer,
			skill = tes3.skill.handToHand,
			current = (0 - handDamage)
		})
		tes3.playSound({ sound = "Health Damage" })
	end

	if (Chance < 0) then
		--mwse.log("[OEA5] Sturdy")
		tes3.messageBox("The lock is too sturdy.")
		tes3.playSound({ sound = "Heavy Armor Hit" })
		return
	end

	if (Roll > Chance) then
		--mwse.log("[OEA5] Failure")
		if (OPMPconfig) then
			if (type == -1) then
				local handToHand = tes3.getSkill(tes3.skill.handToHand)
				tes3.mobilePlayer:exerciseSkill(tes3.skill.handToHand, handToHand.actions[1] * OPMPconfig.HandMult)
			elseif (type ~= -1) and (type < 2) then
				local shortBlade = tes3.getSkill(tes3.skill.shortBlade)
				tes3.mobilePlayer:exerciseSkill(tes3.skill.shortBlade, shortBlade.actions[1] * OPMPconfig.WeaponMult)
			elseif ( type < 4 ) then
				local longBlade = tes3.getSkill(tes3.skill.longBlade)
				tes3.mobilePlayer:exerciseSkill(tes3.skill.longBlade, longBlade.actions[1] * OPMPconfig.WeaponMult)
			elseif ( type == 7 ) then
				local spear = tes3.getSkill(tes3.skill.spear)
				tes3.mobilePlayer:exerciseSkill(tes3.skill.spear, spear.actions[1] * OPMPconfig.WeaponMult)
			elseif ( type > 7 ) then
				local axe = tes3.getSkill(tes3.skill.axe)
				tes3.mobilePlayer:exerciseSkill(tes3.skill.axe, axe.actions[1] * OPMPconfig.WeaponMult)
			else
				local bluntWeapon = tes3.getSkill(tes3.skill.bluntWeapon)
				tes3.mobilePlayer:exerciseSkill(tes3.skill.bluntWeapon, bluntWeapon.actions[1] * OPMPconfig.WeaponMult)
			end
		end
		tes3.messageBox("The lock-bash has failed.")
		tes3.playSound({ sound = "Light Armor Hit" })
		Ref.data.OEA5.hits = Ref.data.OEA5.hits + 1
		return
	end

	if (Roll <= Chance) then
		if (type == -1) then
			local handToHand = tes3.getSkill(tes3.skill.handToHand)
			tes3.mobilePlayer:exerciseSkill(tes3.skill.handToHand, handToHand.actions[1])
		elseif (type ~= -1) and (type < 2) then
			local shortBlade = tes3.getSkill(tes3.skill.shortBlade)
			tes3.mobilePlayer:exerciseSkill(tes3.skill.shortBlade, shortBlade.actions[1])
		elseif ( type < 4 ) then
			local longBlade = tes3.getSkill(tes3.skill.longBlade)
			tes3.mobilePlayer:exerciseSkill(tes3.skill.longBlade, longBlade.actions[1])
		elseif ( type == 7 ) then
			local spear = tes3.getSkill(tes3.skill.spear)
			tes3.mobilePlayer:exerciseSkill(tes3.skill.spear, spear.actions[1])
		elseif ( type > 7 ) then
			local axe = tes3.getSkill(tes3.skill.axe)
			tes3.mobilePlayer:exerciseSkill(tes3.skill.axe, axe.actions[1])
		else
			local bluntWeapon = tes3.getSkill(tes3.skill.bluntWeapon)
			tes3.mobilePlayer:exerciseSkill(tes3.skill.bluntWeapon, bluntWeapon.actions[1])
		end

		temp = tes3.getLockLevel({ reference = Ref })
		temp = temp - (0.1 * tes3.mobilePlayer.strength.current * lockType)
		temp = math.floor(temp)
		tes3.setLockLevel({ reference = Ref, level = temp })
		if (temp <= 0) then
			--mwse.log("[OEA5] Unlocking")
			tes3.setLockLevel({ reference = Ref, level = 1 })
			tes3.unlock({ reference = Ref })
			tes3.messageBox("The lock has been bashed open!")
			tes3.playSound({ sound = "critical damage" })

			if (config.tooltip == 2) then
				local drtooltip = tes3ui.findHelpLayerMenu(-32507)
				local llvl = drtooltip:findChild(-1243)
				if (llvl ~= nil) then
					llvl.text = "Lock Level: Unlocked"
					drtooltip:updateLayout()
				else
					local LTD = drtooltip:findChild(tes3ui.registerID("DT_Tooltip_Lock"))
					if (LTD ~= nil) then
						LTD.text = "Lock Level: Unlocked"
						drtooltip:updateLayout()
					end
				end
			end

			Ref.data.OEA5.hits = Ref.data.OEA5.hits + 1
			if (config.Break == true) then
				BreakThings(Ref)
			end
		elseif (temp > 0) then
			--mwse.log("[OEA5] Part-Bashing")
			tes3.messageBox("The lock has been partially bashed.")
			tes3.playSound({ sound = "Medium Armor Hit" })
			Ref.data.OEA5.hits = Ref.data.OEA5.hits + 1

			if (config.tooltip == 2) then
				local drtooltip = tes3ui.findHelpLayerMenu(-32507)
				local llvl = drtooltip:findChild(-1243)
				if (llvl ~= nil) then
					llvl.text = "Lock Level: " .. temp
					drtooltip:updateLayout()
				else
					local LTD = drtooltip:findChild(tes3ui.registerID("DT_Tooltip_Lock"))
					if (LTD ~= nil) then
						LTD.text = "Lock Level: " .. temp
						drtooltip:updateLayout()
					end
				end
			end
		end

		if (config.tooltip == 1) then
			if (LockData ~= nil) then
				local ld = LockData.getForReference(Ref)
				ld:attemptDetectLock()
				ld:attemptDetectTrap()
			end
			timer.start({ duration = 0.06, type = timer.real, callback =
				function()
					tes3.tapKey(tes3.scanCode.escape)
				end
			})
			tes3.tapKey(tes3.scanCode.escape)
		end
	end
end

event.register("attack", OnAttack)

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
	require("OEA.OEA5 Bash.mcm")
end)