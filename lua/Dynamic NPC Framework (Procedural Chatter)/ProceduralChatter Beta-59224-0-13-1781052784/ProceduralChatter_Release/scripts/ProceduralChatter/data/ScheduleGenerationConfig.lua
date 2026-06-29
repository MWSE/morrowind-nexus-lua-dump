-- ScheduleGenerationConfig.lua
-- Tunables for deterministic, runtime-generated NPC schedules.

return {
    ENABLED = true,
    GENERATION_VERSION = 1,
    REQUIRE_BASE_EXTERIOR = true,

    EVENING_TAVERN_CAP = 6,
    NIGHT_SHELTER_CAP = 6,
    RELIGIOUS_SERVICE_CAP = 6,
    SHOPPING_CAP = 3,
    EXTERIOR_MARKET_CAP = 12,

    DAYS = {
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
    },

    WEEKDAYS = {
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
    },

    SERVICE_SLOTS = {
        "06-08",
        "09-11",
        "12-14",
        "15-17",
        "18-20",
    },

    SERVICE_SLOTS_WITH_EVENING = {
        "09-11",
        "12-14",
        "15-17",
        "18-20",
    },

    SHOPPING_SLOTS = {
        "10-12",
        "12-14",
        "14-16",
    },

    EVENING_BLOCK = "18-21",
    NIGHT_BLOCKS = {
        "00-07",
        "22-24",
    },
}
