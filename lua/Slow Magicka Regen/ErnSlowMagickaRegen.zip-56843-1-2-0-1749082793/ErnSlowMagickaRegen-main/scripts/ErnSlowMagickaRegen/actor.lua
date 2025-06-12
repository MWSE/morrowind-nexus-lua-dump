--[[
ErnSlowMagickaRegen for OpenMW.
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
local interfaces = require("openmw.interfaces")
local settings = require("scripts.ErnSlowMagickaRegen.settings")
local types = require("openmw.types")
local self = require("openmw.self")

local lastUpdateTime = nil
-- partialMagicka tracks how much regen we've stocked up and have yet to apply.
local partialMagicka = 0.0
-- lastFatigueRatio is fatigue sample we took the last time we regenerated.
local lastFatigueRatio = 0.5
-- lastMagicka is just used to discern between resting and waiting.
local lastMagicka = nil

local function isStunted(actor)
    for _, effect in pairs(types.Actor.activeEffects(self)) do
        if effect.id == "stuntedmagicka" then
            return true
        end
    end
    return false
end

local function skipRegen(actor)
    return (settings.scale(actor) <= 0) or (isStunted(actor) == true)
end

local function regen(actor, durationInSeconds, fatigueRatio)
    if skipRegen(actor) then
        return
    end

    local magickaStat = self.type.stats.dynamic.magicka(self)
    local maximumMagicka = magickaStat.base
    if magickaStat.current >= maximumMagicka then
        partialMagicka = 0.0
        return
    end

    scale = settings.scale(actor)
    if scale <= 0 then
        return
    end

    local intelligence = self.type.stats.attributes.intelligence(actor).modified

    local magickaDelta = 0.000041667 * intelligence * fatigueRatio * scale

    partialMagicka = partialMagicka + (magickaDelta * durationInSeconds)

    if partialMagicka >= 1.0 then
        local wholeIncrease = math.floor(partialMagicka)
        partialMagicka = partialMagicka - wholeIncrease
        
        if magickaStat.current < maximumMagicka then
            settings.debugPrint("Regenerating "..wholeIncrease..
                " magicka for actor ".. self.id .. ". Magicka: " ..
                magickaStat.current .. "/" .. maximumMagicka ..
                ". Instant rate: " .. magickaDelta .. "/s. DeltaTime: " .. durationInSeconds .. ".")

            magickaStat.current = math.min(magickaStat.current+wholeIncrease, maximumMagicka)
        end
    end
end

local function regenMagicka(data)
    -- simTime is real-world time.
    -- simTime rate is 0.00125 x Int per  second.
    -- gameTime is the time for actors in Morrowind.
    -- gameTime rate is 0.15 x Int per hour, or 0.000041667 x Int per second
    gameTime = data.gameTime

    if lastUpdateTime == nil then
        lastUpdateTime = gameTime
    end

    local currentMagicka = self.type.stats.dynamic.magicka(self).current
    if lastMagicka == nil then
        lastMagicka = currentMagicka
    end

    deltaTime = gameTime - lastUpdateTime
    --print("gameTime: " .. gameTime .. " last: " .. lastUpdateTime .. "delta: " .. deltaTime)
    lastUpdateTime = gameTime

    if deltaTime < 0 then
        error("deltaTime for actor " .. self.id .. " is " .. deltaTime)
    end

    -- deltaTime is the time since we last ran regen.
    -- This works even if an actor became inactive.

    -- Get the average of fatigue from our last regen to right now,
    -- and use that to inform how much regen should be reduced.
    local fatigueStat = self.type.stats.dynamic.fatigue(self)
    local currentFatigueRatio = fatigueStat.current / fatigueStat.base
    local avgFatigue = (currentFatigueRatio + lastFatigueRatio) / 2.0
    lastFatigueRatio = currentFatigueRatio

    -- If we jumped over an hour, then we are probably waiting or resting.
    if deltaTime >= 3600 then
        settings.debugPrint("Detected a time jump for actor " .. self.id .. ".")
        -- Only consider current fatigue in this case, since fatigue regens
        -- quickly.
        avgFatigue = currentFatigueRatio
        -- Check if magicka increased. If it did, the player rested.
        if currentMagicka > lastMagicka then
            settings.debugPrint("Detected a rest for actor " .. self.id .. ". Skipping regen.")
            -- Since the player rested, do a dummy regen to nullify
            -- the rest period gains. This prevents duplication of mana regen.
            regen(self, deltaTime, 0)
            lastMagicka = currentMagicka
            return
        end
        -- Else the player waited, so calculate normally.
    end

    -- Actually do the regen.
    regen(self, deltaTime, avgFatigue)
    lastMagicka = currentMagicka
end

return {
    eventHandlers = {
        regenMagicka = regenMagicka
    },
}