lws.effectType = {
	-- ###
	absorbMagic = 1,
	detectEnchantment = 2,
	feather = 3,
	fortifyAttack = 4,
	fortifyMagicAttributes = 5,
	fortifyMaxMagicka = 6,
	levitate = 7,
	light = 8,
	reflectMagic = 9,
	resistElements = 10,
	resistMagic = 11,
	resistNormalWeapons = 12,
	restoreFatigue = 13,
	restoreHealth = 14,
	restoreMagicka = 15,
	sanctuary = 16,
	shield = 17,
}

--- @alias lws.effectType
--- | 'lws.effectType.absorbMagic'
--- | 'lws.effectType.detectEnchantment'
--- | 'lws.effectType.feather'
--- | 'lws.effectType.fortifyAttack'
--- | 'lws.effectType.fortifyMagicAttributes'
--- | 'lws.effectType.fortifyMaxMagicka'
--- | 'lws.effectType.levitate'
--- | 'lws.effectType.light'
--- | 'lws.effectType.reflectMagic'
--- | 'lws.effectType.resistElements'
--- | 'lws.effectType.resistMagic'
--- | 'lws.effectType.resistNormalWeapons'
--- | 'lws.effectType.restoreFatigue'
--- | 'lws.effectType.restoreHealth'
--- | 'lws.effectType.restoreMagicka'
--- | 'lws.effectType.sanctuary'
--- | 'lws.effectType.shield'

---@type table<lws.effectType, lwsEffectDefinition>
lws.effectDefinitions = {
	-- ###
	[lws.effectType.absorbMagic] = {
		-- ###
		type = lws.effectType.absorbMagic,
		displayName = "Spell Absorption",
		effectInfos = { { type = tes3.effect.absorbMagicka } },
		magnitudes = { 5, 12, 25 },
		availableAtLevel = 7,
	},
	[lws.effectType.detectEnchantment] = {
		-- ###
		type = lws.effectType.detectEnchantment,
		displayName = "Detect Enchantment",
		effectInfos = { { type = tes3.effect.detectEnchantment } },
		magnitudes = { 90, 150, 240 },
		availableAtLevel = 7,
	},
	[lws.effectType.feather] = {
		-- ###
		type = lws.effectType.feather,
		displayName = "Feather",
		effectInfos = { { type = tes3.effect.feather } },
		magnitudes = { 12, 25, 50, 90, 150 },
		availableAtLevel = 0,
	},
	[lws.effectType.fortifyAttack] = {
		-- ###
		type = lws.effectType.fortifyAttack,
		displayName = "Fortify Attack",
		effectInfos = { { type = tes3.effect.fortifyAttack } },
		magnitudes = { 5, 12, 25 },
		availableAtLevel = 10,
	},
	[lws.effectType.fortifyMagicAttributes] = {
		-- ###
		type = lws.effectType.fortifyMagicAttributes,
		displayName = "Fortify Magic-Attributes",
		effectInfos = {
			-- ###
			{ type = tes3.effect.fortifyAttribute, attribute = tes3.attribute.intelligence },
			{ type = tes3.effect.fortifyAttribute, attribute = tes3.attribute.willpower },
		},
		magnitudes = { 5, 12, 25 },
		availableAtLevel = 0,
	},
	[lws.effectType.fortifyMaxMagicka] = {
		-- ###
		type = lws.effectType.fortifyMaxMagicka,
		displayName = "Fortify Maximum Magicka",
		effectInfos = { { type = tes3.effect.fortifyMaximumMagicka } },
		magnitudes = { 3, 5, 12 },
		availableAtLevel = 0,
	},
	[lws.effectType.levitate] = {
		-- ###
		type = lws.effectType.levitate,
		displayName = "Levitate",
		effectInfos = { { type = tes3.effect.levitate } },
		magnitudes = { 25, 50, 90, 150 },
		availableAtLevel = 10,
	},
	[lws.effectType.light] = {
		-- ###
		type = lws.effectType.light,
		displayName = "Light",
		effectInfos = { { type = tes3.effect.light } },
		magnitudes = { 25, 50 },
		availableAtLevel = 0,
	},
	[lws.effectType.reflectMagic] = {
		-- ###
		type = lws.effectType.reflectMagic,
		displayName = "Reflect",
		effectInfos = { { type = tes3.effect.reflect } },
		magnitudes = { 5, 12, 25 },
		availableAtLevel = 7,
	},
	[lws.effectType.resistElements] = {
		-- ###
		type = lws.effectType.resistElements,
		displayName = "Resist Elements",
		effectInfos = {
			-- ###
			{ type = tes3.effect.resistFire },
			{ type = tes3.effect.resistFrost },
			{ type = tes3.effect.resistShock },
		},
		magnitudes = { 5, 12, 25, 50 },
		availableAtLevel = 4,
	},
	[lws.effectType.resistMagic] = {
		-- ###
		type = lws.effectType.resistMagic,
		displayName = "Resist Magicka",
		effectInfos = { { type = tes3.effect.resistMagicka } },
		magnitudes = { 12, 25, 50 },
		availableAtLevel = 4,
	},
	[lws.effectType.resistNormalWeapons] = {
		-- ###
		type = lws.effectType.resistNormalWeapons,
		displayName = "Resist Normal Weapons",
		effectInfos = { { type = tes3.effect.resistNormalWeapons } },
		magnitudes = { 5, 12, 25 },
		availableAtLevel = 7,
	},
	[lws.effectType.restoreFatigue] = {
		-- ###
		type = lws.effectType.restoreFatigue,
		displayName = "Restore Fatigue",
		effectInfos = { { type = tes3.effect.restoreFatigue } },
		magnitudes = { 3, 5, 12 },
		availableAtLevel = 7,
	},
	[lws.effectType.restoreHealth] = {
		-- ###
		type = lws.effectType.restoreHealth,
		displayName = "Restore Health",
		effectInfos = { { type = tes3.effect.restoreHealth } },
		magnitudes = { 2, 3, 5 },
		availableAtLevel = 10,
	},
	[lws.effectType.restoreMagicka] = {
		-- ###
		type = lws.effectType.restoreMagicka,
		displayName = "Restore Magicka",
		effectInfos = { { type = tes3.effect.restoreMagicka } },
		magnitudes = { 1, 2, 3 },
		availableAtLevel = 10,
	},
	[lws.effectType.sanctuary] = {
		-- ###
		type = lws.effectType.sanctuary,
		displayName = "Sanctuary",
		effectInfos = { { type = tes3.effect.sanctuary } },
		magnitudes = { 5, 12, 25 },
		availableAtLevel = 4,
	},
	[lws.effectType.shield] = {
		-- ###
		type = lws.effectType.shield,
		displayName = "Shield",
		effectInfos = { { type = tes3.effect.shield } },
		magnitudes = { 12, 25, 50 },
		availableAtLevel = 4,
	},
}
