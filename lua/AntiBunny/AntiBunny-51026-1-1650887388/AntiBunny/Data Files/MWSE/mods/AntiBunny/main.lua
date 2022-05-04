local cf = mwse.loadConfig("AntiBunny", {base = 200, acr = 10, agi = 5, mag = 20, stam = 5, enc = 5})

local function JUMP(e)	local m = e.mobile
local Kstat = cf.base + m:getSkillValue(20) * cf.acr/10 + m.agility.current * cf.agi/10 + m.jump * cf.mag
local Kstam = math.min(math.lerp(cf.stam/10, 1, m.fatigue.normalized), 1)
local Kenc = 1 - math.min(m.encumbrance.normalized,1) * cf.enc/10
e.velocity = e.velocity:normalized() * Kstat * Kstam * Kenc
--tes3.messageBox("Jump! %d = %d stat * %d%% stam * %d%% enc   %d", e.velocity.z, Kstat, Kstam*100, Kenc*100, e.velocity.x)
end		event.register("jump", JUMP)

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("AntiBunny")	tpl:saveOnClose("AntiBunny", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createSlider{label = "Base jump power", min = 100, max = 500, step = 50, jump = 100, variable = var{id = "base", table = cf}}
p0:createSlider{label = "Acrobatics Skill Modifier", min = 5, max = 30, step = 1, jump = 5, variable = var{id = "acr", table = cf}}
p0:createSlider{label = "Agility modifier", min = 0, max = 20, step = 1, jump = 5, variable = var{id = "agi", table = cf}}
p0:createSlider{label = "Jump spell modifier", min = 10, max = 50, step = 1, jump = 5, variable = var{id = "mag", table = cf}}
p0:createSlider{label = "Fatigue modifier", min = 0, max = 10, step = 1, jump = 1, variable = var{id = "stam", table = cf}}
p0:createSlider{label = "Encumbrance modifier", min = 0, max = 10, step = 1, jump = 1, variable = var{id = "enc", table = cf}}
end		event.register("modConfigReady", registerModConfig)