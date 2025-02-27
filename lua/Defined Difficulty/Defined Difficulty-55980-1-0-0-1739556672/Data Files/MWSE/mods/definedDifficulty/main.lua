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
        ref.data.definedDifficulty = { ["baseHealth"] = ref.mobile.health.base, ["baseAgility"] = ref.mobile.agility.base, ["healthMod"] = 0, ["agilityMod"] = 0, ["staticDiff"] = diff, ["diff"] = diff }
        ref.modified = true
    else
        log:trace("Saved Mod Data found.")
    end

    return ref.data.definedDifficulty
end


--Combat Difficulty-----------------------------------------------------------------------------------------------------------------------------------------
local function physicalDamage(e)
    if e.attackerReference == nil then return end
    if e.source == "magic" then return end
    log:trace("Physical Damage detected.")

    local diff = (tes3.worldController.difficulty) * 100
    local mod

    if e.attackerReference == tes3.player then
        mod = diff * config.playerDamage
        if mod > config.damageLimitPlayer then
            mod = config.damageLimitPlayer
        end
        if mod < config.damageFloorPlayer then
            mod = config.damageFloorPlayer
        end
        local amount = math.round(e.damage * ((mod + 100) / 100))
        if config.flatValues == true then
            amount = e.damage + mod
        end
        log:debug("Attacker: Player")
        log:debug("Difficulty Slider: " .. diff .. "")
        log:debug("Damage Mod: " .. mod .. "")
        log:debug("Initial Damage: " .. e.damage .. "")
        log:debug("Final Damage: " .. amount .. "")
        e.damage = amount
    elseif e.mobile.reference == tes3.player then
        mod = diff * config.npcDamage
        if mod > config.damageLimitNPC then
            mod = config.damageLimitNPC
        end
        if mod < config.damageFloorNPC then
            mod = config.damageFloorNPC
        end
        local amount = math.round(e.damage * ((mod + 100) / 100))
        if config.flatValues == true then
            amount = e.damage + mod
        end
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
        mod = diff * config.playerDamage
        if mod > config.damageLimitPlayer then
            mod = config.damageLimitPlayer
        end
        if mod < config.damageFloorPlayer then
            mod = config.damageFloorPlayer
        end
        local amount = math.round(e.fatigueDamage * ((mod + 100) / 100))
        if config.flatValues == true then
            amount = e.fatigueDamage + mod
        end
        log:debug("Attacker: Player")
        log:debug("Difficulty Slider: " .. diff .. "")
        log:debug("Damage Mod: " .. mod .. "")
        log:debug("Initial Damage: " .. e.fatigueDamage .. "")
        log:debug("Final Damage: " .. amount .. "")
        e.fatigueDamage = amount
    elseif e.mobile.reference == tes3.player then
        mod = diff * config.npcDamage
        if mod > config.damageLimitNPC then
            mod = config.damageLimitNPC
        end
        if mod < config.damageFloorNPC then
            mod = config.damageFloorNPC
        end
        local amount = math.round(e.fatigueDamage * ((mod + 100) / 100))
        if config.flatValues == true then
            amount = e.fatigueDamage + mod
        end
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

    local diff = (tes3.worldController.difficulty) * 100
    local mod

    if e.target == tes3.player then
        mod = diff * config.playerResist
        if mod > config.resistLimitPlayer then
            mod = config.resistLimitPlayer
        end
        if mod < config.resistFloorPlayer then
            mod = config.resistFloorPlayer
        end
        --local amount = math.round(e.resistedPercent * ((mod + 100) / 100))
        local amount = e.resistedPercent + mod
        if config.capResist == true then
            if amount > 100 then
                amount = 100
            end
        end
        log:debug("Defender: Player")
        log:debug("Difficulty Slider: " .. diff .. "")
        log:debug("Spell Resist Mod: " .. mod .. "")
        log:debug("Initial Resist: " .. e.resistedPercent .. "")
        log:debug("Final Resist: " .. amount .. "")
        e.resistedPercent = amount
    elseif e.caster == tes3.player then
        mod = diff * config.npcResist
        if mod > config.resistLimitNPC then
            mod = config.resistLimitNPC
        end
        if mod < config.resistFloorNPC then
            mod = config.resistFloorNPC
        end
        --local amount = math.round(e.resistedPercent * ((mod + 100) / 100))
        local amount = e.resistedPercent + mod
        if config.capResist == true then
            if amount > 100 then
                amount = 100
            end
        end
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
        mod = diff * config.playerHit
        if mod > config.hitLimitPlayer then
            mod = config.hitLimitPlayer
        end
        if mod < config.hitFloorPlayer then
            mod = config.hitFloorPlayer
        end
        local amount = math.round(e.hitChance * ((mod + 100) / 100))
        if config.flatValues == true then
            amount = e.hitChance + mod
        end
        log:debug("Attacker: Player")
        log:debug("Difficulty Slider: " .. diff .. "")
        log:debug("Hit Mod: " .. mod .. "")
        log:debug("Initial Hit Chance: " .. e.hitChance .. "")
        log:debug("Final Hit Chance: " .. amount .. "")
        e.hitChance = amount
    elseif e.target ~= nil and e.target == tes3.player then
        mod = diff * config.npcHit
        if mod > config.hitLimitNPC then
            mod = config.hitLimitNPC
        end
        if mod < config.hitFloorNPC then
            mod = config.hitFloorNPC
        end
        local amount = math.round(e.hitChance * ((mod + 100) / 100))
        if config.flatValues == true then
            amount = e.hitChance + mod
        end
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

