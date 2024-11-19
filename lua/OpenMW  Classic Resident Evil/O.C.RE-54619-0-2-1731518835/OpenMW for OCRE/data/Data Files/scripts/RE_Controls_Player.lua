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

local TargetedBOW = {}
local BOWchecked = 0
local TargetedAttackObject = {}
local AttackObjectchecked = 0
local changetarget = 0
local TargetBOW
local TargetAttackObject
local SheathTimer=0
local ROOMS={}
local DoorTransition={}

local actionbasetime = 4 *core.getGameTimeScale()

local ContainerUI={}

local ItemDescriptions=util.loadCode("return("..types.Book.record("Item Descriptions").text..")",{})()

local ExaminedItems = util.loadCode("return(" .. types.Book.record("examined items").text .. ")", {})()

local CombinedItems = util.loadCode("return(" ..types.Book.record("combined items").text .. ")", {})()

local NPCHealthSpeed=1

local AmmoUsage={}
util.loadCode(types.Book.record("AmmoUsage").text,{AmmoUsage=AmmoUsage})()

local Toggle={	R1=false, R2=false, L1=false, L2=false,
				Up=false, Down=false, Left=false, Right=false,
				Cross=false, Square=false, Circle=false }



local function ButtonToggle(button,value)
	if (value~=false and value~=nil) and Toggle[button]==false then
		Toggle[button]=true
		--print(button.." toggle")
		return(true)
	elseif value==false and Toggle[button]==true then
		--print(button.." toggle Down")
		Toggle[button]=false
	end
end

MSKlist = {}
BGDepth=nil
types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Looking, false)


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

local Maps=util.loadCode("return({"..types.Book.record("Maps").text.."})",{})()


I.Settings.registerPage {
    key = 'RESettingsPage',
    l10n = 'RESettings',
    name = 'O.C.RE Settings',
    description = 'O.C.RE Settings.',
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
            renderer = 'select',
            name = 'FixedCamera',
            description = 'Play with fixed cameras',
            default = "Yes",
			argument={disabled = false, l10n = 'LocalizationContext', items={"Yes","No for 3D Rooms","No for all Rooms"}},
        },
        {
            key = 'Check',
            renderer = 'checkbox',
            name = 'Check',
            description = 'How to check objects',
            default = true,
			argument={trueLabel = "RE1/RECV",falseLabel = "RE2/RE3"},
        },
        {
            key = 'PSXShader',
            renderer = 'checkbox',
            name = 'PSXShader',
            description = '',
            default = false,
			argument={trueLabel = "Yes",falseLabel = "No"},
        },
        {
            key = 'DoorTransition',
            renderer = 'checkbox',
            name = 'Door Transition',
            description = 'Door transition when activating a door',
            default = true,
			argument={trueLabel = "RE door transition",falseLabel = "Fade in / out"},
        },
    },
}





input.registerAction {
	key = 'R1',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'R2',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'L1',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'L2',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'Up',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'Down',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'Right',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'Left',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'Cross',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'Square',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}
input.registerAction {
	key = 'Circle',
	type = input.ACTION_TYPE.Boolean,
	l10n = 'Playercontrols',
	name = '',
	description = '',
	defaultValue = false,
}


input.registerTrigger({
    name = "",
    description = '',
    l10n = 'Playercontrols',
    key = "Triangle",
})
input.registerTrigger({
    name = "",
    description = '',
    l10n = 'Playercontrols',
    key = "NextWeapon",
})







