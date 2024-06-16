local config = require("GPBank.config")

local common = {
    euler = 2.718,
    totalCopper = 0,
    actualCopper = 0,
    totalCopperBefore = 0,
    actualCopperBefore = 0,
    converted = false,
    currency = {},
    currencies1 = {},
    currencies2 = {},
    currencies3 = {},
    currencies4 = {},
    GPBankData = {},
    activeLoans = {},
    accountBalance = 0,
    daysTilCompound = 0,
    activeLoanMax = 0,
    daysTilReset = 0,
    counts = {},
    allCommodities = {
        wickwheat = {
            name = "Wickwheat",
            startingPrice = 100,
            volatility = 1,
            currentPrice = 100,
            lastPrice = 100,
            owned = 0,
            change = 0,
            buyPrice = 0,
            sellPrice = 0,
        },
        iron = {
            name = "Iron",
            startingPrice = 250,
            volatility = 2,
            currentPrice = 250,
            lastPrice = 250,
            owned = 0,
            change = 0,
            buyPrice = 0,
            sellPrice = 0,
        },
        silver = {
            name = "Silver",
            startingPrice = 1500,
            volatility = 3,
            currentPrice = 1500,
            lastPrice = 1500,
            owned = 0,
            change = 0,
            buyPrice = 0,
            sellPrice = 0,
        },
        gold = {
            name = "Gold",
            startingPrice = 2000,
            volatility = 2,
            currentPrice = 2000,
            lastPrice = 2000,
            owned = 0,
            change = 0,
            buyPrice = 0,
            sellPrice = 0,
        },
        ebony = {
            name = "Ebony",
            startingPrice = 2500,
            volatility = 4,
            currentPrice = 2500,
            lastPrice = 2500,
            owned = 0,
            change = 0,
            buyPrice = 0,
            sellPrice = 0,
        },
        guars = {
            name = "Guars",
            startingPrice = 1000,
            volatility = 3,
            currentPrice = 1000,
            lastPrice = 1000,
            owned = 0,
            change = 0,
            buyPrice = 0,
            sellPrice = 0,
        },
        steel = {
            name = "Steel",
            startingPrice = 500,
            volatility = 3,
            currentPrice = 500,
            lastPrice = 500,
            owned = 0,
            change = 0,
            buyPrice = 0,
            sellPrice = 0,
        },
        spirits = {
            name = "Spirits",
            startingPrice = 1500,
            volatility = 5,
            currentPrice = 1500,
            lastPrice = 1500,
            owned = 0,
            change = 0,
            buyPrice = 0,
            sellPrice = 0,
        },
        hides = {
            name = "Hides",
            startingPrice = 500,
            volatility = 1,
            currentPrice = 500,
            lastPrice = 500,
            owned = 0,
            change = 0,
            buyPrice = 0,
            sellPrice = 0,
        },
        kwama = {
            name = "Kwama",
            startingPrice = 1000,
            volatility = 4,
            currentPrice = 1000,
            lastPrice = 1000,
            owned = 0,
            change = 0,
            buyPrice = 0,
            sellPrice = 0,
        },
        produce = {
            name = "Produce",
            startingPrice = 250,
            volatility = 1,
            currentPrice = 250,
            lastPrice = 250,
            owned = 0,
            change = 0,
            buyPrice = 0,
            sellPrice = 0,
        },
        fish = {
            name = "Fish",
            startingPrice = 100,
            volatility = 4,
            currentPrice = 100,
            lastPrice = 100,
            owned = 0,
            change = 0,
            buyPrice = 0,
            sellPrice = 0,
        },
        gems = {
            name = "Gems",
            startingPrice = 2000,
            volatility = 5,
            currentPrice = 2000,
            lastPrice = 2000,
            owned = 0,
            change = 0,
            buyPrice = 0,
            sellPrice = 0,
        },
        glass = {
            name = "Glass",
            startingPrice = 1500,
            volatility = 5,
            currentPrice = 1500,
            lastPrice = 1500,
            owned = 0,
            change = 0,
            buyPrice = 0,
            sellPrice = 0,
        },
        saltrice = {
            name = "Saltrice",
            startingPrice = 500,
            volatility = 2,
            currentPrice = 500,
            lastPrice = 500,
            owned = 0,
            change = 0,
            buyPrice = 0,
            sellPrice = 0,
        },
        textiles = {
            name = "Textiles",
            startingPrice = 1000,
            volatility = 3,
            currentPrice = 1000,
            lastPrice = 1000,
            owned = 0,
            change = 0,
            buyPrice = 0,
            sellPrice = 0,
        }
    },
    commodities1 = {},
    commodities2 = {},
    commodities3 = {},
    commodities4 = {},
    commodities5 = {},
    commodities6 = {},
    commodities7 = {},
    commodities8 = {},
    septimGold = nil,
    septimGold001Cursed = nil,
    septimGold005 = nil,
    septimGold005Cursed = nil,
    septimGold010 = nil,
    septimGold025 = nil,
    septimGold100 = nil,
    septimSilver = nil,
    septimSilver001Cursed = nil,
    septimSilver005 = nil,
    septimSilver005Cursed = nil,
    septimSilver010 = nil,
    septimSilver025 = nil,
    septimSilver100 = nil,
    septimCopper = nil,
    septimPaper0005 = nil,
    septimPaper0010 = nil,
    septimPaper0020 = nil,
    septimPaper0050 = nil,
    septimPaper0100 = nil,
    septimPaper0500 = nil,
    septimPaper1000 = nil,
    currentDay = nil,
    bankers = {},

    GUI_ID_BankButton = tes3ui.registerID("MenuDialog_service_banking"),
    GUI_ID_DialogMenu = tes3ui.registerID("MenuDialog"),
    GUI_ID_DialogTopics = tes3ui.registerID("MenuDialog_topics_pane"),
    GUI_ID_DialogDivider = tes3ui.registerID("MenuDialog_divider"),

    GUI_ID_BankMenu = tes3ui.registerID("MenuBank"),
    GUI_UI_ID_BankMenuDescription = tes3ui.registerID("MenuBank_description"),
    GUI_ID_BankMenuAccountOverview = tes3ui.registerID("MenuBank_account_overview"),
    GUI_ID_BankMenuAccountButtonCreate = tes3ui.registerID("MenuBank_account_button_create"),
    GUI_ID_BankMenuAccountButton = tes3ui.registerID("MenuBank_account_button"),
    GUI_ID_BankMenuLoanButtonTake = tes3ui.registerID("MenuBankLoan_Take"),
    GUI_ID_BankMenuLoanButtonPay = tes3ui.registerID("MenuBankLoan_Pay"),
    GUI_ID_BankAccountBalance = tes3ui.registerID("MenuBankAccount_balance_number"),
    GUI_ID_BankAccountBalanceLabel = tes3ui.registerID("MenuBankAccount_balance_label"),
    GUI_ID_BankAccountBalanceInput = tes3ui.registerID("MenuBankAccount_balance_input"),

    GUI_ID_ScrollPane = tes3ui.registerID("PartScrollPane_pane"),

    GUI_ID_AccountMenu = tes3ui.registerID("MenuBankAccount"),
    GUI_ID_AccountMenuDescription = tes3ui.registerID("MenuBankAccount_description"),
    GUI_ID_AccountMenuDetail = tes3ui.registerID("MenuBankAccount_detail"),
    GUI_ID_AccountMenuWithdrawButton = tes3ui.registerID("MenuBankAccount_button_withdraw"),

    GUI_ID_LoanMenu = tes3ui.registerID("MenuBankLoan"),
    GUI_ID_LoanMenuDescription = tes3ui.registerID("MenuBankLoan_description"),
    GUI_ID_LoanMenuOverview = tes3ui.registerID("MenuBankLoan_overview"),
    GUI_ID_LoanMenuDetail = tes3ui.registerID("MenuBankLoan_detail"),

    GUI_ID_InvestmentMenu = tes3ui.registerID("MenuBankInvestment"),
    GUI_ID_InvestmentMenuDescription = tes3ui.registerID("MenuBankInvestment_description"),
    GUI_ID_InvestmentMenuOverview = tes3ui.registerID("MenuBankInvestment_overview"),
    GUI_ID_InvestmentMenuDetail = tes3ui.registerID("MenuBankInvestment_detail"),
    GUI_ID_InvestmentMenuIncreaseButton = tes3ui.registerID("MenuBankInvestment_increase"),
    GUI_ID_InvestmentMenuDecreaseButton = tes3ui.registerID("MenuBankInvestment_decrease"),

    GUI_ID_InvestmentMenuBuy = tes3ui.registerID("MenuBankInvestmentBuy"),
    GUI_ID_InvestmentMenuBuyDescription = tes3ui.registerID("MenuBankInvestmentBuy_description"),
    GUI_ID_InvestmentMenuBuyOverview = tes3ui.registerID("MenuBankInvestmentBuy_overview"),
    GUI_ID_InvestmentMenuBuyDetail = tes3ui.registerID("MenuBankInvestmentBuy_detail"),

    GUI_ID_CurrencyExchangeMenu = tes3ui.registerID("MenuBankCurrencyExchange"),
    GUI_ID_CurrencyExchangeMenuDescription = tes3ui.registerID("MenuBankCurrencyExchange_description"),
    GUI_ID_CurrencyExchangeMenuOverview = tes3ui.registerID("MenuBankCurrencyExchange_overview"),
    GUI_ID_CurrencyExchangeMenuDetail = tes3ui.registerID("MenuBankCurrencyExchange_detail"),
    GUI_ID_CurrencyExchangeMenuIncreaseButton = tes3ui.registerID("MenuBankCurrencyExchange_increase"),
    GUI_ID_CurrencyExchangeMenuDecreaseButton = tes3ui.registerID("MenuBankCurrencyExchange_decrease"),

    GUI_ID_LoanMenuTake = tes3ui.registerID("MenuBankLoanTake"),
    GUI_ID_LoanMenuTakeDescription = tes3ui.registerID("MenuBankLoanTake_description"),
    GUI_ID_LoanMenuTotalSeptimsLabel = tes3ui.registerID("MenuBankLoanTake_septims_label"),
    GUI_ID_LoanMenuTotalLoanInput = tes3ui.registerID("MenuBankLoanTake_input"),
    GUI_ID_LoanMenuTakeRateLabel = tes3ui.registerID("MenuBankLoanTake_rate_label"),

    GUI_ID_LoanMenuPay = tes3ui.registerID("MenuBankLoanPay"),
    GUI_ID_LoanMenuPayDescription = tes3ui.registerID("MenuBankLoanPay_description"),
    GUI_ID_LoanMenuPayTotalSeptimsLabel = tes3ui.registerID("MenuBankLoanPay_septims_label"),
    GUI_ID_LoanMenuPayTotalLoanInput = tes3ui.registerID("MenuBankLoanPay_input"),
    GUI_ID_LoanMenuPayRateLabel = tes3ui.registerID("MenuBankLoanPay_rate_label"),
}

