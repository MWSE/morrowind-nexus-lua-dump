-- Script for allowing Graphic Herbalism to affect containers that it otherwise wouldn't
local common = require("tamrielData.common")
event.register(tes3.event.initialized, function()
    if common.gh_config then
		--common.gh_config.blacklist["t_glb_fauna_seabiscuit1"] = false
		--common.gh_config.blacklist["t_glb_fauna_seabiscuit2"] = false
		--common.gh_config.blacklist["t_glb_fauna_seabiscuit3"] = false
		--common.gh_config.blacklist["t_glb_fauna_shellauger1"] = false
		--common.gh_config.blacklist["t_glb_fauna_shellauger2"] = false
		--common.gh_config.blacklist["t_glb_fauna_shellauger3"] = false
		--common.gh_config.blacklist["t_glb_fauna_shellauger4"] = false
		--common.gh_config.blacklist["t_glb_fauna_shellckfrg1"] = false
		--common.gh_config.blacklist["t_glb_fauna_shellckfrg2"] = false
		--common.gh_config.blacklist["t_glb_fauna_shellckfrg3"] = false
		--common.gh_config.blacklist["t_glb_fauna_shellckfrg4"] = false
		--common.gh_config.blacklist["t_glb_fauna_shellckfrg5"] = false
		--common.gh_config.blacklist["t_glb_fauna_shellckfrg6"] = false
		--common.gh_config.blacklist["t_glb_fauna_shellcockl1"] = false
		--common.gh_config.blacklist["t_glb_fauna_shellcockl2"] = false
		--common.gh_config.blacklist["t_glb_fauna_shellcockl3"] = false
		--common.gh_config.blacklist["t_glb_fauna_shellcockl4"] = false
		--common.gh_config.blacklist["t_glb_fauna_shellcockl5"] = false
		--common.gh_config.blacklist["t_glb_fauna_shellcockl6"] = false
		--common.gh_config.blacklist["t_glb_fauna_shellconch"] = false
		--common.gh_config.blacklist["t_glb_fauna_shellsnail1"] = false
		--common.gh_config.blacklist["t_glb_fauna_shellsnail2"] = false
		--common.gh_config.blacklist["t_mw_fauna_ventworm_01"] = false
		--common.gh_config.blacklist["t_mw_fauna_ventworm_02"] = false
		--common.gh_config.blacklist["t_mw_fauna_ventworm_03"] = false
		--common.gh_config.blacklist["t_mw_fauna_ventworm_04"] = false
		--common.gh_config.blacklist["t_pi_fauna_fishslvspd1"] = false
		--common.gh_config.blacklist["t_pi_fauna_fishslvspd2"] = false
		--common.gh_config.blacklist["t_pi_fauna_fishslvspd3"] = false

		common.gh_config.whitelist["t_glb_fauna_seabiscuit1"] = true
		common.gh_config.whitelist["t_glb_fauna_seabiscuit2"] = true
		common.gh_config.whitelist["t_glb_fauna_seabiscuit3"] = true
		common.gh_config.whitelist["t_glb_fauna_shellauger1"] = true
		common.gh_config.whitelist["t_glb_fauna_shellauger2"] = true
		common.gh_config.whitelist["t_glb_fauna_shellauger3"] = true
		common.gh_config.whitelist["t_glb_fauna_shellauger4"] = true
		common.gh_config.whitelist["t_glb_fauna_shellckfrg1"] = true
		common.gh_config.whitelist["t_glb_fauna_shellckfrg2"] = true
		common.gh_config.whitelist["t_glb_fauna_shellckfrg3"] = true
		common.gh_config.whitelist["t_glb_fauna_shellckfrg4"] = true
		common.gh_config.whitelist["t_glb_fauna_shellckfrg5"] = true
		common.gh_config.whitelist["t_glb_fauna_shellckfrg6"] = true
		common.gh_config.whitelist["t_glb_fauna_shellcockl1"] = true
		common.gh_config.whitelist["t_glb_fauna_shellcockl2"] = true
		common.gh_config.whitelist["t_glb_fauna_shellcockl3"] = true
		common.gh_config.whitelist["t_glb_fauna_shellcockl4"] = true
		common.gh_config.whitelist["t_glb_fauna_shellcockl5"] = true
		common.gh_config.whitelist["t_glb_fauna_shellcockl6"] = true
		common.gh_config.whitelist["t_glb_fauna_shellconch"] = true
		common.gh_config.whitelist["t_glb_fauna_shellsnail1"] = true
		common.gh_config.whitelist["t_glb_fauna_shellsnail2"] = true
		common.gh_config.whitelist["t_mw_fauna_ventworm_01"] = true
		common.gh_config.whitelist["t_mw_fauna_ventworm_02"] = true
		common.gh_config.whitelist["t_mw_fauna_ventworm_03"] = true
		common.gh_config.whitelist["t_mw_fauna_ventworm_04"] = true
		common.gh_config.whitelist["t_pi_fauna_fishslvspd1"] = true
		common.gh_config.whitelist["t_pi_fauna_fishslvspd2"] = true
		common.gh_config.whitelist["t_pi_fauna_fishslvspd3"] = true

		common.gh_config.blacklist["t_cyr_fauna_nesttant_01"] = true
		common.gh_config.blacklist["t_cyr_fauna_nesttant_02"] = true
		common.gh_config.blacklist["t_cyr_fauna_nesttant_03"] = true
		common.gh_config.blacklist["t_cyr_fauna_nesttant_04"] = true
    end
end)