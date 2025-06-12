if require('openmw.core').API_REVISION < 64 then
    error('This mod requires a newer version of OpenMW, please update.')
end

--local ui = require('openmw.ui')
local core = require('openmw.core')
local world = require('openmw.world')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local time = require('openmw_aux.time')
local storage = require('openmw.storage')
local crimes = require('openmw.interfaces').Crimes
local async = require('openmw.async')

local inventoryPotion = nil
local armingButtonHeld = false
local drinkingButtonHold = false

local skipArming = false
local forceEquip = false

local modEnabled = true

local objectsToRemove = {}

I.Settings.registerGroup {
    key = 'SettingsPotionThrowerGameplay',
    page = 'PotionThrower',
    l10n = 'PotionThrower',
    name = 'Gameplay',
    --description = 'Potion Thrower gameplay settings.',
    permanentStorage = false,
    settings = {
        {
            key = 'EquipMode',
            renderer = 'select',
            name = 'Default Potion Action',
            --description = 'How to equip throwable potions.\n\nToggle = Hold the weapon toggle key while using a potion to equip it as throwable.\n\nPurist = Always equip potions when using them. The only way to drink a potion in this mode is holding it by holding ToggleSpell then drinking the potion, or tossing it on yourself.\n\nPrompt = Gives a UI prompt when using a potion on whether to drink it or equip it.',
            description = 'Default action when using a potion. You can always hold ToggleWeapon to equip a potion when using it, or ToggleSpell to drink it.\n\nDrink: Like vanilla, using a potion consumes it. Hold ToggleWeapon to equip it instead.\n\nEquip = Using a potion equips it into your potion slot for throwing or consuming. The only way to drink a potion in this mode is by holding ToggleSpell then drinking the potion, or tossing it on yourself.\n\nPrompt = Gives a UI prompt when using a potion on whether to drink it or equip it.\n\nDynamic = On use, a potion with only negative effects will be equipped for throwing, while potions with positive effects will be consumed.',
	    argument = {
		disabled = false,
        	l10n = "PotionThrower", 
	    	items = { 'drink', 'equip', 'prompt', 'dynamic' },
            },
	    default = 'dynamic'
        },
        {
            key = 'LuaPhysics',
            renderer = 'checkbox',
            name = 'MaxYari\'s LuaPhysics Engine',
            --description = 'How to equip throwable potions.\n\nToggle = Hold the weapon toggle key while using a potion to equip it as throwable.\n\nPurist = Always equip potions when using them. The only way to drink a potion in this mode is holding it by holding ToggleSpell then drinking the potion, or tossing it on yourself.\n\nPrompt = Gives a UI prompt when using a potion on whether to drink it or equip it.',
            description = 'Enable to use MaxYari\'s LuaPhysics for thrown potions (LuaPhysicsEngine.omwscripts needs to be enabled in your mod order before Potion Thrower). If this is disabled or LuaPhysics is not installed, falls back to Potion Thrower\'s simpler physics.',
	    default = true
        },
        {
            key = 'Skill',
            renderer = 'select',
            name = 'Governing Skill',
            description = 'Which skill is used to determine successful hits with a thrown potion. Marksman is recommended for a more balanced experience.',
	    argument = {
		disabled = false,
        	l10n = "PotionThrower", 
	    	items = { 'marksman', 'alchemy' },
            },
	    default = 'marksman'
        },
        {
            key = 'XPGain',
            renderer = 'checkbox',
            name = 'XP Gain',
            description = 'Whether to gain XP from thrown potions. XP gained is applied to your configured governing skill. You may want to disable this if you\'re using leveling mods such as NCGDMW as they are incompatable with other mods using the lua SkillProgression interface.',
	    default = true
        },
        {
            key = 'Handicap',
            renderer = 'number',
            name = 'Handicap',
            description = 'Flat value added or subtracted from your odds of hitting enemies with a thrown potion. Useful if you want to play around with the mod but your skills are low, or if you want to give yourself an extra challenge for whatever reason.',
	    default = 0
        },
    },
}

