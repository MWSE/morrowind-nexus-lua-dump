local core      = require("openmw.core")
local self      = require("openmw.self")
local types     = require('openmw.types')
local nearby    = require('openmw.nearby')
local storage   = require('openmw.storage')
local async     = require('openmw.async')
local input     = require('openmw.input')
local util      = require('openmw.util')
local ui        = require('openmw.ui')
local I         = require('openmw.interfaces')
local debug     = require('openmw.debug')

local settings        = storage.playerSection("SettingsQuickSelect")
local mouseSettings   = storage.playerSection("SettingsQuickSelectMouse")
local gamepadSettings = storage.playerSection("SettingsQuickSelectGamepad")
local keyboardSettings= storage.playerSection("SettingsQuickSelectKeyboard")
local colorSettings   = storage.playerSection("SettingsQuickSelectColors") or {}
local dimensionsSettings = storage.playerSection("SettingsQuickSelectDimensions")

local tooltipData = require("scripts.QuickSelect.ci_tooltipgen")
local utility     = require("scripts.QuickSelect.qs_utility")

-- INTERNAL STATE --------------------------------------------------------------
local hotBarElement
local tooltipElement
local num                = 1
local enableHotbar       = false
local pickSlotMode       = false
local controllerPickMode = false
local selectedNum        = 1
local uiVisible          = true

-- BAR CONSTANTS ---------------------------------------------------------------
local DataBarHeight  = dimensionsSettings:get("dataBarHeight") or 7        -- +1 px
local ConditionColor = colorSettings:get("conditionColor") or util.color.rgb(0.90, 0.20, 0.15)
local ChargeColor    = colorSettings:get("chargeColor") or util.color.rgba(0.50, 0.60, 0.90, 1.00)

--------------------------------------------------------------------------------
-- GENERIC PROGRESS BAR --------------------------------------------------------
--------------------------------------------------------------------------------
local function createSmallProgressBar(width, height, color, percent, opacity)
    local p = percent and math.max(0, math.min(1, percent)) or 1
    return {
        template = I.MWUI.templates.boxSolid,
        type     = ui.TYPE.Container,
        props    = { color = util.color.rgba(0, 0, 0, 0), alpha = opacity or 1.0 },
        content  = ui.content({
            {
                type  = ui.TYPE.Widget,
                props = {
                    size   = util.vector2(width - 4, height - 4),
                },
                content = ui.content({
                    {
                        type  = ui.TYPE.Image,
                        props = {
                            alpha  = 1.0,
                            color  = util.color.rgb(color.r, color.g, color.b),
                            size   = util.vector2((width - 4) * p, height - 4),
                            resource = ui.texture{
                                path   = 'textures/menu_bar_gray.dds',
                                size   = util.vector2(1, 8),
                                offset = util.vector2(0, 0)
                            }
                        }
                    }
                })
            }
        })
    }
end

