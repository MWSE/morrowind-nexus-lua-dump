local storage = require('openmw.storage')

local M = {}

M.GROUP = 'SettingsPlayerFailureXPBonus'

-- Per-category multipliers (1.0 = off; >1.0 grants (mult - 1) of a successful use's XP)
M.KEY_WEAPON     = 'weaponFraction'
M.KEY_MAGIC      = 'magicFraction'
M.KEY_LOCKPICK   = 'lockpickFraction'
M.KEY_PICKPOCKET = 'pickpocketFraction'


-- Master override: when enabled, master fraction applies to every category and the
-- per-category values above are ignored.
M.KEY_MASTER_ENABLED  = 'masterEnabled'
M.KEY_MASTER_FRACTION = 'masterFraction'

M.DEFAULT_WEAPON     = 1.25
M.DEFAULT_MAGIC      = 1.25
M.DEFAULT_LOCKPICK   = 1.25
M.DEFAULT_PICKPOCKET = 1.25

M.DEFAULT_MASTER_ENABLED  = false
M.DEFAULT_MASTER_FRACTION = 1.25

M.KEY_DEBUG_UI_MESSAGES = 'debugUIMessages'
M.DEFAULT_DEBUG_UI_MESSAGES = false

-- Categories the mod recognises. Add aliases here if the engine expands SkillUseTypes.
M.CATEGORY = {
    WEAPON     = 'weapon',
    MAGIC      = 'magic',
    LOCKPICK   = 'lockpick',
    PICKPOCKET = 'pickpocket',
}

local function section()
    return storage.playerSection(M.GROUP)
end

local function read(key, default)
    local v = section():get(key)
    if v == nil then return default end
    return v
end

function M.getDebugUIMessagesEnabled()
    return read(M.KEY_DEBUG_UI_MESSAGES, M.DEFAULT_DEBUG_UI_MESSAGES)
end

function M.getFractionFor(category)
    if read(M.KEY_MASTER_ENABLED, M.DEFAULT_MASTER_ENABLED) then
        return read(M.KEY_MASTER_FRACTION, M.DEFAULT_MASTER_FRACTION)
    end
    if category == M.CATEGORY.WEAPON then
        return read(M.KEY_WEAPON, M.DEFAULT_WEAPON)
    elseif category == M.CATEGORY.MAGIC then
        return read(M.KEY_MAGIC, M.DEFAULT_MAGIC)
    elseif category == M.CATEGORY.LOCKPICK then
        return read(M.KEY_LOCKPICK, M.DEFAULT_LOCKPICK)
    elseif category == M.CATEGORY.PICKPOCKET then
        return read(M.KEY_PICKPOCKET, M.DEFAULT_PICKPOCKET)
    end
    return 1.0
end

return M
