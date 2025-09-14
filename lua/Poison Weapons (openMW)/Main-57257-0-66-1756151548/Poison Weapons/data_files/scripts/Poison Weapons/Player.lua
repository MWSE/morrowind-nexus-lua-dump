local self=require('openmw.self')
local I = require('openmw.interfaces')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local input = require('openmw.input')
local ui = require('openmw.ui')
local async = require('openmw.async')
local util = require('openmw.util')
local core = require('openmw.core')
local storage = require('openmw.storage')
local MWUI= require('openmw.interfaces').MWUI


local ApplypotionState=false
local PoisonedWeapons={}
local PoisonInfos=nil
local PoisonUIrelativePosition=util.vector2(0.1,0.975)

local function CreateShowVariable()

    local CarriedRight=types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedRight)
    local Poison
    if types.Ingredient.records[PoisonedWeapons[CarriedRight.id]] then
        Poison=types.Ingredient.records[PoisonedWeapons[CarriedRight.id]]
    else
        Poison=types.Potion.records[PoisonedWeapons[CarriedRight.id]]
    end     
    local FlexContents=ui.content{}
    local TextRatio=1920/ui.screenSize().x
    local PlayerAlchemy=types.NPC.stats.skills["alchemy"](self).modified
    FlexContents:add({type=ui.TYPE.Text, template = I.MWUI.templates.textNormal, props = { text="",textSize=8*TextRatio}})
    for i, effect in ipairs(Poison.effects) do
        if PlayerAlchemy>=i*15 then
            local Text

            if  types.Potion.records[PoisonedWeapons[CarriedRight.id]] then
                if effect.affectedAttribute then
                    Text=" "..core.magic.effects.records[effect.id].name.." "..effect.affectedAttribute:gsub("^%l", string.upper).." "..effect.magnitudeMax.." pts for "..effect.duration.." secs "
                elseif effect.affectedSkill then
                    Text=" "..core.magic.effects.records[effect.id].name.." "..effect.affectedSkill:gsub("^%l", string.upper).." "..effect.magnitudeMax.." pts for "..effect.duration.." secs "

                else
                    Text=" "..core.magic.effects.records[effect.id].name.." "..effect.magnitudeMax.." pts for "..effect.duration.." secs "
                end
            else
                if effect.affectedAttribute then
                    Text=" "..core.magic.effects.records[effect.id].name.." "..effect.affectedAttribute:gsub("^%l", string.upper).." "
                elseif effect.affectedSkill then
                    Text=" "..core.magic.effects.records[effect.id].name.." "..effect.affectedSkill:gsub("^%l", string.upper).." "
                else
                    Text=" "..core.magic.effects.records[effect.id].name.." "
                end
            end

            FlexContents:add({type=ui.TYPE.Flex, props = { horizontal = true, autoSize=true }, content =ui.content {   
                                                                                                                        {type=ui.TYPE.Text, template = I.MWUI.templates.textNormal, props = { text=" ",textSize=17*TextRatio},},  
                                                                                                                        {type=ui.TYPE.Image, props = { size = util.vector2(ui.screenSize().y/100, ui.screenSize().y/100), resource = ui.texture{path =core.magic.effects.records[effect.id].icon},}},
                                                                                                                        {type=ui.TYPE.Text, template = I.MWUI.templates.textNormal, props = { text=Text,textSize=17*TextRatio},},                                                                                
                                                                                                                    }})                                                                                                              
        else
            FlexContents:add({type=ui.TYPE.Text, template = I.MWUI.templates.textNormal, props = { text="?",textSize=17*TextRatio}})                
        end
        FlexContents:add({type=ui.TYPE.Text, template = I.MWUI.templates.textNormal, props = { text="",textSize=8*TextRatio}})  
    end   

    PoisonInfos=ui.create({type=ui.TYPE.Container,template=MWUI.templates.boxSolid, layer="Settings",props = {  autosize=true,
                                                                                                        relativePosition=PoisonUI.layout.props.relativePosition,
                                                                                                        anchor = util.vector2(0, 1),},
                                                                                            content=ui.content{{type=ui.TYPE.Flex, props = {arrange=ui.ALIGNMENT.Center, relativePosition = util.vector2(0, 0), anchor = util.vector2(0, 0), horizontal = false, autoSize=true },
                                                                                                                content =FlexContents
                                                                                                            }}})        
end


local function HideVariable(data)
    if PoisonInfos and  PoisonUI.layout.props.visible==true then
        PoisonInfos:destroy()
    end
