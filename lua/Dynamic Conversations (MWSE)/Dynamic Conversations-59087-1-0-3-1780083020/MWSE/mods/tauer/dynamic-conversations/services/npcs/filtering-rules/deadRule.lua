---@type npcFilteringRule
return {
    name = "Dead",
    isMet = function(npc, _)
        return not (npc.mobile and npc.mobile.isDead)
    end,
}
