---@diagnostic disable: undefined-field
local mod = {
    name = "Summon Souls",
    ver = "0.511",
    cf = {onOff = true, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, dropDown = 0, slider = 5, sliderpercent = 50, blocked = {}, npcs = {}, textfield = "hello", switch = false}
            }
local cf = mwse.loadConfig(mod.name, mod.cf)
local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
if not framework then return end
tes3.claimSpellEffectId("storeSoul", 3300)
tes3.claimSpellEffectId("summonSoul1", 3301)
tes3.claimSpellEffectId("summonSoul2", 3302)
tes3.claimSpellEffectId("summonSoul3", 3303)
tes3.claimSpellEffectId("summonSoul4", 3304)
tes3.claimSpellEffectId("summonSoul5", 3305)
tes3.claimSpellEffectId("summonSoul6", 3306)
tes3.claimSpellEffectId("summonSoul7", 3307)
tes3.claimSpellEffectId("summonSoul8", 3308)
---comment
---@param ref tes3reference
---@param location tes3vector3
---@return boolean

--------------------------- add Prism -------------------


local function OV_OnJournalUpdated(e)
    local quest = tostring(e.topic)  -- Convert e.topic to string
    if e.index == 10 and quest == "MG_Sharn_Necro" then
        local player = tes3.mobilePlayer
        local adding = tes3.addItem({ reference = player, item = "OV_SoulPrism" })
        tes3.messageBox("You have received a strange gem.")
    end
end

event.register(tes3.event.journal, OV_OnJournalUpdated)


------------- Soul Index -------------------

local OV_storedSummonIds = {}

local function OV_storeSummonIds(slotIndex, summonId)
OV_storedSummonIds[slotIndex] = summonId
    tes3.player.data["OV_storedSummonIds"] = tes3.player.data["OV_storedSummonIds"] or {}
    tes3.player.data["OV_storedSummonIds"][slotIndex] = summonId
end

-- Function to load stored data from the player's data
local function OV_loadStoredData()
    local storedData = tes3.player.data["OV_storedSummonIds"]
    if storedData then
        for i = 1, 8 do
            OV_storedSummonIds[i] = storedData[i] or nil
        end
    end
end

event.register("loaded", OV_loadStoredData)


------------------------------------ Get Text / Cost ------------------

local function OV_getSlotText(slotIndex)
    local storedId = OV_storedSummonIds[slotIndex]
    if storedId then
        local storedObject = tes3.getObject(storedId)
        local name = storedObject.name
        return string.format("%d. %s", slotIndex, name)
    else
        return string.format("%d. Empty", slotIndex)
    end
end

local function OV_getLoadText(slotIndex)
    local storedId = OV_storedSummonIds[slotIndex]
    if storedId then
        local storedObject = tes3.getObject(storedId)
        if storedObject then
		local player = tes3.mobilePlayer
            local name = storedObject.name
            local health = storedObject.health
            local magicka = storedObject.magicka
            local fatigue = storedObject.fatigue
		local conjurationSkill = player.skills[tes3.skill.conjuration].current
		local willpower = player.attributes[tes3.attribute.willpower].current
		local playerAbility = conjurationSkill + willpower
	local finalcostraw = (health / 2 + magicka / 15) / 10 / (1 + playerAbility / 100) 
	local finalcost = math.round(finalcostraw)
            -- Display content with name, health, magicka, and fatigue values
            return string.format("%d. %s\nHealth: %d | Magicka: %d\nFatigue: %d | Cost/10s: %d",slotIndex, name, health, magicka, fatigue, finalcost)
        else
            return "Stored Content: Invalid Object"
        end
    else
        -- Display empty slot if the slot is empty
        return "Slot " .. slotIndex .. " (Empty)"
    end
end

---------------------------------------- getSummonId

local function OV_getSummonId(slotIndex)
    return OV_storedSummonIds[slotIndex]
end


-----------------------------------Save Souls Menu ---------------

