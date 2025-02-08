local common = require("GPBank.common.common")
local config = require("GPBank.config")
local bankMenu = require("GPBank.menus.bankMenu")
local accountMenu = require("GPBank.menus.accountMenu")
local loanMenu = require("GPBank.menus.loanMenu")
local payLoanMenu = require("GPBank.menus.payLoanMenu")
local takeLoanMenu = require("GPBank.menus.takeLoanMenu")

local OR = include("DOR.GPObjectReplacer")

local function onBankButtonClick()
	bankMenu.createBankMenu()
end

local function createBankButton(parent,enabled)
	local bankButton
	if enabled then
		bankButton = parent:createTextSelect({id = common.GUI_ID_BankButton, text = "Imperial Bank"})
		bankButton:register("mouseClick", onBankButtonClick)
		bankButton.visible = true
	else
		bankButton = parent:createLabel({id = common.GUI_ID_BankButton, text = "Imperial Bank"})
		bankButton.color = tes3ui.getPalette("journal_finished_quest_color")
		bankButton.visible = true
	end
	return bankButton
end

--- NC: Rebuild banker check to not error on creatures.
--- @param mobile tes3mobileActor
--- @return boolean
local function isBanker(mobile)
    local actor = mobile.reference.baseObject

    -- Check based on configured IDs.
    local actorId = actor.id:lower()
    for _, banker in ipairs(common.bankers) do
        if (banker:lower() == actorId) then
            return true
        end
    end

    -- Allow any actor with banker in their ID to be one.
    if (actorId:find("banker_")) then
        return true
    end

    -- Check based on class.
    if (actor.class) then
        local classId = actor.class.id:lower()

        -- Any class that includes banker in its ID.
        if (classId:find("banker")) then
            return true
        end

        -- Optionally include pawnbrokers.
        if (config.enablePawnbrokers and classId == "pawnbroker") then
            return true
        end
    end

    return false
end

local function updateBankButton()
	local menu = tes3ui.findMenu(common.GUI_ID_DialogMenu)
	if not menu then return end
	local mobile = menu:getPropertyObject("PartHyperText_actor")
	local topics = menu:findChild(common.GUI_ID_DialogTopics):findChild(common.GUI_ID_ScrollPane)
	local dialogDivider = menu:findChild(common.GUI_ID_DialogDivider)

    if (isBanker(mobile)) then
        local bankButton = menu:findChild(common.GUI_ID_BankButton) or createBankButton(topics, true)
        if not bankButton.visible then
            bankButton.visible = true
        end
        topics:reorderChildren(dialogDivider, bankButton, 1)
        menu:updateLayout()
    end
end

local function onEnterFrame()
	updateBankButton()
    local newDay = tes3.getGlobal("Day")
	if common.currentDay ~= newDay then
        local dayDiff = newDay - common.currentDay
		common.currentDay = newDay
        while dayDiff > 0 do
            common.updateAccount()
            common.updateLoans()
            common.updateInvestments()
            dayDiff = dayDiff - 1
        end
	end
	if common.GPBankData.loanCrime == true and tes3.mobilePlayer.bounty == 0 then
		common.GPBankData.loanCrime = false
	end
end

local function onItemAdded(e)
    local itemID = e.reference.id
    if ((string.find(itemID, "GPBankSeptimGold_") or string.find(itemID, "GPBankSeptimSilver_") or (string.find(itemID, "GPBankSilver_"))) or (string.find(itemID, "GPBankGold_"))) then
        tes3ui.forcePlayerInventoryUpdate()
        tes3ui.updateInventoryTiles()
    end
end

local function onInventoryOpen(e)
    if (e.menu.name ~= "MenuMap") then return end
    tes3ui.forcePlayerInventoryUpdate()
    tes3ui.updateInventoryTiles()
    common.removeCoinStacks()
end

local function convertToCopper(e)
    if (e.element.name ~= "MenuDialog") then return end
    common.enterMenu()
    common.removeCoinStacks()
end

