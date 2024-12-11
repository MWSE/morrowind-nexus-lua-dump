local animation = require("openmw.animation")
local self = require("openmw.self")
local types = require("openmw.types")
local time = require("openmw_aux.time")
local input = require("openmw.input")
local async = require("openmw.async")
local core = require("openmw.core")
local util = require("openmw.util")
local camera = require("openmw.camera")
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local l10n = core.l10n("DynamicActors")

local Actor, ST, MD = types.Actor, types.Actor.STANCE, camera.MODE
local ctrls, stance = self.controls, types.Actor.getStance(self)


I.Settings.registerPage {
   key = "dynamicactors",
   l10n = "DynamicActors",
   name = "settings_modName",
   description = "settings_modDesc",
}

I.Settings.registerGroup({
   key = "Settings_dynactors_player",
   page = "dynamicactors",
   l10n = "DynamicActors",
   name = "settings_modCategory1_name",
   permanentStorage = true,
   settings = {
	{key = "dialog_disableHud",
	default = true,
	renderer = "checkbox",
	name = "settings_modCategory1_setting11_name",
	},
	{key = "dialog_1stperson",
	default = false,
	renderer = "checkbox",
	name = "settings_modCategory1_setting01_name",
	},
	{key = "dialog_1st_zoom",
	default = false,
	renderer = "checkbox",
	name = "settings_modCategory1_setting02_name",
	},
	{key = "dialog_1st_zoomdist",
	default = 70,
	renderer = "number",
	name = "settings_modCategory1_setting03_name",
	argument = { min = 40, max = 300 },
	},
	{key = "dialog_1st_zoom_speed",
	default = 50,
	renderer = "number",
	name = "settings_modCategory1_setting04_name",
	argument = { min = 10, max = 200 },
	},
	{key = "dialog_1st_zoom_offset",
	default = 0,
	renderer = "number",
	name = "settings_modCategory1_setting05_name",
	argument = { min = -90, max = 90 },
	},
	{key = "actionHotkey",
	default = input.KEY.P,
	renderer = "inputKeyBox",
	name = "settings_modCategory1_setting06_name",
	description = "settings_modCategory1_setting06_desc",
	},
        {key = "baseIdleAnim_main",
	name = "settings_modCategory1_setting07_name",
	description = "settings_modCategory1_setting07_desc",
	default = "Ready Pose",
	renderer = "select",
	argument = {
		disabled = false,
		l10n = "LocalizationContext", 
		items = { "None", "Ready Pose", "Hand on Hip contrapose", "Idle2" },
		},
	},
        {key = "baseIdleAnim_upper",
	name = "settings_modCategory1_setting08_name",
	description = "settings_modCategory1_setting08_desc",
	default = "Arms Folded",
	renderer = "select",
	argument = {
		disabled = false,
		l10n = "LocalizationContext", 
		items = { "None", "Arms Folded", "Arms Back Clasp", "Ready Pose" },
		},
	},
	{key = "rndIdleAnim",
	default = true,
	renderer = "checkbox",
	name = "settings_modCategory1_setting09_name",
	},
	{key = "autoHelm",
	default = true,
	renderer = "checkbox",
	name = "settings_modCategory1_setting10_name",
	},
	{key = "autoHelmItemID",
	default = nil,
	renderer = "hiddenKey",
	name = "",
	},
   },
})

local settingsplayer = storage.playerSection("Settings_dynactors_player")
local settings = storage.globalSection("Settings_dynamicactors")

local dialogModes = {
	Barter = true,
	Companion = true,
	Dialogue = true,
	Enchanting = true,
	MerchantRepair = true,
	Travel = true,
	Training = true,
	SpellBuying = true,
	SpellCreation = true,
	Persuasion = true,
}

local dialogHudModes = {
	["Alchemy"] = true,
	["Barter"] = true,
	["Container"] = true,
	["Companion"] = true,
	["Enchanting"] = true,
	["MerchantRepair"] = true,
	["Recharge"] = true,
	["Repair"] = true,
	["SpellBuying"] = true,
	["SpellCreation"] = true
}

local moved, idlenum, counter = true, 0, 0
local openDialog = false
local animPlaying = false

local anims = {}

