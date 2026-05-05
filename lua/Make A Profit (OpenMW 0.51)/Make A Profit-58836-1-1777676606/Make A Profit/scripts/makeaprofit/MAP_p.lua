local ui      = require('openmw.ui')
local I       = require('openmw.interfaces')
 
G_hasIE = I.InventoryExtender ~= nil
-- regions loaded when SD installed
G_hasSunsDusk = I.SunsDusk ~= nil
 
local types		= require('openmw.types')
local util		= require('openmw.util')
local self		= require('openmw.self')
local core		= require('openmw.core')
async			= require('openmw.async')
local ambient	= require('openmw.ambient')
 
local v2 = util.vector2
 
local settings      = require('scripts.MakeAProfit.settings')
local serviceHaggle = require('scripts.MakeAProfit.serviceHaggle')
local gamepad       = require('scripts.MakeAProfit.gamepad')
 
-- invest works in both branches (IE button + vanilla [invest] topic)
local invest = require('scripts.MakeAProfit.invest')

-- IE-dependent
local Tooltips, filter, pricing, currencies
if G_hasIE then
	Tooltips   = require('scripts.MakeAProfit.tooltips')
	filter     = require('scripts.MakeAProfit.filter')
	pricing    = require('scripts.MakeAProfit.pricing')
	currencies = require('scripts.MakeAProfit.currencies')
end
 
-- GMSTs
local STR_OFFER        = core.getGMST('sBarterDialog8')
local STR_NO_ITEMS     = core.getGMST('sBarterDialog11')
local STR_PC_TOO_POOR  = core.getGMST('sBarterDialog1')
local STR_NPC_TOO_POOR = core.getGMST('sBarterDialog2')
local STR_REFUSED      = core.getGMST('sNotifyMessage9')
local STR_THATS_MINE   = core.getGMST('sNotifyMessage49')
local DISP_SUCCESS     = core.getGMST('iBarterSuccessDisposition')
local DISP_FAIL        = core.getGMST('iBarterFailDisposition')
 
local l10n = core.l10n('InventoryExtender')
 
saveData = {}
G_nextFrameJobs = {}
G_onFrameJobs = {}
G_inForcedTrade = false
G_inForcedInvest = false
 
-- drop range
local dragAndDrop       = nil
local wasDragging       = false
 
local function onDragStart()
	if not S_ENABLE_DROP_TELEKINESIS then return end
	local range = S_DROP_TELEKINESIS_RANGE or 100
	saveData.dropTelekinesis = range
	types.Actor.activeEffects(self):modify(range, core.magic.EFFECT_TYPE.Telekinesis)
end
 
local function onDragEnd()
	if saveData.dropTelekinesis then
		types.Actor.activeEffects(self):modify(-saveData.dropTelekinesis, core.magic.EFFECT_TYPE.Telekinesis)
		saveData.dropTelekinesis = nil
	end
end
 
-- ======================================================================
-- UI UTILITY
-- ======================================================================
local function findInLayout(layoutOrElement, matchFn)
    local isElem = type(layoutOrElement) == 'userdata'
    local layout = isElem and layoutOrElement.layout or layoutOrElement
    if matchFn(layout) then return layout end
    if layout.content then
        for _, child in pairs(layout.content) do
            local hit = findInLayout(child, matchFn)
            if hit then return hit end
        end
    end
end
 
local function findNthUpdatable(infoBar, n)
    local count = 0
    for i, child in ipairs(infoBar.layout.content) do
        local isElem = type(child) == 'userdata'
        local layout = isElem and child.layout or child
        if layout.userData and layout.userData.update then
            count = count + 1
            if count == n then
                return child, i, isElem
            end
        end
    end
end
 
-- ======================================================================
-- CURRENCY DISPLAY
-- ======================================================================
local function makeCurrencyUpdateFn(getCount, currency)
    local BASE = I.InventoryExtender.Templates.BASE
	
    return function(layout)
        local amount = getCount() or 0
        layout = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                {
                    type = ui.TYPE.Image,
                    props = {
                        resource = ui.texture { path = currency.icon },
                        size = v2(16, 16),
                    },
                },
                BASE.intervalH(4),
                {
                    template = BASE.textNormal,
                    props = {
                        text = tostring(amount),
                    },
                },
            },
        }
        return layout
    end
end
 
local function hookGoldDisplay(window, nth, getCount, currency)
    if not window or not window.infoBar then return false end
	
    local child = findNthUpdatable(window.infoBar, nth)
    if not child then return false end
	
    local isElem = type(child) == 'userdata'
    local layout = isElem and child.layout or child
    layout.userData = layout.userData or {}
    layout.userData.update = makeCurrencyUpdateFn(getCount, currency)
	
    return true
