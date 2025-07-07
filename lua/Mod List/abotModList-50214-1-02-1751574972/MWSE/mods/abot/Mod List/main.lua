-- Hopefully we will get more useful error reports with this

local author = 'abot'
local modName = "Mod List"
local mcmName = author .. "'s " .. modName
local modPrefix = author .. '/'.. modName

local modConfig = {}

local logLevel = 1

local logLevel1 = logLevel >= 1
local logLevel2 = logLevel >= 2
local logLevel3 = logLevel >= 3
local logLevel4 = logLevel >= 4

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
				---assert(attr)
				attrmode = attr.mode
				lcf = string.lower(f)
				if attrmode == "directory" then
					---mwse.log("folder: %s", f)
					suffix = string.sub(lcf, -9)
					if not (suffix == ".disabled") then
						scan(path_f .. "/")
					end
				elseif attrmode == "file" then
					if lcf == "main.lua" then
						table.insert(t, string.sub(path, 22, -2))
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

local function createListLink(parent, labelText, link)
	local block = parent:createBlock({})
	block.flowDirection = 'top_to_bottom'
	block.paddingAllSides = 4
	block.layoutWidthFraction = 1.0
	block.height = 24
	block:createHyperlink({text = labelText, url = link, confirm = false})
end

---local URL_PATTERN = 'https?://[_~a-zA-Z0-9/#\\=&;%.%%%+%-%?]+'
local URL_PATTERN = 'https?://[%:_~a-zA-Z0-9/#\\=&;%.%%%+%-%?]+'

-- return first found URL string in text, or nil
local function getFirstURL(text_with_URLs)
	local s = string.match(text_with_URLs, URL_PATTERN)
	if logLevel3 then
		mwse.log("%s getFirstURL = %s", modPrefix, s)
	end
	return s
end


local function redirectURL(s)
	local lcs = string.lower(s)
	local r
	local webArchivePrefix = 'https://web.archive.org/web/'
	local modhistoryPrefix = 'mw.modhistory.com/download'
	local m = string.match(lcs, "https?://"..modhistoryPrefix.."(%-%d+%-%d+)")
	if m then
		r = webArchivePrefix..'20161103152243/https://'..modhistoryPrefix..m
		if logLevel3 then
			mwse.log('%s redirectURL("%s") = "%s"', modPrefix, s, r)
		end
		return r
	end
	local fliggertyPrefix = 'download.fliggerty.com/'
	m = string.match(lcs, "https?://"..fliggertyPrefix.."download%-(%d+%-%d+)")
	if m then
		r = webArchivePrefix..'20161103125749/https://'..fliggertyPrefix..'file.php?id='..m
		if logLevel3 then
			mwse.log('%s redirectURL("%s") = "%s"', modPrefix, s, r)
		end
		return r
	end
	return s
end

--[[
local function getMWSELuaDump()
	local http = require("socket.http")
	local s, code = http.request('https://raw.githubusercontent.com/MWSE/morrowind-nexus-lua-dump/master/index.json'
	)
	if not s then
		mwse.log(
"%s getMWSELuaDump(): error code %s downloading Morrowind MWSE-Lua dump index",
			modPrefix, code)
		return
	end
	local t = {}
	local c = 0
	for mod_id, name, author in string.gmatch(s,
		'"mod_id": (%d+),[^"]+"name": "([^"]+)",[^"]+"author": "([^"]+)"'
	) do
		c = c + 1
		t[name] = {i = c, id = mod_id, au = author}
		if logLevel1 then
			mwse.log('t["%s"] = {i = %s, id = "%s", au = "%s"}',
				name, c, mod_id, author)
		end
	end
	return t
end
]]

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

	---local a = tes3.getModList()
	local a = tes3.dataHandler.nonDynamicData.activeMods
	for i = 1, #a do
		local mod = a[i]
		local name = mod.filename
		local s = string.format("%04d %s\n", i, name)
		local info = mod.description
		local createLink = false
		local url
		if info then
			url = getFirstURL(info)
			if url then
				url = redirectURL(url)
				createLink = true
			end
		end
		if createLink then
			createListLink(list, s, url)
		else
			createListLabel(list, s)
		end
		s2 = s2 .. s
	end

	list:createDivider({})

	s = "Loaded MWSE-Lua mods:\n(note: you need to be registered and logged to the sire for github search to work!)\n"
	createListLabel(list, s)
	s2 = s2 .. "\n\n" .. s
	a = getInstalledLuaModsTable()

	---local t = getMWSELuaDump()
	---local lastFolder, rec

	for i = 1, #a do
		local name = a[i]
		local s = string.format("%04d MWSE/Mods/%s\n", i, name)
		local url = string.format(
[[https://github.com/search?q=repo%%3AMWSE%%2Fmorrowind-nexus-lua-dump+MWSE%%2FMods%%2F%s&type=code]], name)
		createListLink(list, s, url)
		s2 = s2 .. s
	end
	os.setClipboardText(s2)
	mainPane:getTopLevelMenu():updateLayout()
	list.widget:contentsChanged()

end

local function modConfigReady()
	mwse.log(modPrefix .. " modConfigReady")
	mwse.registerModConfig(mcmName, modConfig)
	---getMWSELuaDump()
end
event.register('modConfigReady', modConfigReady)
