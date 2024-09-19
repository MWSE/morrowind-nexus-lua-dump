local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("backpackController")
local BackpackService = require("mer.joyOfPainting.items.Backpack")

--register backpack slot if it doesn't exist
pcall(function() tes3.addClothingSlot{
    slot = BackpackService.BACKPACK_SLOT, name = "Backpack"
} end)

local function onEquipped(e)
    -- must be a valid backpack
    local isValid = config.backpacks[e.item.id]
    if not isValid then
        return
    end
    -- get parent for attaching
    local parent = e.reference.sceneNode:getObjectByName("Bip01 Spine1")
    -- detach old backpack mesh
    BackpackService.detachBackpack(parent)
    -- attach new backpack mesh
    BackpackService.attachBackpack(e.reference, e.item.id)
    -- update parent scene node
    parent:update()
    parent:updateNodeEffects()
end
event.register("equipped", onEquipped)

local function onUnequipped(e)
    -- must be a valid backpack
    local isValid = config.backpacks[e.item.id]
    if not isValid then return end
    -- get parent for detaching
    local parent = e.reference.sceneNode:getObjectByName("Bip01 Spine1")
    -- detach old backpack mesh
    BackpackService.detachBackpack(parent)
    -- update parent scene node
    parent:update()
    parent:updateNodeEffects()
end
event.register("unequipped", onUnequipped)

local function onMobileActivated(e)
    if e.reference.object.equipment then
        for _, stack in pairs(e.reference.object.equipment) do
            onEquipped{reference=e.reference, item=stack.object}
        end
    end
end
event.register("mobileActivated", onMobileActivated)


local function onLoaded(e)
    onMobileActivated{reference=tes3.player}
    for i, cell in ipairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences(tes3.objectType.npc) do
            onMobileActivated{reference=ref}
        end
    end
end
event.register("loaded", onLoaded)

local function updatePlayer()
    logger:trace("updating player backpack")
    if tes3.player and tes3.player.mobile then
        --check for existing backpack and equip it
        local equippedBackpack = tes3.getEquippedItem{
            actor = tes3.player,
            objectType = tes3.objectType.armor,
            slot = BackpackService.BACKPACK_SLOT
        }
        if equippedBackpack then
            logger:trace("re-equipping %s", equippedBackpack.object.name)
            onEquipped{reference = tes3.player, item = equippedBackpack.object}
        end

        equippedBackpack = tes3.getEquippedItem{
            actor = tes3.player,
            objectType = tes3.objectType.clothing,
            slot = BackpackService.BACKPACK_SLOT
        }
        if equippedBackpack then
            logger:trace("re-equipping %s", equippedBackpack.object.name)
            onEquipped{reference = tes3.player, item = equippedBackpack.object}
        end
    else
        logger:trace("player doesn't exist")
    end
end

event.register("itemDropped", updatePlayer)
event.register("menuEnter", updatePlayer)
event.register("menuExit", updatePlayer)
event.register("weaponReadied", updatePlayer)
event.register("Ashfall:triggerPackUpdate", updatePlayer)