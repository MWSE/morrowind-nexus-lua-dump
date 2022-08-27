local config
local creeperRef
local creeperOriPos
local creeperOriRot
local creeperOriCell
local creeperSales = {}
local creeperLastSales = {}
local creeperDest = require("kindi.roaming creeper.destinations")
local creeperItem = require("kindi.roaming creeper.items")
local creeperRumors = require("kindi.roaming creeper.rumors")

local function removeLastSales()
    if creeperRef then
        for _, item in pairs(creeperLastSales) do
            tes3.removeItem {
                reference = creeperRef,
                item = item,
                playSound = false
            }
        end
        table.clear(creeperLastSales)
    end
end

local function setVars()
    creeperRef = tes3.getReference("scamp_creeper")
    creeperOriPos = creeperRef.position:copy()
    creeperOriRot = creeperRef.orientation:copy()
    creeperOriCell = creeperRef.cell

    creeperRef.object.aiConfig.bartersApparatus = true
    creeperRef.object.aiConfig.bartersLockpicks = true
    creeperRef.object.aiConfig.bartersProbes = true
    creeperRef.object.aiConfig.bartersClothing = true

    for _, stuff in pairs(creeperItem) do
        for _, item in pairs(stuff) do
            table.insert(creeperSales, item)
        end
    end
    for book in tes3.iterateObjects(tes3.objectType.book) do
        if book.type == tes3.bookType.scroll and book.enchantment then
            table.insert(creeperSales, book.id)
        end
    end
end

-- //teleportation vfx
local function placeVFX()
    if tes3.player.cell ~= creeperRef.cell then
        return
    end
    tes3.createReference {
        object = "sprigganup",
        position = creeperRef.position:copy(),
        orientation = creeperRef.orientation:copy(),
        cell = creeperRef.cell
    }
    tes3.playSound {
        sound = "conjuration hit",
        reference = creeperRef
    }
end

-- //the creeper roaming logic
local function timeToMove()

    -- if mod is turned off, roaming is disabled
    if not config.modActive then
        return
    end

    -- if creeper cannot be found, roaming is disabled
    if not creeperRef then
        creeperRef = tes3.getReference("scamp_creeper")
        if not creeperRef then
            return
        end
    end

    -- if creeper is under aifollow package, roaming is disabled
    if tes3.getCurrentAIPackageId {
        reference = creeperRef
    } == tes3.aiPackage.follow then
        return
    end

    -- if creeper is dead, paralysed, disabled or not valid, roaming is disabled
    if creeperRef.mobile and (not creeperRef.mobile.hasFreeAction or creeperRef.disabled or creeperRef.deleted) then
        return
    end

    -- if destination list is empty, roaming is disabled
    if not next(creeperDest) then
        return
    end

    -- set encumbrance of creeper so he doesn't get overencumbered
    if creeperRef.mobile then
        creeperRef.mobile.encumbrance.current = 0
    end

    -- reset creeper animation
    tes3.playAnimation {
        reference = creeperRef,
        startFlag = 1,
        loopCount = 0,
        group = tes3.animationGroup.idle
    }

    local dest = table.choice(creeperDest) -- //random choice of cell to travel to

    placeVFX()

    if creeperRef.data.roaming_creeper_day_tracker == 1 then
        tes3.positionCell {
            cell = creeperOriCell,
            reference = creeperRef,
            position = creeperOriPos,
            orientation = creeperOriRot
        }
        tes3.setAIWander {
            reference = creeperRef,
            idles = {0, 0, 0, 0, 0, 0, 0, 0},
        }
    else
        tes3.positionCell {
            cell = dest.cell,
            reference = creeperRef,
            position = dest.position,
            orientation = dest.position[4]
        }
        tes3.setAIWander {
            reference = creeperRef,
            idles = {0, 0, 0, 0, 0, 0, 0, 0},
            range = 1024 * math.random(0, 1) -- doesn't work? creeper doesn't move around
        }
        tes3.playAnimation {
            reference = creeperRef,
            startFlag = 1,
            loopCount = 0,
            group = tes3.animationGroup.knockOut
        }
    end

    placeVFX()

    if config.debug then
        tes3.messageBox("Creeper travels to %s", tes3.getCell{
            id = dest.cell
        }.name)
    end

    -- //removes last generated goods from the creeper
    removeLastSales()

    -- //add new items for sale
    for _, item in pairs(creeperSales) do
        if math.random(1000) < 100 then
            tes3.addItem {
                reference = creeperRef,
                item = item,
                playSound = false
            }
            table.insert(creeperLastSales, item)
        end
    end

    -- same as above but for wares integration
    if tes3.isModActive("Wares-base.esm") then
        for ware in tes3.iterateObjects(tes3.objectType.leveledItem) do
            if ware.id:startswith("aa_") then
                local item = ware:pickFrom()
                if item and math.random(1000) < 100 then
                    tes3.addItem {
                        reference = creeperRef,
                        item = item,
                        playSound = false
                    }
                    table.insert(creeperLastSales, item)
                end
            end
        end
    end
end

-- // still deciding between "Days" or "DaysPassed" global values
local function dayPassed()
    if creeperRef and creeperRef.data.roaming_creeper_day_tracker ~= tes3.findGlobal("Day").value then
        creeperRef.data.roaming_creeper_day_tracker = tes3.findGlobal("Day").value
        event.trigger("RC:Kindi_DayChanged")
    end
end

-- // force the creeper to run because he is walking at snails pace
local function forceRun()
    if creeperRef and creeperRef.mobile and not creeperRef.mobile.isRunning then
        creeperRef.mobile.isRunning = true
    end
end

local function discountCreeper(e)
    -- // to be decided
    -- // basically you meet certain conditions and you get cheaper prices from the creeper
end

local function onInfoGetText(e)
    if not creeperRef or not e.info.actor or e.info.actor.id ~= "scamp_creeper" then
        return
    end
    -- // Creeper says 'Hellloo Caldera..'' regardless of where he is actually. This takes care of that
    if e.info.type == tes3.dialogueType.greeting then
        e.text = e:loadOriginalText():gsub("Caldera", creeperRef.cell.name:match("[^,]+")):gsub("week", "day")
    end
end

local function latestRumors(e)
    if not creeperRef or not tes3.player or tes3.player.cell == creeperOriCell or not config.modActive then
        return
    end
    if tostring(e.info:findDialogue()):lower() ~= "latest rumors" then
        return
    end
    -- // Trying to avoid infos with scripts, got any other ways to do it?
    if math.random(100) < 33 and e.info.type == tes3.dialogueType.topic and e.info.objectFlags < 12 then
        if tes3ui.getServiceActor() and creeperRef.cell ~= tes3ui.getServiceActor().cell and
            creeperRef.cell.id:match(tes3ui.getServiceActor().cell.id:match("[^,]+")) then
            e.text =
                "The Creeper is in town. You might want to visit the local tavern. The scamp has some nice things for sale."
        else
            e.text = table.choice(creeperRumors):gsub("__CELL__", creeperRef.cell.name:match("[^,]+"))
        end
    end
end

event.register("infoGetText", latestRumors)
event.register("infoGetText", onInfoGetText)
event.register("calcBarterPrice", discountCreeper)
event.register("calcMoveSpeed", forceRun)
event.register("simulate", dayPassed)
event.register("initialized", setVars)
event.register("RC:Kindi_DayChanged", timeToMove)
event.register("RC:Kindi_ModOff", removeLastSales)

event.register("modConfigReady", function()
    config = require("kindi.roaming creeper.config")
    require("kindi.roaming creeper.mcm")
end)