--------------------------------------------------------------------------------
-- createHotbarItem  (bars flush, height equalised) ---------------------------
--------------------------------------------------------------------------------
local function createHotbarItem(item, xicon, num, data, half)
    -- icon sizing ------------------------------------------------------------
    local sizeX, sizeY = utility.iconSize, utility.iconSize
    if half then sizeY = sizeY / 2 end

    -- pick correct icon ------------------------------------------------------
    local icon
    local isEquipped = I.QuickSelect_Storage.isSlotEquipped(num)
    local drawNumber = settings:get("showNumbersForEmptySlots")
    local selectedPage = 0
    if I.QuickSelect then selectedPage = I.QuickSelect.getSelectedPage() end
    local offset     = selectedPage * 10
    local selected   = controllerPickMode and (num == (selectedNum + offset))

    if item and not xicon then
        icon = I.Controller_Icon_QS.getItemIcon(item, half, selected)
    elseif xicon then
        icon = I.Controller_Icon_QS.getSpellIcon(xicon, half, selected)
    else
        icon = I.Controller_Icon_QS.getEmptyIcon(half, num, selected, drawNumber)
    end

    -- inner icon (no padding) -----------------------------------------------
    local innerIcon = utility.renderItemBoxed(
        icon,
        util.vector2(sizeX * 1.5, sizeY * 1.5),
        nil,
        util.vector2(0.5, 0.5),
        1.0
    )

    -- outer padded/bordered box ---------------------------------------------

    local itemBox = utility.renderItemBoxed(
        ui.content({ innerIcon }),
        util.vector2(sizeX * 1.5, sizeY * 1.5),
        I.MWUI.templates.padding,
        util.vector2(0.5, 0.5),
        1.0
    )

    if isEquipped or selected then
        local equippedOpacity = colorSettings:get("equippedItemOpacity") or 1.00
        itemBox = {
            type = ui.TYPE.Container,
            props = { alpha = 1.0 },
            content = ui.content({
                {
                    template = I.MWUI.templates.borders,
                    props = { size = util.vector2(sizeX * 1.5 + 4, sizeY * 1.5 + 4), alpha = 1.0 },
                    content = ui.content({
                        {
                            template = I.MWUI.templates.borders,
                            props = { size = util.vector2(sizeX * 1.5, sizeY * 1.5), alpha = 1.0 },
                            content = ui.content({ itemBox })
                        }
                    })
                }
            })
        }
    end

    -- build bars / placeholders ---------------------------------------------
    local barsContent = {}
    local rec, itemData = nil, nil
    if item then
        rec      = item.type.records[item.recordId]
        if not item.isFake then
            itemData = types.Item.itemData(item)
        end
    end

    -- cond bar / charge bar --------------------------------------------------
    -- Projectiles (arrows, bolts, thrown weapons) never show durability or charge bars
    local isProjectile = false
    if item and item.type == types.Weapon and rec then
        local wt = rec.type
        -- Named constants (OpenMW 0.49+) with numeric fallbacks
        local Arrow         = types.Weapon.TYPE and types.Weapon.TYPE.Arrow         or 12
        local Bolt          = types.Weapon.TYPE and types.Weapon.TYPE.Bolt          or 13
        local MarksmanThrown= types.Weapon.TYPE and types.Weapon.TYPE.MarksmanThrown or 11
        isProjectile = (wt == Arrow or wt == Bolt or wt == MarksmanThrown)
    end

    if rec and not xicon and not isProjectile and (item.type == types.Weapon or item.type == types.Armor) and rec.health then
        local condPct = (itemData and itemData.condition or rec.health) / rec.health
        local barOpacity = colorSettings:get("durabilityChargeBarsOpacity") or 1.00
        table.insert(barsContent,
            createSmallProgressBar(sizeX * 1.5, DataBarHeight, ConditionColor, condPct, barOpacity))
    end
    -- charge bar -------------------------------------------------------------
    if rec and rec.enchant and not isProjectile then
        local ench = core.magic.enchantments.records[rec.enchant]
        if ench then
            local applies =
                (ench.type == core.magic.ENCHANTMENT_TYPE.CastOnStrike and item.type == types.Weapon) or
                (ench.type == core.magic.ENCHANTMENT_TYPE.CastOnUse    and
                 (item.type == types.Armor or item.type == types.Clothing or item.type == types.Weapon))
            if applies then
                local currentCharge = (itemData and itemData.enchantmentCharge) or ench.charge
                local pct = math.max(0, math.min(1, currentCharge / ench.charge))
                local barOpacity = colorSettings:get("durabilityChargeBarsOpacity") or 1.00
                table.insert(barsContent,
                    createSmallProgressBar(sizeX * 1.5, DataBarHeight, ChargeColor, pct, barOpacity))
            end
        end
    end

    -- spell cast chance bar --------------------------------------------------
    if data and data.spell and not data.enchantId and data.spellType and data.spellType:lower() == "spell" then
        local spell = core.magic.spells.records[data.spell]
        if spell then
            local skillId
            if spell.effects and #spell.effects > 0 then
                local eObj = spell.effects[1].effect
                local mgef
                if type(eObj) == "string" then
                    mgef = core.magic.effects.records[eObj]
                else
                    mgef = eObj
                end
                if mgef and mgef.school then 
                    skillId = mgef.school 
                elseif mgef and mgef.id then
                    local rec = core.magic.effects.records[mgef.id]
                    if rec then skillId = rec.school end
                end
            end
            if skillId then
                skillId = string.lower(skillId)
                local skillVal = 0
                if types.NPC.objectIsInstance(self) then
                    skillVal = types.NPC.stats.skills[skillId](self).modified
                end
                local will = types.Actor.stats.attributes.willpower(self).modified
                local luck = types.Actor.stats.attributes.luck(self).modified
                local fatigue = types.Actor.stats.dynamic.fatigue(self)
                local fatigueTerm = 1.0
                if fatigue.base > 0 then
                    fatigueTerm = 0.75 + 0.5 * (math.max(0, fatigue.current) / fatigue.base)
                end
                
                local chance = (skillVal * 2.0 + will / 5.0 + luck / 10.0 - spell.cost) * fatigueTerm
                
                if spell.type ~= core.magic.SPELL_TYPE.Power then
                    local isGodMode = false
                    pcall(function() isGodMode = debug.isGodMode() end)
                    if isGodMode then chance = 100 end
                    
                    local chancePct = math.max(0, math.min(100, chance)) / 100
                    local barOpacity = colorSettings:get("durabilityChargeBarsOpacity") or 1.00
                    local castColor = colorSettings:get("castChanceColor") or util.color.rgba(0.87, 0.70, 0.30, 1.00)
                    table.insert(barsContent,
                        createSmallProgressBar(sizeX * 1.5, DataBarHeight, castColor, chancePct, barOpacity))
                end
            end
        end
    end

    -- always reserve 2 bar slots --------------------------------------------
    local blankBar = { type = ui.TYPE.Widget, props = { size = util.vector2(sizeX * 1.5, DataBarHeight) } }
    while #barsContent < 2 do table.insert(barsContent, blankBar) end

    -- container for bars, slide up by 4 px ----------------------------------
    local barsFlex = {
        type   = ui.TYPE.Flex,
        props  = {
            horizontal = false, autoSize = true,
            align = ui.ALIGNMENT.Center, arrange = ui.ALIGNMENT.Center,
            position = util.vector2(0, -4)      -- slide up by 4 px
        },
        content = ui.content(barsContent)
    }

    -- stack: icon box + bars -------------------------------------------------
    return {
        type   = ui.TYPE.Flex,
        props  = { horizontal = false, autoSize = true,
                   align = ui.ALIGNMENT.Center, arrange = ui.ALIGNMENT.Center },
        content = ui.content({ itemBox, barsFlex })
    }
