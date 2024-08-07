local tMeshNamesToReplace = {}
local sContainerType
local containerRef
local openLockSound
local pickUpSound
local openLockFailSound
local sKeyUsedGMST
local tOpenSounds = {}
local tCloseSounds = {}
local tUpdatedCells = {}
local tContainerTypes = {}
local iActivationDist
local iActivationDistGMST
local openTimer
local closeTimer
-- local tCompatibleScripts = {}
local tNotSafeCtypes = {} -- items placed on them clip into them when animation plays
local playerRef
local tCellsChecked
local tObjectTypesToCheck = {}
local tMovableItemsOnCont = {}
local tStaticItemsOnCont = {}
local tBigStaticsOnCont = {}
local tDontCheck = {}
-- local tOverriddenScripts = {}
-- local tLocalScriptsToRun = {}
local tContHeightToCheck = {} -- Container Height % To Check when detecting items on top of it
local v3up = tes3vector3.new(0,0,1)
local v3down = tes3vector3.new(0,0,-1)
local itemsConfig = {['SkipAnim'] = 0, ['Hide'] = 1, ['TransferToPlayer'] = 2, ['TransferToCont'] = 3}
local config = mwse.loadConfig('MWCA_config') or {stayOpen = true, activateMode = true, animateWhileRunning = true, playSound = true, items = 0, animTimeToWait = 100, barrelRivet = true, version = 2.06}
local iContainerType = tes3.objectType.container
local idistToCheck = 222 -- distance used when looking for items placed on chests
-- local autoUnlock = false
local graphicHerbalism = include("graphicHerbalism.interop")
local modConfig = require("MWCA.configMenu")
modConfig.config = config

local function GetCellName(cell)

    local sCellName = cell.id
    if not cell.isInterior then
        sCellName = sCellName..' '..cell.gridX..' '..cell.gridY
    end
    return sCellName
end


local function GetContainerType(ref)

    local dir, name = ref.object.mesh:match("(.-)([^\\]+)$")
    name = name:lower()
    name = name:gsub(".nif", "")
    return tContainerTypes[name]
end


local function IsRefPickUpable(ref)
    -- check tObjectTypesToCheck[ref.object.objectType] before this
    local iType = ref.object.objectType
    if iType == tes3.objectType.static or iType == tes3.objectType.activator or iType == iContainerType then
        return false
    end

    if iType == tes3.objectType.light then
        return ref.object.canCarry
    end

    return true
end


local function BigStatic(cRef, ref)

    if ref.object.boundingBox.max.x - ref.object.boundingBox.min.x >=cRef.object.boundingBox.max.x - cRef.object.boundingBox.min.x or ref.object.boundingBox.max.y - ref.object.boundingBox.min.y >= cRef.object.boundingBox.max.y - cRef.object.boundingBox.min.y then
        return true
    end

    return false
end


local function IsRefOnChest(cRef, ref)
    -- mwse.log('IsRefOnChest %s %s', cRef.object.id, ref.object.id)
    -- local dist = cRef.object.boundingBox.max.z - cRef.object.boundingBox.min.z - ref.object.boundingBox.min.z
    local fContHeight = cRef.object.boundingBox.max.z - cRef.object.boundingBox.min.z
    local dist = -ref.object.boundingBox.min.z + fContHeight * tContHeightToCheck[GetContainerType(cRef)]

    local result = tes3.rayTest{position = ref.position, direction = v3down, maxDistance = dist, findAll = true, useModelBounds = false, useBackTriangles = true, ignore = {ref}}

    if result then
        for i, hit in pairs(result) do
            if hit.reference then
                -- mwse.log('ray test down hit #%d %s', i, hit.reference.id)
                if hit.reference.id == cRef.object.id then
                    -- mwse.log('%s is on top %s', ref.object.id, cRef.object.id)
                    return true
                elseif BigStatic(cRef, hit.reference) then
                    -- mwse.log('%s Big Static on %s', hit.reference.id, cRef.object.id)
                    return false
                end
            end
        end
    end

    return false
end


local function GetBoundingBoxVertexPositions(position, orientation, boundingBoxMin,boundingBoxMax)

    -- need function to get bounding box position
    -- using hack for now

    local bBoxMinX = boundingBoxMin.x
    local bBoxMinY = boundingBoxMin.y
    local bBoxMaxX = boundingBoxMax.x
    local bBoxMaxY = boundingBoxMax.y

    if orientation.z ~= 0 then
        bBoxMinX = math.min(boundingBoxMin.y, boundingBoxMin.x)
        bBoxMinY = math.min(boundingBoxMin.y, boundingBoxMin.x)
        bBoxMaxX = math.max(boundingBoxMax.y, boundingBoxMax.x)
        bBoxMaxY = math.max(boundingBoxMax.y, boundingBoxMax.x)
    end

    local posX = position.x
    local posY = position.y

    local x = posX + bBoxMinX
    local y = posY + bBoxMinY
    local z = position.z + boundingBoxMin.z
    local pos0 = tes3vector3.new(x,y,z)
    x = posX + bBoxMaxX
    local pos1 = tes3vector3.new(x,y,z)
    x = posX + bBoxMinX
    y = posY + bBoxMaxY
    local pos2 = tes3vector3.new(x,y,z)
    y = posY + bBoxMinY
    z = position.z + boundingBoxMax.z
    local pos3 = tes3vector3.new(x,y,z)
    x = posX + bBoxMaxX
    y = posY + bBoxMaxY
    local pos4 = tes3vector3.new(x,y,z)
    x = posX + bBoxMinX
    local pos5 = tes3vector3.new(x,y,z)
    x = posX + bBoxMaxX
    y = posY + bBoxMinY
    local pos6 = tes3vector3.new(x,y,z)
    y = posY + bBoxMaxY
    z = position.z + boundingBoxMin.z
    local pos7 = tes3vector3.new(x,y,z)

    return {pos0, pos1, pos2, pos3, pos4, pos5, pos6, pos7}
end


