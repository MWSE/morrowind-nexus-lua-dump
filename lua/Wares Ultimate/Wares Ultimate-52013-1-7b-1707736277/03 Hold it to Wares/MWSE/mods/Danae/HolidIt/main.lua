local config = include("weaponSheathing.config")

if config then
	if not config.blocked then
		config.blocked = {}
	end
    config.blocked["hold_it_main_ws.esp"] = true
    config.blocked["hold_it_main.esp"] = true
    config.blocked["hold_it_main_ws_purist.esp"] = true
    config.blocked["wares_lists_hold.esp"] = true
    config.blocked["animated_morrowind - merged.esp"] = true
    config.blocked["staff_agency_3_0.esp"] = true
    config.blocked["F&F_base.esm"] = true
    config.blocked["Animated_Morrowind - Danaes Edits.esp"] = true
end