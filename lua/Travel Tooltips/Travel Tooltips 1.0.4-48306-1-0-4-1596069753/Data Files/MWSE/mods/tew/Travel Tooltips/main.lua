-- Travel Tooltips (by tewlwolow)) --
--- v 1.0.4 ---

event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\mods\\tew\\Travel Tooltips\\mcm.lua")
end)

local data=require("tew\\Travel Tooltips\\data")
local config=require("tew\\Travel Tooltips\\config")
local descriptionTable=data.descriptionTable
local headers=data.headers
local gondoliersTable=data.gondoliersTable

local version="1.0.4"
local mapColour=nil
local mapColours={
    ["Indoril"] = {1.0, 1.0, 1.0},
    ["Velothi"] = {0.9, 0.8, 0.5},
    ["Redoran"] = {0.5, 0.0, 0.0},
    ["Telvanni"] = {0.0, 0.7, 0.7},
    ["Dres"] = {0.3, 0.2, 0.5,},
    ["Hlaalu"] = {0.5, 0.3, 0.0},
    ["Argonian"] = {0.0, 0.3, 0.1},
    ["Cyrodiil"] = {0.4, 0.1, 0.2},
    ["Khajiit"] = {1.0, 0.9, 0.7},
    ["Ayleid"] = {0.0, 0.3, 0.8},
    ["Reman"] = {1.0, 0.4, 0.7}
}
local function getColour()
    for k, v in pairs(mapColours) do
        if k==config.mapColour then
            mapColour=v
        end
    end
end

