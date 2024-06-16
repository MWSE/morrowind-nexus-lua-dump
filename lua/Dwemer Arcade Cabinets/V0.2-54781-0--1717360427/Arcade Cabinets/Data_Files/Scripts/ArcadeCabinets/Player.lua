local self=require('openmw.self')
local ui=require('openmw.ui')
local core=require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local ambient = require('openmw.ambient')





local screen_width = ui.screenSize().x
local screen_height = ui.screenSize().y

local paddle_1_width = 20/500
local paddle_1_height = 70/300
local paddle_1_x = 0
local paddle_1_y = ((screen_height / 2) -  (paddle_1_height / 2))/screen_height
local paddle_1_speed = 1--400

local paddle_2_width = 20/500
local paddle_2_height = 70/300
local paddle_2_x = (1- paddle_2_width)
local paddle_2_y = ((screen_height / 2) -  (paddle_1_height / 2))/screen_height
local paddle_2_speed = 1--400

local ball_width = 20/500
local ball_height = 20/300
local ball_x = ((1 / 2) - (ball_width / 2))
local ball_y = ((1 / 2) - (ball_height / 2))
local ball_speed_x = -0.1---200
local ball_speed_y = 0.1--200
local ball_speed_modifier=0.2

local Pong={}
local PongTimer={}



local Catch={}
local CatchTimer={}
local PointsValue=0
local CatchVFall=0.005
local CatchVUp=0.005
local CatchVDown=100
local CatchUp1=CatchVUp-0.001
local CatchUp2=-CatchVUp

local J2=false


local Bird={}
local BirdTimer={}
local BirdJumpJ1=false
local BirdTargetJumpJ1=false
local BirdJumpJ2=false
local BirdTargetJumpJ2=false


local function CheckPointInSquare(PUI1,UI2)
	local P0=UI2.props.relativePosition
	local P2=UI2.props.relativePosition+UI2.props.relativeSize
	if PUI1.y>=P0.y and PUI1.y<=P2.y and PUI1.x<=P2.x and PUI1.x>=P0.x then
		return(true)
	end

end

local function Collision(UI1,UI2)
	if CheckPointInSquare(UI1.props.relativePosition,UI2) 
		or CheckPointInSquare(util.vector2(UI1.props.relativePosition.x+UI1.props.relativeSize.x,UI1.props.relativePosition.y),UI2) 
		or CheckPointInSquare(UI1.props.relativePosition+UI1.props.relativeSize,UI2) 
		or CheckPointInSquare(util.vector2(UI1.props.relativePosition.x,UI1.props.relativePosition.y+UI1.props.relativeSize.y),UI2) then
		return(true)
	end

end	

local function CatchFall(objet)
	if Catch.layout then
		if Catch.layout.content[objet].props.visible==true then
			Catch.layout.content[objet].props.relativePosition=util.vector2(Catch.layout.content[objet].props.relativePosition.x,Catch.layout.content[objet].props.relativePosition.y+CatchVFall*(objet/7))
		end
		if (Catch.layout.content[1].props.relativePosition-Catch.layout.content[objet].props.relativePosition):length()<0.05 or (Catch.layout.content[2].props.relativePosition-Catch.layout.content[objet].props.relativePosition):length()<0.05 or Catch.layout.content[objet].props.relativePosition.y>0.95 then
			if Catch.layout.content[objet].props.relativePosition.y>0.95 then
				ambient.playSound("ArcadeLoose")
				Catch:destroy()
				Catch={}
				CatchTimer={}
				I.UI.removeMode(I.UI.MODE.Interface)
			else
				ambient.playSound("PongHit"..math.random(2))
				PointsValue=PointsValue+1
				Catch.layout.content[5].props.text=tostring(PointsValue)
				if math.random(2)==1 then
					Catch.layout.content[objet].props.relativePosition=util.vector2(Catch.layout.content[3].props.relativePosition.x,Catch.layout.content[4].props.relativePosition.y)
				else
					Catch.layout.content[objet].props.relativePosition=util.vector2(Catch.layout.content[4].props.relativePosition.x,Catch.layout.content[4].props.relativePosition.y)
				end
				
				ambient.playSound("CatchFall")
			end

		end
		Catch:update()
	end

