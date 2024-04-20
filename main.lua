local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local GetChildren = game.GetChildren
local GetPlayers = Players.GetPlayers
local WorldToScreen = Camera.WorldToScreenPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local FindFirstChild = game.FindFirstChild
local GetMouseLocation = UserInputService.GetMouseLocation

local function GetScreenPosition(Vector)
    local ScreenPosition, OnScreen = WorldToScreen(Camera, Vector)
    return Vector2.new(ScreenPosition.X, ScreenPosition.Y), OnScreen
end

local function IsPlayerVisible(Player)
    local Target = Player.Character
    local Character = LocalPlayer.Character
    
    if not (Target or Character) then return end 
    
    local Part = FindFirstChild(Target, "Head")
    
    if not Part then return end 
    
    local CastPoints, IgnoreList = {Part.Position, Character, Target}, {Character, Target}
    local ObscuringObjects = #GetPartsObscuringTarget(Camera, CastPoints, IgnoreList)
    
    return ((ObscuringObjects == 0 and true) or (ObscuringObjects > 0 and false))
end

local function GetClosest()
    local Minimum, Closest = math.huge
    local MouseLocation = GetMouseLocation(UserInputService)

    for _, Player in next, GetPlayers(Players) do
        if Player == LocalPlayer then continue end
		if Player.Team == LocalPlayer.Team then continue end

        local Character = Player.Character
        if not Character then continue end

		if not IsPlayerVisible(Player) then continue end

        local Part = FindFirstChild(Character, "Head")
        local Humanoid = FindFirstChild(Character, "Humanoid")
        if not Part or not Humanoid or Humanoid and Humanoid.Health <= 0 then continue end

        local ScreenPosition, OnScreen = GetScreenPosition(Part.Position)

        local Distance = (MouseLocation - ScreenPosition).Magnitude

        if Distance <= Minimum and OnScreen then
            Closest = Character.Head
            Minimum = Distance
        end
    end

    return Closest
end

local __namecall
__namecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    local self = Arguments[1]
	local Main = Arguments[2]

    if self == workspace and not checkcaller() then
		local Hit = GetClosest()

		if Hit then
	        if Method == "FindPartOnRayWithIgnoreList" or Method == "FindPartOnRayWithWhitelist" or Method == "FindPartOnRay" or Method == "findPartOnRay" then
                local Origin = Main.Origin
                local Direction = (Hit.Position - Origin).Unit * 15000
                Arguments[2] = Ray.new(Origin, Direction)

                return __namecall(unpack(Arguments))
	        elseif Method == "Raycast" then
                Arguments[3] = (Hit.Position - Main).Unit * 15000

                return __namecall(unpack(Arguments))
	        end
		end
    end

    return __namecall(...)
end))

local __index = nil 
__index = hookmetamethod(game, "__index", newcclosure(function(self, Index)
    if self == Mouse and not checkcaller() then
        local Hit = GetClosest()

        if Hit then
	        if Index == "Target" or Index == "target" then 
	            return Hit
	        elseif Index == "Hit" or Index == "hit" then 
	            return Hit.CFrame
	        elseif Index == "UnitRay" then 
	            return Ray.new(self.Origin, (self.Hit - self.Origin).Unit)
			else
				 local ScreenPosition, OnScreen = GetScreenPosition(Hit.Position)

				if Index == "X" or Index == "x" then 
		            return ScreenPosition.X 
		        elseif Index == "Y" or Index == "y" then 
		            return ScreenPosition.Y 
		        end
			end
		end
    end

    return __index(self, Index)
end))
