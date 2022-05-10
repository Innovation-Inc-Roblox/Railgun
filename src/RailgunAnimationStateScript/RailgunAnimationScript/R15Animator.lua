--[[
TheNexusAvenger

Handles moving R15 joints.
--]]

local LEFT_HAND_GRIP_CORRECTION = CFrame.new(0.6,0,0) * CFrame.Angles(math.rad(-90),0,0)

local TweenService = game:GetService("TweenService")



--[[
Attempts to solve a joint.
--]]
local function SolveJoint(OriginCFrame: CFrame, TargetPosition: Vector3, Length1: number, Length2: number): (CFrame, number, number)
    local LocalizedPosition = OriginCFrame:PointToObjectSpace(TargetPosition)
    local LocalizedUnit = LocalizedPosition.Unit
    local Hypotenuse = LocalizedPosition.Magnitude

    --Get the axis and correct it if it is 0.
    local Axis = Vector3.new(0, 0, -1):Cross(LocalizedUnit)
    if Axis == Vector3.new(0, 0, 0) then
        if LocalizedPosition.Z < 0 then
            Axis = Vector3.new(0, 0, 0.001)
        else
            Axis = Vector3.new(0, 0, -0.001)
        end
    end

    --Calculate and return the angles.
    local PlaneRotation = math.acos(-LocalizedUnit.Z)
    local PlaneCFrame = OriginCFrame * CFrame.fromAxisAngle(Axis, PlaneRotation)
    if Hypotenuse < math.max(Length2, Length1) - math.min(Length2, Length1) then
        local ShoulderAngle,ElbowAngle = -math.pi / 2, math.pi
        return PlaneCFrame * CFrame.new(0, 0, math.max(Length2, Length1) - math.min(Length2, Length1) - Hypotenuse), ShoulderAngle, ElbowAngle
    elseif Hypotenuse > Length1 + Length2 then
        local ShoulderAngle,ElbowAngle = math.pi/2, 0
        return PlaneCFrame * CFrame.new(0, 0, Length1 + Length2 - Hypotenuse), ShoulderAngle, ElbowAngle
    else
        local Angle1 = -math.acos((-(Length2 * Length2) + (Length1 * Length1) + (Hypotenuse * Hypotenuse)) / (2 * Length1 * Hypotenuse))
        local Angle2 = math.acos(((Length2 * Length2) - (Length1 * Length1) + (Hypotenuse * Hypotenuse)) / (2 * Length2 * Hypotenuse))
        return PlaneCFrame, Angle1 + math.pi / 2, Angle2 - Angle1
    end
end

--[[
Returns the rotation offset relative to the Y axis
to an end CFrame.
--]]
local function RotationTo(StartCFrame: CFrame, EndCFrame: CFrame): CFrame
    local Offset = (StartCFrame:Inverse() * EndCFrame).Position
    return CFrame.Angles(math.atan2(Offset.Z, Offset.Y), 0, -math.atan2(Offset.X, Offset.Y))
end