local function OV_openSaveSoulMenu(summonId)
       local storedObject = tes3.getObject(summonId)
	local name = storedObject.name
		local player = tes3.mobilePlayer
             local health = storedObject.health
            local magicka = storedObject.magicka
            local fatigue = storedObject.fatigue
		local conjurationSkill = player.skills[tes3.skill.conjuration].current
		local willpower = player.attributes[tes3.attribute.willpower].current
		local playerAbility = conjurationSkill + willpower
	local rawfinalcost = (health / 2 + magicka / 15) / 10 / (1 + playerAbility / 100) 
	local finalcost = math.round(rawfinalcost)
    local message = "Choose where to store this Soul:\n\n" .. name .. "\nHealth: " .. health .. " | Magicka: " .. magicka .. "\nFatigue: " .. fatigue .. " | Cost/10s: " .. finalcost .. "\n"
    local buttons = {}

    for i = 1, 8 do
        buttons[i] = {
            text = OV_getLoadText(i),
            callback = function()
                OV_storeSummonIds(i, summonId)
                tes3ui.leaveMenuMode()
            end
        }
    end

    -- Add a Cancel button
    buttons[#buttons + 1] = {
        text = "Release Soul",
        callback = function()
            tes3ui.leaveMenuMode()
        end
    }

    tes3ui.showMessageMenu{
        message = message,
        buttons = buttons,
        doesCancel = true,
        callback = function() end
    }
end

local function OV_swapSummonIds(index1, index2)
    local summonId1 = OV_getSummonId(index1)
    local summonId2 = OV_getSummonId(index2)
    
    OV_storeSummonIds(index1, summonId2)
    OV_storeSummonIds(index2, summonId1)
    
    if index1 == index2 or summonId1 == summonId2 then
        tes3.messageBox("Nothing changed.")
    elseif summonId1 == nil or summonId2 == nil then
        tes3.messageBox("The soul has changed position")
    else
        tes3.messageBox("The souls have changed position")
    end
end

local function OV_openSwapSoulMenu(summonId, selectedSlot)
    local name, health, magicka, fatigue, addbasecost

	
    if summonId then
        storedObject = tes3.getObject(summonId)
	player = tes3.mobilePlayer
	name = storedObject.name
        health = storedObject.health or 0
        magicka = storedObject.magicka or 0
        fatigue = storedObject.fatigue or 0
		local conjurationSkill = player.skills[tes3.skill.conjuration].current
		local willpower = player.attributes[tes3.attribute.willpower].current
		local playerAbility = conjurationSkill + willpower
	addbasecost = math.round((health / 2 + magicka / 15) / 10 / (1 + playerAbility / 100)) 

    else
        name = "Empty"
        health = 0
        magicka = 0
        fatigue = 0
        addbasecost = 0
    end

    local message = "Choose where to store this Soul:\n\n" .. selectedSlot.. ". " .. name .. "\nHealth: " .. health .. " | Magicka: " .. magicka .. "\nFatigue: " .. fatigue .. " | Cost/10s: " .. addbasecost .. "\n\nIf there is a soul, it will be sent to " .. selectedSlot .. ". place."
    local buttons = {}

    for i = 1, 8 do
        buttons[i] = {
            text = OV_getLoadText(i),
            callback = function()
                OV_swapSummonIds(selectedSlot, i)
                tes3ui.leaveMenuMode()
            end
        }
    end

    -- Add a Release Soul button
    buttons[#buttons + 1] = {
        text = "Release Soul",
        callback = function()
            if not summonId then
                tes3.messageBox("There is nothing to release.")
            else
                OV_storeSummonIds(selectedSlot, nil)
                tes3.messageBox("" .. name .. " has been released.")
            end
            tes3ui.leaveMenuMode()
        end
    }

    -- Add a Cancel button
    buttons[#buttons + 1] = {
        text = "Cancel",
        callback = function()
            tes3ui.leaveMenuMode()
        end
    }

    tes3ui.showMessageMenu{
        message = message,
        buttons = buttons,
        doesCancel = true,
        callback = function() end
    }
end

------------Soul Prism Menu ------------



local function OV_openSoulSpellMenu()
	local player = tes3.mobilePlayer
    local message = "Select a spell to learn:\n"
    local buttons = {}

    -- Add "Learn Transfer Soul" button
    buttons[1] = {
        text = "Learn Transfer Soul",
        callback = function()
	local wasAdded = tes3.addSpell({ mobile = player, spell = "OV_StoreSoul" })
if wasAdded == true then
tes3.messageBox("You have learned Transfer Soul!")
else
tes3.messageBox("You already know that spell.")
end
        end
    }

buttons[2] = {
        text = "Learn Summon 1. Soul",
        callback = function()
	local wasAdded = tes3.addSpell({ mobile = player, spell = "OV_Summon_Soul1" })
	if wasAdded == true then
	tes3.messageBox("You have learned Summon 1. Soul!")
	else
	tes3.messageBox("You already know that spell.")
	end
        end
    }

buttons[3] = {
        text = "Learn Summon 2. Soul",
        callback = function()
	local wasAdded = tes3.addSpell({ mobile = player, spell = "OV_Summon_Soul2" })
	if wasAdded == true then
	tes3.messageBox("You have learned Summon 2. Soul!")
	else
	tes3.messageBox("You already know that spell.")
	end
        end
    }

