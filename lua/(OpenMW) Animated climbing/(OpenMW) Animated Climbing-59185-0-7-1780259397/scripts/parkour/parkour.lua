local self       = require('openmw.self')
local nearby     = require('openmw.nearby')
local util       = require('openmw.util')
local interfaces = require('openmw.interfaces')
local anim       = require('openmw.animation')
local input      = require('openmw.input')
local ui         = require('openmw.ui')
local core       = require('openmw.core')
local types      = require('openmw.types')
local camera     = require('openmw.camera')

local RAY_DISTANCE       = 80
local RAY_NEAR_OFFSET    = 10
local RAY_SPREAD         = 12
local RAY_HEIGHT_VLOW    = 18
local RAY_HEIGHT_LOW     = 32
local RAY_HEIGHT_HIGH    = 130

local LEDGE_MIN_HEIGHT   = 100
local LEDGE_MAX_HEIGHT   = 280
local LEDGE_SCAN_ABOVE   = 380

local VAULT_DURATION     = 0.55
local VAULT_ARC_HEIGHT   = 55
local VAULT_FOV_DOT      = 0.50

local VAULT_SMALL_MAX    = 80
local SLOPE_STEEP_MIN    = 12
local SLOPE_STEP_DIST    = 15
local VAULT_MAX_HEIGHT   = 180
local VAULT_LAND_DIST    = 85
local VAULT_MIN_HEIGHT   = 35
local VAULT_LAND_WALL_Z  = 90

local STAIR_CLEAR_HEIGHT = 52

local LAND_Z_OFFSET      = 28
local PROBE_DEPTH        = 40
local TOP_SEARCH_RADIUS  = 30
local TOP_SEARCH_STEPS   = 8
local CHAIN_SCAN_ABOVE   = 500
local EDGE_SEARCH_HALF   = 200

local WALL_STATIC_IDS = {
    ["ex_common_wall_01"]           = true,
    ["ex_common_wall_02"]           = true,
    ["ex_common_wall_03"]           = true,
    ["ex_common_wall_04"]           = true,
    ["ex_common_wall_01_se"]        = true,
    ["ex_common_wall_02_se"]        = true,
    ["ex_common_wall_end_01"]       = true,
    ["ex_common_wall_end_02"]       = true,
    ["ex_common_wall_gate_01"]      = true,
    ["ex_common_wall_gate_02"]      = true,
    ["ex_common_wall_tower_01"]     = true,
    ["ex_common_wall_tower_02"]     = true,
    ["ex_common_wall_tower_se"]     = true,
    ["ex_hlaalu_wall_01"]           = true,
    ["ex_hlaalu_wall_02"]           = true,
    ["ex_hlaalu_wall_03"]           = true,
    ["ex_hlaalu_wall_04"]           = true,
    ["ex_hlaalu_wall_se"]           = true,
    ["ex_hlaalu_wall_end_01"]       = true,
    ["ex_hlaalu_wall_end_02"]       = true,
    ["ex_hlaalu_wall_gate_01"]      = true,
    ["ex_hlaalu_wall_gate_02"]      = true,
    ["ex_hlaalu_wall_tower_01"]     = true,
    ["ex_hlaalu_wall_tower_02"]     = true,
    ["ex_hlaalu_wall_tower_se"]     = true,
    ["ex_velothis_wall_01"]         = true,
    ["ex_velothis_wall_02"]         = true,
    ["ex_velothis_wall_se"]         = true,
    ["ex_velothis_wall_end_01"]     = true,
    ["ex_velothis_wall_gate_01"]    = true,
    ["ex_velothis_wall_tower_01"]   = true,
    ["ex_velothis_wall_tower_se"]   = true,
    ["ex_indoril_wall_01"]          = true,
    ["ex_indoril_wall_02"]          = true,
    ["ex_indoril_wall_se"]          = true,
    ["ex_indoril_wall_end_01"]      = true,
    ["ex_indoril_wall_gate_01"]     = true,
    ["ex_indoril_wall_tower_01"]    = true,
    ["ex_redoran_wall_01"]          = true,
    ["ex_redoran_wall_02"]          = true,
    ["ex_redoran_wall_se"]          = true,
    ["ex_redoran_wall_end_01"]      = true,
    ["ex_redoran_wall_gate_01"]     = true,
    ["ex_redoran_wall_tower_01"]    = true,
    ["ex_redoran_wall_tower_se"]    = true,
    ["ex_telvanni_wall_01"]         = true,
    ["ex_telvanni_wall_02"]         = true,
    ["ex_telvanni_wall_se"]         = true,
    ["ex_telvanni_wall_end_01"]     = true,
    ["ex_telvanni_wall_gate_01"]    = true,
    ["ex_telvanni_wall_tower_01"]   = true,
    ["ex_dwrv_wall_01"]             = true,
    ["ex_dwrv_wall_02"]             = true,
    ["ex_dwrv_wall_se"]             = true,
    ["ex_dwrv_wall_end_01"]         = true,
    ["ex_dwrv_wall_gate_01"]        = true,
    ["ex_dwrv_wall_tower_01"]       = true,
    ["ex_dwrv_wall_tower_se"]       = true,
    ["ex_dae_wall_01"]              = true,
    ["ex_dae_wall_02"]              = true,
    ["ex_dae_wall_se"]              = true,
    ["ex_dae_wall_end_01"]          = true,
    ["ex_dae_wall_gate_01"]         = true,
    ["ex_dae_wall_tower_01"]        = true,
    ["ex_dae_wall_tower_se"]        = true,
    ["ex_imp_wall_01"]              = true,
    ["ex_imp_wall_02"]              = true,
    ["ex_imp_wall_03"]              = true,
    ["ex_imp_wall_se"]              = true,
    ["ex_imp_wall_end_01"]          = true,
    ["ex_imp_wall_gate_01"]         = true,
    ["ex_imp_wall_tower_01"]        = true,
    ["ex_imp_wall_tower_02"]        = true,
    ["ex_imp_wall_tower_se"]        = true,
    ["ex_nord_wall_01"]             = true,
    ["ex_nord_wall_02"]             = true,
    ["ex_nord_wall_se"]             = true,
    ["ex_nord_wall_end_01"]         = true,
    ["ex_nord_wall_gate_01"]        = true,
    ["ex_nord_wall_tower_01"]       = true,
    ["ex_nord_wall_tower_se"]       = true,
    ["in_de_p_wall_01"]             = true,
    ["in_de_p_wall_02"]             = true,
    ["in_de_p_wall_03"]             = true,
    ["in_de_p_wall_se"]             = true,
    ["in_de_r_wall_01"]             = true,
    ["in_de_r_wall_02"]             = true,
    ["in_de_r_wall_se"]             = true,
    ["in_de_d_wall_01"]             = true,
    ["in_de_d_wall_02"]             = true,
    ["in_de_d_wall_se"]             = true,
    ["in_de_v_wall_01"]             = true,
    ["in_de_v_wall_02"]             = true,
    ["in_de_v_wall_se"]             = true,
    ["in_imp_wall_01"]              = true,
    ["in_imp_wall_02"]              = true,
    ["in_imp_wall_se"]              = true,
    ["in_nord_wall_01"]             = true,
    ["in_nord_wall_02"]             = true,
    ["in_nord_wall_se"]             = true,
    ["furn_de_ex_wall_01"]          = true,
    ["furn_de_ex_wall_02"]          = true,
    ["ab_wall_01"]                  = true,
    ["ab_wall_02"]                  = true,
    ["ab_wall_se"]                  = true,
    ["ab_wall_end_01"]              = true,
    ["ab_wall_gate_01"]             = true,
    ["ab_wall_tower_01"]            = true,
    ["ab_wall_tower_se"]            = true,
    ["ex_cave_wall_01"]             = true,
    ["ex_cave_wall_02"]             = true,
    ["in_cave_wall_01"]             = true,
    ["in_cave_wall_02"]             = true,
    ["ex_vivec_wall_01"]            = true,
    ["ex_vivec_wall_02"]            = true,
    ["ex_vivec_wall_se"]            = true,
    ["ex_vivec_wall_end_01"]        = true,
    ["ex_vivec_wall_tower_01"]      = true,
}