anims.items = { "None", "Hand on Hip contrapose", "Ready Pose", "Idle2", "Arms Folded",
	"Arms Back Clasp" }
anims.settings = {}
for i=1, #anims.items do anims.settings[anims.items[i]] = i end

anims.idle = {
	base = { {id="none", speed=1},
		{id="handhippose", speed=0.5},
		{id="readypose", speed=1},
		{id="idle2", speed=0.5},
		{id="armsfolded", speed=0.5},
		{id="armsatback", speed=0.5},
	},
	rnd = {
{ {id="armsakimbo", opt={loops=2, speed=1}}, {id="idle4", opt={speed=2}} },
{ {id="armsfolded", opt={loops=2, speed=1}}, {id="idle8", opt={loops=1, speed=2}} }
		}
	}

anims.combo = { ["armsFoldPose"] = { "handhippose", {mask=3}, "armsfolded", {mask=14, spd=1} },
	["armsStrPose"] = { "handhippose", {mask=3} },
	["armsOneBackPose"] = { "handhippose", {mask=3}, "armsatback", {mask=8, spd=1} },
	["armsBackClaspPose"] = { "handhippose", {mask=3}, "armsatback", {mask=12, spd=1} }
	}

anims.clear = { "handhippose", "readypose", "idle2", "armsfolded", "armsfolded", "armsakimbo", "armsatback" }

anims.fixed = require("scripts.DynamicActors.playlist")


local heights = {

	byAnim = {

	["am_beggar.nif"] = { 35, keys={"idle2", "idle3", "idle4", "idle"} },
	["am_dreamera.nif"] = { 45, keys={"idle2", "idle"} },
	["am_dreamerb.nif"] = { 45, keys={"idle6", "idle"} },
	["am_drummer03.nif"] = { 45, keys={"idle2", "idle"} },
	["am_eater.nif"] = { 45, keys={"idle2"} },
	["am_fishman.nif"] = { 45, keys={"idle2", "idle3", "idle"} },
	["am_luteplaying.nif"] = { 45, keys={"idle2", "idle"} },
	["am_reader2.nif"] = { 45, keys={"idle2", "idle3", "idle4"} },
	["am_sitting.nif"] = { 45, keys={"idle2", "idle3", "idle4"} },
	["am_writer02.nif"] = { 45, keys={"idle2", "idle3", "idle4"} },

	["am_sitbar.nif"] = { 45, keys={"idle8", "idle9"} },
	["bandit.nif"] = { 45, keys={"idle8"} },
	["farmer.nif"] = { 45, keys={"idle8"} },
	["farmer2.nif"] = {45, keys={"idle9"} },
	["prayerdf.nif"] = {45, keys={"idle9"} },
	["prayerdm.nif"] = {45, keys={"idle9"} },
	["slavesitting.nif"] = { 35, keys={"idle9"} },

	["va_sitting.nif"] = { 45, keys={"idle2", "idle3", "idle4", "idle5", "idle6", "idle7", "idle8", "idle9"} },
	["va_sittingdunmertest.nif"] = { 45, keys={"idle2"} },

	["anim_sitpleading.nif"] = { 45, keys={"idle9"} },
	["anim_sitthreatening.nif"] = { 45, keys={"idle9"} },

--	["meshes/luce/am/am_luteplaying.nif"] = { }

		},

	byModel = { {id="guar.nif", height=120, scale=0.3}, {id="^guar_", height=120, scale=0.3} }

	}

local npcSettings = require("scripts.DynamicActors.playerCam")
local actionKey = nil
local currentanim = 1
local varFixed = {save=1, choose=false, count=0}
-- local savedanim = 1
local dialogTarget = nil
-- local turningToTarget = false
local dialogCam = {controls=false, block=false, instant=false, auto1st=false,
	height=100, interval=2, counter=0, adjust=true, pos=nil}
local offset3rd = camera.getFocalPreferredOffset()
local zoom1st = {enabled=false, dist=70, speed=1, offset=0, force=false, level=0, vector=nil}
local camsave = {mode=camera.getMode(), offset=nil, offset1st=nil, offset3rd=offset3rd, extrayaw=0}
local logging = false


