--[[
	Weapon Sheathing
	By Greatness7

	TODO:
		separete the 'global' blocked list from a 'custom' blocked list
		add 'block all with matching mesh' shortcut
		add a search bar for blocked/allowed lists
--]]

local this = {}

this.config = mwse.loadConfig("weaponSheathing") or {
	showCustom = true,
	showShield = false,
	showWeapon = true,
	blocked = {
		["animated morrowind 1.0.esp"] = true,
		["animated morrowind ii.esp"] = true,
		["animated_morrowind - expanded.esp"] = true,
		["animated_morrowind - merged.esp"] = true,
		["h.e.l.l.u.v.a. handy holdables.esp"] = true,
		["hold it - dreamers.esp"] = true,
		["hold it - replacer.esp"] = true,
		["hold it - tr addon.esp"] = true,
		["ks_julan"] = true,
		["ks_shani"] = true,
	}
}


--------------
-- CONTENTS --
--------------
local contents


-----------------
-- PREFERENCES --
-----------------
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

	local text = "Weapon Sheathing, Version 1.0\n\nWelcome to the configuration menu! Here you can customize which features of the mod will be turned on or off.\n\nMouse over the individual options for more information. Changes made here may require a reload of your save game to take effect.\n\nThis mod is only possible thanks to the contributions of our talented community members. You can use the links below to find more of their content.\n\nCredits:"
	local label = parent:createLabel{text=text}
	label.widthProportional = 1.0
	label.borderAllSides = 3
	label.borderBottom = 6
	label.wrapText = true

	local contributors = {
		[1] = {"Greatness7", "start https://www.nexusmods.com/morrowind/users/64030?tab=user+files"},
		[2] = {"Heinrich", "start https://www.nexusmods.com/morrowind/users/49330348?tab=user+files"},
		[3] = {"Hrnchamd", "start https://www.nexusmods.com/morrowind/users/843673?tab=user+files"},
		[4] = {"London Rook", "start https://www.nexusmods.com/users/9114769?tab=user+files"},
		[5] = {"Lord Berandas", "start https://www.nexusmods.com/morrowind/users/1858915?tab=user+files"},
		[6] = {"Melchior Dahrk", "start https://www.nexusmods.com/morrowind/users/962116?tab=user+files"},
		[7] = {"MementoMoritius", "start https://www.nexusmods.com/morrowind/users/20765944?tab=user+files"},
		[8] = {"NullCascade", "start https://www.nexusmods.com/morrowind/users/26153919?tab=user+files"},
		[9] = {"PetetheGoat", "start https://www.nexusmods.com/morrowind/users/25319994?tab=user+files"},
		[10] = {"Remiros", "start https://www.nexusmods.com/morrowind/users/899234?tab=user+files"},
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
		key = "showWeapon",
		label = "Show unreadied weapons",
		textParent = right,
		text = "Show unreadied weapons\n\nThis option controls whether or not equipped weapons will be visible while unreadied. Objects blocked by exclusion lists do not respect this setting and will always have their visibility disabled.\n\nDefault: On",
	}
	createFeature{
		parent = left,
		key = "showShield",
		label = "Show unreadied shields on back",
		textParent = right,
		text = "Show unreadied shields on back\n\nThis option controls whether or not equipped shields will be visible on the character's back while unreadied. Objects blocked by exclusion lists do not respect this setting and will always have their visibility disabled.\n\nDefault: Off",
	}
	createFeature{
		parent = left,
		key = "showCustom",
		label = "Show custom scabbards and quivers",
		textParent = right,
		text = "Show custom scabbards and quivers\n\nThis option controls whether or not custom art assets will be used in conjunction with the other mod features. Objects blocked by exclusion lists do not respect this setting and will always have their visibility disabled.\n\nDefault: On",
	}

	createCredits(right)

	contents:getTopLevelParent():updateLayout()
end
-----------------


----------------
-- EXCLUSIONS --
----------------
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

	local header = contents:createLabel{text="Weapon Sheathing by default will support all characters and equipment in your game. In some cases this is not ideal, and you may prefer to exclude certain objects from being processed. This page provides an interface to accomplish that. Using the lists below you can easily view or edit which objects are to be blocked and which are to be allowed."}
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

		local button = filters:createButton{text="Characters"}
		button.widthProportional = 1.0
		button:register("mouseClick", function (e)
			local items = getSortedObjectList(tes3.objectType.npc)
			distribute(items, blocked, allowed, callback)
		end)

		local button = filters:createButton{text="Weapons"}
		button.widthProportional = 1.0
		button:register("mouseClick", function (e)
			local items = getSortedObjectList(tes3.objectType.weapon)
			distribute(items, blocked, allowed, callback)
		end)

		local button = filters:createButton{text="Shields"}
		button.widthProportional = 1.0
		button:register("mouseClick", function (e)
			local items = getSortedObjectList(tes3.objectType.armor, tes3.armorSlot.shield)
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


------------
-- EVENTS --
------------
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
	mwse.saveConfig("weaponSheathing", this.config)
end


event.register("modConfigReady", function (e)
	mwse.registerModConfig("Weapon Sheathing", this)
end)
------------


return this
