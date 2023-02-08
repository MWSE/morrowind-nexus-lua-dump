local cache

local function initialized(e)
    cache = {
    tes3.loadMesh("kurp\\b\\w\\bound_longsword.nif"),
    tes3.loadMesh("kurp\\b\\w\\bound_dagger.nif"),
    tes3.loadMesh("kurp\\b\\w\\bound_axe.nif"),
    tes3.loadMesh("kurp\\b\\w\\bound_longbow.nif"),
    tes3.loadMesh("kurp\\b\\w\\bound_mace.nif"),
    tes3.loadMesh("kurp\\b\\w\\bound_shield.nif"),
    tes3.loadMesh("kurp\\b\\w\\bound_spear.nif"),
    tes3.loadMesh("kurp\\b\\a\\bavfx_cuir.nif"),
    tes3.loadMesh("kurp\\b\\a\\bavfx_gaun.nif"),
    tes3.loadMesh("kurp\\b\\a\\bound_elb.nif"),
    tes3.loadMesh("kurp\\b\\a\\bound_G_G.nif"),
    tes3.loadMesh("kurp\\b\\a\\bound_g_UL_L.nif"),
    tes3.loadMesh("kurp\\b\\a\\bound_g_UL_R.nif"),
    tes3.loadMesh("kurp\\b\\a\\bound_P_CL.nif"),
    tes3.loadMesh("kurp\\b\\a\\bound_p_UA.nif"),
    tes3.loadMesh("kurp\\b\\a\\BoundArmor1st.nif"),
    tes3.loadMesh("kurp\\b\\a\\BoundArmorM.nif"),
    tes3.loadMesh("kurp\\b\\a\\boundb_ank_L.nif"),
    tes3.loadMesh("kurp\\b\\a\\boundb_ank_R.nif"),
    tes3.loadMesh("kurp\\b\\a\\boundb_feet.nif"),
    tes3.loadMesh("kurp\\b\\a\\boundhelm.nif")
    }
end
event.register("initialized", initialized)