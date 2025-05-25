-- Config setup
local cf = mwse.loadConfig("WeaponDamageScaling", { maxDamage = 100, scaleWeapons = true, verboseLogging = true })

-- Armor parts scaling factors
local armorParts = {
    [tes3.armorSlot.helmet] = 0.1,
    [tes3.armorSlot.cuirass] = 0.4,
    [tes3.armorSlot.leftPauldron] = 0.05,
    [tes3.armorSlot.rightPauldron] = 0.05,
    [tes3.armorSlot.greaves] = 0.15,
    [tes3.armorSlot.boots] = 0.15,
    [tes3.armorSlot.leftGauntlet] = 0.05,
    [tes3.armorSlot.rightGauntlet] = 0.05,
    [tes3.armorSlot.leftBracer] = 0.05,
    [tes3.armorSlot.rightBracer] = 0.05
}

local armorSlots = {
    [tes3.armorSlot.helmet] = "Helmet",
    [tes3.armorSlot.cuirass] = "Cuirass",
    [tes3.armorSlot.leftPauldron] = "Left Pauldron",
    [tes3.armorSlot.rightPauldron] = "Right Pauldron",
    [tes3.armorSlot.greaves] = "Greaves",
    [tes3.armorSlot.boots] = "Boots",
    [tes3.armorSlot.leftGauntlet] = "Left Gauntlet",
    [tes3.armorSlot.rightGauntlet] = "Right Gauntlet",
    [tes3.armorSlot.leftBracer] = "Left Bracer",
    [tes3.armorSlot.rightBracer] = "Right Bracer"
}

-- Original weapon stats storage
local originalWeaponStats = {}
local function storeOriginalWeaponStats()
    if cf.verboseLogging then
        mwse.log("[Verbose] Storing original weapon stats.")
    end
    for obj in tes3.iterateObjects(tes3.objectType.weapon) do
        if obj and not originalWeaponStats[obj.id] then
            originalWeaponStats[obj.id] = {
                chopMin = obj.chopMin,
                chopMax = obj.chopMax,
                thrustMin = obj.thrustMin,
                thrustMax = obj.thrustMax,
                slashMin = obj.slashMin,
                slashMax = obj.slashMax
            }
            if cf.verboseLogging then
                mwse.log("[Verbose] Stored stats for weapon: %s", obj.id)
            end
        end
    end
end

-- Ensure Todd exists
local dummyRef = nil
local dummySpawnCell = "ToddTest"
local dummySpawnPos = { 0, 0, 0 }

local function ensureTodd()
    if cf.verboseLogging then
        mwse.log("[Verbose] Ensuring Todd exists.")
    end
    if dummyRef and dummyRef.mobile then return end
    local npc = tes3.createReference({
        object = "Todd",
        position = dummySpawnPos,
        orientation = { 0, 0, 0 },
        cell = dummySpawnCell,
    })
    dummyRef = npc
    if cf.verboseLogging then
        mwse.log("[Verbose] Created reference for Todd.")
    end
end

local function equipBestArmorOnTodd()
    ensureTodd()

    if cf.verboseLogging then
        mwse.log("[Verbose] Equipping best armor on Todd.")
    end

    local bestArmor = {}
    for item in tes3.iterateObjects(tes3.objectType.armor) do
        if armorSlots[item.slot] then
            if not bestArmor[item.slot] or bestArmor[item.slot].armorRating < item.armorRating then
                bestArmor[item.slot] = item
            end
        end
    end

    -- Equip the best armor on Todd
    for slot, armor in pairs(bestArmor) do
        tes3.addItem({ reference = dummyRef, item = armor, count = 1 })
        tes3.mobilePlayer:equip({ reference = dummyRef, item = armor })
        if cf.verboseLogging then
            mwse.log("[Verbose] Equipped armor: %s in slot: %s", armor.id, armorSlots[slot])
        end
    end
end

local function maxToddArmorSkills()
    ensureTodd()

    if cf.verboseLogging then
        mwse.log("[Verbose] Maximizing Todd's armor skills.")
    end
    
    -- Set all armor-related skills to 100
    dummyRef.mobile.skills[tes3.skill.heavyArmor].base = 100
    dummyRef.mobile.skills[tes3.skill.mediumArmor].base = 100
    dummyRef.mobile.skills[tes3.skill.lightArmor].base = 100
    dummyRef.mobile.skills[tes3.skill.unarmored].base = 100

    if cf.verboseLogging then
        mwse.log("[Verbose] Todd's armor skills are now set to 100.")
    end
end

local function getToddTotalArmorRating()
    ensureTodd()
    equipBestArmorOnTodd()
    maxToddArmorSkills()
    
    local totalArmorRating = dummyRef.mobile.armorRating or 0
    if cf.verboseLogging then
        mwse.log("[Verbose] Todd's total armor rating: %.2f", totalArmorRating)
    end
    return totalArmorRating
