local cache

local function initialized(e)
    cache = {
    tes3.loadMesh("kurp\\b\\vfx\\s_cast_barm_he.nif"),
    tes3.loadMesh("kurp\\b\\vfx\\s_cast_barm_bo.nif"),
    tes3.loadMesh("kurp\\b\\vfx\\s_cast_barm_gl.nif"),
    tes3.loadMesh("kurp\\b\\vfx\\s_cast_barm_cu.nif"),
    tes3.loadMesh("kurp\\b\\vfx\\s_cast_bweap.nif"),
    tes3.loadMesh("kurp\\b\\vfx\\s_cast_bshield.nif"),
    tes3.loadMesh("kurp\\b\\vfx\\s_hit_boundw.nif"),
    tes3.loadMesh("kurp\\b\\vfx\\s_hit_bounda.nif"),
    }
end
event.register("initialized", initialized)