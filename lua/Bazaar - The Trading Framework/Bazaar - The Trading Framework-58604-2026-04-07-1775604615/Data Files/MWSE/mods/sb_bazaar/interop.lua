--- @class BazaarCurrencyInterop
--- @field currencies table<string, BazaarCurrencyData>
--- @field goldAlt table<string, GoldDenominationData>
--- @field banks table<string, BazaarMerchantBankData>
--- @field merchants table<string, BazaarMerchantBankData>
--- @field complexBanks table<function, BazaarMerchantBankData>
--- @field complexMerchants table<function, BazaarMerchantBankData>
local interop =
{
    currencies = {},
    goldAlt = {},
    banks = {},
    merchants = {},
    complexBanks = {},
    complexMerchants = {}
}

--- @class BazaarCurrencyData
--- @field symbolPattern string The string pattern used to represent the currency using `%d`. For example: "%d gp", "gold worth %d".
--- @field properties BazaarCurrencyProperties?
--- @field modProperties BazaarCurrencyModProperties? Custom properties for other mods.

--- @class BazaarCurrencyProperties
--- @field denominations table<string, BazaarDenominationData>? Alternate object IDs for denominations of the currency and their associated data.
--- @field stackingMeshes table<string, number>? Alternate object meshes for currency stacks.
--- @field pluralName string? The plural form of the currency's name.
--- @field soundId string? The sound effect played when the currency is exchanged.
--- @field tradeOnly boolean? Hide the currency in the merchant's barter menu.

--- @class BazaarCurrencyModProperties
--- @field uiExpIcon string? The path to the UI icon for the currency.

--- @class BazaarDenominationData
--- @field value number The denomination value of the currency. Note: This can be a decimal, but only whole values can be exchanged at banks.
--- @field properties BazaarDenominationProperties?
--- @field modProperties table<string, any>? Custom properties for other mods.

--- @class BazaarDenominationProperties
--- @field stackingMeshes table<string, number>? Alternate object meshes for denomination stacks.
--- @field pluralName string? The plural form of the denomination's name.
--- @field soundId string? The sound effect played when the denomination is exchanged.
--- @field tradeOnly boolean? Hide the denomination in the merchant's barter menu.

--- @class GoldDenominationData
--- @field value number The gold conversion of the currency. Note: This can be a decimal, but only whole values can be exchanged at banks.
--- @field properties GoldDenominationProperties
--- @field modProperties table<string, any>? Custom properties for other mods.

--- @class GoldDenominationProperties
--- @field stackingMeshes table<string, number>? Alternate object meshes for denomination stacks.
--- @field pluralName string? The plural form of the denomination's name.
--- @field soundId string? The sound effect played when the denomination is exchanged.
--- @field tradeOnly boolean? Hide the denomination in the merchant's barter menu.

--- @class BazaarMerchantBankData
--- @field acceptedCurrencies table<string, number> The object IDs of the currencies accepted by the merchant or bank and their barter amount.
--- @field acceptedDenominations table<string, number> The object IDs of the denominations accepted by the merchant or bank and their barter amount.
--- @field acceptsGold boolean? Default: true

---------

--- @return table<string, BazaarCurrencyData>
function interop.getCurrencies()
    return interop.currencies
end

--- @return table<string, GoldDenominationData>
function interop.getGoldDenominations()
    return interop.goldAlt
end

--- @return table<string, BazaarMerchantBankData>
function interop.getBanks()
    return interop.banks
end

--- @return table<string, BazaarMerchantBankData>
function interop.getMerchants()
    return interop.merchants
end

--- Custom currencies only.
--- @param id string
--- @return BazaarCurrencyData?
function interop.getCurrency(id)
    return interop.currencies[id]
end

--- Custom currencies only.
--- @param id string
--- @return table<string, BazaarDenominationData>?
function interop.getDenominations(id)
    return interop.getCurrency(id) and interop.getCurrency(id).properties.denominations or nil
end

--- Custom currencies and gold.
--- @param cid string The currency's object ID.
--- @param did string The denomination's object ID.
--- @return BazaarDenominationData?
function interop.getDenomination(cid, did)
    local currencyData = interop.getCurrency(cid)
    if (currencyData) then
        return currencyData.properties.denominations[cid]
    elseif (cid == "Gold_001") then
        return interop.getGoldDenomination(did)
    else
        return nil
    end
end

--- Gold only.
--- @param id string
--- @return GoldDenominationData?
function interop.getGoldDenomination(id)
    return interop.goldAlt[id]
end

