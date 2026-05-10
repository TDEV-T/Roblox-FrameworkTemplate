local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local runs = game:GetService("RunService")

-- Directories

local config = RS.Configs
local dataFolder = RS.Data
local modules = RS.Modules
local serverServiceShared = RS.Service
local serverService = SSS.Modules.Server

-- External
local bytenetConfig = RS.Shared.Network.Network
local Network = require(bytenetConfig)
local Players = game:GetService("Players")

-- Shared Types/Enums
-- local enum = require(shared.Enum)
-- local types = require(shared.Types)

--=========================================================
-- Framework Object
--=========================================================
local frameworkServer = {
	cfg = {},
	data = {},
	modules = {},
	services = {},
	controllers = {},
	flags = {},
	networkRemotes = {},
}
frameworkServer.__index = frameworkServer

--=========================================================
-- Utility: Recursive module loader (for configs/data/modules)
--=========================================================
local function loadNestedModules(folder)
	local result = {}

	for _, obj in ipairs(folder:GetChildren()) do
		if obj:IsA("ModuleScript") then
			local ok, value = pcall(require, obj)
			if ok then
				result[obj.Name] = value
			else
				warn("⚠️ Failed loading:", obj:GetFullName(), value)
			end
		elseif obj:IsA("Folder") then
			result[obj.Name] = loadNestedModules(obj)
		end
	end

	return result
end

--=========================================================
-- Utility: Scan Services (Data & Regular) with Priority
--=========================================================
local function scanServices(folder)
	local list = {}

	if not folder then
		return list
	end

	local function scan(f)
		for _, obj in ipairs(f:GetChildren()) do
			if obj:IsA("ModuleScript") then
				table.insert(list, {
					Name = obj.Name,
					Object = obj,
					Priority = obj:GetAttribute("Priority") or 1,
				})
			elseif obj:IsA("Folder") then
				scan(obj)
			end
		end
	end

	scan(folder)

	table.sort(list, function(a, b)
		return a.Priority < b.Priority
	end)

	return list
end

--=========================================================
-- Utility: Instantiate services (call new() if exists)
--=========================================================
local function instantiate(list, container, framework)
	for _, entry in ipairs(list) do
		local ok, module = pcall(require, entry.Object)

		if not ok then
			warn(`[Framework] Failed to require {entry.Name}: {module}`)
			continue
		end

		local instance = module

		if typeof(module) == "table" and typeof(module.new) == "function" then
			instance = module:new(framework)
		end

		container[entry.Name] = instance
	end
end

--=========================================================
-- Utility: Call Init() or Start() on services/data
--=========================================================
local function runLifecycle(targetTable, methodName)
	for name, instance in pairs(targetTable) do
		local fn = instance[methodName]
		if typeof(fn) == "function" then
			local ok, err = pcall(fn, instance)
			if not ok then
				warn(`⚠️ [{methodName}] {name} failed:`, err)
			end
		end
	end
end

--=========================================================
-- Framework Initialization
--=========================================================
function frameworkServer:init()
	if self.flags.initialized then
		warn("⚠️ Framework already initialized on server.")
		return
	end
	self.flags.initialized = true

	-- Load configs, data, modules
	self.cfg = loadNestedModules(config)
	self.data = loadNestedModules(dataFolder)
	self.modules = loadNestedModules(modules)

	-- Load network remotes
	self.networkRemotes = require(bytenetConfig)

	-- Scan services
	local dataServiceList = scanServices(serverService:FindFirstChild("Data"))
	local serviceList = scanServices(serverService:FindFirstChild("Services"))
	local serviceList2 = scanServices(serverServiceShared)
	local controllerList = scanServices(serverService:FindFirstChild("Controllers"))

	table.move(serviceList2, 1, #serviceList2, #serviceList + 1, serviceList)

	-- Instantiate services
	instantiate(dataServiceList, self.data, self)
	instantiate(serviceList, self.services, self)
	instantiate(controllerList, self.controllers, self)

	-- Init Phase
	runLifecycle(self.data, "Init")
	runLifecycle(self.services, "Init")
	runLifecycle(self.controllers, "Init")

	-- Start Phase (ordered: Data → Services → Controllers)
	task.spawn(function()
		runLifecycle(self.data, "Start")
		runLifecycle(self.services, "Start")
		runLifecycle(self.controllers, "Start")

		-- Mark server as ready
		self.flags.serverReady = true
		RS:SetAttribute("ServerReady", true)

		-- Notify all existing clients that server is ready
		Network.Framework.packets.ServerReady.sendToAll({})
	end)

	-- Send ServerReady to players who join after server started
	Players.PlayerAdded:Connect(function(player)
		if self.flags.serverReady then
			task.defer(function()
				Network.Framework.packets.ServerReady.sendTo({}, player)
			end)
		end
	end)

	-- Print loaded services
	-- warn("------ [Framework Server] Loaded Services ------")
	for name in pairs(self.services) do
		-- print("  - " .. name)
	end
	-- warn("------ [Framework Server] Loaded Controllers ------")
	for name in pairs(self.controllers) do
		-- print("  - " .. name)
	end
	-- warn("------------------------------------------------")
end

--=========================================================
-- Return if not server
--=========================================================
if not runs:IsServer() then
	return nil
end

return frameworkServer
