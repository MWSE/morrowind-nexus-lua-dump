local author = 'abot'
local modName = 'ELR'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = configName:gsub(' ', '_')
local mcmName = author .. "'s " .. modName

local defaultConfig = {
enabled = true,
logLevel = 0,
preloadLightEffect = function ()
	local path = tes3.installDirectory..'\\Data Files\\Textures\\OJ\\EL\\kurp\\aura16.dds'
	local bad = false
	local size = 100000
	local f = io.open(path, 'rb')
	if f then
		size = f:seek('end')
		if size then
			bad = (size <= 0)
		else
			bad = true
		end
		f:close()
	else
		bad = true
	end
	if bad then
		mwse.log([[%s: error loading "%s", ensure Enhanced Light mod textures are installed correctly.]],
			modPrefix, path)
		return false
	end
	return size < 100000
end

}

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)

local enabled
local logLevel, logLevel1, logLevel2, logLevel3, logLevel4

local function updateFromConfig()
	enabled = config.enabled
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4
end
updateFromConfig()


local elrVFXid = 'ab01elrVFX'

-- set in initialized()
local elrVFX
local elrVFXcast, elrVFXbolt, elrVFXhit
local elrVFXcastSnd, elrVFXboltSnd, elrVFXhitSnd, elrVFXareaSnd

local tes3_effect_light = tes3.effect.light
local tes3_vfxContext_reference = tes3.vfxContext.reference
local tes3_objectType_static = tes3.objectType.static
local tes3_objectType_weapon = tes3.objectType.weapon
local tes3_weaponType_arrow = tes3.weaponType.arrow

local vertOffs = 64 ---48 -- light orb vertical displacement from actor head

-- set in initialized()
---local simulateTimers

local math_floor = math.floor

local centiSecPassedOnLoaded = 0
local function updateCentiSecPassedOnLoaded()
	local worldController = tes3.worldController
	-- local timescale = worldController.timescale.value
	-- if timescale <= 0 then
	-- 	timescale = 1
	-- end
	local daysPassed = worldController.daysPassed.value
	local hour = worldController.hour.value
	local hoursPassed = 24 * daysPassed + hour
	---centiSecPassedOnLoaded = math_floor( hoursPassed * 360000 / timescale + 0.5 )
	centiSecPassedOnLoaded = math_floor( hoursPassed * 360000 + 0.5 )
end

-- to update centiSecPassedOnLoaded once before vfxCreated or similar happens
event.register('cellActivated', function ()
	updateCentiSecPassedOnLoaded()
end, {doOnce = true})

local function loaded() -- registered in initialized()
	updateCentiSecPassedOnLoaded()
end

local simulateTimers

-- mwse.simulateTimers is available since first fadersCreated
event.register('fadersCreated', function ()
	simulateTimers = mwse.simulateTimers
end, {doOnce = true})

local function getSimulatedCentisecPassed()
	return math_floor( simulateTimers.clock * 100 + centiSecPassedOnLoaded + 0.5 )
end

local mountPrefixesDict = {['ab01bo'] = 1, ['ab01ss'] = 2, ['ab01go'] = 3, ['ab01gu'] = 4}

local constantDur = 2^29 -- sec duration for constant light enchantment effect

---@param ref tes3reference
---@param durSec integer
---@param forced boolean?
local function createVisual(ref, durSec, forced)
	local obj = ref.baseObject
	local idPrefix = obj.id:sub(1, 6)
	if mountPrefixesDict[idPrefix] then
		return -- skip scenic travel creatures
	end
	local data = ref.data
	assert(data)
	-- if not data then
	-- 	ref.data = {}
	-- 	data = ref.data
	-- end
	local ab01elr = data.ab01elr
	local now = getSimulatedCentisecPassed()
	if ab01elr
	and (ab01elr > now)
	and (not forced) then
		return
	end
	if not tes3.createVisualEffect({object = elrVFX, reference = ref,
			lifespan = durSec, verticalOffset = vertOffs}) then
		return
	end
	if logLevel1
	and (durSec == constantDur) then
		mwse.log('%s: createVisual("%s", %s) constant dur',
			modPrefix, ref.id, durSec)
	end
	if durSec then
		data.ab01elr = durSec * 100 + now
	end
	ref:updateLighting()
	if not (tes3.player == ref) then
		tes3.player:updateLighting()
	end

	if logLevel1 then
		mwse.log(
'%s: createVisual("%s", %s) now = %s cSec, forced = %s',
			modPrefix, ref.id, durSec, now, forced)
	end
