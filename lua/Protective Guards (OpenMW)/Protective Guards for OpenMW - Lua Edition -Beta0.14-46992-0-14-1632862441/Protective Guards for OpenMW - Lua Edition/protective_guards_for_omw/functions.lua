local this = {}



this.isGuard = function (actor)
    if (string.match(actor.recordId, "guard") or string.match(actor.recordId, "ordinator") or
        (actor:getEquipment()[1] and actor:getEquipment()[1].recordId:match("imperial") and actor.cell.name:match("Gnisis")))
    then
        return true
    end
		return false
end


return this