local function IsAnotherRefInside(refWithBBox, refToFind, doubleMaxZ)

    local tBBvertexPos = GetBoundingBoxVertexPositions(refWithBBox.position:copy(), refWithBBox.orientation:copy(), refWithBBox.object.boundingBox.min:copy(), refWithBBox.object.boundingBox.max:copy())

    local xMin = math.min(tBBvertexPos[1].x, tBBvertexPos[2].x, tBBvertexPos[3].x, tBBvertexPos[4].x, tBBvertexPos[5].x, tBBvertexPos[6].x, tBBvertexPos[7].x, tBBvertexPos[8].x)
    local xMax = math.max(tBBvertexPos[1].x, tBBvertexPos[2].x, tBBvertexPos[3].x, tBBvertexPos[4].x, tBBvertexPos[5].x, tBBvertexPos[6].x, tBBvertexPos[7].x, tBBvertexPos[8].x)
    local yMin = math.min(tBBvertexPos[1].y, tBBvertexPos[2].y, tBBvertexPos[3].y, tBBvertexPos[4].y, tBBvertexPos[5].y, tBBvertexPos[6].y, tBBvertexPos[7].y, tBBvertexPos[8].y)
    local yMax = math.max(tBBvertexPos[1].y, tBBvertexPos[2].y, tBBvertexPos[3].y, tBBvertexPos[4].y, tBBvertexPos[5].y, tBBvertexPos[6].y, tBBvertexPos[7].y, tBBvertexPos[8].y)
    local zMin = math.min(tBBvertexPos[1].z, tBBvertexPos[2].z, tBBvertexPos[3].z, tBBvertexPos[4].z, tBBvertexPos[5].z, tBBvertexPos[6].z, tBBvertexPos[7].z, tBBvertexPos[8].z)
    local zMax = math.max(tBBvertexPos[1].z, tBBvertexPos[2].z, tBBvertexPos[3].z, tBBvertexPos[4].z, tBBvertexPos[5].z, tBBvertexPos[6].z, tBBvertexPos[7].z, tBBvertexPos[8].z)

    if doubleMaxZ then -- detect items placed on chests
        zMax = zMax + zMax - zMin
    end

    local x = refToFind.position.x
    local y = refToFind.position.y
    local z = refToFind.position.z
    -- detect tall objects on small chests
    if refToFind.object.boundingBox then
        z = refToFind.position.z + refToFind.object.boundingBox.min.z
    end

    if x > xMin and x < xMax then
        if y > yMin and y < yMax then
            if z > zMin and z < zMax then
                return true
            end
        end
    end

    return false
end


local function IsBigStaticAbove(cRef)

    -- mwse.log('IsBigStaticAbove %s', cRef.object.id)
    local fContHeight = cRef.object.boundingBox.max.z - cRef.object.boundingBox.min.z
    local dist = cRef.object.boundingBox.max.z + fContHeight * tContHeightToCheck[GetContainerType(cRef)]

    local result = tes3.rayTest{position = cRef.position, direction = v3up, maxDistance = dist, findAll = true, useModelBounds = false, useBackTriangles = true, ignore = {cRef} }
    -- local eggPos = tes3vector3.new(cRef.position.x,cRef.position.y,cRef.position.z+dist)
    -- local egg = tes3.createReference {object = 'food_kwama_egg_01', position = eggPos, orientation = tes3vector3.new(0,0,0), cell = cRef.cell }
    -- egg.scale = 0.2

    if result then
        for i, hit in pairs(result) do
            if hit.reference and BigStatic(cRef, hit.reference) then
                -- mwse.log('%s Big Static Above %s', hit.reference.object.id, cRef.object.id)
                return true
            end
        end
    end

    return false
end


local function SortItems(cRef)
    local tRefsToRemove = {}

    -- shelf's position can be anywhere so check if it's above
    -- if not cRef.data.AC_skipAnim then
        -- for ref, _ in pairs(tBigStaticsOnCont[cRef]) do
            -- if RayTestUp(cRef, ref) then
                -- cRef.data.AC_skipAnim = true
                -- cRef.modified = true
                -- break
            -- end
        -- end
    -- end

    for ref, _ in pairs(tStaticItemsOnCont[cRef]) do
        if not IsRefOnChest(cRef, ref) then
            table.insert(tRefsToRemove, ref)
        end
    end

    for ref, _ in pairs(tMovableItemsOnCont[cRef]) do
        if not IsRefOnChest(cRef, ref) then
            table.insert(tRefsToRemove, ref)
        end
    end

    for _, ref in pairs(tRefsToRemove) do
        if tMovableItemsOnCont[cRef][ref] then
            tMovableItemsOnCont[cRef][ref] = nil
        elseif tStaticItemsOnCont[cRef][ref] then
            tStaticItemsOnCont[cRef][ref] = nil
        end
    end

    local iTableLength = table.size(tStaticItemsOnCont[cRef])
    if iTableLength > 0 then
        cRef.data.AC_staticItems = true
        cRef.modified = true
    elseif iTableLength == 0 then
        cRef.modified = true
        cRef.data.AC_staticItems = nil
    end

    iTableLength = table.size(tMovableItemsOnCont[cRef])
    if iTableLength > 0 then
        cRef.modified = true
        cRef.data.AC_movableItems = true
    elseif iTableLength == 0 then
        cRef.modified = true
        cRef.data.AC_movableItems = nil
    end

    -- if tStaticItemsOnCont[cRef] then
        -- for ref, _ in pairs(tStaticItemsOnCont[cRef]) do
            -- mwse.log('Static Item On Cont %s %s', cRef.object.id, ref.object.id)
        -- end
    -- end
    -- if tMovableItemsOnCont[cRef] then
        -- for ref, _ in pairs(tMovableItemsOnCont[cRef]) do
            -- mwse.log('Movable Item On Cont %s %s', cRef.object.id, ref.object.id)
        -- end
    -- end
end


local function GetItems(cell, cRef)

    -- mwse.log('GetItems %s', cRef.object.id)
    tStaticItemsOnCont[cRef] = {}
    tMovableItemsOnCont[cRef] = {}
    tBigStaticsOnCont[cRef] = {}

    if not cRef.data.AC_skipAnim and IsBigStaticAbove(cRef) then
        cRef.data.AC_skipAnim = true
        cRef.modified = true
        return
    end

    for iType, _ in pairs(tObjectTypesToCheck) do
        for ref in cell:iterateReferences(iType) do
            if ref ~= cRef and not ref.deleted and ref.object.script == nil and not tDontCheck[ref.object.id] then
                if not ref.disabled or (ref.disabled and ref.data.AC_disabled) then
                    -- mwse.log('pos %s %s', cRef.position, ref.position)
                    local fDistToContainer = cRef.position:distance(ref.position)
                    -- mwse.log('fDistToContainer %d', fDistToContainer)
                    if fDistToContainer < idistToCheck and IsAnotherRefInside(cRef, ref, true) then
                        if not IsRefPickUpable(ref) then
                            if BigStatic(cRef, ref) then
                                tBigStaticsOnCont[cRef][ref] = true
                            else
                                tStaticItemsOnCont[cRef][ref] = true
                            end
                        else -- PickUpable
                            tMovableItemsOnCont[cRef][ref] = true
                        end
                    end
                end
            end
        end
    end
    SortItems(cRef)
end


