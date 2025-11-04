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
local ambient = require('openmw.ambient')
local anim = require('openmw.animation')
local camera = require('openmw.camera')
local time=require('openmw_aux.time')
local auxUi = require('openmw_aux.ui')


local NameColors={util.color.rgb(0.74, 0.11, 0.11),util.color.rgb(0.08, 0.71, 0.02),util.color.rgb(1, 1, 0.2),util.color.rgb(0.09, 0.38, 0.54)}

local Players={}
local NbrPlayers
local LastCellId
local UiRatio={x=1920/ui.screenSize().x, y=1440/ui.screenSize().y, text=1440/ui.screenSize().y}
local Fading=ui.create({type=ui.TYPE.Image, layer="Windows", props={alpha=0.1, alphaDelta=0.01, visible=false, color=util.color.rgb(0, 0, 0), relativeSize=util.vector2(1,1), anchor=util.vector2(0.5,0.5), relativePosition=util.vector2(0.5,0.5), resource=ui.texture{ path="textures/green.tga"}}})

local LastWeapon={}

local Inventories={}
local LastMerchant
local Barter={}
local Menus={"Weapons","Armors","Potions","Statistics","Spells"}
local InventoryToUpdate={}

local CharacterSelection={}
CharacterSelection.Avatars={}

local AvatarsStats={}

local Toggles={}
for i=1,4 do
    Toggles[i]={Up=false,Down=false}
end



local CoVSpell={}
for i, spell in pairs(core.magic.spells.records) do
    local Name=string.lower(spell.name)
    if string.find(spell.id,Name.."_") then
        if CoVSpell[Name]==nil then
            CoVSpell[Name]={}
        end
        local numberString=string.gsub(spell.id,Name.."_","")
        local number=tonumber(numberString)
        if number then
            table.insert(CoVSpell[Name],number,spell)
        end
    end
end
for i, spellCategorie in pairs(CoVSpell) do
    local CoV=false
    for j, spell in pairs(spellCategorie) do
        if spell.id==string.lower(spell.name).."_0" then
            CoV=true
            break
        end
    end
    if CoV==false then
        CoVSpell[i]=nil
    end
end

local Camera={Distance=800, Angle=0}
input.registerTriggerHandler("RAZCamera", async:callback(function () 
                                                            Camera.Distance=800
                                                            Camera.Angle=0
                                                        end))

local Templates={}

Templates.Equipped=auxUi.deepLayoutCopy(I.MWUI.templates.boxTransparentThick)
for i, content in pairs(Templates.Equipped.content) do
    if content and content.template then
        if not(content.template.props.alpha) then
            content.template.props["alpha"]=0
        else
            content.template.props.resource=ui.texture{ path="textures/green.tga"}
            content.template.props.alpha=0.2
            content.template.props.color=util.color.rgb(1,1,1)
        end
    end
end
Templates.EquippedSelected=auxUi.deepLayoutCopy(I.MWUI.templates.boxTransparentThick)
for i, content in pairs(Templates.EquippedSelected.content) do
    if content and content.template then
        if content.template.props.alpha then
            content.template.props.resource=ui.texture{ path="textures/green.tga"}
            content.template.props.alpha=0.2
            content.template.props.color=util.color.rgb(1,1,1)
        end
    end
end
Templates.NotEquipped=auxUi.deepLayoutCopy(I.MWUI.templates.boxTransparentThick)
for i, content in pairs(Templates.NotEquipped.content) do
    if content and content.template then
        if not(content.template.props.alpha) then
            content.template.props["alpha"]=0
        end
    end
end
Templates.NotEquippedSelected=I.MWUI.templates.boxSolidThick


camera.setMode(camera.MODE.Static)
--camera.setStaticPosition(self.position)
--camera.setStaticPosition(util.vector3(10000,5000,200))
I.Controls.overrideMovementControls(true)
I.Controls.overrideCombatControls(true)
I.Controls.overrideUiControls(true)
types.Actor.activeEffects(self):set(1000,"Chameleon")
types.Actor.activeEffects(self):set(1000,"Invisibility")
types.Actor.activeEffects(self):set(1000,"Levitate")
types.Actor.activeEffects(self):set(1000,"Sanctuary")
types.Actor.activeEffects(self):set(1000,"WaterBreathing")
types.Actor.activeEffects(self):set(1000,"Invisibility")
core.sendGlobalEvent("StartCoV")

I.UI.registerWindow("Inventory", function() I.UI.removeMode("Container") end, function() return true end)
I.UI.registerWindow("Container", function() I.UI.removeMode("Container") end, function() return true end)

local function CameraPosition()
    local Position=util.vector3(0,0,0)
    local players=0
    for i, player in pairs(Players) do
        if player.type.isDead(player)==false then
            Position=Position+player.position
            players=players+1
        end
    end 
    camera.setPitch(6*math.pi/16)
    camera.setStaticPosition(Position/players+util.vector3(math.sin(Camera.Angle)*math.cos(6*math.pi/16),math.cos(Camera.Angle)*math.cos(6*math.pi/16),-1)*-Camera.Distance)
    camera.setYaw(Camera.Angle)
end

local function MenuRaceControls(nbr)
    local Ray=nearby.castRay(camera.getPosition(),camera.getPosition()+util.vector3(0,-200,0),{ignore=self})
    if Ray.hitObject and Ray.hitObject  and not(CharacterSelection.Choice.Sex) then
        local ActorRecor=types.NPC.records[Ray.hitObject.recordId]
        CharacterSelection.Choice.Description.layout.content[1].content[1].props.text=types.NPC.classes.records[ActorRecor.class].name..": \n"..types.NPC.classes.records[ActorRecor.class].description
        CharacterSelection.Choice.Description:update()
    end
    if input.getBooleanActionValue('P'..nbr..'MoveRight') then
        if CharacterSelection.Choice.Sex then
            if types.NPC.records[Ray.hitObject.recordId].isMale==true then
                core.sendGlobalEvent("CoVAvatarChoiceSex",{isMale=false, Choice=CharacterSelection.Choice.Target})
                ambient.playSoundFile("sound/fx/menu click.wav")
            end
        elseif CharacterSelection.Choice then
            if CharacterSelection.Activators[CharacterSelection.Choice.Target-1] and Ray.hitObject and types.NPC.records[Ray.hitObject.recordId].race==types.NPC.records["PlayerChoice"..CharacterSelection.Choice.Target].race then
                CharacterSelection.Choice.Target=CharacterSelection.Choice.Target-1
                ambient.playSoundFile("sound/fx/menu click.wav")
            end
        end 
    elseif input.getBooleanActionValue('P'..nbr..'MoveLeft') then
        if CharacterSelection.Choice.Sex then
            if types.NPC.records[Ray.hitObject.recordId].isMale==false then
                core.sendGlobalEvent("CoVAvatarChoiceSex",{isMale=true, Choice=CharacterSelection.Choice.Target})
                ambient.playSoundFile("sound/fx/menu click.wav")
            end
        elseif CharacterSelection.Choice then
            if CharacterSelection.Activators[CharacterSelection.Choice.Target+1] and Ray.hitObject and types.NPC.records[Ray.hitObject.recordId].race==types.NPC.records["PlayerChoice"..CharacterSelection.Choice.Target].race then
                CharacterSelection.Choice.Target=CharacterSelection.Choice.Target+1
                ambient.playSoundFile("sound/fx/menu click.wav")
            end
        end
    end
end

local function XpRatio(Exp,Level)
    local Ratio=(Exp-((Level-1)*50))/(Level*50)
    return(Ratio)
end


local PlayersUI={}
local AvatarsInterraction={}
local function CreatePlayersUI()
    local BarSizes=util.vector2(150*UiRatio.x,15*UiRatio.y)
    for i, player in pairs(Players) do
        local Gold=0
        if types.Actor.inventory(player):find("gold_001") then
            Gold=types.Actor.inventory(player):find("gold_001").count
        end
        PlayersUI[i]=ui.create({type=ui.TYPE.Flex, layer="HUD", props={arrange=ui.ALIGNMENT.Center, relativePosition=util.vector2(i*1/(NbrPlayers+1),0.15), anchor=util.vector2(0.5,0.5), autoSize=true}, 
                                content=ui.content{ {name="Gold",type=ui.TYPE.Text,template=I.MWUI.templates.textHeader, props={alpha=1, visible=false, textShadow=true, text=tostring(Gold), targetValue=0}},
                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="                                                      "}},
                                                    {name="AvatarName",type=ui.TYPE.Text, props={alpha=1, textSize=30*UiRatio.text, textShadow=true, textColor=NameColors[i], text=types.NPC.records[Players[i].recordId].name}},
                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=""}},
                                                    {name="Health", type=ui.TYPE.Container, template=I.MWUI.templates.boxSolidThick, content=ui.content{{name="Base", type=ui.TYPE.Image, props={size=BarSizes, visible=false, resource=ui.texture{ path="textures/red.tga"} }},
                                                                                                                                                        {name="Current",type=ui.TYPE.Image, props={size=util.vector2(BarSizes.x*types.Actor.stats.dynamic.health(player).current/types.Actor.stats.dynamic.health(player).base,BarSizes.y), resource=ui.texture{ path="textures/red.tga"} }},
                                                                                                                                                            }},

                                                    --{type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=""}},
                                                    {name="Exp", type=ui.TYPE.Container, template=I.MWUI.templates.boxSolidThick, content=ui.content{{name="Base", type=ui.TYPE.Image, props={size=util.vector2(BarSizes.x,BarSizes.y/2), visible=false, resource=ui.texture{ path="textures/green.tga"} }},
                                                                                                                                                        {name="Current",type=ui.TYPE.Image, props={size=util.vector2(XpRatio(AvatarsStats[player.recordId].Exp,types.Actor.stats.level(player).current),BarSizes.y/4), resource=ui.texture{ path="textures/green.tga"} }},
                                                                                                                                                            }},
                                                    --{type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=""}},
                                                    {name="Magicka", type=ui.TYPE.Container, template=I.MWUI.templates.boxSolidThick, content=ui.content{{name="Base", type=ui.TYPE.Image, props={size=BarSizes, visible=false, resource=ui.texture{ path="textures/blue.tga"} }},
                                                                                                                                                        {name="Current",type=ui.TYPE.Image, props={size=util.vector2(BarSizes.x*types.Actor.stats.dynamic.magicka(player).current/types.Actor.stats.dynamic.magicka(player).base,BarSizes.y), resource=ui.texture{ path="textures/blue.tga"} }},
                                                                                                                                                            }},

                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=""}},
                                                    {name="SwitchSpell", type=ui.TYPE.Image, props={visible=true, size=util.vector2(300,200), anchor=util.vector2(0.5,0.5),alpha=0, tempo=0, resource=ui.texture{ path="textures/alpha.dds"} },
                                                        content=ui.content{ {name="Icons", type=ui.TYPE.Flex, props={relativePosition=util.vector2(0.5,0), arrange=ui.ALIGNMENT.Center, align=ui.ALIGNMENT.Center, anchor=util.vector2(0.5,0), horizontal=true},
                                                                                content=ui.content{ {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="  "}},
                                                                                                    {name="Previous", type=ui.TYPE.Image, props={size=util.vector2(40*UiRatio.x,40*UiRatio.y), resource=ui.texture{ path="textures/green.tga"} }},                                                                                      
                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="  "}},
                                                                                                    {name="Current", type=ui.TYPE.Image, props={size=util.vector2(40*UiRatio.x,40*UiRatio.y), resource=ui.texture{ path="textures/green.tga"} }},                                                                                      
                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="  "}},
                                                                                                    {name="Next", type=ui.TYPE.Image, props={size=util.vector2(40*UiRatio.x,40*UiRatio.y), resource=ui.texture{ path="textures/green.tga"} }}}},
                                                                                                                                                                                                    
                                                                            {name="Text", type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={autoSize=true, textAlignH=ui.ALIGNMENT.Center, multiline=true, text="Spell description", anchor=util.vector2(0.5,0), relativePosition=util.vector2(0.5,0.2)}},
                                                                            {type=ui.TYPE.Container, template=I.MWUI.templates.bordersThick, props={relativePosition=util.vector2(0.52,0.02), anchor=util.vector2(0.5,0), },
                                                                                content=ui.content{{type=ui.TYPE.Widget, props={visible=false, size=util.vector2(47*UiRatio.x,47*UiRatio.y), resource=ui.texture{ path="textures/green.tga"} }}}},
                                                                                                                                                                                            
                                                                                                                                                                                            
                                                                    }}}
                                })
        AvatarsInterraction[i]=ui.create({type=ui.TYPE.Container, template=I.MWUI.templates.boxTransparentThick, layer="HUD", props={visible=false, arrange=ui.ALIGNMENT.Center, relativePosition=util.vector2(i*1/(NbrPlayers+1),0.9), anchor=util.vector2(0.5,0.5), autoSize=true}, 
                                content=ui.content{{type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=""}}}})
    end
end

local CoinsUI={}
local function TakeCoins(data)
    local ViewPort=util.vector2(camera.worldToViewportVector(data.Player.position).x/ui.screenSize().x,camera.worldToViewportVector(data.Player.position).y/ui.screenSize().y)
    local PlayerNbr
    for i, player in pairs (Players) do
        if player.id==data.Player.id then
            PlayerNbr=i 
        end
    end
    table.insert(CoinsUI,ui.create({type=ui.TYPE.Text, layer="HUD", template=I.MWUI.templates.textHeader, props={text=tostring(data.Value), relativePosition=ViewPort, Player=data.Object, UITarget=PlayerNbr}}) )
