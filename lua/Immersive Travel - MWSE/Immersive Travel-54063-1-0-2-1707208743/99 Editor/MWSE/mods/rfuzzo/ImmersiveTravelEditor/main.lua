--[[
Immersive Travel Mod
v 1.1
by rfuzzo

mwse real-time travel mod


--]]
--
local common = require("rfuzzo.ImmersiveTravel.common")

-- /////////////////////////////////////////////////////////////////////////////////////////
-- ////////////// CONFIGURATION
local config = require("rfuzzo.ImmersiveTravelEditor.config")

local logger = require("logging.logger")
local log = logger.new {
    name = config.mod,
    logLevel = config.logLevel,
    logToConsole = true,
    includeTimestamp = true
}

---@class SPreviewData
---@field mount tes3reference?

---@class SEditorData
---@field service ServiceData
---@field start string
---@field destination string
---@field mount tes3reference?
---@field splineIndex integer
---@field editorMarkers niNode[]?
---@field currentMarker niNode?

--[[
Current Usage (Debug)
- Open route editor 						... R-Ctrl
- move a marker 							... L-Ctrl
- delete a marker 							... Del
- exit edit mode 							... L-Ctrl
- add a marker								... >
- start traveling            		        ... <

--]]
local editMenuId = tes3ui.registerID("it:MenuEdit")
local editMenuSaveId = tes3ui.registerID("it:MenuEdit_Display")
local editMenuPrintId = tes3ui.registerID("it:MenuEdit_Print")
local editMenuModeId = tes3ui.registerID("it:MenuEdit_Mode")
local editMenuCancelId = tes3ui.registerID("it:MenuEdit_Cancel")
local editMenuTeleportId = tes3ui.registerID("it:MenuEdit_Teleport")
local editMenuTeleportEndId = tes3ui.registerID("it:MenuEdit_TeleportEnd")
local editMenuPreviewId = tes3ui.registerID("it:MenuEdit_Preview")
local editMenuSearchId = tes3ui.registerID("it:MenuEdit_Search")

local editorMarkerId = "marker_arrow.nif"
local editorMarkerMesh = nil

-- editor
---@type string | nil
local currentServiceName = nil
---@type SEditorData | nil
local editorData = nil
local editmode = false

-- preview
---@type SPreviewData | nil
local preview = nil

-- tracing
local filter_text = ""
local arrows = {}
local arrow = nil

-- /////////////////////////////////////////////////////////////////////////////////////////
-- ////////////// FUNCTIONS

---@param pos PositionRecord
--- @return tes3vector3
local function vec(pos) return tes3vector3.new(pos.x, pos.y, pos.z) end

---@param data MountData
---@param startPoint tes3vector3
---@param nextPoint tes3vector3
---@param mountId string
---@return tes3reference
local function createMount(data, startPoint, nextPoint, mountId)
    local d = nextPoint - startPoint
    d:normalize()

    local newFacing = math.atan2(d.x, d.y)

    -- create mount
    local mountOffset = tes3vector3.new(0, 0, data.offset)
    local mount = tes3.createReference {
        object = mountId,
        position = startPoint + mountOffset,
        orientation = d
    }
    mount.facing = newFacing

    return mount
end

--- @param from tes3vector3
--- @return number|nil
local function getGroundZ(from)
    local rayhit = tes3.rayTest {
        position = from,
        direction = tes3vector3.new(0, 0, -1),
        returnNormal = true
    }

    if (rayhit) then
        local to = rayhit.intersection
        return to.z
    end

    return nil
end

local function updateMarkers()
    if not editorData then return end
    local editorMarkers = editorData.editorMarkers
    if not editorMarkers then return end

    -- update rotation
    for index, marker in ipairs(editorMarkers) do
        if index < #editorMarkers then
            local nextMarker = editorMarkers[index + 1]
            local direction = nextMarker.translation - marker.translation
            local rotation_matrix = common.rotationFromDirection(direction)
            marker.rotation = rotation_matrix
        end
    end

    tes3.worldController.vfxManager.worldVFXRoot:update()
end

---@return number|nil
local function getClosestMarkerIdx()
    if not editorData then return nil end
    local editorMarkers = editorData.editorMarkers
    if not editorMarkers then return nil end

    -- get closest marker
    local pp = tes3.player.position

    local final_idx = 0
    local last_distance = nil
    for index, marker in ipairs(editorMarkers) do
        local distance_to_marker = pp:distance(marker.translation)

        -- first
        if last_distance == nil then
            last_distance = distance_to_marker
            final_idx = 1
        end

        if distance_to_marker < last_distance then
            final_idx = index
            last_distance = distance_to_marker
        end
    end

    editorData.currentMarker = editorMarkers[final_idx]

    updateMarkers()

    return final_idx
