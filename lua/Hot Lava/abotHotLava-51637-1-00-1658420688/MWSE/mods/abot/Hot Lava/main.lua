---@diagnostic disable: deprecated
--[[
Hot Lava
Lava and similar scripted damage sources should use fire damage instead.
More realistic and also a fire atronach will no more die walking in lava.
]]

-- begin configurable parameters
local defaultConfig = {
duration = 4,
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
local logLevel = config.logLevel
local spellDuration = config.duration

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


-- saved in game, but variables will be invalid on reload so set to nil in loaded()
local heatSpell
local heatEffects

local function getHeatSpell(damage)
	local dps = math.round(damage * fps, 1)
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
		mwse.log('%s: getHeatSpell(damage = %s) dps = %s', modPrefix, damage, dps)
	end
	return heatSpell
end

local casters = {}

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

local validHeatSources = {'fire', 'lava', 'steam'}

local function multifind(s)
	local s1 = string.lower(s)
	local s2 = string.multifind(s1, validHeatSources, 1, true)
	return s2
end

local function getCollTypeString(ref)
	local s = multifind(ref.id)
	if s then
		return s
	end
	s = multifind(ref.mesh)
	if s then
		return s
	end
	return nil
end

local tes3_damageSource_script = tes3.damageSource.script

local function deleteRef(ref)
	if mwscript.disable({reference = ref}) then
		if logLevel > 1 then
			mwse.log('%s: reference %s deleted', modPrefix, ref.id)
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
	local mobRefId = mobRef.id:lower()
	local mob = e.mobile

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

	local collType = getCollTypeString(collRef)
	if not collType then
		return
	end

	local casterRef = getCasterRef(mobRef, mobRefId)
	if not casterRef then
		return
	end
	local casterRefId = casterRef.id:lower()

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


local function loaded()
	heatSpell = nil
	heatEffects = nil
	local data = tes3.player.data
	if data then
		casters = data.ab01heatCasters
		if casters then
			local ref
			for _, refId in pairs(casters) do
				ref = tes3.getReference(refId)
				if ref then
					deleteRef(ref)
				end
			end
		end
	end
	casters = {}
end

local function getPackedTable(t)
	local t2 = {}
	for k, v in pairs(t) do
		if v then
			t2[k] = v
		end
	end
	return t2
end

local function save()
	casters = getPackedTable(casters)
	local data = tes3.player.data
	if data then
		data.ab01heatCasters = casters
	end
	mwse.saveConfig(configName, config, {indent = false})
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId, table = config}
end

local function modConfigReady()

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		logLevel = config.logLevel
		spellDuration = config.duration
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
	sidebar:createInfo{text = ""}

	local controls = preferences:createCategory{label = mcmName}

	controls:createInfo({text = [[Lava and similar scripted damage sources should use fire damage instead.
	More realistic and also a fire atronach will no more die walking in lava.]]
	})

	controls:createSlider{
		label = "Fire damage spell duration",
		description = string.format("Duration of fire damage spell, default: %s seconds.", defaultConfig.duration),
		variable = createConfigVariable("duration")
		,min = 3, max = 10, step = 1, jump = 2
	}

	controls:createDropdown{
		label = "Logging level:",
		options = {
			{ label = "0. Off", value = 0 },
			{ label = "1. Low", value = 1 },
			{ label = "2. Medium", value = 2 },
			{ label = "3. High", value = 3 },
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
	event.register('damage', damage)

end
event.register('modConfigReady', modConfigReady)