end

--------------------------------------------------------------------------------
-- REST OF ORIGINAL FILE (unchanged except where noted) ------------------------
--------------------------------------------------------------------------------
local function isBlockedMode()
    local mode = I.UI.getMode()
    if not mode then return false end
    if mode == "LevelUp" then
        if controllerPickMode or pickSlotMode then return false end
        -- Block if we are in one of our custom selection menus
        if I.QuickSelect_Win1 and (I.QuickSelect_Win1.isQuickSelectOpen() or I.QuickSelect_Win1.isSpellMode() or I.QuickSelect_Win1.isItemMode() or I.QuickSelect_Win1.isMessageBoxOpen()) then
            return true
        end
        -- If paused because of the hotbar (e.g. for selection), don't block by default
        if settings:get("pauseWhenSelecting") then
            return false
        end
    end
    return true
end

local lastActivityTime = 0
local hotBarLayout = nil

local function getFadeTime()
    local val = settings:get("persistMode")
    if val == "Fade Only" then return settings:get("fadeDelay") or 15 end
    return 0
end

local function isPersistStatic()
    local val = settings:get("persistMode")
    return val == "Always" or val == true
end

local function isAnyPersist()
    return isPersistStatic() or getFadeTime() > 0
end

local function resetActivity()
    lastActivityTime = core.getRealTime()
    if isAnyPersist() and not enableHotbar and not isBlockedMode() then
        enableHotbar = true
        if I.QuickSelect_Hotbar and I.QuickSelect_Hotbar.drawHotbar then
            I.QuickSelect_Hotbar.drawHotbar()
        end
    end
