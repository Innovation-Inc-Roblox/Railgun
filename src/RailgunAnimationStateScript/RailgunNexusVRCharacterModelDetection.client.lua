--[[
TheNexusAvenger

Handles detection of VR players.
Run as a separate script in case third-party VR implementations
want to use it.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local NexusVRCharacterModelDetected = false
local VRPlayers = {}

--Create the VR players storage.
if not ReplicatedStorage:FindFirstChild("RailgunVRPlayers") then
    local VRPlayersValue = Instance.new("StringValue")
    VRPlayersValue.Name = "RailgunNoAnimationPlayers"
    VRPlayersValue.Value = "{}"
    VRPlayersValue.Parent = ReplicatedStorage
end
VRPlayersValue = ReplicatedStorage:WaitForChild("RailgunNoAnimationPlayers")



--[[
Connects Nexus VR Character Model.
--]]
local function ConnectNexusVRCharacterModel(): ()
    --Return if Nexus VR Character Model is already connected or doesn't exist.
    if NexusVRCharacterModelDetected then return end
    local NexusVRCharacterModel = ReplicatedStorage:FindFirstChild("NexusVRCharacterModel")
    if not NexusVRCharacterModel then return end
    NexusVRCharacterModelDetected = true

    --Add the local player if VR is enabled.
    if UserInputService.VREnabled then
        VRPlayers = HttpService:JSONDecode(VRPlayersValue.Value)
        VRPlayers[tostring(Players.LocalPlayer.UserId)] = true
        VRPlayersValue.Value = HttpService:JSONEncode(VRPlayers)
    end

    --Connect the UpdateInputs event. VR players send events over this event.
    NexusVRCharacterModel:WaitForChild("UpdateInputs").OnClientEvent:Connect(function(Player: Player)
        --Return if the player is already added.
        if VRPlayers[tostring(Player.UserId)] then return end

        --Reload the player ids, add the player id, and save the player ids.
        --This is done in case the value is touched externally.
        VRPlayers = HttpService:JSONDecode(VRPlayersValue.Value)
        VRPlayers[tostring(Player.UserId)] = true
        VRPlayersValue.Value = HttpService:JSONEncode(VRPlayers)
    end)

    --Connect players leaving.
    Players.PlayerRemoving:Connect(function(Player: Player)
        --Return if the player is not added.
        if not VRPlayers[tostring(Player.UserId)] then return end

        --Reload the player ids, remove the player id, and save the player ids.
        --This is done in case the value is touched externally.
        VRPlayers = HttpService:JSONDecode(VRPlayersValue.Value)
        VRPlayers[tostring(Player.UserId)] = nil
        VRPlayersValue.Value = HttpService:JSONEncode(VRPlayers)
    end)
end



--Set up Nexus VR Character Model.
ConnectNexusVRCharacterModel()
ReplicatedStorage.ChildAdded:Connect(ConnectNexusVRCharacterModel)