local function updateSettingsPlayer()
	dialogCam.auto1st = settingsplayer:get("dialog_1stperson")
	zoom1st.enabled = settingsplayer:get("dialog_1st_zoom")
	I.Settings.updateRendererArgument("Settings_dynactors_player", "dialog_1st_zoomdist", {disabled = not zoom1st.enabled})
	zoom1st.dist = settingsplayer:get("dialog_1st_zoomdist")
	actionKey = settingsplayer:get("actionHotkey")
end

local function updateSettings()
	for m in pairs(dialogModes) do
		I.UI.setPauseOnMode(m, not settings:get("unpause_dialog"))
	end
	I.UI.setPauseOnMode("Dialogue", true)
	logging = settings:get("debuglog")
end

updateSettings()
updateSettingsPlayer()
settings:subscribe(async:callback(updateSettings))
settingsplayer:subscribe(async:callback(updateSettingsPlayer))

local headslot
if settingsplayer:get("autoHelmItemID") then
	headslot = types.Actor.inventory(self):find(settingsplayer:get("autoHelmItemID"))
end

local oldVfsApi = true
if types.Static.records["ex_de_oar"].model:find("/") then oldVfsApi = false	end


local function animHandler(a, g, o)
	local combo = anims.combo[g]
	local play = true
	if g == "none" then return true end
	if a == "isplay" and not combo then
		return animation.isPlaying(self, g)
	end
	if not combo then
		if a == "play" then animation.playBlended(self, g, o)
		else animation.cancel(self, g) end
		return
	end
	if a == "isplay" then
		if g == "armsFoldPose" and not animation.isPlaying(self, "armsfolded") then play = false end
		if ( g == "armsBackClaspPose" or g == "armsOneBackPose" )
			and not animation.isPlaying(self, "armsatback") then play = false end
		if not animation.isPlaying(self, combo[1]) then play = false end
		return play
	end
	if a == "cancel" then
		animation.cancel(self, "armsfolded")
		animation.cancel(self, "armsatback")
		animation.cancel(self, combo[1])
		return
	end
	local options = {}
	for k, v in pairs(o) do options[k] = v end
	if o.speed == nil then o.speed = 1 end
	if g == "armsFoldPose" then
--		o.speed = o.speed * 0.5
		o.blendMask = 12
	elseif g == "armsBackClaspPose" then
--		o.speed = o.speed * 0.25
		o.blendMask = 12
	elseif g == "armsOneBackPose" then
--		o.speed = o.speed * 0.25
		o.blendMask = 8
	end
	options.blendMask = combo[2].mask or options.blendMask
	o.priority = o.priority + 1
	animation.playBlended(self, combo[1], options)
	if g == "armsFoldPose" then animation.playBlended(self, "armsfolded", o) end
	if g == "armsBackClaspPose" or g == "armsOneBackPose" then animation.playBlended(self, "armsatback", o) end
end

local function getActorHeight(o)
	if o.type == types.NPC or o.type == types.Player then
		local gender = "female"
		local npc = types.NPC.record(o)
		if npc.isMale then gender = "male" end
		return types.NPC.races.record(npc.race).height[gender] * o.scale * 128
	else
--		return (o:getBoundingBox().halfSize.z) * o.scale
		return 128 * o.scale
	end
end

