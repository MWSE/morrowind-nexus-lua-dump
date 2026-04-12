local config = require("HP_SA.config")
local interop = require("HP_SA.interop")
local log = mwse.Logger.new()

local authors = {
	{
		name = "Varlothen",
		url = "https://next.nexusmods.com/profile/varlothen/mods?gameId=100",
	},
	{
		name = "Storm Atronach",
		url = "https://next.nexusmods.com/profile/StormAtronach0/mods",
	}
}


--- @param self mwseMCMInfo|mwseMCMHyperlink
local function center(self)
	self.elements.info.absolutePosAlignX = 0.5
end

--- Adds default text to sidebar. Has a list of all the authors that contributed to the mod.
--- @param container mwseMCMSideBarPage
local function createSidebar(container)
	container.sidebar:createInfo({
		text = "\nWelcome to Hidden Powers!\n\nHover over a feature for more info.\n\nMade by:",
		postCreate = center,
	})
	for _, author in ipairs(authors) do
		container.sidebar:createHyperlink({
			text = author.name,
			url = author.url,
			postCreate = center,
		})
	end
end


---@param str string
---@return string
local function get_id(str)
	-- Extract the ID from format "Race Name (id = race_id)"
	return select(3, str:find("%(id = \"([^\"]+)\"%)")) or "invalid"
end

local function make_proxy_view(tables)
    local source    = assert(tables.source,    "tables.source is required")
    local toDisplay = assert(tables.toDisplay, "tables.toDisplay is required")

    local proxy = {}

    -- Read: proxy["Race Name (id = race_id)"] -> source[race_id]
    function proxy:__index(k)
        local id = get_id(k)
        if id == "invalid" then return nil end
        return source[id]
    end

    -- Write: proxy["Race Name (id = race_id)"] = v  ->  source[race_id] = v
    function proxy:__newindex(k, v)
        local id = get_id(k)
        if id == "invalid" then return end
        source[id] = v
    end

    -- Iterate: pairs(proxy) yields ("Race Name (id = race_id)", value) over source
    function proxy:__pairs()
        return coroutine.wrap(function()
            for id, v in pairs(source) do
				local name = toDisplay[id] or id
                coroutine.yield(string.format("%s (id = \"%s\")", name, id), v)
            end
        end)
    end

    return setmetatable({}, proxy)
end

local function get_races_name()
	-- We start the container
	local added = {}
	-- We iterate over all races, which is saved in the allRaces table of the interop when the game is initialized in the title menu
	for race, isPlayable in pairs(interop.allRaces) do
		if isPlayable then
			-- Format: "Race Name (id = race_id)"
			table.insert(added, string.format("%s --- (id = \"%s\")", interop.raceIDtoName[race], race))
		end
    end
	table.sort(added)
	return added
end


local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = "Hidden Powers",
		--headerImagePath = "MWSE/mods/template/mcm/Header.tga",
		config = config,
		defaultConfig = config.default,
		showDefaultSetting = true,
	})
	template:register()
	template:saveOnClose(config.fileName, config)

	local page = template:createSideBarPage({
		label = "Settings",
		showReset = false,
	}) --[[@as mwseMCMSideBarPage]]
	createSidebar(page)

	local filter_proxy =  make_proxy_view({
					source = config.notPlayableRaces,
					toDisplay = interop.raceIDtoName
				})

	local playableRaces = template:createExclusionsPage{
		label = "Playable races",
		description = "Here we can configure which races will be playable",
		leftListLabel = "Not Playable Races",
		rightListLabel = "Playable races",
		variable=mwse.mcm.createTableVariable{
			id="filter_proxy",
			table={ filter_proxy = filter_proxy}
			},
		filters = { {label="Races", callback = get_races_name}, },
	}

	page:createOnOffButton({
		label = "Powers to NPCs",
		description = "Enables the distribution of racial powers to NPCs when their level meets or exceeds the minimum level requirement",
		configKey = "NPC_powerDistribution"
	})

	page:createOnOffButton({
		label = "Powers to Guards",
		description = "Enables the distribution of racial powers to Guards when their level meets or exceeds the minimum level requirement",
		configKey = "Guard_powerDistribution"
	})

	page:createSlider({
		label = "NPC Level to unlock powers",
		description = "The minimum level at which the NPC racial powers will be unlocked",
		min = 1,
		max = 100,
		step = 1,
		jump = 5,
		configKey = "NPC_unlockPowerLevel",
	})

	page:createSlider({
		label = "Guard Level to unlock powers",
		description = "The minimum level at which the Guard racial powers will be unlocked",
		min = 1,
		max = 100,
		step = 1,
		jump = 5,
		configKey = "Guard_unlockPowerLevel",
	})

	page:createOnOffButton({
		label = "Playable race filtering",
		description = "Enables the playable race filtering when creating a new character. Disable to have all playable races available",
		configKey = "playableRaceFiltering"

	})

	page:createOnOffButton({
		label = "Race discovery by conversation topic",
		description = "Enables the discovery of races by the conversation topic",
		configKey = "unlockOnTopic"
	})

	page:createOnOffButton({
		label = "Race discovery by meeting them",
		description = "Enables the discovery of races by meeting them (initiating dialogue with them)",
		configKey = "unlockOnMeetingNewRace"
	})

	page:createOnOffButton({
		label = "Race discovery of a corpse",
		description = "Enables the discovery of races by discovering a corpse as well (needs race discovery by meeting them enabled)",
		configKey = "unlockOnActivatingCorpse"
	})

	page:createButton({
		buttonText = "Start with only Dark Elf (Dunmer) unlocked",
		description = "Start with only Dark Elf (Dunmer) unlocked. You can unlock the rest of the races by learning about them from Morrowind denizens (click on the topic in dialogue).",
		callback = function()
			table.clear(config.notPlayableRaces)
			for raceID, isPlayable in pairs(interop.allRaces) do
				if isPlayable then
					if interop.onlyDarkElf[raceID] == false then
						config.notPlayableRaces[raceID] = false
					else
						config.notPlayableRaces[raceID] = true
					end
				end
			end
			tes3.messageBox("Congratulations, Outlander. You have chosen the long path") end,
	})

	page:createButton({
		buttonText = "Start with only vanilla races.",
		description = "Start with only vanilla races unlocked. You can unlock the rest of the races by learning about them from Morrowind denizens (click on the topic in dialogue).",
		callback = function()
			table.clear(config.notPlayableRaces)
			for raceID, isPlayable in pairs(interop.allRaces) do
				if isPlayable then
					if interop.onlyVanilla[raceID] == false then
						config.notPlayableRaces[raceID] = false
					else
						config.notPlayableRaces[raceID] = true
					end
				end
			end
			tes3.messageBox("Ah, we've been expecting you. As Todd intended, indeed.") end,
	})

	page:createLogLevelOptions({
		configKey = "logLevel",
	})

end

event.register(tes3.event.modConfigReady, registerModConfig)
