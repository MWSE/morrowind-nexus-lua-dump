local vr = require('openmw.vr')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local vfs = require('openmw.vfs')
local self_obj = require('openmw.self') 
local vrspaces = require('openmw.interfaces').vrspaces

local SWING_THRESHOLD = 4.0 
local lastPos = nil
local lastTimestamp = nil
local COOLDOWN = 0.25 
local lastImpactTime = 0

local paths = { sounds = "Sound/Fx/impact/" }
local FIL_CACHE = {}

local matSound = {
    Unknown = "Dirt", Dirt = "Dirt", Metal = "Metal", Stone = "Stone",
    Glass = "Ice", Ice = "Ice", Carpet = "Dirt", Snow = "Dirt",
    Wood = "Wood", Water = "Water", Ceramic = "Ice", Fabric = "Dirt",
    Paper = "Dirt", Organic = "Dirt", MetalHeavy = "Metal", Dmg = "Dmg",
    DmgDwemer = "DmgDwemer", DmgFire = "Dirt", DmgFrost = "Ice",
    DmgGhost = "DmgGhost", DmgSkeleton = "DmgSkeleton", Hit = "Dmg",
    HitFire = "Dirt", HitFrost = "Ice", HitGhost = "DmgGhost",
    HitSkeleton = "Wood", Parry = "Parry", ParryArmorHeavy = "Parry",
    ParryArmorBone = "Wood", ParryArmorIce = "Parry", ParryArmorMedium = "Wood"
}

local function pickSound(d)
    local f = FIL_CACHE[d]
    if not f then
        f = {}
        for file in vfs.pathsWithPrefix(paths.sounds .. d) do
            if file:lower():find("wav$") then table.insert(f, file) end
        end
        FIL_CACHE[d] = f
    end
    if #f > 0 then return f[math.random(#f)] end
    return nil
end

return {
    engineHandlers = {
        onVRFrame = function()
            if not vr.isVr() then return end

            local stance = self_obj.type.getStance(self_obj)
            if stance ~= 1 then return end

            local pose = vrspaces.locateSpace(vrspaces.actionSpaces.RightHandGrip, vrspaces.referenceSpaces.Local)
            if not pose then return end

            local now = core.getRealTime()
            if not lastTimestamp then
                lastTimestamp = now
                lastPos = pose.position
                return
            end

            local dt = now - lastTimestamp
            if dt <= 0 then return end
            local velocity = (pose.position - lastPos):length() / vrspaces.unitsPerMeter / dt

            if velocity > SWING_THRESHOLD and (now - lastImpactTime) > COOLDOWN then
                local worldPose = vrspaces.locateSpaceInWorld(vrspaces.actionSpaces.RightHandGrip)
                if worldPose then
                    local rayStart = worldPose.position
                    local rayDir = worldPose.orientation * util.vector3(0, 1, 0) 
                    local rayEnd = rayStart + (rayDir * 85) 
                    local result = nearby.castRay(rayStart, rayEnd, {ignore = self_obj})
                    
                    local hitPos = result.hitPos or rayEnd
                    local waterline = self_obj.cell.waterLevel
                    local isWaterHit = false
                    
                    if waterline then
                        if (result.hitPos and result.hitPos.z < waterline) or 
                           (rayStart.z > waterline and rayEnd.z < waterline) or
                           (rayStart.z < waterline and rayEnd.z > waterline) then
                            isWaterHit = true
                        end
                    end

                    if result.hit or isWaterHit then
                        print("VR_hit")
                        core.sendGlobalEvent('VR_ImpactRequest', {
                            hitPos = result.hitPos,
                            direction = rayDir,
                            culprit = self_obj
                        })

                        lastImpactTime = now 
                        
                        local material = "Unknown"
                        local finalHitPos = result.hitPos or hitPos

                        if isWaterHit then
                            material = "Water"
                            finalHitPos = util.vector3(hitPos.x, hitPos.y, waterline)
                        elseif I.impactEffects and result.hitObject then
                            material = I.impactEffects.getMaterialByObject(result.hitObject)
                        end

                        -- visual effect
                        if I.impactEffects then
                            I.impactEffects.spawnEffect({
                                material = material,
                                hitPos = finalHitPos
                            })
                        end

                        -- sound
                        local folderName = matSound[material] or "Dirt"
                        local soundFile = pickSound(folderName)
                        if soundFile then
                            core.sound.playSoundFile3d(soundFile, self_obj, {
                                volume = (material == "Water") and 0.6 or 0.8,
                                pitch = math.random(90, 110) / 100
                            })
                        end

                        -- Haptique
                        if vrspaces.setHapticFeedback then
                            vrspaces.setHapticFeedback(vrspaces.actionSpaces.RightHandGrip, 0.5, 0.05)
                        end
                    end
                end
            end
            lastPos = pose.position
            lastTimestamp = now
        end
    }
}