end



local function ArcadeCabinet(data)
	if types.Actor.inventory(self):find("misc_dwrv_coin00") then
		ui.showMessage("You insert a dwemer coin")
		ambient.playSound("InsertCoin")
		core.sendGlobalEvent("Remove",{object=types.Actor.inventory(self):find("misc_dwrv_coin00"),number=1})
		J2=false
		if data.Game==0 and Catch.layout==nil then
			PointsValue=0
			CatchVFall=0.005
			I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
			Catch=ui.create({layer = 'Windows', type = ui.TYPE.Image, 
			props = {color=util.color.rgb(0, 0, 0), autoSize=true, relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0, 0), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },
			content=ui.content{
				{type = ui.TYPE.Image, props = {  color=util.color.rgb(0, 1, 0), visible=true, autoSize=true, relativeSize = util.vector2(0.1, 0.05), relativePosition = util.vector2(0.5, 0.95), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },},
				{type = ui.TYPE.Image, props = {  color=util.color.rgb(0, 0, 1),visible=true, autoSize=true, relativeSize = util.vector2(0.1, 0.05), relativePosition = util.vector2(0.98, 0.95), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },},
				{type = ui.TYPE.Image, props = { visible=true, autoSize=true, relativeSize = util.vector2(0.1, 0.1), relativePosition = util.vector2(0.5, 0), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },},
				{type = ui.TYPE.Image, props = { visible=true, autoSize=true, relativeSize = util.vector2(0.1, 0.1), relativePosition = util.vector2(0.5, 0), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },},
				{type = ui.TYPE.Text, props = {textSize = 35, textColor = util.color.rgb(1, 1, 1), visible=true, autoSize=true, relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0, 0), anchor = (util.vector2(0, 0)), text=tostring(PointsValue)},},
				{type = ui.TYPE.Image, props = { visible=true, autoSize=true, relativeSize = util.vector2(0.05, 0.05), relativePosition = util.vector2(0.5, 0), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },},
				{type = ui.TYPE.Image, props = { visible=true, autoSize=true, relativeSize = util.vector2(0.05, 0.05), relativePosition = util.vector2(0.5, 0), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },},
				{type = ui.TYPE.Image, props = { visible=true, autoSize=true, relativeSize = util.vector2(0.05, 0.05), relativePosition = util.vector2(0.5, 0), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },},
			   
			}})	
			ambient.playSound("CatchFall")


		elseif data.Game==1 and Bird.layout==nil then
			PointsValue=0
			BirdJumpJ1=false
			BirdJumpJ2=false
			I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
			Bird=ui.create({layer = 'Windows', type = ui.TYPE.Image, 
			props = { color=util.color.rgb(0.5, 0.5, 1), autoSize=true, relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0, 0), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },
			content=ui.content{
				{type = ui.TYPE.Image, props = {  color=util.color.rgb(1, 1, 0), visible=true, autoSize=true, relativeSize = util.vector2(0.05, 0.05), relativePosition = util.vector2(0.1, 0.5), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },},
				{type = ui.TYPE.Image, props = {  color=util.color.rgb(0, 1, 1),visible=false, autoSize=true, relativeSize = util.vector2(0.05, 0.05), relativePosition = util.vector2(0.1, 0.5), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },},
				{type = ui.TYPE.Image, props = { color=util.color.rgb(0, 1, 0), visible=true, autoSize=true, relativeSize = util.vector2(0.08, 0.8), relativePosition = util.vector2(0.6, -0.4), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },},
				{type = ui.TYPE.Image, props = { color=util.color.rgb(0, 1, 0), visible=true, autoSize=true, relativeSize = util.vector2(0.08, 0.8), relativePosition = util.vector2(0.6, 0.6), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },},
				{type = ui.TYPE.Image, props = { color=util.color.rgb(0, 1, 0), visible=true, autoSize=true, relativeSize = util.vector2(0.08, 0.8), relativePosition = util.vector2(1.1, -0.4), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },},
				{type = ui.TYPE.Image, props = { color=util.color.rgb(0, 1, 0), visible=true, autoSize=true, relativeSize = util.vector2(0.08, 0.8), relativePosition = util.vector2(1.1, 0.6), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },},
				{type = ui.TYPE.Text, props = { textSize = 35, textColor = util.color.rgb(1, 1, 1), visible=true, autoSize=true, relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0, 0), anchor = (util.vector2(0, 0)), text=tostring(PointsValue)},},
				
			   
			}})	
			
			BirdTimer[1]=core.getRealTime()
			PointsValue=0

		elseif data.Game==2 and Pong.layout==nil then
			I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
			Pong=ui.create({layer = 'Windows', type = ui.TYPE.Image, 
			props = { color=util.color.rgb(0, 0, 0),autoSize=true, relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0, 0), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },
			content=ui.content{
				{type = ui.TYPE.Image, props = { visible=true, autoSize=true, relativeSize = util.vector2(paddle_1_width, paddle_1_height), relativePosition = util.vector2(paddle_1_x, paddle_1_y), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },},
				{type = ui.TYPE.Image, props = { visible=true, autoSize=true, relativeSize = util.vector2(paddle_2_width, paddle_2_height), relativePosition = util.vector2(paddle_2_x, paddle_2_y), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },},
				{type = ui.TYPE.Image, props = { visible=true, autoSize=true, relativeSize = util.vector2(ball_width, ball_height), relativePosition = util.vector2(ball_x, ball_y), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },},
			}})
			print(Pong.layout.layer)
			PongTimer[1]=core.getRealTime()

			paddle_1_x = 0
			paddle_1_y = ((screen_height / 2) -  (paddle_1_height / 2))/screen_height
			paddle_1_speed = 1--400

			paddle_2_x = (1- paddle_2_width)
			paddle_2_y = ((screen_height / 2) -  (paddle_1_height / 2))/screen_height
			paddle_2_speed = 1--400

			ball_x = ((1 / 2) - (ball_width / 2))
			ball_y = ((1 / 2) - (ball_height / 2))
			ball_speed_x = -0.1---200
			ball_speed_y = 0.1--200
		end
	else
		ui.showMessage("You need to insert a dwemer coin")
	end
