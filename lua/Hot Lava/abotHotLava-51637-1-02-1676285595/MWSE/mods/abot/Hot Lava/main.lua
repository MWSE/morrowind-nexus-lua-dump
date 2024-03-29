---@diagnostic disable: deprecated
--[[
Hot Lava
Lava and similar scripted damage sources use fire damage instead.
More realistic and also a fire atronach will no more die walking in lava.
Also configurable actors speed factor in lava/heat
]]

-- begin configurable parameters
local defaultConfig = {
duration = 4,
damagePerc = 100,
speedInLavaPerc = 50, -- actors speed percent in lava
hurt2Fire = true, -- enable conversion from normal damage to fire damage
hurtFix = false, -- try and fix HurtStandingActor/HurtCollidingActor
logLevel = 0,
}
-- end configurable parameters

local author = 'abot'
local modName = 'Hot Lava'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)

-- set in modConfigReady too
local spellDuration = config.duration
local damageMul = config.damagePerc * 0.01
local speedInLavaMul = config.speedInLavaPerc * 0.01
local hurt2Fire = config.hurt2Fire
local hurtFix = config.hurtFix
local logLevel = config.logLevel

--[[
local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end
]]

-- set in modConfigReady()
local heatCasterObj

local tes3_objectType_spell = tes3.objectType.spell
local tes3_effect_fireDamage = tes3.effect.fireDamage
local tes3_effectRange_touch = tes3.effectRange.touch

local function roundInt(x)
	return math.floor(x + 0.5)
end

local fps
local minDelta = 0.0001

local function simulate(e)
	local delta = math.abs(e.delta)
	if delta < minDelta then
		delta = minDelta
	end
	fps = 1 / delta
end


local validHeatSources = {'lava', 'fire', 'steam'}

local function getValidHeathSource(s)
	local s1 = string.lower(s)
	local s2 = string.multifind(s1, validHeatSources, 1, true)
	return s2
end

-- saved in game, but variables will be invalid on reload so reset in loaded()
local heatSpell
local heatEffects
local collType


local function getCollTypeString(ref)
	local script = ref.object.script
	if not script then
		return nil
	end
	if not getValidHeathSource(script.id) then
		return nil
	end
	local s = getValidHeathSource(ref.id)
	if s then
		return s
	end
	s = getValidHeathSource(ref.mesh)
	if s then
		return s
	end
	return nil
end

local function getHeatSpell(damage)
	local dps = damage * damageMul * fps
	if heatEffects then
		heatEffects[1].duration = spellDuration
	else
		heatEffects = {{
			id = tes3_effect_fireDamage, rangeType = tes3_effectRange_touch,
			radius = 2, duration = spellDuration,
			min = roundInt(dps * 0.75), max = roundInt(dps * 1.25)
		}}
	end
	if heatSpell then
		local effect = heatSpell.effects[1]
		effect.min = roundInt(dps * 0.75)
		effect.max = roundInt(dps * 1.25)
		return heatSpell
	end
	-- note: createObject will return a previously saved object if found
	heatSpell = tes3.createObject({
		objectType = tes3_objectType_spell,
		id = 'ab01heatSpell',
		name = 'Severe Heat',
		castType = tes3.spellType.spell,
		sourceLess = true,
		effects = heatEffects,
		---alwaysSucceeds = true,
	})
	if logLevel > 0 then
		mwse.log('%s: getHeatSpell(damage = %s) dps = %s', modPrefix, damage, roundInt(dps))
	end
	return heatSpell
end

local casters = {}

local function getPackedTable(t)
	local t2 = {}
	for k, v in pairs(t) do
		if v then
			t2[k] = v
			t[k] = nil
		end
	end
	return t2
end

local function getCasterRef(mobRef, mobRefId)
	local casterRefId = casters[mobRefId]
	local casterRef
	if casterRefId then
		casterRef = tes3.getReference(casterRefId)
	end
	local pos = mobRef.position:copy()
	pos.z = pos.z + 64
	if casterRef then
		casterRef.position = pos
		return casterRef
	end
	casterRef = tes3.createReference({
		object = heatCasterObj,
		position = pos,
		orientation = {0, 0, 0},
		cell = mobRef.cell
	})
	casterRef.modified = false
	return casterRef
end

local tes3_damageSource_script = tes3.damageSource.script
local tes3_objectType_activator = tes3.objectType.activator

