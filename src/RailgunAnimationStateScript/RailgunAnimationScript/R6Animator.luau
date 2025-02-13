--Handles moving R6 joints.
--!strict

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
    --A Torso and RightArm are assumed to exist.
    local Torso = Character:WaitForChild("Torso") :: BasePart
    local LeftArm = Character:FindFirstChild("Left Arm") :: BasePart
    local RightArm = Character:WaitForChild("Right Arm") :: BasePart
    local LeftShoulder = Torso:FindFirstChild("Left Shoulder") :: Motor6D
    local RightShoulder = Torso:FindFirstChild("Right Shoulder") :: Motor6D
    local RightGrip = RightArm:WaitForChild("RightGrip") :: Weld

    --Create the welds.
    local LeftWeld,RightWeld = nil, nil
    if LeftShoulder and LeftArm then
        LeftShoulder.Part1 = nil

        LeftWeld = Instance.new("Weld")
        LeftWeld.Name = "LeftWeld"
        LeftWeld.Part0 = Torso
        LeftWeld.C0 = CFrame.new(-1.5, 0.5, 0)
        LeftWeld.C1 = CFrame.new(0, 0.5, 0)
        LeftWeld.Part1 = LeftArm
        LeftWeld.Parent = Torso
    end
    if RightShoulder then
        RightShoulder.Part1 = nil

        RightWeld = Instance.new("Weld")
        RightWeld.Name = "RightWeld"
        RightWeld.Part0 = Torso
        RightWeld.C0 = CFrame.new(1.5, 0.5, 0)
        RightWeld.C1 = CFrame.new(0, 0.5, 0)
        RightWeld.Part1 = RightArm
        RightWeld.Parent = Torso
    end

    --Create the psuedo-object.
    local AnimationController = {} :: any

    --[[
    Plays an animation.
    --]]
    function AnimationController:PlayAnimation(AnimationData): ()
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
                for _, Tween in self.Tweens do
                    Tween:Cancel()
                end
            end

            --[[
            Tweens a property.
            --]]
            function Animation:Tween(Ins: Instance, Property: string, Value: any, TweenInfoObject: TweenInfo)
                local TweenName = `{Ins}_{Property}`
                if self.Tweens[TweenName] then
                    self.Tweens[TweenName]:Cancel()
                end

                --Move the limb.
                if Ins then
                    if TweenInfoObject then
                        self.Tweens[TweenName] = TweenService:Create(Ins, TweenInfoObject, {[Property]=Value})
                        self.Tweens[TweenName]:Play()
                    else
                        (Ins :: any)[Property] = Value
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

                    --Get the item to change.
                    local Weld
                    if LimbName == "RightGrip" then
                        Weld = RightGrip
                    elseif LimbName == "LeftShoulder" then
                        Weld = LeftWeld
                    elseif LimbName == "RightShoulder" then
                        Weld = RightWeld
                    end

                    --Determine the properties to move.
                    local Properties = {}
                    if TargetC0 then
                        Properties["C0"] = TargetC0
                    end
                    if TargetC1 then
                        Properties["C1"] = TargetC1
                    end

                    --Move the limb if it exists.
                    if Weld then
                        for Property, Target in Properties :: {[string]: any} do
                            self:Tween(Weld, Property, Target, TweenInfoObject)
                        end
                    end
                end)
            end

            --Play the animation.
            (Animation :: any):Play()
        end
    end

    --[[
    Destroys the animation controller.
    --]]
    function AnimationController:Destroy(): ()
        --Remove the welds.
        if LeftWeld then
            LeftWeld:Destroy()
            LeftWeld = nil :: any
        end
        if RightWeld then
            RightWeld:Destroy()
            RightWeld = nil :: any
        end

        --Reset the shoulders.
        if LeftShoulder then
            LeftShoulder.Part1 = LeftArm
        end
        if RightShoulder then
            RightShoulder.Part1 = RightArm
        end
    end

    --Return the animator.
    return AnimationController
end