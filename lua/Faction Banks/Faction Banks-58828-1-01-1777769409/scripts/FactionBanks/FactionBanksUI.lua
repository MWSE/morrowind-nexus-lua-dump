local cam, camera, core, self, nearby, types, ui, util, storage, async, input,
DaisyUtils, debug = require('openmw.interfaces').Camera, require('openmw.camera'),
    require('openmw.core'), require('openmw.self'),
    require('openmw.nearby'), require('openmw.types'),
    require('openmw.ui'), require('openmw.util'),
    require("openmw.storage"), require("openmw.async"),
    require("openmw.input"),
    require("openmw.debug")
local ambient = require('openmw.ambient')

local constants = require('scripts.omw.mwui.constants')
local buttonTemplate = require("scripts.FactionBanks.templates.button")
local UIInterface = require("scripts.FactionBanks.UIPlayerInterface")

local BankUi = nil
local enabled = false
local v2 = util.vector2
local lastActivatedActor
local activeFaction
local player
local I = require('openmw.interfaces')
local currentSelectedIndex = 0

local function padding(x, y)
    return {
        props = {
            size = util.vector2(x, y)
        }
    }
end

local textSize = 16
local titleTextSize = 22
local topPadding = 8
local bottomPadding = 8
local sidePadding = 8
local centerPadding = 8
local columnWidth = 235
local columnHeight = 176
local statusWidth = columnWidth * 2 + centerPadding


local function borderPadding(content, size)
    return {
        name = "wrapper",
        template = I.MWUI.templates.borders,
        props = {
            size = size
        },
        content = ui.content {
            {
                name = "padding",
                template = I.MWUI.templates.padding,
                content = ui.content { content }
            }
        }
    }
end
local function CloseBankWin()
    I.UI.removeMode(I.UI.getMode())
end

local function closeWindow(openDialog)
    if (BankUi ~= nil) then
        BankUi:destroy()
        enabled = false
    end
    if openDialog then
        --  I.UI.setMode("Dialogue", { target = lastActivatedActor })
    end
end
local function resetBoldOptions(index)
    currentSelectedIndex = index
    --    boldOptions = {}
    -- if index and BankData[index] then
    --    boldOptions[index] = true
    --end
    --
end

local function hoverOption(data, data2)
    local index
    if data2 then
        index = (data2.index)
    end
    resetBoldOptions(index)
end

--[[
    local table = {
        renderOption(1, "Deposit 10 gold", "Line1Text", clickOption),
        renderOption(2, "Deposit 100 gold", "Line2Text", clickOption),
        renderOption(3, "Deposit 1000 gold", "Line3Text", clickOption),
        renderOption(4, "Deposit 10000 gold", "Line4Text", clickOption),
        renderOption(5, "Deposit All gold", "Line5Text", clickOption),
        renderOption(6, "Deposit Half gold", "Line6Text", clickOption),
    }
    if withdraw then
        table = {
            renderOption(1, "Withdraw 10 gold", "Line1Text", clickOption),
            renderOption(2, "Withdraw 100 gold", "Line2Text", clickOption),
            renderOption(3, "Withdraw 1000 gold", "Line3Text", clickOption),
            renderOption(4, "Withdraw 10000 gold", "Line4Text", clickOption),
            renderOption(5, "Withdraw All gold", "Line5Text", clickOption),
            renderOption(6, "Withdraw Half gold", "Line6Text", clickOption),
        }
    end
    --]]
local function clickOption(index, data2)
    local index
    if data2 then
        index = (data2.index)
    end
    
    local playerGold = types.Container.content(self):countOf("gold_001")
    local bankGold = I.FactionBankData.getBankBalance(activeFaction)
    local button = data2.props.text
    local shiftPressed = false
    if input.isKeyPressed(input.KEY.LeftShift) then
        shiftPressed = true
    elseif input.isKeyPressed(input.KEY.RightShift) then
        shiftPressed = true
    end
    local newPlayerGold = 0
    local sound = "item gold up"
    local bookSound = "item book up"
    if shiftPressed then
        sound = bookSound
    end
    local withdraw = button:find("Withdraw") and true or false
    if button == "Deposit 10 gold" then
        newPlayerGold = I.FactionBankData.depositToBank(activeFaction, 10)
    elseif button == "Deposit 100 gold" then
        newPlayerGold = I.FactionBankData.depositToBank(activeFaction, 100)
    elseif button == "Deposit 1000 gold" then
        newPlayerGold = I.FactionBankData.depositToBank(activeFaction, 1000)
    elseif button == "Deposit 10000 gold" then
        newPlayerGold = I.FactionBankData.depositToBank(activeFaction, 10000)
    elseif button == "Deposit Half gold" then
        newPlayerGold = I.FactionBankData.depositToBank(activeFaction, math.floor(playerGold / 2))
    elseif button == "Deposit All gold" then
        newPlayerGold = I.FactionBankData.depositToBank(activeFaction, playerGold)
    elseif button == "Withdraw 10 gold" then
        newPlayerGold = I.FactionBankData.withdrawFromBank(activeFaction, 10, shiftPressed)
    elseif button == "Withdraw 100 gold" then
        newPlayerGold = I.FactionBankData.withdrawFromBank(activeFaction, 100, shiftPressed)
    elseif button == "Withdraw 1000 gold" then
        newPlayerGold = I.FactionBankData.withdrawFromBank(activeFaction, 1000, shiftPressed)
    elseif button == "Withdraw 10000 gold" then
        newPlayerGold = I.FactionBankData.withdrawFromBank(activeFaction, 10000, shiftPressed)
    elseif button == "Withdraw Half gold" then
        newPlayerGold = I.FactionBankData.withdrawFromBank(activeFaction, math.floor(bankGold / 2), shiftPressed)
    elseif button == "Withdraw All gold" then
        newPlayerGold = I.FactionBankData.withdrawFromBank(activeFaction, bankGold, shiftPressed)
    end
    if shiftPressed and withdraw then
        ambient.playSound(sound)
        I.FactionBanksUI.renderBankOptions(lastActivatedActor, newPlayerGold)
    elseif playerGold ~= newPlayerGold and newPlayerGold ~= nil then
        ambient.playSound(sound)

        I.FactionBanksUI.renderBankOptions(lastActivatedActor, newPlayerGold)
    end
    --    closeWindow()
