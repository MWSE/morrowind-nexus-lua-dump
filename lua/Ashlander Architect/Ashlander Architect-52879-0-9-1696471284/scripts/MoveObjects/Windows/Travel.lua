local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local Camera = require("openmw.camera")
local input = require("openmw.input")
local storage = require("openmw.storage")
local ui = require("openmw.ui")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local time = require('openmw_aux.time')
local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local Camera = require("openmw.camera")
local input = require("openmw.input")
local storage = require("openmw.storage")
local acti = require("openmw.interfaces").Activation
local playerSelected
local iconsize = 4
local Actor = require("openmw.types").Actor

local constants = require('scripts.omw.mwui.constants')
local objectToSelect = {}
local selectedObjects = {}
local mainWindowSizeX = 480
local mainWindowSizeY = 120


local settlementData = storage.globalSection("AASettlements")
local editMode = false

local dataInUse = nil

local lastActivatedActor = nil

local travelUi = nil
local boldOne = false
local boldTwo = false
local boldThree = false
local boldFour = false
local boldFive = false
local boldSix = false

local player = nil
local enabled = false
local line1text = ""
local line2text = ""
local line3text = ""
local line4text = ""
local line5text = ""
local line6text = ""


local custData1 = nil
local custData2 = nil
local custData3 = nil
local custData4 = nil
local custData5 = nil
local custData6 = nil


local dest1price = 0
local dest2price = 0
local dest3price = 0
local dest4price = 0
local dest5price = 0
local dest6price = 0

local function hoverNone()
    boldOne = false
    boldTwo = false
    print("Hover None")
    I.TravelWindow.renderTravelOptions()
end
local function hoverOne(mouse)
    if (mouse) then
        print("TP?")
    end
    print("hoverOne")
    boldOne = true
    boldTwo = false
    boldThree = false
    boldFour = false
    boldFive = false
    boldSix = false
    I.TravelWindow.renderTravelOptions()
end

local function hoverTwo()
    boldOne = false
    print("hoverTwo")
    boldTwo = true
    boldThree = false
    boldFour = false
    boldFive = false
    boldSix = false
    I.TravelWindow.renderTravelOptions()
end

local function hoverThree()
    print("hoverThree")
    boldOne = false
    boldTwo = false
    boldThree = true
    boldFour = false
    boldFive = false
    boldSix = false
    I.TravelWindow.renderTravelOptions()
end

local function hoverFour()
    print("hoverFour")
    boldOne = false
    boldTwo = false
    boldThree = false
    boldFour = true
    boldFive = false
    boldSix = false
    I.TravelWindow.renderTravelOptions()
end

local function hoverFive()
    print("hoverFive")
    boldOne = false
    boldTwo = false
    boldThree = false
    boldFour = false
    boldFive = true
    boldSix = false
    I.TravelWindow.renderTravelOptions()
end

local function hoverSix()
    print("hoverSix")
    boldOne = false
    boldTwo = false
    boldThree = false
    boldFour = false
    boldFive = false
    boldSix = true
    I.TravelWindow.renderTravelOptions()
end

local function addCustDestTwoWay(sourceNpc, targetCellName, targetPos, targetRot, startingPos, startingCell)

