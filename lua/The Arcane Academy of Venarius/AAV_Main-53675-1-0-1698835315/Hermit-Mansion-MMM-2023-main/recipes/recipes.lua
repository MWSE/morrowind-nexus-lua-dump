local aux_util = require('openmw_aux.util')

local recipes = {
	{input = {ingred_scrap_metal_01 = 3, ["chargen dagger"] = 1}, output = {["dwarven shortsword"] = 1}}, 
	{input = {misc_6th_ash_statue_01 = 1}, output = {ingred_ash_salts_01 = 5}},
	{input = {misc_skull00 = 1}, output = {ingred_bonemeal_01 = 5}},
    {input = {aav_lpfr_marble_38 = 3}, output = {aav_inspiregil = 1}},
    {input = {aav_lpfr_marble_38 = 6}, output = {aav_inspiregilstrong = 1}}
}

--TODO
--	should make these user supplied recipies autogenerate a second recipe page in the cube.
--	addRecipeToBook
return {recipes = recipes}