end

local function startPickingMode()
    resetActivity()
    enableHotbar = true
    controllerPickMode = true
    I.QuickSelect_Hotbar.drawHotbar()
    if settings:get("pauseWhenSelecting") then
        I.UI.setMode("LevelUp", { windows = {} })
    end
end
local function endPickingMode()
    resetActivity()
    if not isAnyPersist() then enableHotbar = false end
    pickSlotMode, controllerPickMode = false, false
    I.UI.setMode()
    I.QuickSelect_Hotbar.drawHotbar()
end
local function getToolTipPos()
    return settings:get("hotBarOnTop") and utility.itemWindowLocs.BottomCenter
                                       or utility.itemWindowLocs.TopCenter
end
local function drawToolTip()
    local selectedPage = 0
    if I.QuickSelect then selectedPage = I.QuickSelect.getSelectedPage() end
    local offset = selectedPage * 10
    local data   = I.QuickSelect_Storage.getFavoriteItemData(selectedNum + offset)
    local item, spell
    if data.item then
        item = types.Actor.inventory(self):find(data.item)
    elseif data.itemId then
        item = types.Actor.inventory(self):find(data.itemId)
    elseif data.spell then
        if data.spellType:lower() == "spell" then
            spell = types.Actor.spells(self)[data.spell]
            spell = spell and spell.id
        elseif data.spellType:lower() == "enchant" then
            spell = utility.getEnchantment(data.enchantId)
        end
    end
    if item then
        tooltipElement = utility.drawListMenu(tooltipData.genToolTips(item), getToolTipPos(), nil, "HUD")
    elseif spell then
        local spellRecord = core.magic.spells.records[spell]
        tooltipElement = utility.drawListMenu(tooltipData.genToolTips({ spell = spellRecord }),
                                              getToolTipPos(), nil, "HUD")
    end
end
local function constructFakeItem(recordId)
    local allTypes = { types.Weapon, types.Armor, types.Clothing, types.Miscellaneous, types.Apparatus, types.Book, types.Alchemy, types.Ingredient, types.Light, types.Lockpick, types.Probe, types.Repair }
    for _, t in ipairs(allTypes) do
        if t.records[recordId] then
            return {
                isFake = true,
                type = t,
                recordId = recordId,
                id = recordId,
                count = 0,
            }
        end
    end
    return nil
end

local function getHotbarItems(half)
    local items = {}
    local count = num + 10
    local currentNum = num
    while currentNum < count do
        local data = I.QuickSelect_Storage.getFavoriteItemData(currentNum)
        local item, icon
        if data.item then
            item = types.Actor.inventory(self):find(data.item)
        elseif data.spell or data.enchantId then
            if data.spellType:lower() == "spell" then
                local spell = types.Actor.spells(self)[data.spell]
                if spell then icon = spell.effects[1].effect.icon end
            elseif data.spellType:lower() == "enchant" then
                local enchant = utility.getEnchantment(data.enchantId)
                if enchant then icon = enchant.effects[1].effect.icon end
                if data.itemId then 
                    item = types.Actor.inventory(self):find(data.itemId)
                end
            end
        end
        table.insert(items, createHotbarItem(item, icon, currentNum, data, half))
        currentNum = currentNum + 1
    end
    return items
