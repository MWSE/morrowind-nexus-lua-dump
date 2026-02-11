local config = require("sa.atm.config")

local log = mwse.Logger.new()
local util = require("sa.atm.util")
--local augment_creatures = require("sa.atm.util.augment_creatures")
local csvloader = require("sa.atm.util.csvloader")
local crosshair = require("sa.atm.util.crosshair")
local interop = require("sa.atm.interop")
dofile("sa.atm.mcm")

-- Variables

-- Standard weapons table
-- Damage types: 1: Slashing, 2: Piercing, 3: Bludgeoning
-- Swing types: As per the tes3.physicalAttackType
-- 1: Slash, 2: chop, 3: thrust
local standardWeapons = {
       [tes3.weaponType.shortBladeOneHand]  = {1,1,2},
       [tes3.weaponType.longBladeOneHand]   = {1,1,2},
       [tes3.weaponType.longBladeTwoClose]  = {1,1,2},
       [tes3.weaponType.bluntOneHand]       = {3,3,3},
       [tes3.weaponType.bluntTwoClose]      = {3,3,3},
       [tes3.weaponType.bluntTwoWide]       = {3,3,3},
       [tes3.weaponType.spearTwoWide]       = {1,1,2},
       [tes3.weaponType.axeOneHand]         = {1,1,3},
       [tes3.weaponType.axeTwoHand]         = {1,1,3},
       [tes3.weaponType.marksmanBow]        = {2,2,2},
       [tes3.weaponType.marksmanCrossbow]   = {2,2,2},
       [tes3.weaponType.marksmanThrown]     = {2,2,2},
       [tes3.weaponType.arrow]              = {2,2,2},
       [tes3.weaponType.bolt]               = {2,2,2},
       ["kungFu"]                           = {3,3,3},
    }


-- Helper functions

-- Small optimization to not repeat the table lookup
local cacheID = nil
local modifiersCache = {1,1,1,0,0}
--- Return the modifiers of a given creature
---@param id string
local function getCreatureModifiers(id)
    if type(id) ~= "string" then log:debug("Get creature modifiers did not get a string as an argument") return end
    if cacheID and cacheID == id and modifiersCache then
        log:trace("Cache hit for creature modifiers: %s", id)
        return modifiersCache
    end
    local aux = interop.creatures[id:lower()] or {}
    -- Let's safeguard against errors in the table
    modifiersCache =  {
        aux[1] or 1, -- Slashing
        aux[2] or 1, -- Piercing
        aux[3] or 1, -- Bludgeoning
        aux[4] or 0, -- Material
        aux[5] or 0  -- Bonus/Malus
    }
    cacheID = id
    log:trace("Loaded creature modifiers for %s: %s", id, table.concat(modifiersCache, ", "))
    return modifiersCache
end

--- Returns the damage type of a weapon per attack type
--- @param weaponStack tes3equipmentStack | nil
local function getDamageType(weaponStack)
    if not weaponStack then
        log:trace("No weapon equipped, using hand-to-hand.")
        return standardWeapons["kungFu"]
    end
    -- Ensuring the id matches even if it has been enchanted. Needs NC's Consistent Enchanting to populate the data, though
    local id = nil
    if weaponStack.itemData and weaponStack.itemData.data and weaponStack.itemData.data.ncceEnchantedFrom then
        id = weaponStack.itemData.data.ncceEnchantedFrom
    else
        id = (weaponStack.object and weaponStack.object.id) or ""
    end

    local unique = interop.uniqueWeapons[id:lower()]
    if unique then
        log:trace("Unique weapon found: %s", id)
        return unique
    else
        log:trace("Standard weapon type: %s", tostring(weaponStack.object.type))
        return standardWeapons[weaponStack.object.type]
    end
end

