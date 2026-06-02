local core = require('openmw.core')
local world = require('openmw.world')
local crime = require('scripts.gravity_enforcement_act.crime')
local vendor = require('scripts.gravity_enforcement_act.vendor')

local function onUpdate(dt)
    vendor.onUpdate(dt)
end

local function onSoftPushPlayer(data)
    if not data or not data.dz or data.dz <= 0 then
        return
    end

    local player = world.players[1]
    if not player or not player:isValid() then
        return
    end

    local cell = player.cell
    local pos = player.position
    if not cell or not pos then
        return
    end

    local dz = data.dz
    local clearance = data.clearance or 64
    local destZ = pos.z - dz

    -- Exterior terrain safety.
    -- Lua keeps the safety check; MWScript only applies the final Z movement.
    if cell.isExterior and core.land and core.land.getHeightAt then
        local ok, groundZ = pcall(core.land.getHeightAt, pos, cell)

        if ok and groundZ then
            local safeZ = groundZ + clearance

            -- If player is already inside/too close to terrain, do not push lower.
            -- We intentionally do NOT teleport-rescue upward anymore.
            if pos.z < safeZ then
                return
            end

            -- Clamp the push so it stops exactly at safeZ instead of clipping below terrain.
            if destZ < safeZ then
                dz = pos.z - safeZ
            end
        end
    end

    if dz <= 0 then
        return
    end

    local globals = world.mwscript.getGlobalVariables(player)
    if not globals then
        return
    end

    globals.pxm_gea_push_dz = dz
    globals.pxm_gea_push_request = 1
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        GEA_SoftPushPlayer = onSoftPushPlayer,
        GEA_CommitIllegalLevitationCrime = crime.onCommitIllegalLevitationCrime,
        GEA_UpdateVendorLevitateConfig = vendor.onUpdateConfig,
    }
}
