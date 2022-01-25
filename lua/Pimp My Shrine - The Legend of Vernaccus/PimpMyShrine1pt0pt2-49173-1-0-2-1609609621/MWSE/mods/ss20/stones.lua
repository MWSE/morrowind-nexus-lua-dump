local common = require('ss20.common')
local config = common.config
local modName = config.modName

local function summonSeducer()
    local seducerRef = mwscript.placeAtPC{
        reference = tes3.player,
        object= 'ss20_seducer01',
        direction = 0
    }
    tes3.say{
        soundPath = "ss20\\laugh.wav", 
        subtitle = "*laughter*",
        reference = seducerRef
    }
end

local function incrementStones()
    local data = tes3.player.data[modName]
    data.stonesPickedUp = data.stonesPickedUp or 0
    data.stonesPickedUp = data.stonesPickedUp + 1
end

local function pickUpStone(e)
    local data = tes3.player.data[modName]
    local isStone = e.target.baseObject.id:lower() == 'ss20_w_stone'
    local atJournal = tes3.getJournalIndex{ id = 'ss20_main' } == 10
    local atLocation = (tes3.player.cell.region and tes3.player.cell.region.id == "Sheogorad")
    local outside = not tes3.player.cell.isInterior

    if isStone then
        common.log:debug("Is Stone")
        if atJournal then
            common.log:debug("At Journal")
            if atLocation and outside then
                common.log:debug("At location, incrementing stones")
                incrementStones()
                if data.stonesPickedUp == 5 then
                    common.log:debug("Picked up 5, summoning seducer")
                    summonSeducer()
                end
            end
        end
    end
end
event.register("activate", pickUpStone)

--[[
    Place a few extra stones in case the player already picked
    them all up before the quest
]]
local stones = {
    {
        position = {8190.80,180437.56,312.81},
        orientation = {0.00,0.00,1.90},
    },
    {
        position = {8142.70,180545.64,286.64},
        orientation = {0.00,0.30,1.30},
    },
    {
        position = {8155.78,180573.42,302.05},
        orientation = {0.00,0.00,2.12},
    },
    {
        position = {8168.12,180473.64,307.27},
        orientation = {0.00,0.30,5.38},
    },
    {
        position = {8150.51,180518.81,299.82},
        orientation = {0.00,0.00,1.57}
    }
}

local function placeExtraStones(e)
    local atJournal = tes3.getJournalIndex{ id = 'ss20_main' } == 10
    local data = tes3.player.data[modName]
    if atJournal and not data.extraStonesPlaced then
        for _, location in ipairs(stones) do
            tes3.createReference{
                object = 'ss20_w_stone',
                position = location.position,
                orientation = location.orientation,
                cell = "Vas",
                scale = 2
            }
        end
        data.extraStonesPlaced = true
    end
end
event.register("cellChanged", placeExtraStones)