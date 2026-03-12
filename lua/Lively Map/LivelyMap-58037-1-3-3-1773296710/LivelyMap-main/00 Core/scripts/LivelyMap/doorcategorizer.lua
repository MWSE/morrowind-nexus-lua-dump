--[[
LivelyMap for OpenMW.
Copyright (C) Erin Pentecost 2025

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

local MOD_NAME       = require("scripts.LivelyMap.ns")
local aux_util       = require('openmw_aux.util')

local category       = {
    --- vivec, cantons, velothi towers, tombs.
    --- need to split based on number of doors.
    velothi = "velothi",
    hlaalu = "hlaalu",
    redoran = "redoran",
    telvanni = "telvanni",
    ashlander = "ashlander",

    nord = "nord",
    imperial = "imperial",
    common = "common",

    daedra = "daedra",
    dwemer = "dwemer",
    stronghold = "stronghold",
}

local doorToCategory = {
    ["meshes/d/ex_velothi_loaddoor_01.nif"] = category.velothi,
    ["ex_velothi_loaddoor_01"] = category.velothi,
    ["meshes/d/ex_v_cantondoor_01.nif"] = category.velothi,
    ["Ex_V_cantondoor_01"] = category.velothi,

    ["meshes/d/hlaalu_loaddoor_ 02.nif,"] = category.hlaalu,
    ["hlaalu_loaddoor_ 02"] = category.hlaalu,
    ["meshes/d/hlaalu_loaddoor_ 01.nif,"] = category.hlaalu,
    ["hlaalu_loaddoor_ 01"] = category.hlaalu,

    ["meshes/d/ex_redoran_hut_01_a.nif"] = category.redoran,
    ["ex_redoran_hut_01_a"] = category.redoran,
    ["meshes/d/door_redoran_tower_01.nif"] = category.redoran,
    ["door_redoran_tower_01"] = category.redoran,

    ["meshes/d/ex_t_door_01.nif"] = category.telvanni,
    ["ex_t_door_01"] = category.telvanni,
    ["meshes/d/ex_t_door_02.nif"] = category.telvanni,
    ["ex_t_door_02"] = category.telvanni,

    ["meshes/d/ex_nord_door_01.nif"] = category.nord,
    ["ex_nord_door_01"] = category.nord,
    ["meshes/d/ex_nord_door_02.nif"] = category.nord,
    ["ex_nord_door_02"] = category.nord,
    ["meshes/x/ex_nord_doorf_01.nif"] = category.nord,
    ["meshes/x/ex_nord_door_02.nif"] = category.nord,

    ["meshes/d/ex_imp_loaddoor_01.nif"] = category.imperial,
    ["ex_imp_loaddoor_01"] = category.imperial,
    ["meshes/d/ex_imp_loaddoor_02.nif"] = category.imperial,
    ["ex_imp_loaddoor_02"] = category.imperial,
    ["meshes/d/ex_imp_loaddoor_03.nif"] = category.imperial,
    ["ex_imp_loaddoor_03"] = category.imperial,
    ["meshes/i/in_com_traptop_01.nif"] = category.imperial,
    ["in_com_traptop_01"] = category.imperial,

    ["meshes/d/ex_common_door_01.nif"] = category.common,
    ["ex_common_door_01"] = category.common,
    ["meshes/x/ex_de_shack_door.nif"] = category.common,
    ["ex_de_shack_door"] = category.common,


    ["meshes/x/ex_ashl_door_02.nif"] = category.ashlander,
    ["ex_ashl_door_02"] = category.ashlander,
    ["meshes/x/ex_ashl_door_01.nif"] = category.ashlander,
    ["ex_ashl_door_01"] = category.ashlander,


    ["in_strong_vaultdoor00"] = category.stronghold,
    ["meshes/d/in_strong_vaultdoor00.nif"] = category.stronghold,

    ["ex_dae_door_load_oval"] = category.daedra,
    ["meshes/d/ex_dae_door_load_oval.nif"] = category.daedra,

    ["door_dwrv_double01"] = category.dwemer,
    ["meshes/d/door_dwrv_double01.nif"] = category.dwemer,
}

---@type {[string]: {iconName: string, color: number}}
local templates      = {
    canton = {
        color = 5,
        iconName = "village",
    },
    tomb = {
        color = 5,
        iconName = "caution",
    },
    redoran = {
        color = 2,
        iconName = "village",
    },
    hlaalu = {
        color = 1,
        iconName = "village",
    },
    telvanni = {
        color = 4,
        iconName = "village",
    },
    town = {
        color = 3,
        iconName = "village",
    },
    daedra = {
        color = 4,
        iconName = "danger",
    },
    stronghold = {
        color = 5,
        iconName = "danger",
    },
    dwemer = {
        color = 1,
        iconName = "danger",
    },
    camp = {
        color = 5,
        iconName = "campsite",
    },
    default = {
        color = 5,
        iconName = "circle",
    }
}

---@param doorInfos DoorInfo[]
local function getScores(doorInfos)
    local out = {}
    for _, door in ipairs(doorInfos) do
        if doorToCategory[door.recordId] then
            out[doorToCategory[door.recordId]] = (out[doorToCategory[door.recordId]] or 0) + 1
        elseif doorToCategory[door.model] then
            out[doorToCategory[door.model]] = (out[doorToCategory[door.model]] or 0) + 1
        end
    end
    return out
end

---@param doorInfos DoorInfo[]
local function getTemplateForDoors(doorInfos)
    local scores = getScores(doorInfos)
    local highScore = function(cat)
        return ((scores[cat] or 0) / (#scores or 1)) > 0.4
    end

    if highScore(category.velothi) then
        if scores[category.velothi] >= 2 then
            return templates.canton
        end
        return templates.tomb
    elseif highScore(category.hlaalu) then
        return templates.hlaalu
    elseif highScore(category.redoran) then
        return templates.redoran
    elseif highScore(category.telvanni) then
        return templates.telvanni
    elseif highScore(category.ashlander) then
        return templates.camp
    elseif highScore(category.nord) then
        return templates.town
    elseif highScore(category.imperial) then
        return templates.town
    elseif highScore(category.common) then
        return templates.town
    elseif highScore(category.daedra) then
        return templates.daedra
    elseif highScore(category.dwemer) then
        return templates.dwemer
    elseif highScore(category.stronghold) then
        return templates.stronghold
    end

    print("Can't identify area. Scores: " .. aux_util.deepToString(scores, 5))

    return templates.default
end

return {
    interfaceName = MOD_NAME .. "DoorCategorizer",
    interface = {
        version = 1,
        getTemplateForDoors = getTemplateForDoors,
    },
}