end
local function renderOption(index, text, _, clickCallback)
    local lineText = text or "Line"

    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        events = {
            mouseMove = async:callback(hoverOption),
            mousePress = async:callback(clickCallback)
        },
        index = index,
        props = {
            text = lineText,
            textSize = textSize,
            align = ui.ALIGNMENT.Start,
            arrange = ui.ALIGNMENT.Start,
            autoSize = false,
            size = util.vector2(columnWidth - 18, 24)
        }
    }
end


-- Repeat clickOption function for other options (clickOptionTwo, clickOptionThree, ...)

local function boxedTextContentTable(withdraw)
    local options = {
        renderOption(1, "Deposit 10 gold", "Line1Text", clickOption),
        renderOption(2, "Deposit 100 gold", "Line2Text", clickOption),
        renderOption(3, "Deposit 1000 gold", "Line3Text", clickOption),
        renderOption(4, "Deposit 10000 gold", "Line4Text", clickOption),
        renderOption(5, "Deposit Half gold", "Line6Text", clickOption),
        renderOption(6, "Deposit All gold", "Line5Text", clickOption),
    }
    if withdraw then
        options = {
            renderOption(1, "Withdraw 10 gold", "Line1Text", clickOption),
            renderOption(2, "Withdraw 100 gold", "Line2Text", clickOption),
            renderOption(3, "Withdraw 1000 gold", "Line3Text", clickOption),
            renderOption(4, "Withdraw 10000 gold", "Line4Text", clickOption),
            renderOption(5, "Withdraw Half gold", "Line6Text", clickOption),
            renderOption(6, "Withdraw All gold", "Line5Text", clickOption),
        }
    end
    return borderPadding({
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            autoSize = false,
            size = util.vector2(columnWidth - 8, columnHeight - 8),
        },
        content = ui.content(options)
    }, util.vector2(columnWidth, columnHeight))
end


local function lerp(x, x1, x2, y1, y2)
    return y1 + (x - x1) * ((y2 - y1) / (x2 - x1))
end
local function calculateTextScale()
    local screenSize = ui.layers[1].size
    local width = screenSize.x
    local scale = lerp(width, 1280, 2560, 1.3, 1.8)
    local textScaleSetting = 1
    return scale * textScaleSetting
end
local function openUI()
    local UI = UIInterface.interface.renderItemChoice
end

local function textContent(text, template, size, align)
    template = template or I.MWUI.templates.textNormal
    return {
        type = ui.TYPE.Text,
        template = template,
        props = {
            text = tostring(text),
            textSize = size or textSize,
            arrange = align or ui.ALIGNMENT.Start,
            align = align or ui.ALIGNMENT.Start
        }
    }
end

