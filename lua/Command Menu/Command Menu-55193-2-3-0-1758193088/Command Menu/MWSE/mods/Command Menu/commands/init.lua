local util = require("Command Menu.util")

local i18n = mwse.loadTranslations("Command Menu")
local this = {}

--- @type tes3uiMenuController
local menuController

event.register(tes3.event.initialized, function()
	menuController = tes3.worldController.menuController
end)


function this.toggleGodMode()
	menuController.godModeEnabled = not menuController.godModeEnabled
end

--- @param enabled boolean
function this.setGodMode(enabled)
	menuController.godModeEnabled = enabled
end

function this.toggleCollision()
	menuController.collisionDisabled = not menuController.collisionDisabled
end

--- @param enabled boolean
function this.setCollsion(enabled)
	menuController.collisionDisabled = not enabled
end

function this.toggleFogOfWar()
	menuController.fogOfWarDisabled = not menuController.fogOfWarDisabled
end

--- @param enabled boolean
function this.setFogOfWar(enabled)
	menuController.fogOfWarDisabled = not enabled
end

function this.toggleAI()
	menuController.aiDisabled = not menuController.aiDisabled
end

--- @param enabled boolean
function this.setAI(enabled)
	menuController.aiDisabled = not enabled
end

function this.toggleWireframe()
	menuController.wireframeEnabled = not menuController.wireframeEnabled
end

--- @param enabled boolean
function this.setWireframe(enabled)
	menuController.wireframeEnabled = enabled
end

function this.toggleVanityMode()
	tes3.setVanityMode({ toggle = true })
end

--- @param enabled boolean
function this.setVanityMode(enabled)
	tes3.setVanityMode({
		enabled = enabled,
		checkVanityDisabled = false,
	})
end

function this.resetActors()
	tes3.runLegacyScript({ command = "ResetActors" })
end

function this.fixMe()
	tes3.runLegacyScript({ command = "FixMe" })
end

function this.fillMap()
	tes3.runLegacyScript({ command = "FillMap" })
end

function this.fillJournal()
	tes3.runLegacyScript({ command = "FillJournal" })
end

function this.enableStatReviewMenu()
	tes3.runLegacyScript({ command = "EnableStatReviewMenu" })
end

function this.clearBounty()
	tes3.runLegacyScript({ command = "SetPCCrimeLevel 0" })
end

function this.clearStolenFlag()
	if tes3.onMainMenu() then
		return false
	end

	for _, stack in ipairs(tes3.mobilePlayer.inventory) do
		tes3.setItemIsStolen({
			item = stack.object --[[@as tes3item]],
			stolen = false
		})
	end
end

function this.rechargePowers()
	if tes3.onMainMenu() then
		return false
	end

	for _, power in ipairs(tes3.getSpells({ target = tes3.player, spellType = tes3.spellType.power })) do
		tes3.mobilePlayer:rechargePower(power)
	end
end

function this.removeMagic()
	tes3.removeEffects({ reference = tes3.player, castType = tes3.spellType.blight })
	tes3.removeEffects({ reference = tes3.player, castType = tes3.spellType.disease })
	tes3.removeEffects({ reference = tes3.player, castType = tes3.spellType.curse })
	tes3.removeEffects({ reference = tes3.player, castType = tes3.spellType.spell })
	tes3.updateMagicGUI({ reference = tes3.player })
end

function this.killHostiles()
	if tes3.onMainMenu() then
		return false
	end

	for _, hostile in ipairs(tes3.mobilePlayer.hostileActors) do
		hostile:kill()
	end
end

--- Teleports the player to given Cell or NPC.
--- @param destination tes3cell|tes3npc
function this.teleport(destination)
	local cell = destination
	local position
	if destination.objectType == tes3.objectType.npc then
		local npcRef = tes3.getReference(destination.id)
		cell = npcRef.cell
		position = npcRef.position
	end
	--- @cast cell tes3cell
	position = position or util.getTeleportPosition(cell)
	tes3.positionCell({
		cell = cell.isInterior and cell or { cell.gridX, cell.gridY },
		position = position
	})
end

--- Teleports the NPC in front of the player.
---@param npc tes3npc
function this.teleportNPC(npc)
	local npcRef = tes3.getReference(npc.id)
	local position = util.getPointInFrontOfPlayer()
	local cell = tes3.player.cell
	tes3.positionCell({
		reference = npcRef,
		cell = cell.isInterior and cell or nil,
		position = position
	})
end

return this
