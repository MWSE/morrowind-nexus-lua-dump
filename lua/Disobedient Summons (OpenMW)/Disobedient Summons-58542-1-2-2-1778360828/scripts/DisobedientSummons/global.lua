local scriptPath = "scripts/DisobedientSummons/creature.lua"

local function onActorActive(actor)
    if not string.find(actor.recordId, "_summon$")
        or not actor.recordId == "bonewalker_greater_summ"
    then
        return
    end

    actor:addScript(scriptPath)
end

return {
    engineHandlers = {
        onActorActive = onActorActive,
    }
}