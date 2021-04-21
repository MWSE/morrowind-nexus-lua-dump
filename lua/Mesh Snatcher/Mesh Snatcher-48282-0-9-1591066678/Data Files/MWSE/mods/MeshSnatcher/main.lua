--you must have the morrowind import plugin installed: https://blender-morrowind.readthedocs.io/en/latest/

--should point to your blender exe. keep quotes as below
local blender = '"C:/Program Files/Blender Foundation/Blender 2.82/blender.exe"'

--should point to a morrowind installation with extracted BSA (containing data files/meshes, etc)
local extractedBSAPath = "E:/Games/Morrowind BlenderCS"

--key to display path and then import targeted mesh in blender:
local openMeshKey = tes3.scanCode.pageUp

--key to reload mesh from disk (disabled by default as there are some issues, uncomment this line to use)
--local reloadMeshKey = tes3.scanCode.pageDown






--no configuration needed below this line--
local script = "\"import bpy;bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False);importobj = bpy.ops.import_scene.mw(filepath='"
local scriptEnd = "');bpy.ops.object.select_all(action='DESELECT');\""

local lastSeen

local function getMeshName(e)
	if tes3.menuMode() then
		return
	end

	local hitResult = tes3.rayTest({ position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector() })
	local hitReference = hitResult and hitResult.reference
	if hitReference == nil then
		return
	end
	if tes3.getFileSource("Meshes\\" .. hitReference.object.mesh) == "file" then
		if lastSeen == hitReference.object.mesh then
			local file = tes3.installDirectory:gsub("\\", "/") .. "/Data Files/Meshes/" .. hitReference.object.mesh:gsub("\\", "/")
			os.execute('start "" ' .. blender .. " --python-expr " .. script .. file .. scriptEnd)
			lastSeen = nil
		else
			lastSeen = hitReference.object.mesh
			tes3.messageBox("%s\nFile - Press again to open in Blender", hitReference.object.mesh)
		end
	else
		if extractedBSAPath == nil then
			tes3.messageBox("%s\nContained in BSA", hitReference.object.mesh)
			lastSeen = nil
		else
			if lastSeen == hitReference.object.mesh then
				local file = extractedBSAPath:gsub("\\", "/") .. "/Data Files/Meshes/" .. hitReference.object.mesh:gsub("\\", "/")
				os.execute('start "" ' .. blender .. " --python-expr " .. script .. file .. scriptEnd)
				lastSeen = nil
			else
				lastSeen = hitReference.object.mesh
				tes3.messageBox("%s\nBSA - Press again to open in Blender", hitReference.object.mesh)
			end
		end
	end
end
event.register("key", getMeshName, {filter = openMeshKey})


local function updateMeshSceneNode(meshSceneRoot, meshName)
    for i, child in ipairs(meshSceneRoot.children) do
        meshSceneRoot:detachChildAt(i)
    end
    for i, child in ipairs(tes3.loadMesh(meshName, false).children) do
        meshSceneRoot:attachChild(child, true)
    end
    meshSceneRoot:update()
    meshSceneRoot:updateNodeEffects()
end

local function reloadMesh(e)
	if tes3.menuMode() then
		return
	end

	local hitResult = tes3.rayTest({ position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector() })
	local hitReference = hitResult and hitResult.reference
	if hitReference == nil then
		return
	end

	updateMeshSceneNode(hitReference.sceneNode, hitReference.object.mesh)
	tes3.messageBox("Mesh reloaded.")
end
if reloadMeshKey ~= nil then
	event.register("key", reloadMesh, {filter = reloadMeshKey})
end