--[[
SJI 
--]]

local function setSkyBox()
    tes3.game.worldLandscapeRoot.appCulled = false
    if tes3.game.worldRoot:getObjectByName("sjiSkyBox") == nil then
        local worldRoot = tes3.game.worldLandscapeRoot
        local skyBox = tes3.loadMesh("sji\\space.nif"):clone()
        skyBox.name = "sjiSkyBox"
        skyBox.scale = 10
        skyBox.zBufferProperty = niZBufferProperty.new()
        skyBox.zBufferProperty:setFlag(false, 0)
        skyBox.zBufferProperty:setFlag(false, 1)
        worldRoot:attachChild(skyBox, true)
    end
end

local function simulateCallback(e)
    if tes3.game.worldRoot:getObjectByName("sjiSkyBox") then
        local sjiSkyBox = tes3.game.worldRoot:getObjectByName("sjiSkyBox")
        sjiSkyBox.translation.x = tes3.mobilePlayer.position.x
        sjiSkyBox.translation.y = tes3.mobilePlayer.position.y
        sjiSkyBox.translation.z = ( tes3.mobilePlayer.position.z + 50 )
        sjiSkyBox:update()
        sjiSkyBox:updateProperties()
    end
end
event.register(tes3.event.simulate, simulateCallback)

local function cellChangedCallback(e)
    if string.startswith(e.cell.id, "Arkngdamz-Drunulal") then
        setSkyBox()
    else
        if tes3.game.worldRoot:getObjectByName("sjiSkyBox") then
            tes3.game.worldRoot:getObjectByName("sjiSkyBox").parent:detachChild(tes3.game.worldRoot:getObjectByName("sjiSkyBox"))
        end
    end
end
event.register(tes3.event.cellChanged, cellChangedCallback)