end
 
-- ======================================================================
-- BARTER WINDOW
-- ======================================================================
local barterHooked   = false
local currencyHooked = false
 
local function hookBarterWindow()
    local IE = I.InventoryExtender
    if not IE then return false end
	
    local tradeWindow = IE.getWindow('Trade')
    if not tradeWindow or not tradeWindow.infoBar then return false end
	
    local ctx = tradeWindow.ctx
    if not ctx or not ctx.barterState then return false end
	
    local currency = currencies.getCurrent()
	
    -- currency icons
    if not currencyHooked then
        hookGoldDisplay(tradeWindow, 1, function()
            if not tradeWindow.target then return 0 end
            return tradeWindow.target.type.getBarterGold(tradeWindow.target)
        end, currency)
 
        local invWindow = IE.getWindow('Inventory')
        hookGoldDisplay(invWindow, 2, function()
            return currencies.getPlayerCount(currency)
        end, currency)
 
        currencyHooked = true
    end
	
    local barterControls
    for _, child in ipairs(tradeWindow.infoBar.layout.content) do
        local layout = type(child) == 'userdata' and child.layout or child
        if layout.name == 'barterControls' then
            barterControls = layout
            break
        end
    end
    if not barterControls then return false end
	
    -- pricing correction
    barterControls.userData = barterControls.userData or {}
	
    barterControls.userData.update = function(layout)
        local state    = ctx.barterState
        local merchant = ctx.windowArgs.Trade
		
        if merchant and state.currentMerchantOffer ~= (state._mapCorrectedOffer or nil) then
            local vanillaOffer = state.currentMerchantOffer
            local customOffer, trueValue = pricing.computeCustomOffer(state, merchant)
            local correction = customOffer - vanillaOffer
			
            state.currentMerchantOffer = customOffer
            state.currentBalance       = state.currentBalance + correction
            state._mapCorrectedOffer   = customOffer
            state._trueValue           = trueValue
        end
		
        if not next(state.selling) and not next(state.buying) then
            state.currentBalance = 0
        end
		
        if state.currentBalance < 0 then
            layout.content.totalBalanceLabel.props.text = l10n('UI_Barter_Spend')
        else
            layout.content.totalBalanceLabel.props.text = l10n('UI_Barter_Gain')
        end
		
        layout.content.totalBalanceBox.content[1].content.totalBalanceEdit.props.text =
            tostring(math.abs(state.currentBalance))
 
        return layout
    end
	
    -- offer override
    if barterControls.content then
        for _, child in ipairs(barterControls.content) do
            if type(child) == 'userdata' then
                local textNode = findInLayout(child.layout, function(l)
                    return l.props and l.props.text == STR_OFFER
                end)
                if textNode then
                    child.layout.events.mouseRelease = async:callback(function(e)
                        if e.button ~= 1 then return false end
                        if not child.layout.userData.pressed then return false end
                        child.layout.userData.pressed = false
						
                        local state = ctx.barterState
						
                        if state.totalBalance == 0 then
                            state.currentBalance = 0
                        end
						
                        if not next(state.selling) and not next(state.buying) then
                            ui.showMessage(STR_NO_ITEMS)
                            child:update()
                            return true
                        end
						
                        local playerCurrency = currencies.getPlayerCount(currency)
                        if state.currentBalance < 0
                            and playerCurrency < math.abs(state.currentBalance) then
                            ui.showMessage(STR_PC_TOO_POOR)
                            child:update()
                            return true
                        end
						
                        if state.currentBalance > 0 then
                            local merchantGold =
                                tradeWindow.target.type.getBarterGold(tradeWindow.target)
                            if merchantGold < state.currentBalance then
                                ui.showMessage(STR_NPC_TOO_POOR)
                                child:update()
                                return true
                            end
                        end
						
                        for _, entry in pairs(state.selling) do
                            local stolen = ctx.stolenItems[entry.item.recordId]
                            if stolen and stolen[tradeWindow.target.recordId] then
                                I.UI.setMode(nil)
                                ui.showMessage(string.format(
                                    STR_THATS_MINE,
                                    entry.item.type.record(entry.item).name))
                                core.sendGlobalEvent('MI_ConfiscateToOwner', {
                                    item      = entry.item,
                                    count     = entry.count,
                                    player    = self,
                                    victim    = tradeWindow.target,
                                    stolenMap = ctx.stolenItems,
                                })
                                child:update()
                                return true
                            end
                        end
						
                        local accepted, skillGain = pricing.haggle(
                            tradeWindow.target,
                            state.currentBalance,
                            state.currentMerchantOffer)
						
                        if types.NPC.objectIsInstance(tradeWindow.target) then
                            core.sendGlobalEvent('MI_ModDisposition', {
                                target = tradeWindow.target,
                                player = self,
                                amount = accepted and DISP_SUCCESS or DISP_FAIL,
                            })
                        end
						
                        if not accepted then
                            ui.showMessage(STR_REFUSED)
                            child:update()
                            return true
                        end
						
                        local realBalance    = state.currentBalance
                        state.currentBalance = 0
						
                        core.sendGlobalEvent('MI_FinalizeBarter', {
                            player      = self,
                            merchant    = tradeWindow.target,
                            barterState = state,
                            skillGain   = skillGain,
                        })
						
                        if realBalance ~= 0 then
                            core.sendGlobalEvent('MAP_TransferCurrency', {
                                player     = self,
                                merchant   = tradeWindow.target,
                                amount     = realBalance,
                                currencyId = currency.id,
                            })
                        end
						
                        ambient.playSound('item gold up')
                        state.success = true
                        I.UI.removeMode('Barter')
						
                        child:update()
                        return true
                    end)
					
                    break
                end
            end
        end
    end
	
    invest.hookBarterButton(barterControls, tradeWindow)
	
    return true