local function onDialogOpened(data)
	camsave.offset1st = camera.getFirstPersonOffset()
	camsave.dist3rd = camera.getThirdPersonDistance()
	camsave.hud = I.UI.isHudVisible()
	zoom1st.level, zoom1st.scale, zoom1st.force = 0, 1, false
	zoom1st.speed = settingsplayer:get("dialog_1st_zoom_speed") / 100
	zoom1st.offset = math.rad(settingsplayer:get("dialog_1st_zoom_offset"))
	camsave.yaw, camsave.pitch, camsave.extrayaw = camera.getYaw(), camera.getPitch(), camera.getExtraYaw()
	local npc = data.arg
	openDialog, dialogTarget, dialogCam.block = true, npc, true
	if not data.near then return end
	if (npc.position - self.position):length() > 2000 then return end
	dialogCam.interval, dialogCam.counter, dialogCam.adjust = 2, 0, true
	dialogCam.pos = npc.position
	dialogCam.height = getActorHeight(npc) * 0.85
	local file = npc.type.record(npc).model or ""

	local i, j
	if oldVfsApi then
		--	OMW versions before Nov 19 2024
		i, j = string.find(file, "\\[^\\]*$")
	else
		--	OMW versions past Nov 19 2024
		i, j = string.find(file, "/[^/]*$")
	end

	if i then
		file = string.sub(file, i+1, j)
	end
	file = file:lower()
	local height = heights.byAnim[file]
	if height and height.keys then
		for _, v in ipairs(height.keys) do 
			if animation.isPlaying(npc, v) then
				dialogCam.height = height[1]
				if logging then print(file, v) end
			end
		end
	elseif height then
		dialogCam.height = height[1] or dialogCam.height
	end
	if types.Creature.objectIsInstance(npc) then
		for _, v in ipairs(heights.byModel) do
			if file:find(v.id) then
		--		print(v.id, v.height, v.scale)
				dialogCam.height = v.height
				if v.scale then zoom1st.scale = v.scale end
			end
		end
	end
	for _, v in ipairs(npcSettings) do
		if string.find(npc.recordId, "^"..v.id) ~= nil then
			if v.height ~= nil then dialogCam.height = v.height end
			if v.camAdjust ~= nil then dialogCam.adjust = v.camAdjust end
			if v.scale then zoom1st.scale = v.scale end
			break
		end
	end
	dialogCam.controls, dialogCam.block, dialogCam.instant = false, false, false
	if settingsplayer:get("dialog_disableHud") and I.UI.isHudVisible() then I.UI.setHudVisibility(false) end
	if not animPlaying then
		camsave.mode, camsave.offset3rd = camera.getMode(), camera.getFocalPreferredOffset()
		if dialogCam.auto1st and settings:get("unpause_dialog") then
			if camera.getMode() ~= MD.FirstPerson then
				camera.setMode(MD.FirstPerson)
				dialogCam.instant = true
			end
		end
	end
end

local function onDialogClosed(data)
	openDialog, dialogTarget  = false, nil
	if camsave.hud ~= I.UI.isHudVisible() then I.UI.setHudVisibility(camsave.hud) end
	if zoom1st.force then camera.setFirstPersonOffset(camsave.offset1st) end
	if camera.getMode() == MD.FirstPerson and zoom1st.offset ~= 0 then
		camera.setExtraYaw(camsave.extrayaw)
	end
	zoom1st.level, zoom1st.force = 0, false
	if not animPlaying then
		camera.setFocalPreferredOffset(camsave.offset3rd)
		if camera.getMode() ~= camsave.mode then
	-- directly switching 1stPerson-->Preview using setMode will glitch
			if camsave.mode == MD.Preview then camsave.mode = MD.ThirdPerson
			elseif camsave.mode == MD.ThirdPerson and camera.getMode() == MD.Preview then
				camera.setPreferredThirdPersonDistance(camsave.dist3rd)
				camera.setYaw(camsave.yaw)
				camera.setPitch(camsave.pitch)
				camera.instantTransition()
			end
			camera.setMode(camsave.mode)
		end
	end
end

local function cancelAnim()
	animHandler("cancel", anims.fixed[currentanim].id)
	camera.setFocalPreferredOffset(camsave.offset3rd)
	if camsave.mode == MD.FirstPerson then
		async:newUnsavableSimulationTimer(0.1, function() camera.setMode(MD.FirstPerson) end)
	else
		camera.setMode(camsave.mode)
	end
	I.Controls.overrideMovementControls(false)
	animPlaying = false
	idlenum = 0
	ui.showMessage(l10n("msg_moveon"))
end


