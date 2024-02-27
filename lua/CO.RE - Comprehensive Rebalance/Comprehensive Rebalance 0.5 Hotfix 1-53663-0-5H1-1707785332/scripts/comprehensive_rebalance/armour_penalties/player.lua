local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local ui = require('openmw.ui');
local settings = require("scripts.comprehensive_rebalance.lib.settings")

local Actor = types.Actor
local Armor = types.Armor
local Weapon = types.Weapon

local actorSpells = Actor.spells(self)

local function addOrRemoveSpell(spell,add)
    if add then
        actorSpells:add(spell)
        --actorSpells:remove(spell)
        --ui.showMessage("adding " .. spell)
    else
        actorSpells:remove(spell)
        --ui.showMessage("removing " .. spell)
    end
end

--this sucks. There's no good way to get armor type
local function getArmourType(armour)
    if not armour or not Armor.objectIsInstance(armour) then
        return 0
    end

    local r = Armor.record(armour)

    --Account for armours that provide no AR
    --This allows for other mods to add things like hats,
    --Which use the head/helmet slot
    --They will not count towards bulky or implacable armour
    if (r.baseArmor == 0) then
        return 0;
    end

    if (r.type == Armor.TYPE.Cuirass) then
        if r.weight > 27 then
            return 3
        elseif r.weight > 18 then
            return 2
        end
    elseif (r.type == Armor.TYPE.LGauntlet or r.type == Armor.TYPE.RGauntlet or r.type == Armor.TYPE.Helmet or r.type == Armor.TYPE.LBracer or r.type == Armor.TYPE.RBracer) then
        if r.weight > 4.5 then
            return 3
        elseif r.weight > 3 then
            return 2
        end
    elseif (r.type == Armor.TYPE.LPauldron or r.type == Armor.TYPE.RPauldron) then
        if r.weight > 9 then
            return 3
        elseif r.weight > 6 then
            return 2
        end
    elseif (r.type == Armor.TYPE.Greaves or r.type == Armor.TYPE.Shield) then
        if r.weight > 13.5 then
            return 3
        elseif r.weight > 9 then
            return 2
        end
    elseif (r.type == Armor.TYPE.Boots) then
        if r.weight > 18 then
            return 3
        elseif r.weight > 12 then
            return 2
        end
    end

    return 1
end

local previousValue = 0
local previousImplac = 0

local function onSave(initData)
    return {
        pV = previousValue,
        pI = previousImplac,
    }
end

local function onLoad(data)
    previousValue = data.pV
    previousImplac = data.pI
end