I.Settings.registerGroup {
    key = 'Controles',
    page = 'RESettingsPage',
    l10n = 'Controls',
    name = 'Controls',
    description = 'Configuration of controls.',
    permanentStorage = false,
    settings = {

        {
            key = "ButtonR1",
            renderer = "inputBinding",
            name = "Button R1",
            description = '-Draw weapon (locate ennemies only)\n-Navigate in menus (maps, containers)',
            default = "k",
            argument = {
                type = "action",
                key = "R1"
        	},
		},
        {
            key = "ButtonR2",
            renderer = "inputBinding",
            name = "Button R2",
            description = '-Draw weapon (locate targetable objects).',
            default = "l",
            argument = {
                type = "action",
                key = "R2"
        	},
		},
		{
            key = "ButtonL1",
            renderer = "inputBinding",
            name = "Button L1",
            description = '-Change Target\n-Dodge\n-Navigate in menus (maps, containers)',
            default = "h",
            argument = {
                type = "action",
                key = "L1"
            }
        },
		{
            key = "ButtonL2",
            renderer = "inputBinding",
            name = "Button L2",
            description = '-Acces Map screen',
            default = "m",
            argument = {
                type = "action",
                key = "L2"
            }
        },
        {
            key = "ButtonUp",
            renderer = "inputBinding",
            name = "Button Up",
            description = '-Move Cursor.\n-Move character.\n-Aim Weapon',
            default = "z",
            argument = {
                type = "action",
                key = "Up"
        	},
		},
        {
            key = "ButtonDown",
            renderer = "inputBinding",
            name = "Button Down",
            description = '-Move Cursor.\n-Move character.\n-Aim Weapon',
            default = "s",
            argument = {
                type = "action",
                key = "Down"
        	},
		},
        {
            key = "ButtonRight",
            renderer = "inputBinding",
            name = "Button Right",
            description = '-Move Cursor.\n-Move character.\n-Aim Weapon',
            default = "d",
            argument = {
                type = "action",
                key = "Right"
        	},
		},
        {
            key = "ButtonLeft",
            renderer = "inputBinding",
            name = "Button Left",
            description = '-Move Cursor.\n-Move character.\n-Aim Weapon',
            default = "q",
            argument = {
                type = "action",
                key = "Left"
        	},
		},
        {
            key = "ButtonCross",
            renderer = "inputBinding",
            name = "Button Cross",
            description = '-Action/Attack/Open doors',
            default = "j",
            argument = {
                type = "action",
                key = "Cross"
        	},
		},
        {
            key = "ButtonSquare",
            renderer = "inputBinding",
            name = "Button Square",
            description = '-Run. \n-Quick 180° turn (hold + press directional button / Left Stick)\n-Reload (with weapon drawn)',
            default = "n",
            argument = {
                type = "action",
                key = "Square"
        	},
		},
		{
            key = "ButtonCircle",
            renderer = "inputBinding",
            name = "Button Circle",
            description = '-Acces Statut Screen',
            default = "i",
            argument = {
                type = "action",
                key = "Circle"
            }
        },
		{
            key = "ButtonTriangle",
            renderer = "inputBinding",
            name = "Button Triangle",
            description = '-Cancel previous action',
            default = "u",
            argument = {
                type = "trigger",
                key = "Triangle"
            }
        },
		{
            key = "ButtonNextWeapon",
            renderer = "inputBinding",
            name = "Button Next Weapon",
            description = '-Equip Next Weapon',
            default = "y",
            argument = {
                type = "trigger",
                key = "NextWeapon"
            }
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
local AmmoChecked = 0
local Instantammo = 0
local ammochanged = false
local weaponcondition = 0
local InventoryAmmunitionTypes = {}
local InventoryItemSelected = {}
local ContainerItemSelected=0
local Colors={
White=util.color.rgb(1, 1, 1),
Grey=util.color.rgb(0.5, 0.5, 0.5),
Orange=util.color.rgb(0.67, 0.74, 0.12),
Blue=util.color.rgb(0.09, 0.38, 0.54),
Red=util.color.rgb(0.74, 0.11, 0.11),
Green=util.color.rgb(0.08, 0.71, 0.02),
DarkRed=util.color.rgb(0.56, 0.05, 0.05),
}




local textSizeRatio= ui.screenSize().y/1056


local filesList={}
filesList.UI={}
filesList.Bookmarks={}
filesList.Book=1
filesList.Bookmark=1
filesList.BooksTargetX=0
filesList.ArrowsTimer=0
filesList.Page=1
for i, book in pairs(types.Book.records) do
	if book.id~="maps" and book.id~="item descriptions" and book.id~="combined items" and book.id~="ammousage" and string.find(book.id,"_rdt_")==nil then
		table.insert(filesList.Bookmarks,book.id)
		--print(i.." "..book.id)
	end
end

--------------------------------------------------------------------------------------------------------------------------------




local book_window = require('scripts.openmw_books_enhanced.window.book_window')
local callback_creator = require('scripts.openmw_books_enhanced.outside_manipulators.callback_creator')
--local nonmouse_controller = require('scripts.openmw_books_enhanced.outside_manipulators.nonmouse_controller')
--local mousewheel = require("scripts.openmw_books_enhanced.outside_manipulators.mousewheel_handler")
local post_opening_actions = require("scripts.openmw_books_enhanced.outside_manipulators.post_opening_actions")
local style_chooser = require('scripts.openmw_books_enhanced.ui_layout.style_chooser')
--local book_interface_overrides = require('scripts.openmw_books_enhanced.outside_manipulators.book_interface_overrides')
--local read_status_checker = require('scripts.openmw_books_enhanced.outside_manipulators.read_status_checker')
local text_parser = require('scripts.openmw_books_enhanced.wording.text_parser')
--local item_taker = require("scripts.openmw_books_enhanced.outside_manipulators.item_taker")
--local content_name = require("scripts.openmw_books_enhanced.window.content_element_names")


filesList.documentWindow = nil
local savedDataForThisMod = {}


local function onBookOpened(data)
--	filesList.Arrows.R=ui.create({ layer = 'Console', type = ui.TYPE.Image, props = { relativeSize = util.vector2(1/40, 1/25),relativePosition=util.vector2(0.9, 0.4),  anchor = (util.vector2(0, 0)), color = Colors.Green, resource = ui.texture { path = "textures/choice select cursor.dds"},}})
--	filesList.Arrows.L=ui.create({ layer = 'Console', type = ui.TYPE.Image, props = { visible=false, relativeSize = util.vector2(1/40, 1/25),relativePosition=util.vector2(0.1, 0.4),  anchor = (util.vector2(0, 0)), color = Colors.Green, resource = ui.texture { path = "textures/choice select cursor left.dds"},}})


	filesList.Page=1
	if I.UI.getMode()==nil then
		I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
	end
	ambient.playSound("REdecide")
 --   destroyDocumentWindow()
 --   if book_interface_overrides.wasBookUiOverridenBySomething() then
 --       return
 --   end
 
    local chosenDocumentWindowStyle = style_chooser.chooseDocumentWindowStyle(data.activatedBookObject)
    filesList.documentWindow = book_window.createBookWindow(data.activatedBookObject, chosenDocumentWindowStyle)
    callback_creator.applyWindowCallbacks(data.activatedBookObject, filesList.documentWindow)
    text_parser.applyBookObjectTextToWindow(data.activatedBookObject, filesList.documentWindow, chosenDocumentWindowStyle)
--    nonmouse_controller.initiateNonMouseControls(documentWindow)
    post_opening_actions.applyPostOpeningActions(data.activatedBookObject, savedDataForThisMod)


	if filesList.documentWindow.layout.userData.lines[#filesList.documentWindow.layout.userData.lines].userData.page ==1 then
		filesList.documentWindow.layout.content:add({name="ArrowR", layer = 'Console', type = ui.TYPE.Image, props = { visible=false, relativeSize = util.vector2(1/40, 1/25),relativePosition=util.vector2(0.9, 0.4),  anchor = (util.vector2(0, 0)), color = Colors.Green, resource = ui.texture { path = "textures/choice select cursor.dds"},}})
		filesList.documentWindow.layout.content:add({name="ArrowL", layer = 'Console', type = ui.TYPE.Image, props = { visible=false, relativeSize = util.vector2(1/40, 1/25),relativePosition=util.vector2(0.1, 0.4),  anchor = (util.vector2(0, 0)), color = Colors.Green, resource = ui.texture { path = "textures/choice select cursor left.dds"},}})
		filesList.documentWindow.layout.content:add({name="EXIT", layer = 'Console', type = ui.TYPE.Text, props = { visible=true, textSize = 30*textSizeRatio,relativePosition=util.vector2(0.9, 0.4),  anchor = (util.vector2(0, 0)), textColor = Colors.Grey, text="Exit",}})
	else
		filesList.documentWindow.layout.content:add({name="ArrowR", layer = 'Console', type = ui.TYPE.Image, props = { visible=true, relativeSize = util.vector2(1/40, 1/25),relativePosition=util.vector2(0.9, 0.4),  anchor = (util.vector2(0, 0)), color = Colors.Green, resource = ui.texture { path = "textures/choice select cursor.dds"},}})
		filesList.documentWindow.layout.content:add({name="ArrowL", layer = 'Console', type = ui.TYPE.Image, props = { visible=false, relativeSize = util.vector2(1/40, 1/25),relativePosition=util.vector2(0.1, 0.4),  anchor = (util.vector2(0, 0)), color = Colors.Green, resource = ui.texture { path = "textures/choice select cursor left.dds"},}})
		filesList.documentWindow.layout.content:add({name="EXIT", layer = 'Console', type = ui.TYPE.Text, props = { visible=false, textSize = 30*textSizeRatio,relativePosition=util.vector2(0.9, 0.4),  anchor = (util.vector2(0, 0)), textColor = Colors.Grey, text="Exit",}})
	end
	if types.Book.record(data.activatedBookObject).icon then
		filesList.documentWindow.layout.content:add({ layer = 'Console', type = ui.TYPE.Image, props = { visible=true, relativeSize = util.vector2(0.3, 0.3),relativePosition=util.vector2(0.5, 0.5),  anchor = (util.vector2(0.5, 0.5)), resource = ui.texture { path = types.Book.record(data.activatedBookObject).icon},}})
	end
	filesList.documentWindow:update()
end



--------------------------------------------------------------------------------------------------------------------------------



























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


local function InventoryReload(item1, item2)
	if AmmoUsage[item1.recordId] then
		InventoryAmmunitionTypes=AmmoUsage[item1.recordId][2]
	else
		InventoryAmmunitionTypes={}		
	end
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


local QuickTurnButton = 0
local DodgeButton = 0
local TurningBack = 0
local ToggleWeaponButton=false



local frame=0
local shootTimer = 0
local FrameRefresh = false

HealthPath={}
HealthPath.path1 = 0
HealthPath.path2 = 0
HealthPath.path3 = 0
local onFrameHealth

local equipped = types.Actor.equipment(self)

LiveSelect={}
LiveSelect.Timer =0
LiveSelect.Choice1=""
LiveSelect.Choice2=""
LiveSelect.UI=nil
local negativeshader = postprocessing.load('negative')
local psxshader = postprocessing.load('retroDither')


----- variables pour tire shotguns
S={}
S.ShellRotX=nil
S.ShellRotZ=nil
S.shellDamage=nil
S.shellEnchant=nil


---------- override  normal controls
interfaces.Controls.overrideMovementControls(true)
interfaces.Controls.overrideCombatControls(true)
interfaces.Controls.overrideUiControls(true)


-----------------bars cinematiques
ui.create({ layer = 'Windows', type = ui.TYPE.Image, props = { relativeSize = util.vector2(1, 1/ 7), relativePosition = util.vector2(0, 1), anchor = util.vector2(0, 1), resource = ui.texture { path = 'textures/cinematic_bar.dds' }, }, })
ui.create({ layer = 'Windows', type = ui.TYPE.Image, props = { relativeSize = util.vector2(1, 1/ 7), relativePosition = util.vector2(0, 0), anchor = util.vector2(0, 0), resource = ui.texture { path = 'textures/cinematic_bar.dds' }, }, })


local MessageBoxUI={}
MessageBoxUI.UI={}
function MessageBox(data)
	I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
	local Text=data.Text
	Text=Text:gsub("^%l", string.upper)

	MessageBoxUI.UI=ui.create({layer = 'Console', type = ui.TYPE.Text, props = {autoSize=true, relativePosition=util.vector2(0.5,0.9), text = Text, textSize = 40*textSizeRatio , textColor=Colors.White, anchor = util.vector2(0.5, 0.5), },
--					content=ui.content{
--						{ type = ui.TYPE.Image, props = {relativePosition=util.vector2(0.5, 0.9), relativeSize = util.vector2(0.025, 0.25), visible = true, color = Colors.White, resource = ui.texture { path = "textures/Choice select cursor Down.dds" } } }
--					}
				}) 

end

local CamData={}
CamData.Cutscene=false

function Cutscene(data)
	CamData.Cutscene=data.cutscene
end

function Camerapos(data)
	CamData.activecam = data.ActiveCam
	CamData.activeBkg = data.ActiveBkg
	CamData.BGDepth = data.BGDepth
	CamData.CamAng=data.CamAng
	CamData.CamPos=data.CamPos
	print("Change Fixe camera in player script")
	if data.ROOMS~=nil then
		ROOMS=data.ROOMS
	end
	--print(data.MSKList[1])
	if data.MSKList then
		MSKlist = data.MSKList
	end
	if ROOMS[self.cell.name] and (CamData.Cutscene==true or (storage.playerSection('RESettings1'):get('FixedCamera')=="Yes" or (storage.playerSection('RESettings1'):get('FixedCamera')=="No for 3D Rooms" and ROOMS[self.cell.name] and ROOMS[self.cell.name][CamData.activecam].bgd))) then
		camera.setMode(camera.MODE.Static)
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

	if Up == true or input.getAxisValue(input.CONTROLLER_AXIS.LeftY) <= data then
		return ("Up")
	else
		return(false)
	end
end

function MoveBackward(data)
	if Down == true or input.getAxisValue(input.CONTROLLER_AXIS.LeftY) >= data then
		return ("Down")
	else
		return(false)
	end
end

function TurnRight(data)
	if Right == true or input.getAxisValue(input.CONTROLLER_AXIS.LeftX) >= data then
		return ("Right")
	else
		return(false)
	end
end

function TurnLeft(data)
	if Left == true or input.getAxisValue(input.CONTROLLER_AXIS.LeftX) <= data then
		return ("Left")
	else
		return(false)
	end
end



local MenuSelectStop = false
local InventoryItems
local Inventory={}
local PickUpItem = {}
local PickUpItemIcon
local function ShowInventory()
	ambient.playSound("REdecide")

	Inventory.Portrait = { name = "Portrait", layer = 'Windows', type = ui.TYPE.Image, props = { relativeSize = util.vector2(1 / 7, 1 / 5), relativePosition = util.vector2(1 / 8, 1 / 4), anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = 'textures/Portrait/' .. tostring(types.NPC.record(self).race) .. '.jpg' }, }, }
	
	local iconpath
	if types.Actor.getEquipment(self, 16) then
		iconpath = types.Weapon.record(types.Actor.getEquipment(self, 16)).icon
	else
		iconpath = "icons/No Item.dds"
	end
	
	Inventory.EquippedWeaponDisplay ={ name = "EquippedWeapon", layer = 'Windows', type = ui.TYPE.Image, props = { relativeSize = util.vector2(1 / 6, 1 / 6), relativePosition = util.vector2(1 / 2+1/7, 1 / 4), anchor = util.vector2(0.5, 0.5), resource = ui.texture { path = iconpath }, }, }

	Inventory.Content = ui.content {}
	Inventory.Items = {}
	Inventory.LifeBar={}
	Inventory.LifeBar.Timer=0
	

	if types.Actor.activeEffects(self):getEffect("poison") and types.Actor.activeEffects(self):getEffect("poison").magnitude > 0 then
		HealthPath.path1 = 'textures/Lifebar/Poison/'
	elseif (onFrameHealth / types.Actor.stats.dynamic.health(self).base) >= 0.8 then
		HealthPath.path1 = 'textures/Lifebar/Fine/'
	elseif (onFrameHealth / types.Actor.stats.dynamic.health(self).base) <= 0.3 then
		HealthPath.path1 = 'textures/Lifebar/Danger/'
	else
		HealthPath.path1 = 'textures/Lifebar/Caution/'
	end

	HealthPath.path3 = HealthPath.path1 .. '1.jpg'
	Inventory.LifeBar.UI = { name = "LifeBar", type = ui.TYPE.Image, props = { relativeSize = util.vector2(3/10, 1 / 6), relativePosition = util.vector2(1/5, 1 / 6), anchor = util.vector2(0, 0), resource = ui.texture { path = HealthPath.path3 }, }, }

	if not (Inventory.UI == nil ) then
		Inventory.UI:destroy()
	end

	for i = 1, 20 do --20 is an arbitrary value
		if not (types.Actor.inventory(self):getAll()[i] == nil or types.Actor.inventory(self):getAll()[i].type == types.Book) then
			table.insert(Inventory.Items, types.Actor.inventory(self):getAll()[i])
		end
	end


	for i, item in ipairs(Inventory.Items) do
		if i>types.NPC.getCapacity(self) then
			break
		end


		local textLayout = {}
		local weapontextcolor
		if item.count > 1 then                                                   --13 == Bolt 12==Arrow
			textLayout = { type = ui.TYPE.Text, props = { text = tostring(item.count), textSize = 50*textSizeRatio, textColor = util.color.rgb(0.06, 0.4, 0.08), anchor = util.vector2(-1, -1.5), }, }
		elseif item.type == types.Weapon and (types.Weapon.record(item).type == 10 or types.Weapon.record(item).type == 9) then --10 == MarksmanCrossbow  9 == Bows then
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

			if Inventory.Items[i + 1] == nil then
				_G["InventoryLine" .. (i)] = {
					name = "Line" .. (i),
					layer = "Windows",
					type = ui.TYPE.Flex,
					props = { relativePosition = util.vector2(0, 0), anchor = util.vector2(0, 0), horizontal = true },
					content =
						_G["ContentInventoryLine" .. (i)]
				}
				Inventory.Content:add(_G["InventoryLine" .. (i)])
			end
		elseif i % 2 == 0 then
			_G["ContentInventoryLine" .. (i - 1)]:add({ type = ui.TYPE.Image, content = ui.content { textLayout }, props = { size = util.vector2(ui.screenSize().x / 10, ui.screenSize().y / 9), resource = ui.texture { path = item.type.record(item).icon }, }, })

			_G["InventoryLine" .. (i - 1)] = {
				name = "Line" .. (i - 1),
				layer = "Windows",
				type = ui.TYPE.Flex,
				props = { relativePosition = util.vector2(0, 0), anchor = util.vector2(0, 0), horizontal = true },
				content =
					_G["ContentInventoryLine" .. (i - 1)]
			}

			Inventory.Content:add(_G["InventoryLine" .. (i - 1)])
		end
	end

	Inventory.Bgd = {
		name = "Inventory",
		layer = "Windows",
		type = ui.TYPE.Image,
		props = { autoSize=true, relativeSize = util.vector2(2 / 10, types.NPC.getCapacity(self) / 2 / 9), relativePosition = util.vector2(3 / 4, 1 / 3), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/BkgInventory.dds" }},	
	}

	Inventory.Objects={
		name = "InventoryObjects",
		layer = "Windows",
		type = ui.TYPE.Flex,
		props = {  autoSize=true, relativePosition = util.vector2(3 / 4, 1 / 3), anchor = (util.vector2(0, 0)), horizontal = false },
		content =Inventory.Content}



	Inventory.Description={name="Description", layer = 'Windows', type = ui.TYPE.Text, props = {relativePosition = util.vector2(1/2, 9/10), text ="", autoSize = true, textSize = 25*textSizeRatio, textColor = Colors.White,}, }

	I.UI.setMode(I.UI.MODE.Interface, { windows = {} })


	Inventory.UI = ui.create({ 	name = "Inventory", 
								layer = 'Windows', 
								type = ui.TYPE.Widget, 
								props = { relativeSize = util.vector2(1,1),anchor = (util.vector2(0, 0)) },
								content=ui.content{Inventory.Bgd,Inventory.Objects,Inventory.Portrait,Inventory.EquippedWeaponDisplay,Inventory.LifeBar.UI,Inventory.Description}
							})
	return (Inventory.Items)
end


local Container

local function ActiveContainer(data)
	I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
	--print(data.container)
	InventoryItems = ShowInventory()
	InventoryItemSelected[2] = 1
	if InventoryItems[InventoryItemSelected[2]] then
		ui.showMessage(tostring(InventoryItems[InventoryItemSelected[2]].recordId))
	end

	if ContainerUI.layout then
		ContainerUI:destroy()
	end
	local VisilityContainerSelector=false
	local VisibilityInventorySelector=true
	if SelectedItem and SelectedItem.layout then
		if ContainerUI.layout.content[2].props.visible==true then
			VisilityContainerSelector=true
			VisibilityInventorySelector=false
		end
		SelectedItem:destroy()
	end
	SelectedItem = ui.create( {
		layer = "Console",
		type = ui.TYPE.Image,
		props = {
			visible=VisibilityInventorySelector,
			size = util.vector2(ui.screenSize().x / 10, ui.screenSize().y / 9),
			relativePosition = util.vector2(3 / 4, 1 / 3),
			anchor = util.vector2(0, 0),
			resource = ui.texture { path = "textures/SelectedItem.dds" },
		},
	})
	Container=data.container
	ContainerUI=ui.create({layer = 'Console',  type = ui.TYPE.Image,
	props = {relativeSize = util.vector2(0.5,0.4),relativePosition=util.vector2(0.3, 0.6),anchor = util.vector2(0.5, 0.5),resource = ui.texture{path ="textures/BkgInventory.dds"},},
	content=ui.content{	{type = ui.TYPE.Flex,props = { autoSize = true, horizontal = false, relativePosition = util.vector2(0.05,0.5), anchor = util.vector2(0, 0),},content=ui.content{}},
						{type = ui.TYPE.Image, props = {visible=VisilityContainerSelector,size = util.vector2(ui.screenSize().x / 2, ui.screenSize().y / 27),resource = ui.texture{path ="textures/BorderBox.dds"}, relativePosition = util.vector2(0.0,0.5), anchor = util.vector2(0, 0)}},
		}})
	for i, item in pairs(types.Container.inventory(data.container):getAll()) do
		if item.type~=types.Book then
			local StrNum=""
			if item.count>1 then
				StrNum=" x "..tostring(item.count)
			end
			--print(item)
			--print(item.count)
			--print(item.type.record(item).icon)
			ContainerUI.layout.content[1].content:add({type = ui.TYPE.Flex,props = { autoSize = true, horizontal = true, relativePosition = util.vector2(0,0.5), anchor = util.vector2(0, 0),},
														content=ui.content({
														{type = ui.TYPE.Image, props = {size = util.vector2(ui.screenSize().x / 30, ui.screenSize().y / 27),resource = ui.texture{path =item.type.record(item).icon}}},										
														{type = ui.TYPE.Text, props = { text = "   "..item.recordId..StrNum, textSize = 40*textSizeRatio, textColor = Colors.White, anchor = util.vector2(0.5, 0.5), }, },
														})
													})
		end							
	end
	ContainerItemSelected=1

end




local ItemChecked={}
ItemChecked.Show={}
local function ReturnCheckedObject(data)
	ItemChecked.Show.Object=data.Object
	ItemChecked.Show.Light=data.Light
end


function ShowItem(item, text)
		local Text = { layer = 'Windows', type = ui.TYPE.Text, props = {relativePosition = util.vector2(1, 1 / 2),relativeSize = util.vector2(1, 1 / 2), anchor = util.vector2(1 / 2, 1 / 2), text = text, autoSize = false, textSize = 25*textSizeRatio, textColor = Colors.White, wordWrap=true}, }
	
	if storage.playerSection('RESettings1'):get('Check')==false then
		--print("RE2/RE3")
		--print(item.type.record(item).icon )
		local ItemIcon = { layer = 'Windows', type = ui.TYPE.Image, props = { relativeSize = util.vector2(2 / 3, 1 / 2),  anchor = (util.vector2(0, 0)), resource = ui.texture { path = item.type.record(item).icon }, }, }
		ItemChecked["Icon"]= ui.create({
			layer = 'Console',
			type = ui.TYPE.Flex,
			props = { autoSize = false, relativeSize = util.vector2(0.3, 0.4), relativePosition = util.vector2(0.4 , 0.55 ), anchor = util.vector2(0, 0), },
			content = ui.content { ItemIcon,
				{type = ui.TYPE.Text, props = { text = " ", textSize = 120*textSizeRatio } }, Text }
		})
		--print(ItemChecked["Icon"].layout)
	elseif storage.playerSection('RESettings1'):get('Check')==true then
		local ItemIcon = { type = ui.TYPE.Image, props = { relativeSize = util.vector2(0.3, 1/2),relativePosition=util.vector2(-0.2, 0),  anchor = (util.vector2(0, 0)), color = Colors.Green, resource = ui.texture { path = "textures/No texture.dds"}, },
		content=ui.content{
			{ type = ui.TYPE.Image, props = { relativeSize = util.vector2(1/40, 1/25),relativePosition=util.vector2(0.9, 0.4),  anchor = (util.vector2(0, 0)), color = Colors.DarkRed, resource = ui.texture { path = "textures/choice select cursor.dds"}, },},
		{ type = ui.TYPE.Image, props = { relativeSize = util.vector2(1/40, 1/25),relativePosition=util.vector2(1/2, 0),  anchor = (util.vector2(0, 0)), color = Colors.DarkRed, resource = ui.texture { path = "textures/choice select cursor up.dds"}, },},
		{ type = ui.TYPE.Image, props = { relativeSize = util.vector2(1/40, 1/25),relativePosition=util.vector2(1/2, 0.8),  anchor = (util.vector2(0, 0)), color = Colors.DarkRed, resource = ui.texture { path = "textures/choice select cursor down.dds"}, },},
		{ type = ui.TYPE.Image, props = { relativeSize = util.vector2(1/40, 1/25),relativePosition=util.vector2(0, 0.4),  anchor = (util.vector2(0, 0)), color = Colors.DarkRed, resource = ui.texture { path = "textures/choice select cursor left.dds"}, },},
		}, }
		ItemChecked["Icon"] = ui.create({
			layer = 'Console',
			type = ui.TYPE.Flex,
			props = { autoSize = false, relativeSize = util.vector2(1.4, 1), relativePosition = util.vector2(0.3, 1/3), anchor = util.vector2(0, 0), },
			content = ui.content { ItemIcon,
				{type = ui.TYPE.Text, props = { text = " ", textSize =50*textSizeRatio } }, Text }
		})
		
		local ItemToShow
		if item.type.record(item.recordId.."_") then
			ItemToShow=item.recordId.."_"
		else
			ItemToShow=item.recordId
		end
		core.sendGlobalEvent('CreateCheckedObject',
				{
					object=ItemToShow,
					player=self,
					PositionObject=camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5, 0.5))*10,
					PositionLight=camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5, 0.5))*0
				})


	end
end


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local Lockpicking

local function LockPicking(data)
	print("Create LockPicking")
	if Lockpicking==nil then
		Lockpicking={}
		Lockpicking.State=0
		Lockpicking.ConvRot=0.05
		Lockpicking.Value=data.Value*3.6
		Lockpicking.LockRot=0
		Lockpicking.RotRot=0
		Lockpicking.Lockable=data.Lockable
		I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
		Lockpicking.UI=ui.create({
			layer = 'Console',
			type = ui.TYPE.Widget,
			props = { autoSize = false, relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0, 0), anchor = util.vector2(0, 0), },
			content = ui.content {
				{type = ui.TYPE.Text, props = { text = "Right/Left : Turn the Lock Pick", textSize =50*textSizeRatio,relativePosition = util.vector2(1/2, 7.5/10),textColor=Colors.White, anchor = util.vector2(0.5, 0.5) } },
				{type = ui.TYPE.Text, props = { text = "Action: Unlock the lock", textSize =50*textSizeRatio,relativePosition = util.vector2(1/2, 8/10),textColor=Colors.White, anchor = util.vector2(0.5, 0.5) } }, }})
		Lockpicking.Object=data.Object
		Lockpicking.LockBaseRot=Lockpicking.Object.LockPick.rotation*util.transform.rotateZ(camera.getYaw())
		Lockpicking.RotBaseRot=Lockpicking.Object.Rot.rotation*util.transform.rotateZ(camera.getYaw())
		--print(Lockpicking.Object.Fixe)
		--print(Lockpicking.Object.Rot)
		--print(Lockpicking.Object.LockPick)
		core.sendGlobalEvent('Teleport',
				{
					object = Lockpicking.Object.Fixe,
					position =camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5, 0.5))*10,
					rotation = Lockpicking.Object.Fixe.rotation*util.transform.rotateZ(camera.getYaw())
				})	
		core.sendGlobalEvent('Teleport',
				{
					object = Lockpicking.Object.Rot,
					position =camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5, 0.5))*10,
					rotation = Lockpicking.Object.Rot.rotation*util.transform.rotateZ(camera.getYaw())
				})	
		core.sendGlobalEvent('Teleport',
				{
					object = Lockpicking.Object.LockPick,
					position =camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5, 0.5))*10,
					rotation = Lockpicking.Object.LockPick.rotation*util.transform.rotateZ(camera.getYaw())
				})
		core.sendGlobalEvent('Teleport',
				{
					object = Lockpicking.Object.Light,
					position =camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5, 0.5))*1,
					rotation = nil
				})		
	end
	
