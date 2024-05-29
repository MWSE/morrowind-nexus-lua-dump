local core = require("openmw.core")
local types = require("openmw.types")
local world = require("openmw.world")
local acti = require("openmw.interfaces").Activation
local storage = require("openmw.storage")
local interface = require('openmw.interfaces')
local util = require('openmw.util')
local async = require('openmw.async')
local vfs = require('openmw.vfs')
local v3 = require('openmw.util').vector3

--For some reason, weapon values are stored in unsigned chars internally in the engine. That means that the max damage a weapon can ever have for one of its ranges is 255.
--We use a asymptotic increase here to allow you to gradually approach the cap, but never actually exceed it.
--If OpenMW ever fully implements ESM4 weapons, there will be no need for the asymptotic increase - and you can just have weapon scaling scale effectively infinitely.
--For now though, this is needed to prevent players weapon damage from rolling over into 0.
function asymptoticIncrease(currentValue)
    local maxLimit = 256
    local growthRate = 0.1  -- Controls the approach speed to the limit
    local maxPercentIncrease = 0.1  -- Maximum increase as a percentage of the current value. Keep this relatively low to discourage weapons from outpacing daedric too quickly. 
    local minIncrement = 1  -- Minimum increment value

    if currentValue >= maxLimit then
        return maxLimit - 1  -- Ensures it never reaches 255
    else
        local increment = growthRate * (maxLimit - currentValue)  -- Calculate potential increment using growth rate
        local maxIncrement = currentValue * maxPercentIncrease  -- Calculate 10% of the current value as the cap
        increment = math.min(increment, maxIncrement)  -- Use the smaller of the two increments
        increment = math.max(increment, minIncrement)  -- Ensure the increment is at least the minimum increment
        local newValue = currentValue + increment
        if newValue >= maxLimit then
            return maxLimit - 1
        else
            return newValue
        end
    end
end

local function round(num)
    return num >= 0 and math.floor(num + 0.5) or math.ceil(num - 0.5)
end

--Some values are stored as a int32_t
--Int32's have a maximum value that it can ever reach before rolling into the negatives.
--We use this here to prevent it from ever rolling over into the negatives.
function clampInt32(value)
    local INT32_MAX = 2147483647
    local INT32_MIN = -2147483648
    return math.min(math.max(value, INT32_MIN), INT32_MAX)
end

--Disables all bound items. Lets not refine those
local itemDenyListBound = {
    ["bound_battle_axe"] = true,
    ["bound_dagger"] = true,
    ["bound_longbow"] = true,
    ["bound_longsword"] = true,
    ["bound_mace"] = true,
    ["bound_spear"] = true
}

-- In Morrowind, there is a bug - that is preserved in OpenMW - where if you create a modified version of an item, that item won't work for quests anymore. This is because when you create a
-- new record, such as by enchanting or refining here, that record won't be counted as the original item for the purposes of those quests.
-- As such, a certain subset of items are warned against refining. Do note that this doesn't cover TR, or other modded content.
local itemDenyListQuest = {
    -- Every item on UESP flagged as 'quest item'
    ["lugrub's axe"] = true,
    ["dwarven war axe_redas"] = true,
    ["ebony staff caper"] = true,
    ["ebony wizard's staff"] = true,
    ["rusty_dagger_unique"] = true,
    ["devil_tanto_tgamg"] = true,
    ["daedric wakizashi_hhst"] = true,
    ["glass_dagger_enamor"] = true,
    ["dart_uniq_judgement"] = true,
    ["dwemer_boots of flying"] = true,
    ["bonemold_gah-julan_hhda"] = true,
    ["bonemold_founders_helm"] = true,
    ["bonemold_tshield_hrlb"] = true,
    ["amulet of ashamanu (unique)"] = true,
    ["amuletfleshmadewhole_uniq"] = true,
    ["amulet_agustas_unique"] = true,
    ["expensive_amulet_delyna"] = true,
    ["expensive_amulet_aeta"] = true,
    ["sarandas_amulet"] = true,
    ["exquisite_amulet_hlervu1"] = true,
    ["julielle_aumines_amulet"] = true,
    ["linus_iulus_maran amulet"] = true,
    ["amulet_skink_unique"] = true,
    ["linus_iulus_stendarran_belt"] = true,
    ["sarandas_belt"] = true,
    ["common_glove_l/r_balmolagmer"] = true,
    ["extravagant_rt_art_wild"] = true,
    ["expensive_glove_left_ilmeni"] = true,
    ["extravagant_glove_left/right_maur"] = true,
    ["common_pants_02_hentus"] = true,
    ["sarandas_pants_2"] = true,
    ["adusamsi's_ring"] = true,
    ["extravagant_ring_aund_uni"] = true,
    ["ring_blackjinx_uniq"] = true,
    ["exquisite_ring_brallion"] = true,
    ["common_ring_danar"] = true,
    ["sarandas_ring_2"] = true,
    ["ring_keley"] = true,
    ["expensive_ring_01_bill"] = true,
    ["expensive_ring_aeta"] = true,
    ["sarandas_ring_1"] = true,
    ["expensive_ring_01_hrdt"] = true,
    ["exquisite_ring_processus"] = true,
    ["ring_dahrkmezalf_uniq"] = true,
    ["extravagant_robe_01_red"] = true,
    ["robe of st roris"] = true,
    ["exquisite_robe_drake's pride"] = true,
    ["sarandas_shirt_2"] = true,
    ["exquisite_shirt_01_rasha"] = true,
    ["sarandas_shoes_2"] = true,
    ["therana's skirt"] = true,
    -- MQ Items. There is dialogue tied to if you have these in specific. Pretty sure the main quest scripts still work with this, but it's probably safer to just include it here.
    ["keening"] = true,
    ["sunder"] = true,
    ["wraithguard"] = true
}