buttons[4] = {
        text = "Learn Summon 3. Soul",
        callback = function()
	local wasAdded = tes3.addSpell({ mobile = player, spell = "OV_Summon_Soul3" })
	if wasAdded == true then
	tes3.messageBox("You have learned Summon 3. Soul!")
	else
	tes3.messageBox("You already know that spell.")
	end
        end
    }

buttons[5] = {
        text = "Learn Summon 4. Soul",
        callback = function()
	local wasAdded = tes3.addSpell({ mobile = player, spell = "OV_Summon_Soul4" })
	if wasAdded == true then
	tes3.messageBox("You have learned Summon 4. Soul!")
	else
	tes3.messageBox("You already know that spell.")
	end
        end
    }

buttons[6] = {
        text = "Learn Summon 5. Soul",
        callback = function()
	local wasAdded = tes3.addSpell({ mobile = player, spell = "OV_Summon_Soul5" })
	if wasAdded == true then
	tes3.messageBox("You have learned Summon 5. Soul!")
	else
	tes3.messageBox("You already know that spell.")
	end
        end
    }

buttons[7] = {
        text = "Learn Summon 6. Soul",
        callback = function()
	local wasAdded = tes3.addSpell({ mobile = player, spell = "OV_Summon_Soul6" })
	if wasAdded == true then
	tes3.messageBox("You have learned Summon 6. Soul!")
	else
	tes3.messageBox("You already know that spell.")
	end
        end
    }

buttons[8] = {
        text = "Learn Summon 7. Soul",
        callback = function()
	local wasAdded = tes3.addSpell({ mobile = player, spell = "OV_Summon_Soul7" })
	if wasAdded == true then
	tes3.messageBox("You have learned Summon 7. Soul!")
	else
	tes3.messageBox("You already know that spell.")
	end
        end
    }

buttons[9] = {
        text = "Learn Summon 8. Soul",
        callback = function()
	local wasAdded = tes3.addSpell({ mobile = player, spell = "OV_Summon_Soul8" })
	if wasAdded == true then
	tes3.messageBox("You have learned Summon 8. Soul!")
	else
	tes3.messageBox("You already know that spell.")
	end
        end
    }

    buttons[#buttons + 1] = {
        text = "Cancel",
        callback = function()
            tes3ui.leaveMenuMode()
        end
    }

    tes3ui.showMessageMenu{
        message = message,
        buttons = buttons,
    }
end


local function OV_openSoulPrismMenu()
	local selectedSlot = nil
       local message = "Select a soul to change its position or to release it.\n"
    local buttons = {}

    for i = 1, 8 do
        buttons[i] = {
            text = OV_getLoadText(i),
            callback = function()
                local summonId = OV_getSummonId(i)
		selectedSlot = i
                OV_openSwapSoulMenu(summonId, selectedSlot)
                tes3ui.leaveMenuMode()
            end
        }
    end

    -- Add a Spells button (currently without a function)
    buttons[#buttons + 1] = {
        text = "Learn Spells",
        callback = function()
	OV_openSoulSpellMenu()
            tes3ui.leaveMenuMode()
        end
    }

    -- Add a Cancel button
    buttons[#buttons + 1] = {
        text = "Cancel",
        callback = function()
            tes3ui.leaveMenuMode()
        end
    }

    tes3ui.showMessageMenu{
        message = message,
        buttons = buttons,
    }
end

local function OV_equipCallback(e)
local item = e.item
if item.id == "OV_SoulPrism" then
OV_openSoulPrismMenu(summonId)
end
end
event.register(tes3.event.equip, OV_equipCallback)

------------------------------ Additional Cost ------------------------------------

local function OV_getSoulSpellCost(health, magicka, summonDuration)
local player = tes3.mobilePlayer
local conjurationSkill = player.skills[tes3.skill.conjuration].current
local willpower = player.attributes[tes3.attribute.willpower].current
local playerAbility = conjurationSkill + willpower
local cost = (((health / 2 + (magicka / 15)) / 10) / (1 + (playerAbility / 100))) * (1 + summonDuration / 10)
return math.round(cost)
end

----------- get soul spell -------------------------

local function OV_getDistace(ref, location)
    return (ref.position:distance(location) <= 200)
end

