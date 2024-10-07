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
local animPickup, camMode = false, nil
local buyDirect, sneakSteal = true, false
local v2 = util.vector2


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
	camMode = camera.getMode()
	local anim = false
	if settings:get("animate1st") and camMode == MD.FirstPerson then anim = true end
	if settings:get("animate3rd") and ( camMode == MD.ThirdPerson or camMode == MD.Preview )
		then anim = true end
	buyDirect = settings:get("buydirect")
	sneakSteal = settings:get("nosteal")
	core.sendGlobalEvent("anpPlayerUpdate", {player=self, nosteal=settings:get("nosteal"),
		anim=anim, spd=settings:get("animatespd"), spdtk=settings:get("animatespdtk"),
		direct=buyDirect})
end

settings:subscribe(async:callback(updateSettings))
updateSettings()

local function gmstToRgb(id)
	local gmst = core.getGMST(id)
	if not gmst then return util.color.rgb(0.6, 0.6, 0.6) end
	local col = {}
	for v in string.gmatch(gmst, "(%d+)") do col[#col + 1] = tonumber(v) end
	if #col ~= 3 then print("Invalid RGB from "..gmst.." "..id) return util.color.rgb(0.6, 0.6, 0.6) end
	return util.color.rgb(col[1] / 255, col[2] / 255, col[3] / 255)
end

local uiTheme = {
	normal = gmstToRgb("FontColor_color_normal"),
	steal = util.color.rgb(1, 0.15, 0.15),
	size = 16,
	}


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

    
local timer = 0
local tooltip, target, toolIcon

local function onUpdate()
	if camera.getMode() ~= camMode then updateSettings() end
	if self.controls.sneak == sneaking then return end
	sneaking = self.controls.sneak
	if tooltip or (sneaking and sneakSteal) then target = nil end
	core.sendGlobalEvent("anpPlayerUpdate", {player=self, sneak=sneaking,
		nosteal=settings:get("nosteal"), direct=settings:get("buydirect")})
end

local function onFrame(dt)
	timer = timer + dt
	if timer < 0.1 then return end
	timer = 0
	if not buyDirect and not sneakSteal then return end
	local pos = camera.getPosition()
	local posTarget = pos + camera.viewportToWorldVector(v2(0.5,0.5))
		* (220 + camera.getThirdPersonDistance())
	local res = nearby.castRenderingRay(pos, posTarget, { ignore = self })
	local o = res.hitObject
	if target and o == target then return end
	if tooltip then tooltip:destroy() tooltip = nil end
	target = o
--	if o then print(o.recordId) end
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

local messageBox
I.UI.setPauseOnMode(I.UI.MODE.QuickKeysMenu, false)

local function uiClick(_, e)
--	for k, v in pairs(e) do print(k, v) end
--	print(e.userData)
	messageBox:destroy()
	messageBox = nil
	I.UI.removeMode(I.UI.MODE.QuickKeysMenu)
        core.sendGlobalEvent("apMessageMenu", e.userData)
end

local function Container(options)
    options = options or {}

    local color = options.color and options.color or util.color.hex("000000")
    local alpha = options.alpha or 0
    local padding = options.padding and options.padding or 0

    if type(padding) == "number" then
        padding = { left = padding, right = padding, top = padding, bottom = padding }
    else
        padding = {
            left = padding.left and padding.left or 0,
            right = padding.right and padding.right or 0,
            top = padding.top and padding.top or 0,
            bottom = padding.bottom and padding.bottom or 0
        }
    end

    local template = {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    relativeSize = util.vector2(1, 1),
                    resource = ui.texture { path = "white" },
                    color = color,
                    alpha = alpha,
                    size = util.vector2(padding.left + padding.right, padding.top + padding.bottom),
                },
            },
            {
                external = { slot = true },
                props = {
                    position = util.vector2(padding.left, padding.top),
                    relativeSize = util.vector2(1, 1),
                }
            },
        },
    }
    return template
end

local function uiButton(k, text, callback)
    return { type = ui.TYPE.Container, content = ui.content {
	{ template = I.MWUI.templates.box, props = { anchor = v2(0, -0.5) },
		content = ui.content { {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
        	        content = ui.content { {

				type = ui.TYPE.Text,
				userData = k,
				events = { mouseClick = callback },
				name = name,
				props = { text = text, align = ui.ALIGNMENT.Center,
					textColor = uiTheme.normal, textSize = uiTheme.size }
			} }
		} }
	}
    } }
end

local function uiMessageMenu(e)
	if messageBox then messageBox:destroy() end
	I.UI.setMode(I.UI.MODE.QuickKeysMenu, {windows={}})

	local buttons
	if e.message then buttons = { {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
        	        content = ui.content { {

			type = ui.TYPE.Text,
			props = {
			text = e.message, multiline = true,
			textAlignH = ui.ALIGNMENT.Center,
			textColor = uiTheme.normal,
			textSize = uiTheme.size
	        	}

		} }
	} }
	else buttons = {}
	end

	for k, item in ipairs(e.buttons) do
		local button = uiButton(k, item, async:callback(uiClick))
		table.insert(buttons, button)
	end
    messageBox = ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            relativePosition = v2(0.5, 0.7),
            anchor = v2(0.5, 0.5),
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Center
        },
        content = ui.content {

            { template = Container({ alpha = 0.0, padding = 8, color = util.color.hex("00ff00") }),
            content = ui.content {

                { type = ui.TYPE.Flex,
                content = ui.content(buttons),
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
--                    relativeSize = v2(1, 1),
--                    size = v2(40, 40),
                } },

            } },
         }
    }
end

local cancelModes = {
	[I.UI.MODE.QuickKeysMenu] = true,
	[I.UI.MODE.Dialogue] = true,
	[I.UI.MODE.Book] = true,
	[I.UI.MODE.Scroll] = true,
	[I.UI.MODE.Journal] = true,
	[I.UI.MODE.Barter] = true,
	[I.UI.MODE.Alchemy] = true,
	[I.UI.MODE.Companion] = true
}

return {
	engineHandlers = { onUpdate = onUpdate, onFrame = onFrame,
		onMouseButtonPress = function(e)
			if e ~= 3 then return end
			if messageBox then messageBox:destroy() messageBox=nil end
		end,
	},
	eventHandlers = { apShowMessage = function(data) ui.showMessage(l10n(data)) end,
		ambientPlaySound = function(data) ambient.playSound(data.id, data.options) end,
		UiModeChanged = function(e) if messageBox and e.oldMode == I.UI.MODE.QuickKeysMenu then
			messageBox:destroy() messageBox=nil end end,
		apMessageMenu = uiMessageMenu,
		anpResetTooltip = function() target = nil if tooltip then tooltip:destroy() end end
	}
}