time.runRepeatedly(function()
	if openDialog then
		dialogCam.counter = dialogCam.counter + 2
		if dialogCam.counter >= dialogCam.interval then
			if dialogCam.adjust then dialogCam.pos = dialogTarget.position end
			dialogCam.counter = 0
		end
	end
	if animPlaying and not animHandler("isplay", anims.fixed[currentanim].id) then cancelAnim() end
	if moved then moved = false return end
	if camera.getMode() == MD.FirstPerson or Actor.activeEffects(self):getEffect("levitate").magnitude > 0
		or Actor.isSwimming(self) then counter = 0 return end
	if animPlaying then counter = 0 return end
	if idlenum == 0 then
		idlenum = 1
		counter = 26
	end
	counter = counter + 2
	local legs = anims.idle.base[anims.settings[settingsplayer:get("baseIdleAnim_main")]]
	local top = anims.idle.base[anims.settings[settingsplayer:get("baseIdleAnim_upper")]]
	if counter == 6 and top.id ~= legs.id and animHandler("isplay", top.id) then
		animHandler("cancel", top.id)
	end
	if counter < 32 then
		if counter >5 and counter < 28 then
			if not animHandler("isplay", legs.id) then
				animHandler("play", legs.id, {loops=50, priority=1, speed=legs.speed})
			end
			if not animHandler("isplay", top.id) and top.id ~= legs.id then
				animHandler("play", top.id, {loops=50, priority=2, blendMask=(top.mask or 12), speed=top.speed})
			end
		end
		return
	end
	counter = 0
	if not settingsplayer:get("rndIdleAnim") then return end
	for i=1, #anims.clear do animation.cancel(self, anims.clear[i]) end
	local rnd = anims.idle.rnd[math.random(2)]
	for i=1, idlenum do
		local a, options = rnd[i].id, {}
		for k, v in pairs(rnd[i].opt) do options[k] = v end
		options.priority = i + 2
		animation.playBlended(self, a, options)
	end
	if idlenum == 1 then idlenum = 2 end
end, 2 * time.second)


local function playFixed()
	ui.showMessage(l10n("msg_moveoff"))
	animPlaying = true
	for _, v in ipairs(anims.clear) do animation.cancel(self, v) end
	local offset = anims.fixed[currentanim].offset
	local speed = anims.fixed[currentanim].speed or 1
	if offset then
		offset3rd = util.vector2(camsave.offset3rd.x, offset)
		camera.setFocalPreferredOffset(offset3rd)
	else offset3rd = camsave.offset3rd end
	local options = {loops=200, priority=5, speed=speed}
	if anims.fixed[currentanim].force then options.forceLoop = true end
	animHandler("play", anims.fixed[currentanim].id, options)
end

local function onKeyPress(key)
	if (key.code ~= actionKey) then return end
	if core.isWorldPaused() or moved then return end
	if openDialog then
		if camera.getMode() == MD.ThirdPerson then camera.setMode(MD.Preview) end
		if camera.getMode() == MD.Preview then
			dialogCam.controls = not dialogCam.controls
			if dialogCam.controls then ui.showMessage(l10n("msg_ctrlon"))
			else ui.showMessage(l10n("msg_ctrloff")) end
		end
		return
	end
	if animPlaying then cancelAnim() return end
	if Actor.activeEffects(self):getEffect("levitate").magnitude > 0
		or Actor.isSwimming(self) then return end
	if Actor.getStance(self) ~= ST.Nothing then return end
	camsave.mode, camsave.offset3rd = camera.getMode(), camera.getFocalPreferredOffset()
	I.Controls.overrideMovementControls(true)
	currentanim, varFixed.choose = varFixed.save, false
	for _, v in ipairs(anims.clear) do animation.cancel(self, v) end
	local offset = anims.fixed[currentanim].offset
	local speed = anims.fixed[currentanim].speed or 1
	if anims.fixed[currentanim].turn then
		async:newUnsavableSimulationTimer(0.2, function() core.sendGlobalEvent("objTurn", {object=self, angle=180}) end)
	end
	camera.setMode(MD.Preview)
	async:newUnsavableSimulationTimer(0.5, function() playFixed() end)
end

input.registerTriggerHandler("Jump", async:callback(function()
	if openDialog or not animPlaying then return end
	varFixed.choose = not varFixed.choose
	if varFixed.choose then ui.showMessage(l10n("msg_selecton"))
	else ui.showMessage(l10n("msg_selectoff")) end
end))

