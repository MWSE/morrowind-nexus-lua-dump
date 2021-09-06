local common = require("celediel.ASinkingFeeling.common")
local bigConf = require("celediel.ASinkingFeeling.config")
local config = bigConf.getConfig()

local function createTableVar(id) return mwse.mcm.createTableVariable({id = id, table = config}) end

local function createDescriptions()
    local description = "Formula used to calculate down-pull amount.\n\nOptions are: "
    local options = ""

    -- list all current modes
    for _, t in ipairs(common.modes) do
        options = options .. common.camelCaseToWords(t.mode) .. ", "
    end

    -- strip off ending ", "
    options = options:sub(1, string.len(options) - 2)

    -- add modes to description
    description = description .. options

    -- add descriptions to description
    for _, t in ipairs(common.modes) do
        description = description .. "\n\n" .. common.camelCaseToWords(t.mode) .. ": " .. t.description
    end

    return description
end

local function createOptions()
    local options = {}

    for _, t in ipairs(common.modes) do
        options[#options+1] = {label = common.camelCaseToWords(t.mode), value = t.mode}
    end

    return options
end

local template = mwse.mcm.createTemplate(common.modName)
template:saveOnClose(common.configString, config)

local page = template:createSideBarPage({
    label = "Sidebar Page???",
    description = string.format("%s v%s by %s\n\n%s", common.modName, common.version, common.author, common.modInfo)
})

local category = page:createCategory(common.modName)

category:createYesNoButton({
    label = "Enable the mod",
    description = "Does what it says!",
    variable = createTableVar("enabled")
})

category:createYesNoButton({
    label = "Player-only",
    description = "The mod only affects the player, not other actors.",
    variable = createTableVar("playerOnly")
})

category:createDropdown({
    label = "Down-pull formula",
    description = createDescriptions(),
    options = createOptions(),
    variable = createTableVar("mode")
})

category:createDropdown({
    label = "Worst or Best Case Scenario All Equipment variety",
    description = "Chooses which variety of the All Equipment formula is used when Worst or Best Case Scenario is selected.",
    options = {
        { label = "Original Formula", value = false },
        { label = "Necro Edit", value = true }
    },
    variable = createTableVar("caseScenarioNecroMode")
})

for name, _ in pairs(bigConf.defaultConfig.multipliers) do
    local title = common.camelCaseToWords(name)
    category:createSlider({
        label = title .. " multiplier",
        description = "Multiplier used for " .. title .." formula. Default value: " .. bigConf.defaultConfig.multipliers[name],
        variable = mwse.mcm.createTableVariable({id = name, table = config.multipliers}),
        min = 0,
        max = 300,
        step = 1,
        jump = 10
    })
end

category:createYesNoButton({
    label = "Debug logging",
    description = "Spam mwse.log with useless nonsense.",
    variable = createTableVar("debug")
})

return template
