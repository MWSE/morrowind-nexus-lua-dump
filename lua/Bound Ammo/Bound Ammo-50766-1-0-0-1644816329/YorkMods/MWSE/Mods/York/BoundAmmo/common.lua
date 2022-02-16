local public = {}
logging = true

public.modname = "BoundAmmo"

public.info = function(text)
	if text and logging then
		print("["..string.upper(public.modname)..": INFO] "..text)
	end
end

public.err = function(text)
	if text then
		print("["..string.upper(public.modname)..": ERROR] "..text)
	end
end

public.findAllChildren = function(element)
local tab = {}	
	if #(element.children) > 0 then
		for __,child in pairs(element.children) do
			if child.name then
				public.info(element.name .. " menu has a child with name of ".. child.name)
				table.insert(tab,child)
			else
				public.info(element.name .. " menu has a child with no name")
			end
		end
	end
return tab
end

public.findAllChildrenTab = function(tab)
local tab2 = {}
	if #(tab) > 0 then
		for _,element in pairs(tab) do
			for __,child in pairs(public.findAllChildren(element)) do
				table.insert(tab2,child)
			end
		end
	end
return tab2
end


local function onInit()
	print("["..string.upper(public.modname).."] Initialized Pocket")
end

event.register("initialized", onInit)
return public