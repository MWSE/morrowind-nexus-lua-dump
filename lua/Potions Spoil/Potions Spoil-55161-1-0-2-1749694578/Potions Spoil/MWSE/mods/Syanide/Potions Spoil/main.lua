local config = require("Syanide.Potions Spoil.config") -- Adjust path as needed

local pickedUpPotions = {}
local saveKey

-- Replace unsafe filename characters (like spaces, slashes, etc.)
local function sanitizeFileName(name)
    return name:gsub("[^%w_-]", "_")
end

-- Build a per-character config key
local function getSaveKeyForPlayer()
    local playerName = tes3.player.object.name
    return "PotionsSpoil_" .. sanitizeFileName(playerName)
end

-- Load timestamps from disk using MWSE's built-in config system
local function loadPotionData()
    pickedUpPotions = mwse.loadConfig(saveKey) or {}
    mwse.log("[Potions Spoil] Loaded potion data for '%s'", saveKey)
end

-- Save timestamps to disk
local function savePotionData()
    mwse.saveConfig(saveKey, pickedUpPotions)
    mwse.log("[Potions Spoil] Saved potion data for '%s'", saveKey)
end

local function onActivate(e)
    if (e.activator == tes3.player) and (e.target.object.objectType == tes3.objectType.alchemy) then
        local potion = e.target
        local currentTime = tes3.getSimulationTimestamp()
        if not config.blacklist[potion.id] and not string.find(potion.id, "_sp$") then
            pickedUpPotions[potion.id] = pickedUpPotions[potion.id] or {}
            table.insert(pickedUpPotions[potion.id], { time = currentTime })
            savePotionData()
        end
    end
end

local function scanInventoryForNewPotions()
    local currentTime = tes3.getSimulationTimestamp()

    for _, stack in pairs(tes3.player.object.inventory) do
        local item = stack.object

        if item.objectType == tes3.objectType.alchemy and not config.blacklist[item.id] and not string.find(item.id, "_sp$") then
            local trackedList = pickedUpPotions[item.id] or {}

            local newCount = stack.count - #trackedList
            if newCount > 0 then
                for _ = 1, newCount do
                    table.insert(trackedList, { time = currentTime })
                end
                pickedUpPotions[item.id] = trackedList
                savePotionData()
            end
        end
    end
end


local function checkPotionSpoiling()
    local currentTime = tes3.getSimulationTimestamp()
    local spoilTime = config.spoilTime

    for potionID, potionList in pairs(pickedUpPotions) do
        local potionObject = tes3.getObject(potionID)
        if not potionObject then
            pickedUpPotions[potionID] = nil
        else
            -- Get how many the player currently has
            local playerCount = tes3.getItemCount({ reference = tes3.player, item = potionObject })

            -- Remove oldest records if more timestamps than playerCount
            while #potionList > playerCount do
                table.remove(potionList, 1)
            end

            local spoiledCount = 0
            local stillFresh = {}

            for _, data in ipairs(potionList) do
                if currentTime - data.time >= spoilTime then
                    spoiledCount = spoiledCount + 1
                else
                    table.insert(stillFresh, data)
                end
            end

            if spoiledCount > 0 and playerCount > 0 then
                local spoiledPotion = tes3.getObject(potionID .. "_sp")
                if not spoiledPotion then
                    spoiledPotion = tes3.createObject({
                        objectType = tes3.objectType.alchemy,
                        id = potionID .. "_sp",
                        name = "Spoiled Potion",
                        mesh = potionObject.mesh,
                        icon = potionObject.icon,
                        weight = potionObject.weight,
                        value = 10,
                        effects = {
                            { id = 23, rangeType = tes3.effectRange.self, duration = 30, min = 50, max = 50 }
                        }
                    })
                end

                -- Spoil only up to how many the player actually owns
                local spoilCount = math.min(spoiledCount, playerCount)

                tes3.removeItem({ reference = tes3.player, item = potionObject, count = spoilCount })
                tes3.addItem({ reference = tes3.player, item = spoiledPotion, count = spoilCount, playSound = false })

                tes3.playSound({ sound = "potion fail" })
                tes3.messageBox("Some potions have spoiled!")
            end

            -- Save only remaining unspoiled potions
            if stillFresh == 0 then
                pickedUpPotions[potionID] = nil
            else
                pickedUpPotions[potionID] = stillFresh
            end
        end
    end

    savePotionData()
end





-- Initialize and load data once the player is available
local function initializeMod()
    if not tes3.player then return end
    saveKey = getSaveKeyForPlayer()
    loadPotionData()
    mwse.log("[Potions Spoil] Initialized for player: %s", tes3.player.object.name)
end

-- Use loaded event if player isn't ready during initialization
event.register("initialized", function()
    if tes3.player then
        initializeMod()
    else
        event.register("loaded", initializeMod)
    end
end)

event.register("activate", onActivate)
event.register("menuExit", scanInventoryForNewPotions)
event.register("simulate", checkPotionSpoiling)