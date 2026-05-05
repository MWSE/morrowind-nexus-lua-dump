if isPlayer then return end

-- if an actor catches any of the portal magic effects, tell global to skip
-- the next pending portal spawn for that magic effect

local ok, db = pcall(require, 'scripts.teleportationmagic.tpDatabase')
if not ok or type(db) ~= 'table' then return end

for effectId in pairs(db) do
	G.onMgefAdded[effectId] = function(key, eff, activeSpell, entry)
		core.sendGlobalEvent('PurplePortal_actorCaught', {
			magicId = effectId,
			actor = self.object,
		})
	end
end
