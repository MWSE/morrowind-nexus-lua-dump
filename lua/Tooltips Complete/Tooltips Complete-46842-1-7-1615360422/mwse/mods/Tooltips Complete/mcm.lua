local this = {}

this.config = mwse.loadConfig("tooltipsComplete") or {
	menuOnly = true,
	keyTooltips = true,
	questTooltips = true,
	uniqueTooltips = true,
	artifactTooltips = true,
	armorTooltips = true,
	weaponTooltips = true,
	toolTooltips = true,
	soulgemTooltips = true,
	miscTooltips = true,
	lightTooltips = true,
	bookTooltips = true,
	clothingTooltips = true,
	potionTooltips = true,
	ingredientTooltips = true,
	scrollTooltips = true,
	tamrielicLore = false,
	ingredientFlavor = false,
	blocked = {
	
	}
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

	local text = "Tooltips Complete, Created by Anumaril21\n\nWelcome to the configuration menu! Here you can customize which features of the mod will be turned on or off.\n\nMouse over the individual options for more information.\n\nTooltips Complete provides helpful and lore-friendly flavour texts for nearly every item in Morrowind, Tribunal, Bloodmoon, the Official Plugins, and an expanding collection of mods.\n\nThis mod is only possible thanks to the modders listed below. Follow the links provided to discover their own great content.\n\nCredits:"
	local label = parent:createLabel{text=text}
	label.widthProportional = 1.0
	label.borderAllSides = 3
	label.borderBottom = 6
	label.wrapText = true

	local contributors = {
		[1] = {"Flash3113", "start https://www.nexusmods.com/morrowind/users/899234?tab=user+files"},
		[2] = {"PhDInSorcery", "start https://www.nexusmods.com/morrowind/users/8404526?tab=user+files"},
		[3] = {"Greatness7", "start https://www.nexusmods.com/morrowind/users/64030?tab=user+files"},
		[4] = {"Merlord", "start https://www.nexusmods.com/morrowind/users/3040468?tab=user+files"},
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
		key = "menuOnly",
		label = "Show Tooltips Only in Menus",
		textParent = right,
		text = "Show Tooltips Only in Menus\n\nThis option controls whether or not item descriptions will only be viewable while the menu is open.\n\nDefault: On",
	}
	createFeature{
		parent = left,
		key = "questTooltips",
		label = "Show Quest Item Tooltips",
		textParent = right,
		text = "Show Quest Item Tooltips\n\nThis option controls whether or not items required for specific quests are provided with spoiler-free item descriptions in their tooltips.\n\nDefault: On",
	}
	createFeature{
		parent = left,
		key = "uniqueTooltips",
		label = "Show Unique Item Tooltips",
		textParent = right,
		text = "Show Unique Item Tooltips\n\nThis option controls whether or not unique items discovered during your journey or rewarded during quests are provided with relevant item descriptions in their tooltips.\n\nDefault: On",
	}
	createFeature{
		parent = left,
		key = "artifactTooltips",
		label = "Show Artifact Tooltips",
		textParent = right,
		text = "Show Artifact Tooltips\n\nThis option controls whether or not legendary artifacts discovered during your journey or rewarded during quests are provided with lore-accurate item descriptions in their tooltips.\n\nThis option should be disabled when using Tamrielic Lore Tooltips by PhDinSorcery.\n\nDefault: On",
	}
	createFeature{
		parent = left,
		key = "armorTooltips",
		label = "Show Armor Tooltips",
		textParent = right,
		text = "Show Armor Tooltips\n\nThis option controls whether or not base armor and generic magic armor discovered during your journey are provided with lore-friendly item descriptions in their tooltips.\n\nDefault: On",
	}
	createFeature{
		parent = left,
		key = "weaponTooltips",
		label = "Show Weapon Tooltips",
		textParent = right,
		text = "Show Weapon Tooltips\n\nThis option controls whether or not base weapons and generic magic weapons discovered during your journey are provided with lore-friendly item descriptions in their tooltips.\n\nDefault: On",
	}
	createFeature{
		parent = left,
		key = "clothingTooltips",
		label = "Show Clothing Tooltips",
		textParent = right,
		text = "Show Clothing Tooltips\n\nThis option controls whether or not base clothings and generic magic clothings discovered during your journey are provided with lore-friendly item descriptions in their tooltips.\n\nDefault: On",
	}
	createFeature{
		parent = left,
		key = "keyTooltips",
		label = "Show Key Tooltips",
		textParent = right,
		text = "Show custom scabbards and quivers\n\nThis option controls whether or not keys and propylon indices discovered during your journey are provided with relevant item descriptions in their tooltips.\n\nDefault: On",
	}
	createFeature{
		parent = left,
		key = "toolTooltips",
		label = "Show Tool Tooltips",
		textParent = right,
		text = "Show Tool Tooltips\n\nThis option controls whether or not lockpicks, probes, repair, and alchemy items discovered during your journey are provided with relevant item descriptions in their tooltips.\n\nDefault: On",
	}
	createFeature{
		parent = left,
		key = "soulgemTooltips",
		label = "Show Soul Gem Tooltips",
		textParent = right,
		text = "Show Soul Gem Tooltips\n\nThis option controls whether or not soul gems discovered during your journey are provided with relevant item descriptions in their tooltips when empty, and lore-friendly descriptions based on their trapped creature when full.\n\nDefault: On",
	}
	createFeature{
		parent = left,
		key = "bookTooltips",
		label = "Show Book Tooltips",
		textParent = right,
		text = "Show Book Tooltips\n\nThis option controls whether or not books and notes discovered during your journey are provided with relevant item descriptions in their tooltips.\n\nDefault: On",
	}
	createFeature{
		parent = left,
		key = "potionTooltips",
		label = "Show Potion Tooltips",
		textParent = right,
		text = "Show Potion Tooltips\n\nThis option controls whether or not magical potions discovered during your journey are provided with relevant item descriptions in their tooltips.\n\nDefault: On",
	}
	createFeature{
		parent = left,
		key = "scrollTooltips",
		label = "Show Scroll Tooltips",
		textParent = right,
		text = "Show Scroll Tooltips\n\nThis option controls whether or not magical scrolls discovered during your journey are provided with relevant item descriptions in their tooltips.\n\nDefault: On",
	}
	createFeature{
		parent = left,
		key = "ingredientTooltips",
		label = "Show Ingredient Tooltips",
		textParent = right,
		text = "Show Ingredient Tooltips\n\nThis option controls whether or not ingredients and beverages discovered during your journey are provided with relevant and lore-friendly item descriptions in their tooltips.\n\nThis option should be disabled when using Ingredient Flavor Texts by Flash3113.\n\nDefault: On",
	}
	createFeature{
		parent = left,
		key = "lightTooltips",
		label = "Show Light Tooltips",
		textParent = right,
		text = "Show Light Tooltips\n\nThis option controls whether or not equip-able lights discovered during your journey are provided with relevant item descriptions in their tooltips.\n\nDefault: On",
	}
	createFeature{
		parent = left,
		key = "miscTooltips",
		label = "Show Clutter Tooltips",
		textParent = right,
		text = "Show Clutter Tooltips\n\nThis option controls whether or not miscellaneous objects and clutter are provided with relevant and lore-friendly item descriptions in their tooltips.\n\nDefault: On",
	}

	createCredits(right)

	contents:getTopLevelParent():updateLayout()
end
	
-- Exclusions
local function getSortedModList()
	local list = tes3.getModList()
	for i, name in pairs(list) do
		list[i] = name:lower()
	end
	table.sort(list)
	return list
end

local function getSortedObjectList(objectType, slot)
	local list = {}
	for obj in tes3.iterateObjects(objectType) do
		if (slot == nil) or (slot == obj.slot) then
			list[#list+1] = obj.id:lower()
		end
	end
	table.sort(list)
	return list
end


local function toggle(e, blocked, allowed, callback)
	-- toggle an item between blocked / allowed

	-- delete element
	local parent = e.source.parent.parent.parent
	local text = e.source.text
	e.source:destroy()

	-- toggle blocked
	if parent == blocked then
		parent = allowed
		this.config.blocked[text] = nil
	else
		parent = blocked
		this.config.blocked[text] = true
	end

	-- create element
	parent:createTextSelect{text=text}:register("mouseClick", callback)

	-- update sorting
	local container = parent:getContentElement()
	for i, child in pairs(container.children) do
		if child.text > text then
			container:reorderChildren(i-1, -1, 1)
			break
		end
	end

	-- update display
	contents:getTopLevelParent():updateLayout()
end


local function distribute(t, blocked, allowed, callback)
	-- distribute items between blocked / allowed
	blocked:getContentElement():destroyChildren()
	allowed:getContentElement():destroyChildren()

	for i, name in pairs(t) do
		if this.config.blocked[name] then
			blocked:createTextSelect{text=name}:register("mouseClick", callback)
		else
			allowed:createTextSelect{text=name}:register("mouseClick", callback)
		end
	end

	contents:getTopLevelParent():updateLayout()
end

local function createExclusions()
	contents:destroyChildren()
	contents.flowDirection = "top_to_bottom"

	local header = contents:createLabel{text="Tooltips Complete by default provides every item under certain categories with descriptions, for compatibility purposes or personal preference you may wish to prevent certain items from showing their provided texts. This page allows you to do so by using the lists below to view or edit which objects are to be blocked and which are to be allowed."}
	header.heightProportional = -1
	header.widthProportional = 1.0
	header.wrapText = true
	header.borderAllSides = 3
	header.borderBottom = 12

	local sections = contents:createBlock{}
	sections.flowDirection = "left_to_right"
	sections.widthProportional = 1.0
	sections.heightProportional = 1.0

	local blocked, filters, allowed

	do -- 'blocked' section
		local block = sections:createBlock{}
		block.flowDirection = "top_to_bottom"
		block.widthProportional = 4/3
		block.heightProportional = 1.0
		block:createLabel{text="Blocked:"}.borderBottom = 6

		blocked = block:createVerticalScrollPane{}
		blocked.widthProportional = 1.0
		blocked.heightProportional = 1.0
		blocked.paddingAllSides = 6
	end

	do -- 'filters' section
		filters = sections:createBlock{}
		filters.flowDirection = "top_to_bottom"
		filters.widthProportional = 1/3
		filters.heightProportional = 1.0
		filters.borderAllSides = 3
		filters:createLabel{text=""}

		local function callback(e)
			toggle(e, blocked, allowed, callback)
		end
		
		local button = filters:createButton{text="Plugins"}
		button.widthProportional = 1.0
		button:register("mouseClick", function (e)
			local items = getSortedModList()
			distribute(items, blocked, allowed, callback)
		end)
		
		local button = filters:createButton{text="Armor"}
		button.widthProportional = 1.0
		button:register("mouseClick", function (e)
			local items = getSortedObjectList(tes3.objectType.armor)
			distribute(items, blocked, allowed, callback)
		end)
		
		local button = filters:createButton{text="Weapons"}
		button.widthProportional = 1.0
		button:register("mouseClick", function (e)
			local items = getSortedObjectList(tes3.objectType.weapon)
			distribute(items, blocked, allowed, callback)
		end)
		
		local button = filters:createButton{text="Ammo"}
		button.widthProportional = 1.0
		button:register("mouseClick", function (e)
			local items = getSortedObjectList(tes3.objectType.ammunition)
			distribute(items, blocked, allowed, callback)
		end)
		
		local button = filters:createButton{text="Clothing"}
		button.widthProportional = 1.0
		button:register("mouseClick", function (e)
			local items = getSortedObjectList(tes3.objectType.clothing)
			distribute(items, blocked, allowed, callback)
		end)

		local button = filters:createButton{text="Apparatus"}
		button.widthProportional = 1.0
		button:register("mouseClick", function (e)
			local items = getSortedObjectList(tes3.objectType.apparatus)
			distribute(items, blocked, allowed, callback)
		end)
		
		local button = filters:createButton{text="Lockpicks"}
		button.widthProportional = 1.0
		button:register("mouseClick", function (e)
			local items = getSortedObjectList(tes3.objectType.lockpick)
			distribute(items, blocked, allowed, callback)
		end)
		
		local button = filters:createButton{text="Probes"}
		button.widthProportional = 1.0
		button:register("mouseClick", function (e)
			local items = getSortedObjectList(tes3.objectType.probe)
			distribute(items, blocked, allowed, callback)
		end)
		
		local button = filters:createButton{text="Repair"}
		button.widthProportional = 1.0
		button:register("mouseClick", function (e)
			local items = getSortedObjectList(tes3.objectType.repairItem)
			distribute(items, blocked, allowed, callback)
		end)
		
		local button = filters:createButton{text="Books"}
		button.widthProportional = 1.0
		button:register("mouseClick", function (e)
			local items = getSortedObjectList(tes3.objectType.book)
			distribute(items, blocked, allowed, callback)
		end)
		
		local button = filters:createButton{text="Potions"}
		button.widthProportional = 1.0
		button:register("mouseClick", function (e)
			local items = getSortedObjectList(tes3.objectType.alchemy)
			distribute(items, blocked, allowed, callback)
		end)
		
		local button = filters:createButton{text="Ingredients"}
		button.widthProportional = 1.0
		button:register("mouseClick", function (e)
			local items = getSortedObjectList(tes3.objectType.ingredient)
			distribute(items, blocked, allowed, callback)
		end)
		
		local button = filters:createButton{text="Lights"}
		button.widthProportional = 1.0
		button:register("mouseClick", function (e)
			local items = getSortedObjectList(tes3.objectType.light)
			distribute(items, blocked, allowed, callback)
		end)
		
		local button = filters:createButton{text="Misc"}
		button.widthProportional = 1.0
		button:register("mouseClick", function (e)
			local items = getSortedObjectList(tes3.objectType.miscItem)
			distribute(items, blocked, allowed, callback)
		end)
		
		local button = filters:createButton{text="Souls"}
		button.widthProportional = 1.0
		button:register("mouseClick", function (e)
			local items = getSortedObjectList(tes3.objectType.creature)
			distribute(items, blocked, allowed, callback)
		end)
	end

	do -- 'allowed' section
		local block = sections:createBlock{}
		block.flowDirection = "top_to_bottom"
		block.widthProportional = 4/3
		block.heightProportional = 1.0
		block:createLabel{text="Allowed:"}.borderBottom = 6

		allowed = block:createVerticalScrollPane{}
		allowed.widthProportional = 1.0
		allowed.heightProportional = 1.0
		allowed.paddingAllSides = 6
	end

	-- default to first filter
	filters.children[2]:triggerEvent("mouseClick")

	contents:getTopLevelParent():updateLayout()
end
----------------

-- Events

function this.onCreate(parent)
	local tabs = parent:createBlock{}
	tabs.autoWidth, tabs.autoHeight = true, true

	local preferences, exclusions

	preferences = tabs:createButton{text="Preferences"}
	preferences:register("mouseClick", function (e)
		if preferences.widget.state ~= 1 then
			preferences.widget.state = 1
			exclusions.widget.state = 2
			createPreferences(contents)
		end
	end)
	exclusions = tabs:createButton{text="Exclusions"}
	exclusions:register("mouseClick", function(e)
		if exclusions.widget.state ~= 1 then
			exclusions.widget.state = 1
			preferences.widget.state = 2
			createExclusions()
		end
	end)

	-- contents container
	contents = parent:createThinBorder{}
	contents.heightProportional = 1.0
	contents.widthProportional = 1.0
	contents.paddingAllSides = 6

	-- default to preferences
	preferences.widget.state = 1
	exclusions.widget.state = 2
	createPreferences()
end

function this.onClose(parent)
	mwse.saveConfig("tooltipsComplete", this.config)
end


event.register("modConfigReady", function (e)
	mwse.registerModConfig("Tooltips Complete", this)
end)
------------


return this