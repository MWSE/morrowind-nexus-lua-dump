local config = require("OEA.OEA10 Fresh.config")

local template = mwse.mcm.createTemplate({ name = "Freshly-Picked Fargoth's Rosy Septimland" })
template:saveOnClose("FPFRS", config)

local page = template:createPage()
page.label = "Buttons"
page.noScroll = true
page.indent = 0
page.postCreate = function(self)
	self.elements.innerContainer.paddingAllSides = 10
end

--I really wanted it so people could go back and forth from an FPFRS save to regular one. Hence all the "loaded" shenanigans in other files
page:createInfo{
	label = "To apply changes to these settings, you will need to load a save game. The exception is ".. 
	"the spellTick setting, which is designed to be turned off and on again mid-game as needed."
}

page:createYesNoButton{
	label = "Tie your health entirely to your money?",
	variable = mwse.mcm:createTableVariable{
		id = "Money",
		table = config
	}
}

page:createYesNoButton{
	label = "Utilize FPTRR mechanics? (You can hire Fighters' Guild members, you can only bribe, you must buy books, dungeons require payment, "..
	"and all dialogue topics cost money)",
	variable = mwse.mcm:createTableVariable{
		id = "Money",
		table = config
	}
}

page:createYesNoButton{
	label = "Begin the game as Fargoth?",
	variable = mwse.mcm:createTableVariable{
		id = "AltStart",
		table = config
	}
}

page:createYesNoButton{
	label = "Embark on an epic quest for riches and Septimland? (requires the above three to be on)",
	variable = mwse.mcm:createTableVariable{
		id = "Main",
		table = config
	}
}

page:createYesNoButton{
	label = "Enable the spellTick event? (Disabling this may improve performance, especially when many spells "..
	"are active at once, but will cause drain health effects to no longer modify your money, and fortify health effects "..
	"to lose you money at the end without you having gained any for the duration)",
	variable = mwse.mcm:createTableVariable{
		id = "Tick",
		table = config
	}
}

page:createYesNoButton{
	label = "Use my stopgap dialogue solutions while playing as Fargoth? (Disable this if you want to use Fargoth Alternate Start's dialogue. "..
	"Part of these measures is setting Seyda Neen residents' TalkedToPC flag to 1; if you have been in Seyda Neen before, "..
	"that would not reset for 72 in-game hours)",
	variable = mwse.mcm:createTableVariable{
		id = "Dial",
		table = config
	}
}

mwse.mcm.register(template)