--- @param npcId string
--- @return BazaarMerchantBankData?
function interop.getBank(npcId)
    return interop.banks[npcId]
end

--- @param npcId string
--- @return BazaarMerchantBankData?
function interop.getMerchant(npcId)
    return interop.merchants[npcId]
end

--- @class ReferenceCurrencyData
--- @field includeDenominations boolean?
--- @field includeBarter boolean?

--- Gold only.
--- @param ref tes3reference
--- @param options ReferenceCurrencyData?
--- @return number?
function interop.getReferenceGold(ref, options)
    return interop.getReferenceCurrency(ref, "Gold_001", options)
end

--- Custom currencies and gold and denominations.
--- @param ref tes3reference
--- @param id string
--- @param options ReferenceCurrencyData?
--- @return number?
function interop.getReferenceCurrency(ref, id, options)
    local currencyData = interop.getCurrency(id)
    if (currencyData) then
        local count = tes3.getItemCount{reference = ref, item = id}
        if (options) then
            if (options.includeDenominations) then
                for did, denominationData in pairs(currencyData.properties.denominations) do
                    count = count + (denominationData.value * tes3.getItemCount{reference = ref, item = did})
                end
            end
            if (options.includeBarter) then
                count = count + (interop.getReferenceBarter(ref, id) or 0)
            end
        end
        return count
    elseif (id == "Gold_001") then
        local count = tes3.getItemCount{reference = ref, item = id}
        if (options) then
            if (options.includeDenominations) then
                for did, denominationData in pairs(interop.getGoldDenominations()) do
                    count = count + (denominationData.value * tes3.getItemCount{reference = ref, item = did})
                end
            end
            if (options.includeBarter) then
                count = count + ref.object.barterGold
            end
        end
        return count
    else
        local denominationData
        for _, currencyData in pairs(interop.getCurrencies()) do
            denominationData = currencyData.properties.denominations[id]
            if (denominationData) then
                return tes3.getItemCount{reference = ref, item = id}
            end
        end
        denominationData = interop.getGoldDenomination(id)
        if (denominationData) then
            return tes3.getItemCount{reference = ref, item = id}
        else
            return nil
        end
    end
end

--- Custom currencies and gold.
--- @param ref tes3reference
--- @param cid string The currency's object ID.
--- @param did string The denomination's object ID.
--- @param includeBarter boolean?
--- @return number?
function interop.getReferenceDenomination(ref, cid, did, includeBarter)
    local currencyData = interop.getCurrency(cid)
    if (currencyData) then
        if (currencyData.properties.denominations[did]) then
            local count = tes3.getItemCount{reference = ref, item = did}
            if (includeBarter) then
                count = count + (interop.getReferenceBarter(ref, cid) or 0)
            end
            return count
        else
            return nil
        end
    else
        if (cid == "Gold_001") then
            if (interop.getGoldDenomination(did)) then
                local count = tes3.getItemCount{reference = ref, item = did}
                if (includeBarter) then
                    count = count + (interop.getReferenceBarter(ref, cid) or 0)
                end
                return count
            else
                return nil
            end
        else
            return nil
        end
    end
end

--- Custom currencies and denominations only.
--- @param ref tes3reference
--- @param id string
--- @return number?
function interop.getReferenceBarter(ref, id)
    local merchantData = interop.getMerchant(ref.baseObject.id) or interop.getBank(ref.baseObject.id)
    if (merchantData) then
        if (merchantData.acceptedCurrencies[id]) then
            return ref.data.sb_bazaar.barterCurrencies[id]
        else
            for _, currencyData in pairs(interop.getCurrencies()) do
                if (currencyData.properties.denominations[id]) then
                    return ref.data.sb_bazaar.barterDenominations[id]
                end
            end
        end
    end
    return nil
end

--- Gold only.
--- @param includeDenominations boolean?
--- @return number?
function interop.getPlayerGold(includeDenominations)
    return interop.getReferenceGold(tes3.player, {includeDenominations = includeDenominations})
end

--- Custom currencies and gold and denominations.
--- @param id string
--- @param includeDenominations boolean?
--- @return number?
function interop.getPlayerCurrency(id, includeDenominations)
    return interop.getReferenceCurrency(tes3.player, id, {includeDenominations = includeDenominations})
end

--- Custom currencies and gold.
--- @param cid string The currency's object ID.
--- @param did string The denomination's object ID.
--- @return number?
function interop.getPlayerDenomination(cid, did)
    return interop.getReferenceDenomination(tes3.player, cid, did)
end

---------

