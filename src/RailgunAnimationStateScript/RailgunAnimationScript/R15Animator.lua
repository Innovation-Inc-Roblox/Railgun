--[[
TheNexusAvenger

Handles moving R15 joints.
--]]

local LEFT_HAND_GRIP_CORRECTION = CFrame.new(0.6, 0, 0) * CFrame.Angles(math.rad(-90), 0, 0)

local TweenService = game:GetService("TweenService")



return function(Player: Player)
    --Get the required parts and return if the character is invalid.
    local Character = Player.Character
    if not Character then
        return
    end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then
        return
    end

    --Get the components.
    --An UpperTorso and Right Arm are assumed to exist.
    local UpperTorso = Character:WaitForChild("UpperTorso")
    local RightUpperArm = Character:WaitForChild("RightUpperArm")
    local RightHand = Character:WaitForChild("RightHand")

    local LeftUpperArm = Character:FindFirstChild("LeftUpperArm")
    local LeftHand = Character:FindFirstChild("LeftHand")

    local UpperTorsoRightShoulderRigAttachment = UpperTorso:FindFirstChild("RightShoulderRigAttachment") or Instance.new("Attachment")
    local RightUpperArmRightShoulderRigAttachment = RightUpperArm:FindFirstChild("RightShoulderRigAttachment") or Instance.new("Attachment")
    local RightHandRightWristRigAttachment = RightHand:FindFirstChild("RightWristRigAttachment") or Instance.new("Attachment")
    local RightHandRightGripAttachment = RightHand:FindFirstChild("RightGripAttachment") or Instance.new("Attachment")

    local UpperTorsoLeftShoulderRigAttachment = UpperTorso:FindFirstChild("LeftShoulderRigAttachment") or Instance.new("Attachment")
    local LeftUpperArmLeftShoulderRigAttachment = (LeftUpperArm and LeftUpperArm:FindFirstChild("LeftShoulderRigAttachment")) or Instance.new("Attachment")
    local LeftHandLeftWristRigAttachment = (LeftHand and LeftHand:FindFirstChild("LeftWristRigAttachment")) or Instance.new("Attachment")
    local LeftHandLeftGripAttachment = (LeftHand and LeftHand:FindFirstChild("LeftGripAttachment")) or Instance.new("Attachment")

    --Create the IKControls.
    local RightArmIKControl, RightHandTargetAttachment = nil, nil
    local LeftArmIKControl, LeftHandTargetAttachment, LeftArmPoleAttachment = nil, nil, nil
    if RightHand then
        RightHandTargetAttachment = Instance.new("Attachment")
        RightHandTargetAttachment.Name = "RailgunAnimationRightHandTarget"
        RightHandTargetAttachment.Parent = UpperTorso

        RightArmIKControl = Instance.new("IKControl")
        RightArmIKControl.Name = "RailgunRightArmIKControl"
        RightArmIKControl.ChainRoot = RightUpperArm
        RightArmIKControl.EndEffector = RightHand
        RightArmIKControl.Type = Enum.IKControlType.Transform
        RightArmIKControl.Target = RightHandTargetAttachment
        RightArmIKControl.Parent = Humanoid
    end
    if LeftHand then
        LeftHandTargetAttachment = Instance.new("Attachment")
        LeftHandTargetAttachment.Name = "RailgunAnimationLeftHandTarget"
        LeftHandTargetAttachment.Parent = UpperTorso

        LeftArmPoleAttachment = Instance.new("Attachment")
        LeftArmPoleAttachment.CFrame = UpperTorsoLeftShoulderRigAttachment.CFrame * CFrame.new(-1, 0, -1)
        LeftArmPoleAttachment.Name = "RailgunAnimationLeftArmPole"
        LeftArmPoleAttachment.Parent = UpperTorso

        LeftArmIKControl = Instance.new("IKControl")
        RightArmIKControl.Name = "RailgunLeftArmIKControl"
        LeftArmIKControl.ChainRoot = LeftUpperArm
        LeftArmIKControl.EndEffector = LeftHand
        LeftArmIKControl.Type = Enum.IKControlType.Transform
        LeftArmIKControl.Target = LeftHandTargetAttachment
        LeftArmIKControl.Pole = LeftArmPoleAttachment
        LeftArmIKControl.Parent = Humanoid
    end

    --Create the psuedo-object.
    local AnimationController = {}
    AnimationController.LastLeftShoulderCFrameC0 = UpperTorsoLeftShoulderRigAttachment.CFrame
    AnimationController.LastLeftShoulderCFrameC1 = LeftUpperArmLeftShoulderRigAttachment.CFrame
    AnimationController.LastRightShoulderCFrameC0 = UpperTorsoRightShoulderRigAttachment.CFrame
    AnimationController.LastRightShoulderCFrameC1 = RightUpperArmRightShoulderRigAttachment.CFrame
    AnimationController.LastGripCFrameC0 = RightHandRightGripAttachment.CFrame

    --[[
    Plays an animation.
    --]]
    function AnimationController:PlayAnimation(AnimationData)
        --Stop the current animation.
        if AnimationController.CurrentAnimation then
            AnimationController.CurrentAnimation:Stop()
        end

        if AnimationData then
            --Create the animation psuedo-object.
            local Animation = {}
            Animation.Tweens = {}
            AnimationController.CurrentAnimation = Animation

            --[[
            Stops the animations.
            --]]
            function Animation:Stop()
                self.Active = false

                --Stop the tweens.
                for _,Tween in pairs(self.Tweens) do
                    Tween:Cancel()
                end
            end

            --[[
            Tweens a property.
            --]]
            function Animation:Tween(Ins: Instance?, Property: string, Value: any, TweenInfoObject: TweenInfo)
                if not Ins then return end
                local TweenName = tostring(Ins).."_"..Property
                if self.Tweens[TweenName] then
                    self.Tweens[TweenName]:Cancel()
                end

                --Move the limb.
                if Ins then
                    if TweenInfoObject then
                        self.Tweens[TweenName] = TweenService:Create(Ins, TweenInfoObject, {[Property]=Value})
                        self.Tweens[TweenName]:Play()
                    else
                        Ins[Property] = Value
                    end
                end
            end

            --[[
            Plays the animation.
            --]]
            function Animation:Play()
                self.Active = true
                AnimationData(function(LimbName: string, TargetC0: CFrame, TargetC1: CFrame, TweenInfoObject: TweenInfo)
                    if not self.Active then return end

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
                        self:Tween(RightHandTargetAttachment, "CFrame", UpperTorsoRightShoulderRigAttachment.CFrame * RelativeGripCFrame * RightHandRightGripAttachment.CFrame:Inverse() * RightHandRightWristRigAttachment.CFrame, TweenInfoObject)
                    else
                        local RelativeGripCFrame = (CFrame.new(-1, 0.5, 0):Inverse() * AnimationController.LastLeftShoulderCFrameC0) * (CFrame.new(0.5, 0.5, 0):Inverse() * AnimationController.LastLeftShoulderCFrameC1):Inverse() * CFrame.new(-0.5, -1.5, 0) * LEFT_HAND_GRIP_CORRECTION
                        self:Tween(LeftHandTargetAttachment, "CFrame", UpperTorsoLeftShoulderRigAttachment.CFrame * RelativeGripCFrame * LeftHandLeftGripAttachment.CFrame:Inverse() * LeftHandLeftWristRigAttachment.CFrame, TweenInfoObject)
                    end
                end)
            end

            --Play the animation.
            Animation:Play()
        end
    end

    --[[
    Destroys the animation controller.
    --]]
    function AnimationController:Destroy()
        --Remove the IKControls.
        if RightArmIKControl then
            RightArmIKControl:Destroy()
            RightArmIKControl = nil
            RightHandTargetAttachment:Destroy()
            RightHandTargetAttachment = nil
        end
        if LeftArmIKControl then
            LeftArmIKControl:Destroy()
            LeftArmIKControl = nil
            LeftHandTargetAttachment:Destroy()
            LeftHandTargetAttachment = nil
            LeftArmPoleAttachment:Destroy()
            LeftArmPoleAttachment = nil
        end
    end

    --Return the animator.
    return AnimationController
end