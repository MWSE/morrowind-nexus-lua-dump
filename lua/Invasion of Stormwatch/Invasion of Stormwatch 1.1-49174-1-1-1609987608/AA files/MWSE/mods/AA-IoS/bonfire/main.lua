local bonfire = {}

function bonfire.lightBonfire(e)
    if (e.activator == tes3.player and e.target.baseObject.id == "AA_topics_act") then
        print("Found " .. e.target.baseObject.id)
        for i,c in pairs(e.target.sceneNode.children) do
            if (c.name) then
                print(i .. " - " .. c.name)
                print("  - " .. c.switchIndex)
                for j,k in pairs(c.children) do
                    if (k.name) then
                        print("  " .. j .. " - " .. k.name)
                    end
                end
            end
        end
    end
end

function bonfire.init()
    event.register("activate", bonfire.lightBonfire)
end

return bonfire