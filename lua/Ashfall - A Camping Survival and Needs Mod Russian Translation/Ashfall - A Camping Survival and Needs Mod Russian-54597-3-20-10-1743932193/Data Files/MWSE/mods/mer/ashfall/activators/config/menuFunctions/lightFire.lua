local common = require ("mer.ashfall.common.common")
local CraftingFramework = include("CraftingFramework")
local logger = common.createLogger("lightFire")
local DURATION_COST = 10

local function isBlacklisted(e)
    return common.staticConfigs.lightFireBlacklist[e.item.id:lower()] ~= nil
end

local function hasDuration(e)
    return (not e.itemData)
        or e.itemData and e.itemData.timeLeft
        and e.itemData.timeLeft > DURATION_COST
end

local function isLight(e)
    return e.item.objectType == tes3.objectType.light
        and hasDuration(e)
end

local function isFireStarter(e)
    return common.staticConfigs.firestarters[e.item.id:lower()] ~= nil
end


local function filterFireStarter(e)
    if isBlacklisted(e) then
        return false
    end
    return isLight(e) or isFireStarter(e)
end



local function playerHasFlintAndSteel(e)
    --check inventory for flint
    local hasFlint = false
    for _, stack in pairs(common.helper.getInventory()) do
        local flint = CraftingFramework.Material.getMaterial("flint")
        if flint and flint:itemIsMaterial(stack.object.id) then
            hasFlint = true
            break
        end
    end
    --Check for any short or long blade (as the "steel")
    local hasSteel = false
    local steelWeapon = nil
    for _, stack in pairs(common.helper.getInventory()) do
        if stack.object.objectType == tes3.objectType.weapon then
            local validWeaponTypes = {
                [tes3.weaponType.shortBladeOneHand] = true,
                [tes3.weaponType.longBladeOneHand] = true,
                [tes3.weaponType.longBladeTwoClose] = true,
                [tes3.weaponType.axeOneHand] = true,
                [tes3.weaponType.axeTwoHand] = true,
            }
            if validWeaponTypes[stack.object.type] then
                local invalidIdPatterns = {
                    "flint", "chitin", "stone", "glass"
                }
                local invalid = false
                for _, pattern in pairs(invalidIdPatterns) do
                    if stack.object.id:lower():find(pattern) then
                        invalid = true
                        break
                    end
                end
                if not invalid then
                    hasSteel = true
                    steelWeapon = stack.object
                    break
                end
            end
            local validSteelMaterials = {
                metal = true,
                steel = true,
                iron = true
            }
            for material, _ in pairs(validSteelMaterials) do
                local material = CraftingFramework.Material.getMaterial(material)
                if material and material:itemIsMaterial(stack.object.id) then
                    hasSteel = true
                    break
                end
            end
        end
    end
    return (hasFlint and hasSteel), steelWeapon
end

local menuConfig = {
    text = "Зажечь огонь",
    enableRequirements = function(reference)
        return not common.helper.getRefUnderwater(reference)
    end,
    showRequirements = function(reference)
        if not reference.supportsLuaData then return false end
        return (
            not reference.data.isLit and
            reference.data.fuelLevel and
            reference.data.fuelLevel > 0.5
        )
    end,
    tooltip = function()
        return common.helper.showHint("Огонь можно зажечь, поднеся к нему кремень и сталь или факел.")
    end,
    callback = function(reference)
        timer.delayOneFrame(function()
            local hasFlintAndSteel, weapon = playerHasFlintAndSteel()
            if hasFlintAndSteel then
                if weapon then
                    tes3.messageBox(string.format("Вы ударяете куском кремня о %s", weapon.name))
                else
                    tes3.messageBox("Вы разжигаете огонь с помощью кремня и стали.")
                end
                event.trigger("Ashfall:fuelConsumer_Alight", { fuelConsumer = reference, lighterData = nil})
                return
            end
            logger:debug("Opening Inventory Select Menu")
            common.helper.showInventorySelectMenu{
                title = "Выберите чем разжечь",
                noResultsText = "У вас нет ничего, чем можно было бы разжечь огонь.",
                filter = filterFireStarter,
                callback = function(e)
                    if e.item then
                        logger:debug("showInventorySelectMenu Callback")
                        event.trigger("Ashfall:fuelConsumer_Alight", { fuelConsumer = reference, lighterData = e.itemData})
                    end
                end,
            }
        end)
    end,
}

return menuConfig