end

local maxLightDur = 0

---@param effects tes3effect[]
local function maxLightDurUpdate(effects)
	local eff, durSec
	for i = 1, #effects do
		eff = effects[i]
		if eff.id == tes3_effect_light then
			durSec = eff.duration
			if durSec
			and (durSec > 0)
			and (durSec > maxLightDur) then
				maxLightDur = durSec
			end
		end
	end
end

local tes3_enchantmentType_constant = tes3.enchantmentType.constant

--[[ not for now
local tes3_magicSourceType_enchantment = tes3.magicSourceType.enchantment
local tes3_magicSourceType_spell = tes3.magicSourceType.spell

local function isConstantEffect(sourceInstance)
	local isConstant = false
	local source = sourceInstance.source
	if source then
		local sourceType = sourceInstance.sourceType
		if sourceType == tes3_magicSourceType_enchantment then
			---@cast source tes3enchantment
			local castType = source.castType
			if castType then
				isConstant = (castType == tes3_enchantmentType_constant)
			end
		elseif sourceType == tes3_magicSourceType_spell then
			---@cast source tes3spell
			isConstant = source.isAbility
				or source.isCurse
		end
	end
	return isConstant
end]]


--- @param e vfxCreatedEventData
local function vfxCreated(e)
	local context = e.context
	if not (context == tes3_vfxContext_reference) then
		return
	end
	local vfx = e.vfx
	local ref = vfx.target
	if not ref then
		return
	end
	local sourceInstance = vfx.sourceInstance
	if not sourceInstance then
		return
	end
	local effObj = vfx.effectObject
	if effObj.id == elrVFXid then
		return -- important! avoid recursion
	end
	local lcEffObjId = effObj.id:lower()
	if lcEffObjId:multifind({'cast', 'hands'}, 1, true) then
		return
	end
	local effects = sourceInstance.sourceEffects
	if not effects then
		return
	end
	local isLight = false
	local eff
	for i = 1, #effects do
		eff = effects[i]
		if eff.id == tes3_effect_light then
			isLight = true
			break
		end
	end
	if not isLight then
		return
	end
	maxLightDur = 0
	--[[ not for now
	local isConstant = isConstantEffect(sourceInstance)
	if isConstant then
		maxLightDur = constantDur
	else
		maxLightDurUpdate(effects)
	end]]
	maxLightDurUpdate(effects)
	if maxLightDur > 0 then
		createVisual(ref, maxLightDur)
	end
end

--- @param activeMagicEffects tes3activeMagicEffect[]
local function maxLightDurUpdate2(activeMagicEffects)
	local eff, durSec
	for i = 1, #activeMagicEffects do
		eff = activeMagicEffects[i]
		if eff.effectId == tes3_effect_light then
			durSec = eff.duration
			if durSec
			and (durSec > 0)
			and (durSec > maxLightDur) then
				maxLightDur = durSec
			end
		end
	end
end

