local a = {}
local b = "Madman"
local function c()
    if tes3.onMainMenu() then
        return
    end
    local d = tes3.rayTest({position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector()})
    local e = d and d.reference
    if next(a) then
        for f, g in pairs(a) do
            g.mobile.barterGold = g.object.barterGold
        end
    end
    if e == nil or e.object.objectType ~= tes3.objectType.npc and e.object.objectType ~= tes3.objectType.creature then
        return
    end
    if b == "Madman" then
        return
    end
    if e.mobile and e.mobile.barterGold and e.mobile.barterGold > 0 then
        a[e] = e
        e.mobile.barterGold = 0
    end
end
local function h(e)
    if b == "Madman" then
        return
    end

    if tostring(e.block) == "MenuDialog_service_barter" then
        if not atb and mwscript.getItemCount {reference = tes3.player, item = "gold_001"} > 0 then
            bgold = mwscript.getItemCount {reference = tes3.player, item = "gold_001"}
            tes3.removeItem {reference = tes3.player, item = "gold_001", count = bgold, playSound = false}
            atb = true
        end
    elseif atb and not tes3ui.findMenu(tes3ui.registerID("MenuBarter")) then
        atb = false
        tes3.addItem {reference = tes3.player, item = "gold_001", count = bgold, playSound = false}
    end
end
event.register("uiEvent", h)
event.register("simulate", c)
local i = {}
function i.onCreate(j)
    local k = j:createThinBorder {}
    k.widthProportional = 1.0
    k.heightProportional = 1.0
    k.paddingAllSides = 12
    k.flowDirection = "top_to_bottom"
    local l = k:createLabel {}
    l.color = tes3ui.getPalette("header_color")
    l.borderBottom = 25
    l.text = "Primitive Barter"
    local m = k:createBlock()
    m.widthProportional = 1.0
    m.autoHeight = true
    m.borderBottom = 25
    m.flowDirection = "top_to_bottom"
    local n = m:createButton {}
    n.text = b
    n:register(
        "mouseClick",
        function()
            if b == "Caveman" then
                b = "Madman"
            else
                b = "Caveman"
            end
            n.text = b
            tes3.messageBox(string.format("%s it is!", n.text))
        end
    )
    local o = m:createLabel {}
    o.wrapText = true
    o.text = "Do you want to barter primitively like a caveman or barter using gold like a madman?"
    o.font = 1
    j:updateLayout()
end
local function p()
    mwse.registerModConfig("Primitive Barter", i)
end
event.register("modConfigReady", p)
local function q()
    print("[Primitive Barter] initialized")
end
event.register("initialized", q)
