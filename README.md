# Roblox Service-Controller Framework Template

Base Template Roblox Service-Controller and Fusion UI

## Structure

- **`src/ReplicatedStorage/Framework`**: Core System (Shared Bootstrapper)
- **`src/ServerScriptService/Services`**: Server Logic (Singleton Services)
- **`src/ReplicatedStorage/Client/Controllers`**: Client Logic
- **`src/ReplicatedStorage/Client/Components`**: UI Components (Fusion)

### Example Create New Service:

```lua
local MyService = {}
MyService.__index = MyService

function MyService:new(framework)
    local self = setmetatable({}, MyService)
    self.framework = framework
    return self
end

function MyService:Init()
    -- Load Initial Data
end

function MyService:Start()
    -- Start Main Logic
end

return MyService
```

## Tools

- **Fusion**: สำหรับสร้าง UI แบบ Reactive
- **ProfileService**: สำหรับจัดการ DataStore
- **ReplicaService**: สำหรับการ Sync ข้อมูล Server -> Client
