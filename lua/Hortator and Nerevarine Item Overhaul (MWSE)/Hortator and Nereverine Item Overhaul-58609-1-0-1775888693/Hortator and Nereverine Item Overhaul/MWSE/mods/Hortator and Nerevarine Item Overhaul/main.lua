local function overhaulHortatorNerevarineItems(e)
	
	-- Belt of the Hortator
	local hlaaluBelt = tes3.getObject("hortatorbelt")
	
	if hlaaluBelt then
		local beltEnchant = tes3.createObject({
			objectType = tes3.objectType.enchantment,
			id = "OHNI_Hlaalu_Belt_En",
			castType = tes3.enchantmentType.constant
	
		})
	
		-- Effect 1: Jump
		beltEnchant.effects[1].id = tes3.effect.jump
		beltEnchant.effects[1].rangeType = tes3.effectRange.self
		beltEnchant.effects[1].min = 10
		beltEnchant.effects[1].max = 10

		-- Effect 2: Sanctuary
		beltEnchant.effects[2].id = tes3.effect.sanctuary
		beltEnchant.effects[2].rangeType = tes3.effectRange.self
		beltEnchant.effects[2].min = 25
		beltEnchant.effects[2].max = 25

		-- Effect 3: Insight
		beltEnchant.effects[3].id = tes3.effect.T_mysticism_Insight
		beltEnchant.effects[3].rangeType = tes3.effectRange.self
		beltEnchant.effects[3].min = 20
		beltEnchant.effects[3].max = 20

		-- Apply to Belt
		hlaaluBelt.enchantment = beltEnchant
	
		-- Increased Value
		hlaaluBelt.value = 20000
	end
	
	-- Ring of the Hortator
	local redoranRing = tes3.getObject("hortatorring")
	
	if redoranRing then
		local ringEnchant = tes3.createObject({
			objectType = tes3.objectType.enchantment,
			id = "OHNI_Redoran_Ring_En",
			castType = tes3.enchantmentType.constant
	
		})
	
		-- Effect 1: Fortify Health
		ringEnchant.effects[1].id = tes3.effect.fortifyHealth
		ringEnchant.effects[1].rangeType = tes3.effectRange.self
		ringEnchant.effects[1].min = 50
		ringEnchant.effects[1].max = 50

		-- Effect 2: Fortify Attack
		ringEnchant.effects[2].id = tes3.effect.fortifyAttack
		ringEnchant.effects[2].rangeType = tes3.effectRange.self
		ringEnchant.effects[2].min = 20
		ringEnchant.effects[2].max = 20

		-- Effect 3: Shield
		ringEnchant.effects[3].id = tes3.effect.shield
		ringEnchant.effects[3].rangeType = tes3.effectRange.self
		ringEnchant.effects[3].min = 20
		ringEnchant.effects[3].max = 20

		-- Apply to Ring
		redoranRing.enchantment = ringEnchant
	
		-- Increased Value
		redoranRing.value = 30000
	end
	
	-- Robe of the Hortator
	local telvanniRobe = tes3.getObject("hortatorrobe")
	
	if telvanniRobe then
		local robeEnchant = tes3.createObject({
			objectType = tes3.objectType.enchantment,
			id = "OHNI_Telvanni_Robe_En",
			castType = tes3.enchantmentType.constant
	
		})
	
		-- Effect 1: Fortify Casting
		robeEnchant.effects[1].id = tes3.effect.T_restoration_FortifyCasting
		robeEnchant.effects[1].rangeType = tes3.effectRange.self
		robeEnchant.effects[1].min = 40
		robeEnchant.effects[1].max = 40

		-- Effect 2: Spell Absorption
		robeEnchant.effects[2].id = tes3.effect.spellAbsorption
		robeEnchant.effects[2].rangeType = tes3.effectRange.self
		robeEnchant.effects[2].min = 20
		robeEnchant.effects[2].max = 20

		-- Effect 3: Reflect
		robeEnchant.effects[3].id = tes3.effect.reflect
		robeEnchant.effects[3].rangeType = tes3.effectRange.self
		robeEnchant.effects[3].min = 20
		robeEnchant.effects[3].max = 20

		-- Apply to Robe
		telvanniRobe.enchantment = robeEnchant
	
		-- Increased Value
		telvanniRobe.value = 35000
	end
	
		-- Moon and Star
	local moonStar = tes3.getObject("moon_and_star")
	
	if moonStar then
		local nerevarEnchant = tes3.createObject({
			objectType = tes3.objectType.enchantment,
			id = "OHNI_Nerevar_Ring_En",
			castType = tes3.enchantmentType.constant
	
		})
	
		-- Effect 1: Fortify Personality
		nerevarEnchant.effects[1].id = tes3.effect.fortifyAttribute
		nerevarEnchant.effects[1].attribute = tes3.attribute.personality
		nerevarEnchant.effects[1].rangeType = tes3.effectRange.self
		nerevarEnchant.effects[1].min = 30
		nerevarEnchant.effects[1].max = 30

		-- Effect 2: Fortify Mercantile
		nerevarEnchant.effects[2].id = tes3.effect.fortifySkill
		nerevarEnchant.effects[2].skill = tes3.skill.mercantile
		nerevarEnchant.effects[2].rangeType = tes3.effectRange.self
		nerevarEnchant.effects[2].min = 30
		nerevarEnchant.effects[2].max = 30

		-- Effect 3: Fortify Persuasion
		nerevarEnchant.effects[3].id = tes3.effect.fortifySkill
		nerevarEnchant.effects[3].skill = tes3.skill.speechcraft
		nerevarEnchant.effects[3].rangeType = tes3.effectRange.self
		nerevarEnchant.effects[3].min = 30
		nerevarEnchant.effects[3].max = 30

		-- Apply to Moon and Star
		moonStar.enchantment = nerevarEnchant
	
		-- Increased Value
		moonStar.value = 30000
	end
	
	-- Ring of Azura
	local azuraRing = tes3.getObject("ring of azura")
	
	if azuraRing then
		local azuraEnchant = tes3.createObject({
			objectType = tes3.objectType.enchantment,
			id = "OHNI_Azura_Ring_En",
			castType = tes3.enchantmentType.constant
	
		})
	
		-- Effect 1: Restore Fatigue
		azuraEnchant.effects[1].id = tes3.effect.restoreFatigue
		azuraEnchant.effects[1].rangeType = tes3.effectRange.self
		azuraEnchant.effects[1].min = 5
		azuraEnchant.effects[1].max = 5

		-- Effect 2: Detect Enchantment
		azuraEnchant.effects[2].id = tes3.effect.detectEnchantment
		azuraEnchant.effects[2].rangeType = tes3.effectRange.self
		azuraEnchant.effects[2].min = 100
		azuraEnchant.effects[2].max = 100

		-- Effect 3: Detect Key
		azuraEnchant.effects[3].id = tes3.effect.detectKey
		azuraEnchant.effects[3].rangeType = tes3.effectRange.self
		azuraEnchant.effects[3].min = 100
		azuraEnchant.effects[3].max = 100
	
		-- Effect 4: Detect Enemy
		azuraEnchant.effects[4].id = tes3.effect.T_mysticism_DetEnemy
		azuraEnchant.effects[4].rangeType = tes3.effectRange.self
		azuraEnchant.effects[4].min = 100
		azuraEnchant.effects[4].max = 100
		
		-- Effect 5: Detect Humanoid
		azuraEnchant.effects[5].id = tes3.effect.T_mysticism_DetHuman
		azuraEnchant.effects[5].rangeType = tes3.effectRange.self
		azuraEnchant.effects[5].min = 100
		azuraEnchant.effects[5].max = 100

		-- Effect 6: Detect Invisibility
		azuraEnchant.effects[6].id = tes3.effect.T_mysticism_DetInvisibility
		azuraEnchant.effects[6].rangeType = tes3.effectRange.self
		azuraEnchant.effects[6].min = 100
		azuraEnchant.effects[6].max = 100
	
		-- Effect 7: Detect Animal
		azuraEnchant.effects[7].id = tes3.effect.detectAnimal
		azuraEnchant.effects[7].rangeType = tes3.effectRange.self
		azuraEnchant.effects[7].min = 100
		azuraEnchant.effects[7].max = 100
	
		-- Effect 8: Nighteye
		azuraEnchant.effects[8].id = tes3.effect.nightEye
		azuraEnchant.effects[8].rangeType = tes3.effectRange.self
		azuraEnchant.effects[8].min = 50
		azuraEnchant.effects[8].max = 50

		-- Apply to Ring of Azura
		azuraRing.enchantment = azuraEnchant
	
		-- Increased Value
		azuraRing.value = 60000
	end
	
	-- Teeth of the Urshilaku
	local teeth = tes3.getObject("teeth")
	
	if teeth then
		local teethEnchant = tes3.createObject({
			objectType = tes3.objectType.enchantment,
			id = "OHNI_Teeth_En",
			castType = tes3.enchantmentType.constant
	
		})
	
		-- Effect 1: Resist Paralysis
		teethEnchant.effects[1].id = tes3.effect.resistParalysis
		teethEnchant.effects[1].rangeType = tes3.effectRange.self
		teethEnchant.effects[1].min = 100
		teethEnchant.effects[1].max = 100

		-- Effect 2: Reflect Damage
		teethEnchant.effects[2].id = tes3.effect.T_mysticism_ReflectDmg
		teethEnchant.effects[2].rangeType = tes3.effectRange.self
		teethEnchant.effects[2].min = 20
		teethEnchant.effects[2].max = 20

		-- Apply to Teeth of the Urshilaku
		teeth.enchantment = teethEnchant
	
		-- Increased Value
		teeth.value = 5000
	end
	
	-- Thong of the Zainab
	local thong = tes3.getObject("thong")
	
	if thong then
		local thongEnchant = tes3.createObject({
			objectType = tes3.objectType.enchantment,
			id = "OHNI_Thong_En",
			castType = tes3.enchantmentType.onUse,
			chargeCost = 25,
			maxCharge = 200
		})
	
		-- Effect 1: Blink
		thongEnchant.effects[1].id = tes3.effect.T_mysticism_Blink
		thongEnchant.effects[1].rangeType = tes3.effectRange.self
		thongEnchant.effects[1].min = 50
		thongEnchant.effects[1].max = 50

		-- Effect 2: Chameleon
		thongEnchant.effects[2].id = tes3.effect.chameleon
		thongEnchant.effects[2].rangeType = tes3.effectRange.self
		thongEnchant.effects[2].min = 35
		thongEnchant.effects[2].max = 35
		thongEnchant.effects[2].duration = 60

		-- Apply to Thong of the Zainab
		thong.enchantment = thongEnchant
	
		-- Increased Value
		thong.value = 4000
	end
	
	-- Madstone of the Ahemmusa
	local madstone = tes3.getObject("madstone")
	
	if madstone then
		local madstoneEnchant = tes3.createObject({
			objectType = tes3.objectType.enchantment,
			id = "OHNI_Madstone_En",
			castType = tes3.enchantmentType.onUse,
			chargeCost = 200,
			maxCharge = 1000
	
		})
	
		-- Effect 1: Sound Self
		madstoneEnchant.effects[1].id = tes3.effect.sound
		madstoneEnchant.effects[1].rangeType = tes3.effectRange.self
		madstoneEnchant.effects[1].min = 100
		madstoneEnchant.effects[1].max = 100
		madstoneEnchant.effects[1].duration = 60

		-- Effect 2: Sound on Target
		madstoneEnchant.effects[2].id = tes3.effect.sound
		madstoneEnchant.effects[2].rangeType = tes3.effectRange.touch
		madstoneEnchant.effects[2].min = 100
		madstoneEnchant.effects[2].max = 100
		madstoneEnchant.effects[2].duration = 60

		-- Apply to Madstone of the Ahemmusa
		madstone.enchantment = madstoneEnchant
	
		-- Increased Value
		madstone.value = 3000
	end
	
	-- Seizing of the Erabenimsun
	local seizing = tes3.getObject("seizing")
	
	if seizing then
		local seizingEnchant = tes3.createObject({
			objectType = tes3.objectType.enchantment,
			id = "OHNI_Seizing_En",
			castType = tes3.enchantmentType.onUse,
			chargeCost = 80,
			maxCharge = 400
		
		})
	
		-- Effect 1: Telekinesis
		seizingEnchant.effects[1].id = tes3.effect.telekinesis
		seizingEnchant.effects[1].rangeType = tes3.effectRange.self
		seizingEnchant.effects[1].min = 75
		seizingEnchant.effects[1].max = 75
		seizingEnchant.effects[1].duration = 60

		-- Apply to Seizing of the Erabenimsun
		seizing.enchantment = seizingEnchant
	
		-- Increased Value
		seizing.value = 3000
	end
end
event.register("initialized", overhaulHortatorNerevarineItems)