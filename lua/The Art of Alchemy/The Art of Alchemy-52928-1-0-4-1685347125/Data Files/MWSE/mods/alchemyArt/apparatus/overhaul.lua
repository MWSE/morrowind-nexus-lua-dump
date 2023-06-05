local apparatusOverhaul = {}

local skoomaPipe = {
    apparatus_a_spipe_01 = true,
    apparatus_a_spipe_tsia = true
}

apparatusOverhaul.rebalance = function ()
    for app in tes3.iterateObjects(tes3.objectType.apparatus) do
        if not skoomaPipe[app.id] and string.startswith(app.id, "apparatus_a") then
            app.quality = 0.75
        elseif string.startswith(app.id, "apparatus_j") then
            app.quality = 1
        elseif string.startswith(app.id, "apparatus_m") then
            app.quality = 1.25
        elseif string.startswith(app.id, "apparatus_g") then
            app.quality = 1.5
        end
    end
end

local toChange = {
    apparatus_a_mortar_01 = {
        mesh = "m\\Misc_mortarpestle_A_01.nif",
        icon = "m\\Tx_mortarpestle_A_01.dds"
    },
    apparatus_a_mortar_static = {
        mesh = "m\\Misc_mortarpestle_A_01.nif",
        icon = "m\\Tx_mortarpestle_A_01.dds"
    },
    apparatus_j_calcinator_01 = {
        mesh = "m\\App_J_Calcinator_01.nif",
        icon = "m\\Tx_calcinator_02.dds"
    },
    apparatus_j_calcinator_static = {
        mesh = "m\\App_J_Calcinator_01.nif",
        icon = "m\\Tx_calcinator_02.dds"
    },
    apparatus_g_alembic_01 = {
        mesh = "m\\Apparatus_S_Alembic_01.nif",
        icon = "m\\Tx_alembic_05.dds"
    },
    apparatus_g_alembic_static = {
        mesh = "m\\Apparatus_S_Alembic_01.nif",
        icon = "m\\Tx_alembic_05.dds"
    },
    apparatus_sm_alembic_01 = {
        mesh = "m\\Apparatus_G_Alembic_01.nif",
        icon = "m\\Tx_alembic_04.dds"
    },
    apparatus_sm_alembic_static = {
        mesh = "m\\Apparatus_G_Alembic_01.nif",
        icon = "m\\Tx_alembic_04.dds"
    }
}

apparatusOverhaul.changeMeshes = function ()
    for id, data in pairs(toChange) do
        local app = tes3.getObject(id)
        if app then
            app.mesh = data.mesh
            app.icon = data.icon
        end
    end
end

return apparatusOverhaul