---@param mob tes3mobileActor
---@param forced boolean?
local function checkMobLight(mob, forced)
	local ref = mob.reference
	local data = ref.data
	local ab01elr = data.ab01elr
	local ame = mob:getActiveMagicEffects({effect = tes3_effect_light})
	if #ame <= 0 then
		if ab01elr then
			data.ab01elr = nil
		end
		return
	end
	--- not for now local isConstant
	maxLightDur = 0
	maxLightDurUpdate2(ame)
	if maxLightDur <= 0 then
		if ab01elr then
			data.ab01elr = nil
		end
		return
	end
	local now = getSimulatedCentisecPassed()
	if forced
	and	ab01elr
	and (now >= ab01elr) then
		return
	end
	if maxLightDur > 0 then
		if ab01elr
		and (ab01elr > now) then
			maxLightDur = (ab01elr - now) * 0.01
		end
		createVisual(ref, maxLightDur, forced)
	end
	return maxLightDur >= constantDur
end

-- ---@param mob tes3mobileActor
-- local function checkMobLight2(mob)
	-- local ref = mob.reference
	-- local data = ref.data
	-- local ab01elr = data.ab01elr
	-- if not ab01elr then
		-- return
	-- end
	-- local ame = mob:getActiveMagicEffects({effect = tes3_effect_light})
	-- if #ame <= 0 then
		-- data.ab01elr = nil
	-- end
-- end

--[[
---@param e mobileActivatedEventData
local function mobileActivated(e) -- tes3.mobilePlayer not included
	local mob = e.mobile
	if not mob.actorType then
		return
	end
	checkMobLight(mob, true)
	if logLevel1 then
		local ref = e.reference
		mwse.log('%s: mobileActivated("%s") ab01elr = %s', modPrefix, ref.id, ref.ab01elr)
	end
end

-- EVENT order: 00040 calls 000000000000001 cellActivated
-- EVENT order: 00041 calls 000000000000001 mobileActivated

---@param e mobileDeactivatedEventData
local function mobileDeactivated(e) -- tes3.mobilePlayer not included
	local mob = e.mobile
	if not mob.actorType then
		return
	end
	checkMobLight2(mob)
	if logLevel1 then
		local ref = e.reference
		mwse.log('%s: mobileDeactivated("%s") ab01elr = %s', modPrefix, ref.id, ref.ab01elr)
	end
end

---@param e referenceActivatedEventData
local function referenceActivated(e)
	local ref = e.reference
	local mob = ref.mobile
	if not mob then
		return
	end
	if not mob.actorType then
		return
	end
	checkMobLight(mob, true)
	if logLevel1 then
		mwse.log('%s: referenceActivated("%s") ab01elr = %s', modPrefix, ref.id, ref.ab01elr)
	end
end

-- EVENT order: 00040 calls 000000000000001 cellActivated
-- EVENT order: 00041 calls 000000000000001 mobileActivated

---@param e referenceDeactivatedEventData
local function referenceDeactivated(e)
	local ref = e.reference
	local mob = ref.mobile
	if not mob then
		return
	end
	if not mob.actorType then
		return
	end
	checkMobLight2(mob)
	if logLevel1 then
		mwse.log('%s: referenceDeactivated("%s") ab01elr = %s', modPrefix, ref.id, ref.ab01elr)
	end
end
]]

---@param cell tes3cell
local function checkCellMobLights(cell, forced)
	local mob
	for _, ref in pairs(cell.actors) do -- player not included
		if (not ref.disabled)
		and (not ref.isDead) then
			mob = ref.mobile
			if mob then
				checkMobLight(mob, forced)
			end
		end
	end
end

-- EVENT order: 00069 calls 000000000000001 cellChanged
---@param e cellChangedEventData
local function cellChanged(e)
	local cell = e.cell
	local previousCell = e.previousCell
	local mobilePlayer = tes3.mobilePlayer
	assert(mobilePlayer)
	if not previousCell then -- first time/different character loaded
		checkMobLight(mobilePlayer, true)
		checkCellMobLights(cell, true)
		return
	end
	if cell.isInterior
	or previousCell.isInterior then
		---checkMobLight(mobilePlayer, true)
		checkMobLight(mobilePlayer, true)
		checkCellMobLights(previousCell)
		checkCellMobLights(cell)
	end
