local temperatureController = require("mer.ashfall.temperatureController")
temperatureController.registerBaseTempMultiplier({ id = "masartusShrineEffect" })

---@param e activateEventData
local function pray(e)
	if e.target.id ~= "jsmk_ass_ac_shrine" then
		return
	end
	if tes3.player.data.Ashfall.masartusShrineEffect then
		return
	end
	tes3.messageBox({
		message = "Would you like to pray at the shrine?",
		buttons = { "Yes", "No" },
		callback = function(d)
			if d.button == 0 then
				tes3.playSound({ sound = "restoration cast" })
				tes3.player.data.Ashfall.masartusShrineEffect = 0.8
				tes3.messageBox("The Grace of Solitude: Thank you for your solitude, Lord Vivec. I shall withdraw to lonely places and pray, reflect, contemplate.")
				tes3.messageBox({ message = "You received the Grace of Solitude. Reduce Weather Effects by 20% while on the island of Masartus.", buttons = { "OK" } })
			end
		end,
	})
end
event.register("activate", pray)

---@param e cellChangedEventData
local function disableShrineEffect(e)
    if not tes3.player.data.Ashfall.masartusShrineEffect then
        return
    end
	if e.previousCell and e.previousCell.id:startswith("Masartus") and not e.cell.id:startswith("Masartus") then
		tes3.player.data.Ashfall.masartusShrineEffect = nil
		tes3.messageBox("The Masartus Shrine blessing has worn off.")
	end
end
event.register("cellChanged", disableShrineEffect)
