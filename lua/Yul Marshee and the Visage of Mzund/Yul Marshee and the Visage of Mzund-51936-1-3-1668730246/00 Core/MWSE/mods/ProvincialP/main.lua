local mcm = require("ProvincialP.mcm")
local ID33 = tes3matrix33.new(1, 0, 0, 0, 1, 0, 0, 0, 1)
local land = {}
mcm.init()
local function PlayerKey(keybind)
    return tes3.worldController.inputController:isKeyDown(tes3.worldController.inputController.inputMaps[keybind + 1].code)
end

local function KeyPress(keycode)
    return tes3.worldController.inputController:isKeyReleasedThisFrame(keycode)
end

local function Drag(x)
    if math.abs(tes3.mobilePlayer.velocity.z) < 2 then
        tes3.mobilePlayer.velocity.z = 0
    else
        tes3.mobilePlayer.velocity.z = tes3.mobilePlayer.velocity.z - tes3.mobilePlayer.velocity.z * x
    end
end

function land.rotationDifference(vec1, vec2)
    vec1 = vec1:normalized()
    vec2 = vec2:normalized()

    local axis = vec1:cross(vec2)
    local norm = axis:length()
    if norm < 1e-5 then
        return ID33:toEulerXYZ()
    end

    local angle = math.asin(norm)
    if vec1:dot(vec2) < 0 then
        angle = math.pi - angle
    end

    axis:normalize()

    local m = ID33:copy()
    m:toRotation(-angle, axis.x, axis.y, axis.z)
    return m:toEulerXYZ()
end


function land.getGroundBelow(e)
    local ref = tes3.mobilePlayer
    local result = tes3.rayTest {
        position = {ref.position.x, ref.position.y, ref.position.z},
        direction = {0, 0, -1},
        returnNormal = true,
        useBackTriangles = false,
        root = e.terrainOnly and tes3.game.worldLandscapeRoot or nil
    }
    if result ~= nil then
        return result
    else
        return 0
    end
end


function land.positionRef(ref, rayResult, offsetx, offsety, offsetz)
    local bb = ref.object.boundingBox
    local newZ = rayResult.intersection.z - bb.min.z
    local position = tes3vector3.new(ref.position.x + offsetx, ref.position.y + offsety, newZ + offsetz)
    return position
end

function land.orientRef(ref, rayResult, offset)
    local UP = tes3vector3.new(0, 0, 1)
    local maxSteepness = 20
    local newOrientation = land.rotationDifference(UP, rayResult.normal)
    newOrientation.x = math.clamp(newOrientation.x, (0 - maxSteepness), maxSteepness)
    newOrientation.y = math.clamp(newOrientation.y, (0 - maxSteepness), maxSteepness)
    newOrientation.z = tes3.player.orientation.z + offset

    return newOrientation
end

local IsActi
local HorSpeed
local OriOffset
local OriRef
local Shipcell
local Shipori
local Shippos
local PP_Time


local function Button2PressedCallback(e)
    if (e.button == 0) then
        local ref = tes3.mobilePlayer
        local result = land.getGroundBelow(e)
        if result then
            IsActi = 0
            local orient = land.orientRef(ref, result, 135)
            local pos1 = land.positionRef(ref, result, 0, 0, 405)
            tes3.createReference({ object = "PP_Airship_Stage_03", position = pos1, orientation = orient, cell = tes3.player.cell, scale = 1 })
            tes3.createReference({ object = "PP_Airship_Door_MWSE", position = pos1, orientation = orient, cell = tes3.player.cell, scale = 1 })
            tes3.setPlayerControlState({enabled = true, attack = true, jumping = true, magic = true, vanity = true, viewSwitch = true})
            local null = tes3vector3.new(0, 0, 0)
            tes3.set3rdPersonCameraOffset({offset = OriOffset}) --Orioffset calculated in activate callback

            tes3.mobilePlayer.isFlying = false
            tes3.player.scale = 1
            tes3.togglePOV()
            local pos3 = land.positionRef(ref, result, 250, 0, 20)
            tes3.mobilePlayer.position = pos3
            tes3.mobilePlayer.velocity = null
            for _, child in ipairs(tes3.player.sceneNode.children) do
                if child.name ~= "PP_Airship_Flying.nif" then
                    child.appCulled = false
                else
                    tes3.player.sceneNode:detachChild(child)
                end
            end
        end
    elseif ( e.button == 1 ) then
        tes3.messageBox("no")
    end
end

