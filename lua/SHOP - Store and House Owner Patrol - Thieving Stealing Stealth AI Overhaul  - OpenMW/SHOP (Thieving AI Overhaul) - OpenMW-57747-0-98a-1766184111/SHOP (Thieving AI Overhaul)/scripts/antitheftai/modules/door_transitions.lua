--[[
SHOP - Store & House Owner Patrol (NPC in interiors AI overhaul) for OpenMW.
Copyright (C) 2025 Łukasz Walczak

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
----------------------------------------------------------------------
-- Anti-Theft Guard AI  •  v0.9 PUBLIC TEST  •  OpenMW ≥ 0.49
----------------------------------------------------------------------
-- Door Detection and Transitions
----------------------------------------------------------------------

local doorModule = {}

local config = require('scripts.antitheftai.modules.config')
local seenMessages = {}

local function log(...)
    if config.DEBUG then
        local args = {...}
        for i, v in ipairs(args) do
            args[i] = tostring(v)
        end
        local msg = table.concat(args, " ")
        if not seenMessages[msg] then
            print("[Door]", ...)
            seenMessages[msg] = true
        end
    end
end

-- Detect door transition
function doorModule.detectDoorTransition(lastPlayerPosition, currentPosition, nearby, types)
    if not lastPlayerPosition or not currentPosition then
        return false, nil
    end
    
    local positionChange = (currentPosition - lastPlayerPosition):length()
    
    if positionChange > 100 then
        log("Detected significant position change:", math.floor(positionChange), "units")
        
        for _, door in ipairs(nearby.doors) do
            if door and types.Door and types.Door.destPosition then
                local destPos = types.Door.destPosition(door)
                local destCell = types.Door.destCell(door)

                if destPos then
                    local distToDest = (currentPosition - destPos):length()

                    if distToDest < 150 then
                        log("Found matching door transition")
                        log("  Door destination cell:", destCell and destCell.name or "same cell")
                        log("  Distance to destination:", math.floor(distToDest))
                        return true, door
                    end
                end
            end
        end
    end
    
    return false, nil
end

-- Teleport guard through door
function doorModule.teleportGuardThroughDoor(guardId, targetPosition, targetCell, selfCell, core, util, returnPosition)
    log("Teleporting guard", guardId, "through door")

    local offset = util.vector3(
        math.random(-50, 50),
        math.random(-50, 50),
        0
    )

    local teleportPos = targetPosition + offset

    if targetCell and targetCell ~= selfCell then
        log("Teleporting guard to different cell:", targetCell.name or targetCell)
        core.sendGlobalEvent('AntiTheft_TeleportGuard', {
            npcId = guardId,
            cellName = targetCell.name or targetCell,
            position = teleportPos,
            returnPosition = returnPosition
        })
    else
        log("Teleporting guard within same cell:", selfCell.name)
        core.sendGlobalEvent('AntiTheft_TeleportGuard', {
            npcId = guardId,
            cellName = selfCell.name,
            position = teleportPos,
            returnPosition = returnPosition
        })
    end
end

return doorModule