local function OV_onCollision(e)
    local position = e.collision and e.collision.point
    if not position then return end
    local caster = e.sourceInstance.caster and e.sourceInstance.caster.mobile
    for _,cell in pairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences(tes3.objectType.miscItem) do
            if (ref
            and ref.object
            and ref.object.isSoulGem
            and ref.itemData
            and ref.itemData.soul
            and OV_getDistace(ref, position)) then
                summonId = ref.itemData.soul.id
                tes3.playSound{sound = "conjuration hit", reference = tes3.player}
		OV_openSaveSoulMenu(summonId)
		ref.itemData = nil
                break
            end
        end
    end
end


------------------------ summon soul spell -----------------------


local function onSummonSoul1Tick(e)
    local caster = e.sourceInstance.caster
    local id = OV_storedSummonIds[1]
    e:triggerSummon(id)
end

local function onSummonSoul2Tick(e)
    local caster = e.sourceInstance.caster
    local id = OV_storedSummonIds[2]
    e:triggerSummon(id)
end

local function onSummonSoul3Tick(e)
    local caster = e.sourceInstance.caster
    local id = OV_storedSummonIds[3]
    e:triggerSummon(id)
end

local function onSummonSoul4Tick(e)
    local caster = e.sourceInstance.caster
    local id = OV_storedSummonIds[4]
    e:triggerSummon(id)
end

local function onSummonSoul5Tick(e)
    local caster = e.sourceInstance.caster
    local id = OV_storedSummonIds[5]
    e:triggerSummon(id)
end

local function onSummonSoul6Tick(e)
    local caster = e.sourceInstance.caster
    local id = OV_storedSummonIds[6]
    e:triggerSummon(id)
end

local function onSummonSoul7Tick(e)
    local caster = e.sourceInstance.caster
    local id = OV_storedSummonIds[7]
    e:triggerSummon(id)
end

local function onSummonSoul8Tick(e)
    local caster = e.sourceInstance.caster
    local id = OV_storedSummonIds[8]
    e:triggerSummon(id)
end

----------------------------------- register save spell -----------------------

local function OV_addSTEffect()
	framework.effects.conjuration.createBasicEffect({
		-- Base information.
		id = tes3.effect.storeSoul,
		name = "Transfer trapped Soul",
		description = "Transfers a soul from a soulgem into your Soul Prism, wherever it is.",

		-- Basic dials.
		baseCost = 5,

		-- Various flags.
		allowEnchanting = false,
        allowSpellmaking = true,
        canCastSelf = false,
        canCastTouch = false,
        canCastTarget = true,
        hasContinuousVFX = false,
        nonRecastable = false,
        casterLinked = false,
        hasNoDuration = true,
        hasNoMagnitude = true,

		-- Graphics/sounds.
		icon = "GOMA\\OV_SaveSoul.tga",
        lighting = { 0, 0, 0 },
		-- Required callbacks.
		onTick = function(e) e:trigger() end,
        onCollision = OV_onCollision
	})
end 
event.register("magicEffectsResolved", OV_addSTEffect)


--------------------------------------- register summon Spell ---------------------


local function addSummonSoul1Effect()
		framework.effects.conjuration.createBasicEffect({
		-- Base information.
		id = tes3.effect.summonSoul1,
		name = "Summon 1. Soul",
		description = "Summons a creature to fight for the caster for a limited period of time. Summoned creatures will disappear when the spell expires, when they are killed, or when the character who cast the spell is killed",

		-- Basic dials.
		baseCost = 10,

		-- Various flags.
		allowEnchanting = true,
        allowSpellmaking = true,
        canCastSelf = true,
        hasNoMagnitude = true,
        casterLinked = true,
        appliesOnce = true,

		-- Graphics/sounds.
		icon = "GOMA\\OV_SummonSoul1.tga",
        lighting = { 0, 0, 0 },

		-- Required callbacks.
		onTick = onSummonSoul1Tick,
    })
end
event.register("magicEffectsResolved", addSummonSoul1Effect)


local function addSummonSoul2Effect()
		framework.effects.conjuration.createBasicEffect({
		-- Base information.
		id = tes3.effect.summonSoul2,
		name = "Summon 2. Soul",
		description = "Summons a creature to fight for the caster for a limited period of time. Summoned creatures will disappear when the spell expires, when they are killed, or when the character who cast the spell is killed",

		-- Basic dials.
		baseCost = 10,

		-- Various flags.
		allowEnchanting = true,
        allowSpellmaking = true,
        canCastSelf = true,
        hasNoMagnitude = true,
        casterLinked = true,
        appliesOnce = true,

		-- Graphics/sounds.
		icon = "GOMA\\OV_SummonSoul2.tga",
        lighting = { 0, 0, 0 },

		-- Required callbacks.
		onTick = onSummonSoul2Tick,
    })