end


---@param handle mwseSafeObjectHandle
local function handleToRef(handle)
	if not handle then
		return
	end
	if not handle.valid then
		return
	end
	if not handle:valid() then
		return
	end
	local ref = handle:getObject()
	return ref
end

local function ab01elrPT2(e)
	local timer = e.timer
	local tData = timer.data
	local handle = tData.handle
	local equipped = tData.equipped
	local ref = handleToRef(handle)
	if not ref then
		return
	end
	local mob = ref.mobile
	if not mob then
		return
	end
	if not logLevel3 then
		checkMobLight(mob)
		return
	end

	local forced, eqstr
	if equipped then
		eqstr = 'equipped'
		forced = true
	else
		eqstr = 'unequipped'
	end
	mwse.log('%s: ab01elrPT2("%s") item %s, data.ab01elr = %s',
		modPrefix, ref.id, eqstr, ref.data.ab01elr)
	if checkMobLight(mob, forced) then
		mwse.log('%s: ab01elrPT2("%s") constant light item %s',
			modPrefix, ref.id, eqstr)
	end
end

---@param e equippedEventData|unequippedEventData
---#return ref tes3reference?
local function equippedUnequippedConstRef(e)
	local item = e.item
	local enchantment = item.enchantment
	if not enchantment then
		return
	end
	local castType = enchantment.castType
	if not (castType == tes3_enchantmentType_constant) then
		return
	end
	if not enchantment:hasEffect(tes3_effect_light) then
		return
	end
	local ref = e.reference -- actor reference
	return ref
end

---@param e equippedEventData|unequippedEventData
---@param isEquipped boolean
local function equippedUnequipped(e, isEquipped)
	local ref = equippedUnequippedConstRef(e)
	if not ref then
		return
	end
	timer.start({duration = 1, callback = 'ab01elrPT2',
		data = {handle = tes3.makeSafeObjectHandle(ref), equipped = isEquipped}
	})
end

--- @param e equippedEventData
local function equipped(e)
	equippedUnequipped(e, true)
end

--- @param e unequippedEventData
local function unequipped(e)
	equippedUnequipped(e, false)
end

-- set in initialized()
local ab01elrLight20x60self, ab01elrLight20x10self

local function loadedOnce()
	if not tes3.isCharGenFinished() then
		return
	end
	if logLevel1 then
		local player = tes3.player
		if ab01elrLight20x10self
		and ( not tes3.hasSpell({reference = player, spell = ab01elrLight20x10self}) ) then
			mwse.log('%s: loadedOnce() ab01elrLight20x10self spell added', modPrefix)
			tes3.addSpell({reference = player, spell = ab01elrLight20x10self})
		end
		if ab01elrLight20x60self
		and ( not tes3.hasSpell({reference = player, spell = ab01elrLight20x60self}) ) then
			mwse.log('%s: loadedOnce() ab01elrLight20x60self spell added', modPrefix)
			tes3.addSpell({reference = player, spell = ab01elrLight20x60self})
		end
	end
	event.unregister('loaded', loadedOnce)
end

local function checkRegisterEvents()
	if event.isRegistered('vfxCreated', vfxCreated) then
		if enabled then
			return
		end
		event.unregister('vfxCreated', vfxCreated)
		-- event.unregister('mobileDeactivated', mobileDeactivated)
		-- event.unregister('mobileActivated', mobileActivated)
		-- event.unregister('referenceDeactivated', referenceDeactivated)
		-- event.unregister('referenceActivated', referenceActivated)
		event.unregister('cellChanged', cellChanged)
		event.unregister('equipped', equipped)
		event.unregister('unequipped', unequipped)
		return
	end
	if enabled then
		event.register('vfxCreated', vfxCreated)
		-- event.register('mobileDeactivated', mobileDeactivated)
		-- event.register('mobileActivated', mobileActivated)
		-- event.register('referenceDeactivated', referenceDeactivated)
		-- event.register('referenceActivated', referenceActivated)
		event.register('cellChanged', cellChanged)
		event.register('equipped', equipped)
		event.register('unequipped', unequipped)
	end
