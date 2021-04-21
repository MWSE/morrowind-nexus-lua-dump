local this = {}

this.config = mwse.loadConfig("Blood Diversity") or {
	modEnabled = true,
	vampBlood = true,
	ghostBlood = true,
}

local contents

local function createDescription(parent, text)
	parent:destroyChildren()

	local label = parent:createLabel{text=text}
	label.heightProportional = 1.0
	label.widthProportional = 1.0
	label.wrapText = true

	parent:getTopLevelParent():updateLayout()
end


local function createWebsiteLink(parent, name, exec)
	local link = parent:createTextSelect{text=name}
	link.borderLeft = 14

	link.color = tes3ui.getPalette("link_color")
	link.widget.idle = tes3ui.getPalette("link_color")
	link.widget.over = tes3ui.getPalette("link_over_color")
	link.widget.pressed = tes3ui.getPalette("link_pressed_color")

	link:register("mouseClick", function (e)
		tes3.messageBox{
			message = "Open web browser?",
			buttons = {"Yes", "No"},
			callback = function (e)
				if e.button == 0 then
					os.execute(exec)
				end
			end
		}
	end)

	return link
end


local function createCredits(parent)
	parent:destroyChildren()

	local text = "Blood Diversity, Created by Anumaril21\n\nWelcome to the configuration menu! Here you can customize which features of the mod will be turned on or off.\n\nMouse over the individual options for more information.\n\nBlood Diversity provides new blood types for the creatures of Morrowind, Tribunal, Bloodmoon, the Official Plugins, and a variety of mods based on real-world and lore considerations.\n\nThis mod is only possible thanks to the modders listed below. Follow the links provided to discover their own great content.\n\nCredits:"
	local label = parent:createLabel{text=text}
	label.widthProportional = 1.0
	label.borderAllSides = 3
	label.borderBottom = 6
	label.wrapText = true

	local contributors = {
		[1] = {"SpaceDevo", "start https://www.nexusmods.com/morrowind/users/35003500"},
		[2] = {"Reizeron (R-Zero)", "start https://www.nexusmods.com/morrowind/users/3241081"},
		[3] = {"Nullcascade", "start https://www.nexusmods.com/morrowind/users/26153919"},
	}

	for i=1, #contributors do
		local name, url = unpack(contributors[i])
		createWebsiteLink(parent, name, url)
	end

	parent:getTopLevelParent():updateLayout()
end


local function asOnOff(bool)
	return bool and "On" or "Off"
end


local function createFeature(t)
	local block = t.parent:createBlock{}
	block.flowDirection = "left_to_right"
	block.widthProportional = 1.0
	block.autoHeight = true

	local state = this.config[t.key]
	local button = block:createButton{text=asOnOff(state)}
	button:register("mouseClick", function (e)
		this.config[t.key] = not this.config[t.key]
		e.source.text = asOnOff(this.config[t.key])
	end)

	local label = block:createLabel{text=t.label}
	label.borderAllSides = 3

	if t.text and t.textParent then
		label:register("mouseOver", function () createDescription(t.textParent, t.text) end)
		label:register("mouseLeave", function () createCredits(t.textParent) end)
	end

	return button
end

local function createPreferences()
	contents:destroyChildren()
	contents.flowDirection = "left_to_right"

	local left = contents:createBlock{}
	left.flowDirection = "top_to_bottom"
	left.widthProportional = 1.0
	left.heightProportional = 1.0
	left.paddingAllSides = 6

	local right = contents:createThinBorder{}
	right.flowDirection = "top_to_bottom"
	right.widthProportional = 1.0
	right.heightProportional = 1.0
	right.paddingAllSides = 6

	createFeature{
		parent = left,
		key = "modEnabled",
		label = "Enable Blood Diversity",
		textParent = right,
		text = "Enable Blood Diversity\n\nThis option controls whether or not the mod is enabled and enemy blood types are altered.\n\nDefault: On",
	}
	createFeature{
		parent = left,
		key = "vampBlood",
		label = "Alter Vampire Blood",
		textParent = right,
		text = "Alter Vampire Blood\n\nThis option controls whether or not the blood of vampires is altered from the default to the dust blood type, in consideration of the Vampire Dust item.\n\nDefault: On",
	}
	createFeature{
		parent = left,
		key = "ghostBlood",
		label = "Alter Ghost Blood",
		textParent = right,
		text = "Alter Ghost Blood\n\nThis option controls whether or not the blood of Ghost NPCs is altered from the default to the ectoplasm blood type, in consideration of the Ectoplasm item.\n\nDefault: On",
	}

	createCredits(right)

	contents:getTopLevelParent():updateLayout()
end

-- Events
function this.onCreate(parent)
	local tabs = parent:createBlock{}
	tabs.autoWidth, tabs.autoHeight = true, true

	local preferences

	preferences = tabs:createButton{text="Preferences"}
	preferences:register("mouseClick", function (e)
		if preferences.widget.state ~= 1 then
			preferences.widget.state = 1
			createPreferences(contents)
		end
	end)
	
	-- contents container
	contents = parent:createThinBorder{}
	contents.heightProportional = 1.0
	contents.widthProportional = 1.0
	contents.paddingAllSides = 6

	-- default to preferences
	preferences.widget.state = 1
	createPreferences()
end

function this.onClose(parent)
	mwse.saveConfig("Blood Diversity", this.config)
end


event.register("modConfigReady", function (e)
	mwse.registerModConfig("Blood Diversity", this)
end)
------------


return this