local function createTooltip(e)

    local npc=tes3ui.getServiceActor(e).object
    if string.startswith(npc.id, "TR_") or
    string.startswith(npc.id, "PC_") or
    string.startswith(npc.id, "Sky_") then
        return
    end

    if npc.class.id == "Gondolier" and not config.showGondola then
        return
    end

    local size=config.size
    local scale=config.scale/100
    local element=e.element
    local destinationList={}

    element=element:findChild(-1155)
    for _, vF in pairs(element.children) do
        if vF.name=="null" then
            for _, vS in pairs(vF.children) do
                if string.find(vS.text, "gp") then
                    table.insert(destinationList, vS)
                end
            end
        end
    end

    local function updateTooltip()
        for _, trDestination in pairs(destinationList) do
            trDestination:register("help", function()

                local description, headerPath="", ""
                local trDestinationText=string.sub(trDestination.text, 1, -7)

                if npc.class.id == "Gondolier" and config.showGondola then
                    for kDest, vDescr in pairs(gondoliersTable) do
                        if string.find(trDestinationText, kDest) then
                            description=vDescr
                        end
                    end
                else
                    for kDest, vDescr in pairs(descriptionTable) do
                        if string.find(trDestinationText, kDest) then
                            description=vDescr
                        end
                    end
                end

                local tooltip = tes3ui.createTooltipMenu()

                local destBlock = tooltip:createBlock{id=tes3ui.registerID("twl_Travel_Tooltip")}

                if size=="Wide" then
                    destBlock.flowDirection = "top_to_bottom"
                    destBlock.width = 900*scale
                    destBlock.autoHeight = true
                    destBlock.maxHeight = 700*scale
                    destBlock.paddingAllSides = 5*scale
                    destBlock.paddingBottom = 8*scale

                    local destLabel=destBlock:createLabel{id=tes3ui.registerID("twl_Travel_Tooltip"),
                    text=trDestinationText}
                    destLabel.justifyText="center"
                    destLabel.wrapText = true
                    destLabel.font=config.fontLabel
                    destLabel.borderBottom=3*scale

                    for kHead, vHead in pairs(headers) do
                        if string.find(trDestinationText, kHead) then
                            headerPath=vHead
                        end
                    end

                    local destHeader=destBlock:createImage{path=headerPath}
                    getColour()
                    destHeader.color=mapColour
                    destHeader.autoHeight=true
                    destHeader.autoWidth=true
                    destHeader.borderBottom = 2*scale
                    destHeader.borderTop = 2*scale
                    destHeader.justifyText="center"
                    if headerPath=="\\Textures\\Travel Tooltips\\Sheogorad_regionmap.tga" then
                        destHeader.imageScaleX=1*scale
                        destHeader.imageScaleY=1*scale
                    else
                        destHeader.imageScaleX=0.77*scale
                        destHeader.imageScaleY=0.77*scale
                    end

                    local destDescr=destBlock:createLabel{id=tes3ui.registerID("twl_Travel_Tooltip"),
                    text=description}
                    destDescr.font=config.fontText
                    destDescr.wrapText = true
                    destDescr.justifyText="center"
                    destDescr.autoWidth = true
                    destDescr.autoHeight = true

                elseif size =="Slim" then
                    destBlock.flowDirection = "top_to_bottom"
                    destBlock.width = 500*scale
                    destBlock.autoHeight = true
                    destBlock.paddingAllSides = 5*scale
                    destBlock.paddingBottom = 8*scale

                    local destLabel=destBlock:createLabel{id=tes3ui.registerID("twl_Travel_Tooltip"),
                    text=trDestinationText}
                    destLabel.justifyText="center"
                    destLabel.wrapText = true
                    destLabel.font=config.fontLabel
                    destLabel.borderBottom=3*scale

                    for kHead, vHead in pairs(headers) do
                        if string.find(trDestinationText, kHead) then
                            headerPath=vHead
                        end
                    end

                    local destHeader=destBlock:createImage{path=headerPath}
                    getColour()
                    destHeader.color=mapColour
                    destHeader.autoHeight=true
                    destHeader.autoWidth=true
                    destHeader.borderBottom = 2*scale
                    destHeader.borderTop = 2*scale
                    destHeader.justifyText="center"
                    if headerPath=="\\Textures\\Travel Tooltips\\Sheogorad_regionmap.tga" then
                        destHeader.imageScaleX=1*scale
                        destHeader.imageScaleY=1*scale
                    else
                        destHeader.imageScaleX=0.77*scale
                        destHeader.imageScaleY=0.77*scale
                    end

                    local destDescr=destBlock:createLabel{id=tes3ui.registerID("twl_Travel_Tooltip"),
                    text=description}
                    destDescr.font=config.fontText
                    destDescr.wrapText = true
                    destDescr.justifyText="left"
                    destDescr.autoWidth = true
                    destDescr.autoHeight = true
                end
            end)
        end
    end
    updateTooltip()
end

local function createTravelMap(e)

    local npc=tes3ui.getServiceActor().reference.object
    if string.startswith(npc.id, "TR_") or
    string.startswith(npc.id, "PC_") or
    string.startswith(npc.id, "Sky_") then
        return
    end

    if config.showMainMap==false then
        return
    end

    local scale=config.scale/100
    local element=e.element
    local travelButton=element:findChild(tes3ui.registerID("MenuDialog_service_travel"))

    travelButton:register("help", function()

    local tooltip = tes3ui.createTooltipMenu()
    local travelBlock = tooltip:createBlock{id=tes3ui.registerID("twl_Routes_Travel_Tooltip")}
    travelBlock.flowDirection = "top_to_bottom"
    travelBlock.height=520*scale
    travelBlock.width=520*scale
    travelBlock.paddingAllSides = 4*scale
    local travelMapImage = travelBlock:createImage{path=config.mainMap}
    getColour()
    travelMapImage.justifyText="center"
    travelMapImage.color=mapColour
    travelMapImage.autoHeight=true
    travelMapImage.autoWidth=true
    travelMapImage.imageScaleX=1.0*scale
    travelMapImage.imageScaleY=1.0*scale
    end)

end

local function init()
    event.register("uiActivated", createTravelMap, {filter="MenuDialog"})
    event.register("uiActivated", createTooltip, {filter="MenuServiceTravel"})
    mwse.log("[Travel Tooltips] Version "..version.." initialised.")
end

event.register("initialized", init)