end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


local function CheckOverload(actor)
	local bookNum=0
	for i, book in ipairs(types.Player.inventory(actor):getAll(types.Book)) do
		bookNum=bookNum+1
	end
	if types.Player.inventory(actor):getAll()[types.NPC.getCapacity(actor)+bookNum+1] then------------------------------------ A vérifier
		if bookNum==0 then
			return(types.Player.inventory(actor):getAll()[types.NPC.getCapacity(actor)+bookNum+1])
		else
			for i, book in ipairs(types.Player.inventory(actor):getAll(types.Book)) do
				if types.Player.inventory(actor):getAll()[types.NPC.getCapacity(self)+bookNum-i].type~=types.Book then
					return(types.Player.inventory(actor):getAll()[types.NPC.getCapacity(actor)+bookNum-i])	
				end
			end
		end
	elseif types.Player.inventory(actor):getAll()[types.NPC.getCapacity(actor)+bookNum] then
		return(true)
	else
		return(false)
	end
end



local function Overload()
	--print(CheckOverload())
	if CheckOverload(self)~=true and CheckOverload(self)~=false and CheckOverload(self)~=nil then
		core.sendGlobalEvent('Teleport',
		{
			object = CheckOverload(self),
			position =
				self.position,
			rotation = nil
		})
		ui.showMessage("Your inventory is full, you drop : " ..CheckOverload(self).recordId)

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
	if AngleTarget then
		self.controls.yawChange = AngleTarget
	end
end

MapUI=nil
local LastRoom
local ObjectsInWorld
local ObjectsInMap
AreaMap=0
ZoneMap=0
RoomMap=0
MapsUtils={Blink={value=-0.01,Room=0},RoomsVisited={},RoomsMapped={}}
















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
			table.insert(FlexObjectsContent,{ type = ui.TYPE.Text,  props = { text = MapsUtils["RoomsVisited"][Area][2][Zone][2][Cell],relativePosition=util.vector2(0.5, 0.5), anchor = util.vector2(0, 0),textSize = 40*textSizeRatio, textColor = Colors.White } }) 
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
					table.insert(MapUIContent, { type = ui.TYPE.Image, props = {relativePosition=util.vector2(0.5, 0), anchor = util.vector2(0, 0), relativeSize = util.vector2(0.02, 0.02), visible = true, color = Colors.Green, resource = ui.texture { path = "textures/Choice select cursor Up.dds" } } })
				end
			elseif MapsUtils["RoomsMapped"][Area] then
				if MapsUtils["RoomsMapped"][Area][2][Zone+i] then
					table.insert(MapUIContent, { type = ui.TYPE.Image, props = {relativePosition=util.vector2(0.5, 0), anchor = util.vector2(0, 0), relativeSize = util.vector2(0.02, 0.02), visible = true, color = Colors.Green, resource = ui.texture { path = "textures/Choice select cursor Up.dds" } } })
				end
			end
		end
	end

	for i, zone in pairs(Maps[Area][2]) do
		if (Zone-i)>0 then
			if  MapsUtils["RoomsVisited"][Area]then
				if  MapsUtils["RoomsVisited"][Area][2][Zone-i]then
					table.insert(MapUIContent, { type = ui.TYPE.Image, props = {relativePosition=util.vector2(0.5, 0.96), anchor = util.vector2(0, 0), relativeSize = util.vector2(0.02, 0.02), visible = true, color = Colors.Green, resource = ui.texture { path = "textures/Choice select cursor Down.dds" } } })
				end
			elseif MapsUtils["RoomsMapped"][Area] then
				if MapsUtils["RoomsMapped"][Area][2][Zone-i] then
					table.insert(MapUIContent, { type = ui.TYPE.Image, props = {relativePosition=util.vector2(0.5, 0.96), anchor = util.vector2(0, 0), relativeSize = util.vector2(0.02, 0.02), visible = true, color = Colors.Green, resource = ui.texture { path = "textures/Choice select cursor Down.dds" } } })
				end
			end
		end
	end


	for i, area in pairs(Maps)do
		if (MapsUtils["RoomsVisited"][i] or MapsUtils["RoomsMapped"][i]) and i>AreaMap then
			table.insert(MapUIContent, { type = ui.TYPE.Image, props = {relativePosition=util.vector2(0.97, 0.5), anchor = util.vector2(0, 0), relativeSize = util.vector2(0.02, 0.02), visible = true, color = Colors.Green, resource = ui.texture { path = "textures/Choice select cursor.dds" } } })
			break
		end
	end
	for i, area in pairs(Maps)do
		if (MapsUtils["RoomsVisited"][i] or MapsUtils["RoomsMapped"][i]) and i<AreaMap then
			table.insert(MapUIContent, { type = ui.TYPE.Image, props = {relativePosition=util.vector2(0, 0.5), anchor = util.vector2(0, 0), relativeSize = util.vector2(0.02, 0.02), visible = true, color = Colors.Green, resource = ui.texture { path = "textures/Choice select cursor Left.dds" } } })
			break
		end
	end


	table.insert(MapUIContent,{type = ui.TYPE.Flex, props = {autoSize=true,relativePosition=util.vector2(0.1, 0.25),anchor = util.vector2(0.5, 0.5)}, content=ui.content(FlexObjectsContent)})

	MapUI=ui.create({layer = 'Console',  type = ui.TYPE.Image,
	props = {relativeSize = util.vector2(1,1),relativePosition=util.vector2(0.5, 0.5),anchor = util.vector2(0.5, 0.5),resource = ui.texture{path ="textures/Maps/"..Maps[Area][1].."/"..Maps[Area][2][Zone][1].."/BKG.png"},},
	content=ui.content(MapUIContent)
	})

end	




local function FadeEffect(dt)
	if Fade==nil then
		Fade ={}
		Fade.value=1
		Fade.UI=ui.create({layer = 'Windows', type = ui.TYPE.Image, 
		props = { alpha=0.1, autoSize=true, relativeSize = util.vector2(1, 1), relativePosition = util.vector2(0, 0), anchor = (util.vector2(0, 0)), resource = ui.texture { path = "textures/BlackScreen.png" }, },})
	else
		if Fade.UI.layout.props.alpha>0.95 then
			Fade.value=-Fade.value
		end
		
		Fade.UI.layout.props.alpha=Fade.UI.layout.props.alpha+dt*Fade.value
		Fade.UI:update()

		if Fade.UI.layout.props.alpha<0.1 then
			Fade.UI:destroy()
			Fade=nil
			return(0)
		else
			return(Fade.UI.layout.props.alpha)
		end	
	end
end



local function DoorTransitioning(dt)
	if self.cell.name=="DoorStransition" then
		if camera.getMode()~=camera.MODE.Static then
			print("static")
			camera.setMode(camera.MODE.Static)
		end
		if DoorTransition.CreateDoor==nil and DoorTransition.TeleportDoor then
			print(DoorTransition.TeleportDoor)
			print(types.Door.record(DoorTransition.TeleportDoor).name)
			core.sendGlobalEvent("CreateNewObject",{Player=self,RecordId=types.Door.record(DoorTransition.TeleportDoor).name, position=util.vector3(0,0,0)})
			camera.setStaticPosition(util.vector3(-50,-400,130))
			camera.setPitch(0)
			camera.setYaw(0)
			DoorTransition.CreateDoor=true
		
		elseif nearby.doors[1] and DoorTransition.CreateDoor==true then
			if Square==true then	
				ambient.playSound(types.Door.record(DoorTransition.TeleportDoor).closeSound)
				core.sendGlobalEvent('RemoveItem',
				{Item = nearby.doors[1],number = 1})
				core.sendGlobalEvent('Teleport',
				{ object = self, DestCell=types.Door.destCell(DoorTransition.TeleportDoor).name, position = types.Door.destPosition(DoorTransition.TeleportDoor), rotation = types.Door.destRotation(DoorTransition.TeleportDoor)})
				DoorTransition={}
			else
				if DoorTransition.OpenDoor==nil then
					nearby.doors[1]:activateBy(self)
					DoorTransition.OpenDoor=true
				end
				camera.setStaticPosition(camera.getPosition()+util.vector3(0,dt*100,0))
				if camera.getPosition().y>=0 then
					ambient.playSound(types.Door.record(DoorTransition.TeleportDoor).closeSound)
					core.sendGlobalEvent('RemoveItem',
					{Item = nearby.doors[1],number = 1})
					core.sendGlobalEvent('Teleport',
					{ object = self, DestCell=types.Door.destCell(DoorTransition.TeleportDoor).name, position = types.Door.destPosition(DoorTransition.TeleportDoor), rotation = types.Door.destRotation(DoorTransition.TeleportDoor)})
					DoorTransition={}
				end
			end
		end
	elseif DoorTransition.TeleportDoor and storage.playerSection('RESettings1'):get('DoorTransition')==false then
		local value =FadeEffect(dt)
		if value==nil then
			DoorTransition={}	
		elseif  value<0.1 then
			DoorTransition={}	
		elseif value>0.95 then
			print("Teleport")
			ambient.playSound(types.Door.record(DoorTransition.TeleportDoor).closeSound)
			DoorTransition.TeleportDoor:activateBy(self)
			core.sendGlobalEvent('Teleport',
			{ object = self, DestCell=types.Door.destCell(DoorTransition.TeleportDoor).name, position = types.Door.destPosition(DoorTransition.TeleportDoor), rotation = types.Door.destRotation(DoorTransition.TeleportDoor)})
		end
	end
end



local function onUpdate(dt)
	DoorTransitioning(dt)

	if BulletOnScreen and BulletOnScreen.layout then
		if BulletOnScreenTimer<60 then
			BulletOnScreenTimer=BulletOnScreenTimer+1
		else 
			BulletOnScreen:destroy()
		end
	end




	
		
	if I.UI.getMode()==nil and self.cell.name~="DoorStransition" then



			---------Ouvrir carte
			--print(L2)
			if (MapUI==nil or MapUI.layout==nil) and CamData.Cutscene==false then
				if ButtonToggle("L2",L2) then
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
			end

			-----------ouvrir inventaire
			if ButtonToggle("Circle",Circle) and types.Actor.getStance(self) == types.Actor.STANCE.Nothing and CamData.Cutscene==false then -- and PickUpItem[1]==nil then
				--I.UI.setMode(I.UI.MODE.Interface, {windows = {I.UI.WINDOW.QuickKeys,}})
				InventoryItems = ShowInventory()
				InventoryItemSelected[2] = 1
				if InventoryItems[InventoryItemSelected[2]] then
					Inventory.UI.layout.content.Description.props.text=InventoryItems[InventoryItemSelected[2]].type.record(InventoryItems[InventoryItemSelected[2]]).name
					Inventory.UI:update()
--					ui.showMessage(tostring(InventoryItems[InventoryItemSelected[2]].recordId))
				end
				SelectedItem = ui.create( {
					layer = "Console",
					type = ui.TYPE.Image,
					props = {
						visible=true,
						size = util.vector2(ui.screenSize().x / 10, ui.screenSize().y / 9),
						relativePosition = util.vector2(3 / 4, 1 / 3),
						anchor = util.vector2(0, 0),
						resource = ui.texture { path = "textures/SelectedItem.dds" },
					},
				})
			end


		---------------Activate near -> ajouter animation de ramasser un objet

		if  ButtonToggle("Cross",Cross) and types.Actor.getStance(self) == types.Actor.STANCE.Nothing and I.UI.getMode() == nil and CamData.Cutscene==false then
			local Activated=false
			for i, items in ipairs(nearby.items) do
				local dist = (util.vector2(self.position.x, self.position.y) - util.vector2(items.position.x, items.position.y)):length()
				if dist < 100 and ((items.position.z - self.position.z) <= 150) and InFront(items) == true then
					--print(CheckOverload(self))
					if items.type==types.Book then
						ui.showMessage("I have found "..types.Book.record(items).name)
						core.sendGlobalEvent('MoveInto', {
							Item = items,
							container = nil,
							actor = self,
							newItem =nil
						})
						--self:sendEvent('openmwBooksEnhancedBookActivated', { activatedBookObject = items})
						onBookOpened({activatedBookObject=items})
						break
						
						
					elseif CheckOverload(self)==false then
						PickUpItem[1] = items
						PickUpItem[2] = true
						Activated=true
						break
					else
						PickUpItem[1] = items
						PickUpItem[2] = false
						Activated=true
						break
					end
					--[[
					local nbritems = 0
					for i, item in ipairs(types.Actor.inventory(self):getAll()) do
						if item.type ~= types.Book then
							nbritems = nbritems + 1
						end
					end
					if (nbritems <= (types.NPC.getCapacity(self) - 1) or (items.type == types.Book) or (types.Player.inventory(self):countOf(string.gsub(items.recordId, "_", "")) > 0 and items.type.record(items).mwscript == "")) and PickUpItem[1] == nil then
						--for i, item in ipairs(types.Actor.inventory(self):getAll()) do print(item) end
						PickUpItem[1] = items
						PickUpItem[2] = true
						break
					elseif PickUpItem[1] == nil then
						PickUpItem[1] = items
						PickUpItem[2] = false
						break
					end
					]]--
				end
			end
			if Activated==false then
				for i, activator in ipairs(nearby.activators) do
					local dist = (self.position - activator.position):length()
					if ((dist < 120 and ((activator.position.z - self.position.z) <= 150) and InFront(activator) == true) 
					or activator==nearby.castRay(util.vector3(math.sin(self.rotation:getYaw())*10, math.cos(self.rotation:getYaw())*10, 80) + self.position,util.vector3(math.sin(self.rotation:getYaw())*80, math.cos(self.rotation:getYaw())*80, 80) + self.position).hitObject ) and types.Activator.record(activator).id~="blood puddle" then
						activator:activateBy(self)
