local interop = require("sb_compass.interop")
interop.mcm.init()

local hudCustomiser = include("seph.hudCustomizer.interop")

local signs = { "furn_com_fence_01", "furn_com_fence_02", "furn_com_fence_03" }

local function has_value (tab, val)
    if (val ~= nil) then
        for index, value in ipairs(tab) do
            if value == val then
                return true
            end
        end
    end

    return false
end

local function string_starts(String, Start)
    return string.sub(String, 1, string.len(Start)) == Start
end

local function referenceActivatedCallback(e)
    if (interop.isCompassEnabled()) then
        local type = e.reference.baseObject.objectType
        if (interop.mcm.config.mrkSign.enabled and has_value(signs, e.reference.baseObject.id)) then
            table.insert(interop.mcm.distMarkers.mid, e.reference)
            interop.registerMarker(e.reference, tostring(e.reference), "Icons\\sb_compass\\directions.tga", interop.mcm.config.mrkBanner.colour)
        elseif (interop.mcm.config.mrkTransport.enabled and string_starts(e.reference.baseObject.id, "active_port_")) then
            table.insert(interop.mcm.distMarkers.mid, e.reference)
            interop.registerMarker(e.reference, tostring(e.reference), "Icons\\sb_compass\\propylon.tga", interop.mcm.config.mrkTransport.colour)
        elseif (interop.mcm.config.mrkBanner.enabled and type == tes3.objectType.activator and e.reference.baseObject.script and (e.reference.baseObject.script.id == "OutsideBanner" or e.reference.baseObject.script.id == "SignRotate") and e.reference.name ~= "") then
            table.insert(interop.mcm.distMarkers.mid, e.reference)
            interop.registerMarker(e.reference, tostring(e.reference), "Icons\\sb_compass\\sign.tga", interop.mcm.config.mrkSign.colour)
        elseif (type == tes3.objectType.npc) then
            if (interop.mcm.config.mrkTransport.enabled) then
                if (e.reference.baseObject.aiConfig.travelDestinations) then
                    table.insert(interop.mcm.distMarkers.far, e.reference)
                    interop.registerMarker(e.reference, tostring(e.reference), "Icons\\sb_compass\\travel.tga", interop.mcm.config.mrkTransport.colour)
                elseif (interop.mcm.config.mrkSpellsMerchant.enabled and e.reference.baseObject.aiConfig.merchantFlags == tes3.merchantService.spells) then
                    table.insert(interop.mcm.distMarkers.near, e.reference)
                    interop.registerMarker(e.reference, tostring(e.reference), "Icons\\sb_compass\\spells.tga", interop.mcm.config.mrkMerchant.colour)
                elseif (interop.mcm.config.mrkTrainMerchant.enabled and e.reference.baseObject.aiConfig.merchantFlags == tes3.merchantService.training) then
                    table.insert(interop.mcm.distMarkers.near, e.reference)
                    interop.registerMarker(e.reference, tostring(e.reference), "Icons\\sb_compass\\train.tga", interop.mcm.config.mrkMerchant.colour)
                elseif (interop.mcm.config.mrkSpellmakingMerchant.enabled and e.reference.baseObject.aiConfig.merchantFlags == tes3.merchantService.spellmaking) then
                    table.insert(interop.mcm.distMarkers.near, e.reference)
                    interop.registerMarker(e.reference, tostring(e.reference), "Icons\\sb_compass\\spellmaking.tga", interop.mcm.config.mrkMerchant.colour)
                elseif (interop.mcm.config.mrkEnchantmentMerchant.enabled and e.reference.baseObject.aiConfig.merchantFlags == tes3.merchantService.enchanting) then
                    table.insert(interop.mcm.distMarkers.near, e.reference)
                    interop.registerMarker(e.reference, tostring(e.reference), "Icons\\sb_compass\\enchantment.tga", interop.mcm.config.mrkMerchant.colour)
                elseif (interop.mcm.config.mrkRepairMerchant.enabled and e.reference.baseObject.aiConfig.merchantFlags == tes3.merchantService.repair) then
                    table.insert(interop.mcm.distMarkers.near, e.reference)
                    interop.registerMarker(e.reference, tostring(e.reference), "Icons\\sb_compass\\repair.tga", interop.mcm.config.mrkMerchant.colour)
                elseif (e.reference.baseObject.aiConfig.merchantFlags > 0) then
                    table.insert(interop.mcm.distMarkers.near, e.reference)
                    interop.registerMarker(e.reference, tostring(e.reference), "Icons\\sb_compass\\services.tga", interop.mcm.config.mrkMerchant.colour)
                end
            end
        elseif (interop.getFarSoon(e.reference.baseObject.id)) then
            local far = interop.getFarSoon(e.reference.baseObject.id)
            table.insert(interop.mcm.distMarkers.far, e.reference)
            interop.registerMarker(e.reference, tostring(e.reference), far[1], far[2])
        elseif (interop.getMidSoon(e.reference.baseObject.id)) then
            local mid = interop.getMidSoon(e.reference.baseObject.id)
            table.insert(interop.mcm.distMarkers.mid, e.reference)
            interop.registerMarker(e.reference, tostring(e.reference), mid[1], mid[2])
        elseif (interop.getNearSoon(e.reference.baseObject.id)) then
            local near = interop.getNearSoon(e.reference.baseObject.id)
            table.insert(interop.mcm.distMarkers.near, e.reference)
            interop.registerMarker(e.reference, tostring(e.reference), near[1], near[2])
        elseif (interop.getDynamicSoon(e.reference.baseObject.id)) then
            local dynamic = interop.getDynamicSoon(e.reference.baseObject.id)
            table.insert(interop.mcm.distMarkers.dyn, e.reference)
            interop.registerMarker(e.reference, tostring(e.reference), dynamic[1], dynamic[2])
        end
        for _, event in ipairs(interop.mcm.uiEvents) do
            if (event[1] == tes3.event.referenceActivated) then
                event[2](e)
            end
        end
    end