local function processControls(dt)
	local yaw, pitch, dist, proc = camera.getYaw(), camera.getPitch(), camera.getThirdPersonDistance(), false
	local movex, movey = input.getMouseMoveX(), input.getMouseMoveY()
	local zoom = input.getNumberActionValue("Zoom3rdPerson")
	camera.showCrosshair(true)
	if openDialog then
		if movex ~= 0 or movey ~= 0 then
			proc = true
			yaw = yaw + 0.5 * movex * dt
			pitch = pitch + 0.5 * movey * dt
		end
		if zoom ~= 0 then
			proc = true
			dist = dist - zoom
		end
	end
	movex = input.getRangeActionValue("MoveForward") - input.getRangeActionValue("MoveBackward")
	movey = input.getRangeActionValue("MoveRight") - input.getRangeActionValue("MoveLeft")
	if varFixed.choose then varFixed.count = varFixed.count - dt end
	if varFixed.choose and movey ~= 0 and varFixed.count < 1 then
		varFixed.count = 1.25
		varFixed.save = varFixed.save + movey
		if varFixed.save > #anims.fixed then varFixed.save = 1 end
		if varFixed.save < 1 then varFixed.save = #anims.fixed end
		ui.showMessage(anims.fixed[varFixed.save].name.." ("..anims.fixed[varFixed.save].id..")")
	end
	if (movex ~= 0 or movey ~= 0) and not varFixed.choose then
		proc = true
		offset3rd = util.vector2(offset3rd.x + 100*movey*dt, offset3rd.y + 100*movex*dt)
	end
	if not proc then return end
	camera.setFocalPreferredOffset(offset3rd)
	camera.setPreferredThirdPersonDistance(dist)
	camera.instantTransition()
	camera.setYaw(yaw)
	camera.setPitch(pitch)
end

local function autoCam(dt)
	-- Force-set 1st person zoom every frame, to counter camera.lua resetting it
	local bezier
	if zoom1st.force then
		bezier = 1 - (zoom1st.level - 1) ^ 6
		camera.setFirstPersonOffset(util.vector3(0, zoom1st.vector.x, zoom1st.vector.y) * bezier)
	end
	if zoom1st.offset ~= 0 then camera.setExtraYaw(zoom1st.offset) end
	ctrls.movement = 0
        ctrls.sideMovement = 0
	local turningToTarget = false

        local deltaPos = dialogCam.pos - self.position
        local destVec = util.vector2(deltaPos.x, deltaPos.y):rotate(camera.getYaw())
        local deltaYaw = math.atan2(destVec.x, destVec.y)
        if math.abs(deltaYaw) > math.rad(10) then
            turningToTarget = true
        end
	bezier = (8 * math.abs(deltaYaw) / math.pi) ^ 2
--	local v = dt * 3.5 * util.clamp(bezier, math.rad(5), 1)
	local v = dt * 3.5 * bezier
	if dialogCam.instant then v = 3.5 end
        if math.abs(deltaYaw) > math.rad(2) then
            ctrls.yawChange = util.clamp(deltaYaw, -v, v)
        end

	local headPos = self.position + util.vector3(0, 0, getActorHeight(self) * 0.974)
	deltaPos = (dialogCam.pos + util.vector3(0, 0, dialogCam.height)) - headPos
	local lengthXY = util.vector2(deltaPos.x, deltaPos.y):length()
	local deltaPitch = - math.atan2(deltaPos.z, lengthXY) - self.rotation:getPitch()
--	local deltaPitch = - math.asin( deltaPos.z / deltaPos:length() ) - self.rotation:getPitch()
        if math.abs(deltaPitch) > math.rad(10) then
            turningToTarget = true
        end
	bezier = (8 * math.abs(deltaPitch) / math.pi) ^ 2
	if dialogCam.instant then dialogCam.instant = false else v = dt * 3.5 * bezier end
        if math.abs(deltaPitch) > math.rad(2) then
            ctrls.pitchChange = util.clamp(deltaPitch, -v, v)
        end
	if turningToTarget or (not zoom1st.enabled) then return end

	local distance = deltaPos:length() * zoom1st.scale
	destVec = util.vector2(lengthXY, deltaPos.z) * util.clamp((distance - zoom1st.dist), -5, 2000) / distance
	if not zoom1st.force then
		zoom1st.force = true
		zoom1st.vector = destVec
	end
	if (destVec - zoom1st.vector):length() > 5 then zoom1st.vector = destVec end
	if zoom1st.level == 1 then return end
	if zoom1st.level < 1 then zoom1st.level = zoom1st.level + (dt * zoom1st.speed) end	
	if zoom1st.level > 1 then zoom1st.level = 1 end
