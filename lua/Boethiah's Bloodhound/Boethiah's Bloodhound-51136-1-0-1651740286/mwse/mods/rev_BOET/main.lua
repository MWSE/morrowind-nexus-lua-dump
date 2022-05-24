local function boethiahCheck(e)
	if e.info.id == "7672105291381417950" then
		local skills = {}
		skills[tes3.skill.marksman] = tes3.player.mobile.marksman.base
		skills[tes3.skill.bluntWeapon] = tes3.player.mobile.bluntWeapon.base
		skills[tes3.skill.longBlade] = tes3.player.mobile.longBlade.base
		skills[tes3.skill.shortBlade] = tes3.player.mobile.shortBlade.base
		skills[tes3.skill.axe] = tes3.player.mobile.axe.base
		skills[tes3.skill.spear] = tes3.player.mobile.spear.base
				
		local highest = 0
		local skill = tes3.skill.spear
		
		for k,v in pairs(skills) do
			if v > highest then 
				skill = k 
				highest = v
			end
		end
		
		local givenItem = "rev_boet_bloodhound_spear"
		
		if skill == tes3.skill.axe then 
			givenItem = "rev_boet_bloodhound_axe"
		elseif skill == tes3.skill.longBlade then 
			givenItem = "rev_boet_bloodhound_longsword"
		elseif skill == tes3.skill.marksman then 
			givenItem = "rev_boet_bloodhound_bow"
		elseif skill == tes3.skill.shortBlade then 
			givenItem = "rev_boet_bloodhound_dagger"
		elseif skill == tes3.skill.bluntWeapon then 
			givenItem = "rev_boet_bloodhound_mace"
		end
		
		tes3.addItem({ reference = tes3.player, item = givenItem, count = 1, updateGUI = true})
		tes3.removeItem({ reference = tes3.player, item = "rev_boet_knife", count = 1, updateGUI = true})
	end
end

local function attackCallback(e)
	if e.targetReference == nil then return end
	
	local weapons = {
		"rev_boet_bloodhound_axe",
		"rev_boet_bloodhound_longsword",
		"rev_boet_bloodhound_spear",
		"rev_boet_bloodhound_mace",
		"rev_boet_bloodhound_dagger",
	}
	
	for k,v in ipairs(weapons) do 
		if v == e.mobile.readiedWeapon.object.id then 
			e.mobile:applyDamage({ damage = (e.mobile.health.base /5), applyArmor = false, resistAttribute = false, applyDifficulty = false, })
			e.targetMobile:applyDamage({ damage = (e.targetMobile.health.base /5), applyArmor = false, resistAttribute = false, applyDifficulty = false, })
		end
	end
end

local function attackCallbackBow(e)
	if "rev_boet_bloodhound_bow" == e.firingWeapon.id then 
		e.firingReference.mobile:applyDamage({ damage = (e.firingReference.mobile.health.base /5), applyArmor = false, resistAttribute = false, applyDifficulty = false, })
		e.target.mobile:applyDamage({ damage = (e.target.mobile.health.base /5), applyArmor = false, resistAttribute = false, applyDifficulty = false, })
	end
end


event.register(tes3.event.attack, attackCallback)
event.register(tes3.event.infoResponse, boethiahCheck)
event.register(tes3.event.projectileHitActor, attackCallbackBow)