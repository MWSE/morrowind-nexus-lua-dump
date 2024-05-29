local self = require('openmw.self')
local nearby = require('openmw.nearby')
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
local storage = require('openmw.storage')
local async = require('openmw.async')
local postprocessing = require('openmw.postprocessing')
local Puzzles=require('scripts/puzzles')
local PlaceCamera=require('scripts/CameraPosition')
local UI=require('scripts/UI')

local doOnce = nil
local activecam = nil
local activeBkg = nil
MSKlist = {}
BGDepth=nil


local Maps=util.loadCode("return({"..types.Book.record("Maps").text.."})",{})()

I.Settings.registerPage {
    key = 'RESettingsPage',
    l10n = 'RESettings',
    name = 'Resident Evil Settings',
    description = 'Settings that can be changed to play with RE3 or RE0 gameplay.',
}

I.Settings.registerGroup {
    key = 'RESettings1',
    page = 'RESettingsPage',
    l10n = 'RESettings',
    name = 'Edit RE settings',
    description = 'Settings',
    permanentStorage = false,
    settings = {
        {
            key = 'AutoAim',
            renderer = 'checkbox',
            name = 'AutoAim',
            description = 'Target ennemie or attack objects when targeting',
            default = true,
			argument={trueLabel = "Auto",falseLabel = "Manual"},
        },
        {
            key = 'Dodge',
            renderer = 'checkbox',
            name = 'Dodge',
            description = 'Ability to dodge (RE3)',
            default = true,
			argument={trueLabel = "Yes",falseLabel = "No"},
        },
        {
            key = 'Drop',
            renderer = 'checkbox',
            name = 'Drop',
            description = 'Ability to drop object from the inventory (RE0)',
            default = true,
			argument={trueLabel = "Yes",falseLabel = "No"},
        },
        {
            key = 'Reload',
            renderer = 'checkbox',
            name = 'Reload',
            description = 'Ability to reload weapon (draw weapon+run)',
            default = true,
			argument={trueLabel = "Yes",falseLabel = "No"},
        },
        {
            key = 'FixedCamera',
            renderer = 'checkbox',
            name = 'FixedCamera',
            description = 'Play with fixed cameras',
            default = true,
			argument={trueLabel = "Yes",falseLabel = "No"},
        },
    },
}

--{"Hand Gun Bullets", "Hand Gun Bullets Enhanced", "Shotgun Shells","Shotgun Shells Enhanced","Grenade Rounds","Acid Rounds","Flame Rounds","Freeze Rounds","Sponge Round","Assault Rifle Bullets","Magnum Bullets","Mine Thrower Rounds","Fuel"}
local AmmunitionTypes = {}
local EquippedWeapon
local ammosloadable
local StartingAmmo
local ammoscharged = false
local wrongammo = true
AmmoChecked = 0
Instantammo = 0
local ammochanged = false
local weaponcondition = 0
local InventoryAmmunitionTypes = {}
local InventoryItemSelected = {}
local Colors={
White=util.color.rgb(1, 1, 1),
Grey=util.color.rgb(0.5, 0.5, 0.5),
Orange=util.color.rgb(0.67, 0.74, 0.12),
Blue=util.color.rgb(0.09, 0.38, 0.54),
Red=util.color.rgb(0.74, 0.11, 0.11),
Green=util.color.rgb(0.08, 0.71, 0.02),
}
---------------------------



local Borderbox=ui.texture { path = "textures/BorderBox.dds", }
local TransparentBorderBox=ui.texture { path = "textures/TransparentBorderBox.dds", }
local WrapperTemplate = {
	type = ui.TYPE.Image,
	props = {
		resource = Borderbox,
		color = Colors.White,
		visible=true
	},
	content = ui.content {
		{
			external = { slot = true },
			props = {relativeSize = util.vector2(1, 1) } } }
}


---------------------------------------
local function InventoryReload(item1, item2)
	item1:sendEvent('GiveWeaponInfos', { player = self, Equipped = false })
	if InventoryAmmunitionTypes[1] then
		for i, ammo in ipairs(InventoryAmmunitionTypes) do
			--print(ammo)
			--print(item2.recordId)
			if ammo == item2.recordId then
				--print("GOOD AMMO")
				--print(10000 + i)
				local Inventoryammosloadable = 0
				if types.Item.itemData(item1).condition - 10000 == i then
					if types.Actor.inventory(self):countOf(item2.recordId) > (core.magic.enchantments.records[types.Weapon.record(item1).enchant].charge - types.Item.getEnchantmentCharge(item1)) then
						Inventoryammosloadable = core.magic.enchantments.records[types.Weapon.record(item1).enchant].charge -
							types.Item.getEnchantmentCharge(item1)
						--print("ammosload" .. tostring(Inventoryammosloadable))
						core.sendGlobalEvent('setCharge',
							{ Item = item1, value = core.magic.enchantments.records[types.Weapon.record(item1).enchant].charge })
					else
						--print("low ammo")
						Inventoryammosloadable = types.Actor.inventory(self):countOf(item2.recordId)
						--print("ammosload" .. tostring(Inventoryammosloadable))
						core.sendGlobalEvent('setCharge',
							{ Item = item1, value = Inventoryammosloadable + types.Item.getEnchantmentCharge(item1) })
					end
					core.sendGlobalEvent('RemoveItem', { Item = item2, number = Inventoryammosloadable })
				else
					if types.Actor.inventory(self):countOf(item2.recordId) >= core.magic.enchantments.records[types.Weapon.record(item1).enchant].charge then
						core.sendGlobalEvent('setCharge',
							{ Item = item1, value = core.magic.enchantments.records[types.Weapon.record(item1).enchant].charge })
						core.sendGlobalEvent('RemoveItem',
							{ Item = item2, number = core.magic.enchantments.records[types.Weapon.record(item1).enchant].charge })
						for i = 1, types.Item.getEnchantmentCharge(item1) do
							core.sendGlobalEvent('MoveInto',
								{
									Item = nil,
									container = nil,
									actor = self,
									newItem = InventoryAmmunitionTypes
										[types.Item.itemData(item1).condition - 10000]
								})
						end
					else
						core.sendGlobalEvent('setCharge',
							{ Item = item1, value = types.Actor.inventory(self):countOf(item2.recordId) })
						core.sendGlobalEvent('RemoveItem',
							{ Item = item2, number = types.Actor.inventory(self):countOf(item2.recordId) })


						for i = 1, types.Item.getEnchantmentCharge(item1) do
							core.sendGlobalEvent('MoveInto',
								{
									Item = nil,
									container = nil,
									actor = self,
									newItem = InventoryAmmunitionTypes
										[types.Item.itemData(item1).condition - 10000]
								})
						end
					end
					--print(10000 + i)
					item1:sendEvent('setCondition', { value = 10000 + i })
					weaponcondition = 10000 + i
				end
				break
			end
			if InventoryAmmunitionTypes[i + 1] == nil then
				--print("WRONG AMMO")
			end
		end

		InventoryItemSelected[4] = nil
		SelectedCombineItem:destroy()
		ToggleUseButton = false
		FrameRefresh = true
	end
end

local function ReturnEquippedWeaponInfos(data)
	AmmunitionTypes = data.AmmunitionTypes
	--print("returned")
	--for i, ammo in ipairs(AmmunitionTypes) do
	--	print(ammo)
	--end
	--print("returned")
	AmmoChecked = 1
end

local function ReturnInventoryWeaponInfos(data)
	InventoryAmmunitionTypes = data.AmmunitionTypes
	--print("received inventory")
end


local BulletOnScreen
local BulletOnScreenTimer=60
local function CheckBulletOnScreen ()
	local RotZ = self.rotation:getPitch()
	local RotX = self.rotation:getYaw()
	local Target = nearby.castRay(
				util.vector3(0, 0, 110) + self.position +
				util.vector3(math.cos(RotZ) * math.sin(RotX), math.cos(RotZ) * math.cos(RotX), -math.sin(RotZ)) * 50,
				util.vector3(0, 0, 110) + self.position +
				util.vector3(math.cos(RotZ) * math.sin(RotX), math.cos(RotZ) * math.cos(RotX), -math.sin(RotZ)) * (self.position-camera.getPosition()):length())


	--print()
	if ((self.rotation:getPitch())>=(camera.getPitch()-(camera.getFieldOfView())/2)) and ((self.rotation:getPitch())<=(camera.getPitch()+(camera.getFieldOfView())/2)) and ((self.rotation:getYaw()-math.pi)>=(camera.getYaw()-(camera.getFieldOfView())/2)) and ((self.rotation:getYaw()-math.pi)<=(camera.getYaw()+(camera.getFieldOfView())/2)) and Target.hitObject==nil then
		if BulletOnScreen and BulletOnScreen.layout then
			BulletOnScreen.layout.props.relativePosition=util.vector2(math.random(10)/12, math.random(10)/14)
			BulletOnScreen:update()
			BulletOnScreenTimer=0
		else
			BulletOnScreen=ui.create({name="BulletOnScreen",layer = 'HUD',  type = ui.TYPE.Image,  props = {relativeSize = util.vector2(1/5, 1/5),relativePosition=util.vector2(math.random(10)/12, math.random(10)/14),resource = ui.texture{path ="textures/BulletImpactOnGlass.dds"},}})
			BulletOnScreenTimer=0
		end
	end

end

local UseButton = 0
local QuickTurnButton = 0
local ToggleUseButton = false
local DodgeButton = 0
local TurningBack = 0
local ToggleWeaponButton=false
local ToggleWeaponButtonMap=false
local ToggleSneakButtonMap=false



local TargetedBOW = {}
local BOWchecked = 0
local TargetedAttackObject = {}
local AttackObjectchecked = 0
local changetarget = 0

local Menu = false
local shootTimer = 0
local FrameRefresh = false

local TargetBOW
local TargetAttackObject

local Lifebare
local doOnceMenu = 0
local path1
local path2 = 0
local path3
local lifebarTimer = 0
local onFrameHealth

local equipped = types.Actor.equipment(self)

local LiveSelectionTimer =0
local LiveSelectionChoice1=""
local LiveSelectionChoice2=""
local negativeshader = postprocessing.load('negative')


----- variables pour tire shotguns
local SShellRotX
local SShellRotZ
local SshellDamage
local SshellEnchant
local Xshotshell
local Yshotshell
local Zshotshell
local ray


---------- override  normal controls
interfaces.Controls.overrideMovementControls(true)
interfaces.Controls.overrideCombatControls(true)
interfaces.Controls.overrideUiControls(true)


-----------------bars cinematiques
ui.create({ layer = 'Console', type = ui.TYPE.Image, props = { relativeSize = util.vector2(1, 1 / 7), relativePosition = util.vector2(0, 1), anchor = util.vector2(0, 1), resource = ui.texture { path = 'textures/cinematic_bar.dds' }, }, })
ui.create({ layer = 'Console', type = ui.TYPE.Image, props = { relativeSize = util.vector2(1, 1 / 7), relativePosition = util.vector2(0, 0), anchor = util.vector2(0, 0), resource = ui.texture { path = 'textures/cinematic_bar.dds' }, }, })


local ItemDescriptions=util.loadCode("return("..types.Book.record("Item Descriptions").text..")",{})()

local ExaminedItems = util.loadCode("return(" .. types.Book.record("examined items").text .. ")", {})()

local CombinedItems = util.loadCode("return(" ..types.Book.record("combined items").text .. ")", {})()


function Camerapos(data)
	activecam = data.ActiveCam
	activeBkg = data.ActiveBkg
	BGDepth = data.BGDepth
	CamAng=data.CamAng
	CamPos=data.CamPos
	--print(data.MSKList[1])
	if data.MSKList then
		MSKlist = data.MSKList
	end
	if storage.playerSection('RESettings1'):get('FixedCamera')==true and data.CamPos and data.CamAng then
		camera.setMode(0)
		camera.setStaticPosition(data.CamPos)
		camera.setFieldOfView(0.8)--*1280/ui.screenSize().x)	--field of View = 50
		camera.setPitch(data.CamAng.x)
		camera.setYaw(data.CamAng.y)
	end
end

local SwitchZonePoints={}
function DefineSwitchZones(data)
	SwitchZonePoints=data.SwitchZonePoints
end


local function InFront(data)
	if (((self.rotation:getYaw() <= .785 and self.rotation:getYaw() >= -.785) and (data.position.y - self.position.y) >= 0)
			or ((self.rotation:getYaw() <= 2.355 and self.rotation:getYaw() >= .785) and (data.position.x - self.position.x) >= 0)
			or ((self.rotation:getYaw() <= -2.355 or self.rotation:getYaw() >= 2.355) and (data.position.y - self.position.y) <= 0)
			or ((self.rotation:getYaw() <= -.785 and self.rotation:getYaw() >= -2.355) and (data.position.x - self.position.x) <= 0)) then
		return (true)
	end
end

function MoveForward(data)
	if input.isActionPressed(input.ACTION.MoveForward) == true or input.getAxisValue(input.CONTROLLER_AXIS.LeftY) <= data then
		return (true)
	end
end

function MoveBackward(data)
	if input.isActionPressed(input.ACTION.MoveBackward) == true or input.getAxisValue(input.CONTROLLER_AXIS.LeftY) >= data then
		return (true)
	end
end

function TurnRight(data)
	if input.isActionPressed(input.ACTION.QuickKey1) == true or input.getAxisValue(input.CONTROLLER_AXIS.LeftX) >= data then
		return (true)
	end
end

function TurnLeft(data)
	if input.isActionPressed(input.ACTION.QuickKey2) == true or input.getAxisValue(input.CONTROLLER_AXIS.LeftX) <= data then
		return (true)
	end
end

