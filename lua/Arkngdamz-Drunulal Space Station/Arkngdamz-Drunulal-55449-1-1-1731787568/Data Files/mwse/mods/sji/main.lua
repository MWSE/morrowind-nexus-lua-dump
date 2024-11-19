--[[
SJI 
--]]

local function setSkyBox()
    local worldRoot = tes3.game.worldLandscapeRoot
    local skyBox = tes3.loadMesh("sji\\space.nif"):clone()
    skyBox.name = "sjiSkyBox"
    skyBox.scale = 10
    skyBox.zBufferProperty = niZBufferProperty.new()
    skyBox.zBufferProperty:setFlag(false, 0)
    skyBox.zBufferProperty:setFlag(false, 1)
    worldRoot:attachChild(skyBox, true)
end

local function simulateCallback(e)
    if tes3.game.worldRoot:getObjectByName("sjiSkyBox") then
        local skyBox = tes3.game.worldLandscapeRoot:getObjectByName("sjiSkyBox")
        skyBox.translation.x = tes3.mobilePlayer.position.x
        skyBox.translation.y = tes3.mobilePlayer.position.y
        skyBox.translation.z = ( tes3.mobilePlayer.position.z + 50 )
        -- rotation
        skyBox:update()
        skyBox:updateProperties()
    end
end
event.register(tes3.event.simulate, simulateCallback)

local function cellActivatedCallback(e)
    if e.cell.sourceMod ~= "Arkngdamz-Drunulal Space Station.ESP" then
        if tes3.game.worldRoot:getObjectByName("sjiSkyBox") then
            tes3.game.worldRoot:getObjectByName("sjiSkyBox").parent:detachChild(tes3.game.worldRoot:getObjectByName("sjiSkyBox"))
        end
        return
    end
    if tes3.game.worldRoot:getObjectByName("sjiSkyBox") == nil then
        setSkyBox()
    end

    if tes3.game.worldLandscapeRoot.appCulled == true then
        tes3.game.worldLandscapeRoot.appCulled = false
    end
end
event.register(tes3.event.cellActivated, cellActivatedCallback)


local function loadedCallback(e)
end
event.register(tes3.event.loaded, loadedCallback)