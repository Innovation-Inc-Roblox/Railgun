--[[
TheNexusAvenger

Controls the railgun on the server.
--]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
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



--Set up the server animation script.
if not ServerScriptService:FindFirstChild("RailgunAnimationStateScript") then
    local NewScript = script.Parent:WaitForChild("RailgunAnimationStateScript"):Clone()
    NewScript.Disabled = false
    NewScript.Parent = ServerScriptService
end

--Get the events.
local RailgunAnimationEvents = ReplicatedStorage:WaitForChild("RailgunAnimationEvents")
local RailgunAnimationEventsLocal = RailgunAnimationEvents:WaitForChild("Local")
local DisplayTrail = RailgunAnimationEvents:WaitForChild("DisplayTrail")
local EquipPlayer = RailgunAnimationEventsLocal:WaitForChild("EquipPlayer")
local UnequipPlayer = RailgunAnimationEventsLocal:WaitForChild("UnequipPlayer")
local PlayAnimation = RailgunAnimationEventsLocal:WaitForChild("PlayAnimation")



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
            local Rail = Instance.new("Part")
            Rail.BrickColor = BrickColor.new("Dark stone grey")
            Rail.Material = Enum.Material.Metal
            Rail.Name = "Rail"
            Rail.Size = Vector3.new(0.4, 0.6, 8)
            Rail.Friction = 1
            Debris:AddItem(Rail, 10)

            local Overrides = Configuration:FindFirstChild("Overrides")
            if Overrides then
                local TrailOverrides = Overrides:FindFirstChild("Rail")
                if TrailOverrides then
                    for _, Value in pairs(TrailOverrides:GetChildren()) do
                        if Value:IsA("ValueBase") then
                            Rail[Value.Name] = Value.Value
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
            local OnHitCallback = OnHitModule and require(OnHitModule)
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
                    CreatorTag = Instance.new("ObjectValue")
                    CreatorTag.Name = "creator"
                    CreatorTag.Value = Player
                    Debris:AddItem(CreatorTag, 2)
                    CreatorTag.Parent = HitHumanoid

                    --Damage the humanoid.
                    HitHumanoid:TakeDamage(GetConfigurableItem("Damage"))
                end

                --Move and weld the rail.
                local EndCFrame = CFrame.new(EndPosition,StartPosition) * CFrame.new(0,0,(math.random() * (Rail.Size.Z - 2)) - ((Rail.Size.Z - 2)/2))
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
                    for _, ConnectedPart in pairs(HitPart:GetConnectedParts(true)) do
                        if ConnectedPart.Anchored then
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
                Rail.Velocity = Direction * 300
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

            --Invoke the clients to draw a beam and reload.
            DisplayTrail:FireAllClients(RailEnd, EndPosition)
            PlayAnimation:Fire(Player, "FireAndReload")

            --Enable the tool.
            task.wait(GetConfigurableItem("ReloadTime"))
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
            PlayAnimation:Fire(Player, "LowerWeapon")
        else
            PlayAnimation:Fire(Player, "RaiseWeapon")
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
                EquipPlayer:Fire(Player, "LowerWeapon")
            else
                EquipPlayer:Fire(Player, "RaiseWeapon")
            end
            EquippedPlayer = Player
        end
    end
end)

--Connect tool unequiping.
Tool.Unequipped:Connect(function()
    if EquippedPlayer then
        UnequipPlayer:Fire(EquippedPlayer)
        EquippedPlayer = nil
    end
end)