end
local function clickOne()
    if (editMode == true) then
        print("Add it time")
        local list = settlementData:get("settlementList")
        local cellname = ""
        for x, structure in ipairs(settlementData:get("settlementList")) do
            local dist = math.sqrt((self.position.x - structure.settlementCenterx) ^ 2 +
                (self.position.y - structure.settlementCentery) ^ 2)

            if (dist < structure.settlementDiameter / 2) then
                cellname = structure.settlementName
            end
        end
        for _, item in ipairs(I.TravelWindow_Data.travelData) do
            if (types.NPC.record(lastActivatedActor).class == item.class and (item.travel1destcellname == line1text)) then
                I.TravelWindow_Data.addCustDestTwoWay(lastActivatedActor, line1text, item.travel1dest,
                    item.travel1destrot.z, self.position, cellname)
                print("Add it time")
            end
            if (types.NPC.record(lastActivatedActor).class == item.class and (item.travel2destcellname == line1text)) then
                I.TravelWindow_Data.addCustDestTwoWay(lastActivatedActor, line1text, item.travel2dest,
                    item.travel2destrot.z, self.position, cellname)
                print("Add it time")
            end
            if (types.NPC.record(lastActivatedActor).class == item.class and (item.travel3destcellname == line1text)) then
                I.TravelWindow_Data.addCustDestTwoWay(lastActivatedActor, line1text, item.travel3dest,
                    item.travel3destrot.z, self.position, cellname)
                print("Add it time")
            end
            if (types.NPC.record(lastActivatedActor).class == item.class and (item.travel4destcellname == line1text)) then
                I.TravelWindow_Data.addCustDestTwoWay(lastActivatedActor, line1text, item.travel4dest,
                    item.travel4destrot.z, self.position, cellname)
                print("Add it time")
            end
        end
        I.TravelWindow.clearWindow()
        core.sendGlobalEvent("clearTempActor")
        return
    end
    if (types.Actor.inventory(self):countOf("gold_001") < dest1price) then
        return
    end
    core.sendGlobalEvent("removeItemCount", { count = dest1price, actor = self, itemId = "gold_001" })
    core.sendGlobalEvent("clearTempActor")
    if (custData1 ~= nil) then
        I.ZackUtils.teleportItemToCell(player, "",
            util.vector3(custData1.targetPos.x, custData1.targetPos.y, custData1.targetPos.z),
            util.vector3(0, 0, custData1.targetRot))
    else
        I.ZackUtils.teleportItemToCell(player, dataInUse.travel1destcellname,
            util.vector3(dataInUse.travel1dest.x, dataInUse.travel1dest.y, dataInUse.travel1dest.z),
            util.vector3(0, 0, dataInUse.travel1destrot.z))
    end
    I.TravelWindow.clearWindow()
end


local function clickTwo()
    if (types.Actor.inventory(self):countOf("gold_001") < dest2price) then
        return
    end
    core.sendGlobalEvent("removeItemCount", { count = dest2price, actor = self, itemId = "gold_001" })
    I.TravelWindow.clearWindow()
    core.sendGlobalEvent("clearTempActor")
    I.ZackUtils.teleportItemToCell(player, "",
        util.vector3(dataInUse.travel2dest.x, dataInUse.travel2dest.y, dataInUse.travel2dest.z),
        util.vector3(0, 0, dataInUse.travel2destrot.z))
end

local function clickThree()
    if (types.Actor.inventory(self):countOf("gold_001") < dest3price) then
        return
    end
    core.sendGlobalEvent("removeItemCount", { count = dest3price, actor = self, itemId = "gold_001" })
    I.TravelWindow.clearWindow()
    core.sendGlobalEvent("clearTempActor")
    I.ZackUtils.teleportItemToCell(player, "",
        util.vector3(dataInUse.travel3dest.x, dataInUse.travel3dest.y, dataInUse.travel3dest.z),
        util.vector3(0, 0, dataInUse.travel3destrot.z))
end

local function clickFour()
    if (types.Actor.inventory(self):countOf("gold_001") < dest4price) then
        return
    end
    core.sendGlobalEvent("removeItemCount", { count = dest4price, actor = self, itemId = "gold_001" })
    I.TravelWindow.clearWindow()
    core.sendGlobalEvent("clearTempActor")
    I.ZackUtils.teleportItemToCell(player, "",
        util.vector3(dataInUse.travel4dest.x, dataInUse.travel4dest.y, dataInUse.travel4dest.z),
        util.vector3(0, 0, dataInUse.travel4destrot.z))
end

local function clickFive()
    if (types.Actor.inventory(self):countOf("gold_001") < dest5price) then
        return
    end
    core.sendGlobalEvent("removeItemCount", { count = dest5price, actor = self, itemId = "gold_001" })
    core.sendGlobalEvent("clearTempActor")
    if (custData5 ~= nil) then
        I.ZackUtils.teleportItemToCell(player, "",
            util.vector3(custData5.targetPos.x, custData5.targetPos.y, custData5.targetPos.z),
            util.vector3(0, 0, custData5.targetRot))
    else
        I.ZackUtils.teleportItemToCell(player, dataInUse.travel5destcellname,
            util.vector3(dataInUse.travel5dest.x, dataInUse.travel5dest.y, dataInUse.travel5dest.z),
            util.vector3(0, 0, dataInUse.travel5destrot.z))
    end
    I.TravelWindow.clearWindow()
