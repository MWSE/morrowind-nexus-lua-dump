local this = {}
local logger =
    require("JosephMcKean.restockFilledSoulGems.logging").createLogger(
        "validFilledSoulGems")

local config = require("JosephMcKean.restockFilledSoulGems.config")

this.soulGems = {
    "misc_soulgem_petty", "misc_soulgem_petty", "misc_soulgem_petty",
    "misc_soulgem_lesser", "misc_soulgem_lesser", "misc_soulgem_lesser",
    "misc_soulgem_common", "misc_soulgem_common", "misc_soulgem_greater"
}
this.souls = {
    ["misc_soulgem_petty"] = {},
    ["misc_soulgem_lesser"] = {},
    ["misc_soulgem_common"] = {},
    ["misc_soulgem_greater"] = {}
}
this.stockedFilledSoulGems = {
    ["misc_soulgem_petty"] = {},
    ["misc_soulgem_lesser"] = {},
    ["misc_soulgem_common"] = {},
    ["misc_soulgem_greater"] = {}
}

for creatureID, hasValidSoul in pairs(config.souls) do
    local creature = tes3.getObject(creatureID)
    local lastSoulGem = nil
    if hasValidSoul and creature then
        local soulGemCapacity
        local lastSoulGemCapacity = 32767 -- If some modded soul gem capacity go past this number, don't use it. 
        for soulGem, _ in pairs(this.souls) do
            soulGemCapacity = tes3.getObject(soulGem).soulGemCapacity
            if creature.soul == soulGemCapacity then
                if lastSoulGem then
                    table.removevalue(this.souls[lastSoulGem], creatureID)
                    logger:debug("Remove %s from %s table", creatureID,
                                 lastSoulGem)
                end
                table.insert(this.souls[soulGem], creatureID)
                logger:debug("Insert %s to %s table", creatureID, soulGem)
                goto continue
            elseif creature.soul < soulGemCapacity and soulGemCapacity <
                lastSoulGemCapacity then
                if lastSoulGem then
                    table.removevalue(this.souls[lastSoulGem], creatureID)
                    logger:debug("Remove %s from %s table", creatureID,
                                 lastSoulGem)
                end
                table.insert(this.souls[soulGem], creatureID)
                logger:debug("Insert %s to %s table", creatureID, soulGem)
                lastSoulGem = soulGem
                lastSoulGemCapacity = soulGemCapacity
            else
                logger:debug("Not insert %s to %s table", creatureID, soulGem)
            end
        end
    elseif not creature then
        logger:debug("%s/%s is not a valid creature ID", creatureID, creature)
    end
    ::continue::
    lastSoulGem = nil
end
return this