local textSizeRatio= ui.screenSize().y/1056
local MenuSelectStop = false
local iconpath
local InventoryItems
local Inventory
local PickUpItem = {}
local PickUpItemIcon
local function ShowInventory()
	ambient.playSound("REdecide")
	I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
	local InventoryContent = ui.content {}
	local InventoryItems = {}

	if not (Inventory == nil ) then
		Inventory:destroy()
	end

	for i = 1, 20 do --20 is an arbitrary value
		if not (types.Actor.inventory(self):getAll()[i] == nil or types.Actor.inventory(self):getAll()[i].type == types.Book) then
			table.insert(InventoryItems, types.Actor.inventory(self):getAll()[i])
		end
	end


	for i, item in ipairs(InventoryItems) do
		if i>types.NPC.getCapacity(self) then
			break
		end


		local textLayout = {}
		local weapontextcolor
		if item.count > 1 then                                                   --13 == Bolt
			textLayout = { type = ui.TYPE.Text, props = { text = tostring(item.count), textSize = 50*textSizeRatio, textColor = util.color.rgb(0.06, 0.4, 0.08), anchor = util.vector2(-1, -1.5), }, }
		elseif item.type == types.Weapon and types.Weapon.record(item).type == 10 then --10 == MarksmanCrossbow then
			if types.Item.itemData(item).condition == 10001 then
				weapontextcolor = util.color.rgb(0.09, 0.38, 0.54)
			elseif types.Item.itemData(item).condition == 10002 then
				weapontextcolor = util.color.rgb(0.67, 0.74, 0.12)
			elseif types.Item.itemData(item).condition == 10003 then
				weapontextcolor = util.color.rgb(0.74, 0.11, 0.11)
			elseif types.Item.itemData(item).condition == 10004 then
				weapontextcolor = util.color.rgb(0.1, 0.18, 0.73)
			elseif types.Item.itemData(item).condition == 10005 then
				weapontextcolor = util.color.rgb(0.08, 0.71, 0.02)
			elseif types.Item.itemData(item).condition == 10006 then
				weapontextcolor = util.color.rgb(0, 0, 0)
			end
			textLayout = { type = ui.TYPE.Text, props = { text = tostring(types.Item.getEnchantmentCharge(item)), textSize = 50*textSizeRatio, textColor = weapontextcolor, anchor = util.vector2(-1, -1.5), }, }
		else
			textLayout = { type = ui.TYPE.Text, props = { text = nil, textSize = 50*textSizeRatio, textColor = util.color.rgb(0.09, 0.38, 0.54), anchor = util.vector2(-1, -1.5), }, }
		end
		if i % 2 == 1 then
			_G["ContentInventoryLine" .. i] = ui.content {}
			_G["ContentInventoryLine" .. i]:add({ type = ui.TYPE.Image, content = ui.content { textLayout }, props = { size = util.vector2(ui.screenSize().x / 10, ui.screenSize().y / 9), resource = ui.texture { path = item.type.record(item).icon }, }, })

			if InventoryItems[i + 1] == nil then
				_G["InventoryLine" .. (i)] = {
					name = "Line" .. (i),
					layer = "Windows",
					type = ui.TYPE.Flex,
					props = { position = util.vector2(ui.screenSize().x * 5 / 6 - ui.screenSize().x / 10, ui.screenSize().y / 2), anchor = util.vector2(0, 0), horizontal = true },
					content =
						_G["ContentInventoryLine" .. (i)]
				}
				InventoryContent:add(_G["InventoryLine" .. (i)])
			end
		elseif i % 2 == 0 then
			_G["ContentInventoryLine" .. (i - 1)]:add({ type = ui.TYPE.Image, content = ui.content { textLayout }, props = { size = util.vector2(ui.screenSize().x / 10, ui.screenSize().y / 9), resource = ui.texture { path = item.type.record(item).icon }, }, })

			_G["InventoryLine" .. (i - 1)] = {
				name = "Line" .. (i - 1),
				layer = "Windows",
				type = ui.TYPE.Flex,
				props = { position = util.vector2(ui.screenSize().x * 5 / 6 - ui.screenSize().x / 10, ui.screenSize().y / 2), anchor = util.vector2(0, 0), horizontal = true },
				content =
					_G["ContentInventoryLine" .. (i - 1)]
			}

			InventoryContent:add(_G["InventoryLine" .. (i - 1)])
		end
	end

	InventoryLayout = {
		name = "Inventory",
		layer = "Windows",
		type = ui.TYPE.Flex,
		props = { relativePosition = util.vector2(0, 0), anchor = (util.vector2(0, 0)) },
		content =
			InventoryContent
	}
	Inventory = ui.create({ 	name = "Inventory", 
								layer = 'Windows', 
								type = ui.TYPE.Image, 
								props = { autoSize=true, relativeSize = util.vector2(2 / 10, types.NPC.getCapacity(self) / 2 / 9), relativePosition = util.vector2(3 / 4, 1 / 3), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/BkgInventory.dds" }, },
								content=ui.content{InventoryLayout,}
							})
	return (InventoryItems)
end



function ShowItem(item, text)
	local ItemIcon = { layer = 'Windows', type = ui.TYPE.Image, props = { relativeSize = util.vector2(2 / 3, 1 / 2),  anchor = (util.vector2(0, 0)), resource = ui.texture { path = item.type.record(item).icon }, }, }
	local Text = { layer = 'Windows', type = ui.TYPE.Text, props = {relativeSize = util.vector2(2 / 3, 1 / 2), anchor = util.vector2(1 / 2, 1 / 2), text = text, autoSize = false, textSize = 30*textSizeRatio, textColor = util.color.rgb(1, 1, 1), wordWrap=true}, }

	ShowItemIcon = ui.create({
		layer = 'Console',
		type = ui.TYPE.Flex,
		props = { autoSize = false, relativeSize = util.vector2(1 / 2, 1 / 2), relativePosition = util.vector2(1 / 3, 1 / 2), anchor = util.vector2(0, 0), },
		content = ui.content { ItemIcon,
			{ layer = 'Windows', type = ui.TYPE.Text, props = { text = " ", textSize = 120*textSizeRatio } }, Text }
	})
end




local function Overload()
	for i, book in ipairs(types.Player.inventory(self):getAll(types.Book)) do
		if types.Player.inventory(self):getAll(types.Book)[i + 1] == nil then
			if types.Player.inventory(self):getAll()[types.NPC.getCapacity(self) + i + 1] and input.isActionPressed(input.ACTION.ToggleWeapon) == false then
				core.sendGlobalEvent('Teleport',
				{
					object = types.Player.inventory(self):getAll()[types.NPC.getCapacity(self) + i + 1],
					position =
						self.position,
					rotation = nil
				})
			ui.showMessage("Your inventory is full, you drop : " ..
				tostring(types.Player.inventory(self):getAll()[types.NPC.getCapacity(self) + i + 1].recordId))
			end
		end
	end
end




function TurnToTarget(Target)
	local AngleTarget
	if self.position.x < Target.position.x then
		if self.position.y < Target.position.y then --ok
			AngleTarget = -self.rotation:getYaw() +
				math.acos((Target.position.y - self.position.y) / (self.position - Target.position):length())
		elseif self.position.y > Target.position.y then
			AngleTarget = -self.rotation:getYaw() -
				math.acos((self.position.y - Target.position.y) / (self.position - Target.position):length()) - math.pi
		end
	elseif self.position.x > Target.position.x then --ok
		if self.position.y < Target.position.y then
			AngleTarget = -self.rotation:getYaw() +
				math.acos((self.position.y - Target.position.y) / (self.position - Target.position):length()) - math.pi
		elseif self.position.y > Target.position.y then
			AngleTarget = -self.rotation:getYaw() -
				math.acos((Target.position.y - self.position.y) / (self.position - Target.position):length())
		end
	end
	self.controls.yawChange = AngleTarget
end

local MapUI=nil
local LastRoom
local ObjectsInWorld
local ObjectsInMap
AreaMap=0
ZoneMap=0
RoomMap=0
MapsUtils={Blink={value=-0.01,Room=0},RoomsVisited={},RoomsMapped={}}


local function CheckTableUD(table,number,Way)
	--print("function")
	local Delta=0

	--print(number)
	--print(Way)
	if table then
		for i, num in pairs(table) do
			--print(i)
			if Way=="+" and i>number then
				if Delta>(i-number) or Delta==0 then
					Delta=i-number
				end
			elseif  Way=="-" and i<number then
				if Delta<(i-number) or Delta==0 then
					Delta=(i-number)
				end
			end
		end
	end
	--print(Delta)
	return (Delta)
end














local function ShowMap(Area,Zone,Cell)
	MapsUtils.Blink.Room=0
	local MapUIContent={}
	local RoomNum=0
	local FlexObjectsContent={}
	if	 MapUI and MapUI.layout then
		MapUI:destroy()
	end 

	for i, Room in pairs(Maps[Area][2][Zone][2]) do
		if MapsUtils["RoomsVisited"][Area] then
			if MapsUtils["RoomsVisited"][Area][2][Zone] then
					if MapsUtils["RoomsVisited"][Area][2][Zone][2][i] then
						if Room==self.cell.name then
							table.insert(MapUIContent,{type = ui.TYPE.Image, props = {alpha=1, relativeSize = util.vector2(1,1),relativePosition=util.vector2(0.5, 0.5),anchor = util.vector2(0.5, 0.5),resource = ui.texture{path ="textures/Maps/"..Maps[Area][1].."/"..Maps[Area][2][Zone][1].."/"..Room.."In.png"}}})
							RoomNum=RoomNum+1
							if i==Cell then
								MapsUtils.Blink.Room=RoomNum
							end
						else
							table.insert(MapUIContent,{type = ui.TYPE.Image, props = {alpha=1,relativeSize = util.vector2(1,1),relativePosition=util.vector2(0.5, 0.5),anchor = util.vector2(0.5, 0.5),resource = ui.texture{path ="textures/Maps/"..Maps[Area][1].."/"..Maps[Area][2][Zone][1].."/"..Room..".png"}}})
							RoomNum=RoomNum+1
							if i==Cell then
								MapsUtils.Blink.Room=RoomNum
							end
						end
					elseif MapsUtils["RoomsMapped"][Area] then
						if MapsUtils["RoomsMapped"][Area][2][Zone] then
							--print("MappedR")
							table.insert(MapUIContent,{type = ui.TYPE.Image, props = {alpha=0.2,relativeSize = util.vector2(1,1),relativePosition=util.vector2(0.5, 0.5),anchor = util.vector2(0.5, 0.5),resource = ui.texture{path ="textures/Maps/"..Maps[Area][1].."/"..Maps[Area][2][Zone][1].."/"..Room..".png"}}})
							RoomNum=RoomNum+1
						end
					end
			elseif MapsUtils["RoomsMapped"][Area] then
				if MapsUtils["RoomsMapped"][Area][2][Zone] then
					--print("MappedZ")
					table.insert(MapUIContent,{type = ui.TYPE.Image, props = {alpha=0.2,relativeSize = util.vector2(1,1),relativePosition=util.vector2(0.5, 0.5),anchor = util.vector2(0.5, 0.5),resource = ui.texture{path ="textures/Maps/"..Maps[Area][1].."/"..Maps[Area][2][Zone][1].."/"..Room..".png"}}})
					MapsUtils.Blink.Room=0
				end
			end
		elseif MapsUtils["RoomsMapped"][Area] then
			if MapsUtils["RoomsMapped"][Area][2][Zone] then
				--print("MappedA")
				table.insert(MapUIContent,{type = ui.TYPE.Image, props = {alpha=0.2,relativeSize = util.vector2(1,1),relativePosition=util.vector2(0.5, 0.5),anchor = util.vector2(0.5, 0.5),resource = ui.texture{path ="textures/Maps/"..Maps[Area][1].."/"..Maps[Area][2][Zone][1].."/"..Room..".png"}}})
				MapsUtils.Blink.Room=0
			end
		end
	end

	for i, variable in pairs(ObjectsInMap) do
		--print(i)
		--print("variable "..variable)
		if variable==1 and vfs.fileExists('textures/Maps/'..Maps[Area][1].."/"..Maps[Area][2][Zone][1].."/"..i..".png") then
			--print("find")
			table.insert(MapUIContent,{type = ui.TYPE.Image, props = {relativeSize = util.vector2(1,1),relativePosition=util.vector2(0.5, 0.5),anchor = util.vector2(0.5, 0.5),resource = ui.texture{path ='textures/Maps/'..Maps[Area][1].."/"..Maps[Area][2][Zone][1].."/"..i..".png"}}})
		end

	end


	if MapsUtils["RoomsVisited"][Area] then
		if MapsUtils["RoomsVisited"][Area][2][Zone] then
			table.insert(FlexObjectsContent,{ type = ui.TYPE.Text,  props = { text = MapsUtils["RoomsVisited"][Area][2][Zone][2][Cell],relativePosition=util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5),textSize = 40*textSizeRatio, textColor = Colors.White } }) 
			table.insert(FlexObjectsContent,{ type = ui.TYPE.Text,  props = { text = "Items : ",relativePosition=util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5),textSize = 35*textSizeRatio, textColor = Colors.White } }) 
			for i=1,10 do
				--print(Zone)
				--print(Maps[Area][2][Zone][1])
				--print(Cell)
				--print(Maps[Area][2][Zone][2][Cell])
				if i==10 and ObjectsInWorld[Maps[Area][2][Zone][2][Cell]][11] then
					table.insert(FlexObjectsContent,{ type = ui.TYPE.Text,  props = { text = "...",relativePosition=util.vector2(2/16, 7/16), textSize = 25*textSizeRatio, textColor = Colors.White } }) 
					break
				elseif ObjectsInWorld[Maps[Area][2][Zone][2][Cell]][i] then
					table.insert(FlexObjectsContent,{ type = ui.TYPE.Text,  props = { text = ObjectsInWorld[Maps[Area][2][Zone][2][Cell]][i],relativePosition=util.vector2(2/16, 7/16), textSize = 25*textSizeRatio, textColor = Colors.White } }) 
				elseif i==1 and ObjectsInWorld[Maps[Area][2][Zone][2][Cell]][i]==nil then	
					table.insert(FlexObjectsContent,{ type = ui.TYPE.Text,  props = { text = "Nothing",relativePosition=util.vector2(2/16, 7/16), textSize = 25*textSizeRatio, textColor = Colors.White } }) 
				else	
					table.insert(FlexObjectsContent,{ type = ui.TYPE.Text,  props = { text = " ",relativePosition=util.vector2(2/16, 7/16), textSize = 25*textSizeRatio, textColor = Colors.White } }) 
				end
			end
		end
	end


	for i, zone in pairs(Maps[Area][2]) do
		if Maps[Area][2][Zone+i] then
			if MapsUtils["RoomsVisited"][Area] then
				if  MapsUtils["RoomsVisited"][Area][2][Zone+i] then
					table.insert(MapUIContent, { type = ui.TYPE.Image, props = {relativePosition=util.vector2(0.5, 0), anchor = util.vector2(0, 0), size = util.vector2(30, 30), visible = true, color = Colors.Green, resource = ui.texture { path = "textures/Choice select cursor Up.dds" } } })
				end
			elseif MapsUtils["RoomsMapped"][Area] then
				if MapsUtils["RoomsMapped"][Area][2][Zone+i] then
					table.insert(MapUIContent, { type = ui.TYPE.Image, props = {relativePosition=util.vector2(0.5, 0), anchor = util.vector2(0, 0), size = util.vector2(30, 30), visible = true, color = Colors.Green, resource = ui.texture { path = "textures/Choice select cursor Up.dds" } } })
				end
			end
		end
	end

	for i, zone in pairs(Maps[Area][2]) do
		if (Zone-i)>0 then
			if  MapsUtils["RoomsVisited"][Area]then
				if  MapsUtils["RoomsVisited"][Area][2][Zone-i]then
					table.insert(MapUIContent, { type = ui.TYPE.Image, props = {relativePosition=util.vector2(0.5, 0.96), anchor = util.vector2(0, 0), size = util.vector2(30, 30), visible = true, color = Colors.Green, resource = ui.texture { path = "textures/Choice select cursor Down.dds" } } })
				end
			elseif MapsUtils["RoomsMapped"][Area] then
				if MapsUtils["RoomsMapped"][Area][2][Zone-i] then
					table.insert(MapUIContent, { type = ui.TYPE.Image, props = {relativePosition=util.vector2(0.5, 0.96), anchor = util.vector2(0, 0), size = util.vector2(30, 30), visible = true, color = Colors.Green, resource = ui.texture { path = "textures/Choice select cursor Down.dds" } } })
				end
			end
		end
	end


	for i, area in pairs(Maps)do
		if (MapsUtils["RoomsVisited"][i] or MapsUtils["RoomsMapped"][i]) and i>AreaMap then
			table.insert(MapUIContent, { type = ui.TYPE.Image, props = {relativePosition=util.vector2(0.97, 0.5), anchor = util.vector2(0, 0), size = util.vector2(30, 30), visible = true, color = Colors.Green, resource = ui.texture { path = "textures/Choice select cursor.dds" } } })
			break
		end
	end
	for i, area in pairs(Maps)do
		if (MapsUtils["RoomsVisited"][i] or MapsUtils["RoomsMapped"][i]) and i<AreaMap then
			table.insert(MapUIContent, { type = ui.TYPE.Image, props = {relativePosition=util.vector2(0, 0.5), anchor = util.vector2(0, 0), size = util.vector2(30, 30), visible = true, color = Colors.Green, resource = ui.texture { path = "textures/Choice select cursor Left.dds" } } })
			break
		end
	end


	table.insert(MapUIContent,{type = ui.TYPE.Flex, props = {autoSize=true,relativePosition=util.vector2(0.1, 0.25),anchor = util.vector2(0.5, 0.5)}, content=ui.content(FlexObjectsContent)})

	MapUI=ui.create({layer = 'Console',  type = ui.TYPE.Image,
	props = {relativeSize = util.vector2(1,1),relativePosition=util.vector2(0.5, 0.5),anchor = util.vector2(0.5, 0.5),resource = ui.texture{path ="textures/Maps/"..Maps[Area][1].."/"..Maps[Area][2][Zone][1].."/BKG.png"},},
	content=ui.content(MapUIContent)
	})

