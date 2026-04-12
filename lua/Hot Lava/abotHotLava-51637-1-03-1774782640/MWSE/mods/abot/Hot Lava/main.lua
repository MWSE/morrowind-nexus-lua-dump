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
toggleHaze = true,
logLevel = 0,
}
-- end configurable parameters

local author = 'abot'
local modName = 'Hot Lava'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = configName:gsub(' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)

local spellDuration, damageMul, speedInLavaMul, hurt2Fire, hurtFix, toggleHaze
local logLevel, logLevel1, logLevel2, logLevel3, logLevel4

local function updateFromConfig()
	spellDuration = config.duration
	damageMul = config.damagePerc * 0.01
	speedInLavaMul = config.speedInLavaPerc * 0.01
	logLevel = config.logLevel
	toggleHaze = config.toggleHaze
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4
end
updateFromConfig()
hurt2Fire = config.hurt2Fire
hurtFix = config.hurtFix

--[[
local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end
]]


-- set in modConfigReady()
local heatCasterObj
local hazeShader ---@type mgeShaderHandle|nil

local tes3_objectType_spell = tes3.objectType.spell
local tes3_effect_fireDamage = tes3.effect.fireDamage
local tes3_effectRange_touch = tes3.effectRange.touch

local function roundInt(x)
	return math.floor(x + 0.5)
end

local fps = 1

local function simulate(e)
	local secondsPassed = math.max( 0.0001, math.abs(e.delta) )
	fps = math.max(1 / secondsPassed, 7)
end

local validHeatSources = {'lava','fire','steam','magma'}

local function getValidHeatSource(s)
	return s:lower():multifind(validHeatSources, 1, true)
end

-- saved in game, but variables will be invalid on reload so reset in loaded()
local heatSpell
local heatEffects
local collType

local function getCollTypeString(ref)
	local script = ref.object.script
	if not script then
		return
	end
	if not getValidHeatSource(script.id) then
		return
	end
	local s = getValidHeatSource(ref.id)
	if s then
		return s
	end
	s = getValidHeatSource(ref.mesh)
	if s then
		return s
	end
end

local tes3_spellType_spell = tes3.spellType.spell

local function getHeatSpell(damage)
	local dps = math.abs(damage) * damageMul * fps
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
		castType = tes3_spellType_spell,
		sourceLess = true,
		effects = heatEffects,
		---alwaysSucceeds = true,
	})
	if logLevel1 then
		mwse.log('%s: getHeatSpell(damage = %s) dps = %s', modPrefix, damage, roundInt(dps))
	end
	return heatSpell
end

local casters = {}

local tes3_damageSource_script = tes3.damageSource.script
local tes3_objectType_activator = tes3.objectType.activator

-- reset in loaded()
local skip = {}
local lastTarget, lastMobRef


local actorRefs = {}

--- @param e objectInvalidatedEventData
local function objectInvalidated(e)
	if not (type(e.object) == 'userdata') then
		return -- bah hopefully this will be enough to skip weird data
	end
	local obj = e.object -- should be a tes3baseObject or a tes3reference
	if not obj then
		return
	end
	local id = obj.id
	if not id then
		return
	end
	local lcObjId = id:lower()
	if actorRefs[lcObjId] then
		actorRefs[lcObjId] = nil
	end
end

--set in initialized()
local worldController

local function getActorRef(lcRefId)
	local ref = actorRefs[lcRefId]
	if ref
	and (not ref.disabled)
	and (not ref.deleted) then
		return ref
	end
	local allMobileActors = worldController.allMobileActors
	local mob
	for i = 1, #allMobileActors do
		mob = allMobileActors[i]
		ref = mob.reference
		if ref
		and (not ref.disabled)
		and (not ref.deleted)
		and (ref.id:lower() == lcRefId) then
			actorRefs[lcRefId] = ref
			return ref
		end
	end
	ref = tes3.getReference(lcRefId)
	if ref
	and (not ref.disabled)
	and (not ref.deleted) then
		actorRefs[lcRefId] = ref
		return ref
	end
end

local function getCasterObjRef(mobRef, lcMobRefId)
	local casterObjRefId = casters[lcMobRefId]
	local casterObjRef
	if casterObjRefId then
		casterObjRef = getActorRef(casterObjRefId)
	end
	local pos = mobRef.position:copy()
	pos.z = pos.z + 64
	if casterObjRef then
		local to = casterObjRef.position
		to.x, to.y, to.z = pos.x, pos.y, pos.z
		return casterObjRef
	end
	casterObjRef = tes3.createReference({
		object = heatCasterObj,
		position = pos,
		orientation = {0, 0, 0},
		cell = mobRef.cell
	})
	casterObjRef.modified = false
	return casterObjRef
end

local function collDamage(e)
	local timer = e.timer
	local data = timer.data
	local lcMobRefId = data.lcRefId
	local ref = getActorRef(lcMobRefId)
	skip[lcMobRefId] = nil
	if not ref then
		return
	end
	if logLevel4 then
		mwse.log('%s: collDamage("%s")', modPrefix, ref.id)
	end
	event.trigger('damage',{source = tes3_damageSource_script,
		reference = ref, mobile = ref.mobile, damage = 20}
	)