end

local DamagesUI={}
local function ShowDamage(data)
    if storage.playerSection('CoVGeneralSettings'):get('ShowDamages')==true then
        local ViewPort=camera.worldToViewportVector(data.Object.position)
        table.insert(DamagesUI,ui.create({type=ui.TYPE.Text, layer="HUD", template=I.MWUI.templates.textHeader, props={alpha=1, text=tostring(-data.Value),position=util.vector2(ViewPort.x,ViewPort.y), Actor=data.Object, deltaY=0}}))
    end
end




local function CreateInventoryUIItem(item,Avatar,nbr)
    local minDamage
    local maxDamage
    local StringHeader
    StringHeader=" "..item.type.records[item.recordId].name.." x"..item.count
    StringHeader=StringHeader..string.rep(" ",40-string.len(StringHeader))
    local StringDamage=""
    local DamageIcon=ui.texture{path="textures/alpha.dds"}
    local ContainerTemplate=Templates.NotEquipped
    local Equipped=false

    for i, equipment in pairs(types.Actor.getEquipment(Avatar)) do
        if equipment==item then
 --           print("Equipped ", item)
            ContainerTemplate=Templates.Equipped
 --           print(ContainerTemplate[2].props.visible)
            Equipped=true
        end
    end
    if item==LastWeapon[Avatar.recordId] then
        ContainerTemplate=Templates.Equipped
        Equipped=true
    end


    if item.type==types.Weapon then
        minDamage=types.Weapon.records[item.recordId].chopMinDamage
        if types.Weapon.records[item.recordId].slashMinDamage<minDamage then
            minDamage=types.Weapon.records[item.recordId].slashMinDamage
        end
        if types.Weapon.records[item.recordId].thrustMinDamage<minDamage then
            minDamage=types.Weapon.records[item.recordId].thrustMinDamage
        end
        maxDamage=types.Weapon.records[item.recordId].chopMaxDamage
        if types.Weapon.records[item.recordId].slashMaxDamage>maxDamage then
            maxDamage=types.Weapon.records[item.recordId].slashMaxDamage
        end
        if types.Weapon.records[item.recordId].thrustMaxDamage>maxDamage then
            maxDamage=types.Weapon.records[item.recordId].thrustMaxDamage
        end


        StringDamage=" "..minDamage.." - "..maxDamage

        DamageIcon=ui.texture{path="icons/cov/attribute_strength.dds"}
    elseif item.type==types.Armor then
        StringDamage=" "..types.Armor.records[item.recordId].baseArmor
        DamageIcon=ui.texture{path="icons/cov/combat_mediumarmor.dds"}
    end
    StringDamage=StringDamage..string.rep(" ",10-string.len(StringDamage))

        
    local Icon
    if item.type.records[item.recordId].enchant and (core.magic.enchantments.records[item.type.records[item.recordId].enchant].type==core.magic.ENCHANTMENT_TYPE.CastOnStrike or core.magic.enchantments.records[item.type.records[item.recordId].enchant].type==core.magic.ENCHANTMENT_TYPE.ConstantEffect) then
        Icon={type=ui.TYPE.Image, props={size=util.vector2(80*UiRatio.x,80*UiRatio.y), anchor=util.vector2(0,0), resource=ui.texture{path="textures/menu_icon_magic_mini.dds"}},content=ui.content{{type=ui.TYPE.Image, props={relativeSize=util.vector2(1,1), relativePosition=util.vector2(0.5,0.5), anchor=util.vector2(0.5,0.5), resource=ui.texture{path=item.type.records[item.recordId].icon}}}}}
    else
        Icon={type=ui.TYPE.Image, props={size=util.vector2(80*UiRatio.x,80*UiRatio.y), anchor=util.vector2(0,0), resource=ui.texture{path=item.type.records[item.recordId].icon}}}
    end

    local content={name=tostring(nbr), type=ui.TYPE.Container, template=ContainerTemplate, props={item=item,Equipped=Equipped, autoSize=false}, content=ui.content{ {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}},
                                                                                                                                                                    {type=ui.TYPE.Image, props={size=util.vector2(350*UiRatio.x,160*UiRatio.y), anchor=util.vector2(0,0),resource=ui.texture{ path="textures/alpha.dds"} }, content=ui.content{  {type=ui.TYPE.Flex, content=ui.content{{type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}},
                                                                                                                                                                                                                                                                                                                                                                                        {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=StringHeader}},
                                                                                                                                                                                                                                                                                                                                                                                        {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}},
                                                                                                                                                                                                                                                                                                                                                                                        {type=ui.TYPE.Flex, props={horizontal=true}, content=ui.content{{type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}},
                                                                                                                                                                                                                                                                                                                                                                                                                                                        {type=ui.TYPE.Flex, content=ui.content{ {type=ui.TYPE.Flex,props={horizontal=true, arrange=ui.ALIGNMENT.Center},  content=ui.content{   {type=ui.TYPE.Image, props={size=util.vector2(40*UiRatio.x,40*UiRatio.y), anchor=util.vector2(0.5,0.5), resource=DamageIcon}},
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=StringDamage}}}},
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}},
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                {type=ui.TYPE.Flex,props={horizontal=true, arrange=ui.ALIGNMENT.Center},  content=ui.content{   {type=ui.TYPE.Image, props={size=util.vector2(40*UiRatio.x,40*UiRatio.y), anchor=util.vector2(0.5,0.5), resource=ui.texture{path="icons/tx_goldicon.dds"}}},
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "..item.type.records[item.recordId].value}}}}}},
                                                                                                                                                                                                                                                                                                                                                                                                                                                        {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}},
                                                                                                                                                                                                                                                                                                                                                                                                                                                        {type=ui.TYPE.Flex, content=ui.content{ {type=ui.TYPE.Flex,props={horizontal=true, arrange=ui.ALIGNMENT.Center},  content=ui.content{   {type=ui.TYPE.Image, props={size=util.vector2(40*UiRatio.x,40*UiRatio.y), anchor=util.vector2(0.5,0.5), resource=ui.texture{path="textures/alpha.dds"}}},
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}}}},
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}},
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                {type=ui.TYPE.Flex,props={horizontal=true, arrange=ui.ALIGNMENT.Center},  content=ui.content{   {type=ui.TYPE.Image, props={size=util.vector2(40*UiRatio.x,40*UiRatio.y), anchor=util.vector2(0.5,0.5), resource=ui.texture{path="icons/weight.dds"}}},
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "..math.floor(item.type.records[item.recordId].weight*item.count)}}}}}},
                                                                                                                                                                                                                                                                                                                                                                                                                                                        {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="  "}},
                                                                                                                                                                                                                                                                                                                                                                                                                                                        
                                                                                                                                                                                                                                                                                                                                                                                                                                                        Icon,
                                                                                                                                                                                                                                                                                                                                                                                                                                                        {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}}}},
                                                                                                                                                                                                                                                                                                                                                                                        {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}}}}}},
                                                                                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}}}}




    return (content)
end

local function AdditionalDatasText(Layout)
    local ItemNbr=tostring(Layout.layout.content[1].content["Menus"].props.SelectionNbr)
    local Menu=Layout.layout.content[1].content["Menus"].props.Menu
    local Item
    if Layout.layout.content[1].content["Menus"].content[Menu].content:indexOf(ItemNbr) then
        Item=Layout.layout.content[1].content["Menus"].content[Menu].content[ItemNbr].props.item
    end
    if Layout.layout.content[1].content["Menus"].props.Menu=="Spells" then
        Layout.layout.content["AdditionalDatas"].props.visible=true
        if Layout.layout.content[1].content["Menus"].content["Spells"].content[tostring(Layout.layout.content[1].content["Menus"].props.SelectionNbr)].props.NextSpell then
            local Spell=Layout.layout.content[1].content["Menus"].content["Spells"].content[tostring(Layout.layout.content[1].content["Menus"].props.SelectionNbr)].props.NextSpell
            local Text="Cost : "..string.gsub(Spell.id,string.lower(Spell.name).."_","").."\n"
            if Spell.type==core.magic.SPELL_TYPE.Spell then
                Text=Text.."Spell\n" 
            elseif  Spell.type==core.magic.SPELL_TYPE.Ability then
                Text=Text.."Ability\n" 
            end
            for i, effect in pairs(Spell.effects) do
                local MagnitudeText=effect.magnitudeMax
                if effect.magnitudeMax~=effect.magnitudeMin then
                MagnitudeText=effect.magnitudeMin.."-"..effect.magnitudeMax
                end
                local DescriptionText=effect.effect.name
                if effect.affectedAttribute then
                    DescriptionText=effect.effect.name.." "..effect.affectedAttribute
                elseif effect.affectedSkill then
                    DescriptionText=effect.effect.name.." "..effect.affectedSkill
                end
                local RangeText 
                local Range={"self","touch","target"}
                RangeText=Range[effect.range+1]

                local AreaText=""
                if effect.area>1 then
                    AreaText=" on "..effect.area.." area"
                end
                Text=Text.."\n"..DescriptionText.." "..MagnitudeText.."\n for "..effect.duration.." secs on "..RangeText..AreaText
            end
            Layout.layout.content["AdditionalDatas"].content[1].props.text=Text
        else
            Layout.layout.content["AdditionalDatas"].content[1].props.text="Maxed"
        end
        Layout:update()
    elseif Item and Item.type.records[Item.recordId].enchant then
        Layout.layout.content["AdditionalDatas"].props.visible=true
        local Enchant=core.magic.enchantments.records[Item.type.records[Item.recordId].enchant]
        local Text=""
        
        if Enchant.type==core.magic.ENCHANTMENT_TYPE.CastOnStrike then
            Text=Text.."On strike\n" 
        elseif  Enchant.type==core.magic.ENCHANTMENT_TYPE.ConstantEffect then
            Text=Text.."Constant effect\n" 
        end
        for i, effect in pairs(Enchant.effects) do
            local MagnitudeText=effect.magnitudeMax
            if effect.magnitudeMax~=effect.magnitudeMin then
            MagnitudeText=effect.magnitudeMin.."-"..effect.magnitudeMax
            end
            local DescriptionText=effect.effect.name
            if effect.affectedAttribute then
                DescriptionText=effect.effect.name.." "..effect.affectedAttribute
            elseif effect.affectedSkill then
                DescriptionText=effect.effect.name.." "..effect.affectedSkill
            end
            local RangeText 
            local Range={"self","touch","target"}
            RangeText=Range[effect.range+1]

            local AreaText=""
            if effect.area>1 then
                AreaText=" on "..effect.area.." area"
            end
            Text=Text.."\n"..DescriptionText.." "..MagnitudeText.."\n for "..effect.duration.." secs on "..RangeText..AreaText
        end
        Layout.layout.content["AdditionalDatas"].content[1].props.text=Text
    elseif Menu=="Statistics" then
        Layout.layout.content["AdditionalDatas"].content[1].props.text=Layout.layout.content[1].content["Menus"].content[Menu].content[ItemNbr].props.Description
        

    else
        
        Layout.layout.content["AdditionalDatas"].props.visible=false
    end
end


