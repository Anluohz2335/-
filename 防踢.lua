-- ==============================================
-- 🔥 终极防踢 · 前置绕过整合版
-- 先静默绕过 Adonis，再加载 UI 和其他功能
-- ==============================================

-- ==============================================
-- 🛡️ 第一阶段：静默前置绕过（UI加载前执行）
-- ==============================================
local function preBypass()
    print("[前置绕过] 正在静默绕过 Adonis...")
    
    -- 1. 提升权限
    pcall(function()
        if setthreadidentity then
            setthreadidentity(7)
        elseif setidentity then
            setidentity(7)
        end
    end)
    
    -- 2. 伪装 debug.info（最关键）
    pcall(function()
        local oldDebug = debug.info
        debug.info = function(...)
            local args = {...}
            local func, what = args[1], args[2]
            if what == "s" then return "[C]" end
            if what == "n" then return "unnamed" end
            if what == "f" then return func end
            return oldDebug(...)
        end
    end)
    
    -- 3. 干扰计时检测
    pcall(function()
        local oldClock = os.clock
        os.clock = function() return oldClock() + 0.00001 end
        local oldTick = tick
        tick = function() return oldTick() + 0.00001 end
    end)
    
    -- 4. 快速扫描并废掉 Detected 函数
    pcall(function()
        if getgc and hookfunction then
            for _, v in ipairs(getgc(true)) do
                if typeof(v) == "table" then
                    local Detected = rawget(v, "Detected")
                    if typeof(Detected) == "function" then
                        hookfunction(Detected, function() return true end)
                        print("[前置绕过] 已钝化 Detected 函数")
                        break
                    end
                end
            end
        end
    end)
    
    -- 5. 快速屏蔽可疑远程事件
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        for _, v in ipairs(rs:GetDescendants()) do
            if v:IsA("RemoteEvent") and v.Name:lower():find("adonis") then
                local oldFire = v.FireServer
                v.FireServer = function(self, ...) return nil end
            end
        end
    end)
    
    print("[前置绕过] 完成，正在加载主界面...")
end

-- 立即执行前置绕过
preBypass()

-- 短暂等待绕过生效
task.wait(0.3)

-- ==============================================
-- 🔥 第二阶段：加载 UI 和主功能
-- ==============================================
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()

local Window = Rayfield:CreateWindow({
   Name = "终极防踢系统",
   LoadingTitle = "加载中",
   LoadingSubtitle = "e",
   ConfigurationSaving = {Enabled = true, FolderName = "AntiKick"},
   KeySystem = false
})

local Tab = Window:CreateTab("高检测专用", "shield")

-- ==============================================
-- 📊 状态管理
-- ==============================================
local state = {
    MasterEnabled = false,
    JitterEnabled = false,
    AntiAfkEnabled = false,
    AdonisBypass = true,
    interceptCount = 0,
    isTeleporting = false,
    lastBeat = os.clock()
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local jitterCon, afkCon, networkCon, steppedCon

-- 通知函数
local function notify(title, text, duration)
    duration = duration or 3
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration
        })
    end)
end

-- ==============================================
-- 🛡️ 核心功能
-- ==============================================
local function installCoreFeatures()
    -- 1. Hook Namecall拦截
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(Self, ...)
            local method = getnamecallmethod()
            if method == "Kick" and Self == LocalPlayer and state.MasterEnabled then
                state.interceptCount += 1
                for i = 1, 3 do
                    notify("🛡️ 拦截成功", "已阻止踢出 #" .. state.interceptCount, 3)
                    task.wait(0.2)
                end
                return nil
            end
            return old(Self, ...)
        end)
        setreadonly(mt, true)
    end)

    -- 2. 角色重载保险
    LocalPlayer.CharacterRemoving:Connect(function()
        if state.MasterEnabled and not state.isTeleporting then
            task.wait(0.1)
            pcall(function()
                LocalPlayer:LoadCharacter()
                notify("🔄 角色重载", "角色已自动恢复", 2)
            end)
        end
    end)

    -- 3. 隐形微移
    steppedCon = RunService.Stepped:Connect(function()
        if not state.MasterEnabled or state.isTeleporting then return end
        pcall(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local root = char.HumanoidRootPart
                root.CFrame = root.CFrame + Vector3.new(math.random(-5,5)/100, 0, math.random(-5,5)/100)
            end
        end)
    end)

    -- 4. Teleport防护
    LocalPlayer.OnTeleport:Connect(function(State)
        if State == Enum.TeleportState.Started then
            state.isTeleporting = true
            if state.MasterEnabled then
                task.wait(0.1)
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                    notify("🌐 传送防护", "已阻止传送踢出", 3)
                end)
            end
        elseif State == Enum.TeleportState.Finished or State == Enum.TeleportState.Failed then
            state.isTeleporting = false
        end
    end)
end

-- ==============================================
-- ✅ 函数覆盖
-- ==============================================
local function installFunctionOverrides()
    pcall(function()
        local oldKick = LocalPlayer.Kick
        LocalPlayer.Kick = function(self, ...)
            if state.MasterEnabled then
                state.interceptCount += 1
                notify("🛡️ 函数拦截", "Kick已阻止", 2)
                return nil
            end
            return oldKick(self, ...)
        end
    end)

    pcall(function()
        if LocalPlayer.Destroy then
            local oldDestroy = LocalPlayer.Destroy
            LocalPlayer.Destroy = function(self, ...)
                if state.MasterEnabled then
                    state.interceptCount += 1
                    return nil
                end
                return oldDestroy(self, ...)
            end
        end
    end)