local MIN_PLATFORM_WIDTH = 45
local WALL_ASPECT_RATIO  = 2.5

local CHAIN_RAY_DIST        = 400
local CHAIN_FOV_DOT         = 0.50
local CHAIN_HEIGHT_DIFF_MAX = 200

local LOOK_JUMP_SCAN_DIST   = 220
local LOOK_JUMP_SCAN_HEIGHT = 50
local LOOK_JUMP_FOV_DOT     = 0.70

local FATIGUE_VAULT_COST = 10

local SAFETY_ABOVE = 200
local SAFETY_LIFT  = 22

local VAULT_SMOOTH = 20

local ANIM_WALLPRESS  = "hitwall"
local ANIM_VAULT      = "minobstacle"
local ANIM_VAULT_LOW  = "lowobstacle"

local state      = "idle"
local vaultTimer = 0

local vaultP0    = nil
local vaultP1    = nil
local vaultP2    = nil

local vaultIsSmall = false

local landedTopZ   = nil
local landedCenter = nil
local landedTimer  = 0

local inputLocked = false

local playingAnim = {}
local wasBlocked  = { forward=false, backward=false, left=false, right=false }

local jumpWasPrev = false

local smoothedVaultPos = nil

local COLL = nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.Door + nearby.COLLISION_TYPE.HeightMap

local function lockInput()
    if inputLocked then return end
    inputLocked = true
    input.setControlSwitch(input.CONTROL_SWITCH.Controls, false)
    input.setControlSwitch(input.CONTROL_SWITCH.Jumping,  false)
end

local function unlockInput()
    interfaces.Controls.overrideMovementControls(false)
    if not inputLocked then return end
    inputLocked = false
    input.setControlSwitch(input.CONTROL_SWITCH.Controls, true)
    input.setControlSwitch(input.CONTROL_SWITCH.Jumping,  true)
end

local HUD_ICON_SIZE = 48

local hud = ui.create({
    layer = 'HUD',
    type  = ui.TYPE.Image,
    props = {
        relativePosition = util.vector2(0.5, 0.95),
        anchor   = util.vector2(0.0, 0.0),
        size     = util.vector2(HUD_ICON_SIZE, HUD_ICON_SIZE),
        resource = ui.texture({ path = 'icons/climbing.dds' }),
        visible  = false,
    },
})

local function setHUD(active)
    hud.layout.props.visible = active
    hud:update()
end