local function convertBack(e)
    common.GPBankData.activeLoans = common.activeLoans
    common.GPBankData.accountBalance = common.accountBalance
    common.GPBankData.accountCreated = common.accountCreated
    common.GPBankData.allCommodities =  common.allCommodities
    tes3.player.data.GPBank = common.GPBankData
    local actualCopper = common.getActualCopper(common.totalCopper)
    local newTotalCopper = 0
    local diff = common.totalCopperBefore - tes3.getPlayerGold()
    if (common.converted) then
        if (diff > 0 and common.actualCopperBefore ~= common.totalCopperBefore and actualCopper ~= common.totalCopper) then
            common.convertLoss(math.abs(diff))
        elseif (diff < 0 and common.actualCopperBefore ~= common.totalCopperBefore and actualCopper ~= common.totalCopper) then
            common.convertGain(diff)
        end
        common.fixCounts()
        common.updateCountsOnExit()
        common.totalCopperBefore = tes3.getPlayerGold()
        common.totalCopper = tes3.getPlayerGold()
        common.converted = false;
    end
    if (config.resetSharePrices) then
        common.resetCommodityPrices()
        config.resetSharePrices = false
    end
end

-- INIT

local function initCoins()
    common.septimGold = tes3.getObject("GPBankSeptimGold")
    common.septimGold005 = tes3.getObject("GPBankSeptimGold_005")
    common.septimGold010 = tes3.getObject("GPBankSeptimGold_010")
    common.septimGold025 = tes3.getObject("GPBankSeptimGold_025")
    common.septimGold100 = tes3.getObject("GPBankSeptimGold_100")
    common.septimGold001Cursed = tes3.getObject("GPBankGold_Dae_cursed_001")
    common.septimGold005Cursed = tes3.getObject("GPBankGold_Dae_cursed_005")
    common.septimSilver = tes3.getObject("GPBankSeptimSilver")
    common.septimSilver005 = tes3.getObject("GPBankSeptimSilver_005")
    common.septimSilver010 = tes3.getObject("GPBankSeptimSilver_010")
    common.septimSilver025 = tes3.getObject("GPBankSeptimSilver_025")
    common.septimSilver100 = tes3.getObject("GPBankSeptimSilver_100")
    common.septimSilver001Cursed = tes3.getObject("GPBankSilver_Dae_cursed_001")
    common.septimSilver005Cursed = tes3.getObject("GPBankSilver_Dae_cursed_005")
    common.septimCopper = tes3.getObject("Gold_001")
    common.septimGold.weight = config.septimGoldWeight / 100
    common.septimSilver.weight = config.septimSilverWeight / 100
    common.septimGold.value = config.septimGoldValue
    common.septimSilver.value = config.septimSilverValue
    common.septimCopper.name = "Septim (Copper)"
    common.septimPaper0005 = tes3.getObject("GPBankSeptimPaper0005")
    common.septimPaper0010 = tes3.getObject("GPBankSeptimPaper0010")
    common.septimPaper0020 = tes3.getObject("GPBankSeptimPaper0020")
    common.septimPaper0050 = tes3.getObject("GPBankSeptimPaper0050")
    common.septimPaper0100 = tes3.getObject("GPBankSeptimPaper0100")
    common.septimPaper0500 = tes3.getObject("GPBankSeptimPaper0500")
    common.septimPaper1000 = tes3.getObject("GPBankSeptimPaper1000")
    common.septimPaper0005.weight = config.septimPaperWeight / 100
    common.septimPaper0010.weight = config.septimPaperWeight / 100
    common.septimPaper0020.weight = config.septimPaperWeight / 100
    common.septimPaper0050.weight = config.septimPaperWeight / 100
    common.septimPaper0100.weight = config.septimPaperWeight / 100
    common.septimPaper0500.weight = config.septimPaperWeight / 100
    common.septimPaper1000.weight = config.septimPaperWeight / 100
    common.currency = {
        common.septimPaper0005,
        common.septimPaper0010,
        common.septimPaper0020,
        common.septimPaper0050,
        common.septimPaper0100,
        common.septimPaper0500,
        common.septimPaper1000,
        common.septimGold,
        common.septimSilver
    }
    common.currencies1 = {
        common.septimPaper0005,
        common.septimPaper0050,
        common.septimPaper1000,
    }
    common.currencies2 = {
        common.septimPaper0010,
        common.septimPaper0100,
        common.septimSilver,
    }
    common.currencies3 = {
        common.septimPaper0020,
        common.septimPaper0500,
        common.septimGold,
    }

    for _, currency in ipairs(common.currency) do
        common.registerTradeGood(currency)
    end