-- reset in loaded()
local skip = {}
local lastTarget, lastMobRef

local function collision(e)
	local targetRef = e.target
	if not targetRef then
		return -- it happens
	end
	local targetObj = targetRef.object
	if not (targetObj.objectType == tes3_objectType_activator) then
		return
	end
	local mobRef = e.reference
	if skip[mobRef.id] == targetRef.id then
		return
	end

	collType = getCollTypeString(targetRef)
	if not collType then
		return
	end

	local doLog = logLevel > 3
	if targetRef == lastTarget then
		if mobRef == lastMobRef then
			doLog = false
		else
			lastMobRef = mobRef
		end
	else
		lastTarget = targetRef
	end

	---local mob = e.mobile

	if doLog then
		mwse.log('%s: %s collision({mobRef = "%s", targetRef = "%s", targetRef.object.mesh = "%s"',
			modPrefix, collType, mobRef.id, targetRef.id, targetObj.mesh)
	end

	skip[mobRef.id] = targetRef.id
	local refHandle = tes3.makeSafeObjectHandle(mobRef)

	timer.start({duration = 1, callback =
		function ()
			if not refHandle then
				return
			end
			if not refHandle:valid() then
				return
			end
			local r = refHandle:getObject()
			if not r then
				return
			end
			skip[r.id] = nil
			event.trigger('damage',{source = tes3_damageSource_script,
				reference = r, mobile = r.mobile, damage = 20,}
			)
		end
	})
end

local function deleteRef(ref)
	if mwscript.disable({reference = ref}) then
		if logLevel > 1 then
			mwse.log('%s: reference "%s deleted', modPrefix, ref.id)
		end
		ref.position.z = ref.position.z + 12288
		mwscript.setDelete({reference = ref})
	end
end


local function damage(e)
	if not (e.source == tes3_damageSource_script) then
		return
	end
	local mobRef = e.reference
	local mobRefId = string.lower(mobRef.id)
	local mob = e.mobile
	if not mob then
		return
	end

	if logLevel > 3 then
		mwse.log('%s: damage() mobRefId = %s', modPrefix, mobRefId)
	end

	local collRef = mob.collidingReference
	if not collRef then
		return
	end

	if logLevel > 3 then
		mwse.log('%s: damage() collRef = %s', modPrefix, collRef)
	end

	collType = getCollTypeString(collRef)
	if not collType then
		return
	end

	local casterRef = getCasterRef(mobRef, mobRefId)
	if not casterRef then
		return
	end
	local casterRefId = string.lower(casterRef.id)

	if logLevel > 3 then
		mwse.log('%s: damage() casterRefId = %s', modPrefix, casterRefId)
	end

	if getHeatSpell(e.damage) then
		e.damage = 0
	else
		return
	end

	if tes3ui.menuMode() then
		-- should not happen
		if logLevel > 2 then
			mwse.log('%s: tes3ui.menuMode(), skipping', modPrefix)
		end
		return
	end

	if casters[mobRefId] then
		return
	end
	casters[mobRefId] = casterRefId

	local refHandle = tes3.makeSafeObjectHandle(casterRef)
	timer.start({duration = spellDuration + 3, callback =
		function ()
			casters[mobRefId] = nil
			if not refHandle then
				return
			end
			if not refHandle:valid() then
				return
			end
			local ref = refHandle:getObject()
			if not ref then
				return
			end
			deleteRef(ref)
		end
	})

	if logLevel > 1 then
		mwse.log('%s: collType = %s, caster = %s, target = %s, spell = %s', modPrefix, collType, casterRef, mobRefId, heatSpell)
	end

	mwscript.explodeSpell({reference = casterRef, spell = heatSpell})
end


local function calcMoveSpeed(e)
	if not collType then
		return
	end
	if not (collType == 'lava') then
		return
	end
	if math.isclose(speedInLavaMul, 1, 0.001) then
		return
	end
	local refId = string.lower(e.reference.id)
	if not casters[refId] then
		return
	end
	e.speed = e.speed * speedInLavaMul
end


local function loaded()
	for k, v in pairs(skip) do
		if v then
			skip[k] = nil
		end
	end
	skip = {}
	lastTarget = nil
	lastMobRef = nil
	heatSpell = nil
	heatEffects = nil
	collType = nil
	local data = tes3.player.data
	if data then
		casters = data.ab01heatCasters
		if casters then
			local ref
			for k, refId in pairs(casters) do
				if refId then
					ref = tes3.getReference(refId)
					if ref then
						deleteRef(ref)
					end
					casters[k] = nil
				end
			end
		end
	end
	casters = {}