end

local function onFrame(dt)
	if Catch.layout then
		if J2==true then
			CatchVFall=0.007
		end
        if Catch.layout.content[3].props.relativePosition.x>.95 then
            CatchUp1=-CatchVUp+0.001
        elseif Catch.layout.content[3].props.relativePosition.x<0.05 then
            CatchUp1=CatchVUp-0.001
        end
        if Catch.layout.content[4].props.relativePosition.x>0.95 then
            CatchUp2=-CatchVUp
        elseif Catch.layout.content[4].props.relativePosition.x<0.05 then
            CatchUp2=CatchVUp
        end
        Catch.layout.content[3].props.relativePosition=util.vector2(Catch.layout.content[3].props.relativePosition.x+CatchUp1,0)
        Catch.layout.content[4].props.relativePosition=util.vector2(Catch.layout.content[4].props.relativePosition.x+CatchUp2,0)

		if input.isActionPressed(input.ACTION.MoveRight) and (Catch.layout.content[1].props.relativePosition.x+1/CatchVDown)<0.95 then
        	Catch.layout.content[1].props.relativePosition=util.vector2(Catch.layout.content[1].props.relativePosition.x+1/CatchVDown,0.95)
		elseif input.isActionPressed(input.ACTION.MoveLeft) and (Catch.layout.content[1].props.relativePosition.x-1/CatchVDown)>0  then
        	Catch.layout.content[1].props.relativePosition=util.vector2(Catch.layout.content[1].props.relativePosition.x-1/CatchVDown,0.95)
		end

		if input.isActionPressed(input.ACTION.QuickKey2) and (Catch.layout.content[2].props.relativePosition.x+1/CatchVDown)<0.95 then
			J2=true
        	Catch.layout.content[2].props.relativePosition=util.vector2(Catch.layout.content[2].props.relativePosition.x+1/CatchVDown,0.95)
		elseif input.isActionPressed(input.ACTION.QuickKey1) and (Catch.layout.content[2].props.relativePosition.x-1/CatchVDown)>0  then
			J2=true
        	Catch.layout.content[2].props.relativePosition=util.vector2(Catch.layout.content[2].props.relativePosition.x-1/CatchVDown,0.95)
		end

		CatchFall(6)
		CatchFall(7)
		CatchFall(8)
			
		if I.UI.getMode() == nil then
			if CatchTimer[2]==nil  then
				CatchTimer[2]=true
			else
				Catch:destroy()
				Catch={}
				CatchTimer={}
			end
		end
		CatchTimer[1]=core.getRealTime()

	elseif Bird.layout then
				
		if I.UI.getMode() == nil then
			if BirdTimer[2]==nil  then
				BirdTimer[2]=true
			elseif Bird.layout then
				Bird:destroy()
				Bird={}
				BirdTimer={}
			end
		end

		Bird.layout.content[3].props.relativePosition=util.vector2(Bird.layout.content[3].props.relativePosition.x-(core.getRealTime()-BirdTimer[1])*0.1,Bird.layout.content[3].props.relativePosition.y)
		Bird.layout.content[4].props.relativePosition=util.vector2(Bird.layout.content[4].props.relativePosition.x-(core.getRealTime()-BirdTimer[1])*0.1,Bird.layout.content[4].props.relativePosition.y)
		Bird.layout.content[5].props.relativePosition=util.vector2(Bird.layout.content[5].props.relativePosition.x-(core.getRealTime()-BirdTimer[1])*0.1,Bird.layout.content[5].props.relativePosition.y)
		Bird.layout.content[6].props.relativePosition=util.vector2(Bird.layout.content[6].props.relativePosition.x-(core.getRealTime()-BirdTimer[1])*0.1,Bird.layout.content[6].props.relativePosition.y)

		if Bird.layout.content[3].props.relativePosition.x<=0 then
			Bird.layout.content[3].props.relativePosition=util.vector2(1,math.random(2,7)/10-0.8)
			Bird.layout.content[4].props.relativePosition=util.vector2(1,Bird.layout.content[3].props.relativePosition.y+1)
			PointsValue=PointsValue+1
			Bird.layout.content[7].props.text=tostring(PointsValue)
		end
		if Bird.layout.content[5].props.relativePosition.x<=0 then
			Bird.layout.content[5].props.relativePosition=util.vector2(1,math.random(2,7)/10-0.8)
			Bird.layout.content[6].props.relativePosition=util.vector2(1,Bird.layout.content[5].props.relativePosition.y+1)
			PointsValue=PointsValue+1
			Bird.layout.content[7].props.text=tostring(PointsValue)
		end


		if input.isActionPressed(input.ACTION.MoveForward) and BirdJumpJ2==false then	
			ambient.playSound("Ponghit1")
			J2=true
			BirdJumpJ2=true
			BirdTargetJumpJ2=Bird.layout.content[2].props.relativePosition.y-0.1
			Bird.layout.content[2].props.visible=true
		end

		
		if J2==false then
			Bird.layout.content[2].props.relativePosition=Bird.layout.content[1].props.relativePosition
		elseif BirdJumpJ2==true then
			if Bird.layout.content[2].props.relativePosition.y>BirdTargetJumpJ2 then
				Bird.layout.content[2].props.relativePosition=util.vector2(0.4,Bird.layout.content[2].props.relativePosition.y-(core.getRealTime()-BirdTimer[1])*0.3)
			else 
				BirdJumpJ2=false
			end
		else
			Bird.layout.content[2].props.relativePosition=util.vector2(0.4,Bird.layout.content[2].props.relativePosition.y+(core.getRealTime()-BirdTimer[1])*0.1)
		end



		if input.isActionPressed(input.ACTION.Jump) and BirdJumpJ1==false then
			ambient.playSound("Ponghit2")
			BirdJumpJ1=true
			BirdTargetJumpJ1=Bird.layout.content[1].props.relativePosition.y-0.1
		end

		if BirdJumpJ1==true then
			if Bird.layout.content[1].props.relativePosition.y>BirdTargetJumpJ1 then
				Bird.layout.content[1].props.relativePosition=util.vector2(0.4,Bird.layout.content[1].props.relativePosition.y-(core.getRealTime()-BirdTimer[1])*0.3)
			else 
				BirdJumpJ1=false
			end
		else
			Bird.layout.content[1].props.relativePosition=util.vector2(0.4,Bird.layout.content[1].props.relativePosition.y+(core.getRealTime()-BirdTimer[1])*0.1)
		end

		
		Bird:update()
		BirdTimer[1]=core.getRealTime()

		
		if Bird.layout.content[1].props.relativePosition.y<0 or (Bird.layout.content[1].props.relativePosition.y>(1-Bird.layout.content[1].props.relativeSize.y)) or Collision(Bird.layout.content[1],Bird.layout.content[3]) or Collision(Bird.layout.content[1],Bird.layout.content[4]) or Collision(Bird.layout.content[1],Bird.layout.content[5]) or Collision(Bird.layout.content[1],Bird.layout.content[6]) then	
			Bird:destroy()
			Bird={}
			I.UI.removeMode(I.UI.MODE.Interface)
			BirdTimer={}
			ambient.playSound("ArcadeLoose")
		end

		if J2 then
			if Bird.layout.content[2].props.relativePosition.y<0 or (Bird.layout.content[2].props.relativePosition.y>(1-Bird.layout.content[2].props.relativeSize.y)) or Collision(Bird.layout.content[2],Bird.layout.content[3]) or Collision(Bird.layout.content[2],Bird.layout.content[4]) or Collision(Bird.layout.content[2],Bird.layout.content[5]) or Collision(Bird.layout.content[2],Bird.layout.content[6]) then	
				Bird:destroy()
				Bird={}
				BirdTimer={}
				I.UI.removeMode(I.UI.MODE.Interface)
				ambient.playSound("ArcadeLoose")
			end
		end



	elseif Pong.layout then

		if input.isActionPressed(input.ACTION.MoveForward) then
			paddle_1_y = paddle_1_y - (paddle_1_speed * (core.getRealTime()-PongTimer[1]))
		end
		if input.isActionPressed(input.ACTION.MoveBackward) then
			paddle_1_y = paddle_1_y + (paddle_1_speed * (core.getRealTime()-PongTimer[1]))
		end
	
		if J2==false then 
			if Pong.layout.content[2].props.relativePosition.y+0.01>Pong.layout.content[3].props.relativePosition.y then
				paddle_2_y = paddle_2_y - (paddle_2_speed * (core.getRealTime()-PongTimer[1]))
			end
			if Pong.layout.content[2].props.relativePosition.y-0.01<Pong.layout.content[3].props.relativePosition.y then
				paddle_2_y = paddle_2_y + (paddle_2_speed * (core.getRealTime()-PongTimer[1]))
			end
			if input.isActionPressed(input.ACTION.QuickKey1) or input.isActionPressed(input.ACTION.QuickKey2) then
				J2=true
			end
		elseif J2==true then
			if input.isActionPressed(input.ACTION.QuickKey1) then
				paddle_2_y = paddle_2_y - (paddle_2_speed * (core.getRealTime()-PongTimer[1]))
			end
			if input.isActionPressed(input.ACTION.QuickKey2) then
				paddle_2_y = paddle_2_y + (paddle_2_speed * (core.getRealTime()-PongTimer[1]))
			end
		end



		if paddle_1_y < 0 then
			paddle_1_y = 0
		elseif (paddle_1_y + paddle_1_height) > 1 then
			paddle_1_y = 1 - paddle_1_height
		end
	
		-- NEW
		if paddle_2_y < 0 then
			paddle_2_y = 0
		elseif (paddle_2_y + paddle_2_height) > 1 then
			paddle_2_y = 1 - paddle_2_height
		end
		--
	
		if ball_y < 0 then
			ball_speed_y = math.abs(ball_speed_y+ball_speed_modifier)
			ambient.playSound("Ponghit"..math.random(2))
		elseif (ball_y + ball_height) > 1  then
			ball_speed_y = -math.abs(ball_speed_y+ball_speed_modifier)
			ambient.playSound("Ponghit"..math.random(2))
		end
	
		if ball_x <= paddle_1_width and
			(ball_y + ball_height) >= paddle_1_y and
			ball_y < (paddle_1_y + paddle_1_height)
		then
			ball_speed_x = math.abs(ball_speed_x+ball_speed_modifier)
			ambient.playSound("Ponghit"..math.random(2))
		end
	
		-- NEW
		if (ball_x + ball_width) >= (1 - paddle_2_width) and
			(ball_y + ball_height) >= paddle_2_y and
			ball_y < (paddle_2_y + paddle_2_height)
		then
			ball_speed_x = -math.abs(ball_speed_x+ball_speed_modifier)
			ambient.playSound("Ponghit"..math.random(2))
		end
		--
	
		if ball_x > 1 then
			ball_x = (1 / 2) - (ball_width / 2)
			ball_y = (1 / 2) - (ball_height / 2)
			ball_speed_x = -0.1---200
			ball_speed_y = 0.1--200
		elseif ball_x + ball_width < 0  then
			Pong:destroy()
			Pong={}
			I.UI.removeMode(I.UI.MODE.Interface)
			PongTimer={}
			ambient.playSound("ArcadeLoose")
		end
		--print(ball_speed_x)
		--print(ball_speed_y)

		ball_x = ball_x + (ball_speed_x * (core.getRealTime()-PongTimer[1]))
		ball_y = ball_y + (ball_speed_y * (core.getRealTime()-PongTimer[1]))
		Pong.layout.content=ui.content{
            {type = ui.TYPE.Image, props = { visible=true, autoSize=true, relativeSize = util.vector2(paddle_1_width, paddle_1_height), relativePosition = util.vector2(paddle_1_x, paddle_1_y), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },},
            {type = ui.TYPE.Image, props = { visible=true, autoSize=true, relativeSize = util.vector2(paddle_2_width, paddle_2_height), relativePosition = util.vector2(paddle_2_x, paddle_2_y), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },},
            {type = ui.TYPE.Image, props = { visible=true, autoSize=true, relativeSize = util.vector2(ball_width, ball_height), relativePosition = util.vector2(ball_x, ball_y), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/pixel.png" }, },},
        }
		Pong:update()

		if I.UI.getMode() == nil then
			if PongTimer[2]==nil  then
				PongTimer[2]=true
			else
				Pong:destroy()
				Pong={}
				PongTimer={}
			end
		end
	PongTimer[1]=core.getRealTime()
	end

end

return {
	eventHandlers = {ArcadeCabinet=ArcadeCabinet},
	engineHandlers = {

        onFrame = onFrame,
	}

}