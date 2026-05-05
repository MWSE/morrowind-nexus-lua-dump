local I       = require("openmw.interfaces")
local self    = require("openmw.self")
local ambient = require('openmw.ambient')

local deps    = require("scripts.RingABell.utils.dependencies")
deps.checkAll("Ring a Bell", { {
    plugin = "Impact Effects.omwscripts",
    interface = I.impactEffects
} })

local bells = {
    -- vanilla
    ["active_6th_bell_01"]      = true,
    ["active_6th_bell_02"]      = true,
    ["active_6th_bell_03"]      = true,
    ["active_6th_bell_04"]      = true,
    ["active_6th_bell_05"]      = true,
    ["active_6th_bell_06"]      = true,
    -- tamriel data
    ["tr_m3_q_kha_bell1"]       = true,
    ["tr_m3_q_kha_bell2"]       = true,
    ["tr_m3_q_kha_bell3"]       = true,
    ["tr_m3_q_kha_bell4"]       = true,
    ["tr_m3_q_kha_bell5"]       = true,
    ["tr_m3_q_kha_bell6"]       = true,
    ["t_de_setind_bell_01"]     = true,
    ["t_de_setind_bell_02"]     = true,
    ["t_de_setind_bell_03"]     = true,
    ["t_de_setind_bell_04"]     = true,
    ["t_de_setind_bell_05"]     = true,
    ["t_de_setind_bell_06"]     = true,
    ["t_de_setind_bell_07"]     = true,
    ["tr_act_m2-69_bell"]       = true,
    ["tr_m3_oe_act_bell"]       = true,
    ["t_de_setind_gong_01"]     = true,
    ["t_de_setind_gong_02"]     = true,
    ["t_de_setind_drum_01"]     = true,
    ["t_de_setind_drum_02"]     = true,
    ["t_de_setind_drum_03"]     = true,
    -- tamriel rebuilt
    ["tr_m1_bthalcrystal_act1"] = true,
    ["tr_m1_bthalcrystal_act2"] = true,
    ["tr_m1_bthalcrystal_act3"] = true,
    ["tr_m1_bthalcrystal_act4"] = true,
    ["tr_m1_bthalcrystal_act5"] = true,
    ["tr_m1_bthalcrystal_act6"] = true,
}

local belltowers = {
    -- bell towers of vvardenfell
    ["dm_ex_sur_bell"]   = true,
    ["dm_ex_nosnd_bell"] = true,
    ["dm_ex_balm2_bell"] = true,
    ["dm_ex_mora_bell"]  = true,
    ["dm_gna_bell"]      = true,
}

---@param obj GameObject
---@param var any
---@param res RayCastingResult
I.impactEffects.addHitObjectHandler(function(obj, var, res)
    if bells[obj.recordId] then
        obj:activateBy(self)
    elseif belltowers[obj.recordId] then
        ambient.say("sound\\rab\\dm_imperialbell_close.wav")
    end
end)
