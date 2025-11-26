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
local pself = require("openmw.self")
local types = require("openmw.types")
local ns = require("scripts.ErnCultistPerk.namespace")
local interfaces = require("openmw.interfaces")
local core = require("openmw.core")
local localization = core.l10n(ns)

local totalRequired = 3

-- no need to persist this; the perk will be applied by the framework.
local hasPerk = false

--[[
Test with:
journal DA_Azura, 30
journal DA_Boethiah, 70
journal DA_Malacath, 70
journal DA_Mehrunes, 40
journal DA_Mephala, 60
journal DA_MolagBal, 30
]]

local daedricQuests = {
    -- these must be lowercased
    ['da_azura'] = 30,
    ['da_boethiah'] = 70,
    ['da_malacath'] = 70,
    ['da_mehrunes'] = 40,
    ['da_mephala'] = 60,
    ['da_molagbal'] = 30,
    ['da_sheogorath'] = 70,
    -- TR
    ['tr_m7_da_meridia'] = 100,
    ['tr_m7_da_namira'] = 100,
    ['tr_m1_da_sanguine'] = 100,
}

local function getCompletedQuests()
    local completedOK = 0
    for id, quest in pairs(types.Player.quests(pself)) do
        if (daedricQuests[id] ~= nil) and (daedricQuests[id] == quest.stage) then
            completedOK = completedOK + 1
        end
    end
    return completedOK
end

interfaces.ErnPerkFramework.registerPerk({
    id = ns .. "_daedric_cultist",
    requirements = {
        {
            id = ns .. '_completed_daedric_quests',
            localizedName = function()
                return localization("req_completed_daedric_quests",
                    { done = getCompletedQuests(), total = totalRequired })
            end,
            check = function()
                return getCompletedQuests() >= totalRequired
            end
        },
    },
    localizedName = localization("cultist_name"),
    art = "textures\\levelup\\sorcerer",
    cost = 1,
    localizedDescription = localization("cultist_description"),
    onAdd = function()
        hasPerk = true
    end,
    onRemove = function()
        hasPerk = false
    end,
})

local function daedraSpawned(data)
    if hasPerk then
        local daedraLevel = types.Actor.stats.level(data.creature).current
        local myLevel = types.Actor.stats.level(pself).current
        if myLevel >= daedraLevel then
            data.creature:sendEvent(ns .. "calmDaedra", { player = pself })
        end
    end
end

return {
    eventHandlers = {
        [ns .. "daedraSpawned"] = daedraSpawned,
    }
}