end

-- ==============================================
-- ✅ 抖动伪装
-- ==============================================
local function startJitter()
    if jitterCon then jitterCon:Disconnect() end
    jitterCon = RunService.Heartbeat:Connect(function()
        if not state.MasterEnabled or not state.JitterEnabled or state.isTeleporting then return end
        pcall(function()
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame += Vector3.new(
                    math.random(-1.5, 1.5) / 100,
                    0,
                    math.random(-1.5, 1.5) / 100
                )
            end
        end)
    end)
end

local function stopJitter()
    if jitterCon then jitterCon:Disconnect() jitterCon = nil end
end

-- ==============================================
-- ✅ 反挂机
-- ==============================================
local function startAfk()
    if afkCon then afkCon:Disconnect() end
    afkCon = RunService.Heartbeat:Connect(function()
        if not state.MasterEnabled or not state.AntiAfkEnabled or state.isTeleporting then return end
        pcall(function()
            LocalPlayer:SetAttribute("LastActive", os.clock())
        end)
    end)
end

local function stopAfk()
    if afkCon then afkCon:Disconnect() afkCon = nil end
end

-- ==============================================
-- ✅ 网络保活
-- ==============================================
local function startNetwork()
    if networkCon then networkCon:Disconnect() end
    networkCon = RunService.Heartbeat:Connect(function()
        if not state.MasterEnabled then return end
        if os.clock() - state.lastBeat > 15 then
            state.lastBeat = os.clock()
            LocalPlayer:SetAttribute("KeepAlive", os.clock())
        end
    end)
end

-- ==============================================
-- ✅ 远程拦截
-- ==============================================
local function blockRemotes()
    local exact = {"kick", "ban", "softkick", "punish", "destroy", "remove"}
    local partial = {"adonis", "hd", "hdadmin", "anticheat", "detect"}

    local blocked = {}

    local function checkName(n)
        n = n:lower()
        for _, k in ipairs(exact) do if n == k then return true end end
        for _, k in ipairs(partial) do if n:find(k) then return true end end
        return false
    end

    local function hook(obj)
        if not obj:IsA("RemoteEvent") and not obj:IsA("RemoteFunction") then return end
        if blocked[obj] then return end
        
        if checkName(obj.Name) then
            blocked[obj] = true
            if obj:IsA("RemoteEvent") then
                local oldFire = obj.FireServer
                obj.FireServer = function(self, ...)
                    if state.MasterEnabled then return nil end
                    return oldFire(self, ...)
                end
            end
        end
    end

    local function scan(parent)
        for _, v in ipairs(parent:GetDescendants()) do
            pcall(hook, v)
        end
    end

    scan(ReplicatedStorage)
    scan(Workspace)
end

-- ==============================================
-- ✅ 深度增强
-- ==============================================
local function enhance()
    pcall(function()
        local ot = tick
        tick = function() return ot() + math.random(1, 3) / 10000 end
        
        local oc = os.clock
        os.clock = function() return oc() + math.random(1, 2) / 10000 end
        
        settings().Network.MtuOverride = 1500
    end)
    
    -- 二次扫描 Adonis 检测函数
    pcall(function()
        if getgc and hookfunction then
            for _, v in ipairs(getgc(true)) do
                if typeof(v) == "table" then
                    local Detected = rawget(v, "Detected")
                    if typeof(Detected) == "function" then
                        hookfunction(Detected, function() return true end)
                    end
                end
            end
        end
    end)
    
    notify("✅ 增强完成", "深度伪装已激活", 4)
end

-- ==============================================
-- 🎮 UI
-- ==============================================
Tab:CreateToggle({
    Name = "🛡️ 终极防护总开关",
    CurrentValue = false,
    Callback = function(v)
        state.MasterEnabled = v
        if v then
            state.interceptCount = 0
            startNetwork()
            if state.JitterEnabled then startJitter() end
            if state.AntiAfkEnabled then startAfk() end
            notify("✅ 防护开启", "所有功能已激活", 4)
        else
            stopJitter()
            stopAfk()
            notify("⚠️ 防护关闭", "所有功能已停止", 3)
        end
    end
})

Tab:CreateToggle({
    Name = "👻 隐形微移（管理员来了可关闭）",
    CurrentValue = false,
    Callback = function(v)
        state.JitterEnabled = v
        if v and state.MasterEnabled then startJitter() else stopJitter() end
    end
})

Tab:CreateToggle({
    Name = "💓 反挂机心跳",
    CurrentValue = false,
    Callback = function(v)
        state.AntiAfkEnabled = v
        if v and state.MasterEnabled then startAfk() else stopAfk() end
    end
})

Tab:CreateButton({
    Name = "💎 一键深度增强",
    Callback = enhance
})

Tab:CreateLabel("✅ 功能列表：")
Tab:CreateLabel("🛡️ Hook拦截 | 函数覆盖 | 角色重载")
Tab:CreateLabel("👻 隐形微移 | 💓 反挂机 | 🌐 传送防护")
Tab:CreateLabel("🔒 Adonis绕过 | 📡 远程拦截 | 网络保活")
Tab:CreateLabel("")
Tab:CreateLabel("💡 前置绕过已自动执行")

-- ==============================================
-- 🚀 启动
-- ==============================================
installCoreFeatures()
installFunctionOverrides()
blockRemotes()
startNetwork()

notify("✅ 系统加载完成", "前置绕过已激活", 5)

print("===== 终极防踢 · 前置绕过整合版 已启动 =====")