local function updateInventoryUI(Inventory,Avatar,Actor)
--    print("InventoryUPDATE")
    Inventory.layout.content[1].content["Menus"].content["Weapons"].content=ui.content{}
    Inventory.layout.content[1].content["Menus"].content["Armors"].content=ui.content{}
    Inventory.layout.content[1].content["Menus"].content["Potions"].content=ui.content{}
    Inventory.layout.content[1].content[1].content["Header"].content["Encumbrance"].props.text=" : "..math.floor(types.Actor.getEncumbrance(Avatar)).."/"..types.Actor.getCapacity(Avatar)
    Inventory.layout.content[1].content[1].content["Header"].content["Gold"].props.text=" : "..types.Actor.inventory(Avatar):countOf("gold_001")

    for i, weapon in pairs(types.Actor.inventory(Actor):getAll(types.Weapon)) do
        Inventory.layout.content[1].content["Menus"].content["Weapons"].content:add(CreateInventoryUIItem(weapon,Actor,i))
        Inventory.layout.content[1].content["Menus"].content["Weapons"].content:add({type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}})
        if Inventory.layout.content[1].content["Menus"].content["Weapons"].content[tostring(i)].props.Equipped then
            Inventory.layout.content[1].content["Menus"].content["Weapons"].content[tostring(i)].template=Templates.Equipped
        else
            Inventory.layout.content[1].content["Menus"].content["Weapons"].content[tostring(i)].template=Templates.NotEquipped
        end
    end
    for i, armor in pairs(types.Actor.inventory(Actor):getAll(types.Armor)) do
        Inventory.layout.content[1].content["Menus"].content["Armors"].content:add(CreateInventoryUIItem(armor,Actor,i))
        Inventory.layout.content[1].content["Menus"].content["Armors"].content:add({type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}})
        if Inventory.layout.content[1].content["Menus"].content["Armors"].content[tostring(i)].props.Equipped then
            Inventory.layout.content[1].content["Menus"].content["Armors"].content[tostring(i)].template=Templates.Equipped
        else
            Inventory.layout.content[1].content["Menus"].content["Armors"].content[tostring(i)].template=Templates.NotEquipped
        end
    end

    local PotionsList={}
    for i , potion in pairs(types.Actor.inventory(Actor):getAll(types.Potion)) do
        table.insert(PotionsList,potion)
    end
    for i, clothing in pairs(types.Actor.inventory(Actor):getAll(types.Clothing)) do
        if types.Clothing.records[clothing.recordId].type==types.Clothing.TYPE.Ring or types.Clothing.records[clothing.recordId].type==types.Clothing.TYPE.Amulet then
            table.insert(PotionsList,clothing)
        end
    end

    for i, item in pairs(PotionsList) do
        Inventory.layout.content[1].content["Menus"].content["Potions"].content:add(CreateInventoryUIItem(item,Actor,i))
        Inventory.layout.content[1].content["Menus"].content["Potions"].content:add({type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}})
        if Inventory.layout.content[1].content["Menus"].content["Potions"].content[tostring(i)].props.Equipped then
            Inventory.layout.content[1].content["Menus"].content["Potions"].content[tostring(i)].template=Templates.Equipped
        else
            Inventory.layout.content[1].content["Menus"].content["Potions"].content[tostring(i)].template=Templates.NotEquipped
        end
    end

    local Armor=0
    for i, equipment in pairs(types.Actor.getEquipment(Avatar)) do
        if equipment.type.records[equipment.recordId].baseArmor then
            Armor=Armor+equipment.type.records[equipment.recordId].baseArmor
        end
    end
    Inventory.layout.content[1].content["Menus"].content["Statistics"].content["Level"].props.text="Level "..tostring(types.Actor.stats.level(Avatar).current.."  "..types.NPC.records[Avatar.recordId].race:gsub("^%l", string.upper).." "..types.NPC.records[Avatar.recordId].class:gsub("^%l", string.upper))
    Inventory.layout.content[1].content["Menus"].content["Statistics"].content["Experience"].props.text="Experience : "..tostring(AvatarsStats[Avatar.recordId].Exp)
    Inventory.layout.content[1].content["Menus"].content["Statistics"].content["NextLevel"].props.text="Next Level : "..tostring(50+50*XpRatio(AvatarsStats[Avatar.recordId].Exp,types.Actor.stats.level(Avatar).current))
    Inventory.layout.content[1].content["Menus"].content["Statistics"].content["Health"].props.text="Health : "..tostring(math.floor(types.Actor.stats.dynamic.health(Avatar).current)).." / "..tostring(types.Actor.stats.dynamic.health(Avatar).base)
    Inventory.layout.content[1].content["Menus"].content["Statistics"].content["Magicka"].props.text="Magicka : "..tostring(math.floor(types.Actor.stats.dynamic.magicka(Avatar).current)).." / "..tostring(types.Actor.stats.dynamic.magicka(Avatar).base)
    Inventory.layout.content[1].content["Menus"].content["Statistics"].content["Armor"].props.text="Armor : "..tostring(Armor)
    Inventory.layout.content[1].content["Menus"].content["Statistics"].content["AttributePoints"].props.text="Attributes points to use : "..tostring(AvatarsStats[Avatar.recordId].AttributePoints)
    Inventory.layout.content[1].content["Menus"].content["Statistics"].content["1"].content[1].props.text="Strength : "..tostring(types.Actor.stats.attributes.strength(Avatar).base)
    Inventory.layout.content[1].content["Menus"].content["Statistics"].content["2"].content[1].props.text="Intelligence : "..tostring(types.Actor.stats.attributes.intelligence(Avatar).base)
    Inventory.layout.content[1].content["Menus"].content["Statistics"].content["3"].content[1].props.text="Willpower : "..tostring(types.Actor.stats.attributes.willpower(Avatar).base)
    Inventory.layout.content[1].content["Menus"].content["Statistics"].content["4"].content[1].props.text="Agility : "..tostring(types.Actor.stats.attributes.agility(Avatar).base)
    Inventory.layout.content[1].content["Menus"].content["Statistics"].content["5"].content[1].props.text="Endurance : "..tostring(types.Actor.stats.attributes.endurance(Avatar).base)
    Inventory.layout.content[1].content["Menus"].content["Statistics"].content["6"].content[1].props.text="Personality : "..tostring(types.Actor.stats.attributes.personality(Avatar).base)
    Inventory.layout.content[1].content["Menus"].content["Statistics"].content["7"].content[1].props.text="Speed : "..tostring(types.Actor.stats.attributes.speed(Avatar).base)
    Inventory.layout.content[1].content["Menus"].content["Statistics"].content["8"].content[1].props.text="Luck : "..tostring(types.Actor.stats.attributes.luck(Avatar).base)
    for i=1,7 do
        Inventory.layout.content[1].content["Menus"].content["Statistics"].content[tostring(i)].template=Templates.NotEquipped
    end



    Inventory.layout.content[1].content["Menus"].content["Spells"].content=ui.content{}
    Inventory.layout.content[1].content["Menus"].content["Spells"].content:add({type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}})
    Inventory.layout.content[1].content["Menus"].content["Spells"].content:add({type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}})
    Inventory.layout.content[1].content["Menus"].content["Spells"].content:add({type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="Skill points to use : "..AvatarsStats[Avatar.recordId].SkillsPoints}})
    Inventory.layout.content[1].content["Menus"].content["Spells"].content:add({type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}})
    local SpellNumber=1
--[[    for i, spell in pairs(types.Actor.spells(Avatar)) do
        if CoVSpell[string.lower(spell.name)] then
            local SpellLevelName=string.gsub(spell.id,string.lower(spell.name).."_","")
            local SpellLevel=tonumber(SpellLevelName)
            local SpellName=spell.name
            Inventory.layout.content[1].content["Menus"].content["Spells"].content:add({type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}})
            Inventory.layout.content[1].content["Menus"].content["Spells"].content:add({name=tostring(SpellNumber),type=ui.TYPE.Container, template=Templates.NotEquipped, props={autoSize=true, Spell=spell, NextSpell}, content=ui.content{{type=ui.TYPE.Flex,props={arrange=ui.ALIGNMENT.Center,align=ui.ALIGNMENT.Center, horizontal=true},content=ui.content{{type=ui.TYPE.Image, props={size=util.vector2(220*UiRatio.x,40*UiRatio.y), anchor=util.vector2(0,0),resource=ui.texture{ path="textures/alpha.dds"} }, content=ui.content{{type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={anchor=util.vector2(0,0.5),relativePosition=util.vector2(0,0.5), text=SpellName.." : "}}}}
        }}}})
            for j, level in pairs(CoVSpell[string.lower(spell.name)]) do
                if j>0 then
                    if j<=SpellLevel then
                        Inventory.layout.content[1].content["Menus"].content["Spells"].content[tostring(SpellNumber)].content[1].content:add({type=ui.TYPE.Image, props={size=util.vector2(40*UiRatio.x,40*UiRatio.y), anchor=util.vector2(0,1), resource=ui.texture{ path="textures/spellpaid.dds"}}})
                    else
                        if Inventory.layout.content[1].content["Menus"].content["Spells"].content[tostring(SpellNumber)].props.NextSpell==nil then
                            Inventory.layout.content[1].content["Menus"].content["Spells"].content[tostring(SpellNumber)].props.NextSpell=level
--                            print(Inventory.layout.content[1].content["Menus"].content["Spells"].content[tostring(SpellNumber)].props.NextSpell)
                        end
                        Inventory.layout.content[1].content["Menus"].content["Spells"].content[tostring(SpellNumber)].content[1].content:add({type=ui.TYPE.Image, props={size=util.vector2(40*UiRatio.x,40*UiRatio.y), anchor=util.vector2(0,1), resource=ui.texture{ path="textures/spellunpaid.dds"}}})
                    end
                end
            end
            SpellNumber=SpellNumber+1
        end
--]]
    local SpellOrder={}
    for i, spell in pairs(types.Actor.spells(Avatar)) do
        if CoVSpell[string.lower(spell.name)] then
            for categorie, spells in pairs(CoVSpell) do
                if not(SpellOrder[string.lower(spell.name)]) then
                    SpellOrder[string.lower(spell.name)]=SpellNumber
                    SpellNumber=SpellNumber+1
                end
            end
            local SpellLevelName=string.gsub(spell.id,string.lower(spell.name).."_","")
            local SpellLevel=tonumber(SpellLevelName)
            local SpellName=spell.name
            Inventory.layout.content[1].content["Menus"].content["Spells"].content:add({type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}})
            Inventory.layout.content[1].content["Menus"].content["Spells"].content:add({name=tostring(SpellOrder[string.lower(spell.name)]),type=ui.TYPE.Container, template=Templates.NotEquipped, props={autoSize=true, Spell=spell, NextSpell}, content=ui.content{{type=ui.TYPE.Flex,props={arrange=ui.ALIGNMENT.Center,align=ui.ALIGNMENT.Center, horizontal=true},content=ui.content{{type=ui.TYPE.Image, props={size=util.vector2(220*UiRatio.x,40*UiRatio.y), anchor=util.vector2(0,0),resource=ui.texture{ path="textures/alpha.dds"} }, content=ui.content{{type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={anchor=util.vector2(0,0.5),relativePosition=util.vector2(0,0.5), text=SpellName.." : "}}}}
        }}}})
            for j, level in pairs(CoVSpell[string.lower(spell.name)]) do
                if j>0 then
                    if j<=SpellLevel then
                        Inventory.layout.content[1].content["Menus"].content["Spells"].content[tostring(SpellOrder[string.lower(spell.name)])].content[1].content:add({type=ui.TYPE.Image, props={size=util.vector2(40*UiRatio.x,40*UiRatio.y), anchor=util.vector2(0,1), resource=ui.texture{ path="textures/spellpaid.dds"}}})
                    else
                        if Inventory.layout.content[1].content["Menus"].content["Spells"].content[tostring(SpellOrder[string.lower(spell.name)])].props.NextSpell==nil then
                            Inventory.layout.content[1].content["Menus"].content["Spells"].content[tostring(SpellOrder[string.lower(spell.name)])].props.NextSpell=level
--                            print(Inventory.layout.content[1].content["Menus"].content["Spells"].content[tostring(SpellNumber)].props.NextSpell)
                        end
                        Inventory.layout.content[1].content["Menus"].content["Spells"].content[tostring(SpellOrder[string.lower(spell.name)])].content[1].content:add({type=ui.TYPE.Image, props={size=util.vector2(40*UiRatio.x,40*UiRatio.y), anchor=util.vector2(0,1), resource=ui.texture{ path="textures/spellunpaid.dds"}}})
                    end
                end
            end
        end
    end



    local CurrentContent=Inventory.layout.content[1].content["Menus"].props.Menu
    local NbrSelected=Inventory.layout.content[1].content["Menus"].props.SelectionNbr
    for i=1,NbrSelected do
        if Inventory.layout.content[1].content["Menus"].content[CurrentContent].content:indexOf(tostring(NbrSelected+1-i)) then
            Inventory.layout.content[1].content["Menus"].props.SelectionNbr=NbrSelected+1-i
            if Inventory.layout.content[1].content["Menus"].content[CurrentContent].content[tostring(NbrSelected+1-i)].template==Templates.Equipped then
                Inventory.layout.content[1].content["Menus"].content[CurrentContent].content[tostring(NbrSelected+1-i)].template=Templates.EquippedSelected
            else
                Inventory.layout.content[1].content["Menus"].content[CurrentContent].content[tostring(NbrSelected+1-i)].template=Templates.NotEquippedSelected
            end
            break
        end     
    end
--    Inventory.layout.content[1].content["Menus"].content["Spells"].content
    AdditionalDatasText(Inventory)




    Inventory:update()

end