end
event.register("magicEffectsResolved", addSummonSoul2Effect)


local function addSummonSoul3Effect()
		framework.effects.conjuration.createBasicEffect({
		-- Base information.
		id = tes3.effect.summonSoul3,
		name = "Summon 3. Soul",
		description = "Summons a creature to fight for the caster for a limited period of time. Summoned creatures will disappear when the spell expires, when they are killed, or when the character who cast the spell is killed",

		-- Basic dials.
		baseCost = 10,

		-- Various flags.
		allowEnchanting = true,
        allowSpellmaking = true,
        canCastSelf = true,
        hasNoMagnitude = true,
        casterLinked = true,
        appliesOnce = true,

		-- Graphics/sounds.
		icon = "GOMA\\OV_SummonSoul3.tga",
        lighting = { 0, 0, 0 },

		-- Required callbacks.
		onTick = onSummonSoul3Tick,
    })
end
event.register("magicEffectsResolved", addSummonSoul3Effect)

local function addSummonSoul4Effect()
		framework.effects.conjuration.createBasicEffect({
		-- Base information.
		id = tes3.effect.summonSoul4,
		name = "Summon 4. Soul",
		description = "Summons a creature to fight for the caster for a limited period of time. Summoned creatures will disappear when the spell expires, when they are killed, or when the character who cast the spell is killed",

		-- Basic dials.
		baseCost = 10,

		-- Various flags.
		allowEnchanting = true,
        allowSpellmaking = true,
        canCastSelf = true,
        hasNoMagnitude = true,
        casterLinked = true,
        appliesOnce = true,

		-- Graphics/sounds.
		icon = "GOMA\\OV_SummonSoul4.tga",
        lighting = { 0, 0, 0 },

		-- Required callbacks.
		onTick = onSummonSoul4Tick,
    })
end
event.register("magicEffectsResolved", addSummonSoul4Effect)

local function addSummonSoul5Effect()
		framework.effects.conjuration.createBasicEffect({
		-- Base information.
		id = tes3.effect.summonSoul5,
		name = "Summon 5. Soul",
		description = "Summons a creature to fight for the caster for a limited period of time. Summoned creatures will disappear when the spell expires, when they are killed, or when the character who cast the spell is killed",

		-- Basic dials.
		baseCost = 10,

		-- Various flags.
		allowEnchanting = true,
        allowSpellmaking = true,
        canCastSelf = true,
        hasNoMagnitude = true,
        casterLinked = true,
        appliesOnce = true,

		-- Graphics/sounds.
		icon = "GOMA\\OV_SummonSoul5.tga",
        lighting = { 0, 0, 0 },

		-- Required callbacks.
		onTick = onSummonSoul5Tick,
    })
end
event.register("magicEffectsResolved", addSummonSoul5Effect)

local function addSummonSoul6Effect()
		framework.effects.conjuration.createBasicEffect({
		-- Base information.
		id = tes3.effect.summonSoul6,
		name = "Summon 6. Soul",
		description = "Summons a creature to fight for the caster for a limited period of time. Summoned creatures will disappear when the spell expires, when they are killed, or when the character who cast the spell is killed",

		-- Basic dials.
		baseCost = 10,

		-- Various flags.
		allowEnchanting = true,
        allowSpellmaking = true,
        canCastSelf = true,
        hasNoMagnitude = true,
        casterLinked = true,
        appliesOnce = true,

		-- Graphics/sounds.
		icon = "GOMA\\OV_SummonSoul6.tga",
        lighting = { 0, 0, 0 },

		-- Required callbacks.
		onTick = onSummonSoul6Tick,
    })
end
event.register("magicEffectsResolved", addSummonSoul6Effect)


local function addSummonSoul7Effect()
		framework.effects.conjuration.createBasicEffect({
		-- Base information.
		id = tes3.effect.summonSoul7,
		name = "Summon 7. Soul",
		description = "Summons a creature to fight for the caster for a limited period of time. Summoned creatures will disappear when the spell expires, when they are killed, or when the character who cast the spell is killed",

		-- Basic dials.
		baseCost = 10,

		-- Various flags.
		allowEnchanting = true,
        allowSpellmaking = true,
        canCastSelf = true,
        hasNoMagnitude = true,
        casterLinked = true,
        appliesOnce = true,

		-- Graphics/sounds.
		icon = "GOMA\\OV_SummonSoul7.tga",
        lighting = { 0, 0, 0 },

		-- Required callbacks.
		onTick = onSummonSoul7Tick,
    })
end
event.register("magicEffectsResolved", addSummonSoul7Effect)


