local self=require('openmw.self')
local ui=require('openmw.ui')
local core=require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local async = require('openmw.async')
local interfaces = require('openmw.interfaces')
local input = require('openmw.input')

TitleEditing=nil
TitleBox=nil
TextEditing=nil
TextBox=nil
Button=nil
Book=nil
Pagejump="<BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR> "

local function TextClick(mouseEvent, data)
	TextBox:destroy()
	print(Book)
	if string.find(types.Book.record(Book).text,Pagejump) and Text then
		Text=string.gsub(types.Book.record(Book).text,Pagejump..Pagejump..Pagejump..Pagejump,"").."<BR>"..Text
		core.sendGlobalEvent('CreateWritting', {actor=self,Book=Book,scroll=types.Book.record(Book).isScroll, Title=types.Book.record(Book).name, Text=Text})
	else
		core.sendGlobalEvent('CreateWritting', {actor=self,Book=Book,scroll=types.Book.record(Book).isScroll, Title=Title, Text=Text})
	end
end


local function TitleClick(mouseEvent, data)
	

	if TitleBox then
		TitleBox:destroy()
		print(Title)
	end
	TextEditing={template = interfaces.MWUI.templates.textEditBox,name="text",layer='Windows', type = ui.TYPE.TextEdit,props = {autoSize=false,relativeSize = util.vector2(300/600,200/500),multiline=true,relativePosition=util.vector2(0.5, 0.5),anchor = util.vector2(0.5, 0.5),text="*your text here*",textSize=30,textColor=util.color.rgb(0.5,0.5,0.5)},events={textChanged=async:callback(function(text) Text=text end)}}
	Button={name="textbutton",layer='Windows', type = ui.TYPE.Text,props = {autoSize=true,relativePosition=util.vector2(1, 0),anchor = util.vector2(-1, 0.5),text="Validate Text",textSize=40,textColor=util.color.rgb(0.5,0.5,0.5)},events={mousePress = async:callback(TextClick)}}
	TextBox=ui.create({name="TextBox",layer='Windows',type=ui.TYPE.Flex,props={autoSize=false,arrange=ui.ALIGNMENT.Center,relativeSize = util.vector2(300/600,200/520),relativePosition = util.vector2(1/2, 3/5),anchor = util.vector2(1/2, 1/2)},content=ui.content{TextEditing,Button}})

end


local function Write(data)
	Text=""
	Book=data.Book
	print(Book)
	if string.find(types.Book.record(Book).text,Pagejump)==nil then
		TitleEditing={template = interfaces.MWUI.templates.textEditBox,name="title",layer='Windows', type = ui.TYPE.TextEdit,props = {autoSize=false,relativeSize = util.vector2(300/600,200/500),multiline=true,relativePosition=util.vector2(0.5, 0.5),anchor = util.vector2(0.5, 0.5),text="*your title here*",textSize=30,textColor=util.color.rgb(0.5,0.5,0.5)},events={textChanged=async:callback(function(text) Title=text end)}}
		Button={name="titlebutton",layer='Windows', type = ui.TYPE.Text,props = {autoSize=true,relativePosition=util.vector2(1, 0),anchor = util.vector2(0.5, 0.5),text="Validate Title",textSize=40,textColor=util.color.rgb(0.5,0.5,0.5)},events={mousePress = async:callback(TitleClick)}}
		TitleBox=ui.create({name="TitleBox",layer='Windows',type=ui.TYPE.Flex,props={autoSize=false,arrange=ui.ALIGNMENT.Center,relativeSize = util.vector2(300/600,200/520),relativePosition = util.vector2(1/2, 3/5),anchor = util.vector2(1/2, 1/2)},content=ui.content{TitleEditing,Button}})
	else
		TitleClick()
	end
end





local function onFrame()
	if not(interfaces.UI.getMode()=="Scroll") and not(interfaces.UI.getMode()=="Book") then
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
end

return {
	eventHandlers = {Write=Write,},
	engineHandlers = {

        onFrame = onFrame,
	}

}