end

local function getBestWeaponDamage()
    local bestDamage = 0
    if cf.verboseLogging then
        mwse.log("[Verbose] Calculating best weapon damage.")
    end
    for item in tes3.iterateObjects(tes3.objectType.weapon) do
        local stats = originalWeaponStats[item.id]
        if stats then
            local baseDamage = math.max(stats.chopMax, stats.slashMax, stats.thrustMax)
            if baseDamage > bestDamage then
                bestDamage = baseDamage * 1.5
            end
        end
    end
    if cf.verboseLogging then
        mwse.log("[Verbose] Best weapon damage: %.2f", bestDamage)
    end
    return bestDamage
end

local function calculateFinalDamage()
    -- Always reset all weapon stats before doing anything
    for obj in tes3.iterateObjects(tes3.objectType.weapon) do
        local original = originalWeaponStats[obj.id]
        if original then
            obj.chopMax   = original.chopMax
            obj.thrustMax = original.thrustMax
            obj.slashMax  = original.slashMax
        end
    end

    if cf.scaleWeapons and cf.maxDamage > 0 then
        if cf.verboseLogging then
            mwse.log("[Verbose] Scaling weapon damage from original stats (maxDamage = %d).", cf.maxDamage)
        end

        local vanillaBestDamage = 0
        local bestWeapon = nil

        for obj in tes3.iterateObjects(tes3.objectType.weapon) do
            local stats = originalWeaponStats[obj.id]
            if stats then
                local baseDamage = math.max(stats.chopMax, stats.slashMax, stats.thrustMax)
                if baseDamage > vanillaBestDamage then
                    vanillaBestDamage = baseDamage * 1.5
                    bestWeapon = obj
                end
            end
        end

        local totalArmorRating = getToddTotalArmorRating()

        local targetDamage = totalArmorRating + cf.maxDamage
        local adjustmentFactor = 1.0

        if vanillaBestDamage > 0 then
            adjustmentFactor = targetDamage / vanillaBestDamage
        end

        if adjustmentFactor <= 0 then
            adjustmentFactor = 1 + adjustmentFactor
        end

        for obj in tes3.iterateObjects(tes3.objectType.weapon) do
            local original = originalWeaponStats[obj.id]
            if original then
                obj.chopMax   = math.floor(original.chopMax   * adjustmentFactor)
                obj.thrustMax = math.floor(original.thrustMax * adjustmentFactor)
                obj.slashMax  = math.floor(original.slashMax  * adjustmentFactor)

                if cf.verboseLogging then
                    mwse.log("[Verbose] Adjusted %s: chopMax=%d, thrustMax=%d, slashMax=%d (factor %.2f)",
                        obj.id, obj.chopMax, obj.thrustMax, obj.slashMax, adjustmentFactor)
                end
            end
        end

        if cf.verboseLogging then
            mwse.log("[Verbose] Target damage: %.2f (Best weapon base = %.2f, Armor = %.2f, Factor = %.2f)",
                cf.maxDamage, vanillaBestDamage, totalArmorRating, adjustmentFactor)
        end

        return cf.maxDamage
    else
        if cf.verboseLogging then
            mwse.log("[Verbose] Weapon scaling disabled or maxDamage = 0. Restoring original weapon stats.")
        end
        return getBestWeaponDamage()
    end
end




-- MCM setup
local function registerMCM()
    local template = mwse.mcm.createTemplate("Weapon Damage Scaling")
    template:saveOnClose("WeaponDamageScaling", cf)
    template.onClose = function()
        mwse.saveConfig("WeaponDamageScaling", cf)
        calculateFinalDamage()
    end
    local page = template:createSideBarPage({ label = "Settings" })
    local category = page:createCategory("Weapon Damage Scaling Options")
    category:createSlider({
        label = "Max Damage",
        min = 0, max = 500, step = 1, jump = 10,
        variable = mwse.mcm.createTableVariable({ id = "maxDamage", table = cf })
    })
    category:createYesNoButton({
        label = "Scale Weapon Damage",
        variable = mwse.mcm.createTableVariable({ id = "scaleWeapons", table = cf })
    })
    category:createYesNoButton({
        label = "Enable Verbose Logging",
        variable = mwse.mcm.createTableVariable({ id = "verboseLogging", table = cf })
    })
    mwse.mcm.register(template)
end

event.register("modConfigReady", registerMCM)

event.register("loaded", function()
    storeOriginalWeaponStats()
end, { priority = 100 })

event.register("loaded", function()
    if cf.scaleWeapons then
        calculateFinalDamage()
    end
end, { priority = 10 })

event.register("loaded", function()
    mwse.log("[Init] All initialization steps complete.")
end)