end
local function drawHotbar()
    if not uiVisible then
        if hotBarElement then hotBarElement:destroy() end
        if tooltipElement then tooltipElement:destroy(); tooltipElement = nil end
        return
    end
    if I.UI.getMode() == "Inventory" or I.UI.getMode() == "Container" then
        if hotBarElement then hotBarElement:destroy() end
        return
    end
    if I.UI.getMode() == "Interface" or I.UI.getMode() == "Dialogue" then
        if hotBarElement then hotBarElement:destroy() end
        return
    end
    -- Check if quickactionwindow is displayed, spellmode is true, itemmode is true, or messagebox is displayed
    if I.QuickSelect_Win1 and (I.QuickSelect_Win1.isQuickSelectOpen() or I.QuickSelect_Win1.isSpellMode() or I.QuickSelect_Win1.isItemMode() or I.QuickSelect_Win1.isMessageBoxOpen()) then
        if hotBarElement then hotBarElement:destroy() end
        -- Force disable picking modes to prevent input handling
        controllerPickMode = false
        pickSlotMode = false
        return
    end
    if hotBarElement then hotBarElement:destroy() end
    if tooltipElement then tooltipElement:destroy(); tooltipElement = nil end
    if not enableHotbar then return end

    -- Update DataBarHeight from settings
    DataBarHeight = dimensionsSettings:get("dataBarHeight") or 7

    -- Update colors from settings
    ConditionColor = colorSettings:get("conditionColor") or util.color.rgb(0.90, 0.20, 0.15)
    ChargeColor = colorSettings:get("chargeColor") or util.color.rgba(0.50, 0.60, 0.90, 1.00)

    local hotbarScale = dimensionsSettings:get("hotbarScale") or 0.97
    local isVertical = dimensionsSettings:get("hotbarVertical")
    
    local content = {}
    local selectedPage = 0
    if I.QuickSelect then selectedPage = I.QuickSelect.getSelectedPage() end
    num = 1 + (10 * selectedPage)
    
    local showExtra = settings:get("previewOtherHotbars")
    -- Main hotbar
    table.insert(content,
        utility.renderItemBoxed(
            utility.flexedItems(getHotbarItems(), not isVertical, util.vector2(0.5, 0.5)),
            utility.scaledVector2((isVertical and 95 or 800) * hotbarScale, (isVertical and 800 or 95) * hotbarScale), 
            I.MWUI.templates.padding, util.vector2(0.5, 0.5)))
    
    content = ui.content(content)

    local anchor, relPos = util.vector2(0.5, 1), util.vector2(0.5, 0.9999)
    if settings:get("hotBarOnTop") then 
        anchor, relPos = util.vector2(0.5, 0), util.vector2(0.5, 0.001) 
    end
    
    if isVertical then 
        anchor, relPos = util.vector2(0, 0.5), util.vector2(0.001, 0.5) 
    end
    if controllerPickMode then drawToolTip() end
    
    local maxAlpha = colorSettings:get("hotbarOpacity") or 1.00
    
    hotBarLayout = {
        layer = "HUD",
        template = I.MWUI.templates.padding,
        props = {
            anchor = anchor,
            relativePosition = relPos,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            autoSize = true,
            alpha = maxAlpha
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = content,
                props = {
                    horizontal = not isVertical,
                    autoSize = true,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                }
            }
        }
    }
    hotBarElement = ui.create(hotBarLayout)
end

local data
local function selectSlot(item, spell, enchant)
    enableHotbar, pickSlotMode, controllerPickMode = true, true, true
    data = { item = item, spell = spell, enchant = enchant }
    drawHotbar()
end
local function saveSlot()
    if not pickSlotMode then return end
    local selectedPage = 0
    if I.QuickSelect then selectedPage = I.QuickSelect.getSelectedPage() end
    local slot = selectedNum + (selectedPage * 10)
    if data.item and not data.enchant then
        I.QuickSelect_Storage.saveStoredItemData(data.item, slot)
    elseif data.spell then
        I.QuickSelect_Storage.saveStoredSpellData(data.spell, "Spell", slot)
    elseif data.enchant then
        I.QuickSelect_Storage.saveStoredEnchantData(data.enchant, data.item, slot)
    end
    enableHotbar, pickSlotMode, data = false, false, nil
