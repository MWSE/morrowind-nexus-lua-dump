
local M = {}


local BONE_BY_TYPE = {
    [0]  = "Bip01 ShortBladeOneHand",   
    [1]  = "Bip01 LongBladeOneHand",    
    [2]  = "Bip01 LongBladeTwoClose",  
    [3]  = "Bip01 BluntOneHand",        
    [4]  = "Bip01 BluntTwoClose",      
    [5]  = "Bip01 BluntTwoWide",       
    [6]  = "Bip01 SpearTwoWide",        
    [7]  = "Bip01 LongBladeOneHand",    
    [8]  = "Bip01 AxeTwoClose",         
    [9]  = "Bip01 MarksmanBow",         
    [10] = "Bip01 MarksmanCrossbow",    
    [11] = "Bip01 MarksmanThrown",      
    [12] = "Bip01 Ammo",                
    [13] = "Bip01 Ammo",                
}

M.SHIELD_BONE        = "Bip01 AttachShield"
M.ATTACH_WEAPON_BONE = "Bip01 AttachWeapon"  

function M.boneForWeapon(weaponType)
    return BONE_BY_TYPE[weaponType] or M.ATTACH_WEAPON_BONE
end

return M
