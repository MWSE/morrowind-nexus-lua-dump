local fishId = "jsmk_rw_cr_dyingfish"

---@param e activateEventData
local function saveFish(e)
	if e.activator ~= tes3.player then
		return
	end
	if e.target.baseObject.id ~= fishId then
		return
	end
	tes3.messageBox({
		message = "Would you like to save this dying slaughterfish?",
		buttons = { "Yes", "No" },
		callback = function(data)
			if data.button == 0 then
				e.target:disable()
				e.target:delete()
				tes3.updateJournal({ id = "jsmk_rw", index = 1, showMessage = true })
				tes3.addTopic({ topic = "stranded fish" })
			end
		end,
	})
	return false
end
event.register("activate", saveFish)