local function CreateInventory(AvatarNbr)
    local Avatar=Players[AvatarNbr]
    local Inventory
        if I.UI.getMode()==nil then
            I.UI.setMode('Interface', { windows = {} })
        end
        Inventory={type=ui.TYPE.Image, layer="Windows", props={alpha=0.6, relativeSize=util.vector2(1/NbrPlayers,1), anchor=util.vector2(0,0), relativePosition=util.vector2(AvatarNbr/(NbrPlayers)-1/NbrPlayers,0), resource=ui.texture{ path="textures/InventoryBackground.tga"}},
                                            content=ui.content{{type=ui.TYPE.Flex, props={inheritAlpha=false, anchor=util.vector2(0.5,0), relativePosition=util.vector2(0.5,0.2),arrange=ui.ALIGNMENT.Center}, 
                                                                content=ui.content{{type=ui.TYPE.Flex,content=ui.content{   {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}},
                                                                                                                            {name="Header",type=ui.TYPE.Flex, props={horizontal=true}, content=ui.content{  {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                                                            {type=ui.TYPE.Image, props={size=util.vector2(20*UiRatio.x,20*UiRatio.y), anchor=util.vector2(0.5,0.5), resource=ui.texture{path="icons/weight.dds"}}},
                                                                                                                                                                                                            {name="Encumbrance", type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" : "..math.floor(types.Actor.getEncumbrance(Avatar)).."/"..types.Actor.getCapacity(Avatar)}},
                                                                                                                                                                                                            {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                                                            {type=ui.TYPE.Image, props={size=util.vector2(20*UiRatio.x,20*UiRatio.y), anchor=util.vector2(0.5,0.5), resource=ui.texture{path="icons/tx_goldicon.dds"}}},
                                                                                                                                                                                                            {name="Gold", type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" : "}},
                                                                                                                            }},
                                                                                                                                                        
                                                                                                                                                        
                                                                                                                        }},
                                                                                    
                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}},
                                                                                    {name="Categories",type=ui.TYPE.Flex, props={horizontal=true}, content=ui.content{  {name="Weapons", type=ui.TYPE.Container, template=I.MWUI.templates.boxTransparent, props={anchor=util.vector2(0.5,0.5)}, content=ui.content{ {type=ui.TYPE.Image, props={size=util.vector2(40*UiRatio.x,40*UiRatio.y), resource=ui.texture{path="icons/cov/combat_longblade.dds"}}}}},
                                                                                                                                                                        {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                        {name="Armors", type=ui.TYPE.Container, template=nil, props={anchor=util.vector2(0.5,0.5)},content=ui.content{ {type=ui.TYPE.Image, props={size=util.vector2(40*UiRatio.x,40*UiRatio.y), resource=ui.texture{path="icons/cov/combat_block.dds"}}}}},
                                                                                                                                                                        {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                        {name="Potions", type=ui.TYPE.Container, template=nil, props={anchor=util.vector2(0.5,0.5)}, content=ui.content{ {type=ui.TYPE.Image, props={size=util.vector2(40*UiRatio.x,40*UiRatio.y), resource=ui.texture{path="icons/cov/magic_alchemy.dds"}}}}},
                                                                                                                                                                        {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                        {name="Statistics", type=ui.TYPE.Container, template=nil, props={anchor=util.vector2(0.5,0.5)}, content=ui.content{ {type=ui.TYPE.Image, props={size=util.vector2(40*UiRatio.x,40*UiRatio.y), resource=ui.texture{path="icons/cov/magic_mysticism.dds"}}}}},
                                                                                                                                                                        {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                        {name="Spells", type=ui.TYPE.Container, template=nil, props={anchor=util.vector2(0.5,0.5)}, content=ui.content{ {type=ui.TYPE.Image, props={size=util.vector2(40*UiRatio.x,40*UiRatio.y), resource=ui.texture{path="icons/cov/magic_destruction.dds"}}}}},
                                                                                                                    }},
                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=" "}},
                                                                                    {name="Menus", type=ui.TYPE.Image, layer="Windows", props={alpha=0, size=util.vector2((1/NbrPlayers)*ui.screenSize().x,ui.screenSize().y*10), anchor=util.vector2(0,0), resource=ui.texture{ path="textures/white.tga"},SelectionNbr=1, Menu="Weapons", Barter},
                                                                                                            content=ui.content{ {name="Weapons", type=ui.TYPE.Flex,props={visible=true,inheritAlpha=false, relativePosition=util.vector2(0.5,0), anchor=util.vector2(0.5,0)}, content=ui.content{ }},
                                                                                                                                {name="Armors", type=ui.TYPE.Flex, props={visible=false,inheritAlpha=false, relativePosition=util.vector2(0.5,0), anchor=util.vector2(0.5,0)}, content=ui.content{ }},
                                                                                                                                {name="Potions", type=ui.TYPE.Flex, props={visible=false,inheritAlpha=false, relativePosition=util.vector2(0.5,0), anchor=util.vector2(0.5,0)}, content=ui.content{ }},
                                                                                                                                {name="Statistics", type=ui.TYPE.Flex, props={arrange=ui.ALIGNMENT.Center,visible=false,inheritAlpha=false, relativePosition=util.vector2(0.5,0), anchor=util.vector2(0.5,0)}, content=ui.content{{type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                                                                                                                                                    {name="Level",type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="Level "}},
                                                                                                                                                                                                                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                                                                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                                                                                                                                                    {name="Experience", type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="Experience : "}},
                                                                                                                                                                                                                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                                                                                                                                                    {name="NextLevel", type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="Next Level : "}},
                                                                                                                                                                                                                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                                                                                                                                                    {name="Health", type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="Health : "}},
                                                                                                                                                                                                                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                                                                                                                                                    {name="Magicka", type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="Magicka : "}},
                                                                                                                                                                                                                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                                                                                                                                                    {name="Armor", type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="Armor : "}},
                                                                                                                                                                                                                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                                                                                                                                                    {name="AttributePoints", type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="Attributes points to use : "}},
                                                                                                                                                                                                                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                                                                                                                                                    {name="1", type=ui.TYPE.Container, template=Templates.NotEquipped, props={anchor=util.vector2(0.5,0.5), autoSize=true, Attribute="strength", Description=core.getGMST("sStrDesc")},content=ui.content{ {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="Strength : "}}}},
                                                                                                                                                                                                                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                                                                                                                                                    {name="2", type=ui.TYPE.Container, template=Templates.NotEquipped, props={anchor=util.vector2(0.5,0.5), autoSize=true, Attribute="intelligence", Description=core.getGMST("sIntDesc")},content=ui.content{{ type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="Intelligence : "}}}},
                                                                                                                                                                                                                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                                                                                                                                                    {name="3", type=ui.TYPE.Container, template=Templates.NotEquipped, props={anchor=util.vector2(0.5,0.5), autoSize=true, Attribute="willpower", Description=core.getGMST("sWilDesc")},content=ui.content{{ type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="Willpower : "}}}},
                                                                                                                                                                                                                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                                                                                                                                                    {name="4", type=ui.TYPE.Container, template=Templates.NotEquipped, props={anchor=util.vector2(0.5,0.5), autoSize=true, Attribute="agility", Description=core.getGMST("sAgiDesc")},content=ui.content{{ type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="Agility : "}}}},
                                                                                                                                                                                                                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                                                                                                                                                    {name="5", type=ui.TYPE.Container, template=Templates.NotEquipped, props={anchor=util.vector2(0.5,0.5), autoSize=true, Attribute="endurance", Description=core.getGMST("sEndDesc")},content=ui.content{{ type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="Endurance : "}}}},
                                                                                                                                                                                                                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                                                                                                                                                    {name="6", type=ui.TYPE.Container, template=Templates.NotEquipped, props={anchor=util.vector2(0.5,0.5), autoSize=true, Attribute="personality", Description=core.getGMST("sPerDesc")},content=ui.content{ { type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="personality : "}}}},
                                                                                                                                                                                                                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                                                                                                                                                    {name="7", type=ui.TYPE.Container, template=Templates.NotEquipped, props={anchor=util.vector2(0.5,0.5), autoSize=true, Attribute="speed", Description=core.getGMST("sSpdDesc")},content=ui.content{ {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="Speed : "}}}},
                                                                                                                                                                                                                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="   "}},
                                                                                                                                                                                                                                                                                                    {name="8", type=ui.TYPE.Container, template=Templates.NotEquipped, props={anchor=util.vector2(0.5,0.5), autoSize=true, Attribute="luck", Description=core.getGMST("sLucDesc")},content=ui.content{ {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="Luck : "}}}},}},
                                                                                                                                {name="Spells", type=ui.TYPE.Flex, props={visible=false,inheritAlpha=false, relativePosition=util.vector2(0.5,0), anchor=util.vector2(0.5,0)}, content=ui.content{ }}}},              
                                                                                                                    }},
                                                                {name="AdditionalDatas",type=ui.TYPE.Container, template=Templates.NotEquippedSelected, props={inheritAlpha=false, visible=false, relativePosition=util.vector2(0.8,0.4), anchor=util.vector2(0.5,0.5)}, content=ui.content{{type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={multiline=true, textAlignH=ui.ALIGNMENT.Center, text="Datas"}}}}
                                                            }}




        return(Inventory)
end

I.UI.registerWindow("Trade", function() I.UI.removeMode("Barter") 
                                        I.UI.removeMode("Dialogue") 
--                                        print("BARTER",LastMerchant) 
                                        for i, player in pairs(Players) do
                                            Barter[i]=ui.create(CreateInventory(i))
                                            Barter[i].layout.content[1].content["Menus"].props.Barter="Buy"
                                            updateInventoryUI(Barter[i],player,LastMerchant)
                                        end
                            end, function() return true end)



local function Controls(nbr,dt)
    if Players[nbr] then
        local NoMove
        local ViewPort=camera.worldToViewportVector(Players[nbr].position)
        local ScreenX=ViewPort.x/ui.screenSize().x
        local ScreenY=ViewPort.y/ui.screenSize().y
        
        if dt>0 and input.getBooleanActionValue('P'..nbr..'Block') and anim.isPlaying(Players[nbr], "runback")==false 
                                                                    and types.Actor.getEquipment(Players[nbr],types.Actor.EQUIPMENT_SLOT.CarriedRight)
                                                                    and not(types.Weapon.records[types.Actor.getEquipment(Players[nbr],types.Actor.EQUIPMENT_SLOT.CarriedRight).recordId].type==types.Weapon.TYPE.MarksmanCrossbow) 
                                                                    and not(types.Weapon.records[types.Actor.getEquipment(Players[nbr],types.Actor.EQUIPMENT_SLOT.CarriedRight).recordId].type==types.Weapon.TYPE.MarksmanBow) then
            Players[nbr]:sendEvent("Block")
        else
            if input.getBooleanActionValue('P'..nbr..'MoveUp') then
                if Inventories[nbr] and Toggles[nbr].Up==false then
 --                   print("invenotryUP")
                    local ItemNbr=tostring(Inventories[nbr].layout.content[1].content["Menus"].props.SelectionNbr)
                    local Menu=Inventories[nbr].layout.content[1].content["Menus"].props.Menu
                    if Inventories[nbr].layout.content[1].content["Menus"].props.SelectionNbr>1 then
                        ambient.playSoundFile("sound/fx/menu click.wav")
                        if Inventories[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].props.Equipped==true then
                            Inventories[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].template=Templates.Equipped
                        else
                            Inventories[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].template=Templates.NotEquipped
                        end
                        Inventories[nbr].layout.content[1].content["Menus"].props.SelectionNbr=Inventories[nbr].layout.content[1].content["Menus"].props.SelectionNbr-1
                        ItemNbr=tostring(Inventories[nbr].layout.content[1].content["Menus"].props.SelectionNbr)
                        if Inventories[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].props.Equipped==true then
                            Inventories[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].template=Templates.EquippedSelected
                        else
                            Inventories[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].template=Templates.NotEquippedSelected
                        end
                        if Inventories[nbr].layout.content[1].content["Menus"].props.SelectionNbr>3 and Inventories[nbr].layout.content[1].content["Menus"].props.Menu~="Statistics" and Inventories[nbr].layout.content[1].content["Menus"].props.Menu~="Spells" then
                            Inventories[nbr].layout.content[1].content["Menus"].content[Menu].props.relativePosition=Inventories[nbr].layout.content[1].content["Menus"].content[Menu].props.relativePosition+util.vector2(0,0.01)
                        end
                        Inventories[nbr]:update()
                        AdditionalDatasText(Inventories[nbr])

                    end
                    Toggles[nbr].Up=true
                elseif Barter[nbr] and Toggles[nbr].Up==false then
 --                   print("BarterUP")
                    local ItemNbr=tostring(Barter[nbr].layout.content[1].content["Menus"].props.SelectionNbr)
                    local Menu=Barter[nbr].layout.content[1].content["Menus"].props.Menu
                    if Barter[nbr].layout.content[1].content["Menus"].props.SelectionNbr>1 then
                        ambient.playSoundFile("sound/fx/menu click.wav")
                        if Barter[nbr].layout.content[1].content["Menus"].props.SelectionNbr>5 and Barter[nbr].layout.content[1].content["Menus"].props.Menu~="Statistics" and Barter[nbr].layout.content[1].content["Menus"].props.Menu~="Spells" then
                            Barter[nbr].layout.content[1].content["Menus"].content[Menu].props.relativePosition=Barter[nbr].layout.content[1].content["Menus"].content[Menu].props.relativePosition+util.vector2(0,0.01)
                        end
                        
                        if Barter[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].props.Equipped==true then
                            Barter[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].template=Templates.Equipped
                        else
                            Barter[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].template=Templates.NotEquipped
                        end
                        Barter[nbr].layout.content[1].content["Menus"].props.SelectionNbr=Barter[nbr].layout.content[1].content["Menus"].props.SelectionNbr-1
                        ItemNbr=tostring(Barter[nbr].layout.content[1].content["Menus"].props.SelectionNbr)
                        
                        if Barter[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].props.Equipped==true then
                            Barter[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].template=Templates.EquippedSelected
                        else
                            Barter[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].template=Templates.NotEquippedSelected
                        end
                        AdditionalDatasText(Barter[nbr])

                        Barter[nbr]:update()
                    end
                    Toggles[nbr].Up=true
                     
                elseif dt>0 then
                    if ScreenY<0.2 then
                        NoMove=true
                    end
                    if input.getBooleanActionValue('P'..nbr..'MoveRight') then
                        if ScreenX>0.9 then
                            NoMove=true
                        end
                        Players[nbr]:sendEvent("Move",{Value=math.pi/4+Camera.Angle,NoMove=NoMove})
                    elseif input.getBooleanActionValue('P'..nbr..'MoveLeft') then
                        if ScreenX<0.1 then
                            NoMove=true
                        end
                        Players[nbr]:sendEvent("Move",{Value=-math.pi/4+Camera.Angle,NoMove=NoMove})
                    else
                        Players[nbr]:sendEvent("Move",{Value=0+Camera.Angle,NoMove=NoMove})
                    end
                end
            elseif input.getBooleanActionValue('P'..nbr..'MoveDown') then
                if Inventories[nbr] and Toggles[nbr].Down==false then