end

local function clickSix()
    if (types.Actor.inventory(self):countOf("gold_001") < dest6price) then
        return
    end
    core.sendGlobalEvent("removeItemCount", { count = dest6price, actor = self, itemId = "gold_001" })
    I.TravelWindow.clearWindow()
    core.sendGlobalEvent("clearTempActor")
    I.ZackUtils.teleportItemToCell(player, dataInUse.travel6destcellname,
        util.vector3(dataInUse.travel6dest.x, dataInUse.travel6dest.y, dataInUse.travel6dest.z),
        util.vector3(0, 0, dataInUse.travel6destrot.z))
end
local function clickCancel()
    I.TravelWindow.clearWindow()
    print("Cancel")
end




local function boxedTextContentTable(text, callback)
    local textOne = I.MWUI.templates.textNormal
    if (types.Actor.inventory(player):countOf("gold_001") < dest1price) then
        textOne = {
            type = ui.TYPE.Text,
            props = {
                textSize = constants.textNormalSize,
                textColor = util.color.rgba(179, 168, 135, 0.7),
            },
        }
    elseif (boldOne == true) then
        textOne = I.MWUI.templates.textHeader
    end

    local textTwo = I.MWUI.templates.textNormal
    if (types.Actor.inventory(player):countOf("gold_001") < dest2price) then
        textTwo = {
            type = ui.TYPE.Text,
            props = {
                textSize = constants.textNormalSize,
                textColor = util.color.rgba(179, 168, 135, 0.7),
            },
        }
    elseif (boldTwo == true) then
        textTwo = I.MWUI.templates.textHeader
    end


    local textThree = I.MWUI.templates.textNormal
    if (types.Actor.inventory(player):countOf("gold_001") < dest3price) then
        textThree = {
            type = ui.TYPE.Text,
            props = {
                textSize = constants.textNormalSize,
                textColor = util.color.rgba(179, 168, 135, 0.7),
            },
        }
    elseif (boldThree == true) then
        textThree = I.MWUI.templates.textHeader
    end


    local textFour = I.MWUI.templates.textNormal
    if (types.Actor.inventory(player):countOf("gold_001") < dest4price) then
        textFour = {
            type = ui.TYPE.Text,
            props = {
                textSize = constants.textNormalSize,
                textColor = util.color.rgba(179, 168, 135, 0.7),
            },
        }
    elseif (boldFour == true) then
        textFour = I.MWUI.templates.textHeader
    end


    local textFive = I.MWUI.templates.textNormal
    if (types.Actor.inventory(player):countOf("gold_001") < dest5price) then
        textFive = {
            type = ui.TYPE.Text,
            props = {
                textSize = constants.textNormalSize,
                textColor = util.color.rgba(179, 168, 135, 0.7),
            },
        }
    elseif (boldFive == true) then
        textFive = I.MWUI.templates.textHeader
    end

    local textSix = I.MWUI.templates.textNormal
    if (types.Actor.inventory(player):countOf("gold_001") < dest6price) then
        textSix = {
            type = ui.TYPE.Text,
            props = {
                textSize = constants.textNormalSize,
                textColor = util.color.rgba(179, 168, 135, 0.7),
            },
        }
    elseif (boldSix == true) then
        textSix = I.MWUI.templates.textHeader
    end

    local textWidth = 400
    return {
        type = ui.TYPE.Container,
        props = {
            anchor = util.vector2(0.5, 0.5),
            size = util.vector2(400, 400),
            autoSize = false
        },
        content = ui.content {
            {
                template = I.MWUI.templates.box,
                events = {
                    mouseMove = async:callback(I.TravelWindow.hoverNone),
                    mouseClick = async:callback(I.TravelWindow.hoverNone)
                },
                props = {
                    anchor = util.vector2(0, -0.5),
                    size = util.vector2(400, 400),
                    autoSize = false
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = textOne,
                        events = {
                            mouseMove = async:callback(I.TravelWindow.hoverNone),
                            mouseClick = async:callback(I.TravelWindow.hoverNone)
                        },
                        props = {
                            text = "",
                            textSize = 15,
                            align = ui.ALIGNMENT.Start,
                            anchor = util.vector2(0, 0),
                            arrange = ui.ALIGNMENT.End,
                            size = util.vector2(480, 90),
                            autoSize = false
                        }
                    },
                    {
                        type = ui.TYPE.Text,
                        template = textOne,
                        events = {
                            mouseMove = async:callback(I.TravelWindow.hoverOne),
                            mousePress = async:callback(clickOne)
                        },
                        props = {
                            text = line1text,
                            textSize = 15,
                            align = ui.ALIGNMENT.Start,
                            anchor = util.vector2(0, 0),
                            arrange = ui.ALIGNMENT.End,
                            size = util.vector2(textWidth, 30),
                            autoSize = false
                        }
                    },
                    {
                        type = ui.TYPE.Text,
                        template = textTwo,
                        events = {
                            mouseMove = async:callback(I.TravelWindow.hoverTwo),
                            mousePress = async:callback(clickTwo)
                        },
                        props = {
                            text = line2text,
                            textSize = 15,
                            anchor = util.vector2(0, -0.8),
                            align = ui.ALIGNMENT.Center,
                            arrange = ui.ALIGNMENT.Center,
                            size = util.vector2(textWidth, 20),
                            autoSize = false
                        }
                    },
                    {
                        type = ui.TYPE.Text,
                        template = textThree,
                        events = {
                            mouseMove = async:callback(I.TravelWindow.hoverThree),
                            mousePress = async:callback(clickThree)
                        },
                        props = {
                            text = line3text,
                            textSize = 15,
                            anchor = util.vector2(0, -1.6), -- Updated anchor value
                            align = ui.ALIGNMENT.Start,
                            arrange = ui.ALIGNMENT.End,
                            size = util.vector2(textWidth, 20),
                            autoSize = false
                        }
                    },
                    {
                        type = ui.TYPE.Text,
                        template = textFour,
                        events = {
                            mouseMove = async:callback(I.TravelWindow.hoverFour),
                            mousePress = async:callback(clickFour)
                        },
                        props = {
                            text = line4text,
                            textSize = 15,
                            anchor = util.vector2(0, -2.4), -- Updated anchor value
                            align = ui.ALIGNMENT.Center,
                            arrange = ui.ALIGNMENT.Center,
                            size = util.vector2(textWidth, 20),
                            autoSize = false
                        }
                    },
                    {
                        type = ui.TYPE.Text,
                        template = textFive,
                        events = {
                            mouseMove = async:callback(I.TravelWindow.hoverFive),
                            mousePress = async:callback(clickFive)
                        },
                        props = {
                            text = line5text,
                            textSize = 15,
                            anchor = util.vector2(0, -3.2), -- Updated anchor value
                            align = ui.ALIGNMENT.Start,
                            arrange = ui.ALIGNMENT.End,
                            size = util.vector2(textWidth, 20),
                            autoSize = false
                        }
                    },
                    {
                        type = ui.TYPE.Text,
                        template = textSix,
                        events = {
                            mouseMove = async:callback(I.TravelWindow.hoverSix),
                            mousePress = async:callback(clickSix)
                        },
                        props = {
                            text = line6text,
                            textSize = 15,
                            anchor = util.vector2(0, -4), -- Updated anchor value
                            align = ui.ALIGNMENT.Center,
                            arrange = ui.ALIGNMENT.Center,
                            size = util.vector2(textWidth, 20),
                            autoSize = false
                        }
                    }
                }
            }
        }
    }
