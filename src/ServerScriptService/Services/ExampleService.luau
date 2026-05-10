local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ExampleService = {}
ExampleService.__index = ExampleService

function ExampleService:new(framework)
	local service = setmetatable({}, ExampleService)
	service.framework = framework
	return service
end

function ExampleService:Init()
	print("[ExampleService] Initialized")
end

function ExampleService:Start()
	print("[ExampleService] Started")
end

return ExampleService
