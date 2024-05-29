local func_table={}

local self = require('openmw.self')
local input = require('openmw.input')
local ui = require('openmw.ui')
local util = require('openmw.util')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local core = require('openmw.core')
local camera = require('openmw.camera')
local interfaces = require('openmw.interfaces')
local ambient = require('openmw.ambient')
local vfs = require("openmw.vfs")
local async = require('openmw.async')
local nearby = require('openmw.nearby')
local postprocessing = require('openmw.postprocessing')


local activeBkg
local activecam
local Switchzonepoints={}
local Mask=1
local MSKlistDepth={}
local ToggleButton=true
local CameraMenu
local White=util.color.rgb(1, 1, 1)
local Grey=util.color.rgb(0.5, 0.5, 0.5)
local textSizeRatio= ui.screenSize().y/1056
local ShowSwitchZone=0
local SwitchZonePointPastPosition={}
local ChangeSZ=0
local TargetCams={}

local TextEditBox2 = {
	type = ui.TYPE.TextEdit,
	props = {
		size = util.vector2(50, 25),
		textSize = 25,
		textColor = White,
		multiline = true,
		wordWrap = true,
	},}


function ChangeCam(activeBkg,MSKlist,activecam,BGDepth)
	core.sendGlobalEvent('changeCam',
		{
			CamPos=camera.getPosition(),
			CamPitch=camera.getPitch(),
			CamYaw=camera.getYaw(),
			ActivCam = activecam,
			Bgd = activeBkg,
			MSKList=MSKlist,
			player=self,
			BGDepth=BGDepth,

		})
end


local function TextSwitchZone(text)
	if (tonumber(text) and Switchzonepoints["SwitchZone"..text]) or text=="" then
		CameraMenu.layout.content[22].content[2].props.text=text
		if tonumber(text) then
			if text =="1" then
				CameraMenu.layout.content[22].content[3].props.text="(Red) to camera "
				CameraMenu.layout.content[22].content[4].props.text=Switchzonepoints["SwitchZone"..text].Camera
			elseif text=="2" then
				CameraMenu.layout.content[22].content[3].props.text="(Green) to camera "
				CameraMenu.layout.content[22].content[4].props.text=Switchzonepoints["SwitchZone"..text].Camera
			elseif text=="3" then
				CameraMenu.layout.content[22].content[3].props.text="(Blue) to camera "
				CameraMenu.layout.content[22].content[4].props.text=Switchzonepoints["SwitchZone"..text].Camera
			elseif text=="4" then
				CameraMenu.layout.content[22].content[3].props.text="(Yellow) to camera "
				CameraMenu.layout.content[22].content[4].props.text=Switchzonepoints["SwitchZone"..text].Camera
			end
			ChangeSZ=1
			CameraMenu.layout.content[22].content[4].props.text=tostring(Switchzonepoints["SwitchZone"..text].Camera)
			CameraMenu.layout.content[23].content[2].props.text=tostring(Switchzonepoints["SwitchZone"..text].Point0.position.x)
			CameraMenu.layout.content[23].content[4].props.text=tostring(Switchzonepoints["SwitchZone"..text].Point0.position.y)
			CameraMenu.layout.content[24].content[2].props.text=tostring(Switchzonepoints["SwitchZone"..text].Point1.position.x)
			CameraMenu.layout.content[24].content[4].props.text=tostring(Switchzonepoints["SwitchZone"..text].Point1.position.y)
			CameraMenu.layout.content[25].content[2].props.text=tostring(Switchzonepoints["SwitchZone"..text].Point2.position.x)
			CameraMenu.layout.content[25].content[4].props.text=tostring(Switchzonepoints["SwitchZone"..text].Point2.position.y)
			CameraMenu.layout.content[26].content[2].props.text=tostring(Switchzonepoints["SwitchZone"..text].Point3.position.x)
			CameraMenu.layout.content[26].content[4].props.text=tostring(Switchzonepoints["SwitchZone"..text].Point3.position.y)
			CameraMenu:update()
		elseif text==""  then
			CameraMenu.layout.content[22].content[3].props.text="to camera "
			CameraMenu.layout.content[22].content[4].props.text="nil"
			CameraMenu.layout.content[23].content[2].props.text="nil"
			CameraMenu.layout.content[23].content[4].props.text="nil"
			CameraMenu.layout.content[24].content[2].props.text="nil"
			CameraMenu.layout.content[24].content[4].props.text="nil"
			CameraMenu.layout.content[25].content[2].props.text="nil"
			CameraMenu.layout.content[25].content[4].props.text="nil"
			CameraMenu.layout.content[26].content[2].props.text="nil"
			CameraMenu.layout.content[26].content[4].props.text="nil"
		end
		CameraMenu:update()
	end
