local cf = mwse.loadConfig("Quick Wheel", {qwhkey = {keyCode = 16}, whalf = 0, whn = 16, whwid = 700, mbwh = 3, scric = true})
local L = {}	local M = {}	local G = {pi2 = math.pi*2}
local p, mp, inv, D, MB

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Quick Wheel")	tpl:saveOnClose("Quick Wheel", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createKeyBinder{label = "Quick Wheel button", variable = var{id = "qwhkey", table = cf}}
p0:createSlider{label = "Hold down this mouse button when selecting a quick slot to reassign it (1 - left, 2 - right, 3 - middle, 4-7 - side)", min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mbwh", table = cf}}
p0:createSlider{label = "Number of slots", min = 1, max = 100, step = 1, jump = 8, variable = var{id = "whn", table = cf}, callback = L.WHnum}
p0:createSlider{label = "Wheel size", min = 300, max = 2000, step = 50, jump = 100, variable = var{id = "whwid", table = cf}}
p0:createDecimalSlider{label = "Quick Wheel transparency", variable = var{id = "whalf", table = cf}}
p0:createYesNoButton{label = "Show effect icons for scrolls", variable = var{id = "scric", table = cf}}
end		event.register("modConfigReady", registerModConfig)



L.WHnum = function()
	if D and cf.whn > #D.QW then
		for i = 1, cf.whn do if D.QW[i] == nil then D.QW[i] = false end end
	end
end

L.MousAx = function(e) 
G.MoX = G.MoX + e.deltaX	G.MoY = G.MoY - e.deltaY		--local Dist = math.sqrt(G.MoX*G.MoX + G.MoY*G.MoY)
local Ang = math.atan2(G.MoX, G.MoY)	if Ang < 0 then Ang = G.pi2 + Ang end
Ang = Ang + G.WHang/2					if Ang > G.pi2 then Ang = Ang - G.pi2 end

G.WHcur = math.ceil(Ang / G.WHang)

if G.WHcur ~= G.WHlast then
	if G.WHlast then M.WH[G.WHlast].width = 32		M.WH[G.WHlast].height = 32		M.WH[G.WHlast].scaleMode = false end
	M.WH[G.WHcur].width = 64		M.WH[G.WHcur].height = 64		M.WH[G.WHcur].scaleMode = true
	M.WH[0]:updateLayout()
end
G.WHlast = G.WHcur

--tes3.messageBox("Dx = %s    Dy = %s     Dist = %d   Ang = %.3f   Cur = %d", G.MoX, G.MoY, Dist, Ang, G.WHcur)
end


L.KeyUpWH = function(e) if e.keyCode == cf.qwhkey.keyCode then
	if G.WHcur then		local id = D.QW[G.WHcur]
		if not id or MB[cf.mbwh] == 128 then
			tes3.messageBox{message = "Select a spell or item for this quick slot", buttons = {"spell", "item", "clear"}, callback = function(mt)
				if mt.button == 0 then
					tes3ui.showMagicSelectMenu{title = "Select a spell for this quick slot", callback = function(t)
						if t.spell then D.QW[G.WHcur] = t.spell.id elseif t.item then D.QW[G.WHcur] = t.item.id end		tes3ui.leaveMenuMode()
					end}
				elseif mt.button == 1 then
					tes3ui.showInventorySelectMenu{title = "Select a item for this quick slot", filter = "quickUse", callback = function(t)
						if t.item then D.QW[G.WHcur] = t.item.id end	tes3ui.leaveMenuMode()
					end}
				else D.QW[G.WHcur] = false end
			end}
		elseif id then
			local ob = tes3.getObject(id)	local ct = ob.castType
			if ct then
				if p.object.spells:contains(ob) or ct == 5 then mp:equipMagic{source = ob}
				else D.QW[G.WHcur] = false end
			elseif inv:contains(ob) then
				local enc = ob.enchantment		ct = enc and enc.castType
				if ct == 0 or ct == 2 then mp:equipMagic{source = ob, equipItem = true}
				else	
					if ob.effects then mwscript.equip{reference = p, item = ob}
					else local best = not ob.quality		mp:equip{item = ob, selectBestCondition = best, selectWorstCondition = not best} end
				end
			end
		end
	end
	event.unregister("mouseAxis", L.MousAx)		event.unregister("keyUp", L.KeyUpWH)	M.WH[0]:destroy()	M.WH = nil
end end



local function KEYDOWN(e) if not tes3ui.menuMode() and e.keyCode == cf.qwhkey.keyCode and not M.WH then		local ob, ic, enc, count
	G.WHang = G.pi2 / cf.whn		G.MoX = 0		G.MoY = 0		G.WHlast = nil		G.WHcur = nil
	M.WH = {}	M.WH[0] = tes3ui.createHelpLayerMenu{id = "WH_Menu", fixedFrame = true}		M.WH[0]:destroyChildren()
	M.WH[0].absolutePosAlignX = 0.5		M.WH[0].absolutePosAlignY = 0.5		M.WH[0].color = {0,0,0}		M.WH[0].alpha = cf.whalf	M.WH[0].minWidth = cf.whwid		M.WH[0].minHeight = cf.whwid
	for i = 1, cf.whn do
		ob = D.QW[i] and tes3.getObject(D.QW[i])	enc = nil	count = nil
		if ob then
			if ob.castType then ic = ob.effects[1].object.bigIcon
			else	ic = ob.icon	enc = ob.enchantment
				if enc then		if cf.scric or ob.objectType ~= tes3.objectType.book then enc = enc.effects[1].object.icon else enc = nil end
				else enc = ob.effects	if enc then enc = ob.objectType == tes3.objectType.alchemy and enc[1].object.icon or tes3.getMagicEffect(enc[1]).icon end end
				count = tes3.getItemCount{reference = p, item = ob}	
			end
		else ic = "k\\magicka.dds" end
		
		M.WH[i] = M.WH[0]:createImage{path = "icons\\" .. ic}
		M.WH[i].absolutePosAlignX = 0.5 + math.cos(G.WHang * (i - 1) - math.pi/2) * 0.4
		M.WH[i].absolutePosAlignY = 0.5 + math.sin(G.WHang * (i - 1) - math.pi/2) * 0.4
		if ob then 
			if enc then enc = M.WH[i]:createImage{path = "icons\\" .. enc}		enc.absolutePosAlignX = 1	enc.absolutePosAlignY = 0 end
			if count and count ~= 1 then count = M.WH[i]:createLabel{text = ("%s"):format(count)}		count.color = {1,1,1}		count.absolutePosAlignX = 1		count.absolutePosAlignY = 1 end
		end
	end		M.WH[0]:updateLayout()
	event.register("mouseAxis", L.MousAx)	event.register("keyUp", L.KeyUpWH)
end end		event.register("keyDown", KEYDOWN)

local function loaded(e) p = tes3.player	 mp = tes3.mobilePlayer		D = p.data		inv = p.object.inventory	MB = tes3.worldController.inputController.mouseState.buttons	
	if not D.QW then D.QW = {} end		L.WHnum()
end		event.register("loaded", loaded)