local function playAnim(name, loops, fullBody)
    if playingAnim[name] then return end
    playingAnim[name] = true
    local prio = {
        [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Weapon,
        [anim.BONE_GROUP.LeftArm]  = anim.PRIORITY.Weapon,
        [anim.BONE_GROUP.Torso]    = anim.PRIORITY.Weapon,
    }
    if fullBody then
        prio[anim.BONE_GROUP.LowerBody] = anim.PRIORITY.Weapon
    end
    interfaces.AnimationController.playBlendedAnimation(name, {
        startKey    = 'start',
        stopKey     = 'stop',
        loops       = loops,
        priority    = prio,
        autoDisable = true,
        blendMask   = fullBody and anim.BLEND_MASK.All or anim.BLEND_MASK.UpperBody,
        speed       = 1,
        forceLoop   = (loops == math.maxinteger),
    })
end

local function stopAnim(name)
    if not playingAnim[name] then return end
    playingAnim[name] = false
    anim.cancel(self, name)
end

local function stopAllAnims()
    stopAnim(ANIM_WALLPRESS)
    stopAnim(ANIM_VAULT)
    stopAnim(ANIM_VAULT_LOW)
end

local function getForwardDir()
    local yaw = self.object.rotation:getYaw()
    return util.vector3(math.sin(yaw), math.cos(yaw), 0):normalize()
end

local function getRightDir()
    local f = getForwardDir()
    return util.vector3(f.y, -f.x, 0):normalize()
end

local function getCameraForwardDir()
    local yaw = camera.getYaw()
    return util.vector3(math.sin(yaw), math.cos(yaw), 0):normalize()
end

local function getCameraRightDir()
    local f = getCameraForwardDir()
    return util.vector3(f.y, -f.x, 0):normalize()
end

local function isInFOV(targetPos, base, dotThreshold)
    local dx = targetPos.x - base.x
    local dy = targetPos.y - base.y
    local len = math.sqrt(dx*dx + dy*dy)
    if len < 0.001 then return true end
    local toTarget = util.vector3(dx/len, dy/len, 0)
    local fwd      = getCameraForwardDir()
    return (fwd.x*toTarget.x + fwd.y*toTarget.y) >= (dotThreshold or VAULT_FOV_DOT)
end

local function isStair(base, dir, loHit, loObj)
    local offX = dir.x * RAY_NEAR_OFFSET
    local offY = dir.y * RAY_NEAR_OFFSET
    local perpX = -dir.y
    local perpY =  dir.x

    local origins = {
        util.vector3(base.x + offX,                          base.y + offY,                          base.z + STAIR_CLEAR_HEIGHT),
        util.vector3(base.x + offX + perpX * RAY_SPREAD,     base.y + offY + perpY * RAY_SPREAD,     base.z + STAIR_CLEAR_HEIGHT),
        util.vector3(base.x + offX - perpX * RAY_SPREAD,     base.y + offY - perpY * RAY_SPREAD,     base.z + STAIR_CLEAR_HEIGHT),
    }

    for _, orig in ipairs(origins) do
        local r = nearby.castRay(orig, orig + dir * RAY_DISTANCE, { collisionType = COLL })
        if not r.hit then
            return true
        end
    end

    return false
end

local function analyzeObstacle(base, dir)
    local perpX = -dir.y
    local perpY =  dir.x

    local offX = dir.x * RAY_NEAR_OFFSET
    local offY = dir.y * RAY_NEAR_OFFSET

    local function castFan(height)
        local oX = base.x + offX
        local oY = base.y + offY
        local oZ = base.z + height

        local best     = nil
        local bestDist = math.huge
        local bestObj  = nil

        local origins = {
            util.vector3(oX,                        oY,                        oZ),
            util.vector3(oX + perpX*RAY_SPREAD,     oY + perpY*RAY_SPREAD,     oZ),
            util.vector3(oX - perpX*RAY_SPREAD,     oY - perpY*RAY_SPREAD,     oZ),
            util.vector3(oX + perpX*RAY_SPREAD*2,   oY + perpY*RAY_SPREAD*2,   oZ),
            util.vector3(oX - perpX*RAY_SPREAD*2,   oY - perpY*RAY_SPREAD*2,   oZ),
        }

        for _, orig in ipairs(origins) do
            local r = nearby.castRay(orig, orig + dir * RAY_DISTANCE,
                                     { collisionType = COLL })
            if r.hit then
                local d = (r.hitPos.x - base.x)^2 + (r.hitPos.y - base.y)^2
                if d < bestDist then
                    best     = r.hitPos
                    bestDist = d
                    bestObj  = r.hitObject
                end
            end
        end
        return best, bestObj
    end

    local loHit, loObj = castFan(RAY_HEIGHT_LOW)
    if not loHit then
        loHit, loObj = castFan(RAY_HEIGHT_VLOW)
    end
    if not loHit then return "none", nil, nil, nil, false end

    if isStair(base, dir, loHit, loObj) then
        return "stair", nil, nil, nil, true
    end

    local function sampleSurfaceZ(px, py)
        local r = nearby.castRay(
            util.vector3(px, py, base.z + LEDGE_SCAN_ABOVE),
            util.vector3(px, py, base.z - 50),
            { collisionType = COLL }
        )
        return r.hit and r.hitPos.z or nil
    end

    local function measureSlope(hitX, hitY)
        local nearZ = sampleSurfaceZ(hitX, hitY)
        local farZ  = sampleSurfaceZ(
            hitX + dir.x * SLOPE_STEP_DIST,
            hitY + dir.y * SLOPE_STEP_DIST
        )
        if nearZ and farZ then
            return farZ - nearZ
        end
        return nil
    end

    local hiHit, _ = castFan(RAY_HEIGHT_HIGH)
    if not hiHit then
        local fx       = loHit.x + dir.x * RAY_NEAR_OFFSET
        local fy       = loHit.y + dir.y * RAY_NEAR_OFFSET
        local scanFrom = util.vector3(fx, fy, base.z + LEDGE_SCAN_ABOVE)
        local scanTo   = util.vector3(fx, fy, base.z)
        local scanR    = nearby.castRay(scanFrom, scanTo, { collisionType = COLL })
        if scanR.hit then
            local relH = scanR.hitPos.z - base.z
            if relH < VAULT_SMALL_MAX then
                return "vault_low", scanR.hitPos.z, loHit, loObj, false
            end
            local slope = measureSlope(loHit.x, loHit.y)
            if slope and slope >= SLOPE_STEEP_MIN then
                return "vault", scanR.hitPos.z, loHit, loObj, false
            end
            return "vault_low", scanR.hitPos.z, loHit, loObj, false
        end
        return "vault_low", nil, loHit, loObj, false
    end

    local bestLedgeZ  = nil
    local bestWallPos = loHit

    local probeDepths = { 0, PROBE_DEPTH * 0.5, PROBE_DEPTH,
                          PROBE_DEPTH * 1.5, PROBE_DEPTH * 2.5 }
    local anchors = { loHit, hiHit }

    for _, anchor in ipairs(anchors) do
        for _, depth in ipairs(probeDepths) do
            local fx = anchor.x + dir.x * depth
            local fy = anchor.y + dir.y * depth
            local scanFrom = util.vector3(fx, fy, base.z + LEDGE_SCAN_ABOVE)
            local scanTo   = util.vector3(fx, fy, base.z)
            local r = nearby.castRay(scanFrom, scanTo, { collisionType = COLL })
            if r.hit then
                if not bestLedgeZ or r.hitPos.z > bestLedgeZ then
                    bestLedgeZ  = r.hitPos.z
                    bestWallPos = anchor
                end
            end
        end
    end

    if not bestLedgeZ then return "block", nil, loHit, nil, false end

    local relH = bestLedgeZ - base.z

    if relH < LEDGE_MIN_HEIGHT then
        if relH < VAULT_SMALL_MAX then
            return "vault_low", bestLedgeZ, bestWallPos, loObj, false
        end
        local slope = measureSlope(bestWallPos.x, bestWallPos.y)
        if slope and slope >= SLOPE_STEEP_MIN then
            return "vault", bestLedgeZ, bestWallPos, loObj, false
        end
        return "vault_low", bestLedgeZ, bestWallPos, loObj, false
    end

    if relH > LEDGE_MAX_HEIGHT then return "block", bestLedgeZ, bestWallPos, nil, false end
    local slopeHi = measureSlope(bestWallPos.x, bestWallPos.y)
    if slopeHi and slopeHi < SLOPE_STEEP_MIN then
        return "vault_low", bestLedgeZ, bestWallPos, loObj, false
    end
    return "vault", bestLedgeZ, bestWallPos, loObj, false
end

local function safePos(pos)
    local scanFrom = util.vector3(pos.x, pos.y, pos.z + SAFETY_ABOVE)
    local scanTo   = util.vector3(pos.x, pos.y, pos.z - 15)
    local r = nearby.castRay(scanFrom, scanTo, { collisionType = COLL })
    if r.hit then
        if r.hitPos.z > pos.z + 3 then
            return util.vector3(pos.x, pos.y, r.hitPos.z + SAFETY_LIFT)
        end
        return pos
    end
    return util.vector3(pos.x, pos.y, pos.z + SAFETY_LIFT)
end

local NEAR_EDGE_MARGIN = 16
local NEAR_EDGE_STEPS  = 6

local function nearEdgePos(base, dir, centerX, centerY, topZ)
    local scanZ     = topZ + 4
    local nearX     = base.x + dir.x * RAY_NEAR_OFFSET
    local nearY     = base.y + dir.y * RAY_NEAR_OFFSET

    for i = 1, NEAR_EDGE_STEPS do
        local t  = i / NEAR_EDGE_STEPS
        local px = nearX   + (centerX - nearX)   * t
        local py = nearY   + (centerY - nearY)   * t
        local r  = nearby.castRay(
            util.vector3(px, py, scanZ + 50),
            util.vector3(px, py, topZ  - 20),
            { collisionType = COLL }
        )
        if r.hit then
            return util.vector3(
                r.hitPos.x - dir.x * NEAR_EDGE_MARGIN,
                r.hitPos.y - dir.y * NEAR_EDGE_MARGIN,
                r.hitPos.z
            )
        end
    end

    return util.vector3(centerX, centerY, topZ)
end

local LAND_GUARD_CHEST    = 70
local LAND_GUARD_PULLBACK = 12

local function clampLandingPos(base, landPos)
    local fromX = base.x
    local fromY = base.y
    local fromZ = base.z + LAND_GUARD_CHEST

    local toX   = landPos.x
    local toY   = landPos.y
    local toZ   = landPos.z + LAND_GUARD_CHEST

    local r = nearby.castRay(
        util.vector3(fromX, fromY, fromZ),
        util.vector3(toX,   toY,   toZ),
        { collisionType = COLL }
    )

    if not r.hit then
        return landPos
    end

    local dx  = fromX - r.hitPos.x
    local dy  = fromY - r.hitPos.y
    local len = math.sqrt(dx*dx + dy*dy)
    local nx, ny
    if len > 0.001 then
        nx = r.hitPos.x + (dx/len) * LAND_GUARD_PULLBACK
        ny = r.hitPos.y + (dy/len) * LAND_GUARD_PULLBACK
    else
        nx = r.hitPos.x
        ny = r.hitPos.y
    end

    local snapFrom = util.vector3(nx, ny, r.hitPos.z + SAFETY_ABOVE)
    local snapTo   = util.vector3(nx, ny, base.z - 50)
    local snapR    = nearby.castRay(snapFrom, snapTo, { collisionType = COLL })
    if snapR.hit then
        return util.vector3(nx, ny, snapR.hitPos.z + SAFETY_LIFT)
    end

    return util.vector3(nx, ny, landPos.z)
end

local function findObjectTopCenter(wallHit, dir, baseZ)
    local perpX = -dir.y
    local perpY =  dir.x

    local topZ   = nil
    local probeX = nil
    local probeY = nil

    local offsets = { 0, PROBE_DEPTH * 0.5, PROBE_DEPTH,
                      PROBE_DEPTH * 1.5, PROBE_DEPTH * 3 }

    for _, offset in ipairs(offsets) do
        local px = wallHit.x + dir.x * offset
        local py = wallHit.y + dir.y * offset
        local scanFrom = util.vector3(px, py, baseZ + CHAIN_SCAN_ABOVE)
        local scanTo   = util.vector3(px, py, wallHit.z - 50)
        local r = nearby.castRay(scanFrom, scanTo, { collisionType = COLL })
        if r.hit then
            topZ   = r.hitPos.z
            probeX = px
            probeY = py
            break
        end
    end

    if not topZ then return nil end

    local scanZ = topZ + 2

    local function findEdgePair(ax, ay, searchHalf)
        local lR = nearby.castRay(
            util.vector3(ax + perpX * searchHalf, ay + perpY * searchHalf, scanZ),
            util.vector3(ax - perpX * searchHalf, ay - perpY * searchHalf, scanZ),
            { collisionType = COLL }
        )
        local rR = nearby.castRay(
            util.vector3(ax - perpX * searchHalf, ay - perpY * searchHalf, scanZ),
            util.vector3(ax + perpX * searchHalf, ay + perpY * searchHalf, scanZ),
            { collisionType = COLL }
        )
        return lR, rR
    end

    local lR, rR = findEdgePair(probeX, probeY, 40)
    if not lR.hit and not rR.hit then
        lR, rR = findEdgePair(probeX, probeY, EDGE_SEARCH_HALF)
    end

    local centerX, centerY
    if lR.hit and rR.hit then
        centerX = (lR.hitPos.x + rR.hitPos.x) * 0.5
        centerY = (lR.hitPos.y + rR.hitPos.y) * 0.5
    elseif lR.hit then
        centerX = (lR.hitPos.x + probeX) * 0.5
        centerY = (lR.hitPos.y + probeY) * 0.5
    elseif rR.hit then
        centerX = (rR.hitPos.x + probeX) * 0.5
        centerY = (rR.hitPos.y + probeY) * 0.5
    else
        centerX = probeX
        centerY = probeY
    end

    local function findDepthPair(ax, ay, searchHalf)
        local nR = nearby.castRay(
            util.vector3(ax + dir.x * searchHalf, ay + dir.y * searchHalf, scanZ),
            util.vector3(ax - dir.x * searchHalf, ay - dir.y * searchHalf, scanZ),
            { collisionType = COLL }
        )
        local fR = nearby.castRay(
            util.vector3(ax - dir.x * searchHalf, ay - dir.y * searchHalf, scanZ),
            util.vector3(ax + dir.x * searchHalf, ay + dir.y * searchHalf, scanZ),
            { collisionType = COLL }
        )
        return nR, fR
    end

    local nR, fR = findDepthPair(centerX, centerY, 40)
    if not nR.hit and not fR.hit then
        nR, fR = findDepthPair(centerX, centerY, EDGE_SEARCH_HALF)
    end

    if nR.hit and fR.hit then
        centerX = (nR.hitPos.x + fR.hitPos.x) * 0.5
        centerY = (nR.hitPos.y + fR.hitPos.y) * 0.5
    elseif nR.hit then
        centerX = (nR.hitPos.x + centerX) * 0.5
        centerY = (nR.hitPos.y + centerY) * 0.5
    elseif fR.hit then
        centerX = (fR.hitPos.x + centerX) * 0.5
        centerY = (fR.hitPos.y + centerY) * 0.5
    end

    local recheck = nearby.castRay(
        util.vector3(centerX, centerY, baseZ + CHAIN_SCAN_ABOVE),
        util.vector3(centerX, centerY, topZ   - 10),
        { collisionType = COLL }
    )
    if recheck.hit then
        topZ = recheck.hitPos.z
    end

    local bestTopZ  = topZ
    local bestCX    = centerX
    local bestCY    = centerY

    for i = 0, TOP_SEARCH_STEPS - 1 do
        local angle = (2 * math.pi * i) / TOP_SEARCH_STEPS
        local sx    = centerX + math.cos(angle) * TOP_SEARCH_RADIUS
        local sy    = centerY + math.sin(angle) * TOP_SEARCH_RADIUS
        local sr    = nearby.castRay(
            util.vector3(sx, sy, baseZ + CHAIN_SCAN_ABOVE),
            util.vector3(sx, sy, topZ  - 50),
            { collisionType = COLL }
        )
        if sr.hit and sr.hitPos.z > bestTopZ then
            bestTopZ = sr.hitPos.z
            bestCX   = sx
            bestCY   = sy
        end
    end

    if bestCX ~= centerX or bestCY ~= centerY then
        local apex = nearby.castRay(
            util.vector3(bestCX, bestCY, baseZ + CHAIN_SCAN_ABOVE),
            util.vector3(bestCX, bestCY, bestTopZ - 10),
            { collisionType = COLL }
        )
        if apex.hit then
            topZ    = apex.hitPos.z
            centerX = bestCX
            centerY = bestCY
        else
            topZ = bestTopZ
        end
    end

    return { topZ = topZ, centerX = centerX, centerY = centerY }
end

local function resetAll(controls)
    state        = "idle"
    vaultTimer   = 0
    vaultP0      = nil
    vaultP1      = nil
    vaultP2      = nil
    vaultIsSmall = false

    landedTopZ   = nil
    landedCenter = nil
    landedTimer  = 0

    smoothedVaultPos = nil

    controls.jump         = false
    controls.movement     = 0
    controls.sideMovement = 0
    unlockInput()
    wasBlocked.forward  = false
    wasBlocked.backward = false
    wasBlocked.left     = false
    wasBlocked.right    = false
    stopAllAnims()
end

local WALL_BEHIND_DIST   = 55
local WALL_BEHIND_SPREAD = 14

local function hasWallBehind(cx, cy, topZ, dir)
    local checkZ = topZ + 20
    local perpX  = -dir.y
    local perpY  =  dir.x
    local spreads = { 0, WALL_BEHIND_SPREAD, -WALL_BEHIND_SPREAD }
    for _, sp in ipairs(spreads) do
        local ox = perpX * sp
        local oy = perpY * sp
        local r = nearby.castRay(
            util.vector3(cx + ox,                             cy + oy,                             checkZ),
            util.vector3(cx + ox + dir.x * WALL_BEHIND_DIST, cy + oy + dir.y * WALL_BEHIND_DIST, checkZ),
            { collisionType = COLL }
        )
        if r.hit then
            return true
        end
    end
    return false
end

local function spendFatigue(cost)
    local f = types.Actor.stats.dynamic.fatigue(self)
    if f.current < cost then return false end
    f.current = f.current - cost
    return true
end

local function beginVault(dir, ledgeZ, wallPos, hitObj, controls, isLow)
    local base = self.object.position

    if not spendFatigue(FATIGUE_VAULT_COST) then return false, false end

    if not isInFOV(wallPos, base, VAULT_FOV_DOT) then
        return false, true
    end

    local relH = ledgeZ and (ledgeZ - base.z) or 0

    if ledgeZ and relH >= VAULT_MAX_HEIGHT then return false, false end

    if (not ledgeZ) or (relH < VAULT_SMALL_MAX) then
        local estH = ledgeZ and relH or (RAY_HEIGHT_LOW + RAY_HEIGHT_HIGH) * 0.5

        if estH < VAULT_MIN_HEIGHT then return false, true end

        local topZ = ledgeZ or (base.z + estH)

        local landX = wallPos.x + dir.x * VAULT_LAND_DIST
        local landY = wallPos.y + dir.y * VAULT_LAND_DIST
        local landZ = base.z

        local groundFrom = util.vector3(landX, landY, topZ + 50)
        local groundTo   = util.vector3(landX, landY, base.z - 200)
        local groundR    = nearby.castRay(groundFrom, groundTo, { collisionType = COLL })
        if groundR.hit then
            landZ = groundR.hitPos.z
        end

        if landZ - base.z > VAULT_LAND_WALL_Z then
            return false, false
        end

        local obstCX = wallPos.x + dir.x * (VAULT_LAND_DIST * 0.3)
        local obstCY = wallPos.y + dir.y * (VAULT_LAND_DIST * 0.3)
        if hasWallBehind(obstCX, obstCY, topZ, dir) then
            local onTopZ  = topZ + LAND_Z_OFFSET
            local lipPos  = nearEdgePos(base, dir, obstCX, obstCY, topZ)
            local landPos = clampLandingPos(base, safePos(util.vector3(lipPos.x, lipPos.y, onTopZ)))
            vaultP0 = util.vector3(base.x, base.y, base.z)
            vaultP1 = util.vector3(
                (base.x + landPos.x) * 0.5,
                (base.y + landPos.y) * 0.5,
                onTopZ + VAULT_ARC_HEIGHT
            )
            vaultP2      = landPos
            landedTopZ   = topZ
            landedCenter = { x = landPos.x, y = landPos.y }
            vaultIsSmall = false
        else
            vaultP0 = util.vector3(base.x, base.y, base.z)
            vaultP1 = util.vector3(
                (base.x + landX) * 0.5,
                (base.y + landY) * 0.5,
                topZ + VAULT_ARC_HEIGHT
            )
            vaultP2      = clampLandingPos(base, safePos(util.vector3(landX, landY, landZ)))
            vaultIsSmall = true
        end
    else
        local info = findObjectTopCenter(wallPos, dir, base.z)

        local topZ, p2x, p2y

        if info then
            topZ = info.topZ
            p2x  = info.centerX
            p2y  = info.centerY
        else
            topZ = ledgeZ
            p2x  = wallPos.x + dir.x * 40
            p2y  = wallPos.y + dir.y * 40
        end

        local objHeight = topZ - base.z
        if objHeight < VAULT_MIN_HEIGHT then return false, true end

        local safeTopZ = topZ + LAND_Z_OFFSET

        if hasWallBehind(p2x, p2y, topZ, dir) then
            local lipPos  = nearEdgePos(base, dir, p2x, p2y, topZ)
            local landPos = clampLandingPos(base, safePos(util.vector3(lipPos.x, lipPos.y, safeTopZ)))
            vaultP0 = util.vector3(base.x, base.y, base.z)
            vaultP1 = util.vector3(
                (base.x + landPos.x) * 0.5,
                (base.y + landPos.y) * 0.5,
                safeTopZ + VAULT_ARC_HEIGHT
            )
            vaultP2      = landPos
            landedTopZ   = topZ
            landedCenter = { x = landPos.x, y = landPos.y }
            vaultIsSmall = false
        else
            local lipPos  = nearEdgePos(base, dir, p2x, p2y, topZ)
            local landPos = clampLandingPos(base, safePos(util.vector3(lipPos.x, lipPos.y, safeTopZ)))
            vaultP0 = util.vector3(base.x, base.y, base.z)
            vaultP1 = util.vector3(
                (base.x + landPos.x) * 0.5,
                (base.y + landPos.y) * 0.5,
                safeTopZ + VAULT_ARC_HEIGHT
            )
            vaultP2 = landPos

            landedTopZ   = topZ
            landedCenter = { x = landPos.x, y = landPos.y }
            vaultIsSmall = false
        end
    end

    state      = "vault"
    vaultTimer = VAULT_DURATION

    lockInput()
    controls.movement     = 0
    controls.sideMovement = 0
    controls.jump         = false

    smoothedVaultPos = nil
    stopAllAnims()

    if isLow then
        playAnim(ANIM_VAULT_LOW, 1, true)
    else
        playAnim(ANIM_VAULT, 1, true)
    end
    return true, false
end

local function tryLookAndJump(freshJump, controls)
    if not freshJump then return false end

    local base = self.object.position
    local dir  = getCameraForwardDir()

    if not isInFOV(
            util.vector3(base.x + dir.x, base.y + dir.y, base.z),
            base, LOOK_JUMP_FOV_DOT) then
        return false
    end

    local perpX = -dir.y
    local perpY =  dir.x
    local oZ    = base.z + LOOK_JUMP_SCAN_HEIGHT
    local spreads = { 0, RAY_SPREAD, -RAY_SPREAD, RAY_SPREAD * 2, -RAY_SPREAD * 2 }
    local anyHit  = false
    for _, sp in ipairs(spreads) do
        local ox = base.x + perpX * sp
        local oy = base.y + perpY * sp
        local r  = nearby.castRay(
            util.vector3(ox, oy, oZ),
            util.vector3(ox + dir.x * LOOK_JUMP_SCAN_DIST,
                         oy + dir.y * LOOK_JUMP_SCAN_DIST, oZ),
            { collisionType = COLL }
        )
        if r.hit then anyHit = true break end
    end
    if not anyHit then return false end

    local obsType, ledgeZ, wallPos, hitObj = analyzeObstacle(base, dir)

    if obsType == "none" or obsType == "stair" or obsType == "block" then
        return false
    end

    if obsType == "vault_low" then
        local ok = beginVault(dir, ledgeZ, wallPos, hitObj, controls, true)
        return ok
    end

    if obsType == "vault" then
        local ok = beginVault(dir, ledgeZ, wallPos, hitObj, controls, false)
        return ok
    end

    return false
end

local function onFrame(dt)
    local controls    = self.controls
    local parkourMode = input.getBooleanActionValue('enparkour')

    local jumpNowGlobal = input.isActionPressed(input.ACTION.Jump)
    local freshJump     = jumpNowGlobal and not jumpWasPrev
    jumpWasPrev         = jumpNowGlobal

    setHUD(parkourMode)

    if state == "vault" then
        if not parkourMode then
            resetAll(controls)
            return
        end

        inputLocked = true
        input.setControlSwitch(input.CONTROL_SWITCH.Controls, false)
        input.setControlSwitch(input.CONTROL_SWITCH.Jumping,  false)

        controls.movement     = 0
        controls.sideMovement = 0
        controls.jump         = false

        vaultTimer = vaultTimer - dt

        if vaultTimer > 0 and vaultP0 then
            local t  = 1.0 - (vaultTimer / VAULT_DURATION)
            t  = math.max(0.0, math.min(1.0, t))
            local ts = t * t * (3.0 - 2.0 * t)
            local u  = 1.0 - ts

            local pos = util.vector3(
                u*u*vaultP0.x + 2*u*ts*vaultP1.x + ts*ts*vaultP2.x,
                u*u*vaultP0.y + 2*u*ts*vaultP1.y + ts*ts*vaultP2.y,
                u*u*vaultP0.z + 2*u*ts*vaultP1.z + ts*ts*vaultP2.z
            )

            if smoothedVaultPos == nil then
                smoothedVaultPos = pos
            else
                local lk = 1.0 - math.exp(-VAULT_SMOOTH * dt)
                smoothedVaultPos = util.vector3(
                    smoothedVaultPos.x + (pos.x - smoothedVaultPos.x) * lk,
                    smoothedVaultPos.y + (pos.y - smoothedVaultPos.y) * lk,
                    smoothedVaultPos.z + (pos.z - smoothedVaultPos.z) * lk
                )
            end

            core.sendGlobalEvent('ParkourLedgeGrab', { pos = smoothedVaultPos })
        else
            if vaultP2 then
                local finalPos = safePos(util.vector3(vaultP2.x, vaultP2.y, vaultP2.z))
                core.sendGlobalEvent('ParkourLedgeGrab', { pos = finalPos })
            end

            vaultP0 = nil
            vaultP1 = nil
            vaultP2 = nil
            stopAnim(ANIM_VAULT)
            stopAnim(ANIM_VAULT_LOW)
            unlockInput()
            controls.movement     = 0
            controls.sideMovement = 0
            controls.jump         = false

            if vaultIsSmall then
                vaultIsSmall = false
                state = "idle"
            else
                state = "landed"
            end
        end
        return
    end

    if state == "landed" then
        if not parkourMode then
            unlockInput()
            state        = "idle"
            landedTopZ   = nil
            landedCenter = nil
            return
        end

        lockInput()
        controls.movement     = 0
        controls.sideMovement = 0
        controls.jump         = false

        local jumpDir
        local fwdVal  = (input.isActionPressed(input.ACTION.MoveForward)  and 1 or 0)
                      - (input.isActionPressed(input.ACTION.MoveBackward) and 1 or 0)
        local sideVal = (input.isActionPressed(input.ACTION.MoveRight)    and 1 or 0)
                      - (input.isActionPressed(input.ACTION.MoveLeft)     and 1 or 0)

        local fwd   = getCameraForwardDir()
        local right = getCameraRightDir()

        if fwdVal ~= 0 or sideVal ~= 0 then
            jumpDir = (fwd * fwdVal + right * sideVal):normalize()
        elseif freshJump then
            jumpDir = fwd
        else
            return
        end

        if not landedTopZ or not landedCenter then
            state = "idle"
            unlockInput()
            return
        end

        local perpJX = -jumpDir.y
        local perpJY =  jumpDir.x
        local scanZ  = landedTopZ + 20
        local startX = landedCenter.x + jumpDir.x * 20
        local startY = landedCenter.y + jumpDir.y * 20
        local endX   = landedCenter.x + jumpDir.x * CHAIN_RAY_DIST
        local endY   = landedCenter.y + jumpDir.y * CHAIN_RAY_DIST
        local chainSpreads = { 0, RAY_SPREAD, -RAY_SPREAD, RAY_SPREAD*2, -RAY_SPREAD*2 }

        local r = nil
        for _, sp in ipairs(chainSpreads) do
            local ox = perpJX * sp
            local oy = perpJY * sp
            local candidate = nearby.castRay(
                util.vector3(startX + ox, startY + oy, scanZ),
                util.vector3(endX   + ox, endY   + oy, scanZ),
                { collisionType = COLL }
            )
            if candidate.hit then
                if r == nil then
                    r = candidate
                else
                    local d1 = (candidate.hitPos.x - startX)^2 + (candidate.hitPos.y - startY)^2
                    local d2 = (r.hitPos.x         - startX)^2 + (r.hitPos.y         - startY)^2
                    if d1 < d2 then r = candidate end
                end
            end
        end

        local NO_CHAIN_TIMEOUT = 0.5
        local function noChainTarget()
            if fwdVal == 0 and sideVal == 0 then return end
            landedTimer = landedTimer + dt
            if landedTimer >= NO_CHAIN_TIMEOUT then
                resetAll(controls)
            end
        end

        if not r then noChainTarget() return end

        local base = self.object.position
        if not isInFOV(r.hitPos, base, CHAIN_FOV_DOT) then noChainTarget() return end

        local info = findObjectTopCenter(r.hitPos, jumpDir, landedTopZ)
        if not info then noChainTarget() return end
        if math.abs(info.topZ - landedTopZ) > CHAIN_HEIGHT_DIFF_MAX then noChainTarget() return end

        landedTimer = 0

        if not spendFatigue(FATIGUE_VAULT_COST) then
            resetAll(controls)
            return
        end

        local nextSafeTopZ = info.topZ + LAND_Z_OFFSET
        local curPos       = self.object.position

        local lipPos  = nearEdgePos(curPos, jumpDir, info.centerX, info.centerY, info.topZ)
        local landPos = clampLandingPos(curPos, safePos(util.vector3(lipPos.x, lipPos.y, nextSafeTopZ)))

        vaultP0 = util.vector3(curPos.x, curPos.y, curPos.z)
        vaultP2 = landPos
        vaultP1 = util.vector3(
            (curPos.x + landPos.x) * 0.5,
            (curPos.y + landPos.y) * 0.5,
            math.max(landedTopZ, info.topZ) + VAULT_ARC_HEIGHT
        )

        landedTopZ   = info.topZ
        landedCenter = { x = landPos.x, y = landPos.y }

        state        = "vault"
        vaultTimer   = VAULT_DURATION
        vaultIsSmall = false

        smoothedVaultPos = nil
        stopAllAnims()

        playAnim(ANIM_VAULT, 1, true)
        return
    end

    if not parkourMode and state ~= "idle" then
        resetAll(controls)
        return
    end

    if parkourMode and state == "idle"
       and types.Actor.isOnGround(self.object)
       and not types.Actor.isSwimming(self.object)
    then
        if tryLookAndJump(freshJump, controls) then return end
    end

    if controls.movement == 0 and controls.sideMovement == 0 then
        wasBlocked.forward  = false
        wasBlocked.backward = false
        wasBlocked.left     = false
        wasBlocked.right    = false
        stopAnim(ANIM_WALLPRESS)
        return
    end

    local base    = self.object.position
    local forward = getCameraForwardDir()
    local right   = getCameraRightDir()

    local inAir = not types.Actor.isOnGround(self.object)
                  and not types.Actor.isSwimming(self.object)

    local function handleDir(dir, axisName, posKey)
        local obsType, ledgeZ, wallPos, hitObj, isStairFlag = analyzeObstacle(base, dir)

        if obsType == "none" or obsType == "stair" then
            wasBlocked[posKey] = false
            return false
        end

        if parkourMode then
            if (obsType == "vault" or obsType == "vault_low") and state == "idle" then
                local isLow = (obsType == "vault_low")
                local ok, tooSmall = beginVault(dir, ledgeZ, wallPos, hitObj, controls, isLow)
                if ok then
                    return true
                end
                if tooSmall then
                    wasBlocked[posKey] = false
                    return false
                end
            end
        end

        if obsType == "vault_low" then
            wasBlocked[posKey] = false
            return false
        end

        if obsType == "block"
            or (obsType == "vault" and parkourMode)
            or not parkourMode
        then
            if axisName == "movement" then
                controls.movement = 0
            else
                controls.sideMovement = 0
            end
            wasBlocked[posKey] = true
        end
        return false
    end

    local grabbed = false
    if not grabbed and controls.movement     >  0 then grabbed = handleDir(forward,      "movement",     "forward")  end
    if not grabbed and controls.movement     <  0 then grabbed = handleDir(forward * -1, "movement",     "backward") end
    if not grabbed and controls.sideMovement >  0 then grabbed = handleDir(right,        "sideMovement", "right")    end
    if not grabbed and controls.sideMovement <  0 then grabbed = handleDir(right * -1,   "sideMovement", "left")     end

    if not grabbed and controls.movement ~= 0 and controls.sideMovement ~= 0 then
        local diag = (forward * controls.movement + right * controls.sideMovement):normalize()
        local t, lz, wp, hObj, diagStair = analyzeObstacle(base, diag)

        if t == "none" or t == "stair" or t == "vault_low" then

        elseif t == "vault" and parkourMode and state == "idle" then
            local ok, tooSmall = beginVault(diag, lz, wp, hObj, controls, false)
            if ok then
                grabbed = true
            elseif not tooSmall then
                controls.movement     = 0
                controls.sideMovement = 0
                wasBlocked.forward    = true
            end
        elseif t ~= "none" and (t == "block" or not parkourMode) then
            controls.movement     = 0
            controls.sideMovement = 0
            wasBlocked.forward    = true
        end
    end

    if not grabbed and parkourMode and state == "idle"
       and (controls.movement ~= 0 or controls.sideMovement ~= 0)
    then
        local camFwd   = getCameraForwardDir()
        local alreadyCovered = false

        local function dot2d(a, b) return a.x*b.x + a.y*b.y end
        local SAME_DIR_DOT = 0.92
        if controls.movement     >  0 and dot2d(camFwd, forward)      >= SAME_DIR_DOT then alreadyCovered = true end
        if controls.movement     <  0 and dot2d(camFwd, forward * -1) >= SAME_DIR_DOT then alreadyCovered = true end
        if controls.sideMovement >  0 and dot2d(camFwd, right)        >= SAME_DIR_DOT then alreadyCovered = true end
        if controls.sideMovement <  0 and dot2d(camFwd, right * -1)   >= SAME_DIR_DOT then alreadyCovered = true end
        if controls.movement ~= 0 and controls.sideMovement ~= 0 then
            local diag = (forward * controls.movement + right * controls.sideMovement):normalize()
            if dot2d(camFwd, diag) >= SAME_DIR_DOT then alreadyCovered = true end
        end

        if not alreadyCovered then
            local obsType, ledgeZ, wallPos, hitObj = analyzeObstacle(base, camFwd)
            if obsType == "vault_low" then
                local ok, _ = beginVault(camFwd, ledgeZ, wallPos, hitObj, controls, true)
                if ok then grabbed = true end
            elseif obsType == "vault" then
                local ok, _ = beginVault(camFwd, ledgeZ, wallPos, hitObj, controls, false)
                if ok then grabbed = true end
            end
        end
    end

    if not parkourMode then
        local blocked = wasBlocked.forward or wasBlocked.backward
                     or wasBlocked.left    or wasBlocked.right
        if blocked then playAnim(ANIM_WALLPRESS, math.maxinteger, false)
        else            stopAnim(ANIM_WALLPRESS) end
    else
        stopAnim(ANIM_WALLPRESS)
        wasBlocked.forward  = false
        wasBlocked.backward = false
        wasBlocked.left     = false
        wasBlocked.right    = false
    end
end

return {
    engineHandlers = { onFrame = onFrame },
}