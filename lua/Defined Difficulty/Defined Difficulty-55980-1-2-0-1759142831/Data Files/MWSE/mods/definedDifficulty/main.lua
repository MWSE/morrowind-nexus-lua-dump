--Initialize--
local config = require("definedDifficulty.config")
local logger = require("logging.logger")

local log = logger.new {
    name = "Defined Difficulty",
    logLevel = "TRACE",
}
log:setLogLevel(config.logLevel)

local function initialized(e)
    log:info("Initialized.")
end

event.register("initialized", initialized)

local function getModData(ref, diff)
    log:trace("Checking saved Mod Data. (" .. ref.object.name .. ")")

    if not ref.data.definedDifficulty then
        log:info("Mod Data not found, setting to base Mod Data values.")
        ref.data.definedDifficulty = {
            ["baseHealth"] = ref.mobile.health.base, ["baseAtts"] = { ref.mobile.strength.base, ref.mobile.intelligence.base, ref.mobile.willpower.base, ref.mobile.agility.base, ref.mobile.speed.base, ref.mobile.endurance.base, ref.mobile.personality.base, ref.mobile.luck.base },
            ["healthMod"] = 0, ["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 },
            ["staticDiff"] = diff, ["diff"] = diff
        }
        ref.modified = true
    else
        log:trace("Saved Mod Data found.")
        --keep this on for a while
        if ref.data.definedDifficulty["baseAtts"] == nil then
            ref.data.definedDifficulty["baseAtts"] = { ref.mobile.strength.base, ref.mobile.intelligence.base, ref.mobile.willpower.base, ref.mobile.agility.base, ref.mobile.speed.base, ref.mobile.endurance.base, ref.mobile.personality.base, ref.mobile.luck.base }
            ref.data.definedDifficulty["attMods"] = { 0, 0, 0, 0, 0, 0, 0, 0 }
        end
    end

    return ref.data.definedDifficulty
end

-- Helper: compute a modulation value and apply limits/floors
local function computeMod(diff, factor, limit, floor)
    local mod = diff * factor
    if limit and mod > limit then mod = limit end
    if floor and mod < floor then mod = floor end
    return mod
end

-- Helper: apply percent-style modification or flat addition depending on config.flatValues
local function applyPercentMod(initial, mod, doRound)
    if config.flatValues == true then
        local amount = initial + mod
        if doRound then amount = math.round(amount) end
        return amount
    else
        local amount = initial * ((mod + 100) / 100)
        if doRound then amount = math.round(amount) end
        return amount
    end
end

--- @param magicSource tes3spell|tes3enchantment|tes3alchemy
local function isSpellHostile(magicSource)
    for _, effect in ipairs(magicSource.effects) do
        if (effect.object.isHarmful) then
            log:debug("Hostile spell detected.")
            return true
        end
        if config.hostileIllusion then
            if effect.id == tes3.effect.calmCreature or effect.id == tes3.effect.calmHumanoid or effect.id == tes3.effect.charm then
                log:debug("Calm/Charm spell detected.")
                return true
            end
        end
    end
    log:debug("Non-Hostile spell detected.")
    return false
end

local function affectAttribute(ref, cmod, limit, floor, diff, id)
    local modData = getModData(ref, diff)
    local name = tes3.attributeName[id - 1]

    --Config or Difficulty Changed since last met
    if modData.attMods[id] ~= cmod or modData.diff ~= diff then
        local value = diff * cmod
        if config.staticMode == true then
            value = modData.staticDiff * cmod
            log:debug("Static Difficulty: " .. modData.staticDiff .. "")
        end
        if value > limit then
            value = limit
        end
        if value < floor then
            value = floor
        end
        local amount = math.round(modData.baseAtts[id] * ((value + 100) / 100))
        if config.flatValues == true then
            amount = modData.baseAtts[id] + value
        end
    
        log:debug("**" .. string.upper(name) .. "**")
        log:debug("" .. name .. " Mod: " .. value .. "")
        log:debug("Initial " .. name .. ": " .. modData.baseAtts[id] .. "")
        log:debug("Final " .. name .. ": " .. amount .. "")
    
        --Update Attribute
        tes3.setStatistic({ attribute = id - 1, value = amount, reference = ref })
        modData.attMods[id] = cmod
    end
end


--Combat Difficulty-----------------------------------------------------------------------------------------------------------------------------------------
local function physicalDamage(e)
    if e.attackerReference == nil then return end
    if e.source == "magic" then return end
    log:trace("Physical Damage detected.")

    local diff = (tes3.worldController.difficulty) * 100
    local mod

    if e.attackerReference == tes3.player then
        mod = computeMod(diff, config.playerDamage, config.damageLimitPlayer, config.damageFloorPlayer)
        local amount = applyPercentMod(e.damage, mod, true)
        log:debug("Attacker: Player")
        log:debug("Difficulty Slider: " .. diff .. "")
        log:debug("Damage Mod: " .. mod .. "")
        log:debug("Initial Damage: " .. e.damage .. "")
        log:debug("Final Damage: " .. amount .. "")
        e.damage = amount
    elseif e.mobile.reference == tes3.player then
        mod = computeMod(diff, config.npcDamage, config.damageLimitNPC, config.damageFloorNPC)
        local amount = applyPercentMod(e.damage, mod, true)
        log:debug("Attacker: NPC")
        log:debug("Difficulty Slider: " .. diff .. "")
        log:debug("Damage Mod: " .. mod .. "")
        log:debug("Initial Damage: " .. e.damage .. "")
        log:debug("Final Damage: " .. amount .. "")
        e.damage = amount
    end
end
if config.affectDamage == true then
    event.register("damage", physicalDamage)
end

local function damageH2H(e)
    log:trace("Damage H2H detected.")

    if e.attackerReference == nil then return end

    local diff = (tes3.worldController.difficulty) * 100
    local mod

    if e.attackerReference == tes3.player then
        mod = computeMod(diff, config.playerDamage, config.damageLimitPlayer, config.damageFloorPlayer)
        local amount = applyPercentMod(e.fatigueDamage, mod, true)
        log:debug("Attacker: Player")
        log:debug("Difficulty Slider: " .. diff .. "")
        log:debug("Damage Mod: " .. mod .. "")
        log:debug("Initial Damage: " .. e.fatigueDamage .. "")
        log:debug("Final Damage: " .. amount .. "")
        e.fatigueDamage = amount
    elseif e.mobile.reference == tes3.player then
        mod = computeMod(diff, config.npcDamage, config.damageLimitNPC, config.damageFloorNPC)
        local amount = applyPercentMod(e.fatigueDamage, mod, true)
        log:debug("Attacker: NPC")
        log:debug("Difficulty Slider: " .. diff .. "")
        log:debug("Damage Mod: " .. mod .. "")
        log:debug("Initial Damage: " .. e.fatigueDamage .. "")
        log:debug("Final Damage: " .. amount .. "")
        e.fatigueDamage = amount
    end
end
if config.affectDamage == true then
    event.register("damageHandToHand", damageH2H)
end

local function spellResist(e)
    log:trace("Spell Resist check detected.")

    if e.caster == nil then return end
    if config.affectPositiveSpells == false and isSpellHostile(e.source) == false then return end
    if config.affectLockSpells == false and e.effect and (e.effect.id == 12 or e.effect.id == 13) then
        log:debug("Lock/Open spell detected.")
        return
    end
    log:debug("Caster is " .. e.caster.object.name .. " and target is " .. e.target.object.name .. ".")

    local diff = (tes3.worldController.difficulty) * 100
    local mod

    if e.target == tes3.player and e.caster ~= tes3.player then
        mod = computeMod(diff, config.playerResist, config.resistLimitPlayer, config.resistFloorPlayer)
        local amount = e.resistedPercent + mod
        if config.capResist == true and amount > 100 then amount = 100 end
        log:debug("Defender: Player")
        log:debug("Difficulty Slider: " .. diff .. "")
        log:debug("Spell Resist Mod: " .. mod .. "")
        log:debug("Initial Resist: " .. e.resistedPercent .. "")
        log:debug("Final Resist: " .. amount .. "")
        e.resistedPercent = amount
    elseif e.caster == tes3.player and e.target ~= tes3.player then
        mod = computeMod(diff, config.npcResist, config.resistLimitNPC, config.resistFloorNPC)
        local amount = e.resistedPercent + mod
        if config.capResist == true and amount > 100 then amount = 100 end
        log:debug("Defender: NPC")
        log:debug("Difficulty Slider: " .. diff .. "")
        log:debug("Spell Resist Mod: " .. mod .. "")
        log:debug("Initial Resist: " .. e.resistedPercent .. "")
        log:debug("Final Resist: " .. amount .. "")
        e.resistedPercent = amount
    end
end
if config.affectResist == true then
    event.register(tes3.event.spellResist, spellResist)
end

local function calcHitChance(e)
    log:trace("Hit Chance check detected.")

    local diff = (tes3.worldController.difficulty) * 100
    local mod

    if e.attacker == tes3.player then
        mod = computeMod(diff, config.playerHit, config.hitLimitPlayer, config.hitFloorPlayer)
        local amount = applyPercentMod(e.hitChance, mod, true)
        log:debug("Attacker: Player")
        log:debug("Difficulty Slider: " .. diff .. "")
        log:debug("Hit Mod: " .. mod .. "")
        log:debug("Initial Hit Chance: " .. e.hitChance .. "")
        log:debug("Final Hit Chance: " .. amount .. "")
        e.hitChance = amount
    elseif e.target ~= nil and e.target == tes3.player then
        mod = computeMod(diff, config.npcHit, config.hitLimitNPC, config.hitFloorNPC)
        local amount = applyPercentMod(e.hitChance, mod, true)
        log:debug("Attacker: NPC")
        log:debug("Difficulty Slider: " .. diff .. "")
        log:debug("Hit Mod: " .. mod .. "")
        log:debug("Initial Hit Chance: " .. e.hitChance .. "")
        log:debug("Final Hit Chance: " .. amount .. "")
        e.hitChance = amount
    end
end
if config.affectHit == true then
    event.register(tes3.event.calcHitChance, calcHitChance)
end

--Health/Attributes
local function onMobileActivated(e)
    log:trace("Mobile activation detected.")
    log:debug("Reference: " .. e.reference.object.name .. "")

    if (e.reference.object.objectType ~= tes3.objectType.creature and e.reference.object.objectType ~= tes3.objectType.npc) or e.reference.object.name == "" then
        log:debug("Invalid mobile.")
        return
    end
    if string.startswith(e.reference.object.name, "Summoned") then return end
    if e.reference.object.objectType == tes3.objectType.npc and config.blacklistNPC[e.reference.baseObject.id:lower()] then log:debug("Blacklisted.") return end
    if e.reference.object.objectType == tes3.objectType.creature and config.blacklistCreature[e.reference.baseObject.id:lower()] then log:debug("Blacklisted.") return end

    local diff = math.round((tes3.worldController.difficulty) * 100)
    log:debug("Difficulty Slider: " .. diff .. "")
    local modData = getModData(e.reference, diff)

    affectAttribute(e.reference, config.strengthMod, config.strengthLimit, config.strengthFloor, diff, 1)
    affectAttribute(e.reference, config.intelligenceMod, config.intelligenceLimit, config.intelligenceFloor, diff, 2)
    affectAttribute(e.reference, config.willpowerMod, config.willpowerLimit, config.willpowerFloor, diff, 3)
    affectAttribute(e.reference, config.agilityMod, config.agilityLimit, config.agilityFloor, diff, 4)
    affectAttribute(e.reference, config.speedMod, config.speedLimit, config.speedFloor, diff, 5)
    affectAttribute(e.reference, config.enduranceMod, config.enduranceLimit, config.enduranceFloor, diff, 6)
    affectAttribute(e.reference, config.personalityMod, config.personalityLimit, config.personalityFloor, diff, 7)
    affectAttribute(e.reference, config.luckMod, config.luckLimit, config.luckFloor, diff, 8)

    if config.affectHealth == false or e.mobile.health.current <= 0 then
        modData.diff = diff
        return
    end

    if modData.healthMod ~= config.healthMod or modData.diff ~= diff then
        local mod = diff * config.healthMod
        if config.staticMode == true then
            mod = modData.staticDiff * config.healthMod
            log:debug("Static Difficulty: " .. modData.staticDiff .. "")
        end
        if mod > config.healthLimit then
            mod = config.healthLimit
        end
        if mod < config.healthFloor then
            mod = config.healthFloor
        end
        local amount = math.round(modData.baseHealth * ((mod + 100) / 100))
        if config.flatValues == true then
            amount = modData.baseHealth + mod
        end
        if amount < 1 then
            amount = 1
        end
    
        log:debug("Reference: " .. e.reference.object.name .. "")
        log:debug("Difficulty Slider: " .. diff .. "")
        log:debug("Health Mod: " .. mod .. "")
        log:debug("Initial Health: " .. modData.baseHealth .. "")
        log:debug("Final Health: " .. amount .. "")
    
        --Update Health
        tes3.setStatistic({ name = "health", value = amount, reference = e.mobile })
        modData.healthMod = config.healthMod
        modData.diff = diff
    end
end
event.register("mobileActivated", onMobileActivated)

local function castChance(e)
    if config.affectCastChance == false then return end
    if e.caster ~= tes3.player then return end
    log:trace("Cast Detected.")

    local diff = math.round((tes3.worldController.difficulty) * 100)
    local mod = computeMod(diff, config.castMod, nil, config.castFloor)
    local amount = applyPercentMod(e.castChance, mod, true)

    log:debug("Difficulty Slider: " .. diff .. "")
    log:debug("Cast Mod: " .. mod .. "")
    log:debug("Initial Cast Chance: " .. e.castChance .. "")
    log:debug("Final Cast Chance: " .. amount .. "")

    e.castChance = amount
end
event.register(tes3.event.spellCast, castChance)

local function enchantChargeUse(e)
    if config.affectCharge == false or e.caster ~= tes3.player then return end
    log:trace("Charge Use Detected.")

    local diff = math.round((tes3.worldController.difficulty) * 100)
    local mod = computeMod(diff, config.chargeMod, config.chargeLimit, config.chargeFloor)
    local amount = applyPercentMod(e.charge, mod, false)
    if amount < 1 then
        amount = 1
    end

    log:trace("Difficulty Slider: " .. diff .. "")
    log:trace("Charge Mod: " .. mod .. "")
    log:trace("Initial Charge Cost: " .. e.charge .. "")
    log:trace("Final Charge Cost: " .. amount .. "")

    e.charge = amount
end
if config.affectCharge == true then
    event.register(tes3.event.enchantChargeUse, enchantChargeUse)
end

local function reflectChance(e)
    if e.mobile ~= tes3.mobilePlayer then return end
    log:trace("Reflect Detected.")

    local diff = math.round((tes3.worldController.difficulty) * 100)
    local mod = computeMod(diff, config.reflectMod, nil, config.reflectFloor)
    local amount = applyPercentMod(e.reflectChance, mod, true)

    log:debug("Difficulty Slider: " .. diff .. "")
    log:debug("Reflect Mod: " .. mod .. "")
    log:debug("Initial Reflect Chance: " .. e.reflectChance .. "")
    log:debug("Final Reflect Chance: " .. amount .. "")

    e.reflectChance = amount
end
if config.affectReflect == true then
    event.register(tes3.event.magicReflect, reflectChance)
end



--Non-Combat Difficulty---------------------------------------------------------------------------------------------------------------------
local function lockPick(e)
    if config.affectLocks == false then return end
    if e.picker ~= tes3.mobilePlayer then return end
    log:trace("Lockpicking Detected.")

    local diff = math.round((tes3.worldController.difficulty) * 100)
    local mod = computeMod(diff, config.lockMod, nil, config.lockFloor)
    local amount = applyPercentMod(e.chance, mod, true)

    log:debug("Difficulty Slider: " .. diff .. "")
    log:debug("Lock Mod: " .. mod .. "")
    log:debug("Initial Pick Chance: " .. e.chance .. "")
    log:debug("Final Pick Chance: " .. amount .. "")

    e.chance = amount
end
event.register(tes3.event.lockPick, lockPick)

local function disarm(e)
    if config.affectLocks == false then return end
    if e.disarmer ~= tes3.mobilePlayer then return end
    log:trace("Trap Disarm Detected.")

    local diff = math.round((tes3.worldController.difficulty) * 100)
    local mod = computeMod(diff, config.lockMod, nil, config.lockFloor)
    local amount = applyPercentMod(e.chance, mod, true)

    log:debug("Difficulty Slider: " .. diff .. "")
    log:debug("Disarm Mod: " .. mod .. "")
    log:debug("Initial Disarm Chance: " .. e.chance .. "")
    log:debug("Final Disarm Chance: " .. amount .. "")

    e.chance = amount
end
event.register(tes3.event.trapDisarm, disarm)

local function pickpocket(e)
    if config.affectPockets == false then return end
    log:trace("Pickpocket Detected.")

    local diff = math.round((tes3.worldController.difficulty) * 100)
    local mod = computeMod(diff, config.pocketMod, nil, config.pocketFloor)
    local amount = applyPercentMod(e.chance, mod, true)

    log:debug("Difficulty Slider: " .. diff .. "")
    log:debug("Pickpocket Mod: " .. mod .. "")
    log:debug("Initial Pickpocket Chance: " .. e.chance .. "")
    log:debug("Final Pickpocket Chance: " .. amount .. "")

    e.chance = amount
end
event.register(tes3.event.pickpocket, pickpocket)

local function potionStrength(e)
    if config.affectAlchemy == false or e.potionStrength < 0 then return end
    log:trace("Alchemy Detected.")

    local diff = math.round((tes3.worldController.difficulty) * 100)
    local mod = computeMod(diff, config.alchemyMod, config.alchemyLimit, config.alchemyFloor)
    local amount = applyPercentMod(e.potionStrength, mod, true)
    if amount < -1 then
        amount = -1
        log:info("Alchemy settings caused potion to fail!")
    end

    log:debug("Difficulty Slider: " .. diff .. "")
    log:debug("Alchemy Mod: " .. mod .. "")
    log:debug("Initial Potion Strength: " .. e.potionStrength .. "")
    log:debug("Final Potion Strength: " .. amount .. "")

    e.potionStrength = amount
end
event.register(tes3.event.potionBrewSkillCheck, potionStrength)

local function repair(e)
    if config.affectRepair == false then return end
    if e.repairer and e.repairer == tes3.mobilePlayer then
        log:trace("Player Repair Detected.")

        local diff = math.round((tes3.worldController.difficulty) * 100)
        local mod = computeMod(diff, config.repairMod, config.repairLimit, config.repairFloor)
        local amount = applyPercentMod(e.repairAmount, mod, true)
        if amount < 1 then
            amount = 1
        end
    
        log:debug("Difficulty Slider: " .. diff .. "")
        log:debug("Repair Mod: " .. mod .. "")
        log:debug("Initial Repair Amount: " .. e.repairAmount .. "")
        log:debug("Final Repair Amount: " .. amount .. "")
    
        e.repairAmount = amount
    end
end
event.register(tes3.event.repair, repair)

local function skillExperience(e)
    log:trace("Skill Exercise Detected.")

    local diff = math.round((tes3.worldController.difficulty) * 100)
    local mod = computeMod(diff, config.expMod, config.expLimit, config.expFloor)
    local amount
    if config.flatValues == true then
        amount = e.progress + mod
    else
        amount = e.progress * ((mod + 100) / 100)
    end
    if amount < 0 then
        amount = 0
        log:info("Experience settings caused Skill EXP to reduce to 0!")
    end

    log:debug("Difficulty Slider: " .. diff .. "")
    log:debug("EXP Mod: " .. mod .. "")
    log:debug("Initial Skill Experience: " .. e.progress .. "")
    log:debug("Final Skill Experience: " .. amount .. "")

    e.progress = amount
end
--same thing as above
if config.affectExperience == true then
    event.register(tes3.event.exerciseSkill, skillExperience)
end



--Economy-----------------------------------------------------------------------------------------------------------------------
local function calcTravelPrice(e)
    if config.affectTravelPrice == false then return end
    log:trace("Travel Price Calc Detected.")

    local diff = math.round((tes3.worldController.difficulty) * 100)
    local mod = computeMod(diff, config.travelPriceMod, config.travelPriceLimit, config.travelPriceFloor)
    local amount = applyPercentMod(e.price, mod, true)
    if amount < 1 then
        amount = 1
    end

    log:debug("Difficulty Slider: " .. diff .. "")
    log:debug("Travel Mod: " .. mod .. "")
    log:debug("Initial Travel Price: " .. e.price .. "")
    log:debug("Final Travel Price: " .. amount .. "")

    e.price = amount
end
event.register(tes3.event.calcTravelPrice, calcTravelPrice)

local function calcRepairPrice(e)
    if config.affectRepairPrice == false then return end
    log:trace("Repair Price Calc Detected.")

    local diff = math.round((tes3.worldController.difficulty) * 100)
    local mod = computeMod(diff, config.repairPriceMod, config.repairPriceLimit, config.repairPriceFloor)
    local amount = applyPercentMod(e.price, mod, true)
    if amount < 1 then
        amount = 1
    end

    log:debug("Difficulty Slider: " .. diff .. "")
    log:debug("Repair Price Mod: " .. mod .. "")
    log:debug("Initial Repair Price: " .. e.price .. "")
    log:debug("Final Repair Price: " .. amount .. "")

    e.price = amount
end
event.register(tes3.event.calcRepairPrice, calcRepairPrice)

local function calcTrainingPrice(e)
    if config.affectTrainingPrice == false then return end
    log:trace("Training Price Calc Detected.")

    local diff = math.round((tes3.worldController.difficulty) * 100)
    local mod = computeMod(diff, config.trainingPriceMod, config.trainingPriceLimit, config.trainingPriceFloor)
    local amount = applyPercentMod(e.price, mod, true)
    if amount < 1 then
        amount = 1
    end

    log:debug("Difficulty Slider: " .. diff .. "")
    log:debug("Training Price Mod: " .. mod .. "")
    log:debug("Initial Training Price: " .. e.price .. "")
    log:debug("Final Training Price: " .. amount .. "")

    e.price = amount
end
event.register(tes3.event.calcTrainingPrice, calcTrainingPrice)

local function calcSpellmakingPrice(e)
    if config.affectSpellmakingPrice == false then return end
    log:trace("Spellmaking Price Calc Detected.")

    local diff = math.round((tes3.worldController.difficulty) * 100)
    local mod = computeMod(diff, config.spellmakingPriceMod, config.spellmakingPriceLimit, config.spellmakingPriceFloor)
    local amount = applyPercentMod(e.price, mod, true)
    if amount < 1 then
        amount = 1
    end

    log:debug("Difficulty Slider: " .. diff .. "")
    log:debug("Spellmaking Price Mod: " .. mod .. "")
    log:debug("Initial Spellmaking Price: " .. e.price .. "")
    log:debug("Final Spellmaking Price: " .. amount .. "")

    e.price = amount
end
event.register(tes3.event.calcSpellmakingPrice, calcSpellmakingPrice)

local function calcEnchantmentPrice(e)
    if config.affectEnchantingPrice == false then return end
    log:trace("Enchanting Price Calc Detected.")

    local diff = math.round((tes3.worldController.difficulty) * 100)
    local mod = computeMod(diff, config.spellmakingPriceMod, config.spellmakingPriceLimit, config.spellmakingPriceFloor)
    local amount = applyPercentMod(e.price, mod, true)
    if amount < 1 then
        amount = 1
    end

    log:debug("Difficulty Slider: " .. diff .. "")
    log:debug("Enchanting Price Mod: " .. mod .. "")
    log:debug("Initial Enchanting Price: " .. e.price .. "")
    log:debug("Final Enchanting Price: " .. amount .. "")

    e.price = amount
end
event.register(tes3.event.calcEnchantmentPrice, calcEnchantmentPrice)


--
--Config Stuff------------------------------------------------------------------------------------------------------------------------------
--

event.register("modConfigReady", function()
	require("definedDifficulty.mcm")
	config = require("definedDifficulty.config")
end)