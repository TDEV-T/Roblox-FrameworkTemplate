local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[[
	ExampleController
	A template for creating a new Controller on the Client.
]]

local ExampleController = {}
ExampleController.__index = ExampleController

-- Constructor: Called when the framework loads the controller
function ExampleController:new(framework)
	local controller = setmetatable({}, ExampleController)
	controller.framework = framework
	return controller
end

-- Init: Called after all controllers are required but before Start
function ExampleController:Init()
	-- Initialize client-side variables and references here
	print("[ExampleController] Initialized")
end

-- Start: Called after all controllers have been initialized
function ExampleController:Start()
	-- Handle UI interactions and client-side logic here
	print("[ExampleController] Started")
end

return ExampleController
