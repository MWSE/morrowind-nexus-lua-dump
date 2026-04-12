local core = require("openmw.core")
local I = require("openmw.interfaces")
local self = require("openmw.self")
local storage = require("openmw.storage")
local types = require("openmw.types")

local sectionAmmoRetrieval = storage.globalSection("SettingsBullseye_ammoRetrieval")

function AmmoHandler(attack)
    if not attack.successful
        or attack.sourceType ~= I.Combat.ATTACK_SOURCE_TYPES.Ranged
    then
        return
    end

    local ammoRecord = types.Weapon.records[attack.ammo]
    local retrieveEnchanted = sectionAmmoRetrieval:get("retrieveEnchantedProjectiles")
    local isThrown = attack.weapon.id == "@0x0"
        -- HOW THE FUCK
        or attack.weapon.type.records[attack.weapon.recordId].type == attack.weapon.type.TYPE.MarksmanThrown
    local retrievalChance = isThrown
        and sectionAmmoRetrieval:get("thrownRetrievalChance")
        or sectionAmmoRetrieval:get("ammoRetrievalChance")

    if math.random() > retrievalChance
        or (not retrieveEnchanted and ammoRecord.enchant)
    then
        return
    end

    core.sendGlobalEvent("Bullseye_retrieveAmmo", {
        actor = self,
        itemRecordId = attack.ammo
    })
end