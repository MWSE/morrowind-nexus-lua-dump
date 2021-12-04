local ui = require("openmw.ui")
local core = require("openmw.core")
local nearby = require("openmw.nearby")
local self = require("openmw.self")

--[[https://wiki.libsdl.org/SDLKeycodeLookup]]
local buttons = {
    warpIn = 1073741897,
    warpOut = 127,
    activeStance = 1073741899,
    passiveStance = 1073741902,
    shine = 1073741898,
    dim = 1073741901
}

local function find(t, val)
    for k, v in pairs(t) do
        if v == val then
            return k
        end
    end
    return nil
end

local function commands(key)
    for _, dummyRef in nearby.activators:ipairs() do
        if dummyRef.recordId == "aaa_kindi_dummy" then
            core.sendGlobalEvent("getDummy", {dummyRef})
            break
        end
    end

    if self.inventory:countOf("kindi_book_of_laaeet") > 0 then
        if key.code == buttons.warpIn then --insert
            ui.showMessage("Warp In")
            core.sendGlobalEvent("warpToPlayer")
        elseif key.code == buttons.warpOut then --delete
            ui.showMessage("Warp Out")
            core.sendGlobalEvent("warpToVoid")
        elseif key.code == buttons.activeStance then --pageUp
            ui.showMessage("Active Stance")
            core.sendGlobalEvent("onOffAi", {enable = true})
        elseif key.code == buttons.passiveStance then --pageDown
            ui.showMessage("Passive Stance")
            core.sendGlobalEvent("onOffAi", {enable = false})
        elseif key.code == buttons.shine then --home
            ui.showMessage("Wisp Shine")
            core.sendGlobalEvent("shineOrDim", {enable = true})
        elseif key.code == buttons.dim then --end
            ui.showMessage("Wisp Dim")
            core.sendGlobalEvent("shineOrDim", {enable = false})
        end
    elseif find(buttons, key.code) then
        ui.showMessage("No spellbook in your inventory to command wisp")
    end
end

return {
    engineHandlers = {
        onKeyPress = commands
    }
}
