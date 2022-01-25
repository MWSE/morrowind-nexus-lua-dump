local common = require("Neph.Power Fantasy.common")
local p, pMob
local W = {}

local function onAttack(e)

	local aRef = e.reference
	local aMob = e.mobile
	local tRef = e.targetReference
	local tMob = e.targetMobile
	
	-- AoE attacks (after the example of 4NM Final Strike)
	if aRef.data.neph[11] >= 0 and (aMob.actionData.physicalAttackType == 1
	or (common.skills and aMob:getSkillValue(4) >= 60 and aRef.data.neph[11] >= 3 and aRef.data.neph[11] <= 5 and aMob.actionData.physicalAttackType == 2)) then
		local weap = aMob.readiedWeapon
		timer.start{
			duration = 0.2/weap.object.speed,
			callback = function()
				for actor in tes3.iterate(aMob.hostileActors) do
					if actor ~= aMob and actor ~= tMob and actor.position:distance(aMob.position) <= 150 * weap.object.reach then
						common.scriptDmg.aRef	= aRef
						common.scriptDmg.aMob	= aMob
						common.scriptDmg.tMob	= actor
						common.scriptDmg.swing	= 1
						common.scriptDmg.dir	= aMob.actionData.physicalAttackType
						common.scriptDmg.weap	= aRef.data.neph[11]
						actor:applyDamage{damage = aMob.actionData.physicalDamage, applyArmor = true}
						--if aRef == tes3.player then tes3.messageBox("AoE Attack: %f", aMob.actionData.physicalDamage) end
					end
				end
			end
		}
	end
	
	if common.rbs then
	
		-- Mage: Swinging weapons costs more stamina, except for staves
		if aRef.data.neph[99] == "Mage" then
			if aMob.readiedWeapon and aRef.data.neph[11] ~= 5 then
				tes3.modStatistic{
					reference = aRef,
					name = "fatigue",
					current = -0.2*aMob.readiedWeapon.object.weight
				}
			end
		end
		
		-- Nord: Attacks on high fatigue cost more, but deal more damage in return
		if aMob.actorType > 0 and aRef.object.race.id:lower() == "nord" then
			if aRef.data.neph[11] >= 0 then
				tes3.modStatistic{
					reference = aRef,
					name = "fatigue",
					current = -0.2 * aMob.readiedWeapon.object.weight * aMob.fatigue.normalized
				}
			else
				tes3.modStatistic{
					reference = aRef,
					name = "fatigue",
					current = -1 * aMob.fatigue.normalized
				}
			end
		end
	end
	
	if common.skills then
	
		-- Acrobatics 30: Can attack while jumping (this handles blocking it before)
		if pMob.acrobatics.base < 30 and (pMob.isJumping or pMob.isFalling) then
			pMob.actionData.animationAttackState = 0
		end
		
		-- active block reset
		if aRef == p then
			if common.blockT then common.blockT:cancel() end
			p.data.neph[94] = 0
			tes3.findGMST("iBlockMaxChance").value = 50
			tes3.findGMST("iBlockMinChance").value = 10
		end
		
		if tRef == p and p.data.neph[11] >= 0 and p.data.neph[94] == 1 and pMob.block.base >= 60 then
			if 0.003*pMob.block.base + 0.002*pMob.luck.current >= math.random() and aMob.hasFreeAction and aRef.data.neph[96] == 0 then
				local hit = tes3.rayTest{
					position = tes3.getCameraPosition(),
					direction = {
						-1*tes3.getCameraVector().x,
						-1*tes3.getCameraVector().y,
						-1*tes3.getCameraVector().z
					}
				}
				if hit.intersection:distance(aRef.position) > hit.intersection:distance(tRef.position) then
					timer.start{
						duration = 0.2,
						callback = function()
							tes3.playSound{sound = "Light Armor Hit", reference = p}
							aMob.actionData.animationAttackState = 14
							aRef.data.neph[96] = 1
						end
					}
				end
			end
		end
		
		-- Short Blade 90: target takes 50% of the health difference 10s after being marked by an attack
		if tMob and aRef.data.neph[11] == 0 and aMob:getSkillValue(22) >= 90 and tRef.data.neph[16] == 0 then
			tes3.applyMagicSource{
				reference = tRef,
				source = "_neph_perk_22_90marker"
			}
			tRef.data.neph[16] = tMob.health.current
			timer.start{duration = 4.9, callback = function()
				if tMob:isAffectedByObject(tes3.getObject("_neph_perk_22_90marker")) and tRef.data.neph[16] > tMob.health.current and not tMob.isDead then
					tes3.applyMagicSource{
						reference = tRef,
						name = "Maximum Health Damage",
						effects = {{id = 23, min = 0.5*(tRef.data.neph[16] - tMob.health.current), max = 0.5*(tRef.data.neph[16] - tMob.health.current)}}
					}
					tes3.messageBox("Short blade combo attack!")
				end
				timer.start{duration = 5, callback = function()
					tRef.data.neph[16] = 0
				end}
			end}
		end
		
		-- Illusion 30: Set up damage bonus marker when breaking invisibility by attacking
		if aMob.invisibility > 0 then
			aRef.data.neph[17] = 2
			timer.start{duration = 2.5, callback = function()
				aRef.data.neph[17] = 0
			end}
		end

		-- Enchant 60: Staves with on-strike enchantments can cast their enchantment at range
		-- Basically player-only, since NPCs won't attack unless they are in melee range. 
		if aRef.object.objectType == tes3.objectType.npc and not tMob then
			if aMob.enchant.base >= 60 and aRef.data.neph[11] == 5 then
				local ench = aMob.readiedWeapon.object.enchantment
				if ench then
					if ench.castType == tes3.enchantmentType.onStrike then
						local spell = tes3.getObject("0n_" .. ench.id) or tes3alchemy.create{
							id 		= "0n_" .. ench.id,
							name	= ench.name,
							effects	= ench.effects
						}
						for i = 1, #ench.effects do
							spell.effects[i].rangeType = tes3.effectRange.target
						end
						spell.modified = true
						if aMob.readiedWeapon.variables.charge >= ench.chargeCost then
							aMob.readiedWeapon.variables.charge = aMob.readiedWeapon.variables.charge - ench.chargeCost
							tes3.applyMagicSource{reference = aRef, source = spell}
						else
							tes3.messageBox("Item does not have enough charge.")
						end
					end
				end
			end
		end
	end
