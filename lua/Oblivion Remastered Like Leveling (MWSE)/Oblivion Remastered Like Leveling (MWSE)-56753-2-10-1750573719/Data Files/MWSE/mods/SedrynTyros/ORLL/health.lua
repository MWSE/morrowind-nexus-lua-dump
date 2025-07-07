local config = require("SedrynTyros.ORLL.config")
local log = require("SedrynTyros.ORLL.log")

local this = {}

-- Capture initial stats at character generation
event.register(tes3.event.charGenFinished, function()
    tes3.player.data.ORLL = {
        initialStrength = tes3.mobilePlayer.strength.base,
        initialEndurance = tes3.mobilePlayer.endurance.base,
        initialHealth = tes3.mobilePlayer.health.base
    }
    log:info("Initial stats captured at character generation.")
end)

-- Fallback capture in case mod was not active during character gen
event.register("loaded", function()
    local player = tes3.player
    local mp = tes3.mobilePlayer
    local data = player.data.ORLL or {}
    local modified = false

    if not data.initialStrength then
        data.initialStrength = mp.strength.base
        log:warn("Missing initialStrength. Fallback value used at load time.")
        modified = true
    end
    if not data.initialEndurance then
        data.initialEndurance = mp.endurance.base
        log:warn("Missing initialEndurance. Fallback value used at load time.")
        modified = true
    end
    if not data.initialHealth then
        data.initialHealth = mp.health.base
        log:warn("Missing initialHealth. Fallback value used at load time.")
        modified = true
    end

    if modified then
        log:debug("Fallback initial stats: Strength = %d, Endurance = %d", data.initialStrength, data.initialEndurance)
    end

    player.data.ORLL = data
end)

---Calculates projected base health based on retroactive formula.
---This function does not apply changes directly — it returns a value to be used elsewhere (e.g., UI previews, health update logic).
---@param level number
---@param initialStrength number
---@param baseEndurance number
this.previewRetroactive = function(level, initialStrength, baseEndurance)
    local retroHealth = (initialStrength + baseEndurance) / 2
    retroHealth = retroHealth + ((level - 1) * 0.1 * baseEndurance)
    return math.max(retroHealth, config.minHealth)
end

---Calculates projected base health gain using vanilla formula.
---Does not modify player stats; used by both UI and level-up logic to determine new base health.
---@param baseHealth number
---@param projectedEndurance number
this.previewVanilla = function(baseHealth, projectedEndurance)
    local healthGain = 0.1 * projectedEndurance
    return math.max(baseHealth + healthGain, config.minHealth)
end

---Apply Oblivion Remastered-style Retroactive Endurance Health
local function applyRetroactiveHealth()
    local player = tes3.player
    local mp = tes3.mobilePlayer
    local data = player.data.ORLL or {}
    local level = player.object.level
    local initialStrength = data.initialStrength or mp.strength.base
    local endurance = mp.endurance.base

    local retroHealthNew = this.previewRetroactive(level, initialStrength, endurance)

    log:trace("Retroactive Health applied: %.1f (Initial STR: %d, Base END: %d, Level: %d)",
        retroHealthNew, initialStrength, endurance, level)

    tes3.setStatistic{ reference = player, name = "health", base = retroHealthNew }

    -- Force UI refresh with -1 HP nudge if player has greater than 1 HP
    mp:updateDerivedStatistics()
    local current = mp.health.current
    if current > 1 then
        tes3.setStatistic{ reference = player, name = "health", current = current - 1 }
        tes3.setStatistic{ reference = player, name = "health", current = current }
    else
        -- Not safe to nudge. Just set the current value directly.
        tes3.setStatistic{ reference = player, name = "health", current = current }
    end
end

---Apply vanilla Morrowind-style health gain (non-retroactive)
local function applyVanillaHealth()
    local player = tes3.player
    local mp = tes3.mobilePlayer
    local endurance = mp.endurance.base
    local baseHealth = mp.health.base

    local vanillaHealthNew = this.previewVanilla(baseHealth, endurance)

	log:trace("Vanilla level-up: Base health increased to %.1f", vanillaHealthNew)

	tes3.setStatistic{ reference = tes3.player, name = "health", base = vanillaHealthNew }

    -- Force UI refresh with -1 HP nudge if player has greater than 1 HP
    mp:updateDerivedStatistics()
    local current = mp.health.current
    if current > 1 then
        tes3.setStatistic{ reference = player, name = "health", current = current - 1 }
        tes3.setStatistic{ reference = player, name = "health", current = current }
    else
        -- Not safe to nudge. Just set the current value directly.
        tes3.setStatistic{ reference = player, name = "health", current = current }
    end	
end

---Unified level-up handler
event.register("levelUp", function()
    if config.retroHealth then
        applyRetroactiveHealth()
    else
        applyVanillaHealth()
    end
end)

return this
