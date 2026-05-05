local _, world           = pcall(require, "openmw.world")
local I                  = require("openmw.interfaces")
local types              = require("openmw.types")
local util               = require("openmw.util")
local acti               = require("openmw.interfaces").Activation
local minimumFactionRank = 3
local minimumFactionNPCs = 3
local factionChests      = {
    ["com_chest_02_mg_supply"] = "com_chest_02_mg_supply",
    ["com_chest_02_fg_supply"] = "com_chest_02_fg_supply",
}
local depositBoxes       = {}
local function addItem(obj, itemId, count)
    if count == 0 then
        return
    end
    if not obj then
        obj = world.players[1]
    end
    local newObj = world.createObject(itemId, count)
    newObj:moveInto(obj)
end

local function onObjectActive(obj)
    if obj.recordId == "zhac_marker_bankbal" then
        world.players[1]:sendEvent("OpenBankMenu")
        obj:remove()
    end
end
local function findHighestRankActor(NPC)
    local factionNumber = 0
    if NPC.type == types.Creature then
        return
    end
    local NPCFaction = types.NPC.getFactions(NPC)[1]
    local myRank = types.NPC.getFactionRank(NPC, NPCFaction)
    local cells = { NPC.cell }
    local actors = {}
    for i, x in ipairs(NPC.cell:getAll(types.Door)) do
        if types.Door.isTeleport(x) then
            local cell = types.Door.destCell(x)
            table.insert(cells, cell)
        end
    end
    for i, x in ipairs(cells) do
        for index, actor in ipairs(x:getAll(types.NPC)) do
            local fact = types.NPC.getFactions(actor)[1]
            if fact == NPCFaction then
                table.insert(actors, actor)
                factionNumber = factionNumber + 1
            end
            local myRank = types.NPC.getFactionRank(NPC, NPCFaction)
        end
    end
    if NPC.type == types.Creature then
        return nil, 0
    end
    local highestRankActor = NPC

    for index, actor in ipairs(actors) do
        local theirRank = types.NPC.getFactionRank(actor, NPCFaction)

        if NPCFaction == types.NPC.getFactions(actor)[1] and theirRank > myRank and not types.Actor.isDead(actor) and actor.enabled == true then
            myRank = theirRank
            highestRankActor = actor
        end
    end
    local rank = types.NPC.getFactionRank(highestRankActor, types.NPC.getFactions(highestRankActor)[1])
    if rank < minimumFactionRank then
        return nil, 0
    end
    return highestRankActor, factionNumber
end

local function isInFaction(id)
    local player = world.players[1]
    -- print(id)
    if types.NPC.isExpelled(player, id) then
        return false
    end
    for i, x in pairs(types.NPC.getFactions(player)) do
        if x == id then
            return true
        end
    end
    return false
end
local pickpocketing = false
local function NPCActivate(NPC, player, factio)
    
    local NPCFaction = factio or types.NPC.getFactions(NPC)[1]
    if not NPCFaction then
        world.mwscript.getGlobalVariables(world.players[1])["zhac_factionbank_state"] = 0
        return
    end
    local playerInFaction = false
    for index, value in ipairs(types.NPC.getFactions(player)) do
        if value == NPCFaction then
            playerInFaction = true
        end
    end
    if pickpocketing then
        world.mwscript.getGlobalVariables(world.players[1])["zhac_factionbank_state"] = 0
        return
        
    end
    local playerExpelled = false
    if playerInFaction then
        playerExpelled = types.NPC.isExpelled(player, NPCFaction)
    end
    local highestRankActor, actorCount = findHighestRankActor(NPC)

    if highestRankActor and playerInFaction and highestRankActor == NPC and actorCount > minimumFactionNPCs then
        --print(actorCount)
        if playerExpelled then
            world.mwscript.getGlobalVariables(world.players[1])["zhac_factionbank_state"] = 2
        else
            world.mwscript.getGlobalVariables(world.players[1])["zhac_factionbank_state"] = 1
            player:sendEvent("EnterTempMode", { actor = NPC, faction = NPCFaction })
        end
    elseif playerInFaction and not playerExpelled then
        world.mwscript.getGlobalVariables(world.players[1])["zhac_factionbank_state"] = 0
        player:sendEvent("EnterTempMode", { actor = NPC, faction = NPCFaction })
    else
        world.mwscript.getGlobalVariables(world.players[1])["zhac_factionbank_state"] = 0
    end
