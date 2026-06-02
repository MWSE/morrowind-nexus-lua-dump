---@type npcFilteringRule
return {
    name = "Combat",
    isMet = function(npc, _)
        return not (npc.mobile and npc.mobile.inCombat)
    end,
}