end

---comment
---@param spline PositionRecord[]
local function renderMarkers(spline)
    if not editorData then return nil end
    if not editorMarkerMesh then return nil end

    editorData.editorMarkers = {}
    editorData.currentMarker = nil

    local vfxRoot = tes3.worldController.vfxManager.worldVFXRoot
    vfxRoot:detachAllChildren()

    -- add markers

    for idx, v in ipairs(spline) do
        local child = editorMarkerMesh:clone()
        child.translation = tes3vector3.new(v.x, v.y, v.z)
        child.appCulled = false

        ---@diagnostic disable-next-line: param-type-mismatch
        vfxRoot:attachChild(child)

        ---@diagnostic disable-next-line: assign-type-mismatch
        editorData.editorMarkers[idx] = child
    end

    updateMarkers()
end

local function cleanup()
    if editorData then
        if editorData.mount ~= nil then editorData.mount:delete() end
    end
    editorData = nil
end

local last_position = nil ---@type tes3vector3|nil
local last_forwardDirection = nil ---@type tes3vector3|nil
local last_facing = nil ---@type number|nil

---comment
---@param startpos tes3vector3
---@param mountData MountData
local function calculatePositions(startpos, mountData)
    if not editorData then return end
    if not editorData.editorMarkers then return end

    editorData.splineIndex = 2
    last_position = editorData.mount.position
    last_forwardDirection = editorData.mount.forwardDirection
    last_facing = editorData.mount.facing

    -- local positions = {} ---@type tes3vector3[]
    arrows = {}
    -- table.insert(positions, 1, startpos)

    for idx = 1, config.tracemax * 1000, 1 do
        if editorData.splineIndex <= #editorData.editorMarkers then
            local mountOffset = tes3vector3.new(0, 0, mountData.offset)
            local point = editorData.editorMarkers[editorData.splineIndex]
                .translation
            local nextPos = tes3vector3.new(point.x, point.y, point.z)
            local currentPos = last_position - mountOffset

            local forwardDirection = last_forwardDirection
            -- if idx > 1 then v = currentPos - positions[idx - 1] end
            forwardDirection:normalize()
            local d = (nextPos - currentPos):normalized()
            local lerp = forwardDirection:lerp(d, mountData.turnspeed / 10):normalized()

            -- calculate heading
            local current_facing = last_facing
            local new_facing = math.atan2(d.x, d.y)
            local facing = new_facing
            local diff = new_facing - current_facing
            if diff < -math.pi then diff = diff + 2 * math.pi end
            if diff > math.pi then diff = diff - 2 * math.pi end
            local angle = mountData.turnspeed / 10000 * config.grain
            if diff > 0 and diff > angle then
                facing = current_facing + angle
            elseif diff < 0 and diff < -angle then
                facing = current_facing - angle
            else
                facing = new_facing
            end
            editorData.mount.facing = facing

            -- calculate position
            local forward = tes3vector3.new(editorData.mount.forwardDirection.x,
                editorData.mount.forwardDirection.y,
                lerp.z):normalized()
            local delta = forward * mountData.speed * config.grain
            local mountPosition = currentPos + delta + mountOffset
            editorData.mount.position = mountPosition

            -- save
            last_position = editorData.mount.position
            last_forwardDirection = editorData.mount.forwardDirection
            last_facing = editorData.mount.facing


            -- draw vfx lines
            if arrow then
                local child = arrow:clone()
                child.translation = mountPosition - mountOffset
                child.appCulled = false
                child.rotation = common.rotationFromDirection(forward)
                table.insert(arrows, child)
            end

            -- move to next marker
            local isBehind = common.isPointBehindObject(nextPos, mountPosition,
                forward)
            if isBehind then
                editorData.splineIndex = editorData.splineIndex + 1
            end
        else
            break
        end
    end

    editorData.mount:delete()
    editorData.mount = nil
end