--						print(activator)
						Activated=true
						activator:sendEvent("onActivated",{actor=self})
						break
					end
				end
			end
			if Activated==false then
				for i, door in ipairs(nearby.doors) do
					--print(self.position)
					--print(util.vector3(math.sin(self.rotation:getPitch())*10, math.cos(self.rotation:getPitch())*10, 80) + self.position)
					--print(util.vector3(math.sin(self.rotation:getPitch())*80, math.cos(self.rotation:getPitch())*80, 80) + self.position)
					--print(door)
					--print(door.position)
					--print(nearby.castRay(util.vector3(math.sin(self.rotation:getPitch())*10, math.cos(self.rotation:getPitch())*10, 80) + self.position,util.vector3(math.sin(self.rotation:getPitch())*80, math.cos(self.rotation:getPitch())*80, 80) + self.position).hitObject)-----
					local dist = (self.position - door.position):length()
					if (dist < 80 and ((door.position.z - self.position.z) <= 150) and InFront(door) == true) or door==nearby.castRay(util.vector3(math.sin(self.rotation:getYaw())*10, math.cos(self.rotation:getYaw())*10, 80) + self.position,util.vector3(math.sin(self.rotation:getYaw())*80, math.cos(self.rotation:getYaw())*80, 80) + self.position).hitObject then
						print(door)
						if storage.playerSection('RESettings1'):get('DoorTransition')==true then
							door:sendEvent("onActivated",{actor=self})
							DoorTransition.TeleportDoor=door
							print(door)
							print(DoorTransition.TeleportDoor)
							print(string.find(types.Door.record(door).mwscript, "animateddoors"))
							door:activateBy(self)
							if types.Door.record(door).mwscript and string.find(types.Door.record(door).mwscript, "animateddoors")==nil then
								Activated=true
							end
							if types.Door.isTeleport(door)==true and types.Lockable.isLocked(door)==false and types.Door.records[types.Door.record(door).name] then
								core.sendGlobalEvent('Teleport',
								{ object = self, DestCell="DoorStransition", position = util.vector3(0,-400,0), rotation = nil})
							end	
						elseif (storage.playerSection('RESettings1'):get('DoorTransition')==false or types.Door.records[types.Door.record(door).name]==nil) and types.Lockable.isLocked(door)==false then
							FadeEffect(dt)
							ambient.playSound(types.Door.record(door).openSound)
							DoorTransition.TeleportDoor=door
						else
							door:activateBy(self)
							door:sendEvent("onActivated",{actor=self})
						end
						break
					end
				end
			end
			if Activated==false then
				for i, container in ipairs(nearby.containers) do
					local dist = (self.position - container.position):length()
					if dist < 100 and ((container.position.z - self.position.z) <= 150) and InFront(container) == true then
						container:activateBy(self)
						Activated=true
						container:sendEvent("onActivated",{actor=self})
						break
					end
				end
			end
			if Activated==false then
				for i, actor in ipairs(nearby.actors) do
					local dist = (self.position - actor.position):length()
					if dist < 50 and ((actor.position.z - self.position.z) <= 150) and types.Actor.stats.dynamic.health(actor).current > 0 and InFront(actor) == true and actor.type ~= types.Player then
						actor:activateBy(self)
						Activated=true
						actor:sendEvent("onActivated",{actor=self})
						break
					end
				end
			end
			
		end



		------test marcher/courrir  ->ok
		if MoveForward(-0.3)~=false and Square == true and types.Actor.getStance(self) == types.Actor.STANCE.Nothing  then
			if types.Actor.activeEffects(self):getEffect("poison") and types.Actor.activeEffects(self):getEffect("poison").magnitude > 0 then
				NPCHealthSpeed=0.8
			elseif (onFrameHealth / types.Actor.stats.dynamic.health(self).base) >= 0.8 then
				NPCHealthSpeed=1
			elseif (onFrameHealth / types.Actor.stats.dynamic.health(self).base) <= 0.3 then
				NPCHealthSpeed=0.4
			else
				NPCHealthSpeed=0.8
			end
			self.controls.movement = NPCHealthSpeed
			self.controls.run = true
		elseif MoveForward(-0.3)~=false and types.Actor.getStance(self) == types.Actor.STANCE.Nothing  then
			if types.Actor.activeEffects(self):getEffect("poison") and types.Actor.activeEffects(self):getEffect("poison").magnitude > 0 then
				NPCHealthSpeed=0.8
			elseif (onFrameHealth / types.Actor.stats.dynamic.health(self).base) >= 0.8 then
				NPCHealthSpeed=1
			elseif (onFrameHealth / types.Actor.stats.dynamic.health(self).base) <= 0.3 then
				NPCHealthSpeed=0.6
			else
				NPCHealthSpeed=0.8
			end
			self.controls.movement = NPCHealthSpeed
			self.controls.run = false
		elseif MoveBackward(0.3)~=false and types.Actor.getStance(self) == types.Actor.STANCE.Nothing  then
			if types.Actor.activeEffects(self):getEffect("poison") and types.Actor.activeEffects(self):getEffect("poison").magnitude > 0 then
				NPCHealthSpeed=0.7
			elseif (onFrameHealth / types.Actor.stats.dynamic.health(self).base) >= 0.8 then
				NPCHealthSpeed=0.8
			elseif (onFrameHealth / types.Actor.stats.dynamic.health(self).base) <= 0.3 then
				NPCHealthSpeed=0.6
			else
				NPCHealthSpeed=0.7
			end
			self.controls.movement = -NPCHealthSpeed
			self.controls.run = false
		else
			self.controls.movement = 0
		end
		------------- test rotation sans souris->ok
		if TurnRight(0.2)~=false then
			self.controls.yawChange = dt* 2
		elseif TurnLeft(-0.2)~=false then
			self.controls.yawChange = dt*-2
		end

		--------------Quick rotate
		if MoveBackward(0.2)~=false and types.Actor.getStance(self) == types.Actor.STANCE.Nothing and Square == true and QuickTurnButton == 0 then
			TurningBack = 1
			QuickTurnButton = 1
		elseif not (MoveBackward(0.2)) and Square == false then
			QuickTurnButton = 0
		end

		if TurningBack > 0 then
			self.controls.yawChange = dt*10
			TurningBack = TurningBack + dt*100
			if TurningBack >= 31 then
				TurningBack = 0
			end
		end

		--------Test dodge  -> ajouter les animations
		if L1 == true and MoveBackward(0.2) and DodgeButton == 0 and types.Actor.getStance(self) == types.Actor.STANCE.Nothing and storage.playerSection('RESettings1'):get('Dodge')==true then
--			ui.showMessage('Dodge Back')
			self.controls.jump = true
			self.controls.movement = -1
			DodgeButton = 1
		elseif L1 == true and MoveForward(-0.2) and DodgeButton == 0 and types.Actor.getStance(self) == types.Actor.STANCE.Nothing and storage.playerSection('RESettings1'):get('Dodge')==true then
--			ui.showMessage('Dodge Front')
			self.controls.jump = true
			self.controls.movement = 1
			DodgeButton = 1
		elseif L1 == true and TurnRight(0.2) and DodgeButton == 0 and types.Actor.getStance(self) == types.Actor.STANCE.Nothing and storage.playerSection('RESettings1'):get('Dodge')==true then
--			ui.showMessage('Dodge Right')
			self.controls.jump = true
			self.controls.sideMovement = 1
			DodgeButton = 1
		elseif L1 == true and TurnLeft(-0.2) and DodgeButton == 0 and types.Actor.getStance(self) == types.Actor.STANCE.Nothing and storage.playerSection('RESettings1'):get('Dodge')==true then
--			ui.showMessage('Dodge Left')
			self.controls.jump = true
			self.controls.sideMovement = -1
			DodgeButton = 1
		elseif L1 == true and DodgeButton == 1 then
			DodgeButton = 0
			self.controls.sideMovement = 0
			self.controls.movement = 0
			self.controls.jump = false
		end
		------------- test visée Y fixe  -ok
		if types.Actor.getStance(self) == types.Actor.STANCE.Weapon then
--			if  camera.getMode()==camera.MODE.FirstPerson and input.getAxisValue(input.CONTROLLER_AXIS.LeftY) then
--				--print(input.getAxisValue(input.CONTROLLER_AXIS.LeftY))
--				if self.rotation:getPitch()<(input.getAxisValue(input.CONTROLLER_AXIS.LeftY)*0.8) and input.getAxisValue(input.CONTROLLER_AXIS.LeftY)>0.06 then 
--					self.controls.pitchChange = dt*2
--				elseif self.rotation:getPitch()>(input.getAxisValue(input.CONTROLLER_AXIS.LeftY)*0.8) and input.getAxisValue(input.CONTROLLER_AXIS.LeftY)<-0.06  then 
--					self.controls.pitchChange = dt*-2
--				elseif self.rotation:getPitch()>0.06 and (input.getAxisValue(input.CONTROLLER_AXIS.LeftY)>-0.06 and input.getAxisValue(input.CONTROLLER_AXIS.LeftY)<0.06) then
--					self.controls.pitchChange = dt*-2
--				elseif self.rotation:getPitch()<-0.06 and (input.getAxisValue(input.CONTROLLER_AXIS.LeftY)>-0.06 and input.getAxisValue(input.CONTROLLER_AXIS.LeftY)<0.06) then
--					self.controls.pitchChange = dt*2
--				end
--				
--			else
				if (types.Actor.getStance(self) == types.Actor.STANCE.Weapon and not (self.rotation:getPitch() < 0.01 and self.rotation:getPitch() > -0.01) and not (MoveForward(-0.5)) and not (MoveBackward(0.5))) then
					if self.rotation:getPitch() <= 0.03 and self.rotation:getPitch() >= -0.03 then
					elseif self.rotation:getPitch() < -0.03 then
						self.controls.pitchChange = dt*2
					elseif self.rotation:getPitch() > 0.03 then
						self.controls.pitchChange = dt*-2
					end
				elseif types.Actor.getStance(self) == types.Actor.STANCE.Weapon and MoveBackward(0.5) and self.rotation:getPitch() < 0.45 then
					self.controls.pitchChange = dt*2
				elseif types.Actor.getStance(self) == types.Actor.STANCE.Weapon and MoveForward(-0.5) and self.rotation:getPitch() > -0.45 then
					self.controls.pitchChange = dt*-2
				end
--			end
		elseif types.Actor.getStance(self)==types.Actor.STANCE.Nothing then
			if self.rotation:getPitch() <= 0.03 and self.rotation:getPitch() >= -0.03 then
			elseif self.rotation:getPitch() < -0.03 then
				self.controls.pitchChange = dt*2
			elseif self.rotation:getPitch() > 0.03 then
				self.controls.pitchChange = dt*-2
			end
		end
		---------------test viser uniquement sur pression bouton ->ok
		--if types.Actor.getEquipment(self,16) then
		--	print("weaponcondition="..tostring(weaponcondition))
		--	print("Actual weaponcondition="..tostring(types.Item.itemData(types.Actor.getEquipment(self,16)).condition))
		--end
		if types.Actor.getEquipment(self, 16) and (types.Weapon.record(types.Actor.getEquipment(self, 16)).type == 10 or types.Weapon.record(types.Actor.getEquipment(self, 16)).type == 9) and weaponcondition > 9000 and types.Actor.getStance(self) == types.Actor.STANCE.Weapon then
			types.Actor.getEquipment(self, 16):sendEvent('setCondition', { value = weaponcondition })
		end
	--	if types.Actor.getEquipment(self, 16) and types.Actor.getEquipment(self, 16) == EquippedWeapon and types.Item.itemData(types.Actor.getEquipment(self, 16)).condition ~= weaponcondition then
	--		types.Actor.getEquipment(self, 16):sendEvent('setCondition', { value = weaponcondition })
	--	end

		if R1 == false and R2 == false and Instantammo ~= 0 then
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

		if (R1 == true or R2 == true) and types.Actor.getEquipment(self, 16) and (AmmoChecked == 1 or types.Actor.getEquipment(self, 16)) then ----degainer l'arme
			types.Actor.setStance(self, 1)
			self.controls.use = 1
			actionbasetime = 4 *core.getGameTimeScale()
			
			if SheathTimer==0 then
				SheathTimer=core.getGameTime()
			end


			if types.Weapon.record(types.Actor.getEquipment(self, 16)).type == 10 or types.Weapon.record(types.Actor.getEquipment(self, 16)).type == 9 then
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

			if Cross and ((types.Item.getEnchantmentCharge(types.Actor.getEquipment(self, 16))~=nil and types.Item.getEnchantmentCharge(types.Actor.getEquipment(self, 16))>0) or types.Weapon.record(types.Actor.getEquipment(self, 16)).type ~= 10) and (core.getGameTime() - shootTimer) > (actionbasetime / types.Weapon.record(types.Actor.getEquipment(self, 16)).speed) and (core.getGameTime()-SheathTimer)>1 then -- Fire!!
				self.controls.use = 0
				shootTimer = (core.getGameTime())

				if types.Weapon.record(types.Actor.getEquipment(self, 16)).type == 10 or types.Weapon.record(types.Actor.getEquipment(self, 16)).type == 9 then
					core.sendGlobalEvent('setCharge',{Item = types.Actor.getEquipment(self, 16), value = types.Item.getEnchantmentCharge(types.Actor.getEquipment(self, 16)) - 1})
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
							S.shellDamage = types.Weapon.record(types.Actor.getEquipment(self, 18)).thrustMinDamage
							S.shellEnchant = core.magic.enchantments.records[types.Weapon.record(types.Actor.getEquipment(self, 18)).enchant]
							for a = 1, pellets do
								--S.ShellPos=util.transform.move(0,0,70)*self.position+ util.transform.rotate(1,util.vector3(0,0,math.pi/2))self.rotation*util.vector3(0,1,0)*100
								S.ShellRotX = RotX + math.random(-5,5)*math.pi*types.Weapon.record(types.Actor.getEquipment(self, 16)).slashMinDamage/(180*11)
								S.ShellRotZ = RotZ + math.random(-5,5)*math.pi*types.Weapon.record(types.Actor.getEquipment(self, 16)).slashMinDamage/(180*11)
								local ray = nearby.castRay(util.vector3(0, 0, 80) + self.position,
									util.vector3(0, 0, 80) + self.position +
									util.vector3(math.cos(S.ShellRotZ) * math.sin(S.ShellRotX),math.cos(S.ShellRotZ) * math.cos(S.ShellRotX), -math.sin(S.ShellRotZ)) * shelldistance,{ ignore = self })
								--print(ray.hitPos)
								--print(ray.hitObject)
								if ray.hitObject and ray.hitObject.type == types.Creature and types.Actor.isDead(ray.hitObject)==nil then
									ray.hitObject:sendEvent('DamageEffects', { damages = S.shellDamage }) --,enchant=S.shellEnchant})
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


			elseif Cross and types.Item.getEnchantmentCharge(types.Actor.getEquipment(self, 16)) == 0 and (core.getGameTime()- shootTimer) > (actionbasetime / types.Weapon.record(types.Actor.getEquipment(self, 16)).speed) then
				ui.showMessage("Weapon empty")
				shootTimer = (core.getGameTime())
				ambient.playSound("ClipEmpty")
				types.Actor.setEquipment(self, {
					[types.Actor.EQUIPMENT_SLOT.CarriedRight] = types.Actor.getEquipment(self,
						16)
				})
			elseif Square == true and (core.getGameTime() - shootTimer) > (actionbasetime / types.Weapon.record(types.Actor.getEquipment(self, 16)).speed) and storage.playerSection('RESettings1'):get('Reload')==true then
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
				if R1 == true and storage.playerSection('RESettings1'):get('AutoAim')==true then -----cible bow
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
						if actors.type == types.Creature and types.Creature.record(actors).mwscript and string.find(types.Creature.record(actors).mwscript, "_attackobjects_") == nil and (self.position - TargetBOW.position):length() > (self.position - actors.position):length() and types.Actor.stats.dynamic.health(actors).current > 0 then
							TargetBOW = actors
							table.insert(TargetedBOW, TargetBOW)
							--print((self.position-TargetBOW.position):length())
							--print(TargetBOW)
						end
					end

--					ui.showMessage(tostring(TargetBOW))
					TurnToTarget(TargetBOW)
				elseif R2 == true and storage.playerSection('RESettings1'):get('AutoAim')==true then -------------cible attackobject
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

--					ui.showMessage(tostring(TargetAttackObject))
					TurnToTarget(TargetAttackObject)
				end
			elseif L1 and R1 and changetarget == 0 and storage.playerSection('RESettings1'):get('AutoAim')==true then --------Change target BOW
				changetarget = 1
				for i, actors in pairs(nearby.actors) do
					BOWchecked = 0
					if actors.type == types.Creature and types.Actor.stats.dynamic.health(actors).current > 0 then
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

--				ui.showMessage(tostring(TargetBOW))
				TurnToTarget(TargetBOW)
			elseif L1 and R2 and changetarget == 0 and storage.playerSection('RESettings1'):get('AutoAim')==true  then --------Change target attackobject
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