end	






local function onUpdate()


	if BulletOnScreen and BulletOnScreen.layout then
		if BulletOnScreenTimer<60 then
			BulletOnScreenTimer=BulletOnScreenTimer+1
		else 
			BulletOnScreen:destroy()
		end
	end


	------- picking items 1/2
	if PickUpItem[2] == true and PickUpItem[3] == nil then
		ShowInventory()
		InventoryItemSelected[2] = nil
		PickUpItem[3] = true
		ShowItem(PickUpItem[1], 'You Pickup ' .. PickUpItem[1].recordId)
	elseif PickUpItem[2] == false and PickUpItem[3] == nil then
		ShowInventory()
		InventoryItemSelected[2] = nil
		PickUpItem[3] = true
		ShowItem(PickUpItem[1], "You can't pickup " .. PickUpItem[1].recordId .. '. Your Inventory is full.')
	end

	---------Ouvrir carte
	if input.isActionPressed(input.ACTION.ToggleSpell) and (MapUI==nil or MapUI.layout==nil) then
		core.sendGlobalEvent('AskObjectsInWorld',{player=self,maps=Maps})
		ambient.playSound("REdecide")
		for i, Area in pairs(Maps) do
			for j ,Zone in pairs (Area[2]) do
				for k, Room in pairs(Zone[2]) do
					if Room==self.cell.name then
						I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
						AreaMap=i 
						ZoneMap=j
						RoomMap=k
					end
				end
			end
		end
	end












	---------------Activate near -> ajouter animation de ramasser un objet
	if input.isActionPressed(input.ACTION.Use) and types.Actor.getStance(self) == 0 and UseButton == 0 and I.UI.getMode() == nil then
		for i, items in ipairs(nearby.items) do
			local dist = (util.vector2(self.position.x, self.position.y) - util.vector2(items.position.x, items.position.y)):length()
			if dist < 100 and ((items.position.z - self.position.z) <= 150) and InFront(items) == true and UseButton==0 then
				UseButton = 1
				local nbritems = 0
				for i, item in ipairs(types.Actor.inventory(self):getAll()) do
					if item.type ~= types.Book then
						nbritems = nbritems + 1
					end
				end
				print(nbritems)
				if (nbritems <= (types.NPC.getCapacity(self) - 1) or (items.type == types.Book) or (types.Player.inventory(self):countOf(string.gsub(items.recordId, "_", "")) > 0 and items.type.record(items).mwscript == "")) and PickUpItem[1] == nil then
					items:activateBy(self)
					--for i, item in ipairs(types.Actor.inventory(self):getAll()) do print(item) end
					PickUpItem[1] = items
					PickUpItem[2] = true
					break
				elseif PickUpItem[1] == nil then
					PickUpItem[1] = items
					PickUpItem[2] = false
					break
				end
			end
		end
		for i, doors in ipairs(nearby.doors) do
			local dist = (self.position - doors.position):length()
			if dist < 80 and ((doors.position.z - self.position.z) <= 150) and InFront(doors) == true and UseButton==0 then
				doors:activateBy(self)
				UseButton = 1
				print("door")
				break
			end
		end
		for i, container in ipairs(nearby.containers) do
			local dist = (self.position - container.position):length()
			if dist < 100 and ((container.position.z - self.position.z) <= 150) and InFront(container) == true and UseButton==0 then
				container:activateBy(self)
				UseButton = 1
				break
			end
		end
		for i, actors in ipairs(nearby.actors) do
			local dist = (self.position - actors.position):length()
			if dist < 50 and ((actors.position.z - self.position.z) <= 150) and types.Actor.stats.dynamic.health(actors).current > 0 and InFront(actors) == true and actors.type ~= types.Player and UseButton==0 then
				actors:activateBy(self)
				UseButton = 1
				break
			end
		end
		for i, activators in ipairs(nearby.activators) do
			local dist = (self.position - activators.position):length()
			if dist < 120 and ((activators.position.z - self.position.z) <= 150) and InFront(activators) == true and UseButton==0 and types.Activator.record(activators).id~="blood puddle" then
				activators:activateBy(self)
				UseButton = 1
				print("activator")
				break
			end
		end
	elseif input.isActionPressed(input.ACTION.Use) == false then
		UseButton = 0
	end


	------test marcher/courrir  ->ok
	if MoveForward(-0.2) == true and input.isActionPressed(input.ACTION.AutoMove) == true and input.isActionPressed(input.ACTION.Sneak) == false then
		self.controls.movement = 1
		self.controls.run = true
	elseif MoveForward(-0.2) == true and input.isActionPressed(input.ACTION.Sneak) == false then
		self.controls.movement = 1
		self.controls.run = false
	elseif MoveBackward(0.2) == true and input.isActionPressed(input.ACTION.Sneak) == false then
		self.controls.movement = -1
		self.controls.run = false
	else
		self.controls.movement = 0
	end
	------------- test rotation sans souris->ok
	if TurnRight(0.2) == true and input.isActionPressed(input.ACTION.Sneak) == false then
		self.controls.yawChange = 0.03
	elseif TurnLeft(-0.2) == true and input.isActionPressed(input.ACTION.Sneak) == false then
		self.controls.yawChange = -0.03
	end
	------------- test visée Y fixe  -ok
	if types.Actor.getStance(self) == 1 then
		if storage.playerSection('RESettings1'):get('FixedCamera')==false and input.getAxisValue(input.CONTROLLER_AXIS.LeftY) then
			--print(input.getAxisValue(input.CONTROLLER_AXIS.LeftY))
			if self.rotation:getPitch()<(input.getAxisValue(input.CONTROLLER_AXIS.LeftY)*0.8) and input.getAxisValue(input.CONTROLLER_AXIS.LeftY)>0.06 then 
				self.controls.pitchChange = 0.03
			elseif self.rotation:getPitch()>(input.getAxisValue(input.CONTROLLER_AXIS.LeftY)*0.8) and input.getAxisValue(input.CONTROLLER_AXIS.LeftY)<-0.06  then 
				self.controls.pitchChange = -0.03
			elseif self.rotation:getPitch()>0.06 and (input.getAxisValue(input.CONTROLLER_AXIS.LeftY)>-0.06 and input.getAxisValue(input.CONTROLLER_AXIS.LeftY)<0.06) then
				self.controls.pitchChange = -0.03
			elseif self.rotation:getPitch()<-0.06 and (input.getAxisValue(input.CONTROLLER_AXIS.LeftY)>-0.06 and input.getAxisValue(input.CONTROLLER_AXIS.LeftY)<0.06) then
				self.controls.pitchChange = 0.03
			end
			
		else
			if types.Actor.getStance(self) == 1 and not (self.rotation:getPitch() < 0.01 and self.rotation:getPitch() > -0.01) and not (MoveForward(-0.5)) and not (MoveBackward(0.5)) then
				if self.rotation:getPitch() <= 0.03 and self.rotation:getPitch() >= -0.03 then
				elseif self.rotation:getPitch() < -0.03 then
					self.controls.pitchChange = 0.05
				elseif self.rotation:getPitch() > 0.03 then
					self.controls.pitchChange = -0.05
				end
			elseif types.Actor.getStance(self) == 1 and MoveBackward(0.5) and self.rotation:getPitch() < 0.45 then
				self.controls.pitchChange = 0.03
			elseif types.Actor.getStance(self) == 1 and MoveForward(-0.5) and self.rotation:getPitch() > -0.45 then
				self.controls.pitchChange = -0.03
			end
		end
	end



	--------------Quick rotate
	if MoveBackward(0.2) == true and types.Actor.getStance(self) == 0 and input.isActionPressed(input.ACTION.AutoMove) == true and QuickTurnButton == 0 then
		TurningBack = 1
		QuickTurnButton = 1
	elseif not (MoveBackward(0.2) == true) and input.isActionPressed(input.ACTION.AutoMove) == false then
		QuickTurnButton = 0
	end

	if TurningBack > 0 then
		self.controls.yawChange = math.pi / 10
		TurningBack = TurningBack + 1
		if TurningBack == 11 then
			TurningBack = 0
		end
	end

	--------Test dodge  -> ajouter les animations
	if input.isActionPressed(input.ACTION.Sneak) == true and MoveBackward(0.2) == true and DodgeButton == 0 and types.Actor.getStance(self) == 0 and storage.playerSection('RESettings1'):get('Dodge')==true then
		ui.showMessage('Dodge Back')
		self.controls.jump = true
		self.controls.movement = -1
		DodgeButton = 1
	elseif input.isActionPressed(input.ACTION.Sneak) == true and MoveForward(-0.2) == true and DodgeButton == 0 and types.Actor.getStance(self) == 0 and storage.playerSection('RESettings1'):get('Dodge')==true then
		ui.showMessage('Dodge Front')
		self.controls.jump = true
		self.controls.movement = 1
		DodgeButton = 1
	elseif input.isActionPressed(input.ACTION.Sneak) == true and TurnRight(0.2) == true and DodgeButton == 0 and types.Actor.getStance(self) == 0 and storage.playerSection('RESettings1'):get('Dodge')==true then
		ui.showMessage('Dodge Right')
		self.controls.jump = true
		self.controls.sideMovement = 1
		DodgeButton = 1
	elseif input.isActionPressed(input.ACTION.Sneak) == true and TurnLeft(-0.2) == true and DodgeButton == 0 and types.Actor.getStance(self) == 0 and storage.playerSection('RESettings1'):get('Dodge')==true then
		ui.showMessage('Dodge Left')
		self.controls.jump = true
		self.controls.sideMovement = -1
		DodgeButton = 1
	elseif input.isActionPressed(input.ACTION.Sneak) == true and DodgeButton == 1 then
		DodgeButton = 0
		self.controls.sideMovement = 0
		self.controls.movement = 0
		self.controls.jump = false
	end

	---------------test viser uniquement sur pression bouton ->ok
	--if types.Actor.getEquipment(self,16) then
	--	print("weaponcondition="..tostring(weaponcondition))
	--	print("Actual weaponcondition="..tostring(types.Item.itemData(types.Actor.getEquipment(self,16)).condition))
	--end
	if types.Actor.getEquipment(self, 16) and types.Weapon.record(types.Actor.getEquipment(self, 16)).type == 10 and weaponcondition > 0 and types.Actor.getStance(self) == 1 then
		types.Actor.getEquipment(self, 16):sendEvent('setCondition', { value = weaponcondition })
	end
	if types.Actor.getEquipment(self, 16) and types.Actor.getEquipment(self, 16) == EquippedWeapon and types.Item.itemData(types.Actor.getEquipment(self, 16)).condition ~= weaponcondition then
		types.Actor.getEquipment(self, 16):sendEvent('setCondition', { value = weaponcondition })
	end

	if input.isActionPressed(input.ACTION.ToggleWeapon) == false and input.isActionPressed(input.ACTION.Jump) == false and Instantammo ~= 0 then
		Instantammo = 0
		types.Actor.setEquipment(self, { [types.Actor.EQUIPMENT_SLOT.CarriedRight] = types.Actor.getEquipment(self, 16) })
		if types.Actor.inventory(self):findAll(AmmunitionTypes[types.Item.itemData(types.Actor.getEquipment(self, 16)).condition - 10000])[2] == nil then
			core.sendGlobalEvent('RemoveItem',
				{
					Item = types.Actor.inventory(self):findAll(AmmunitionTypes
						[types.Item.itemData(types.Actor.getEquipment(self, 16)).condition - 10000])[1],
					number = types.Item
						.getEnchantmentCharge(types.Actor.getEquipment(self, 16))
				})
		else
			core.sendGlobalEvent('RemoveItem',
				{
					Item = types.Actor.inventory(self):findAll(AmmunitionTypes
						[types.Item.itemData(types.Actor.getEquipment(self, 16)).condition - 10000])[2],
					number = types.Item
						.getEnchantmentCharge(types.Actor.getEquipment(self, 16))
				})
		end
	end

	if (input.isActionPressed(input.ACTION.ToggleWeapon) == true or input.isActionPressed(input.ACTION.Jump) == true) and types.Actor.getEquipment(self, 16) and (AmmoChecked == 1 or types.Actor.getEquipment(self, 16)) then ----degainer l'arme
		types.Actor.setStance(self, 1)
		self.controls.use = 1

		if types.Weapon.record(types.Actor.getEquipment(self, 16)).type == 10 then
			--print(AmmunitionTypes[types.Item.itemData(types.Actor.getEquipment(self,16)).condition-10000])
			if Instantammo == 0 and types.Actor.inventory(self):find(AmmunitionTypes[types.Item.itemData(types.Actor.getEquipment(self, 16)).condition - 10000]) then
				core.sendGlobalEvent('createAmmosinInventory',
					{	ammo = AmmunitionTypes[types.Item.itemData(types.Actor.getEquipment(self, 16)).condition - 10000],
						number =types.Item.getEnchantmentCharge(types.Actor.getEquipment(self, 16)),
						actor = self
					})
				equipped[types.Actor.EQUIPMENT_SLOT.Ammunition] = types.Actor.inventory(self):find(AmmunitionTypes
					[types.Item.itemData(types.Actor.getEquipment(self, 16)).condition - 10000])
				equipped[types.Actor.EQUIPMENT_SLOT.CarriedRight] = EquippedWeapon
				types.Actor.setEquipment(self, equipped)
				Instantammo = 1
			elseif Instantammo == 0 and types.Actor.inventory(self):find(AmmunitionTypes[types.Item.itemData(types.Actor.getEquipment(self, 16)).condition - 10000]) == nil then
				core.sendGlobalEvent('createAmmosinInventory',
					{
						ammo = AmmunitionTypes
							[types.Item.itemData(types.Actor.getEquipment(self, 16)).condition - 10000],
						number =
							types.Item.getEnchantmentCharge(types.Actor.getEquipment(self, 16)),
						actor = self
					})
				Instantammo = 1
			elseif Instantammo == 1 then
				Instantammo = 2
			elseif Instantammo == 2 then
				Instantammo = 3
				equipped[types.Actor.EQUIPMENT_SLOT.Ammunition] = types.Actor.inventory(self):find(AmmunitionTypes[types.Item.itemData(types.Actor.getEquipment(self, 16)).condition - 10000])
				equipped[types.Actor.EQUIPMENT_SLOT.CarriedRight] = EquippedWeapon
				types.Actor.setEquipment(self, equipped)
			end
		end




		----------------------------------------
		local actionbasetime = 4 *core.getGameTimeScale()

		if input.isActionPressed(input.ACTION.Use) and ((types.Item.getEnchantmentCharge(types.Actor.getEquipment(self, 16))~=nil and types.Item.getEnchantmentCharge(types.Actor.getEquipment(self, 16))>0) or types.Weapon.record(types.Actor.getEquipment(self, 16)).type ~= 10) and (core.getGameTime() - shootTimer) > (actionbasetime / types.Weapon.record(types.Actor.getEquipment(self, 16)).speed) then -- Fire!!
			self.controls.use = 0
			shootTimer = (core.getGameTime())
			if types.Weapon.record(types.Actor.getEquipment(self, 16)).type == 10 then
				core.sendGlobalEvent('setCharge',{Item = types.Actor.getEquipment(self, 16),	value = types.Item.getEnchantmentCharge(types.Actor.getEquipment(self, 16)) - 1})
				if types.Weapon.record(tostring(types.Actor.getEquipment(self, 18).recordId) .. "SpecialAmmo")~=true then
					CheckBulletOnScreen()
				end
			end


			local RotZ = self.rotation:getPitch()
			local RotX = self.rotation:getYaw()
			DamageLocalisation = nearby.castRay(
				util.vector3(0, 0, 110) + self.position +
				util.vector3(math.cos(RotZ) * math.sin(RotX), math.cos(RotZ) * math.cos(RotX), -math.sin(RotZ)) * 50,
				util.vector3(0, 0, 110) + self.position +
				util.vector3(math.cos(RotZ) * math.sin(RotX), math.cos(RotZ) * math.cos(RotX), -math.sin(RotZ)) * 1000000)

			if DamageLocalisation.hitObject and DamageLocalisation.hitObject.type == types.Creature then
				DamageLocalisation.hitObject:sendEvent('Damagelocalisation',
					{ Hitpos = DamageLocalisation.hitPos, Player = self })
			end

			---------------------------shotshell -----------en cours
			if types.Actor.getEquipment(self, 18) then
				if types.Weapon.record(types.Actor.getEquipment(self, 18)).enchant then
					if core.magic.enchantments.records[types.Weapon.record(types.Actor.getEquipment(self, 18)).enchant] and string.find(core.magic.enchantments.records[types.Weapon.record(types.Actor.getEquipment(self, 18)).enchant].id, "shotshell") then
						--print("self  " .. tostring(self.position))
						local shelldistance = 1000
						local pellets = types.Weapon.record(types.Actor.getEquipment(self, 16)).chopMinDamage
						local r = 10
						SshellDamage = types.Weapon.record(types.Actor.getEquipment(self, 18)).thrustMinDamage
						SshellEnchant = core.magic.enchantments.records[types.Weapon.record(types.Actor.getEquipment(self, 18)).enchant]
						for a = 1, pellets do
							--SShellPos=util.transform.move(0,0,70)*self.position+ util.transform.rotate(1,util.vector3(0,0,math.pi/2))self.rotation*util.vector3(0,1,0)*100
							SShellRotX = RotX + math.random(-5,5)*math.pi*types.Weapon.record(types.Actor.getEquipment(self, 16)).slashMinDamage/(180*11)
							SShellRotZ = RotZ + math.random(-5,5)*math.pi*types.Weapon.record(types.Actor.getEquipment(self, 16)).slashMinDamage/(180*11)
							local ray = nearby.castRay(util.vector3(0, 0, 80) + self.position,
								util.vector3(0, 0, 80) + self.position +
								util.vector3(math.cos(SShellRotZ) * math.sin(SShellRotX),math.cos(SShellRotZ) * math.cos(SShellRotX), -math.sin(SShellRotZ)) * shelldistance,{ ignore = self })
							--print(ray.hitPos)
							--print(ray.hitObject)
							if ray.hitObject and ray.hitObject.type == types.Creature and types.Actor.isDead(ray.hitObject)==nil then
								ray.hitObject:sendEvent('DamageEffects', { damages = SshellDamage }) --,enchant=SshellEnchant})
							end
						end
					end
				end
			end
			-----------------------------Special Ammo-----------------------------------------------------------------
			--print(tostring(types.Actor.getEquipment(self, 18).recordId) .. "SpecialAmmo")
			--------SpecialAmmo------ en cours
			if types.Actor.getEquipment(self, 18) then
				if types.Weapon.record(tostring(types.Actor.getEquipment(self, 18).recordId) .. "SpecialAmmo") then
					--print(tostring(types.Actor.getEquipment(self, 18).recordId) .. "SpecialAmmo")
					core.sendGlobalEvent('CreateSpecialAmmo',
						{ Player = self, Ammo = tostring(types.Actor.getEquipment(self, 18).recordId .. "SpecialAmmo") })
				end
			end
			----------------------------------------------------------------------------------------------


		elseif input.isActionPressed(input.ACTION.Use) and types.Item.getEnchantmentCharge(types.Actor.getEquipment(self, 16)) == 0 and (core.getGameTime()- shootTimer) > (actionbasetime / types.Weapon.record(types.Actor.getEquipment(self, 16)).speed) then
			ui.showMessage("Weapon empty")
			shootTimer = (core.getGameTime())
			ambient.playSound("ClipEmpty")
			types.Actor.setEquipment(self, {
				[types.Actor.EQUIPMENT_SLOT.CarriedRight] = types.Actor.getEquipment(self,
					16)
			})
		elseif input.isActionPressed(input.ACTION.AutoMove) == true and (core.getGameTime() - shootTimer) > (actionbasetime / types.Weapon.record(types.Actor.getEquipment(self, 16)).speed) and storage.playerSection('RESettings1'):get('Reload')==true then
			shootTimer = (core.getGameTime())

			if (types.Actor.inventory(self):countOf(AmmunitionTypes[types.Item.itemData(types.Actor.getEquipment(self, 16)).condition - 10000]) - types.Item.getEnchantmentCharge(types.Actor.getEquipment(self, 16))) == 0 then
				ambient.playSound("ClipEmpty")
				ui.showMessage("No more ammo")
			elseif types.Item.getEnchantmentCharge(types.Actor.getEquipment(self, 16)) == core.magic.enchantments.records[types.Weapon.record(types.Actor.getEquipment(self, 16)).enchant].charge then
				ui.showMessage("Weapon full")
			elseif (types.Actor.inventory(self):countOf(AmmunitionTypes[types.Item.itemData(types.Actor.getEquipment(self, 16)).condition - 10000]) - types.Item.getEnchantmentCharge(types.Actor.getEquipment(self, 16))) >= (core.magic.enchantments.records[types.Weapon.record(types.Actor.getEquipment(self, 16)).enchant].charge - types.Item.getEnchantmentCharge(types.Actor.getEquipment(self, 16))) then
				ammosloadable = core.magic.enchantments.records[types.Weapon.record(types.Actor.getEquipment(self, 16)).enchant]
					.charge - types.Item.getEnchantmentCharge(types.Actor.getEquipment(self, 16))
				--print("ammosload" .. tostring(ammosloadable))
				ui.showMessage("reload")
				core.sendGlobalEvent('setCharge',
					{
						Item = types.Actor.getEquipment(self, 16),
						value = core.magic.enchantments.records
							[types.Weapon.record(types.Actor.getEquipment(self, 16)).enchant].charge
					})
				Instantammo = 1
			elseif (types.Actor.inventory(self):countOf(AmmunitionTypes[types.Item.itemData(types.Actor.getEquipment(self, 16)).condition - 10000]) - types.Item.getEnchantmentCharge(types.Actor.getEquipment(self, 16))) < (core.magic.enchantments.records[types.Weapon.record(types.Actor.getEquipment(self, 16)).enchant].charge - types.Item.getEnchantmentCharge(types.Actor.getEquipment(self, 16))) then
				--print("low ammo")
				ammosloadable = types.Actor.inventory(self):countOf(AmmunitionTypes
						[types.Item.itemData(types.Actor.getEquipment(self, 16)).condition - 10000]) -
					types.Item.getEnchantmentCharge(types.Actor.getEquipment(self, 16))
				ui.showMessage("reload")
				core.sendGlobalEvent('setCharge',
					{
						Item = types.Actor.getEquipment(self, 16),
						value = ammosloadable +
							types.Item.getEnchantmentCharge(types.Actor.getEquipment(self, 16))
					})
				Instantammo = 1
			end
		elseif ToggleWeaponButton == false then                         -------first autotarget
			weaponcondition = types.Item.itemData(types.Actor.getEquipment(self, 16)).condition
			if input.isActionPressed(input.ACTION.ToggleWeapon) == true and storage.playerSection('RESettings1'):get('AutoAim')==true then -----cible bow
				ToggleWeaponButton = true
				changetarget = 0
				TargetBOW = {
					position = self.position +
						util.vector3(math.cos(self.rotation:getPitch()) * math.sin(self.rotation:getYaw()),
							math.cos(self.rotation:getPitch()) * math.cos(self.rotation:getYaw()),
							-math.sin(self.rotation:getPitch())) * 100000
				}
				--print(TargetBOW.position)
				for i, actors in pairs(nearby.actors) do
					if actors.type == types.Creature and string.find(types.Creature.record(actors).mwscript, "_attackobjects_") == nil and (self.position - TargetBOW.position):length() > (self.position - actors.position):length() and types.Actor.stats.dynamic.health(actors).current > 0 then
						TargetBOW = actors
						table.insert(TargetedBOW, TargetBOW)
						--print((self.position-TargetBOW.position):length())
						--print(TargetBOW)
					end
				end

				ui.showMessage(tostring(TargetBOW))
				TurnToTarget(TargetBOW)
			elseif input.isActionPressed(input.ACTION.Jump) == true and storage.playerSection('RESettings1'):get('AutoAim')==true then -------------cible attackobject
				ToggleWeaponButton = true
				changetarget = 0
				TargetAttackObject = {
					position = self.position +
						util.vector3(math.cos(self.rotation:getPitch()) * math.sin(self.rotation:getYaw()),
							math.cos(self.rotation:getPitch()) * math.cos(self.rotation:getYaw()),
							-math.sin(self.rotation:getPitch())) * 100000
				}
				--print(TargetAttackObject.position)
				for i, actors in pairs(nearby.actors) do
					--print(actors)
					if actors.type == types.Creature and types.Creature.record(actors).mwscript and string.find(types.Creature.record(actors).mwscript, "_attackobjects_") and (self.position - TargetAttackObject.position):length() > (self.position - actors.position):length() and types.Actor.stats.dynamic.health(actors).current > 0 then
						TargetAttackObject = actors
					end
				end

				ui.showMessage(tostring(TargetAttackObject))
				TurnToTarget(TargetAttackObject)
			end
		elseif input.isActionPressed(input.ACTION.Sneak) and input.isActionPressed(input.ACTION.ToggleWeapon) and changetarget == 0 and storage.playerSection('RESettings1'):get('AutoAim')==true then --------Change target BOW
			changetarget = 1
			for i, actors in pairs(nearby.actors) do
				BOWchecked = 0
				if actors.type == types.Creature and string.find(types.Creature.record(actors).mwscript, "_attackobjects_") == nil and types.Actor.stats.dynamic.health(actors).current > 0 then
					for j, BOW in pairs(TargetedBOW) do
						if actors == BOW then
							BOWchecked = 1
						end
					end
					if BOWchecked == 0 then
						TargetBOW = actors
						table.insert(TargetedBOW, TargetBOW)
						break
					end
				end
			end
			if TargetedBOW[#TargetedBOW] == TargetBOW and BOWchecked == 1 then
				TargetedBOW = {}
			end

			ui.showMessage(tostring(TargetBOW))
			TurnToTarget(TargetBOW)
		elseif input.isActionPressed(input.ACTION.Sneak) and input.isActionPressed(input.ACTION.Jump) and changetarget == 0 then --------Change target attackobject
			changetarget = 1
			for i, actors in pairs(nearby.actors) do
				AttackObjectchecked = 0
				if actors.type == types.Creature and string.find(types.Creature.record(actors).mwscript, "_attackobjects_") and types.Actor.stats.dynamic.health(actors).current > 0 then
					for j, AttackObject in pairs(TargetedAttackObject) do
						if actors == AttackObject then
							AttackObjectchecked = 1
						end
					end
					if AttackObjectchecked == 0 then
						TargetAttackObject = actors
						table.insert(TargetedAttackObject, TargetAttackObject)
						break
					end
				end
			end
			if TargetedAttackObject[#TargetedAttackObject] == TargetAttackObject and AttackObjectchecked == 1 then
				TargetedAttackObject = {}
			end

			ui.showMessage(tostring(TargetAttackObject))
			TurnToTarget(TargetAttackObject)
		elseif input.isActionPressed(input.ACTION.Sneak) == false then
			changetarget = 0
		end
	else
		types.Actor.setStance(self, 0)
		ToggleWeaponButton = false
		TargetedBOW = {}
		TargetAttackObject = {}
	end

	if onFrameHealth ~= types.Actor.stats.dynamic.health(self).current then
		onFrameHealth = types.Actor.stats.dynamic.health(self).current
	end





end










local function LiveSelection(data)
	LiveSelectionChoice1=data.Choice1
	LiveSelectionChoice2=data.Choice2
	negativeshader:enable()
	LiveSelectionUI = ui.create({
		layer = 'HUD',
		type = ui.TYPE.Flex,
		props = { autoSize = false, anchor = util.vector2(0.5, 0), relativeSize = util.vector2(1 / 2, 1 / 2), relativePosition = util.vector2(0.5, 0.5), },
		content = ui.content {
	
			{ template = nil, props = { relativeSize = util.vector2(1, 1 / 10) }, content = ui.content {
				{ type = ui.TYPE.Text, props = { text = data.Choice1, textSize = 60*textSizeRatio, textColor = util.color.rgb(0, 0, 0), relativePosition= util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5),} } } },
	
			{ type = ui.TYPE.Text, props = { text = " ", textSize = 50*textSizeRatio, textColor = util.color.rgb(1, 1, 1) }, },
	
			{ template = nil, props = { relativeSize = util.vector2(1, 1 / 10) }, content = ui.content {
				{ type = ui.TYPE.Text, props = { text = data.Choice2, textSize = 60*textSizeRatio, textColor = util.color.rgb(0, 0, 0), relativePosition= util.vector2(0.5, 0.5) , anchor = util.vector2(0.5, 0.5),} } } } }
	})
	WrapperTemplate.props.color=Colors.Blue
end


function Framewait(frametowait)
	if frame == nil then
		frame = 0
	elseif frame == frametowait then
		frame = 0
		return (true)
	else
		frame = frame + 1
	end
end

local Saves

local function SavingMenu(data)

	--print("saving")
	core.sendGlobalEvent("ReturnGlobalVariable",{variable="SavingMenu",player=self,value=0})
	Saves=data.Value
	--for i, save in pairs(Saves) do print(save['description']) end
	--print(Saves[11])

	if (SavingMenuUI == nil or SavingMenuUI.layout == nil) then	
		I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
		SavingMenuUI=ui.create({layer = 'HUD',  type = ui.TYPE.Image,
		props = {relativeSize = util.vector2(1,1),relativePosition=util.vector2(0.5, 0.5),anchor = util.vector2(0.5, 0.5),resource = ui.texture{path ="textures/bgd/RE2/TypeWritter.dds"},},
		content=ui.content{
			{ type = ui.TYPE.Flex, props = {relativeSize = util.vector2(1,1),relativePosition=util.vector2(0.6, 0.7),anchor = util.vector2(0.5, 0.5)}, content=ui.content{
				{ type = ui.TYPE.Text,  props = { text = " 1 . "..Saves[1]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White} },
				{ type = ui.TYPE.Text,  props = { text = " 2 . "..Saves[2]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Text,  props = { text = " 3 . "..Saves[3]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Text,  props = { text = " 4 . "..Saves[4]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Text,  props = { text = " 5 . "..Saves[5]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Text,  props = { text = " 6 . "..Saves[6]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Text,  props = { text = " 7 . "..Saves[7]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Text,  props = { text = " 8 . "..Saves[8]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Text,  props = { text = " 9 . "..Saves[9]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Text,  props = { text = "10 . "..Saves[10]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White } },
			}},
			{ type = ui.TYPE.Flex, props = {relativeSize = util.vector2(1,1),relativePosition=util.vector2(0.55, 0.72),anchor = util.vector2(0.5, 0.5)}, content=ui.content{
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(30, 30), visible = true, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "",relativePosition=util.vector2(2/16, 7/16), textSize = 35*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(30, 30), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "",relativePosition=util.vector2(2/16, 7/16), textSize = 35*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(30, 30), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "",relativePosition=util.vector2(2/16, 7/16), textSize = 35*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(30, 30), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "",relativePosition=util.vector2(2/16, 7/16), textSize = 35*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(30, 30), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "",relativePosition=util.vector2(2/16, 7/16), textSize = 35*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(30, 30), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "",relativePosition=util.vector2(2/16, 7/16), textSize = 35*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(30, 30), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "",relativePosition=util.vector2(2/16, 7/16), textSize = 35*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(30, 30), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "",relativePosition=util.vector2(2/16, 7/16), textSize = 35*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(30, 30), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "",relativePosition=util.vector2(2/16, 7/16), textSize = 35*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(30, 30), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
			}}
		
		}})
			
	end
end



local function ElectricalPanelPuzzle()
	if (ElectricalPanelPuzzleUI == nil or ElectricalPanelPuzzleUI.layout == nil) then
		I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
		ElectricalPanelPuzzleUI=ui.create({layer = 'HUD',  type = ui.TYPE.Image,
		props = {relativeSize = util.vector2(1,1),relativePosition=util.vector2(0.5, 0.5),anchor = util.vector2(0.5, 0.5),resource = ui.texture{path ="textures/Puzzles/ElectricalPanel/ElectricalPanel.dds"},},
		content=ui.content{
			{ type = ui.TYPE.Image,  props = {resource = ui.texture{path ="textures/BorderBox.dds"},relativeSize=util.vector2(1/20, 1/19),relativePosition=util.vector2(6/30, 12/28),} },
			{ type = ui.TYPE.Text,  props = { text = "50",relativePosition=util.vector2(2/16, 7/16), textSize = 90*textSizeRatio, textColor = Colors.Red } },
			{ type = ui.TYPE.Text,  props = { text = "",relativePosition=util.vector2(5/18, 7/16), textSize = 90*textSizeRatio, textColor = Colors.Red } },
			{ type = ui.TYPE.Text,  props = { text = "",relativePosition=util.vector2(8/19, 7/16), textSize = 90*textSizeRatio, textColor = Colors.Red } },
			{ type = ui.TYPE.Text,  props = { text = "",relativePosition=util.vector2(11/19, 7/16), textSize = 90*textSizeRatio, textColor = Colors.Red } },
			{ type = ui.TYPE.Text,  props = { text = "",relativePosition=util.vector2(15/19, 7/16), textSize = 90*textSizeRatio, textColor = Colors.Red } },
			{ type = ui.TYPE.Image,  props = {resource = ui.texture{path ="textures/Puzzles/ElectricalPanel/selected.dds"},relativeSize=util.vector2(1/20, 1/19),} },
			{ type = ui.TYPE.Image,  props = {resource = ui.texture{path ="textures/Puzzles/ElectricalPanel/selected.dds"},relativeSize=util.vector2(1/20, 1/19),} },
			{ type = ui.TYPE.Image,  props = {resource = ui.texture{path ="textures/Puzzles/ElectricalPanel/selected.dds"},relativeSize=util.vector2(1/20, 1/19),} },
			{ type = ui.TYPE.Image,  props = {resource = ui.texture{path ="textures/Puzzles/ElectricalPanel/selected.dds"},relativeSize=util.vector2(1/20, 1/19),} }
		
		}})
	end
end

--[[
local function ChoiceYesNo(data)
	if (MenuYesNo == nil or MenuYesNo.layout == nil) then
		MWscriptGameObject = nil
		I.UI.setMode(I.UI.MODE.Interface, { windows = {} })

		MenuYesNoLayout = {
			layer = 'Console',
			type = ui.TYPE.Flex,
			props = { autoSize = true, horizontal = true, relativePosition = util.vector2(1 / 2, 7 / 8), anchor = util.vector2(0, 0), },
			content = ui.content {
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(20, 20), visible = true, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "Yes", textSize = 30*textSizeRatio, textColor = util.color.rgb(1, 1, 1) } },
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(20, 20), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "No", textSize = 30*textSizeRatio, textColor = util.color.rgb(1, 1, 1) } },
			}
		}

		MenuYesNo = ui.create(MenuYesNoLayout)
		MWscriptGameObject = data.GameObject
	end
end


local function Choice15(data)
	if data.Value == -1 and (Menu15 == nil or Menu15.layout == nil) then
		MWscriptGameObject = nil

		I.UI.setMode(I.UI.MODE.Interface, { windows = {} })

		Menu15Layout = {
			layer = 'Console',
			type = ui.TYPE.Flex,
			props = { autoSize = true, horizontal = true, relativePosition = util.vector2(1 / 2, 7 / 8), anchor = util.vector2(0, 0), },
			content = ui.content {
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(20, 20), visible = true, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "1", textSize = 30*textSizeRatio, textColor = util.color.rgb(1, 1, 1) } },
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(20, 20), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "2", textSize = 30*textSizeRatio, textColor = util.color.rgb(1, 1, 1) } },
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(20, 20), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "3", textSize = 30*textSizeRatio, textColor = util.color.rgb(1, 1, 1) } },
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(20, 20), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "4", textSize = 30*textSizeRatio, textColor = util.color.rgb(1, 1, 1) } },
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(20, 20), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "5", textSize = 30*textSizeRatio, textColor = util.color.rgb(1, 1, 1) } },
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(20, 20), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "6", textSize = 30*textSizeRatio, textColor = util.color.rgb(1, 1, 1) } },
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(20, 20), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "7", textSize = 30*textSizeRatio, textColor = util.color.rgb(1, 1, 1) } },
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(20, 20), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "8", textSize = 30*textSizeRatio, textColor = util.color.rgb(1, 1, 1) } },
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(20, 20), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "9", textSize = 30*textSizeRatio, textColor = util.color.rgb(1, 1, 1) } },
				{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(20, 20), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } },
				{ type = ui.TYPE.Text,  props = { text = "0", textSize = 30*textSizeRatio, textColor = util.color.rgb(1, 1, 1) } },
			}
		}

		Menu15 = ui.create(Menu15Layout)
		MWscriptGameObject = data.GameObject
	end
