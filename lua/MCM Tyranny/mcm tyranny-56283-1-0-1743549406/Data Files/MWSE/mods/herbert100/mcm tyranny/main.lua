local MOD_NAME = "MCM Tyranny"

---@class herbert.McmTyranny.config
local DEFAULT_CONFIG = {
	---@type {[string]: boolean}
	blacklist = {},
	show_this_mod_in_search = true,
}
---@type herbert.McmTyranny.config
local cfg = assert(mwse.loadConfig(MOD_NAME, DEFAULT_CONFIG))


local log = Herbert_Logger.new()

---@type {[string]: mwseModConfig}
local configMods

if not mwse.registerModConfig then
	log:error("Could not load the list of config mods. Probably a breaking change was made to the MCM API or something.\n\n\z
		For your own protection, this mod is going to disable itself and not do anything further.")
	return 
end

-- try to get the list of registered mods
for i = 1, 25 do
	-- this function refers to the list of `configMods` :)
	local name, value = debug.getupvalue(mwse.registerModConfig, i)
	if not name then
		break
	end
	if name == "configMods" then
		configMods = value
		break
	end
end


if not configMods then
	log:error("Could not load the list of config mods. Probably a breaking change was made to the MCM API or something.\n\n\z
		For your own protection, this mod is going to disable itself and not do anything further.")
	return
end



--- Checks if a mod should be considered in this mods logic.
---@param name string Name of the mod
---@return boolean is_valid 
local function mod_is_valid(name)
	return name ~= MOD_NAME
end

-- if we included "MCM Tyranny" in the list of mod names, then the only way to unhide mods would be to edit the json file
local function get_mod_names()
	local mod_names = {}
	log("building mod names")
	for name in pairs(configMods) do
		if mod_is_valid(name) then
			log:trace("adding %s", name)
			table.insert(mod_names, name)
		end
	end
	table.sort(mod_names, function (a, b)
		return a:lower() < b:lower()
	end)
    return mod_names
end


local function update_mod_visibility()
	for name, pkg in pairs(configMods) do
		if mod_is_valid(name) then
			log:trace('%s "%s". status changed? %s', function ()
				-- use `not` so that we avoid the whole "or nil" problem
				local status_changed = (not pkg.hidden) ~= (not cfg.blacklist[name])
				local action = cfg.blacklist[name] and "hiding" or "showing"
				return action, name, status_changed
			end)
			pkg.hidden = cfg.blacklist[name] or false
		end
	end
	-- log message
	log("hidden mods: %s", function ()
		local hidden = {}
		for _, pkg in pairs(configMods) do	
			if pkg.hidden then
				table.insert(hidden, pkg.name)
			end
		end
		table.sort(hidden)
		return hidden
	end)
end


event.register("modConfigReady", function()
    local template = mwse.mcm.createTemplate{
		name = MOD_NAME, 
		onClose = function()
			update_mod_visibility()
			mwse.saveConfig(MOD_NAME, cfg)
		end,
		-- Make the search function show this mod instead of any mods it hides.
		onSearch = function (searchText)
			if cfg.show_this_mod_in_search then
				for name, hidden in pairs(cfg.blacklist) do
					if hidden and mod_is_valid(name) and name:lower():find(searchText) then
						return true
					end
				end
			end
			return false
		end,
		config = cfg,
		defaultConfig = DEFAULT_CONFIG
	}
    template:createExclusionsPage{ 
		label = "Mods to Hide", 
        description = "Selected mods won't show up in the MCM. You will need to reopen the MCM for changes to take effect.",
        variable = mwse.mcm.createTableVariable{id="blacklist",table=cfg},
        leftListLabel = "Hidden mods", 
		rightListLabel = "Unhidden mods",
        filters = {{label = "Installed Mods", callback = get_mod_names}},
    }
	template:register()

	local other_settings = template:createSideBarPage{label = "Other Settings"}
	other_settings:createYesNoButton{label = "Show this mod when searching for hidden mods", 
		configKey = "show_this_mod_in_search",
		description = "If enabled, then this mod will appear in search results if any hidden mod names match the search string.\n\n\z
		For example, if the MCM for More QuickLoot is hidden and this setting is enabled, then this mod will show up when searching for More QuickLoot."
	}
	log:add_to_MCM(other_settings)

end, {doOnce = true})


event.register("initialized", function()
	update_mod_visibility()
	log:info("Initialized mod. Hid %s MCMs.", function()
		local count = 1
		for _, pkg in pairs(configMods or {}) do	
			if pkg.hidden then
				count = count + 1
			end
		end
		return count
	end)
end, {doOnce = true})