end


local function save()
	casters = getPackedTable(casters)
	local data = tes3.player.data
	if data then
		data.ab01heatCasters = casters
	end
end


local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId, table = config}
end

local function updateCollisionRegistration()
	if event.isRegistered('collision', collision) then
		if not hurtFix then
			event.unregister('collision', collision)
		end
	elseif hurtFix then
		event.register('collision', collision)
	end
end

local function updateDamageRegistration()
	if event.isRegistered('damage', damage) then
		if not hurt2Fire then
			event.unregister('damage', damage)
		end
	elseif hurt2Fire then
		event.register('damage', damage)
	end
end

local yesOrNo = {[false] = 'No', [true] = 'Yes'}

local function modConfigReady()

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		spellDuration = config.duration
		damageMul = config.damagePerc * 0.01
		speedInLavaMul = config.speedInLavaPerc * 0.01
		if not (hurt2Fire == config.hurt2Fire) then
			hurt2Fire = config.hurt2Fire
			updateDamageRegistration()
		end
		if not (hurtFix == config.hurtFix) then
			hurtFix = config.hurtFix
			updateCollisionRegistration()
		end
		logLevel = config.logLevel
		mwse.saveConfig(configName, config, {indent = false})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage{
		label="Info",
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	}

	local sidebar = preferences.sidebar
	sidebar:createInfo({text = [[Lava and similar scripted damage sources should use fire damage instead.
More realistic and also a fire atronach will no more die walking in lava.
Also configurable actors speed factor in lava/heat.]]
	})

	---local controls = preferences:createCategory{label = mcmName}
	local controls = preferences:createCategory({})

	controls:createSlider{
		label = "Fire damage spell duration",
		description = string.format("Duration of fire damage spell, default: %s seconds.", defaultConfig.duration),
		variable = createConfigVariable("duration")
		,min = 3, max = 10, step = 1, jump = 2
	}

	controls:createSlider{
		label = "Fire damage multiplier %s%%",
		description = string.format("Fire damage percent multiplier, default: %s%%.", defaultConfig.damagePerc),
		variable = createConfigVariable("damagePerc")
		,min = 1, max = 300, step = 1, jump = 5
	}

	controls:createSlider{
		label = "Actors speed in lava (%s%%)",
		description = string.format("Actors speed percent in lava (default: %s%%)", defaultConfig.speedInLavaPerc),
		variable = createConfigVariable("speedInLavaPerc")
		,min = 10, max = 100, step = 1, jump = 5
	}

	controls:createYesNoButton{
		label = 'Fire Damage',
		description = string.format([[Default: %s.
Enable conversion from normal damage to fire damage.
]], yesOrNo[defaultConfig.hurt2Fire]),
		variable = createConfigVariable('hurt2Fire')
	}

	controls:createYesNoButton{
		label = 'Hurt fix',
		description = string.format([[Default: %s.
Try and fix HurtStandingActor/HurtCollidingActor vanilla scripting functions not working as expected with certain meshes.
Use it e.g. if lava does not seem to hurt.
]], yesOrNo[defaultConfig.hurtFix]),
		variable = createConfigVariable('hurtFix')
	}

	controls:createDropdown{
		label = "Logging level:",
		options = {
			{ label = "0. Off", value = 0 },
			{ label = "1. Low", value = 1 },
			{ label = "2. Medium", value = 2 },
			{ label = "3. High", value = 3 },
			{ label = "4. Max", value = 4 },
		},
		variable = createConfigVariable("logLevel"),
		description = [[Logging level. Default: 0. Off.]]
	}

	mwse.mcm.register(template)

	heatCasterObj = tes3.createObject({
		objectType = tes3.objectType.static,
		id = 'ab01heatCasterObj',
		mesh = 'e\\magic_hit_dst.nif',
		sourceless = true,
	})
	---assert(heatCasterObj)

	event.register('loaded', loaded)
	event.register('save', save)
	event.register('simulate', simulate)
	event.register('calcMoveSpeed', calcMoveSpeed)
	updateDamageRegistration()
	updateCollisionRegistration()
end
event.register('modConfigReady', modConfigReady)