--[[
Attempts to solve a limb.
From: https://github.com/TheNexusAvenger/Nexus-VR-Character-Model/blob/master/src/Character/Appendage.lua
--]]
local function SolveLimb(StartCFrame: CFrame, HoldCFrame: CFrame, UpperLimbStartAttachment: Attachment, UpperLimbJointAttachment: Attachment, LowerLimbJointAttachment: Attachment, LowerLimbEndAttachment: Attachment, LimbEndAttachment: Attachment, LimbHoldAttachment: Attachment): (CFrame, CFrame, CFrame)
    --Get the attachment CFrames.
    local UpperLimbStartCFrame = UpperLimbStartAttachment.CFrame
    local UpperLimbJointCFrame = UpperLimbJointAttachment.CFrame
    local LowerLimbJointCFrame = LowerLimbJointAttachment.CFrame
    local LowerLimbEndCFrame = LowerLimbEndAttachment.CFrame
    local LimbEndCFrame = LimbEndAttachment.CFrame
    local LimbHoldCFrame = LimbHoldAttachment.CFrame

    --Calculate the appendage lengths.
    local UpperLimbLength = (UpperLimbStartCFrame.Position - UpperLimbJointCFrame.Position).Magnitude
    local LowerLimbLength = (LowerLimbJointCFrame.Position - LowerLimbEndCFrame.Position).Magnitude

    --Calculate the end point of the limb.
    local AppendageEndJointCFrame = HoldCFrame * LimbHoldCFrame:Inverse() * LimbEndCFrame

    --Solve the join.
    local PlaneCFrame,UpperAngle,CenterAngle = SolveJoint(StartCFrame, AppendageEndJointCFrame.Position, UpperLimbLength, LowerLimbLength)

    --Calculate the CFrame of the limb join before and after the center angle.
    local JointUpperCFrame = PlaneCFrame * CFrame.Angles(UpperAngle, 0, 0) * CFrame.new(0, -UpperLimbLength, 0)
    local JointLowerCFrame = JointUpperCFrame * CFrame.Angles(CenterAngle, 0, 0)

    --Calculate the part CFrames.
    --The appendage end is not calculated with hold CFrame directly since it can ignore PreventDisconnection = true.
    local UpperLimbCFrame = JointUpperCFrame * RotationTo(UpperLimbJointCFrame,UpperLimbStartCFrame):Inverse() * UpperLimbJointCFrame:Inverse()
    local LowerLimbCFrame = JointLowerCFrame * RotationTo(LowerLimbEndCFrame,LowerLimbJointCFrame):Inverse() * LowerLimbJointCFrame:Inverse()
    local AppendageEndCFrame = CFrame.new((LowerLimbCFrame * LowerLimbEndCFrame).Position) * (CFrame.new(-AppendageEndJointCFrame.Position) * AppendageEndJointCFrame) * LimbEndCFrame:Inverse()

    --Return the part CFrames.
    return UpperLimbCFrame, LowerLimbCFrame, AppendageEndCFrame