---comment
---@param service ServiceData
local function traceRoute(service)
    if not editorData then return end
    if not editorData.editorMarkers then return end
    if #editorData.editorMarkers < 2 then return end

    log:debug("Tracing " .. editorData.start .. " > " .. editorData.destination)

    arrow = tes3.loadMesh("mwse\\arrow.nif"):getObjectByName("unitArrow"):clone()
    arrow.scale = 40
    local vfxRoot = tes3.worldController.vfxManager.worldVFXRoot
    for index, value in ipairs(arrows) do vfxRoot:detachChild(value) end

    -- trace the route
    local start_point = editorData.editorMarkers[1].translation
    local start_pos = tes3vector3.new(start_point.x, start_point.y,
        start_point.z)
    local next_point = editorData.editorMarkers[2].translation

    -- create mount
    local mountId = service.mount
    -- override mounts
    if service.override_mount then
        for _, o in ipairs(service.override_mount) do
            if common.is_in(o.points, editorData.start) and common.is_in(o.points, editorData.destination) then
                mountId = o.id
                break
            end
        end
    end
    local mountData = common.loadMountData(mountId)
    if not mountData then return end
    editorData.mount = createMount(mountData, start_point, next_point, mountId)

    calculatePositions(start_pos, mountData)

    -- vfx
    for index, child in ipairs(arrows) do
        ---@diagnostic disable-next-line: param-type-mismatch
        vfxRoot:attachChild(child)
    end

    vfxRoot:update()
end

-- /////////////////////////////////////////////////////////////////////////////////////////
-- ////////////// EDITOR