function common.getInterestRateBank()
    local merc = tes3.mobilePlayer.mercantile.base
    return ((merc / config.mercInterestDivAccount)^(common.euler * (config.naturalMultAccount)/100) + config.baseInterestRateAccount/100)
end

function common.getInterestBank(balance)
    local rate = common.getInterestRateBank()
    return math.floor((rate + 1) * balance) - balance
end

function common.compoundInterestAccount(balance)
    local rate = common.getInterestRateBank()
    return math.floor((rate + 1) * balance)
end

function common.getAccountFee()
    local merc = tes3.mobilePlayer.mercantile.base
    return (-merc + 100) * 5
end

function common.getTextAmount(element)
    tes3ui.acquireTextInput(element)
    local amount = tonumber(element.text)
    return amount
end

function common.depositGold()
    local amount = math.floor(common.getTextAmount(tes3ui.findMenu(common.GUI_ID_AccountMenu):findChild(common.GUI_ID_BankAccountBalanceInput)))
    if (not amount) then return end
    if (amount > common.totalCopper) then
        tes3.messageBox({message = "You don't have that much money.", showInDialog = false})
    elseif (amount <= 0) then
        tes3.messageBox({message = "Enter a valid amount.", showInDialog = false})
    else
        common.totalCopper = common.totalCopper - math.floor(amount)
        common.convertDiff(math.floor(amount))
        common.totalCopperBefore = common.totalCopper
        common.accountBalance = common.accountBalance + amount
        common.GPBankData.accountBalance = common.accountBalance
        tes3ui.findMenu(common.GUI_ID_AccountMenu):findChild(common.GUI_ID_BankAccountBalanceInput).text = ("0")
        tes3ui.findMenu(common.GUI_ID_AccountMenu):findChild(common.GUI_ID_BankAccountBalance).text = ("Balance: " .. string.format("%.0f", common.accountBalance))
        tes3ui.findMenu(common.GUI_ID_AccountMenu):findChild(common.GUI_ID_BankAccountBalanceLabel).text = ("Septims: " .. common.totalCopper .. "\n")
        local accountOverview = tes3ui.findMenu(common.GUI_ID_BankMenu):findChild(common.GUI_ID_BankMenuAccountOverview)
        accountOverview.text = ("\n You currently have an account with a balance of ".. string.format("%.0f", common.accountBalance) .. " septims. \n Your account is earning " .. string.format("%.0f", common.getInterestBank(common.accountBalance)) .. " septims every " .. config.interestPeriodAccount .. " days. \n Interest Rate: " .. string.format("%.4f", common.getInterestRateBank()) .. "\n")
        local accountDetail = tes3ui.findMenu(common.GUI_ID_AccountMenu):findChild(common.GUI_ID_AccountMenuDetail)
        accountDetail.text = ("Balance: ".. string.format("%.0f", common.accountBalance) .. "\n Interest Rate: " .. string.format("%.4f", common.getInterestRateBank()) .. "\n Interest Gain: " .. string.format("%.0f", common.getInterestBank(common.accountBalance)) .. "\n")
    end
