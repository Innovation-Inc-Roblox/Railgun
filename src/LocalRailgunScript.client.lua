--[[
TheNexusAvenger

Fires rails on the client.
--]]

local GUN_ICON = "rbxasset://textures/GunCursor.png"
local GUN_RELOAD_ICON = "rbxasset://textures/GunWaitCursor.png"

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local Tool = script.Parent
local Handle = Tool:WaitForChild("Handle")
local RailEnd = Handle:WaitForChild("RailEnd")
local FireWeapon = Tool:WaitForChild("FireWeapon")
local LowerWeapon = Tool:WaitForChild("LowerWeapon")
local Configuration = Tool:WaitForChild("Configuration")
local FireBackAtPlayerWhenThroughWallValue = Configuration:WaitForChild("FireBackAtPlayerWhenThroughWall")
local FullAutomaticValue = Configuration:WaitForChild("FullAutomatic")
local RailgunNoAnimationPlayersValue = ReplicatedStorage:WaitForChild("RailgunNoAnimationPlayers")
local RailgunNoAnimationPlayers = HttpService:JSONDecode(RailgunNoAnimationPlayersValue.Value)

local DB = true
local Equipped = false
local HoldDownStartTime = nil
local WeaponLowered = false
local InputEvents = {}



--[[
Returns if a valid part was hit.
--]]
local function ValidPartHit(Part: BasePart): boolean
    --Return if the part is invalid.
    if Part and Part.Parent and not Part.Parent:FindFirstChildOfClass("Humanoid") then
        local PartName = string.lower(Part.Name)
        if Part:IsDescendantOf(Tool.Parent) or Part.Transparency > 0.8 or not Part.CanCollide or PartName == "handle" or PartName == "effect" or PartName == "bullet" or PartName == "laser" or PartName == "water" or PartName == "rail" then
            return false
        end
    end

    --Return false (valid).
    return true
end

--[[
Ray casts from a point and direction until a specific
length or a collidable part has been hit.
--]]
local function RayCast(StartPosition: Vector3, Direction: Vector3, MaxLength: number): (BasePart, Vector3)
	--Cast rays until a valid part is reached.
    local EndPosition = StartPosition + (Direction * MaxLength)
    local IgnoreList = {Tool.Parent}
	local RaycastResult = nil
	local RaycastParameters = RaycastParams.new()
	RaycastParameters.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParameters.FilterDescendantsInstances = IgnoreList
	RaycastParameters.IgnoreWater = true
	repeat
		--Perform the raycast.
		RaycastResult = Workspace:Raycast(StartPosition, EndPosition - StartPosition, RaycastParameters)
		if not RaycastResult then
			break
		end
		if not RaycastResult.Instance then
			break
		end

		--Return the part and position if the part is valid.
		local HitPart = RaycastResult.Instance
		if ValidPartHit(HitPart) then
			return HitPart, RaycastResult.Position
		end

		--Add the hit to the ignore list and allow it to retry.
		table.insert(IgnoreList, HitPart)
		RaycastParameters.FilterDescendantsInstances = IgnoreList
	until RaycastResult == nil

	--Return the end position and no part.
	return nil, EndPosition
end

