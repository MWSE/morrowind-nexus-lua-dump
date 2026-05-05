---@diagnostic disable: missing-fields, discard-returns
local world = require("openmw.world")
local types = require("openmw.types")
local core = require("openmw.core")

local swordRecordId = "mer_bg_famedSword"

local enchantMagnitudePerRival = 1
local enchantChargePerRival = 10
local minDamagePerRival = 2
local maxDamagePerRival = 3

local function generateFamedSword(data)
    local record = world.createRecord(
        types.Weapon.createRecordDraft {
            template = types.Weapon.records[swordRecordId],
            name     = data.swordName
        }
    )
    local sword = world.createObject(record.id)
    sword:moveInto(data.player)
    data.player:sendEvent("MerlordsTraits_swordRecieved", sword)

    ---@diagnostic disable-next-line: undefined-field
    data.player:sendEvent("ShowMessage", { message = "Your sword has been named " .. record.name .. "." })
    core.sendGlobalEvent('UseItem', { object = sword, actor = data.player })
end

local function upgradeSword(data)
    local inv = data.player.type.inventory(data.player)
    local oldSword = inv:find(data.currSwordRecordId)
    if not oldSword then return end
    local swordWasEquipped = data.player.type.getEquipment(
        data.player,
        data.player.type.EQUIPMENT_SLOT.CarriedRight
    )
    local oldSwordRecord = oldSword.type.records[oldSword.recordId]
    oldSword:remove()

    local swordLevel = data.swordLevel
    local swordInitRecord = types.Weapon.records[swordRecordId]
    local enchantInitRecord = core.magic.enchantments.records[swordInitRecord.enchant]
    local enchEffect = enchantInitRecord.effects[1]

    local newEnchRecord = world.createRecord(
    ---@diagnostic disable-next-line: undefined-field
        core.magic.enchantments.createRecordDraft {
            template = enchantInitRecord,
            charge = enchantInitRecord.charge + enchantChargePerRival * swordLevel,
            effects = { {
                area         = enchEffect.area,
                duration     = enchEffect.duration,
                effect       = enchEffect.effect,
                id           = enchEffect.id,
                index        = enchEffect.index,
                magnitudeMax = enchEffect.magnitudeMax + enchantMagnitudePerRival * swordLevel,
                magnitudeMin = enchEffect.magnitudeMin + enchantMagnitudePerRival * swordLevel,
                range        = enchEffect.range,
            } }
        }
    )

    local newSwordRecord = world.createRecord(
        types.Weapon.createRecordDraft {
            template        = swordInitRecord,
            name            = oldSwordRecord.name,
            enchant         = newEnchRecord.id,
            chopMaxDamage   = swordInitRecord.chopMaxDamage + maxDamagePerRival * swordLevel,
            chopMinDamage   = swordInitRecord.chopMinDamage + minDamagePerRival * swordLevel,
            slashMaxDamage  = swordInitRecord.slashMaxDamage + maxDamagePerRival * swordLevel,
            slashMinDamage  = swordInitRecord.slashMinDamage + minDamagePerRival * swordLevel,
            thrustMaxDamage = swordInitRecord.thrustMaxDamage + maxDamagePerRival * swordLevel,
            thrustMinDamage = swordInitRecord.thrustMinDamage + minDamagePerRival * swordLevel,
        }
    )

    local newSword = world.createObject(newSwordRecord.id)
    newSword:moveInto(inv)

    ---@diagnostic disable-next-line: undefined-field
    data.player:sendEvent("ShowMessage", { message = newSwordRecord.name .. " has grown more powerful." })
    data.player:sendEvent("MerlordsTraits_swordUpgraded", newSword)
    if swordWasEquipped then
        core.sendGlobalEvent('UseItem', { object = newSword, actor = data.player })
    end
end

return {
    eventHandlers = {
        MerlordsTraits_generateFamedSword = generateFamedSword,
        MerlordsTraits_upgradeSword = upgradeSword,
    }
}