local function addSummonSoul8Effect()
		framework.effects.conjuration.createBasicEffect({
		-- Base information.
		id = tes3.effect.summonSoul8,
		name = "Summon 8. Soul",
		description = "Summons a creature to fight for the caster for a limited period of time. Summoned creatures will disappear when the spell expires, when they are killed, or when the character who cast the spell is killed",

		-- Basic dials.
		baseCost = 10,

		-- Various flags.
		allowEnchanting = true,
        allowSpellmaking = true,
        canCastSelf = true,
        hasNoMagnitude = true,
        casterLinked = true,
        appliesOnce = true,

		-- Graphics/sounds.
		icon = "GOMA\\OV_SummonSoul8.tga",
        lighting = { 0, 0, 0 },

		-- Required callbacks.
		onTick = onSummonSoul8Tick,
    })
end
event.register("magicEffectsResolved", addSummonSoul8Effect)
----------------------- register premade spells ---------------------

local function registerSpells()
    framework.spells.createBasicSpell({
        id = "OV_StoreSoul",
        name = "Transfer Soul",
	cost = 1,
        effect = tes3.effect.storeSoul,
        range = tes3.effectRange.target,
    })

  framework.spells.createBasicSpell({
    id = "OV_Summon_Soul1",
    name = "Summon 1. Soul",
cost = 0,
    effect = tes3.effect.summonSoul1,
    range = tes3.effectRange.self,
    duration = 30
  })

  framework.spells.createBasicSpell({
    id = "OV_Summon_Soul2",
    name = "Summon 2. Soul",
cost = 0,
    effect = tes3.effect.summonSoul2,
    range = tes3.effectRange.self,
    duration = 30
  })

  framework.spells.createBasicSpell({
    id = "OV_Summon_Soul3",
    name = "Summon 3. Soul",
cost = 0,
    effect = tes3.effect.summonSoul3,
    range = tes3.effectRange.self,
    duration = 30
  })

  framework.spells.createBasicSpell({
    id = "OV_Summon_Soul4",
    name = "Summon 4. Soul",
cost = 0,
    effect = tes3.effect.summonSoul4,
    range = tes3.effectRange.self,
    duration = 30
  })

  framework.spells.createBasicSpell({
    id = "OV_Summon_Soul5",
    name = "Summon 5. Soul",
cost = 0,
    effect = tes3.effect.summonSoul5,
    range = tes3.effectRange.self,
    duration = 30
  })

  framework.spells.createBasicSpell({
    id = "OV_Summon_Soul6",
    name = "Summon 6. Soul",
cost = 0,
    effect = tes3.effect.summonSoul6,
    range = tes3.effectRange.self,
    duration = 30
  })

  framework.spells.createBasicSpell({
    id = "OV_Summon_Soul7",
    name = "Summon 7. Soul",
cost = 0,
    effect = tes3.effect.summonSoul7,
    range = tes3.effectRange.self,
    duration = 30
  })

  framework.spells.createBasicSpell({
    id = "OV_Summon_Soul8",
    name = "Summon 8. Soul",
cost = 0,
    effect = tes3.effect.summonSoul8,
    range = tes3.effectRange.self,
    duration = 30
  })

end event.register("MagickaExpanded:Register", registerSpells)

--------------- Cast Cost --------------------