local function renderBankOptions(BankActor, playerGold, resetUI)
    if resetUI then
        I.UI.setMode("Interface", { windows = {} })
    end
    if not playerGold then
        playerGold = types.Container.content(self):countOf("gold_001")
        I.UI.setMode("Interface", { windows = {} })
    end
    lastActivatedActor = BankActor
    activeFaction = types.NPC.getFactions(BankActor)[1]
    if not activeFaction then
        error("No faction found")
    end
    if not I.UI.getMode() then
        I.UI.setMode("Interface", { windows = {} })
    end
    if (BankActor ~= nil) then
        enabled = true
    end
    if (enabled == false) then
        return
    end
    if (BankUi ~= nil) then
        BankUi:destroy()
    end
    if (self.object ~= nil) then
        player = self.object
    end
    if (OKText == nil) then
        OKText = "OK"
    end
    if (core.isWorldPaused() == false) then
        return
    end

    local depositList = boxedTextContentTable(false)
    local withdrawList = boxedTextContentTable(true)
    local cancelButton = buttonTemplate.button("Cancel", textSize, function()
        closeWindow()
        self:sendEvent("CloseBankWin")
        return
    end, "buttonClose", 1)
    local boxButton = buttonTemplate.button("Safe Deposit Box", textSize, function()
        closeWindow()
        core.sendGlobalEvent("openDepositBox", activeFaction)
        return
    end, "buttonDepositBox", 1)
    local voucherButton = buttonTemplate.button("Deposit Voucher", textSize, function()
        local deposited = I.FactionBankData.depositVouchers(activeFaction)
        if deposited > 0 then
            local bookSound = "item book up"
            ambient.playSound(bookSound)
            I.FactionBanksUI.renderBankOptions(lastActivatedActor)
        end
        return
    end, "buttonDepositVoucher", 1)
    local factionName = core.factions.records[activeFaction].name
    local bankBalance = I.FactionBankData.getBankBalance(activeFaction)
    local voucherBalance = I.FactionBankData.getCarriedVoucherBalance(activeFaction)

    BankUi = ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            arrange = ui.ALIGNMENT.Center
        },
        content = ui.content {
            {
                name = "rootPadding",
                template = I.MWUI.templates.padding,
                content = ui.content {
                    padding(0, topPadding),
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            horizontal = false,
                            arrange = ui.ALIGNMENT.Center,
                        },
                        content = ui.content {
                            padding(sidePadding, 0),
                            textContent(factionName .. " Bank", I.MWUI.templates.textHeader, titleTextSize, ui.ALIGNMENT.Center),
                            padding(0, centerPadding),
                            borderPadding({
                                type = ui.TYPE.Flex,
                                props = {
                                    horizontal = false,
                                    autoSize = false,
                                    size = util.vector2(statusWidth - 8, 54),
                                },
                                content = ui.content {
                                    textContent(factionName .. " Balance: " .. tostring(bankBalance), I.MWUI.templates.textNormal,
                                        textSize, ui.ALIGNMENT.Center),
                                    padding(0, 4),
                                    textContent("Carried Gold: " .. tostring(playerGold), I.MWUI.templates.textNormal, textSize,
                                        ui.ALIGNMENT.Center),
                                        textContent("Carried Voucher Balance: " .. tostring(voucherBalance), I.MWUI.templates.textNormal, textSize,
                                        ui.ALIGNMENT.Center),
                                }
                            }, util.vector2(statusWidth, 62)),
                            padding(0, centerPadding),
                            {
                                type = ui.TYPE.Flex,
                                props = {
                                    horizontal = true,
                                    arrange = ui.ALIGNMENT.Center,
                                },
                                content = ui.content {
                                    {
                                        type = ui.TYPE.Flex,
                                        props = {
                                            horizontal = false,
                                        },
                                        content = ui.content {
                                            textContent("Deposit", I.MWUI.templates.textHeader, textSize, ui.ALIGNMENT.Center),
                                            padding(0, 4),
                                            depositList,
                                        }
                                    },
                                    padding(centerPadding, 0),
                                    {
                                        type = ui.TYPE.Flex,
                                        props = {
                                            horizontal = false,
                                        },
                                        content = ui.content {
                                            textContent("Withdraw", I.MWUI.templates.textHeader, textSize, ui.ALIGNMENT.Center),
                                            padding(0, 4),
                                            withdrawList,
                                        }
                                    },
                                }
                            },
                            padding(0, centerPadding),
                            textContent("Hold Shift to withdraw a transfer voucher", I.MWUI.templates.textNormal, textSize,
                                ui.ALIGNMENT.Center),
                            padding(0, centerPadding),
                            {
                                type = ui.TYPE.Flex,
                                props = {
                                    horizontal = true,
                                    arrange = ui.ALIGNMENT.Center,
                                },
                                content = ui.content {
                                    cancelButton,
                                    padding(centerPadding, 0),
                                    boxButton,
                                    padding(centerPadding, 0),
                                    voucherButton,
                                }
                            },
                            padding(sidePadding, 0),
                        }
                    },
                    padding(0, bottomPadding),
                }
            }
        }
    }
    BankUi:update()
end
local lastSneak = false

local function onUpdate()
    local state = self.controls.sneak
    if state ~= lastSneak then
        core.sendGlobalEvent("SneakStateChanged", state)
        lastSneak = state
    end
end
local function OpenBankMenu()
    local balanceCheck = I.FactionBankTemp.exitTempMode()
    if lastActivatedActor then
        renderBankOptions(lastActivatedActor, balanceCheck, true)
    end
end
return {
    interfaceName = "FactionBanksUI",
    interface = {
        renderBankOptions = renderBankOptions,
    },
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        CloseBankWin  = CloseBankWin,
        OpenBankMenu  = OpenBankMenu,
        UiModeChanged = function(data)
            if data and data.arg and data.arg then
                lastActivatedActor = data.arg
            end


            if not data.newMode then
                if BankUi then
                    closeWindow()
                end
            else
                if true == true then
                    --
                    --closeWindow(true)
                elseif data and data.arg and data.arg then
                    lastActivatedActor = data.arg
                end
            end
        end
    },

}