I.Settings.registerGroup {
    key = 'SettingsPotionThrowerTweaks',
    page = 'PotionThrower',
    l10n = 'PotionThrower',
    name = 'Tweaks',
    description = 'Tweak throw potion initial physics to get it feeling correct for your playstyle.',
    permanentStorage = false,
    settings = {
        {
            key = 'BaseSpeed',
            renderer = 'number',
            name = 'Base Speed',
            description = 'Initial speed of a potion being tossed.',
	    default = 30
        },
        {
            key = 'StrengthFactor',
            renderer = 'number',
            name = 'Strength Factor',
            description = 'How much your strength attribute factors into a charged potion toss.',
	    default = 1
        },
        {
            key = 'ArcFactor',
            renderer = 'number',
            name = 'Arc Amount',
            description = 'How much initial upward velocity a tossed potion has. Set to 0 to have no arc on a toss.',
	    default = 20
        },
        {
            key = 'InitialHeight',
            renderer = 'number',
            name = 'Initial Height',
            description = 'Determines the height on a player from which a thrown potion originates.',
	    default = 105
        },
    },
}


local settings = storage.globalSection('SettingsPotionThrowerGameplay')
local playerSettings = storage.globalSection('SettingsPotionThrower')
local tweakSettings = storage.globalSection('SettingsPotionThrowerTweaks')

local function decrementPotion(data)
	if inventoryPotion ~= nil then
		inventoryPotion:remove(1)
		if inventoryPotion.count == 0 then
			inventoryPotion = nil
		else
			data.player:sendEvent('RefreshUI', { count = inventoryPotion.count } )
		end
	elseif data.recordId ~= nil then
		local tempPotion = types.Actor.inventory(data.player):find(data.recordId)
		tempPotion:remove(1)
	end
end

local function enableArming(data)
	armingButtonHeld = data.armingButtonHeld
end

local function enableDrinking(data)
	drinkingButtonHeld = data.drinkingButtonHeld
end

