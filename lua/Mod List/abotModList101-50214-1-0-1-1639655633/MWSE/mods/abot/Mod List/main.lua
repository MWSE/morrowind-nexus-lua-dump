-- Hopefully we will get more useful error reports with this

local author = 'abot'
local modName = "Mod List"
local mcmName = author .. "'s " .. modName
local modPrefix = author .. '/'.. modName

local modConfig = {}

local function getInstalledLuaModsTable()
	local basePath = "Data Files\\MWSE\\mods\\"
	local t = {}

	local function scan(path)
		local lcf, suffix, path_f, attr, attrmode
		for f in lfs.dir(path) do
			if not (
					 (f == '.')
				or (f == '..')
				) then
				path_f = path .. f
				attr = lfs.attributes(path_f)
				attrmode = attr.mode
				lcf = string.lower(f)
				if attrmode == "directory" then
					---mwse.log("folder: %s", f)
					suffix = string.sub(lcf, -9)
					if not (suffix == ".disabled") then
						scan(path_f .. "\\")
					end
				elseif attrmode == "file" then
					if lcf == "main.lua" then
						table.insert(t, path:sub(12,-2))
						return
					end
				end
			end
		end
	end

	scan(basePath)
	table.sort(t)
	return t
end

local function createListLabel(parent, labelText)
	local block = parent:createBlock({})
	block.flowDirection = 'top_to_bottom'
	block.paddingAllSides = 4
	block.layoutWidthFraction = 1.0
	block.height = 24
	block:createLabel({text = labelText})
end

function modConfig.onCreate(container)

	local mainPane = container:createThinBorder({})
	mainPane.flowDirection = 'top_to_bottom'
	mainPane.layoutHeightFraction = 1.0
	mainPane.layoutWidthFraction = 1.0
	mainPane.paddingAllSides = 6
	mainPane.widthProportional = 1.0
	mainPane.heightProportional = 1.0

	local list = mainPane:createVerticalScrollPane({})
	list.borderAllSides = 6
	list.widthProportional = 1.0
	list.heightProportional = 1.0

	createListLabel(list, "Current Mod List has been copied to the clipboard, you can now paste it using CTRL+V keyboard shortcut\n")

	local s = "Standard Mods Loading Order:\n"
	createListLabel(list, s)
	local s2 = s
	for i, mod in ipairs(tes3.getModList()) do
		s = string.format("%04d %s\n", i, mod)
		createListLabel(list, s)
		s2 = s2 .. s
	end

	list:createDivider({})

	s = "Loaded MWSE-Lua mods:\n"
	createListLabel(list, s)
	s2 = s2 .. "\n\n" .. s
	for i, mod in ipairs(getInstalledLuaModsTable()) do
		s = string.format("%04d %s\n", i, mod)
		createListLabel(list, s)
		s2 = s2 .. s
	end

	os.setClipboardText(s2)

	mainPane:getTopLevelParent():updateLayout()
	list.widget:contentsChanged()

end

local function modConfigReady()
	mwse.log(modPrefix .. " modConfigReady")
	mwse.registerModConfig(mcmName, modConfig)
end
event.register('modConfigReady', modConfigReady)
