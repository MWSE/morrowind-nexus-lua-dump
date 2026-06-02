local content = require('openmw.content')
local core = require('openmw.core')

local ingredients = content.ingredients.records
local globals = content.globals.records

local function updateIngred(ingredSrc, ingredDst)
    local iSrc = ingredients[ingredSrc]
    local iDst = ingredients[ingredDst]

    if iDst and iSrc then
        for _, iProperty in pairs{"icon", "model", "name", "value", "weight"} do
            iDst[iProperty] = iSrc[iProperty]
        end

        iDst.effects = {}
        for i = 1, 4 do
            if iSrc.effects[i] then
                iDst.effects[i] = {
                    id = iSrc.effects[i].id,
                    affectedAttribute = iSrc.effects[i].affectedAttribute,
                    affectedSkill = iSrc.effects[i].affectedSkill,
                }
            end
        end
    end
end

if core.contentFiles.has('OAAB_Data.esm') or (globals.ab_enchantbonus ~= nil) then
    updateIngred("AB_IngCrea_SfMeat_01", "pf_IngFood_SfMeat_01")
end

if core.contentFiles.has('Tamriel_Data.esm') or (globals.t_glob_passtimehours ~= nil) then
    updateIngred("T_IngFood_FishBrowntrout_01", "pf_IngFood_FishBrowntrout_01")
    updateIngred("T_IngFood_FishPike_01", "pf_IngFood_FishPike_01")
    updateIngred("T_IngFood_FishPikeperch_01", "pf_IngFood_FishPikeperch_01")
    updateIngred("T_IngFood_FishSpr_01", "pf_IngFood_FishSpr_01")
    updateIngred("T_IngFood_FishStrid_01", "pf_IngFood_FishStrid_01")
    updateIngred("T_IngFood_FishSalmon_01", "pf_IngFood_FishSalmon_01")
    updateIngred("T_IngFood_FishCod_01", "pf_IngFood_FishCod_01")
    updateIngred("T_IngFood_FishChrysophant_01", "pf_IngFood_FishChrysophant_01")
end	