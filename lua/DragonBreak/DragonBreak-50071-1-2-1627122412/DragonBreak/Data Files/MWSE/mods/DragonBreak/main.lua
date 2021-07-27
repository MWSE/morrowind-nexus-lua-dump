local p, mp, wc, flag

local function SIMTIME(e) if mp.movementFlags == 0 or mp.movementFlags == 1280 then wc.deltaTime = wc.deltaTime * 0.01
elseif not (mp.isMovingForward or mp.isMovingBack or mp.isMovingLeft or mp.isMovingRight or mp.isFalling) then wc.deltaTime = wc.deltaTime * 0.3 end end

local function EQUIPPED(e) if e.reference == p and e.item.id == "ring_keley" and tes3.getJournalIndex{id = "MS_FargothRing"} >= 100 then event.register("simulate", SIMTIME)	flag = true end end		event.register("equipped", EQUIPPED)
local function UNEQUIPPED(e) if flag and e.reference == p and e.item.id == "ring_keley" then event.unregister("simulate", SIMTIME)		flag = nil end end		event.register("unequipped", UNEQUIPPED)

local function LOADED(e)	p = tes3.player		mp = tes3.mobilePlayer	wc = tes3.worldController		event.unregister("simulate", SIMTIME)		flag = nil
if tes3.getJournalIndex{id = "MS_FargothRing"} >= 100 and p.object:hasItemEquipped("ring_keley") then event.register("simulate", SIMTIME)		flag = true end
end		event.register("loaded", LOADED)