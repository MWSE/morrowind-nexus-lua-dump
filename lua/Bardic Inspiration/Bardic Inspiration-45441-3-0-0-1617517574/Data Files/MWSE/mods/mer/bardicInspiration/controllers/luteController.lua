--[[
    This script finds all vanilla lutes the player may
    come across and converts them into playable lutes.
]]

local common = require("mer.bardicInspiration.common")
--In case the player has bought one from a merchant
local function switchLutesInInventory(from, to, count)
    timer.frame.delayOneFrame(function()
        tes3.removeItem{
            reference = tes3.player,
            item = from,
            playSound = false,
            count = count
        }
        tes3.addItem{
            reference = tes3.player,
            item = to,
            playSound = false,
            count = count
        }
    end)
end
local function onMenu()
    if not common.config.enabled then return end
    for vanillaID, replacementID in pairs(common.staticData.idMapping) do
        local luteCount = mwscript.getItemCount{ reference = tes3.player, item = vanillaID }
        if luteCount > 0 then
            switchLutesInInventory(vanillaID, replacementID, luteCount)
        end
    end
end
event.register("menuEnter", onMenu)
event.register("menuExit", onMenu)

--[[
    Remove a vanilla lute from the ground and replace it with a new one
]]
local function replaceLute(reference)
    if not common.config.enabled then return end
    if reference.disabled == true then return end
    local id = reference.baseObject.id
    if common.staticData.idMapping[id] then
        timer.delayOneFrame(function()
            common.log:debug("Replacing lute")
            local newLute = tes3.createReference{
                object = common.staticData.idMapping[id],
                position = reference.position,
                orientation = reference.orientation,
                cell = reference.cell
            }
            local itemData = reference.attachments.variables
            if itemData and itemData.owner then
                common.log:debug("Setting owner of new lute to %s", ( itemData.owner.name or itemData.owner.id) )
                tes3.setOwner{ reference = newLute, owner = itemData.owner }
            end
            mwscript.disable({ reference = reference})
        end)
    end
end

local function translateFloorLute(ref)
    local node = ref.sceneNode:getObjectByName("MER_LUTE")
    common.log:debug("translating floor sceneNode")
    node.translation.x = -3.5
    node.translation.y = 4.9
    node.translation.z = 6.0
    common.log:debug("rotating floor sceneNode")
    local rot = tes3matrix33.new()
    rot:fromEulerXYZ(math.rad(4), math.rad(89), math.rad(0))
    node.rotation = rot

    node.scale = 1.07
end

--[[
    Check for a vanilla lute placed in the world and switch it
]]
local function switchPlacedLute(e)
    if e.reference then
        local id = e.reference.baseObject.id:lower()
        if common.staticData.idMapping[id] then
            replaceLute(e.reference)
        end
        if  common.staticData.lutes[id] then
            common.log:debug("Switching to floor lute switch node")
            translateFloorLute(e.reference)
        end
    end
end
event.register("referenceSceneNodeCreated", switchPlacedLute)

--[[
    referenceSceneNodeCreated may not be triggered on load, so 
    iterate references manually
]]
local function checkLoadedLutes()
    for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.miscItem) do
        if common.staticData.idMapping[ref.baseObject.id] then
            replaceLute(ref)
        end
    end
end
event.register("BardicInspiration:DataLoaded", checkLoadedLutes)

local luteMesh
event.register("meshLoaded", function()
    luteMesh = tes3.loadMesh("mer_bard\\mer_lute.nif")
end, { doOnce = true })