-- By manipulating these items, you don't break quests, instead you just prevent the item from being sold to the Museum in Mournhold for lots of gold.
local itemDenyListMuseum = {
    ["ebony_bow_auriel"] = true,
    ["ebony_shield_auriel"] = true,
    ["bipolar blade"] = true,
    ["bloodworm_helm_unique"] = true,
    ["boots of blinding speed[unique]"] = true,
    ["boots_apostle_unique"] = true,
    ["longbow_shadows_unique"] = true,
    ["claymore_chrysamere_unique"] = true,
    ["cuirass_savior_unique"] = true,
    ["glass dagger_symmachus_unique"] = true,
    ["dragonbone_cuirass_unique"] = true,
    ["ebon_plate_cuirass_unique"] = true,
    ["towershield_eleidon_unique"] = true,
    ["dagger_fang_unique"] = true,
    ["katana_goldbrand_unique"] = true,
    ["helm_bearclaw_unique"] = true,
    ["claymore_iceblade_unique"] = true,
    ["lords_cuirass_unique"] = true,
    ["mace of molag bal_unique"] = true,
    ["mace of slurring"] = true,
    ["ring_phynaster_unique"] = true,
    ["robe_lich_unique"] = true,
    ["warhammer_crusher_unique"] = true,
    ["spear_mercy_unique"] = true,
    ["staff_hasedoki_unique"] = true,
    ["staff_magnus_unique"] = true,
    ["tenpaceboots"] = true,
    ["longsword_umbra_unique"] = true,
    ["ring_vampiric_unique"] = true,
    ["daedric warhammer_ttgd"] = true,
    ["ring_warlock_unique"] = true
}

--Starwind is given special support!
--If you have starwind in your load list, instead 'Anvils' are 'Modification bays', also disables world placement.
local function isStarwind()
    local contentFiles = core.contentFiles.list
    for _, file in ipairs(contentFiles) do
        if string.lower(file):find("starwind") then
            return true
        end
    end
    return false
end

--Our main anvil record - we try to remember this with onsave, on load to avoid populating the save with tons of references to similar objects.
local anvilRecordID = nil

--Creates the item ref! The item ref is slightly different if we are playing in Starwind or not.
local function initializeAnvilReference()
    local anvilDraft = nil
    if isStarwind() then
        anvilDraft = types.Miscellaneous.createRecordDraft({
            name = "Modification Bay",
            weight = 40,
            icon = "icons/weapon-refinement-lua/modification_bay.tga",
            model = "Meshes/Ig/Static/ContFootlocker.nif",
            value = 40
        })
    else
        anvilDraft = types.Miscellaneous.createRecordDraft({
            name = "Anvil",
            weight = 40,
            icon = "icons/weapon-refinement-lua/anvil.tga",
            model = "meshes/f/furn_anvil00.nif",
            value = 40
        })
    end
    anvilRecordID = world.createRecord(anvilDraft).id
end

--This method spawns a few anvils in the world in places a player might find them early on.
--They are pretty common on merchants, but figure its probably for the best to add a couple here as a safeguard.
local function createWorldAnvils()
    if not isStarwind() then
        local a = anvilRecordID
        local anv = world.createObject(a, 1)
        anv:addScript("scripts/weapon-refinement-lua/weapon-refinement-lua-c.lua")
        anv:teleport("Balmora, Guild of Fighters", util.vector3(-49.7944, 563.563, -347.03))

        anv = world.createObject(a, 1)
        anv:addScript("scripts/weapon-refinement-lua/weapon-refinement-lua-c.lua")
        anv:teleport("Seyda Neen, Arrille's Tradehouse", util.vector3(-481.976, 84.7985, 415.97))
    end