--                    print("invenotryDOWN")
                    local ItemNbr=tostring(Inventories[nbr].layout.content[1].content["Menus"].props.SelectionNbr)
                    local Menu=Inventories[nbr].layout.content[1].content["Menus"].props.Menu
                    if Inventories[nbr].layout.content[1].content["Menus"].content[Menu].content:indexOf(tostring(Inventories[nbr].layout.content[1].content["Menus"].props.SelectionNbr+1)) then
                        ambient.playSoundFile("sound/fx/menu click.wav")
                        if Inventories[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].props.Equipped==true then
                            Inventories[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].template=Templates.Equipped
                        else
                            Inventories[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].template=Templates.NotEquipped
                        end
                        Inventories[nbr].layout.content[1].content["Menus"].props.SelectionNbr=Inventories[nbr].layout.content[1].content["Menus"].props.SelectionNbr+1
                        ItemNbr=tostring(Inventories[nbr].layout.content[1].content["Menus"].props.SelectionNbr)
                        if Inventories[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].props.Equipped==true then
                            Inventories[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].template=Templates.EquippedSelected
                        else
                            Inventories[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].template=Templates.NotEquippedSelected
                        end
                        if Inventories[nbr].layout.content[1].content["Menus"].props.SelectionNbr>4 and Inventories[nbr].layout.content[1].content["Menus"].props.Menu~="Statistics" and Inventories[nbr].layout.content[1].content["Menus"].props.Menu~="Spells" then
                            Inventories[nbr].layout.content[1].content["Menus"].content[Menu].props.relativePosition=Inventories[nbr].layout.content[1].content["Menus"].content[Menu].props.relativePosition-util.vector2(0,0.01)
                        end
                        AdditionalDatasText(Inventories[nbr])

                        Inventories[nbr]:update()
                    end
                    Toggles[nbr].Down=true
                elseif Barter[nbr] and Toggles[nbr].Down==false then
 --                   print("BarterDOWN")
                    local ItemNbr=tostring(Barter[nbr].layout.content[1].content["Menus"].props.SelectionNbr)
                    local Menu=Barter[nbr].layout.content[1].content["Menus"].props.Menu
                    if Barter[nbr].layout.content[1].content["Menus"].content[Menu].content:indexOf(tostring(Barter[nbr].layout.content[1].content["Menus"].props.SelectionNbr+1)) then
                        ambient.playSoundFile("sound/fx/menu click.wav")
                        Barter[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].template=Templates.NotEquipped
                        ItemNbr=tostring(Barter[nbr].layout.content[1].content["Menus"].props.SelectionNbr)
                        if Barter[nbr].layout.content[1].content["Menus"].props.SelectionNbr>4 and Barter[nbr].layout.content[1].content["Menus"].props.Menu~="Statistics" and Barter[nbr].layout.content[1].content["Menus"].props.Menu~="Spells" then
                            Barter[nbr].layout.content[1].content["Menus"].content[Menu].props.relativePosition=Barter[nbr].layout.content[1].content["Menus"].content[Menu].props.relativePosition-util.vector2(0,0.01)
                        end
                        if Barter[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].props.Equipped==true then
                            Barter[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].template=Templates.Equipped
                        else
                            Barter[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].template=Templates.NotEquipped
                        end
                        Barter[nbr].layout.content[1].content["Menus"].props.SelectionNbr=Barter[nbr].layout.content[1].content["Menus"].props.SelectionNbr+1
                        ItemNbr=tostring(Barter[nbr].layout.content[1].content["Menus"].props.SelectionNbr)
                        
                        if Barter[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].props.Equipped==true then
                            Barter[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].template=Templates.EquippedSelected
                        else
                            Barter[nbr].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].template=Templates.NotEquippedSelected
                        end
                        AdditionalDatasText(Barter[nbr])

                        Barter[nbr]:update()
                    end
                    Toggles[nbr].Down=true
                    
                elseif dt>0 then
                    if ScreenY>0.9 then
                        NoMove=true
                    end
                    if input.getBooleanActionValue('P'..nbr..'MoveRight') then
                        if ScreenX>0.9 then
                            NoMove=true
                        end
                        Players[nbr]:sendEvent("Move",{Value=1.5*math.pi/2+Camera.Angle,NoMove=NoMove})
                    elseif input.getBooleanActionValue('P'..nbr..'MoveLeft') then
                        if ScreenX<0.1 then
                            NoMove=true
                        end
                        Players[nbr]:sendEvent("Move",{Value=-1.5*math.pi/2+Camera.Angle,NoMove=NoMove})
                    else
                        Players[nbr]:sendEvent("Move",{Value=math.pi+Camera.Angle,NoMove=NoMove})
                    end
                end
            elseif input.getBooleanActionValue('P'..nbr..'MoveRight')then
                if ScreenX>0.9 and dt>0  then
                    NoMove=true
                end
                Players[nbr]:sendEvent("Move",{Value=math.pi/2+Camera.Angle,NoMove=NoMove})   
            elseif input.getBooleanActionValue('P'..nbr..'MoveLeft') and dt>0  then
                if ScreenX<0.1 then
                    NoMove=true
                end
                Players[nbr]:sendEvent("Move",{Value=-math.pi/2+Camera.Angle,NoMove=NoMove})
            else
                if Toggles[nbr].Up==true then
                    Toggles[nbr].Up=false
                elseif Toggles[nbr].Down==true then
                    Toggles[nbr].Down=false
                end
            end
        end
    end
end



local function onUpdate(dt)

    local dtRatio=math.floor(dt/0.02*1000)/1000

    Camera.Distance=Camera.Distance+input.getMouseMoveY()*0.5*dtRatio
    if  Camera.Distance>2000 then
        Camera.Distance=2000
    end
    Camera.Angle=Camera.Angle-input.getMouseMoveX()*0.005*dtRatio

    if camera.getMode()~=camera.MODE.Static then
        camera.setMode(camera.MODE.Static)
    end

    if self.cell.name=="CharacterSelectionCell" then
--        SelectionMenu.ChooseNbrPlayers=ui.
        if not(CharacterSelection.AskPlayers) then
            camera.setStaticPosition(util.vector3(0,200,1500))
            camera.setPitch(-math.pi/2)
            camera.setYaw(math.pi) 
            CharacterSelection.AskPlayers=ui.create({type=ui.TYPE.Container, layer="HUD", template=I.MWUI.templates.boxTransparent, 
                                                            props={anchor=util.vector2(0.5,0.5) ,relativePosition=util.vector2(0.5,0.5), PlayersNbr=1, AlphaValue=0.01},
                                                            content=ui.content{{type=ui.TYPE.Flex, props={arrange=ui.ALIGNMENT.Center,},
                                                                                content=ui.content{ {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=""}},
                                                                                                    {name="Player1", type=ui.TYPE.Text, props={alpha=0.5, textColor=NameColors[1], text="Player 1 Validate to START.",textSize=60*UiRatio.text}},
                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=""}},
                                                                                                    {name="Player2", type=ui.TYPE.Text, props={alpha=0.5, textColor=NameColors[2], text="Player 2 Validate to JOIN.",textSize=60*UiRatio.text}},
                                                                                                    {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=""}},
                                                                            
                                                                            }}}})
        elseif  not(CharacterSelection.PlayersNbr) then
--            for i=1,4 do
--                if CharacterSelection.AskPlayers.layout.content[1].content:indexOf("Player"..i) then
--                    CharacterSelection.AskPlayers.layout.content[1].content["Player"..i].props.alpha=CharacterSelection.AskPlayers.layout.content[1].content["Player"..i].props.alpha+dtRatio*CharacterSelection.AskPlayers.layout.props.AlphaValue
--                end 
--            end
--            if CharacterSelection.AskPlayers.layout.content[1].content["Player1"].props.alpha>0.8 then
--                CharacterSelection.AskPlayers.layout.props.AlphaValue=-CharacterSelection.AskPlayers.layout.props.AlphaValue
--            elseif CharacterSelection.AskPlayers.layout.content[1].content["Player1"].props.alpha<0.4 then
--                CharacterSelection.AskPlayers.layout.props.AlphaValue=-CharacterSelection.AskPlayers.layout.props.AlphaValue
--            end
--            CharacterSelection.AskPlayers:update()


        elseif not(CharacterSelection.Choice) then
            if CharacterSelection.Activators and Fading.layout.props.visible==false then
                camera.setStaticPosition(CharacterSelection.Activators[1].position+util.vector3(0,180,80))
            end
            camera.setPitch(0)
            camera.setYaw(math.pi) 

            CharacterSelection.Choice={Target=1}
            if CharacterSelection.ActivePlayer then
                CharacterSelection.Choice.Description=ui.create({type=ui.TYPE.Container, layer="HUD", template=I.MWUI.templates.boxTransparent, 
                                                                props={anchor=util.vector2(0.5,0.5) ,relativePosition=util.vector2(0.8,0.5),},
                                                                content=ui.content{{type=ui.TYPE.Container, template=I.MWUI.templates.padding, 
                                                                                    content=ui.content{ {type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text="", size=util.vector2(500*UiRatio.x,100*UiRatio.y), wordWrap=true}}}}}})
            end

        elseif CharacterSelection.ActivePlayer then
            MenuRaceControls(CharacterSelection.ActivePlayer)
            if Fading.layout.props.visible==false then
                camera.setStaticPosition((camera.getPosition()*2+CharacterSelection.Activators[CharacterSelection.Choice.Target].position+util.vector3(0,180,80))/3)
            end
        end



    end




    if Players[1] then
        local PlayersDead=0
        for i, player in pairs(Players) do
            if player.type.isDead(player)==true then
                PlayersDead=PlayersDead+1
                PlayersUI[i].layout.content["Health"].content["Current"].props.size=util.vector2(PlayersUI[i].layout.content["Health"].content["Base"].props.size.x*types.Actor.stats.dynamic.health(player).current/types.Actor.stats.dynamic.health(player).base,PlayersUI[i].layout.content["Health"].content["Current"].props.size.y)
                PlayersUI[i]:update()
            end

            
            Controls(i,dt)

            if Inventories[i] or Barter[i] then
                if InventoryToUpdate[i] then
                    if InventoryToUpdate[i]>0 then
                        InventoryToUpdate[i]=InventoryToUpdate[i]-1
                    else
                        if Inventories[i] then
                            updateInventoryUI(Inventories[i],player,player)
                        elseif Barter[i] then
                            if Barter[i].layout.content[1].content["Menus"].props.Barter=="Buy" then
                                updateInventoryUI(Barter[i],player,LastMerchant)
                            elseif Barter[i].layout.content[1].content["Menus"].props.Barter=="Sell" then
                                updateInventoryUI(Barter[i],player,player)
                            
                            end
                        end
                        InventoryToUpdate[i]=nil
                    end
                end
            end

                
        end
        if PlayersDead>=NbrPlayers then
            if ambient.isSoundFilePlaying("music/special/mw_death.mp3")==false then
                ambient.playSoundFile("music/special/mw_death.mp3")
            end
            --camera.setStaticPosition(camera.getPosition())
            --types.Actor.stats.dynamic.health(self).current=0
            return
        else
            types.Actor.stats.dynamic.health(self).current=types.Actor.stats.dynamic.health(self).base
        end





        if Players[1] then
            CameraPosition()
        end

        if dt>0 then
            for i, player in pairs(Players) do


                if tonumber(PlayersUI[i].layout.content["Gold"].props.text)<PlayersUI[i].layout.content["Gold"].props.targetValue then
                    PlayersUI[i].layout.content["Gold"].props.text=tostring(tonumber(PlayersUI[i].layout.content["Gold"].props.text)+1)
                    PlayersUI[i].layout.content["Gold"].props.visible=true
                    PlayersUI[i].layout.content["Gold"].props.alpha=1
                elseif PlayersUI[i].layout.content["Gold"].props.visible==true then
                    if PlayersUI[i].layout.content["Gold"].props.alpha>0.2 then
                        PlayersUI[i].layout.content["Gold"].props.alpha=PlayersUI[i].layout.content["Gold"].props.alpha-dtRatio/100
                    else
                        PlayersUI[i].layout.content["Gold"].props.visible=false
                    end
                elseif tonumber(PlayersUI[i].layout.content["Gold"].props.text)>PlayersUI[i].layout.content["Gold"].props.targetValue then
                    PlayersUI[i].layout.content["Gold"].props.targetValue=tonumber(PlayersUI[i].layout.content["Gold"].props.text)
                end
                PlayersUI[i].layout.content["Health"].content["Current"].props.size=util.vector2(PlayersUI[i].layout.content["Health"].content["Base"].props.size.x*types.Actor.stats.dynamic.health(player).current/types.Actor.stats.dynamic.health(player).base,PlayersUI[i].layout.content["Health"].content["Current"].props.size.y)
                PlayersUI[i].layout.content["Magicka"].content["Current"].props.size=util.vector2(PlayersUI[i].layout.content["Magicka"].content["Base"].props.size.x*types.Actor.stats.dynamic.magicka(player).current/types.Actor.stats.dynamic.magicka(player).base,PlayersUI[i].layout.content["Magicka"].content["Current"].props.size.y)
                PlayersUI[i].layout.content["Exp"].content["Current"].props.size=util.vector2(PlayersUI[i].layout.content["Exp"].content["Base"].props.size.x*XpRatio(AvatarsStats[player.recordId].Exp,(types.Actor.stats.level(player).current)),PlayersUI[i].layout.content["Exp"].content["Current"].props.size.y)
                if PlayersUI[i].layout.content["SwitchSpell"].props.tempo>0.1 then
                    PlayersUI[i].layout.content["SwitchSpell"].props.tempo= PlayersUI[i].layout.content["SwitchSpell"].props.tempo-dt

                    if PlayersUI[i].layout.content["SwitchSpell"].content["Icons"].props.relativePosition.x-0.005*dtRatio>0.485 then     
                        if PlayersUI[i].layout.content["SwitchSpell"].content["Icons"].props.relativePosition.x>0.6 then 
                            PlayersUI[i].layout.content["SwitchSpell"].content["Icons"].props.relativePosition=PlayersUI[i].layout.content["SwitchSpell"].content["Icons"].props.relativePosition+util.vector2(-0.05*dtRatio,0)
                        else
                            PlayersUI[i].layout.content["SwitchSpell"].content["Icons"].props.relativePosition=PlayersUI[i].layout.content["SwitchSpell"].content["Icons"].props.relativePosition+util.vector2(-0.005*dtRatio,0)
                        end
                    end
                    
                    if PlayersUI[i].layout.content["SwitchSpell"].props.tempo<0.1 then
                        PlayersUI[i].layout.content["SwitchSpell"].props.tempo=0
                        PlayersUI[i].layout.content["SwitchSpell"].props.alpha=0
                    elseif PlayersUI[i].layout.content["SwitchSpell"] and  PlayersUI[i].layout.content["SwitchSpell"].props.tempo<0.5 then
                        PlayersUI[i].layout.content["SwitchSpell"].props.alpha=PlayersUI[i].layout.content["SwitchSpell"].props.alpha-0.05*dtRatio
                    end
                end
                if PlayersUI[i].layout.content["AvatarName"].props.alpha~=1 then
                    PlayersUI[i].layout.content["AvatarName"].props.alpha=PlayersUI[i].layout.content["AvatarName"].props.alpha+dt*5
                end
                PlayersUI[i]:update()
            end
        end

        for i, damage in pairs(DamagesUI) do
            if damage.layout then
                local ViewPort=camera.worldToViewportVector(damage.layout.props.Actor.position)
                damage.layout.props.alpha=damage.layout.props.alpha-dtRatio/100
                damage.layout.props.deltaY=damage.layout.props.deltaY+dtRatio*2
                damage.layout.props.position=util.vector2(ViewPort.x,ViewPort.y-damage.layout.props.deltaY)
                damage:update()
                if damage.layout.props.alpha<0 then
                    damage:destroy()
                    damage=nil
                end
            end
        end

        for i, coinui in pairs (CoinsUI) do
            if coinui.layout then
                coinui.layout.props.relativePosition=coinui.layout.props.relativePosition-(coinui.layout.props.relativePosition-PlayersUI[coinui.layout.props.UITarget].layout.props.relativePosition)/60
                coinui:update()
                if (coinui.layout.props.relativePosition-PlayersUI[coinui.layout.props.UITarget].layout.props.relativePosition):length()<0.05 then
                    PlayersUI[coinui.layout.props.UITarget].layout.content["Gold"].props.targetValue=types.Actor.inventory(Players[coinui.layout.props.UITarget]):find("gold_001").count --PlayersUI[coinui.layout.props.UITarget].layout.content["Gold"].props.targetValue+tonumber(coinui.layout.props.text)
                    coinui:destroy()
                    coinui=nil
                end
            end
        end
    end


    if Fading.layout.props.visible==true then
        if Fading.layout.props.alpha>0.9 then
            Fading.layout.props.alphaDelta=-Fading.layout.props.alphaDelta
            if CharacterSelection.ActivePlayer==CharacterSelection.PlayersNbr then
                CharacterSelection.ActivePlayer=nil
                CharacterSelection.ActivePlayerUI:destroy()
                core.sendGlobalEvent("CoVStartGlobal",{Avatars=CharacterSelection.Avatars})
                CharacterSelection.Choice.Description:destroy()
            end
        end

        if Fading.layout.props.alphaDelta<0 and Fading.layout.props.alpha<0.1 then
            Fading.layout.props.visible=false
            Fading.layout.props.alphaDelta=-Fading.layout.props.alphaDelta
        end

        Fading.layout.props.alpha=Fading.layout.props.alpha+Fading.layout.props.alphaDelta*dtRatio
        Fading:update()

    end
    core.sendGlobalEvent("CoVReturnMWGlobal",{Player=self, Variable="PlayerXPosition", Value=camera.getPosition().x})
    core.sendGlobalEvent("CoVReturnMWGlobal",{Player=self, Variable="PlayerYPosition", Value=camera.getPosition().y})
    core.sendGlobalEvent("CoVReturnMWGlobal",{Player=self, Variable="PlayerZPosition", Value=camera.getPosition().z+400})

        