end

local function collision(e)
	local targetRef = e.target
	if not targetRef then
		return -- it happens
	end
	if not e.mobile.actorType then
		return -- only interested in mobile actors
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

	local logOnce = logLevel3
	if targetRef == lastTarget then
		if mobRef == lastMobRef then
			logOnce = false
		else
			lastMobRef = mobRef
		end
	else
		lastTarget = targetRef
	end

	---local mob = e.mobile

	local lcMobRefId = mobRef.id

	if logOnce then
		mwse.log('%s: %s collision({mobRef = "%s", targetRef = "%s", targetRef.object.mesh = "%s"',
			modPrefix, collType, lcMobRefId, targetRef.id, targetObj.mesh)
	end
	skip[lcMobRefId] = targetRef.id
	-- probably not worth a persistent timer
	timer.start({ duration = 1, data = {lcRefId = lcMobRefId}, callback = collDamage })
end


---@param ref tes3reference
local function deleteRef(ref)
	if ref:disable() then
---@diagnostic disable-next-line: deprecated
	---if mwscript.disable({reference = ref, modify = true}) then
		if logLevel2 then
			mwse.log('%s: reference "%s deleted', modPrefix, ref.id)
		end
		---tes3.removeSound({reference = ref})
		ref.position.z = ref.position.z + 12288
		ref:delete()
---@diagnostic disable-next-line: deprecated
		---mwscript.setDelete({reference = ref, delete = true})
	end
end

local tes3_animationState_dying = tes3.animationState.dying
local tes3_animationState_dead = tes3.animationState.dead

local function isDead(mob)
	local result = false
	if mob.isDead then
		result = true
	else
		local actionData = mob.actionData
		if actionData then
			local animState = actionData.animationAttackState
			if animState then
				if (animState == tes3_animationState_dying)
				or (animState == tes3_animationState_dead) then
					result = true
				end
			end
		end
	end
	-- as we are here fix health glitches
	local health = mob.health
	if health then
		local health_current = health.current
		if not health_current then
			return result
		end
		if result then
			if health_current > 0 then
				health.current = 0
			end
		else
			if (health.normalized <= 0.025) -- health ratio <= 2.5%
			and (health_current > 0)
			and (health_current < 3)
			and (health.normalized > 0) then
				health.current = 0 -- kill when nearly dead, could be a glitch
				result = true
			end
		end
	end
	return result
end

local hazeShaderOn = false

local function damage(e)
	if not (e.source == tes3_damageSource_script) then
		return
	end
	local mob = e.mobile
	if not mob then
		return
	end
	if isDead(mob) then
		return
	end
	local mobRef = e.reference
	local lcMobRefId = mobRef.id:lower()

	if logLevel4 then
		mwse.log('%s: damage() lcMobRefId = %s', modPrefix, lcMobRefId)
	end

	local collRef = mob.collidingReference
	if not collRef then
		return
	end

	if logLevel4 then
		mwse.log('%s: damage() collRef = %s', modPrefix, collRef)
	end

	collType = getCollTypeString(collRef)
	if not collType then
		return
	end

	local casterObjRef = getCasterObjRef(mobRef, lcMobRefId)
	if not casterObjRef then
		return
	end
	local casterObjRefId = casterObjRef.id:lower()

	if logLevel4 then
		mwse.log('%s: damage() casterObjRefId = %s', modPrefix, casterObjRefId)
	end

    local dmg = e.damage
    if dmg == 0 then
        return
    end

    if getHeatSpell(dmg) then
        if dmg < 0 then
            -- e.damage = 0 could not work when e.damage is negative
		    local health = mob.health
			health.current = health.current - dmg
        end
		e.damage = 0
	else
		return
	end

	if tes3ui.menuMode() then
		-- should not happen
		if logLevel3 then
			mwse.log('%s: tes3ui.menuMode(), skipping', modPrefix)
		end
		return
	end

	if casters[lcMobRefId] then
		return
	end
	casters[lcMobRefId] = casterObjRefId

	timer.start({duration = spellDuration + 3, callback =
		function ()
			local ref = getActorRef(casterObjRefId)
			casters[lcMobRefId] = nil
			if not ref then
				return
			end
			deleteRef(ref)

			if hazeShader
			and toggleHaze
			and hazeShaderOn then
				if logLevel1 then
					mwse.log('%s: haze shader disabled', modPrefix)
				end	
				hazeShaderOn = false
				hazeShader.enabled = false
			end
		end
	})

	if logLevel2 then
		mwse.log('%s: collType = %s, caster = %s, target = %s, spell = %s', modPrefix, collType, casterObjRef, lcMobRefId, heatSpell)
	end
	---mwscript.explodeSpell({reference = casterObjRef, spell = heatSpell})
    tes3.cast({target = casterObjRef, reference = casterObjRef, spell = heatSpell})


	if hazeShader
	and toggleHaze
	and (not hazeShaderOn)
	and (mobRef == tes3.player) then
		if logLevel1 then
			mwse.log('%s: haze shader enabled', modPrefix)
		end	
		hazeShaderOn = true
		hazeShader.enabled = true
	end
	
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
	local ref = e.reference
	if not ref then
		return
	end
	local lcRefId = ref.id:lower()
	if not casters[lcRefId] then
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
	
	assert(tes3.worldController == worldController)
	
	local data = tes3.player.data
	if data then
		casters = data.ab01heatCasters
		if casters then
			for k, refId in pairs(casters) do
				if refId then
					local ref = getActorRef(refId)
					if ref then
						deleteRef(ref)
					end
					casters[k] = nil
				end
			end
		end
	end
	casters = {}
	if not event.isRegistered('simulate', simulate) then
		event.register('simulate', simulate)
	end
