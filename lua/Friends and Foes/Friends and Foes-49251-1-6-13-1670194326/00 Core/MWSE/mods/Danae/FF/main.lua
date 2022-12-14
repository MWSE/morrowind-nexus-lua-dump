local config = include("weaponSheathing.config")

if config then
	if not config.blocked then
		config.blocked = {}
	end
    config.blocked["aa_book01"] = true
    config.blocked["aa_book02"] = true
    config.blocked["aa_book03"] = true
    config.blocked["aa_book04"] = true
    config.blocked["aa_book05"] = true
    config.blocked["aa_book06"] = true
    config.blocked["aa_book07"] = true
    config.blocked["aa_book08"] = true
    config.blocked["aa_book09"] = true
    config.blocked["aa_book10"] = true
    config.blocked["aa_invisible_shield"] = true
    config.blocked["aa_meat"] = true
    config.blocked["aa_shield_staff"] = true
    config.blocked["aa_tankard_com"] = true
    config.blocked["aa_tankard_de"] = true
end