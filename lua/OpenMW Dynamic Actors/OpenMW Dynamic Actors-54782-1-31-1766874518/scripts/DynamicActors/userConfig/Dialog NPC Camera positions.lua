
return {

	-- for certain NPCs, set a custom position for the camera during dialogue
	-- positive match if the NPC record ID starts with the 'id' string
	-- 'id' string must be entered in lowercase
	-- 'height' is the height at which the camera will center it's view

	{ id = "almalexia", height = 120 },
	{ id = "vivec", height = 109, camAdjust = false },
	{ id = "dagoth_ur", height = 135, distance = 100, camAdjust = false },
	{ id = "yagrum bagarn", height = 95, camAdjust = false },

}

