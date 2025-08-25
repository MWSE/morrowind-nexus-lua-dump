local modName = 'Regional Bounty'
local configPath = 'RegionalBounty'
local description = "Your bounty doesn't travel with you from region to region. Adds notifications and optional bounty decay over time."

-- Config with new options
local config = {
    enabled = true,
    payOffAll = true,
    hiddenBounties = false,

    -- Notifications
    showNotifications = true,
    notifyOnEnter = true,
    notifyOnlyWhenWanted = true,    -- only notify on enter if local bounty > 0
    notifyOnBountyChange = true,

    -- Decay
    decayEnabled = true,
    decayAmount = 5,                -- amount reduced per interval
    decayIntervalHours = 24,        -- in-game hours per decay tick
    decaySkipCurrentRegion = true,  -- don't decay where the player currently is
}

local loadedConfig = mwse.loadConfig(configPath)
if loadedConfig ~= nil then
    for k, v in pairs(loadedConfig) do
        config[k] = v
    end
end

local debugMode = false
local function debug(str, ...)
    if debugMode then
        print(tostring(str):format(...))
    end
end

local function notify(fmt, ...)
    if config.showNotifications then
        tes3.messageBox(fmt, ...)
    else
        debug(fmt, ...)
    end
end

-- UI IDs
local GUI_ID_MenuStat = tes3ui.registerID('MenuStat')
local GUI_ID_MenuStat_misc_layout = tes3ui.registerID('MenuStat_misc_layout')
local GUI_ID_MenuStat_Bounty_layout = tes3ui.registerID('MenuStat_Bounty_layout')
local GUI_ID_inner_block = tes3ui.registerID('RegionalBounty:inner_block')
local GUI_ID_bounty_block = tes3ui.registerID('RegionalBounty:bounty_block')
local GUI_ID_bounty_region = tes3ui.registerID('RegionalBounty:bounty_region')
local GUI_ID_bounty_value = tes3ui.registerID('RegionalBounty:bounty_value')

-- State
local lastRegion
local lastBounty = 0
local bountyBlock
local bountyLabel
local innerBlock

local bountyWatcherTimer
local decayTimer

-- Helpers

local function getCurrentCell()
    local dh = tes3.getDataHandler()
    return dh and dh.currentCell or tes3.player and tes3.player.cell
end

local function getLastExteriorRegionId()
    local dh = tes3.getDataHandler()
    if not dh or not dh.lastExteriorCell or not dh.lastExteriorCell.region then
        return nil
    end
    return dh.lastExteriorCell.region.id
end

local function resolvePlayerRegionId()
    local cell = getCurrentCell()
    if cell and cell.region then
        return cell.region.id
    end
    -- Interior or no-region cell: fall back to last exterior region
    return getLastExteriorRegionId()
end

local function ensureData()
    tes3.player.data.bounties = tes3.player.data.bounties or {}
end

local function setBounty(region)
    if (region == nil) then
        region = resolvePlayerRegionId() or 'Unknown'
    end
    tes3.mobilePlayer.bounty = tes3.player.data.bounties[region] or 0
    debug('[RegionalBounty] Player bounty set to %d from "%s".', tes3.mobilePlayer.bounty, region)
end

local function saveBounty(region, bounty)
    if not region then return end
    ensureData()
    tes3.player.data.bounties[region] = bounty
    debug('[RegionalBounty] Player bounty in "%s" updated to %d.', region, bounty)
end

-- UI

local function updateBounties()
    debug('[RegionalBounty] Update bounties block.')
    if not innerBlock then
        return
    end
    innerBlock.autoHeight = false
    innerBlock.height = 0
    innerBlock:destroyChildren()
    if config.hiddenBounties then
        if bountyBlock then
            bountyBlock.autoHeight = false
            bountyBlock.height = 0
        end
        return
    else
        if bountyBlock then
            bountyBlock.autoHeight = true
        end
    end

    local mainMenu = tes3ui.findMenu(GUI_ID_MenuStat)
    if not mainMenu then
        return
    end

    ensureData()
    -- Show all non-zero bounties except current region (since vanilla shows current bounty)
    for region, bounty in pairs(tes3.player.data.bounties) do
        if bounty ~= 0 and lastRegion ~= region then
            innerBlock.autoHeight = true

            local block = innerBlock:createBlock { id = GUI_ID_bounty_block }
            if block then
                block.layoutWidthFraction = 1.0
                block.flowDirection = 'left_to_right'
                block.borderLeft = 15
                block.borderRight = 5
                block.autoHeight = true

                local bountyRegion = block:createLabel({ id = GUI_ID_bounty_region, text = region })
                bountyRegion.layoutOriginFractionX = 0.0

                local bountyValue = block:createLabel({ id = GUI_ID_bounty_value, text = tostring(bounty) })
                bountyValue.layoutOriginFractionX = 1.0
            end
        end
    end

    timer.delayOneFrame(function()
        if bountyLabel ~= nil and lastRegion then
            bountyLabel.text = lastRegion
        end
    end)

    mainMenu:updateLayout()
