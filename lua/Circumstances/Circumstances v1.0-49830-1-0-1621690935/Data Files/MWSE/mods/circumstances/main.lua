local defaultConfig = {
    -- If you want to add additional Khajiit races, and have them benfit from the fall damage reduction, list their IDs in the following tables.
    khajiitIDs = {"Khajiit"},
    -- If you decide to change the esp name for some reason, also change this variable to match.
    modName = "Circumstances",
    initializeWithoutESP = false
}
local config = mwse.loadConfig("circumstances", defaultConfig)

local function onDamage(e)
    if(e.source == "fall") then
        local race = e.reference.object.race.id
        local isKhajiit = false
        for _, id in ipairs(config.khajiitIDs) do
            if (race == id) then isKhajiit = true end
        end
        if (isKhajiit == true) then
            e.damage = e.damage * 0.5
            if(e.damage < 5) then
                e.block = true
            end
        end
    end
end

local function onInitialized()
    if (table.find(tes3.getModList(), config.modName) ~= nil or config.initializeWithoutESP == true) then
        event.register("damage", onDamage)
        print("Circumstances Initialized.")
    else
        print("Circumstances ESP not activated. Mod disabled.")
    end
end

event.register("initialized", onInitialized)

local function onModConfigReady()
    local template = mwse.mcm.createTemplate("Circumstances")
    template.headerImagePath = "Textures/circumstances/CircumstancesIcon.dds"
	template:saveOnClose("circumstances", config)

	local page = template:createPage()
	page:createOnOffButton{
		label = "Enable mod without ESP? (Requires restart)",
		variable = mwse.mcm.createTableVariable{
			id = "initializeWithoutESP",
			table = config
		}
	}
    mwse.mcm.register(template)
end
event.register("modConfigReady", onModConfigReady)