-- Regional Bounties for TES3MP
-- Made by Vidi_Aquam, inspired by Regional Bounty by sushi (https://www.nexusmods.com/morrowind/mods/47285) 

-- Features: -Tracks player bounties by region instead of universally 
--           -Automatically adjusts bounty when changing cells
--           -Works with any modded regions

-- Bugs: -Teleporting to an interior in a different region will not update your bounty to reflect the new region. I don't know of an easy way to fix this globally, but it should be possible to create manual region overrides for places like Mournhold.
--       -When moving into a region in which you have a bounty, you will get a "Your crime has been reported" message box.
 
-- To do: -Make a GUI for viewing your bounties
  
-- Credits/Permissions: Do what you want with it; credit is nice to have

local RegionalBounties = {}

local defaultRegion = "Bitter Coast Region" -- Generally, the region into which a player will spawn after chargen

function RegionalBounties.loadBounty(pid, region)
    if (region == nil) then
		if Players[pid].data.customVariables.currentRegion ~= nil then
			region = Players[pid].data.customVariables.currentRegion 
		else
			region = defaultRegion
		end
    end
	if Players[pid].data.customVariables.bounties ~= nil then
		if Players[pid].data.customVariables.bounties[region] ~= nil then
			local bounty = Players[pid].data.customVariables.bounties[region]
			tes3mp.SetBounty(pid, bounty)
			tes3mp.SendBounty(pid)
		else
			Players[pid].data.customVariables.bounties[region] = 0
			tes3mp.SetBounty(pid, 0)
			tes3mp.SendBounty(pid)
		end
	else
		Players[pid].data.customVariables.bounties = {}
		Players[pid].data.customVariables.bounties[region] = 0
		tes3mp.SetBounty(pid, 0)
		tes3mp.SendBounty(pid)
	end
end

function RegionalBounties.saveBounty(pid, region, bounty)
    Players[pid].data.customVariables.bounties[region] = bounty
	Players[pid]:Save()
end

function RegionalBounties.OnCellChange(eventStatus, pid)
	if tes3mp.IsInExterior(pid) and tes3mp.IsChangingRegion(pid) then
		local currentRegion = tes3mp.GetRegion(pid)
		Players[pid].data.customVariables.currentRegion = currentRegion
		RegionalBounties.loadBounty(pid, currentRegion)
		Players[pid]:Save()
		tes3mp.LogMessage(0, "[RegionalBounties] currentRegion set to " .. currentRegion .. " for pid " .. pid)
	end
end

function RegionalBounties.OnBountyChange(eventStatus, pid)
	local currentRegion = Players[pid].data.customVariables.currentRegion
	if currentRegion == nil then currentRegion = defaultRegion end
	local currentBounty = tes3mp.GetBounty(pid)
	RegionalBounties.saveBounty(pid, currentRegion, currentBounty)
end

function RegionalBounties.OnAuthentified(eventStatus, pid)
	local currentRegion = Players[pid].data.customVariables.currentRegion
	if currentRegion == nil then currentRegion = defaultRegion end
	tes3mp.LogMessage(0, "[RegionalBounties] currentRegion set to " .. currentRegion .. " for pid " .. pid)
	RegionalBounties.loadBounty(pid, currentRegion)
	Players[pid]:Save()
end

customEventHooks.registerHandler("OnPlayerCellChange", RegionalBounties.OnCellChange)
customEventHooks.registerHandler("OnPlayerBounty", RegionalBounties.OnBountyChange)
customEventHooks.registerHandler("OnPlayerAuthentified", RegionalBounties.OnAuthentified)