end
local blockedModes = {
    Inventory=true, Container=true, Interface=true, Dialogue=true, Barter=true,
    Scroll=true, Book=true, Journal=true, Travel=true, Alchemy=true, Companion=true,
    SpellBuying=true, MerchantRepair=true, Repair=true, Recharge=true, Training=true,
    Enchanting=true, SpellCreating=true, Rest=true, Jail=true, LevelUp=true
}

local function UiModeChanged(d)
    if d.newMode then
        if controllerPickMode and not isAnyPersist() then
            if settings:get("pauseWhenSelecting") and d.newMode == "LevelUp" then return end
            controllerPickMode, pickSlotMode, enableHotbar = false, false, false
            drawHotbar()
        elseif isAnyPersist() and not blockedModes[d.newMode] then
            enableHotbar = true; drawHotbar()
        end
        if blockedModes[d.newMode] and d.newMode ~= "LevelUp" then
            enableHotbar = false; if hotBarElement then hotBarElement:destroy() end
        end
        -- Reset hotbar selection when entering QuickSelect menu
        if d.newMode == "LevelUp" and I.QuickSelect_Win1.isQuickSelectOpen() then
            selectedNum = 1
        end
    elseif isAnyPersist() and not blockedModes[I.UI.getMode() or ""] then
        enableHotbar = true; drawHotbar()
    end
end
local function selectNextOrPrevHotBar(dir)
    if isBlockedMode() then return end
    resetActivity()
    if not enableHotbar and dir == "next" then return end
    local p = 0
    if I.QuickSelect then p = I.QuickSelect.getSelectedPage() end
    local maxBars = tonumber(settings:get("hotbarCount")) or 3
    p = (dir == "next") and ((p + 1) % maxBars) or ((p + maxBars - 1) % maxBars)
    if I.QuickSelect then I.QuickSelect.setSelectedPage(p) end
    drawHotbar()
end
local function selectNextOrPrevHotKey(dir)
    if isBlockedMode() then return end
    resetActivity()
    if not enableHotbar or not controllerPickMode then startPickingMode(); return end
    selectedNum = (dir == "next") and ((selectedNum % 10) + 1) or (((selectedNum + 8) % 10) + 1)
    drawHotbar()
end
local function getNextKey()
    return keyboardSettings:get("barSelectionMode") == "-/= Keys" and "="
        or keyboardSettings:get("barSelectionMode") == "[/] Keys" and "[" or nil
end
local function getPrevKey()
    return keyboardSettings:get("barSelectionMode") == "-/= Keys" and "-"
        or keyboardSettings:get("barSelectionMode") == "[/] Keys" and "]" or nil
end
local function getMouseButton()
    local s = mouseSettings:get("mouseHotbarButton")
    return s == "Mouse3" and 2 or s == "Mouse4" and 3 or s == "Mouse5" and 4 or 2
end