end
]]--





local MenuSelection={}
local MenuSelectionContent={}

local function ChoicesSelection(data)
	if MenuSelection==nil or MenuSelection.layout==nil then
		I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
		MenuSelection={}
		MenuSelectionContent={}
		for i, variable in pairs(data.selection) do
			--print(variable)
			table.insert(MenuSelectionContent,{ type = ui.TYPE.Image, props = { anchor = util.vector2(0, 0), size = util.vector2(20, 20), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } })
			table.insert(MenuSelectionContent,{ type = ui.TYPE.Text,  props = { text = variable, textSize = 30*textSizeRatio, textColor = util.color.rgb(1, 1, 1) } })
		end
		MenuSelection=ui.create({layer = 'Console',type = ui.TYPE.Flex,props = { autoSize = true, horizontal = true, relativePosition = util.vector2(1 / 2, 7 / 8), anchor = util.vector2(0, 0), },
			content =ui.content(MenuSelectionContent)})
		MenuSelection.layout.content[1].props.visible=true
		MenuSelection:update()
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



local function onFrame(dt)


	if camera.getMode()==0 and storage.playerSection('RESettings1'):get('FixedCamera')==false then
		camera.setMode(1)
	elseif (camera.getMode()==1 or camera.getMode()==2) and storage.playerSection('RESettings1'):get('FixedCamera')==true then
		self:sendEvent('CameraPos', {source=self, BGDepth=BGDepth,CamPos=CamPos, CamAng=CamAng, ActiveCam=activecam,ActiveBkg=activeBkg,MSKList=MSKlist})
	end 
	
	if MapsUtils["RoomsVisited"][1]==nil then -----------------First room added to maps
		LastRoom=self.cell.name
		for i, Area in ipairs(Maps) do
			for j, Zone in ipairs(Area[2]) do
				for k, Room in ipairs(Zone[2]) do
					if Room==self.cell.name then
						if MapsUtils["RoomsVisited"][i]==nil then
							MapsUtils["RoomsVisited"][i]={}
						end
						MapsUtils["RoomsVisited"][i][1]=Area[1]
						if 	MapsUtils["RoomsVisited"][i][2]==nil then
							MapsUtils["RoomsVisited"][i][2]={}
						end
						if 	MapsUtils["RoomsVisited"][i][2][j]==nil then
							MapsUtils["RoomsVisited"][i][2][j]={}
						end
						MapsUtils["RoomsVisited"][i][2][j][1]=Zone[1]
						if 
						MapsUtils["RoomsVisited"][i][2][j][2]==nil then
							MapsUtils["RoomsVisited"][i][2][j][2]={}
						end
						MapsUtils["RoomsVisited"][i][2][j][2][k]=Room
					end
				end
			end
		end
	end
	if LastRoom~=self.cell.name then ----------New room added to maps
		LastRoom=self.cell.name
		for i, Area in ipairs(Maps) do
			--print(Area[1])
			for j, Zone in ipairs(Area[2]) do
				--print(Zone[1])
				for k, Room in ipairs(Zone[2]) do
					if Room==self.cell.name then
						if MapsUtils["RoomsVisited"][i]==nil then
							MapsUtils["RoomsVisited"][i]={}
						end
						MapsUtils["RoomsVisited"][i][1]=Area[1]
						if 	MapsUtils["RoomsVisited"][i][2]==nil then
							MapsUtils["RoomsVisited"][i][2]={}
						end
						if 	MapsUtils["RoomsVisited"][i][2][j]==nil then
							MapsUtils["RoomsVisited"][i][2][j]={}
						end
						MapsUtils["RoomsVisited"][i][2][j][1]=Zone[1]
						if 
						MapsUtils["RoomsVisited"][i][2][j][2]==nil then
							MapsUtils["RoomsVisited"][i][2][j][2]={}
						end
						MapsUtils["RoomsVisited"][i][2][j][2][k]=Room
						print(MapsUtils["RoomsVisited"][i][2][j][2][k])
					end
				end
			end
		end