end
 
local function getMerchant()
    local invWindow = I.InventoryExtender.getWindow('Inventory')
    return invWindow and invWindow.ctx
        and invWindow.ctx.windowArgs and invWindow.ctx.windowArgs.Trade
end
 
local function onEnterBarter()
    if not G_hasIE then return end
    local merchant = getMerchant()
    filter.onEnterBarter(merchant)
    invest.onEnterBarter(merchant)
    Tooltips.apply('Inventory')
    Tooltips.apply('Trade')
end
 
local function onLeaveBarter()
    G_inForcedTrade = false
    G_inForcedInvest = false
    if not G_hasIE then return end
    filter.onLeaveBarter()
    invest.onLeaveBarter()
end
 
-- ======================================================================
-- TRADE WITH ANYONE
-- ======================================================================
 
local tradeErrorOnce, investErrorOnce
function checkMercantileForTradeAny()
	local threshold = S_SELL_ANYTHING_THRESHOLD or 100
	if types.Player.stats.skills.mercantile(self).base >= threshold and not saveData.hasTradeTopic and not tradeErrorOnce then
		tradeErrorOnce = true
		-- dialogue topic in esp
		types.Player.addTopic(self, "[Trade]")
		if S_SHOW_MESSAGES then
			ui.showMessage("You have learned how to barter with anyone.")
		end
		saveData.hasTradeTopic = true
		tradeErrorOnce = false
	end
end

-- IE players use the barter-window button; topic is the no-IE fallback
function checkMercantileForInvest()
	if G_hasIE then return end
	local threshold = S_INVESTMENT_THRESHOLD or 25
	if types.Player.stats.skills.mercantile(self).base >= threshold and not saveData.hasInvestTopic and not investErrorOnce then
		investErrorOnce = true
		-- dialogue topic in esp
		types.Player.addTopic(self, "[Invest]")
		if S_SHOW_MESSAGES then
			ui.showMessage("You have learned how to invest in merchants.")
		end
		saveData.hasInvestTopic = true
		investErrorOnce = false
	end
end

local function checkMercantileTopics()
	checkMercantileForTradeAny()
	checkMercantileForInvest()
end

I.SkillProgression.addSkillLevelUpHandler(function(skillId)
	if skillId == "mercantile" then
		G_nextFrameJobs["checkMercantileTopics"] = checkMercantileTopics
	end
end)

local function onConsoleCommand()
	G_nextFrameJobs["checkMercantileTopics"] = checkMercantileTopics
end
 
function dialogueResponse(e)
	if e.recordId == "[trade]" then
		local record = types.NPC.records[e.actor.recordId]
		local isNormalMerchant = not record or record.servicesOffered.Barter
		if not isNormalMerchant then
			G_inForcedTrade = true
			local id = e.actor.recordId
			saveData.forcedTradeGold[id] = saveData.forcedTradeGold[id] or 500
		end
		I.UI.setMode("Barter", {target = e.actor})
	elseif e.recordId == "[invest]" and not G_hasIE then
		-- no-IE invest flow; IE players use the Invest button in the barter window instead
		G_inForcedInvest = true
		local id = e.actor.recordId
		saveData.forcedTradeGold[id] = saveData.forcedTradeGold[id] or 500
		invest.showDialogVanilla(e.actor)
	end
end
 
-- ======================================================================
-- LIFECYCLE
-- ======================================================================
 