end

local function textContentLeft(text)
    return {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            relativePosition = v2(0.5, 0.5),
            text = tostring(text),
            arrange = ui.ALIGNMENT.Start,
            align = ui.ALIGNMENT.Start
        }
    }
end

local function boxedTextContentEnd(text, callback)
    return {
        type = ui.TYPE.Container,
        events = { mousePress = async:callback(clickCancel) },
        props = {
            anchor = util.vector2(0, -0.5),
            align = ui.ALIGNMENT.End,
            arrange = ui.ALIGNMENT.End,
        },
        content = ui.content {
            {
                template = I.MWUI.templates.box,
                events = { mousePress = async:callback(clickCancel) },
                props = {
                    anchor = util.vector2(0, -0.5),
                    align = ui.ALIGNMENT.End,
                    arrange = ui.ALIGNMENT.End,
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        events = { mousePress = async:callback(clickCancel) },
                        props = {
                            text = text,
                            textSize = 15,
                            align = ui.ALIGNMENT.End,
                            arrange = ui.ALIGNMENT.End,
                        }
                    }
                }
            }
        }
    }
end

local function findValidDestinations(sourceActor)
    local ret = {}
    for _, item in ipairs(I.TravelWindow_Data.travelData) do
        if (types.NPC.record(sourceActor).class == item.class and item.myCell ~= nil and item.myCell ~= "") then
            local dist = 0
            if (sourceActor.cell.isExterior) then
                dist = math.sqrt(math.pow(sourceActor.position.x - item.myPos.x, 2) +
                    math.pow(sourceActor.position.y - item.myPos.y, 2)
                    + math.pow(sourceActor.position.z - item.myPos.z, 2))
            end
            if (dist < 150000) then
                table.insert(ret, item.myCell)
                print(item.myCell .. ": " .. tostring(dist), item.ID)
            end
        end
    end
    return ret