local function EnableItems(cRef)
    if cRef.data.AC_staticItems then
        if not tStaticItemsOnCont[cRef] then -- game reloaded
            GetItems(playerRef.cell, cRef)
        end
        for ref, _ in pairs(tStaticItemsOnCont[cRef]) do
            tes3.setEnabled {reference = ref, enabled = true}
            ref.modified = true
            ref.data.AC_disabled = nil
        end
    end
    if cRef.data.AC_movableItems then
        if not tMovableItemsOnCont[cRef] then
            GetItems(playerRef.cell, cRef)
        end
        for ref, _ in pairs(tMovableItemsOnCont[cRef]) do
            tes3.setEnabled {reference = ref, enabled = true}
            ref.data.AC_disabled = nil
            ref.modified = true
        end
    end
end


local function DisableItems(cRef)
    -- mwse.log('DisableItems %s', cRef.object.id)

    if cRef.data.AC_staticItems then
        for ref, _ in pairs(tStaticItemsOnCont[cRef]) do
            ref.data.AC_disabled = true
            ref.modified = true
            tes3.setEnabled {reference = ref, enabled = false}
        end
    end
    if cRef.data.AC_movableItems then
        for ref, _ in pairs(tMovableItemsOnCont[cRef]) do
            ref.data.AC_disabled = true
            ref.modified = true
            tes3.setEnabled {reference = ref, enabled = false}
        end
    end
end


local function CloseAnimationEnd()
    -- tes3.messageBox('Close Animation End  %s', containerRef.object.id)
    containerRef.data.AC_state = 'closed'
    containerRef.modified = true
    EnableItems(containerRef)
end


local function PlayCloseAnimation(cRef)
    cRef.data.AC_state = 'closing'
    cRef.modified = true
    tes3.playAnimation {reference = cRef, group = 2, startFlag = 1}
    local animDuration = 0.5

    if string.find(sContainerType, 'Dwemer') or string.find(sContainerType, 'daedric') or string.find(sContainerType, 'cauldron') then
        animDuration = animDuration + animDuration
    end

    local closeSound = tCloseSounds[sContainerType]
    if config.playSound and closeSound then
        tes3.playSound {sound = closeSound, reference = cRef}
    end

    closeTimer = timer.start{duration = animDuration, callback = CloseAnimationEnd }
end


local function OnMenuExit(eventData)

    if not config.stayOpen and containerRef.data.AC_state == 'open' then
        -- mwse.log("[MWCA] menu exit close")
        PlayCloseAnimation(containerRef)
    end
    event.unregister("menuExit", OnMenuExit)
end


local function OpenAnimationEnd()

    if openTimer then
        openTimer:cancel() -- timer is still active
    end
    -- mwse.log('OpenAnimationEnd openTimer state go %d', openTimer.state)
    containerRef.data.AC_state = 'openAnimDone'
    containerRef.modified = true
    -- event.register("menuEnter", OnMenuEnter)
    if config.activateMode then
        if not config.stayOpen then
            event.register("menuExit", OnMenuExit)
        end
        playerRef:activate(containerRef)
    end
end


local function OpenAnimEndGH()

    if openTimer then
        openTimer:cancel() -- timer is still active
    end
    -- mwse.log('OpenAnimationEnd openTimer state go %d', openTimer.state)
    containerRef.data.AC_state = 'openAnimDone'
    containerRef.modified = true
    local switchNode = containerRef.sceneNode:getObjectByName("HerbalismSwitch")
    if switchNode then
        switchNode.switchIndex = 1 -- HARVESTED
    end
    playerRef:activate(containerRef)
end


local function PlayOpenAnimation(cRef)
    -- tes3.messageBox('PlayOpenAnimation %s', cRef.object.id)
    cRef.data.AC_state = 'opening'
    cRef.modified = true
    tes3.playAnimation {reference = cRef, group = 1, startFlag = 1}
    -- timer.start{duration = 3, type = timer.simulate, callback = OpenAnimationEnd}
    local animDuration = 0.5

    if string.find(sContainerType, 'cauldron') or string.find(sContainerType, 'daedric') or string.find(sContainerType, 'Dwemer') then
        animDuration = 1.0
    end
    animDuration = animDuration * config.animTimeToWait / 100

    local openSound = tOpenSounds[sContainerType]
    if config.playSound and openSound then
        tes3.playSound{sound = openSound, reference = cRef}
    end

    if animDuration == 0 then
        OpenAnimationEnd()
    else
        openTimer = timer.start{duration = animDuration, callback = OpenAnimationEnd }
    end
end


local function PlayGHkollopOpenAnimation(cRef)
    -- tes3.messageBox('Play kollop Open Animation %s', cRef.object.id)
    cRef.data.AC_state = 'opening'
    cRef.modified = true

    local switchNode = cRef.sceneNode:getObjectByName("HerbalismSwitch")
    if switchNode then
        switchNode.switchIndex = 2 -- empty
    end
    tes3.playAnimation{reference = cRef, group = 1, startFlag = 1}

    local animDuration = 0.5 * config.animTimeToWait / 100

    if animDuration == 0 then
        OpenAnimEndGH()
    else
        openTimer = timer.start{duration = animDuration, callback = OpenAnimEndGH }
    end
end

local function HandleActivation(cRef, quick)
    if not cRef then
        return
    end

    if cRef.object.objectType ~= iContainerType then
        return
    end

    sContainerType = GetContainerType(cRef)

    if not sContainerType then
        return
    end

    -- mwse.log('OnActivateObject %s', sContainerType)

    if not cRef:testActionFlag(tes3.actionFlag.useEnabled) then
        -- local script has 'onactivate'
        return
    end

    if cRef.data.AC_state == nil then
        cRef.data.AC_state = 'closed'
        cRef.modified = true
    end
    local sState = cRef.data.AC_state