--		print("check table")
--		for i,area in ipairs(MapsUtils["RoomsVisited"]) do
--			print(area[1])
--			for j, zone in ipairs(area[2]) do
--				print(zone[1])
--				for k, room in pairs(zone[2]) do
--					print(room)
--				end
--			end
--		end


	end

	if MapUI then
		if MapUI.layout then---------------------------- Navigate in Maps
			--print(MapsUtils.Blink.Room)
			if MapsUtils.Blink.Room>0 then
				if MapUI.layout.content[MapsUtils.Blink.Room] then
					if MapUI.layout.content[MapsUtils.Blink.Room].props.alpha>=1 then
						MapsUtils.Blink.Value=-.02
					elseif MapUI.layout.content[MapsUtils.Blink.Room].props.alpha<=0.2 then
						MapsUtils.Blink.Value=0.02
					end
					MapUI.layout.content[MapsUtils.Blink.Room].props.alpha=MapUI.layout.content[MapsUtils.Blink.Room].props.alpha+MapsUtils.Blink.Value
					MapUI:update()
					
					if input.isActionPressed(input.ACTION.ToggleWeapon) and ToggleWeaponButtonMap==false then
						ToggleWeaponButtonMap=true
							if CheckTableUD(MapsUtils["RoomsVisited"][AreaMap][2][ZoneMap][2],RoomMap,"+")~=0 then
								--print("here")
								RoomMap=CheckTableUD(MapsUtils["RoomsVisited"][AreaMap][2][ZoneMap][2],RoomMap,"+")+RoomMap
								core.sendGlobalEvent('AskObjectsInWorld',{player=self,maps=Maps})
								ambient.playSound("Cursor")
							end

					elseif input.isActionPressed(input.ACTION.ToggleWeapon)==false and ToggleWeaponButtonMap==true then
						ToggleWeaponButtonMap=false
					elseif input.isActionPressed(input.ACTION.Sneak) and ToggleSneakButtonMap==false then
						ToggleSneakButtonMap=true
							if CheckTableUD(MapsUtils["RoomsVisited"][AreaMap][2][ZoneMap][2],RoomMap,"-")~=0 then
								--print("there")
								RoomMap=CheckTableUD(MapsUtils["RoomsVisited"][AreaMap][2][ZoneMap][2],RoomMap,"-")+RoomMap
								core.sendGlobalEvent('AskObjectsInWorld',{player=self,maps=Maps})
								ambient.playSound("Cursor")
							end
					elseif input.isActionPressed(input.ACTION.Sneak)==false and ToggleSneakButtonMap==true then
						ToggleSneakButtonMap=false				
					end

				end
			end




			if MoveForward(-0.2) and MenuSelectStop==false then ------------Show previous Zone
				MenuSelectStop=true
				for i, zone in pairs(Maps[AreaMap][2]) do
					if Maps[AreaMap][2][ZoneMap+i] then
						if  MapsUtils["RoomsVisited"][AreaMap]then
							if  MapsUtils["RoomsVisited"][AreaMap][2][ZoneMap+i] then
								ZoneMap=ZoneMap+i
								for j, room in pairs(Maps[AreaMap][2][ZoneMap][2]) do
									if room== self.cell.name then
										RoomMap=j
									else
										RoomMap=CheckTableUD(MapsUtils["RoomsVisited"][AreaMap][2][ZoneMap][2],0,"+")
									end
								end
								core.sendGlobalEvent('AskObjectsInWorld',{player=self,maps=Maps})
								ambient.playSound("Book Page")
							end
						elseif MapsUtils["RoomsMapped"][AreaMap] then
							if MapsUtils["RoomsMapped"][AreaMap][2][ZoneMap+i] then
								ZoneMap=ZoneMap+i
								RoomMap=1
								core.sendGlobalEvent('AskObjectsInWorld',{player=self,maps=Maps})
								ambient.playSound("Book Page")
							end
						end
					end
				end
			elseif MoveBackward(0.2) and MenuSelectStop==false then ------------Show next Zone
				MenuSelectStop=true
				for i, zone in pairs(Maps[AreaMap][2]) do
					if (ZoneMap-i)>0 then
						if  MapsUtils["RoomsVisited"][AreaMap]then
							if  MapsUtils["RoomsVisited"][AreaMap][2][ZoneMap-i] then
								ZoneMap=ZoneMap-i
								for j, room in pairs(Maps[AreaMap][2][ZoneMap][2]) do
									if room== self.cell.name then
										RoomMap=j
									else
										RoomMap=CheckTableUD(MapsUtils["RoomsVisited"][AreaMap][2][ZoneMap][2],0,"+")
									end
								end
								core.sendGlobalEvent('AskObjectsInWorld',{player=self,maps=Maps})
								ambient.playSound("Book Page")
							end
						elseif MapsUtils["RoomsMapped"][AreaMap] then
							if MapsUtils["RoomsMapped"][AreaMap][2][ZoneMap-i] then
								ZoneMap=ZoneMap-i
								RoomMap=1
								core.sendGlobalEvent('AskObjectsInWorld',{player=self,maps=Maps})
								ambient.playSound("Book Page")
							end
						end
					end
				end
			elseif TurnLeft(-0.2) and MenuSelectStop==false then ------------Show previous Area
				MenuSelectStop=true
				local lasti=0
				for i, area in pairs(Maps) do
					if i<AreaMap then
						if  MapsUtils["RoomsVisited"][i] or MapsUtils["RoomsMapped"][i] then
							lasti=i
							for k, zone in pairs(Maps[i][2]) do
								if MapsUtils["RoomsVisited"][i] then
									if  MapsUtils["RoomsVisited"][i][2][k] then
										ZoneMap=k
										break
									end
								elseif MapsUtils["RoomsMapped"][i]then
									if  MapsUtils["RoomsMapped"][i][2][k] then
										ZoneMap=k
										break
									end
								end
							end
							for l, room in pairs(Maps[i][2][ZoneMap][2]) do
								RoomMap=l
								break
							end
						end
					elseif i==AreaMap then
						if lasti~=0 then
							AreaMap=lasti
							core.sendGlobalEvent('AskObjectsInWorld',{player=self,maps=Maps})
							ambient.playSound("Book Page")
							break
						end
					end
				end
			elseif TurnRight(0.2)  and MenuSelectStop==false then ------------Show next Area
				MenuSelectStop=true	
				for i, area in pairs(Maps) do
					if i>AreaMap then
						if  MapsUtils["RoomsVisited"][i] or MapsUtils["RoomsMapped"][i] then
							for k, zone in pairs(Maps[i][2]) do
								if MapsUtils["RoomsVisited"][i] then
									if  MapsUtils["RoomsVisited"][i][2][k] then
										ZoneMap=k
										break
									end
								elseif MapsUtils["RoomsMapped"][i] then
									if  MapsUtils["RoomsMapped"][i][2][k] then
										ZoneMap=k
										break
									end
								end
							end
							for l, room in pairs(Maps[i][2][ZoneMap][2]) do
								RoomMap=l
								break
							end
							AreaMap=i
							core.sendGlobalEvent('AskObjectsInWorld',{player=self,maps=Maps})
							ambient.playSound("Book Page")
							break
						end
					end
				end
			end



			
