-- Pretty Loot --
-- OpenMW 50 --
-- Credits: ownlyme  Huge thanks for the coding help and optimizations in update 1.4! :) --


local ui      = require("openmw.ui")
local util    = require("openmw.util")
local self    = require("openmw.self")
local types   = require("openmw.types")
local core    = require("openmw.core")
local I       = require("openmw.interfaces")
local storage = require("openmw.storage")
local async   = require("openmw.async")

--------------------------------------------------
-- SETTINGS SECTIONS
--------------------------------------------------
local cfg          = storage.playerSection("SettingsPrettyLoot")
local cfgScale     = storage.playerSection("ScalingPrettyLoot")
local cfgBehavior  = storage.playerSection("BehaviorPrettyLoot")

--------------------------------------------------
-- CONFIG
--------------------------------------------------
local BASE_STAY_TIME        = 1.5
local QUEUE_SPEED_UP        = 0.6
local NEXT_ITEM_DELAY       = 0.3

-- PERFORMANCE CONFIG
local frameCounter        = 0
local SCAN_FRAME_INTERVAL  = 10 

-- Chargen / Stability State
local isSafetyLockActive    = true 
local unpausedTimeTotal     = 0
local REQUIRED_STABILITY_TIME = 1.5

-- Mod State
local lastInventory         = {}
local activePopups          = {}
local popupQueue            = {}
local lastExitTime          = 0
local lastStanceState       = nil
local customQuestItems      = {}

--------------------------------------------------
-- TEXT BUILDER (Required for Stacking)
--------------------------------------------------
local function buildText(name, amount)
    local isLoss    = amount < 0
    local absAmount = math.abs(amount)
    if absAmount == 1 then
        return (isLoss and "- " or "") .. name
    else
        local prefix = isLoss and "" or "+"
        return prefix .. amount .. " " .. name
    end
end

--------------------------------------------------
-- VISUALS & DYNAMIC PATHS
--------------------------------------------------
local function getTexturePath(filename)
    local folderNum = cfg:get("textureFolder") or 1
    return string.format("textures/pretty_loot/%d/%s", folderNum, filename)
end

local function getBackgrounds()
    return {
        NORMAL = getTexturePath("popup_bg.dds"),
        QUEST  = getTexturePath("popup_quest_bg.dds"),
        MAGIC  = getTexturePath("popup_magic_bg.dds"),
        CRAFT  = getTexturePath("popup_craft_bg.dds")
    }
end

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

local function getItemData(recordId)
    local lowerId = string.lower(tostring(recordId))
    local bgs = getBackgrounds()

    if customQuestItems[lowerId] then
        for _, t in ipairs({
            types.Miscellaneous, types.Book, types.Weapon,
            types.Armor, types.Clothing, types.Potion
        }) do
            local rec = t.record(recordId)
            if rec then return rec, bgs.QUEST, COLOR_QUEST end
        end
    end

    local ingre = types.Ingredient.record(recordId)
    if ingre then
        return ingre, bgs.CRAFT, COLOR_CRAFT
    end

    local misc = types.Miscellaneous.record(recordId)
    if misc then
        if lowerId:find("ore") or lowerId:find("raw_") or lowerId:find("ingot") 
           or lowerId:find("scrap") or lowerId:find("pelt") or lowerId:find("hide") then
            return misc, bgs.CRAFT, COLOR_CRAFT
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
                return rec, bgs.MAGIC, COLOR_MAGIC
            end
            return rec, bgs.NORMAL, COLOR_NORMAL
        end
    end
    return nil
end

--------------------------------------------------
-- OPTIMIZED INVENTORY SNAPSHOT
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
-- QUEUE (With Search & Merge Stacking)
--------------------------------------------------
local function addPopupToQueue(recordId, amount)
    if recordId == "gold_001" then return end
    if cfgBehavior:get("disableDuringDialogue") and I.UI.getMode() == "Dialogue" then return end
    if amount < 0 and cfgBehavior:get("disableDropPopups") then return end

    -- STACK INTO ACTIVE SCREEN
    for _, row in ipairs(activePopups) do
        if row.recordId == recordId then
            row.rawAmount = row.rawAmount + amount
            row.text = buildText(row.name, row.rawAmount)
            row.needsRebuild = true
            row.exitStartedTime = core.getSimulationTime() 
            return 
        end
    end

    -- MERGE IN QUEUE
    for _, d in ipairs(popupQueue) do
        if d.recordId == recordId then
            d.rawAmount = d.rawAmount + amount
            d.timestamp = core.getSimulationTime()
            return
        end
    end
	
    -- AMMO FILTER
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
        textColor = textColor,
        timestamp = core.getSimulationTime()
    })