end

local function getGlobalAnvil()
    local a = nil
    if anvilRecordID == nil then
        initializeAnvilReference()
        createWorldAnvils()
    end

    a = anvilRecordID
    return a
end

--Used the framework provided by "HD Forge for OpenMW-Lua" for this code section.
--https://modding-openmw.gitlab.io/hd-forge-for-openmw-lua/
local srcId = "furn_anvil00"
local minAngle = 25
local maxAngle = 360 - 25 -- 335

local function replace(obj)
    local angle = math.deg(math.abs(obj.position.y))
	return obj.type == types.Static
        and obj.recordId == srcId
        and not ((angle > minAngle) and (angle < maxAngle))
end

local function onObjectActive(obj)
    if replace(obj) then
        local a = getGlobalAnvil()
        local anv = world.createObject(a, 1)
        anv.enabled = obj.enabled
        anv:setScale(obj.scale)
        anv:teleport(obj.cell, obj.position + obj.rotation * v3(0, 0, 0), obj.rotation)
        anv:addScript("scripts/weapon-refinement-lua/weapon-refinement-lua-c.lua")
        obj:remove()
    end
end
--

local function OnSave()
    local data = {}
    if anvilRecordID ~= nil then
        data.anvilID = anvilRecordID
    end
    return data
end

local function OnLoad(data)
    if data ~= nill then
        if data.anvilID ~= nil then
            anvilRecordID = data.anvilID
        end
    else
        local timer = async:newUnsavableSimulationTimer(
            5,
            function()
                local a = getGlobalAnvil()
            end
        )
    end
end

local function OnInitialize()
    local timer = async:newUnsavableSimulationTimer(
        5,
        function()
            local a = getGlobalAnvil()
        end
    )
end

-- This function calculates the chance to successfully refine a weapon, considering weapon stats and player skills.
local function calculateRefinementSuccess(data, weapon)
    -- Determine the maximum damage output of the weapon to establish a starting difficulty level.
    local weaponMaxDamage = math.max(types.Weapon.record(weapon).chopMaxDamage, 
                                     types.Weapon.record(weapon).thrustMaxDamage, 
                                     types.Weapon.record(weapon).slashMaxDamage)

    local weaponSpeed = types.Weapon.record(weapon).speed
    local enchantCapacity = types.Weapon.record(weapon).enchantCapacity

    -- Base difficulty challenge (DC) calculation, adjusting for weapon damage with logarithmic scaling.
    local baseDC = (weaponMaxDamage / 1.5) + math.log(weaponMaxDamage)
    local exponentialFactor = 0

    -- Increase the difficulty challenge significantly if the weapon's max damage is above 240.
    if weaponMaxDamage > 240 then
        exponentialFactor = (weaponMaxDamage - 240)^2 * 3.42
    end

    -- Calculate the total difficulty challenge, ensuring a minimum DC of 10.
    local totalDC = math.max(10, baseDC) + exponentialFactor

    -- Modify the influence of weapon speed on the refinement process.
    -- Slower speed on a weapon - aka a larger two handed weapon - improves our chances of success.
    -- Without this, fast weapons would objectively be the best weapons to use.
    local speedModifier = math.max(1, 3 - weaponSpeed)

    -- Enchant capacity influence adjustment with diminishing returns beyond 22
    -- Diminishing returns are used to prevent people from approaching the damage cap with just 100 armorer and something with a high enchantmentCapacity, like a Ebony Staff.
    local enchantModifier
    if enchantCapacity <= 22 then
        enchantModifier = 0.5 + ((enchantCapacity - 1) / 21)  -- Scales from 0.5 to 1.5
    else
        -- Apply a logarithmic scale to reduce the rate of increase beyond 22. Most base MW weapons have around 1-22 capacity, while a few outliers have like 90 or so.
        enchantModifier = 1.5 + math.log(enchantCapacity - 21) / math.log(30)
    end

    -- Compute the total skill modifier based on player's skills and attributes, modifying the chance of success.
    local fatigueInfluence = data.fatigue / data.fatigueMax  -- Influence of player fatigue on success chance.
    local skillModifier = (((0.25 * data.armorer) +          -- Armorer skill
                           (0.02 * data.intelligence) +      -- Intelligence,
                           (0.02 * data.agility) +           -- Agility,
                           (0.01 * data.luck)) *             -- Luck,
                           speedModifier) *                  -- Speed modifier,
                           enchantModifier                   -- Enchant Modifier

    -- Randomly determine the refinement roll, influenced by skill modifiers and fatigue.
    local roll = (
        math.random(
            round(math.max(10, (totalDC * 0.10)))
        ) + skillModifier
    ) * fatigueInfluence

    -- Determine if the refinement attempt is successful by comparing the roll to the total DC.
    local isSuccess = roll >= totalDC

    return isSuccess