-- Override Use action (global script).
I.ItemUsage.addHandlerForType(types.Potion, function(potion, actor)

	if not types.Player.objectIsInstance(actor) then return end
	if not modEnabled then return end
	if settings:get('EquipMode') == 'drink' and not armingButtonHeld then return end

	if skipArming or drinkingButtonHeld then
		skipArming = false
		return
	end
	
	local hasPositiveEffects = false
	for index, effect in pairs(types.Potion.record(potion.recordId).effects) do
		if not effect.effect.harmful then
			hasPositiveEffects = true
		end
	end

	if settings:get('EquipMode') == 'dynamic' and hasPositiveEffects and not armingButtonHeld then
		-- drink a potion with positive effects when EquipMode is "dynamic"
		return
	end

	local count = potion.count

	-- remove stack from mouse by removing and re-adding stack to inventory
	potion:remove(count)
	local pendingPotion = world.createObject(potion.recordId, count)
	pendingPotion:moveInto(types.Actor.inventory(actor))

	if settings:get('EquipMode') == 'prompt' and not forceEquip and not armingButtonHeld then
		actor:sendEvent('PromptForAction', { recordId = potion.recordId })
		return false
	end

	forceEquip = false

	if inventoryPotion ~= nil and inventoryPotion.recordId == potion.recordId then
		-- clear potion
		inventoryPotion = nil
		actor:sendEvent('PotionArmed', {potion=nil})
		return false
	else
		inventoryPotion = pendingPotion
		actor:sendEvent('PotionArmed', {potion=potion.recordId})
	end

	--[[
	-- previouslyEquipped = types.Actor.getEquipment(actor, types.Actor.EQUIPMENT_SLOT.CarriedRight)
	if types.Weapon.objectIsInstance(previouslyEquipped) then
		local weaponRecord = types.Weapon.record(previouslyEquipped)
		print(string.format("Player is holding %s", weaponRecord))
	end

	-- actor:sendEvent('PotionArmed', {potion=potion, throwable=nil})

	local potionRecord = types.Potion.record(potion)

	-- create a thrown weapon record for this potion
	print(string.format("Size of weapon table before is %s", #types.Weapon.records))

	-- local thrownCopy = types.Weapon.records["iron throwing knife"]
	-- local thrownCopy = types.Armor.records["iron_shield"]

	local thrownPotionTable = {
		name = string.format('Throwable %s', potionRecord.name),
		template = thrownCopy,
		icon = potionRecord.icon,
		model = potionRecord.model,
		-- type = types.Armor.TYPE.Shield
	}

	local newRecordDraft = types.Weapon.createRecordDraft(thrownPotionTable)

	--add to world
	local newRecord = world.createRecord(newRecordDraft)

	-- armedPotionId = potion.recordId
	local armedThrowable = world.createObject(newRecord.id, potion.count)
	-- potion:remove(potion.count)

	print(string.format("Size of weapon table after is %s", #types.Weapon.records))
	print(string.format("Created new throwable potion %s", armedThrowable))

	armedThrowable:moveInto(types.Actor.inventory(actor))

	core.sendGlobalEvent('UseItem', {object = armedThrowable, actor = actor, force = true})

	actor:sendEvent('PotionArmed', {potion=potion, throwable=armedThrowable})
	]]--

	-- Disable drinking the potion
	return false
end)

local function onSave()
	return {
		inventoryPotion = inventoryPotion,
	}
end

local function onLoad(saveData, initData)
	if saveData == nil then return end
	inventoryPotion = saveData.inventoryPotion
	if inventoryPotion ~= nil then
		world.players[1]:sendEvent('PotionArmed', {potion=inventoryPotion.recordId})
	else
		world.players[1]:sendEvent('PotionArmed', {potion=nil})
	end
end

local function settingChanged(data)
	if data.key == 'Enabled' and not data.value then
		inventoryPotion = nil
	end
end

local function throwPotion(data)
	local potionWorldObj = world.createObject(inventoryPotion.recordId, 1)

  	potionWorldObj:teleport(data.player.cell, data.startPos, util.transform.rotateX(math.random(6.28)) )

	--potionWorldObj:addScript("scripts/PotionThrower/pt_physics.lua")
  	potionWorldObj:sendEvent("DoPhysics", { thrower = data.player, velocity = data.direction * data.speed + util.vector3(0, 0, tweakSettings:get('ArcFactor')), recordId = inventoryPotion.recordId, worldRef = potionWorldObj })

	decrementPotion(data)
end

local function moveObject(data)
	if not data.active then return end
	if data.rotation then
		data.object:teleport( data.object.cell, data.destination, data.rotation )
	else
		data.object:teleport( data.object.cell, data.destination )
	end
end

local function drinkPotion(data)
	if data.fromInventory then
		local appliedPotion = types.Actor.inventory(data.target):find(data.recordId)
		skipArming = true
		core.sendGlobalEvent('UseItem', {object = appliedPotion, actor = data.target, force = true})
	else
		local appliedPotion = world.createObject(data.recordId, 1)
		if types.Player.objectIsInstance(data.target) then
			skipArming = true
			decrementPotion({player = data.target, recordId = data.recordId })
		end
		core.sendGlobalEvent('UseItem', {object = appliedPotion, actor = data.target, force = true})
	end
	if types.Player.objectIsInstance(data.target) then
		data.target:sendEvent('RefreshUI', { } )
	end

	-- appliedPotion:moveInto(types.Actor.inventory(data.collision))
	-- core.sendGlobalEvent('SpawnVfx', {model = 'meshes/e/potion_thrower/waterSplash.nif', position = data.target.position + util.vector3(0, 0, 110)})
end

local function equipPotion(data)
	local tempPotion = types.Actor.inventory(data.player):find(data.recordId)
	if tempPotion == nil then
		return
	end
	forceEquip = true
	core.sendGlobalEvent('UseItem', {object = tempPotion, actor = data.player, force = true})
end

local function unprompt(data)
	--world.unpause('potion_prompt')
end

-- Hit chance calculation thanks to Always Hungry's SME mod: https://www.nexusmods.com/morrowind/mods/53996

local function marksmanChance(player)
	local weaponSkill = types.NPC.stats.skills[settings:get('Skill')](player).modified
	local agility = types.Actor.stats.attributes.agility(player).modified
	local luck = types.Actor.stats.attributes.luck(player).modified
	local fatigueCurrent = types.Actor.stats.dynamic.fatigue(player).current
	local fatigueBase = types.Actor.stats.dynamic.fatigue(player).base
	local fortifyAttack = types.Actor.activeEffects(player):getEffect(core.magic.EFFECT_TYPE.FortifyAttack)
	local blind = types.Actor.activeEffects(player):getEffect(core.magic.EFFECT_TYPE.Blind)
	return (weaponSkill + (agility / 5) + (luck / 10)) * (0.75 + (0.5 * (fatigueCurrent / fatigueBase)))
		+ (fortifyAttack and fortifyAttack.magnitude or 0)
		+ (blind and blind.magnitude or 0)
end

local function targetEvasion(target)
	local agility = types.Actor.stats.attributes.agility(target).modified
	local luck = types.Actor.stats.attributes.luck(target).modified
	local fatigueCurrent = types.Actor.stats.dynamic.fatigue(target).current
	local fatigueBase = types.Actor.stats.dynamic.fatigue(target).base
	local sanctuary = types.Actor.activeEffects(target):getEffect(core.magic.EFFECT_TYPE.Sanctuary)
	return ((agility / 5) + (luck / 10)) * (0.75 + (0.5 * (fatigueCurrent / fatigueBase)))
		+ (sanctuary and sanctuary.magnitude or 0)
end

local function hitSuccessful(player, target, volume)
	local hitChance = math.max(0, marksmanChance(player) + settings:get('Handicap') - targetEvasion(target))

	local roll = math.random(0, 100)

	local success = roll <= hitChance

	if not success then
		player:sendEvent('ShowMessage', {text = string.format('Potion missed! Hit chance was %.2f%%', hitChance)})
		player:sendEvent('PlaySound', {path = 'sound/fx/miss23.wav', volume = volume})
	else
		player:sendEvent('PlaySound', {path = 'sound/fx/body fall heavy.wav', volume = volume})
	end

	return success
end

local function resolveCollision(data)
	-- use impact effects from the awesome Impact Effects mod by taitechnic: https://www.nexusmods.com/morrowind/mods/55508?tab=description
	local distance = (data.object.position - data.thrower.position):length()
	local volume = math.min(1.0, math.max(0.1, ((1000.0 - distance) / 1000.0)))
	core.sendGlobalEvent('SpawnVfx', {model = 'meshes/e/potion_thrower/cloudSmall.nif', position = data.object.position})
	data.thrower:sendEvent('PlaySound', {path = 'sound/fx/BodyFallMED.wav', volume = volume})
	if data.collision ~= nil and types.Actor.objectIsInstance(data.collision) then
		if hitSuccessful(data.thrower, data.collision, volume) then
			core.sendGlobalEvent('SpawnVfx', {model = 'meshes/e/potion_thrower/waterSplash.nif', position = data.object.position})
			local appliedPotion = world.createObject(data.recordId, 1)
			if types.Player.objectIsInstance(data.collision) then
				skipArming = true
			end
			-- appliedPotion:moveInto(types.Actor.inventory(data.collision))
			core.sendGlobalEvent('UseItem', {object = appliedPotion, actor = data.collision, force = true})

			if not types.Player.objectIsInstance(data.collision) then
				for index, effect in pairs(types.Potion.record(appliedPotion.recordId).effects) do
					if effect.effect.harmful then
						-- harmful effects aggro
						if types.Player.objectIsInstance(data.thrower) and types.NPC.objectIsInstance(data.collision) and types.Actor.getStance(data.collision) == types.Actor.STANCE.Nothing then
							crimes.commitCrime(data.thrower, { type = types.Player.OFFENSE_TYPE.Assault, victim = data.collision })
						end
						data.collision:sendEvent('StartAIPackage', {type='Combat', target=data.thrower})
					end
				end
			end
			if settings:get('XPGain') then
				data.thrower:sendEvent('SkillUp', { skill=settings:get('Skill'), amount = 1 } )
			end
		else
			if settings:get('XPGain') then
				data.thrower:sendEvent('SkillUp', { skill=settings:get('Skill'), amount = 0.5 } )
			end
		end
	else
		core.sendGlobalEvent('SpawnVfx', {model = 'meshes/e/potion_thrower/waterSplash.nif', position = data.object.position})
	end
	
	data.object:sendEvent('CleanUp', {})
	--objectsToRemove[data.thrower] = data.object
	--data.object:removeScript("scripts/PotionThrower/pt_physics.lua")
end

local function removeObject(data)
	data.object:remove()
end

local function setEnabled(data)
	modEnabled = data.enabled
	if not modEnabled then
		inventoryPotion = nil
	end
end

return {
	eventHandlers = {
		ThrowPotion = throwPotion,
		MoveObject = moveObject,
		ResolveCollision = resolveCollision,
		EnableArming = enableArming,
		EnableDrinking = enableDrinking,
		SettingChanged = settingChanged,
		DrinkPotion = drinkPotion,
		EquipPotion = equipPotion,
		Unprompt = unprompt,
		RemoveObject = removeObject,
		SetEnabled = setEnabled
	},
	engineHandlers = { onSave = onSave, onLoad = onLoad }
}