--				ui.showMessage(tostring(TargetAttackObject))
				TurnToTarget(TargetAttackObject)
			elseif L1 == false then
				changetarget = 0
			end
		else
			types.Actor.setStance(self, 0)
			ToggleWeaponButton = false
			TargetedBOW = {}
			TargetAttackObject = {}
			if SheathTimer>0 then
				SheathTimer=0
			end

		end
	end


	if onFrameHealth ~= types.Actor.stats.dynamic.health(self).current then
		onFrameHealth = types.Actor.stats.dynamic.health(self).current
	end





	------- picking items 1/2
	if PickUpItem[2] == true and PickUpItem[3] == nil then
		ShowInventory()
		InventoryItemSelected[2] = nil
		PickUpItem[3] = true
		ShowItem(PickUpItem[1], 'You Pickup ' .. PickUpItem[1].recordId)
		PickUpItem[1]:activateBy(self)
		print(PickUpItem[1].recordId)
		print(PickUpItem[1].recordId=="hk p_grenage launcher")
		print(AmmoUsage[PickUpItem[1].recordId])
		if PickUpItem[1].type==types.Weapon and AmmoUsage[PickUpItem[1].recordId] and types.Item.itemData(PickUpItem[1]).condition==10010 then
			core.sendGlobalEvent('setCharge',
			{ Item = PickUpItem[1], value = AmmoUsage[PickUpItem[1].recordId][1][1] })
			PickUpItem[1]:sendEvent('setCondition', { value = 10001 })
		end
	elseif PickUpItem[2] == false and PickUpItem[3] == nil then
		ShowInventory()
		InventoryItemSelected[2] = nil
		PickUpItem[3] = true
		ShowItem(PickUpItem[1], "You can't pickup " .. PickUpItem[1].recordId .. '. Your Inventory is full.')
	end


end










