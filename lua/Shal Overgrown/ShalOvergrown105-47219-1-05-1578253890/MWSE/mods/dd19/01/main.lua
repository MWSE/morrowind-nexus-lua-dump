local function loaded()
	local globalVarName = "dd01_atronach_exp"
	if tes3.getGlobal(globalVarName) then
		local value = 0
		local f = io.open("Data Files/MWSE/mods/AtronachExpansion/main.lua", "r")
		if f then
			io.close(f)
			value = 1
			mwse.log("dd19/01 Atronach Expansion detected")
		end
		tes3.setGlobal(globalVarName, value)
		mwse.log("dd19/01 setting global short %s to %s", globalVarName, value )
	end
end
event.register("loaded", loaded)