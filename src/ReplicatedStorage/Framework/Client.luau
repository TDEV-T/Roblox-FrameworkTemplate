local RS = game:GetService("ReplicatedStorage")

local config = RS.Configs
local dataFolder = RS.Data

local Client = RS.Client
local componentsFolder = Client:FindFirstChild("Components")
local controllersFolder = Client:FindFirstChild("Controllers")

local bytenetConfig = RS.Shared.Network.Network

--=========================================================
-- Framework Object
--=========================================================
local frameworkClient = {
	cfg = {},
	data = {},
	components = {},
	controllers = {},
	modules = {},
	flags = {},
	networkRemotes = {},
}
frameworkClient.__index = frameworkClient

--=========================================================
-- Utility: Load nested config/data (recursive)
--=========================================================
local function loadNestedModules(folder)
	local result = {}

	for _, obj in ipairs(folder:GetChildren()) do
		if obj:IsA("ModuleScript") then
			local ok, value = pcall(require, obj)
			result[obj.Name] = ok and value or warn("⚠️ Failed:", obj:GetFullName(), value)
		elseif obj:IsA("Folder") then
			result[obj.Name] = loadNestedModules(obj)
		end
	end

	return result
end

--=========================================================
-- Utility: Scan folder for Modules (Components/Controllers)
--=========================================================
local function scanModules(folder)
	local list = {}
	if not folder then
		return list
	end

	local function scan(f)
		for _, obj in ipairs(f:GetChildren()) do
			if obj:IsA("ModuleScript") then
				-- print("[Framework] Found module:", obj.Name, "in", f.Name)
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
-- Utility: Instantiate (new() if exists)
--=========================================================

local function instantiate(list, container, framework)
	for _, entry in ipairs(list) do
		local ok, module = pcall(require, entry.Object)

		if not ok then
			warn(`[Framework] Failed to require {entry.Name}: {module}`)
			if entry.Name == "BiomeSelectorUI" then
				warn(
					"[Framework] BiomeSelectorUI failed to load — Sidebar 'Biome' button will not work. Check Packages.fusion and script syntax."
				)
			end
			continue
		end

		local instance = module

		if typeof(module) == "table" and typeof(module.new) == "function" then
			instance = module:new(framework)
		end

		-- print("[Framework] Instantiating controller/component:", entry.Name)
		container[entry.Name] = instance
	end
end

--=========================================================
-- Utility: Run Init() or Start()
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
-- Initialize Framework
--=========================================================
function frameworkClient:init()
	warn("[Framework] Client Init started")
	if self.flags.initialized then
		warn("⚠️ FrameworkClient already initialized")
		return
	end
	self.flags.initialized = true

	-- Shared CFG/DATA
	self.cfg = loadNestedModules(config)
	self.data = loadNestedModules(dataFolder)
	self.networkRemotes = require(bytenetConfig)

	-- Scan component & controller modules
	local componentList = scanModules(componentsFolder)
	local controllerList = scanModules(controllersFolder)

	-- Instantiate
	instantiate(componentList, self.components, self)
	instantiate(controllerList, self.controllers, self)

	-- Init Phase
	runLifecycle(self.components, "Init")
	runLifecycle(self.controllers, "Init")

	-- Start Phase (ordered: Wait for Server → Controllers → Components)
	task.spawn(function()
		-- Wait for Server to signal it's ready
		if not RS:GetAttribute("ServerReady") then
			RS:GetAttributeChangedSignal("ServerReady"):Wait()
		end

		-- Wait for Loading Screen to complete (Prevent UI Overlap)
		local RunService = game:GetService("RunService")
		local ReplicatedFirst = game:GetService("ReplicatedFirst")
		if not RunService:IsStudio() and not ReplicatedFirst:GetAttribute("LoadingComplete") then
			ReplicatedFirst:GetAttributeChangedSignal("LoadingComplete"):Wait()
		end

		runLifecycle(self.controllers, "Start")
		runLifecycle(self.components, "Start")
	end)

	-- Debug Logs
	-- warn("------ [Framework Client] Components Loaded ------")
	for name in pairs(self.components) do
		-- print("  -", name)
	end

	-- warn("------ [Framework Client] Controllers Loaded ------")
	for name in pairs(self.controllers) do
		-- print("  -", name)
	end
end

return frameworkClient