--- @param id string The currency's object ID.
--- @param symbolPattern string The string pattern used to represent the currency using `%d`. For example: "%d gp", "gold worth %d".
--- @param properties BazaarCurrencyProperties?
--- @param modProperties BazaarCurrencyModProperties?
--- @return boolean
function interop.registerCurrency(id, symbolPattern, properties, modProperties)
    if (tes3.getObject(id) == nil) then return false end
    interop.currencies[id] = {
        symbolPattern = symbolPattern,
        properties =
        {
            denominations = {},
            stackingMeshes = properties and properties.stackingMeshes or {},
            pluralName = properties and properties.pluralName or tes3.getObject(id).name,
            soundId = properties and properties.soundId or "Item Gold Down",
            tradeOnly = properties and properties.tradeOnly or false
        },
        modProperties =
        {
            uiExpIcon = modProperties and modProperties.uiExpIcon or tes3.getObject(id).icon
        }
    }
    for did, denominationData in pairs(properties and properties.denominations or {}) do
        interop.currencies[id].properties.denominations[did] =
        {
            value = denominationData.value,
            properties =
            {
                stackingMeshes = denominationData.properties and denominationData.properties.stackingMeshes or {},
                pluralName = denominationData.properties and denominationData.properties.pluralName or tes3.getObject(did).name,
                soundId = denominationData.properties and denominationData.properties.soundId or interop.currencies[id].properties.soundId,
                tradeOnly = denominationData.properties and denominationData.properties.tradeOnly or interop.currencies[id].properties.tradeOnly
            },
            modProperties = denominationData.modProperties or {}
        }
    end
    return true
end

--- @param data table<string, BazaarCurrencyData>
--- @return table<string, boolean>
function interop.registerCurrencies(data)
    local registered = {}
    for id, value in pairs(data) do
        table.insert(registered, {[id] = interop.registerCurrency(id, value.symbolPattern, value.properties, value.modProperties)})
    end
    return registered
end

--- @param id string The denomination's object ID.
--- @param value number The gold conversion of the currency. Note: This can be a decimal, but only whole values can be exchanged at banks.
--- @param properties GoldDenominationProperties?
--- @param modProperties table<string, any>?
--- @return boolean
function interop.registerGoldDenomination(id, value, properties, modProperties)
    if (tes3.getObject(id) == nil) then return false end
    interop.goldAlt[id] = {
        value = value,
        properties =
        {
            stackingMeshes = properties and properties.stackingMeshes or {},
            pluralName = properties and properties.pluralName or tes3.getObject(id).name,
            soundId = properties and properties.soundId or "Item Gold Down",
            tradeOnly = properties and properties.tradeOnly or false
        },
        modProperties = modProperties or {}
    }
    return true
end

--- @param data table<string, GoldDenominationData>
--- @return table<string, boolean>
function interop.registerGoldDenominations(data)
    local registered = {}
    for id, value in pairs(data) do
        table.insert(registered, {[id] = interop.registerGoldDenomination(id, value.value, value.properties, value.modProperties)})
    end
    return registered
end

--- @param npcId string
--- @param acceptedCurrencies table<string, number> The object IDs of the currencies accepted by the bank and their barter amount.
--- @param acceptedDenominations table<string, number> The object IDs of the denominations accepted by the bank and their barter amount. Note: If this table is empty, the bank will have no barter denominations but will still accept denominations of their accepted currencies.
--- @param acceptsGold boolean? Default: true
--- @return boolean
function interop.registerBank(npcId, acceptedCurrencies, acceptedDenominations, acceptsGold)
    if (tes3.getObject(npcId) == nil) then return false end
    interop.banks[npcId] = {
        acceptedCurrencies = acceptedCurrencies,
        acceptedDenominations = acceptedDenominations,
        acceptsGold = acceptsGold == nil or acceptsGold
    }
    return true
end

--- @param data table<string, BazaarMerchantBankData>
--- @return table<string, boolean>
function interop.registerBanks(data)
    local registered = {}
    for npcId, bankData in pairs(data) do
        table.insert(registered, {[npcId] = interop.registerBank(npcId, bankData.acceptedCurrencies, bankData.acceptsGold)})
    end
    return registered
end