--Health/Agility
local function onMobileActivated(e)
    log:trace("Mobile activation detected.")
    log:debug("Reference: " .. e.reference.object.name .. "")

    if string.startswith(e.reference.object.name, "Summoned") then return end
    if config.affectHealth == false and config.affectAgility == false then return end
    if e.reference.object.objectType == tes3.objectType.npc and config.blacklistNPC[e.reference.baseObject.id:lower()] then log:debug("Blacklisted.") return end
    if e.reference.object.objectType == tes3.objectType.creature and config.blacklistCreature[e.reference.baseObject.id:lower()] then log:debug("Blacklisted.") return end

    local diff = math.round((tes3.worldController.difficulty) * 100)
    local modData = getModData(e.reference, diff)

    if config.affectAgility == true then
        --Config or Difficulty Changed since last met
        if modData.agilityMod ~= config.agilityMod or modData.diff ~= diff then
            local mod = diff * config.agilityMod
            if config.staticMode == true then
                mod = modData.staticDiff * config.agilityMod
                log:debug("Static Difficulty: " .. modData.staticDiff .. "")
            end
            if mod > config.agilityLimit then
                mod = config.agilityLimit
            end
            if mod < config.agilityFloor then
                mod = config.agilityFloor
            end
            local amount = math.round(modData.baseAgility * ((mod + 100) / 100))
            if config.flatValues == true then
                amount = modData.baseAgility + mod
            end
        
            log:debug("Difficulty Slider: " .. diff .. "")
            log:debug("Agility Mod: " .. mod .. "")
            log:debug("Initial Agility: " .. modData.baseAgility .. "")
            log:debug("Final Agility: " .. amount .. "")
        
            --Update Agility
            tes3.setStatistic({ attribute = tes3.attribute.agility, value = amount, reference = e.mobile })
            modData.agilityMod = config.agilityMod
            if config.affectHealth == false then
                modData.diff = diff
            end
        end
    end

    if config.affectHealth == false then return end

    --Config or Difficulty Changed since last met
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
    local mod = config.castMod * diff
    if mod < config.castFloor then
        mod = config.castFloor
    end
    local amount = math.round(e.castChance * ((mod + 100) / 100))
    if config.flatValues == true then
        amount = e.castChance + mod
    end

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
    local mod = config.chargeMod * diff
    if mod > config.chargeLimit then
        mod = config.chargeLimit
    end
    if mod < config.chargeFloor then
        mod = config.chargeFloor
    end

    local amount = e.charge * ((mod + 100) / 100)
    if config.flatValues == true then
        amount = e.charge + mod
    end
    if amount < 1 then
        amount = 1
    end

    log:debug("Difficulty Slider: " .. diff .. "")
    log:debug("Charge Mod: " .. mod .. "")
    log:debug("Initial Charge Cost: " .. e.charge .. "")
    log:debug("Final Charge Cost: " .. amount .. "")

    e.charge = amount
