local CHANGES = [[

- Improved performance with event-based pursuit
- Added interface for interop with Pursuit
- Added user-extensible folders (drop-in files supported):
    • Blacklist
    • Handlers
- Various bug fixes
]]

local HELP = [[
    ~Denotes optional arguments~

    help = Lists commands.
    info = Prints mod info.
    isActive() = Whether the mod is currently active.
    getBlacklist() = Returns blacklisted recordIds {key:recordId}.
    add/removeBlacklist(recordId) = Add or remove actor recordId from blacklist.
    addHandler(fn, name) = fn is a function that receives pursuit data as its argument. Return false to cancel the pursuit. See pursuit_data.lua for available fields.
    removeHandler(name) = Remove a handler with the given name.
    getHandlers() = Returns the list of handlers. Can be indexed by handler name.

    e.g.
    I.Pursuit.info
    I.Pursuit.addBlacklist("habasi")
    I.Pursuit.getBlacklist()["habasi"]
    I.Pursuit.addHandler(function(e)
        local targetCell = e.target.cell
        if targetCell.isExterior then return false end
        if e.pursuer.recordId == "habasi" then
            return false
        end
    end)
]]

return setmetatable({
    MOD_AUTHOR = "kuyondo",
    MOD_NAME = "Pursuit",
    MOD_VERSION = 1.0,
    MOD_SITE = "www.nexusmods.com/morrowind/mods/50271",
    MIN_API = 97, -- v0.50. v0.51 needs 129 (best)
    CHANGES = CHANGES,
    HELP = HELP
}, {
    __tostring = function(modInfo)
        return string.format("\n[%s](%s)\nAuthor: %s\nVersion: %s\nMinimum API: %s\nChanges: %s", modInfo.MOD_NAME,
            modInfo.MOD_SITE, modInfo.MOD_AUTHOR, modInfo.MOD_VERSION, modInfo.MIN_API, modInfo.CHANGES)
    end,
    __metatable = tostring
})

-- require("scripts.pursuit.modInfo")
