local interop = require("sb_bazaar.interop")
local i18n = mwse.loadTranslations("sb_bazaar")
local uiExp = include("sb_bazaar.uiExpInterop")

--- @param element tes3uiElement
--- @param propertyElement tes3uiElement
--- @param buyerRef tes3reference
--- @param sellerRef tes3reference
--- @return boolean
local function transferCurrency(element, propertyElement, buyerRef, sellerRef)
    local currencyId = element:findChild("sb_currency").widget.value
    local remaining, change = interop.calculateChange(buyerRef, currencyId, math.abs(propertyElement:getPropertyInt(currencyId)))

    --- @param buyer tes3reference
    --- @param seller tes3reference
    --- @param id string
    --- @param count number
    local transferOrAdd = function(buyer, seller, id, count)
        if (buyer == tes3.player) then
            tes3.removeItem{
                reference = buyer,
                item = id,
                count = count,
                playSound = false,
                updateGUI = false
            }
            if (seller.data.sb_bazaar.barterCurrencies[id]) then
                seller.data.sb_bazaar.barterCurrencies[id] = seller.data.sb_bazaar.barterCurrencies[id] + count
            else
                seller.data.sb_bazaar.barterDenominations[id] = seller.data.sb_bazaar.barterDenominations[id] + count
            end
        else
            tes3.addItem{
                reference = seller,
                item = id,
                count = count,
                playSound = false,
                updateGUI = false
            }
            if (buyer.data.sb_bazaar.barterCurrencies[id]) then
                buyer.data.sb_bazaar.barterCurrencies[id] = buyer.data.sb_bazaar.barterCurrencies[id] - count
                if (buyer.data.sb_bazaar.barterCurrencies[id] < 0) then
                    tes3.removeItem{
                        reference = buyer,
                        item = id,
                        count = -buyer.data.sb_bazaar.barterCurrencies[id],
                        playSound = false,
                        updateGUI = false
                    }
                    buyer.data.sb_bazaar.barterCurrencies[id] = 0
                end
            else
                buyer.data.sb_bazaar.barterDenominations[id] = buyer.data.sb_bazaar.barterDenominations[id] - count
                if (buyer.data.sb_bazaar.barterDenominations[id] < 0) then
                    tes3.removeItem{
                        reference = buyer,
                        item = id,
                        count = -buyer.data.sb_bazaar.barterDenominations[id],
                        playSound = false,
                        updateGUI = false
                    }
                    buyer.data.sb_bazaar.barterDenominations[id] = 0
                end
            end
        end
    end

    --- @param buyer tes3reference
    --- @param value number
    local addCompensationGold = function(buyer, value)
        if (value > 0) then
            if (buyer == tes3.player) then
                tes3.addItem{
                    reference = buyer,
                    item = "Gold_001",
                    count = value,
                    playSound = false,
                    updateGUI = false
                }
            else
                buyer.object.barterGold = buyer.object.barterGold + value
            end
        end
    end

    if (remaining == 0) then
        local soundChange = false
        if (currencyId == "Gold_001") then
            if (interop.getReferenceGold(buyerRef, {includeBarter = true, includeDenominations = true}) >= propertyElement:getPropertyInt("Gold_001")) then
                local goldUsed = 0
                for _, changeData in ipairs(change) do
                    if (changeData.count > 0) then
                        if (changeData.id == "Gold_001") then
                            goldUsed = changeData.count
                            soundChange = true
                        else
                            transferOrAdd(buyerRef, sellerRef, changeData.id, changeData.count)
                            if (soundChange == false) then
                                local currencyData = interop.getCurrency(changeData.id) or interop.getDenomination(currencyId, changeData.id)
                                event.register(tes3.event.addSound, function(f)
                                    if (f.sound.id == "Item Gold Down") then
                                        f.sound = tes3.getSound(currencyData.properties.soundId)
                                    end
                                end, {doOnce = true})
                                soundChange = true
                            end
                        end
                    end
                end
                addCompensationGold(buyerRef, math.abs(propertyElement:getPropertyInt("Gold_001")) - goldUsed)
                return true
            end
        else
            if (interop.getReferenceCurrency(buyerRef, currencyId, {includeBarter = true, includeDenominations = true}) >= propertyElement:getPropertyInt(currencyId)) then
                for _, changeData in ipairs(change) do
                    if (changeData.count > 0) then
                        transferOrAdd(buyerRef, sellerRef, changeData.id, changeData.count)
                        if (soundChange == false) then
                            local currencyData = interop.getCurrency(changeData.id) or interop.getDenomination(currencyId, changeData.id)
                            event.register(tes3.event.addSound, function(f)
                                if (f.sound.id == "Item Gold Down") then
                                    f.sound = tes3.getSound(currencyData.properties.soundId)
                                end
                            end, {doOnce = true})
                            soundChange = true
                        end
                    end
                end
                addCompensationGold(buyerRef, math.abs(propertyElement:getPropertyInt("Gold_001")))
                return true
            end
        end
    end
    return false
end

--- @param currencyButton tes3uiElement
--- @param newValue tes3uiElement?
--- @param tileUpdate boolean?
local function updateBarterValue(currencyButton, newValue, tileUpdate)
    local currencyId = currencyButton.name == "sb_currency" and currencyButton.widget.value or currencyButton:getTopLevelMenu():findChild("sb_currency").widget.value
    local newValue = newValue or currencyButton:getTopLevelMenu():findChild("MenuBarter_Price").children[2]
    local barterHaggleAmountPtr = require("ffi").cast("int*", 0x7D287C)
    if (currencyId ~= "Gold_001") then
        if (tileUpdate) then
            local value = interop.ConvertFromGold(currencyId, barterHaggleAmountPtr[0])
            value = (value > 0 and math.max(1, math.round(value))) or (value < 0 and math.min(-1, math.round(value))) or 0
            currencyButton:setPropertyInt(currencyId, value)
        end
        barterHaggleAmountPtr[0] = interop.ConvertToGold(currencyId, currencyButton:getPropertyInt(currencyId))
    end
    currencyButton:setPropertyInt("Gold_001", barterHaggleAmountPtr[0])
    local merchantData = interop.getMerchant(tes3ui.getServiceActor().reference.baseObject.id)

    if (merchantData.acceptsGold) then
        newValue.text = math.abs(barterHaggleAmountPtr[0]) .. tes3.findGMST(tes3.gmst.sgp).value .. " / "
    else
        newValue.text = ""
    end
    for id, _ in pairs(merchantData.acceptedCurrencies) do
        local currencyData = interop.getCurrency(id)
        if (currencyData) then
            if (currencyId == "Gold_001") then
                local value = interop.ConvertFromGold(id, barterHaggleAmountPtr[0])
                value = (value > 0 and math.max(1, math.round(value))) or (value < 0 and math.min(-1, math.round(value))) or 0
                newValue.text = newValue.text .. currencyData.symbolPattern:format(math.abs(value)) .. " / "
                currencyButton:setPropertyInt(id, value)
            elseif (currencyId == id) then
                newValue.text = newValue.text .. currencyData.symbolPattern:format(math.abs(currencyButton:getPropertyInt(id))) .. " / "
            else
                local value = interop.ConvertCurrency(currencyId, id, currencyButton:getPropertyInt(currencyId))
                value = (value > 0 and math.max(1, math.round(value))) or (value < 0 and math.min(-1, math.round(value))) or 0
                newValue.text = newValue.text .. currencyData.symbolPattern:format(math.abs(value)) .. " / "
                currencyButton:setPropertyInt(id, value)
            end
        end
    end
    newValue.text = newValue.text:sub(1, -4)
end