end
local function buildData(id)
    for _, item in ipairs(I.TravelWindow_Data.travelData) do
        if (item.ID:lower() == id.recordId:lower()) then
            dataInUse = item
            local disposition = 40
            if (item.travel1destcellname ~= nil) then
                line1text, dest1price = I.TravelWindow.addDestination(item.travel1destcellname, item.travel1dest,
                    lastActivatedActor, disposition)
            end
            if (item.travel2destcellname ~= nil) then
                line2text, dest2price = I.TravelWindow.addDestination(item.travel2destcellname, item.travel2dest,
                    lastActivatedActor, disposition)
            else
                line2text = ""
                dest2price = -1
            end
            if (item.travel3destcellname ~= nil) then
                line3text, dest3price = I.TravelWindow.addDestination(item.travel3destcellname, item.travel3dest,
                    lastActivatedActor, disposition)
            else
                line3text = ""
                dest3price = -1
            end
            if (item.travel4destcellname ~= nil) then
                line4text, dest4price = I.TravelWindow.addDestination(item.travel4destcellname, item.travel4dest,
                    lastActivatedActor, disposition)
            else
                line4text = ""
                dest4price = -1
            end
        end
    end
    local cdest1 = I.TravelWindow_Data.getCustomDataID(id.recordId)

    if (cdest1 ~= nil) then
        dataInUse = item
        local disposition = 40
        print("Found custom data")
        if (cdest1.targetCellName ~= nil) then
            
            if(line1text == "") then
    
                line1text, dest1price = I.TravelWindow.addDestination(cdest1.targetCellName, cdest1.targetPos,
                lastActivatedActor, disposition)

                custData1            = cdest1
            elseif(line2text == "") then
    
                line2text, dest2price = I.TravelWindow.addDestination(cdest1.targetCellName, cdest1.targetPos,
                lastActivatedActor, disposition)

                custData2             = cdest1
            elseif(line3text == "") then
    
                line3text, dest3price = I.TravelWindow.addDestination(cdest1.targetCellName, cdest1.targetPos,
                lastActivatedActor, disposition)

                custData3             = cdest1
            elseif(line4text == "") then
    
                line4text, dest4price = I.TravelWindow.addDestination(cdest1.targetCellName, cdest1.targetPos,
                lastActivatedActor, disposition)

                custData4             = cdest1
            elseif(line5text == "") then
    
                line5text, dest5price = I.TravelWindow.addDestination(cdest1.targetCellName, cdest1.targetPos,
                lastActivatedActor, disposition)

                custData5             = cdest1
            elseif(line6text == "") then

                    line6text, dest6price = I.TravelWindow.addDestination(cdest1.targetCellName, cdest1.targetPos,
                    lastActivatedActor, disposition)
                custData6             = cdest1
            end
        end
    end
    cdest1 = I.TravelWindow_Data.getCustomDataID(id.id)

    if (cdest1 ~= nil) then
        dataInUse = item
        local disposition = 40
        print("Found custom data")
        if (cdest1.targetCellName ~= nil) then
            
            if(line1text == "") then
    
                line1text, dest1price = I.TravelWindow.addDestination(cdest1.targetCellName, cdest1.targetPos,
                lastActivatedActor, disposition)

                custData1            = cdest1
            elseif(line2text == "") then
    
                line2text, dest2price = I.TravelWindow.addDestination(cdest1.targetCellName, cdest1.targetPos,
                lastActivatedActor, disposition)

                custData2             = cdest1
            elseif(line3text == "") then
    
                line3text, dest3price = I.TravelWindow.addDestination(cdest1.targetCellName, cdest1.targetPos,
                lastActivatedActor, disposition)

                custData3             = cdest1
            elseif(line4text == "") then
    
                line4text, dest4price = I.TravelWindow.addDestination(cdest1.targetCellName, cdest1.targetPos,
                lastActivatedActor, disposition)

                custData4             = cdest1
            elseif(line5text == "") then
    
                line5text, dest5price = I.TravelWindow.addDestination(cdest1.targetCellName, cdest1.targetPos,
                lastActivatedActor, disposition)

                custData5             = cdest1
            elseif(line6text == "") then

                    line6text, dest6price = I.TravelWindow.addDestination(cdest1.targetCellName, cdest1.targetPos,
                    lastActivatedActor, disposition)
                custData6             = cdest1
            end
        end
    end
    for _, item in ipairs(I.TravelWindow_Data.custTravelData) do
        print(item.ID)
        if (item.ID:lower() == id.recordId:lower()) then

        end
    end
