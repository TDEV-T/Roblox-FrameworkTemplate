# Roblox Service-Controller Framework Template

โครงสร้างเริ่มต้นสำหรับโปรเจกต์ Roblox ที่ใช้รูปแบบ Service-Controller และ Fusion UI

## 📂 โครงสร้างโฟลเดอร์

- **`src/ReplicatedStorage/Framework`**: หัวใจหลักของระบบ (Shared Bootstrapper)
- **`src/ServerScriptService/Services`**: สำหรับใส่ Logic ฝั่ง Server (Singleton Services)
- **`src/ReplicatedStorage/Client/Controllers`**: สำหรับใส่ Logic ฝั่ง Client
- **`src/ReplicatedStorage/Client/Components`**: สำหรับเก็บ UI Components (Fusion)

## 🚀 วิธีเริ่มต้นใช้งาน

1. ติดตั้ง **Rojo** เพื่อ Sync โค้ดเข้า Roblox Studio
2. Framework จะทำการโหลดทุกไฟล์ใน `Services` และ `Controllers` อัตโนมัติ
3. ทุก Module จะต้องมีฟังก์ชัน `:new(framework)` และอาจมี `:Init()` กับ `:Start()`

### ตัวอย่างการสร้าง Service ใหม่:

```lua
local MyService = {}
MyService.__index = MyService

function MyService:new(framework)
    local self = setmetatable({}, MyService)
    self.framework = framework
    return self
end

function MyService:Init()
    -- โหลดข้อมูลเบื้องต้น
end

function MyService:Start()
    -- เริ่มการทำงานหลัก
end

return MyService
```

## 🛠️ เครื่องมือที่แนะนำ

- **Fusion**: สำหรับสร้าง UI แบบ Reactive
- **ProfileService**: สำหรับจัดการ DataStore
- **ReplicaService**: สำหรับการ Sync ข้อมูล Server -> Client
