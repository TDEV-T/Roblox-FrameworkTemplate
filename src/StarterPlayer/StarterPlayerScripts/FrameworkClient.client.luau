print("[FrameworkClient] Script started")
local RS = game:GetService("ReplicatedStorage")
local framework = require(RS.Framework)
print("[FrameworkClient] Framework required")
local client = framework.client

client:init()
print("[FrameworkClient] client:init() called")