--- @param npcId string
--- @param acceptedCurrencies table<string, number> The object IDs of the currencies accepted by the merchant and their barter amount.
--- @param acceptedDenominations table<string, number> The object IDs of the denominations accepted by the merchant and their barter amount. Note: If this table is empty, the merchant will have no barter denominations but will still accept denominations of their accepted currencies.
--- @param acceptsGold boolean? Default: true.
--- @return boolean
function interop.registerMerchant(npcId, acceptedCurrencies, acceptedDenominations, acceptsGold)
    if (tes3.getObject(npcId) == nil) then return false end
    interop.merchants[npcId] = {
        acceptedCurrencies = acceptedCurrencies,
        acceptedDenominations = acceptedDenominations,
        acceptsGold = acceptsGold == nil or acceptsGold
    }
    return true
end

--- @param data table<string, BazaarMerchantBankData>
--- @return table<string, boolean>
function interop.registerMerchants(data)
    local registered = {}
    for npcId, merchantData in pairs(data) do
        table.insert(registered, {[npcId] = interop.registerMerchant(npcId, merchantData.acceptedCurrencies, merchantData.acceptedDenominations, merchantData.acceptsGold)})
    end
    return registered
end

--- @param condition function The function used to verify a bank accepts a custom currency.
--- @param acceptedCurrencies table<string, number> The object IDs of the currencies accepted by the bank and their barter amount.
--- @param acceptedDenominations table<string, number> The object IDs of the denominations accepted by the bank and their barter amount.
--- @param acceptsGold boolean? Default: true
function interop.registerComplexBank(condition, acceptedCurrencies, acceptedDenominations, acceptsGold)
    interop.complexBanks[condition] =
    {
        acceptedCurrencies = acceptedCurrencies,
        acceptedDenominations = acceptedDenominations,
        acceptsGold = acceptsGold == nil or acceptsGold
    }
end

--- @param data table<function, BazaarMerchantBankData>
function interop.registerComplexBanks(data)
    for cond, bankData in pairs(data) do
        interop.registerComplexBank(cond, bankData.acceptedCurrencies, bankData.acceptedDenominations, bankData.acceptsGold)
    end
end

--- @param condition function The function used to verify a merchant accepts a custom currency.
--- @param acceptedCurrencies table<string, number> The object IDs of the currencies accepted by the merchant and their barter amount.
--- @param acceptedDenominations table<string, number> The object IDs of the denominations accepted by the merchant and their barter amount.
--- @param acceptsGold boolean? Default: true.
function interop.registerComplexMerchant(condition, acceptedCurrencies, acceptedDenominations, acceptsGold)
    interop.complexMerchants[condition] =
    {
        acceptedCurrencies = acceptedCurrencies,
        acceptedDenominations = acceptedDenominations,
        acceptsGold = acceptsGold == nil or acceptsGold
    }
end

--- @param data table<function, BazaarMerchantBankData>
function interop.registerComplexMerchants(data)
    for cond, merchantData in pairs(data) do
        interop.registerComplexMerchant(cond, merchantData.acceptedCurrencies, merchantData.acceptedDenominations, merchantData.acceptsGold)
    end
end

---------

--- @param id string
--- @param value number
--- @param object tes3object? Saves a `tes3.getObject` call if data has already been accessed.
--- @return number?
function interop.ConvertFromGold(id, value, object)
    return interop.getCurrency(id) and (value / (object or tes3.getObject(id)).value) or nil
end

--- @param id string
--- @param value number
--- @param object tes3object? Saves a `tes3.getObject` call if data has already been accessed.
--- @return number?
function interop.ConvertToGold(id, value, object)
    return interop.getCurrency(id) and (value * (object or tes3.getObject(id)).value) or nil
end

--- @param fromId string
--- @param toId string
--- @param value number
--- @param fromObject tes3object? Saves a `tes3.getObject` call if data has already been accessed.
--- @param toObject tes3object? Saves a `tes3.getObject` call if data has already been accessed.
--- @return number?
function interop.ConvertCurrency(fromId, toId, value, fromObject, toObject)
    return (interop.getCurrency(toId) and interop.getCurrency(fromId)) and interop.ConvertFromGold(toId, interop.ConvertToGold(fromId, value, fromObject), toObject) or nil
end

---------

