--[[
TheNexusAvenger

Handles local animations for the Railgun tools.
--]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local VRService = game:GetService("VRService")

local RemotesContainer = ReplicatedStorage:WaitForChild("RailgunAnimationEvents")
local RailgunNoAnimationPlayersValue = RemotesContainer:WaitForChild("RailgunNoAnimationPlayers")
local VRPlayerJoinedEvent = RemotesContainer:WaitForChild("VRPlayerJoined")
local R6Animator = require(script:WaitForChild("R6Animator"))
local R15Animator = require(script:WaitForChild("R15Animator"))
local RailgunNoAnimationPlayers = HttpService:JSONDecode(RailgunNoAnimationPlayersValue.Value)

local PlayerAnimators = {}



local ANIMATION_FUNCTIONS = {
    RaiseWeapon = function(MoveLimbFunction)
        local AnimationTweenInfo = TweenInfo.new(0.5)
        MoveLimbFunction("RightGrip", CFrame.new(-0.3, -1, 0) * CFrame.fromEulerAnglesXYZ(-1.22 - 0.15, -0.45, 0.22))
        MoveLimbFunction("RightShoulder", CFrame.new(1.5, 0.5, -0.2) * CFrame.fromEulerAnglesXYZ(1.4, 0, -0.5), nil, AnimationTweenInfo)
        MoveLimbFunction("LeftShoulder", CFrame.new(-1.2, 0.2, 0.4) * CFrame.fromEulerAnglesXYZ(1.7, 0, 0.5), CFrame.new(0.3, 2, 0), AnimationTweenInfo)
    end,
    LowerWeapon = function(MoveLimbFunction)
        local AnimationTweenInfo = TweenInfo.new(0.5)
        MoveLimbFunction("RightGrip", CFrame.new(-0.3, -1, 0) * CFrame.fromEulerAnglesXYZ(-1.22 - 0.15, -0.45, 0.22))
        MoveLimbFunction("RightShoulder", CFrame.new(1.5, 0.5, -0.2) * CFrame.fromEulerAnglesXYZ(0.5, 0, -0.5), nil, AnimationTweenInfo)
        MoveLimbFunction("LeftShoulder", CFrame.new(-1.7, 0.5, 0.1) * CFrame.fromEulerAnglesXYZ(0.7, 0, 0.8), CFrame.new(0.3, 2, 0), AnimationTweenInfo)
    end,
    FireAndReload = function(MoveLimbFunction)
        --Move the arms to the correct position.
        MoveLimbFunction("RightGrip", CFrame.new(-0.3, -1, 0) * CFrame.fromEulerAnglesXYZ(-1.22 - 0.15, -0.45, 0.22))
        MoveLimbFunction("RightShoulder", CFrame.new(1.5,0.5,-0.2) * CFrame.fromEulerAnglesXYZ(1.4, 0, -0.5))
        MoveLimbFunction("LeftShoulder", CFrame.new(-1.2,0.2,0.4) * CFrame.fromEulerAnglesXYZ(1.7, 0, 0.5), CFrame.new(0.3, 2, 0))

        --Recoil the gun.
        local RecoilTime = TweenInfo.new(0.05)
        MoveLimbFunction("RightGrip", CFrame.new(-0.3, -1, 0) * CFrame.fromEulerAnglesXYZ(-1.22 - 0.15, -0.45, 0.22) * CFrame.new(0, 0, 0.1), nil, RecoilTime)
        task.wait(0.05)
        MoveLimbFunction("RightGrip", CFrame.new(-0.3, -1, 0) * CFrame.fromEulerAnglesXYZ(-1.22 - 0.15, -0.45, 0.22), nil, RecoilTime)
        task.wait(0.05)

        --Lower the gun to reload.
        local LowerTweenInfo = TweenInfo.new(0.25)
        MoveLimbFunction("RightGrip", CFrame.new(-0.3, -1, 0) * CFrame.fromEulerAnglesXYZ(-1.22 - 0.15, -0.45, 0.22))
        MoveLimbFunction("RightShoulder", CFrame.new(1.5, 0.5, -0.2) * CFrame.fromEulerAnglesXYZ(0.5, 0, -0.5), nil, LowerTweenInfo)
        MoveLimbFunction("LeftShoulder", CFrame.new(-0.8, 0.8, 0.6) * CFrame.fromEulerAnglesXYZ(0.9, 0, 0.3), CFrame.new(0.3, 2, 0) * CFrame.Angles(0, math.pi/2, 0), LowerTweenInfo)
        task.wait(0.25)

        --Reload the gun.
        local ReloadTweenInfo = TweenInfo.new(0.15)
        MoveLimbFunction("LeftShoulder", CFrame.new(-0.8, 1.3, 1) * CFrame.fromEulerAnglesXYZ(0.9, 0, 0.3), nil,ReloadTweenInfo)
        task.wait(0.2)
        MoveLimbFunction("LeftShoulder", CFrame.new(-0.8, 0.8, 0.6) * CFrame.fromEulerAnglesXYZ(0.9, 0, 0.3), nil,ReloadTweenInfo)
        task.wait(0.2)

        --Raise the gun.
        local RaiseTweenInfo = TweenInfo.new(0.25)
        MoveLimbFunction("RightShoulder", CFrame.new(1.5, 0.5, -0.2) * CFrame.fromEulerAnglesXYZ(1.4, 0, -0.5), nil, RaiseTweenInfo)
        MoveLimbFunction("LeftShoulder", CFrame.new(-1.2, 0.2, 0.4) * CFrame.fromEulerAnglesXYZ(1.7, 0, 0.5), CFrame.new(0.3, 2, 0), RaiseTweenInfo)
    end,
}



--[[
Equips a player.
--]]
local function EquipPlayer(Player: Player, InitialAnimation: string): ()
    --Return if animations are disabled for the player.
    if RailgunNoAnimationPlayers[tostring(Player.UserId)] then
        return
    end

    --Stop the existing animation controller.
    if PlayerAnimators[Player] then
        PlayerAnimators[Player]:Destroy()
        PlayerAnimators[Player] = nil
    end

    --Get the required parts and return if the character is invalid.
    local Character = Player.Character
    if not Character then
        return
    end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then
        return
    end
    local Tool = Character:FindFirstChildOfClass("Tool")
    if not Tool then
        return
    end

    --Create the animator.
    local AnimationController = (Humanoid.RigType == Enum.HumanoidRigType.R6 and R6Animator(Player) or R15Animator(Player))
    PlayerAnimators[Player] = AnimationController

    --Play the initial animation.
    if InitialAnimation then
        task.spawn(function()
            AnimationController:PlayAnimation(ANIMATION_FUNCTIONS[InitialAnimation])
        end)
    end

    --Connect clearing the animation controller.
    while Tool.Parent == Character do
        Tool.AncestryChanged:Wait()
    end
    AnimationController:Destroy()
    if PlayerAnimators[Player] == AnimationController then
        PlayerAnimators[Player] = nil
    end
end



--Connect displaying trails.
RemotesContainer:WaitForChild("DisplayTrail").OnClientEvent:Connect(function(StartAttachment: Attachment, EndPosition: Vector3)
    local StartPosition = StartAttachment.WorldPosition
    local Distance = (EndPosition - StartPosition).Magnitude

    --Create the trail.
    local Trail = Instance.new("Part")
    Trail.CastShadow = false
    Trail.Color = Color3.new(1, 1, 1)
    Trail.Material = Enum.Material.SmoothPlastic
    Trail.Name = "Effect"
    Trail.Anchored = true
    Trail.CanCollide = false
    Trail.Size = Vector3.new(0.2, 0.2, 0.2)
    Trail.Transparency = 0.5
    Trail.CFrame = CFrame.new(StartPosition, EndPosition) * CFrame.new(0, 0, -Distance/2) * CFrame.Angles(math.pi/2, 0, 0)

    local TrailMesh = Instance.new("CylinderMesh")
    TrailMesh.Scale = Vector3.new(2, Distance * 5, 2)
    TrailMesh.Parent = Trail
    Trail.Parent = Workspace

    local Tool = StartAttachment.Parent and StartAttachment.Parent.Parent
    if Tool then
        local Configuration = Tool:FindFirstChild("Configuration")
        if Configuration then
            local Overrides = Configuration:FindFirstChild("Overrides")
            if Overrides then
                local TrailOverrides = Overrides:FindFirstChild("Trail")
                if TrailOverrides then
                    for _, Value in pairs(TrailOverrides:GetChildren()) do
                        if Value:IsA("ValueBase") then
                            Trail[Value.Name] = Value.Value
                        end
                    end
                end
            end
        end
    end

    --Hide and remove the trail.
    TweenService:Create(Trail, TweenInfo.new(2), {
        CFrame = Trail.CFrame + Vector3.new(2, -1, 1).Unit,
        Transparency = 1,
    }):Play()
    task.wait(2)
    Trail:Destroy()
end)

--Connect the disabled animations changing.
RailgunNoAnimationPlayersValue.Changed:Connect(function()
    RailgunNoAnimationPlayers = HttpService:JSONDecode(RailgunNoAnimationPlayersValue.Value)
end)

--Connect equipping players.
RemotesContainer:WaitForChild("EquipPlayer").OnClientEvent:Connect(EquipPlayer)

--Connect unequipping players.
RemotesContainer:WaitForChild("UnequipPlayer").OnClientEvent:Connect(function(Player: Player)
    if PlayerAnimators[Player] then
        PlayerAnimators[Player]:Destroy()
        PlayerAnimators[Player] = nil
    end
end)

--Connect playing animations.
RemotesContainer:WaitForChild("PlayAnimation").OnClientEvent:Connect(function(Player: Player, AnimationName: string)
    if PlayerAnimators[Player] then
        PlayerAnimators[Player]:PlayAnimation(ANIMATION_FUNCTIONS[AnimationName])
    end
end)

--Fetch the existing states.
for _,AnimationData in RemotesContainer:WaitForChild("GetPlayerAnimations"):InvokeServer() do
    local Player, LastAnimation = AnimationData[1], AnimationData[2]
    task.spawn(function()
        while not Player.Character do task.wait() end
        while not Player.Character:FindFirstChildOfClass("Humanoid") do task.wait() end
        EquipPlayer(Player, LastAnimation)
    end)
end

--Notify the server if the client is in VR.
if VRService.VREnabled then
    VRPlayerJoinedEvent:FireServer()
else
    VRService:GetPropertyChangedSignal("VREnabled"):Connect(function()
        VRPlayerJoinedEvent:FireServer()
    end)
end