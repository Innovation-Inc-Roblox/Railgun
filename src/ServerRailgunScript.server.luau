--Controls the railgun on the server.
--!strict

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local Tool = script.Parent
local Configuration = Tool:WaitForChild("Configuration")
local FireWeapon = Tool:WaitForChild("FireWeapon")
local LowerWeapon = Tool:WaitForChild("LowerWeapon")
local Handle = Tool:WaitForChild("Handle")
local RailEnd = Handle:WaitForChild("RailEnd")
local FireSound = Handle:WaitForChild("FireSound")
local ReloadSound = Handle:WaitForChild("ReloadSound")

local ToolHeldDown = false



--[[
Returns the value for a configurable item.
--]]
local function GetConfigurableItem(Name: string): any
    return Configuration:WaitForChild(Name).Value
end

--[[
Sets the animation of the railgun.
--]]
local function SetAnimation(Name: string): ()
    Tool:SetAttribute("LastRailgunAnimation", HttpService:JSONEncode({Name = Name, Time = tick()}))
end



--Set up the server animation script.
if not ServerScriptService:FindFirstChild("RailgunAnimationStateScript") then
    local NewScript = script.Parent:WaitForChild("RailgunAnimationStateScript"):Clone()
    NewScript.Disabled = false
    script.Parent:WaitForChild("NexusAppendage"):Clone().Parent = NewScript:WaitForChild("RailgunAnimationScript")
    NewScript.Parent = ServerScriptService
end

--Get the events.
local RailgunAnimationEvents = ReplicatedStorage:WaitForChild("RailgunAnimationEvents")
local DisplayTrail = RailgunAnimationEvents:WaitForChild("DisplayTrail")



