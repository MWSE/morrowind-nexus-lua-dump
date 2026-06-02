-- ------------------------------ Evening Star : ct interop -----------------
-- character traits framework lookups go through here so other modules don't
-- depend on I.CharacterTraits directly. extend as more interop lands (e.g.
-- registering a "faith" trait, syncing belief selection to currentDeity).

local M = {}

-- ct framework loaded AND user opted in; safe to call only after onActive
function M.isInstalled()
	return I.CharacterTraits ~= nil
		and ES.S and ES.S.TOGGLE_USE_CB
end

-- belief trait line id used by ct's statWindow (namespace .. trait.type)
M.BELIEF_LINE_ID  = "CharacterTraits_belief"
M.CULTURE_LINE_ID = "CharacterTraits_culture"

-- jobs to run after ct's chargen modal closes for the final time. register
-- with table.insert(esCtInterop.onChargenDoneJobs, fn). only fires once per
-- playthrough -- ct re-evaluates allTraitsPicked on load from saved
-- selections, so checks needed on load go in G_onLoadJobs instead.
M.onChargenDoneJobs = {}

-- single funnel; G_eventHandlers is one-handler-per-event in sun's dusk
G_eventHandlers.CharacterTraits_allTraitsPicked = function()
	for _, job in pairs(M.onChargenDoneJobs) do
		job()
	end
end

return M