--			if TurnRight(0.2) and CheckTableUD(MapsUtils["RoomsVisited"],AreaMap,"+")~=0 and MenuSelectStop==false then
--				MenuSelectStop=true
--				AreaMap=CheckTableUD(MapsUtils["RoomsVisited"][AreaMap],"+")+AreaMap
--				ZoneMap=CheckTableUD(MapsUtils["RoomsVisited"][AreaMap][2],0,"+")
--				RoomMap=CheckTableUD(MapsUtils["RoomsVisited"][AreaMap][2][ZoneMap][2],0,"+")
--				core.sendGlobalEvent('AskObjectsInWorld',{player=self,maps=Maps})
--				ambient.playSound("Book Page")
--			end
--			if TurnLeft(-0.2) and CheckTableUD(MapsUtils["RoomsVisited"],AreaMap,"-")~=0 and MenuSelectStop==false then
--				MenuSelectStop=true
--				AreaMap=CheckTableUD(MapsUtils["RoomsVisited"][AreaMap],"-")+AreaMap
--				ZoneMap=CheckTableUD(MapsUtils["RoomsVisited"][AreaMap][2],0,"+")
--				RoomMap=CheckTableUD(MapsUtils["RoomsVisited"][AreaMap][2][ZoneMap][2],0,"+")
--				core.sendGlobalEvent('AskObjectsInWorld',{player=self,maps=Maps})
--				ambient.playSound("Book Page")
--			end


		end
	end






	UI.RunningUI(MoveForward,MoveBackward,TurnLeft,TurnRight,Colors,Saves,SavingMenuUI, MapUI, MapsUtils, Maps)

	Puzzles.RunningPuzzles(self,input,util,core,I,MoveForward,MoveBackward,TurnLeft,TurnRight,Colors,
	MenuYesNo,Menu15,ElectricalPanelPuzzleUI,MenuSelection)
	
	

	PlaceCamera.PositionnningCamera(util,input,camera,core,BGDepth,activecam,activeBkg,MSKlist,TurnLeft,TurnRight,MoveForward,MoveBackward,SwitchZonePoints)


	---- picking item 2/2
	if PickUpItem[3] == true and PickUpItem[4] ~= true and (input.isActionPressed(input.ACTION.Use) or input.isActionPressed(input.ACTION.Inventory)) then
		ShowInventory()
		InventoryItemSelected[2] = nil
		PickUpItem[4] = true
	end
	if PickUpItem[4] == true and PickUpItem[5] ~= true and input.isActionPressed(input.ACTION.Use) == false and input.isActionPressed(input.ACTION.Inventory) == false then
		PickUpItem[5] = true
	end
	if PickUpItem[2] == true and PickUpItem[5] == true and PickUpItem[6] ~= true and (input.isActionPressed(input.ACTION.Use) == true or input.isActionPressed(input.ACTION.Inventory) == true) then
		ShowInventory()
		InventoryItemSelected[2] = nil
		PickUpItem[6] = true
	end
	if PickUpItem[6] == true and PickUpItem[7] ~= true and input.isActionPressed(input.ACTION.Use) == false and input.isActionPressed(input.ACTION.Inventory) == false then
		PickUpItem[7] = true
	end
	if (PickUpItem[7] == true or (PickUpItem[2] == false and PickUpItem[5] == true)) and (input.isActionPressed(input.ACTION.Use) == true or input.isActionPressed(input.ACTION.Inventory) == true) then
		Inventory:destroy()
		ShowItemIcon:destroy()
		PickUpItem = {}
		I.UI.removeMode(I.UI.MODE.Interface)
	end





	----------- Inventaire
	if I.UI.getMode() then
		Overload()
	end




	if Inventory and Inventory.layout and (MenuYesNo == nil or MenuYesNo.layout == nil) and (Menu15 == nil or Menu15.layout == nil) and (ElectricalPanelPuzzleUI == nil or ElectricalPanelPuzzleUI.layout == nil) then
		if doOnceMenu == 0 then
			doOnceMenu = 1
			MenuSelectStop = false
			SelectedItemLayout = {
				layer = 'Windows',
				type = ui.TYPE.Image,
				props = {
					size = util.vector2(ui.screenSize().x / 10, ui.screenSize().y / 9),
					relativePosition = util.vector2(3 / 4, 1 / 3),
					anchor = util.vector2(0, 0),
					resource = ui.texture { path = "textures/SelectedItem.dds" },
				},
			}
			if InventoryItemSelected[2] then
				SelectedItem = ui.create(SelectedItemLayout)
			end


			if types.Actor.getEquipment(self, 16) then
				iconpath = types.Weapon.record(types.Actor.getEquipment(self, 16)).icon
			else
				iconpath = "icons/No Item.dds"
			end
			EquippedWeaponDisplay = ui.create({ name = "EquippedWeapon", layer = 'Windows', type = ui.TYPE.Image, props = { relativeSize = util.vector2(1 / 6, 1 / 6), relativePosition = util.vector2(1 / 2, 1 / 4), anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = iconpath }, }, })

			Portrait = ui.create({ name = "Portrait", layer = 'Windows', type = ui.TYPE.Image, props = { relativeSize = util.vector2(1 / 7, 1 / 5), relativePosition = util.vector2(1 / 8, 1 / 4), anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'textures/Portrait/' .. tostring(types.NPC.record(self).race) .. '.jpg' }, }, })
			if types.Actor.activeEffects(self):getEffect("poison") and types.Actor.activeEffects(self):getEffect("poison").magnitude > 0 then
				path1 = 'textures/Lifebar/Poison/'
			elseif (onFrameHealth / types.Actor.stats.dynamic.health(self).base) >= 0.8 then
				path1 = 'textures/Lifebar/Fine/'
			elseif (onFrameHealth / types.Actor.stats.dynamic.health(self).base) <= 0.3 then
				path1 = 'textures/Lifebar/Danger/'
			else
				path1 = 'textures/Lifebar/Caution/'
			end

			path3 = path1 .. '1.jpg'
			Lifebare = ui.create({ name = "LifeBare", layer = 'Windows', type = ui.TYPE.Image, props = { relativeSize = util.vector2(1 / 5, 1 / 6), relativePosition = util.vector2(1 / 6, 1 / 4), anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = path3 }, }, })
		end
		if (core.getRealTime() - lifebarTimer) > 0.04 then
			path2 = path2 + 1
			lifebarTimer = core.getRealTime()
			if path2 == 55 then
				path2 = 1
				if types.Actor.activeEffects(self):getEffect("poison") and types.Actor.activeEffects(self):getEffect("poison").magnitude > 0 then
					path1 = 'textures/Lifebar/Poison/'
				elseif (onFrameHealth / types.Actor.stats.dynamic.health(self).base) >= 0.8 then
					path1 = 'textures/Lifebar/Fine/'
				elseif (onFrameHealth / types.Actor.stats.dynamic.health(self).base) <= 0.3 then
					path1 = 'textures/Lifebar/Danger/'
				else
					path1 = 'textures/Lifebar/Caution/'
				end
			end

			path3 = path1 .. path2 .. ".jpg"
			Lifebare.layout.props = {
				relativeSize = util.vector2(1 / 5, 1 / 6),
				relativePosition = util.vector2(0, 0),
				anchor =
					util.vector2(-1, -1),
				resource = ui.texture { path = path3 },
			}
			if Lifebare then
				Lifebare:update()
			end
		end



		----------Naviguer dans inventaire

		if InventoryItemSelected[2] and TurnLeft(-0.2) == true and InventoryItemSelected[3] == nil and InventoryItemSelected[4] == nil and InventoryItemSelected[2] ~= 1 and MenuSelectStop == false then
			InventoryItemSelected[2] = InventoryItemSelected[2] - 1
			ambient.playSound("Cursor")
			MenuSelectStop = true
			if InventoryItems[InventoryItemSelected[2]] then
				ui.showMessage(tostring(InventoryItems[InventoryItemSelected[2]].recordId))
			end
		elseif InventoryItemSelected[2] and TurnRight(0.2) == true and InventoryItemSelected[3] == nil and InventoryItemSelected[4] == nil and InventoryItemSelected[2] ~= types.NPC.getCapacity(self) and MenuSelectStop == false then
			InventoryItemSelected[2] = InventoryItemSelected[2] + 1
			ambient.playSound("Cursor")
			MenuSelectStop = true
			if InventoryItems[InventoryItemSelected[2]] then
				ui.showMessage(tostring(InventoryItems[InventoryItemSelected[2]].recordId))
			end
		elseif InventoryItemSelected[2] and MoveBackward(0.2) == true and InventoryItemSelected[3] == nil and InventoryItemSelected[4] == nil and InventoryItemSelected[2] <= (types.NPC.getCapacity(self) - 2) and MenuSelectStop == false then
			InventoryItemSelected[2] = InventoryItemSelected[2] + 2
			ambient.playSound("Cursor")
			MenuSelectStop = true
			if InventoryItems[InventoryItemSelected[2]] then
				ui.showMessage(tostring(InventoryItems[InventoryItemSelected[2]].recordId))
			end
		elseif InventoryItemSelected[2] and MoveForward(-0.2) == true and InventoryItemSelected[3] == nil and InventoryItemSelected[4] == nil and InventoryItemSelected[2] >= 3 and MenuSelectStop == false then
			InventoryItemSelected[2] = InventoryItemSelected[2] - 2
			ambient.playSound("Cursor")
			MenuSelectStop = true
			if InventoryItems[InventoryItemSelected[2]] then
				ui.showMessage(tostring(InventoryItems[InventoryItemSelected[2]].recordId))
			end
		elseif InventoryItemSelected[2] and InventoryItemSelected[3] == nil and input.isActionPressed(input.ACTION.Use) == true and InventoryItems[InventoryItemSelected[2]] and ToggleUseButton == true then
			InventoryItemSelected[3] = 1
			ToggleUseButton = false
			
			SubInventoryText1 = { layer = 'Windows', type = ui.TYPE.Text, props = { text = "Equip", textSize = 50*textSizeRatio, textColor = util.color.rgb(0.5, 0.5, 0.5) }, }
			SubInventoryText2 = { layer = 'Windows', type = ui.TYPE.Text, props = { text = "Check", textSize = 50*textSizeRatio, textColor = util.color.rgb(1, 1, 1) }, }
			SubInventoryText3 = { layer = 'Windows', type = ui.TYPE.Text, props = { text = "Combine", textSize = 50*textSizeRatio, textColor = util.color.rgb(1, 1, 1) }, }


			if storage.playerSection('RESettings1'):get('Drop')==true then
				SubInventoryText4 = { layer = 'Windows', type = ui.TYPE.Text, props = { text = "Drop", textSize = 50*textSizeRatio, textColor = util.color.rgb(1, 1, 1) }, }
				SubInventoryBKG="textures/Sub Menu Inventory.dds"
			else
				SubInventoryText4 = { layer = 'Windows', type = ui.TYPE.Text, props = { text = "", textSize = 50*textSizeRatio, textColor = util.color.rgb(1, 1, 1) }, }
				SubInventoryBKG="textures/Sub Menu Inventory Dropless.dds"
			end





			SubInventoryTexts = {
				layer = 'Windows',
				type = ui.TYPE.Flex,
				props = {
					relativeSize = util.vector2(1 / 5, 1 / 2),
					relativePosition = util.vector2(0.5, 0.45),
					anchor = util.vector2(0.5, 0.5),
				},
				content = ui.content { SubInventoryText1,
					{ layer = 'Windows', type = ui.TYPE.Text, props = { text = " ", textSize = 35*textSizeRatio } }, SubInventoryText2,
					{ layer = 'Windows', type = ui.TYPE.Text, props = { text = " ", textSize = 35*textSizeRatio } }, SubInventoryText3,
					{ layer = 'Windows', type = ui.TYPE.Text, props = { text = " ", textSize = 30*textSizeRatio } }, SubInventoryText4 }
			}

			SubInventory = ui.create{
				layer = 'Windows',
				type = ui.TYPE.Image,
				props = {
					autoSize = true,
					relativeSize = util.vector2(1/ 5, 1/ 3),
					relativePosition = util.vector2(13 / 24, 1 / 2),
					anchor = util.vector2(0, 0),
					resource = ui.texture { path = SubInventoryBKG },
				},

				content=ui.content {SubInventoryTexts}
			}
		end

		if InventoryItemSelected[2] and SelectedItem then
			SelectedItemLayout.props.relativePosition = util.vector2(
				3 / 4 + 1 / 10 - (InventoryItemSelected[2] % 2) * 1 /
				10, 1 / 3 + (InventoryItemSelected[2] + InventoryItemSelected[2] % 2) / 2 * 1 / 9 - 1 / 9)
			SelectedItem:update()
		end




		-----------------Naviguer dans inventaire de combine
		if InventoryItemSelected[4] and TurnLeft(-0.2) == true and MenuSelectStop == false and InventoryItemSelected[4] ~= 1 then
			InventoryItemSelected[4] = InventoryItemSelected[4] - 1
			ambient.playSound("Cursor")
			MenuSelectStop = true
		elseif InventoryItemSelected[4] and TurnRight(0.2) == true and InventoryItemSelected[4] ~= types.NPC.getCapacity(self) and MenuSelectStop == false then
			InventoryItemSelected[4] = InventoryItemSelected[4] + 1
			ambient.playSound("Cursor")
			MenuSelectStop = true
		elseif InventoryItemSelected[4] and MoveBackward(0.2) == true and InventoryItemSelected[4] <= (types.NPC.getCapacity(self) - 2) and MenuSelectStop == false then
			InventoryItemSelected[4] = InventoryItemSelected[4] + 2
			ambient.playSound("Cursor")
			MenuSelectStop = true
		elseif InventoryItemSelected[4] and MoveForward(-0.2) == true and InventoryItemSelected[4] >= 3 and MenuSelectStop == false then
			InventoryItemSelected[4] = InventoryItemSelected[4] - 2
			ambient.playSound("Cursor")
			MenuSelectStop = true
		elseif InventoryItemSelected[4] and input.isActionPressed(input.ACTION.Use) == true and ToggleUseButton == true and InventoryItems[InventoryItemSelected[2]] ~= InventoryItems[InventoryItemSelected[4]] then
			local item1 = InventoryItems[InventoryItemSelected[2]]
			local item2 = InventoryItems[InventoryItemSelected[4]]
			local itemscombined = false
			if item1.type == types.Weapon and item2.type == types.Weapon then
				if (types.Weapon.record(item1).type == 10 and types.Weapon.record(item2).type == 13) or (types.Weapon.record(item1).type == 13 and types.Weapon.record(item2).type == 10) then
					--print("RELOAD/LOAD WEAPON")


					if types.Weapon.record(item1).type == 10 and ToggleUseButton then
						InventoryReload(item1, item2)
					elseif types.Weapon.record(item2).type == 10 and ToggleUseButton then
						InventoryReload(item2, item1)
					end
				end
			else
				for i, item in ipairs(CombinedItems) do
					if itemscombined == false and ((item1.type.record(item1).id) == (string.lower(item[1])) and (item2.type.record(item2).id) == (string.lower(item[3]))) then
						if types.Actor.inventory(self):countOf(item1.recordId) < tonumber(item[2]) then
							for i = 1, math.ceil(types.Actor.inventory(self):countOf(item1.recordId) / item[2] * item[6]) do
								core.sendGlobalEvent('MoveInto', {
									Item = nil,
									container = nil,
									actor = self,
									newItem =
										item[5]
								})
							end
							core.sendGlobalEvent('RemoveItem',
								{ Item = item1, number = tonumber(types.Actor.inventory(self):countOf(item1.recordId)) })
							core.sendGlobalEvent('RemoveItem', { Item = item2, number = tonumber(item[4]) })
							itemscombined = true
						elseif types.Actor.inventory(self):countOf(item2.recordId) < tonumber(item[4]) then
							for i = 1, math.ceil(types.Actor.inventory(self):countOf(item2.recordId) / item[4] * item[6]) do
								core.sendGlobalEvent('MoveInto', {
									Item = nil,
									container = nil,
									actor = self,
									newItem =
										item[5]
								})
							end
							core.sendGlobalEvent('RemoveItem', { Item = item1, number = tonumber(item[2]) })
							core.sendGlobalEvent('RemoveItem',
								{ Item = item2, number = tonumber(types.Actor.inventory(self):countOf(item2.recordId)) })
							itemscombined = true
						else
							for i = 1, tonumber(item[6]) do
								core.sendGlobalEvent('MoveInto', {
									Item = nil,
									container = nil,
									actor = self,
									newItem =
										item[5]
								})
							end
							core.sendGlobalEvent('RemoveItem', { Item = item1, number = tonumber(item[2]) })
							core.sendGlobalEvent('RemoveItem', { Item = item2, number = tonumber(item[4]) })
							itemscombined = true
						end
					elseif itemscombined == false and ((item1.type.record(item1).id) == (string.lower(item[3])) and (item2.type.record(item2).id) == (string.lower(item[1]))) then
						if types.Actor.inventory(self):countOf(item1.recordId) < tonumber(item[4]) then
							for i = 1, math.ceil(types.Actor.inventory(self):countOf(item1.recordId) / item[3] * item[6]) do
								core.sendGlobalEvent('MoveInto', {
									Item = nil,
									container = nil,
									actor = self,
									newItem =
										item[5]
								})
							end
							core.sendGlobalEvent('RemoveItem',
								{ Item = item1, number = tonumber(types.Actor.inventory(self):countOf(item1.recordId)) })
							core.sendGlobalEvent('RemoveItem', { Item = item2, number = tonumber(item[2]) })
							itemscombined = true
						elseif types.Actor.inventory(self):countOf(item2.recordId) < tonumber(item[2]) then
							for i = 1, math.ceil(types.Actor.inventory(self):countOf(item2.recordId) / item[2] * item[6]) do
								core.sendGlobalEvent('MoveInto', {
									Item = nil,
									container = nil,
									actor = self,
									newItem =
										item[5]
								})
							end
							core.sendGlobalEvent('RemoveItem', { Item = item1, number = tonumber(item[4]) })
							core.sendGlobalEvent('RemoveItem',
								{ Item = item2, number = tonumber(types.Actor.inventory(self):countOf(item2.recordId)) })
							itemscombined = true
						else
							for i = 1, tonumber(item[6]) do
								core.sendGlobalEvent('MoveInto', {
									Item = nil,
									container = nil,
									actor = self,
									newItem =
										item[5]
								})
							end
							core.sendGlobalEvent('RemoveItem', { Item = item1, number = tonumber(item[4]) })
							core.sendGlobalEvent('RemoveItem', { Item = item2, number = tonumber(item[2]) })
							itemscombined = true
						end
					end
				end
				InventoryItemSelected[4] = nil
				SelectedCombineItem:destroy()
				ToggleUseButton = false
				FrameRefresh = true
			end
		end

		if InventoryItemSelected[4] and SelectedItem then
			SelectedCombineItemLayout.props.relativePosition = util.vector2(3 / 4 + 1 / 10 -
				(InventoryItemSelected[4] % 2) * 1 / 10,
				1 / 3 + (InventoryItemSelected[4] + InventoryItemSelected[4] % 2) /
				2 * 1 / 9 - 1 / 9)
			SelectedCombineItem:update()
		end





		-----------------Naviguer dans sub Menu inventaire
		if InventoryItemSelected[3] and InventoryItemSelected[4] == nil then
			if MoveForward(-0.2) == true and InventoryItemSelected[3] >= 3 and MenuSelectStop == false then
				ambient.playSound("Cursor")
				SubInventoryTexts.content[InventoryItemSelected[3]].props.textColor = util.color.rgb(1, 1, 1)
				SubInventory:update()
				InventoryItemSelected[3] = InventoryItemSelected[3] - 2
				MenuSelectStop = true
				SubInventoryTexts.content[InventoryItemSelected[3]].props.textColor = util.color.rgb(0.5, 0.5, 0.5)
				SubInventory:update()
			elseif MoveBackward(0.2) == true and MenuSelectStop == false and ((InventoryItemSelected[3] <= 5 and storage.playerSection('RESettings1'):get('Drop')==true) or (InventoryItemSelected[3] <= 3 and storage.playerSection('RESettings1'):get('Drop')==false)) then
				ambient.playSound("Cursor")
				SubInventoryTexts.content[InventoryItemSelected[3]].props.textColor = util.color.rgb(1, 1, 1)
				SubInventory:update()
				InventoryItemSelected[3] = InventoryItemSelected[3] + 2
				MenuSelectStop = true
				SubInventoryTexts.content[InventoryItemSelected[3]].props.textColor = util.color.rgb(0.5, 0.5, 0.5)
				SubInventory:update()
			elseif FrameRefresh == true and Framewait(3) then
				ToggleUseButton = false
				FrameRefresh = false
				doOnceMenu = 0
				if ShowItemIcon then
					ShowItemIcon:destroy()
					ShowItemIcon = nil
				end
				EquippedWeaponDisplay:destroy()
				Portrait:destroy()
				Lifebare:destroy()
				SelectedItem:destroy()
				if SubInventory then
					SubInventory:destroy()
				end
				InventoryItemSelected[2] = 1
				InventoryItemSelected[3] = nil
				InventoryItems = ShowInventory()
			elseif input.isActionPressed(input.ACTION.Use) and ToggleUseButton == true and FrameRefresh == false then ---------- EQUIP
				if InventoryItemSelected[3] == 1 then
					core.sendGlobalEvent('UseItem',
						{ object = InventoryItems[InventoryItemSelected[2]], actor = self, force = true })
					if InventoryItems[InventoryItemSelected[2]].type == types.Potion then
						for i, effect in ipairs(types.Potion.record(InventoryItems[InventoryItemSelected[2]]).effects) do
							--print(effect.effect.id)
							--print(core.magic.EFFECT_TYPE.RestoreHealth)
							if effect.effect.id == core.magic.EFFECT_TYPE.RestoreHealth then
								onFrameHealth = types.Actor.stats.dynamic.health(self).current +
									(effect.magnitudeMin + effect.magnitudeMin) / 2
								if onFrameHealth > types.Actor.stats.dynamic.health(self).base then
									onFrameHealth = types.Actor.stats.dynamic.health(self).base
								end
								--print(onFrameHealth)
							end
						end
					end

					FrameRefresh = true
				elseif InventoryItemSelected[3] == 3 then ---------- CHECK
					if input.isActionPressed(input.ACTION.Use) and ToggleUseButton == true and ShowItemIcon then
						FrameRefresh = true
						for i, item in ipairs(ExaminedItems) do
							if InventoryItems[InventoryItemSelected[2]].type.record(InventoryItems[InventoryItemSelected[2]]).id == string.lower(ExaminedItems[i][1]) then
								core.sendGlobalEvent('RemoveItem',
									{ Item = InventoryItems[InventoryItemSelected[2]], number = 1 })
								core.sendGlobalEvent('MoveInto',
									{ Item = nil, container = nil, actor = self, newItem = ExaminedItems[i][2] })
							end
						end
					end

					if ShowItemIcon == nil then
						local ItemDescription=""
						if ItemDescriptions[InventoryItems[InventoryItemSelected[2]].type.record(InventoryItems[InventoryItemSelected[2]]).name] then
							ShowItem(InventoryItems[InventoryItemSelected[2]],ItemDescriptions[InventoryItems[InventoryItemSelected[2]].type.record(InventoryItems[InventoryItemSelected[2]]).name])
						else
							ShowItem(InventoryItems[InventoryItemSelected[2]],tostring(InventoryItems[InventoryItemSelected[2]]))
						end
						SubInventory:destroy()
					end

					ToggleUseButton = false
				elseif InventoryItemSelected[3] == 5 then ---------- COMBINE
					SelectedCombineItemLayout = {
						layer = 'Windows',
						type = ui.TYPE.Image,
						props = {
							size = util.vector2(ui.screenSize().x / 10, ui.screenSize().y / 9),
							relativePosition = util.vector2(3 / 4, 1 / 3),
							anchor = util.vector2(0, 0),
							resource = ui.texture { path = "textures/SelectedItemCombine.dds" },
						},
					}
					SelectedCombineItem = ui.create(SelectedCombineItemLayout)
					InventoryItemSelected[4] = 1

					FrameRefresh = true
				elseif InventoryItemSelected[3] == 7 then ---------- DROP
					core.sendGlobalEvent('Teleport',
						{ object = InventoryItems[InventoryItemSelected[2]], position = self.position, rotation = nil })
					FrameRefresh = true
				end
				ToggleUseButton = false
			end
			--print(InventoryItemSelected[3])
		end

		--print(InventoryItemSelected[2])
		--print(InventoryItems[InventoryItemSelected[2]])
	end
	if I.UI.getMode() == nil and doOnceMenu == 1 then
		ambient.playSound("RECancel")
		EquippedWeaponDisplay:destroy()
		Portrait:destroy()
		Lifebare:destroy()
		Inventory:destroy()
		if SelectedItem then
			SelectedItem:destroy()
		end
		if InventoryItemSelected[3] then
			SubInventory:destroy()
			if InventoryItemSelected[4] then
				SelectedCombineItem:destroy()
			end
		end

		InventoryItemSelected[2] = nil
		InventoryItemSelected[3] = nil
		InventoryItemSelected[4] = nil
		doOnceMenu = 0
	end

	if I.UI.getMode() == nil then
		if ElectricalPanelPuzzleUI and ElectricalPanelPuzzleUI.layout then
			ElectricalPanelPuzzleUI:destroy()
			ambient.playSound("RECancel")
		end
		if MenuYesNo and MenuYesNo.layout then
			MenuYesNo:destroy()
			core.sendGlobalEvent("ReturnChoiceYesNo", { value = -2, Player = self, GameObject = MWscriptGameObject })
			ambient.playSound("RECancel")
		end
		if Menu15 and Menu15.layout then
			Menu15:destroy()
			core.sendGlobalEvent("ReturnChoice15", { value = -2, Player = self, GameObject = MWscriptGameObject })
			ambient.playSound("RECancel")
		end
		if SavingMenuUI and SavingMenuUI.layout then
			SavingMenuUI:destroy()
			ambient.playSound("RECancel")
		end
		if MapUI and MapUI.layout then
			MapUI:destroy()
			ambient.playSound("RECancel")
		end
		if MenuSelection and MenuSelection.layout then
			MenuSelection:destroy()
			MenuSelection=nil
			ambient.playSound("RECancel")
		end

		--if ShowItemIcon and ShowItemIcon.layout then
		--	ShowItemIcon:destroy()
		--end
	end





	-----------ouvrir le menu inventaire
	if input.isActionPressed(input.ACTION.Inventory) == true and I.UI.getMode() == nil and Menu == false and types.Actor.getStance(self) == 0 then -- and PickUpItem[1]==nil then
		--I.UI.setMode(I.UI.MODE.Interface, {windows = {I.UI.WINDOW.QuickKeys,}})
		InventoryItems = ShowInventory()
		InventoryItemSelected[2] = 1
		ui.showMessage(tostring(InventoryItems[InventoryItemSelected[2]].recordId))
	elseif input.isActionPressed(input.ACTION.Inventory) == true and I.UI.getMode() and Menu == true and InventoryItemSelected[3] == nil then
		--I.UI.removeMode(I.UI.MODE.Interface)
	elseif input.isActionPressed(input.ACTION.Inventory) == false and I.UI.getMode() then
		Menu = true
	elseif input.isActionPressed(input.ACTION.Inventory) == false and I.UI.getMode() == nil then
		Menu = false
	end


	if I.UI.getMode() or (LiveSelectionUI and LiveSelectionUI.layout) then
		if MoveBackward(0.2) == nil and MoveForward(-0.2) == nil and TurnLeft(-0.2) == nil and TurnRight(0.2) == nil and MenuSelectStop == true then
			MenuSelectStop = false
		end
		if ToggleUseButton == false and input.isActionPressed(input.ACTION.Use) == false then
			ToggleUseButton = true
			InventoryAmmunitionTypes = {}
		end
	end


	-------------Equiper une arme       		
	if types.Actor.getEquipment(self, 16) and types.Weapon.record(types.Actor.getEquipment(self, 16)).type == 10 and types.Actor.getEquipment(self, 16) ~= EquippedWeapon then ---define ammo an auto equip basic ammos
		EquippedWeapon = types.Actor.getEquipment(self, 16)
		AmmunitionTypes = {}
		ammoscharged = false
		AmmoChecked = 0
		types.Actor.getEquipment(self, 16):sendEvent('GiveWeaponInfos', { player = self, Equipped = true })
		--print("send")
		weaponcondition = types.Item.itemData(types.Actor.getEquipment(self, 16)).condition
	end

	
