local config = require("Syanide.Potions Spoil.config") -- Adjust path as needed

local pickedUpPotions = {}

local function onActivate(e)
    if (e.activator == tes3.player) then
        if (e.target.object.objectType == tes3.objectType.alchemy) then
            local potion = e.target

            local currentTime = tes3.getSimulationTimestamp()
            if not config.blacklist[potion.id] then
                pickedUpPotions[potion.id] = currentTime
            end
        end
    end
end

local function onItemTileUpdated(e)
    if e.item.objectType == tes3.objectType.alchemy then
        local potion = e.item

        -- Check if the potion is already being tracked
        if not pickedUpPotions[potion.id] then
            local currentTime = tes3.getSimulationTimestamp()

            -- If the potion was not in the player's inventory, start tracking it now
            if not config.blacklist[potion.id] then
                pickedUpPotions[potion.id] = currentTime
            end
        end
    end
end

local function checkPotionSpoiling()
    local currentTime = tes3.getSimulationTimestamp()
    local spoilTime = config.spoilTime

    for potionID, pickUpTime in pairs(pickedUpPotions) do
        local count = tes3.getItemCount({ reference = tes3.player, item = potionID })
        if count > 0 and currentTime - pickUpTime >= spoilTime then
            local potion = tes3.getObject(potionID)

            if potion and not string.find(potion.name, "Spoiled") then
                local spoiledPotion = tes3.createObject({
                    objectType = tes3.objectType.alchemy,
                    id = potion.id .. "_sp",
                    name = "Spoiled Potion",
                    mesh = potion.mesh,
                    icon = potion.icon,
                    weight = potion.weight,
                    value = 10,
                    effects = { { id = 23, rangeType = tes3.effectRange.self, duration = 30, min = 50, max = 50 } }
                })

                tes3.removeItem({ reference = tes3.player, item = potionID, count = count })
                tes3.addItem({ reference = tes3.player, item = spoiledPotion, count = count, playSound = false })

                tes3.playSound({ sound = "potion fail" })
                tes3.messageBox("A potion has spoiled!")

                pickedUpPotions[potionID] = nil
            end
        end
    end
end

mwse.log("[Potions Spoil] Initialized!")

event.register("activate", onActivate)
event.register("itemTileUpdated", onItemTileUpdated)
event.register("simulate", checkPotionSpoiling)