end


local function ActivatorsForAvatarSelection(data)
    CharacterSelection.Activators=data.ActivatorsAvatarsList
end



local function onTeleported()
 --   print("TELEPORT")
    for i, player in pairs(Players) do
		player:sendEvent("AddVfx",{model="meshes/player"..i..".nif",options={loop=true}})
	end
end


local function CoVAddXp(data)
--    print("ADDXP")
    if AvatarsStats[data.Avatar] then
        AvatarsStats[data.Avatar].Exp=AvatarsStats[data.Avatar].Exp+data.Xp
--        print(AvatarsStats[data.Avatar].Exp)
    end
end

time.runRepeatedly(function() 	
	if LastCellId~=self.cell.id then
        LastCellId=self.cell.id
        for i, player in pairs(Players) do
            player:sendEvent("AddVfx",{model="meshes/player"..i..".nif",options={loop=true}})
        end
    end

    for i, player in pairs(Players) do
        if XpRatio(AvatarsStats[player.recordId].Exp,(types.Actor.stats.level(player).current))>1 then
--            print("LEVELUP")
            player:sendEvent("LevelUp")
            PlayersUI[i].layout.content["AvatarName"].props.alpha=0.9
            ambient.playSoundFile("sound/fx/inter/levelup.wav")
            AvatarsStats[player.recordId].SkillsPoints=AvatarsStats[player.recordId].SkillsPoints+types.Actor.stats.level(player).current
            AvatarsStats[player.recordId].AttributePoints=AvatarsStats[player.recordId].AttributePoints+3
        end


        local text
        local ActivateDistance=150
        if not(text) then
            for i, item in pairs(nearby.items) do
                if types.Item.isCarriable(item) and (item.position-player.position):length()<ActivateDistance and item.type.records[item.recordId].name~="Gold" then
                    text="Take "..item.type.records[item.recordId].name
                    break
                end
            end
        end
        if not(text) then
            for i, container in pairs(nearby.containers) do
                if (types.Container.inventory(container):isResolved()==false or types.Container.inventory(container):getAll()[1]) and (container.position-player.position):length()<ActivateDistance then
                    text="Open "..container.type.records[container.recordId].name
                    break
                end
            end
        end
        if not(text) then
            for i, activator in pairs(nearby.activators) do
                if (activator.position-player.position):length()<ActivateDistance then
                    if activator.recordId=="save point" then
                        for j, avatar in pairs(Players) do
                            if player~=avatar and types.Actor.isDead(avatar)==true then
                                core.sendGlobalEvent("CoVReanimateAvatar",{AvatarNbr=j,Survivor=player})
                                player=nil
                            end
                        end
                    end
                    text="Activate "..activator.type.records[activator.recordId].name
                    break
                end
            end
        end
        if not(text) then
            for i, actor in pairs(nearby.actors) do
                if types.Actor.isDead(actor)==false and types.Actor.stats.ai.fight(actor).modified<30 and actor.id~=player.id and (actor.position-player.position):length()<ActivateDistance then
                    text="Speak to "..actor.type.records[actor.recordId].name
                    LastMerchant=actor
                    break
                end
            end
        end
        if not(text) then
            for i, door in pairs(nearby.doors) do
                if (door.position-player.position):length()<ActivateDistance then
                    text="Open "..door.type.records[door.recordId].name
                    break
                end
            end
        end
        if text then
            AvatarsInterraction[i].layout.props.visible=true
            AvatarsInterraction[i].layout.content[1].props.text=text
        else
            AvatarsInterraction[i].layout.props.visible=false
        end
        AvatarsInterraction[i]:update()
    end

end,
0.3*time.second)



local function SwitchSpellUI(PlayerNbr,PreviousSpell,CurrentSpell,NextSpell)
    local Spell=core.magic.spells.records[CurrentSpell.id]
    local Text="\n"..Spell.name
    for i, effect in pairs(Spell.effects) do
        local MagnitudeText=effect.magnitudeMax
        if effect.magnitudeMax~=effect.magnitudeMin then
             MagnitudeText=effect.magnitudeMin.."-"..effect.magnitudeMax
        end
        local DescriptionText=effect.effect.name
        if effect.affectedAttribute then
            DescriptionText=effect.effect.name.." "..effect.affectedAttribute
        elseif effect.affectedSkill then
            DescriptionText=effect.effect.name.." "..effect.affectedSkill
        end
        local RangeText 
        local Range={"self","touch","target"}
        RangeText=Range[effect.range+1]

        local AreaText=""
        if effect.area>1 then
            AreaText=" on "..effect.area.." area"
        end
        Text=Text.."\n"..DescriptionText.." "..MagnitudeText.."\n for "..effect.duration.." secs on "..RangeText..AreaText
        end
        PlayersUI[PlayerNbr].layout.content["SwitchSpell"].content["Icons"].content["Previous"].props.resource=ui.texture{ path=core.magic.effects.records[core.magic.spells.records[PreviousSpell.id].effects[1].id].icon}
        PlayersUI[PlayerNbr].layout.content["SwitchSpell"].content["Text"].props.text=Text
        PlayersUI[PlayerNbr].layout.content["SwitchSpell"].content["Icons"].content["Current"].props.resource=ui.texture{ path=core.magic.effects.records[core.magic.spells.records[CurrentSpell.id].effects[1].id].icon}
        PlayersUI[PlayerNbr].layout.content["SwitchSpell"].content["Icons"].content["Next"].props.resource=ui.texture{ path=core.magic.effects.records[core.magic.spells.records[NextSpell.id].effects[1].id].icon}
        PlayersUI[PlayerNbr].layout.content["SwitchSpell"].content["Icons"].props.relativePosition=util.vector2(1,0.03)
        PlayersUI[PlayerNbr].layout.content["SwitchSpell"].props.tempo=1.5
        PlayersUI[PlayerNbr].layout.content["SwitchSpell"].props.alpha=1
end

local function Transaction(Seller,Buyer, Item)
    local Price=Item.type.records[Item.recordId].value+0.1*Item.type.records[Item.recordId].value*types.Actor.stats.attributes.personality(Seller).modified/types.Actor.stats.attributes.personality(Buyer).modified
 --   print("Seller", Seller, Item,Price)
  --  print("Buyer", Buyer, Item,Price)
    if types.Actor.inventory(Buyer):find("gold_001") and types.Actor.inventory(Buyer):find("gold_001").count>Price then
        core.sendGlobalEvent("CoVMoveInto",{Object=Item, Container=Buyer, Number=1})
        core.sendGlobalEvent("CoVMoveInto",{Object=types.Actor.inventory(Buyer):find("gold_001"), Container=Seller, Number=Price})
        ambient.playSoundFile("sound/fx/item/gold_up.wav")
        for i,player in pairs(Players) do
            InventoryToUpdate[i]=5
        end
    else
        ambient.playSoundFile("sound/fx/item/repairfail.wav")
    end
end