local function OV_spellMagickaUseCallback(e)
    local effects = e.spell.effects
    if effects ~= nil then
        for index, effect in ipairs(effects) do
            local effectId = effect.id
            if effectId == 3301 then 
		local summonDuration = effect.duration
                local storedSoul = tes3.getObject(OV_storedSummonIds[1])
                local health = storedSoul.health or 0
                local magicka = storedSoul.magicka or 0
                local additionalCost = OV_getSoulSpellCost(health, magicka, summonDuration)
                e.cost = e.cost + additionalCost
            end
		if effectId == 3302 then 
		local summonDuration = effect.duration
                local storedSoul = tes3.getObject(OV_storedSummonIds[2])
                local health = storedSoul.health or 0
                local magicka = storedSoul.magicka or 0
                local additionalCost = OV_getSoulSpellCost(health, magicka, summonDuration)
                e.cost = e.cost + additionalCost
            end
		if effectId == 3303 then 
		local summonDuration = effect.duration
                local storedSoul = tes3.getObject(OV_storedSummonIds[3])
                local health = storedSoul.health or 0
                local magicka = storedSoul.magicka or 0
                local additionalCost = OV_getSoulSpellCost(health, magicka, summonDuration)
                e.cost = e.cost + additionalCost
            end
		if effectId == 3304 then 
		local summonDuration = effect.duration
                local storedSoul = tes3.getObject(OV_storedSummonIds[4])
                local health = storedSoul.health or 0
                local magicka = storedSoul.magicka or 0
                local additionalCost = OV_getSoulSpellCost(health, magicka, summonDuration)
                e.cost = e.cost + additionalCost
            end
		if effectId == 3305 then 
		local summonDuration = effect.duration
                local storedSoul = tes3.getObject(OV_storedSummonIds[5])
                local health = storedSoul.health or 0
                local magicka = storedSoul.magicka or 0
                local additionalCost = OV_getSoulSpellCost(health, magicka, summonDuration)
                e.cost = e.cost + additionalCost
            end
		if effectId == 3306 then 
		local summonDuration = effect.duration
                local storedSoul = tes3.getObject(OV_storedSummonIds[6])
                local health = storedSoul.health or 0
                local magicka = storedSoul.magicka or 0
                local additionalCost = OV_getSoulSpellCost(health, magicka, summonDuration)
                e.cost = e.cost + additionalCost
            end
		if effectId == 3307 then 
		local summonDuration = effect.duration
                local storedSoul = tes3.getObject(OV_storedSummonIds[7])
                local health = storedSoul.health or 0
                local magicka = storedSoul.magicka or 0
                local additionalCost = OV_getSoulSpellCost(health, magicka, summonDuration)
                e.cost = e.cost + additionalCost
            end
		if effectId == 3308 then 
		local summonDuration = effect.duration
                local storedSoul = tes3.getObject(OV_storedSummonIds[8])
                local health = storedSoul.health or 0
                local magicka = storedSoul.magicka or 0
                local additionalCost = OV_getSoulSpellCost(health, magicka, summonDuration)
                e.cost = e.cost + additionalCost
            end
        end
    end
end

event.register(tes3.event.spellMagickaUse, OV_spellMagickaUseCallback)

---------------------------Spell Tooltip ---------------------

local OV_oldspell = nil

local function clearOV_oldspell()
    OV_oldspell = nil
end

local function OV_onClickEventHandler(e)
    if tes3ui.menuMode() then
        clearOV_oldspell()
    end
end

local function OV_registerClickEvent()
    event.register("mouseButtonDown", OV_onClickEventHandler)
end

event.register("initialized", OV_registerClickEvent)

local function OV_uiSpellTooltipCallback(e)
    local hasSpecifiedEffect = false
    local spell = e.spell
	if spell ~= OV_oldspell then
		OV_oldspell = spell
    		local effects = spell.effects
		local totalCost = 0
		local names = {}
			for index, effect in ipairs(effects) do
            		local effectId = effect.id