local function onLoad(data)
    saveData = data or {}
	saveData.forcedTradeGold = saveData.forcedTradeGold or {}
    settings.init()
    invest.init(saveData)
    if G_hasIE then
        local ieHelpers = require('scripts.InventoryExtender.util.helpers')
        Tooltips.init(ieHelpers)
        Tooltips.registerTooltipModifier()
        pricing.init(ieHelpers)
        filter.init()
    end
	checkMercantileForTradeAny()
	checkMercantileForInvest()
	-- mirror pawnbroker setting to global script for activation handler
	core.sendGlobalEvent('MAP_SetPawnbrokerDamage', {
		enabled = G_hasIE and S_ENABLE_PAWNBROKER and true or false,
	})
end
 
local function onSave()
    return saveData
end
 
-- ======================================================================
-- SCRIPT INTERFACE
-- ======================================================================
 
return {
    engineHandlers = {
        onInit = onLoad,
        onLoad = onLoad,
        onSave = onSave,
		onConsoleCommand = onConsoleCommand,
		onControllerButtonPress = function(id)
			gamepad.onButtonPress(id)
		end,
		onControllerButtonRelease = function(id)
			gamepad.onButtonRelease(id)
		end,
        onFrame = function()
            gamepad.tick()
            for name, fn in pairs(G_nextFrameJobs) do
                fn()
                G_nextFrameJobs[name] = nil
            end
			for name, fn in pairs(G_onFrameJobs) do
				fn()
			end
            serviceHaggle.onFrame()
            -- drop range: track drag start/end via draggingObject
            if dragAndDrop then
                local isDragging = dragAndDrop.draggingObject ~= nil
                if isDragging and not wasDragging then
                    onDragStart()
                elseif not isDragging and wasDragging then
                    onDragEnd()
                end
                wasDragging = isDragging
            elseif wasDragging then
                -- window closed while dragging
                onDragEnd()
                wasDragging = false
            end
        end,
    },
    eventHandlers = {
		--postSkillGain = function(data)
		--	print(data.skillId, data.params.skillGain)
		--end,
		DialogueResponse = dialogueResponse,
		MAP_RefreshInfoBars = function()
			if not G_hasIE then return end
			local IE = I.InventoryExtender
			local tw = IE.getWindow('Trade')
			if tw and tw.infoBar then tw.infoBar.layout.userData.updateAll() end
			local iw = IE.getWindow('Inventory')
			if iw and iw.infoBar then iw.infoBar.layout.userData.updateAll() end
		end,
        UiModeChanged = function(data)
            -- vanilla invest dialog should not survive a mode change
            invest.closeDialog()
            if data.newMode and G_hasIE then
                Tooltips.apply('Inventory')
                -- lazily cache dragAndDrop - ctx is guaranteed live by first mode change
                if not dragAndDrop then
                    local invWindow = I.InventoryExtender.getWindow('Inventory')
                    if invWindow and invWindow.ctx then
                        dragAndDrop = invWindow.ctx.dragAndDrop
                    end
                end
            end
			
            if data.newMode == 'Barter' then
                barterHooked   = false
                currencyHooked = false
                onEnterBarter()
                if G_hasIE then
                    -- schedule initial tint for after IE finishes building rows
                    G_nextFrameJobs.tintRestricted = filter.tintRestrictedRows
                    -- hook barter controls on next frame (don't wait for MI_Update)
                    G_nextFrameJobs.barterHookDeferred = function()
                        if not barterHooked then
                            barterHooked = hookBarterWindow()
                        end
                    end
                end
            elseif data.oldMode == 'Barter' then
                barterHooked   = false
                currencyHooked = false
                onLeaveBarter()
            end
			
            if data.newMode then
                serviceHaggle.onModeEnter(data.newMode, data.oldMode)
            end
            if data.oldMode then
                serviceHaggle.onModeLeave(data.oldMode)
            end
            if not data.newMode then
                onDragEnd()
            end
        end,
		
        MI_Update = function()
            if I.UI.getMode() == 'Barter' then
                local IE = I.InventoryExtender
                if IE then
                    local tradeWindow = IE.getWindow('Trade')
                    if tradeWindow and tradeWindow.ctx then
                        if filter.ejectRestricted(tradeWindow.ctx) then
                            local state = tradeWindow.ctx.barterState
                            state.currentMerchantOffer = 0
                            state.currentBalance       = 0
                            state._mapCorrectedOffer   = nil
                            tradeWindow:updateData()
                            local invWindow = IE.getWindow('Inventory')
                            if invWindow then invWindow:updateData() end
                        end
                    end
                end
				
                if not barterHooked then
                    barterHooked = hookBarterWindow()
                end
				
                -- defer tinting to next frame - IE's renderVisibleRows
                -- runs after MI_Update and would overwrite our color changes
                G_nextFrameJobs.tintRestricted = filter.tintRestrictedRows
            end
        end,
    },
}