end
local function CreatureActivate(Crea, player)
    for index, actor in ipairs(Crea.cell:getAll(types.NPC)) do
        local theirFact = types.NPC.getFactions(actor)[1]
        if theirFact then
            NPCActivate(Crea, player, theirFact)
            return
        end
    end
end
local function getDepositBox(faction)
    if not depositBoxes[faction] then
        local newBox = world.createObject("de_p_chest_02_empty")
        newBox:teleport("toddtest", util.vector3(0, 0, 0))
        depositBoxes[faction] = newBox.id
        return newBox
    else
        for index, value in ipairs(world.getCellById("toddtest"):getAll(types.Container)) do
            if value.id == depositBoxes[faction] then
                return value
            end
        end
    end
end
local function openDepositBox(faction, box)
    faction = faction:lower()
    if not faction or faction == "" then
        return
    end
    if box then
        world.players[1]:sendEvent("openDepositBox", box)
        return
    end
    local box = getDepositBox(faction)
    if box then
        world.players[1]:sendEvent("openDepositBox", box)
    end
end
local function containerActivate(container, player)
    local faction = container.owner.factionId
    if faction and factionChests[container.recordId] and isInFaction(faction) then
        if not types.Container.content(container):isResolved() then
            types.Container.content(container):resolve()
        end
        local depositBox = getDepositBox(faction)
        for index, item in ipairs(types.Actor.inventory(container):getAll()) do
            item:moveInto(depositBox)
        end
        openDepositBox(faction, depositBox)
        return false
    end
end
local function createVoucher(data)
    local amount = data.amount
    local adjustedAmount = math.floor(amount)
    if adjustedAmount == 0 then
        return
    end
    local recordDraft = types.Book.createRecordDraft
        { template = types.Book.records["text_paper_roll_01"],
            name = "Bank Balance Transfer Voucher",
            weight = 0.1,
            text = "<DIV ALIGN=\"CENTER\"><FONT COLOR=\"000000\" SIZE=\"3\" FACE=\"Magic Cards\"><BR>" .. "This voucher authorizes the transfer of the amount of " .. tostring(adjustedAmount) .. " into any desired account.<BR>" }
    local newRecord = world.createRecord(recordDraft)
    local newItem = world.createObject(newRecord.id)
    newItem:moveInto(world.players[1])
    world.players[1]:sendEvent("storeVoucherData", { adjustedAmount = adjustedAmount, itemId = newRecord.id })
end
acti.addHandlerForType(types.Creature, CreatureActivate)
acti.addHandlerForType(types.Container, containerActivate)
acti.addHandlerForType(types.NPC, NPCActivate)
return {
    interface = {},
    interfaceName = "ActiBank",
    engineHandlers = {
        onObjectActive = onObjectActive,
        onSave = function()
            return { depositBoxes = depositBoxes }
        end,
        onLoad = function(data)
            if data then
                depositBoxes = data.depositBoxes
            end
        end
    },
    eventHandlers = {
        SneakStateChanged = function (state)
            pickpocketing = state
            
        end,
        removeVouchers = function(items)
            for i, x in ipairs(items) do
                x:remove()
            end
        end,
        createVoucher = createVoucher,
        openDepositBox = openDepositBox,
        addItemEvent_FB = function(data)
            local obj = data.obj
            local itemId = data.itemId
            local count = data.count
            addItem(obj, itemId, count)
        end,
        removeItemEvent_FB = function(data)
            local obj = data.obj
            if not obj then
                obj = world.players[1]
            end
            local itemId = data.itemId
            local count = data.count
            local item = types.NPC.inventory(obj):find(itemId)
            if item then
                if item.count < count then
                    count = item.count
                end
                if item.count == count then
                    item:remove()
                elseif count > 0 then
                    item:remove(count)
                end
            end
        end
    }
}
