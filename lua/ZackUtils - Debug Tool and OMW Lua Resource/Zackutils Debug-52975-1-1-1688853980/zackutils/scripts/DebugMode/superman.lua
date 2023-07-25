local cam = require('openmw.interfaces').Camera
local camera = require('openmw.camera')
local core = require('openmw.core')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local storage = require("openmw.storage")
local async = require("openmw.async")
local input = require("openmw.input")
local I = require("openmw.interfaces")

local time = require('openmw_aux.time')
local calendar = require('openmw_aux.calendar')

local destPos = nil
local lastUp = 0
local tdist = 10000
local speed = 0.002
local hadSpell = false
local flying = false
local function canLand()
    local zu = I.ZackUtils
    local downPos = util.vector3(self.position.x, self.position.y, self.position.z - 100)
    local lookPos = nearby.castRay(self.position, downPos)
    if (lookPos.hitPos ~= nil) then
        return true
    else
        return false
    end
end
local function land()
    local zu = I.ZackUtils
    if (canLand()) then
        print("Landing")
        if (hadSpell == false) then
            zu.removeSpell("zhac_debug_fly")
        end
        flying = false
    end
end
local function takeOff()
    local zu = I.ZackUtils
    print("Taking off")
    hadSpell = zu.hasSpell("zhac_debug_fly")
    if (hadSpell == false) then
        zu.addSpell("zhac_debug_fly")
    end
    flying = true
end
local function onFrame(dt)
    if (core.isWorldPaused()) then
        return
    end

    local zu = I.ZackUtils
    if (destPos ~= nil) then
        if (flying == false) then
            takeOff()
        end
        local nextPoint = zu.getLinePoints(self.position, destPos, speed)[2]
        zu.teleportItem(self, nextPoint)
        local dist = destPos - self.position

        if (destPos == self.position) then
            destPos = nil
            land()
        end
    else
        if (flying) then
            land()
        end
    end
    if (input.isKeyPressed(input.KEY.K)) then
        local zu      = I.ZackUtils

        local lookPos = zu.getObjInCrosshairs(nil, tdist, true)
        destPos       = lookPos.hitPos
    end
    if (input.isKeyPressed(input.KEY.L)) then
        local zu      = I.ZackUtils

        local lookPos = zu.getObjInCrosshairs(nil, tdist, true)
        destPos       = util.vector3(lookPos.hitPos.x, lookPos.hitPos.y, self.position.z)
    end
    if input.isKeyPressed(input.KEY.I) then
        local upPos = util.vector3(self.position.x, self.position.y, self.position.z + 500)
        local lookPos = nearby.castRay(self.position, upPos)
        if (lookPos.hitPos ~= nil) then
            destPos = lookPos.hitPos
        else
            destPos = upPos
        end
    end
    if input.isKeyPressed(input.KEY.M) then
        local upPos = util.vector3(self.position.x, self.position.y, self.position.z - 500)
        local lookPos = nearby.castRay(self.position, upPos)
        if (lookPos.hitPos ~= nil) then
            destPos = lookPos.hitPos
        else
            destPos = upPos
        end
    end
end

local function onKeyPress(key)

    if(ui.getConsoleLine() ~= nil and ui.getConsoleLine() ~= "") then
        ui.showMessage(ui.getConsoleLine())
        ui.setConsoleLine(ui.getConsoleLine() .. " F")
    else
        ui.showMessage("No message")
    end
end
local function onQuestUpdate(id, index)
    print(id, index)
    print(types.Player.getJournalIndex(self,id))   --will return the quest index from before this update was done.
    types.Player.setJournalIndex(self,id, index + 1) --will cause an infinite loop, crash the game
end


return {
    interfaceName = "superman",
    interface = { version = 1, test = test, sendToPos = sendToPos },

    engineHandlers = {
        onLoad = onInit,
        onFrame = onFrame,
     --  onQuestUpdate = onQuestUpdate
    },
    eventHandlers = {
        testFunc = testFunc,
        setStat = setStat,
        setEquipment = setEquipment,
        setBadItems = setBadItems,
        equipItems = equipItems
    }
}