return {
    interfaceName = "QuickSelect_Hotbar",
    interface = { drawHotbar = drawHotbar, selectSlot = selectSlot, isBlockedMode = isBlockedMode, resetActivity = resetActivity, endPickingMode = endPickingMode },
    eventHandlers = { 
        UiModeChanged = function(d)
            if d.newMode == "LevelUp" and (controllerPickMode or pickSlotMode) then return end
            if isBlockedMode() then
                enableHotbar = false; if hotBarElement then hotBarElement:destroy() hotBarElement = nil end
            elseif isAnyPersist() then
                resetActivity()
                enableHotbar = true; drawHotbar()
            end
        end
    },
    engineHandlers = {
        onUpdate = function(dt)
            local mode = settings:get("persistMode")
            if mode == "Fade Only" and enableHotbar and not pickSlotMode and not controllerPickMode then
                local fadeDelay = settings:get("fadeDelay") or 15
                local fadeTransition = settings:get("fadeTime") or 1.0
                local elapsed = core.getRealTime() - lastActivityTime
                local maxAlpha = colorSettings:get("hotbarOpacity") or 1.00
                
                if elapsed > fadeDelay then
                    local timePastDelay = elapsed - fadeDelay
                    
                    if timePastDelay >= fadeTransition then
                        enableHotbar = false
                        if hotBarElement then hotBarElement:destroy() hotBarElement = nil end
                    elseif hotBarElement and hotBarLayout then
                        local factor = math.max(0, 1.0 - (timePastDelay / fadeTransition))
                        local newAlpha = maxAlpha * factor
                        hotBarLayout.props.alpha = newAlpha
                        hotBarElement:update()
                    end
                else
                    -- Within delay period, keep at max alpha
                    if hotBarElement and hotBarLayout and hotBarLayout.props.alpha ~= maxAlpha then
                        hotBarLayout.props.alpha = maxAlpha
                        hotBarElement:update()
                    end
                end
            end
        end,
        onLoad = function()
            if isAnyPersist() then 
                resetActivity()
                enableHotbar = true; 
                drawHotbar() 
            end
        end,
        onKeyPress = function(key)
            if isBlockedMode() then return end
            if I.QuickSelect_Win1 and (I.QuickSelect_Win1.isMessageBoxOpen() or I.QuickSelect_Win1.isQuickSelectOpen() or I.QuickSelect_Win1.isSpellMode() or I.QuickSelect_Win1.isItemMode()) then return end
            if core.isWorldPaused() and not controllerPickMode then return end
            local handled = false
            local c = key.symbol
            if c == getNextKey() then selectNextOrPrevHotBar("next"); handled = true
            elseif c == getPrevKey() then selectNextOrPrevHotBar("prev"); handled = true
            elseif key.code == input.KEY.F11 then
                uiVisible = not uiVisible
                I.QuickSelect_Hotbar.drawHotbar()
                return true
            end
            if not keyboardSettings:get("useArrowKeys") then return handled or false end
            if key.code == input.KEY.RightArrow then selectNextOrPrevHotKey("next"); handled = true
            elseif key.code == input.KEY.LeftArrow then selectNextOrPrevHotKey("prev"); handled = true
            elseif key.code == input.KEY.UpArrow then if enableHotbar then selectNextOrPrevHotBar("prev"); handled = true end
            elseif key.code == input.KEY.DownArrow then if enableHotbar then selectNextOrPrevHotBar("next"); handled = true end
            elseif key.code == input.KEY.Enter or key.code == input.KEY.Mouse3 then
                if not enableHotbar then return handled or false end
                if pickSlotMode then saveSlot(); drawHotbar(); return true end
                local selectedPage = 0
                if I.QuickSelect then selectedPage = I.QuickSelect.getSelectedPage() end
                I.QuickSelect_Storage.equipSlot(selectedNum + (selectedPage * 10))
                endPickingMode()
                handled = true
            end
            if handled then return true end
        end,
        onControllerButtonPress = function(btn)
            if isBlockedMode() then return end
            local qsActive = I.QuickSelect_Win1.isMessageBoxOpen() or I.QuickSelect_Win1.isQuickSelectOpen() or I.QuickSelect_Win1.isSpellMode() or I.QuickSelect_Win1.isItemMode()
            if core.isWorldPaused() and not controllerPickMode and not qsActive then return end
            
            -- Broadly block DPads for other mods if any menu is active
            if qsActive or enableHotbar or controllerPickMode then
                if btn >= 15 and btn <= 18 then -- DPad buttons range
                    -- Continue processing to let hotbar use them, but always return true
                end
            end
            
            if qsActive then return true end -- Exclusively handle in Magic Menu
            
            local handled = false
            if btn == input.CONTROLLER_BUTTON.DPadLeft then
                if gamepadSettings:get("enableGamepadControls") then 
                    selectNextOrPrevHotKey("prev")
                    handled = true
                end
            elseif btn == input.CONTROLLER_BUTTON.DPadRight then
                if gamepadSettings:get("enableGamepadControls") then
                    selectNextOrPrevHotKey("next")
                    handled = true
                end
            elseif btn == input.CONTROLLER_BUTTON.DPadDown then
                if gamepadSettings:get("enableGamepadControls") then
                    if gamepadSettings:get("compatibilitymode") then
                        if not enableHotbar then startPickingMode() end
                    end
                    selectNextOrPrevHotBar("next")
                    handled = true
                end
            elseif btn == input.CONTROLLER_BUTTON.DPadUp and controllerPickMode then
                if gamepadSettings:get("enableGamepadControls") then
                    if enableHotbar then selectNextOrPrevHotBar("prev") end
                    handled = true
                end
            elseif btn == input.CONTROLLER_BUTTON.A and controllerPickMode then
                if gamepadSettings:get("enableGamepadControls") and enableHotbar then
                    if pickSlotMode then saveSlot(); drawHotbar(); return true end
                    local selectedPage = 0
                    if I.QuickSelect then selectedPage = I.QuickSelect.getSelectedPage() end
                    I.QuickSelect_Storage.equipSlot(selectedNum + (selectedPage * 10))
                    endPickingMode()
                    handled = true
                end
            elseif btn == input.CONTROLLER_BUTTON.B then
                if enableHotbar then 
                    endPickingMode()
                    handled = true
                end
            end
            
            if handled then return true end
        end,
        onMouseWheel = function(delta)
            if not mouseSettings:get("enableMouseControls") then return end
            if isBlockedMode() then return end
            if I.QuickSelect_Win1 and (I.QuickSelect_Win1.isMessageBoxOpen() or I.QuickSelect_Win1.isQuickSelectOpen() or I.QuickSelect_Win1.isSpellMode() or I.QuickSelect_Win1.isItemMode()) then return end
            local blocked = {
                Inventory=true, Container=true, Interface=true, Dialogue=true, Barter=true,
                Scroll=true, Book=true, Journal=true, Travel=true, Alchemy=true, Companion=true,
                SpellBuying=true, MerchantRepair=true, Repair=true, Recharge=true, Training=true,
                Enchanting=true, SpellCreating=true, Rest=true, Jail=true, LevelUp=true
            }
            local isHotbarActive = controllerPickMode or enableHotbar
            if blocked[I.UI.getMode() or ""] and not isHotbarActive then return end
            if core.isWorldPaused() and not isHotbarActive then return end
            local modifierPressed = false
            if keyboardSettings:get("barSelectionMode") == "Shift Modifier" then
                modifierPressed = input.isShiftPressed()
            elseif keyboardSettings:get("barSelectionMode") == "Ctrl Modifier" then
                modifierPressed = input.isCtrlPressed()
            elseif keyboardSettings:get("barSelectionMode") == "Alt Modifier" then
                modifierPressed = input.isAltPressed()
            end
            if modifierPressed then
                if delta > 0 then
                    selectNextOrPrevHotBar("prev")
                elseif delta < 0 then
                    selectNextOrPrevHotBar("next")
                end
            else
                if delta > 0 then
                    selectNextOrPrevHotKey("prev")
                elseif delta < 0 then
                    selectNextOrPrevHotKey("next")
                end
            end
        end,
        onMouseButtonPress = function(btn)
            if not mouseSettings:get("enableMouseControls") then return end
            if isBlockedMode() then return end
            if I.QuickSelect_Win1 and (I.QuickSelect_Win1.isMessageBoxOpen() or I.QuickSelect_Win1.isQuickSelectOpen() or I.QuickSelect_Win1.isSpellMode() or I.QuickSelect_Win1.isItemMode()) then return end
            if core.isWorldPaused() and not (controllerPickMode and enableHotbar) then return end
            if btn == getMouseButton() then
                if not enableHotbar then return end
                if pickSlotMode then saveSlot(); drawHotbar(); return end
                local selectedPage = 0
                if I.QuickSelect then selectedPage = I.QuickSelect.getSelectedPage() end
                I.QuickSelect_Storage.equipSlot(selectedNum + (selectedPage * 10))
                endPickingMode()
            end
        end
    }
}
