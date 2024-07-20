--[[
TheNexusAvenger

Stores the state of the railguns on the server.
--]]
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VRService = game:GetService("VRService")

local VRAnimationsDetected = false
local VRPlayers = {}



--Create the remote objects.
local RailgunAnimationEvents = Instance.new("Folder")
RailgunAnimationEvents.Name = "RailgunAnimationEvents"
RailgunAnimationEvents.Parent = ReplicatedStorage

local DisplayTrail = Instance.new("RemoteEvent")
DisplayTrail.Name = "DisplayTrail"
DisplayTrail.Parent = RailgunAnimationEvents

local VRPlayerJoined = Instance.new("RemoteEvent")
VRPlayerJoined.Name = "VRPlayerJoined"
VRPlayerJoined.Parent = RailgunAnimationEvents

local VRPlayersValue = Instance.new("StringValue")
VRPlayersValue.Name = "RailgunNoAnimationPlayers"
VRPlayersValue.Value = "{}"
VRPlayersValue.Parent = RailgunAnimationEvents



--[[
Connects VR animations being loaded.
--]]
local function ConnectVRAnimations(): ()
    --Return if Nexus VR Character Model is already connected or doesn't exist.
    if VRAnimationsDetected then return end
    local NexusVRCharacterModel = ReplicatedStorage:FindFirstChild("NexusVRCharacterModel")
    if not NexusVRCharacterModel and not VRService.AvatarGestures then return end
    VRAnimationsDetected = true

    --Set the list of VR players.
    --The list remains empty until either Nexus VR Character Model or AvatarGestures is detected.
    VRPlayersValue.Value = HttpService:JSONEncode(VRPlayers)
end



--Add the animation script.
local ClonedRailgunAnimationScript = script:WaitForChild("RailgunAnimationScript"):Clone()
ClonedRailgunAnimationScript.Disabled = false
ClonedRailgunAnimationScript.Parent = ReplicatedStorage

--Connect players declaring they are using VR.
VRPlayerJoined.OnServerEvent:Connect(function(Player: Player)
    --Return if the player is already added.
    if VRPlayers[tostring(Player.UserId)] then return end

    --Add the player.
    VRPlayers[tostring(Player.UserId)] = true
    if VRAnimationsDetected then
        VRPlayersValue.Value = HttpService:JSONEncode(VRPlayers)
    end
end)

--Connect players leaving.
Players.PlayerRemoving:Connect(function(Player: Player)
    --Return if the player is not added.
    if not VRPlayers[tostring(Player.UserId)] then return end

    --Remove the player.
    VRPlayers[tostring(Player.UserId)] = nil
    if VRAnimationsDetected then
        VRPlayersValue.Value = HttpService:JSONEncode(VRPlayers)
    end
end)

--Connect VR players joining.
ConnectVRAnimations()
ReplicatedStorage.ChildAdded:Connect(ConnectVRAnimations)
VRService:GetPropertyChangedSignal("AvatarGestures"):Connect(ConnectVRAnimations)