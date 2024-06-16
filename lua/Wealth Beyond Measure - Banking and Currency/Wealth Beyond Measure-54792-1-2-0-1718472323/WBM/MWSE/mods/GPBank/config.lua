local defaultConfig = {

    baseInterestRateAccount = 2,
    mercInterestDivAccount = 150,
    naturalMultAccount = 70,
    interestPeriodAccount = 7,
    mercXPAccount = 20,

    baseInterestRateLoan = 10,
    mercInterestDivLoan = 400,
    naturalMultLoan = 50,
    interestPeriodLoan = 7,
    mercXPLoan = 10,
    crimePeriodLoan = 14,
    crimePeriodMult = 1,

    maxInvestmentMercMult = 1,
    mercXPInvest = 30,

	septimGoldWeight = 50,
    septimSilverWeight = 25,
    septimGoldValue = 100,
    septimSilverValue = 25,
    septimPaperWeight = 1,

    enablePawnbrokers = true,
    resetSharePrices = false,
    resetShareTimer = 14,
}

local mwseConfig = mwse.loadConfig("Wealth Beyond Measure", defaultConfig)

return mwseConfig;