end

local function TextCam(text)
	CameraMenu.layout.content[22].content[4].props.text=text
	TargetCams["SwitchZone"..CameraMenu.layout.content[22].content[2].props.text]=text
	CameraMenu:update()
end

local function teleportPoint(UI,Point,X,Y)
	if  tonumber(X) or X=="" or X=="-" then
		CameraMenu.layout.content[UI].content[2].props.text=X
	end
	if  tonumber(Y) or Y=="" or Y=="-" then
		CameraMenu.layout.content[UI].content[4].props.text=Y
	end
	if tonumber(X) then
		print(X)
		core.sendGlobalEvent('Teleport',{object=Switchzonepoints["SwitchZone"..CameraMenu.layout.content[22].content[2].props.text]["Point"..Point],position=util.vector3(tonumber(X),tonumber(CameraMenu.layout.content[UI].content[4].props.text),self.position.z),rotation=nil})
	elseif tonumber(Y) then
		print(Y)
		core.sendGlobalEvent('Teleport',{object=Switchzonepoints["SwitchZone"..CameraMenu.layout.content[22].content[2].props.text]["Point"..Point],position=util.vector3(tonumber(CameraMenu.layout.content[UI].content[2].props.text),tonumber(Y),self.position.z),rotation=nil})
	end
end

