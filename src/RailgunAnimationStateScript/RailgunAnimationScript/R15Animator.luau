--Handles moving R15 joints.
--!strict

local LEFT_HAND_GRIP_CORRECTION = CFrame.new(0.6, 0, 0) * CFrame.Angles(math.rad(-90), 0, 0)

local Appendage = require(script.Parent:WaitForChild("NexusAppendage"):WaitForChild("Appendage")) :: any



return function(Player: Player)
    --Get the required parts and return if the character is invalid.
    local Character = Player.Character
    if not Character then
        return
    end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid") :: Humanoid
    if not Humanoid then
        return
    end

    --Get the components.
    --An UpperTorso and Right Arm are assumed to exist.
    local UpperTorso = Character:WaitForChild("UpperTorso") :: BasePart
    local RightUpperArm = Character:WaitForChild("RightUpperArm") :: BasePart
    local RightHand = Character:WaitForChild("RightHand") :: BasePart
    local LeftUpperArm = Character:FindFirstChild("LeftUpperArm") :: BasePart
    local LeftHand = Character:FindFirstChild("LeftHand") :: BasePart

    --Create the appendages.
    local LeftArm = LeftUpperArm and LeftHand and Appendage.FromPreset("LeftArm", Character, true)
    local RightArm = Appendage.FromPreset("RightArm", Character, true)

    --Create the psuedo-object.
    local AnimationController = {}
    AnimationController.LastLeftShoulderCFrameC0 = LeftArm and LeftArm:GetAttachmentCFrame(UpperTorso, "LeftShoulderRigAttachment") or CFrame.identity
    AnimationController.LastLeftShoulderCFrameC1 = LeftArm and LeftArm:GetAttachmentCFrame(LeftUpperArm, "LeftShoulderRigAttachment") or CFrame.identity
    AnimationController.LastRightShoulderCFrameC0 = RightArm:GetAttachmentCFrame(UpperTorso, "RightShoulderRigAttachment")
    AnimationController.LastRightShoulderCFrameC1 = RightArm:GetAttachmentCFrame(RightUpperArm, "RightShoulderRigAttachment")
    AnimationController.LastGripCFrameC0 = RightArm:GetAttachmentCFrame(RightHand, "RightGripAttachment")

    --[[
    Plays an animation.
    --]]
    function AnimationController:PlayAnimation(AnimationData)
        AnimationData(function(LimbName: string, TargetC0: CFrame, TargetC1: CFrame, TweenInfoObject: TweenInfo?)
            --Update the stored CFrame.
            if LimbName == "RightGrip" then
                AnimationController.LastGripCFrameC0 = (TargetC0 or AnimationController.LastGripCFrameC0)
            elseif LimbName == "LeftShoulder" then
                AnimationController.LastLeftShoulderCFrameC0 = (TargetC0 or AnimationController.LastLeftShoulderCFrameC0)
                AnimationController.LastLeftShoulderCFrameC1 = (TargetC1 or AnimationController.LastLeftShoulderCFrameC1)
            elseif LimbName == "RightShoulder" then
                AnimationController.LastRightShoulderCFrameC0 = (TargetC0 or AnimationController.LastRightShoulderCFrameC0)
                AnimationController.LastRightShoulderCFrameC1 = (TargetC1 or AnimationController.LastRightShoulderCFrameC1)
            end

            --Update the changed arm.
            if LimbName == "RightGrip" or LimbName == "RightShoulder" then
                local RelativeGripCFrame = (CFrame.new(1, 0.5, 0):Inverse() * AnimationController.LastRightShoulderCFrameC0) * (CFrame.new(-0.5, 0.5, 0):Inverse() * AnimationController.LastRightShoulderCFrameC1):Inverse() * CFrame.new(0.5, -1.5, 0) * (CFrame.new(0, -1, 0):Inverse() * AnimationController.LastGripCFrameC0)
                RightArm:MoveTo(RelativeGripCFrame, TweenInfoObject)
            elseif LeftArm then
                local RelativeGripCFrame = (CFrame.new(-1, 0.5, 0):Inverse() * AnimationController.LastLeftShoulderCFrameC0) * (CFrame.new(0.5, 0.5, 0):Inverse() * AnimationController.LastLeftShoulderCFrameC1):Inverse() * CFrame.new(-0.5, -1.5, 0) * LEFT_HAND_GRIP_CORRECTION
                LeftArm:MoveTo(RelativeGripCFrame, TweenInfoObject)
            end
        end)
    end

    --[[
    Destroys the animation controller.
    --]]
    function AnimationController:Destroy()
        --Remove the appendages.
        LeftArm:Destroy()
        RightArm:Destroy()
    end

    --Return the animator.
    return AnimationController
end