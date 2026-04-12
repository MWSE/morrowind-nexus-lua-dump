local self = require("openmw.self")
local types = require("openmw.types")
local input = require("openmw.input")
local async = require("openmw.async")
local core = require("openmw.core")
local camera = require("openmw.camera")
local nearby = require("openmw.nearby")
local ambient = require("openmw.ambient")
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local util = require("openmw.util")
local storage = require("openmw.storage")
local l10n = core.l10n("AnimatedPickup")

local L = {
	getMode = camera.getMode,
	FirstPerson = camera.MODE.FirstPerson,
	ctrls = self.controls
}

local sneaking = false
local camMode = L.getMode()
local buyDirect, sneakSteal, showSteal, animPickup, iconPosition
local v2 = util.vector2		local maxDist = core.getGMST("iMaxActivateDist")


I.Settings.registerPage {
   key = "animPickup",
   l10n = "AnimatedPickup",
   name = "settings_modName",
   description = "settings_modDesc"
}

I.Settings.registerGroup({
   key = "Settings_animPickup_player",
   page = "animPickup",
   l10n = "AnimatedPickup",
   name = "settings_modCategory1_name",
   permanentStorage = true,
   settings = {
	{key = "animatespd",
	default = 750,
	renderer = "number",
	name = "settings_modCategory1_setting01_name",
	argument = { min = 1, max = 2000 },
	},
	{key = "animatespdtk",
	default = 100,
	renderer = "number",
	name = "settings_modCategory1_setting02_name",
	argument = { min = 1, max = 2000 },
	},
	{key = "animate1st",
	default = true,
	renderer = "checkbox",
	name = "settings_modCategory1_setting03_name",
	},
	{key = "animate3rd",
	default = true,
	renderer = "checkbox",
	name = "settings_modCategory1_setting04_name",
	},
	{key = "nosteal",
	default = false,
	renderer = "checkbox",
	name = "settings_modCategory1_setting05_name",
	},
	{key = "buydirect",
	default = true,
	renderer = "checkbox",
	name = "settings_modCategory1_setting06_name",
	},
	{key = "iconPosition",
	default = "510,505",
	renderer = "textLine",
	name = "settings_modCategory1_setting07_name",
        },
	{key = "showStealIcon",
	default = true,
	renderer = "checkbox",
	name = "settings_modCategory1_setting08_name",
	},
   },
})

local settings = storage.playerSection("Settings_animPickup_player")

