local ui = require("openmw.ui")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local input = require("openmw.input")
local self = require("openmw.self")
local storage = require("openmw.storage")
local constants = require('scripts.omw.mwui.constants')
local ambient = require("openmw.ambient")

local objectToSelect = {}
local selectedObjects = {}
local mainWindowSizeX = 480
local mainWindowSizeY = 120

local settlementData = storage.globalSection("AASettlements")

local dataInUse = nil
local lastActivatedActor = nil
local travelUi = nil
local boldOptions = {}
local player = nil
local enabled = false
local textLines = {}
local custData = {}
local prices = {}

local currentSelectedIndex = 1
local function closeWindow(openDialog)
    print("Click close")
    if (travelUi ~= nil) then
        travelUi:destroy()
        enabled = false
    end
    if openDialog then
        I.UI.setMode("Dialogue", { target = lastActivatedActor })
    end
end
local travelData = {}
local v2 = util.vector2

local function setTargetActor(npc)
    lastActivatedActor = npc
end
local function resetBoldOptions(index)
    currentSelectedIndex = index
    boldOptions = {}
    if index and travelData[index] then
        
    boldOptions[index] = true
    end
    I.TravelWindow.renderTravelOptions()
end

local function hoverOption(data, data2)
    local index
    if data2 then
        index = (data2.index)
    end
    resetBoldOptions(index)
end
local function createRotation(x, y, z)
    if (core.API_REVISION < 40) then
        return util.vector3(x, y, z)
    else
        local rotate = util.transform.rotateZ(z)
        local rotatex = util.transform.rotateX(x)
        local rotatey = util.transform.rotateY(y)
        rotate = rotate:__mul(rotatex)
        rotate = rotate:__mul(rotatey)
        return rotate
    end
end
local function travelToDestination(destCellName, destPos, destRot, price)
    if types.Actor.inventory(player):countOf("gold_001") < price then
        return
    end
    print(destRot)
    I.ZackUtilsAA.removeItem("gold_001", price)
    if not self.cell.isExterior then
        ambient.playSound("mysticism cast")
    else
        local fTravelMult = core.getGMST("fTravelTimeMult")
        local d = (util.vector3(destPos.x, destPos.y, 0) - util.vector3(self.position.x, self.position.y, 0)):length()
        local travelTimeMult = core.getGMST("fTravelTimeMult")

        local hours = math.floor(d / travelTimeMult)
        core.sendGlobalEvent("AdvanceTime", hours)
    end
    I.UI.setMode()
    I.ZackUtilsAA.teleportItemToCell(self.object, destCellName, destPos, createRotation(0, 0, destRot))
end
local function clickOption(index, data2)
    local index
    if data2 then
        index = (data2.index)
    end
    local data = travelData[index]

    if types.Actor.inventory(player):countOf("gold_001") < data.price then
        return
    end
    closeWindow()
    -- ui.showMessage("Travel to " .. data.cellName)
    travelToDestination(data.cellName, util.vector3(data.position.x, data.position.y, data.position.z), data.rotation:getAnglesZYX(),
        data.price)
    -- Implement your click logic here for the specific option
end

local function addCustomDestinationTwoWay(sourceNpc, targetCellName, targetPos, targetRot, startingPos, startingCell)
    -- Implement your logic for adding a custom destination here
end

local textDisabled = {
    type = ui.TYPE.Text,
    props = {
        textSize = constants.textNormalSize,
        textColor = util.color.rgb(10, 10, 10)
    },
}

local function renderOption(index, text, _, clickCallback)
    local lineText = ""
    local template = I.MWUI.templates.textNormal
    if travelData[index] and travelData[index].line then
        lineText = travelData[index].line

        local canAfford = types.Actor.inventory(self):countOf("gold_001") > travelData[index].price

        if canAfford and boldOptions[index] then
            template = I.MWUI.templates.textHeader
        elseif not canAfford then
            template = textDisabled
        end
    end

    return {
        type = ui.TYPE.Text,
        template = template,
        events = {
            mouseMove = async:callback(hoverOption),
            mousePress = async:callback(clickCallback)
        },
        index = index,
        props = {
            text = lineText,
            textSize = 15,
            align = ui.ALIGNMENT.Start,
            anchor = util.vector2(0, -index * 1.0 + 1),
            arrange = ui.ALIGNMENT.End,
            size = util.vector2(480, 20),
            autoSize = false
        }
    }
end


-- Repeat clickOption function for other options (clickOptionTwo, clickOptionThree, ...)