end

local MoveUI=false

local function SelectMoveUI(MouseEvent)
    MoveUI=true
end
local function ReleasetMoveUI(MouseEvent)
--    print("RELEASE")
    MoveUI=false
--    print(MoveUI)
end

PoisonUI=ui.create({type=ui.TYPE.Image,template=MWUI.templates.borders, layer="Windows",props = { visible=false,
                                                                                                        size = util.vector2( tonumber(storage.playerSection('PoisonWeaponscontrols'):get('PoisonUIX')),  tonumber(storage.playerSection('PoisonWeaponscontrols'):get('PoisonUIY'))),
                                                                                                        relativePosition=PoisonUIrelativePosition,
                                                                                                        anchor = util.vector2(0.5, 0.5),
                                                                                                        resource = ui.texture{path ="icons/k/stealth_shortblade.dds"},},
                                                                                content=ui.content({{type = ui.TYPE.Image, props = {relativeSize = util.vector2(0.5,0.5),relativePosition=util.vector2(1, 0),anchor = util.vector2(1, 0),resource = ui.texture{path ="icons/k/magic_alchemy.dds"}}},}),
                                                                                events={focusGain = async:callback(CreateShowVariable),
                                                                                        focusLoss = async:callback(HideVariable),
                                                                                        mousePress = async:callback(SelectMoveUI),
                                                                                        mouseRelease = async:callback(ReleasetMoveUI)} })


local function onUpdate(dt)
    if MoveUI==true then
        PoisonUIrelativePosition=PoisonUI.layout.props.relativePosition+util.vector2(input.getMouseMoveX()/ui.screenSize().x,input.getMouseMoveY()/ui.screenSize().y)
        PoisonUI.layout.props.relativePosition=PoisonUIrelativePosition
        PoisonUI:update()
        PoisonInfos.layout.props.relativePosition=PoisonUI.layout.props.relativePosition
        PoisonInfos:update()
    end

    if input.getBooleanActionValue('ApplyPoison')==true and ApplypotionState==false then
        core.sendGlobalEvent("APtWApplyPoisonKey",{Actor=self, Bolean=true})
        ApplypotionState=true
    elseif input.getBooleanActionValue('ApplyPoison')==false and ApplypotionState==true then
        core.sendGlobalEvent("APtWApplyPoisonKey",{Actor=self, Bolean=false})
        ApplypotionState=false
    end

    if  I.UI.isHudVisible()==true and  PoisonUI.layout.props.visible==false then
        if types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedRight) and PoisonedWeapons[types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedRight).id]  then
            PoisonUI.layout.props.visible=true
            PoisonUI.layout.props.size = util.vector2( tonumber(storage.playerSection('PoisonWeaponscontrols'):get('PoisonUIX')),  tonumber(storage.playerSection('PoisonWeaponscontrols'):get('PoisonUIY')))
            PoisonUI:update()
        end
    elseif  PoisonUI.layout.props.visible==true then
        if  types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedRight)==nil or 
        (types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedRight) and PoisonedWeapons[types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedRight).id]==nil)  then
            PoisonUI.layout.props.visible=false
            PoisonUI:update()
        end
    end

    if I.UI.isHudVisible()==false and PoisonUI.layout.props.visible==true then
        PoisonUI.layout.props.visible=false
        PoisonUIrelativePosition=util.vector2(0.1,0.975)
        PoisonUI.layout.props.relativePosition=PoisonUIrelativePosition
        PoisonUI:update()
        if PoisonInfos then
            PoisonInfos:destroy()
        end
    end
end



local function ShowMessage(data)
    ui.showMessage(data.text)
end

local function DeclarePoisonedWeapons(data)
    PoisonedWeapons={}
    PoisonedWeapons=data.List
end



local function onSave()
    return{SavedPoisonUIPosition=PoisonUIrelativePosition}
end


local function onLoad(data)
    if data and data.SavedPoisonUIPosition then
        PoisonUIrelativePosition=data.SavedPoisonUIPosition
        PoisonUI.layout.props.relativePosition=PoisonUIrelativePosition
        PoisonUI:update()
    end
end



return {
	eventHandlers = {
                        APtWShowMessage=ShowMessage,
                        APtWDeclarePoisonedWeapons=DeclarePoisonedWeapons,

					},
	engineHandlers = {
                        onUpdate=onUpdate,
                        onSave=onSave,
                        onLoad=onLoad,

	}

}