local function updateSettings()
	if camMode == L.FirstPerson then
		animPickup = settings:get("animate1st")
	else
		animPickup = settings:get("animate3rd")
	end
	buyDirect = settings:get("buydirect")
	sneakSteal = settings:get("nosteal")
	showSteal = settings:get("showStealIcon")

	local pos, x, y = settings:get("iconPosition")
	local l = type(pos) == "string" and pos:find(",")
	if l then
		x, y = tonumber(pos:sub(1, l - 1)), tonumber(pos:sub(l + 1, #pos))
	end
	x = (x and x > 0 and x < 1000) and x or 510		y = (y and y > 0 and y < 1000) and y or 505
	iconPosition = v2(x / 1000, y / 1000)

	core.sendGlobalEvent("anpPlayerUpdate",
		{player=self, sneak=L.ctrls.sneak, nosteal=sneakSteal, direct=buyDirect,
		anim=animPickup, speed=settings:get("animatespd"), speedtk=settings:get("animatespdtk")})
end

settings:subscribe(async:callback(updateSettings))
updateSettings()

common = {
	omw = { input=input, async=async, core=core, ui=ui, interfaces=I, util=util, ambient=ambient }
}

local uicode = require("scripts.AnimatedPickup.uicode")

local function gmstToRgb(id, blend)
	local gmst = core.getGMST(id)
	if not gmst then return util.color.rgb(0.6, 0.6, 0.6) end
	local col = {}
	for v in string.gmatch(gmst, "(%d+)") do col[#col + 1] = tonumber(v) end
	if #col ~= 3 then print("Invalid RGB from "..gmst.." "..id) return util.color.rgb(0.6, 0.6, 0.6) end
	if blend then
		for i = 1, 3 do col[i] = col[i] * blend[i] end
	end
	return util.color.rgb(col[1] / 255, col[2] / 255, col[3] / 255)
end

local uiTheme = {
	normal = uicode.gmstToRgb("FontColor_color_normal"),
	normal_over = uicode.gmstToRgb("FontColor_color_normal_over"),
	normal_pressed = uicode.gmstToRgb("FontColor_color_normal_pressed"),
	steal = uicode.gmstToRgb("FontColor_color_normal", {1, 0.15, 0.15}),
	baseSize = 16
	}

local uiMenu = {}
local merchants = {}

local function getOwner(reference)
    local id = reference.owner.recordId
    local owner = merchants[id]
    if owner then
        local o = owner.object
        if o and o:isValid() then
            if o.cell ~= reference.cell then o = nil end
            return o
        end
    end
    if owner and owner.scanned == reference.cell then return end
    print("SCAN for merchant "..id)
    local actor
    for _, v in ipairs(nearby.actors) do
        if v.recordId == id then actor = v end
    end
    merchants[id] = {scanned=reference.cell}
    if actor then merchants[id].object = actor end
    return actor
end

local typeToService = {
	[types.Apparatus] = "Apparatus",
	[types.Armor] = "Armor",
--	[types.Book] = "Books",
	[types.Clothing] = "Clothing",
	[types.Ingredient] = "Ingredients",
	[types.Light] = "Lights",
	[types.Lockpick] = "Picks",
	[types.Miscellaneous] = "Misc",
	[types.Potion] = "Potions",
	[types.Probe] = "Probes",
	[types.Repair] = "RepairItems",
	[types.Weapon] = "Weapon"
	}

local function tradesItemType(id, item)
    local services = types.NPC.record(id).servicesOffered
    if not services.Barter then return false end
    if types.Item.itemData(item).enchantmentCharge then
        if services.MagicItems then return true end
        return false
    end
    local serviceType = typeToService[item.type]
    return services[serviceType]
end


local tooltip, target, toolIcon
local uiVisible = I.UI.isHudVisible()

local function targetChange(o)
	-- if o then print(o.recordId)	else print(o)	end
	if tooltip then
		tooltip:destroy()	tooltip = nil
	end
	target = o
	if not o or not(buyDirect or sneakSteal) or not typeToService[o.type] then
		return
	end

	local ownerId = o.owner.recordId
	local factionId = o.owner.factionId
	if not ownerId and not factionId then		return		end

	local icon
	if ownerId and buyDirect then
		local canBuy
		if not o.recordId:find("^gold_") and types.NPC.records[ownerId] then
			canBuy = tradesItemType(ownerId, o)
		end
		if canBuy and not sneaking then
			icon = "purchase"
		end
	end
	if not icon and showSteal and (not sneakSteal or sneaking) then
		if factionId then
			if types.NPC.getFactionRank(self, factionId) < (o.owner.factionRank or 1) then
				icon = "steal"
			end
		else
			icon = "steal"
		end
	end
	if not icon then		return			end

	toolIcon = icon == "steal" and "take.dds" or "directPurchase.dds"
    tooltip = ui.create { layer = 'HUD', type = ui.TYPE.Image,
            props = {
                visible = uiVisible,
                relativePosition = iconPosition,
                size = v2(32, 32),
                resource = ui.texture { path = "textures/AnimatedPickup/" .. toolIcon },
                color = icon == "steal" and uiTheme.steal or uiTheme.normal,
            },
        }
end

local useHelper = false
local timer = 0
local messageBox


local function onFrame(dt)
	if messageBox then
		if uicode.update() then
			messageBox = nil
		--	print("MESSAGE", messageBox)
		end
	end
	timer = timer + dt	if timer < 0.1 then return	end		timer = 0
	
	if uiVisible ~= I.UI.isHudVisible() then
		uiVisible = I.UI.isHudVisible()
		if tooltip then
			tooltip.layout.props.visible = uiVisible	tooltip:update()
		end
	end
	if useHelper or not(buyDirect or sneakSteal) then
		return
	end

	local pos = camera.getPosition()
	local posTarget = pos + camera.viewportToWorldVector(v2(0.5,0.5))
		* (maxDist + camera.getThirdPersonDistance())
	local res = nearby.castRenderingRay(pos, posTarget, { ignore = self })

	if res.hitObject ~= target then targetChange(res.hitObject)		end
end

local skipChecks
async:newUnsavableSimulationTimer(1, function()
	if I.ODAR and I.ODAR.version >= 111 then

I.ODAR.addEventHandler("statusChange", function(s)
--	print(s.viewChange, s.inFirst, s.sneak)
	if s.viewChange then
		camMode = L.getMode()
		local ap
		if camMode == L.FirstPerson then
			ap = settings:get("animate1st")
		else
			ap = settings:get("animate3rd")
		end
		if ap ~= animPickup then
			animPickup = ap
			core.sendGlobalEvent("anpPlayerUpdate", {player=self, anim=ap})
		end
	end
	if s.sneak ~= sneaking then
		sneaking = s.sneak
		if tooltip or sneakSteal then		targetChange(target)	end
		core.sendGlobalEvent("anpPlayerUpdate", {player=self, sneak=sneaking,
			nosteal=sneakSteal, direct=buyDirect})
	end
end)
skipChecks = true

	end
end)

local function onUpdate(dt)
	if skipChecks or dt <= 0 then		return		end

	if L.getMode() ~= camMode then
		camMode = L.getMode()
		local ap
		if camMode == L.FirstPerson then
			ap = settings:get("animate1st")
		else
			ap = settings:get("animate3rd")
		end
		if ap ~= animPickup then
			animPickup = ap
			core.sendGlobalEvent("anpPlayerUpdate", {player=self, anim=ap})
		end
	end
	if L.ctrls.sneak ~= sneaking then
		sneaking = L.ctrls.sneak
		if tooltip or sneakSteal then		targetChange(target)	end
		core.sendGlobalEvent("anpPlayerUpdate", {player=self, sneak=sneaking,
			nosteal=sneakSteal, direct=buyDirect})
	end

end


local function uiCallback(e)
--	print("CALLBACK "..e)
	I.UI.removeMode(I.UI.MODE.QuickKeysMenu)
	core.sendGlobalEvent("anpEvent", {event="uiMenu", data=e})
end

local function uiMessageMenu(e)
	if e.show then ui.showMessage(l10n(e.show))	return		end
	e.callback = uiCallback
--	ambient.playSound("Menu Click")
	if I.uiTweaks then I.uiTweaks.skipSounds(I.UI.MODE.QuickKeysMenu)		end
	I.UI.setMode(I.UI.MODE.QuickKeysMenu, {windows={}})
        core.sendGlobalEvent("anpEvent", {event="unPause"})

	messageBox = uicode.createMenu(e)
end



return {
	engineHandlers = {
		onUpdate = onUpdate,
		onFrame = onFrame,
	},
	eventHandlers = {
		anpUiSound = function(e)
			ambient.playSound(e.id, e.options)
		end,
		UiModeChanged = function(e)
			if messageBox and e.newMode ~= I.UI.MODE.QuickKeysMenu then
				uicode.removeBox()
			end
		end,
		anpUiMessage = uiMessageMenu,
		anpResetTooltip = function()
			target = nil		if tooltip then tooltip:destroy()	end
		end,
		anpSkipFrame = function(e)
			if I.UI.getMode() ~= e then		return		end
			if #I.UI.modes > 1 then
				I.UI.removeMode(I.UI.getMode())
			else	I.UI.setMode()
			end
		end,
		olhInitialized = function()
			useHelper = true
			I.luaHelper.eventRegister("playerTargetChanged", targetChange)
		end
	},
}
