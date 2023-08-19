local util = require("openmw.util")
local world = require("openmw.world")
local types = require("openmw.types")
local core = require("openmw.core")
local storage = require("openmw.storage")
local interfaces = require("openmw.interfaces")

local merchantState = nil
--nil == not placed
--1 == placed but not recrited
--2 = recruited but not moved
--3 = recruited and moved
local merchantDoorMessages = {
    mundis_servicedoor_magic  = {
        message =
        "You need to hire some shopkeepers to run the magic shop. Look around the Mages Guilds around Morrowind.",
        merchant = "mundis_merchant1",
        cell = "Vivec, Guild of Mages",
        placePos = util.vector3(3445.288, 1725.453, 12206.391)
    },
    mundis_servicedoor_armory = {
        message = "You need to hire some shopkeepers to run the armory. Look in the Fighters Guilds around Morrowind.",
        merchant = "mundis_merchant4",
        cell = "Balmora, Guild of Fighters",
        placePos = util.vector3(5119.492, 3199.838, 12189.459)
    },
    mundis_servicedoor_healer = {
        message = "You need to hire a healer to run the temple. Look around the Tribunal Temples around Morrowind.",
        merchant = "mundis_merchant2",
        cell = "Ald-ruhn, Temple",
        placePos = util.vector3(3700.073, 3084.537, 12167.409)
    },
    mundis_servicedoor_shrine = {
        message = "You need to hire a priest to run the shrine. Look around the Imperiel Cults around Morrowind.",
        merchant = "mundis_merchant8",
        cell = "Sadrith Mora, Wolverine Hall: Imperial Shrine",
        placePos = util.vector3(3398.693, 4258.023, 12167.409)
    },
    mundis_servicedoor_trader = {
        message =
        "You need to hire some shopkeepers to run the Trader. Ask around taverns and inns about a trader for hire.",
        merchant = "mundis_merchant3",
        cell = "Balmora, South Wall Cornerclub",
        placePos = util.vector3(5237.632, 2472.814, 12193.796)
    },
}
local function findActorById(catCell, containerName)
    local cell = world.getCellByName(catCell)
    for _, cont in ipairs(cell:getAll(types.NPC)) do
        local contName = cont.recordId
        if contName == containerName then
            return cont
        end
    end
end
local function placeObject(recordId, cell, pos)
    if merchantState[recordId:lower()] == nil then
        merchantState[recordId:lower()] = 1

        world.createObject(recordId):teleport(cell, pos)
    end
end
local function placeMerchantsInWorld()
    if not merchantState then
        merchantState = {}
    end
    placeObject("mundis_merchant4", "Balmora, Guild of Fighters", util.vector3(263.197418, -267.434143, -344.509888))
    placeObject("mundis_merchant3", "Balmora, South Wall Cornerclub", util.vector3(246.808472, 826.250427, -243.604965))
    placeObject("mundis_merchant8", "Sadrith Mora, Wolverine Hall: Imperial Shrine",
        util.vector3(-144.633286, 428.074860, -65.453407))
    placeObject("mundis_merchant1", "Vivec, Guild of Mages", util.vector3(-512.232483, 746.159851, -426.591797))
    placeObject("mundis_merchant2", "Ald-ruhn, Temple", util.vector3(4064.386719, 4108.393066, 14738.716797))
end

local function onLoad(data)
    if data then
        merchantState = data.merchantState
    end
    if merchantState == nil then
    end
end
local function onSave()
    return { merchantState = merchantState }
end

local function onActivate(object, actor)

end
local function doorActivate(object, actor)
    if merchantDoorMessages[object.recordId] then
        if not merchantState or not merchantState[merchantDoorMessages[object.recordId].merchant] or merchantState[merchantDoorMessages[object.recordId].merchant] < 2 then
            world.players[1]:sendEvent("showMessageMundis",
                merchantDoorMessages[object.recordId].message)
            return false
        end
    end
    
    if object.recordId == "mundis_3_enterdoor" then
        
    if merchantState == nil then
        placeMerchantsInWorld()
    end
    end
end
local function onObjectActive(obj)
    if obj.recordId == "zhac_mwbridge_x" then
        for index, value in pairs(merchantDoorMessages) do
            if value.cell == obj.cell.name then
                merchantState[value.merchant] = 2
            end
        end
    elseif merchantDoorMessages[obj.recordId] then
        local merchantId = merchantDoorMessages[obj.recordId].merchant
        if merchantState[merchantId] == 2 then
            local actor = findActorById(merchantDoorMessages[obj.recordId].cell, merchantId)
            if actor then actor:teleport(obj.cell, merchantDoorMessages[obj.recordId].placePos) end
            merchantState[merchantId] = 3
        end
    end
end

if core.API_REVISION > 29 then 
interfaces.Activation.addHandlerForType(types.Door, doorActivate)
end
return {
    interfaceName = "MundisMerchantSystem",
    interface = {
        version = 1,
        placeMerchantsInWorld = placeMerchantsInWorld
    },
    eventHandlers = {
    },
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
        onInit = onLoad,
        onObjectActive = onObjectActive,
        onActivate = onActivate,
    }
}