-- returns the material of a weapon
local cacheWeaponID
local cacheMaterial
local function getWeaponMaterial(weaponStack)
    if not weaponStack then
        log:trace("No weapon equipped, returning default material.")
        return {0,0.0}
    end
    local id = (weaponStack.object and weaponStack.object.id) or ""
    if id == cacheWeaponID and cacheMaterial then
        log:trace("Cache hit for weapon material: %s", id)
        return cacheMaterial
    end
    cacheWeaponID = id

    -- Ensuring the ID matches the original one if the item was enchanted. Needs NC's Consistent Enchanting to populate the data, though
    if weaponStack.itemData and weaponStack.itemData.data and weaponStack.itemData.data.ncceEnchantedFrom then
        id = weaponStack.itemData.data.ncceEnchantedFrom
    end

    local aux = interop.materialsWeapons[id] or {}
    cacheMaterial = {
        aux[1] or 0,
        aux[2] or 0.0}
    log:trace("Loaded weapon material for %s: %s - %s", id, cacheMaterial[1], cacheMaterial[2])
    return cacheMaterial
end

-- Here we modify the damage
--- @param e attackHitEventData
local function attackHitCallback(e)
    -- If the mod is disabled, exit
    if not config.enabled then log:debug("Mod is disabled, skipping attackHitCallback.") return end

    -- If there is no target, do nothing
    if not e.targetMobile then log:trace("No target mobile in attackHitCallback.") return end

    -- If the attacker is not the player, do nothing
    if e.reference ~= tes3.player then log:trace("Attacker is not player, skipping.") return end
    local AD = tes3.mobilePlayer.actionData
    if not AD then log:debug("Action data is nil for some reason?") return end

    -- Get the attack type
    local attackType = AD.physicalAttackType
    if not attackType then log:debug("Attack type is nil for some reason?: %s",attackType) return end
    -- Special case for projectiles
    if attackType == 4 then attackType = 1 end
    -- Last check
    if attackType < 1 or attackType > 3 then log:debug("Attack type not slash, chop or thrust: %s",attackType) return end

    -- Get the equipped weapon type
    local weapon = tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.weapon})
    local damageTypes = getDamageType(weapon)
    local damageType  = damageTypes and damageTypes[attackType]

    -- Creatures stream. NPC stream (armors, etc.) might come later
    if e.targetReference.baseObject.objectType == tes3.objectType.creature then
        local modifiers = getCreatureModifiers(e.targetReference.baseObject.id) or {1,1,1,0,0}
        local modifier = modifiers and modifiers[damageType] or 1

        local material = {}
        local materialVulnerability = modifiers[4] -- The creature material from the table
        local creatureMaterialBonus = modifiers[5] -- The bonus/malus from the creature table
        if config.materials and materialVulnerability and materialVulnerability > 0 then
            material = getWeaponMaterial(weapon)
            if material[1] == materialVulnerability then
                local bonus = creatureMaterialBonus or material[2] or 0 -- First, use the creatures table value. If there is none, check the weapon default modifier. If there is none, then default to 0.
                log:debug("Material match for %s: +%.2f modifier", e.targetReference.baseObject.id, material[2])
                modifier = modifier + bonus
            end
        end

        log:debug("Final damage modifier for %s: %.2f", e.targetReference.baseObject.id, modifier)
        AD.physicalDamage = modifier*AD.physicalDamage
        -- Feedback
        if modifier ~= 1 then
            if config.messages then
                local modifierIndex = tostring(modifier)
                local text = interop.modifiersMessages[modifierIndex]
                if text then
                    log:trace("Showing notify message: %s", text)
                    tes3ui.showNotifyMenu(text)
                end
            end

            if config.crosshair then
                log:trace("Showing modified crosshair for modifier %.2f", modifier)
                crosshair.showModifiedCrosshair(modifier)
            end
        end
    end
end
event.register(tes3.event.attackHit, attackHitCallback)


   

-- Loading the data into the game
--- @param e initializedEventData
local function initializedCallback(e)
    log:info("Loading creatures.csv...")
    interop.creatures           = csvloader.load("creatures.csv") or {}
    log:info("Loading unique_weapons.csv...")
    interop.uniqueWeapons       = csvloader.load("unique_weapons.csv") or {}
    log:info("Loading materials_weapons.csv...")
    interop.materialsWeapons    = csvloader.load("materials_weapons.csv") or {}
    log:info("Data loading complete.")
  --  augment_creatures.run()
end
event.register(tes3.event.initialized, initializedCallback)