end

function common.withdrawGold()
    local amount = math.floor(common.getTextAmount(tes3ui.findMenu(common.GUI_ID_AccountMenu):findChild(common.GUI_ID_BankAccountBalanceInput)))
    if (not amount) then return end
    if (amount > common.accountBalance) then
        tes3.messageBox({message = "You don't have that much money.", showInDialog = false})
    elseif (amount <= 0) then
        tes3.messageBox({message = "Enter a valid amount.", showInDialog = false})
    else
        tes3.addItem({reference = tes3.mobilePlayer, item = "Gold_001", count = amount, playSound = true})
        common.totalCopper = common.totalCopper + amount
        common.accountBalance = common.accountBalance - amount
        common.convertDiff(-amount)
        common.totalCopperBefore = common.totalCopper
        common.GPBankData.accountBalance = common.accountBalance
        tes3ui.findMenu(common.GUI_ID_AccountMenu):findChild(common.GUI_ID_BankAccountBalanceInput).text = ("0")
        tes3ui.findMenu(common.GUI_ID_AccountMenu):findChild(common.GUI_ID_BankAccountBalance).text = ("Balance: " .. string.format("%.0f", common.accountBalance))
        tes3ui.findMenu(common.GUI_ID_AccountMenu):findChild(common.GUI_ID_BankAccountBalanceLabel).text = ("Septims: " .. common.totalCopper .. "\n")
        local accountOverview = tes3ui.findMenu(common.GUI_ID_BankMenu):findChild(common.GUI_ID_BankMenuAccountOverview)
        accountOverview.text = ("\n You currently have an account with a balance of ".. string.format("%.0f", common.accountBalance) .. " septims. \n Your account is earning " .. string.format("%.0f", common.getInterestBank(common.accountBalance)) .. " septims every " .. config.interestPeriodAccount .. " days. \n Interest Rate: " .. string.format("%.4f", common.getInterestRateBank()) .. "\n")
        local accountDetail = tes3ui.findMenu(common.GUI_ID_AccountMenu):findChild(common.GUI_ID_AccountMenuDetail)
        accountDetail.text = ("Balance: ".. string.format("%.0f", common.accountBalance) .. "\n Interest Rate: " .. string.format("%.4f", common.getInterestRateBank()) .. "\n Interest Gain: " .. string.format("%.0f", common.getInterestBank(common.accountBalance)) .. "\n")
    end
end

function common.createAccount()
    local fee = common.getAccountFee()
    if (common.totalCopper >= fee) then
        common.totalCopper = common.totalCopper - math.floor(common.getAccountFee())
        common.convertDiff(math.floor(common.getAccountFee()))
        common.totalCopperBefore = common.totalCopper
        common.accountCreated = true
        common.GPBankData.accountCreated = true
        tes3.messageBox({message = "You have opened an account.", showInDialog = false})
        common.daysTilCompound = config.interestPeriodAccount
        common.GPBankData.daysTilCompound = common.daysTilCompound
        local accountOverview = tes3ui.findMenu(common.GUI_ID_BankMenu):findChild(common.GUI_ID_BankMenuAccountOverview)
        accountOverview.text = ("\n You currently have an account with a balance of ".. string.format("%.0f", common.accountBalance) .. " septims. \n Your account is earning " .. string.format("%.0f", common.getInterestBank(common.accountBalance)) .. " septims every " .. config.interestPeriodAccount .. " days. \n Interest Rate: " .. string.format("%.4f", common.getInterestRateBank()) .. "\n")
        local accountButton = tes3ui.findMenu(common.GUI_ID_BankMenu):findChild(common.GUI_ID_BankMenuAccountButtonCreate)
        accountButton.visible = false
        accountButton = tes3ui.findMenu(common.GUI_ID_BankMenu):findChild(common.GUI_ID_BankMenuAccountButton)
        accountButton.visible = true
    else
        common.accountCreated = false
        common.GPBankData.accountCreated = false
        tes3.messageBox({message = "You don't have enough money.", showInDialog = false})
    end
