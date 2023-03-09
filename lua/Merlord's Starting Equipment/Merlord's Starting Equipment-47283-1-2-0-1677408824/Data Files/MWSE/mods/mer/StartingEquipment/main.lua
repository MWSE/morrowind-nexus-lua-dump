local presetClasses = require("mer.StartingEquipment.presetClasses")
local customClasses = require("mer.StartingEquipment.customClasses")

local function isBoots(itemObject)
    local isShoes = itemObject.objectType == tes3.objectType.clothing and itemObject.slot == tes3.clothingSlot.shoes
    local isBoots = itemObject.objectType == tes3.objectType.armor and itemObject.slot == tes3.armorSlot.boots
    return isShoes or isBoots
end

local function playerIsBeast()
    --if boots and beast race, skip
    local raceId = tes3.player.object.race.id:lower()
    local beastRaces = {
        ["argonian"] = true,
        ["khajiit"] = true,
    }
    return beastRaces[raceId] == true
end

local function canWear(itemObject)
    return not (playerIsBeast() and isBoots(itemObject))
end

local function isEquipment(itemObject)
    return itemObject.objectType == tes3.objectType.armor
        or itemObject.objectType == tes3.objectType.weapon
        or itemObject.objectType == tes3.objectType.clothing
end

local function addGear(gearList)
    for _, gear in ipairs(gearList) do
        local item = tes3.getObject(gear.item)
        if item then
            if not canWear(item) then
                tes3.addItem{
                    reference = tes3.player,
                    item = "gold_001",
                    count = item.value,
                    updateGUI = false,
                    playSound = false
                }
            else
                tes3.addItem{
                    reference = tes3.player,
                    item = item.id,
                    count = gear.count,
                    updateGUI = false,
                    playSound = false
                }
            end
        else
            mwse.log("%s does not exist", gear.item)
        end
    end
    tes3ui.forcePlayerInventoryUpdate()

    --Equip everything in inventory
    timer.delayOneFrame(function()
        for _, stack in pairs(tes3.player.object.inventory) do
            if isEquipment(stack.object) and canWear(stack.object) then
                tes3.mobilePlayer:equip{ item = stack.object, playSound = false }
            end
        end
        tes3.messageBox("Class based equipment and spells added.")
    end)
end

local function startClassGear()
    local class = tes3.player.object.class.id
    local gearList
    if presetClasses.pickGear[class] then
        gearList = presetClasses.pickGear[class]()
    else
        gearList = customClasses.pickGear()
    end
    addGear(gearList)

end

local charGen
local newGame
local checkingChargen
local function checkCharGen()
    if charGen.value == 10 then
        newGame = true
    elseif newGame and charGen.value == -1 then
        checkingChargen = false
        event.unregister("simulate", checkCharGen)
        timer.start{
            type = timer.simulate,
            duration = 0.7, --If clashes with char backgrounds, mess with this
            callback = startClassGear
        }
    end
end



local function loaded()
    newGame = nil --reset so we can check chargen state again
    charGen = tes3.findGlobal("CharGenState")
    --Only reregister if necessary. If new game was started during
    --  chargen of previous game, this will already be running
    if not checkingChargen then
        event.register("simulate", checkCharGen)
        checkingChargen = true
    end
end

event.register("loaded", loaded )