end

event.register('initialized', function ()
	local funcPrefix = modPrefix .. ': initialized()'

	local lightEffect = tes3.getMagicEffect(tes3_effect_light)
	if not lightEffect then
		local s = funcPrefix..': Error tes3.effect.light magic effect not found.'
		mwse.log(s)
		tes3.messageBox(s)
		return
	end

	local meshFolder = 'OJ\\EL\\'

	if not tes3.getFileExists('Meshes\\' .. meshFolder .. 'LightAnimated.nif') then
		local s = string.format(
[[%s: Error mesh
"%s"
not found, please reinstall Enhanced Light mod resources]], funcPrefix, meshFolder)
		mwse.log(s)
		tes3.messageBox(s)
		return
	end

	local function createObj(objId, nifName, arrow)
		local obj
		if arrow then
			obj = tes3.createObject({id = elrVFXid .. objId,
			objectType = tes3_objectType_weapon,
			type = tes3_weaponType_arrow,
			mesh = meshFolder .. nifName})
		else
			obj = tes3.createObject({id = elrVFXid .. objId,
			objectType = tes3_objectType_static,
			mesh = meshFolder .. nifName})
		end
		return obj
	end

	elrVFX = createObj('', 'LightAnimated.nif')
	if not elrVFX then
		local s = string.format([[%s: initialized()
unable to create light VFX, mod disabled]], funcPrefix)
		mwse.log(s)
		tes3.messageBox(s)
		return
	end

	elrVFXcast = createObj('Cast', 'LightCast.nif')
	if elrVFXcast then
		lightEffect.castVisualEffect = elrVFXcast
	end
	elrVFXbolt = createObj('Bolt', 'LightProj.nif', true)
	if elrVFXbolt then
		lightEffect.boltVisualEffect = elrVFXbolt
	end
	elrVFXhit = createObj('Hit', 'LightHit.nif')
	if elrVFXhit then
		lightEffect.hitVisualEffect = elrVFXhit
	end

	local function createSnd(objId, sndName)
		local sndFolder = 'OJ\\EL\\'
		local obj = tes3.createObject({id = elrVFXid .. objId,
			objectType = tes3.objectType.sound,
			filename = sndFolder .. sndName})
		return obj
	end

	elrVFXcastSnd = createSnd('CastSnd', 'LightC.wav')
	if elrVFXcastSnd then
		lightEffect.castSoundEffect = elrVFXcastSnd
	end
	elrVFXboltSnd = createSnd('BoltSnd', 'LightT.wav')
	if elrVFXboltSnd then
		lightEffect.boltSoundEffect = elrVFXboltSnd
	end
	elrVFXhitSnd = createSnd('HitSnd', 'LightH.wav')
	if elrVFXhitSnd then
		lightEffect.hitSoundEffect = elrVFXhitSnd
	end
	elrVFXareaSnd = createSnd('AreaSnd', 'LightA.wav')
	if elrVFXareaSnd then
		lightEffect.areaSoundEffect = elrVFXareaSnd
	end

	lightEffect.areaSoundEffect = elrVFXareaSnd

	lightEffect.lightingRed = 231 --1
	lightEffect.lightingGreen = 230 --1
	lightEffect.lightingBlue = 201 --1

	local function createSpell(spellId, spellName, spellEffects)
		return tes3.createObject({objectType = tes3.objectType.spell,
			id = spellId,
			name = spellName,
			castType = tes3.spellType.spell,
			alwaysSucceeds = false,
			sourceLess = true,
			effects = spellEffects,
			modified = true, -- we want to store it if possible
		})
	end

	ab01elrLight20x60self = createSpell('ab01elrLight20x60self',
		'Light 20 60s on self',
		{ {id = tes3.effect.light, min = 20, max = 20, duration = 60,
			rangeType = tes3.effectRange.self, cost = 12, autoCalc = true} }

	)
	if ab01elrLight20x60self then
		ab01elrLight20x60self.modified = true
	else
		mwse.log([[%s: Error creating ab01elrLight20x60self spell.]], funcPrefix)
	end

	ab01elrLight20x10self = createSpell('ab01elrLight20x10self',
		'Light 20 10s on self',
		{ {id = tes3.effect.light, min = 20, max = 20, duration = 10,
			rangeType = tes3.effectRange.self, cost = 2} }
	)
	if ab01elrLight20x10self then
		ab01elrLight20x10self.modified = true
	else
		mwse.log('%s: Error creating ab01elrLight20x10self spell.', funcPrefix)
	end

	---timer.register('ab01elrPT1', ab01elrPT1)
	timer.register('ab01elrPT2', ab01elrPT2)

	event.register('loaded', loaded)
	event.register('loaded', loadedOnce)
	checkRegisterEvents()

	if config.preloadLightEffect then
		local m1 = mwse.getVirtualMemoryUsage()
		for _, v in ipairs({'LightAnimated','LightArea','LightCast','LightHit','LightProj','LightStationary'}) do
			tes3.loadMesh('OJ\\EL\\'..v..'.nif')
		end
		m1 = mwse.getVirtualMemoryUsage() - m1
		mwse.log([[%s: Light spell animation preloaded for faster first cast, cache memory usage = %s]], funcPrefix, m1)
	end

end, {priority = -100, doOnce = true})