--Connect firing the weapon.
FireWeapon.OnServerEvent:Connect(function(Player: Player, Direction: Vector3, HitPart: BasePart, EndPosition: Vector3)
    local Character = Tool.Parent
    if not ToolHeldDown and Tool.Enabled and Character and Player.Character == Character then
        local Head = Character:FindFirstChild("Head")
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if Head and Humanoid and Humanoid.Health > 0 then
            --Disable the tool.
            Tool.Enabled = false

            --Create the rail.
            local MaterialPhysics = PhysicalProperties.new(Enum.Material.Metal)
            local Rail = Instance.new("Part")
            Rail.BrickColor = BrickColor.new("Dark stone grey")
            Rail.Material = Enum.Material.Metal
            Rail.Name = "Rail"
            Rail.Size = Vector3.new(0.4, 0.6, 8)
            Rail.CustomPhysicalProperties = PhysicalProperties.new(MaterialPhysics.Density, MaterialPhysics.Elasticity, 1)
            Debris:AddItem(Rail, 10)

            local Overrides = Configuration:FindFirstChild("Overrides")
            if Overrides then
                local RailOverrides = Overrides:FindFirstChild("Rail")
                if RailOverrides then
                    for _, Value in RailOverrides:GetChildren() do
                        if Value:IsA("ValueBase") then
                            (Rail :: any)[Value.Name] = Value.Value
                        end
                    end
                end
            end

            local RailSound = Instance.new("Sound")
            RailSound.Volume = 1
            RailSound.SoundId = "http://www.roblox.com/asset/?id=77170993"
            RailSound.Parent = Rail

            --Move the rail.
            local StartPosition = RailEnd.WorldPosition
            local OnHitModule = Configuration:FindFirstChild("OnHit")
            local OnHitCallback = OnHitModule and require(OnHitModule) :: (Tool, BasePart, BasePart?, Humanoid?) -> ()
            if HitPart and HitPart.Parent then
                --Damage the hit character.
                local HitCharacter = HitPart.Parent
                local HitHumanoid = HitCharacter:FindFirstChildOfClass("Humanoid")
                local HitPlayer = Players:GetPlayerFromCharacter(HitCharacter)
                if HitHumanoid and HitHumanoid.Health > 0 and (not HitPlayer or GetConfigurableItem("AllowTeamKill") or Player.Neutral or HitPlayer.Neutral or Player.TeamColor ~= HitPlayer.TeamColor) then
                    --Clear the existing tag.
                    local CreatorTag = HitHumanoid:FindFirstChild("creator")
                    if CreatorTag then
                        CreatorTag:Destroy()
                    end

                    --Add the tag.
                    local NewCreatorTag = Instance.new("ObjectValue")
                    NewCreatorTag.Name = "creator"
                    NewCreatorTag.Value = Player
                    Debris:AddItem(NewCreatorTag, 2)
                    NewCreatorTag.Parent = HitHumanoid

                    --Damage the humanoid.
                    HitHumanoid:TakeDamage(GetConfigurableItem("Damage"))
                end

                --Move and weld the rail.
                local EndCFrame = CFrame.new(EndPosition, StartPosition) * CFrame.new(0,0,(math.random() * (Rail.Size.Z - 2)) - ((Rail.Size.Z - 2)/2))
                Rail.CFrame = EndCFrame

                local Weld = Instance.new("Weld")
                Weld.Part0 = HitPart
                Weld.Part1 = Rail
                Weld.C0 = HitPart.CFrame:Inverse() * EndCFrame
                Weld.C1 = EndCFrame:Inverse() * EndCFrame
                Weld.Parent = Rail
                Rail.Parent = Workspace

                --Set the velocity.
                if not HitPart.Anchored then
                    local AssemblyAnchored = false
                    for _, ConnectedPart in HitPart:GetConnectedParts(true) do
                        if (ConnectedPart :: BasePart).Anchored then
                            AssemblyAnchored = true
                            break
                        end
                    end
                    if not AssemblyAnchored then
                        HitPart.AssemblyLinearVelocity = HitPart.AssemblyLinearVelocity + (Direction * 50)
                    end
                end
                if OnHitCallback then OnHitCallback(Tool, Rail, HitPart, HitHumanoid) end
            else
                Rail.CFrame = CFrame.new(EndPosition, EndPosition + Direction)
                Rail.AssemblyLinearVelocity = Direction * 300
                Rail.Parent = Workspace
                if OnHitCallback then OnHitCallback(Tool, Rail) end
            end
            RailSound:Play()

            --Play the fire sound.
            FireSound:Play()

            --Play the reload sound.
            task.delay(0.1, function()
                ReloadSound.TimePosition = 1
                ReloadSound:Play()
            end)

            --Build the list of trail properties.
            --This is done on the server in case the railgun (and properties) haven't streamed in.
            local TrailProperties = {}
            local TrailOverrides = Overrides and Overrides:FindFirstChild("Trail")
            if TrailOverrides then
                for _, Value in TrailOverrides:GetChildren() do
                    if not Value:IsA("ValueBase") then continue end
                    TrailProperties[Value.Name] = (Value :: any).Value
                end
            end

            --Invoke the clients to draw a beam and reload.
            DisplayTrail:FireAllClients(RailEnd, RailEnd.WorldPosition, EndPosition, TrailProperties)
            SetAnimation("FireAndReload")

            --Enable the tool.
            local ReloadTime = GetConfigurableItem("ReloadTime")
            if ReloadTime > 0 then
                task.wait(ReloadTime)
            end
            Tool.Enabled = true
        end
    end
end)

--Connect holding down being toggled.
LowerWeapon.OnServerEvent:Connect(function(Player: Player)
    local Character = Tool.Parent
    if Character and Player.Character == Character then
        ToolHeldDown = not ToolHeldDown
        if ToolHeldDown then
            SetAnimation("LowerWeapon")
        else
            SetAnimation("RaiseWeapon")
        end
    end
end)

--Connect tool equiping.
local EquippedPlayer
Tool.Equipped:Connect(function()
    local Character = Tool.Parent
    if Character then
        local Player = Players:GetPlayerFromCharacter(Character)
        if Player then
            if ToolHeldDown then
                SetAnimation("LowerWeapon")
            else
                SetAnimation("RaiseWeapon")
            end
            EquippedPlayer = Player
        end
    end
end)

--Connect tool unequiping.
Tool.Unequipped:Connect(function()
    if EquippedPlayer then
        Tool:SetAttribute("LastRailgunAnimation", nil)
        EquippedPlayer = nil
    end
end)

--Add the animated railgun tag.
CollectionService:AddTag(Tool, "AnimatedRailgun")