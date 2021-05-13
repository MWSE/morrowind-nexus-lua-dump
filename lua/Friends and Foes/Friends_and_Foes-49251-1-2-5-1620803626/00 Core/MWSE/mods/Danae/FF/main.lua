local config = include("weaponSheathing.config")

if config then
	if not config.blocked then
		config.blocked = {}
	end
    config.blocked["Hold_it_main_WS.ESP"] = true
    config.blocked["Hold_it_main.ESP"] = true
    config.blocked["Hold_it_main_WS_purist.ESP"] = true

end