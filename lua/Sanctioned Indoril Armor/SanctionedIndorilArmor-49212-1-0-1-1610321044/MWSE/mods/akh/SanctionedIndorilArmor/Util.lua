local constants = require('akh.SanctionedIndorilArmor.Constants')

local util = {}

function util.isItemIndoril(item)
    if not item or not item.id then
        return false
    end

    return string.startswith(item.id:lower(), "indoril")
end

function util.isOrdinatorInCell(cell)

    for actorRef in tes3.iterate(cell.actors) do
        local actor = tes3.getObject(actorRef.id)
        if actor.class ~= nil and actor.class.id == constants.npcClass.GUARD and actor.faction.id == constants.faction.TEMPLE then
            return true
        end
    end

    return false

end

function util.splitRequiredQuestCompletion(text)
    return text:match("([^=]+)=([^=]+)")
end

return util