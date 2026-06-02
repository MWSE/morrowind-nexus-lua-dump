---@type conversationCallback
return {
	execute = function(data)
		local firstParticipant = data.conversation.firstParticipant.mobile
		local secondParticipant = data.conversation.secondParticipant.mobile
		if not firstParticipant or not secondParticipant then
			return
		end

		timer.delayOneFrame(function()
			firstParticipant:startCombat(secondParticipant)
			secondParticipant:startCombat(firstParticipant)
		end)
	end,
}