--	if negativeshader:isEnabled() and (LiveSelectionUI == nil or LiveSelectionUI.layout==nil) and LiveSelectionTimer==0 then
--		LiveSelectionTimer=core.getRealTime()
--	elseif negativeshader:isEnabled() and (core.getRealTime()-LiveSelectionTimer)>3 and (LiveSelectionUI == nil or LiveSelectionUI.layout==nil) then
--		LiveSelectionTimer=0
--		negativeshader:disable()
--	end
	if negativeshader:isEnabled() and LiveSelectionUI == nil then
		negativeshader:disable()
	end


	if LiveSelectionUI then
		print(core.getRealTime())
		print(LiveSelectionTimer)
		print(core.getRealTime()-LiveSelectionTimer)
		if LiveSelectionTimer==0 then
			LiveSelectionTimer=core.getRealTime()
		end
		print(LiveSelectionTimer)
		if (core.getRealTime()-LiveSelectionTimer)>9 then
			print('9')
			core.sendGlobalEvent("ReturnGlobalVariable",{variable=LiveSelectionChoice1,player=self,value=3})
			core.sendGlobalEvent("ReturnGlobalVariable",{variable=LiveSelectionChoice2,player=self,value=0})
			LiveSelectionUI:destroy()
			LiveSelectionUI=nil
			LiveSelectionTimer=0
			negativeshader:enable()
		elseif (core.getRealTime()-LiveSelectionTimer)>7 then
			print("7")
			if I.UI.getMode() then 
				negativeshader:disable()
				I.UI.removeMode(I.UI.MODE.Interface)
				LiveSelectionUI.layout.content[1].content[1].props.textColor = util.color.rgb(1, 1, 1)
				LiveSelectionUI.layout.content[3].content[1].props.textColor = util.color.rgb(1, 1, 1)
				LiveSelectionUI.layout.props.relativePosition = util.vector2(0.5, 0.7)
				LiveSelectionUI:update()
			end
			if (string.byte(core.getRealTime()%1,3)==48 or string.byte(core.getRealTime()%1,3)==52 or string.byte(core.getRealTime()%1,3)==56) and WrapperTemplate.props.resource==Borderbox then
				WrapperTemplate.props.resource= TransparentBorderBox
				LiveSelectionUI:update()
			elseif (string.byte(core.getRealTime()%1,3)==50 or string.byte(core.getRealTime()%1,3)==54 or string.byte(core.getRealTime()%1,3)==57) and WrapperTemplate.props.resource==TransparentBorderBox then
				WrapperTemplate.props.resource= Borderbox
				LiveSelectionUI:update()
			end
		elseif (core.getRealTime()-LiveSelectionTimer)>6 then
			print("6")
			if  I.UI.getMode() == nil then
				WrapperTemplate.props.color=Colors.Red
				negativeshader:enable()
				I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
				LiveSelectionUI.layout.content[1].content[1].props.textColor = util.color.rgb(0, 0, 0)
				LiveSelectionUI.layout.content[3].content[1].props.textColor = util.color.rgb(0, 0, 0)
				if LiveSelectionUI.layout.content[1].template then
					LiveSelectionUI.layout.content[1].template=WrapperTemplate
				else
					LiveSelectionUI.layout.content[3].template=WrapperTemplate
				end
				LiveSelectionUI:update()
			end
		elseif (core.getRealTime()-LiveSelectionTimer)>4 then
			print("4")
			if I.UI.getMode() then 
				negativeshader:disable()
				I.UI.removeMode(I.UI.MODE.Interface)
				LiveSelectionUI.layout.content[1].content[1].props.textColor = util.color.rgb(1, 1, 1)
				LiveSelectionUI.layout.content[3].content[1].props.textColor = util.color.rgb(1, 1, 1)
				LiveSelectionUI:update()
			end
			if (string.byte(core.getRealTime()%1,3)==48 or string.byte(core.getRealTime()%1,3)==54) and WrapperTemplate.props.resource==Borderbox then
				WrapperTemplate.props.resource= TransparentBorderBox
				LiveSelectionUI:update()
			elseif (string.byte(core.getRealTime()%1,3)==50 or string.byte(core.getRealTime()%1,3)==56) and WrapperTemplate.props.resource==TransparentBorderBox then
				WrapperTemplate.props.resource= Borderbox
				LiveSelectionUI:update()
			end
		elseif (core.getRealTime()-LiveSelectionTimer)>3 then
			print("3")
			if  I.UI.getMode() == nil then
				WrapperTemplate.props.color=Colors.Orange
				negativeshader:enable()
				I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
				LiveSelectionUI.layout.content[1].content[1].props.textColor = util.color.rgb(0, 0, 0)
				LiveSelectionUI.layout.content[3].content[1].props.textColor = util.color.rgb(0, 0, 0)
				if LiveSelectionUI.layout.content[1].template then
					LiveSelectionUI.layout.content[1].template=WrapperTemplate
				else
					LiveSelectionUI.layout.content[3].template=WrapperTemplate
				end
				LiveSelectionUI:update()
			end
		elseif (core.getRealTime()-LiveSelectionTimer)>1 then
			print("1")
			if I.UI.getMode() then 
				LiveSelectionUI.layout.content[1].template = WrapperTemplate
				negativeshader:disable()
				I.UI.removeMode(I.UI.MODE.Interface)
				LiveSelectionUI.layout.content[1].content[1].props.textColor = util.color.rgb(1, 1, 1)
				LiveSelectionUI.layout.content[3].content[1].props.textColor = util.color.rgb(1, 1, 1)
				LiveSelectionUI.layout.props.relativePosition = util.vector2(0.5, 0.7)
				LiveSelectionUI:update()
			end
			if string.byte(core.getRealTime()%1,3)==48 and WrapperTemplate.props.resource==Borderbox then
				WrapperTemplate.props.resource= TransparentBorderBox
				LiveSelectionUI:update()
			elseif string.byte(core.getRealTime()%1,3)==52 and WrapperTemplate.props.resource==TransparentBorderBox then
				WrapperTemplate.props.resource= Borderbox
				LiveSelectionUI:update()
			end

		elseif (core.getRealTime()-LiveSelectionTimer)>0.1 and I.UI.getMode() == nil then
				print("0")
				I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
		end

		if (MoveBackward(0.2) or MoveForward(-0.2)) and MenuSelectStop==false and I.UI.getMode() == nil then
			MenuSelectStop=true
			ambient.playSound("Cursor")
			if LiveSelectionUI.layout.content[1].template == nil then
				LiveSelectionUI.layout.content[1].template = WrapperTemplate
				LiveSelectionUI.layout.content[3].template = nil
			else
				LiveSelectionUI.layout.content[1].template = nil
				LiveSelectionUI.layout.content[3].template = WrapperTemplate
			end
			LiveSelectionUI:update()
		elseif input.isActionPressed(input.ACTION.Use) and I.UI.getMode() == nil and (core.getRealTime()-LiveSelectionTimer)>0.1 then
			print("use")
			if LiveSelectionUI.layout.content[1].template then
				core.sendGlobalEvent("ReturnGlobalVariable",{variable=LiveSelectionChoice1,player=self,value=1})
				core.sendGlobalEvent("ReturnGlobalVariable",{variable=LiveSelectionChoice2,player=self,value=0})
			elseif LiveSelectionUI.layout.content[3].template then
				core.sendGlobalEvent("ReturnGlobalVariable",{variable=LiveSelectionChoice1,player=self,value=2})
				core.sendGlobalEvent("ReturnGlobalVariable",{variable=LiveSelectionChoice2,player=self,value=0})
			end
			LiveSelectionUI:destroy()
			LiveSelectionUI=nil
			LiveSelectionTimer=0
			negativeshader:enable()
		end
	end
	print(input.isActionPressed(input.ACTION.Use))