local function Transition()
    if (IsActi == 1) then
        Shippos = tes3.mobilePlayer.position
        Shipcell = tes3.mobilePlayer.cell
        Shipori = tes3.player.orientation
        print(Shipcell)
        print(Shipori)
        print(Shippos)
        HorSpeed = 0
        local pos4 = tes3vector3.new(3610, 4126, 15053)
        local orient = tes3vector3.new(0,0,270)
        local cell = tes3.getCell({id = "Serican Rain"})
        tes3.positionCell({reference = tes3.player,cell = cell, position = pos4, orientation = orient})
        tes3.setPlayerControlState({enabled = true, attack = true, jumping = true, magic = true, vanity = true, viewSwitch = true})
        local null = tes3vector3.new(0, 0, 0)
        tes3.set3rdPersonCameraOffset({offset = OriOffset}) --Orioffset calculated in activate callback
        tes3.mobilePlayer.isFlying = false
        tes3.player.scale = 1
        tes3.togglePOV()
        tes3.mobilePlayer.velocity = null
        for _, child in ipairs(tes3.player.sceneNode.children) do
            if child then
                if child.name ~= "PP_Airship_Flying.nif" then
                    child.appCulled = false
                else
                    tes3.player.sceneNode:detachChild(child)
                end
            end
        end
        IsActi = 2


    end
end

local function fixme()
    HorSpeed = 0
    tes3.mobilePlayer.position.z = tes3.mobilePlayer.position.z + 2500
end

local function simul(t)
    local airdoorref = tes3.getReference("PP_Airship_Door_MWSE")
    local airshipref = tes3.getReference("PP_Airship_Stage_03")
    local oldshipref = tes3.getReference("PP_Airship_Stage_01")
    local olddoorref = tes3.getReference("PP_Airship_Door")
    if ( tes3.getJournalIndex({id = "PP_q06"}) < 200 ) then
        if ( tes3.player.cell.id == "Pelagiad, Yul Marshee's House" ) then
            return
        end
        if (airdoorref) then
            airdoorref:disable()
        end
        if (airshipref) then
            airshipref:disable()
        end
    elseif ( airdoorref ) then
        if (airdoorref.disabled) then
            airdoorref:enable()
            airshipref:enable()
            if (oldshipref) then
                oldshipref:disable()
                olddoorref:disable()
            end
        end
    end
    --if KeyPress(28) then --enter key
        --Transition()
    --end
    if IsActi == nil then
        return
    end
    if IsActi ~= 1 then
        HorSpeed = 0
        return
    end
    for _, child in ipairs(tes3.player.sceneNode.children) do
        if child then
            if child.name ~= "PP_Airship_Flying.nif" then
                child.appCulled = true
            end
        end
    end
    local IsShiftPressed = tes3.worldController.inputController:isShiftDown()
    local waterLevel = tes3.player.cell.isInterior == false and 0 or (tes3.player.cell.hasWater and tes3.player.cell.waterLevel or nil)
    local MaxSpeed = 500
    local HorAcc = 300
    local facing = tes3.mobilePlayer.facing
    local sin = math.sin(facing)
    local cos = math.cos(facing)
    if KeyPress(45) then
        if IsShiftPressed then
            fixme()
        end
    end
    if KeyPress(16) then --q key
        local zpos = land.getGroundBelow(t).distance
        local groundorient = land.getGroundBelow(t).normal
        local ishighslope = math.abs(groundorient.x) > 0.3 or math.abs(groundorient.y) > 0.3
        if (zpos < 175) and not ishighslope then
            tes3.messageBox( {
                message = "Do you want to exit?",
                buttons = {"Yes", "No"},
                callback = function(e)
                    timer.delayOneFrame(function() Button2PressedCallback(e)
                    end)
                end})
        elseif ishighslope then
            tes3.messageBox("The slope is too steep to land.") 
        else
            tes3.messageBox("You are too high to land.")
        end
        --move the player out only if safe
    end
    if HorSpeed == nil then
        HorSpeed = 0
    end
    
    PP_Time = tes3.worldController.deltaTime
    local offsetvec = tes3vector3.new(0, -750, 150)
    if tes3.get3rdPersonCameraOffset ~= offsetvec then
        tes3.set3rdPersonCameraOffset({offset = offsetvec})
    end

    tes3.mobilePlayer.velocity.x = HorSpeed * sin
    tes3.mobilePlayer.velocity.y = HorSpeed * cos

    if PlayerKey(tes3.keybind.forward) then
        if IsShiftPressed then
            tes3.mobilePlayer.velocity.z = tes3.mobilePlayer.velocity.z + 3
        else
            if HorSpeed <= MaxSpeed then
            HorSpeed = HorSpeed + HorAcc * PP_Time
            end
        end
    end
    if PlayerKey(tes3.keybind.back) then
        if IsShiftPressed then
           if (tes3.mobilePlayer.position.z > waterLevel ) then
            tes3.mobilePlayer.velocity.z = tes3.mobilePlayer.velocity.z - 3
           end
        else
            if HorSpeed > 0 then
                HorSpeed = math.max(0, HorSpeed - HorAcc * 2 * PP_Time)
            end
        end
    end
    Drag(0.025)
