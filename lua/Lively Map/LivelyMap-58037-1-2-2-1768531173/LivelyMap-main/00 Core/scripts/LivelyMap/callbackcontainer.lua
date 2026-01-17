--[[
LivelyMap for OpenMW.
Copyright (C) 2025 Erin Pentecost

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

local CallbackContainerFunctions = {}
CallbackContainerFunctions.__index = CallbackContainerFunctions

---@class CallbackContainer
---@field add fun(fn: fun()): number?
---@field invoke fun(id: number)
---@field abort fun(id: number)

function NewCallbackContainer()
    local new = {
        ---@type number
        nextPendingCallbackId = 1,
        ---@type table<number, fun()>
        pendingCallbacks = {},
    }
    setmetatable(new, CallbackContainerFunctions)
    return new
end

---@param fn fun()
---@return number?
function CallbackContainerFunctions.add(self, fn)
    if fn then
        local curId = self.nextPendingCallbackId
        self.pendingCallbacks[curId] = fn
        self.nextPendingCallbackId = self.nextPendingCallbackId + 1
        return curId
    end
    return nil
end

---@param id number
function CallbackContainerFunctions.invoke(self, id)
    if id == nil then
        return
    end
    if not self.pendingCallbacks[id] then
        print("Callback missing: " .. tostring(id))
        return
    end
    print("Invoking callback " .. tostring(id) .. "...")
    local status, err = pcall(self.pendingCallbacks[id])
    if not status then
        print("Callback " .. tostring(id) .. " error: " .. tostring(err))
    end
    self.pendingCallbacks[id] = nil
end

---@param id number
function CallbackContainerFunctions.abort(self, id)
    if id == nil then
        return
    end
    self.pendingCallbacks[id] = nil
end

return {
    ---@type fun() CallbackContainer
    NewCallbackContainer = NewCallbackContainer
}
