local hlib = require("herbert100")
local log = Herbert_Logger()

local mod_name = hlib.get_mod_name() ---@type string
local cfg = hlib.get_mod_config() ---@type herbert.BS.config

local function update_player_spells()
	-- make sure the player exists and the players birthsign is valid
	if not tes3.player or not cfg.whitelist[tes3.mobilePlayer.birthsign.id] then return end

	--- spell_func will either add or remove spells from the player, depending on whether the mod is enabled or not
	-- both `addSpell` and `removeSpell` make sure the spell isn't originating from a birthsign, so we dont need to check that manually
	local spell_func, log_str 
	if cfg.enable then
		spell_func, log_str = tes3.addSpell, "adding spell %q (id=%q) to player"
	else
		spell_func, log_str = tes3.removeSpell, "removing spell %q (id=%q) from player"
	end

	log("updating player spells")
	
	local player_ref = tes3.player
	for _, bs in pairs(tes3.dataHandler.nonDynamicData.birthsigns) do
		for _, spell in pairs(bs.spells) do
			log(log_str, spell.name, spell.id)
			spell_func{reference=player_ref, spell=spell}
		end
	end
	tes3.updateMagicGUI{reference=player_ref}

end

local function initialized()
	event.register(tes3.event.loaded, update_player_spells)
    log:write_init_message()
end

event.register("initialized", initialized, {doOnce=true})

-- =============================================================================
-- MCM
-- =============================================================================

event.register("herbert:MCM_closed", function (e)
	if e.mod_name == mod_name then update_player_spells() end
end)

event.register("modConfigReady", function(e)
	local MCM = hlib.MCM.new()
	MCM:register()

	local p = MCM:new_sidebar_page{label="Settings", 
		desc="This mod slightly buffs the thief birthsign by making thieves steal the abilities from all other birthsigns.\n\n\z
			The MCM lets you enable/disable the mod, and change which birthsigns are affected."
	}

	p:new_button{label="Enable?", id="enable",
		desc="This toggles whether the mod is enabled or not. You may need to use this setting \z
			before uninstalling the mod in order to remove any added birthsign effects. \z
			Make sure you save the game after changing this setting."
	}

	local fmt = string.format



	---@type string
	local function get_id(str)
		-- `string.find` will return `start, end, ...`, where the `...` are the matched patterns
		-- so, `select(3, string.find(str, pattern))` will only return the matched patterns
		return select(3, str:find("%(id = \"([^)]+)\"%)"))
			or "invalid"
	end


	-- dummy table that allows values to be shown in the MCM in a different way than they're stored in the config
	-- (e.g., they're shown as "BIRTHSIGN_NAME (id = BIRTHSIGN_ID)" but stored with just the birthsign id)
	local filter_cfg = setmetatable({}, {
		__index=function (_, k) return cfg.whitelist[get_id(k)] end,
		__newindex=function (_, k, v) cfg.whitelist[get_id(k)] = v end,

		__pairs = function() 
			return coroutine.wrap(function()
				for id, v in pairs(cfg.whitelist) do
					coroutine.yield(fmt("%s (id = \"%s\")", tes3.findBirthsign(id).name, id), v)
				end
			end) 
		end
	})

	local function filter_clbk()
		local arr = {}
		for _, bs in pairs(tes3.dataHandler.nonDynamicData.birthsigns) do
			table.insert(arr, fmt("%s (id = \"%s\")", bs.name, bs.id))
		end
		return arr
	end

	MCM.template:createExclusionsPage{label="Allowed Birthsigns",
		description="The mod will treat all birthsigns in this list as if they were the thief birthsign.",
		filters={{label="Birthsigns", callback=filter_clbk}},
		-- `createExclusionsPage` wants a table, so we make yet another table to store the filter wrapper in
		variable=mwse.mcm.createTableVariable{id="yeah", table={yeah=filter_cfg}},
		leftListLabel="Allowed",
		rightListLabel="Not Allowed",
	}
	log:add_to_MCM(p.component, cfg)
end, {doOnce=true})