end
event.register("attack", onAttack)


local function attackSpeed(e)

	local mob = e.mobile
	local ref = e.reference
	
	-- Redguard: Weapon attack speed during Adrenaline Rush
	if common.rbs and mob:isAffectedByObject(tes3.getObject("_neph_race_rg_pwAdrenaline")) then
		e.attackSpeed = e.attackSpeed * (1.5 + 0.02*ref.object.level)
	end
	
	-- Marksman 30: Successive attacks increase draw speed during combat
	if common.skills and mob:getSkillValue(23) >= 30 and ref.data.neph[11] >= 9 then
		e.attackSpeed = e.attackSpeed * (1 + 0.002*mob:getSkillValue(23) * ref.data.neph[24])
	end
	--if ref == p then tes3.messageBox("attack speed: %f", e.attackSpeed) end
end
event.register("attackStart", attackSpeed)


local function marksmanReset(e)
	if e.actor:getSkillValue(23) >= 30 then
		e.actor.reference.data.neph[24] = 0
	end
end
if common.skills then
	event.register("combatStopped", marksmanReset)
end


local function unresistStatus(e)
	-- (mostly alchemical) physical status effects, only resisted by new sanctuary
	if not e.target.mobile then return end
	if e.sourceInstance.sourceType == 3 or (e.source.id and (e.source.id == "_neph_perk_26_30ArPen" or e.source.id == "_neph_onhit_Daze")) then
		
		local status	= e.source.name
		local tRef		= e.target

		if status == "Slow"
		or status == "Bleeding"
		or status == "Maximum Health Damage"
		or status == "Knockdown"
		or status == "Armor Penetration"
		or status == "Damage Weapon"
		then
			e.resistedPercent = 0 + math.min(tRef.mobile.sanctuary, 100)
			if status == "Bleeding" then
				if tRef.object.type == tes3.creatureType.undead or string.find(tRef.object.id, "atronach") or string.find(tRef.object.id, "centurion") then
					e.resistedPercent = 100
				end
			end
		end
		
		-- irresistible knockout
		if status == "Knockout" then
			e.resistedPercent = 0
		end
	end