end

local function initOnLoad()
    if OR then
        OR.loadORFile("GPBank._OR_GPBank")
    end
    initCoins()
    common.commodities1 = {
        wickwheat = common.allCommodities.wickwheat,
        saltrice = common.allCommodities.saltrice,
        
    }
    common.commodities2 = {
        kwama = common.allCommodities.kwama,
        silver = common.allCommodities.silver,
    }
    common.commodities3 = {
        spirits = common.allCommodities.spirits,
        glass = common.allCommodities.glass,
        gold = common.allCommodities.gold,
    }
    common.commodities4 = {
        produce = common.allCommodities.produce,
        iron = common.allCommodities.iron,
        
    }
    common.commodities5 = {
        ebony = common.allCommodities.ebony,
        gems = common.allCommodities.gems,
        gold = common.allCommodities.hides,
        
    }
    common.commodities6 = {
        textiles = common.allCommodities.textiles,
        guars = common.allCommodities.guars,
    }
    common.commodities7 = {
        steel = common.allCommodities.steel,
        fish = common.allCommodities.fish,
    }
    common.commodities8 = {

    }
    common.currentDay = tes3.getGlobal("Day")
    common.bankers = {
        "chargen class",
        "Canctunian Ponius",
        "beldrose dralor",
        "baren alen",
    }
    tes3.player.data.GPBank = tes3.player.data.GPBank or {}
    common.GPBankData = tes3.player.data.GPBank
    if common.GPBankData.activeLoans == nil then common.GPBankData.activeLoans = {} end
    common.activeLoans = common.GPBankData.activeLoans
    if common.GPBankData.accountBalance == nil then common.GPBankData.accountBalance = 0 end
    common.accountBalance = common.GPBankData.accountBalance
    if common.GPBankData.accountCreated == nil then common.GPBankData.accountCreated = false end
    common.accountCreated = common.GPBankData.accountCreated
    if common.GPBankData.daysTilCompound == nil then common.GPBankData.daysTilCompound = config.interestPeriodAccount end
    common.daysTilCompound = common.GPBankData.daysTilCompound
    if common.GPBankData.daysTilReset == nil then common.GPBankData.daysTilReset = config.resetShareTimer end
    common.daysTilReset = common.GPBankData.daysTilReset
    if common.GPBankData.allCommodities == nil then common.GPBankData.allCommodities = common.allCommodities end
    common.allCommodities = common.GPBankData.allCommodities
    common.activeLoanMax = common.getMaxNumLoans()
    common.totalCopper = 0
    common.initCounts()
    common.updateCounts()
    common.updateCommodityLists()
    local isRegistered = event.isRegistered(tes3.event.enterFrame, onEnterFrame)
    if (not isRegistered) then
        event.register(tes3.event.enterFrame, onEnterFrame) 
    end
    print("[MWSE Currency] MWSE Currency Initialized")
end

local function initialized()
    event.register(tes3.event.loaded, initOnLoad)
    event.register(tes3.event.uiActivated, convertToCopper)
    event.register(tes3.event.menuExit, convertBack)
    event.register(tes3.event.menuEnter, onInventoryOpen)
    event.register(tes3.event.convertReferenceToItem, onItemAdded)
end

event.register(tes3.event.initialized, initialized)

--- @param e calcBarterPriceEventData
local function onCalcBarterPrice(e)
    -- Trade good prices are fixed.
    if (common.isTradeGood(e.item)) then
        e.price = e.item.value
        return false
    end
end
event.register(tes3.event.calcBarterPrice, onCalcBarterPrice, { priority = 100 })

event.register("modConfigReady", function()
    require("gpbank.mcm")
    config = require("gpbank.config")
end)