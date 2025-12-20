local self=require('openmw.self')
local ui=require('openmw.ui')
local core=require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local ambient = require('openmw.ambient')


local Color=util.color.rgb(0.4,0.4,0.4)
local TitleBox=nil
local TextBox=nil
local Book=nil
Title=nil
Text=nil
local Pagejump="<BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR> "

local function TextClick(mouseEvent, data)
    ambient.playSound("book close")
	TextBox:destroy()
	if types.Book.records[Book.recordId].text=="" or types.Book.records[Book.recordId].text==nil or types.Book.records[Book.recordId].text=="<BR><BR>" or types.Book.records[Book.recordId].name=="" or  types.Book.records[Book.recordId].name==nil then
		Text=types.Book.records[Book.recordId].text.."<BR>"..Text
		core.sendGlobalEvent('CreateWritting', {actor=self,Book=Book, Title=Title, Text=string.gsub(Text,Pagejump,"")})
	else
		core.sendGlobalEvent('CreateWritting', {actor=self,Book=Book, Title=types.Book.records[Book.recordId].name, Text=string.gsub(types.Book.records[Book.recordId].text,Pagejump,"").."<BR>"..Text})
	end
	TitleBox=nil
	TextBox=nil
	Book=nil
	Title=nil
	Text=nil
end


local function TitleClick(mouseEvent, data)
    ambient.playSound("book open")

	if TitleBox then
		TitleBox:destroy()
	end
	local BKGPath="textures/scroll.dds"
	if types.Book.records[Book.recordId].isScroll==false then
		BKGPath="textures/tx_menubook.dds"
	end
	local TextEditing={template = I.MWUI.templates.textEditBox,name="text",layer='Windows', type = ui.TYPE.TextEdit,props = {autoSize=false,relativeSize = util.vector2(0.6,3/5),multiline=true,relativePosition=util.vector2(0.5, 0.5),anchor = util.vector2(0.5, 0.5),text="*Your text here*",textSize=30,textColor=Color},events={textChanged=async:callback(function(text) Text=text end)}}
	local Button={name="TitleButton",
				type=ui.TYPE.Container,
				template = I.MWUI.templates.boxThick,
				props={autoSize=true},
				events={mousePress = async:callback(TextClick)},
				content=ui.content{{template = I.MWUI.templates.textNormal,type = ui.TYPE.Text,props = {text="Validate Text",textSize=40,textColor=Color}}}}
	TextBox=ui.create({name="TextBox",
							layer='Windows',
							type=ui.TYPE.Image,
							props={relativeSize = util.vector2(0.75,0.75),relativePosition = util.vector2(1/2, 1/2),anchor = util.vector2(1/2, 1/2),resource = ui.texture{path =BKGPath }}, 
							content=ui.content{{type=ui.TYPE.Flex,
												props={	relativeSize = util.vector2(1,1), 
														relativePosition = util.vector2(1/2, 0.2),
														autoSize=false,
														arrange=ui.ALIGNMENT.Center, 
														anchor = util.vector2(1/2, 0)},
												content=ui.content{TextEditing,Button}}}})
end


local function Write(data)
	Text=""
	Book=data.Book
	if types.Book.records[Book.recordId].text=="" or types.Book.records[Book.recordId].text==nil or types.Book.records[Book.recordId].text=="<BR><BR>" or types.Book.records[Book.recordId].name=="" or  types.Book.records[Book.recordId].name==nil then
		local BKGPath="textures/scroll.dds"
		if types.Book.records[Book.recordId].isScroll==false then
			BKGPath="textures/tx_menubook.dds"
		end
		local TitleEditing={template = I.MWUI.templates.textEditBox,name="Title", type = ui.TYPE.TextEdit,props = {autoSize=false,relativeSize = util.vector2(0.6,3/5),multiline=true,relativePosition=util.vector2(0.5, 0.5),anchor = util.vector2(0.5, 0.5),text="*Your title here*",textSize=30,textColor=Color},events={textChanged=async:callback(function(text) Title=text end)}}
		local Button={name="TitleButton",
				type=ui.TYPE.Container,
				template = I.MWUI.templates.boxThick,
				props={autoSize=true},
				events={mousePress = async:callback(TitleClick)},
				content=ui.content{{template = I.MWUI.templates.textNormal,type = ui.TYPE.Text,props = {text="Validate Title",textSize=40,textColor=Color}}}}
		TitleBox=ui.create({name="TitleBox",
							layer='Windows',
							type=ui.TYPE.Image,
							props={relativeSize = util.vector2(0.75,0.75),relativePosition = util.vector2(1/2, 1/2),anchor = util.vector2(1/2, 1/2),resource = ui.texture{path =BKGPath }}, 
							content=ui.content{{type=ui.TYPE.Flex,
												props={	relativeSize = util.vector2(1,1), 
														relativePosition = util.vector2(1/2, 0.2),
														autoSize=false,
														arrange=ui.ALIGNMENT.Center, 
														anchor = util.vector2(1/2, 0)},
												content=ui.content{TitleEditing,Button}}}})
	else
		TitleClick()
	end
end



local WriteKeyState=false

local function onUpdate()


    if input.getBooleanActionValue('Write')==true and WriteKeyState==false then
        core.sendGlobalEvent("ApplyWriteKey",{Actor=self, Bolean=true})
        WriteKeyState=true
    elseif input.getBooleanActionValue('Write')==false and WriteKeyState==true then
        core.sendGlobalEvent("ApplyWriteKey",{Actor=self, Bolean=false})
        WriteKeyState=false
    end



----[[
	if not(I.UI.getMode()=="Interface") then
		if TitleBox then
			if TitleBox.layout then
				TitleBox:destroy()
			end
		end
		if TextBox then
			if TextBox.layout then
				TextBox:destroy()
			end
		end
	end
--]]--
end

return {
	eventHandlers = {Write=Write,
					},
	engineHandlers = {

        onUpdate = onUpdate,
	}

}