end
local stopFn
local function onUpdate()
    if (core.isWorldPaused() == false) then
        print("bad")
        I.TravelWindow.clearWindow()
        stopfn()
    end
end
local function renderTravelOptions(playerref, travelnpcid)
    print("Redoing")

    if (travelnpcid ~= nil) then
        enabled = true
        buildData(travelnpcid)
        stopFn = time.runRepeatedly(function() onUpdate() end,
            0.1 * time.second)
        --  async:registerTimerCallback("onupdate",onUpdate)
    end
    if (enabled == false) then
        return
    end
    if (travelUi ~= nil) then
        travelUi:destroy()
    end
    if (playerref ~= nil) then
        player = playerref
    end
    if (OKText == nil) then
        OKText = "OK"
    end
    if (core.isWorldPaused() == false) then
        return
    end
    local vertical = 50
    local horizontal = (ui.screenSize().x / 2) - 400

    local vertical = 0
    local horizontal = ui.screenSize().x / 2 - 25
    local vertical = vertical + ui.screenSize().y / 2 + 100

    local content = {}
    local content2 = {}
    local content3 = {}
    local content4 = {}
    table.insert(content, I.ZackUtilsUI.textContent(""))
    --    table.insert(content, textContent("Travel"))
    if (editMode == true) then
        table.insert(content, textContentLeft("Select destination to add"))
    else
        table.insert(content, textContentLeft("Select destination"))
    end
    local textEdit = boxedTextContentTable("Ald-Ruhn - 36gp", async:callback(nil))
    local cancelButton = boxedTextContentEnd("Cancel")
    local goldText = textContentLeft("Gold: " .. tostring(types.Actor.inventory(player):countOf("gold_001")),
        async:callback(nil))
    --  local okButton = boxedTextContentEnd("Cancel", async:callback(nil))
    table.insert(content2, textEdit)
    table.insert(content3, cancelButton)
    table.insert(content4, goldText)

    travelUi = ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            --position = v2(500, 250),
            vertical = false,
            relativeSize = util.vector2(0.5, 0.8),
            arrange = ui.ALIGNMENT.Center
        },
        content = ui.content {
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textHeader,
                props = {
                    anchor = v2(-5, -0),
                    relativePosition = v2(0.5, 0.5),
                    text = tostring("Travel"),
                    arrange = ui.ALIGNMENT.Start,
                    align = ui.ALIGNMENT.Center
                },
            },
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    anchor = v2(0.0, -0.0),
                    horizontal = true,
                    autoSize = false,
                    align = ui.ALIGNMENT.Start,
                    arrange = ui.ALIGNMENT.Start,
                    size = util.vector2(500, 180),
                }
            },
            {
                type = ui.TYPE.Flex,
                content = ui.content(content3),
                props = {
                    anchor = v2(0.0, -0.0),
                    horizontal = true,
                    autoSize = false,
                    align = ui.ALIGNMENT.End,
                    arrange = ui.ALIGNMENT.End,
                    size = util.vector2(500, 180),
                }
            },
            {
                type = ui.TYPE.Flex,
                content = ui.content(content4),
                props = {
                    anchor = v2(-0.01, -0.01),
                    horizontal = true,
                    autoSize = false,
                    align = ui.ALIGNMENT.Start,
                    arrange = ui.ALIGNMENT.End,
                    size = util.vector2(500, 180),
                }
            },
            {
                type = ui.TYPE.Flex,
                content = ui.content(content2),
                props = {
                    horizontal = true,
                    anchor = v2(0, 0.05),
                    autoSize = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Start,
                    size = util.vector2(500, 180),
                }
            },
        }
    }