end
event.register("spellResist", unresistStatus)


local function unEquipShield(e)
	if e.reference.data.neph[11] == -1 and e.reference.mobile.readiedShield then
		e.reference.mobile:unequip{armorSlot = 8}
	end
end
if common.skills then
	event.register("weaponReadied",	unEquipShield)
end


local function hitChance(e)

	local tRef		= e.target
	local tMob		= e.targetMobile
	local aMob		= e.attackerMobile
	local lAFac		= 0
	local temp		= 0
	local blindFac	= math.clamp(1 - 0.01*aMob.blind + 0.01*aMob.attackBonus, 0.05, 1)

	if common.skills and tRef.object.objectType == tes3.objectType.npc and tMob:getSkillValue(21) >= 30 and tMob.hasFreeAction then
		-- Light Armor Scaling: Harder to hit, jumping and/or dashing per piece (double for helmet and cuirass)
		if tMob.isRunning then
			temp = temp + 1
		end
		if tMob.isJumping or tMob.isFalling then
			temp = temp + 1
		end
		if tRef == p and p.data.neph[98] == 3 then
			temp = temp + 1
		end
		-- LA 60: Harder to hit when low
		if tMob.lightArmor.base >= 60 and tMob.health.normalized < 1 then
			temp = temp + 3 * (1 - tMob.health.normalized)
		end
		for i = 0, 10 do
			if i == 9 and tRef.data.neph[6] <= 0 then -- do nothing
			elseif i == 10 and tRef.data.neph[7] <= 0 then -- do nothing
			elseif i ~= 8 and tRef.data.neph[i] <= 0 then
				lAFac = lAFac + 0.01*tMob.lightArmor.base * temp
				if i <= 1 then
					lAFac = lAFac + 0.01*tMob.lightArmor.base * temp
				end
			end
		end
	end
	e.hitChance = (100 - lAFac) * blindFac
	--if e.attacker == p then tes3.messageBox("lAFac: %f", lAFac) end
		
	if common.config.creaPerks and tMob.actorType == 0 and tMob.hasFreeAction then
		if string.find(tRef.object.id, "scamp") or tRef.object.id == "lustidrike" then
			e.hitChance = (65 + 0.5*aMob.attackBonus) * blindFac
		end
	end
	--tes3.messageBox("HIT CHANCE: %f", e.hitChance)
end
event.register("calcHitChance",	hitChance)