end



--------------------------------------------------
-- SCAN LOGIC (Async-Ready)
--------------------------------------------------
local function scanInventory()
    local snap = getInventorySnapshot()
    if snap then
        for id, c in pairs(snap) do
            local prev = lastInventory[id] or 0
            if c ~= prev then
                addPopupToQueue(id, c - prev)
            end
        end
        for id, prev in pairs(lastInventory) do
            if not snap[id] then
                addPopupToQueue(id, -prev)
            end
        end
        lastInventory = snap
    end
end

--------------------------------------------------
-- REBUILD ROW (The "Stacking" Engine)
--------------------------------------------------
local function rebuildRow(row)
    if row.element and row.element.layout then
        -- Find the Text Widget (Index 3 in content list)
        local textWidget = row.element.layout.content[3]
        
        -- Generate the new string using the updated rawAmount
        local newText = buildText(row.name, row.rawAmount)

        -- Update the text property
        textWidget.props.text = newText
        
        -- Signal the engine to redraw this specific popup
        row.element:update()
    end
    row.needsRebuild = false
end

--------------------------------------------------
-- SPAWN (Popup)
--------------------------------------------------
local function spawnPopup(data, baseX, baseY, scale, targetY)
    local fontSize = cfgScale:get("fontScale") or 18 
    local sideVal  = cfg:get("side")
    local isRight  = (sideVal == 2)
    
    -- Generate initial text
    local text = buildText(data.name, data.rawAmount)

    -- Create the UI element
    local createdElement = ui.create {
        layer = "HUD",
        props = {
            relativePosition = util.vector2(baseX, baseY),
            anchor = util.vector2(isRight and 1 or 0, 0),
            size = util.vector2(350, 45),
        },
        content = ui.content {
            { -- [1] Background
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = data.bg },
                    relativeSize = util.vector2(1, 1),
                    color = util.color.rgba(data.textColor.r, data.textColor.g, data.textColor.b, 0.4)
                }
            },
            { -- [2] Icon
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = data.icon },
                    size = util.vector2(34, 34),
                    relativePosition = util.vector2(0.02, 0.5),
                    anchor = util.vector2(0, 0.5)
                }
            },
            { -- [3] Text
                type = ui.TYPE.Text,
                props = {
                    text = text,
                    textSize = fontSize,
                    textColor = data.textColor,
                    textShadow = true,
                    relativePosition = util.vector2(0.15, 0.5),
                    anchor = util.vector2(0, 0.5)
                }
            }
        }
    }

    -- Return the object with metadata for the onFrame loop
    return {
        element         = createdElement,
        recordId        = data.recordId,    
        name            = data.name,        
        rawAmount       = data.rawAmount,   
        currentX        = isRight and 350 or -350,
        exitStartedTime = nil,
        lastAlpha       = 1.0,
        lastPosX        = isRight and 350 or -350,
        displayedY      = targetY,
        lastPosY        = targetY,
        needsRebuild    = false,            
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
            isSafetyLockActive = true 
            unpausedTimeTotal = 0
        end,

        onLoad = function(data)
            loadExternalQuestLists()
            lastInventory = getInventorySnapshot() or {}
            isSafetyLockActive = false
            -- Cleanup UI on load to prevent ghost popups
            for _, p in ipairs(activePopups) do 
                if p.element then p.element:destroy() end 
            end
            activePopups = {}
            popupQueue = {}
        end,

        onFrame = function(dt)
            local mode = I.UI.getMode() 
            local isPaused = core.isWorldPaused()
            local padding = cfgScale:get("sidePadding") or 0.01

            -- 1. DIALOGUE & SAFETY FILTERS
            if cfgBehavior:get("disableDuringDialogue") and mode == "Dialogue" then
                if #activePopups > 0 then
                    for _, p in ipairs(activePopups) do if p.element then p.element:destroy() end end
                    activePopups = {}
                end
                popupQueue = {}
                lastInventory = getInventorySnapshot() or {}
                return 
            end

            if isSafetyLockActive then
                if mode == nil and not isPaused then
                    unpausedTimeTotal = unpausedTimeTotal + dt
                    if unpausedTimeTotal >= REQUIRED_STABILITY_TIME then
                        isSafetyLockActive = false
                    end
                end
                return 
            end

            -- 2. PERFORMANCE: THROTTLED SCAN
            frameCounter = frameCounter + 1
            if frameCounter >= SCAN_FRAME_INTERVAL then
                scanInventory() 
                frameCounter = 0
            end

            -- 3. CHARGEN / GLOBAL ENABLE FILTERS
            if mode == "Name" or mode == "Race" or mode == "Class" or mode == "Birth" then
                isSafetyLockActive = true
                unpausedTimeTotal = 0
                return
            end

            if cfg:get("enabled") == false then
                if #activePopups > 0 then
                    for _, p in ipairs(activePopups) do p.element:destroy() end
                    activePopups = {}
                end
                popupQueue = {}
                lastInventory = getInventorySnapshot() or {}
                return
            end

            -- 4. CONFIG & SCALING
            local MAX_ON_SCREEN = cfgBehavior:get("maxOnScreen") or 4
            local SPACING       = cfgBehavior:get("spacing") or 45
            local SLIDE_SPEED   = cfgBehavior:get("slideSpeed") or 8.0
            local FADE_DURATION = cfgBehavior:get("fadeDuration") or 1.0
            local uiScale       = storage.globalSection("SettingsGUI"):get("scaling factor") or 1.0
            local scale         = uiScale
            local spacingScaled = SPACING * scale

            local baseX, baseY
            local sideSetting = cfg:get("side")
            local isRight = (sideSetting == 2)

            -- Handle Position
            if cfg:get("pinToCorner") then
                local cornerIdx = cfg:get("corner")
                if cornerIdx == 1 then     baseX, baseY = padding, 0.02          
                elseif cornerIdx == 2 then baseX, baseY = 1.0 - padding, 0.02  
                elseif cornerIdx == 3 then baseX, baseY = padding, 0.82          
                else                       baseX, baseY = 1.0 - padding, 0.82 end                      
            else
                baseX = isRight and (1.0 - padding) or padding
                baseY = (mode == "Dialogue" or mode == "Container") and 0.01 or 0.6
            end

            local time = core.getSimulationTime()

            -- 5. SPAWN NEXT POPUP 
            if #activePopups < MAX_ON_SCREEN and #popupQueue > 0 then
                if time > lastExitTime + NEXT_ITEM_DELAY then
                    local data = table.remove(popupQueue, 1)
                    
                    -- Calculate spawn target immediately to prevent "sliding down"
                    local nextIndex = #activePopups
                    local spawnTargetY = nextIndex * spacingScaled
                    
                    table.insert(activePopups, spawnPopup(data, baseX, baseY, scale, spawnTargetY))
                end
            end

            -- 6. RENDER LOOP (With Stacking Rebuild)
            for i = #activePopups, 1, -1 do
                local p = activePopups[i]
                local targetY = (i - 1) * spacingScaled
                
                -- UPDATE TEXT if stacking logic triggered a merge
                if p.needsRebuild then
                    rebuildRow(p)
                end

                -- Horizontal Slide Animation
                if p.currentX ~= 0 then
                    p.currentX = p.currentX - (p.currentX * SLIDE_SPEED * dt)
                    if math.abs(p.currentX) < 1 then p.currentX = 0 end
                end
				
                -- Vertical Smooth Scroll (Lerp)
                local lerpSpeed = 10.0 
                p.displayedY = p.displayedY + (targetY - p.displayedY) * math.min(1, dt * lerpSpeed)

                -- Fading Logic (Only for the top item)
                local alpha = 1.0
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
                        goto continue 
                    end
                end

                -- PERFORMANCE DIRTY CHECK
                if math.abs(alpha - p.lastAlpha) > 0.005 or 
                   math.abs(p.currentX - p.lastPosX) >= 0.5 or 
                   math.abs(p.displayedY - p.lastPosY) >= 0.5 then
                    
                    p.element.layout.props.alpha = math.max(0, math.min(1, alpha))
                    p.element.layout.props.relativePosition = util.vector2(baseX, baseY)
                    p.element.layout.props.position = util.vector2(p.currentX * scale, p.displayedY)
                    p.element:update()

                    p.lastAlpha = alpha
                    p.lastPosX = p.currentX
                    p.lastPosY = p.displayedY
                end

                ::continue::
            end
        end
    }
}