end
if config.affectCharge == true then
    event.register(tes3.event.enchantChargeUse, enchantChargeUse)
end

local function reflectChance(e)
    if e.mobile ~= tes3.mobilePlayer then return end
    log:trace("Reflect Detected.")

    local diff = math.round((tes3.worldController.difficulty) * 100)
    local mod = config.reflectMod * diff
    if mod < config.reflectFloor then
        mod = config.reflectFloor
    end
    local amount = math.round(e.reflectChance * ((mod + 100) / 100))
    if config.flatValues == true then
        amount = e.castChance + mod
    end

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
    local mod = config.lockMod * diff
    if mod < config.lockFloor then
        mod = config.lockFloor
    end
    local amount = math.round(e.chance * ((mod + 100) / 100))
    if config.flatValues == true then
        amount = e.chance + mod
    end

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
    local mod = config.lockMod * diff
    if mod < config.lockFloor then
        mod = config.lockFloor
    end
    local amount = math.round(e.chance * ((mod + 100) / 100))
    if config.flatValues == true then
        amount = e.chance + mod
    end

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
    local mod = config.pocketMod * diff
    if mod < config.pocketFloor then
        mod = config.pocketFloor
    end
    local amount = math.round(e.chance * ((mod + 100) / 100))
    if config.flatValues == true then
        amount = e.chance + mod
    end

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
    local mod = config.alchemyMod * diff
    if mod > config.alchemyLimit then
        mod = config.alchemyLimit
    end
    if mod < config.alchemyFloor then
        mod = config.alchemyFloor
    end
    local amount = math.round(e.potionStrength * ((mod + 100) / 100))
    if config.flatValues == true then
        amount = e.potionStrength + mod
    end
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
        local mod = config.repairMod * diff
        if mod > config.repairLimit then
            mod = config.repairLimit
        end
        if mod < config.repairFloor then
            mod = config.reparFloor
        end
        local amount = math.round(e.repairAmount * ((mod + 100) / 100))
        if config.flatValues == true then
            amount = e.repairAmount + mod
        end
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
    local mod = config.expMod * diff
    if mod > config.expLimit then
        mod = config.expLimit
    end
    if mod < config.expFloor then
        mod = config.expFloor
    end
    local amount = e.progress * ((mod + 100) / 100) --don't round it probably because exp is weird
    if config.flatValues == true then
        amount = e.progress + mod
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
    local mod = config.travelPriceMod * diff
    if mod > config.travelPriceLimit then
        mod = config.travelPriceLimit
    end
    if mod < config.travelPriceFloor then
        mod = config.travelPriceFloor
    end
    local amount = math.round(e.price * ((mod + 100) / 100))
    if config.flatValues == true then
        amount = math.round(e.price + mod)
    end
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
    local mod = config.repairPriceMod * diff
    if mod > config.repairPriceLimit then
        mod = config.repairPriceLimit
    end
    if mod < config.repairPriceFloor then
        mod = config.repairPriceFloor
    end
    local amount = math.round(e.price * ((mod + 100) / 100))
    if config.flatValues == true then
        amount = math.round(e.price + mod)
    end
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
    local mod = config.trainingPriceMod * diff
    if mod > config.trainingPriceLimit then
        mod = config.trainingPriceLimit
    end
    if mod < config.trainingPriceFloor then
        mod = config.trainingPriceFloor
    end
    local amount = math.round(e.price * ((mod + 100) / 100))
    if config.flatValues == true then
        amount = math.round(e.price + mod)
    end
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
    local mod = config.spellmakingPriceMod * diff
    if mod > config.spellmakingPriceLimit then
        mod = config.spellmakingPriceLimit
    end
    if mod < config.spellmakingPriceFloor then
        mod = config.spellmakingPriceFloor
    end
    local amount = math.round(e.price * ((mod + 100) / 100))
    if config.flatValues == true then
        amount = math.round(e.price + mod)
    end
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
    local mod = config.spellmakingPriceMod * diff
    if mod > config.spellmakingPriceLimit then
        mod = config.spellmakingPriceLimit
    end
    if mod < config.spellmakingPriceFloor then
        mod = config.spellmakingPriceFloor
    end
    local amount = math.round(e.price * ((mod + 100) / 100))
    if config.flatValues == true then
        amount = math.round(e.price + mod)
    end
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