-------------------------------------------------------------------------------------
            			if effectId == 3301 then
				hasSpecifiedEffect = true
				local summonDuration = effect.duration
                		local summonId = OV_storedSummonIds[1]
                		if summonId then
       				local storedSoul = tes3.getObject(summonId)
        			local name = storedSoul.name
        			local health = storedSoul.health
        			local magicka = storedSoul.magicka
        			local additionalCost = OV_getSoulSpellCost(health, magicka, summonDuration)
        			totalCost = totalCost + additionalCost
        			table.insert(names, name)
    				else
        			table.insert(names, "Nothing")
    				end
				end
            			if effectId == 3302 then
				hasSpecifiedEffect = true
				local summonDuration = effect.duration
                		local summonId = OV_storedSummonIds[2]
                		if summonId then
       				local storedSoul = tes3.getObject(summonId)
        			local name = storedSoul.name
        			local health = storedSoul.health
        			local magicka = storedSoul.magicka
        			local additionalCost = OV_getSoulSpellCost(health, magicka, summonDuration)
        			totalCost = totalCost + additionalCost
        			table.insert(names, name)
    				else
        			table.insert(names, "Nothing")
    				end
				end
            			if effectId == 3303 then
				hasSpecifiedEffect = true
				local summonDuration = effect.duration
                		local summonId = OV_storedSummonIds[3]
                		if summonId then
       				local storedSoul = tes3.getObject(summonId)
        			local name = storedSoul.name
        			local health = storedSoul.health
        			local magicka = storedSoul.magicka
        			local additionalCost = OV_getSoulSpellCost(health, magicka, summonDuration)
        			totalCost = totalCost + additionalCost
        			table.insert(names, name)
    				else
        			table.insert(names, "Nothing")
    				end
				end
            			if effectId == 3304 then
				hasSpecifiedEffect = true
				local summonDuration = effect.duration
                		local summonId = OV_storedSummonIds[4]
                		if summonId then
       				local storedSoul = tes3.getObject(summonId)
        			local name = storedSoul.name
        			local health = storedSoul.health
        			local magicka = storedSoul.magicka
        			local additionalCost = OV_getSoulSpellCost(health, magicka, summonDuration)
        			totalCost = totalCost + additionalCost
        			table.insert(names, name)
    				else
        			table.insert(names, "Nothing")
    				end
				end
            			if effectId == 3305 then
				hasSpecifiedEffect = true
				local summonDuration = effect.duration
                		local summonId = OV_storedSummonIds[5]
                		if summonId then
       				local storedSoul = tes3.getObject(summonId)
        			local name = storedSoul.name
        			local health = storedSoul.health
        			local magicka = storedSoul.magicka
        			local additionalCost = OV_getSoulSpellCost(health, magicka, summonDuration)
        			totalCost = totalCost + additionalCost
        			table.insert(names, name)
    				else
        			table.insert(names, "Nothing")
    				end
				end
            			if effectId == 3306 then
				hasSpecifiedEffect = true
				local summonDuration = effect.duration
                		local summonId = OV_storedSummonIds[6]
                		if summonId then
       				local storedSoul = tes3.getObject(summonId)
        			local name = storedSoul.name
        			local health = storedSoul.health
        			local magicka = storedSoul.magicka
        			local additionalCost = OV_getSoulSpellCost(health, magicka, summonDuration)
        			totalCost = totalCost + additionalCost
        			table.insert(names, name)
    				else
        			table.insert(names, "Nothing")
    				end
				end
            			if effectId == 3307 then
				hasSpecifiedEffect = true
				local summonDuration = effect.duration
                		local summonId = OV_storedSummonIds[7]
                		if summonId then
       				local storedSoul = tes3.getObject(summonId)
        			local name = storedSoul.name
        			local health = storedSoul.health
        			local magicka = storedSoul.magicka
        			local additionalCost = OV_getSoulSpellCost(health, magicka, summonDuration)
        			totalCost = totalCost + additionalCost
        			table.insert(names, name)
    				else
        			table.insert(names, "Nothing")
    				end
				end
            			if effectId == 3308 then
				hasSpecifiedEffect = true
				local summonDuration = effect.duration
                		local summonId = OV_storedSummonIds[8]
                		if summonId then
       				local storedSoul = tes3.getObject(summonId)
        			local name = storedSoul.name
        			local health = storedSoul.health
        			local magicka = storedSoul.magicka
        			local additionalCost = OV_getSoulSpellCost(health, magicka, summonDuration)
        			totalCost = totalCost + additionalCost
        			table.insert(names, name)
    				else
        			table.insert(names, "Nothing")
    				end
				end
				if effectId == 3300 then
				local tooltip = tes3ui.createTooltipMenu{spell = spell}
				local slotTexts = {}
					for i = 1, 8 do
    					slotTexts[i] = OV_getSlotText(i)
					end
				local fullText = table.concat(slotTexts, "\n")
				tooltip:createLabel({ text = fullText })
				end
			end
-------------------------------------------------------------------------------------
		if hasSpecifiedEffect == true then
		local tooltipText = ""
   		local namesText = table.concat(names, ", ")
    		tooltipText = "Summons: " .. namesText .. ".\nAdditional Cost: " .. totalCost .."."

                local tooltip = tes3ui.createTooltipMenu{spell = spell}
                tooltip:createLabel({ text = tooltipText })
                end
	OV_oldspell = spell
        end
end
event.register("uiSpellTooltip", OV_uiSpellTooltipCallback)

------------------------- Soul Prism Tooltip ------------------------------
local OV_dotooltip = 1

local function OV_uiObjectTooltipCallback(e)
    local examinedObject = e.object
    local objectId = examinedObject.id
	if objectId == "OV_SoulPrism" and OV_dotooltip == 1 then
	OV_dotooltip = 0
	local item = tes3.getObject("OV_SoulPrism")
        local tooltip = tes3ui.createTooltipMenu()
local slotTexts = {}
for i = 1, 8 do
    slotTexts[i] = OV_getSlotText(i)
end
local fullText = "Soul Prism\n\n" .. table.concat(slotTexts, "\n")
tooltip:createLabel({ text = fullText })
        tooltip:updateLayout()
    end
	OV_dotooltip = 1
end

event.register(tes3.event.uiObjectTooltip, OV_uiObjectTooltipCallback)

------------------------- initialized ----------------------------

local function initialized()
    print("["..mod.name..", by OverlordMasterofAll] "..mod.ver.." Initialized!")
end event.register("initialized", initialized, {priority = -1000})