end



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
    local RightLowerArm = Character:WaitForChild("RightLowerArm")
    local RightHand = Character:WaitForChild("RightHand")

    local LeftUpperArm = Character:FindFirstChild("LeftUpperArm")
    local LeftLowerArm = Character:FindFirstChild("LeftLowerArm")
    local LeftHand = Character:FindFirstChild("LeftHand")

    local UpperTorsoRightShoulderRigAttachment = UpperTorso:FindFirstChild("RightShoulderRigAttachment") or Instance.new("Attachment")
    local RightUpperArmRightShoulderRigAttachment = RightUpperArm:FindFirstChild("RightShoulderRigAttachment") or Instance.new("Attachment")
    local RightUpperArmRightElbowRigAttachment = RightUpperArm:FindFirstChild("RightElbowRigAttachment") or Instance.new("Attachment")
    local RightLowerArmRightElbowRigAttachment = RightLowerArm:FindFirstChild("RightElbowRigAttachment") or Instance.new("Attachment")
    local RightLowerArmRightWristRigAttachment = RightLowerArm:FindFirstChild("RightWristRigAttachment") or Instance.new("Attachment")
    local RightHandRightWristRigAttachment = RightHand:FindFirstChild("RightWristRigAttachment") or Instance.new("Attachment")
    local RightHandRightGripAttachment = RightHand:FindFirstChild("RightGripAttachment") or Instance.new("Attachment")

    local UpperTorsoLeftShoulderRigAttachment = UpperTorso:FindFirstChild("LeftShoulderRigAttachment") or Instance.new("Attachment")
    local LeftUpperArmLeftShoulderRigAttachment = (LeftUpperArm and LeftUpperArm:FindFirstChild("LeftShoulderRigAttachment")) or Instance.new("Attachment")
    local LeftUpperArmLeftElbowRigAttachment = (LeftUpperArm and LeftUpperArm:FindFirstChild("LeftElbowRigAttachment")) or Instance.new("Attachment")
    local LeftLowerArmLeftElbowRigAttachment = (LeftLowerArm and LeftLowerArm:FindFirstChild("LeftElbowRigAttachment")) or Instance.new("Attachment")
    local LeftLowerArmLeftWristRigAttachment = (LeftLowerArm and LeftLowerArm:FindFirstChild("LeftWristRigAttachment")) or Instance.new("Attachment")
    local LeftHandLeftWristRigAttachment = (LeftHand and LeftHand:FindFirstChild("LeftWristRigAttachment")) or Instance.new("Attachment")
    local LeftHandLeftGripAttachment = (LeftHand and LeftHand:FindFirstChild("LeftGripAttachment")) or Instance.new("Attachment")

    local RightShoulder = RightUpperArm:FindFirstChild("RightShoulder")
    local RightElbow = RightLowerArm:FindFirstChild("RightElbow")
    local RightWrist = RightHand:FindFirstChild("RightWrist")
    local LeftShoulder = LeftUpperArm and LeftUpperArm:FindFirstChild("LeftShoulder")
    local LeftElbow = LeftLowerArm and LeftLowerArm:FindFirstChild("LeftElbow")
    local LeftWrist = LeftHand and LeftHand:FindFirstChild("LeftWrist")

    --Create the welds.
    local RightShoulderWeld,RightElbowWeld,RightWristWeld = nil, nil, nil
    local LeftShoulderWeld,LeftElbowWeld,LeftWristWeld = nil, nil, nil
    if RightShoulder then
        RightShoulder.Part1 = nil

        RightShoulderWeld = Instance.new("Weld")
        RightShoulderWeld.Name = "RightShoulderWeld"
        RightShoulderWeld.C0 = UpperTorsoRightShoulderRigAttachment.CFrame
        RightShoulderWeld.C1 = RightUpperArmRightShoulderRigAttachment.CFrame
        RightShoulderWeld.Part0 = UpperTorso
        RightShoulderWeld.Part1 = RightUpperArm
        RightShoulderWeld.Parent = RightUpperArm
    end
    if RightElbow then
        RightElbow.Part1 = nil

        RightElbowWeld = Instance.new("Weld")
        RightElbowWeld.Name = "RightElbowWeld"
        RightElbowWeld.C0 = RightUpperArmRightElbowRigAttachment.CFrame
        RightElbowWeld.C1 = RightLowerArmRightElbowRigAttachment.CFrame
        RightElbowWeld.Part0 = RightUpperArm
        RightElbowWeld.Part1 = RightLowerArm
        RightElbowWeld.Parent = RightLowerArm
    end
    if RightWrist then
        RightWrist.Part1 = nil

        RightWristWeld = Instance.new("Weld")
        RightWristWeld.Name = "RightHandWeld"
        RightWristWeld.C0 = RightLowerArmRightWristRigAttachment.CFrame
        RightWristWeld.C1 = RightHandRightWristRigAttachment.CFrame
        RightWristWeld.Part0 = RightLowerArm
        RightWristWeld.Part1 = RightHand
        RightWristWeld.Parent = RightHand
    end
    if LeftShoulder then
        LeftShoulder.Part1 = nil

        LeftShoulderWeld = Instance.new("Weld")
        LeftShoulderWeld.Name = "LeftShoulderWeld"
        LeftShoulderWeld.C0 = UpperTorsoLeftShoulderRigAttachment.CFrame
        LeftShoulderWeld.C1 = LeftUpperArmLeftShoulderRigAttachment.CFrame
        LeftShoulderWeld.Part0 = UpperTorso
        LeftShoulderWeld.Part1 = LeftUpperArm
        LeftShoulderWeld.Parent = LeftUpperArm
    end
    if LeftElbow then
        LeftElbow.Part1 = nil

        LeftElbowWeld = Instance.new("Weld")
        LeftElbowWeld.Name = "LeftElbowWeld"
        LeftElbowWeld.C0 = LeftUpperArmLeftElbowRigAttachment.CFrame
        LeftElbowWeld.C1 = LeftLowerArmLeftElbowRigAttachment.CFrame
        LeftElbowWeld.Part0 = LeftUpperArm
        LeftElbowWeld.Part1 = LeftLowerArm
        LeftElbowWeld.Parent = LeftLowerArm
    end
    if LeftWrist then
        LeftWrist.Part1 = nil

        LeftWristWeld = Instance.new("Weld")
        LeftWristWeld.Name = "LeftHandWeld"
        LeftWristWeld.C0 = LeftLowerArmLeftWristRigAttachment.CFrame
        LeftWristWeld.C1 = LeftHandLeftWristRigAttachment.CFrame
        LeftWristWeld.Part0 = LeftLowerArm
        LeftWristWeld.Part1 = LeftHand
        LeftWristWeld.Parent = LeftHand
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
            function Animation:Tween(Ins: Instance, Property: string, Value: any, TweenInfoObject: TweenInfo)
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
                        local ShoulderCFrame = CFrame.new(1, 0.5, 0)
                        local GripCFrame = ShoulderCFrame * (CFrame.new(1, 0.5, 0):Inverse() * AnimationController.LastRightShoulderCFrameC0) * (CFrame.new(-0.5, 0.5, 0):Inverse() * AnimationController.LastRightShoulderCFrameC1):Inverse() * CFrame.new(0.5, -1.5, 0) * (CFrame.new(0, -1, 0):Inverse() * AnimationController.LastGripCFrameC0)

                        local NewUpperArmCFrame,NewLowerArmCFrame,NewHandCFrame = SolveLimb(ShoulderCFrame, GripCFrame, RightUpperArmRightShoulderRigAttachment, RightUpperArmRightElbowRigAttachment, RightLowerArmRightElbowRigAttachment, RightLowerArmRightWristRigAttachment, RightHandRightWristRigAttachment, RightHandRightGripAttachment)
                        self:Tween(RightShoulderWeld, "C0", NewUpperArmCFrame * RightUpperArmRightShoulderRigAttachment.CFrame, TweenInfoObject)
                        self:Tween(RightElbowWeld, "C0", NewUpperArmCFrame:Inverse() * (NewLowerArmCFrame * RightLowerArmRightElbowRigAttachment.CFrame), TweenInfoObject)
                        self:Tween(RightWristWeld, "C0", NewLowerArmCFrame:Inverse() * (NewHandCFrame * RightHandRightWristRigAttachment.CFrame), TweenInfoObject)
                    else
                        local ShoulderCFrame = CFrame.new(-1, 0.5, 0)
                        local GripCFrame = ShoulderCFrame * (CFrame.new(-1, 0.5, 0):Inverse() * AnimationController.LastLeftShoulderCFrameC0) * (CFrame.new(0.5, 0.5, 0):Inverse() * AnimationController.LastLeftShoulderCFrameC1):Inverse() * CFrame.new(-0.5, -1.5, 0) * LEFT_HAND_GRIP_CORRECTION

                        local NewUpperArmCFrame,NewLowerArmCFrame,NewHandCFrame = SolveLimb(ShoulderCFrame, GripCFrame, LeftUpperArmLeftShoulderRigAttachment, LeftUpperArmLeftElbowRigAttachment, LeftLowerArmLeftElbowRigAttachment, LeftLowerArmLeftWristRigAttachment, LeftHandLeftWristRigAttachment, LeftHandLeftGripAttachment)
                        self:Tween(LeftShoulderWeld, "C0", NewUpperArmCFrame * LeftUpperArmLeftShoulderRigAttachment.CFrame, TweenInfoObject)
                        self:Tween(LeftElbowWeld, "C0", NewUpperArmCFrame:Inverse() * (NewLowerArmCFrame * LeftLowerArmLeftElbowRigAttachment.CFrame),TweenInfoObject)
                        self:Tween(LeftWristWeld, "C0", NewLowerArmCFrame:Inverse() * (NewHandCFrame * LeftHandLeftWristRigAttachment.CFrame), TweenInfoObject)
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
        --Remove the welds.
        if RightShoulderWeld then
            RightShoulderWeld:Destroy()
            RightShoulderWeld = nil
        end
        if RightElbowWeld then
            RightElbowWeld:Destroy()
            RightElbowWeld = nil
        end
        if RightWristWeld then
            RightWristWeld:Destroy()
            RightWristWeld = nil
        end
        if LeftShoulderWeld then
            LeftShoulderWeld:Destroy()
            LeftShoulderWeld = nil
        end
        if LeftElbowWeld then
            LeftElbowWeld:Destroy()
            LeftElbowWeld = nil
        end
        if LeftWristWeld then
            LeftWristWeld:Destroy()
            LeftWristWeld = nil
        end

        --Reset the motors.
        if RightShoulder then
            RightShoulder.Part1 = RightUpperArm
        end
        if RightElbow then
            RightElbow.Part1 = RightLowerArm
        end
        if RightWrist then
            RightWrist.Part1 = RightHand
        end
        if LeftShoulder then
            LeftShoulder.Part1 = LeftUpperArm
        end
        if LeftElbow then
            LeftElbow.Part1 = LeftLowerArm
        end
        if LeftWrist then
            LeftWrist.Part1 = LeftHand
        end
    end

    --Return the animator.
    return AnimationController
end