end

local function createBountiesBlock(e)
    debug('[RegionalBounty] Create bounties block.')
    if not e.element then
        return
    end

    local miscBlock = e.element:findChild(GUI_ID_MenuStat_misc_layout)
    local statsBlock = miscBlock.parent

    innerBlock = statsBlock:createBlock { id = GUI_ID_inner_block }
    innerBlock.autoHeight = true
    innerBlock.layoutWidthFraction = 1.0
    innerBlock.flowDirection = 'top_to_bottom'

    bountyBlock = e.element:findChild(GUI_ID_MenuStat_Bounty_layout).parent
    if bountyBlock ~= nil then
        bountyLabel = bountyBlock.children[1]
    end

    updateBounties()
end

-- Notifications and timers

local function startBountyWatcher()
    if bountyWatcherTimer then
        bountyWatcherTimer:cancel()
        bountyWatcherTimer = nil
    end
    bountyWatcherTimer = timer.start{
        duration = 0.5,
        type = timer.simulate,
        iterations = -1,
        callback = function()
            if not config.enabled or not tes3.mobilePlayer then return end
            local current = tes3.mobilePlayer.bounty or 0
            if current ~= lastBounty then
                if config.notifyOnBountyChange and config.showNotifications then
                    if current > lastBounty then
                        notify("Bounty increased in %s: %d -> %d", lastRegion or "Unknown", lastBounty, current)
                    else
                        notify("Bounty decreased in %s: %d -> %d", lastRegion or "Unknown", lastBounty, current)
                    end
                end
                saveBounty(lastRegion or resolvePlayerRegionId() or "Unknown", current)
                lastBounty = current
                updateBounties()
            end
        end
    }
end

local function startDecayTimer()
    if decayTimer then
        decayTimer:cancel()
        decayTimer = nil
    end
    if not config.decayEnabled then
        return
    end
    decayTimer = timer.start{
        duration = math.max(1, tonumber(config.decayIntervalHours) or 24),
        type = timer.game,
        iterations = -1,
        callback = function()
            if not config.enabled or not tes3.player then return end
            ensureData()
            local currentRegion = lastRegion or resolvePlayerRegionId()
            local changedAny = false

            for region, bounty in pairs(tes3.player.data.bounties) do
                if bounty > 0 then
                    if not (config.decaySkipCurrentRegion and currentRegion and region == currentRegion) then
                        local new = math.max(0, bounty - (tonumber(config.decayAmount) or 5))
                        if new ~= bounty then
                            tes3.player.data.bounties[region] = new
                            changedAny = true

                            if config.notifyOnBountyChange and config.showNotifications then
                                notify("Bounty decayed in %s: %d -> %d", region, bounty, new)
                            end

                            if currentRegion and region == currentRegion and tes3.mobilePlayer then
                                tes3.mobilePlayer.bounty = new
                                lastBounty = new
                            end
                        end
                    end
                end
            end

            if changedAny then
                updateBounties()
            end
        end
    }
end

-- Events

local function onCellChanged()
    if not config.enabled or not tes3.player then
        return
    end
    -- Always record the last exterior region for interiors to inherit
    local le = getLastExteriorRegionId()
    if le ~= nil then
        -- First-time setup
        if lastRegion == nil then
            lastRegion = le
            setBounty(lastRegion)
            lastBounty = tes3.mobilePlayer.bounty or 0
            updateBounties()
            return
        end

        -- Save outgoing region's bounty, apply incoming region's bounty
        saveBounty(lastRegion, tes3.mobilePlayer.bounty or 0)
        setBounty(le)

        lastRegion = le
        lastBounty = tes3.mobilePlayer.bounty or 0
        updateBounties()

        -- Notify on entering a region (TR regions included automatically via region.id)
        if config.notifyOnEnter and (not config.notifyOnlyWhenWanted or lastBounty > 0) then
            notify("Entering %s. Local bounty: %d", lastRegion, lastBounty)
        end
    end
end
event.register(tes3.event.cellChanged, onCellChanged)

local function onLoaded(e)
    ensureData()

    -- Resolve region robustly (works with interiors + TR)
    lastRegion = resolvePlayerRegionId() or lastRegion
    if lastRegion then
        setBounty(lastRegion)
        lastBounty = tes3.mobilePlayer.bounty or 0
    end

    updateBounties()

    -- Start timers
    startBountyWatcher()
    startDecayTimer()

    if e.newGame then
        return
    end
end
event.register(tes3.event.loaded, onLoaded)

local function onSave()
    if not config.enabled or not tes3.player then
        return
    end
    -- Save to the best-known region (interiors included via fallback)
    local cell = getCurrentCell()
    local regionId = (cell and cell.region and cell.region.id) or lastRegion or resolvePlayerRegionId()
    if regionId then
        saveBounty(regionId, tes3.mobilePlayer.bounty or 0)
    end