local function DeclareRedisterTriggerHandler(i)
    input.registerTriggerHandler("P"..i.."Hit", async:callback(function () 
        
                                                                        if Players[i] then
                                                                            if Inventories[i] then
                                                                                local ItemNbr=tostring(Inventories[i].layout.content[1].content["Menus"].props.SelectionNbr)
                                                                                local Menu=Inventories[i].layout.content[1].content["Menus"].props.Menu
                                                                                if Menu=="Statistics" then
                                                                                    if AvatarsStats[Players[1].recordId].AttributePoints>0 then
                                                                                        Players[i]:sendEvent("SetAttribute",{Attribute=Inventories[i].layout.content[1].content["Menus"].content["Statistics"].content[ItemNbr].props.Attribute,Value=types.Actor.stats.attributes[Inventories[i].layout.content[1].content["Menus"].content["Statistics"].content[ItemNbr].props.Attribute](Players[i]).base+1})
                                                                                        AvatarsStats[Players[1].recordId].AttributePoints=AvatarsStats[Players[1].recordId].AttributePoints-1
                                                                                        InventoryToUpdate[i]=5
                                                                                        ambient.playSoundFile("sound/fx/magic/enchant.wav")
                                                                
                                                                                    else
                                                                                        ambient.playSoundFile("sound/fx/item/repairfail.wav")
                                                                                    end
                                                                                elseif Menu=="Spells" then
                                                                                    local Spell=Inventories[i].layout.content[1].content["Menus"].content["Spells"].content[ItemNbr].props.NextSpell
                                                                                    if Spell then
                                                                                        local SpellCostText=string.gsub(Spell.id,string.lower(Spell.name).."_","")
                                                                                        local SpellCost=tonumber(SpellCostText)
                                                                                        if AvatarsStats[Players[1].recordId].SkillsPoints>=SpellCost then
                                                                                            Players[i]:sendEvent("CoVUpSpell",{OldSpell=Inventories[i].layout.content[1].content["Menus"].content["Spells"].content[ItemNbr].props.Spell.id, NewSpell=Inventories[i].layout.content[1].content["Menus"].content["Spells"].content[ItemNbr].props.NextSpell.id})
                                                                                            AvatarsStats[Players[1].recordId].SkillsPoints=AvatarsStats[Players[1].recordId].SkillsPoints-SpellCost
                                                                                            InventoryToUpdate[i]=5
                                                                                            ambient.playSoundFile("sound/fx/magic/enchant.wav")
                                                                                        else
                                                                                            ambient.playSoundFile("sound/fx/item/repairfail.wav")
                                                                                        end
                                                                                    else
                                                                                        ambient.playSoundFile("sound/fx/item/repairfail.wav")
                                                                                    end


                                                                                else
                                                                                    local Item=Inventories[i].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].props.item
                                                                                    if Item.type==types.Weapon then
                                                                                        local BowType=types.Weapon.TYPE.MarksmanBow
                                                                                        local CrossbowType=types.Weapon.TYPE.MarksmanCrossbow
                                                                                        local ThrownType=types.Weapon.TYPE.MarksmanThrown
                                                                                        local LastWeaponType
                                                                                        if types.Actor.getEquipment(Players[i],types.Actor.EQUIPMENT_SLOT.CarriedRight) and LastWeapon then
                                                                                            LastWeaponType=types.Weapon.records[types.Actor.getEquipment(Players[i],types.Actor.EQUIPMENT_SLOT.CarriedRight).recordId].type
                                                                                        end
                                                                                        local NewType=types.Weapon.records[Item.recordId].type
                                                                                        if (LastWeaponType~=BowType and LastWeaponType~=CrossbowType and LastWeaponType~=ThrownType and (NewType==BowType or NewType==CrossbowType or NewType==ThrownType))
                                                                                            or ((LastWeaponType==BowType or LastWeaponType==CrossbowType or LastWeaponType==ThrownType) and (NewType~=BowType and NewType~=CrossbowType and NewType~=ThrownType)) then
--                                                                                               print("SWITCH INVENTORY")
                                                                                            LastWeapon[Players[i].recordId]=types.Actor.getEquipment(Players[i],types.Actor.EQUIPMENT_SLOT.CarriedRight)
                                                                                        end
                                                                                        core.sendGlobalEvent('UseItem', {object = Item, actor = Players[i], force = true})
                                                                                        ambient.playSoundFile("sound/fx/item/longblad.wav")
                                                                                        InventoryToUpdate[i]=5
                                                                                    elseif Item.type==types.Armor then
                                                                                        core.sendGlobalEvent('UseItem', {object = Item, actor = Players[i], force = true})
                                                                                        ambient.playSoundFile("sound/fx/item/clothes.wav")
                                                                                        InventoryToUpdate[i]=5
                                                                                    elseif Item.type==types.Clothing then
                                                                                        core.sendGlobalEvent('UseItem', {object = Item, actor = Players[i], force = true})
                                                                                        ambient.playSoundFile("sound/fx/item/ring.wav")
                                                                                        InventoryToUpdate[i]=5
                                                                                    elseif Item.type==types.Potion then
                                                                                        core.sendGlobalEvent('UseItem', {object = Item, actor = Players[i], force = true})
                                                                                        ambient.playSoundFile("sound/fx/item/drink.wav")
                                                                                        InventoryToUpdate[i]=5
                                                                                    end
                                                                                end
                                                                            
                                                                            elseif Barter[i] then
                                                                                local ItemNbr=tostring(Barter[i].layout.content[1].content["Menus"].props.SelectionNbr)
                                                                                local Menu=Barter[i].layout.content[1].content["Menus"].props.Menu
                                                                                if Menu=="Statistics" then
                                                                                    if AvatarsStats[Players[1].recordId].AttributePoints>0 then
                                                                                        AvatarsStats[Players[1].recordId].AttributePoints=AvatarsStats[Players[1].recordId].AttributePoints-1
                                                                                        Players[i]:sendEvent("SetAttribute",{Attribute=Barter[i].layout.content[1].content["Menus"].content["Statistics"].content[ItemNbr].props.Attribute,Value=types.Actor.stats.attributes[Barter[i].layout.content[1].content["Menus"].content["Statistics"].content[ItemNbr].props.Attribute](Players[i]).base+1})
                                                                                        InventoryToUpdate[i]=5
                                                                                        ambient.playSoundFile("sound/fx/magic/enchant.wav")
                                                                
                                                                                    else
                                                                                        ambient.playSoundFile("sound/fx/item/repairfail.wav")
                                                                                    end
                                                                                elseif Menu=="Spells" then
                                                                                    local Spell=Barter[i].layout.content[1].content["Menus"].content["Spells"].content[ItemNbr].props.NextSpell
                                                                                    if Spell then
                                                                                        local SpellCostText=string.gsub(Spell.id,string.lower(Spell.name).."_","")
                                                                                        local SpellCost=tonumber(SpellCostText)
                                                                                        if AvatarsStats[Players[1].recordId].SkillsPoints>=SpellCost then
                                                                                            Players[i]:sendEvent("CoVUpSpell",{OldSpell=Barter[i].layout.content[1].content["Menus"].content["Spells"].content[ItemNbr].props.Spell.id, NewSpell=Barter[i].layout.content[1].content["Menus"].content["Spells"].content[ItemNbr].props.NextSpell.id})
                                                                                            AvatarsStats[Players[1].recordId].SkillsPoints=AvatarsStats[Players[1].recordId].SkillsPoints-SpellCost
                                                                                            InventoryToUpdate[i]=5
                                                                                            ambient.playSoundFile("sound/fx/magic/enchant.wav")
                                                                                        else
                                                                                            ambient.playSoundFile("sound/fx/item/repairfail.wav")
                                                                                        end
                                                                                    else
                                                                                        ambient.playSoundFile("sound/fx/item/repairfail.wav")
                                                                                    end


                                                                                else
                                                                                    local Item=Barter[i].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].props.item
                                                                                    if Barter[i].layout.content[1].content["Menus"].props.Barter=="Buy" then
                                                                                        Transaction(LastMerchant,Players[i],Item)
                                                                                    elseif Barter[i].layout.content[1].content["Menus"].props.Barter=="Sell" then
                                                                                        Transaction(Players[i],LastMerchant,Item)
                                                                                    end
                                                                                end
                                                                            elseif types.Actor.getEquipment(Players[i],types.Actor.EQUIPMENT_SLOT.CarriedRight) then
                                                                                Players[i]:sendEvent("PlayerHit",{FriendlyFire=storage.playerSection('CoVGeneralSettings'):get('FriendlyFire')})
                                                                            end
                                                                        elseif not(CharacterSelection.PlayersNbr) then
                                                                            if i==1 then
                                                                                CharacterSelection.PlayersNbr=CharacterSelection.AskPlayers.layout.props.PlayersNbr
                                                                                CharacterSelection.ActivePlayer=1
                                                                                CharacterSelection.AskPlayers:destroy()
                                                                                ambient.playSoundFile("sound/fx/magic/enchant.wav")
                                                                                CharacterSelection.ActivePlayerUI=ui.create({type=ui.TYPE.Text, layer="HUD", props={text="Player "..CharacterSelection.ActivePlayer, textSize=30*UiRatio.text, relativePosition=util.vector2(0.5,0.1), autoSize=true, anchor=util.vector2(0.5,0.5), textColor=NameColors[CharacterSelection.ActivePlayer]}})
                                                                            elseif CharacterSelection.AskPlayers.layout.content[1].content:indexOf("Player"..i) then
                                                                                if not(string.find(CharacterSelection.AskPlayers.layout.content[1].content["Player"..i].props.text,"Ready")) then
                                                                                CharacterSelection.AskPlayers.layout.content[1].content["Player"..i].props.text="Player "..i.." Ready"
                                                                                ambient.playSoundFile("sound/fx/menu click.wav")
                                                                                    if i<4 then
                                                                                        CharacterSelection.AskPlayers.layout.content[1].content:add({name="Player"..(i+1), type=ui.TYPE.Text, props={alpha=0.5,textColor=NameColors[i+1], text="Player "..(i+1).." Validate to JOIN.",textSize=60*UiRatio.text}})
                                                                                        CharacterSelection.AskPlayers.layout.content[1].content:add({type=ui.TYPE.Text, template=I.MWUI.templates.textHeader, props={text=""}})
                                                                                        CharacterSelection.AskPlayers.layout.props.PlayersNbr=CharacterSelection.AskPlayers.layout.props.PlayersNbr+1
                                                                                    end
                                                                                    CharacterSelection.AskPlayers:update()     
                                                                                end          
                                                                            end
                                                                        elseif CharacterSelection.Choice and CharacterSelection.ActivePlayer==i and Fading.layout.props.alpha==0.1 then
                                                                            ambient.playSoundFile("sound/fx/inter/levelup.wav")
                                                                            if not(CharacterSelection.Choice.Sex) then
                                                                                CharacterSelection.Choice.Sex={}        
                                                                                CharacterSelection.Choice.Description.layout.content[1].content[1].props.text="Choose sex"
                                                                                CharacterSelection.Choice.Description:update()
                                                                            else
                                                                                table.insert(CharacterSelection.Avatars, types.NPC.records[nearby.castRay(camera.getPosition(),camera.getPosition()+util.vector3(0,-200,0),{ignore=self}).hitObject.recordId].id)
                                                                                CharacterSelection.Choice.Description:destroy()
                                                                                CharacterSelection.Choice=nil
                                                                                if CharacterSelection.ActivePlayer==CharacterSelection.PlayersNbr then
                                                                                    ambient.playSoundFile("music/cov/mw_triumph.mp3")
                                                                                    Fading.layout.props.visible=true
                                                                                    ------------------------------------------------------------
                                                                                else
                                                                                    CharacterSelection.ActivePlayer=CharacterSelection.ActivePlayer+1
                                                                                    CharacterSelection.ActivePlayerUI.layout.props.text="Player "..CharacterSelection.ActivePlayer
                                                                                    CharacterSelection.ActivePlayerUI.layout.props.textColor=NameColors[CharacterSelection.ActivePlayer]
                                                                                    CharacterSelection.ActivePlayerUI:update()
                                                                                end
                                                                            end
                                                                        end

    end))
    input.registerTriggerHandler("P"..i.."Cast", async:callback(function () 
                                                                        if Players[i] then
                                                                            if Barter[i] then
                                                                                if  Barter[i].layout.content[1].content["Menus"].props.Barter=="Buy" then
                                                                                    Barter[i].layout.content[1].content["Menus"].props.Barter="Sell"
                                                                                    ui.showMessage("Sell")
                                                                                    updateInventoryUI(Barter[i],Players[i],Players[i])
                                                                                elseif Barter[i].layout.content[1].content["Menus"].props.Barter=="Sell" then
                                                                                    Barter[i].layout.content[1].content["Menus"].props.Barter="Buy"
                                                                                    ui.showMessage("Buy")
                                                                                    updateInventoryUI(Barter[i],Players[i],LastMerchant)
                                                                                end
                                                                            elseif Inventories[i] then
 --                                                                               print("DropITEM")
                                                                                local ItemNbr=tostring(Inventories[i].layout.content[1].content["Menus"].props.SelectionNbr)
                                                                                local Menu=Inventories[i].layout.content[1].content["Menus"].props.Menu
                                                                                local Item=Inventories[i].layout.content[1].content["Menus"].content[Menu].content[ItemNbr].props.item
                                                                                core.sendGlobalEvent('CoVTeleport', {Object = Item, Cell = Players[i].cell.name, Position = Players[i].position})
                                                                                ambient.playSoundFile("sound/fx/item/generic_down.wav")
                                                                                InventoryToUpdate[i]=5

                                                                            else
                                                                                Players[i]:sendEvent("PlayerCast",{FriendlyFire=storage.playerSection('CoVGeneralSettings'):get('FriendlyFire')})

                                                                            end
                                                                        end

    end))
    input.registerTriggerHandler("P"..i.."Use", async:callback(function () 
                                                                        if Players[i] then
                                                                            Players[i]:sendEvent("PlayerUse",{Players=Players})
                                                                        end

    end))
    input.registerTriggerHandler("P"..i.."SwitchWeapon", async:callback(function () 
                                                                        if Players[i] then
                                                                            if anim.isPlaying(Players[i], "shield") then
                                                                                Players[i]:sendEvent("StepBack")
                                                                            elseif types.Actor.inventory(Players[i]):find(LastWeapon[Players[i].recordId].recordId) then
                                                                                core.sendGlobalEvent('UseItem', {object = types.Actor.inventory(Players[i]):find(LastWeapon[Players[i].recordId].recordId), actor = Players[i], force = true})
                                                                                LastWeapon[Players[i].recordId]=types.Actor.getEquipment(Players[i],types.Actor.EQUIPMENT_SLOT.CarriedRight)
                                                                                ambient.playSoundFile("sound/fx/item/longblad.wav")
 --                                                                               print(Players[i],"Switch Weapon")
                                                                            end
                                                                        end

    end))
    input.registerTriggerHandler("P"..i.."SwitchSpell", async:callback(function () 
                                                                        if Players[i] then
 --                                                                           print(Players[i],"Switch Spell")
                                                                            local AvatarSpells=types.Actor.spells(Players[i])
                                                                            local AvatarSpell=types.Actor.getSelectedSpell(Players[i])
                                                                            local Avatar=Players[i]
                                                                            local CastingSpells={}
                                                                            for j, spell in pairs(AvatarSpells) do
                                                                                if spell.type==core.magic.SPELL_TYPE.Spell and spell.id~=string.lower(core.magic.spells.records[spell.id].name).."_0" then
                                                                                    table.insert(CastingSpells,spell)
                                                                                end
                                                                            end
                                                                            for j, spell in pairs(CastingSpells) do
                                                                                if spell.id==AvatarSpell.id then
                                                                                    ambient.playSoundFile("sound/fx/item/bookpage1.wav")
                                                                                    local LastSpell=AvatarSpell
                                                                                    local CurrentSpell
                                                                                    local NextSpell

                                                                                    if CastingSpells[j+1] then
                                                                                        CurrentSpell=CastingSpells[j+1]
                                                                                        if CastingSpells[j+2] then
                                                                                            NextSpell=CastingSpells[j+2]
                                                                                        else
                                                                                            NextSpell=CastingSpells[1]
                                                                                        end

                                                                                    else 
                                                                                        CurrentSpell=CastingSpells[1]
                                                                                        if CastingSpells[2] then
                                                                                            NextSpell=CastingSpells[2]
                                                                                        else
                                                                                            NextSpell=CastingSpells[1]
                                                                                        end
                                                                                    end
                                                                                    Avatar:sendEvent("EquipSpell",{spell=CurrentSpell.id})
                                                                                    SwitchSpellUI(i, LastSpell, CurrentSpell, NextSpell)
                                                                                end
                                                                            end
                                                                        end

    end))
    input.registerTriggerHandler("P"..i.."MagickaPotion", async:callback(function () 
                                                                        if Players[i] then
                                                                            if Inventories[i] then
  --                                                                              print("NEXT")
                                                                                local NewMenu
                                                                                for j, menu in pairs(Menus) do
                                                                                    if menu==Inventories[i].layout.content[1].content["Menus"].props.Menu then
                                                                                        if Menus[j+1] then
                                                                                            NewMenu=Menus[j+1]
                                                                                        else
                                                                                            NewMenu=Menus[1]
                                                                                        end
                                                                                    end
                                                                                end
                                                                                Inventories[i].layout.content[1].content["Menus"].props.Menu=NewMenu


                                                                                for j, menu in pairs(Menus) do
                                                                                    if menu==Inventories[i].layout.content[1].content["Menus"].props.Menu then
                                                                                        Inventories[i].layout.content[1].content["Menus"].content[menu].props.visible=true
                                                                                        Inventories[i].layout.content[1].content["Categories"].content[menu].template=I.MWUI.templates.boxTransparent
                                                                                    else
                                                                                        Inventories[i].layout.content[1].content["Menus"].content[menu].props.visible=false
                                                                                        Inventories[i].layout.content[1].content["Categories"].content[menu].template=nil
                                                                                    end
                                                                                end
                                                                                updateInventoryUI(Inventories[i],Players[i],Players[i])
                                                                                ambient.playSoundFile("sound/fx/item/bookpage1.wav")
                                                                                Inventories[i]:update()
                                                                            elseif Barter[i] then
  --                                                                              print("NEXT")
                                                                                local NewMenu
                                                                                for j, menu in pairs(Menus) do
                                                                                    if menu==Barter[i].layout.content[1].content["Menus"].props.Menu then
                                                                                        if Menus[j+1] then
                                                                                            NewMenu=Menus[j+1]
                                                                                        else
                                                                                            NewMenu=Menus[1]
                                                                                        end
                                                                                    end
                                                                                end
                                                                                Barter[i].layout.content[1].content["Menus"].props.Menu=NewMenu


                                                                                for j, menu in pairs(Menus) do
                                                                                    if menu==Barter[i].layout.content[1].content["Menus"].props.Menu then
                                                                                        Barter[i].layout.content[1].content["Menus"].content[menu].props.visible=true
                                                                                        Barter[i].layout.content[1].content["Categories"].content[menu].template=I.MWUI.templates.boxTransparent
                                                                                    else
                                                                                        Barter[i].layout.content[1].content["Menus"].content[menu].props.visible=false
                                                                                        Barter[i].layout.content[1].content["Categories"].content[menu].template=nil
                                                                                    end
                                                                                end
                                                                                Barter[i].layout.content[1].content["Menus"].content[NewMenu].props.relativePosition=util.vector2(0.5,0)
                                                                                if Barter[i].layout.content[1].content["Menus"].props.Barter=="Buy" then
                                                                                    updateInventoryUI(Barter[i],Players[i],LastMerchant)
                                                                                else
                                                                                    updateInventoryUI(Barter[i],Players[i],Players[i])
                                                                                end
                                                                                ambient.playSoundFile("sound/fx/item/bookpage1.wav")
                                                                                Barter[i]:update()

                                                                            elseif types.Actor.stats.dynamic.magicka(Players[i]).current<types.Actor.stats.dynamic.magicka(Players[i]).base then
                                                                                for _, potion in pairs(types.Actor.inventory(Players[i]):getAll(types.Potion)) do
                                                                                    for _, effect in pairs(types.Potion.records[potion.recordId].effects) do
                                                                                        if effect.effect.id==core.magic.EFFECT_TYPE.RestoreMagicka then
                                                                                            core.sendGlobalEvent('UseItem', {object = potion, actor = Players[i], force = true})
                                                                                            break
                                                                                        end
                                                                                    end
                                                                                end
                                                                            end
                                                                        end

    end))
    input.registerTriggerHandler("P"..i.."HealthPotion", async:callback(function () 
                                                                        if Players[i] then
                                                                            if Inventories[i] then
  --                                                                              print("PREVIOUS")
                                                                                local NewMenu
                                                                                for j, menu in pairs(Menus) do
                                                                                    if menu==Inventories[i].layout.content[1].content["Menus"].props.Menu then
                                                                                        if Menus[j-1] then
                                                                                            NewMenu=Menus[j-1]
                                                                                        else
                                                                                            NewMenu=Menus[#Menus]
                                                                                        end
                                                                                    end
                                                                                end
                                                                                Inventories[i].layout.content[1].content["Menus"].props.Menu=NewMenu


                                                                                for j, menu in pairs(Menus) do
                                                                                    if menu==Inventories[i].layout.content[1].content["Menus"].props.Menu then
                                                                                        Inventories[i].layout.content[1].content["Menus"].content[menu].props.visible=true
                                                                                        Inventories[i].layout.content[1].content["Categories"].content[menu].template=I.MWUI.templates.boxTransparent
                                                                                    else
                                                                                        Inventories[i].layout.content[1].content["Menus"].content[menu].props.visible=false
                                                                                        Inventories[i].layout.content[1].content["Categories"].content[menu].template=nil
                                                                                    end
                                                                                end
                                                                                Inventories[i].layout.content[1].content["Menus"].content[NewMenu].props.relativePosition=util.vector2(0.5,0)
                                                                                updateInventoryUI(Inventories[i],Players[i],Players[i])

                                                                                ambient.playSoundFile("sound/fx/item/bookpage1.wav")
                                                                                Inventories[i]:update()

                                                                            elseif Barter[i] then
  --                                                                              print("PREVIOUS")
                                                                                local NewMenu
                                                                                for j, menu in pairs(Menus) do
                                                                                    if menu==Barter[i].layout.content[1].content["Menus"].props.Menu then
                                                                                        if Menus[j-1] then
                                                                                            NewMenu=Menus[j-1]
                                                                                        else
                                                                                            NewMenu=Menus[#Menus]
                                                                                        end
                                                                                    end
                                                                                end
                                                                                Barter[i].layout.content[1].content["Menus"].props.Menu=NewMenu


                                                                                for j, menu in pairs(Menus) do
                                                                                    if menu==Barter[i].layout.content[1].content["Menus"].props.Menu then
                                                                                        Barter[i].layout.content[1].content["Menus"].content[menu].props.visible=true
                                                                                        Barter[i].layout.content[1].content["Categories"].content[menu].template=I.MWUI.templates.boxTransparent
                                                                                    else
                                                                                        Barter[i].layout.content[1].content["Menus"].content[menu].props.visible=false
                                                                                        Barter[i].layout.content[1].content["Categories"].content[menu].template=nil
                                                                                    end
                                                                                end
                                                                                Barter[i].layout.content[1].content["Menus"].content[NewMenu].props.relativePosition=util.vector2(0.5,0)
                                                                                if Barter[i].layout.content[1].content["Menus"].props.Barter=="Buy" then
                                                                                    updateInventoryUI(Barter[i],Players[i],LastMerchant)
                                                                                else
                                                                                    updateInventoryUI(Barter[i],Players[i],Players[i])
                                                                                end
                                                                                ambient.playSoundFile("sound/fx/item/bookpage1.wav")
                                                                                Barter[i]:update()

                                                                            elseif types.Actor.stats.dynamic.health(Players[i]).current<types.Actor.stats.dynamic.health(Players[i]).base then
                                                                                for _, potion in pairs(types.Actor.inventory(Players[i]):getAll(types.Potion)) do
                                                                                    for _, effect in pairs(types.Potion.records[potion.recordId].effects) do
                                                                                        if effect.effect.id==core.magic.EFFECT_TYPE.RestoreHealth then
                                                                                            core.sendGlobalEvent('UseItem', {object = potion, actor = Players[i], force = true})
                                                                                            break
                                                                                        end
                                                                                    end
                                                                                end
                                                                            end
                                                                        end

    end))
    input.registerTriggerHandler("P"..i.."Inventory", async:callback(function () 
                                                                    if Players[i] then
  --                                                                      print(Players[i],"Inventory")
                                                                        if Barter[i] then
                                                                            local ActiveBarter=0
                                                                            for i, inventory in pairs(Barter) do
                                                                                ActiveBarter=ActiveBarter+1
                                                                            end
                                                                            if ActiveBarter==1 then
                                                                                I.UI.removeMode('Interface')
                                                                            end
                                                                            Barter[i]:destroy()
                                                                            Barter[i]=nil
                                                                        
                                                                        elseif Inventories[i] then
                                                                            PlayersUI[i].layout.content["AvatarName"].props.alpha=1
                                                                            
                                                                            local ActiveInventories=0
                                                                            for i, inventory in pairs(Inventories) do
                                                                                ActiveInventories=ActiveInventories+1
                                                                            end
                                                                            if ActiveInventories==1 then
                                                                                I.UI.removeMode('Interface')
                                                                            end
  --                                                                          print("DESTROY")
                                                                            Inventories[i]:destroy()
                                                                            Inventories[i]=nil

                                                                        else
                                                                            Inventories[i]=ui.create(CreateInventory(i))
                                                                            updateInventoryUI(Inventories[i],Players[i],Players[i])
                                                                            
                                                                        end
                                                                    end



    end))
end

for i=1,4 do
    DeclareRedisterTriggerHandler(i)
end

local function DeclarePlayers(data)
    Players=data.Players
    for i, player in pairs(Players) do
        NbrPlayers=i
        AvatarsStats[player.recordId]={}
        AvatarsStats[player.recordId].Exp=0
        AvatarsStats[player.recordId].AttributePoints=0
        AvatarsStats[player.recordId].SkillsPoints=0

--        LastWeapon[player.recordId]=types.Actor.getEquipment(player,types.Actor.EQUIPMENT_SLOT.CarriedRight)
--        if i>1 then
--            DeclareRedisterTriggerHandler(i)
--        end
    end
    CreatePlayersUI()
end


local function onSave()
	return{Players=Players,AvatarsStats=AvatarsStats, LastWeapon=LastWeapon}
end

local function onLoad(data)
    if data.Players then
        Players=data.Players
        for i, player in pairs(Players) do
            NbrPlayers=i
--            if i>1 then
--                DeclareRedisterTriggerHandler(i)
--            end
        end
    end
    if data.LastWeapon then
        LastWeapon=data.LastWeapon
    end
    if data.AvatarsStats then
        AvatarsStats=data.AvatarsStats
    end
    CreatePlayersUI()
end

local function CoVReanimate(data)
    Players[data.AvatarNbr]=data.Avatar
end

return {
	eventHandlers = {
                        DeclarePlayers=DeclarePlayers,
                        ShowDamage=ShowDamage,
                        TakeCoins=TakeCoins,
                        ActivatorsForAvatarSelection=ActivatorsForAvatarSelection,
                        CoVAddXp=CoVAddXp,
                        CoVReanimate=CoVReanimate


					},
	engineHandlers = {
                        onUpdate=onUpdate,
                        onSave=onSave,
                        onLoad=onLoad,

	}

}

