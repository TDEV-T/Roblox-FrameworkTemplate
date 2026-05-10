--[[
	ExampleComponent (Fusion UI)
	A template for creating a reactive UI component using Fusion.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Assuming Fusion is installed via Wally/Packages
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local New = Fusion.New
local Value = Fusion.Value
local Computed = Fusion.Computed
local Children = Fusion.Children

return function(props)
	-- Define your state here
	local counter = Value(0)
	
	-- Define computed values
	local labelText = Computed(function()
		return "Count: " .. tostring(counter:get())
	end)

	-- Return the UI element
	return New "ScreenGui" {
		Name = "ExampleUI",
		
		[Children] = {
			New "TextButton" {
				Size = UDim2.fromOffset(200, 50),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Text = labelText,
				BackgroundColor3 = Color3.fromRGB(45, 45, 45),
				TextColor3 = Color3.new(1, 1, 1),
				
				[Fusion.OnEvent "Activated"] = function()
					counter:set(counter:get() + 1)
				end
			}
		}
	}
end
