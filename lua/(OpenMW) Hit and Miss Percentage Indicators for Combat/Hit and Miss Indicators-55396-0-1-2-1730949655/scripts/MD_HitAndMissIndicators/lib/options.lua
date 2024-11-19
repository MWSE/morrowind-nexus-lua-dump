local util = require("openmw.util")
local storage = require("openmw.storage")

local MOD_SETTINGS_ID = "MD_HitAndMissIndicators"
local MISS_INDICATOR_SECTION_KEY = 'Settings_' .. MOD_SETTINGS_ID .. '_MISS'
local HIT_INDICATOR_SECTION_KEY = 'Settings_' .. MOD_SETTINGS_ID .. '_HIT'
local PUNCH_INDICATOR_SECTION_KEY = 'Settings_' .. MOD_SETTINGS_ID .. '_PUNCH'

local function getIndicatorOptions(settings)
    return {
        ENABLED = settings:get("ENABLED"),
        COLOR = settings:get("COLOR"),
        TEXT_SIZE = settings:get("TEXT_SIZE"),
        DURATION = settings:get("DURATION"),
        FLOAT_SPEED = settings:get("FLOAT_SPEED"),
    }
end

return {
    MOD_SETTINGS_ID = MOD_SETTINGS_ID,
    MISS_INDICATOR_SECTION_KEY = MISS_INDICATOR_SECTION_KEY,
    HIT_INDICATOR_SECTION_KEY = HIT_INDICATOR_SECTION_KEY,
    PUNCH_INDICATOR_SECTION_KEY = PUNCH_INDICATOR_SECTION_KEY,

	DELAY_AFTER_SWISH_BEFORE_MISS = 0.2,
	OFFSET_RANGE = util.vector2(0.1, 0.05),

    missIndicator = function ()
        local settings = storage.playerSection(MISS_INDICATOR_SECTION_KEY)
        return getIndicatorOptions(settings)
    end,

    hitIndicator = function ()
        local settings = storage.playerSection(HIT_INDICATOR_SECTION_KEY)
        return getIndicatorOptions(settings)
    end,

    punchIndicator = function ()
        local settings = storage.playerSection(PUNCH_INDICATOR_SECTION_KEY)
        return getIndicatorOptions(settings)
    end,
}