--- @param ref tes3reference
function interop.refreshReferenceBarter(ref)
    local merchantData = interop.getMerchant(ref.baseObject.id) or interop.getBank(ref.baseObject.id)
    if (merchantData) then
        if (ref.object.barterGold == ref.baseObject.barterGold) then
            if (ref.mobile.actionData.lastBarterHoursPassed ~= 0) then
                return;
            end
        else
            local daysPassed = tes3.worldController.daysPassed.value
            local gameHour = tes3.worldController.hour.value
            local goldResetDelay = tes3.findGMST(tes3.gmst.fBarterGoldResetDelay).value
            local lastBarterHoursPassed = ref.mobile.actionData.lastBarterHoursPassed;
            if ((daysPassed * 24 + gameHour) < (goldResetDelay + lastBarterHoursPassed)) then
                return;
            end
            if (ref.data.sb_bazaar == nil) then
                ref.data.sb_bazaar = {}
            end
            ref.data.sb_bazaar.barterCurrencies = {}
            ref.data.sb_bazaar.barterDenominations = {}
            for id, value in pairs(merchantData.acceptedCurrencies) do
                ref.data.sb_bazaar.barterCurrencies[id] = value
                for did, _ in pairs(interop.getCurrency(id).properties.denominations) do
                    ref.data.sb_bazaar.barterDenominations[did] = 0
                end
            end
            for id, value in pairs(merchantData.acceptedDenominations) do
                ref.data.sb_bazaar.barterDenominations[id] = value
            end
            if (merchantData.acceptsGold) then
                for did, _ in pairs(interop.getGoldDenominations()) do
                    ref.data.sb_bazaar.barterDenominations[did] = 0
                end
            end
        end
    else
        for func, complexMerchantData in pairs(interop.complexMerchants) do
            if (func(ref)) then
                if (ref.object.barterGold == ref.baseObject.barterGold) then
                    if (ref.mobile.actionData.lastBarterHoursPassed ~= 0) then
                        return;
                    end
                else
                    local daysPassed = tes3.worldController.daysPassed.value
                    local gameHour = tes3.worldController.hour.value
                    local goldResetDelay = tes3.findGMST(tes3.gmst.fBarterGoldResetDelay).value
                    local lastBarterHoursPassed = ref.mobile.actionData.lastBarterHoursPassed;
                    if ((daysPassed * 24 + gameHour) < (goldResetDelay + lastBarterHoursPassed)) then
                        return;
                    end
                    if (ref.data.sb_bazaar == nil) then
                        ref.data.sb_bazaar = {}
                    end
                    ref.data.sb_bazaar.barterCurrencies = {}
                    ref.data.sb_bazaar.barterDenominations = {}
                    for id, value in pairs(complexMerchantData.acceptedCurrencies) do
                        ref.data.sb_bazaar.barterCurrencies[id] = value
                        for did, _ in pairs(interop.getCurrency(id).properties.denominations) do
                            ref.data.sb_bazaar.barterDenominations[did] = 0
                        end
                    end
                    for id, value in pairs(complexMerchantData.acceptedDenominations) do
                        ref.data.sb_bazaar.barterDenominations[id] = value
                    end
                    if (complexMerchantData.acceptsGold) then
                        for did, _ in pairs(interop.getGoldDenominations()) do
                            ref.data.sb_bazaar.barterDenominations[did] = 0
                        end
                    end
                end
                break
            end
        end
    end
end

--- @param ref tes3reference
--- @param id string The currency's object ID.
--- @param value number
--- @param reverse boolean?
--- @return number, {id: string, count: number}[]
function interop.calculateChange(ref, id, value, reverse)
    local denominations = id == "Gold_001" and interop.getGoldDenominations() or interop.getDenominations(id)

    if (denominations) then
        local numDecimals = 0

        -- Gotta sort them first, super important
        -- reverse sort
        local sorted = {}
        for denominationId, denominationData in pairs(denominations) do
            table.insert(sorted, {id = denominationId, value = denominationData.value, inventory = interop.getReferenceDenomination(ref, id, denominationId)})
            local n = #tostring(select(2, math.modf(denominationData.value))) - 2
            if (n > numDecimals) then
                numDecimals = math.max(numDecimals, n)
            end
        end
        table.insert(sorted, {id = id, value = 1, inventory = interop.getReferenceCurrency(ref, id)})

        table.sort(sorted, function(a, b)
            if (reverse) then
                return a.value > b.value
            else
                return a.value < b.value
            end
        end)

        local result = {}
        local remaining = value * (10 ^ numDecimals)

        -- Get maximum we can use of each.
        for _, d in ipairs(sorted) do
            local maxCanUse = math.floor(remaining / (d.value * 10 ^ numDecimals))
            local toUse = math.min(maxCanUse, d.inventory)

            table.insert(result, {id = d.id, count = toUse})

            remaining = remaining - (toUse * (d.value * 10 ^ numDecimals))
        end

        if (not reverse and remaining ~= 0) then
            return interop.calculateChange(ref, id, value, true)
        else
            return remaining / (10 ^ numDecimals), result
        end
    else
        return value, {}
    end
end

return interop