end

local function loadedCallback()
    for _, child in ipairs(tes3.player.sceneNode.children) do
        IsActi = 0
        if child.name ~= "PP_Airship_Flying.nif" then
            return
        end
        IsActi = 1
        tes3.setPlayerControlState()

        local mesh = tes3.loadMesh("PP\\PP_Airship_Flying.nif")
        tes3.player.sceneNode:attachChild(mesh:clone())
        local offsetvec = tes3vector3.new(0, -750, -100)
        tes3.set3rdPersonCameraOffset({offset = offsetvec})
        tes3.mobilePlayer.isFlying= true
        tes3.player.scale = 5
        tes3.mobilePlayer.position.z = tes3.mobilePlayer.position.z + 200
    end
    if (IsActi == 0) then
        tes3.setPlayerControlState{ enabled = true, attack = true, jumping = true, magic = true, vanity = true, viewSwitch = true }
    end
end

function Button1PressedCallback(e)
    if e.button == 0 then
        OriOffset = tes3.get3rdPersonCameraOffset()
        local airdoorref = tes3.getReference("PP_Airship_Door_MWSE")
        if (airdoorref) then
            airdoorref:delete()
        end
        local airshipref = tes3.getReference("PP_Airship_Stage_03")
        if (airshipref) then
            airshipref:delete()
        end
        IsActi = 1
        if tes3.mobilePlayer.is3rdPerson == false then
            tes3.togglePOV()
        end
        tes3.setPlayerControlState()
        local null = tes3vector3.new(0, 0, 0)

        local mesh = tes3.loadMesh("PP\\PP_Airship_Flying.nif")
        tes3.player.sceneNode:attachChild(mesh:clone())
        local offsetvec = tes3vector3.new(0, -750, -100)
        tes3.set3rdPersonCameraOffset({offset = offsetvec})
        tes3.mobilePlayer.isFlying= true
        tes3.mobilePlayer.velocity = null
        tes3.player.scale = 5
        tes3.mobilePlayer.position.z = tes3.mobilePlayer.position.z + 200
    elseif e.button == 1 then
        --OriPos = tes3.mobilePlayer.position
        --OriOrient = tes3.player.orientation
        --OriCell = tes3.mobilePlayer.cell
        --print(OriCell)
        local pos = tes3vector3.new(3610, 4126, 15053)
        local orient = tes3vector3.new(0,0,270)
        local cell = tes3.getCell({id = "Serican Rain"})
        tes3.positionCell({cell = cell, position = pos, orientation = orient})
    end
end

local function activatecallback(t)
    if tes3.getJournalIndex({id ="PP_q06"}) >= 200 then
        if (t.target.object.id == "PP_Airship_Door_MWSE") then
            OriRef = t.target
            tes3.messageBox( {
                message = "What do you want to do?",
                buttons = {"Travel", "Enter"},
                callback = function(e)
                    timer.delayOneFrame(function() Button1PressedCallback(e)
                    end)
                end})
                return false
        elseif (t.target.object.id == "PP_Airship_I_Door") then
            if ( IsActi == 2 ) then
                print(Shipcell.region)
                print(Shipori)
                print(Shippos)
                tes3.positionCell({reference = tes3.mobilePlayer, cell = Shipcell, position = Shippos:copy(), orientation = Shipori:copy()})
                if tes3.mobilePlayer.is3rdPerson == false then
                    tes3.togglePOV()
                end
                tes3.setPlayerControlState()
                local null = tes3vector3.new(0, 0, 0)
                local mesh = tes3.loadMesh("PP\\PP_Airship_Flying.nif")
                tes3.player.sceneNode:attachChild(mesh:clone())
                local offsetvec = tes3vector3.new(0, -750, -100)
                tes3.set3rdPersonCameraOffset({offset = offsetvec})
                tes3.mobilePlayer.isFlying= true
                tes3.mobilePlayer.velocity = null
                tes3.player.scale = 5
                IsActi = 1
                return
            end
            if (OriRef) then
                local facing = OriRef.facing
                local sin = math.sin(facing)
                local cos = math.cos(facing)
                local pos2 = tes3vector3.new(OriRef.position.x + 200 * cos, OriRef.position.y + 200 * sin, OriRef.position.z - 450)
                tes3.positionCell({
                    reference = tes3.player,
                    position = pos2,
                    orientation = OriRef.orientation,
                    cell = OriRef.cell
                })
                return
            else
                print("No Ref")
            end
        end
    end
end


local function init()
    event.register("simulate", simul)
    event.register("activate", activatecallback)
    event.register("loaded", loadedCallback)
end


event.register(tes3.event.initialized, init)