--[[
    if cRef.object.script ~= nil then
        local sScriptID = cRef.object.script.id
        -- mwse.log("container with script %s %s",cRef.object.id, cRef.object.script.id)
        if not tCompatibleScripts[sScriptID] then
            return
        end

        -- if tOverriddenScripts[sScriptID] and cRef.data.AC_state == 'closed' then
            -- if not tLocalScriptsToRun[sScriptID] then
                -- mwse.log('run local script %s', sScriptID)
                -- tLocalScriptsToRun[sScriptID] = true
            -- end
        -- end
    end
--]]
    -- mwse.log("OnActivateObject %s %s", cRef.object.id, sContainerType)
    local hasKey = false

    if cRef.lockNode and cRef.lockNode.level == 0 and cRef.lockNode.key then
        -- tes3.messageBox('lockNode.level == 0  key')
        cRef.lockNode.level = 1
        cRef.modified = true
    end

    if tes3.getLocked{reference = cRef} then

        -- if autoUnlock then
            -- tes3.unlock {reference = cRef}
        -- end
        if cRef.lockNode.key then
            if mwscript.getItemCount{reference = playerRef, item = cRef.lockNode.key.id} > 0 then
                local sKeyUsed = cRef.lockNode.key.name..' '..sKeyUsedGMST
                tes3.messageBox('%s', sKeyUsed)
                tes3.unlock {reference = cRef}
                cRef.modified = true
                -- cRef.lockNode.locked = false
                -- cRef.lockNode.level = 0
                tes3.playSound {sound = openLockSound, reference = cRef}
                hasKey = true
            end
        end

        if not hasKey then
            return
        end
    end

        -- another container is opening
    if openTimer and openTimer.state == 0 and containerRef ~= cRef then
        openTimer:cancel()
        containerRef.data.AC_state = 'open'
        containerRef.modified = true
        if not config.stayOpen then
            -- mwse.log("[MWCA] another container opening close")
            PlayCloseAnimation(containerRef)
        end
        -- tes3.messageBox('cancel timer')
    end
        -- another container is closing
    if closeTimer and closeTimer.state == 0 and containerRef ~= cRef then
        EnableItems(containerRef)
        closeTimer:cancel()
        containerRef.data.AC_state = 'closed'
        containerRef.modified = true
        -- tes3.messageBox('cancel timer')
    end

    containerRef = cRef
    -- local sState = cRef.data.AC_state or 'closed'
    -- if #ref.object.inventory == 0 then
    if graphicHerbalism and sContainerType == 'kollop' then
        -- tes3.messageBox('GH kollop AC_state %s', cRef.data.AC_state)
        local iGHstate = cRef.data.GH or 0

        if iGHstate == 1 then -- opened
            -- tes3.messageBox('activate opened kollop')
        elseif sState == 'closed' and iGHstate == 0 then
            PlayGHkollopOpenAnimation(cRef)
        elseif sState == 'openAnimDone' then
            -- tes3.messageBox('GH kollop openAnimDone AC_state %s', cRef.data.AC_state)
            cRef.data.AC_state = 'open'
            return -- activate
        end
    elseif sState == 'closed' then
        -- forceInstance(cRef)
        iActivationDist = math.max(cRef.position:distance(playerRef.position), iActivationDistGMST)

        local trapSpell = tes3.getTrap {reference = cRef}

        if trapSpell and not quick then

            tes3.playSound{sound = openLockFailSound, reference = cRef}
            -- tes3.setTrap {reference = cRef, spell = nil}
            cRef.lockNode.trap = nil -- remove trap
            -- tes3.messageBox('cast trap %s', trapSpell.id)
            -- cast trap spell without waiting for activation
            if not hasKey then
                local fDistToContainer = cRef.position:distance(playerRef.position)
                if tes3.mobilePlayer.telekinesis > 0 and iActivationDist > iActivationDistGMST then	-- opened with telekinesis
                elseif fDistToContainer <= iActivationDist then
                    tes3.cast{reference = cRef, target = playerRef, spell = trapSpell}
                end
            end
        end

        if tNotSafeCtypes[sContainerType] then

            GetItems(playerRef.cell, cRef)

            if config.items == itemsConfig.SkipAnim then
                if cRef.data.AC_movableItems or cRef.data.AC_staticItems then
                    return
                end
            elseif config.items == itemsConfig.TransferToPlayer then
                if not cRef.data.AC_skipAnim then
                    if cRef.data.AC_movableItems then
                        for ref, _ in pairs(tMovableItemsOnCont[cRef]) do
                            -- tes3.messageBox('TransferToPlayer %s', ref.object.id)
                            -- playerRef:activate(ref) -- book will open
                            tes3.addItem{reference = playerRef, item = ref.object, count = ref.stackSize, playSound = false, updateGUI = false}
                            tes3.setEnabled {reference = ref, enabled = false}
                            timer.frame.delayOneFrame(function() mwscript.setDelete{reference = ref, delete = true}; end)
                        end
                        tes3ui.forcePlayerInventoryUpdate()
                        tes3.playSound{sound = pickUpSound, reference = cRef}
                        -- tes3.playItemPickupSound {reference = cRef}
                        tMovableItemsOnCont[cRef] = {}
                        cRef.data.AC_movableItems = nil
                        cRef.modified = true
                    end
                    DisableItems(cRef)
                end
            end

            if cRef.data.AC_skipAnim then
                return
            elseif cRef.data.AC_staticItems then
                DisableItems(cRef)
            end

            if config.items == itemsConfig.Hide then
                DisableItems(cRef)
            end
        end

        PlayOpenAnimation(cRef)

    elseif sState == 'open' then
        if not config.stayOpen and config.activateMode then
            -- mwse.log("[MWCA] is open close")
            PlayCloseAnimation(cRef)
        end
    elseif sState == 'openAnimDone' or sState == 'opening' then

        if openTimer then
            openTimer:cancel()
        end
        cRef.data.AC_state = 'open'
        cRef.modified = true
        local fDistToContainer = cRef.position:distance(playerRef.position)

        if fDistToContainer <= iActivationDist then
            return  -- activate
        end
    end

    return false -- prevent activation
end

-- the old way still works
local function OnActivateObject(eventData)
    if not config.activateMode then
        return
    end

    HandleActivation(eventData.target)
end

-- ! this is where the QuickLoot mode happens ! --
local function OnActivationTargetChanged(eventData)
    if config.activateMode then return end

    -- gets kinda janky when rapidly looking at a container, looking away, then
    -- looking back, and running while looking at a container kinda does that, so:
    if tes3.mobilePlayer.isRunning and not config.animateWhileRunning then return end

    if not config.stayOpen and (containerRef and containerRef ~= eventData.current) then
        local oldCState = containerRef.data.AC_state or "closed"
        if not eventData.current then
        -- not looking at something, or pulling item out of container
            if tostring(tes3ui.getMenuOnTop()) == "QuickLoot:Menu" then
                -- are we not looking at something for real, or did we just pull something out of the container?
                timer.start({ -- delayOneFrame wasn't enough time for the QuickLoot Menu to disappear
                    type = timer.simulate,
                    duration = 0.1,
                    iterations = 1,
                    callback = function()
                        if tostring(tes3ui.getMenuOnTop()) ~= "QuickLoot:Menu" then
                            -- hey we really aren't looking at something
                            if oldCState ~= "closed" then
                                -- mwse.log("[MWCA] timer close")
                                PlayCloseAnimation(containerRef)
                            end
                        end
                    end
                })
            else
                -- definitely not looking at something
                if oldCState ~= "closed" then
                    -- mwse.log("[MWCA] definitely close")
                    PlayCloseAnimation(containerRef)
                end
            end
        else
            -- still looking at something, so close the other thing
            if oldCState ~= "closed" then
                -- mwse.log("[MWCA] other thing close")
                PlayCloseAnimation(containerRef)
            end
        end
    end

    HandleActivation(eventData.current, true)