local function boxedTextContentTable(text)
    local content = {
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
                    renderOption(1, "Dest1", "Line1Text", clickOption),
                    renderOption(2, "Dest2", "Line2Text", clickOption),
                    renderOption(3, "Dest3", "Line3Text", clickOption),
                    renderOption(4, "Dest4", "Line4Text", clickOption),
                    renderOption(5, "Dest5", "Line5Text", clickOption),
                    renderOption(6, "Dest6", "Line6Text", clickOption),
                }
            }
        }
    }

    return content
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
        events = {
            mousePress = async:callback(function()
                if (travelUi ~= nil) then
                    travelUi:destroy()
                    enabled = false
                end
            end)
        },
        props = {
            anchor = util.vector2(0, -0.5),
            align = ui.ALIGNMENT.End,
            arrange = ui.ALIGNMENT.End,
        },
        content = ui.content {
            {
                template = I.MWUI.templates.box,
                props = {
                    anchor = util.vector2(0, -0.5),
                    align = ui.ALIGNMENT.End,
                    arrange = ui.ALIGNMENT.End,
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
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
                    math.pow(sourceActor.position.y - item.myPos.y, 2) +
                    math.pow(sourceActor.position.z - item.myPos.z, 2))
            end
            if (dist < 150000) then
                table.insert(ret, item.myCell)
                print(item.myCell .. ": " .. tostring(dist), item.ID)
            end
        end
    end
    return ret
end

local function onUpdate()
    if (core.isWorldPaused() == false) then
        print("bad")
        I.TravelWindow.clearWindow()
    end
end
local innerWindowSize = util.vector2(500, 250)
local function renderTravelOptions(travelActor)
    if not I.UI.getMode() then
        I.UI.setMode("Interface", { windows = {} })
    end
    if (travelActor ~= nil) then
        enabled = true
    end
    if (enabled == false) then
        return
    end
    if (travelUi ~= nil) then
        travelUi:destroy()
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

    local content = {}
    local content2 = {}
    local content3 = {}
    local content4 = {}

    --resetBoldOptions()

    table.insert(content, I.ZackUtilsUI_AA.textContent(""))
    table.insert(content, textContentLeft("Select destination"))

    local textEdit = boxedTextContentTable("Ald-Ruhn - 36gp")
    local cancelButton = boxedTextContentEnd("Cancel", function() closeWindow(true) end)
    local goldText = textContentLeft("Gold: " .. tostring(types.Actor.inventory(player):countOf("gold_001")))

    table.insert(content2, textEdit)
    table.insert(content3, cancelButton)
    table.insert(content4, goldText)

    travelUi = ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
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
                    size = innerWindowSize
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
                    size = innerWindowSize
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
                    size = innerWindowSize
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
                    size = innerWindowSize
                }
            },
        }
    }
end

local function clearWindow()
    if not travelUi then return end
    travelUi:destroy()
end

local function addDestination(name, Tarpos, npc, disposition)
    local price = core.getGMST("fMagesGuildTravel")

    if self.cell.isExterior then
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

end

local function startTravel(actor)
    renderTravelOptions(actor)
    lastActivatedActor = nil
end
local function hoverNone()
    resetBoldOptions()
    I.TravelWindow.renderTravelOptions()
end
local function onActivate(actor)
    if actor.type == types.NPC then
        lastActivatedActor = actor
    end
end
--I.UI.registerWindow("Travel",
--    function()
 --       enabled = true
       -- I.UI.setMode("Interface", { windows = {} })

        --                travelData = I.TravelWindow_Data.getTravelDataForActor(lastActivatedActor)

        --renderTravelOptions(lastActivatedActor)
        --I.TravelWindow.renderTravelOptions(lastActivatedActor)

--        core.sendGlobalEvent("getRequestForActorData", lastActivatedActor)
 --   end,

   -- function()
   --     closeWindow()
   -- end
--)
local function onInputAction(action)
    if not travelUi then return end
if action == input.ACTION.ZoomIn then
    if not currentSelectedIndex then
        currentSelectedIndex = 0
    end
    if travelData[ currentSelectedIndex + 1] then
        
    currentSelectedIndex = currentSelectedIndex + 1
    end
    resetBoldOptions(currentSelectedIndex)
elseif action == input.ACTION.ZoomOut then
    if not currentSelectedIndex then
        currentSelectedIndex = #travelData
    end
    if travelData[ currentSelectedIndex - 1] then
        
    currentSelectedIndex = currentSelectedIndex - 1
    end
    resetBoldOptions(currentSelectedIndex)
end
end

local function onKeyPress(key)
    if not travelUi then return end
    if key.code == input.KEY.DownArrow then
        if not currentSelectedIndex then
            currentSelectedIndex = 0
        end
        if travelData[ currentSelectedIndex + 1] then
            
        currentSelectedIndex = currentSelectedIndex + 1
        end
        resetBoldOptions(currentSelectedIndex)
    elseif key.code == input.KEY.UpArrow then
        if not currentSelectedIndex then
            currentSelectedIndex = #travelData
        end
        if travelData[ currentSelectedIndex - 1] then
            
        currentSelectedIndex = currentSelectedIndex - 1
        end
        resetBoldOptions(currentSelectedIndex)
    end
end
return {
    interfaceName = "TravelWindow",
    interface = {
        version = 1,
        addCustomDestinationTwoWay = addCustomDestinationTwoWay,
        renderTravelOptions = renderTravelOptions,
        clearWindow = clearWindow,
        findValidDestinations = findValidDestinations,
        hoverNone = hoverNone,
    },
    eventHandlers = {
        activated        = activated,
        startTravel      = startTravel,
        returnTravelData = function(data)
            travelData = data

            renderTravelOptions(lastActivatedActor)
            I.TravelWindow.renderTravelOptions(lastActivatedActor)
        end,
        UiModeChanged    = function(data)
            if data and data.arg and data.arg then
                lastActivatedActor = data.arg
            end

    
            if true == true then

            else
                if not data.newMode and travelUi then
                    --
                    closeWindow(true)
                elseif data.newMode == "Travel" then
                elseif data and data.arg and data.arg then
                    lastActivatedActor = data.arg
                end
            end
        end
    },

    engineHandlers = {
        onActivated = onActivated,
        onInputAction = onInputAction,
        onKeyPress = onKeyPress,
    }
}