func_table.PositionnningCamera=function(util,input,camera,core,BGDepth,activecam,activeBkg,MSKlist,TurnLeft,TurnRight,MoveForward,MoveBackward,SwitchZonePoints)
	
	-------------Move camera, background and masks
	if ShowSwitchZone==1 then
		--print(SwitchZonePoints[1])
		for s, switchzones in pairs(SwitchZonePoints) do
			if CameraMenu.layout then
				if s=="SwitchZone"..CameraMenu.layout.content[22].content[2].props.text and switchzones["Point0"] and switchzones["Point1"] and switchzones["Point2"] and switchzones["Point3"] then
					if SwitchZonePointPastPosition[s.."Point0"]~=switchzones["Point0"].position or SwitchZonePointPastPosition[s.."Point1"]~=switchzones["Point1"].position or SwitchZonePointPastPosition[s.."Point2"]~=switchzones["Point2"].position or  SwitchZonePointPastPosition[s.."Point3"]~=switchzones["Point3"].position or ChangeSZ==1 then
						core.sendGlobalEvent('CreateSwitchzoneBorders',{point1=switchzones["Point0"],point2=switchzones["Point1"],point3=switchzones["Point2"],point4=switchzones["Point3"],switchzone=s,player=self})
						SwitchZonePointPastPosition[s.."Point0"]=switchzones["Point0"].position
						SwitchZonePointPastPosition[s.."Point1"]=switchzones["Point1"].position
						SwitchZonePointPastPosition[s.."Point2"]=switchzones["Point2"].position
						SwitchZonePointPastPosition[s.."Point3"]=switchzones["Point3"].position
						ChangeSZ=0
						print(CameraMenu.layout.content[23].content[2].props.text)
						print(Switchzonepoints["SwitchZone"..CameraMenu.layout.content[22].content[2].props.text])
						CameraMenu.layout.content[23].content[2].props.text=tostring(Switchzonepoints["SwitchZone"..CameraMenu.layout.content[22].content[2].props.text].Point0.position.x)
						CameraMenu.layout.content[23].content[4].props.text=tostring(Switchzonepoints["SwitchZone"..CameraMenu.layout.content[22].content[2].props.text].Point0.position.y)
						CameraMenu.layout.content[24].content[2].props.text=tostring(Switchzonepoints["SwitchZone"..CameraMenu.layout.content[22].content[2].props.text].Point1.position.x)
						CameraMenu.layout.content[24].content[4].props.text=tostring(Switchzonepoints["SwitchZone"..CameraMenu.layout.content[22].content[2].props.text].Point1.position.y)
						CameraMenu.layout.content[25].content[2].props.text=tostring(Switchzonepoints["SwitchZone"..CameraMenu.layout.content[22].content[2].props.text].Point2.position.x)
						CameraMenu.layout.content[25].content[4].props.text=tostring(Switchzonepoints["SwitchZone"..CameraMenu.layout.content[22].content[2].props.text].Point2.position.y)
						CameraMenu.layout.content[26].content[2].props.text=tostring(Switchzonepoints["SwitchZone"..CameraMenu.layout.content[22].content[2].props.text].Point3.position.x)
						CameraMenu.layout.content[26].content[4].props.text=tostring(Switchzonepoints["SwitchZone"..CameraMenu.layout.content[22].content[2].props.text].Point3.position.y)
						CameraMenu:update()
					end
				end
			end
		end
	elseif SwitchZonePointPastPosition~=nil then
		SwitchZonePointPastPosition={}
	end

	if I.UI.getMode()=="MainMenu" and (CameraMenu==nil or CameraMenu.layout==nil) then
		TargetCams={}

		CameraMenu=ui.create{layer = 'Console',  type = ui.TYPE.Flex,props={relativePosition=util.vector2(7/10, 1/30), autoSize=true, anchor=util.vector2(0,0)},
							content=ui.content{
									{ type = ui.TYPE.Text,  props = { text = "0 : Camera placement tool", textSize = 25*textSizeRatio, textColor = White, visible = true} },
									{ type = ui.TYPE.Text,  props = { text = "P : Print datas (F10)", textSize = 25*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Text,  props = { text = "Right : Turn Camera Right (with fixed camera only)", textSize = 20*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Text,  props = { text = "Left : Turn Camera Left (with fixed camera only)", textSize = 20*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Text,  props = { text = "Forward : Turn Camera Up (with fixed camera only)", textSize = 20*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Text,  props = { text = "Back : Turn Camera Down (with fixed camera only)", textSize = 20*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Text,  props = { text = "9 : Move Camera (with fixed camera only)",relativePosition=util.vector2(2/16, 7/16), textSize = 25*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Text,  props = { text = "Right : Move Camera Right", textSize = 25*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Text,  props = { text = "Left : Move Camera Left", textSize = 25*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Text,  props = { text = "Forward : Move Camera Forward", textSize = 25*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Text,  props = { text = "Back : Move Camera Back", textSize = 25*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Text,  props = { text = "8 : Move Up/Down (with fixed camera only)", textSize = 20*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Text,  props = { text = "Forward : Move Camera Up", textSize = 25*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Text,  props = { text = "Back : Move Camera Down", textSize = 25*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Text,  props = { text = "M : Mask tool", textSize = 25*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Text,  props = { text = "Left/Right : Change Mask", textSize = 25*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Text,  props = { text = "Forward/Back : Change Mask's depth", textSize = 25*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Text,  props = { text = "B : Background tool", textSize = 25*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Text,  props = { text = "Forward/Back : Change Background's depth", textSize = 25*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Text,  props = { text = "H : Show Switchzones", textSize = 25*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Text,  props = { text = "T : Save Switchzones", textSize = 25*textSizeRatio, textColor = White, visible = false} },
									{ type = ui.TYPE.Flex,  props = { visible = false, autoZise=false, horizontal=true} ,content=ui.content{
																	{ type = ui.TYPE.Text,  props = { text = "SwitchZone ", textSize = 25*textSizeRatio, textColor = White, visible = true} },
																	{ template = TextEditBox2,type = ui.TYPE.TextEdit,props = {wordWrap = true, autoSize = true,text="1",textSize=25*textSizeRatio,textColor=Grey, visible = true},events={textChanged=async:callback(TextSwitchZone)}},
																	{ type = ui.TYPE.Text,  props = { text = "(Red) to camera ", textSize = 25*textSizeRatio, textColor = White, visible = true} },
																	{ template = TextEditBox2,type = ui.TYPE.TextEdit,props = {wordWrap = true, autoSize = true,text="Cam??",textSize=25*textSizeRatio,textColor=Grey, visible = true},events={textChanged=async:callback(TextCam)}},
																	},},
									{ type = ui.TYPE.Flex,  props = { visible = false, autoZise=false, horizontal=true} ,content=ui.content{
																	{ type = ui.TYPE.Text,  props = { text = "Point 0 X ", textSize = 25*textSizeRatio, textColor = White, visible = true} },
																	{ template = TextEditBox2,type = ui.TYPE.TextEdit,props = {text="0",textSize=25*textSizeRatio,textColor=Grey, visible = true},events={textChanged=async:callback(function(text) teleportPoint(23,0,text,nil) end)}},
																	{ type = ui.TYPE.Text,  props = { text = "Point 0 Y ", textSize = 25*textSizeRatio, textColor = White, visible = true} },
																	{ template = TextEditBox2,type = ui.TYPE.TextEdit,props = {text="0",textSize=25*textSizeRatio,textColor=Grey, visible = true},events={textChanged=async:callback(function(text) teleportPoint(23,0,nil,text) end)}}
																	},},
									{ type = ui.TYPE.Flex,  props = { visible = false, autoZise=false, horizontal=true} ,content=ui.content{
																	{ type = ui.TYPE.Text,  props = { text = "Point 1 X ", textSize = 25*textSizeRatio, textColor = White, visible = true} },
																	{ template = TextEditBox2,type = ui.TYPE.TextEdit,props = {text="0",textSize=25*textSizeRatio,textColor=Grey, visible = true},events={textChanged=async:callback(function(text) teleportPoint(24,1,text,nil) end)}},
																	{ type = ui.TYPE.Text,  props = { text = "Point 1 Y ", textSize = 25*textSizeRatio, textColor = White, visible = true} },
																	{ template = TextEditBox2,type = ui.TYPE.TextEdit,props = {text="0",textSize=25*textSizeRatio,textColor=Grey, visible = true},events={textChanged=async:callback(function(text)  teleportPoint(24,1,nil,text)end)}}
																	},},
									{ type = ui.TYPE.Flex,  props = { visible = false, autoZise=false, horizontal=true} ,content=ui.content{
																	{ type = ui.TYPE.Text,  props = { text = "Point 2 X ", textSize = 25*textSizeRatio, textColor = White, visible = true} },
																	{ template = TextEditBox2,type = ui.TYPE.TextEdit,props = {text="0",textSize=25*textSizeRatio,textColor=Grey, visible = true},events={textChanged=async:callback(function(text)  teleportPoint(25,2,text,nil)  end)}},
																	{ type = ui.TYPE.Text,  props = { text = "Point 2 Y ", textSize = 25*textSizeRatio, textColor = White, visible = true} },
																	{ template = TextEditBox2,type = ui.TYPE.TextEdit,props = {text="0",textSize=25*textSizeRatio,textColor=Grey, visible = true},events={textChanged=async:callback(function(text)  teleportPoint(25,2,nil,text) end)}}
																	},},
									{ type = ui.TYPE.Flex,  props = { visible = false, autoZise=false, horizontal=true} ,content=ui.content{
																	{ type = ui.TYPE.Text,  props = { text = "Point 3 X ", textSize = 25*textSizeRatio, textColor = White, visible = true} },
																	{ template = TextEditBox2,type = ui.TYPE.TextEdit,props = {text="0",textSize=25*textSizeRatio,textColor=Grey, visible = true},events={textChanged=async:callback(function(text)  teleportPoint(26,3,text,nil) end)}},
																	{ type = ui.TYPE.Text,  props = { text = "Point 3 Y ", textSize = 25*textSizeRatio, textColor = White, visible = true} },
																	{ template = TextEditBox2,type = ui.TYPE.TextEdit,props = {text="0",textSize=25*textSizeRatio,textColor=Grey, visible = true},events={textChanged=async:callback(function(text)  teleportPoint(26,3,nil,text) end)}}
																	},},

								},}
	elseif I.UI.getMode()=="MainMenu" then
		for i=1,20 do
			if i==1 then
				CameraMenu.layout.content[i].props.visible=true
			elseif CameraMenu.layout.content[i].props then
				CameraMenu.layout.content[i].props.visible=false
			end
		end
		CameraMenu:update()
	elseif I.UI.getMode()~="MainMenu" and CameraMenu then
		CameraMenu:destroy()
	end

	
	if CameraMenu and I.UI.getMode()=="MainMenu" then
		if input.isKeyPressed(input.KEY.T) and ShowSwitchZone==1 then

			ui.showMessage("SwitchZones Saved")
			core.sendGlobalEvent('SHSwitchZones',{Player=self,SH=3, cam=activecam,TargetCam=TargetCams})
		elseif ShowSwitchZone==1 and CameraMenu.layout.content[21].props.visible==false and SwitchZonePoints["SwitchZone1"] then
			print(ShowSwitchZone)
			Switchzonepoints=SwitchZonePoints
			CameraMenu.layout.content[21].props.visible=true
			CameraMenu.layout.content[22].props.visible=true
			CameraMenu.layout.content[22].content[3].props.text="(Red) to camera "
			CameraMenu.layout.content[22].content[4].props.text=SwitchZonePoints.SwitchZone1.Camera
			CameraMenu.layout.content[23].props.visible=true
			CameraMenu.layout.content[23].content[2].props.text=tostring(SwitchZonePoints.SwitchZone1.Point0.position.x)
			CameraMenu.layout.content[23].content[4].props.text=tostring(SwitchZonePoints.SwitchZone1.Point0.position.y)
			CameraMenu.layout.content[24].props.visible=true
			CameraMenu.layout.content[24].content[2].props.text=tostring(SwitchZonePoints.SwitchZone1.Point1.position.x)
			CameraMenu.layout.content[24].content[4].props.text=tostring(SwitchZonePoints.SwitchZone1.Point1.position.y)
			CameraMenu.layout.content[25].props.visible=true
			CameraMenu.layout.content[25].content[2].props.text=tostring(SwitchZonePoints.SwitchZone1.Point2.position.x)
			CameraMenu.layout.content[25].content[4].props.text=tostring(SwitchZonePoints.SwitchZone1.Point2.position.y)
			CameraMenu.layout.content[26].props.visible=true
			CameraMenu.layout.content[26].content[2].props.text=tostring(SwitchZonePoints.SwitchZone1.Point3.position.x)
			CameraMenu.layout.content[26].content[4].props.text=tostring(SwitchZonePoints.SwitchZone1.Point3.position.y)
			CameraMenu:update()
		elseif ShowSwitchZone==0 and CameraMenu.layout.content[21].props.visible==true then
			print(ShowSwitchZone)
			CameraMenu.layout.content[21].props.visible=false
			CameraMenu.layout.content[22].props.visible=false
			CameraMenu.layout.content[23].props.visible=false
			CameraMenu.layout.content[24].props.visible=false
			CameraMenu.layout.content[25].props.visible=false
			CameraMenu.layout.content[26].props.visible=false
			CameraMenu:update()
		end
	end


	if I.UI.getMode()=="MainMenu" and input.isKeyPressed(input.KEY._0) then
		if CameraMenu.layout.content[2].props.visible==false then
			if ShowSwitchZone==1 and CameraMenu.layout.content[20].props.text=="H : Show Switchzones" then
				CameraMenu.layout.content[20].props.text="H : Hide Switchzones"
			end
			for i=1,20 do
				if i==2 or i==3  or i==4  or i==5  or i==6 or i==7  or i==15 or i==18 or i ==20 then
					CameraMenu.layout.content[i].props.visible=true
				elseif CameraMenu.layout.content[i].props then
					CameraMenu.layout.content[i].props.visible=false
				end
			end
			CameraMenu:update()
		end
		if input.isKeyPressed(input.KEY.B) then
			for i=1,20 do
				if i ==19 then
					CameraMenu.layout.content[i].props.visible=true
				elseif CameraMenu.layout.content[i].props then
					CameraMenu.layout.content[i].props.visible=false
				end
			end
			
			if  MoveBackward(0.2) then
				BGDepth=BGDepth-5
				ChangeCam(activeBkg,MSKlist,activecam,BGDepth)
			elseif input.isKeyPressed(input.KEY.B) and  MoveForward(-0.2) then
				BGDepth=BGDepth+5
				ChangeCam(activeBkg,MSKlist,activecam,BGDepth)
			end

		elseif input.isKeyPressed(input.KEY.P) and ToggleButton==false then
			ToggleButton=true
			core.sendGlobalEvent('saveRDT',{Cell=self.cell.name})
			ui.showMessage("RTD printed")

		elseif input.isKeyPressed(input.KEY.H) and ToggleButton==false then
			ToggleButton=true
			if ShowSwitchZone==0 then
				CameraMenu.layout.content[20].props.text="H : Hide Switchzones"
				core.sendGlobalEvent('SHSwitchZones',{Player=self,SH=ShowSwitchZone, cam=activecam})
				ShowSwitchZone=1
			elseif ShowSwitchZone==1 then
				CameraMenu.layout.content[20].props.text="H : Show Switchzones"
				core.sendGlobalEvent('SHSwitchZones',{Player=self,SH=ShowSwitchZone, cam=activecam})
				ShowSwitchZone=0
			end
			CameraMenu:update()

		elseif input.isKeyPressed(input.KEY.M) then
			for i=1,20 do
				if i ==16 or i ==17 then
					CameraMenu.layout.content[i].props.visible=true
				elseif CameraMenu.layout.content[i].props then
					CameraMenu.layout.content[i].props.visible=false
				end
			end
			core.sendGlobalEvent('BlinkingMask',{Mask=Mask})
			if MoveBackward(0.2) and MSKlist[Mask].depth>1 then
				MSKlist[Mask].depth=MSKlist[Mask].depth-1
				print(MSKlist[Mask].depth)
				ChangeCam(activeBkg,MSKlist,activecam,BGDepth)
			elseif MoveForward(-0.2) then
				MSKlist[Mask].depth=MSKlist[Mask].depth+1
				print(MSKlist[Mask].depth)
				ChangeCam(activeBkg,MSKlist,activecam,BGDepth)
			elseif TurnRight(0.2) and vfs.fileExists('meshes/Masks/'..MSKlist[Mask+1].idname..'.nif') and ToggleButton==false then
				Mask=Mask+1
				ui.showMessage("Mask"..Mask)
				ToggleButton=true
			elseif TurnLeft(-0.2) and Mask>1 and ToggleButton==false  then
				Mask=Mask-1
				ui.showMessage("Mask"..Mask)
				ToggleButton=true
			end
		elseif input.isKeyPressed(input.KEY._9) and camera.getMode()==0 then
			for  i=1,20 do
				if i ==8 or i ==9 or i ==10 or i ==11 or i ==12 then
					CameraMenu.layout.content[i].props.visible=true
				elseif CameraMenu.layout.content[i].props then
					CameraMenu.layout.content[i].props.visible=false
				end
			end
			CameraMenu:update()
			if TurnLeft(-0.2) == true then
				camera.setStaticPosition(util.transform.move(util.vector3(-1, 0, 0)) * camera.getPosition())
				ChangeCam(activeBkg,MSKlist,activecam,BGDepth)
			elseif TurnRight(0.2) == true then
				camera.setStaticPosition(util.transform.move(util.vector3(1, 0, 0)) * camera.getPosition())
				ChangeCam(activeBkg,MSKlist,activecam,BGDepth)





			elseif input.isKeyPressed(input.KEY._8) == true then
				for  i=1,20 do
					if i ==13 or i ==14 then
						CameraMenu.layout.content[i].props.visible=true
					elseif CameraMenu.layout.content[i].props then
						CameraMenu.layout.content[i].props.visible=false
					end
				end
				CameraMenu:update()
				if MoveBackward(0.2) == true then
				CameraMenu:update()
					camera.setStaticPosition(util.transform.move(util.vector3(0, 0, -1)) * camera.getPosition())
					ChangeCam(activeBkg,MSKlist,activecam,BGDepth)
				elseif MoveForward(-0.2) == true then
					camera.setStaticPosition(util.transform.move(util.vector3(0, 0, 1)) * camera.getPosition())
					ChangeCam(activeBkg,MSKlist,activecam,BGDepth)
				end



				
			elseif MoveBackward(0.2) == true then
				camera.setStaticPosition(util.transform.move(util.vector3(0, -1, 0)) * camera.getPosition())
				ChangeCam(activeBkg,MSKlist,activecam,BGDepth)
			elseif MoveForward(-0.2) == true then
				camera.setStaticPosition(util.transform.move(util.vector3(0, 1, 0)) * camera.getPosition())
				ChangeCam(activeBkg,MSKlist,activecam,BGDepth)
			end
		elseif TurnLeft(-0.2) == true and camera.getMode()==0 then
			camera.setYaw(camera.getYaw() - 0.005)
			ChangeCam(activeBkg,MSKlist,activecam,BGDepth)
		elseif TurnRight(0.2) == true and camera.getMode()==0 then
			camera.setYaw(camera.getYaw() + 0.005)
			ChangeCam(activeBkg,MSKlist,activecam,BGDepth)
		elseif MoveBackward(0.2) == true and camera.getMode()==0 then
			camera.setPitch(camera.getPitch() + 0.005)
			ChangeCam(activeBkg,MSKlist,activecam,BGDepth)
		elseif MoveForward(-0.2) == true and camera.getMode()==0 then
			camera.setPitch(camera.getPitch() - 0.005)
			ChangeCam(activeBkg,MSKlist,activecam,BGDepth)
		end
		if ToggleButton==true and TurnRight(0.2)~=true and TurnLeft(-0.2)~=true and input.isKeyPressed(input.KEY.P)==false and input.isKeyPressed(input.KEY.H)==false and input.isKeyPressed(input.KEY.T)==false then
			ToggleButton=false
		elseif input.isKeyPressed(input.KEY.M)==false then
			Mask=1
		end
	end

end

return func_table

