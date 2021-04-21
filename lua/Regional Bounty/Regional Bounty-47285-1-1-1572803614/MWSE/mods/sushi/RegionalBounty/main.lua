local modName = 'Regional Bounty'
local configPath = 'RegionalBounty'
local description = "Your bounty doesn't travel with you from region to region."

local config = {enabled = true, payOffAll = true, hiddenBounties = false}
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

local GUI_ID_MenuStat = tes3ui.registerID('MenuStat')
local GUI_ID_MenuStat_misc_layout = tes3ui.registerID('MenuStat_misc_layout')
local GUI_ID_MenuStat_Bounty_layout = tes3ui.registerID('MenuStat_Bounty_layout')
local GUI_ID_inner_block = tes3ui.registerID('RegionalBounty:inner_block')
local GUI_ID_bounty_block = tes3ui.registerID('RegionalBounty:bounty_block')
local GUI_ID_bounty_region = tes3ui.registerID('RegionalBounty:bounty_region')
local GUI_ID_bounty_value = tes3ui.registerID('RegionalBounty:bounty_value')

local lastRegion
local lastBounty = 0
local bountyBlock
local bountyLabel
local innerBlock

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
    for region, bounty in pairs(tes3.player.data.bounties) do
        if bounty ~= 0 and lastRegion ~= region then
            innerBlock.autoHeight = true

            local block = innerBlock:createBlock {id = GUI_ID_bounty_block}
            if block then
                block.layoutWidthFraction = 1.0
                block.flowDirection = 'left_to_right'
                block.borderLeft = 15
                block.borderRight = 5
                block.autoHeight = true

                local bountyRegion = block:createLabel({id = GUI_ID_bounty_region, text = region})
                bountyRegion.layoutOriginFractionX = 0.0

                local bountyValue = block:createLabel({id = GUI_ID_bounty_value, text = tostring(bounty)})
                bountyValue.layoutOriginFractionX = 1.0
            end
        end
    end

    timer.delayOneFrame(
        function()
            if bountyLabel ~= nil and lastRegion then
                bountyLabel.text = lastRegion
            end
        end
    )

    mainMenu:updateLayout()
end

local function createBountiesBlock(e)
    debug('[RegionalBounty] Create bounties block.')
    if not e.element then
        return
    end

    local miscBlock = e.element:findChild(GUI_ID_MenuStat_misc_layout)
    local statsBlock = miscBlock.parent

    innerBlock = statsBlock:createBlock {id = GUI_ID_inner_block}
    innerBlock.autoHeight = true
    innerBlock.layoutWidthFraction = 1.0
    innerBlock.flowDirection = 'top_to_bottom'

    bountyBlock = e.element:findChild(GUI_ID_MenuStat_Bounty_layout).parent
    if bountyBlock ~= nil then
        bountyLabel = bountyBlock.children[1]
    end

    updateBounties()
end

local function setBounty(region)
    if (region == nil) then
        region = 'Unknown'
    end
    tes3.mobilePlayer.bounty = tes3.player.data.bounties[region] or 0
    debug('[RegionalBounty] Player bounty set to %d from "%s".', tes3.mobilePlayer.bounty, region)
end

local function saveBounty(region, bounty)
    tes3.player.data.bounties[region] = bounty
    debug('[RegionalBounty] Player bounty in "%s" updated to %d.', region, bounty)
end

local function onCellChanged()
    if not config.enabled or not tes3.player then
        return
    end
    local lastExteriorCell = tes3.getDataHandler().lastExteriorCell
    if lastExteriorCell == nil or lastExteriorCell.region == nil then
        return
    end
    lastExteriorCell = lastExteriorCell.region.id
    if lastRegion == nil then
        lastRegion = lastExteriorCell
        return
    end
    saveBounty(lastRegion, tes3.mobilePlayer.bounty)
    setBounty(lastExteriorCell)
    lastRegion = lastExteriorCell
    updateBounties()
end
event.register(tes3.event.cellChanged, onCellChanged)

local function onLoaded(e)
    tes3.player.data.bounties = tes3.player.data.bounties or {}
    local currentCell = tes3.getDataHandler().currentCell
    if currentCell and currentCell.region then
        lastRegion = currentCell.region.id
    end
    updateBounties()
    if e.newGame then
        return
    end
end
event.register(tes3.event.loaded, onLoaded)

local function onSave()
    if not config.enabled or not tes3.player then
        return
    end
    local currentCell = tes3.getDataHandler().currentCell
    if currentCell and currentCell.region then
        saveBounty(currentCell.region.id, tes3.mobilePlayer.bounty)
    end
end
event.register(tes3.event.save, onSave)

local function onDialog(e)
    if not e.newlyCreated or not tes3.mobilePlayer or not config.payOffAll then
        return
    end
    lastBounty = tes3.mobilePlayer.bounty
    debug('[RegionalBounty] Set last bounty to: %d', lastBounty)
end

local function onMenuExit()
    if not tes3.mobilePlayer then
        return
    end

    -- if the player's bounty was reduced to 0 in a dialog, then they paid off their bounty
    if config.payOffAll and lastBounty > 0 and tes3.mobilePlayer.bounty == 0 then
        debug('[RegionalBounty] Clearing bounties less than: %d', lastBounty)
        for region, bounty in pairs(tes3.player.data.bounties) do
            if lastBounty >= bounty then
                tes3.player.data.bounties[region] = 0
            end
        end
        lastBounty = 0
    end
    updateBounties()
end

event.register(tes3.event.uiActivated, onDialog, {filter = 'MenuDialog'})
event.register(tes3.event.menuExit, onMenuExit)
event.register(tes3.event.uiRefreshed, createBountiesBlock, {filter = 'MenuStat_scroll_pane'})

local function registerMCM()
    local function addSideBar(component)
        component.sidebar:createInfo {text = description}
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
        variable = mwse.mcm.createTableVariable {
            id = 'enabled',
            table = config
        }
    }

    page:createOnOffButton {
        label = 'Pay off all bounties',
        description = 'If enabled, paying off a bounty in one region will remove all bounties that are ' ..
            'less or equal to it in other regions.',
        variable = mwse.mcm.createTableVariable {
            id = 'payOffAll',
            table = config
        }
    }

    page:createOnOffButton {
        label = 'Hide bounties',
        description = "If enabled, you won't be able to see any bounties. Remember where you're wanted",
        variable = mwse.mcm.createTableVariable {
            id = 'hiddenBounties',
            table = config
        }
    }
end

event.register('modConfigReady', registerMCM)