local function createEditWindow()
    -- Return if window is already open
    if (tes3ui.findMenu(editMenuId) ~= nil) then return end

    -- load services
    local services = common.loadServices()
    if not services then return end

    -- get current service
    if not currentServiceName then
        currentServiceName = table.keys(services)[1]
    end
    if editorData then currentServiceName = editorData.service.class end

    local service = services[currentServiceName]
    common.loadRoutes(service)

    -- Create window and frame
    local menu = tes3ui.createMenu {
        id = editMenuId,
        fixedFrame = false,
        dragFrame = true
    }

    -- To avoid low contrast, text input windows should not use menu transparency settings
    menu.alpha = 1.0
    menu.width = 500
    menu.height = 500
    if editorData then
        menu.text = "Editor " .. editorData.start .. "_" ..
            editorData.destination
    else
        menu.text = "Editor"
    end

    local input = menu:createTextInput { text = filter_text, id = editMenuSearchId }
    input.widget.lengthLimit = 31
    input.widget.eraseOnFirstKey = true
    input:register(tes3.uiEvent.keyEnter, function()
        local m = tes3ui.findMenu(editMenuId)
        if (m) then
            local text = menu:findChild(editMenuSearchId).text
            filter_text = text
            cleanup()
            m:destroy()
            createEditWindow()
        end
    end)

    -- Create layout
    local label = menu:createLabel { text = "Loaded routes (" .. currentServiceName .. ")" }
    label.borderBottom = 5

    -- get destinations
    local destinations = service.routes
    if destinations then
        local pane = menu:createVerticalScrollPane { id = "sortedPane" }
        for _i, start in ipairs(table.keys(destinations)) do
            for _j, destination in ipairs(destinations[start]) do
                -- filter
                local filter = filter_text:lower()
                if filter_text ~= "" then
                    if (not string.find(start:lower(), filter) and not string.find(destination:lower(), filter)) then
                        goto continue
                    end
                end

                local text = start .. " - " .. destination
                local button = pane:createButton {
                    id = "button_spline" .. text,
                    text = text
                }
                button:register(tes3.uiEvent.mouseClick, function()
                    -- start editor
                    editorData = {
                        service = service,
                        destination = destination,
                        start = start,
                        mount = nil,
                        splineIndex = 1,
                        editorMarkers = nil,
                        currentMarker = nil
                    }

                    local spline =
                        common.loadSpline(start, destination, service)
                    tes3.messageBox("loaded spline: " .. start .. " -> " ..
                        destination)

                    renderMarkers(spline)
                    if config.traceOnSave then
                        traceRoute(service)
                    end
                end)

                ::continue::
            end
        end
        pane:getContentElement():sortChildren(function(a, b)
            return a.text < b.text
        end)
    end

    local button_block = menu:createBlock {}
    button_block.widthProportional = 1.0 -- width is 100% parent width
    button_block.autoHeight = true
    button_block.childAlignX = 1.0       -- right content alignment

    local button_mode = button_block:createButton {
        id = editMenuModeId,
        text = currentServiceName
    }
    local button_teleport = button_block:createButton {
        id = editMenuTeleportId,
        text = "Start"
    }
    local button_teleportEnd = button_block:createButton {
        id = editMenuTeleportEndId,
        text = "End"
    }
    local button_preview = button_block:createButton {
        id = editMenuPreviewId,
        text = "Preview"
    }
    local button_save = button_block:createButton {
        id = editMenuSaveId,
        text = "Save"
    }
    -- local button_print = button_block:createButton {
    --     id = editMenuPrintId,
    --     text = "Print"
    -- }
    local button_cancel = button_block:createButton {
        id = editMenuCancelId,
        text = "Exit"
    }

    -- Switch mode
    button_mode:register(tes3.uiEvent.mouseClick, function()
        local m = tes3ui.findMenu(editMenuId)
        if (m) then
            -- go to next
            local idx = table.find(table.keys(services), currentServiceName)
            local nextIdx = idx + 1
            if nextIdx > #table.keys(services) then nextIdx = 1 end
            currentServiceName = table.keys(services)[nextIdx]

            cleanup()
            m:destroy()
            createEditWindow()
        end
    end)
    -- Leave Menu
    button_cancel:register(tes3.uiEvent.mouseClick, function()
        local m = tes3ui.findMenu(editMenuId)
        if (m) then
            tes3ui.leaveMenuMode()
            m:destroy()
        end
    end)
    -- Teleport
    button_teleport:register(tes3.uiEvent.mouseClick, function()
        if not editorData then return end
        if not editorData.editorMarkers then return end

        local m = tes3ui.findMenu(editMenuId)
        if (m) then
            if #editorData.editorMarkers > 1 then
                tes3.positionCell({
                    reference = tes3.mobilePlayer,
                    position = editorData.editorMarkers[1].translation
                })

                tes3ui.leaveMenuMode()
                m:destroy()
            end
        end
    end)

    button_teleportEnd:register(tes3.uiEvent.mouseClick, function()
        if not editorData then return end
        if not editorData.editorMarkers then return end

        local m = tes3ui.findMenu(editMenuId)
        if (m) then
            if #editorData.editorMarkers > 1 then
                tes3.positionCell({
                    reference = tes3.mobilePlayer,
                    position = editorData.editorMarkers[#editorData.editorMarkers].translation
                })

                tes3ui.leaveMenuMode()
                m:destroy()
            end
        end
    end)

    button_preview:register(tes3.uiEvent.mouseClick, function()
        if not editorData then return end

        local m = tes3ui.findMenu(editMenuId)
        if (m) then
            -- delete preview
            if preview then
                preview.mount:delete()
                preview.mount = nil
                preview = nil
                local vfxRoot = tes3.worldController.vfxManager.worldVFXRoot
                vfxRoot:detachAllChildren()
                return
            end

            local from = tes3.getPlayerEyePosition() + tes3.getPlayerEyeVector() * 256

            -- create mount
            local mountId = service.mount
            if service.override_mount then
                for _, o in ipairs(service.override_mount) do
                    if common.is_in(o.points, editorData.start) and common.is_in(o.points, editorData.destination) then
                        mountId = o.id
                        break
                    end
                end
            end

            local mount = tes3.createReference {
                object = mountId,
                position = from,
                orientation = tes3.player.orientation
            }

            preview = {
                mount = mount
            }

            -- preview slots
            local mountData = common.loadMountData(mountId)
            if not mountData then return end

            local vfxRoot = tes3.worldController.vfxManager.worldVFXRoot
            -- local marker = tes3.loadMesh("marker_divine.nif")
            local marker = tes3.loadMesh("marker_arrow.nif")
            for _index, slot in ipairs(mountData.slots) do
                local child = marker:clone()
                child.scale = 0.5
                child.translation = mount.sceneNode.worldTransform * vec(slot.position)
                child.rotation = mount.sceneNode.worldTransform.rotation
                child.appCulled = false
                vfxRoot:attachChild(child, true)
            end

            vfxRoot:update()

            tes3ui.leaveMenuMode()
            m:destroy()
        end
    end)

    -- log current spline
    -- button_print:register(tes3.uiEvent.mouseClick, function()
    --     if not editorData then return end
    --     if not editorData.editorMarkers then return end

    --     -- print to log
    --     local current_editor_route = editorData.start .. "_" ..
    --         editorData.destination
    --     mwse.log("============================================")
    --     mwse.log(current_editor_route)
    --     mwse.log("============================================")
    --     for i, value in ipairs(editorData.editorMarkers) do
    --         local t = value.translation
    --         mwse.log("{ \"x\": " .. math.round(t.x) .. ", \"y\": " ..
    --             math.round(t.y) .. ", \"z\": " .. math.round(t.z) ..
    --             " },")
    --     end
    --     mwse.log("============================================")
    --     tes3.messageBox("printed spline: " .. current_editor_route)
    -- end)

    --- save to file
    button_save:register(tes3.uiEvent.mouseClick, function()
        if not editorData then return end
        if not editorData.editorMarkers then return end

        local tempSpline = {}
        for i, value in ipairs(editorData.editorMarkers) do
            local t = value.translation

            -- save currently edited markers back to spline
            table.insert(tempSpline, i, {
                x = math.round(t.x),
                y = math.round(t.y),
                z = math.round(t.z)
            })
        end

        -- save to file
        local current_editor_route = editorData.start .. "_" ..
            editorData.destination
        local filename = common.localmodpath .. service.class .. "\\" ..
            current_editor_route
        json.savefile(filename, tempSpline)

        tes3.messageBox("saved spline: " .. current_editor_route)
    end)



    -- Final setup
    tes3ui.acquireTextInput(input)
    menu:updateLayout()
    tes3ui.enterMenuMode(editMenuId)
end

-- /////////////////////////////////////////////////////////////////////////////////////////
-- ////////////// EVENTS

--- @param e simulatedEventData
local function simulatedCallback(e)
    if not editorData then return end
    if not editorData.currentMarker then return end

    if editmode == false then return end

    local service = editorData.service
    local from = tes3.getPlayerEyePosition() + tes3.getPlayerEyeVector() * 256

    if service.ground_offset == 0 then
        from.z = 0
    else
        local groundZ = getGroundZ(from)
        if groundZ == nil then
            from.z = service.ground_offset
        else
            from.z = groundZ + service.ground_offset
        end
    end

    editorData.currentMarker.translation = from
    editorData.currentMarker:update()
end
event.register(tes3.event.simulated, simulatedCallback)

--- @param e keyDownEventData
local function editor_keyDownCallback(e)
    -- editor menu
    if e.keyCode == config.openkeybind.keyCode then createEditWindow() end

    -- insert
    if e.keyCode == config.placekeybind.keyCode then
        if not editorData then return end
        if not editorMarkerMesh then return end
        if not editorData.editorMarkers then return end

        local idx = getClosestMarkerIdx()
        local child = editorMarkerMesh:clone()

        local from = tes3.getPlayerEyePosition() + tes3.getPlayerEyeVector() *
            256

        child.translation = tes3vector3.new(from.x, from.y, from.z)
        child.appCulled = false

        local vfxRoot = tes3.worldController.vfxManager.worldVFXRoot
        ---@diagnostic disable-next-line: param-type-mismatch
        vfxRoot:attachChild(child)
        vfxRoot:update()

        table.insert(editorData.editorMarkers, idx + 1, child)

        editorData.currentMarker = child
        editmode = true
    end

    -- marker edit mode
    if e.keyCode == config.editkeybind.keyCode then
        local idx = getClosestMarkerIdx()
        if idx then
            editmode = not editmode
            tes3.messageBox("Marker index: " .. idx)
            if not editmode then
                if editorData and config.traceOnSave then
                    traceRoute(editorData.service)
                end
            end
        end
    end

    -- delete
    if e.keyCode == config.deletekeybind.keyCode then
        if not editorData then return end
        if not editorData.editorMarkers then return end

        local idx = getClosestMarkerIdx()
        if idx then
            local instance = editorData.editorMarkers[idx]
            local vfxRoot = tes3.worldController.vfxManager.worldVFXRoot
            vfxRoot:detachChild(instance)
            vfxRoot:update()

            table.remove(editorData.editorMarkers, idx)

            if editorData and config.traceOnSave then
                traceRoute(editorData.service)
            end
        end
    end

    -- trace
    if e.keyCode == config.tracekeybind.keyCode then
        if editorData then traceRoute(editorData.service) end
    end
end
event.register(tes3.event.keyDown, editor_keyDownCallback)

--- Cleanup on save load
--- @param e loadEventData
local function editloadCallback(e)
    editorMarkerMesh = tes3.loadMesh(editorMarkerId)
    cleanup()
end
event.register(tes3.event.load, editloadCallback)

-- /////////////////////////////////////////////////////////////////////////////////////////
-- ////////////// CONFIG
require("rfuzzo.ImmersiveTravelEditor.mcm")
