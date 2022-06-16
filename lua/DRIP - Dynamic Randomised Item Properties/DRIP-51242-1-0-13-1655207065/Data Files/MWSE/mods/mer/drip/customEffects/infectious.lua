local common = require("mer.drip.common")
local logger = common.createLogger("Infectious")

local diseaseTypes = {
    blight = {
        infectChance = 0.01,
        resist = "resistBlightDisease",
        spells = {
            "ash-chancre",
            "black-heart blight",
            "chanthrax blight",
            "ash woe blight",
        }
    },
    disease = {
        infectChance = 0.05,
        resist = "resistCommonDisease",
        spells = {
            "ataxia",
            "brown rot",
            "chills",
            "collywobbles",
            "dampworm",
            "droops",
            "greenspore",
            "helljoint",
            "rattles",
            "rockjoint",
            "rust chancre",
            "serpiginous dementia",
            "swamp fever",
            "witbane",
            "witchwither",
            "wither",
            "yellow tick",
        }
    }
}

---@param ref tes3reference
---@param list table<string>
local function alreadyDiseased(ref, list)
    for _, id in pairs(list) do
        local disease = tes3.getObject(id)
        if disease and ref.mobile:isAffectedByObject(disease) then
            return true
        end
    end
end


---@param target tes3reference
---@param diseaseType string
local function applyDisease(target, diseaseType)
    logger:debug("Applying disease %s to %s", diseaseType, target.object.name)
    local typeData = diseaseTypes[diseaseType:lower()]
    local spellList = typeData.spells
    --Roll to infect

    local roll = math.random()
    logger:debug("Rolling to infect. Roll: %s, Infect chance: %s", roll, typeData.infectChance)
    if roll <= typeData.infectChance then
        --Roll to resist
        roll = math.random(100)
        local resist = target.mobile[typeData.resist]
        logger:debug("Rolling to resist. Roll: %s, Resist chance: %s", roll, resist)
        if roll > resist then
            local chosenDiseaseId = table.choice(spellList)
            local chosenDisease = tes3.getObject(chosenDiseaseId)
            logger:debug("Chosen disease: %s. Infecting", chosenDisease.name)
            if chosenDisease then
                if alreadyDiseased(target, spellList) then
                    logger:debug("Already diseased. Skipping")
                    return
                end

                target.data.dripInfected = true
                tes3.addSpell{ reference = target, spell = chosenDisease}
                if target == tes3.player then
                    tes3.messageBox("You have been infected with " .. chosenDisease.name)
                else
                    tes3.messageBox("%s has been inftected with %s", target.object.name, chosenDisease.name)
                end
            end
        end
    end
end


---@param e damagedEventData
local function onDamage(e)
    if not e.source == tes3.damageSource.attack then return end
    local weapon
    --get weapon from projectile
    if e.projectile then
        weapon = e.projectile.firingWeapon
    end
    --Get weapon from attacker
    if e.attackerReference then
        local stack = tes3.getEquippedItem{
            actor = e.attackerReference,
            objectType = tes3.objectType.weapon
        }
        if stack then weapon = stack.object end
    end
    if not weapon then return end
    --Check if weapon is infectious
    local generatedLoot = common.config.persistent.generatedLoot
    local loot = generatedLoot[weapon.id:lower()]
    if loot then
        if loot.modifiers then
            for _, modifier in ipairs(loot.modifiers) do
                if modifier.infectious then
                    --Apply disease to target
                    applyDisease(e.reference, modifier.infectious)
                end
            end
        end
    end
end
event.register("damage", onDamage)