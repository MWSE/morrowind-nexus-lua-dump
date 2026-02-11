-- Pretty Loot --
-- OpenMW 50 --

local ui      = require("openmw.ui")
local util    = require("openmw.util")
local self    = require("openmw.self")
local types   = require("openmw.types")
local core    = require("openmw.core")
local I       = require("openmw.interfaces")
local storage = require("openmw.storage")

--------------------------------------------------
-- SETTINGS SECTIONS
--------------------------------------------------
local cfg          = storage.playerSection("SettingsPrettyLoot")
local cfgScale     = storage.playerSection("ScalingPrettyLoot")
local cfgBehavior  = storage.playerSection("BehaviorPrettyLoot")

--------------------------------------------------
-- CONFIG
--------------------------------------------------
local BASE_STAY_TIME  = 1.5
local QUEUE_SPEED_UP  = 0.6
local NEXT_ITEM_DELAY = 0.3

local lastInventory = {}
local activePopups  = {}
local popupQueue    = {}
local lastExitTime  = 0
local customQuestItems = {}

--------------------------------------------------
-- VISUALS
--------------------------------------------------
local BG_NORMAL = "textures/pretty_loot/popup_bg.dds"
local BG_QUEST  = "textures/pretty_loot/popup_quest_bg.dds"
local BG_MAGIC  = "textures/pretty_loot/popup_magic_bg.dds"
local BG_CRAFT  = "textures/pretty_loot/popup_craft_bg.dds"

local COLOR_QUEST  = util.color.rgb(0.95, 0.78, 0.35)
local COLOR_MAGIC  = util.color.rgb(0.55, 0.65, 1.0)
local COLOR_CRAFT  = util.color.rgb(0.55, 0.75, 0.55)
local COLOR_NORMAL = util.color.rgb(0.9, 0.9, 0.85)

--------------------------------------------------
-- QUEST LISTS
--------------------------------------------------
local function loadExternalQuestLists()
    customQuestItems = {} 
    local function merge(path)
        local ok, mod = pcall(require, path)
        if ok and type(mod) == "table" then
            for k, v in pairs(mod) do
                local id = (type(k) == "number") and v or k
                customQuestItems[string.lower(tostring(id))] = true
            end
        end
    end
    
    merge("scripts.YourModName.quest_index")
    merge("scripts.OwnlysQuickLoot.ql_questItems")
    merge("scripts.OwnlysQuickLoot.ql_questItems_ONLY_MISC_AND BOOK")
end

--------------------------------------------------
-- ITEM DATA
--------------------------------------------------
local function getItemData(recordId)
    local lowerId = string.lower(tostring(recordId))

    if customQuestItems[lowerId] then
        for _, t in ipairs({
            types.Miscellaneous, types.Book, types.Weapon,
            types.Armor, types.Clothing, types.Potion
        }) do
            local rec = t.record(recordId)
            if rec then return rec, BG_QUEST, COLOR_QUEST end
        end
    end

    local ingre = types.Ingredient.record(recordId)
    if ingre then
        return ingre, BG_CRAFT, COLOR_CRAFT
    end

    local misc = types.Miscellaneous.record(recordId)
    if misc then
        if lowerId:find("ore") or lowerId:find("raw_") or lowerId:find("ingot") 
           or lowerId:find("scrap") or lowerId:find("pelt") or lowerId:find("hide") then
            return misc, BG_CRAFT, COLOR_CRAFT
        end
    end

    for _, t in ipairs({
        types.Weapon, types.Armor, types.Clothing,
        types.Miscellaneous, types.Potion,
        types.Apparatus, types.Book, types.Light,
        types.Lockpick, types.Repair
    }) do
        local rec = t.record(recordId)
        if rec then
            local isMagical = rec.isMagical or (rec.enchant and rec.enchant ~= "")
            if isMagical then
                return rec, BG_MAGIC, COLOR_MAGIC
            end
            return rec, BG_NORMAL, COLOR_NORMAL
        end
    end
    return nil
end

--------------------------------------------------
-- INVENTORY SNAPSHOT
--------------------------------------------------
local function getInventorySnapshot()
    local inv = types.Actor.inventory(self)
    if not inv then return nil end
    local snap = {}
    for _, it in ipairs(inv:getAll()) do
        if it.recordId ~= "gold_001" then
            snap[it.recordId] = (snap[it.recordId] or 0) + it.count
        end
    end
    return snap
end

--------------------------------------------------
-- QUEUE
--------------------------------------------------
local function addPopupToQueue(recordId, amount)
    if amount < 0 then
        local stance = types.Actor.getStance(self)
        if stance == types.Actor.STANCE.Weapon then
            local inv = types.Actor.inventory(self)
            local item = inv:find(recordId)
            
            if item and types.Actor.hasEquipped(self, item) then
                local weaponRec = types.Weapon.record(recordId)
                if weaponRec then
                    local wType = weaponRec.type
                    if wType == types.Weapon.TYPE.Arrow or 
                       wType == types.Weapon.TYPE.Bolt or 
                       wType == types.Weapon.TYPE.MarksmanThrown then
                        return
                    end
                end
            end
        end
    end

    for _, d in ipairs(popupQueue) do
        if d.recordId == recordId then
            d.rawAmount = d.rawAmount + amount
            return
        end
    end

    local rec, bg, itemColor = getItemData(recordId)
    if not rec then return end
    
    local useColorsSetting = cfgBehavior:get("useColors")
    if useColorsSetting == nil then useColorsSetting = true end 
    local displayColor = useColorsSetting and itemColor or COLOR_NORMAL
    local textColor = (amount < 0) and util.color.rgb(1, 0.2, 0.2) or displayColor

    table.insert(popupQueue, {
        recordId  = recordId,
        rawAmount = amount,
        icon      = rec.icon,
        name      = rec.name,
        bg        = bg,
        textColor = textColor
    })
