local skillValues = {
    plume = 10,
    ebony = 53,
	daedric = 55
}
local newMaterials = {
    trama = {
        id = "_trama",
        description = "корня трамы",
        ingredients = {
            { id = "ingred_trama_root_01", count = 1 },
        },
        skillReq = skillValues.plume
    },

    cork = {
        id = "_corkbulb",
        description = "корня пробочника",
        ingredients = {
            { id = "ingred_corkbulb_root_01", count = 1 },
        },
        skillReq = skillValues.plume
    },
	
	ebony = {
        id = "_ebony",
        description = "эбонита",
        ingredients = {
            { id = "ingred_raw_ebony_01", count = 1 },
        },
        skillReq = skillValues.ebony
    },
	
	daedric = {
        id = "_daedric",
        description = "сердца даэдра",
        ingredients = {
            { id = "ingred_raw_ebony_01", count = 1 },
			{ id = "ingred_daedras_heart_01", count = 1},
        },
		skillReq = skillValues.daedric
    }
}
local recipes = require("mer.goFletch.recipes")
table.copy(newMaterials, recipes.materials)
mwse.log("[Jay's Fletching for Go Fletch] New recipes registered succesfully!")