end
event.register(tes3.event.save, onSave)

local function onDialog(e)
    if not e.newlyCreated or not tes3.mobilePlayer or not config.payOffAll then
        return
    end
    lastBounty = tes3.mobilePlayer.bounty or 0
    debug('[RegionalBounty] Set last bounty to: %d', lastBounty)
end

local function onMenuExit()
    if not tes3.mobilePlayer then
        return
    end

    -- if the player's bounty was reduced to 0 in a dialog, then they paid off their bounty
    if config.payOffAll and lastBounty > 0 and (tes3.mobilePlayer.bounty or 0) == 0 then
        debug('[RegionalBounty] Clearing bounties less than: %d', lastBounty)
        ensureData()
        local cleared = 0
        for region, bounty in pairs(tes3.player.data.bounties) do
            if lastBounty >= bounty then
                tes3.player.data.bounties[region] = 0
                cleared = cleared + 1
            end
        end
        if config.showNotifications then
            notify("Bounty paid. Cleared %d lesser regional bounties.", cleared)
        end
        lastBounty = 0
    end
    updateBounties()
end

event.register(tes3.event.uiActivated, onDialog, { filter = 'MenuDialog' })
event.register(tes3.event.menuExit, onMenuExit)
event.register(tes3.event.uiRefreshed, createBountiesBlock, { filter = 'MenuStat_scroll_pane' })

-- MCM

local function registerMCM()
    local function addSideBar(component)
        component.sidebar:createInfo { text = description }
        component.sidebar:createHyperLink {
            text = 'Made by sushi',
            exec = 'start https://www.nexusmods.com/morrowind/users/9875502?tab=user+files',
            postCreate = (function(self)
                self.elements.outerContainer.borderAllSides = self.indent
                self.elements.outerContainer.alignY = 1.0
                self.elements.outerContainer.layoutHeightFraction = 1.0
                self.elements.info.layoutOriginFractionX = 0.5
            end)
        }
    end

    local template = mwse.mcm.createTemplate(modName)
    template:saveOnClose(configPath, config)
    template:register()

    local page = template:createSideBarPage()
    addSideBar(page)

    page:createOnOffButton {
        label = 'Enable ' .. modName,
        description = 'Enable/disable ' .. modName .. ". Disabling the mod won't remove existing bounties.",
        variable = mwse.mcm.createTableVariable { id = 'enabled', table = config }
    }

    page:createOnOffButton {
        label = 'Pay off all bounties',
        description = 'If enabled, paying off a bounty in one region will remove all bounties that are less or equal to it in other regions.',
        variable = mwse.mcm.createTableVariable { id = 'payOffAll', table = config }
    }

    page:createOnOffButton {
        label = 'Hide bounties',
        description = "If enabled, you won't be able to see any bounties. Remember where you're wanted.",
        variable = mwse.mcm.createTableVariable { id = 'hiddenBounties', table = config }
    }

    page:createCategory("Notifications")
    page:createOnOffButton {
        label = 'Show notifications',
        description = 'Enable all message notifications.',
        variable = mwse.mcm.createTableVariable { id = 'showNotifications', table = config }
    }
    page:createOnOffButton {
        label = 'Notify when entering a region',
        description = 'Shows local bounty upon entering a region.',
        variable = mwse.mcm.createTableVariable { id = 'notifyOnEnter', table = config }
    }
    page:createOnOffButton {
        label = 'Only notify on enter if wanted',
        description = 'Suppress entry notifications when your local bounty is zero.',
        variable = mwse.mcm.createTableVariable { id = 'notifyOnlyWhenWanted', table = config }
    }
    page:createOnOffButton {
        label = 'Notify on bounty change',
        description = 'Shows a message whenever your bounty changes.',
        variable = mwse.mcm.createTableVariable { id = 'notifyOnBountyChange', table = config }
    }

    page:createCategory("Bounty Decay")
    page:createOnOffButton {
        label = 'Enable bounty decay',
        description = 'Over time, regional bounties decrease by the configured amount.',
        variable = mwse.mcm.createTableVariable { id = 'decayEnabled', table = config }
    }
    page:createSlider {
        label = 'Decay amount per interval',
        description = 'How much each regional bounty is reduced each interval.',
        min = 1, max = 100, step = 1, jump = 5,
        variable = mwse.mcm.createTableVariable { id = 'decayAmount', table = config }
    }
    page:createSlider {
        label = 'Decay interval (in-game hours)',
        description = 'How often decay is applied, measured in in-game hours.',
        min = 1, max = 168, step = 1, jump = 24,
        variable = mwse.mcm.createTableVariable { id = 'decayIntervalHours', table = config }
    }
    page:createOnOffButton {
        label = 'Skip current region',
        description = 'If enabled, your current region will not decay while you are present.',
        variable = mwse.mcm.createTableVariable { id = 'decaySkipCurrentRegion', table = config }
    }
end

event.register('modConfigReady', registerMCM)