end

local function UpdateContainers()
    -- local time_ = os.clock()

    local tCellsToCheck = {}

    for i, cell in ipairs(tes3.getActiveCells()) do
        local sCellName = GetCellName(cell)

        if tUpdatedCells[sCellName] == cell then
            -- mwse.log('Update Containers skip cell %s', sCellName)
        else
            tCellsToCheck[sCellName] = cell
        end
    end

    if config.items == itemsConfig.TransferToCont then
        tCellsToCheck[GetCellName(playerRef.cell)] = playerRef.cell
    end

    for cellName, cell in pairs(tCellsToCheck) do

        tUpdatedCells[cellName] = cell
        -- mwse.log('Update Containers %s', cellName)
        for cRef in cell:iterateReferences(iContainerType) do
            local sType = GetContainerType(cRef)

            if sType and not cRef.deleted and not cRef.disabled and cRef:testActionFlag(tes3.actionFlag.useEnabled) then
                -- if not cRef.object.script or (cRef.object.script and tCompatibleScripts[cRef.object.script.id]) then

                -- mwse.log('Update Container %s', cRef.object.id)

                if cRef.data.AC_state == 'open' or cRef.data.AC_state == 'opening' then
                    cRef.data.AC_state = 'open'
                    cRef.modified = true
                    tes3.playAnimation {reference = cRef, group = 3, startFlag = 1}
                end
                -- mwse.log('id %s', cRef.object.id)

                if cRef.data.AC_state == 'open' then
                    -- will not work for containers with leveled items, will work with GH
                    -- mwse.log('open %s', cRef.object.id)
                    if cRef.isRespawn and not cRef.isEmpty then
                        -- mwse.log('isRespawn %s %d', cRef.object.id,
                        cRef.data.AC_state = 'closed'
                        cRef.modified = true
                        tes3.playAnimation {reference = cRef, group = 2, startFlag = 1}
                    end
                end

                if config.items == itemsConfig.TransferToCont and not cRef.data.AC_skipAnim and tNotSafeCtypes[sType] then
                    GetItems(cell, cRef)
                    if cRef.data.AC_movableItems then
                        for ref, _ in pairs(tMovableItemsOnCont[cRef]) do
                            tes3.addItem{reference = cRef, item = ref.object, count = ref.stackSize, playSound = false, updateGUI = false}
                            tes3.setEnabled {reference = ref, enabled = false}
                            timer.frame.delayOneFrame (function() mwscript.setDelete{reference = ref, delete = true}; end)
                        end
                        tMovableItemsOnCont[cRef] = {}
                        cRef.data.AC_movableItems = nil
                        cRef.modified = true
                    end
                end
            end
        end
    end
    -- mwse.log("UpdateContainers elapsed time: %.4f\n", os.clock() - time_)
end


local function OnCellChanged(eventData)

    -- local sCellName = GetCellName(eventData.cell)
    -- mwse.log('\n OnCellChanged %s \n', sCellName)
    -- tes3.messageBox('OnCellChanged %s', sCellName)
    UpdateContainers()
end


local function OnLoaded()
    -- mwse.log('OnLoaded')
    -- playerRef = tes3.mobilePlayer.reference

    playerRef = tes3.player
    tStaticItemsOnCont = {}
    tMovableItemsOnCont = {}
    tBigStaticsOnCont = {}
    tUpdatedCells = {}
    UpdateContainers()
end


local function Setup()
--[[
    -- local tt = {}
    -- for obj in tes3.iterateObjects(iContainerType) do
        -- if not tt[obj.model] then
            -- mwse.log(' %s %s', obj.id, obj.model)
            -- tt[obj.model] = 2
        -- end
    -- end

    -- tCompatibleScripts['CharGenFatigueBarrel'] = true
    -- tCompatibleScripts['Colony_first_boat'] = true
    -- tCompatibleScripts['ColonyDock'] = true
    -- tCompatibleScripts['ColonyEquipBag'] = true
    -- tCompatibleScripts['Float'] = true
    -- tCompatibleScripts['floatAboveStartHeight'] = true
    -- tCompatibleScripts['jeannechestScript'] = true -- 'activate' in this script does not make sense
    -- tCompatibleScripts['landDeedChest'] = true
    -- tCompatibleScripts['MeadScript'] = true
    -- tCompatibleScripts['sirilonweChest'] = true
    -- tCompatibleScripts['Sound_Boat_Hull'] = true

    -- TR scripts
    -- tCompatibleScripts['LocalState'] = true
    -- tCompatibleScripts['T_ScObj_FGuildSupplyChestTR'] = true
    -- tCompatibleScripts['T_ScObj_MGuildSupplyChestTR'] = true

    -- tOverriddenScripts['T_ScObj_FGuildSupplyChestTR'] = function(params)
        -- if tLocalScriptsToRun[params.script.id] == true then
            -- local fightersGuild = tes3.getFaction('Fighters Guild')
            -- if fightersGuild and fightersGuild.playerRank == -1 then
                -- tes3.messageBox('This chest is reserved for newcomers to the Guild. You need to join the Guild of Fighters in order to be able to legally take its content.')
            -- end
            -- tLocalScriptsToRun[params.script.id] = false
        -- end
    -- end
--]]
    -- this thing has stupid mesh origin, changes its position with scale
    tDontCheck['furn_woodbar_01'] = true

    if graphicHerbalism then
        tMeshNamesToReplace['f\\furn_shell00.nif'] = 'AC\\anim_kollop_01gh.nif'
        tMeshNamesToReplace['f\\furn_shell10.nif'] = 'AC\\anim_kollop_02gh.nif'
        tMeshNamesToReplace['f\\furn_shell20.nif'] = 'AC\\anim_kollop_03gh.nif'
        tContainerTypes['anim_kollop_01gh'] = 'kollop'
        tContainerTypes['anim_kollop_02gh'] = 'kollop'
        tContainerTypes['anim_kollop_03gh'] = 'kollop'
    else
        tMeshNamesToReplace['f\\furn_shell00.nif'] = 'AC\\anim_kollop_01.nif'
        tMeshNamesToReplace['f\\furn_shell10.nif'] = 'AC\\anim_kollop_02.nif'
        tMeshNamesToReplace['f\\furn_shell20.nif'] = 'AC\\anim_kollop_03.nif'
        tContainerTypes['anim_kollop_01'] = 'kollop'
        tContainerTypes['anim_kollop_02'] = 'kollop'
        tContainerTypes['anim_kollop_03'] = 'kollop'
    end

    tMeshNamesToReplace['o\\contain_crate_01.nif'] = 'AC\\Anim_Crate_01.nif'
    tMeshNamesToReplace['o\\contain_crate_02.nif'] = 'AC\\Anim_Crate_02.nif'
    tMeshNamesToReplace['o\\contain_chest_small_01.nif'] = 'AC\\anim_chest_small_01.nif'
    tMeshNamesToReplace['o\\contain_chest_small_02.nif'] = 'AC\\anim_chest_small_02.nif'
    tMeshNamesToReplace['o\\contain_couldron10.nif'] = 'AC\\Anim_Cauldron.nif'
    tMeshNamesToReplace['o\\contain_pot_01.nif'] = 'AC\\Anim_Pot.nif'
    tMeshNamesToReplace['o\\contain_com_basket_01.nif'] = 'AC\\Anim_Basket.nif'
    tMeshNamesToReplace['o\\contain_com_chest_01.nif'] = 'AC\\anim_com_chest_01.nif'
    tMeshNamesToReplace['o\\contain_com_chest_02.nif'] = 'AC\\anim_com_chest_02.nif'
    tMeshNamesToReplace['o\\contain_com_closet_01.nif'] = 'AC\\Anim_com_Closet_01.nif'
    tMeshNamesToReplace['o\\contain_com_cupboard_01.nif'] = 'AC\\Anim_CupBoard.nif'
    tMeshNamesToReplace['o\\contain_com_drawers_01.nif'] = 'AC\\Anim_com_drawers_01.nif'
    tMeshNamesToReplace['o\\contain_com_hutch_01.nif'] = 'AC\\Anim_Hutch.nif'
    tMeshNamesToReplace['o\\contain_com_sack_01.nif'] = 'AC\\Anim_sack_01.nif'
    tMeshNamesToReplace['o\\contain_com_sack_02.nif'] = 'AC\\Anim_sack_02.nif'
    tMeshNamesToReplace['o\\contain_com_sack_03.nif'] = 'AC\\Anim_sack_03.nif'
    tMeshNamesToReplace['o\\contain_urn_01.nif'] = 'AC\\Anim_Urn_01.nif'
    tMeshNamesToReplace['o\\contain_urn_02.nif'] = 'AC\\Anim_Urn_02.nif'
    tMeshNamesToReplace['o\\contain_urn_03.nif'] = 'AC\\Anim_Urn_03.nif'
    tMeshNamesToReplace['o\\contain_urn_04.nif'] = 'AC\\Anim_Urn_04.nif'
    tMeshNamesToReplace['o\\contain_urn_05.nif'] = 'AC\\Anim_Urn_05.nif'
    if config.barrelRivet then
        tMeshNamesToReplace['o\\contain_barrel_01.nif'] = 'AC\\Anim_Barrel_01.nif'
    else
        tMeshNamesToReplace['o\\contain_barrel_01.nif'] = 'AC\\Anim_Barrel_noRivet.nif'
    end
    tMeshNamesToReplace['o\\contain_barrel10.nif'] = 'AC\\Anim_Barrel_02.nif'
    tMeshNamesToReplace['o\\contain_de_chest_01.nif'] = 'AC\\anim_de_chest_01.nif'
    tMeshNamesToReplace['o\\contain_de_chest_02.nif'] = 'AC\\anim_de_chest_02.nif'
    tMeshNamesToReplace['o\\contain_de_closet_01.nif'] = 'AC\\Anim_de_Closet_01.nif'
    tMeshNamesToReplace['o\\contain_de_closet_02.nif'] = 'AC\\Anim_de_Closet_02.nif'
    tMeshNamesToReplace['o\\contain_de_desk_01.nif'] = 'AC\\Anim_de_desk_01.nif'
    tMeshNamesToReplace['o\\contain_de_drawers_01.nif'] = 'AC\\Anim_de_drawers_01.nif'
    tMeshNamesToReplace['o\\contain_de_drawers_02.nif'] = 'AC\\Anim_de_drawers_02.nif'
    tMeshNamesToReplace['o\\contain_de_table_01.nif'] = 'AC\\Anim_de_table_01.nif'
    tMeshNamesToReplace['o\\contain_de_table_02.nif'] = 'AC\\Anim_de_table_02.nif'
    tMeshNamesToReplace['o\\contain_dwrv_barrel00.nif'] = 'AC\\Anim_Dw_Barrel_01.nif'
    tMeshNamesToReplace['o\\contain_dwrv_barrel10.nif'] = 'AC\\Anim_Dw_Barrel_02.nif'
    tMeshNamesToReplace['o\\contain_dwrv_chest00.nif'] = 'AC\\anim_dwrv_chest00.nif'
    tMeshNamesToReplace['o\\contain_dwrv_chest10.nif'] = 'AC\\anim_dwrv_chest10.nif'
    tMeshNamesToReplace['o\\contain_dwrv_closet00.nif'] = 'AC\\Anim_Dw_Closet.nif'
    tMeshNamesToReplace['o\\contain_dwrv_desk00.nif'] = 'AC\\Anim_Dw_Desk.nif'
    tMeshNamesToReplace['o\\contain_dwrv_drawers00.nif'] = 'AC\\Anim_Dw_Drawers.nif'
    tMeshNamesToReplace['o\\contain_dwrv_table00.nif'] = 'AC\\Anim_Dw_Table.nif'
    tMeshNamesToReplace['o\\contain_de_crate_logo.nif'] = 'AC\\Anim_CrateLogo.nif'
    tMeshNamesToReplace['f\\furn_dwrv_cabinet00.nif'] = 'AC\\Anim_Dw_Cabinet.nif'
    tMeshNamesToReplace['o\\contain_chest10.nif'] = 'AC\\anim_chest10.nif'
    -- tMeshNamesToReplace['o\\contain_chest_large_01.nif'] = ' ' -- only in test room
    -- tMeshNamesToReplace['o\\contain_sack00.nif'] = ' ' -- not placed in world
    -- tMeshNamesToReplace['o\\contain_chest11.nif'] = ' ' -- open contain_chest10
    -- mwse.log(' config.barrelRivet %s', config.barrelRivet)
    for obj in tes3.iterateObjects(iContainerType) do
        local name = obj.model:lower()
        local newName = tMeshNamesToReplace[name]

        if newName then
            -- mwse.log(' replace %s %s %s', obj.id, obj.model, tMeshNamesToReplace[name])
            obj.model = newName
        end
        -- if obj.script then
            -- if tOverriddenScripts[sScriptID] then
                -- mwse.log('override Script %s %s', obj.id, sScriptID)
                -- mwse.overrideScript(sScriptID, tOverriddenScripts[sScriptID])
            -- end
        -- end
    end

    local unique = tes3.getObject('com_chest_Daed_crusher')
    if unique then -- unique levitating chest in Forgotten Vaults of Anudnabia
        unique.model = 'AC\\anim_daedric_chest.nif'
    end

    pickUpSound = tes3.getSound('Item Misc Up')
    openLockFailSound = tes3.getSound('Open Lock Fail')
    openLockSound = tes3.getSound('Open Lock')

    -- actual distance is often larger
    iActivationDistGMST = tes3.findGMST(tes3.gmst.iMaxActivateDist).value
    sKeyUsedGMST = tes3.findGMST(tes3.gmst.sKeyUsed).value

    tObjectTypesToCheck[tes3.objectType.activator] = true
    tObjectTypesToCheck[tes3.objectType.alchemy] = true
    tObjectTypesToCheck[tes3.objectType.apparatus] = true
    tObjectTypesToCheck[tes3.objectType.armor] = true
    tObjectTypesToCheck[tes3.objectType.book] = true
    tObjectTypesToCheck[tes3.objectType.clothing] = true
    tObjectTypesToCheck[tes3.objectType.container] = true
    tObjectTypesToCheck[tes3.objectType.ingredient] = true
    tObjectTypesToCheck[tes3.objectType.light] = true
    tObjectTypesToCheck[tes3.objectType.lockpick] = true
    tObjectTypesToCheck[tes3.objectType.miscItem] = true
    tObjectTypesToCheck[tes3.objectType.probe] = true
    tObjectTypesToCheck[tes3.objectType.repairItem] = true
    tObjectTypesToCheck[tes3.objectType.static] = true
    tObjectTypesToCheck[tes3.objectType.weapon] = true

    tOpenSounds['barrel'] = tes3.getSound('AC_barrel_open')
    tCloseSounds['barrel'] = tes3.getSound('AC_barrel_close')
    tOpenSounds['cauldron'] = tes3.getSound('AC_cauldron_open')
    tCloseSounds['cauldron'] = tes3.getSound('AC_cauldron_close')
    tOpenSounds['pot'] = tes3.getSound('AC_pot_open')
    tCloseSounds['pot'] = tes3.getSound('AC_pot_close')
    tOpenSounds['daedric'] = tes3.getSound('AC_daed_open')
    tCloseSounds['daedric'] = tes3.getSound('AC_daed_close')
    tOpenSounds['closet'] = tes3.getSound('AC_closet_open')
    tCloseSounds['closet'] = tes3.getSound('AC_closet_close')
    tOpenSounds['cupboard'] = tes3.getSound('AC_cupboard_open')
    tCloseSounds['cupboard'] = tes3.getSound('AC_cupboard_close')
    tOpenSounds['drawer'] = tes3.getSound('AC_drawer_open')
    tCloseSounds['drawer'] = tes3.getSound('AC_drawer_close')
    tOpenSounds['drawerDunmer'] = tes3.getSound('AC_drawer_de_open')
    tCloseSounds['drawerDunmer'] = tes3.getSound('AC_drawer_de_close')
    tOpenSounds['basket'] = tes3.getSound('AC_basket_open')
    tCloseSounds['basket'] = tes3.getSound('AC_basket_close')
    tOpenSounds['chestSmall'] = tes3.getSound('AC_smallChest_open')
    tCloseSounds['chestSmall'] = tes3.getSound('AC_smallChest_close')
    tOpenSounds['sack'] = tes3.getSound('AC_sack_open')
    tCloseSounds['sack'] = tes3.getSound('AC_sack_close')
    tOpenSounds['chest'] = tes3.getSound('AC_chest_open')
    tCloseSounds['chest'] = tes3.getSound('AC_chest_close')
    tOpenSounds['crate'] = tes3.getSound('AC_crate_open')
    tCloseSounds['crate'] = tes3.getSound('AC_crate_close')
    tOpenSounds['chestDwemer'] = tes3.getSound('AC_dw_chest_open')
    tCloseSounds['chestDwemer'] = tes3.getSound('AC_dw_chest_close')
    tOpenSounds['closetDwemer'] = tes3.getSound('AC_dw_closet_open')
    tCloseSounds['closetDwemer'] = tes3.getSound('AC_dw_closet_close')
    tOpenSounds['drawerDwemer'] = tes3.getSound('AC_dw_drawer_open')
    tCloseSounds['drawerDwemer'] = tes3.getSound('AC_dw_drawer_close')
    tOpenSounds['keg'] = tes3.getSound('AC_keg_open')
    tCloseSounds['keg'] = tes3.getSound('AC_keg_close')
    tOpenSounds['urn'] = tes3.getSound('AC_urn_open')
    tCloseSounds['urn'] = tes3.getSound('AC_urn_close')

    tNotSafeCtypes['daedric'] = true
    tNotSafeCtypes['barrel'] = true
    tNotSafeCtypes['crate'] = true
    tNotSafeCtypes['basket'] = true
    tNotSafeCtypes['cauldron'] = true
    tNotSafeCtypes['chestSmall'] = true
    tNotSafeCtypes['keg'] = true
    tNotSafeCtypes['chestDwemer'] = true
    tNotSafeCtypes['urn'] = true
    tNotSafeCtypes['chest'] = true

    tContHeightToCheck['daedric'] = 0.33
    tContHeightToCheck['barrel'] = 0.2
    tContHeightToCheck['crate'] = 0.4
    tContHeightToCheck['basket'] = 0.2
    tContHeightToCheck['cauldron'] = 0.15
    tContHeightToCheck['chestSmall'] = 1
    tContHeightToCheck['keg'] =  0.25
    tContHeightToCheck['chestDwemer'] = 0.33
    tContHeightToCheck['urn'] = 0.2
    tContHeightToCheck['chest'] = 0.55

    tContainerTypes['anim_daedric_chest'] = 'daedric'
    tContainerTypes['anim_barrel_01'] = 'barrel'
    tContainerTypes['anim_barrel_norivet'] = 'barrel'
    tContainerTypes['anim_barrel_02'] = 'barrel'
    tContainerTypes['anim_crate_01'] = 'crate'
    tContainerTypes['anim_crate_02'] = 'crate'
    tContainerTypes['anim_cratelogo'] = 'crate'
    tContainerTypes['anim_basket'] = 'basket'
    tContainerTypes['anim_cauldron'] = 'cauldron'
    tContainerTypes['anim_chest_small_01'] = 'chestSmall'
    tContainerTypes['anim_chest_small_02'] = 'chestSmall'
    tContainerTypes['anim_chest10'] = 'chest'
    tContainerTypes['anim_com_chest_01'] = 'chest'
    tContainerTypes['anim_com_chest_02'] = 'chest'
    tContainerTypes['anim_de_chest_01'] = 'chest'
    tContainerTypes['anim_de_chest_02'] = 'chest'
    tContainerTypes['anim_de_closet_02'] = 'closet'
    tContainerTypes['anim_de_closet_01'] = 'closet'
    tContainerTypes['anim_com_closet_01'] = 'closet'
    tContainerTypes['anim_com_drawers_01'] = 'drawer'
    tContainerTypes['anim_de_drawers_01'] = 'drawer'
    tContainerTypes['anim_de_table_02'] = 'drawerDunmer'
    tContainerTypes['anim_de_table_01'] = 'drawerDunmer'
    tContainerTypes['anim_de_drawers_02'] = 'drawerDunmer'
    tContainerTypes['anim_de_desk_01'] = 'drawerDunmer'
    tContainerTypes['anim_dw_barrel_02'] = 'keg'
    tContainerTypes['anim_dw_barrel_01'] = 'keg'
    tContainerTypes['anim_dw_table'] = 'drawerDwemer'
    tContainerTypes['anim_dw_drawers'] = 'drawerDwemer'
    tContainerTypes['anim_dw_desk'] = 'drawerDwemer'
    tContainerTypes['anim_dw_cabinet'] = 'drawerDwemer'
    tContainerTypes['anim_dwrv_chest10'] = 'chestDwemer'
    tContainerTypes['anim_dwrv_chest00'] = 'chestDwemer'
    tContainerTypes['anim_dw_closet'] = 'closetDwemer'
    tContainerTypes['anim_hutch'] = 'cupboard'
    tContainerTypes['anim_cupboard'] = 'cupboard'
    tContainerTypes['anim_pot'] = 'pot'
    tContainerTypes['anim_sack_01'] = 'sack'
    tContainerTypes['anim_sack_02'] = 'sack'
    tContainerTypes['anim_sack_03'] = 'sack'
    tContainerTypes['anim_urn_01'] = 'urn'
    tContainerTypes['anim_urn_02'] = 'urn'
    tContainerTypes['anim_urn_03'] = 'urn'
    tContainerTypes['anim_urn_04'] = 'urn'
    tContainerTypes['anim_urn_05'] = 'urn'

    config.version = 2.06
end


local function OnInitialized(eventData)

    if not tes3.isModActive('MW Containers Animated.esp') then
        return
    end

    Setup()

    event.register("cellChanged", OnCellChanged)
    event.register("loaded", OnLoaded)
    event.register("activate", OnActivateObject, {priority = 1200})
    event.register("activationTargetChanged", OnActivationTargetChanged, {priority = 1200})
    mwse.log("[MW Containers Animated v2.06] lua loaded")
end
event.register("initialized", OnInitialized)

-- debug stuff below

local function OnActivationTargetChangedTest(eventData)
    if eventData.current then
        local ref = eventData.current
        if ref.object.objectType == iContainerType then
            local sContType = GetContainerType(ref)
            -- tes3.messageBox('LEVELED ITEMS %d', CountLeveledItems(ref.object.inventory))
             -- tes3.messageBox("%s   %s", ref.object.id, ref.isEmpty)
            if sContType then
                -- tes3.messageBox('orientation.z %f', math.deg(ref.orientation.z))
                tes3.messageBox('sContType %s', sContType)
                if tNotSafeCtypes[sContType] then
                    if ref.data.AC_skipAnim then
                        tes3.messageBox('AC_skipAnim %s', ref.data.AC_skipAnim)
                    end
                    if ref.data.AC_staticItems then
                        tes3.messageBox('AC_staticItems %s', ref.data.AC_staticItems)
                    end
                    if ref.data.AC_movableItems then
                        tes3.messageBox('AC_movableItems %s', ref.data.AC_movableItems)
                    end
                end
        -- tes3.messageBox('max y %d', eventData.current.object.boundingBox.max.y)
        -- tes3.messageBox('min y %d', eventData.current.object.boundingBox.min.y)
            end
        end
    end
end
-- event.register("activationTargetChanged", OnActivationTargetChangedTest)


-- local switchIndex = 0
local function Test()
    local target = tes3.getPlayerTarget()
    -- local v = tes3.getPlayerEyeVector()
    if target then
        GetContainerType(target)
        tes3.messageBox('data.GH %s AC_state %s isEmpty %s', target.data.GH, target.data.AC_state, target.isEmpty)
        -- tes3.messageBox('%s', target.object.mesh)
        local sceneNode = target.sceneNode
        if not sceneNode then
            tes3.messageBox(' no sceneNode')
            return
        end

        local switchNode = sceneNode:getObjectByName("HerbalismSwitch")
        if switchNode then
            -- switchIndex = switchIndex + 1
            -- if switchIndex == 3 then
                -- switchIndex = 0
            -- end
            -- switchNode.switchIndex = switchIndex
            tes3.messageBox('%s', switchNode.children[switchNode.switchIndex+1].name)
        else
            tes3.messageBox(' no switchNode')
        end
        -- tes3.messageBox('GH %s', target.data.GH)
        -- tes3.messageBox('AC_state %s', target.data.AC_state)
        -- local pos = tes3vector3.new(target.position.x,target.position.y,target.position.z +target.object.boundingBox.min.z)
        -- local egg = tes3.createReference { object = 'food_kwama_egg_01', position = target.position, orientation = v3up, cell = playerRef.cell }
        -- egg.scale = 0.3
        -- target.data.AC_skipAnim = true
        -- target.lockNode.level = 33
        -- tes3.unlock {reference = target}
        -- mwse.log('mwse.log test %d', 'q')
        -- local result1 = tes3.rayTest{ position = target.position, direction = tes3vector3.new(0,0,1), findAll = true, useBackTriangles = true, ignore = {target} }
            -- if result1 then
                -- for i, hit in pairs(result1) do
                    -- if hit.reference then
                        -- mwse.log('%s RayTestUp hit %s', target.object.id, hit.reference.id)
                    -- end
                -- end
            -- end
        -- RayTest(target)
        -- if target.data.AC_items then
        -- for _, ref in pairs(target.data.AC_items) do
            -- mwse.log('MWCA items %s %s', target.object.id, ref.object.id)

        -- for _, pos in pairs( GGetBoundingBoxVertexPositions(target.position:copy(), target.orientation:copy(), target.object.boundingBox.min:copy(), target.object.boundingBox.max:copy())) do
            -- local egg = tes3.createReference { object = 'food_kwama_egg_01', position = pos, orientation = v3up, cell = target.cell }
            -- egg.scale = 0.5
        -- end

        -- local trapSpell = tes3.getTrap {reference = ref}
        -- tes3.setTrap {reference = target, spell = 'ghost_snake'}
        -- tes3.playAnimation {reference = target, group = 2, startFlag = 0}
        -- tes3.messageBox('W  %d', target.object.inventory:calculateWeight())
    end
end
-- event.register("keyDown", Test, { filter = tes3.scanCode.z })