end

function common.updateAccount()
    common.daysTilCompound = common.daysTilCompound - 1
    common.GPBankData.daysTilCompound = common.daysTilCompound
    if (common.daysTilCompound <= 0 and common.accountCreated) then
        local increase = common.compoundInterestAccount(common.accountBalance)
        common.accountBalance = increase
        common.GPBankData.accountBalance = common.accountBalance
        tes3.messageBox({message = "Your account has compounded interest.", showInDialog = false})
        tes3.mobilePlayer:exerciseSkill(24, (increase / (config.mercXPAccount * 10)))
        common.GPBankData.daysTilCompound = config.interestPeriodAccount
        common.daysTilCompound = common.GPBankData.daysTilCompound
    end
end

-- LOANS --

function common.getInterestRateLoan()
    local merc = tes3.mobilePlayer.mercantile.base
    return (((-(merc - 100)) / config.mercInterestDivLoan)^(common.euler * (config.naturalMultLoan)/100) + config.baseInterestRateLoan/100)
end

function common.getInterestLoan(balance)
    local rate = common.getInterestRateLoan()
    return math.floor((rate + 1) * balance) - balance
end

function common.compoundInterestLoan(balance)
    local rate = common.getInterestRateLoan()
    return math.floor((rate + 1) * balance)
end

function common.getMaxNumLoans()
    local merc = tes3.mobilePlayer.mercantile.base
    return math.floor(merc / 25)
end

function common.getMaxLoanAmount()
    local merc = tes3.mobilePlayer.mercantile.base
    return math.floor(merc * 500)
end

