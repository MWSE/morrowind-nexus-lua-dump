local self = require("openmw.self")
local core = require("openmw.core")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local function playerHasSoul(soulId)
    local player = nearby.players[1]
    for index, value in ipairs(types.Actor.inventory(player):getAll(types.Miscellaneous)) do
        local objSoul = types.Miscellaneous.getSoul(value)
        if objSoul and objSoul == soulId then
            return true
        end
    end
    return false
end
local function Died()
    if self.cell.id == "Esm3ExteriorCell:6:25" then
        core.sendGlobalEvent("daedraDied")
    end
    if self.recordId:find("zhac_hestatur_dremgen") then

        if not playerHasSoul(self.recordId) then
            core.vfx.spawn("vfx_soul_trap", self.position)
            core.sendGlobalEvent("resurrectDaedra", self)
        else
        core.sendGlobalEvent("generalDeath"     )
        end
    end
end

return {
    eventHandlers = {
        Died = Died,
    }
}
