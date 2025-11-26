--[[
ErnPerkFramework for OpenMW.
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
local ns = require("scripts.ErnExamplePerkPack.namespace")
local interfaces = require("openmw.interfaces")
local ui = require('openmw.ui')

-- We're going to make 50 dummy perks with a variety of different requirements.
for i = 1, 50, 1 do
    local id = ns .. "_dummy_" .. tostring(i)
    local requirements = {}

    local levelReq = 10 * math.floor(i / 15)
    if levelReq > 0 then
        table.insert(requirements, interfaces.ErnPerkFramework.requirements().minimumLevel(levelReq))
    end
    if i == 1 then
        table.insert(requirements, interfaces.ErnPerkFramework.requirements().
        minimumFactionRank('thieves guild', 0))
        table.insert(requirements, interfaces.ErnPerkFramework.requirements().
        vampire(false))
        table.insert(requirements, interfaces.ErnPerkFramework.requirements().
        werewolf(false))
    elseif i == 2 then
        table.insert(requirements, interfaces.ErnPerkFramework.requirements().
        minimumSkillLevel('sneak', 40))
    elseif i == 3 then
        table.insert(requirements, interfaces.ErnPerkFramework.requirements().
        minimumAttributeLevel('strength', 50))
    elseif i == 4 then
        table.insert(requirements, interfaces.ErnPerkFramework.requirements().
        race("khajiit", "argonian", "dark elf"))
    elseif i == 5 then
        -- You can group requirements into OR group arbitrarily
        table.insert(requirements, interfaces.ErnPerkFramework.requirements().
        orGroup(
            interfaces.ErnPerkFramework.requirements().minimumSkillLevel('mysticism', 30),
            interfaces.ErnPerkFramework.requirements().minimumSkillLevel('destruction', 30)
        )
        )
    elseif i == 6 then
        table.insert(requirements, interfaces.ErnPerkFramework.requirements().
        orGroup(
            interfaces.ErnPerkFramework.requirements().race('high elf'),
            interfaces.ErnPerkFramework.requirements().andGroup(
                interfaces.ErnPerkFramework.requirements().minimumSkillLevel('mysticism', 30),
                interfaces.ErnPerkFramework.requirements().minimumAttributeLevel('intelligence', 70)
            )
        )
        )
    elseif i >= 7 and i <= 10 then
        -- You can make perks require other perks.
        -- If you end up making a cycle the game will probably crash.
        table.insert(requirements, interfaces.ErnPerkFramework.requirements().hasPerk(ns .. "_dummy_" .. tostring(i - 1)))
    elseif i == 11 then
        -- exclusive perk demo
        table.insert(requirements,
            interfaces.ErnPerkFramework.requirements().invert(interfaces.ErnPerkFramework.requirements().hasPerk(
                ns .. "_dummy_" .. tostring(12), ns .. "_dummy_" .. tostring(13))))
    elseif i == 12 then
        -- exclusive perk demo
        table.insert(requirements,
            interfaces.ErnPerkFramework.requirements().invert(interfaces.ErnPerkFramework.requirements().hasPerk(
                ns .. "_dummy_" .. tostring(11), ns .. "_dummy_" .. tostring(13))))
    elseif i == 13 then
        -- exclusive perk demo
        table.insert(requirements,
            interfaces.ErnPerkFramework.requirements().invert(interfaces.ErnPerkFramework.requirements().hasPerk(
                ns .. "_dummy_" .. tostring(11), ns .. "_dummy_" .. tostring(12))))
    end

    interfaces.ErnPerkFramework.registerPerk({
        id = id,
        requirements = requirements,
        localizedName = "Example " .. tostring(i),
        localizedDescription = "perk description " .. tostring(i),
        onAdd = function()
            -- This function should be idempotent.
            -- That means the framework should be able to call it multiple times,
            -- and your function shouldn't have any additional side effect after
            -- the first time it is called.
            local logLine = id .. " perk added!"
            ui.showMessage(logLine, {})
            print(logLine)
        end,
        onRemove = function()
            -- This function should clean up after your perk.
            -- For example, if you applied any magic effects, you would remove them here.
            local logLine = id .. " perk removed!"
            ui.showMessage(logLine, {})
            print(logLine)
        end,
    })
end

-- perks with nonstandard costs
interfaces.ErnPerkFramework.registerPerk({
    id = ns .. "_dummy_" .. "penalty",
    requirements = {},
    -- You'll want to use localization rather than just relying on a string for this field.
    -- Try to keep perk names brief since it will mess up the UI if they are too long.
    localizedName = "Negative Cost",
    -- You can use levelup art if you don't have any textures for your perk.
    art = "textures\\levelup\\knight",
    cost = -1,
    -- You'll want to use localization rather than just relying on a string for this field.
    localizedDescription = "This perk has a negative cost, so it could be used as a handicap.",
    onAdd = function()
        local logLine = "Negative Cost perk added!"
        ui.showMessage(logLine, {})
        print(logLine)
    end,
    onRemove = function()
        local logLine = "Negative Cost perk removed!"
        ui.showMessage(logLine, {})
        print(logLine)
    end,
})
interfaces.ErnPerkFramework.registerPerk({
    id = ns .. "_dummy_" .. "expensive",
    requirements = {},
    localizedName = "Expensive Cost",
    art = "textures\\levelup\\healer",
    cost = 2,
    localizedDescription = "This perk costs extra points, so it could be extra powerful.",
    onAdd = function()
        local logLine = "Expensive Cost perk added!"
        ui.showMessage(logLine, {})
        print(logLine)
    end,
    onRemove = function()
        local logLine = "Expensive Cost perk removed!"
        ui.showMessage(logLine, {})
        print(logLine)
    end,
})
interfaces.ErnPerkFramework.registerPerk({
    id = ns .. "_dummy_" .. "hidden",
    requirements = {},
    localizedName = "Hidden Perk",
    art = "textures\\levelup\\acrobat",
    cost = 0,
    hidden = true,
    localizedDescription =
    "This perk is not normally visible in the UI. This can be shown if you do this console command: `lua perks ErnExamplePerkPack_dummy_hidden`",
    onAdd = function()
        local logLine = "Hidden perk added!"
        ui.showMessage(logLine, {})
        print(logLine)
    end,
    onRemove = function()
        local logLine = "Hidden perk removed!"
        ui.showMessage(logLine, {})
        print(logLine)
    end,
})
