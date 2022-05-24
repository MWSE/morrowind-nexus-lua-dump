local modInfo = require("WeightOfTheWorld.modInfo")
local config = require("WeightOfTheWorld.config")
local common = require("WeightOfTheWorld.common")
local mod = string.format("[%s %s]", modInfo.mod, modInfo.version)

local curStr, curEnd, curAgi

local function onInventoryCreated(e)
    if not e.newlyCreated then
        return
    end

    -- Override the display of encumbrance each time the inventory updates.
    e.element:registerAfter("update", function()
        if config.accurateDisplay then
            common.updateEncDisplay()
        end
    end)
end

local function onAtrChange(newStr, newEnd, newAgi)
    common.changeEnc(newStr, newEnd, newAgi)

    curStr = newStr
    curEnd = newEnd
    curAgi = newAgi
end

local function onEnterFrame()
    if not tes3.player then
        return
    end

    local newStr, newEnd, newAgi = common.getAttributes()

    if newStr ~= curStr
    or newEnd ~= curEnd
    or newAgi ~= curAgi then
        onAtrChange(newStr, newEnd, newAgi)
    end
end

local function onLoaded()
    local newStr, newEnd, newAgi = common.getAttributes()
    onAtrChange(newStr, newEnd, newAgi)
end

local function onInitialized()
    -- Without Attribute Effect Tweaks, max encumbrance would be reset to vanilla under certain circumstances, like
    -- being subject to a Restore Strength effect when strength is already at full.
    local attributeEffectTweaks = include("AttributeEffectTweaks.interop")
    local needMod = string.format("%s This mod requires Attribute Effect Tweaks. Please install Attribute Effect Tweaks to use this mod.", mod)

    if (not attributeEffectTweaks) or (not attributeEffectTweaks.enabled) then
        tes3.messageBox(needMod)
        mwse.log(needMod)
        return
    end

    event.register("loaded", onLoaded)
    event.register("enterFrame", onEnterFrame)
    event.register("uiActivated", onInventoryCreated, { filter = "MenuInventory" })
    mwse.log("%s initialized.", mod)
end

event.register("initialized", onInitialized)

local function onModConfigReady()
    dofile("WeightOfTheWorld.mcm")
end

event.register("modConfigReady", onModConfigReady)