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
		message = "Вы хотите помолиться у святилища?",
		buttons = { "Да", "Нет" },
		callback = function(d)
			if d.button == 0 then
				tes3.playSound({ sound = "restoration cast" })
				tes3.player.data.Ashfall.masartusShrineEffect = 0.8
				tes3.messageBox("Благодать уединения: Благодарю вас за уединение, лорд Вивек. Я удалюсь в уединенные места и буду молиться, размышлять, созерцать.")
				tes3.messageBox({ message = "Вы получили Благодать уединения. На время пребывания на острове Масартус погодные эффекты уменьшились на 20%.", buttons = { "OK" } })
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
		tes3.messageBox("Благословение святилища Масартус прекратило свое действие.")
	end
end
event.register("cellChanged", disableShrineEffect)