end

--------------------------------------------------
-- SPAWN (LEFT SIDE)
--------------------------------------------------
local function spawnPopup(data, baseX, baseY, scale)
    local fontSize = cfgScale:get("fontScale") or 18 
    local sideVal = cfg:get("side")
    local isRight = (sideVal == 2)
	local isLoss = data.rawAmount < 0
    local absAmount = math.abs(data.rawAmount)
	
	local text
          if absAmount == 1 then
          text = (isLoss and "- " or "") .. data.name
          else
    local prefix = isLoss and "" or "+"
          text = prefix .. data.rawAmount .. " " .. data.name
    end

    return {
        element = ui.create {
            layer = "HUD",
            props = {
                relativePosition = util.vector2(baseX, baseY),
                anchor = util.vector2(isRight and 1 or 0, 0),
                size = util.vector2(350, 45),
            },
            content = ui.content {
                { 
                    type = ui.TYPE.Image,
                    props = {
                        resource = ui.texture { path = data.bg },
                        relativeSize = util.vector2(1, 1),
                        color = util.color.rgba(data.textColor.r, data.textColor.g, data.textColor.b, 0.25)
                    }
                },
                { 
                    type = ui.TYPE.Image,
                    props = {
                        resource = ui.texture { path = data.icon },
                        size = util.vector2(34, 34),
                        relativePosition = util.vector2(0.02, 0.5),
                        anchor = util.vector2(0, 0.5)
                    }
                },
                { -- Scaled Text
                    type = ui.TYPE.Text,
                    props = {
                        text = text, -- FIX: Changed 'data.name' to 'text'
                        textSize = fontSize,
                        textColor = data.textColor,
                        textShadow = true,
                        relativePosition = util.vector2(0.15, 0.5),
                        anchor = util.vector2(0, 0.5)
                    }
                }
            }
        },
        currentX = isRight and 350 or -350,
        exitStartedTime = nil
    }
end

--------------------------------------------------
-- ENGINE
--------------------------------------------------
return {
    engineHandlers = {
onInit = function()
    loadExternalQuestLists()
    lastInventory = getInventorySnapshot() or {}
end,

onLoad = function(data)
    loadExternalQuestLists()
    lastInventory = getInventorySnapshot() or {}
    for _, p in ipairs(activePopups) do if p.element then p.element:destroy() end end
    activePopups = {}
    popupQueue = {}
end,

        onFrame = function(dt)
            if not cfg:get("enabled") then return end

            local MAX_ON_SCREEN = cfgBehavior:get("maxOnScreen") or 4
            local SPACING       = cfgBehavior:get("spacing") or 45
            local SLIDE_SPEED   = cfgBehavior:get("slideSpeed") or 8.0
            local FADE_DURATION = cfgBehavior:get("fadeDuration") or 1.0
            local uiScale       = storage.globalSection("SettingsGUI"):get("scaling factor") or 1.0
            local scale = uiScale

            local baseX, baseY
            if cfg:get("pinToCorner") then
                local cornerIdx = cfg:get("corner")
                if cornerIdx == 1 then baseX, baseY = 0.185, 0.02      -- TL
                elseif cornerIdx == 2 then baseX, baseY = 1.0, 0.02  -- TR
                elseif cornerIdx == 3 then baseX, baseY = 0.185, 0.82  -- BL
                else baseX, baseY = 1.0, 0.82 end                    -- BR
            else
                local isDialogue = I.UI.getMode() == "Dialogue" or I.UI.getMode() == "Container"
                local sideSetting = cfg:get("side")
                baseX = (sideSetting == 2) and 1.0 or 0.0
                baseY = isDialogue and 0.01 or 0.6
            end

            local inv = getInventorySnapshot()
            if inv then

            for id, c in pairs(inv) do
            local prev = lastInventory[id] or 0
            if c ~= prev then 
            addPopupToQueue(id, c - prev) 
                end
            end

            for id, prev in pairs(lastInventory) do
            if not inv[id] then 
            addPopupToQueue(id, -prev) 
                end
            end
            lastInventory = inv
            end

            local time = core.getSimulationTime()

            if #activePopups < MAX_ON_SCREEN and #popupQueue > 0 then
                if time > lastExitTime + NEXT_ITEM_DELAY then
                    local data = table.remove(popupQueue, 1)
                    table.insert(activePopups, spawnPopup(data, baseX, baseY, scale))
                end
            end

            for i = #activePopups, 1, -1 do
                local p = activePopups[i]
                local targetY = (i - 1) * SPACING * scale
                local alpha = 1.0

                if p.currentX ~= 0 then
                    p.currentX = p.currentX - (p.currentX * SLIDE_SPEED * dt)
                    if math.abs(p.currentX) < 1 then p.currentX = 0 end
                end

                if i == 1 then
                    if not p.exitStartedTime then p.exitStartedTime = time end
                    local stay = (#popupQueue > 3) and QUEUE_SPEED_UP or BASE_STAY_TIME
                    if time - p.exitStartedTime > stay then
                        alpha = 1.0 - ((time - p.exitStartedTime - stay) / FADE_DURATION)
                    end
                    if alpha <= 0 then
                        p.element:destroy()
                        table.remove(activePopups, 1)
                        lastExitTime = time
                    end
                end

                if p.element and p.element.layout then
                    p.element.layout.props.alpha = alpha
                    p.element.layout.props.relativePosition = util.vector2(baseX, baseY)
                    p.element.layout.props.position = util.vector2(p.currentX * scale, targetY)
                    p.element:update()
                end
            end
        end
    }
}