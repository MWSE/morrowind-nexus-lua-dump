-- Disown the Dead

local factionInheritance = true
local includeDisabled = true

--- @param e activationTargetChangedEventData
local function activationTargetChangedCallback(e)
	if e.current then
		local ref = e.current
		if tes3.getOwner(ref) then
			local owner = tes3.getOwner(ref)			
			if owner.objectType == tes3.objectType.npc and owner.cloneCount > 0 then
				ownerRef = tes3.getReference(owner.id)
				if ownerRef.isDead or (includeDisabled and ownerRef.disabled) then
					if factionInheritance and owner.faction then
						tes3.setOwner({ reference = ref, remove = false, owner = owner.faction, requiredRank = owner.factionRank })
					else
						tes3.setOwner({ reference = ref, remove = true })
					end
					ref.modified = true
					tes3.game:clearTarget()
				end
			end
		end
	end
end

event.register(tes3.event.activationTargetChanged, activationTargetChangedCallback)