end

local function procStanceChange(force)
	if not settingsplayer:get("autoHelm") then return end
	local equip, h = Actor.getEquipment(self), Actor.EQUIPMENT_SLOT.Helmet
	if force and headslot then
		equip[h] = headslot
		Actor.setEquipment(self, equip)
		return
	end
	if Actor.getStance(self) == ST.Nothing then
			headslot = equip[h]
			local stored, id = settingsplayer:get("autoHelmItemID")
			if headslot then id = headslot.recordId		end
			if id and stored ~= id then settingsplayer:set("autoHelmItemID", id)	end
			equip[h] = nil
	elseif equip[h] == nil and headslot then
		equip[h] = headslot
	end
	Actor.setEquipment(self, equip)
	stance = Actor.getStance(self)
end

local function processCamera(dt)
	if core.isWorldPaused() then return end
	if animPlaying and not openDialog then processControls(dt) end
	if dialogCam.block or not openDialog then return end
	if camera.getMode() == MD.FirstPerson then autoCam(dt) end
	if camera.getMode() == MD.Preview and dialogCam.controls then processControls(dt) end
end

local function onUpdate(dt)
	if stance ~= Actor.getStance(self) then procStanceChange() end
	if openDialog or animPlaying then processCamera(dt) end
	if moved then moved = false return end
	if ctrls.movement ~= 0 or ctrls.sideMovement ~= 0 then moved=true end
	if ctrls.yawChange ~= 0 and animPlaying then moved=true end
	if ctrls.jump or ctrls.sneak then moved=true end
	if Actor.getStance(self) ~= ST.Nothing then moved=true end
	if not moved then return end
	if idlenum > 0 then
		for _, v in ipairs(anims.clear) do animation.cancel(self, v) end
		idlenum = 0
	end
	if animPlaying then cancelAnim() end
end


local function UiModeChanged(data)
	local near = false
	if dialogModes[data.newMode] and not dialogModes[data.oldMode] and data.arg and dialogTarget ~= data.arg then
		if self.cell == data.arg.cell then near = true else near = false end
		data["near"], data["player"] = near, self
		core.sendGlobalEvent("dynDialogOpened", data)
		onDialogOpened(data)
	elseif dialogModes[data.newMode] and dialogTarget then
		core.sendGlobalEvent("dynDialogChange", data)
	elseif data.newMode == nil and dialogTarget then
		core.sendGlobalEvent("dynDialogClosed", data)
		onDialogClosed(data)
	end
	if not openDialog then return end
	if dialogHudModes[data.newMode] then
		if not I.UI.isHudVisible() then I.UI.setHudVisibility(true) end
	elseif settingsplayer:get("dialog_disableHud") and I.UI.isHudVisible() then
		if data.newMode then I.UI.setHudVisibility(false) end
	end
end


local function updateActorCombat(e)
		if next(e.targets) == nil or not dialogTarget then return	end
		for _, target in ipairs(e.targets) do
			if target == self then
				core.sendGlobalEvent("dynForcePause") break	end
		end
end


return {
	engineHandlers = { onUpdate = onUpdate, onKeyPress = onKeyPress },
	eventHandlers = {
	UiModeChanged = UiModeChanged,
	tes3InfoGetText = function(e) if dialogTarget then dialogTarget:sendEvent("dynInfoEvent", e) end end,
	dynUiMessage = function(e) ui.showMessage(l10n(e)) end,
	OMWMusicCombatTargetsChanged = function(e)
		if next(e.targets) == nil or not e.actor then return	end
		local inCombat
		for _, target in ipairs(e.targets) do
			if target == self.object then inCombat = true	break	end
		end
		if not inCombat then return	end
		if dialogTarget then core.sendGlobalEvent("dynForcePause")	end
		local pos1, pos2 = e.actor.position, self.object.position
		if (pos1 - pos2):length() > 2000 then return end
		if math.abs(pos1.z - pos2.z) > 1000 then return end
		procStanceChange(true)
	end
	},
}
