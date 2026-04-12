local function updateAppearance(e)
    if (e.topic.id == "q_IneoneBelodyn") then
		-- this just updates Ineone's equipment when the relevant quest changes so that the face change is seen right away rather than when armor changes
		local p = tes3.getReference("q_Ineone")
		p:updateEquipment()
	end
end

local function ineoneHead(e)
	if ( string.match(e.reference.id, "q_Ineone")) then
		if ( e.index == tes3.activeBodyPart.head and e.bodyPart.partType == 0 ) then
			local journalIndex = tes3.getJournalIndex{id = "q_IneoneBelodyn"}
			if (journalIndex == 60 or journalIndex == 70) then
				local newFace = tes3.getObject("q_IneoneHead_Bare") --Replace ID here with the head body part you want
				e.bodyPart = newFace
			end
		end
	end
end


local function initialized()
	event.register(tes3.event.bodyPartAssigned, ineoneHead)
	event.register(tes3.event.journal, updateAppearance)
end

event.register(tes3.event.initialized, initialized)