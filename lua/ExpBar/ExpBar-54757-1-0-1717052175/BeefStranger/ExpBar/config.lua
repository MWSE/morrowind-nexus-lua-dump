local bs = require("BeefStranger.functions")
local log = bs.getLog("ExpBar")
local db = log.debug
local configPath = "ExpBar"

---@class bsExpBar<K, V>: { [K]: V }
local defaults = {
    allowed = {},            --List of skills to show
    enabled = true,          --If mod is enabled
    enableThreshold = false, --Enable threshold
    keycode = {              --Keycode to trigger menu
        keyCode = tes3.scanCode.z,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },
    logLevel = "WARN",
    opacity = 1,        --Opacity of menu
    refreshRate = 1.2,  --How often it updates
    removeCheck = true, --Removes the Yes No menu when removing a skill
    slim = true,        --Slim mode
    threshold = 25,     --The minimum amount of progress before the skill will show
}


---@class bsExpBar
local config = mwse.loadConfig(configPath, defaults)

local function getSkillList()
    local skillList = {}
    local skillMajor = {}
    local skillMinor = {}
    for name, id in pairs(tes3.skill) do
        table.insert(skillList, tes3.skillName[id])

        if tes3.mobilePlayer then
            local skillType = tes3.mobilePlayer:getSkillStatistic(id).type

            if skillType == tes3.skillType.major then
                table.insert(skillMajor, tes3.skillName[id])
            elseif skillType == tes3.skillType.minor then
                table.insert(skillMinor, tes3.skillName[id])
            end
        end

    end
    -- bs.inspect(skillList)
    event.trigger("bsExpBar:RefreshUI")

    table.sort(skillList)
    return skillList, skillMajor, skillMinor
end

---Just a little guy, to make callbacks faster
local function updateUI()
    event.trigger("bsExpBar:RefreshUI")
end


local function registerModConfig()
    local template = bs.config.template(configPath)
    template:saveOnClose(configPath, config)

    local settings = template:createPage({ label = "Settings" })

    local toggle = settings:createCategory{paddingBottom = 10,}
        bs.config.yesNo(toggle, "Enable Mod", "enabled", config, {callback = updateUI})
        bs.config.yesNo(toggle, "Slim UI mode", "slim", config, {callback = updateUI})
        bs.config.yesNo(toggle, "Enable skill threshold", "enableThreshold", config, {callback = updateUI})
        bs.config.yesNo(toggle, "Verify Skill Removal when clicking on it in ExpBar", "removeCheck", config)
    ---------------------------------------------------------------------------------

    local sliders = settings:createCategory{label = "Sliders", paddingBottom = 5}
        sliders:createSlider({
            variable = mwse.mcm.createTableVariable{id = "threshold", table = config},
            label = "Minimum amount of progress for skill to be visible in list",
            min = 0, max = 99, step = 1, jump = 10,
            callback = updateUI
        })
        sliders:createSlider({
            variable = mwse.mcm.createTableVariable{id = "refreshRate", table = config},
            label = "Update Rate in seconds (Values under 1 tend to be slower, 1.2 seems to be the sweetspot)",
            min = 0.8, max = 20, step = 0.01, jump = 0.10,
            decimalPlaces = 2
        })
        sliders:createSlider({
            variable = mwse.mcm.createTableVariable{id = "opacity", table = config},
            label = "Opacity of Menu",
            min = 0, max = 1, step = 0.01, jump = 0.10, decimalPlaces = 2,
            callback = updateUI
        })
    ---------------------------------------------------------------------------------

    settings:createButton{
        buttonText = "Show ExpBar",
        callback = updateUI,
        paddingBottom = 5
    }
    ---------------------------------------------------------------------------------

    local filters = settings:createCategory{label = "Filtering"}

    filters:createButton({
        buttonText = "Select Major Skills",
        callback = function()
            local _, major = getSkillList()
            bs.inspect(major)
            for _, skill in ipairs(major) do
                config.allowed[skill] = true
            end
            updateUI()
        end,
        inGameOnly = true
    })

    filters:createButton({
        buttonText = "Select Minor Skills",
        callback = function()
            local _, _, minor = getSkillList()
            bs.inspect(minor)
            for _, skill in ipairs(minor) do
                config.allowed[skill] = true
            end
            updateUI()
        end,
        inGameOnly = true
    })

    filters:createButton({
        buttonText = "Clear Filters",
        callback = function()
            config.allowed = {}
            updateUI()
        end,
    })
---------------------------------------------------------------------------------
    settings:createKeyBinder({
        label = "Assign Keybind",
        description = "Assign a new keybind to perform awesome tasks.",
        variable = mwse.mcm.createTableVariable{ id = "keycode", table = config },
        allowCombinations = false,
    })

    settings:createButton({
        buttonText = "Restore Default Settings",
        callback = function()
            for key, value in pairs(defaults) do
                config[key] = value
            end
            mwse.saveConfig(configPath, config)
            updateUI()
        end,

    })

    -- settings:createButton({
    --     buttonText = "Config Check",
    --     callback = function()
    --         bs.inspect(config)
    --     end,
    --     indent = 150
    -- })

    bs.config.createLogLevel(settings, config, log.log)

    template:createExclusionsPage({
        label = "Allowed Skills",
        description = "Manage the list of allowed skills.",
        leftListLabel = "Allowed Skills",
        rightListLabel = "Excluded Skills",
        variable = mwse.mcm.createTableVariable{ id = "allowed", table = config},
        filters = { { label = "Skills", callback = getSkillList }, },
    })

    template:register()

end
event.register(tes3.event.modConfigReady, registerModConfig)

return config