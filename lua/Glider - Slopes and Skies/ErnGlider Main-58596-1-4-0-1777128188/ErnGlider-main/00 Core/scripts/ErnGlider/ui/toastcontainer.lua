--[[
ErnGlider for OpenMW.
Copyright (C) 2026 Erin Pentecost

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
local util       = require('openmw.util')
local ui         = require('openmw.ui')
local interfaces = require("openmw.interfaces")

local function toastContainerLayout(content)
    return {
        name = 'toastContainer',
        type = ui.TYPE.Flex,
        layer = 'HUD',
        props = {
            horizontal = false,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            anchor = util.vector2(0.5, 0),
            relativePosition = util.vector2(0.5, 0.3),
            --relativeSize = util.vector2(1, 1),
            autoSize = true,
        },
        content = content,
    }
end

local duration = 3

local function quadraticEaseOut(x)
    return 1 - (1 - x) * (1 - x)
end

local ToastFunctions   = {}
ToastFunctions.__index = ToastFunctions

local function newToast(elem)
    elem.layout.props.alpha = 1
    local new = {
        elem = elem,
        elapsedTime = 0,
        startTime = 0,
        expiryTime = duration,
    }
    setmetatable(new, ToastFunctions)
    print("new toast")
    return new
end

function ToastFunctions.update(self, dt)
    self.elapsedTime = self.elapsedTime + dt
    local age = util.remap(self.elapsedTime, self.startTime, self.expiryTime, 0, 1)
    self.elem.layout.props.alpha = quadraticEaseOut(1 - age)
    --print(tostring(self.elem.layout.props.alpha))
    self.elem:update()
end

function ToastFunctions.shouldRemove(self)
    return self.elapsedTime > self.expiryTime
end

local ToastContainerFunctions   = {}
ToastContainerFunctions.__index = ToastContainerFunctions

function NewToastContainer()
    local new = {
        toasts = {},
        elem = ui.create(toastContainerLayout(ui.content {}))
    }
    setmetatable(new, ToastContainerFunctions)
    return new
end

function ToastContainerFunctions.purgeToasts(self, purgeAll)
    --- check if remove is pending
    local doRemoval = false
    for _, toast in ipairs(self.toasts) do
        if purgeAll or toast:shouldRemove() then
            doRemoval = true
            break
        end
    end

    if (not doRemoval) or (#(self.toasts) == 0) then
        return
    end

    local remainingToasts = {}
    local remainingContent = {}

    for _, toast in ipairs(self.toasts) do
        if purgeAll or toast:shouldRemove() then
            print("removing toast")
            toast.elem:destroy()
        else
            table.insert(remainingToasts, toast)
            table.insert(remainingContent, toast.elem)
        end
    end

    self.toasts = remainingToasts
    self.elem.layout.content = ui.content(remainingContent)
    if #self.toasts == 0 then
        self.elapsedTime = 0
    end
end

function ToastContainerFunctions.update(self, dt, newToasts)
    self:purgeToasts()
    if newToasts then
        for _, toast in ipairs(newToasts) do
            local addedToast = newToast(toast)
            table.insert(self.toasts, addedToast)
            table.insert(self.elem.layout.content, addedToast.elem)
        end
    end
    for _, toast in ipairs(self.toasts) do
        toast:update(dt)
    end
    self.elem:update()
end

return {
    NewToastContainer = NewToastContainer,
}