end


local function save()
	for k in pairs(casters) do
		casters[k] = nil
	end
	casters = {}
	local data = tes3.player.data
	if data then
		data.ab01heatCasters = casters
	end
end


local collisionRegistered = false
local function updateCollisionRegistration()
	if collisionRegistered then
		if not hurtFix then
			collisionRegistered = false
			event.unregister('collision', collision)
		end
	elseif hurtFix then
		collisionRegistered = true
		event.register('collision', collision)
	end
end

local damageRegistered = false
local function updateDamageRegistration()
	if damageRegistered then
		if not hurt2Fire then
			damageRegistered = false
			event.unregister('damage', damage)
		end
	elseif hurt2Fire then
		damageRegistered = true
		event.register('damage', damage)
	end
end

local function onClose()
	updateFromConfig()
	if not (hurt2Fire == config.hurt2Fire) then
		hurt2Fire = config.hurt2Fire
		updateDamageRegistration()
	end
	if not (hurtFix == config.hurtFix) then
		hurtFix = config.hurtFix
		updateCollisionRegistration()
	end
	mwse.saveConfig(configName, config, {indent = false})
end

local function modConfigReady()

	local template = mwse.mcm.createTemplate({name = mcmName,
		config = config, defaultConfig = defaultConfig,
		showDefaultSetting = true, onClose = onClose})
		
	local sideBarPage = template:createSideBarPage({
		label = modName,
		showHeader = false,
		description = [[Lava and similar scripted damage sources should use fire damage instead.
More realistic and also a fire atronach will no more die walking in lava.
Also configurable actors speed factor in lava/heat.]],
		showReset = true,
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	})

	sideBarPage:createSlider({
		label = "Fire damage spell duration",
		description = "Duration of fire damage spell",
		configKey = 'duration'
		,min = 3, max = 10, step = 1, jump = 2
	})

	sideBarPage:createSlider({
		label = "Fire damage multiplier %s%%",
		description = "Fire damage percent multiplier.",
		configKey = 'damagePerc'
		,min = 1, max = 300, step = 1, jump = 5
	})

	sideBarPage:createSlider({
		label = "Actors speed in lava (%s%%)",
		description = "Actors speed percent in lava",
		configKey = 'speedInLavaPerc'
		,min = 10, max = 100, step = 1, jump = 5
	})

	sideBarPage:createYesNoButton({
		label = 'Fire Damage',
		description = "Enable conversion from normal damage to fire damage.",
		configKey = 'hurt2Fire'
	})

	sideBarPage:createYesNoButton({
		label = 'Hurt fix',
		description = [[Try and fix HurtStandingActor/HurtCollidingActor vanilla scripting functions not working as expected with certain meshes.
Use it e.g. if lava does not seem to hurt.]],
		configKey = 'hurtFix'
	})

	sideBarPage:createYesNoButton({
		label = 'Toggle Haze shader',
		description = [[Toggle a detected Haze shader according to player being on lava.]],
		configKey = 'toggleHaze'
	})

	local optionList = {'Off','Low','Medium','High','Max'}

	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = ('%s. %s'):format(i - 1, optionList[i]), value = i - 1}
		end
		return options
	end

	sideBarPage:createDropdown({
		label = 'Logging level:',
		options = getOptions(),
		configKey = 'logLevel'
	})

	mwse.mcm.register(template)

	heatCasterObj = tes3.createObject({
		objectType = tes3.objectType.static,
		id = 'ab01heatCasterObj',
		--- nope mesh = 'e\\magic_hit_dst.nif',
		mesh = 'c\\c_ring_common02.nif',
		sourceless = true,
	})
	---assert(heatCasterObj)

	event.register('objectInvalidated', objectInvalidated)

end
event.register('modConfigReady', modConfigReady)

event.register('initialized', function ()
	worldController = tes3.worldController
	event.register('loaded', loaded)
	event.register('save', save)
	event.register('calcMoveSpeed', calcMoveSpeed)
	updateCollisionRegistration()
	updateDamageRegistration()
	hazeShader = mge.shaders.load({name = 'heathaze'})
	if hazeShader
	and toggleHaze then
		hazeShader.enabled = false
	end
end, {doOnce = true})
