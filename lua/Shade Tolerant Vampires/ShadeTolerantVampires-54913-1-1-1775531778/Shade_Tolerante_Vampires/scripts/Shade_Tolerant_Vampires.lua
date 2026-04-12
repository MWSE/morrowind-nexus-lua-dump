local self = require("openmw.self")
local camera = require("openmw.camera")
local types = require("openmw.types")
local core = require("openmw.core")
local ui = require("openmw.ui")
local util = require("openmw.util")
local nearby = require("openmw.nearby")

local changestate = 2
local startmode
local sun
local moon
local blood
local alphavalue = 0
local bloodalphavalue = 0
local suncontrol = 0
local mooncontrol = 0
local bloodcontrol = 0

return {
	engineHandlers = {
		onUpdate = function()
			if types.Actor.isSwimming(self) then
				core.sendGlobalEvent("STV_Water_Safe")
			end

			if blood ~= nil and bloodcontrol == 1 then
				bloodalphavalue = bloodalphavalue + 0.005
				blood.layout.props.alpha = bloodalphavalue
				blood:update()
				if bloodalphavalue >= 0.5 then
					bloodcontrol = 2
				end
			elseif blood ~= nil and bloodcontrol == 2 then
				bloodalphavalue = bloodalphavalue - 0.005
				blood.layout.props.alpha = bloodalphavalue
				blood:update()
				if bloodalphavalue <= 0 then
					blood:destroy()
					blood = nil
					bloodcontrol = 0
				end
			end

			if changestate == 1 then
				types.Actor.spells(self):remove("stv_sun_damage")
				types.Actor.spells(self):add("stv_sun_damage_visual")
				camera.setMode(startmode)
				types.Actor.spells(self):remove("chameleon_100_unique")
			elseif changestate == 0 then
				types.Actor.spells(self):remove("stv_sun_damage_visual")
				types.Actor.spells(self):add("stv_sun_damage")
				camera.setMode(startmode)
				types.Actor.spells(self):remove("chameleon_100_unique")
			end

			if sun ~= nil and suncontrol == 1 then
				alphavalue = alphavalue + 0.006
				sun.layout.props.alpha = alphavalue
				sun:update()
				if alphavalue >= 0.6 then
					suncontrol = 2
				end
			elseif sun ~= nil and suncontrol == 2 then
				alphavalue = alphavalue - 0.006
				sun.layout.props.alpha = alphavalue
				sun:update()
				if alphavalue <= 0 then
					sun:destroy()
					sun = nil
					suncontrol = 0
				end
			end

			if moon ~= nil and mooncontrol == 1 then
				alphavalue = alphavalue + 0.006
				moon.layout.props.alpha = alphavalue
				moon:update()
				if alphavalue >= 0.6 then
					mooncontrol = 2
				end
			elseif moon ~= nil and mooncontrol == 2 then
				alphavalue = alphavalue - 0.006
				moon.layout.props.alpha = alphavalue
				moon:update()
				if alphavalue <= 0 then
					moon:destroy()
					moon = nil
					mooncontrol = 0
				end
			end

			changestate = 2 --avoids locking in the startmode camera mode
			local insunlight = false
			local sunshade = false
			if types.Actor.activeSpells(self):isSpellActive("stv_sun_damage_visual") then
				insunlight = true
			end
			--At this point the variable insunlight will be true or false

			if types.Actor.activeSpells(self):isSpellActive("stv_sun_shade") then
				types.Actor.spells(self):remove("stv_sun_shade")
				sunshade = true
			end
			--At this point sunshade will be true if the player just changed from sun to shade or vice versa

			if sunshade == true then
				alphavalue = 0.2
				if insunlight == true or self.cell.isExterior == false then -- Sunlight to shade
					startmode = camera.getMode()
					types.Actor.spells(self):add("chameleon_100_unique")
					if camera.getMode() == 1 then
						camera.setMode(0)
					end
					changestate = 0
					mooncontrol = 1
					if moon == nil then
						if sun ~= nil then
							sun:destroy()
							sun = nil
							suncontrol = 0
						end
						moon = ui.create({
							layer = "HUD",
							type = ui.TYPE.Image,
							props = {
								resource = ui.texture({ path = "textures/zhi_black.bmp" }),
								relativeSize = util.vector2(2, 2),
								alpha = alphavalue,
								relativePosition = util.vector2(-0.5, -0.5),
							},
						})
					end
				else --Shade to sunlight
					startmode = camera.getMode()
					types.Actor.spells(self):add("chameleon_100_unique")
					if camera.getMode() == 1 then
						camera.setMode(0)
					end
					changestate = 1
					suncontrol = 1
					if sun == nil then
						if moon ~= nil then
							moon:destroy()
							moon = nil
							mooncontrol = 0
						end
						sun = ui.create({
							layer = "HUD",
							type = ui.TYPE.Image,
							props = {
								resource = ui.texture({ path = "textures/vfx_fireball01.dds" }),
								relativeSize = util.vector2(2, 2),
								alpha = alphavalue,
								relativePosition = util.vector2(-0.5, -0.5),
							},
						})
					end
				end
			end

			-- Send script to nearby enemies to react to vampire touch
			if types.Actor.getSelectedSpell(self) ~= nil then
				if types.Actor.getSelectedSpell(self).id == "vampire touch" then
					for i, actor in pairs(nearby.actors) do
						if
							(self.position - actor.position):length() < 500
							and not types.Actor.activeSpells(actor):isSpellActive("STV_Drained")
							and types.Actor.activeSpells(actor):isSpellActive("vampire touch")
							and actor ~= self.object
						then
							if
								types.NPC.objectIsInstance(actor)
								or (
									types.Creature.objectIsInstance(actor)
									and (
										types.Creature.record(actor).type == 3
										or types.Creature.record(actor).type == 0
									)
								)
							then
								core.sendGlobalEvent("STV_Feed", { actor = actor })

								if blood == nil then --Change color
									bloodcontrol = 1
									blood = ui.create({
										layer = "HUD",
										type = ui.TYPE.Image,
										props = {
											resource = ui.texture({ path = "textures/vfx_were_void.dds" }),
											relativeSize = util.vector2(2, 2),
											alpha = bloodalphavalue,
											relativePosition = util.vector2(-0.5, -0.5),
										},
									})
								end
							end
						end
					end
				end
			end
		end,
	},
}
