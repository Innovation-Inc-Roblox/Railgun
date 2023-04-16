--[[
TheNexusAvenger

Stores the state of the railguns on the server.
--]]
--!strict

local SCRIPTS_TO_REPLICATE = {
    script:WaitForChild("RailgunAnimationScript"),
    script:WaitForChild("RailgunNexusVRCharacterModelDetection"),
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")



--Create the remote objects.
local RailgunAnimationEvents = Instance.new("Folder")
RailgunAnimationEvents.Name = "RailgunAnimationEvents"
RailgunAnimationEvents.Parent = ReplicatedStorage

local DisplayTrail = Instance.new("RemoteEvent")
DisplayTrail.Name = "DisplayTrail"
DisplayTrail.Parent = RailgunAnimationEvents

local EquipPlayer = Instance.new("RemoteEvent")
EquipPlayer.Name = "EquipPlayer"
EquipPlayer.Parent = RailgunAnimationEvents

local UnequipPlayer = Instance.new("RemoteEvent")
UnequipPlayer.Name = "UnequipPlayer"
UnequipPlayer.Parent = RailgunAnimationEvents

local PlayAnimation = Instance.new("RemoteEvent")
PlayAnimation.Name = "PlayAnimation"
PlayAnimation.Parent = RailgunAnimationEvents

local GetPlayerAnimations = Instance.new("RemoteFunction")
GetPlayerAnimations.Name = "GetPlayerAnimations"
GetPlayerAnimations.Parent = RailgunAnimationEvents

--Create the local objects.
local RailgunAnimationEventsLocal = Instance.new("Folder")
RailgunAnimationEventsLocal.Name = "Local"
RailgunAnimationEventsLocal.Parent = RailgunAnimationEvents

local EquipPlayerLocal = Instance.new("BindableEvent")
EquipPlayerLocal.Name = "EquipPlayer"
EquipPlayerLocal.Parent = RailgunAnimationEventsLocal

local UnequipPlayerLocal = Instance.new("BindableEvent")
UnequipPlayerLocal.Name = "UnequipPlayer"
UnequipPlayerLocal.Parent = RailgunAnimationEventsLocal

local PlayAnimationLocal = Instance.new("BindableEvent")
PlayAnimationLocal.Name = "PlayAnimation"
PlayAnimationLocal.Parent = RailgunAnimationEventsLocal

--Add the animation script.
for _, Script in SCRIPTS_TO_REPLICATE do
    local ClonedRailgunAnimationScript = Script:Clone()
    ClonedRailgunAnimationScript.Disabled = false
    ClonedRailgunAnimationScript.Parent = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

    for _, Player in Players:GetPlayers() do
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = Script.Name.."Container"
        ScreenGui.ResetOnSpawn = false

        local PlayerClonedRailgunAnimationScript = ClonedRailgunAnimationScript:Clone()
        PlayerClonedRailgunAnimationScript.Disabled = false
        PlayerClonedRailgunAnimationScript.Parent = ScreenGui
        ScreenGui.Parent = Player:FindFirstChild("PlayerGui")
    end
end

--Connect the local events.
local LastPlayerAnimations = {}
EquipPlayerLocal.Event:Connect(function(Player: Player, InitialAnimation: string)
    EquipPlayer:FireAllClients(Player,InitialAnimation)
    LastPlayerAnimations[Player] = {Character = Player.Character, Animation = InitialAnimation}
end)

UnequipPlayerLocal.Event:Connect(function(Player: Player)
    UnequipPlayer:FireAllClients(Player)
    LastPlayerAnimations[Player] = nil
end)

PlayAnimationLocal.Event:Connect(function(Player: Player, Animation: string)
    PlayAnimation:FireAllClients(Player, Animation)
    if LastPlayerAnimations[Player] then
        LastPlayerAnimations[Player].Animation = Animation
    end
end)

--Connect the remote objects.
function GetPlayerAnimations.OnServerInvoke()
    --Create the list of animations.
    local Animations = {}
    for Player, Data in LastPlayerAnimations do
        if Player.Parent and Player.Character == Data.Character then
            table.insert(Animations, {Player = Player, Animation = Data.Animation})
        end
    end

    --Return the animations.
    return Animations
end