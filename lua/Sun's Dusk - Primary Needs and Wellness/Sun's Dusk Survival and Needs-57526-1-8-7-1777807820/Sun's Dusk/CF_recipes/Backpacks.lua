-- Leather function for wildcard ingredients
wildcardFunctions["Any leather"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll()) do
		if (item.recordId:find("hide") or item.recordId:find("pelt") or item.recordId:find("leather")) and (types.Ingredient.objectIsInstance(item) or types.Miscellaneous.objectIsInstance(item)) then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any pillow"] = function()
	local ret = {}
	for _, item in pairs(types.Player.inventory(self):getAll()) do
		if item.recordId:find("_pillow_") and types.Miscellaneous.objectIsInstance(item) then
			table.insert(ret, item)
		end
	end
	table.sort(ret, function(a,b) return a.count > b.count end)
	return ret
end

wildcardFunctions["Any cloth"] = function()
    local ret = {}
    for _, item in pairs(types.Player.inventory(self):getAll()) do
        if (item.recordId:find("cloth"))
        and types.Miscellaneous.objectIsInstance(item) then
            table.insert(ret, item)
        end
    end
    table.sort(ret, function(a,b) return a.count > b.count end)
    return ret
end

return [[Raw data from game files -- DO NOT ALTER												Crafting details						Materials --------------------------------- Materials --------------------------------- Materials 																																	
item code	In-Game Label	Weight	Value	Armor	DPS	Ench	Weight-Class	Subtype	Score	Crafting Category	types.	Crafting Recipe Name (Opt)	Lvl	Req. Skill	rank	faction	ProducedCount (Opt)	Amount Mat 1	Material 1	Amount Mat 2	Material 2	Amount Mat 3	Material 3	Amount Mat 4	Mat 4	Amount Mat 5	Mat 5	Description	disabled	crafting sound	crafting time	experience	1st skill	2nd Level	2nd skill	?	?	ownly's list	leo's lists												
sd_pouch	Pouch	2	16	10		10	light	pauldron	20.07	{-19} Survival	Miscellaneous		1.5	5				5	Any leather											sound/sunsdusk/craft_bedroll.ogg																															
sd_backpack	Backpack	2	16	10		10	light	pauldron	20.07	{-19} Survival	Miscellaneous		1.5	12				5	Any leather	5	iron ore	1	sd_pouch							sound/sunsdusk/craft_bedroll.ogg																															
sd_backpack_traveler										{-19} Survival	Miscellaneous			25				3	Any leather	1	ingred_shalk_resin_01	1	misc_spool_01							sound/sunsdusk/craft_bedroll.ogg																															
sd_backpack_adventurer										{-19} Survival	Miscellaneous			25				3	Any leather	1	ingred_shalk_resin_01	1	misc_spool_01							sound/sunsdusk/craft_bedroll.ogg																															
sd_backpack_velvetblue										{-19} Survival	Miscellaneous			25				1	misc_clothbolt_01	1	ingred_shalk_resin_01	1	misc_spool_01							sound/sunsdusk/craft_bedroll.ogg																															
sd_backpack_satchelbrown										{-19} Survival	Miscellaneous			25				5	Any leather	1	ingred_shalk_resin_01	1	misc_spool_01							sound/sunsdusk/craft_bedroll.ogg																															
sd_backpack_adventurerblue										{-19} Survival	Miscellaneous			25				5	Any leather	1	misc_clothbolt_01	1	ingred_shalk_resin_01							sound/sunsdusk/craft_bedroll.ogg																															
sd_backpack_adventurergreen										{-19} Survival	Miscellaneous			25				5	Any leather	1	misc_clothbolt_03	1	ingred_shalk_resin_01							sound/sunsdusk/craft_bedroll.ogg																															
sd_backpack_velvetbrown										{-19} Survival	Miscellaneous			25				1	misc_clothbolt_02	1	ingred_shalk_resin_01	1	misc_spool_01							sound/sunsdusk/craft_bedroll.ogg																															
sd_backpack_velvetgreen										{-19} Survival	Miscellaneous			25				1	misc_clothbolt_03	1	ingred_shalk_resin_01	1	misc_spool_01							sound/sunsdusk/craft_bedroll.ogg																															
sd_backpack_velvetpink										{-19} Survival	Miscellaneous			25				1	misc_clothbolt_02	5	ingred_heather_01	1	ingred_shalk_resin_01	1	misc_spool_01					sound/sunsdusk/craft_bedroll.ogg																															
sd_backpack_satchelblue										{-19} Survival	Miscellaneous			18				5	Any leather	1	misc_clothbolt_01	1	ingred_shalk_resin_01	1	misc_spool_01					sound/sunsdusk/craft_bedroll.ogg																															
sd_backpack_satchelblack										{-19} Survival	Miscellaneous			18				3	ingred_daedra_skin_01	1	ingred_shalk_resin_01	1	misc_spool_01							sound/sunsdusk/craft_bedroll.ogg																															
sd_backpack_satchelgreen										{-19} Survival	Miscellaneous			18				5	Any leather	1	misc_clothbolt_03	1	ingred_shalk_resin_01	1	misc_spool_01					sound/sunsdusk/craft_bedroll.ogg																															]]