end

local function incrementWeaponName(weaponName)
    -- Check if the name ends with a space followed by a plus sign and a number
    local baseName, upgradeLevel = string.match(weaponName, "^(.+)%s+%+(%d+)$")
    
    if upgradeLevel then
        -- If it has an upgrade level, increment and clamp it
        upgradeLevel = tonumber(upgradeLevel) + 1
        upgradeLevel = clampInt32(upgradeLevel)
        return baseName .. " +" .. upgradeLevel
    else
        -- If no upgrade level, append "+1" and ensure it stays within 32-bit int bounds
        return weaponName .. " +1"
    end
end

-- Function to replace the equipped weapon with an improved version
local function MainWeaponRefinement(data)
    local player = data.player
    if not player then
        return { success = false, message = 'Could not find player' }
    end

    -- Get the currently equipped weapon in the right hand
    local weapon = types.Actor.getEquipment(player, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if not weapon then
        return { success = false, message = 'No weapon equipped' }
    end

    local tempRecordId = weapon.recordId:lower()
    if itemDenyListBound[tempRecordId] then
        local thisIsBadResult = { success = false, message = "The bound weapon lashes out as you attempt to manipulate it!" }
        player:sendEvent("boundWeaponHurtPlayer", 10)
        player:sendEvent("refinePlaySound", {sound = "Spell Failure Conjuration" } )
        player:sendEvent("displayResultMessage", thisIsBadResult)
        return
    end

    -- Check if the refinement process is successful
    local success, _ = calculateRefinementSuccess(data, weapon)
    if success then
        -- Check if the weapon is on the quest deny list
        if itemDenyListQuest[tempRecordId] then
            local badSaveResult = { success = false, message = "With this item's manipulation, the thread of prophecy is severed. Restore a saved game to restore the weave of fate, or persist in the doomed world you have created." }
            player:sendEvent("displayResultMessage", badSaveResult)
        -- Check if the weapon is on the museum deny list
        elseif itemDenyListMuseum[tempRecordId] then
            local badSaveResult = { success = false, message = "Tampering with this relic diminishes its ancient worth. To preserve its allure for collectors, restore a saved game or bear the diminished riches of your actions." }
            player:sendEvent("displayResultMessage", badSaveResult)
        end

        -- Calculate the value modifier for a weapon based on various skill attributes and a speed modifier.
        local baseValue = types.Weapon.record(weapon).value
        local armorerSkill = data.armorer
        -- Determine the weapon's maximum damage across all attack types
        local weaponMaxDamage = math.max(
            types.Weapon.record(weapon).chopMaxDamage, 
            types.Weapon.record(weapon).thrustMaxDamage, 
            types.Weapon.record(weapon).slashMaxDamage
        )

        -- Cap the scaling factor to the lesser of the weapons max damage * 0.001, or 0.10.
        -- This prevents you from being able to make Pickaxes thousands of gold in a single refine if your armorer skill is high enough.
        local damageBasedScalingFactor = weaponMaxDamage * 0.001
        local scalingFactor = math.min(damageBasedScalingFactor, 0.10)

        -- Calculate diminishing impact of armorer skill as weapon value increases
        -- This is mostly targeted at alchemy enjoyers with millions of armorer
        local armorerImpact = math.max(armorerSkill / 100, 0) * math.log10(1000 / (baseValue / 1000 + 10))

        -- Calculate the value modifier
        local valueModifier = baseValue * scalingFactor * armorerImpact

        -- Ensure the value modifier is at least 1 if the weapon's base value is under 1000
        if baseValue < 1000 then
            valueModifier = math.max(valueModifier, 1)
        else
            -- Ensure that the value modifier is not negative
            valueModifier = math.max(valueModifier, 0)
        end

        -- Create a new weapon draft with improved stats
        local newWeaponDraft = types.Weapon.createRecordDraft({
            name = incrementWeaponName(types.Weapon.record(weapon).name),
            chopMinDamage = asymptoticIncrease(types.Weapon.record(weapon).chopMinDamage),
            chopMaxDamage = asymptoticIncrease(types.Weapon.record(weapon).chopMaxDamage),
            thrustMinDamage = asymptoticIncrease(types.Weapon.record(weapon).thrustMinDamage),
            thrustMaxDamage = asymptoticIncrease(types.Weapon.record(weapon).thrustMaxDamage),
            slashMinDamage = asymptoticIncrease(types.Weapon.record(weapon).slashMinDamage),
            slashMaxDamage = asymptoticIncrease(types.Weapon.record(weapon).slashMaxDamage),
            value = clampInt32(types.Weapon.record(weapon).value + valueModifier),
            template = types.Weapon.record(weapon)
        })

        -- Create the improved weapon record
        local improvedWeaponRecord = world.createRecord(newWeaponDraft)
        if not improvedWeaponRecord then
            return { success = false, message = 'Error in the creation of the improved weapon record' }
        end

        -- Create the improved weapon object from the record
        local improvedWeapon = world.createObject(improvedWeaponRecord.id, 1)
        if not improvedWeapon then
            return { success = false, message = 'Error in the creation of the improved weapon object' }
        end

        -- Move the improved weapon into the player's inventory and remove the old weapon
        improvedWeapon:moveInto(types.Actor.inventory(player))
        core.sendGlobalEvent('UseItem', {object = improvedWeapon, actor = player, force = true})
        weapon:remove(1)

        -- Play sound effect for successful refinement and display success message
        player:sendEvent("refinePlaySound", {sound = "repair" } )
        local string = { success = true, message = "You have received an improved version of your equipped weapon" }
        player:sendEvent("displayResultMessage", string)
        player:sendEvent("SkillUpFromRefine", data)

    else
        -- Play sound effect for failed refinement and display failure message
        player:sendEvent("refinePlaySound", {sound = "repair fail"} )
        local string = { success = true, message = "You have failed to improve the item" }
        player:sendEvent("displayResultMessage", string)
    end
end

--This adds the activator interface for the anvils.
local function giveAnvilActivationInterface(data)
    interface.Activation.addHandlerForObject(
        data.object,
        function(object, actor)
            local stance = types.Actor.getStance(actor)
            if stance == 1 then
                actor:sendEvent("attemptRefineWeapon")
                return false
            else
                return true
            end
        end
    )
end

local function createAnvilForMerchant(data)
    local a = getGlobalAnvil()

    if types.Actor.inventory(data.arg):countOf(a) ~= 1 then
        local anv = world.createObject(a, 1)
        anv:addScript("scripts/weapon-refinement-lua/weapon-refinement-lua-c.lua")
        anv:moveInto(types.Actor.inventory(data.arg))
    end
end

local function addItemToQuestDenyList(itemIds)
    for _, id in pairs(itemIds) do
        itemDenyListQuest[id:lower()] = true
    end
end

local function removeItemFromQuestDenyList(itemIds)
    for _, id in pairs(itemIds) do
        itemDenyListQuest[id:lower()] = nil
    end
end

local function addItemToMuseumDenyList(itemIds)
    for _, id in pairs(itemIds) do
        itemDenyListMuseum[id:lower()] = true
    end
end

local function removeItemFromMuseumDenyList(itemIds)
    for _, id in pairs(itemIds) do
        itemDenyListMuseum[id:lower()] = nil
    end
end

local function addItemToBoundDenyList(itemIds)
    for _, id in pairs(itemIds) do
        itemDenyListBound[id:lower()] = true
    end
end

local function removeItemFromBoundDenyList(itemIds)
    for _, id in pairs(itemIds) do
        itemDenyListBound[id:lower()] = nil
    end
end

return {
    eventHandlers = {
        GiveAnvilActivationInterface = giveAnvilActivationInterface,
        mainWeaponRefinement = MainWeaponRefinement,
        CreateAnvilForMerchant = createAnvilForMerchant
    },
    engineHandlers = {
        onSave = OnSave,
        onLoad = OnLoad,
        onInit = OnInitialize,
        onObjectActive = onObjectActive
    },
    interfaceName = "WeaponRefinementLuaDenyLists",
    interface = {
        AddItemToQuestDenyList = addItemToQuestDenyList,
        RemoveItemFromQuestDenyList = removeItemFromQuestDenyList,
        AddItemToMuseumDenyList = addItemToMuseumDenyList,
        RemoveItemFromMuseumDenyList = removeItemFromMuseumDenyList,
        AddItemToBoundDenyList = addItemToBoundDenyList,
        RemoveItemFromBoundDenyList = removeItemFromBoundDenyList
    }
}
