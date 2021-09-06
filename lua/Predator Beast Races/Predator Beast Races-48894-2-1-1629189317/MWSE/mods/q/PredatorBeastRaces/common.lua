local config = include("q.PredatorBeastRaces.config")

local common = {}
common.timers = {}

local function detectChargen()
	common.timers["chargen"] = timer.start{
		iterations = -1,
		duration = 0.1,
		callback = function()

			if tes3.getGlobal("chargenState") ~= -1 then return end

			common.timers["chargen"]:cancel()
			common.timers["chargen"] = nil

			event.trigger("PBR_chargenEnded")
		end
	}
end

common.settings = config
common.beastRaces = {
	["khajiit"] = true,
	["t_els_cathay"] = true,
	["t_els_cathay-raht"] = true,
	["t_els_suthay"] = true,
	["t_els_ohmes"] = true,
	["t_els_ohmes-raht"] = true,
	["war_cathay-raht"] = true,
	["war_dagi-raht"] = true,
	["war_ohmes"] = true,
	["war_senche-raht"] = true,
	["argonian"] = true,
	["godzilla"] = true,
	["shadowscale"] = true,
	["boe_argo_white"] = true,
	["black khajiit"] = true,
	["black panther"] = true,
	["feral mane"] = true,
	["mane"] = true,
	["silver khajiit"] = true,
	["white tiger"] = true,
}
common.khajiitRaces = {
	["khajiit"] = true,
	["t_els_cathay"] = true,
	["t_els_cathay-raht"] = true,
	["t_els_suthay"] = true,
	["t_els_ohmes"] = true,
	["t_els_ohmes-raht"] = true,
	["war_cathay-raht"] = true,
	["war_dagi-raht"] = true,
	["war_ohmes"] = true,
	["war_senche-raht"] = true,
	["black khajiit"] = true,
	["black panther"] = true,
	["feral mane"] = true,
	["mane"] = true,
	["silver khajiit"] = true,
	["white tiger"] = true,
}
common.argonianRaces = {
	["argonian"] = true,
	["godzilla"] = true,
	["shadowscale"] = true,
	["boe_argo_white"] = true,
}
common.khajiitFallDamageSmall = {
	["khajiit"] = true,
	["war_dagi-raht"] = true,
	["black khajiit"] = true,
}
common.khajiitFallDamageMedium = {
	["war_cathay-raht"] = true,
	["t_els_cathay-raht"] = true,
	["war_senche-raht"] = true,
	["feral mane"] = true,
	["silver khajiit"] = true,
}
common.khajiitFallDamageBig = {
	["t_els_cathay"] = true,
	["t_els_suthay"] = true,
	["t_els_ohmes"] = true,
	["t_els_ohmes-raht"] = true,
	["war_ohmes"] = true,
	["black panther"] = true,
	["mane"] = true,
	["white tiger"] = true,
}
common.clawRaceMod = {
	--[[
		If these values are set to 0, the race will behave as any other human race:
		Hand to hand attacks will do fatigue damage. Once the target collapses,
		the attacker will start to deal health damage. If set to any other value,
		they change how much health damage unarmed attack for a race does.
	]]
	["khajiit"] = 1,
	["t_els_cathay"] = 1,
	["t_els_cathay-raht"] = 1,
	["t_els_ohmes"] = 0.3,
	["t_els_ohmes-raht"] = 0.3,
	["t_els_suthay"] = 1,
	["war_cathay-raht"] = 1,
	["war_dagi-raht"] = 1,
	["war_ohmes"] = 0.2,
	["war_senche-raht"] = 1,
	["argonian"] = 1,
	["godzilla"] = 1,
	["shadowscale"] = 1,
	["boe_argo_white"] = 1,
	["black khajiit"] = 1,
	["black panther"] = 0.3,
	["feral mane"] = 1,
	["mane"] = 0.3,
	["silver khajiit"] = 1,
	["white tiger"] = 0.3,
}


function common.isBeast(reference)
	return common.beastRaces[reference.object.race.id:lower()]
end

function common.isArgonian(reference)
	return common.argonianRaces[reference.object.race.id:lower()]
end

function common.isKhajiit(reference)
	return common.khajiitRaces[reference.object.race.id:lower()]
end

function common.playerHeadIsUnderwater()
	local waterLevel = tes3.mobilePlayer.cell.waterLevel
	local minPosition = tes3.mobilePlayer.position.z + tes3.mobilePlayer.height * 0.9

	return minPosition < waterLevel
end

function common.removeSpell(spell, mobile)
	mobile = mobile or tes3.mobilePlayer

	--if mobile:isAffectedByObject(spell) then
		mwscript.removeSpell{ reference = mobile.reference, spell = spell }
	--end
end

function common.addSpell(spell, mobile)
	mobile = mobile or tes3.mobilePlayer

	--if not mobile:isAffectedByObject(spell) then
		mwscript.addSpell{ reference = mobile.reference, spell = spell }
	--end
end

function common.message(text)
	if common.settings.showMessages then
		tes3.messageBox(text)
	end
end

function common.updateSettings(e)
	common.settings = e
end

event.register("initialized", function ()
	event.register("loaded", detectChargen)
end)

return common
