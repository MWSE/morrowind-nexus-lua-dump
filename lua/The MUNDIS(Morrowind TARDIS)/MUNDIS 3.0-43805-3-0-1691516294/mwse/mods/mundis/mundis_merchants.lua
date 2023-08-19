local merchantState = nil
--nil == not placed
--1 == placed but not recrited
--2 = recruited but not moved
--3 = recruited and moved
local merchants = {}
local merchantDoorMessages = {
    mundis_servicedoor_magic  = {
        message =
        "You need to hire some shopkeepers to run the magic shop. Look around the Mages Guilds around Morrowind.",
        merchant = "mundis_merchant1",
        cell = "Vivec, Guild of Mages",
        placePos = tes3vector3.new(3445.288, 1725.453, 12206.391),
        merchant2 = "mundis_merchant5",
    },
    mundis_servicedoor_armory = {
        message = "You need to hire some shopkeepers to run the armory. Look in the Fighters Guilds around Morrowind.",
        merchant = "mundis_merchant4",
        cell = "Balmora, Guild of Fighters",
        merchant2 = "mundis_merchant6",
        placePos = tes3vector3.new(5119.492, 3199.838, 12189.459)
    },
    mundis_servicedoor_healer = {
        message = "You need to hire a healer to run the temple. Look around the Tribunal Temples around Morrowind.",
        merchant = "mundis_merchant2",
        cell = "Ald-ruhn, Temple",
        placePos = tes3vector3.new(3700.073, 3084.537, 12167.409)
    },
    mundis_servicedoor_shrine = {
        message = "You need to hire a priest to run the shrine. Look around the Imperiel Cults around Morrowind.",
        merchant = "mundis_merchant8",
        cell = "Sadrith Mora, Wolverine Hall: Imperial Shrine",
        placePos = tes3vector3.new(3398.693, 4258.023, 12167.409)
    },
    mundis_servicedoor_trader = {
        message =
        "You need to hire some shopkeepers to run the Trader. Ask around taverns and inns about a trader for hire.",
        merchant = "mundis_merchant3",
        cell = "Balmora, South Wall Cornerclub",
        merchant2 = "mundis_merchant7",
        placePos = tes3vector3.new(5237.632, 2472.814, 12193.796)
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
    if tes3.player.data.merchantState[recordId:lower()] == nil then
        tes3.player.data.merchantState[recordId:lower()] = 1
        local newReference = tes3.createReference({
            object = recordId,
            position = pos,
            cell = cell,
            orientation = tes3vector3.new(0, 0, 0)
        })
        for index, value in pairs(merchantDoorMessages) do
            if value.merchant:lower() == recordId:lower() and value.merchant2 ~= nil then
                print("Killing SM " .. value.merchant2)
                local secondMerch = tes3.getReference(value.merchant2)
                secondMerch:disable()
            else
                print("No merch for  " .. value.merchant)
            end
        end
    end
end
function merchants.placeMerchantsInWorld()
    if not tes3.player.data.merchantState then
        tes3.player.data.merchantState = {}
    else
        --  return
    end
    placeObject("mundis_merchant4", "Balmora, Guild of Fighters", tes3vector3.new(263.197418, -267.434143, -344.509888))
    placeObject("mundis_merchant3", "Balmora, South Wall Cornerclub",
        tes3vector3.new(246.808472, 826.250427, -243.604965))
    placeObject("mundis_merchant8", "Sadrith Mora, Wolverine Hall: Imperial Shrine",
        tes3vector3.new(-144.633286, 428.074860, -65.453407))
    placeObject("mundis_merchant1", "Vivec, Guild of Mages", tes3vector3.new(-512.232483, 746.159851, -426.591797))
    placeObject("mundis_merchant2", "Ald-ruhn, Temple", tes3vector3.new(4064.386719, 4108.393066, 14738.716797))
end

local function doorActivate(e)
    local id = e.target.object.id:lower()

    if merchantDoorMessages[id] then
        if tes3.player.data.merchantState[merchantDoorMessages[id].merchant] < 2 then
            tes3.messageBox({
                message = merchantDoorMessages[id].message, buttons = { "OK" } })
            return false
        end
    end
    if not tes3.player.data.merchantState and id == "mundis_3_enterdoor" then
        merchants.placeMerchantsInWorld()
    end
end
local function onObjectActive(obj)
    if obj.recordId == "zhac_mwbridge_x" then
        for index, value in pairs(merchantDoorMessages) do
            if value.cell == obj.cell.name then
                tes3.player.data.merchantState[value.merchant] = 2
            end
        end
    elseif merchantDoorMessages[obj.recordId] then
        local merchantId = merchantDoorMessages[obj.recordId].merchant
        if tes3.player.data.merchantState[merchantId] == 2 then
            local actor = findActorById(merchantDoorMessages[obj.recordId].cell, merchantId)
            if actor then actor:teleport(obj.cell, merchantDoorMessages[obj.recordId].placePos) end
            tes3.player.data.merchantState[merchantId] = 3
        end
    end
end
local function cellChanged(e)
    local cell = tes3.player.cell
    local cellName = cell.name:lower()
    if cellName == "mundis services hall" then
        for index, value in pairs(tes3.player.data.merchantState) do
            if value == 2 then
                for findex, fvalue in pairs(merchantDoorMessages) do
                    if fvalue.merchant:lower() == index:lower() then
                        if fvalue.merchant2 ~= nil then
                            local secondMerch = tes3.getReference(fvalue.merchant2)
                            secondMerch:enable()
                        end
                        local firstMerch = tes3.getReference(fvalue.merchant)
                        tes3.positionCell({ reference = firstMerch, position = fvalue.placePos,cell = cellName })
                        firstMerch:enable()
                        tes3.player.data.merchantState[fvalue.merchant] = 3
                    end
                end
            end
        end
    end
end

event.register(tes3.event.cellChanged, cellChanged)
event.register(tes3.event.activate, doorActivate)
return merchants
