local function traverse(nodes, shouldHighlight)
  if not nodes then
    return
  end

  for node in table.traverse(nodes) do
    if node.materialProperty then
        local materialProperty = node:detachProperty(0x2):clone()

        if shouldHighlight then
          materialProperty.emissive = { r = 0.5, g = 0.5, b = 0.5 }
        else
          materialProperty.emissive = { r = 0, g = 0, b = 0 }
        end

        node:attachProperty(materialProperty)
    end
  end
end

local function highlight(ref)
  local sceneNode = ref.sceneNode
  traverse(sceneNode.children, true)
  sceneNode:updateProperties()
end

local function unhighlight(ref)
  local sceneNode = ref.sceneNode
  traverse(sceneNode.children, false)
  sceneNode:updateProperties()
end

local function activateCallback(e)
  unhighlight(e.target)
end
event.register(tes3.event.activate, activateCallback)

local function onActivationTargetChanged(e)
  if e.current then
    highlight(e.current)
  end
  if e.previous then
    unhighlight(e.previous)
  end
end
event.register('activationTargetChanged', onActivationTargetChanged)

local function OnInitialized()
  mwse.log('[Highlighter] lua script loaded')
end
event.register('initialized', OnInitialized)