local function LiveSelection(data)
	LiveSelect.Choice1=data.Choice1
	LiveSelect.Choice2=data.Choice2
	negativeshader:enable()
	LiveSelect.UI = ui.create({
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
--		SavingMenuUI=ui.create({layer = 'InputBlocker',  type = ui.TYPE.Image,
		props = {relativeSize = util.vector2(1,1),relativePosition=util.vector2(0.5, 0.5),anchor = util.vector2(0.5, 0.5),resource = ui.texture{path ="textures/TypeWritter.png"},},
--		props = {relativeSize = util.vector2(1,1),relativePosition=util.vector2(0.5, 0.5),anchor = util.vector2(0.5, 0.5),resource = ui.texture{path ="textures/BlackScreen.png"},},----------------------
		content=ui.content{
			{ type = ui.TYPE.Flex, props = {relativeSize = util.vector2(1,1),relativePosition=util.vector2(0.6, 0.7),anchor = util.vector2(0.5, 0.5)}, content=ui.content{
				{ type = ui.TYPE.Text,  props = {visible=true, text = " 1 . "..Saves[1]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White} },
				{ type = ui.TYPE.Text,  props = {visible=true,  text = " 2 . "..Saves[2]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Text,  props = {visible=true,  text = " 3 . "..Saves[3]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Text,  props = {visible=true,  text = " 4 . "..Saves[4]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Text,  props = {visible=true,  text = " 5 . "..Saves[5]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Text,  props = {visible=true,  text = " 6 . "..Saves[6]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Text,  props = {visible=true,  text = " 7 . "..Saves[7]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Text,  props = {visible=true,  text = " 8 . "..Saves[8]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Text,  props = {visible=true,  text = " 9 . "..Saves[9]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White } },
				{ type = ui.TYPE.Text,  props = {visible=true,  text = "10 . "..Saves[10]["description"],relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White } },
--				{ type = ui.TYPE.Text,  props = {visible=false,  text = "",relativePosition=util.vector2(2/16, 7/16), textSize = 65*textSizeRatio, textColor = Colors.White } },
				
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

local ElectricalPanelPuzzleUI={}

local function ElectricalPanelPuzzle(data)
	if (ElectricalPanelPuzzleUI.UI == nil) then --and ElectricalPanelPuzzleUI.UI.layout == nil) then
		print(data.Value)
		print(data.object)
		ElectricalPanelPuzzleUI.Value=data.Value
		ElectricalPanelPuzzleUI.States={}
		ElectricalPanelPuzzleUI.Object=data.Object
		I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
		ElectricalPanelPuzzleUI.UI=ui.create({layer = 'HUD',  type = ui.TYPE.Image,
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


local CrowbarPuzzleUI={}

local function CrowbarPuzzle(data)
	if (CrowbarPuzzleUI.UI == nil or CrowbarPuzzleUI.UI.layout == nil) then
		CrowbarPuzzleUI.Way=1
		CrowbarPuzzleUI.Speed=0.5
		CrowbarPuzzleUI.value=data.value
		CrowbarPuzzleUI.timer=0
		CrowbarPuzzleUI.Object=data.Object
		--print(CrowbarPuzzleUI.value)
		I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
		CrowbarPuzzleUI.UI=ui.create({layer = 'HUD',  type = ui.TYPE.Image,
		props = {relativeSize = util.vector2(0.5,0.1),relativePosition=util.vector2(0.5, 0.75),anchor = util.vector2(0.5, 0.5),resource = ui.texture{path ="textures/Puzzles/Crowbar/bar.png"},},
		content=ui.content{
			{type = ui.TYPE.Image,  props = {color=Colors.White, resource = ui.texture{path ="textures/Puzzles/Crowbar/cursor.png"},relativeSize=util.vector2(1, 1),relativePosition=util.vector2(0.1*CrowbarPuzzleUI.value, 0.5),anchor = util.vector2(0.5, 0.5)} },
			{type = ui.TYPE.Text, props = { text = "Action : Force with the crowbar", textSize =50*textSizeRatio,relativePosition = util.vector2(1/2, 8/10),textColor=Colors.White, anchor = util.vector2(0.5, 0.5) } },
		
		}})
		
	end

end



local MenuSelection={}
local MenuSelectionContent={}

local function ChoicesSelection(data)
	if MenuSelection==nil or MenuSelection.layout==nil then
		I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
		MenuSelection={}
		MenuSelectionContent={}
		for i, variable in pairs(data.selection) do
			--print(variable)
			table.insert(MenuSelectionContent,{ type = ui.TYPE.Image, props = {position = util.vector2(0, 0.5), anchor = util.vector2(0, 0), size = util.vector2(20, 20), visible = false, resource = ui.texture { path = "textures/Choice select cursor.dds" } } })
			table.insert(MenuSelectionContent,{ type = ui.TYPE.Text,  props = { text = variable, textSize = 30*textSizeRatio, textColor = util.color.rgb(1, 1, 1) } })
		end
		MenuSelection=ui.create({layer = 'Console',type = ui.TYPE.Flex,props = {arrange=ui.ALIGNMENT.Center, autoSize = true, horizontal = true, relativePosition = util.vector2(1 / 2, 10/11), anchor = util.vector2(0, 0), },
			content =ui.content(MenuSelectionContent)})
		MenuSelection.layout.content[1].props.visible=true
		MenuSelection:update()
	end
end


local function onFrameLiveSelectionUI()
		
	--	if negativeshader:isEnabled() and (LiveSelect.UI == nil or LiveSelect.UI.layout==nil) and LiveSelect.Timer==0 then
	--		LiveSelect.Timer=core.getRealTime()
	--	elseif negativeshader:isEnabled() and (core.getRealTime()-LiveSelect.Timer)>3 and (LiveSelect.UI == nil or LiveSelect.UI.layout==nil) then
	--		LiveSelect.Timer=0
	--		negativeshader:disable()
	--	end
	if negativeshader:isEnabled() and LiveSelect.UI == nil then
		negativeshader:disable()
	end
	if LiveSelect.UI then
		if LiveSelect.Timer==0 then
			LiveSelect.Timer=core.getRealTime()
		end
		--print(LiveSelect.Timer)
		if (core.getRealTime()-LiveSelect.Timer)>9 then
			--print('9')
			core.sendGlobalEvent("ReturnGlobalVariable",{variable=LiveSelect.Choice1,player=self,value=3})
			core.sendGlobalEvent("ReturnGlobalVariable",{variable=LiveSelect.Choice2,player=self,value=0})
			LiveSelect.UI:destroy()
			LiveSelect.UI=nil
			LiveSelect.Timer=0
			negativeshader:enable()
		elseif (core.getRealTime()-LiveSelect.Timer)>7 then
			--print("7")
			if I.UI.getMode() then 
				negativeshader:disable()
				I.UI.removeMode(I.UI.MODE.Interface)
				LiveSelect.UI.layout.content[1].content[1].props.textColor = util.color.rgb(1, 1, 1)
				LiveSelect.UI.layout.content[3].content[1].props.textColor = util.color.rgb(1, 1, 1)
				LiveSelect.UI.layout.props.relativePosition = util.vector2(0.5, 0.7)
				LiveSelect.UI:update()
			end
			if (string.byte(core.getRealTime()%1,3)==48 or string.byte(core.getRealTime()%1,3)==52 or string.byte(core.getRealTime()%1,3)==56) and WrapperTemplate.props.resource==Borderbox then
				WrapperTemplate.props.resource= TransparentBorderBox
				LiveSelect.UI:update()
			elseif (string.byte(core.getRealTime()%1,3)==50 or string.byte(core.getRealTime()%1,3)==54 or string.byte(core.getRealTime()%1,3)==57) and WrapperTemplate.props.resource==TransparentBorderBox then
				WrapperTemplate.props.resource= Borderbox
				LiveSelect.UI:update()
			end
		elseif (core.getRealTime()-LiveSelect.Timer)>6 then
			--print("6")
			if  I.UI.getMode() == nil then
				WrapperTemplate.props.color=Colors.Red
				negativeshader:enable()
				I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
				LiveSelect.UI.layout.content[1].content[1].props.textColor = util.color.rgb(0, 0, 0)
				LiveSelect.UI.layout.content[3].content[1].props.textColor = util.color.rgb(0, 0, 0)
				if LiveSelect.UI.layout.content[1].template then
					LiveSelect.UI.layout.content[1].template=WrapperTemplate
				else
					LiveSelect.UI.layout.content[3].template=WrapperTemplate
				end
				LiveSelect.UI:update()
			end
		elseif (core.getRealTime()-LiveSelect.Timer)>4 then
			--print("4")
			if I.UI.getMode() then 
				negativeshader:disable()
				I.UI.removeMode(I.UI.MODE.Interface)
				LiveSelect.UI.layout.content[1].content[1].props.textColor = util.color.rgb(1, 1, 1)
				LiveSelect.UI.layout.content[3].content[1].props.textColor = util.color.rgb(1, 1, 1)
				LiveSelect.UI:update()
			end
			if (string.byte(core.getRealTime()%1,3)==48 or string.byte(core.getRealTime()%1,3)==54) and WrapperTemplate.props.resource==Borderbox then
				WrapperTemplate.props.resource= TransparentBorderBox
				LiveSelect.UI:update()
			elseif (string.byte(core.getRealTime()%1,3)==50 or string.byte(core.getRealTime()%1,3)==56) and WrapperTemplate.props.resource==TransparentBorderBox then
				WrapperTemplate.props.resource= Borderbox
				LiveSelect.UI:update()
			end
		elseif (core.getRealTime()-LiveSelect.Timer)>3 then
			--print("3")
			if  I.UI.getMode() == nil then
				WrapperTemplate.props.color=Colors.Orange
				negativeshader:enable()
				I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
				LiveSelect.UI.layout.content[1].content[1].props.textColor = util.color.rgb(0, 0, 0)
				LiveSelect.UI.layout.content[3].content[1].props.textColor = util.color.rgb(0, 0, 0)
				if LiveSelect.UI.layout.content[1].template then
					LiveSelect.UI.layout.content[1].template=WrapperTemplate
				else
					LiveSelect.UI.layout.content[3].template=WrapperTemplate
				end
				LiveSelect.UI:update()
			end
		elseif (core.getRealTime()-LiveSelect.Timer)>1 then
			--print("1")
			if I.UI.getMode() then 
				LiveSelect.UI.layout.content[1].template = WrapperTemplate
				negativeshader:disable()
				I.UI.removeMode(I.UI.MODE.Interface)
				LiveSelect.UI.layout.content[1].content[1].props.textColor = util.color.rgb(1, 1, 1)
				LiveSelect.UI.layout.content[3].content[1].props.textColor = util.color.rgb(1, 1, 1)
				LiveSelect.UI.layout.props.relativePosition = util.vector2(0.5, 0.7)
				LiveSelect.UI:update()
			end
			if string.byte(core.getRealTime()%1,3)==48 and WrapperTemplate.props.resource==Borderbox then
				WrapperTemplate.props.resource= TransparentBorderBox
				LiveSelect.UI:update()
			elseif string.byte(core.getRealTime()%1,3)==52 and WrapperTemplate.props.resource==TransparentBorderBox then
				WrapperTemplate.props.resource= Borderbox
				LiveSelect.UI:update()
			end

		elseif (core.getRealTime()-LiveSelect.Timer)>0.1 and I.UI.getMode() == nil then
				I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
		end

		if (ButtonToggle("Down",MoveBackward(0.3)) or ButtonToggle("Up",MoveForward(-0.3))) and I.UI.getMode() == nil then
			ambient.playSound("Cursor")
			if LiveSelect.UI.layout.content[1].template == nil then
				LiveSelect.UI.layout.content[1].template = WrapperTemplate
				LiveSelect.UI.layout.content[3].template = nil
			else
				LiveSelect.UI.layout.content[1].template = nil
				LiveSelect.UI.layout.content[3].template = WrapperTemplate
			end
			LiveSelect.UI:update()
		elseif Cross and I.UI.getMode() == nil and (core.getRealTime()-LiveSelect.Timer)>0.1 then
			if LiveSelect.UI.layout.content[1].template then
				core.sendGlobalEvent("ReturnGlobalVariable",{variable=LiveSelect.Choice1,player=self,value=1})
				core.sendGlobalEvent("ReturnGlobalVariable",{variable=LiveSelect.Choice2,player=self,value=0})
			elseif LiveSelect.UI.layout.content[3].template then
				core.sendGlobalEvent("ReturnGlobalVariable",{variable=LiveSelect.Choice1,player=self,value=2})
				core.sendGlobalEvent("ReturnGlobalVariable",{variable=LiveSelect.Choice2,player=self,value=0})
			end
			LiveSelect.UI:destroy()
			LiveSelect.UI=nil
			LiveSelect.Timer=0
			negativeshader:enable()
		end
	end
end


local function 	onFrameMaps(DeltaT)
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
						--print(MapsUtils["RoomsVisited"][i][2][j][2][k])
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
						MapsUtils.Blink.Value=DeltaT*-1
					elseif MapUI.layout.content[MapsUtils.Blink.Room].props.alpha<=0.2 then
						MapsUtils.Blink.Value=DeltaT*1
					end
					MapUI.layout.content[MapsUtils.Blink.Room].props.alpha=MapUI.layout.content[MapsUtils.Blink.Room].props.alpha+MapsUtils.Blink.Value
					MapUI:update()
					if ButtonToggle("L1",L1)==true then
							if CheckTableUD(MapsUtils["RoomsVisited"][AreaMap][2][ZoneMap][2],RoomMap,"+")~=0 then
								--print("here")
								RoomMap=CheckTableUD(MapsUtils["RoomsVisited"][AreaMap][2][ZoneMap][2],RoomMap,"+")+RoomMap
								core.sendGlobalEvent('AskObjectsInWorld',{player=self,maps=Maps})
								ambient.playSound("Cursor")
							end

					elseif ButtonToggle("R1",R1)==true then
							if CheckTableUD(MapsUtils["RoomsVisited"][AreaMap][2][ZoneMap][2],RoomMap,"-")~=0 then
								--print("there")
								RoomMap=CheckTableUD(MapsUtils["RoomsVisited"][AreaMap][2][ZoneMap][2],RoomMap,"-")+RoomMap
								core.sendGlobalEvent('AskObjectsInWorld',{player=self,maps=Maps})
								ambient.playSound("Cursor")
							end	
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


		end
	end
end



local function ItemChecheck()

	if ItemChecked.Show.Object and ItemChecked["Icon"] and ItemChecked["Icon"].layout then
		if MoveBackward(0.2)=="Down" then
			core.sendGlobalEvent('Teleport',
						{ object = ItemChecked.Show.Object , position = ItemChecked.Show.Object .position, rotation = ItemChecked.Show.Object .rotation*util.transform.rotateY(-0.02)})
			ItemChecked["Icon"].layout.content[1].content[3].props.color=Colors.Red
			ItemChecked["Icon"]:update()
		elseif MoveForward(-0.2)=="Up" then
			core.sendGlobalEvent('Teleport',
						{ object = ItemChecked.Show.Object , position = ItemChecked.Show.Object .position, rotation = ItemChecked.Show.Object .rotation*util.transform.rotateY(0.02)})
			ItemChecked["Icon"].layout.content[1].content[2].props.color=Colors.Red
			ItemChecked["Icon"]:update()
		elseif TurnRight(0.2)=="Right" then
			core.sendGlobalEvent('Teleport',
						{ object = ItemChecked.Show.Object , position = ItemChecked.Show.Object .position, rotation = ItemChecked.Show.Object .rotation*util.transform.rotateZ(0.02)})
			ItemChecked["Icon"].layout.content[1].content[1].props.color=Colors.Red
			ItemChecked["Icon"]:update()
		elseif TurnLeft(-0.2)=="Left" then
			core.sendGlobalEvent('Teleport',
						{ object = ItemChecked.Show.Object , position = ItemChecked.Show.Object .position, rotation = ItemChecked.Show.Object .rotation*util.transform.rotateZ(-0.02)})
			ItemChecked["Icon"].layout.content[1].content[4].props.color=Colors.Red
			ItemChecked["Icon"]:update()
		elseif L1 then
			core.sendGlobalEvent('Teleport',
						{ object = ItemChecked.Show.Object , position = ItemChecked.Show.Object .position, rotation = ItemChecked.Show.Object .rotation*util.transform.rotateX(-0.02)})
		elseif R1 then
			core.sendGlobalEvent('Teleport',
						{ object = ItemChecked.Show.Object , position = ItemChecked.Show.Object .position, rotation = ItemChecked.Show.Object .rotation*util.transform.rotateX(0.02)})
		end
		if ItemChecked["Icon"].layout.content[1].content[3].props.color==Colors.Red and MoveBackward(0.2)==false then
			ItemChecked["Icon"].layout.content[1].content[3].props.color=Colors.DarkRed
			ItemChecked["Icon"]:update()
		end
		if ItemChecked["Icon"].layout.content[1].content[2].props.color==Colors.Red and MoveForward(-0.2)==false then
			ItemChecked["Icon"].layout.content[1].content[2].props.color=Colors.DarkRed
			ItemChecked["Icon"]:update()		
		end
		if ItemChecked["Icon"].layout.content[1].content[1].props.color==Colors.Red and TurnRight(0.2)==false then
			ItemChecked["Icon"].layout.content[1].content[1].props.color=Colors.DarkRed
			ItemChecked["Icon"]:update()		
		end
		if ItemChecked["Icon"].layout.content[1].content[4].props.color==Colors.Red and TurnLeft(-0.2)==false then
			ItemChecked["Icon"].layout.content[1].content[4].props.color=Colors.DarkRed
			ItemChecked["Icon"]:update()
		end


		if ItemChecked.Show.Object .scale>0.05 and L2 then
			core.sendGlobalEvent('SetScale',
						{ object = ItemChecked.Show.Object , scale=ItemChecked.Show.Object .scale-.01})

		elseif ItemChecked.Show.Object .scale<=0.1 and R2 then
			core.sendGlobalEvent('SetScale',
						{ object = ItemChecked.Show.Object , scale=ItemChecked.Show.Object .scale+.01})
		end 
	end

end


local ModeNilTempo=0
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local DeltaT=core.getRealTime()

local function onFrame(dt)



	DeltaT=core.getRealTime()-DeltaT
	ItemChecheck()

	if ItemChecked.Show.Object~=nil and ItemChecked["Icon"]==nil then
		print("hum")
		core.sendGlobalEvent('RemoveItem', { Item = ItemChecked.Show.Object , number = 1})
		core.sendGlobalEvent('RemoveItem', { Item = ItemChecked.Show.Light , number = 1})
		ItemChecked.Show={}			
	end



	R1 = input.getBooleanActionValue('R1')
	--if R1 then print("R1") end
	R2 = input.getBooleanActionValue('R2')
	--if R2 then print("R2") end
	L1 = input.getBooleanActionValue('L1')
	--if L1 then print("L1") end
	L2 = input.getBooleanActionValue('L2')
	--if L2 then print("L2") end
	Up = input.getBooleanActionValue('Up')
	--if Up then print("Up") end
	Down = input.getBooleanActionValue('Down')
	--if Down then print("Down") end
	Right = input.getBooleanActionValue('Right')
	--if Right then print("Right") end
	Left = input.getBooleanActionValue('Left')
	--if Left then print("Left") end
	Cross = input.getBooleanActionValue('Cross')
	--if Cross then print("Cross") end
	Square = input.getBooleanActionValue('Square')
	--if Square then print("Square") end
	Circle = input.getBooleanActionValue('Circle')
	--if Circle then print("Circle") end
	
	if types.Actor.getStance(self) == types.Actor.STANCE.Nothing then
		Overload()	
	end





	if I.UI.getMode() then

		if I.UI.getMode()=="Container" then
			I.UI.removeMode("Container")
		end


		if MessageBoxUI.UI and MessageBoxUI.UI.layout then
			if ButtonToggle("Cross",Cross) then
				MessageBoxUI.UI:destroy()
				I.UI.removeMode(I.UI.MODE.Interface)	
			end
		end


		UI.RunningUI(MoveForward,MoveBackward,TurnLeft,TurnRight,Colors,Saves,SavingMenuUI, MapUI, MapsUtils, Maps, Cross)

		
		Puzzles.RunningPuzzles(self,input,util,DeltaT,core,I,MoveForward,MoveBackward,TurnLeft,TurnRight,Colors,ElectricalPanelPuzzleUI,MenuSelection,Lockpicking,Cross,CrowbarPuzzleUI,ButtonToggle,Toggle)


		if filesList.documentWindow and filesList.documentWindow.layout then
			filesList.ArrowsTimer=filesList.ArrowsTimer+DeltaT
			if filesList.ArrowsTimer>0.5 then
				filesList.ArrowsTimer=0
				if filesList.documentWindow.layout.content.ArrowL.props.relativePosition.x>0.101 then
					filesList.documentWindow.layout.content.ArrowL.props.relativePosition=filesList.documentWindow.layout.content.ArrowL.props.relativePosition+util.vector2(-0.01,0)
				else
					filesList.documentWindow.layout.content.ArrowL.props.relativePosition=filesList.documentWindow.layout.content.ArrowL.props.relativePosition+util.vector2(0.01,0)
				end
				if filesList.documentWindow.layout.content.ArrowR.props.relativePosition.x<0.899 then
					filesList.documentWindow.layout.content.ArrowR.props.relativePosition=filesList.documentWindow.layout.content.ArrowR.props.relativePosition+util.vector2(0.01,0)
				else
					filesList.documentWindow.layout.content.ArrowR.props.relativePosition=filesList.documentWindow.layout.content.ArrowR.props.relativePosition+util.vector2(-0.01,0)
				end
				filesList.documentWindow:update()
			end
			if ButtonToggle("Left",TurnLeft(-0.2)) then
				if filesList.Page>1 and filesList.documentWindow.layout.content.EXIT.props.textColor==Colors.Grey then
					filesList.Page=filesList.Page-1
					local readable_space_shifter = require("scripts.openmw_books_enhanced.outside_manipulators.readable_space_shifter")
					readable_space_shifter.shiftToPrevPage(filesList.documentWindow)
					ambient.playSound("Book Page")
					if filesList.Page==1 then
						filesList.documentWindow.layout.content.ArrowL.props.visible=false
					end
					filesList.documentWindow.layout.content.ArrowR.props.visible=true
					filesList.documentWindow.layout.content.EXIT.props.visible=false
					filesList.documentWindow:update()
				elseif filesList.documentWindow.layout.content.EXIT.props.textColor==Colors.White then
					filesList.Page=filesList.Page-1
					filesList.documentWindow.layout.content.EXIT.props.textColor=Colors.Grey
					filesList.documentWindow.layout.content.ArrowL.props.visible=true
					filesList.documentWindow:update()
				end
			elseif ButtonToggle("Right",TurnRight(0.2)) then
				if filesList.Page<filesList.documentWindow.layout.userData.lines[#filesList.documentWindow.layout.userData.lines].userData.page then
					filesList.Page=filesList.Page+1
					if filesList.Page==filesList.documentWindow.layout.userData.lines[#filesList.documentWindow.layout.userData.lines].userData.page then
						filesList.documentWindow.layout.content.ArrowR.props.visible=false
						filesList.documentWindow.layout.content.EXIT.props.visible=true
					end
					filesList.documentWindow.layout.content.ArrowL.props.visible=true
					local readable_space_shifter = require("scripts.openmw_books_enhanced.outside_manipulators.readable_space_shifter")
					readable_space_shifter.shiftToNextPage(filesList.documentWindow)
					ambient.playSound("Book Page")
					filesList.documentWindow:update()
				elseif filesList.documentWindow.layout.content.EXIT.props.visible==true and filesList.documentWindow.layout.content.EXIT.props.textColor==Colors.Grey then
					filesList.Page=filesList.Page+1
					filesList.documentWindow.layout.content.EXIT.props.textColor=Colors.White
					filesList.documentWindow.layout.content.ArrowL.props.visible=false
					ambient.playSound("Cursor")
					filesList.documentWindow:update()
				end
			elseif ButtonToggle("Cross",Cross) and filesList.documentWindow.layout.content.EXIT.props.textColor==Colors.White then
				filesList.documentWindow:destroy()
				if Inventory.UI==nil or Inventory.UI.layout==nil then
					I.UI.removeMode(I.UI.MODE.Interface)
				end
				ambient.playSound("REdecide")
			end
		end



		if Inventory.UI and Inventory.UI.layout and (ElectricalPanelPuzzleUI.UI == nil or ElectricalPanelPuzzleUI.UI.layout == nil or CrowbarPuzzleUI.UI.layout==nil) then

			if filesList.UI.layout and (filesList.documentWindow==nil or filesList.documentWindow.layout==nil)  then
				if filesList.BooksTargetX>filesList.UI.layout.content[filesList.Book].props.relativePosition.x and math.floor(math.abs(filesList.BooksTargetX-filesList.UI.layout.content[filesList.Book].props.relativePosition.x)*100+0.5)>0 then
					for i, book in pairs(filesList.UI.layout.content) do
						if book.props then
							book.props.relativePosition=book.props.relativePosition+util.vector2(DeltaT,0)
						end
					end
					filesList.UI:update()
				elseif filesList.BooksTargetX<filesList.UI.layout.content[filesList.Book].props.relativePosition.x and math.floor(math.abs(filesList.BooksTargetX-filesList.UI.layout.content[filesList.Book].props.relativePosition.x)*100+0.5)>0  then
					for i, book in pairs(filesList.UI.layout.content) do
						if book.props then
							book.props.relativePosition=book.props.relativePosition+util.vector2(-DeltaT,0)
						end
					end
					filesList.UI:update()
				end

				if ButtonToggle("Left",TurnLeft(-0.2)) then
					print("left")
					if filesList.Book>1 and filesList.Bookmarks[(filesList.Book-1)*10] then
						filesList.BooksTargetX=filesList.BooksTargetX+1/200
						filesList.Book=filesList.Book-1
						filesList.Bookmark=0
						for i, content in pairs(filesList.UI.layout.content[filesList.Book].content) do
							if content.props and content.props.visible==true then
								content.props.color=util.color.rgb(1, 1, 1)
							end
						end
						for i, content in pairs(filesList.UI.layout.content[filesList.Book].content) do
							if content.props and content.props.visible==true then
								filesList.Bookmark=i
								content.props.color=util.color.rgb(0.5, 0.5, 0.5)
								break
							end
						end
						
						filesList.UI:update()
						ambient.playSound("Cursor")
						
--						ui.showMessage(filesList.Bookmarks[(filesList.Book-1)*10+filesList.Bookmark])
						Inventory.UI.layout.content.Description.props.text=filesList.Bookmarks[(filesList.Book-1)*10+filesList.Bookmark]
						Inventory.UI:update()
					end
	
					
				elseif ButtonToggle("Right",TurnRight(0.2)) then
					print("right")
					if filesList.Book<5 and filesList.Bookmarks[(filesList.Book)*10+1] then
						filesList.BooksTargetX=filesList.BooksTargetX-1/200
						filesList.Book=filesList.Book+1
						filesList.Bookmark=0
						for i, content in pairs(filesList.UI.layout.content[filesList.Book].content) do
							if content.props and content.props.visible==true then
								content.props.color=util.color.rgb(1, 1, 1)
							end
						end
						for i, content in pairs(filesList.UI.layout.content[filesList.Book].content) do
							if content.props and content.props.visible==true then
								filesList.Bookmark=i
								content.props.color=util.color.rgb(0.5, 0.5, 0.5)
								break
							end
						end
						
						filesList.UI:update()
						ambient.playSound("Cursor")
						if types.Actor.inventory(self):find(filesList.Bookmarks[(filesList.Book-1)*10+filesList.Bookmark]) then
--							ui.showMessage(filesList.Bookmarks[(filesList.Book-1)*10+filesList.Bookmark])
							Inventory.UI.layout.content.Description.props.text=filesList.Bookmarks[(filesList.Book-1)*10+filesList.Bookmark]
							Inventory.UI:update()
						end
					end
					
	
				elseif ButtonToggle("Down",MoveBackward(0.3)) then------------à corriger pour si pas de marque page dans livre
					print("down")
	
					for i=filesList.Bookmark,10 do
						if filesList.UI.layout.content[filesList.Book].content[i].props.visible==true and i>filesList.Bookmark then
							filesList.UI.layout.content[filesList.Book].content[filesList.Bookmark].props.color=util.color.rgb(1, 1, 1)
							filesList.UI.layout.content[filesList.Book].content[i].props.color=util.color.rgb(0.5, 0.5, 0.5)
							filesList.Bookmark=i
							filesList.UI:update()
--							ui.showMessage(filesList.Bookmarks[(filesList.Book-1)*10+filesList.Bookmark])
							Inventory.UI.layout.content.Description.props.text=filesList.Bookmarks[(filesList.Book-1)*10+filesList.Bookmark]
							Inventory.UI:update()
							ambient.playSound("Book Page")
							break
						end
					end
	
				elseif ButtonToggle("Up",MoveForward(-0.3)) then
					print("up")
	
					for i=1, (filesList.Bookmark-1) do
						print(filesList.UI.layout.content[filesList.Book].content[(filesList.Bookmark-i)].props.visible)
						if filesList.UI.layout.content[filesList.Book].content[(filesList.Bookmark-i)].props.visible==true and (filesList.Bookmark-i)<filesList.Bookmark then
							print(filesList.Bookmark-i)
							filesList.UI.layout.content[filesList.Book].content[filesList.Bookmark].props.color=util.color.rgb(1, 1, 1)
							filesList.UI.layout.content[filesList.Book].content[(filesList.Bookmark-i)].props.color=util.color.rgb(0.5, 0.5, 0.5)
							filesList.Bookmark=filesList.Bookmark-i
							filesList.UI:update()
--							ui.showMessage(filesList.Bookmarks[(filesList.Book-1)*10+filesList.Bookmark])
							Inventory.UI.layout.content.Description.props.text=filesList.Bookmarks[(filesList.Book-1)*10+filesList.Bookmark]
							Inventory.UI:update()
							ambient.playSound("Book Page")
							break
						end
					end
					
				elseif ButtonToggle("Cross",Cross) and types.Actor.inventory(self):find(filesList.Bookmarks[(filesList.Book-1)*10+filesList.Bookmark]) then
					print("cross")
					print(types.Actor.inventory(self):find(filesList.Bookmarks[(filesList.Book-1)*10+filesList.Bookmark]))
					--self:sendEvent('openmwBooksEnhancedBookActivated', { activatedBookObject = types.Actor.inventory(self):find(filesList.Bookmarks[(filesList.Book-1)*10+filesList.Bookmark]) })
					onBookOpened({activatedBookObject=types.Actor.inventory(self):find(filesList.Bookmarks[(filesList.Book-1)*10+filesList.Bookmark])})

				elseif (ButtonToggle("R1",R1) or ButtonToggle("L1",L1)) then
					filesList.UI:destroy()
					InventoryItemSelected[2] = 1
					if InventoryItems[InventoryItemSelected[2]] then
--						ui.showMessage(tostring(InventoryItems[InventoryItemSelected[2]].recordId))
						Inventory.UI.layout.content.Description.props.text=InventoryItems[InventoryItemSelected[2]].type.record(InventoryItems[InventoryItemSelected[2]]).name
					else
						Inventory.UI.layout.content.Description.props.text=""
					end
					Inventory.UI:update()
					SelectedItem = ui.create( {
						layer = "Console",
						type = ui.TYPE.Image,
						props = {
							visible=true,
							size = util.vector2(ui.screenSize().x / 10, ui.screenSize().y / 9),
							relativePosition = util.vector2(3 / 4, 1 / 3),
							anchor = util.vector2(0, 0),
							resource = ui.texture { path = "textures/SelectedItem.dds" },
						},
					})
	
				end
			end

			
			-------------menu files
			if ContainerUI.layout==nil and ItemChecked["Icon"]==nil and (filesList.documentWindow==nil or filesList.documentWindow.layout==nil)  then
				if (ButtonToggle("R1",R1) or ButtonToggle("L1",L1)) then
					local filesListUIContent=ui.content({})
					for i=1,5 do
						if filesList.Bookmarks[(i-1)*10+1] then
							local Bookmarks=ui.content({})
							for j= 1, 10 do						
								local visible =false
	--							print(filesList.Bookmarks[(i-1)*10+j])
								if filesList.Bookmarks[(i-1)*10+j] and types.Actor.inventory(self):find(filesList.Bookmarks[(i-1)*10+j])~=nil then
									visible=true
								end
								table.insert(Bookmarks,
									
								{type = ui.TYPE.Image,
								props = {
									autoSize = true,
									visible=visible,
									relativeSize = util.vector2(1,1),
									relativePosition = util.vector2(0, ((j-1)/10)),
									anchor = util.vector2(0, 0),
									resource = ui.texture { path =  "textures/bookmark.png" },
									color=util.color.rgb(1, 1, 1)
									},}		
								)
							end


	--						print("book "..i)
							filesListUIContent:add(
									{type = ui.TYPE.Image,
									props = {
										autoSize = true,
										relativeSize = util.vector2(0.3,0.5),
										relativePosition = util.vector2((i-1)/3, 0),--------------------------------/5
										anchor = util.vector2(-0.5, -0.5),
										resource = ui.texture { path =  "textures/files"..i..".png" },
										visible = true,},
										content=Bookmarks,
									})
						end
					end
						
						filesList.UI= ui.create{
							layer = 'HUD',
							type = ui.TYPE.Image,
							props = {
								autoSize = true,
								relativeSize = util.vector2(0.7,0.7),
								relativePosition = util.vector2(0, 0),
								anchor = util.vector2(0, -0.3),
								resource = ui.texture { path =  "textures/no texture.dds" },
							},
							content=filesListUIContent
							
							,}

						filesList.UI.layout.content[1].props.visible=true
						filesList.UI:update()

	--				for i, file in pairs(types.Actor.inventory(self):getAll(types.Book))do
	--					print(types.Book.record(file).name)
	--				end

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

					if ItemChecked.Show then
						ItemChecked["Icon"]:destroy()
						ItemChecked["Icon"]=nil
					end

					filesList.Book=1
					filesList.Bookmark=0
					for i, content in pairs(filesList.UI.layout.content[1].content) do
						if content.props.visible==true then
							filesList.Bookmark=i
							content.props.color=util.color.rgb(0.5, 0.5, 0.5)
							filesList.UI:update()
--							ui.showMessage(filesList.Bookmarks[(filesList.Book-1)*10+filesList.Bookmark])
							Inventory.UI.layout.content.Description.props.text=filesList.Bookmarks[(filesList.Book-1)*10+filesList.Bookmark]
							Inventory.UI:update()
							
							break
						end
					end
				end
				
			end
			


				if Inventory.UI.layout then
					if (core.getRealTime() - Inventory.LifeBar.Timer) > 0.04 then
						HealthPath.path2 = HealthPath.path2 + 1
						Inventory.LifeBar.Timer = core.getRealTime()
						if HealthPath.path2 == 55 then
							HealthPath.path2 = 1
							if types.Actor.activeEffects(self):getEffect("poison") and types.Actor.activeEffects(self):getEffect("poison").magnitude > 0 then
								HealthPath.path1 = 'textures/Lifebar/Poison/'
							elseif (onFrameHealth / types.Actor.stats.dynamic.health(self).base) >= 0.8 then
								HealthPath.path1 = 'textures/Lifebar/Fine/'
							elseif (onFrameHealth / types.Actor.stats.dynamic.health(self).base) <= 0.3 then
								HealthPath.path1 = 'textures/Lifebar/Danger/'
							else
								HealthPath.path1 = 'textures/Lifebar/Caution/'
							end
						end

						HealthPath.path3 = HealthPath.path1 .. HealthPath.path2 .. ".jpg"
						Inventory.UI.layout.content.LifeBar.props.resource= ui.texture { path = HealthPath.path3}
						Inventory.UI:update()
					end
				end



				----------Naviguer dans inventaire
				if InventoryItemSelected[3] == nil and InventoryItemSelected[4] == nil  then
					if InventoryItemSelected[2] and ButtonToggle("Left",TurnLeft(-0.2)) and InventoryItemSelected[2] ~= 1 and SelectedItem.layout.props.visible==true then
						InventoryItemSelected[2] = InventoryItemSelected[2] - 1
						ambient.playSound("Cursor")
						if InventoryItems[InventoryItemSelected[2]] then
--							ui.showMessage(tostring(InventoryItems[InventoryItemSelected[2]].recordId))
							Inventory.UI.layout.content.Description.props.text=InventoryItems[InventoryItemSelected[2]].type.record(InventoryItems[InventoryItemSelected[2]]).name
						else
							Inventory.UI.layout.content.Description.props.text=""
						end
						Inventory.UI:update()
					elseif InventoryItemSelected[2] and ButtonToggle("Right",TurnRight(0.2)) and InventoryItemSelected[3] == nil and InventoryItemSelected[4] == nil and InventoryItemSelected[2] ~= types.NPC.getCapacity(self) and SelectedItem.layout.props.visible==true   then
						InventoryItemSelected[2] = InventoryItemSelected[2] + 1
						ambient.playSound("Cursor")
						if InventoryItems[InventoryItemSelected[2]] then
--							ui.showMessage(tostring(InventoryItems[InventoryItemSelected[2]].recordId))
							Inventory.UI.layout.content.Description.props.text=InventoryItems[InventoryItemSelected[2]].type.record(InventoryItems[InventoryItemSelected[2]]).name
						else
							Inventory.UI.layout.content.Description.props.text=""
						end
						Inventory.UI:update()
					elseif InventoryItemSelected[2] and ButtonToggle("Down",MoveBackward(0.3)) and InventoryItemSelected[3] == nil and InventoryItemSelected[4] == nil then
						if ContainerUI and ContainerUI.layout and ContainerUI.layout.content[2].props.visible==true  then
								ambient.playSound("ContainerCursor")
								ContainerItemSelected=ContainerItemSelected+1
								ContainerUI.layout.content[1].props.relativePosition=ContainerUI.layout.content[1].props.relativePosition+util.vector2(0,-0.095)
								ContainerUI:update()
								--print(types.Container.inventory(Container):getAll()[ContainerItemSelected])
						elseif InventoryItemSelected[2] <= (types.NPC.getCapacity(self) - 2) then
							InventoryItemSelected[2] = InventoryItemSelected[2] + 2
							ambient.playSound("Cursor")
							if InventoryItems[InventoryItemSelected[2]] then
--								ui.showMessage(tostring(InventoryItems[InventoryItemSelected[2]].recordId))
								Inventory.UI.layout.content.Description.props.text=InventoryItems[InventoryItemSelected[2]].type.record(InventoryItems[InventoryItemSelected[2]]).name
							else
								Inventory.UI.layout.content.Description.props.text=""
							end
							Inventory.UI:update()
						end
					elseif InventoryItemSelected[2] and ButtonToggle("Up",MoveForward(-0.3)) and InventoryItemSelected[3] == nil and InventoryItemSelected[4] == nil then
						if ContainerUI and ContainerUI.layout and ContainerUI.layout.content[2].props.visible==true then

								ambient.playSound("ContainerCursor")
								ContainerItemSelected=ContainerItemSelected-1
								ContainerUI.layout.content[1].props.relativePosition=ContainerUI.layout.content[1].props.relativePosition+util.vector2(0,0.095)
								ContainerUI:update()
								--print(types.Container.inventory(Container):getAll()[ContainerItemSelected])
							
						
						elseif  InventoryItemSelected[2] >= 3  then					
							InventoryItemSelected[2] = InventoryItemSelected[2] - 2
							ambient.playSound("Cursor")
							if InventoryItems[InventoryItemSelected[2]] then
--								ui.showMessage(tostring(InventoryItems[InventoryItemSelected[2]].recordId))
								Inventory.UI.layout.content.Description.props.text=InventoryItems[InventoryItemSelected[2]].type.record(InventoryItems[InventoryItemSelected[2]]).name
							else
								Inventory.UI.layout.content.Description.props.text=""
							end
							Inventory.UI:update()
						end
					elseif InventoryItemSelected[2] and ButtonToggle("R1",R1) and ContainerUI and ContainerUI.layout then
						if ContainerUI.layout.content[2].props.visible==true then
							ContainerUI.layout.content[2].props.visible=false
							SelectedItem.layout.props.visible=true
							ContainerUI:update()
							SelectedItem:update()
							ambient.playSound("Cursor")
						end
					elseif InventoryItemSelected[2] and ButtonToggle("L1",L1) and ContainerUI and ContainerUI.layout then
						if ContainerUI.layout.content[2].props.visible==false then
							ContainerUI.layout.content[2].props.visible=true
							SelectedItem.layout.props.visible=false
							ContainerUI:update()
							SelectedItem:update()
							ambient.playSound("Cursor")
						end
					elseif InventoryItemSelected[2] and InventoryItemSelected[3] == nil and ButtonToggle("Cross",Cross) then
						if ContainerUI and ContainerUI.layout then
							--print(types.Container.inventory(Container):getAll()[ContainerItemSelected])
							if ContainerUI.layout.content[2].props.visible==true then
								if types.Container.inventory(Container):getAll()[ContainerItemSelected] and CheckOverload(self)==false  then
									ambient.playSound("REdecide")
									core.sendGlobalEvent('MoveInto', {
										Item = types.Container.inventory(Container):getAll()[ContainerItemSelected],
										container = nil,
										actor = self,
										newItem =nil
									})
									core.sendGlobalEvent('Container', {container=Container, player=self,action="in/out"})	
								else
									ui.showMessage("Inventory full")
									ambient.playSound("decidewrong")
									
								end
							elseif InventoryItems[InventoryItemSelected[2]] then
								ambient.playSound("REdecide")
								core.sendGlobalEvent('MoveInto', {
									Item = InventoryItems[InventoryItemSelected[2]],
									container = Container,
									actor = nil,
									newItem =nil
								})
								core.sendGlobalEvent('Container', {container=Container, player=self,action="in/out"})	
							end			
						elseif InventoryItems[InventoryItemSelected[2]] then
							InventoryItemSelected[3] = 1
							
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
					end
				end
				if InventoryItemSelected[2] and SelectedItem then
					SelectedItem.layout.props.relativePosition = util.vector2(
						3 / 4 + 1 / 10 - (InventoryItemSelected[2] % 2) * 1 /
						10, 1 / 3 + (InventoryItemSelected[2] + InventoryItemSelected[2] % 2) / 2 * 1 / 9 - 1 / 9)
					SelectedItem:update()
				end





				-----------------Naviguer dans inventaire de combine
				if InventoryItemSelected[4] and ButtonToggle("Left",TurnLeft(-0.2)) and InventoryItemSelected[4] ~= 1 then
					InventoryItemSelected[4] = InventoryItemSelected[4] - 1
					ambient.playSound("Cursor")
					if InventoryItems[InventoryItemSelected[4]] then
--						ui.showMessage(InventoryItems[InventoryItemSelected[4]].recordId)
					end
				elseif InventoryItemSelected[4] and ButtonToggle("Right",TurnRight(0.2)) and InventoryItemSelected[4] ~= types.NPC.getCapacity(self) then
					InventoryItemSelected[4] = InventoryItemSelected[4] + 1
					ambient.playSound("Cursor")
					if InventoryItems[InventoryItemSelected[4]] then
--						ui.showMessage(InventoryItems[InventoryItemSelected[4]].recordId)
					end
				elseif InventoryItemSelected[4] and ButtonToggle("Down",MoveBackward(0.3)) and InventoryItemSelected[4] <= (types.NPC.getCapacity(self) - 2) then
					InventoryItemSelected[4] = InventoryItemSelected[4] + 2
					ambient.playSound("Cursor")
					if InventoryItems[InventoryItemSelected[4]] then
--						ui.showMessage(InventoryItems[InventoryItemSelected[4]].recordId)
					end
				elseif InventoryItemSelected[4] and ButtonToggle("Up",MoveForward(-0.3)) and InventoryItemSelected[4] >= 3 then
					InventoryItemSelected[4] = InventoryItemSelected[4] - 2
					ambient.playSound("Cursor")
					if InventoryItems[InventoryItemSelected[4]] then
--						ui.showMessage(InventoryItems[InventoryItemSelected[4]].recordId)
					end
				elseif InventoryItemSelected[4] and ButtonToggle("Cross",Cross) and InventoryItems[InventoryItemSelected[2]] ~= InventoryItems[InventoryItemSelected[4]] then
					local item1 = InventoryItems[InventoryItemSelected[2]]
					local item2 = InventoryItems[InventoryItemSelected[4]]
					local itemscombined = false
--					if item1.type == types.Weapon and item2.type == types.Weapon then
						if item1.type == types.Weapon and item2.type == types.Weapon and ((types.Weapon.record(item1).type == 10 and types.Weapon.record(item2).type == 13) or (types.Weapon.record(item1).type == 13 and types.Weapon.record(item2).type == 10) or (types.Weapon.record(item1).type == 12 and types.Weapon.record(item2).type == 9) or (types.Weapon.record(item1).type == 9 and types.Weapon.record(item2).type == 12)) then
							--print("RELOAD/LOAD WEAPON")


							if types.Weapon.record(item1).type == 10 or types.Weapon.record(item1).type == 9 then
								InventoryReload(item1, item2)
							elseif types.Weapon.record(item2).type == 10 or types.Weapon.record(item2).type == 9 then
								InventoryReload(item2, item1)
							end
--						end
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
									if item[7] then
										for i = 1, tonumber(item[8]) do
											core.sendGlobalEvent('MoveInto', {
												Item = nil,
												container = nil,
												actor = self,
												newItem =
													item[7]
											})
										end
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
									if item[7] then
										for i = 1, tonumber(item[8]) do
											core.sendGlobalEvent('MoveInto', {
												Item = nil,
												container = nil,
												actor = self,
												newItem =
													item[7]
											})
										end
									end
									core.sendGlobalEvent('RemoveItem', { Item = item1, number = tonumber(item[4]) })
									core.sendGlobalEvent('RemoveItem', { Item = item2, number = tonumber(item[2]) })
									itemscombined = true
								end
							end
						end
						InventoryItemSelected[4] = nil
						SelectedCombineItem:destroy()
						FrameRefresh = true
					end
				end

				if InventoryItemSelected[4] and SelectedItem.layout then
					SelectedCombineItemLayout.props.relativePosition = util.vector2(3 / 4 + 1 / 10 -
						(InventoryItemSelected[4] % 2) * 1 / 10,
						1 / 3 + (InventoryItemSelected[4] + InventoryItemSelected[4] % 2) /
						2 * 1 / 9 - 1 / 9)
					SelectedCombineItem:update()
				end





				-----------------Naviguer dans sub Menu inventaire
				if InventoryItemSelected[3] and InventoryItemSelected[4] == nil then
					if ButtonToggle("Up",MoveForward(-0.3)) and InventoryItemSelected[3] >= 3 and ItemChecked["Icon"]==nil then
						ambient.playSound("Cursor")
						SubInventoryTexts.content[InventoryItemSelected[3]].props.textColor = util.color.rgb(1, 1, 1)
						SubInventory:update()
						InventoryItemSelected[3] = InventoryItemSelected[3] - 2
						SubInventoryTexts.content[InventoryItemSelected[3]].props.textColor = util.color.rgb(0.5, 0.5, 0.5)
						SubInventory:update()
					elseif ButtonToggle("Down",MoveBackward(0.3)) and ((InventoryItemSelected[3] <= 5 and storage.playerSection('RESettings1'):get('Drop')==true) or (InventoryItemSelected[3] <= 3 and storage.playerSection('RESettings1'):get('Drop')==false)) and  ItemChecked["Icon"]==nil then
						ambient.playSound("Cursor")
						SubInventoryTexts.content[InventoryItemSelected[3]].props.textColor = util.color.rgb(1, 1, 1)
						SubInventory:update()
						InventoryItemSelected[3] = InventoryItemSelected[3] + 2
						SubInventoryTexts.content[InventoryItemSelected[3]].props.textColor = util.color.rgb(0.5, 0.5, 0.5)
						SubInventory:update()
					elseif FrameRefresh == true and Framewait(3) then
						FrameRefresh = false
						--doOnceMenu = 0
						if ItemChecked["Icon"] then
							ItemChecked["Icon"]:destroy()
							ItemChecked["Icon"]=nil
							--print("destroy 2")
						end
						if SubInventory then
							SubInventory:destroy()
						end
						InventoryItemSelected[2] = 1
						InventoryItemSelected[3] = nil
						InventoryItems = ShowInventory()

					elseif ButtonToggle("Cross",Cross) and FrameRefresh == false then ---------- EQUIP
						if InventoryItemSelected[3] == 1 and InventoryItems[InventoryItemSelected[2]].type~=types.Lockpick and InventoryItems[InventoryItemSelected[2]].type~=types.Probe then
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
							if ItemChecked["Icon"] then
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

							if ItemChecked["Icon"] == nil then
								if ItemDescriptions[InventoryItems[InventoryItemSelected[2]].type.record(InventoryItems[InventoryItemSelected[2]]).name] then
									ShowItem(InventoryItems[InventoryItemSelected[2]],ItemDescriptions[InventoryItems[InventoryItemSelected[2]].type.record(InventoryItems[InventoryItemSelected[2]]).name])
								else
									ShowItem(InventoryItems[InventoryItemSelected[2]],tostring(InventoryItems[InventoryItemSelected[2]]))
								end
								SubInventory:destroy()
							end

							
						elseif InventoryItemSelected[3] == 5 then ---------- COMBINE
							SelectedCombineItemLayout = {
								layer = 'Console',
								type = ui.TYPE.Image,
								props = {
									visible=true,
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
					end
					--print(InventoryItemSelected[3])
				end

				--print(InventoryItemSelected[2])
				--print(InventoryItems[InventoryItemSelected[2]])

		end



		if I.UI.getMode() or (LiveSelect.UI and LiveSelect.UI.layout) then
			if MoveBackward(0.2) == false and MoveForward(-0.2) == false and TurnLeft(-0.2) == false and TurnRight(0.2) == false and MenuSelectStop == true then
				MenuSelectStop = false
			end
		end


		if MapUI then
			if ButtonToggle("L2",L2)==true then
				MapUI:destroy()
				ambient.playSound("RECancel")
				MapUI=nil
				I.UI.removeMode(I.UI.MODE.Interface)
			end
		end
		
		onFrameMaps(DeltaT)
		
--[[		if Inventory then
			if Inventory.UI then
				if ButtonToggle("Circle",Circle) and ContainerUI.layout==nil then
					I.UI.removeMode(I.UI.MODE.Interface)
					ambient.playSound("RECancel")
					Inventory.UI:destroy()
					if SelectedItem then
						SelectedItem:destroy()
					end
					--if  ItemChecked["Icon"] then
					--	ItemChecked["Icon"]:destroy()
					--	core.sendGlobalEvent('RemoveItem', { Item = ItemChecked["Object"], number = 1})
					--	ItemChecked["Icon"]=nil
					--	ItemChecked["Object"]=nil
					--	print("destroy 3")
					--end
					if InventoryItemSelected[3] then
						SubInventory:destroy()
						if InventoryItemSelected[4] then
							SelectedCombineItem:destroy()
						end
					end
			
					InventoryItemSelected[2] = nil
					InventoryItemSelected[3] = nil
					InventoryItemSelected[4] = nil
				end
			end
		end
--]]




		ButtonToggle("R1",R1)
		ButtonToggle("R2",R2)
		ButtonToggle("L1",L1)
		ButtonToggle("L2",L2)
		ButtonToggle("Up",MoveForward(-0.3))
		ButtonToggle("Down",MoveBackward(0.3))
		ButtonToggle("Left",TurnLeft(-0.2))
		ButtonToggle("Right",TurnRight(0.2))
		ButtonToggle("Cross",Cross)
		ButtonToggle("Square",Square)
		ButtonToggle("Circle",Circle)
	
		
	end












	if camera.getMode()==camera.MODE.Static and CamData.Cutscene==false and (ROOMS[self.cell.name]==nil or((storage.playerSection('RESettings1'):get('FixedCamera')=="No for all Rooms") or (storage.playerSection('RESettings1'):get('FixedCamera')=="No for 3D Rooms" and ROOMS[self.cell.name] and ROOMS[self.cell.name][CamData.activecam].bgd.idname=="" ))) and self.cell.name~="DoorStransition" then
		camera.setMode(camera.MODE.FirstPerson)
		print("FPS")
		print(ROOMS[self.cell.name])
	elseif ROOMS[self.cell.name] and camera.getMode()~=camera.MODE.Static and (CamData.Cutscene==true or storage.playerSection('RESettings1'):get('FixedCamera')=="Yes" or (storage.playerSection('RESettings1'):get('FixedCamera')=="No for 3D Rooms" and ROOMS[self.cell.name][CamData.activecam].bgd.idname~="")) then
		print("Camerapos")
		--camera.setMode(camera.MODE.Static)
		self:sendEvent('CameraPos', {source=self, BGDepth=BGDepth,CamPos=CamData.CamPos, CamAng=CamData.CamAng, ActiveCam=CamData.activecam,ActiveBkg=CamData.activeBkg,MSKList=MSKlist})
	end 


	if storage.playerSection('RESettings1'):get('PSXShader')==true and psxshader:isEnabled()==false then
		psxshader:enable()
	elseif storage.playerSection('RESettings1'):get('PSXShader')==false and psxshader:isEnabled()==true then
		psxshader:disable()
	end



	

	PlaceCamera.PositionnningCamera(util,input,camera,core,CamData.BGDepth,CamData.activecam,CamData.activeBkg,MSKlist,TurnLeft,TurnRight,MoveForward,MoveBackward,SwitchZonePoints)


	---- picking item 2/2
	if PickUpItem[3] == true and PickUpItem[4] ~= true and Cross then
		ShowInventory()
		InventoryItemSelected[2] = nil
		PickUpItem[4] = true
	end
	if PickUpItem[4] == true and PickUpItem[5] ~= true and Cross == false then
		PickUpItem[5] = true
	end
	if PickUpItem[2] == true and PickUpItem[5] == true and PickUpItem[6] ~= true and Cross == true then
		ShowInventory()
		InventoryItemSelected[2] = nil
		PickUpItem[6] = true
	end
	if PickUpItem[6] == true and PickUpItem[7] ~= true and Cross == false then
		PickUpItem[7] = true
	end
	if (PickUpItem[7] == true or (PickUpItem[2] == false and PickUpItem[5] == true)) and Cross == true and ItemChecked["Icon"] and ItemChecked["Icon"].layout then
		Inventory.UI:destroy()
		ItemChecked["Icon"]:destroy()
		ItemChecked["Icon"]=nil
		PickUpItem = {}
		I.UI.removeMode(I.UI.MODE.Interface)
		--print("destroy 1")
	end








	if I.UI.getMode() == nil then 

			if MessageBoxUI.UI and MessageBoxUI.UI.layout then				
				if ModeNilTempo==2 then
					ModeNilTempo=0
					MessageBoxUI.UI:destroy()			
				else
					ModeNilTempo=ModeNilTempo+1
				end	
			end

			if ElectricalPanelPuzzleUI.UI and ElectricalPanelPuzzleUI.UI.layout then
				if ModeNilTempo==2 then
					print("destroy electrical pannel")
					ModeNilTempo=0
					ElectricalPanelPuzzleUI.UI:destroy()
					ambient.playSound("RECancel")
					core.sendGlobalEvent("ReturnLocalScriptVariable",
						{ value = 0, Player = self, Variable = "electricalpanelpuzzle",GameObject=ElectricalPanelPuzzleUI.Object })
						
					ElectricalPanelPuzzleUI={}
					
				else
					ModeNilTempo=ModeNilTempo+1
				end
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
				MenuSelection={}
				ambient.playSound("RECancel")
			end



			
			if Inventory and Inventory.UI  and Inventory.UI.layout then
				if PickUpItem[5] then
					PickUpItem = {}
				end
				if ModeNilTempo==2 then
					ModeNilTempo=0
						print("destroy inventory")
						ambient.playSound("RECancel")
						Inventory.UI:destroy()
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

						if ItemChecked.Show.Object then
							ItemChecked["Icon"]:destroy()
							ItemChecked["Icon"]=nil
						end
						Inventory={}
				else
					ModeNilTempo=ModeNilTempo+1
				end
			end




			if CrowbarPuzzleUI.UI and CrowbarPuzzleUI.UI.layout then
				if ModeNilTempo==2 then
					ModeNilTempo=0
					print("destroy crowbar hors menu")
					CrowbarPuzzleUI.UI:destroy()
					ambient.playSound("RECancel")
				else
					ModeNilTempo=ModeNilTempo+1
				end
			end


	--[[
			print(ContainerUI)
			print()
			if ContainerUI and ContainerUI.layout then
				print("there")
				ContainerUI:destroy()
				ContainerUI={}
				ambient.playSound("RECancel")
			end
	]]--
			if Lockpicking then
				if Lockpicking.State==0 then
					Lockpicking.State=1
				else
					print("delete lockpicking")
					Lockpicking.UI:destroy()
					core.sendGlobalEvent('RemoveItem', { Item = Lockpicking.Object.Fixe, number = 1 })
					core.sendGlobalEvent('RemoveItem', { Item = Lockpicking.Object.Rot, number = 1 })
					core.sendGlobalEvent('RemoveItem', { Item = Lockpicking.Object.LockPick, number = 1 })
					core.sendGlobalEvent('RemoveItem', { Item = Lockpicking.Object.Light, number = 1 })
					Lockpicking=nil
				end
			end
			--if ShowItemIcon and ShowItemIcon.layout then
			--	ShowItemIcon:destroy()
			--end

	elseif ModeNilTempo>0 then
		ModeNilTempo=0

	end

 


	-------------Equiper une arme       		
	if types.Actor.getEquipment(self, 16) and (types.Weapon.record(types.Actor.getEquipment(self, 16)).type == 10 or types.Weapon.record(types.Actor.getEquipment(self, 16)).type == 9 ) and types.Actor.getEquipment(self, 16) ~= EquippedWeapon then ---define ammo an auto equip basic ammos
		EquippedWeapon = types.Actor.getEquipment(self, 16)
		AmmunitionTypes = {}
		ammoscharged = false
		AmmoChecked = 0
		--print(types.Actor.getEquipment(self, 16).recordId)
		--print(AmmoUsage[types.Actor.getEquipment(self, 16).recordId][2])
		AmmunitionTypes=AmmoUsage[types.Actor.getEquipment(self, 16).recordId][2]
		--print("send")
		weaponcondition = types.Item.itemData(types.Actor.getEquipment(self, 16)).condition
	end




	onFrameLiveSelectionUI()
	DeltaT=core.getRealTime()
	--print(input.isActionPressed(input.ACTION.Use))

end


input.registerTriggerHandler("NextWeapon", async:callback(function ()
	local ActualWeapon=types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
	local Weapons=types.Actor.inventory(self.object):getAll(types.Weapon)
	local Bolt=types.Weapon.TYPE.Bolt
	local Arrow=types.Weapon.TYPE.Arrow
	if self.stance==0 then
		for i, weapon in pairs(Weapons) do
			if weapon==ActualWeapon then
				for j, weapon2 in pairs(Weapons) do
					if j>i and types.Weapon.record(weapon2).type~=Bolt and types.Weapon.record(weapon2).type~=Arrow then
						types.Actor.setEquipment(self, { [types.Actor.EQUIPMENT_SLOT.CarriedRight] = weapon2 })
						break
					end
					if ActualWeapon==types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight) then
						for j, weapon2 in pairs(Weapons) do
							if types.Weapon.record(weapon2).type~=Bolt and types.Weapon.record(weapon2).type~=Arrow then
								types.Actor.setEquipment(self, { [types.Actor.EQUIPMENT_SLOT.CarriedRight] = weapon2 })
								break
							end
						end
					end
				end
				break
			end
		end
	end
end))


input.registerTriggerHandler("Triangle", async:callback(function ()
	print("triangle")
	--if I.UI.getMode() then
		I.UI.removeMode(I.UI.MODE.Interface)
		PickUpItem = {}
		if Inventory and Inventory.UI and Inventory.UI.layout then
				ambient.playSound("RECancel")
				Inventory.UI:destroy()
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
				if ItemChecked.Show.Object then
					ItemChecked["Icon"]:destroy()
					ItemChecked["Icon"]=nil
				end

		end

		
		if filesList.UI.layout then
			filesList.UI:destroy()
			ambient.playSound("RECancel")
		end
		if filesList.documentWindow and filesList.documentWindow.layout then
			filesList.documentWindow:destroy()
			ambient.playSound("RECancel")
		end
		if CrowbarPuzzleUI.UI and CrowbarPuzzleUI.UI.layout then
			CrowbarPuzzleUI.UI:destroy()
			ambient.playSound("RECancel")
		end
		if ElectricalPanelPuzzleUI.UI and ElectricalPanelPuzzleUI.UI.layout then
			ElectricalPanelPuzzleUI.UI:destroy()
			ambient.playSound("RECancel")
			core.sendGlobalEvent("ReturnLocalScriptVariable",
				{ value = 0, Player = self, Variable = "electricalpanelpuzzle",GameObject=ElectricalPanelPuzzleUI.Object })
				
			ElectricalPanelPuzzleUI={}
			
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
			MenuSelection={}
			ambient.playSound("RECancel")
		end


		if ContainerUI and ContainerUI.layout then
			--print("there")
			ContainerUI:destroy()
			ContainerUI={}
			ambient.playSound("RECancel")
		end

		if Lockpicking then

				print("delete lockpicking")
				Lockpicking.UI:destroy()
				core.sendGlobalEvent('RemoveItem', { Item = Lockpicking.Object.Fixe, number = 1 })
				core.sendGlobalEvent('RemoveItem', { Item = Lockpicking.Object.Rot, number = 1 })
				core.sendGlobalEvent('RemoveItem', { Item = Lockpicking.Object.LockPick, number = 1 })
				core.sendGlobalEvent('RemoveItem', { Item = Lockpicking.Object.Light, number = 1 })
				Lockpicking=nil

		end
	--end
end))


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
	eventHandlers = {MessageBox=MessageBox, Cutscene=Cutscene, CrowbarPuzzle=CrowbarPuzzle,ActiveContainer=ActiveContainer,LockPicking=LockPicking,ReturnCheckedObject=ReturnCheckedObject, ChoicesSelection=ChoicesSelection,DefineSwitchZones=DefineSwitchZones,ReturnObjectsInWorld=ReturnObjectsInWorld, SavingMenu=SavingMenu, ElectricalPanelPuzzle=ElectricalPanelPuzzle, LiveSelection = LiveSelection, CameraPos = Camerapos, ReturnEquippedWeaponInfos = ReturnEquippedWeaponInfos, ReturnInventoryWeaponInfos = ReturnInventoryWeaponInfos,},
	engineHandlers = {
		onSave=onSave,
		onLoad=onLoad,
		onFrame=onFrame,
		onUpdate=onUpdate

	}
}
