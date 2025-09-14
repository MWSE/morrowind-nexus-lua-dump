--[[
ErnShaderWrangler for OpenMW.
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


local StatsFunctions = {}
StatsFunctions.__index = StatsFunctions

local function newWindow()
    return {
        count = 0,
        mean = 0,
        m2 = 0,
    }
end

local function addSampleToWindow(window, sample)
    window.count = window.count + 1
    local delta = sample - window.mean
    window.mean = window.mean + delta / window.count
    local delta2 = sample - window.mean
    window.m2 = window.m2 + delta * delta2
end

-- this is just an A/B Welford situation offset by half a window
-- https://en.wikipedia.org/wiki/Algorithms_for_calculating_variance
function NewSampleCollection(samplesPerWindow)
    local new = {
        samplesPerWindow = samplesPerWindow,
        currentSampleNumber = 0,
        active = newWindow(),
        inactive = newWindow()
    }
    setmetatable(new, StatsFunctions)
    return new
end

function StatsFunctions.add(self, sample)
    -- if the current window is full, swap to the other one.
    if self.active.count > self.samplesPerWindow then
        -- the active tracker is full. time to swap.
        self.active.count = self.inactive.count
        self.active.mean = self.inactive.mean
        self.active.m2 = self.inactive.m2

        self.inactive.count = 0
        self.inactive.mean = 0
        self.inactive.m2 = 0
    end

    -- always add a sample to the current window.
    addSampleToWindow(self.active, sample)

    -- offset adding samples to the other window.
    if self.currentSampleNumber > self.samplesPerWindow / 3 then
        addSampleToWindow(self.inactive, sample)
    else
        self.currentSampleNumber = self.currentSampleNumber + 1
    end
end

function StatsFunctions.calculate(self)
    if self.active.count < 2 then
        return nil
    end
    return {
        mean = self.active.mean,
        variance = self.active.m2 / self.active.count
    }
end

return {
    NewSampleCollection = NewSampleCollection
}
