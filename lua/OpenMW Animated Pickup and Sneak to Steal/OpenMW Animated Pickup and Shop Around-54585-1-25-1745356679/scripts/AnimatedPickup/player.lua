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


local MD = camera.MODE
local sneaking = false
local animPickup, camMode = false
local buyDirect, sneakSteal = true, false
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
   },
})

local settings = storage.playerSection("Settings_animPickup_player")

local function updateSettings()
	local anim = false
	if settings:get("animate1st") and camMode == MD.FirstPerson then anim = true		end
	if settings:get("animate3rd") and camMode ~= MD.FirstPerson then anim = true		end
	buyDirect = settings:get("buydirect")
	sneakSteal = settings:get("nosteal")
	core.sendGlobalEvent("anpPlayerUpdate", {player=self, nosteal=settings:get("nosteal"),
		anim=anim, spd=settings:get("animatespd"), spdtk=settings:get("animatespdtk"),
		direct=buyDirect})
end

settings:subscribe(async:callback(updateSettings))
updateSettings()

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

local function targetChange(o)
	if not buyDirect and not sneakSteal then return		end
	-- if o then print(o.recordId)	else print(o)	end
	target = o
	if tooltip then tooltip:destroy()	tooltip = nil		end
	if not o or not types.Item.objectIsInstance(o) or types.Book.objectIsInstance(o) then return end

    local ownerId = o.owner.recordId
    local factionId = o.owner.factionId
    if not ownerId and not factionId then return end

    if factionId then
        local rank = o.owner.factionRank or 1
        if sneakSteal and not sneaking then return end
        if types.NPC.getFactionRank(self, factionId) >= rank then return end
        toolIcon = "take.dds"
    elseif ownerId then
        if not buyDirect and sneakSteal and not sneaking then return end
        local trade
        if types.NPC.record(ownerId) then trade = tradesItemType(ownerId, o) end
        toolIcon = "take.dds"
        if o.recordId:find("^gold_") then trade = false end
        if sneakSteal and not sneaking and not trade then return end
        if buyDirect and trade and not sneaking then toolIcon = "directPurchase.dds" end
    end

    local col = uiTheme.normal
    if toolIcon == "take.dds" then col = uiTheme.steal end
--    local owner = getOwner(o)
--    if not owner then return end
--    if not tradesItemType(ownerId, o) then return end
    tooltip = ui.create { layer = 'HUD', type = ui.TYPE.Image,
            props = {
                visible = true,
                relativePosition = v2(0.505, 0.505),
                size = v2(32, 32),
                resource = ui.texture { path = "textures/AnimatedPickup/" .. toolIcon },
                color = col,
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
	if useHelper or dt == 0 then return			end
	timer = timer + dt	if timer < 0.1 then return	end		timer = 0

	if not buyDirect and not sneakSteal then return		end
	local pos = camera.getPosition()
	local posTarget = pos + camera.viewportToWorldVector(v2(0.5,0.5))
		* (maxDist + camera.getThirdPersonDistance())
	local res = nearby.castRenderingRay(pos, posTarget, { ignore = self })

	if res.hitObject ~= target then targetChange(res.hitObject)		end
end

local function onUpdate(dt)
	if dt == 0 then return		end
	if camera.getMode() ~= camMode then
		local mode, fp = camera.getMode(), MD.FirstPerson
		if mode == fp or camMode == fp then updateSettings()		end
		camMode = mode
	end
	if self.controls.sneak ~= sneaking then
		sneaking = self.controls.sneak
		if tooltip or (sneaking and sneakSteal) then targetChange(target)	end
		core.sendGlobalEvent("anpPlayerUpdate", {player=self, sneak=sneaking,
			nosteal=settings:get("nosteal"), direct=settings:get("buydirect")})
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