end


local function onSave()
	return{MapsUtils=MapsUtils}

end

local function onLoad(data)
	if data.MapsUtils then
		MapsUtils=data.MapsUtils
	end
end

local function ReturnObjectsInWorld(data)
	ObjectsInWorld=data.Objects
	ObjectsInMap=data.ObjectsInMap
	MapsUtils["RoomsMapped"]=data.Mapped

--	print("Table Mapped")
--	for j, area in ipairs(MapsUtils["RoomsMapped"]) do
--		print("j "..j.." Area "..area)
--		for k, zone in ipairs(area) do
--			print("k "..k.." zonz "..zone)
--		end
--	end

--	print("return... "..RoomMap)
	ShowMap(AreaMap,ZoneMap,RoomMap)

end

return {
	eventHandlers = {ChoicesSelection=ChoicesSelection,DefineSwitchZones=DefineSwitchZones,ReturnObjectsInWorld=ReturnObjectsInWorld, SavingMenu=SavingMenu, ElectricalPanelPuzzle=ElectricalPanelPuzzle, LiveSelection = LiveSelection, CameraPos = Camerapos, ReturnEquippedWeaponInfos = ReturnEquippedWeaponInfos, ReturnInventoryWeaponInfos = ReturnInventoryWeaponInfos, ChoiceYesNo = ChoiceYesNo, Choice15 = Choice15 },
	engineHandlers = {
		onSave=onSave,
		onLoad=onLoad,
		onFrame = onFrame,
		onUpdate = onUpdate

	}
}