local function combatStarted(e)

	local aRef = e.actor.reference
	local tRef = e.target.reference
	local ref = aRef or tRef
	local mob = e.actor or e.target
	
	if mob.actorType > 0 then return end
	
	if common.skills then
	
		-- Short Blade 30: Reset initial crit chance
		if ref.data.neph[11] == 0 then
			ref.data.neph[18] = 5
		end
		
		-- Athletics 30: Initial SPD and fatigue regeneration in combat
		if mob.actorType > 0 and mob:getSkillValue(8) >= 30 then 
			local effect = tes3.getObject("_neph_perk_08_combatBonus").effects
			effect[1].max = 0.35*mob:getSkillValue(8)
			effect[1].min = 0.35*mob:getSkillValue(8)
			effect[2].max = 0.035*mob.fatigue.base
			effect[2].min = 0.035*mob.fatigue.base
			tes3.applyMagicSource{
				reference = ref,
				source = "_neph_perk_08_combatBonus"
			}
		end
	end
	
	-- NPC power use
	if common.rbs and mob.actorType == 1 then
		
		-- Racial powers
		if 0.1 + 0.9 * ref.object.level/60 >= math.random() then
			for power, msg in pairs(common.combatStartRacePowers) do
				if ref.data.neph[51] == power then
					ref.data.neph[51] = "done"
					timer.start{
						duration = 2,
						callback = function()
							if not mob.isDead then
								tes3.cast{
									reference = ref,
									target = ref,
									spell = power,
									instant = true
								}
								if common.config.NPCpowerMsg then
									tes3.messageBox(msg .. " has been casted.")
								end
							end
						end
					}
					break
				end
			end
			for actor in tes3.iterate(mob.hostileActors) do
				if actor == pMob then
					if ref.data.neph[51] == "_neph_race_no_pwBattleCry" then
						ref.data.neph[51] = "done"
						timer.start{
							duration = 2,
							callback = function()
								if not mob.isDead then
									tes3.cast{
										reference = ref,
										target = p,
										spell = "_neph_race_no_pwBattleCry",
										instant = true
									}
									if common.config.NPCpowerMsg then
										tes3.messageBox("Storm Voice has been casted.")
									end
								end
							end
						}
					end
				end
			end
		end
		
		-- Birthsign powers
		if 0.1 + 0.9 * ref.object.level/60 >= math.random() then
			for power, msg in pairs(common.combatStartBSPowers) do
				if ref.data.neph[50] == power then
					ref.data.neph[50] = "done"
					timer.start{
						duration = 4,
						callback = function()
							if not mob.isDead then
								tes3.cast{
									reference = ref,
									target = ref,
									spell = power,
									instant = true
								}
								if common.config.NPCpowerMsg then
									tes3.messageBox(msg .. " has been casted.")
								end
							end
						end
					}
					--tes3.messageBox("power chance: %f", 0.1 + 0.9 * ref.object.level/60)
					break
				end
			end
			for actor in tes3.iterate(mob.hostileActors) do
				if actor == pMob then
					if ref.data.neph[51] == "_neph_race_no_pwBattleCry" then
						ref.data.neph[51] = "done"
						timer.start{
							duration = 2,
							callback = function()
								if not mob.isDead then
									tes3.cast{
										reference = ref,
										target = p,
										spell = "_neph_race_no_pwBattleCry",
										instant = true
									}
									if common.config.NPCpowerMsg then
										tes3.messageBox("Storm Voice has been casted.")
									end
								end
							end
						}
					end
				end
			end
		end
	end
end
event.register("combatStarted", combatStarted)


-- Active Block Setup (reset by onAttack)
---------------------
local function activeBlockOn(e)
	if not tes3ui.menuMode() then
		if e.button == 0 then
			if p.data.neph[8] >= 0 and p.data.neph[11] < 9 and p.data.neph[11] >= 0 then
				common.blockT = timer.start{
					duration = 0.2,
					callback = function()
						p.data.neph[94] = 1
					end
				}				
			end
		end
	end
end
if common.skills then
	event.register("mouseButtonDown", activeBlockOn)
end


-- Marksman 60: Slow Time on right mouse button (used snippet of 4NM N'wah Shooter)
---------------
local function bulletTime(e)
	if pMob.actionData.animationAttackState == 2 then
		local dt = tes3.worldController.deltaTime
		local ic = tes3.worldController.inputController
		local MB = ic.mouseState.buttons
		if MB[2] == 128 and pMob.fatigue.current > (10 - 0.05*pMob.marksman.base) then
			pMob.fatigue.current = pMob.fatigue.current - dt * 5
			dt = -dt
			tes3.worldController.deltaTime = tes3.worldController.deltaTime * (0.8 - 0.006*pMob.marksman.base)
		end
		W.artim = math.clamp((W.artim or 0) + dt, 0, 4)
	else
		W.artim = nil
	end
end

local function rMouseUp(e)
	if e.button == 0 then
		W.artim = nil
		event.unregister("simulate", bulletTime)
		event.unregister("mouseButtonUp", rMouseUp)
	end
end

local function rMouseDown(e)
	if common.skills and not tes3ui.menuMode() and pMob.marksman.base >= 60 then
		if e.button == 0 then
			if p.data.neph[11] >= 9 then
				if not W.artim then
					event.register("simulate", bulletTime)
					event.register("mouseButtonUp", rMouseUp)
				end
			end
		end
	end
end
event.register("mouseButtonDown", rMouseDown)


local function playerVars(e)

	W = {}
	p = tes3.player
	pMob = tes3.mobilePlayer

end
event.register("loaded", playerVars)