end

local function clearWindow()
    travelUi:destroy()
    enabled = false
    boldOne = false
    boldTwo = false
    boldThree = false
    boldFour = false
    boldFive = false
    boldSix = false
    custData1 = nil
    custData2 = nil
    custData3 = nil
    custData4 = nil
    custData5 = nil
    custData6 = nil
    line1text = ""
    line2text = ""
    line3text = ""
    line4text = ""
    line5text = ""
    line6text = ""
end
local function addDestination(name, Tarpos, npc, disposition)
    local price

    local player = self
    local playerGold = types.Actor.inventory(player):countOf("gold_001")

    if self.cell.isExterior == false then
        price = core.getGMST("fMagesGuildTravel")
    else
        local playerPos = player.position
        local d = math.sqrt(math.pow(Tarpos.x - playerPos.x, 2) + math.pow(Tarpos.y - playerPos.y, 2)
            + math.pow(Tarpos.z - playerPos.z, 2))
        local fTravelMult = core.getGMST("fTravelMult")
        if fTravelMult ~= 0 then
            price = math.floor(d / fTravelMult)
        else
            price = math.floor(d)
        end
    end

    price = math.max(1, price)
    price = I.ZackUtils.getBarterOffer(npc, price, disposition, true)

    -- Add price for the travelling followers
    local followers = {}
    for i, record in ipairs(nearby.actors) do
        ---  records[string.lower(record.id)] = true
    end
    --need to fix this later
    -- Apply followers cost, unlike vanilla the first follower doesn't travel for free
    price = price * (1 + #followers)



    return ("" .. name .. "   -   " .. tostring(price) .. core.getGMST("sGp")), price
end

local function activated(actor)
    print("Was activated")
    lastActivatedActor = actor
end
local function addDestinationWindow()

    if(addDestinationWindow == nil) then
        return
    end
    editMode = true
    local dests = findValidDestinations(lastActivatedActor)
    if (#dests > 0) then
        line1text = dests[1]
    end
    if (#dests > 1) then
        line2text = dests[2]
    end
    if (#dests > 2) then
        line3text = dests[3]
    end
    if (#dests > 3) then
        line4text = dests[4]
    end
    if (#dests > 4) then
        line5text = dests[5]
    end
    if (#dests > 5) then
        line6text = dests[6]
    end
    renderTravelOptions(self, lastActivatedActor)
end
local function startTravel(player)
    editMode = false
    renderTravelOptions(self, lastActivatedActor)
    lastActivatedActor = nil
    --core.sendGlobalEvent("activateThingEvent",{source = self,target = lastActivatedActor})
end

return {
    interfaceName = "TravelWindow",
    interface = {
        version = 1,
        imageContent = imageContent,
        textContent = textContent,
        addDestination = addDestination,
        paddedTextContent = paddedTextContent,
        boxedTextContent = boxedTextContent,
        hoverOne = hoverOne,
        hoverTwo = hoverTwo,
        hoverThree = hoverThree,
        hoverFour = hoverFour,
        hoverFive = hoverFive,
        hoverSix = hoverSix,
        hoverNone = hoverNone,
        boxedTextEditContent = boxedTextEditContent,
        renderItemChoice = renderItemChoice,
        renderTextWithBox = renderTextWithBox,
        renderTextInput = renderTextInput,
        renderTravelOptions = renderTravelOptions,
        clearWindow = clearWindow,
        findValidDestinations = findValidDestinations,
        addDestinationWindow = addDestinationWindow,
    },
    eventHandlers = {
        activated = activated,
        startTravel = startTravel,
        renameCellLabel = renameCellLabel,
        exitBuildMode = exitBuildMode,
        addDestinationWindow = addDestinationWindow,
    },
}