function common.takeOutLoan()
    local amount = common.getTextAmount(tes3ui.findMenu(common.GUI_ID_LoanMenuTake):findChild(common.GUI_ID_LoanMenuTotalLoanInput))
    if (not amount) then return end
    local npc = tes3ui.findMenu(common.GUI_ID_DialogMenu):getPropertyObject("PartHyperText_actor")
    local npcMerc = npc.mercantile.base
    local merc = tes3.mobilePlayer.mercantile.base
    local ratio = merc / npcMerc
    if (amount > common.getMaxLoanAmount() * ratio) then
        tes3.messageBox({message = "You are not trusted with that much money.", showInDialog = false})
    elseif (amount <= 0) then
        tes3.messageBox({message = "Enter a valid amount.", showInDialog = false})
    else
        common.totalCopper = common.totalCopper + math.floor(amount)
        common.convertDiff(-math.floor(amount))
        common.totalCopperBefore = common.totalCopper
        local newTime = config.interestPeriodLoan * ratio
        local newCrimePeriod = (config.crimePeriodLoan * config.crimePeriodMult) * ratio
        if (newTime < 1) then newTime = 1 end
        if (newCrimePeriod < 1) then newCrimePeriod = 1 end
        local loan = {
            npc = npc.reference.object.name,
            principal = amount,
            rate = common.getInterestRateLoan(),
            balance = amount,
            time = newTime,
            period = newCrimePeriod
        }
        table.insert(common.activeLoans, loan)
        tes3.messageBox({message = "Loan taken from " .. npc.reference.object.name, showInDialog = false})
        tes3ui.findMenu(common.GUI_ID_LoanMenu):findChild(common.GUI_ID_BankMenuLoanButtonTake).visible = false
        tes3ui.findMenu(common.GUI_ID_LoanMenu):findChild(common.GUI_ID_BankMenuLoanButtonPay).visible = true
        tes3ui.findMenu(common.GUI_ID_LoanMenu):findChild(common.GUI_ID_LoanMenuOverview).text = ("\n You currently have " .. #(common.activeLoans) .. " active loans. \n ")
        local loanDetail = tes3ui.findMenu(common.GUI_ID_LoanMenu):findChild(common.GUI_ID_LoanMenuDetail)
        loanDetail.autoHeight = true
        loanDetail.widthProportional = 1
        loanDetail.visible = true
        loanDetail.childAlignX = 0
        for _, activeLoan in pairs(common.activeLoans) do
            local tempID = "GPBankActiveLoan" .. activeLoan.npc
            local activeLoanText = loanDetail:createLabel({id = tempID, text = "Loan from " .. activeLoan.npc .. "\n" .. "Principal - " .. activeLoan.principal .. "\nRate - "  .. string.format("%.4f", activeLoan.rate) .. "\nBalance Remaining - " .. string.format("%.0f", activeLoan.balance) .. "\nTime Remaining - " .. activeLoan.period .. " \n"})
            if (activeLoan.period < 5) then
                activeLoanText.color = {0.610, 0.0122, 0.0122}
            else
                activeLoanText.color = {0.875, 0.788, 0.624}
            end
            activeLoanText.visible = true
            activeLoanText.wrapText = 1
            activeLoanText.justifyText = "center"
            activeLoanText.autoHeight = true
            activeLoanText.autoWidth = true
        end
        tes3ui.findMenu(common.GUI_ID_LoanMenu).visible = true
        tes3ui.findMenu(common.GUI_ID_LoanMenuTake):destroy()
    end
end

function common.getLoanFromNPC(npc)
    for _, activeLoan in pairs(common.activeLoans) do
        if (npc.reference.object.name == activeLoan.npc) then
            return activeLoan
        end
    end
end

function common.payOffLoan()
    local amount = common.getTextAmount(tes3ui.findMenu(common.GUI_ID_LoanMenuPay):findChild(common.GUI_ID_LoanMenuPayTotalLoanInput))
    if (not amount) then return end
    local npc = tes3ui.findMenu(common.GUI_ID_DialogMenu):getPropertyObject("PartHyperText_actor")
    local loanNpc
    local paidOff = false
    local loan
    local activeLoan = common.getLoanFromNPC(npc)
    if (activeLoan and activeLoan.npc == npc.reference.object.name) then
        loan = activeLoan
        loanNpc = activeLoan.npc
    end
    if (amount > common.totalCopper) then
        tes3.messageBox({message = "You don't have that much money.", showInDialog = false})
    elseif (amount <= 0) then
        tes3.messageBox({message = "Enter a valid amount.", showInDialog = false})
    else
        common.totalCopper = common.totalCopper - math.floor(amount)
        common.convertDiff(math.floor(amount))
        common.totalCopperBefore = common.totalCopper
        loan.balance = loan.balance - amount
        for i, activeLoan in pairs(common.activeLoans) do
            if (activeLoan.npc == loanNpc) then
                common.activeLoans[i].balance = loan.balance
            end
            tes3ui.findMenu(common.GUI_ID_LoanMenu):findChild("GPBankActiveLoan" .. loanNpc).text = "Loan from " .. activeLoan.npc .. "\n" .. "Principal - " .. activeLoan.principal .. "\nRate - "  .. string.format("%.4f", activeLoan.rate) .. "\nBalance Remaining - " .. string.format("%.0f", activeLoan.balance) .. "\nTime Remaining - " .. math.floor(activeLoan.period) .. " \n"
            tes3ui.findMenu(common.GUI_ID_LoanMenuPay):findChild(common.GUI_ID_LoanMenuPayDescription).text = ("Here you can pay off your loan to a lender. \n Balance: " .. common.getLoanFromNPC(npc).balance)
            tes3ui.findMenu(common.GUI_ID_LoanMenuPay):findChild(common.GUI_ID_LoanMenuPayTotalSeptimsLabel).text = ("Septims: " .. common.totalCopper .. "\n")
        end
        if (loan.balance <= 0) then
            paidOff = true
        end
        if paidOff then
            tes3ui.findMenu(common.GUI_ID_LoanMenu):findChild("GPBankActiveLoan" .. loanNpc):destroy()
            tes3.messageBox({message = "Loan from " .. npc.reference.object.name .. " paid off", showInDialog = false})
            for i, activeLoan in pairs(common.activeLoans) do
                if (npc.reference.object.name == activeLoan.npc) then
                    common.activeLoans[i] = nil
                end
            end
        end
        if (#(common.activeLoans) > 0) then
            if (#(common.activeLoans) <= common.activeLoanMax and common.GPBankData.loanCrime == false) then
                tes3ui.findMenu(common.GUI_ID_LoanMenu):findChild(common.GUI_ID_BankMenuLoanButtonTake).visible = true
            else
                tes3ui.findMenu(common.GUI_ID_LoanMenu):findChild(common.GUI_ID_BankMenuLoanButtonTake).visible = false
            end
            tes3ui.findMenu(common.GUI_ID_LoanMenu):findChild(common.GUI_ID_BankMenuLoanButtonPay).visible = true
            tes3ui.findMenu(common.GUI_ID_LoanMenu):findChild(common.GUI_ID_LoanMenuOverview).text = ("\n You currently have " .. #(common.activeLoans) .. " active loans. ")
        elseif (common.GPBankData.loanCrime == true) then
            tes3ui.findMenu(common.GUI_ID_LoanMenu):findChild(common.GUI_ID_BankMenuLoanButtonTake).visible = false
        else
            tes3ui.findMenu(common.GUI_ID_LoanMenu):findChild(common.GUI_ID_BankMenuLoanButtonTake).visible = true
            tes3ui.findMenu(common.GUI_ID_LoanMenu):findChild(common.GUI_ID_BankMenuLoanButtonPay).visible = false
            tes3ui.findMenu(common.GUI_ID_LoanMenu):findChild(common.GUI_ID_LoanMenuOverview).text = ("\n You do not currently have any active loans.")
        end
            tes3ui.findMenu(common.GUI_ID_LoanMenu).visible = true
            tes3ui.findMenu(common.GUI_ID_LoanMenuPay):destroy()
    end
end

function common.updateLoans()
	for id, activeLoan in pairs(common.activeLoans) do
        activeLoan.period = activeLoan.period - 1
        activeLoan.time = activeLoan.time - 1
		if (activeLoan.time <= 0) then
            local increase = common.compoundInterestLoan(activeLoan.balance)
            activeLoan.balance = increase
            tes3.messageBox({message = "Your loan has compounded interest.", showInDialog = false})
            tes3.mobilePlayer:exerciseSkill(24, (increase / (config.mercXPLoan * 10)))
		end
        if (activeLoan.period <= 0) then
            if (tes3.mobilePlayer.bounty + activeLoan.balance >= 5000) then
                if(tes3.mobilePlayer.bounty > 5000) then
                    tes3.mobilePlayer.bounty = tes3.mobilePlayer.bounty + activeLoan.balance
                else
                    tes3.mobilePlayer.bounty = 4999
                end
                common.GPBankData.loanCrime = true
                tes3.messageBox("Your loan has defaulted.")
                tes3.messageBox(tes3.findGMST("sCrimeMessage").value)
                activeLoan = nil
            elseif (tes3.mobilePlayer.bounty + activeLoan.balance < 5000) then
                tes3.mobilePlayer.bounty = tes3.mobilePlayer.bounty + activeLoan.balance
                common.GPBankData.loanCrime = true
                tes3.messageBox("Your loan has defaulted.")
                tes3.messageBox(tes3.findGMST("sCrimeMessage").value)
                activeLoan = nil
            end
        end
	end
	common.GPBankData.activeLoans = common.activeLoans
end

-- INVESTMENTS

function common.getMaxNumInvestments()
    local merc = tes3.mobilePlayer.mercantile.base
    return (merc * config.maxInvestmentMercMult)
end

function common.getTotalOwnedShares()
    local totalShares = 0
    for _, commodity in pairs(common.GPBankData.allCommodities) do
        totalShares = totalShares + commodity.owned
    end
    return totalShares
end

function common.getInvestmentValueTotal()
    local totalValue = 0
    for _, commodity in pairs(common.GPBankData.allCommodities) do
        totalValue = totalValue + (commodity.owned * commodity.currentPrice)
    end
    return string.format("%.0f", totalValue)
end

function common.calcNewPrice(risk, merc)
    local sign
    local luck = tes3.mobilePlayer.luck.current
    local roll = math.random(-risk, risk)
    local rand = roll + (luck / 50) + 1
    --if risk < 0 then
       --return (risk * math.abs(rand / 15) + 1)^((common.euler * (rand - 1)) / ((luck / 5) * (merc / 2)) - 0.4)
    --else
        --return (risk * math.abs(rand / 15) + 1)^((common.euler * (rand - 1)) * ((luck / 400) * (merc / 800)) + 0.2)
    --end
    return (risk * math.abs(rand / 15) + 1)^(((common.euler * (rand - (1))) / (600 / merc)) - (0.5 / merc))
end

function common.updateInvestments()
    local startingPrice
    local currentPrice
    local lastPrice
    local merc = tes3.mobilePlayer.mercantile.current
    local newPrice
    local risk
	for _, commodity in pairs(common.allCommodities) do
        startingPrice = commodity.startingPrice
        currentPrice = commodity.currentPrice
        lastPrice = commodity.lastPrice
        risk = commodity.volatility
        newPrice = common.calcNewPrice(risk, merc)
        commodity.lastPrice = commodity.currentPrice
        commodity.currentPrice = newPrice * commodity.lastPrice
        if (commodity.currentPrice < 0) then
            commodity.currentPrice = 0
        end
        commodity.change = commodity.currentPrice - commodity.lastPrice
	end
    local investChange = common.getTotalInvestmentChange()
	common.GPBankData.allCommodities = common.allCommodities
    common.daysTilReset = common.daysTilReset - 1
    common.GPBankData.daysTilReset = common.daysTilReset
    if (config.resetShareTimer ~= 0 and (common.daysTilReset <= 0)) then
        common.resetCommodityPrices()
        common.GPBankData.daysTilReset = config.resetShareTimer
        common.daysTilReset = common.GPBankData.daysTilReset
    end
end

function common.getTotalInvestmentChange()
    local totalChange = 0
    for _, commodity in pairs(common.allCommodities) do
        if (commodity.owned > 0) then
            totalChange = totalChange + (commodity.change * commodity.owned)
        end
    end
    return totalChange
end

function common.resetCommodityPrices()
    for _, commodity in pairs(common.allCommodities) do
        commodity.currentPrice = commodity.startingPrice
        commodity.lastPrice = commodity.startingPrice
        commodity.change = 0
    end
    common.updateCommodityLists()
end

function common.updateCommodityLists()
    for _, commodity in pairs(common.commodities1) do
        for _, allCommodity in pairs(common.allCommodities) do
            if (commodity.name == allCommodity.name) then
                commodity.currentPrice = allCommodity.currentPrice
                commodity.lastPrice = allCommodity.lastPrice
                commodity.change = allCommodity.change
                commodity.owned = allCommodity.owned
            end
        end
    end
    for _, commodity in pairs(common.commodities2) do
        for _, allCommodity in pairs(common.allCommodities) do
            if (commodity.name == allCommodity.name) then
                commodity.currentPrice = allCommodity.currentPrice
                commodity.lastPrice = allCommodity.lastPrice
                commodity.change = allCommodity.change
                commodity.owned = allCommodity.owned
            end
        end
    end
    for _, commodity in pairs(common.commodities3) do
        for _, allCommodity in pairs(common.allCommodities) do
            if (commodity.name == allCommodity.name) then
                commodity.currentPrice = allCommodity.currentPrice
                commodity.lastPrice = allCommodity.lastPrice
                commodity.change = allCommodity.change
                commodity.owned = allCommodity.owned
            end
        end
    end
    for _, commodity in pairs(common.commodities4) do
        for _, allCommodity in pairs(common.allCommodities) do
            if (commodity.name == allCommodity.name) then
                commodity.currentPrice = allCommodity.currentPrice
                commodity.lastPrice = allCommodity.lastPrice
                commodity.change = allCommodity.change
                commodity.owned = allCommodity.owned
            end
        end
    end
    for _, commodity in pairs(common.commodities5) do
        for _, allCommodity in pairs(common.allCommodities) do
            if (commodity.name == allCommodity.name) then
                commodity.currentPrice = allCommodity.currentPrice
                commodity.lastPrice = allCommodity.lastPrice
                commodity.change = allCommodity.change
                commodity.owned = allCommodity.owned
            end
        end
    end
    for _, commodity in pairs(common.commodities6) do
        for _, allCommodity in pairs(common.allCommodities) do
            if (commodity.name == allCommodity.name) then
                commodity.currentPrice = allCommodity.currentPrice
                commodity.lastPrice = allCommodity.lastPrice
                commodity.change = allCommodity.change
                commodity.owned = allCommodity.owned
            end
        end
    end
    for _, commodity in pairs(common.commodities7) do
        for _, allCommodity in pairs(common.allCommodities) do
            if (commodity.name == allCommodity.name) then
                commodity.currentPrice = allCommodity.currentPrice
                commodity.lastPrice = allCommodity.lastPrice
                commodity.change = allCommodity.change
                commodity.owned = allCommodity.owned
            end
        end
    end
end

-- CURRENCY

function common.convertDiff(diff)
    common.fixCounts()
    if (diff ~= 0) then
        if diff < 0 then
            common.convertGain(math.abs(diff))
        elseif diff > 0 then
            common.convertLoss(math.abs(diff))
        end
    end
    common.fixCounts()
end

function common.fixCounts()
    for _, currencyObj in pairs(common.counts) do
        local count = common.counts[currencyObj.id].count
        local amount = count * currencyObj.value
        if (count > 0 and tes3.getItemCount({reference = tes3.mobilePlayer, item = currencyObj.id}) < count) then
            tes3.addItem({reference = tes3.mobilePlayer, item = currencyObj.id, count = count, playSound = false})
            tes3.removeItem({reference = tes3.mobilePlayer, item = "Gold_001", count = amount, playSound = false})
        elseif (count < tes3.getItemCount({reference = tes3.mobilePlayer, item = currencyObj.id})) then
            tes3.removeItem({reference = tes3.mobilePlayer, item = currencyObj.id, count = (tes3.getItemCount({reference = tes3.mobilePlayer, item = currencyObj.id}) - count), playSound = false})
        end
    end
end

function common.pickBestDenomination(amount)
    local price = math.abs(amount)
    local highestBill = {
        value = 1,
        id = "Gold_001",
    }
    for _, currencyObj in pairs(common.counts) do
        if currencyObj.value > highestBill.value and common.counts[currencyObj.id].count > 0 then
            highestBill.value = currencyObj.value
            highestBill.id = currencyObj.id
        end
    end
    return highestBill
end

function common.getActualCopper(totalCopper)
    for _, currency in pairs(common.counts) do
        totalCopper = totalCopper - (currency.count * currency.value)
    end
    return totalCopper
end

function common.convertLoss(diff)
    if (diff ~= 0) then
        local totalBills = 0
        for _, bill in pairs(common.counts) do
            if bill.count > 0 then
                totalBills = totalBills + bill.count
            end
        end
        if (totalBills == 0) then
            tes3.removeItem({reference = tes3.mobilePlayer, item = "Gold_001", count = diff, playSound = false})
            diff = 0
        end
        while (diff > 0 and totalBills > 0) do
            local highest = common.pickBestDenomination(diff)
            for _, currencyObj in pairs(common.counts) do
                if (currencyObj.value == highest.value) then
                    while ((currencyObj.count > 0) and diff > 0) do
                        currencyObj.count = currencyObj.count - 1
                        totalBills = totalBills - 1
                        diff = diff - currencyObj.value
                    end
                end
            end
        end
    end
    if diff > 0 then
        tes3.addItem({reference = tes3.mobilePlayer, item = "Gold_001", count = diff, playSound = false})
    elseif diff < 0 then
        common.convertGain(math.abs(diff))
    end
end

function common.convertGain(diff)
    while diff >= 1000 do
        common.counts["GPBankSeptimPaper1000"].count = common.counts["GPBankSeptimPaper1000"].count + 1
        diff = diff - 1000
    end
    while diff >= 500 do
        common.counts["GPBankSeptimPaper0500"].count = common.counts["GPBankSeptimPaper0500"].count + 1
        diff = diff - 500
    end
    while diff >= 100 do
        common.counts["GPBankSeptimPaper0100"].count = common.counts["GPBankSeptimPaper0100"].count + 1
        diff = diff - 100
    end
    while diff >= 50 do
        common.counts["GPBankSeptimPaper0050"].count = common.counts["GPBankSeptimPaper0050"].count + 1
        diff = diff - 50
    end
    while diff >= 20 do
        common.counts["GPBankSeptimPaper0020"].count = common.counts["GPBankSeptimPaper0020"].count + 1
        diff = diff - 20
    end
    while diff >= 10 do
        common.counts["GPBankSeptimPaper0010"].count = common.counts["GPBankSeptimPaper0010"].count + 1
        diff = diff - 10
    end
    while diff >= 5 do
        common.counts["GPBankSeptimPaper0005"].count = common.counts["GPBankSeptimPaper0005"].count + 1
        diff = diff - 5
    end
end

function common.updateCounts()
    for _, currencyObj in pairs(common.currency) do
        for _, itemStack in pairs(tes3.mobilePlayer.inventory) do
            if ((currencyObj.id == itemStack.object.id)) then
                common.counts[currencyObj.id].count = itemStack.count
            end
        end
    end
end

function common.updateCountsOnExit()
    for _, currencyObj in pairs(common.counts) do
        if (tes3.getItemCount({reference = tes3.mobilePlayer, item = currencyObj.id}) == 0) then
            common.counts[currencyObj.id].count = 0
        end
    end
    local diff = common.actualCopper - tes3.getPlayerGold()
    if (diff > 0) then
        tes3.addItem(tes3.addItem({reference = tes3.mobilePlayer, item = "Gold_001", count = diff, playSound = false}))
    end
end

function common.emptyCounts()
    for _, currencyObj in pairs(common.counts) do
        if (tes3.getItemCount({reference = tes3.mobilePlayer, item = currencyObj.id}) == 0) then
            common.counts[currencyObj.id].count = 0
        end
    end
end

function common.enterMenu()
    local totalCopperAdded = 0
    common.emptyCounts()
    common.updateCounts()
    for _, currencyObj in pairs(common.counts) do
        if (currencyObj.count ~= 0) then
            totalCopperAdded = totalCopperAdded +  (currencyObj.count * currencyObj.value)
            tes3.addItem({reference = tes3.mobilePlayer, item = "Gold_001", count = currencyObj.count * currencyObj.value, playSound = false})
            tes3.removeItem({reference = tes3.mobilePlayer, item = currencyObj.id, count = currencyObj.count, playSound = false})
        end
    end
    common.totalCopper = tes3.getPlayerGold()
    common.actualCopperBefore = common.totalCopper - totalCopperAdded
    common.totalCopperBefore = common.totalCopper
    common.converted = true
end

function common.exitBankMenu()
    local actualCopper = common.getActualCopper(common.totalCopper)
    local newTotalCopper = tes3.getPlayerGold()
    local spareChange = 0
    local diff = common.totalCopperBefore - common.totalCopper
    common.convertDiff(diff)
    spareChange = (common.totalCopper - newTotalCopper) % 5
    common.totalCopperBefore = newTotalCopper
    common.totalCopper = newTotalCopper
    if (spareChange > 0) then
        tes3.addItem({reference = tes3.mobilePlayer, item = "Gold_001", count = spareChange, playSound = false})
    end
    common.enterMenu()
end

function common.initCounts()
    for _, currencyObj in pairs(common.currency) do
        common.counts[currencyObj.id] = {}
        common.counts[currencyObj.id].id = currencyObj.id
        common.counts[currencyObj.id].name = currencyObj.name
        common.counts[currencyObj.id].value = currencyObj.value
        common.counts[currencyObj.id].count = 0
    end
end

function common.removeCoinStacks()
    for _, itemStack in pairs(tes3.mobilePlayer.inventory) do
        if (itemStack.object.id == "GPBankSeptimGold_005") then
            tes3.addItem({reference = tes3.mobilePlayer, item = "GPBankSeptimGold", count = itemStack.count * 5, playSound = false})
            tes3.removeItem({reference = tes3.mobilePlayer, item = itemStack.object, count = itemStack.count, playSound = false})
        elseif (itemStack.object.id == "GPBankSeptimGold_010") then
            tes3.addItem({reference = tes3.mobilePlayer, item = "GPBankSeptimGold", count = itemStack.count * 10, playSound = false})
            tes3.removeItem({reference = tes3.mobilePlayer, item = itemStack.object, count = itemStack.count, playSound = false})
        elseif (itemStack.object.id == "GPBankSeptimGold_025") then
            tes3.addItem({reference = tes3.mobilePlayer, item = "GPBankSeptimGold", count = itemStack.count * 25, playSound = false})
            tes3.removeItem({reference = tes3.mobilePlayer, item = itemStack.object, count = itemStack.count, playSound = false})
        elseif (itemStack.object.id == "GPBankSeptimGold_100") then
            tes3.addItem({reference = tes3.mobilePlayer, item = "GPBankSeptimGold", count = itemStack.count * 100, playSound = false})
            tes3.removeItem({reference = tes3.mobilePlayer, item = itemStack.object, count = itemStack.count, playSound = false})
        elseif (itemStack.object.id == "GPBankGold_Dae_cursed_001") then
            tes3.addItem({reference = tes3.mobilePlayer, item = "GPBankSeptimGold", count = itemStack.count, playSound = false})
            tes3.removeItem({reference = tes3.mobilePlayer, item = itemStack.object, count = itemStack.count, playSound = false})
        elseif (itemStack.object.id == "GPBankGold_Dae_cursed_005") then
            tes3.addItem({reference = tes3.mobilePlayer, item = "GPBankSeptimGold", count = itemStack.count * 5, playSound = false})
            tes3.removeItem({reference = tes3.mobilePlayer, item = itemStack.object, count = itemStack.count, playSound = false})
        elseif (itemStack.object.id == "GPBankSeptimSilver_005") then
            tes3.addItem({reference = tes3.mobilePlayer, item = "GPBankSeptimSilver", count = itemStack.count * 5, playSound = false})
            tes3.removeItem({reference = tes3.mobilePlayer, item = itemStack.object, count = itemStack.count, playSound = false})
        elseif (itemStack.object.id == "GPBankSeptimSilver_010") then
            tes3.addItem({reference = tes3.mobilePlayer, item = "GPBankSeptimSilver", count = itemStack.count * 10, playSound = false})
            tes3.removeItem({reference = tes3.mobilePlayer, item = itemStack.object, count = itemStack.count, playSound = false})
        elseif (itemStack.object.id == "GPBankSeptimSilver_025") then
            tes3.addItem({reference = tes3.mobilePlayer, item = "GPBankSeptimSilver", count = itemStack.count * 25, playSound = false})
            tes3.removeItem({reference = tes3.mobilePlayer, item = itemStack.object, count = itemStack.count, playSound = false})
        elseif (itemStack.object.id == "GPBankSeptimSilver_100") then
            tes3.addItem({reference = tes3.mobilePlayer, item = "GPBankSeptimSilver", count = itemStack.count * 100, playSound = false})
            tes3.removeItem({reference = tes3.mobilePlayer, item = itemStack.object, count = itemStack.count, playSound = false})
        elseif (itemStack.object.id == "GPBankSilver_Dae_cursed_001") then
            tes3.addItem({reference = tes3.mobilePlayer, item = "GPBankSeptimSilver", count = itemStack.count * 100, playSound = false})
            tes3.removeItem({reference = tes3.mobilePlayer, item = itemStack.object, count = itemStack.count, playSound = false})
        elseif (itemStack.object.id == "GPBankSilver_Dae_cursed_005") then
            tes3.addItem({reference = tes3.mobilePlayer, item = "GPBankSeptimSilver", count = itemStack.count * 5, playSound = false})
            tes3.removeItem({reference = tes3.mobilePlayer, item = itemStack.object, count = itemStack.count, playSound = false})
        end
    end
end

return common