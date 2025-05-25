-- Core logic for replacing static keg models with usable ones,
-- OpenMW modules
local world     = require("openmw.world")
local types     = require("openmw.types")

-- Known keg model IDs (to be replaced on activation)
local wellIds = {
["ex_nord_well_01"] = true,
["ab_ex_hlawell01"] = true,
["ex_nord_well_01a"] = true,
["furn_well00"] = true,
["t_com_set_well_02"] = true,
["t_com_set_welldg_01"] = true,
["t_bre_setostr_x_well_01"] = true,
["t_de_setind_x_well_01"] = true,
["t_de_sethla_x_well_01"] = true,
["t_de_setred_x_well_01"] = true,
["t_de_setmh_x_well_01"] = true,
["t_imp_legioncyr_x_well_01"] = true,
["t_imp_legionmw_x_well_01"] = true,
["t_imp_legionsky_x_well_01"] = true,
["t_imp_setgcpoor_x_well_01"] = true,
["t_imp_setkva_x_well_01"] = true,
["t_imp_setnord_x_well_01"] = true,
["t_imp_setsky_x_well_02"] = true,
["t_nor_set_well_03"] = true,
["t_nor_set_well_01"] = true,
["t_nor_set_well_02"] = true,
["t_nor_set_well_04"] = true,
["t_nor_set_well_05"] = true,
["t_nor_setskaal_well_01"] = true,
["t_imp_setsky_x_well_01"] = true,
["t_imp_setkva_x_well_02"] = true,
["_ex_hlaalu_well"] = true,
["bw_ex_hlaalu_well"] = true,
["ex_imp_well_01"] = true,
["ex_imp_well_01_square"] = true,
["ex_redoran_well_01"] = true,
["izi_hlaalu_well"] = true,
["r0_red_well"] = true,
["rp_mh_well_01"] = true,
["rp_red_well"] = true,
["rp_ww_izi_hlaalu_well"] = true,
["t_de_setveloth_x_well_01"] = true,
["t_imp_setmw_x_fountain_01"] = true,
["t_imp_legionmw_x_well_02"] = true,
["t_rga_setreach_x_pool_01"] = true, 
}
-- Determine if object should be replaced with a usable keg
local shouldReplace
    shouldReplace = function(obj)
        return obj.type == types.Static and wellIds[obj.recordId:lower()]
    end

-- Called when keg object is added to world; replaces it with usable keg
local function onObjectActive(obj)
    if shouldReplace(obj) then

        local record = obj.type == types.Static and types.Static.record(obj.recordId)
                    or obj.type == types.Activator and types.Activator.record(obj.recordId)

        local newObj = world.createObject("detd_well_fillme", 1)

        newObj.enabled = obj.enabled
        newObj:setScale(obj.scale)
        newObj:teleport(obj.cell, obj.position, obj.rotation)
    end
end


-- Main API export
return {
    engineHandlers = {
        onObjectActive = onObjectActive
    }
}