--[[
Connects sets up the tool for equipping.
--]]
local function OnEquip(Mouse: Mouse): nil
    Mouse.Icon = GUN_ICON
    Equipped = true

    --[[
    Fires a rail.
    --]]
    local function FireRail(): nil
        --Check if the character is intact.
        local Character = Tool.Parent
        if Character and not WeaponLowered then
            local Head = Character:FindFirstChild("Head")
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")
            if Head and Humanoid and Humanoid.Health > 0 then
                --Show the reload icon.
                Mouse.Icon = GUN_RELOAD_ICON
                Tool.Enabled = false

                --Aim the gun.
                local EndPosition = nil
                if RailgunNoAnimationPlayers[tostring(Players.LocalPlayer.UserId)] then
                    EndPosition = (RailEnd.WorldCFrame * CFrame.new(0, 0, -10000)).Position
                else
                    local Camera = Workspace.CurrentCamera
                    local MouseRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y, 10000)
                    local RawEndPosition = MouseRay.Origin + MouseRay.Direction
                    local _, NewEndPosition = RayCast(Camera.CFrame.p, (RawEndPosition - Camera.CFrame.p).Unit, 10000)
                    EndPosition = NewEndPosition
                end
                local StartPosition = RailEnd.WorldPosition
                local Direction = (EndPosition - StartPosition).Unit
                local HitPart,HitEndPosition = RayCast(StartPosition, Direction, 10000)

                --Fire the gun backwards if it is through a wall.
                if FireBackAtPlayerWhenThroughWallValue.Value then
                    local GunEndPosition = (Handle.CFrame * CFrame.new(RailEnd.Position) * CFrame.new(0, 0, Handle.Size.Z - (RailEnd.Position.Z + (Handle.Size.Z / 2)))).Position
                    local GunTargetRelative = (GunEndPosition - StartPosition)
                    local BackPart,BackPosition = RayCast(StartPosition, GunTargetRelative.Unit, GunTargetRelative.Magnitude)
                    if BackPart then
                        HitPart,HitEndPosition = BackPart, BackPosition
                    end
                end

                --Fire the gun on the server.
                FireWeapon:FireServer(Direction, HitPart, HitEndPosition, StartPosition)

                --Wait for the tool to be enabled.
                while not Tool.Enabled do
                    Tool.Changed:Wait()
                end
                if Equipped then
                    Mouse.Icon = GUN_ICON
                end
            end
        end
    end

    --[[
    Starts firing the railgun.
    --]]
    local function StartFiring(): nil
        if HoldDownStartTime then return end
        if WeaponLowered then return end

        --Fire a single rail or start the automatic firing.
        local CurrentTime = tick()
        HoldDownStartTime = CurrentTime
        if FullAutomaticValue.Value and not WeaponLowered then
            while HoldDownStartTime == CurrentTime do
                FireRail()
            end
        else
            FireRail()
        end
    end

    --[[
    Stops firing the railgun.
    --]]
    local function StopFiring(): nil
        HoldDownStartTime = nil
    end

    --Connect the input events.
    table.insert(InputEvents, UserInputService.InputBegan:Connect(function(Input: InputObject, Processed: boolean)
        if Processed then return end
        if DB then
            DB = false
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                StartFiring()
            elseif Input.KeyCode == Enum.KeyCode.Q then
                --Toggle the weapon being lowered.
                WeaponLowered = not WeaponLowered
                LowerWeapon:FireServer()
            end
            wait()
            DB = true
        end
    end))

    table.insert(InputEvents,UserInputService.InputEnded:Connect(function(Input: InputObject)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            StopFiring()
        end
    end))

    table.insert(InputEvents,UserInputService.InputChanged:Connect(function(Input: InputObject)
        if Input.KeyCode == Enum.KeyCode.ButtonR2 then
            if Input.Position.Z > 0.7 then
                StartFiring()
            else
                StopFiring()
            end
        end
    end))

    --Set the icon to reloading if the tool is disabled and wait for it to be enabled.
    if not Tool.Enabled then
        Mouse.Icon = GUN_RELOAD_ICON
        while not Tool.Enabled do
            Tool.Changed:Wait()
        end
        if Equipped then
            Mouse.Icon = GUN_ICON
        end
    end
end

--[[
Cleans up the tool for unequipping.
--]]
local function OnUnequip(): nil
    Equipped = false
    HoldDownStartTime = nil

    --Disconnect the events.
    for _,Event in pairs(InputEvents) do
        Event:Disconnect()
    end
    InputEvents = {}
end



--Connect the disabled animations changing.
RailgunNoAnimationPlayersValue.Changed:Connect(function()
    RailgunNoAnimationPlayers = HttpService:JSONDecode(RailgunNoAnimationPlayersValue.Value)
end)

--Connect the events.
Tool.Equipped:Connect(OnEquip)
Tool.Unequipped:Connect(OnUnequip)