end

local function referenceDeactivatedCallback(e)
    if (interop.isCompassEnabled()) then
        interop.destroyMarker(e.reference)
        for _, event in ipairs(interop.mcm.uiEvents) do
            if (event[1] == tes3.event.referenceDeactivated) then
                event[2](e)
            end
        end
    end
end

local function objectInvalidatedCallback(e)
    if (interop.isCompassEnabled()) then
        if (e.object.objectType == tes3.objectType.reference) then
            referenceDeactivatedCallback({ reference = e.object })
        end
        for _, event in ipairs(interop.mcm.uiEvents) do
            if (event[1] == tes3.event.objectInvalidated) then
                event[2](e)
            end
        end
    end
end

local function simulateCallback(e)
    interop.getCompass().visible = interop.isCompassEnabled()
    if (interop.isCompassEnabled()) then
        if (interop.getRefreshState() == 1) then
            interop.mcm.uiRefreshState = 2
            for ref, _ in pairs(interop.mcm.uiMarkers) do
                referenceDeactivatedCallback({ reference = ref })
            end
            for _, cell in ipairs(tes3.getActiveCells()) do
                for ref in cell:iterateReferences() do
                    referenceActivatedCallback({ reference = ref })
                end
            end
            interop.mcm.uiRefreshState = 0
        elseif (interop.getRefreshState() == 0) then
            for _, ref in pairs(interop.mcm.distMarkers.far) do
                interop.getMarker(ref).marker.visible = true
                interop.updateMarkers(ref)
            end
            for _, ref in pairs(interop.mcm.distMarkers.mid) do
                local dist = math.sqrt(math.abs(ref.position.x - tes3.player.position.x) ^ 2 + math.abs(ref.position.y - tes3.player.position.y) ^ 2)
                if (dist <= 2 ^ interop.mcm.config.midDist) then
                    interop.getMarker(ref).marker.visible = true
                    interop.updateMarkers(ref)
                else
                    interop.getMarker(ref).marker.visible = false
                    interop.getMarker(ref).mini.visible = false
                end
            end
            for _, ref in pairs(interop.mcm.distMarkers.near) do
                local dist = math.sqrt(math.abs(ref.position.x - tes3.player.position.x) ^ 2 + math.abs(ref.position.y - tes3.player.position.y) ^ 2)
                if (dist <= 2 ^ interop.mcm.config.nearDist) then
                    interop.getMarker(ref).marker.visible = true
                    interop.updateMarkers(ref)
                else
                    interop.getMarker(ref).marker.visible = false
                    interop.getMarker(ref).mini.visible = false
                end
            end
            for _, ref in pairs(interop.mcm.distMarkers.dyn) do
                interop.updateMarkers(ref)
            end
            for _, event in ipairs(interop.mcm.uiEvents) do
                if (event[1] == tes3.event.simulate) then
                    event[2](e)
                end
            end
        end
    end
end

local function uiActivatedCallback(e)
    if (e.newlyCreated) then
        local multiMain = e.element:findChild(tes3ui.registerID("PartNonDragMenu_main"))
        interop.mcm.compass = multiMain:createRect { id = "sb_compass", color = interop.mcm.colours.black }
        interop.mcm.compass.width = tes3.worldController.viewWidth / 3
        interop.mcm.compass.height = 32 + 4
        interop.mcm.compass.absolutePosAlignX = 0.5
        interop.mcm.compass.absolutePosAlignY = 0.01
        interop.mcm.compass.alpha = 0.8

        local controlSpawnBorder = interop.mcm.compass:createThinBorder { id = tes3ui.registerID("sb_compass_border") }
        controlSpawnBorder.widthProportional = 1
        controlSpawnBorder.heightProportional = 1

        if (hudCustomiser) then
            hudCustomiser:registerElement("sb_compass", "Safebox's Compass", {
                positionX = interop.mcm.compass.absolutePosAlignX,
                positionY = interop.mcm.compass.absolutePosAlignY,
                width     = interop.mcm.compass.width,
                height    = interop.mcm.compass.height,
                visible   = true
            }, {
                position   = true,
                size       = true,
                visibility = false
            })
        end
    end
    for _, event in ipairs(interop.mcm.uiEvents) do
        if (event[1] == tes3.event.uiActivated) then
            event[2](e)
        end
    end
end

local function initializedCallback(e)
    event.register(tes3.event.objectInvalidated, objectInvalidatedCallback)
    event.register(tes3.event.simulate, simulateCallback)
    event.register(tes3.event.referenceActivated, referenceActivatedCallback)
    event.register(tes3.event.referenceDeactivated, referenceDeactivatedCallback)
    event.register(tes3.event.cellChanged, interop.refreshUI)
    event.register(tes3.event.loaded, interop.refreshUI)
    event.register(tes3.event.uiActivated, uiActivatedCallback, { filter = "MenuMulti" })
end
event.register("initialized", initializedCallback)