local function onClose()
	updateFromConfig()
	mwse.saveConfig(configName, config, {indent = false})
end

local function modConfigReady()
	local template = mwse.mcm.createTemplate({name = mcmName,
		config = config, defaultConfig = defaultConfig,
		showDefaultSetting = true, onClose = onClose})

	local fullName = 'Enhanced Light Redux'

	local sideBarPage = template:createSideBarPage({
		label = fullName, showHeader = true,
		description = fullName .. [[

Pros:
- does not require replacement of standard light effect, avoiding possible crashes and saves corruption related to replacing the vanilla light effect
- simpler code remade from scratch, just adding the pretty animated light orb vfx & sound
- you can uninstall this mod any time without risking crashes due to new light magic effects possibly baked in the save
- the MCM panel "Preload light effect" option + related size-reduced textures loaded should allow to reduce the first casting stutter of the enhanced light spell animation

Cons:
- light is the standard one so not floating around with the Orb VFX. The Orbs float/follow nicely though
- like vanilla, it does not show lights not directly targeted on actors,
but light effects are still applied to any actors (player excluded) in area hit radius
]],
		showReset = true,
		postCreate = function(self)
			-- total width must be 2
			local block = self.elements.sideToSideBlock
			block.children[1].widthProportional = 1.0
			block.children[2].widthProportional = 1.0
		end
	})

	local optionList = {'Off', 'Low', 'Medium', 'High', 'Max'}
	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = ('%s. %s'):format(i - 1, optionList[i]), value = i - 1}
		end
		return options
	end

	sideBarPage:createYesNoButton({
		label = 'Enabled',
		description = [[Enable/disable the mod effects.]],
		configKey = 'enabled'
	})

	sideBarPage:createYesNoButton({
		label = 'Preload light effect',
		description = [[Enable/disable light animation effects preloading.

Pros: should make stutter/delay on first light spell casting not so noticeable

Cons: will use some extra memory, so this is enabled by default only if reduced size textures are installed/detected.]],
		restartRequired = true,
		configKey = 'preloadLightEffect'
	})

	sideBarPage:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		configKey = 'logLevel'
	})

	mwse.mcm.register(template)
end
event.register('modConfigReady', modConfigReady)
