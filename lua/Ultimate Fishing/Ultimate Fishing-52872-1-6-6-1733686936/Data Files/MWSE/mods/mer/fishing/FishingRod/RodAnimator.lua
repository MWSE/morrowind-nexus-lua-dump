-- ---@class Fishing.BoneAnimator.params
-- ---@field rootBone niNode -- The root bone, at the base of the fishing rod. This contains a chain of bones that span the length of the rod.
-- ---@field stiffness number -- The stiffness of the rod. Higher values will make the rod more rigid.

-- ---@class Fishing.BoneAnimator : Fishing.BoneAnimator.params
-- local RodAnimator = {}

-- ---@param o Fishing.BoneAnimator.params
-- function RodAnimator:new(o)
--     o = o or {}
--     setmetatable(o, self)
--     self.__index = self
--     return o
-- end

-- --[[
-- Bends the rod towards the target position.
-- ]]
-- ---@param targetPosition tes3vector3
-- ---@param tension number
-- function RodAnimator:bend(targetPosition, tension)
--     local currentBone = self.rootBone
--     ---@type niNode[]
--     local boneChain = {}
--     ---@type number[]
--     local boneLengths = {}

--     -- Collect all bones in the chain and their original lengths
--     while currentBone do
--         table.insert(boneChain, currentBone)
--         if currentBone.children[1] then
--             local length = (currentBone.children[1].translation - currentBone.translation):length()
--             table.insert(boneLengths, length)
--         end
--         currentBone = currentBone.children[1]
--     end

--     local numBones = #boneChain
--     if numBones == 0 then return end

--     local rootPosition = boneChain[1].translation
--     local direction = (targetPosition - rootPosition):normalized()
--     local totalLength = (targetPosition - rootPosition):length()

--     -- Calculate the bend factor based on stiffness and tension
--     local bendFactor = tension / self.stiffness

--     for i, bone in ipairs(boneChain) do
--         local progress = i / numBones
--         local bendPosition = rootPosition + direction * totalLength * progress * bendFactor

--         if i == 1 then
--             bone.translation = bendPosition
--         else
--             local previousBone = boneChain[i - 1]
--             local length = boneLengths[i - 1]
--             local directionToPrevious = (previousBone.translation - bendPosition):normalized()
--             bone.translation = previousBone.translation - directionToPrevious * length
--         end
--     end
-- end

-- return RodAnimator