--This is horribly inefficient, but
--ItemUsage.addHandlerForType(type, handler)
--https://openmw.readthedocs.io/en/latest/reference/lua-scripting/interface_item_usage.html
--is not really usable currently, as
--it only sends inventory events (no hotkeys, AI equip etc),
--and doesn't send any unequip events
local function equipHandler()
    
    local section = settings.GetSection("armour")
	
    local slots = Actor.getEquipment(self)
	local shield_slot = slots[Actor.EQUIPMENT_SLOT.CarriedLeft]
	local weapon = slots[Actor.EQUIPMENT_SLOT.CarriedRight]

    local shield = nil
    if shield_slot and Armor.objectIsInstance(shield_slot) then
        shield = shield_slot
    end

    local boots = slots[Actor.EQUIPMENT_SLOT.Boots]
    local cuirass = slots[Actor.EQUIPMENT_SLOT.Cuirass]
    local greaves = slots[Actor.EQUIPMENT_SLOT.Greaves]
    local helmet = slots[Actor.EQUIPMENT_SLOT.Helmet]
    local leftGauntlet = slots[Actor.EQUIPMENT_SLOT.LeftGauntlet]
    local leftPauldron = slots[Actor.EQUIPMENT_SLOT.LeftPauldron]
    local rightGauntlet = slots[Actor.EQUIPMENT_SLOT.RightGauntlet]
    local rightPauldron = slots[Actor.EQUIPMENT_SLOT.RightPauldron]

    --ui.showMessage("boots type " .. type)

    local bulkyShield = section:get("bulkyShieldsMode")
    local penalty = bulkyShield == "penalty" or bulkyShield == "both"
    local bonus = bulkyShield == "bonus" or bulkyShield == "both"

    addOrRemoveSpell('shield bulk',shield and penalty)
    addOrRemoveSpell('shield empty reward',not shield and bonus)

    local t_b = getArmourType(boots)
    local t_c = getArmourType(cuirass)
    local t_g = getArmourType(greaves)
    local t_h = getArmourType(helmet)
    local t_lg = getArmourType(leftGauntlet)
    local t_rg = getArmourType(rightGauntlet)
    local t_lp = getArmourType(leftPauldron)
    local t_rp = getArmourType(rightPauldron)
    local t_s = getArmourType(shield)

    local implacable = section:get("implacableArmour") 
    local bulky = section:get("bulkyArmour") 
    local mult = section:get("bulkyArmourMult") 

    local value = 0

    if (bulky) then
        value = value + t_b * mult
        value = value + t_c * mult
        value = value + t_g * mult
        value = value + t_h * mult
        value = value + t_lg * mult
        value = value + t_rg * mult
        value = value + t_lp * mult
        value = value + t_rp * mult
        value = value + t_s * mult
    end

    --print("value is " .. tostring(value))

    if previousValue ~= value then
        if previousValue > 0 then
            addOrRemoveSpell('armor magic penalty ' .. tostring(previousValue),false)
        end
        previousValue = value
        if value > 0 then
            addOrRemoveSpell('armor magic penalty ' .. tostring(value),true)
        end
    end

    --stop awful magic sound
    if previousValue ~= 0 then
        core.sound.stopSound3d("magic sound", self)
    end
    
    --do implacable
    local i = 0
    if implacable then
        if t_b == 3 then
            i = i + 1
        end
        if t_c == 3 then
            i = i + 2
        end
        if t_g == 3 then
            i = i + 1
        end
        if t_h == 3 then
            i = i + 1
        end
        if t_lg == 3 then
            i = i + 1
        end
        if t_rg == 3 then
            i = i + 1
        end
        if t_lp == 3 then
            i = i + 1
        end
        if t_rp == 3 then
            i = i + 1
        end
        if t_s == 3 then
            i = i + 1
        end
    end

    if previousImplac ~= i then
        if previousImplac > 0 then
            addOrRemoveSpell('armor slow ' .. tostring(previousImplac),false)
        end
        previousImplac = i
        if i > 0 then
            addOrRemoveSpell('armor slow ' .. tostring(i),true)
        end
    end

	--[[
    addOrRemoveSpell('armor absorption BL',allow and t_boots == 'light')
    addOrRemoveSpell('armor absorption BM',allow and t_boots == 'medium')
    addOrRemoveSpell('armor absorption BH',allow and t_boots == 'heavy')
    addOrRemoveSpell('armor absorption CL',allow and t_cuirass == 'light')
    addOrRemoveSpell('armor absorption CM',allow and t_cuirass == 'medium')
    addOrRemoveSpell('armor absorption CH',allow and t_cuirass == 'heavy')
    addOrRemoveSpell('armor absorption GL',allow and t_greaves == 'light')
    addOrRemoveSpell('armor absorption GM',allow and t_greaves == 'medium')
    addOrRemoveSpell('armor absorption GH',allow and t_greaves == 'heavy')
    addOrRemoveSpell('armor absorption HL',allow and t_helmet == 'light')
    addOrRemoveSpell('armor absorption HM',allow and t_helmet == 'medium')
    addOrRemoveSpell('armor absorption HH',allow and t_helmet == 'heavy')
    addOrRemoveSpell('armor absorption SL',allow and t_s == 'light')
    addOrRemoveSpell('armor absorption SM',allow and t_s == 'medium')
    addOrRemoveSpell('armor absorption SH',allow and t_s == 'heavy')

    --gauntlets
    addOrRemoveSpell('armor absorption GLL',allow and t_lg == 'light')
    addOrRemoveSpell('armor absorption GLM',allow and t_lg == 'medium')
    addOrRemoveSpell('armor absorption GLH',allow and t_lg == 'heavy')
    addOrRemoveSpell('armor absorption GRL',allow and t_rg == 'light')
    addOrRemoveSpell('armor absorption GRM',allow and t_rg == 'medium')
    addOrRemoveSpell('armor absorption GRH',allow and t_rg == 'heavy')
    
    --pauldrons
    addOrRemoveSpell('armor absorption PLL',allow and t_lp == 'light')
    addOrRemoveSpell('armor absorption PLM',allow and t_lp == 'medium')
    addOrRemoveSpell('armor absorption PLH',allow and t_lp == 'heavy')
    addOrRemoveSpell('armor absorption PRL',allow and t_rp == 'light')
    addOrRemoveSpell('armor absorption PRM',allow and t_rp == 'medium')
    addOrRemoveSpell('armor absorption PRH',allow and t_rp == 'heavy')

    --IMPLACABLE
    local implacable = section:get("implacableArmour") 
    addOrRemoveSpell('armor slow BH',implacable and t_boots == 'heavy')
    addOrRemoveSpell('armor slow CH',implacable and t_cuirass == 'heavy')
    addOrRemoveSpell('armor slow GH',implacable and t_greaves == 'heavy')
    addOrRemoveSpell('armor slow HH',implacable and t_helmet == 'heavy')
    addOrRemoveSpell('armor slow LGH',implacable and t_lg == 'heavy')
    addOrRemoveSpell('armor slow LPH',implacable and t_lp == 'heavy')
    addOrRemoveSpell('armor slow RGH',implacable and t_rg == 'heavy')
    addOrRemoveSpell('armor slow RPH',implacable and t_rp == 'heavy')
    addOrRemoveSpell('armor slow SH',implacable and t_s == 'heavy')
    ]]--

	--[[
	local spell = Actor.spells(self)['armor slow SH']
	print('SPELL: '..spell.name)
	for _, effect in pairs(spell.effects) do
		print('  -> effects['..tostring(effect)..']:')
		print('       id: '..tostring(effect.id))
		print('       name: '..tostring(effect.name))
		print('       affectedSkill: '..tostring(effect.affectedSkill))
		print('       affectedAttribute: '..tostring(effect.affectedAttribute))
		print('       magnitudeThisFrame: '..tostring(effect.magnitudeThisFrame))
		print('       minMagnitude: '..tostring(effect.minMagnitude))
		print('       maxMagnitude: '..tostring(effect.maxMagnitude))
		print('       duration: '..tostring(effect.duration))
		print('       durationLeft: '..tostring(effect.durationLeft))
	end
	]]--
	
	--[[
	local spell = Actor.spells(self)['armor slow SH']
	if (spell) then
		for _, effect in pairs(spell.effects) do
			print('       minMagnitude: '..tostring(effect.magnitudeMin))
			print('       maxMagnitude: '..tostring(effect.magnitudeMax))
			effect.magnitudeMax = 99
			effect.magnitudeMin = 99
		end
	end
	]]--

	--[[
    --Actor.activeEffects(self):set(10, "sound")
	for id, params in pairs(Actor.activeSpells(self)) do
		print('active spell '..tostring(params.id)..':')
		if (tostring(params.id) == 'armor slow sh') then
			for _, effect in pairs(params.effects) do
				effect.magnitudeThisFrame = 20;
				print('  -> effects['..tostring(effect)..']:')
				print('       id: '..tostring(effect.id))
				print('       name: '..tostring(effect.name))
				print('       affectedSkill: '..tostring(effect.affectedSkill))
				print('       affectedAttribute: '..tostring(effect.affectedAttribute))
				print('       magnitudeThisFrame: '..tostring(effect.magnitudeThisFrame))
				print('       minMagnitude: '..tostring(effect.minMagnitude))
				print('       maxMagnitude: '..tostring(effect.maxMagnitude))
				print('       duration: '..tostring(effect.duration))
				print('       durationLeft: '..tostring(effect.durationLeft))
			end
		end
		]]--
		--[[
		print('active spell '..tostring(id)..':')
		print('  name: '..tostring(params.name))
		print('  id: '..tostring(params.id))
		print('  item: '..tostring(params.item))
		print('  caster: '..tostring(params.caster))
		print('  effects: '..tostring(params.effects))
		for _, effect in pairs(params.effects) do
			print('  -> effects['..tostring(effect)..']:')
			print('       id: '..tostring(effect.id))
			print('       name: '..tostring(effect.name))
			print('       affectedSkill: '..tostring(effect.affectedSkill))
			print('       affectedAttribute: '..tostring(effect.affectedAttribute))
			print('       magnitudeThisFrame: '..tostring(effect.magnitudeThisFrame))
			print('       minMagnitude: '..tostring(effect.minMagnitude))
			print('       maxMagnitude: '..tostring(effect.maxMagnitude))
			print('       duration: '..tostring(effect.duration))
			print('       durationLeft: '..tostring(effect.durationLeft))
		end
	end
	]]--
end

return
{
	engineHandlers =
	{
		onUpdate = equipHandler,
        onSave = onSave,
        onLoad = onLoad,
	}
}

