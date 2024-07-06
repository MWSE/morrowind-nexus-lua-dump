local config  = require("gpbank.config")
local modName = 'Wealth Beyond Measure';
local template = mwse.mcm.createTemplate(modName)
template:saveOnClose(modName, config)
template:register()

local function createPage(label)
    local page = template:createSideBarPage {
        label = label,
        noScroll = false,
    }
    page.sidebar:createInfo {
        text = "Wealth Beyond Measure \n\n by GOOGLEPOX \n\n This mod adds various new denominations of currency. \n\n Use this MCM to tweak the values and weights to your liking."
    }
    return page
end

-- BANK

local settings = createPage("Bank Settings")

local accountSettings = settings:createCategory("Account Settings")

accountSettings:createSlider {
    label = "Base Interest Rate (Account)",
    description = "Sets the base interest rate for the player account. This rate is added to the calculated Mercantile rate. Value is divided by 100.",
    max = 100,
    min = 0,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "baseInterestRateAccount",
        table = config
    }
}

accountSettings:createSlider {
    label = "Mercantile Divisor (Account)",
    description = "Divides the player Mercantile skill by this amount, then raises to power of e. Finally adds the base interest rate. Higher values mean much slower interest gain; lower much faster.",
    max = 250,
    min = 1,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "mercInterestDivAccount",
        table = config
    }
}

accountSettings:createSlider {
    label = "Natural Multiplier (Account)",
    description = "Multiplies e by this value (divided by 100) when raising the calculated rate. Full formula: ((mercantile / divisor) ^ (e * naturalMult)) + baseInterest",
    max = 200,
    min = 1,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "naturalMultAccount",
        table = config
    }
}

accountSettings:createSlider {
    label = "Interest Period (Account)",
    description = "Every x days, compounds interest. Default: 7",
    max = 100,
    min = 1,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "interestPeriodAccount",
        table = config
    }
}

accountSettings:createSlider {
    label = "Mercantile Experience Divisor (Account)",
    description = "Every time the player's account compounds interest, adds Mercantile XP equal to the profit / this value * 10",
    max = 100,
    min = 0,
    step = 10,
    jump = 10,
    variable = mwse.mcm:createTableVariable {
        id = "mercXPAccount",
        table = config
    }
}

local loanSettings = settings:createCategory("Loan Settings")

loanSettings:createSlider {
    label = "Base Interest Rate (Loan)",
    description = "Sets the base interest rate for player loans. This rate is added to the calculated Mercantile rate. Value is divided by 100.",
    max = 100,
    min = 0,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "baseInterestRateAccount",
        table = config
    }
}

loanSettings:createSlider {
    label = "Mercantile Divisor (Loan)",
    description = "Divides the player Mercantile skill (negated and minus 100) by this amount, then raises to power of (e * naturalMult). Higher values mean much slower interest gain; lower much faster.",
    max = 500,
    min = 100,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "mercInterestDivLoan",
        table = config
    }
}

loanSettings:createSlider {
    label = "Natural Multiplier (Loan)",
    description = "Multiplies e by this value (divided by 100) when raising the calculated rate. Full formula: (( - (mercantile - 100) / divisor) ^ (e * naturalMult)) + baseInterest",
    max = 200,
    min = 1,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "naturalMultLoan",
        table = config
    }
}

loanSettings:createSlider {
    label = "Interest Period (Loan)",
    description = "Every x days, compounds interest. Default: 7",
    max = 100,
    min = 1,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "interestPeriodLoan",
        table = config
    }
}

loanSettings:createSlider {
    label = "Mercantile Experience Divisor (Loan)",
    description = "Every time the player's loan compounds interest, adds Mercantile XP equal to the principal increase / this value * 10",
    max = 100,
    min = 0,
    step = 10,
    jump = 10,
    variable = mwse.mcm:createTableVariable {
        id = "mercXPLoan",
        table = config
    }
}

loanSettings:createSlider {
    label = "Repayment Period Base (Loan)",
    description = "Time to repay the loan in full plus any interest. If this time passes and you still have any loan balances, you will default and accrue a bounty.",
    max = 100,
    min = 1,
    step = 10,
    jump = 10,
    variable = mwse.mcm:createTableVariable {
        id = "crimePeriodLoan",
        table = config
    }
}

loanSettings:createSlider {
    label = "Repayment Period Mercantile Mult (Loan)",
    description = "Multiplies the base loan repayment period by this value.",
    max = 10,
    min = 1,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "crimePeriodMult",
        table = config
    }
}

local investmentSettings = settings:createCategory("Investment Settings")

investmentSettings:createSlider {
    label = "Max Number of Investments",
    description = "The maximum number of current investments is this value multiplied by the player's Mercantile skill.",
    max = 100,
    min = 0,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "maxInvestmentMercMult",
        table = config
    }
}

investmentSettings:createSlider {
    label = "Mercantile Experience Divisor (Investments)",
    description = "Every time the player sells shares at a profit, adds Mercantile XP equal to the profit / this value * 100",
    max = 100,
    min = 0,
    step = 10,
    jump = 10,
    variable = mwse.mcm:createTableVariable {
        id = "mercXPInvest",
        table = config
    }
}

-- CURRENCY

settings = createPage("Currency Settings")

-- Value Settings
local valueSettings = settings:createCategory("Value Settings")

valueSettings:createSlider {
    label = "Platinum Septim Value",
    description = "Set the value of a platinum Septim. Requires game restart.",
    max = 5000,
    min = 1,
    step = 5,
    jump = 5,
    variable = mwse.mcm:createTableVariable {
        id = "septimGoldValue",
        table = config
    }
}

valueSettings:createSlider {
    label = "Rose Gold Septim Value",
    description = "Set the value of a rose gold Septim. Requires game restart.",
    max = 1000,
    min = 1,
    step = 5,
    jump = 5,
    variable = mwse.mcm:createTableVariable {
        id = "septimSilverValue",
        table = config
    }
}

-- Weight Settings
local weightSettings = settings:createCategory("Weight Settings")

valueSettings:createTextField({
    label = "Platinum Weight",
    description = "The weight per platinum coin. Number will be divided by 100.",
    numbersOnly = true,
    variable = mwse.mcm:createTableVariable{id = "septimGoldWeight", table = config },
})

valueSettings:createTextField({
    label = "Rose Gold Weight",
    description = "The weight per rose gold coin. Number will be divided by 100.",
    numbersOnly = true,
    variable = mwse.mcm:createTableVariable{id = "septimSilverWeight", table = config },
})

valueSettings:createTextField({
    label = "Letter of Credit Weight",
    description = "The weight per Letter of Credit. Number will be divided by 100.",
    numbersOnly = true,
    variable = mwse.mcm:createTableVariable{id = "septimPaperWeight", table = config },
})

-- Global Settings

settings = createPage("Global Settings")
local globalSettings = settings:createCategory("Global Settings")

globalSettings:createYesNoButton({
    label = "Add Banking Services to Pawnbrokers",
    description = "All Pawnbrokers in the game (mods included) will now offer Imperial Banking services.",
    defaultSetting = true,
    variable = mwse.mcm:createTableVariable({ id = "enablePawnbrokers", table = config }),
})

globalSettings:createYesNoButton({
    label = "Reset Share Prices",
    description = "Reset Share Prices",
    defaultSetting = false,
    variable = mwse.mcm:createTableVariable({ id = "resetSharePrices", table = config }),
})

globalSettings:createSlider {
    label = "Share Reset Period",
    description = "Time before all investment shares reset to their initial price. Set to 0 to disable.",
    max = 100,
    min = 0,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "resetShareTimer",
        table = config
    }
}