--- @param element tes3uiElement
--- @param merchantData BazaarMerchantBankData
local function substituteBarterLabels(element, merchantData)
    local currencyLabel = ""
    local currencyValue = ""
    local merchantGold = interop.getReferenceGold(tes3ui.getServiceActor().reference, {includeBarter = true, includeDenominations = true})

    for id, _ in pairs(merchantData.acceptedCurrencies) do
        local currencyData = interop.getCurrency(id)
        if (currencyData) then
            currencyLabel = currencyLabel .. currencyData.properties.pluralName .. " / "
            currencyValue = currencyValue .. interop.getPlayerCurrency(id, true) .. " / "
        end
    end
    currencyLabel = currencyLabel:upper():sub(1, -4)
    currencyValue = currencyValue:sub(1, -4)

    local label = element:findChild("MenuBarter_yourgold")
    label:setPropertyInt("Gold_001", label.text:match("%d+"))
    label.text = merchantData.acceptsGold and (tes3.findGMST(tes3.gmst.sYourGold).value .. " / " .. currencyLabel .. ": " .. interop.getPlayerGold(true) .. " / " .. currencyValue) or ("YOUR " .. currencyLabel .. ": " .. currencyValue)
    label = element:findChild("MenuBarter_Price").children[2]
    currencyValue = ""
    local merchant = tes3ui.getServiceActor().reference
    local options = {}

    if (merchantData.acceptsGold) then
        table.insert(options, {text = i18n("CurrencyButton", {currency = tes3.getObject("Gold_001").name}), value = "Gold_001"})
        label.text = label.text .. tes3.findGMST(tes3.gmst.sgp).value .. " / "
    else
        label.text = ""
    end
    for id, _ in pairs(merchantData.acceptedCurrencies) do
        local currencyData = interop.getCurrency(id)
        if (currencyData) then
            currencyValue = currencyValue .. interop.getReferenceCurrency(merchant, id, {includeBarter = true, includeDenominations = true}) .. " / "
            table.insert(options, {text = i18n("CurrencyButton", {currency = currencyData.properties.pluralName}), value = id})
            label.text = label.text .. currencyData.symbolPattern:format("0") .. " / "
        end
    end
    currencyValue = currencyValue:sub(1, -4)
    label.text = label.text:sub(1, -4)

    label = element:findChild("MenuBarter_BarterGold")
    label:setPropertyInt("Gold_001", label.text:match("%d+"))
    label.text = merchantData.acceptsGold and (tes3.findGMST(tes3.gmst.sSellerGold).value .. " / " .. currencyLabel .. ": " .. merchantGold .. " / " .. currencyValue) or ("SELLER " .. currencyLabel .. ": " .. currencyValue)

    local confirm = element:findChild("MenuBarter_Offerbutton")
    confirm:registerBefore(tes3.uiEvent.mouseClick, function(e)
        local currencyButton = e.forwardSource:getTopLevelMenu():findChild("sb_currency")
        local target = e.forwardSource:getTopLevelMenu():findChild("MenuBarter_Price").children[1].text:gsub("TOTAL ", "")

        if (target == "COST") then
            if (transferCurrency(element, currencyButton, tes3.player, tes3ui.getServiceActor().reference) == false) then
                tes3.messageBox(tes3.findGMST(tes3.gmst.sBarterDialog1).value)
                return
            end
        else
            if (transferCurrency(element, currencyButton, tes3ui.getServiceActor().reference, tes3.player) == false) then
                tes3.messageBox(tes3.findGMST(tes3.gmst.sBarterDialog2).value)
                return
            end
        end
    end)
    confirm:registerAfter(tes3.uiEvent.mouseClick, function(e)
        tes3ui.forcePlayerInventoryUpdate()
        tes3ui.updateBarterMenuTiles()
    end)

    local currencyButton = confirm.parent:createCycleButton{
        id = "sb_currency",
        options = options,
        index = 1,
    }
    currencyButton:reorder{
        before = confirm
    }

    -- --- @param e tes3uiEventData
    -- local updateValue = function(e)
    --     local currencyId = e.forwardSource.name == "sb_currency" and e.forwardSource.widget.value or e.forwardSource:getTopLevelMenu():findChild("sb_currency").widget.value
    --     local newValue = e.forwardSource:getTopLevelMenu():findChild("MenuBarter_Price").children[2]
    --     local barterHaggleAmountPtr = require("ffi").cast("int*", 0x7D287C)
    --     local value = barterHaggleAmountPtr[0]
    --     local merchantData = interop.getMerchant(tes3ui.getServiceActor().reference.baseObject.id)

    --     if (merchantData.acceptsGold) then
    --         if (currencyId == "Gold_001") then
    --             newValue.text = math.abs(value) .. tes3.findGMST(tes3.gmst.sgp).value .. " / "
    --         else
    --             newValue.text = math.abs(interop.ConvertToGold(currencyId, value)) .. tes3.findGMST(tes3.gmst.sgp).value .. " / "
    --         end
    --     else
    --         newValue.text = ""
    --     end
    --     for id, _ in pairs(merchantData.acceptedCurrencies) do
    --         local currencyData = interop.getCurrency(id)
    --         if (currencyData) then
    --             if (currencyId == "Gold_001") then
    --                 newValue.text = newValue.text .. currencyData.symbolPattern:format(math.abs(interop.ConvertFromGold(id, value))) .. " / "
    --             elseif (currencyId == id) then
    --                 newValue.text = newValue.text .. currencyData.symbolPattern:format(math.abs(value)) .. " / "
    --             else
    --                 newValue.text = newValue.text .. currencyData.symbolPattern:format(math.abs(interop.ConvertCurrency(currencyId, id, value))) .. " / "
    --             end
    --         end
    --     end
    --     newValue.text = newValue.text:sub(1, -4)

    --     e.forwardSource:forwardEvent(e)
    -- end

    -- --- @param e tes3uiEventData
    -- local convertValue = function(e)
    --     local prevCurrencyId = e.forwardSource.widget.options[e.forwardSource.widget.index == 1 and #e.forwardSource.widget.options or e.forwardSource.widget.index - 1].value
    --     local currencyId = e.forwardSource.widget.options[e.forwardSource.widget.index].value
    --     local barterHaggleAmountPtr = require("ffi").cast("int*", 0x7D287C)

    --     if (prevCurrencyId == "Gold_001") then
    --         barterHaggleAmountPtr[0] = interop.ConvertFromGold(currencyId, barterHaggleAmountPtr[0])
    --     elseif (currencyId == "Gold_001") then
    --         barterHaggleAmountPtr[0] = interop.ConvertToGold(prevCurrencyId, barterHaggleAmountPtr[0])
    --     else
    --         barterHaggleAmountPtr[0] = interop.ConvertCurrency(prevCurrencyId, currencyId, barterHaggleAmountPtr[0])
    --     end
    --     updateValue(e)

    --     e.forwardSource:forwardEvent(e)
    -- end

    --- @param e tes3uiEventData
    local increaseValue = function(e)
        local currencyButton = e.forwardSource:getTopLevelMenu():findChild("sb_currency")
        local currencyId = currencyButton.widget.options[currencyButton.widget.index].value

        if (currencyId ~= "Gold_001") then
            currencyButton:setPropertyInt(currencyId, currencyButton:getPropertyInt(currencyId) + 1)
        end
        updateBarterValue(currencyButton)

        e.forwardSource:forwardEvent(e)
    end

    --- @param e tes3uiEventData
    local decreaseValue = function(e)
        local currencyButton = e.forwardSource:getTopLevelMenu():findChild("sb_currency")
        local currencyId = currencyButton.widget.options[currencyButton.widget.index].value

        if (currencyId ~= "Gold_001") then
            currencyButton:setPropertyInt(currencyId, currencyButton:getPropertyInt(currencyId) - 1)
        end
        updateBarterValue(currencyButton)

        e.forwardSource:forwardEvent(e)
    end

    currencyButton:registerAfter(tes3.uiEvent.mouseClick, function(e)
        updateBarterValue(e.forwardSource)
        e.forwardSource:forwardEvent(e)
    end)
    element:findChild("MenuBarter_arrowup"):registerAfter(tes3.uiEvent.mouseClick, increaseValue)
    element:findChild("MenuBarter_arrowdown"):registerAfter(tes3.uiEvent.mouseClick, decreaseValue)

    for _ = 1, #options do
        currencyButton:triggerEvent(tes3.uiEvent.mouseClick)
    end
    if (#options == 1) then
        currencyButton.visible = false
    end

    element:updateLayout()
end

--- @param element tes3uiElement
--- @param merchantData BazaarMerchantBankData
--- @param menuName string
local function substituteServiceLabels(element, merchantData, menuName)
    element.minWidth = element.width
    element.autoWidth = true

    local label = element:findChild("MenuService" .. menuName .. "_ServiceList")
    if (uiExp and label.visible == false) then
        label = element:findChild("MenuServiceSpells_Spells")
    end
    local currency = ""

    --- @param childLabel tes3uiElement
    for childLabel in table.traverse(label.children) do
        --- @type string
        local value = childLabel.text:match("%d+" .. tes3.findGMST("sgp").value)
        if (value) then
            value = value:gsub(tes3.findGMST("sgp").value, "")
            currency = ""
            childLabel:setPropertyInt("Gold_001", tonumber(value))

            for id, _ in pairs(merchantData.acceptedCurrencies) do
                local currencyData = interop.getCurrency(id)
                if (currencyData) then
                    local newValue = math.round(interop.ConvertFromGold(id, tonumber(value)))
                    if (newValue == 0) then
                        newValue = 1
                    end
                    childLabel:setPropertyInt(id, newValue)
                    currency = currency .. currencyData.symbolPattern:format(tostring(newValue)) .. " / "
                end
            end
            currency = currency:sub(1, -4)

            childLabel.text = merchantData.acceptsGold and (childLabel.text .. " / " .. currency) or childLabel.text:gsub("%d+", currency)
            childLabel:register(tes3.uiEvent.mouseClick, function(e)
                transferCurrency(element, childLabel, tes3.player, tes3ui.getServiceActor().reference)
                e.forwardSource:forwardEvent(e)
            end)
        end
    end

    label = element:findChild("MenuService" .. menuName .. "_Okbutton").parent
    label.autoWidth = true
    label = label.children[1]
    label.autoWidth = true
    label.borderRight = 16
    currency = ""
    local options = {}

    if (merchantData.acceptsGold) then table.insert(options, {text = i18n("CurrencyButton", {currency = tes3.getObject("Gold_001").name}), value = "Gold_001"}) end
    for id, _ in pairs(merchantData.acceptedCurrencies) do
        local currencyData = interop.getCurrency(id)
        if (currencyData) then
            currency = currency .. currencyData.properties.pluralName .. ": " .. interop.getPlayerCurrency(id) .. " / "
            table.insert(options, {text = i18n("CurrencyButton", {currency = currencyData.properties.pluralName}), value = id})
        end
    end
    currency = currency:sub(1, -4)

    label.text = merchantData.acceptsGold and (label.text:gsub("%d+", interop.getPlayerGold(true)) .. " / " .. currency) or currency
    local confirm = element:findChild("MenuService" .. menuName .. "_Okbutton")

    local currencyButton = confirm.parent:createCycleButton{
        id = "sb_currency",
        options = options,
        index = 1,
    }
    currencyButton:reorder{
        before = confirm
    }
    currencyButton:registerAfter(tes3.uiEvent.mouseClick, function(e)
        local labelContainer = e.forwardSource:getTopLevelMenu():findChild("MenuService" .. menuName .. "_ServiceList")
        if (uiExp and label.visible == false) then
            label = element:findChild("MenuServiceSpells_Spells")
        end
        for childLabel in table.traverse(labelContainer.children) do
            if (e.forwardSource.widget.value == "Gold_001") then
                local value = childLabel.text:match("%d+" .. tes3.findGMST("sgp").value)
                if (value) then
                    local remaining, _ = interop.calculateChange(tes3.player, "Gold_001", childLabel:getPropertyInt("Gold_001"))
                    if (remaining == 0) then
                        childLabel.disabled = false
                        if (uiExp) then
                            childLabel.widget.state = tes3.uiState.active
                            uiExp.setColour(childLabel)
                        else
                            childLabel.widget.state = tes3.uiState.normal
                        end
                    else
                        childLabel.disabled = true
                        childLabel.widget.state = tes3.uiState.disabled
                    end
                end
            else
                local currencyData = interop.getCurrency(e.forwardSource.widget.value)
                if (currencyData) then
                    local value = childLabel.text:match(currencyData.symbolPattern:gsub("%%d", "%%d+"))
                    if (value) then
                        local remaining, _ = interop.calculateChange(tes3.player, e.forwardSource.widget.value, childLabel:getPropertyInt(e.forwardSource.widget.value))
                        if (remaining == 0) then
                            childLabel.disabled = false
                            if (uiExp) then
                                childLabel.widget.state = tes3.uiState.active
                                uiExp.setColour(childLabel)
                            else
                                childLabel.widget.state = tes3.uiState.normal
                            end
                        else
                            childLabel.disabled = true
                            childLabel.widget.state = tes3.uiState.disabled
                        end
                    end
                end
            end
        end
        e.forwardSource:forwardEvent(e)
    end)
    for _ = 1, #options do
        currencyButton:triggerEvent(tes3.uiEvent.mouseClick)
    end
    if (#options == 1) then
        currencyButton.visible = false
    end

    element:updateLayout()
end

--- @param element tes3uiElement
--- @param merchantData BazaarMerchantBankData
local function substituteUiExpServiceLabels(element, merchantData)
    element.minWidth = element.width
    element.autoWidth = true

    local label = element:findChild("UIEXP_MenuTraining_Skill1").parent
    local currency = ""

    --- @param childLabel tes3uiElement
    for childLabel in table.traverse(label.children) do
        --- @type string
        local value = childLabel.text:match("%d+ " .. tes3.findGMST("sgp").value)
        if (value) then
            value = value:gsub(" " .. tes3.findGMST("sgp").value, "")
            currency = ""

            for id, _ in pairs(merchantData.acceptedCurrencies) do
                local currencyData = interop.getCurrency(id)
                if (currencyData) then
                    local newValue = math.round(interop.ConvertFromGold(id, tonumber(value)))
                    if (newValue == 0) then
                        newValue = 1
                    end
                    currency = currency .. currencyData.symbolPattern:format(tostring(newValue)) .. " / "
                end
            end
            currency = currency:sub(1, -4)

            childLabel.text = merchantData.acceptsGold and (childLabel.text .. " / " .. currency) or childLabel.text:gsub("%d+ " .. tes3.findGMST("sgp").value, currency)
            childLabel.parent.children[1].children[1]:setPropertyInt("Gold_001", tonumber(value))
            childLabel.parent.children[1].children[1]:registerBefore(tes3.uiEvent.mouseClick, function(e)
                transferCurrency(element, e.forwardSource, tes3.player, tes3ui.getServiceActor().reference)
                e.forwardSource:forwardEvent(e)
            end)
        end
    end

    label = element:findChild("UIEXP_MenuTraining_Gold")
    currency = ""
    local options = {}

    if (merchantData.acceptsGold) then table.insert(options, {text = i18n("CurrencyButton", {currency = tes3.getObject("Gold_001").name}), value = "Gold_001"}) end
    for id, _ in pairs(merchantData.acceptedCurrencies) do
        local currencyData = interop.getCurrency(id)
        if (currencyData) then
            currency = currency .. currencyData.properties.pluralName .. ": " .. interop.getPlayerCurrency(id) .. " / "
            table.insert(options, {text = i18n("CurrencyButton", {currency = currencyData.properties.pluralName}), value = id})
        end
    end
    currency = currency:sub(1, -4)

    label.text = merchantData.acceptsGold and (label.text .. " / " .. currency) or currency
    local confirm = element:findChild("UIEXP_MenuTraining_Cancel")

    local currencyButton = confirm.parent:createCycleButton{
        id = "sb_currency",
        options = options,
        index = 1,
    }
    currencyButton.positionY = 0
    currencyButton.absolutePosAlignX = 0.8
    currencyButton.height = 24
    currencyButton:reorder{
        before = confirm
    }
    currencyButton:registerAfter(tes3.uiEvent.mouseClick, function(e)
        local labelContainer = e.forwardSource:getTopLevelMenu():findChild("UIEXP_MenuTraining_Skill1").parent
        for childLabel in table.traverse(labelContainer.children) do
            if (e.forwardSource.widget.value == "Gold_001") then
                local value = childLabel.text:match("%d+ " .. tes3.findGMST("sgp").value)
                if (value) then
                    local group = childLabel.parent
                    local name = group.children[2]
                    local limit = group.children[3]
                    local level = group.children[4]
                    local button = group.children[1].children[1]
                    local remaining, _ = interop.calculateChange(tes3.player, "Gold_001", tonumber(value:match("%d+")))
                    uiExp.setTrainingColour(group, name, limit, level, button, childLabel, remaining == 0)
                    element:updateLayout()
                end
            else
                local currencyData = interop.getCurrency(e.forwardSource.widget.value)
                if (currencyData) then
                    local value = childLabel.text:match(currencyData.symbolPattern:gsub("%%d", "%%d+"))
                    if (value) then
                        local group = childLabel.parent
                        local name = group.children[2]
                        local limit = group.children[3]
                        local level = group.children[4]
                        local button = group.children[1].children[1]
                        local remaining, _ = interop.calculateChange(tes3.player, e.forwardSource.widget.value, tonumber(value:match("%d+")))
                        uiExp.setTrainingColour(group, name, limit, level, button, childLabel, remaining == 0)
                        element:updateLayout()
                    end
                end
            end
        end
        e.forwardSource:forwardEvent(e)
    end)
    for _ = 1, #options do
        currencyButton:triggerEvent(tes3.uiEvent.mouseClick)
    end
    if (#options == 1) then
        currencyButton.visible = false
    end

    element:updateLayout()
end

--- @param element tes3uiElement
--- @param merchantData BazaarMerchantBankData
--- @param menuName string
local function substituteEncSpeLabels(element, merchantData, menuName)
    element.minWidth = element.width
    element.autoWidth = true
    if (menuName == "Enchantment") then
        element:findChild("MenuEnchantment_bottomButtonRow").autoWidth = true
        element:findChild("MenuEnchantment_priceContainer").autoWidth = true
        element:findChild("MenuEnchantment_Cost").parent.autoWidth = true
    elseif (menuName == "Spellmaking") then
        element:findChild("MenuSpellmaking_PriceLayout").autoWidth = true
        element:findChild("MenuSpellmaking_BottomLayout").autoWidth = true
    end
    local label = element:findChild("MenuEnchantment_Cost") or element:findChild("MenuSpellmaking_PriceValueLabel")
    label.borderRight = 16
    local options = {}
    if (merchantData.acceptsGold) then table.insert(options, {text = i18n("CurrencyButton", {currency = tes3.getObject("Gold_001").name}), value = "Gold_001"}) end
    local currency = ""
    label:setPropertyInt("Gold_001", tonumber(label.text:match("%d+")))

    for id, _ in pairs(merchantData.acceptedCurrencies) do
        local currencyData = interop.getCurrency(id)
        if (currencyData) then
            local newValue = interop.ConvertFromGold(id, label:getPropertyInt("Gold_001"))
            newValue = newValue > 0 and math.max(1, math.round(newValue)) or newValue
            currency = currency .. currencyData.symbolPattern:format(tostring(newValue)) .. " / "
            table.insert(options, {text = i18n("CurrencyButton", {currency = currencyData.properties.pluralName}), value = id})
            label:setPropertyInt(id, newValue)
        end
    end
    currency = currency:sub(1, -4)

    label.text = merchantData.acceptsGold and (label:getPropertyInt("Gold_001") .. tes3.findGMST(tes3.gmst.sgp).value .. " / " .. currency) or currency
    label.autoWidth = true

    local confirm = element:findChild("Menu" .. menuName .. "_Buybutton")
    confirm.parent.autoWidth = true
    confirm:register(tes3.uiEvent.mouseClick, function(e)
        if (transferCurrency(element, label, tes3.player, tes3ui.getServiceActor().reference)) then
            e.forwardSource:forwardEvent(e)
        else
            tes3.messageBox(i18n("MessageDeny"))
            return
        end
    end)

    local currencyButton = confirm.parent:createCycleButton{
        id = "sb_currency",
        options = options,
        index = 1,
    }
    currencyButton:reorder{
        before = confirm
    }
    currencyButton.borderAllSides = 0
    currencyButton.borderRight = menuName == "Enchantment" and 2 or 4

    element:register(tes3.uiEvent.update, function(e)
        label = e.forwardSource:findChild("MenuEnchantment_Cost") or e.forwardSource:findChild("MenuSpellmaking_PriceValueLabel")
        label:setPropertyInt("Gold_001", tonumber(label.text:match("%d+")))
        options = {}
        if (merchantData.acceptsGold) then table.insert(options, {text = i18n("CurrencyButton", {currency = tes3.getObject("Gold_001").name}), value = "Gold_001"}) end
        currency = ""

        for id, _ in pairs(merchantData.acceptedCurrencies) do
            local currencyData = interop.getCurrency(id)
            if (currencyData) then
                local newValue = interop.ConvertFromGold(id, label:getPropertyInt("Gold_001"))
                newValue = newValue > 0 and math.max(1, math.round(newValue)) or newValue
                currency = currency .. currencyData.symbolPattern:format(tostring(newValue)) .. " / "
                table.insert(options, {text = i18n("CurrencyButton", {currency = currencyData.properties.pluralName}), value = id})
                label:setPropertyInt(id, newValue)
            end
        end
        currency = currency:sub(1, -4)

        label.text = merchantData.acceptsGold and (label:getPropertyInt("Gold_001") .. tes3.findGMST(tes3.gmst.sgp).value .. " / " .. currency) or currency
        label.autoWidth = true

        e.forwardSource:forwardEvent(e)
    end)
    for _ = 1, #options do
        currencyButton:triggerEvent(tes3.uiEvent.mouseClick)
    end
    if (#options == 1) then
        currencyButton.visible = false
    end

    element:updateLayout()
end

--- @param element tes3uiElement
--- @param merchantData BazaarMerchantBankData
local function addBribery(element, merchantData)
    element.minWidth = element.width
    element.autoWidth = true

    local label = element:findChild("MenuPersuasion_ServiceList")
    if (merchantData.acceptsGold == false) then
        label:findChild("MenuPersuasion_Bribe10").visible = false
        label:findChild("MenuPersuasion_Bribe100").visible = false
        label:findChild("MenuPersuasion_Bribe1000").visible = false
    end

    for id, _ in pairs(merchantData.acceptedCurrencies) do
        local currencyData = interop.getCurrency(id)
        if (currencyData) then
            for v = 1, 3 do
                local remaining, _ = interop.calculateChange(tes3.player, id, math.round(interop.ConvertFromGold(id, 10 ^ v)))
                local t = label:createTextSelect{
                    text = "Bribe " .. math.round(interop.ConvertFromGold(id, 10 ^ v)) .. " " .. currencyData.properties.pluralName,
                    state = remaining == 0 and tes3.uiState.normal or tes3.uiState.disabled
                }

                if (t.widget.state == tes3.uiState.normal) then
                    t:register(tes3.uiEvent.mouseClick, function (e)
                        element:destroy()

                        local npc = tes3ui.getServiceActor()
                        local persTerm = npc.personality.current / tes3.findGMST(tes3.gmst.fPersonalityMod).value
                        local luckTerm = npc.luck.current / tes3.findGMST(tes3.gmst.fLuckMod).value
                        local repTerm = npc.object.reputation * tes3.findGMST(tes3.gmst.fReputationMod).value
                        local fatigueTerm = tes3.findGMST(tes3.gmst.fFatigueBase).value - tes3.findGMST(tes3.gmst.fFatigueMult).value * (1 - npc.fatigue.normalized)
                        local playerRating = (tes3.player.mobile.mercantile.current + luckTerm + persTerm) * fatigueTerm
                        local npcRating = (npc.mercantile.current + repTerm + luckTerm + persTerm) * fatigueTerm
                        local d = 1 - 0.02 * math.abs(npc.object.disposition - 50)
                        local target = d * (playerRating - npcRating + 50) + tes3.findGMST(
                            v and tes3.gmst.fBribe10Mod or
                            v and tes3.gmst.fBribe100Mod or
                            v and tes3.gmst.fBribe1000Mod
                        ).value

                        target = math.max(tes3.findGMST(tes3.gmst.iPerMinChance).value, target)
                        local roll = math.random(100)
                        local c = (target - roll) * tes3.findGMST(tes3.gmst.fPerDieRollMult).value
                        local x = 0
                        if (math.random(100) <= target) then
                            x = math.max(tes3.findGMST(tes3.gmst.iPerMinChange).value, c)
                        else
                            x = c
                        end

                        if (tes3.persuade{actor = npc, modifier = x}) then
                            tes3.transferItem{
                                from = tes3.player,
                                to = npc,
                                item = id,
                                count = 10 ^ v
                            }
                            tes3ui.showDialogueMessage{
                                reference = npc,
                                style = 1,
                                text = tes3.findGMST(tes3.gmst.sBribeSuccess).value
                            }
                            tes3ui.showDialogueMessage{
                                reference = npc,
                                text = tes3.findDialogue{topic = tes3.findGMST(tes3.gmst.sBribeSuccess).value}:getInfo{actor = npc, context = tes3.dialogueFilterContext.persuasion}.text:gsub("gold", currencyData.properties.pluralName)
                            }
                        else
                            tes3ui.showDialogueMessage{
                                reference = npc,
                                style = 1,
                                text = tes3.findGMST(tes3.gmst.sBribeFail).value
                            }
                            tes3ui.showDialogueMessage{
                                reference = npc,
                                text = tes3.findDialogue{topic = tes3.findGMST(tes3.gmst.sBribeFail).value}:getInfo{actor = npc, context = tes3.dialogueFilterContext.persuasion}.text:gsub("gold", currencyData.properties.pluralName)
                            }
                        end
                    end)
                else
                    t.disabled = true
                end
            end
        end
    end

    label = element:findChild("MenuPersuasion_Gold").parent
    label.autoWidth = true
    label = label.children[1]
    label.borderRight = 16
    local currency = ""

    for id, _ in pairs(merchantData.acceptedCurrencies) do
        if (interop.getCurrency(id)) then
            currency = currency .. interop.getCurrency(id).properties.pluralName .. ": " .. interop.getPlayerCurrency(id) .. " / "
        end
    end
    currency = currency:sub(1, -4)
    label.text = merchantData.acceptsGold and (label.text .. " / " .. currency) or currency
end

--- @param e uiActivatedEventData
local function uiActivatedCallback(e)
    local ref = tes3ui.getServiceActor().reference
    local merchantData = interop.getMerchant(ref.baseObject.id)
    local substituteFunction
    if (merchantData) then
        if (e.element.name == "MenuBarter") then
            substituteFunction = function() substituteBarterLabels(e.element, merchantData) end
        elseif (e.element.name == "MenuServiceSpells") then
            substituteFunction = function() substituteServiceLabels(e.element, merchantData, "Spells") end
        elseif (e.element.name == "MenuServiceTraining") then
            if (uiExp == false) then
                substituteFunction = function() substituteServiceLabels(e.element, merchantData, "Training") end
            else
                substituteFunction = function() substituteUiExpServiceLabels(e.element, merchantData) end
            end
        elseif (e.element.name == "MenuSpellmaking") then
            substituteFunction = function() substituteEncSpeLabels(e.element, merchantData, "Spellmaking") end
        elseif (e.element.name == "MenuEnchantment") then
            substituteFunction = function() substituteEncSpeLabels(e.element, merchantData, "Enchantment") end
        elseif (e.element.name == "MenuServiceRepair") then
            substituteFunction = function() substituteServiceLabels(e.element, merchantData, "Repair") end
        elseif (e.element.name == "MenuServiceTravel") then
            substituteFunction = function() substituteServiceLabels(e.element, merchantData, "Travel") end
        elseif (e.element.name == "MenuPersuasion") then
            substituteFunction = function() addBribery(e.element, merchantData) end
        end
    else
        for func, merchantData in pairs(interop.complexMerchants) do
            if (func(ref)) then
                if (e.element.name == "MenuBarter") then
                    substituteFunction = function() substituteBarterLabels(e.element, merchantData) end
                elseif (e.element.name == "MenuServiceSpells") then
                    substituteFunction = function() substituteServiceLabels(e.element, merchantData, "Spells") end
                elseif (e.element.name == "MenuServiceTraining") then
                    if (uiExp == false) then
                        substituteFunction = function() substituteServiceLabels(e.element, merchantData, "Training") end
                    else
                        substituteFunction = function() substituteUiExpServiceLabels(e.element, merchantData) end
                    end
                elseif (e.element.name == "MenuSpellmaking") then
                    substituteFunction = function() substituteEncSpeLabels(e.element, merchantData, "Spellmaking") end
                elseif (e.element.name == "MenuEnchantment") then
                    substituteFunction = function() substituteEncSpeLabels(e.element, merchantData, "Enchantment") end
                elseif (e.element.name == "MenuServiceRepair") then
                    substituteFunction = function() substituteServiceLabels(e.element, merchantData, "Repair") end
                elseif (e.element.name == "MenuServiceTravel") then
                    substituteFunction = function() substituteServiceLabels(e.element, merchantData, "Travel") end
                elseif (e.element.name == "MenuPersuasion") then
                    substituteFunction = function() addBribery(e.element, merchantData) end
                end
                break
            end
        end
    end
    if (substituteFunction) then
        if (uiExp == false) then
            substituteFunction()
        else
            timer.delayOneFrame(substituteFunction, timer.real)
        end
    end
end
event.register(tes3.event.uiActivated, uiActivatedCallback, {filter = "MenuBarter"})
event.register(tes3.event.uiActivated, uiActivatedCallback, {filter = "MenuServiceSpells"})
event.register(tes3.event.uiActivated, uiActivatedCallback, {filter = "MenuServiceTraining"})
event.register(tes3.event.uiActivated, uiActivatedCallback, {filter = "MenuSpellmaking"})
event.register(tes3.event.uiActivated, uiActivatedCallback, {filter = "MenuEnchantment"})
event.register(tes3.event.uiActivated, uiActivatedCallback, {filter = "MenuServiceRepair"})
event.register(tes3.event.uiActivated, uiActivatedCallback, {filter = "MenuServiceTravel"})
event.register(tes3.event.uiActivated, uiActivatedCallback, {filter = "MenuPersuasion"})

-- doesn't work
-- --- @param e infoResponseEventData
-- local function infoResponseCallback(e)
--     local ref = tes3ui.getServiceActor().reference
--     if (ref.baseObject.class.id == "Guard" or ref.baseObject.class.id == "Ordinator" or ref.baseObject.class.id == "Ordinator Guard" or ref.baseObject.objectType == tes3.objectType.creature) then
--         local merchantData = interop.getMerchant(ref.baseObject.id)
--         if (merchantData) then
--             local newText = ""
--             for id, _ in pairs(merchantData.acceptedCurrencies) do
--                 if (interop.getPlayerCurrency(id) > 0) then
--                     newText = newText .. "\"Pay " .. interop.getCurrency(id).properties.pluralName .. ".\", 1, "
--                 end
--             end
--             e.command = e.command:gsub("\"Pay Gold.\", 1,", merchantData.acceptsGold == false and newText or ("\"Pay Gold.\", 1, " .. newText))
--         else
--             for func, merchantData in pairs(interop.complexMerchants) do
--                 if (func(ref)) then
--                     local newText = ""
--                     for id, _ in pairs(merchantData.acceptedCurrencies) do
--                         if (interop.getPlayerCurrency(id) > 0) then
--                             newText = newText .. "\"Pay " .. interop.getCurrency(id).properties.pluralName .. ".\", 1, "
--                         end
--                     end
--                     e.command = e.command:gsub("\"Pay Gold.\", 1, ", merchantData.acceptsGold == false and newText or ("\"Pay Gold.\", 1, " .. newText))
--                     break
--                 end
--             end
--         end
--     end
-- end
-- event.register(tes3.event.infoResponse, infoResponseCallback)

--- @param referenceLabel tes3uiElement
--- @param item tes3reference | (tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3physicalObject|tes3probe|tes3repairTool|tes3static|tes3weapon)
--- @param weight number
local function createAndSortLabels(referenceLabel, item, weight)
    local merchantData = tes3ui.getServiceActor() and interop.getMerchant(tes3ui.getServiceActor().reference.baseObject.id)
    local elementOrder = {}
    local itemValue = item.objectType == tes3.objectType.reference and item.object.value or item.value
    local uiExpCounter = 0

    for id, _ in pairs(interop.currencies) do
        if (merchantData == nil or merchantData.acceptedCurrencies[id]) then
            local currency = tes3.getObject(id)
            local value = interop.ConvertFromGold(id, itemValue, currency)
            local newElement
            if (uiExp == false) then
                newElement = referenceLabel.parent:createLabel{text = currency.name .. " value: " .. value}
            else
                if (weight == 0) then
                    referenceLabel:getTopLevelMenu():findChild("UIEXP_Tooltip_IconWeightBlock").visible = false
                    local ratioBlock = referenceLabel:getTopLevelMenu():findChild("UIEXP_Tooltip_IconRatioBlock")
                    if (ratioBlock) then ratioBlock.visible = false end
                end
                newElement = referenceLabel.parent:createBlock()
                newElement.autoWidth = true
                newElement.autoHeight = true
                newElement.flowDirection = tes3.flowDirection.leftToRight
                local icon = newElement:createImage{path = "Icons\\" .. interop.getCurrency(id).modProperties.uiExpIcon}
                icon.width = 16
                icon.height = 16
                icon.scaleMode = true
                newElement:createLabel{
                    text = tostring(value)
                }.borderLeft = 4
                if (uiExpCounter == 1) then
                    newElement.borderLeft = 8
                    uiExpCounter = 0
                else
                    uiExpCounter = uiExpCounter + 1
                end
            end
            table.insert(elementOrder, newElement)
        end
    end

    if (uiExp == false) then
        --- @param element tes3uiElement
        for index, element in ipairs(elementOrder) do
            element:reorder{after = (index == 1 and referenceLabel or elementOrder[index - 1])}
        end
    else
        uiExpCounter = 0
        local block
        --- @param element tes3uiElement
        for _, element in ipairs(elementOrder) do
            if (uiExpCounter == 0) then
                block = referenceLabel.parent:createBlock{id = "UIEXP_Tooltip_BazaarCurrencies"}
                block.autoWidth = true
                block.widthProportional = 1
                block.minHeight = 16
                block.autoHeight = true
                block.paddingAllSides = 2
                block.paddingTop = 4
                block.flowDirection = tes3.flowDirection.leftToRight
                block.childAlignX = 1
            end
            element:move{to = block}
            if (uiExpCounter == 1) then
                uiExpCounter = 0
            else
                uiExpCounter = uiExpCounter + 1
            end
        end
        timer.delayOneFrame(function(e)
            local uiExpDivider = referenceLabel.parent:findChild("UIEXP_Tooltip_ExtraDivider")
            if (uiExpDivider) then
                local uiExpGoldWeight = referenceLabel.parent:findChild("UIEXP_Tooltip_IconBar")
                if (uiExpGoldWeight) then uiExpGoldWeight:reorder{after = uiExpDivider} end
                if (referenceLabel.parent.children[#referenceLabel.parent.children].id ~= "UIEXP_Tooltip_BazaarCurrencies") then
                    uiExpDivider.visible = false
                end
            end
        end, timer.real)
    end
end

--- @param referenceLabel tes3uiElement
--- @param item tes3reference | (tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3physicalObject|tes3probe|tes3repairTool|tes3static|tes3weapon)
--- @param count number
local function createAndSortGoldLabels(referenceLabel, item, count)
    local merchantData = tes3ui.getServiceActor() and interop.getMerchant(tes3ui.getServiceActor().reference.baseObject.id)
    local elementOrder = {}
    local itemValue = item.objectType == tes3.objectType.reference and item.object.value or item.value
    local uiExpCounter = 0

    for id, _ in pairs(interop.currencies) do
        if (merchantData == nil or merchantData.acceptedCurrencies[id]) then
            local currency = tes3.getObject(id)
            local value = interop.ConvertFromGold(id, itemValue * count, currency)
            local newElement
            if (uiExp == false) then
                newElement = referenceLabel.parent:createLabel{text = currency.name .. " value: " .. value}
            else
                newElement = referenceLabel.parent:createBlock()
                newElement.autoWidth = true
                newElement.autoHeight = true
                newElement.flowDirection = tes3.flowDirection.leftToRight
                local icon = newElement:createImage{path = "Icons\\" .. interop.getCurrency(id).modProperties.uiExpIcon}
                icon.width = 16
                icon.height = 16
                icon.scaleMode = true
                newElement:createLabel{
                    text = tostring(value)
                }.borderLeft = 4
                if (uiExpCounter == 1) then
                    newElement.borderLeft = 8
                    uiExpCounter = 0
                else
                    uiExpCounter = uiExpCounter + 1
                end
            end
            table.insert(elementOrder, newElement)
        end
    end

    if (uiExp == false) then
        --- @param element tes3uiElement
        for index, element in ipairs(elementOrder) do
            element:reorder{after = (index == 1 and referenceLabel or elementOrder[index - 1])}
        end
    else
        uiExpCounter = 0
        local block
        --- @param element tes3uiElement
        for _, element in ipairs(elementOrder) do
            if (uiExpCounter == 0) then
                block = referenceLabel.parent:createBlock{id = "UIEXP_Tooltip_BazaarCurrencies"}
                block.autoWidth = true
                block.widthProportional = 1
                block.minHeight = 16
                block.autoHeight = true
                block.paddingAllSides = 2
                block.paddingTop = 4
                block.flowDirection = tes3.flowDirection.leftToRight
                block.childAlignX = 1
            end
            element:move{to = block}
            if (uiExpCounter == 1) then
                uiExpCounter = 0
            else
                uiExpCounter = uiExpCounter + 1
            end
        end
        timer.delayOneFrame(function(e)
            local uiExpDivider = referenceLabel.parent:findChild("UIEXP_Tooltip_ExtraDivider")
            if (uiExpDivider) then
                local uiExpGoldWeight = referenceLabel.parent:findChild("UIEXP_Tooltip_IconBar")
                if (uiExpGoldWeight) then uiExpGoldWeight:reorder{after = uiExpDivider} end
                if (referenceLabel.parent.children[#referenceLabel.parent.children].id ~= "UIEXP_Tooltip_BazaarCurrencies") then
                    uiExpDivider.visible = false
                end
            end
        end, timer.real)
    end
end

--- @param referenceLabel tes3uiElement
--- @param item tes3reference | (tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3physicalObject|tes3probe|tes3repairTool|tes3static|tes3weapon)
--- @param count number
--- @param weight number
local function createAndSortCurrencyLabels(referenceLabel, item, count, weight)
    local merchantData = tes3ui.getServiceActor() and interop.getMerchant(tes3ui.getServiceActor().reference.baseObject.id)
    local elementOrder = {}
    local itemId = item.objectType == tes3.objectType.reference and item.baseObject.id or item.id
    local value = interop.ConvertToGold(itemId, count)
    local newElement = referenceLabel.parent:createBlock()
    local uiExpCounter = 0

    if (uiExp == false) then
        table.insert(elementOrder, referenceLabel.parent:createLabel{
            text = tes3.getObject("Gold_001").name .. " value: " .. interop.ConvertToGold(itemId, count)
        })
    else
        if (weight == 0) then
            referenceLabel:getTopLevelMenu():findChild("UIEXP_Tooltip_IconBar").visible = false
        else
            referenceLabel:getTopLevelMenu():findChild("UIEXP_Tooltip_IconGoldBlock").visible = false
            local ratioBlock = referenceLabel:getTopLevelMenu():findChild("UIEXP_Tooltip_IconRatioBlock")
            if (ratioBlock) then ratioBlock.visible = false end
        end
        newElement.autoWidth = true
        newElement.autoHeight = true
        newElement.flowDirection = tes3.flowDirection.leftToRight
        local icon = newElement:createImage{path = "Icons\\gold.dds"}
        icon.width = 16
        icon.height = 16
        icon.scaleMode = true
        newElement:createLabel{
            text = tostring(value)
        }.borderLeft = 4
        if (uiExpCounter == 1) then
            newElement.borderLeft = 8
            uiExpCounter = 0
        else
            uiExpCounter = uiExpCounter + 1
        end
        table.insert(elementOrder, newElement)
    end

    for id, _ in pairs(interop.currencies) do
        if (id ~= itemId and (merchantData == nil or merchantData.acceptedCurrencies[id])) then
            local currency = tes3.getObject(id)
            value = interop.ConvertCurrency(itemId, id, count, nil, currency)
            if (uiExp == false) then
                newElement = referenceLabel.parent:createLabel{text = currency.name .. " value: " .. value}
            else
                newElement = referenceLabel.parent:createBlock()
                newElement.autoWidth = true
                newElement.autoHeight = true
                newElement.flowDirection = tes3.flowDirection.leftToRight
                local icon = newElement:createImage{path = "Icons\\" .. interop.getCurrency(id).modProperties.uiExpIcon}
                icon.width = 16
                icon.height = 16
                icon.scaleMode = true
                newElement:createLabel{
                    text = tostring(value)
                }.borderLeft = 4
                if (uiExpCounter == 1) then
                    newElement.borderLeft = 8
                    uiExpCounter = 0
                else
                    uiExpCounter = uiExpCounter + 1
                end
            end
            table.insert(elementOrder, newElement)
        end
    end

    if (uiExp == false) then
        --- @param element tes3uiElement
        for index, element in ipairs(elementOrder) do
            element:reorder{after = (index == 1 and referenceLabel or elementOrder[index - 1])}
        end
    else
        uiExpCounter = 0
        local block
        --- @param element tes3uiElement
        for _, element in ipairs(elementOrder) do
            if (uiExpCounter == 0) then
                block = referenceLabel.parent:createBlock{id = "UIEXP_Tooltip_BazaarCurrencies"}
                block.autoWidth = true
                block.widthProportional = 1
                block.minHeight = 16
                block.autoHeight = true
                block.paddingAllSides = 2
                block.paddingTop = 4
                block.flowDirection = tes3.flowDirection.leftToRight
                block.childAlignX = 1
            end
            element:move{to = block}
            if (uiExpCounter == 1) then
                uiExpCounter = 0
            else
                uiExpCounter = uiExpCounter + 1
            end
        end
        timer.delayOneFrame(function(e)
            local uiExpDivider = referenceLabel.parent:findChild("UIEXP_Tooltip_ExtraDivider")
            if (uiExpDivider) then
                local uiExpGoldWeight = referenceLabel.parent:findChild("UIEXP_Tooltip_IconBar")
                if (uiExpGoldWeight) then uiExpGoldWeight:reorder{after = uiExpDivider} end
                if (referenceLabel.parent.children[#referenceLabel.parent.children].id ~= "UIEXP_Tooltip_BazaarCurrencies") then
                    uiExpDivider.visible = false
                end
            end
        end, timer.real)
    end
end

--- @param referenceLabel tes3uiElement
--- @param item tes3reference | (tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3physicalObject|tes3probe|tes3repairTool|tes3static|tes3weapon)
--- @param count number
--- @param weight number
--- @return boolean
local function createAndSortDenominationLabels(referenceLabel, item, count, weight)
    local merchantData = tes3ui.getServiceActor() and interop.getMerchant(tes3ui.getServiceActor().reference.baseObject.id)
    local elementOrder = {}
    local denomId = item.objectType == tes3.objectType.reference and item.baseObject.id or item.id
    local denomValue
    local baseId
    local uiExpCounter = 0

    local denominationData = interop.getGoldDenominations()[denomId]
    if (denominationData) then
        denomValue = denominationData.value
        baseId = "Gold_001"
    end
    if (denominationData == nil) then
        for cid, currencyData in pairs(interop.getCurrencies()) do
            denominationData = currencyData.properties.denominations[denomId]
            if (denominationData) then
                denomValue = denominationData.value
                baseId = cid
                break
            end
        end
    end

    if (denominationData) then
        local newElement
        local value = baseId == "Gold_001" and (denomValue * count) or interop.ConvertToGold(baseId, denomValue * count)
        if (uiExp == false) then
            table.insert(elementOrder, referenceLabel.parent:createLabel{text = tes3.getObject("Gold_001").name .. " value: " .. value})
        else
            if (weight == 0) then
                referenceLabel:getTopLevelMenu():findChild("UIEXP_Tooltip_IconWeightBlock").visible = false
                local ratioBlock = referenceLabel:getTopLevelMenu():findChild("UIEXP_Tooltip_IconRatioBlock")
                if (ratioBlock) then ratioBlock.visible = false end
            end
            local goldLabel = referenceLabel:getTopLevelMenu():findChild("UIEXP_Tooltip_IconGoldBlock").children[2]
            goldLabel.text = value
            if (baseId == "Gold_001") then goldLabel.color = tes3ui.getPalette(tes3.palette.linkColor) end
        end

        if (baseId == "Gold_001") then
            for id, _ in pairs(interop.currencies) do
                local currency = tes3.getObject(id)
                value = interop.ConvertFromGold(id, denomValue * count, currency)
                if (uiExp == false) then
                    newElement = referenceLabel.parent:createLabel{text = currency.name .. " value: " .. value}
                else
                    newElement = referenceLabel.parent:createBlock()
                    newElement.autoWidth = true
                    newElement.autoHeight = true
                    newElement.flowDirection = tes3.flowDirection.leftToRight
                    local icon = newElement:createImage{path = "Icons\\" .. interop.getCurrency(id).modProperties.uiExpIcon}
                    icon.width = 16
                    icon.height = 16
                    icon.scaleMode = true
                    newElement:createLabel{
                        text = tostring(value)
                    }.borderLeft = 4
                    if (uiExpCounter == 1) then
                        newElement.borderLeft = 8
                        uiExpCounter = 0
                    else
                        uiExpCounter = uiExpCounter + 1
                    end
                end
                table.insert(elementOrder, newElement)
            end
        else
            for id, _ in pairs(interop.currencies) do
                if (merchantData == nil or merchantData.acceptedCurrencies[id]) then
                    local currency = tes3.getObject(id)
                    value = interop.ConvertCurrency(baseId, id, denomValue * count, nil, currency)
                    if (uiExp == false) then
                        newElement = referenceLabel.parent:createLabel{text = currency.name .. " value: " .. value}
                    else
                        newElement = referenceLabel.parent:createBlock()
                        newElement.autoWidth = true
                        newElement.autoHeight = true
                        newElement.flowDirection = tes3.flowDirection.leftToRight
                        local icon = newElement:createImage{path = "Icons\\" .. interop.getCurrency(id).modProperties.uiExpIcon}
                        icon.width = 16
                        icon.height = 16
                        icon.scaleMode = true
                        local label = newElement:createLabel{
                            text = tostring(value)
                        }
                        label.borderLeft = 4
                        if (id == baseId) then label.color = tes3ui.getPalette(tes3.palette.linkColor) end
                        if (uiExpCounter == 1) then
                            newElement.borderLeft = 8
                            uiExpCounter = 0
                        else
                            uiExpCounter = uiExpCounter + 1
                        end
                    end
                    table.insert(elementOrder, newElement)
                end
            end
        end

        if (uiExp == false) then
            --- @param element tes3uiElement
            for index, element in ipairs(elementOrder) do
                element:reorder{after = (index == 1 and referenceLabel or elementOrder[index - 1])}
            end
        else
            uiExpCounter = 0
            local block
            --- @param element tes3uiElement
            for _, element in ipairs(elementOrder) do
                if (uiExpCounter == 0) then
                    block = referenceLabel.parent:createBlock{id = "UIEXP_Tooltip_BazaarCurrencies"}
                    block.autoWidth = true
                    block.widthProportional = 1
                    block.minHeight = 16
                    block.autoHeight = true
                    block.paddingAllSides = 2
                    block.paddingTop = 4
                    block.flowDirection = tes3.flowDirection.leftToRight
                    block.childAlignX = 1
                end
                element:move{to = block}
                if (uiExpCounter == 1) then
                    uiExpCounter = 0
                else
                    uiExpCounter = uiExpCounter + 1
                end
            end
            timer.delayOneFrame(function(e)
                local uiExpDivider = referenceLabel.parent:findChild("UIEXP_Tooltip_ExtraDivider")
                if (uiExpDivider) then
                    local uiExpGoldWeight = referenceLabel.parent:findChild("UIEXP_Tooltip_IconBar")
                    if (uiExpGoldWeight) then uiExpGoldWeight:reorder{after = uiExpDivider} end
                    if (referenceLabel.parent.children[#referenceLabel.parent.children].id ~= "UIEXP_Tooltip_BazaarCurrencies") then
                        uiExpDivider.visible = false
                    end
                end
            end, timer.real)
        end
        return true
    else
        return false
    end
end

--- @param e uiObjectTooltipEventData
local function uiObjectTooltipCallback(e)
    if (e.reference and (e.reference.object.isCarriable == false or e.reference.object.isCarriable == nil)) then
        return
    end

    local item = e.reference or e.object
    local itemValue = e.reference and item.object.value or item.value
    local itemWeight = e.reference and item.object.weight or item.weight
    local nameLabel = e.tooltip:findChild("HelpMenu_name")

    if (itemValue > 0) then
        local valueLabel = e.tooltip:findChild("HelpMenu_value")
        local count = tonumber(e.reference and e.reference.itemData and e.reference.itemData.count) or (e.count > 0 and e.count) or 1

        if (item.id:match("Gold_%d+")) then
            createAndSortGoldLabels(e.reference and nameLabel.parent or nameLabel, item, count)
        elseif (valueLabel) then
            createAndSortLabels(valueLabel, item, itemWeight)
            valueLabel.text = tes3.findGMST(tes3.gmst.sGold).value .. " " .. valueLabel.text:lower()
        elseif (interop.getCurrency(item.objectType == tes3.objectType.reference and item.baseObject.id or item.id)) then
            createAndSortCurrencyLabels(e.reference and nameLabel.parent or nameLabel, item, count, itemWeight)
        else
            createAndSortDenominationLabels(e.reference and nameLabel.parent or nameLabel, item, count, itemWeight)
        end
    else
        -- For some reason this is needed for some items as they don't always contain a count value.
        local countFound = nameLabel.text:match("%(%d+%)")
        local isDenom = createAndSortDenominationLabels(e.reference and nameLabel.parent or nameLabel, item, countFound and countFound:match("%d+") or 1, itemWeight)
        if (uiExp) then
            if (isDenom == false and itemWeight == 0) then
                e.tooltip:findChild("UIEXP_Tooltip_IconBar").visible = false
            elseif (isDenom == false) then
                e.tooltip:findChild("UIEXP_Tooltip_IconGoldBlock").visible = false
                local ratioBlock = e.tooltip:findChild("UIEXP_Tooltip_IconRatioBlock")
                if (ratioBlock) then ratioBlock.visible = false end
            end
        end
    end

    e.tooltip.autoWidth = true
end
event.register(tes3.event.uiObjectTooltip, uiObjectTooltipCallback)

-- --- @param ref tes3reference
-- --- @param count number
-- local function groupCurrencies(ref, count)
--     local totalValue = 0
--     --- @type {id: string, data: GoldDenominationData}
--     local nextDenominator

--     for did, denominationData in pairs(interop.getGoldDenominations()) do
--         totalValue = totalValue + count * denominationData.value
--         tes3.removeItem{
--             reference = ref,
--             item = did,
--             count = tes3.getItemCount{reference = ref, item = did},
--             playSound = false
--         }
--         if (nextDenominator == nil or denominationData.value > nextDenominator.data.value) then
--             nextDenominator = {id = did, data = denominationData}
--         end
--     end

--     local g, r = math.modf(totalValue)
--     totalValue = r
--     tes3.addItem{
--         reference = ref,
--         item = "Gold_001",
--         count = g,
--         playSound = false
--     }

--     while (nextDenominator ~= nil) do
--         local denomination, _ = math.modf(totalValue / nextDenominator.data.value)
--         if (denomination > 0) then
--             tes3.addItem{
--                 reference = ref,
--                 item = nextDenominator.id,
--                 count = denomination,
--                 playSound = false
--             }
--         end
--         totalValue = totalValue % nextDenominator.data.value
--         nextDenominator = nextDenominator.data.properties.convertsFrom and {id = nextDenominator.id, data = interop.getGoldDenomination(nextDenominator.data.properties.convertsFrom)} or nil
--     end
-- end

--- @param e filterBarterMenuEventData
--- @param merchantData BazaarMerchantBankData
local function updateTile(e, merchantData)
    if (merchantData.acceptsGold) then
        if (e.item.id == "Gold_001") then
            -- groupCurrencies(ref, e.tile.count)
            e.filter = false
            return
        else
            for did, denominationData in pairs(interop.getGoldDenominations()) do
                if (e.item.id == did) then
                    e.filter = not denominationData.properties.tradeOnly
                    return
                end
            end
        end
    end
    for cid, _ in pairs(merchantData.acceptedCurrencies) do
        if (e.item.id == cid) then
            e.filter = not interop.getCurrency(cid).properties.tradeOnly
            return
        else
            for did, denominationData in pairs(interop.getCurrency(cid).properties.denominations) do
                if (e.item.id == did) then
                    e.filter = not denominationData.properties.tradeOnly
                    return
                end
            end
        end
    end
end

--- @param e filterBarterMenuEventData
local function filterBarterMenuCallback(e)
    if (e.tile.isBartered == false) then
        local ref = tes3ui.getServiceActor().reference
        local merchantData = interop.getMerchant(ref.baseObject.id)
        if (merchantData) then
            updateTile(e, merchantData)
        else
            for func, merchantData in pairs(interop.complexMerchants) do
                if (func(ref)) then
                    updateTile(e, merchantData)
                    break
                end
            end
        end
    end
end
event.register(tes3.event.filterBarterMenu, filterBarterMenuCallback)

--- @param e menuExitEventData
local function menuExitCallback(e)
    for did, _ in pairs(interop.getGoldDenominations()) do
        local count = tes3.getItemCount{
            reference = tes3.player,
            item = did
        }
        if (count > 0) then
            -- groupCurrencies(tes3.player, count)
            return
        end
    end
end
event.register(tes3.event.menuExit, menuExitCallback)

--- @param e containerClosedEventData
local function containerClosedCallback(e)
    for did, _ in pairs(interop.getGoldDenominations()) do
        local count = tes3.getItemCount{
            reference = e.reference,
            item = did
        }
        if (count > 0) then
            -- groupCurrencies(e.reference, count)
            return
        end
    end
end
event.register(tes3.event.containerClosed, containerClosedCallback)

--- @param e itemTileUpdatedEventData
local function itemTileUpdatedCallback(e)
    local barterMenu = e.menu.name == "MenuBarter" and e.menu or tes3ui.findMenu("MenuBarter")
    if (barterMenu and (e.menu.name == "MenuBarter" or e.menu.name == "MenuInventory")) then
        local newValue = barterMenu:findChild("MenuBarter_Price").children[2]
        local currency = barterMenu:findChild("sb_currency")
        if (tonumber(newValue.text) and currency) then
            updateBarterValue(currency, newValue, true)
        end
    end
end
event.register(tes3.event.itemTileUpdated, itemTileUpdatedCallback)

--- @param e barterOfferEventData
local function barterOfferCallback(e)
    local currencyElement = tes3ui.findMenu("MenuBarter"):findChild("sb_currency")
    local currencyId = currencyElement.widget.value
    local remaining, _ = interop.calculateChange(e.offer < 0 and tes3.player or e.mobile.reference, currencyId, math.abs(currencyElement:getPropertyInt(currencyId)))
    if (remaining == 0) then
        if (e.offer < 0) then
            if (currencyId ~= "Gold_001") then
                timer.delayOneFrame(function(f)
                    tes3.addItem{
                        reference = tes3.player,
                        item = "Gold_001",
                        count = math.abs(e.offer),
                        playSound = false
                    }
                    e.mobile.barterGold = e.mobile.barterGold + e.offer
                end, timer.real)
            end
        else
            if (currencyId ~= "Gold_001") then
                timer.delayOneFrame(function(f)
                    tes3.removeItem{
                        reference = tes3.player,
                        item = "Gold_001",
                        count = e.offer,
                        playSound = false
                    }
                    e.mobile.barterGold = e.mobile.barterGold - e.offer
                end, timer.real)
            end
        end
        e.success = true
    else
        e.success = false
    end
end
event.register(tes3.event.barterOffer, barterOfferCallback)

--- @param e uiActivatedEventData
--- @param ref tes3reference
--- @param bankData BazaarMerchantBankData
local function bankMenu(e, ref, bankData)
    local topService = e.element:findChild("MenuDialog_service_barter")
    local bankService = topService.parent:createTextSelect{
        id = "sb_bank",
        text = i18n("Button")
    }
    timer.delayOneFrame(function(e)
        bankService.visible = true
    end)
    bankService:reorder{
        before = topService
    }
    bankService:register(tes3.uiEvent.mouseClick, function(e)
        local playerTrade = 0
        local bankTrade = 0
        local playerFirst
        local bankFirst

        local playerCount
        local bankCount
        local canPerformExchange = false

        if (bankData.acceptsGold) then
            playerCount = interop.getPlayerGold()
            bankCount = interop.getReferenceGold(ref, {includeBarter = true})

            playerFirst = "Gold_001"
            if (playerCount > 0) then
                playerTrade = playerTrade + 1
            end

            bankFirst = "Gold_001"
            if (bankCount > 0) then
                bankTrade = bankTrade + 1
            end

            if ((playerCount > 0 or bankCount > 0) and playerCount ~= bankCount) then
                canPerformExchange = true
            end

            for denominationId, _ in pairs(interop.getGoldDenominations()) do
                playerCount = interop.getPlayerDenomination("Gold_001", denominationId)
                bankCount = interop.getReferenceDenomination(ref, "Gold_001", denominationId)

                if (playerCount > 0) then
                    playerTrade = playerTrade + 1
                end

                if (bankCount > 0) then
                    bankTrade = bankTrade + 1
                end

                if ((playerCount > 0 or bankCount > 0) and playerCount ~= bankCount) then
                    canPerformExchange = true
                end
            end
        end
        for currency, _ in pairs(bankData.acceptedCurrencies) do
            playerCount = interop.getPlayerCurrency(currency)
            bankCount = interop.getReferenceCurrency(ref, currency)

            if (playerCount > 0) then
                playerTrade = playerTrade + 1
                playerFirst = playerFirst or currency
            end

            if (bankCount > 0) then
                bankTrade = bankTrade + 1
                bankFirst = bankFirst or currency
            end

            if ((playerCount > 0 or bankCount > 0) and playerCount ~= bankCount) then
                canPerformExchange = true
            end

            for denominationId, _ in pairs(interop.getDenominations(currency)) do
                playerCount = interop.getPlayerDenomination(currency, denominationId)
                bankCount = interop.getReferenceDenomination(ref, currency, denominationId)

                if (playerCount > 0) then
                    playerTrade = playerTrade + 1
                end

                if (bankCount > 0) then
                    bankTrade = bankTrade + 1
                end

                if ((playerCount > 0 or bankCount > 0) and playerCount ~= bankCount) then
                    canPerformExchange = true
                end
            end
        end

        if ((playerTrade < 1 and bankTrade < 1) or (canPerformExchange == false)) then
            tes3ui.showDialogueMessage{
                reference = ref,
                style = 1,
                text = i18n("MessageNoBoth")
            }

            e.forwardSource:forwardEvent(e)
            return
        elseif (playerTrade < 1) then
            tes3ui.showDialogueMessage{
                reference = ref,
                style = 1,
                text = i18n("MessageNoPlayer")
            }

            e.forwardSource:forwardEvent(e)
            return
        elseif (bankTrade < 1) then
            tes3ui.showDialogueMessage{
                reference = ref,
                style = 1,
                text = i18n("MessageNoBank")
            }

            e.forwardSource:forwardEvent(e)
            return
        end

        tes3ui.findMenu("MenuDialog").visible = false

        local menu = tes3ui.createMenu{
            id = "sb_bank",
            fixedFrame = true
        }
        menu.minWidth = 400
        menu.autoWidth = true
        menu.minHeight = 320
        menu.autoHeight = true

        local titleBlock = menu:createBlock()
        titleBlock.widthProportional = 1
        titleBlock.autoHeight = true
        titleBlock.childAlignX = 0.5
        local title = titleBlock:createLabel{
            id = "title",
            text = i18n("Title")
        }
        title.color = tes3ui.getPalette(tes3.palette.headerColor)

        local blockBlock = menu:createBlock()
        blockBlock.autoWidth = true
        blockBlock.widthProportional = 1
        blockBlock.heightProportional = 1
        blockBlock.flowDirection = tes3.flowDirection.leftToRight

        local valueOptions = {{text = tes3.getObject("Gold_001").name, value = "Gold_001"}}
        for id, denominationData in pairs(interop.getGoldDenominations()) do
            table.insert(valueOptions, {text = denominationData.properties.pluralName, value = id})
        end

        local leftBlock = blockBlock:createBlock()
        leftBlock.widthProportional = 1
        leftBlock.heightProportional = 1
        leftBlock.borderAllSides = 4
        leftBlock.flowDirection = tes3.flowDirection.topToBottom
        local fromLabel = leftBlock:createLabel{
            id = "fromLabel",
            text = i18n("From")
        }
        fromLabel.color = tes3ui.getPalette(tes3.palette.headerColor)
        local fromList = leftBlock:createVerticalScrollPane()
        local fromValueLabel = leftBlock:createLabel{
            id = "fromValueLabel",
            text = i18n("ValueFrom", {currency = "DUMMY", count = "DUMMY"})
        }
        local fromValue = leftBlock:createCycleButton{
            id = "fromValue",
            options = valueOptions,
            index = 1
        }
        fromValue.visible = false
        fromValue:register(tes3.uiEvent.valueChanged, function(e)
            fromValueLabel.text = i18n("ValueFrom", {currency = e.forwardSource.widget.text, count = interop.getPlayerCurrency(e.forwardSource.widget.value)})
        end)

        local rightBlock = blockBlock:createBlock()
        rightBlock.widthProportional = 1
        rightBlock.heightProportional = 1
        rightBlock.borderAllSides = 4
        rightBlock.flowDirection = tes3.flowDirection.topToBottom
        local toLabel = rightBlock:createLabel{
            id = "toLabel",
            text = i18n("To")
        }
        toLabel.color = tes3ui.getPalette(tes3.palette.headerColor)
        local toList = rightBlock:createVerticalScrollPane()
        local toValueLabel = rightBlock:createLabel{
            id = "toValueLabel",
            text = i18n("ValueTo", {currency = "DUMMY", count = "DUMMY"})
        }
        local toValue = rightBlock:createCycleButton{
            id = "toValue",
            options = valueOptions,
            index = 1
        }
        toValue.visible = false
        toValue:register(tes3.uiEvent.valueChanged, function(e)
            toValueLabel.text = i18n("ValueTo", {currency = e.forwardSource.widget.text, count = interop.getReferenceCurrency(ref, e.forwardSource.widget.value)})
        end)

        local updateMax = function()
            if (fromValue.widget.value == toValue.widget.value) then
                if (fromValue.widget.value == "Gold_001") then
                    return math.min(interop.getPlayerGold(), ref.object.barterGold)
                else
                    local playerCurrency = interop.getCurrency(fromValue.widget.value) and interop.getPlayerCurrency(fromValue.widget.value, true) or nil
                    local referenceCurrency = interop.getCurrency(toValue.widget.value) and interop.getReferenceCurrency(ref, toValue.widget.value, {includeBarter = true}) or nil
                    if (playerCurrency == nil) then
                        if (interop.getGoldDenomination(fromValue.widget.value)) then
                            playerCurrency = interop.getPlayerDenomination("Gold_001", fromValue.widget.value)
                            referenceCurrency = interop.getReferenceDenomination(ref, "Gold_001", toValue.widget.value)
                        else
                            for id, data in pairs(interop.getCurrencies()) do
                                if (data.properties.denominations[fromValue.widget.value]) then
                                    playerCurrency = interop.getPlayerDenomination(id, fromValue.widget.value)
                                    referenceCurrency = interop.getReferenceDenomination(ref, id, toValue.widget.value)
                                    break
                                end
                            end
                        end
                    end
                    return math.min(playerCurrency, referenceCurrency)
                end
            else
                if (fromValue.widget.value == "Gold_001") then
                    return math.min(interop.getPlayerGold(), interop.getReferenceCurrency(ref, toValue.widget.value))
                else
                    local playerCurrency = (fromValue.widget.value == "Gold_001" and interop.getPlayerGold(true)) or (interop.getCurrency(fromValue.widget.value) and interop.getPlayerCurrency(fromValue.widget.value, true)) or nil
                    local referenceCurrency = (toValue.widget.value == "Gold_001" and interop.getReferenceGold(ref)) or (interop.getCurrency(toValue.widget.value) and interop.getReferenceCurrency(ref, toValue.widget.value, {includeBarter = true})) or nil
                    if (playerCurrency == nil) then
                        if (interop.getGoldDenomination(fromValue.widget.value)) then
                            playerCurrency = interop.getPlayerDenomination("Gold_001", fromValue.widget.value)
                        else
                            for id, data in pairs(interop.getCurrencies()) do
                                if (data.properties.denominations[fromValue.widget.value]) then
                                    playerCurrency = interop.getPlayerDenomination(id, fromValue.widget.value)
                                    break
                                end
                            end
                        end
                    end
                    if (referenceCurrency == nil) then
                        if (interop.getGoldDenomination(fromValue.widget.value)) then
                            referenceCurrency = interop.getReferenceDenomination(ref, "Gold_001", toValue.widget.value)
                        else
                            for id, data in pairs(interop.getCurrencies()) do
                                if (data.properties.denominations[fromValue.widget.value]) then
                                    referenceCurrency = interop.getReferenceDenomination(ref, id, toValue.widget.value)
                                    break
                                end
                            end
                        end
                    end
                    return math.min(playerCurrency, referenceCurrency)
                end
            end
        end

        local count = menu:createSlider{
            id = "count",
            current = 1,
            max = updateMax()
        }
        count.widthProportional = 1
        count.borderLeft = 4
        count.borderRight = 4
        count.borderTop = 8

        local createCurrencyButtons = function(id, data, prefix, from, to)
            local currency = fromList:createTextSelect{
                id = prefix .. id,
                text = i18n(from, {currency = data.properties.pluralName, count = interop.getPlayerCurrency(id)})
            }
            currency:register(tes3.uiEvent.mouseClick, function(e)
                fromValue.widget.value = e.forwardSource.name:gsub(prefix, "")
                count.widget.max = updateMax()
                count.widget.current = math.min(count.widget.current, count.widget.max)
                count:triggerEvent(tes3.uiEvent.partScrollBarChanged)
            end)
            if (prefix == "d_") then currency.borderLeft = 16 end

            currency = toList:createTextSelect{
                id = prefix .. id,
                text = i18n(to, {currency = data.properties.pluralName, count = interop.getReferenceCurrency(ref, id)}),
            }
            currency:register(tes3.uiEvent.mouseClick, function(e)
                toValue.widget.value = e.forwardSource.name:gsub(prefix, "")
                count.widget.max = updateMax()
                count.widget.current = math.min(count.widget.current, count.widget.max)
                count:triggerEvent(tes3.uiEvent.partScrollBarChanged)
            end)
            if (prefix == "d_") then currency.borderLeft = 16 end

            fromValue.widget:addOption{text = data.properties.pluralName, value = id}
            toValue.widget:addOption{text = data.properties.pluralName, value = id}
        end
        for cid, _ in pairs(bankData.acceptedCurrencies) do
            local currencyData = interop.getCurrency(cid)
            createCurrencyButtons(cid, currencyData, "c_", "ItemFrom", "ItemTo")
            for did, denominationData in pairs(currencyData.properties.denominations) do
                createCurrencyButtons(did, denominationData, "d_", "ItemFromDenom", "ItemToDenom")
            end
        end
        if (bankData.acceptsGold) then
            local currency = fromList:createTextSelect{
                id = "c_Gold_001",
                text = i18n("ItemFrom", {currency = tes3.findGMST(tes3.gmst.sGold).value, count = interop.getPlayerGold(true)})
            }
            currency:register(tes3.uiEvent.mouseClick, function(e)
                fromValue.widget.value = "Gold_001"
                count.widget.max = updateMax()
                count.widget.current = math.min(count.widget.current, count.widget.max)
                count:triggerEvent(tes3.uiEvent.partScrollBarChanged)
            end)
            currency:reorder{before = fromList:getContentElement().children[1]}

            currency = toList:createTextSelect{
                id = "c_Gold_001",
                text = i18n("ItemTo", {currency = tes3.findGMST(tes3.gmst.sGold).value, count = ref.object.barterGold})
            }
            currency:register(tes3.uiEvent.mouseClick, function(e)
                toValue.widget.value = "Gold_001"
                count.widget.max = updateMax()
                count.widget.current = math.min(count.widget.current, count.widget.max)
                count:triggerEvent(tes3.uiEvent.partScrollBarChanged)
            end)
            currency:reorder{before = toList:getContentElement().children[1]}

            local i = 1
            for did, denominationData in pairs(interop.getGoldDenominations()) do
                local denomination = fromList:createTextSelect{
                    id = "d_" .. did,
                    text = i18n("ItemFromDenom", {currency = denominationData.properties.pluralName, count = interop.getPlayerCurrency(did)})
                }
                denomination:register(tes3.uiEvent.mouseClick, function(e)
                    fromValue.widget.value = e.forwardSource.name:gsub("d_", "")
                    count.widget.max = updateMax()
                    count.widget.current = math.min(count.widget.current, count.widget.max)
                    count:triggerEvent(tes3.uiEvent.partScrollBarChanged)
                end)
                denomination.borderLeft = 16
                denomination:reorder{after = fromList:getContentElement().children[i]}

                denomination = toList:createTextSelect{
                    id = "d_" .. did,
                    text = i18n("ItemToDenom", {currency = denominationData.properties.pluralName, count = interop.getReferenceCurrency(ref, did)})
                }
                denomination:register(tes3.uiEvent.mouseClick, function(e)
                    toValue.widget.value = e.forwardSource.name:gsub("d_", "")
                    count.widget.max = updateMax()
                    count.widget.current = math.min(count.widget.current, count.widget.max)
                    count:triggerEvent(tes3.uiEvent.partScrollBarChanged)
                end)
                denomination.borderLeft = 16
                denomination:reorder{after = toList:getContentElement().children[i]}

                i = i + 1
            end

            fromValue:triggerEvent(tes3.uiEvent.valueChanged)
            toValue.widget.index = 2
        else
            fromValue.widget.index = 2
            toValue.widget.index = 3
        end

        local bottomBlock = menu:createBlock()
        bottomBlock.widthProportional = 1
        bottomBlock.autoHeight = true
        bottomBlock.borderLeft = 4
        bottomBlock.borderRight = 2
        bottomBlock.borderTop = 4
        bottomBlock.borderBottom = 2
        bottomBlock.flowDirection = tes3.flowDirection.leftToRight

        local countLabel = bottomBlock:createLabel{
            id = "countLabel",
            text = i18n("Count", {from = "1", to = "1"})
        }
        countLabel.widthProportional = 1

        count:registerAfter(tes3.uiEvent.partScrollBarChanged, function(e)
            local calculateValue = function(fromId, toId, value)
                local fromCurrency = interop.getCurrency(fromId) and fromId or nil
                local toCurrency = interop.getCurrency(toId) and toId or nil
                if (fromId == toId) then
                    return value
                elseif (fromId == "Gold_001" and toCurrency) then
                    return interop.ConvertFromGold(toId, value)
                elseif (fromCurrency and toId == "Gold_001") then
                    return interop.ConvertToGold(fromId, value)
                else
                    if (fromCurrency and toCurrency) then
                        return interop.ConvertCurrency(fromId, toId, value)
                    else
                        local fromDenomination
                        local toDenomination
                        if (fromId == "Gold_001") then
                            fromCurrency = "Gold_001"
                        end
                        if (toId == "Gold_001") then
                            toCurrency = "Gold_001"
                        end
                        for did, denominationData in pairs(interop.getGoldDenominations()) do
                            if (did == fromId) then
                                fromCurrency = "Gold_001"
                                fromDenomination = denominationData
                            end
                            if (did == toId) then
                                toCurrency = "Gold_001"
                                toDenomination = denominationData
                            end
                            if (fromDenomination and toDenomination) then
                                break
                            end
                        end
                        if (fromCurrency == nil or toCurrency == nil) then
                            for cid, currencyData in pairs(interop.getCurrencies()) do
                                for did, denominationData in pairs(currencyData.properties.denominations) do
                                    if (did == fromId) then
                                        fromCurrency = cid
                                        fromDenomination = denominationData
                                    end
                                    if (did == toId) then
                                        toCurrency = cid
                                        toDenomination = denominationData
                                    end
                                    if (fromDenomination and toDenomination) then
                                        break
                                    end
                                end
                                if (fromDenomination and toDenomination) then
                                    break
                                end
                            end
                        end
                        if (fromCurrency and toCurrency) then
                            if (fromCurrency == toCurrency) then
                                return ((fromDenomination and fromDenomination.value or 1) * value) / (toDenomination and toDenomination.value or 1)
                            elseif (fromCurrency == "Gold_001") then
                                return (toDenomination and toDenomination.value or 1) * interop.ConvertFromGold(toCurrency, (fromDenomination and fromDenomination.value or 1) * value)
                            elseif (toCurrency == "Gold_001") then
                                return interop.ConvertToGold(fromCurrency, (fromDenomination and fromDenomination.value or 1) * value) / (toDenomination and toDenomination.value or 1)
                            else
                                return (toDenomination and toDenomination.value or 1) * interop.ConvertCurrency(fromCurrency, toCurrency, (fromDenomination and fromDenomination.value or 1) * value)
                            end
                        end
                    end
                end
            end
            local getCurrencyOrDenominationSymbol = function(id, value)
                local goldDenominationData = interop.getGoldDenominations()[id]
                if (goldDenominationData) then
                    return (goldDenominationData.value * value) .. tes3.findGMST(tes3.gmst.sgp).value
                end

                local currency = interop.getCurrency(id)
                if (currency) then
                    return currency.symbolPattern:format(value)
                else
                    for _, currencyData in pairs(interop.getCurrencies()) do
                        local denominationData = currencyData.properties.denominations[id]
                        if (denominationData) then
                            return currencyData.symbolPattern:format(denominationData.value * value)
                        end
                    end
                end
            end

            if (fromValue.widget.value == toValue.widget.value) then
                countLabel.text = i18n("Count", {
                    from = fromValue.widget.value == "Gold_001" and ("1" .. tes3.findGMST(tes3.gmst.sgp).value) or getCurrencyOrDenominationSymbol(fromValue.widget.value, 1),
                    to = toValue.widget.value == "Gold_001" and ("1" .. tes3.findGMST(tes3.gmst.sgp).value) or getCurrencyOrDenominationSymbol(toValue.widget.value, 1)
                })
            else
                local rightValue = 0
                if (fromValue.widget.value == "Gold_001") then
                    rightValue = calculateValue(fromValue.widget.value, toValue.widget.value, e.forwardSource.widget.current)
                    countLabel.text = i18n("Count", {
                        from = fromValue.widget.value == "Gold_001" and (e.forwardSource.widget.current .. tes3.findGMST(tes3.gmst.sgp).value) or getCurrencyOrDenominationSymbol(fromValue.widget.value, e.forwardSource.widget.current),
                        to = getCurrencyOrDenominationSymbol(toValue.widget.value, math.round(rightValue))
                    })
                else
                    rightValue = calculateValue(fromValue.widget.value, toValue.widget.value, e.forwardSource.widget.current)
                    countLabel.text = i18n("Count", {
                        from = getCurrencyOrDenominationSymbol(fromValue.widget.value, e.forwardSource.widget.current),
                        to = toValue.widget.value == "Gold_001" and (rightValue .. tes3.findGMST(tes3.gmst.sgp).value) or getCurrencyOrDenominationSymbol(toValue.widget.value, math.round(rightValue))
                    })
                end
            end

            e.forwardSource:forwardEvent(e)
        end)
        count:triggerEvent(tes3.uiEvent.partScrollBarChanged)

        local okButton = bottomBlock:createButton{
            id = "ok",
            text = i18n("Ok")
        }
        okButton.borderAllSides = 2
        okButton:register(tes3.uiEvent.mouseClick, function(e)
            if (fromValue.widget.value == toValue.widget.value) then
                tes3.messageBox(i18n("MessageDeny"))
            elseif (interop.getPlayerCurrency(fromValue.widget.value, true) < 1 or interop.getReferenceCurrency(ref, toValue.widget.value, {includeBarter = true, includeGold = true}) < 1) then
                tes3.messageBox(i18n("MessageDeny"))
            else
                if (fromValue.widget.value == "Gold_001") then
                    tes3.transferItem{
                        from = tes3.player,
                        to = ref,
                        item = "Gold_001",
                        count = count.widget.current,
                        playSound = false
                    }
                    tes3.transferItem{
                        from = ref,
                        to = tes3.player,
                        item = toValue.widget.value,
                        count = math.round(interop.ConvertFromGold(toValue.widget.value, count.widget.current)),
                        playSound = false
                    }
                    tes3.playSound{
                        sound = interop.getCurrency(toValue.widget.value).properties.soundId
                    }
                else
                    tes3.transferItem{
                        from = tes3.player,
                        to = ref,
                        item = fromValue.widget.value,
                        count = count.widget.current,
                        playSound = false
                    }
                    tes3.transferItem{
                        from = ref,
                        to = tes3.player,
                        item = toValue.widget.value,
                        count = toValue.widget.value == "Gold_001" and interop.ConvertToGold(fromValue.widget.value, count.widget.current) or interop.ConvertFromGold(toValue.widget.value, count.widget.current),
                        playSound = false
                    }
                    tes3.playSound{
                        sound = interop.getCurrency(toValue.widget.value).properties.soundId
                    }
                end

                menu:destroy()
                local dialogMenu = tes3ui.findMenu("MenuDialog")
                dialogMenu.visible = true
                dialogMenu:findChild("sb_bank").visible = true
            end
            tes3ui.showDialogueMessage{
                reference = ref,
                style = 1,
                text = tes3.findGMST(tes3.gmst.sBarterDialog5).value
            }

            e.forwardSource:forwardEvent(e)
        end)
        local cancelButton = bottomBlock:createButton{
            id = "cancel",
            text = i18n("Cancel")
        }
        cancelButton.borderAllSides = 2
        cancelButton:register(tes3.uiEvent.mouseClick, function(e)
            menu:destroy()
            local dialogMenu = tes3ui.findMenu("MenuDialog")
            dialogMenu.visible = true
            dialogMenu:findChild("sb_bank").visible = true
            e.forwardSource:forwardEvent(e)
        end)

        menu:updateLayout()
    end)
end

--- @param e uiActivatedEventData
local function uiActivatedCallback(e)
    if (e.newlyCreated) then
        local ref = tes3ui.getServiceActor().reference
        local bankData = interop.getBank(ref.baseObject.id)
        if (bankData) then
            bankMenu(e, ref, bankData)
        else
            for func, bankData in pairs(interop.complexBanks) do
                if (func(ref)) then
                    bankMenu(e, ref, bankData)
                    break
                end
            end
        end
    end
end
event.register(tes3.event.uiActivated, uiActivatedCallback, {filter = "MenuDialog"})

--- @param e itemDroppedEventData
local function itemDroppedCallback(e)
    local id = e.reference.baseObject.id
    local maxMesh
    local data = interop.getCurrency(id) or interop.getGoldDenomination(id)
    if (data) then
        for mesh, value in pairs(data.properties.stackingMeshes) do
            if (e.reference.itemData.count >= value) then
                maxMesh = mesh
            end
        end
    else
        local found = false
        for _, currencyData in pairs(interop.getCurrencies()) do
            data = currencyData.properties.denominations[id]
            if (data) then
                for mesh, value in pairs(data.properties.stackingMeshes) do
                    if (e.reference.itemData.count >= value) then
                        maxMesh = mesh
                    end
                end
                found = true
            end
            if (found) then
                break
            end
        end
    end

    if (maxMesh) then
        e.reference.mesh = maxMesh
    end
end
event.register(tes3.event.itemDropped, itemDroppedCallback)

--- @param e activateEventData
local function activateCallback(e)
    if (e.target.data) then
        local merchantData = interop.getMerchant(e.target.baseObject.id) or interop.getBank(e.target.baseObject.id)
        if (merchantData) then
            if (e.target.data.sb_bazaar == nil) then
                e.target.data.sb_bazaar = {}
            end
            if (e.target.data.sb_bazaar.barterCurrencies == nil) then
                e.target.data.sb_bazaar.barterCurrencies = {}
                e.target.data.sb_bazaar.barterDenominations = {}
                for id, value in pairs(merchantData.acceptedCurrencies) do
                    e.target.data.sb_bazaar.barterCurrencies[id] = value
                    for did, _ in pairs(interop.getCurrency(id).properties.denominations) do
                        e.target.data.sb_bazaar.barterDenominations[did] = 0
                    end
                end
                for id, value in pairs(merchantData.acceptedDenominations) do
                    e.target.data.sb_bazaar.barterDenominations[id] = value
                end
                if (merchantData.acceptsGold) then
                    for did, _ in pairs(interop.getGoldDenominations()) do
                        e.target.data.sb_bazaar.barterDenominations[did] = 0
                    end
                end
            else
                interop.refreshReferenceBarter(e.target)
            end
        else
            for _, service in ipairs{interop.complexMerchants, interop.complexBanks} do
                for func, complexMerchantData in pairs(service) do
                    if (func(e.target)) then
                        if (e.target.data.sb_bazaar == nil) then
                            e.target.data.sb_bazaar = {}
                        end
                        if (e.target.data.sb_bazaar.barterCurrencies == nil) then
                            e.target.data.sb_bazaar.barterCurrencies = {}
                            e.target.data.sb_bazaar.barterDenominations = {}
                            for id, value in pairs(complexMerchantData.acceptedCurrencies) do
                                e.target.data.sb_bazaar.barterCurrencies[id] = value
                                for did, _ in pairs(interop.getCurrency(id).properties.denominations) do
                                    e.target.data.sb_bazaar.barterDenominations[did] = 0
                                end
                            end
                            for id, value in pairs(complexMerchantData.acceptedDenominations) do
                                e.target.data.sb_bazaar.barterDenominations[id] = value
                            end
                            if (complexMerchantData.acceptsGold) then
                                for did, _ in pairs(interop.getGoldDenominations()) do
                                    e.target.data.sb_bazaar.barterDenominations[did] = 0
                                end
                            end
                        else
                            interop.refreshReferenceBarter(e.target)
                        end
                        break
                    end
                end
            end
        end
    end
end
event.register(tes3.event.activate, activateCallback)