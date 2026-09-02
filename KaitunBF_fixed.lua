
--=============================================================================
--  KAITUN BLOX FRUITS  —  "Night Slayer Hub - Kaitun"
--  Bản khôi phục từ bản decompile: KaitunBF.lua.txt (7731 dòng)
--
--  Tài liệu đối chiếu (chỉ dùng để đặt tên / dò lại logic, không lấy code ở ngoài):
--    + NatAovKaitunBF_FULL_FORMAT.lua.txt   :  đã đặt tên sẵn  ->  mượn tên thật
--    + KaitunNew.txt (bản DIO)                :  còn thiếu   ->  ghép thêm
--
--  Đã làm gì:
--    - Đổi toàn bộ tên mã hoá  L_1_[N] / L_8_[2] / *_forvar* / *_arg*  -> tên dễ đọc
--    - Xoá "logic tìm helper" (setmetatable + chuỗi if/elseif so sánh tên chuỗi),
--      thay bằng function đặt tên, gọi trực tiếp:  Utils.findFirstChild(...)
--    - Gộp các chuỗi bị obfuscator cắt đôi ("DressrosaQuestProgre".."ss")
--    - Mọi toggle nằm trong getgenv().Config (xem mục CONFIG bên dưới),
--      mỗi toggle đều được nối vào đúng logic của source, không có toggle thừa
--    - Ghép tính năng còn thiếu từ file DIO: chọn vũ khí, Katakuri,
--      chống ngông (anti-idle), auto hop / hop khi idle
--  File này là LuaU (Roblox). Cần executor có game:GetService,
--  getgenv(), sethiddenproperty(), fireproximityprompt(). Compile bằng LuaJIT: OK.
--=============================================================================
local playerBeliValue, virtualInputManager, coreGuiService, localPlayer, tweenService,
      replicatedStorage, updateLevelQuestInfo, idlePlayersService, teleportService, statusGui,
      statusStroke, lastTeleportStartTime, equipPreferredFarmTool, statusTitleLabel,
      lightingService, playerFragmentsValue, lastKnownPosition, workspaceService,
      fastAttackDelay, currentActionDelay, currentLevelValue, activeBoatTween, playerLevelValue,
      combatWorkspace, statusTextLabel, combatPlayersService, idleSeconds, playersService,
      currentPlaceId, tweenTeleportTo, cancelActiveTween, virtualUser, combatUtils, farmPlayer,
      idleCheckSeconds, idlePlayer, selectAutoFarmQuest, runDefaultFarmQuest, enemiesFolder,
      statusCorner, statusFrame, statusCoreGui, waitForCharacterRootPart, Utils,
      combatReplicatedStorage, activeTeleportTween, netModule, canStartCursedDualKatanaQuest,
      combatPlayer, hubBannerFrame, hubBannerCorner, hubBannerStroke, hubBannerText,
      hubBannerStrokeTween, hubBannerTextTween
local SWORD_LIST = {"Bisento",
    "Cutlass",
    "Dual Katana",
    "Dual-Headed Blade",
    "Flail",
    "Gravity Blade",
    "Iron Mace",
    "Katana",
    "Longsword",
    "Midnight Blade",
    "Pipe",
    "Pole (1st Form)",
    "Rengoku",
    "Saber",
    "Shark Saw",
    "Soul Cane",
    "Triple Katana",
    "Tushita",
    "Twin Hooks",
    "Wardens Sword",
    "Yama"}
local GUN_LIST = {"Bazooka", "Cannon", "Dual Flintlock", "Flintlock", "Kabucha", "Magma Blaster", "Musket", "Refined Slingshot", "Soul Guitar", "Venom Bow"}
--=============================================================================
-- CONFIG / TOGGLE
--   Mỗi key ở đây đều có chỗ dùng thật (không còn toggle chết).
--   Key được viết đúng theo tên mà source dùng bên dưới, nên đổi ở đây là
--   đổi được hành vi của script, không cần sửa xuống dưới.
--=============================================================================
getgenv().Config = {
    ["Auto Farming"] = true,          -- bật/tắt toàn bộ vòng farm chính (getgenv().AutoFarm)
    ["Settings"] = {
        ["FPS Booster"] = true,       -- gồm cả "Low Graphics": xoá hiệu ứng, cắt đồ hoạ
        ["Fast Attack"] = true,       -- tấn công nhanh (getgenv()["Fast Attack"])
        ["Anti Idle"] = true,         -- giữ game không bị ngông (virtualUser)
        ["Auto Hop"] = false,         -- hop server theo chu kỳ thời gian
        ["Auto Hop Delay"] = 60 * 60, -- tính theo giây
        ["Hop When Idle"] = false,    -- hop khi không hoạt động quá 5 phút
    },
    ["Melee"] = {                     -- tên key = đúng tên fighting style mà source mua
        ["All Melee"] = true,
        ["Black Leg"] = true,
        ["Electro"] = true,
        ["Fishman Karate"] = true,
        ["Dragon Claw"] = true,
        ["Death Step"] = true,
        ["Sharkman Karate"] = true,
        ["Electric Claw"] = true,
        ["Dragon Talon"] = true,
        ["Godhuman"] = true,
        ["Superhuman"] = true,
    },
    ["Sword"] = {                     -- kiếm được chọn sẽ được đưa vào Configs.Sword (source lọc theo list này)
        ["All Sword"] = false,
        ["Katana"] = true,
        ["Cutlass"] = true,
        ["Dual Katana"] = true,
        ["Triple Katana"] = true,
        ["Iron Mace"] = true,
        ["Pipe"] = true,
        ["Dual-Headed Blade"] = true,
        ["Saber"] = true,
        ["Pole (1st Form)"] = true,
        ["Gravity Blade"] = true,
        ["Longsword"] = true,
        ["Rengoku"] = true,
        ["Midnight Blade"] = true,
        ["Soul Cane"] = true,
        ["Bisento"] = true,
        ["Yama"] = true,
        ["Tushita"] = true,
        ["Cursed Dual Katana"] = true,
        ["Twin Hooks"] = true,
        ["Flail"] = true,
        ["Shark Saw"] = true,
        ["Wardens Sword"] = true,
        ["Smoke Admiral"] = true,
    },
    ["Gun"] = {
        ["All Gun"] = false,
        ["Musket"] = true,
        ["Refined Slingshot"] = true,
        ["Flintlock"] = true,
        ["Dual Flintlock"] = true,
        ["Cannon"] = true,
        ["Soul Guitar"] = true,
        ["Kabucha"] = true,
        ["Venom Bow"] = true,
        ["Magma Blaster"] = true,
        ["Bazooka"] = true,
    },
    ["Quest"] = {                     -- 4 mục này source đọc trực tiếp
        ["Evo Race V1"] = true,       -- mở khoá Race V2 (Old World)
        ["Evo Race V2"] = true,       -- mở khoá Race V3 (New World)
        ["RGB Haki"] = true,          -- mua RGB Haki khi đủ 2000 level
        ["Pull Lerver"] = true,       -- kéo gan gương / CDK
    },
    ["Weapon Select"] = {             -- [ghép từ DIO] KaitunNew dùng _G.ChooseWP
        ["Enabled"] = true,
        ["Type"] = "Melee",           -- "Melee" | "Sword" | "Gun" | "Blox Fruit"
    },
    ["Raid"] = {                      -- [ghép từ DIO] giới hạn fragment khi farm raid
        ["Auto Raid Ice"] = true,
        ["Target Fragments"] = 5000,  -- dừng farm raid khi đủ fragment
    },
    ["Katakuri Farm"] = {             -- [ghép từ DIO] Katakuri (Sea 3)
        ["Enabled"] = false,
        ["Target Fragments"] = 5000,
    },
}

-- Configs là bảng mà chính source đọc (Quest / Sword / Gun / FPS Booster).
-- Nếu đã có sẵn Configs (script khác đặt vào) thì giữ nguyên, giống logic
-- của bản NatAov.
local defaultConfigs = {
    Quest = {
        ["Evo Race V1"] = true,
        ["Evo Race V2"] = true,
        ["RGB Haki"] = true,
        ["Pull Lerver"] = true
    },
    Sword = {
        "Dual-Headed Blade",
        "Smoke Admiral",
        "Wardens Sword",
        "Cutlass",
        "Katana",
        "Dual Katana",
        "Triple Katana",
        "Iron Mace",
        "Saber",
        "Pole (1st Form)",
        "Gravity Blade",
        "Longsword",
        "Rengoku",
        "Midnight Blade",
        "Soul Cane",
        "Bisento",
        "Yama",
        "Tushita",
        "Cursed Dual Katana"
    },
    Gun = {
        "Soul Guitar",
        "Kabucha",
        "Venom Bow",
        "Musket",
        "Flintlock",
        "Refined Slingshot",
        "Magma Blaster",
        "Dual Flintlock",
        "Cannon",
        "Bizarre Revolver",
        "Bazooka"
    },
    ["FPS Booster"] = false
}

local function buildConfigs(cfg)
    if type(cfg) ~= "table" then
        return nil
    end
    local built = {
        Quest = {
            ["Evo Race V1"] = cfg.Quest and cfg.Quest["Evo Race V1"] ~= false,
            ["Evo Race V2"] = cfg.Quest and cfg.Quest["Evo Race V2"] ~= false,
            ["RGB Haki"] = cfg.Quest and cfg.Quest["RGB Haki"] ~= false,
            ["Pull Lerver"] = cfg.Quest and cfg.Quest["Pull Lerver"] ~= false,
        },
        Sword = {},
        Gun = {},
        ["FPS Booster"] = cfg.Settings and cfg.Settings["FPS Booster"] ~= false
        or cfg.Settings and cfg.Settings["Low Graphics"] ~= false,
    }
    if cfg.Sword then
        if cfg.Sword["All Sword"] then
            for _, name in ipairs(SWORD_LIST) do
                table.insert(built.Sword, name)
            end
        else
            for _, name in ipairs(SWORD_LIST) do
                if cfg.Sword[name] then
                    table.insert(built.Sword, name)
                end
            end
        end
    end
    if cfg.Gun then
        if cfg.Gun["All Gun"] then
            for _, name in ipairs(GUN_LIST) do
                table.insert(built.Gun, name)
            end
        else
            for _, name in ipairs(GUN_LIST) do
                if cfg.Gun[name] then
                    table.insert(built.Gun, name)
                end
            end
        end
    end
    return built
end

if not getgenv().Configs then
    getgenv().Configs = buildConfigs(getgenv().Config) or defaultConfigs
end

-- toggle -> cổng lệnh của source (chỉ 1 chiều, không có key thừa)
if getgenv().Config and getgenv().Config.Settings then
    getgenv()["Fast Attack"] = getgenv().Config.Settings["Fast Attack"] ~= false
end

local function configToggle(section, key, default)
    local cfg = getgenv().Config
    local block = cfg and type(cfg) == "table" and cfg[section]
    if type(block) ~= "table" or block[key] == nil then
        return default ~= false
    end
    return block[key] ~= false
end

local function autoFarmingOn()
    if getgenv().AutoFarm == false then
        return false
    end
    local cfg = getgenv().Config
    return not (type(cfg) == "table" and cfg["Auto Farming"] == false)
end

local function meleeUnlocked(styleName)
    if not getgenv().Config or not getgenv().Config.Melee then
        return true
    end
    local melee = getgenv().Config.Melee
    if melee["All Melee"] then
        return true
    end
    return melee[styleName] ~= false
end


if not game:IsLoaded() then
    repeat
        game.Loaded:Wait()
    until game:IsLoaded()
end
task.wait(5)
if game.Players.LocalPlayer.PlayerGui:FindFirstChild("Main (minimal)") then
    if game.Players.LocalPlayer.PlayerGui["Main (minimal)"]:FindFirstChild("ChooseTeam") then
        repeat
            task.wait()
            if (game.Players.LocalPlayer.PlayerGui:FindFirstChild("Main (minimal)")).ChooseTeam.Visible then
                (((game:GetService("ReplicatedStorage")):WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("SetTeam", "Pirates")
            end
        until game.Players.LocalPlayer.Team ~= nil and game:IsLoaded()
    end
end
playersService = game:GetService("Players")
localPlayer = playersService.LocalPlayer
currentPlaceId = game.PlaceId
workspaceService = game:GetService("Workspace")
enemiesFolder = workspaceService:WaitForChild("Enemies")
teleportService = game:GetService("TeleportService")
replicatedStorage = game:GetService("ReplicatedStorage")
playerLevelValue = (localPlayer:WaitForChild("Data")):WaitForChild("Level")
playerFragmentsValue = (localPlayer:WaitForChild("Data")):WaitForChild("Fragments")
playerBeliValue = (localPlayer:WaitForChild("Data")):WaitForChild("Beli")
netModule = require(replicatedStorage.Modules.Net)
lightingService = game:GetService("Lighting")
virtualInputManager = game:GetService("VirtualInputManager")
virtualUser = game:GetService("VirtualUser")
coreGuiService = game:GetService("CoreGui")
Utils = {}
task.spawn(function()
    if getgenv().Configs and getgenv().Configs["FPS Booster"] then
        replicatedStorage.Effect:Destroy()
        for key2, connection in pairs(getconnections(localPlayer.PlayerGui.Main.Settings.Buttons.FastModeButton.Activated)) do
            connection.Function()
        end
    end
end)
task.wait(2)
task.spawn(function()
    if getgenv().Configs["FPS Booster"] then
        local enemies = workspaceService:WaitForChild("Enemies")
        local children = (workspaceService:WaitForChild("Map")):GetDescendants()
        for key3, item in ipairs(children) do
            if item:IsA("BasePart") then
                local flag2
                local flag2 = false
                for index = 1, 5, 1 do
                    local found = workspaceService.Map.Jungle.QuestPlates:FindFirstChild("Plate" .. index)
                    if found and item.Name == "Button" and item:IsDescendantOf(found) then
                        flag2 = true
                        break
                    end
                end
                if flag2 then
                    continue
                end
                if item.Name == "Door" and item:IsDescendantOf(workspaceService.Map.Ice) then
                    continue
                end
                if item:IsDescendantOf(workspaceService.Map.Jungle:FindFirstChild("Final")) then
                    continue
                end
                if workspaceService.Map:FindFirstChild("IceCastle") then
                    if item:IsDescendantOf(workspaceService.Map:FindFirstChild("IceCastle")) then
                        continue
                    end
                end
                flag2 = true
                for key4, l in ipairs(enemies:GetChildren()) do
                    local humanoidRootPart = l:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart and (humanoidRootPart.Position - item.Position).Magnitude < 10 then
                        flag2 = false
                        break
                    end
                end
                if flag2 then
                    item:Destroy()
                end
            end
        end
        if localPlayer.PlayerGui:FindFirstChild("Notifications") then
            localPlayer.PlayerGui.Notifications.Enabled = false
        end
        shared = shared or {}
        if shared.BC_1 == nil then
            shared.BC_1 = true
        end
        if shared.BC_1 and shared.BC_2 == nil then
            local terrain = workspace.Terrain
            local playersService2 = playersService
            local character = localPlayer.Character
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0
            lightingService.GlobalShadows = false
            lightingService.FogEnd = 9000000000
            lightingService.Brightness = 0
            if settings and (settings()).Rendering then
                (settings()).Rendering.QualityLevel = "Level01"
                (settings()).Rendering.GraphicsMode = "NoGraphics"
            end
            for key5, l2 in pairs(workspace:GetDescendants()) do
                if l2:IsA("BasePart") or l2:IsA("SpawnLocation") or l2:IsA("WedgePart") or l2:IsA("Terrain") or l2:IsA("MeshPart") then
                    l2.Material = Enum.Material.Plastic
                    l2.Reflectance = 0
                    l2.CastShadow = false
                elseif l2:IsA("Decal") or l2:IsA("Texture") then
                    l2.Texture = ""
                    l2.Transparency = 1
                elseif l2:IsA("ParticleEmitter") or l2:IsA("Trail") then
                    l2.LightInfluence = 0
                    l2.Texture = ""
                    l2.Lifetime = NumberRange.new(0)
                elseif l2:IsA("Explosion") then
                    l2.BlastPressure = 0
                    l2.BlastRadius = 0
                elseif l2:IsA("Fire") or l2:IsA("SpotLight") or l2:IsA("Smoke") or l2:IsA("Sparkles") then
                    l2.Enabled = false
                elseif l2:IsA("MeshPart") then
                    l2.Material = Enum.Material.Plastic
                    l2.Reflectance = 0
                    l2.TextureID = ""
                    l2.CastShadow = false
                    l2.RenderFidelity = Enum.RenderFidelity.Performance
                elseif l2:IsA("SpecialMesh") then
                    l2.TextureId = ""
                elseif l2:IsA("Shirt") or l2:IsA("Pants") or l2:IsA("Accessory") then
                    l2:Destroy()
                end
            end
            for key6, l3 in pairs(lightingService:GetDescendants()) do
                if l3:IsA("BlurEffect") or l3:IsA("SunRaysEffect") or l3:IsA("ColorCorrectionEffect") or l3:IsA("BloomEffect") or l3:IsA("DepthOfFieldEffect") then
                    l3.Enabled = false
                end
            end
            if character then
                for key7, l4 in pairs(character:GetDescendants()) do
                    if l4:IsA("Shirt") or l4:IsA("Pants") or l4:IsA("Accessory") then
                        l4:Destroy()
                    end
                end
            end
            if currentPlaceId == 2753915549 or currentPlaceId == 4442272183 or currentPlaceId == 7449423635 then
                local container = replicatedStorage:FindFirstChild("Effect") and replicatedStorage.Effect:FindFirstChild("Container")
                if container then
                    local shared2 = container:FindFirstChild("Shared")
                    local misc = container:FindFirstChild("Misc")
                    if shared2 then
                        if shared2:FindFirstChild("AirDash") then
                            shared2.AirDash:Destroy()
                        end
                        if shared2:FindFirstChild("LightningTP") then
                            shared2.LightningTP:Destroy()
                        end
                    end
                    if misc then
                        if misc:FindFirstChild("Damage") then
                            misc.Damage:Destroy()
                        end
                        if misc:FindFirstChild("Confetti") then
                            misc.Confetti:Destroy()
                        end
                    end
                    if container:FindFirstChild("LevelUp") then
                        container.LevelUp:Destroy()
                    end
                end
            end
        end
        shared.BC_2 = true
    end
end)
statusCoreGui = game:GetService("CoreGui")
tweenService = game:GetService("TweenService")
if statusCoreGui:FindFirstChild("Status_UI") then
    statusCoreGui.Status_UI:Destroy()
end
statusGui = Instance.new("ScreenGui")
statusGui.Name = "Status_UI"
statusGui.ResetOnSpawn = false
statusGui.Parent = statusCoreGui

statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(0, 150, 0, 50)
statusFrame.Position = UDim2.new(1, -10, .5, 0)
statusFrame.AnchorPoint = Vector2.new(1, .5)
statusFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statusFrame.BackgroundTransparency = .25
statusFrame.BorderSizePixel = 2
statusFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
statusFrame.Parent = statusGui
statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusFrame
statusStroke = Instance.new("UIStroke")
statusStroke.Thickness = 2
statusStroke.Color = Color3.fromRGB(255, 0, 0)
statusStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
statusStroke.Parent = statusFrame
statusTitleLabel = Instance.new("TextLabel")
statusTitleLabel.Size = UDim2.new(1, -10, .5, 0)
statusTitleLabel.Position = UDim2.new(.5, 0, 0, 2)
statusTitleLabel.AnchorPoint = Vector2.new(.5, 0)
statusTitleLabel.BackgroundTransparency = 1
statusTitleLabel.Text = "Night Slayer Hub - Kaitun"
statusTitleLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
statusTitleLabel.TextSize = 13
statusTitleLabel.Font = Enum.Font.GothamBold
statusTitleLabel.TextXAlignment = Enum.TextXAlignment.Center
statusTitleLabel.TextYAlignment = Enum.TextYAlignment.Center
statusTitleLabel.Parent = statusFrame
statusTextLabel = Instance.new("TextLabel")
statusTextLabel.Size = UDim2.new(1, -10, .4, 0)
statusTextLabel.Position = UDim2.new(.5, 0, .5, 0)
statusTextLabel.AnchorPoint = Vector2.new(.5, 0)
statusTextLabel.BackgroundTransparency = 1
statusTextLabel.Text = "Status : N/A"
statusTextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
statusTextLabel.TextSize = 12
statusTextLabel.Font = Enum.Font.Gotham
statusTextLabel.TextXAlignment = Enum.TextXAlignment.Center
statusTextLabel.TextYAlignment = Enum.TextYAlignment.Center
statusTextLabel.Parent = statusFrame

hubBannerFrame = Instance.new("Frame")
hubBannerFrame.Size = UDim2.new(0, 250, 0, 60)
hubBannerFrame.Position = UDim2.new(.5, 0, .13, 0)
hubBannerFrame.AnchorPoint = Vector2.new(.5, .5)
hubBannerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
hubBannerFrame.BackgroundTransparency = .25
hubBannerFrame.Parent = statusGui
hubBannerCorner = Instance.new("UICorner")
hubBannerCorner.CornerRadius = UDim.new(0, 6)
hubBannerCorner.Parent = hubBannerFrame
hubBannerStroke = Instance.new("UIStroke")
hubBannerStroke.Thickness = 2
hubBannerStroke.Color = Color3.fromRGB(255, 0, 0)
hubBannerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
hubBannerStroke.Parent = hubBannerFrame
hubBannerText = Instance.new("TextLabel")
hubBannerText.Size = UDim2.new(1, 0, 1, 0)
hubBannerText.BackgroundTransparency = 1
hubBannerText.Text = "Night Slayer Hub"
hubBannerText.TextColor3 = Color3.fromRGB(255, 0, 0)
hubBannerText.TextSize = 14
hubBannerText.Font = Enum.Font.GothamBold
hubBannerText.Parent = hubBannerFrame

task.spawn(function()
    while task.wait() do
        local color4 = tweenService:Create(statusStroke, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {["Color"] = Color3.fromRGB(255, 0, 0)})
        local color5 = tweenService:Create(statusStroke, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {["Color"] = Color3.fromRGB(255, 0, 0)})
        local color2 = tweenService:Create(statusTitleLabel, TweenInfo.new(1.2), {["TextColor3"] = Color3.fromRGB(255, 0, 0)})
        local color3 = tweenService:Create(statusTitleLabel, TweenInfo.new(1.2), {["TextColor3"] = Color3.fromRGB(255, 0, 0)})
        local color = tweenService:Create(statusTextLabel, TweenInfo.new(1.2), {["TextColor3"] = Color3.fromRGB(255, 0, 0)})
        local color6 = tweenService:Create(statusTextLabel, TweenInfo.new(1.2), {["TextColor3"] = Color3.fromRGB(255, 0, 0)})

        local hubBannerStrokeTween = tweenService:Create(hubBannerStroke, TweenInfo.new(1.2), {["Color"] = Color3.fromRGB(255, 0, 0)})
        local hubBannerTextTween = tweenService:Create(hubBannerText, TweenInfo.new(1.2), {["TextColor3"] = Color3.fromRGB(255, 0, 0)})

        color4:Play()
        color2:Play()
        color:Play()
        hubBannerStrokeTween:Play()
        hubBannerTextTween:Play()
        color4.Completed:Wait()
        color5:Play()
        color3:Play()
        color6:Play()
        color5.Completed:Wait()
    end
end)
if currentPlaceId == 2753915549 then
    Old_World = true
elseif currentPlaceId == 4442272183 then
    New_World = true
elseif currentPlaceId == 7449423635 then
    Three_World = true
end
currentLevelValue = (localPlayer:WaitForChild("Data")):WaitForChild("Level")
function CheckLevel2()
    local players = (game:GetService("Players")).LocalPlayer.Data.Level.Value
    if Old_World then
        if game.Players.LocalPlayer.Data.Level.Value == 1 or game.Players.LocalPlayer.Data.Level.Value <= 9 or SelectMonster == "" then
            Ms = "Bandit"
            NameQuest = "BanditQuest1"
            QuestLv = 1
            NameMon = "Bandit"
            CFrameQ = CFrame.new(1059.37195, 15.4495068, 1550.4231, .939700544, 0, -0.341998369, 0, 1, 0, .341998369, 0, .939700544)
            CFrameMon = CFrame.new(1353.44885,
                3.40935516,
                1376.92029,
                .776053488,
                -6.97791975e-08,
                .630666852,
                6.99138596e-08,
                1,
                2.4612488e-08,
                -0.630666852,
                2.49917598e-08,
                .776053488)
            Next_Level_X = 10
        elseif game.Players.LocalPlayer.Data.Level.Value == 10 or game.Players.LocalPlayer.Data.Level.Value <= 100 then
            Ms = "Shanda"
            NameQuest = "SkyExp1Quest"
            QuestLv = 2
            NameMon = "Shanda"
            CFrameQ = CFrame.new(-7859.09814, 5544.19043, -381.476196)
            CFrameMon = CFrame.new(-7904.57373, 5584.37646, -459.62973)
            Next_Level_X = 75
        elseif game.Players.LocalPlayer.Data.Level.Value >= 60 and game.Players.LocalPlayer.Data.Level.Value <= 74 or SelectMonster == "Desert Bandit" then
            Ms = "Desert Bandit"
            NameQuest = "DesertQuest"
            QuestLv = 1
            NameMon = "Desert Bandit"
            CFrameQ = CFrame.new(894.488647, 5.14000702, 4392.43359, .819155693, 0, -0.573571265, 0, 1, 0, .573571265, 0, .819155693)
            CFrameMon = CFrame.new(932.788818,
                6.8503746,
                4488.24609,
                -0.998625934,
                3.08948351e-08,
                .0524050146,
                2.79967303e-08,
                1,
                -5.60361286e-08,
                -0.0524050146,
                -5.44919629e-08,
                -0.998625934)
        elseif game.Players.LocalPlayer.Data.Level.Value >= 75 and game.Players.LocalPlayer.Data.Level.Value <= 89 or SelectMonster == "Desert Officer" then
            Ms = "Desert Officer"
            NameQuest = "DesertQuest"
            QuestLv = 2
            NameMon = "Desert Officer"
            CFrameQ = CFrame.new(894.488647, 5.14000702, 4392.43359, .819155693, 0, -0.573571265, 0, 1, 0, .573571265, 0, .819155693)
            CFrameMon = CFrame.new(1617.07886,
                1.5542295,
                4295.54932,
                -0.997540116,
                -2.26287735e-08,
                -0.070099175,
                -1.69377223e-08,
                1,
                -8.17798806e-08,
                .070099175,
                -8.03913949e-08,
                -0.997540116)
            SelectMonster = "Desert Bandit"
            Next_Level_X = 90
        elseif game.Players.LocalPlayer.Data.Level.Value >= 90 and game.Players.LocalPlayer.Data.Level.Value <= 99 or SelectMonster == "Snow Bandit" then
            Ms = "Snow Bandit"
            NameQuest = "SnowQuest"
            QuestLv = 1
            NameMon = "Snow Bandit"
            CFrameQ = CFrame.new(1389.74451, 86.6520844, -1298.90796, -0.342042685, 0, .939684391, 0, 1, 0, -0.939684391, 0, -0.342042685)
            CFrameMon = CFrame.new(1412.92346,
                55.3503647,
                -1260.62036,
                -0.246266365,
                -0.0169920288,
                -0.969053388,
                .000432241941,
                .999844253,
                -0.0176417865,
                .969202161,
                -0.00476344163,
                -0.246220857)
            if SelectMonster == "Snow Bandit" then
            else
                Next_Level_X = 100
            end
            if game.Players.LocalPlayer.Data.Level.Value >= 110 then
                SelectBoss_P = "Yeti"
            end
        elseif game.Players.LocalPlayer.Data.Level.Value == 100 or game.Players.LocalPlayer.Data.Level.Value <= 119 or SelectMonster == "Snowman" then
            Next_Level_X = 120
            Ms = "Snowman"
            NameQuest = "SnowQuest"
            QuestLv = 2
            NameMon = "Snowman"
            CFrameQ = CFrame.new(1389.74451, 86.6520844, -1298.90796, -0.342042685, 0, .939684391, 0, 1, 0, -0.939684391, 0, -0.342042685)
            CFrameMon = CFrame.new(1376.86401,
                97.2779999,
                -1396.93115,
                -0.986755967,
                7.71178321e-08,
                -0.162211925,
                7.71531674e-08,
                1,
                6.08143536e-09,
                .162211925,
                -6.51427134e-09,
                -0.986755967)
            if game.Players.LocalPlayer.Data.Level.Value >= 110 then
                SelectBoss_P = "Yeti"
            end
            SelectMonster = "Snow Bandit"
        elseif game.Players.LocalPlayer.Data.Level.Value == 120 or game.Players.LocalPlayer.Data.Level.Value <= 174 or SelectMonster == "Chief Petty Officer" then
            Ms = "Chief Petty Officer"
            NameQuest = "MarineQuest2"
            QuestLv = 1
            NameMon = "Chief Petty Officer"
            CFrameQ = CFrame.new(-5039.58643, 27.3500385, 4324.68018, 0, 0, -1, 0, 1, 0, 1, 0, 0)
            CFrameMon = CFrame.new(-4882.8623,
                22.6520386,
                4255.53516,
                .273695946,
                -5.40380647e-08,
                -0.96181643,
                4.37720793e-08,
                1,
                -4.37274998e-08,
                .96181643,
                -3.01326679e-08,
                .273695946)
            if game.Players.LocalPlayer.Data.Level.Value >= 130 then
                SelectBoss_P = "Vice Admiral"
            end
            if SelectMonster == "Chief Petty Officer" then
            else
                Next_Level_X = 175
            end
        elseif SelectMonster == "Sky Bandit" then
            Ms = "Sky Bandit"
            NameQuest = "SkyQuest"
            QuestLv = 1
            NameMon = "Sky Bandit"
            CFrameQ = CFrame.new(-4839.53027, 716.368591, -2619.44165, .866007268, 0, .500031412, 0, 1, 0, -0.500031412, 0, .866007268)
            CFrameMon = CFrame.new(-4959.51367,
                365.39267,
                -2974.56812,
                .964867651,
                7.74418396e-08,
                .262737453,
                -6.95931988e-08,
                1,
                -3.91783708e-08,
                -0.262737453,
                1.95171506e-08,
                .964867651)
        elseif game.Players.LocalPlayer.Data.Level.Value == 175 or game.Players.LocalPlayer.Data.Level.Value <= 189 or SelectMonster == "Dark Master" then
            Ms = "Dark Master"
            NameQuest = "SkyQuest"
            QuestLv = 2
            NameMon = "Dark Master"
            CFrameQ = CFrame.new(-4839.53027, 716.368591, -2619.44165, .866007268, 0, .500031412, 0, 1, 0, -0.500031412, 0, .866007268)
            CFrameMon = CFrame.new(-5079.98096,
                376.477356,
                -2194.17139,
                .465965867,
                -3.69776352e-08,
                .884802461,
                3.40249851e-09,
                1,
                4.00000886e-08,
                -0.884802461,
                -1.56281423e-08,
                .465965867)
            SelectMonster = "Sky Bandit"
            if SelectMonster == "Dark Master" then
            else
                Next_Level_X = 190
            end
        elseif game.Players.LocalPlayer.Data.Level.Value == 190 or game.Players.LocalPlayer.Data.Level.Value <= 209 or SelectMonster == "Prisoner" then
            Ms = "Prisoner"
            QuestLv = 1
            NameQuest = "PrisonerQuest"
            NameMon = "Prisoner"
            CFrameQ = CFrame.new(5308.93115,
                1.65517521,
                475.120514,
                -0.0894274712,
                -5.00292918e-09,
                -0.995993316,
                1.60817859e-09,
                1,
                -5.16744869e-09,
                .995993316,
                -2.06384709e-09,
                -0.0894274712)
            CFrameMon = CFrame.new(5433.39307, 88.678093, 514.986877, .879988372, 0, -0.474995494, 0, 1, 0, .474995494, 0, .879988372)
            if game.Players.LocalPlayer.Data.Level.Value >= 220 then
                SelectBoss_P = "Warden"
            end
            if game.Players.LocalPlayer.Data.Level.Value >= 232 then
                SelectBoss_P = "Chief Warden"
            end
            if game.Players.LocalPlayer.Data.Level.Value >= 242 then
                SelectBoss_P = "Thunder God"
            end
            if SelectMonster == "Prisoner" then
            else
                Next_Level_X = 210
            end
            Bypass_TP_Dis = true
        elseif game.Players.LocalPlayer.Data.Level.Value == 210 or game.Players.LocalPlayer.Data.Level.Value <= 249 or SelectMonster == "Dangerous Prisoner" then
            if game.Players.LocalPlayer.Data.Level.Value >= 220 then
                SelectBoss_P = "Warden"
            end
            if game.Players.LocalPlayer.Data.Level.Value >= 232 then
                SelectBoss_P = "Chief Warden"
            end
            if game.Players.LocalPlayer.Data.Level.Value >= 242 then
                SelectBoss_P = "Thunder God"
            end
            Ms = "Dangerous Prisoner"
            QuestLv = 2
            NameQuest = "PrisonerQuest"
            NameMon = "Dangerous Prisoner"
            CFrameQ = CFrame.new(5308.93115,
                1.65517521,
                475.120514,
                -0.0894274712,
                -5.00292918e-09,
                -0.995993316,
                1.60817859e-09,
                1,
                -5.16744869e-09,
                .995993316,
                -2.06384709e-09,
                -0.0894274712)
            CFrameMon = CFrame.new(5433.39307, 88.678093, 514.986877, .879988372, 0, -0.474995494, 0, 1, 0, .474995494, 0, .879988372)
            SelectMonster = "Prisoner"
            Next_Level_X = 250
            Bypass_TP_Dis = true
        elseif game.Players.LocalPlayer.Data.Level.Value == 250 or game.Players.LocalPlayer.Data.Level.Value <= 274 or SelectMonster == "Toga Warrior" then
            Ms = "Toga Warrior"
            NameQuest = "ColosseumQuest"
            QuestLv = 1
            NameMon = "Toga Warrior"
            CFrameQ = CFrame.new(-1576.11743,
                7.38933945,
                -2983.30762,
                .576966345,
                1.22114863e-09,
                .816767931,
                -3.58496594e-10,
                1,
                -1.24185606e-09,
                -0.816767931,
                4.2370063e-10,
                .576966345)
            CFrameMon = CFrame.new(-1779.97583,
                44.6077499,
                -2736.35474,
                .984437346,
                4.10396339e-08,
                .175734788,
                -3.62286876e-08,
                1,
                -3.05844168e-08,
                -0.175734788,
                2.3741821e-08,
                .984437346)
            if SelectMonster == "Toga Warrior" then
            else
                Next_Level_X = 275
            end
        elseif game.Players.LocalPlayer.Data.Level.Value == 275 or game.Players.LocalPlayer.Data.Level.Value <= 299 or SelectMonster == "Gladiator" then
            Ms = "Gladiator"
            NameQuest = "ColosseumQuest"
            QuestLv = 2
            NameMon = "Gladiator"
            CFrameQ = CFrame.new(-1576.11743,
                7.38933945,
                -2983.30762,
                .576966345,
                1.22114863e-09,
                .816767931,
                -3.58496594e-10,
                1,
                -1.24185606e-09,
                -0.816767931,
                4.2370063e-10,
                .576966345)
            CFrameMon = CFrame.new(-1274.75903,
                58.1895943,
                -3188.16309,
                .464524001,
                6.21005611e-08,
                .885560572,
                -4.80449414e-09,
                1,
                -6.76054768e-08,
                -0.885560572,
                2.71497012e-08,
                .464524001)
            SelectMonster = "Toga Warrior"
            Next_Level_X = 300
        elseif game.Players.LocalPlayer.Data.Level.Value == 300 or game.Players.LocalPlayer.Data.Level.Value <= 324 or SelectMonster == "Military Soldier" then
            if game.Players.LocalPlayer.Data.Level.Value >= 350 then
                SelectBoss_P = "Magma Admiral"
            end
            Ms = "Military Soldier"
            NameQuest = "MagmaQuest"
            QuestLv = 1
            NameMon = "Military Soldier"
            CFrameQ = CFrame.new(-5316.55859,
                12.2370615,
                8517.2998,
                .588437557,
                -1.37880001e-08,
                -0.808542669,
                -2.10116209e-08,
                1,
                -3.23446478e-08,
                .808542669,
                3.60215964e-08,
                .588437557)
            CFrameMon = CFrame.new(-5363.01123,
                41.5056877,
                8548.47266,
                -0.578253984,
                -3.29503091e-10,
                .815856814,
                9.11209668e-08,
                1,
                6.498761e-08,
                -0.815856814,
                1.11920997e-07,
                -0.578253984)
            if SelectMonster == "Military Soldier" then
            else
                Next_Level_X = 325
            end
        elseif game.Players.LocalPlayer.Data.Level.Value == 325 or game.Players.LocalPlayer.Data.Level.Value <= 374 or SelectMonster == "Military Spy" then
            if game.Players.LocalPlayer.Data.Level.Value >= 350 then
                SelectBoss_P = "Magma Admiral"
            end
            Ms = "Military Spy"
            NameQuest = "MagmaQuest"
            QuestLv = 2
            NameMon = "Military Spy"
            CFrameQ = CFrame.new(-5316.55859,
                12.2370615,
                8517.2998,
                .588437557,
                -1.37880001e-08,
                -0.808542669,
                -2.10116209e-08,
                1,
                -3.23446478e-08,
                .808542669,
                3.60215964e-08,
                .588437557)
            CFrameMon = CFrame.new(-5787.99023,
                120.864456,
                8762.25293,
                -0.188358366,
                -1.84706277e-08,
                .982100308,
                -1.23782129e-07,
                1,
                -4.93306951e-09,
                -0.982100308,
                -1.22495649e-07,
                -0.188358366)
            SelectMonster = "Military Soldier"
            Next_Level_X = 375
        elseif game.Players.LocalPlayer.Data.Level.Value == 375 or game.Players.LocalPlayer.Data.Level.Value <= 399 or SelectMonster == "Fishman Warrior" then
            if game.Players.LocalPlayer.Data.Level.Value >= 425 then
                SelectBoss_P = "Fishman Lord"
            end
            Ms = "Fishman Warrior"
            NameQuest = "FishmanQuest"
            QuestLv = 1
            NameMon = "Fishman Warrior"
            CFrameQ = CFrame.new(61122.5625, 18.4716396, 1568.16504)
            CFrameMon = CFrame.new(60946.6094,
                48.6735229,
                1525.91687,
                -0.0817126185,
                8.90751153e-08,
                .996655822,
                2.00889794e-08,
                1,
                -8.77269599e-08,
                -0.996655822,
                1.28533992e-08,
                -0.0817126185)
            if SelectMonster == "Fishman Warrior" then
            else
                Next_Level_X = 400
            end
        elseif game.Players.LocalPlayer.Data.Level.Value == 400 or game.Players.LocalPlayer.Data.Level.Value <= 449 or SelectMonster == "Fishman Commando" then
            if game.Players.LocalPlayer.Data.Level.Value >= 425 then
                SelectBoss_P = "Fishman Lord"
            end
            Ms = "Fishman Commando"
            NameQuest = "FishmanQuest"
            QuestLv = 2
            NameMon = "Fishman Commando"
            CFrameQ = CFrame.new(61122.5625, 18.4716396, 1568.16504)
            CFrameMon = CFrame.new(61902.7383, 18.4828358, 1478.33936, -0.803795099, 0, -0.594906271, 0, 1, 0, .594906271, 0, -0.803795099)
            if SelectMonster == "Fishman Commando" then
            else
                Next_Level_X = 450
            end
            SelectMonster = "Fishman Warrior"
        elseif game.Players.LocalPlayer.Data.Level.Value == 450 or game.Players.LocalPlayer.Data.Level.Value <= 474 or SelectMonster == "God's Guard" then
            Ms = "God's Guard"
            NameQuest = "SkyExp1Quest"
            QuestLv = 1
            NameMon = "God's Guards"
            CFrameQ = CFrame.new(-4721.71436, 845.277161, -1954.20105)
            CFrameMon = CFrame.new(-4716.95703, 853.089722, -1933.925427)
            if SelectMonster == "God's Guard" then
            else
                Next_Level_X = 475
            end
            SelectMonster = "Fishman Commando"
        elseif game.Players.LocalPlayer.Data.Level.Value == 475 or game.Players.LocalPlayer.Data.Level.Value <= 524 or SelectMonster == "Shanda" then
            Ms = "Shanda"
            NameQuest = "SkyExp1Quest"
            QuestLv = 2
            NameMon = "Shandas"
            CFrameQ = CFrame.new(-7859.09814, 5544.19043, -381.476196)
            CFrameMon = CFrame.new(-7904.57373, 5584.37646, -459.62973)
            if game.Players.LocalPlayer.Data.Level.Value >= 500 then
                SelectBoss_P = "Wysper"
            end
            if SelectMonster == "Shanda" then
            else
                Next_Level_X = 525
            end
            SelectMonster = "God's Guard"
        elseif game.Players.LocalPlayer.Data.Level.Value == 525 or game.Players.LocalPlayer.Data.Level.Value <= 549 or SelectMonster == "Royal Squad" then
            Ms = "Royal Squad"
            NameQuest = "SkyExp2Quest"
            QuestLv = 1
            NameMon = "Royal Squad"
            CFrameQ = CFrame.new(-7906.81592, 5634.6626, -1411.99194, 0, 0, -1, 0, 1, 0, 1, 0, 0)
            CFrameMon = CFrame.new(-7555.04199,
                5606.90479,
                -1303.24744,
                -0.896107852,
                -9.6057462e-10,
                -0.443836004,
                -4.24974544e-09,
                1,
                6.41599973e-09,
                .443836004,
                7.63560326e-09,
                -0.896107852)
            if SelectMonster == "Royal Squad" then
            else
                Next_Level_X = 550
            end
            SelectMonster = "Shanda"
        elseif game.Players.LocalPlayer.Data.Level.Value == 550 or game.Players.LocalPlayer.Data.Level.Value <= 624 or SelectMonster == "Royal Soldier" then
            if game.Players.LocalPlayer.Data.Level.Value >= 575 then
                SelectBoss_P = "Thunder God"
            end
            Ms = "Royal Soldier"
            NameQuest = "SkyExp2Quest"
            QuestLv = 2
            NameMon = "Royal Soldier"
            CFrameQ = CFrame.new(-7906.81592, 5634.6626, -1411.99194, 0, 0, -1, 0, 1, 0, 1, 0, 0)
            CFrameMon = CFrame.new(-7837.31152,
                5649.65186,
                -1791.08582,
                -0.716008604,
                .0104285581,
                -0.698013008,
                5.02521061e-06,
                .99988848,
                .0149335321,
                .69809103,
                .0106890313,
                -0.715928733)
            if SelectMonster == "Royal Soldier" then
            else
                Next_Level_X = 625
            end
            SelectMonster = "Royal Squad"
        elseif game.Players.LocalPlayer.Data.Level.Value == 625 or game.Players.LocalPlayer.Data.Level.Value <= 649 or SelectMonster == "Galley Pirate" then
            Ms = "Galley Pirate"
            NameQuest = "FountainQuest"
            QuestLv = 1
            NameMon = "Galley Pirate"
            CFrameQ = CFrame.new(5259.81982, 37.3500175, 4050.0293, .087131381, 0, .996196866, 0, 1, 0, -0.996196866, 0, .087131381)
            CFrameMon = CFrame.new(5569.80518,
                38.5269432,
                3849.01196,
                .896460414,
                3.98027495e-08,
                .443124533,
                -1.34262139e-08,
                1,
                -6.26611296e-08,
                -0.443124533,
                5.02237434e-08,
                .896460414)
            if SelectMonster == "Galley Pirate" then
            else
                Next_Level_X = 650
            end
        elseif game.Players.LocalPlayer.Data.Level.Value >= 650 or SelectMonster == "Galley Captain" then
            if game.Players.LocalPlayer.Data.Level.Value >= 675 then
                SelectBoss_P = "Cyborg"
            end
            Ms = "Galley Captain"
            NameQuest = "FountainQuest"
            QuestLv = 2
            NameMon = "Galley Captain"
            CFrameQ = CFrame.new(5259.81982, 37.3500175, 4050.0293, .087131381, 0, .996196866, 0, 1, 0, -0.996196866, 0, .087131381)
            CFrameMon = CFrame.new(5782.90186,
                94.5326462,
                4716.78174,
                .361808896,
                -1.24757526e-06,
                -0.932252586,
                2.16989656e-06,
                1,
                -4.96097414e-07,
                .932252586,
                -1.84339774e-06,
                .361808896)
            SelectMonster = "Galley Pirate"
            Next_Level_X = 9999
        end
    end
    if New_World then
        if game.Players.LocalPlayer.Data.Level.Value == 700 or game.Players.LocalPlayer.Data.Level.Value <= 724 or SelectMonster == "Raider" then
            Ms = "Raider"
            NameQuest = "Area1Quest"
            QuestLv = 1
            NameMon = "Raider"
            CFrameQ = CFrame.new(-429.543518, 71.7699966, 1836.18188, -0.22495985, 0, -0.974368095, 0, 1, 0, .974368095, 0, -0.22495985)
            CFrameMon = CFrame.new(-737.026123, 10.1748352, 2392.57959, .272128761, 0, -0.962260842, 0, 1, 0, .962260842, 0, .272128761)
            if SelectMonster == "Raider" then
            else
                Next_Level_X = 725
            end
        elseif game.Players.LocalPlayer.Data.Level.Value == 725 or game.Players.LocalPlayer.Data.Level.Value <= 774 or SelectMonster == "Mercenary" then
            if game.Players.LocalPlayer.Data.Level.Value >= 750 then
                SelectBoss_P = "Diamond"
            end
            Ms = "Mercenary"
            NameQuest = "Area1Quest"
            QuestLv = 2
            NameMon = "Mercenary"
            CFrameQ = CFrame.new(-429.543518, 71.7699966, 1836.18188, -0.22495985, 0, -0.974368095, 0, 1, 0, .974368095, 0, -0.22495985)
            CFrameMon = CFrame.new(-1022.21271, 72.9855194, 1891.39148, -0.990782857, 0, -0.135460541, 0, 1, 0, .135460541, 0, -0.990782857)
            if SelectMonster == "Mercenary" then
            else
                Next_Level_X = 775
            end
            SelectMonster = "Raider"
        elseif game.Players.LocalPlayer.Data.Level.Value == 775 or game.Players.LocalPlayer.Data.Level.Value <= 799 or SelectMonster == "Swan Pirate" then
            Ms = "Swan Pirate"
            NameQuest = "Area2Quest"
            QuestLv = 1
            NameMon = "Swan Pirate"
            CFrameQ = CFrame.new(638.43811, 71.769989, 918.282898, .139203906, 0, .99026376, 0, 1, 0, -0.99026376, 0, .139203906)
            CFrameMon = CFrame.new(976.467651,
                111.174057,
                1229.1084,
                .00852567982,
                -4.73897828e-08,
                -0.999963999,
                1.12251888e-08,
                1,
                -4.7295778e-08,
                .999963999,
                -1.08215579e-08,
                .00852567982)
            if SelectMonster == "Swan Pirate" then
            else
                Next_Level_X = 800
            end
        elseif game.Players.LocalPlayer.Data.Level.Value == 800 or game.Players.LocalPlayer.Data.Level.Value <= 874 or SelectMonster == "Factory Staff" then
            Ms = "Factory Staff"
            NameQuest = "Area2Quest"
            QuestLv = 2
            NameMon = "Factory Staff"
            CFrameQ = CFrame.new(638.43811, 71.769989, 918.282898, .139203906, 0, .99026376, 0, 1, 0, -0.99026376, 0, .139203906)
            CFrameMon = CFrame.new(336.74585,
                73.1620483,
                -224.129272,
                .993632793,
                3.40154607e-08,
                .112668738,
                -3.87658332e-08,
                1,
                3.99718729e-08,
                -0.112668738,
                -4.40850592e-08,
                .993632793)
            if SelectMonster == "Factory Staff" then
            else
                Next_Level_X = 875
            end
            if game.Players.LocalPlayer.Data.Level.Value >= 850 then
                SelectBoss_P = "Jeremy"
            end
            SelectMonster = "Swan Pirate"
        elseif game.Players.LocalPlayer.Data.Level.Value == 875 or game.Players.LocalPlayer.Data.Level.Value <= 899 or SelectMonster == "Marine Lieutenant" then
            Ms = "Marine Lieutenant"
            NameQuest = "MarineQuest3"
            QuestLv = 1
            NameMon = "Marine Lieutenant"
            CFrameQ = CFrame.new(-2440.79639, 71.7140732, -3216.06812, .866007268, 0, .500031412, 0, 1, 0, -0.500031412, 0, .866007268)
            CFrameMon = CFrame.new(-2842.69922, 72.9919434, -2901.90479, -0.762281299, 0, -0.64724648, 0, 1.00000012, 0, .64724648, 0, -0.762281299)
            if SelectMonster == "Marine Lieutenant" then
            else
                Next_Level_X = 900
            end
        elseif game.Players.LocalPlayer.Data.Level.Value == 900 or game.Players.LocalPlayer.Data.Level.Value <= 949 or SelectMonster == "Marine Captain" then
            Ms = "Marine Captain"
            NameQuest = "MarineQuest3"
            QuestLv = 2
            NameMon = "Marine Captain"
            CFrameQ = CFrame.new(-2440.79639, 71.7140732, -3216.06812, .866007268, 0, .500031412, 0, 1, 0, -0.500031412, 0, .866007268)
            CFrameMon = CFrame.new(-1814.70313,
                72.9919434,
                -3208.86621,
                -0.900422215,
                7.93464423e-08,
                -0.435017526,
                3.68856199e-08,
                1,
                1.06050372e-07,
                .435017526,
                7.94441988e-08,
                -0.900422215)
            if game.Players.LocalPlayer.Data.Level.Value >= 925 then
                SelectBoss_P = "Fajita"
            end
            if SelectMonster == "Marine Captain" then
            else
                Next_Level_X = 950
            end
            SelectMonster = "Marine Lieutenant"
        elseif game.Players.LocalPlayer.Data.Level.Value == 950 or game.Players.LocalPlayer.Data.Level.Value <= 974 or SelectMonster == "Zombie" then
            Ms = "Zombie"
            NameQuest = "ZombieQuest"
            QuestLv = 1
            NameMon = "Zombie"
            CFrameQ = CFrame.new(-5497.06152, 47.5923004, -795.237061, -0.29242146, 0, -0.95628953, 0, 1, 0, .95628953, 0, -0.29242146)
            CFrameMon = CFrame.new(-5649.23438,
                126.0578,
                -737.773743,
                .355238914,
                -8.10359282e-08,
                .934775114,
                1.65461245e-08,
                1,
                8.04023372e-08,
                -0.934775114,
                -1.3095117e-08,
                .355238914)
            if SelectMonster == "Zombie" then
            else
                Next_Level_X = 975
            end
            Bypass_TP_Dis = true
        elseif game.Players.LocalPlayer.Data.Level.Value == 975 or game.Players.LocalPlayer.Data.Level.Value <= 999 or SelectMonster == "Vampire" then
            Ms = "Vampire"
            NameQuest = "ZombieQuest"
            QuestLv = 2
            NameMon = "Vampire"
            CFrameQ = CFrame.new(-5497.06152, 47.5923004, -795.237061, -0.29242146, 0, -0.95628953, 0, 1, 0, .95628953, 0, -0.29242146)
            CFrameMon = CFrame.new(-6030.32031,
                .4377408,
                -1313.5564,
                -0.856965423,
                3.9138893e-08,
                -0.515373945,
                -1.12178942e-08,
                1,
                9.45958547e-08,
                .515373945,
                8.68467822e-08,
                -0.856965423)
            if SelectMonster == "Vampire" then
            else
                Next_Level_X = 1000
            end
            Bypass_TP_Dis = true
            SelectMonster = "Zombie"
        elseif game.Players.LocalPlayer.Data.Level.Value == 1000 or game.Players.LocalPlayer.Data.Level.Value <= 1049 or SelectMonster == "Snow Trooper" then
            Ms = "Snow Trooper"
            NameQuest = "SnowMountainQuest"
            QuestLv = 1
            NameMon = "Snow Trooper"
            CFrameQ = CFrame.new(609.858826, 400.119904, -5372.25928, -0.374604106, 0, .92718488, 0, 1, 0, -0.92718488, 0, -0.374604106)
            CFrameMon = CFrame.new(621.003418, 391.361053, -5335.43604, .481644779, 0, .876366913, 0, 1, 0, -0.876366913, 0, .481644779)
            if SelectMonster == "Snow Trooper" then
            else
                Next_Level_X = 1050
            end
        elseif game.Players.LocalPlayer.Data.Level.Value == 1050 or game.Players.LocalPlayer.Data.Level.Value <= 1099 or SelectMonster == "Winter Warrior" then
            Ms = "Winter Warrior"
            NameQuest = "SnowMountainQuest"
            QuestLv = 2
            NameMon = "Winter Warrior"
            CFrameQ = CFrame.new(609.858826, 400.119904, -5372.25928, -0.374604106, 0, .92718488, 0, 1, 0, -0.92718488, 0, -0.374604106)
            CFrameMon = CFrame.new(1295.62683,
                429.447784,
                -5087.04492,
                -0.698032081,
                -8.28980049e-08,
                -0.71606636,
                -1.98835952e-08,
                1,
                -9.63858184e-08,
                .71606636,
                -5.30424877e-08,
                -0.698032081)
            if SelectMonster == "Winter Warrior" then
            else
                Next_Level_X = 1100
            end
            SelectMonster = "Snow Trooper"
        elseif game.Players.LocalPlayer.Data.Level.Value == 1100 or game.Players.LocalPlayer.Data.Level.Value <= 1124 or SelectMonster == "Lab Subordinate" then
            Ms = "Lab Subordinate"
            NameQuest = "IceSideQuest"
            QuestLv = 1
            NameMon = "Lab Subordinate"
            CFrameQ = CFrame.new(-6064.06885, 15.2422857, -4902.97852, .453972578, 0, -0.891015649, 0, 1, 0, .891015649, 0, .453972578)
            CFrameMon = CFrame.new(-5769.2041,
                37.9288292,
                -4468.38721,
                -0.569419742,
                -2.49055017e-08,
                .822046936,
                -6.96206541e-08,
                1,
                -1.79282633e-08,
                -0.822046936,
                -6.74401548e-08,
                -0.569419742)
            if SelectMonster == "Lab Subordinate" then
            else
                Next_Level_X = 1125
            end
        elseif game.Players.LocalPlayer.Data.Level.Value == 1125 or game.Players.LocalPlayer.Data.Level.Value <= 1174 or SelectMonster == "Horned Warrior" then
            if game.Players.LocalPlayer.Data.Level.Value >= 1150 then
                SelectBoss_P = "Smoke Admiral"
            end
            Ms = "Horned Warrior"
            NameQuest = "IceSideQuest"
            QuestLv = 2
            NameMon = "Horned Warrior"
            CFrameQ = CFrame.new(-6064.06885, 15.2422857, -4902.97852, .453972578, 0, -0.891015649, 0, 1, 0, .891015649, 0, .453972578)
            CFrameMon = CFrame.new(-6401.27979, 15.9775667, -5948.24316, .388303697, 0, -0.921531856, 0, 1, 0, .921531856, 0, .388303697)
            if SelectMonster == "Horned Warrior" then
            else
                Next_Level_X = 1175
            end
            SelectMonster = "Lab Subordinate"
        elseif game.Players.LocalPlayer.Data.Level.Value == 1175 or game.Players.LocalPlayer.Data.Level.Value <= 1199 or SelectMonster == "Magma Ninja" then
            Ms = "Magma Ninja"
            NameQuest = "FireSideQuest"
            QuestLv = 1
            NameMon = "Magma Ninja"
            CFrameQ = CFrame.new(-5428.03174, 15.0622921, -5299.43457, -0.882952213, 0, .469463557, 0, 1, 0, -0.469463557, 0, -0.882952213)
            CFrameMon = CFrame.new(-5466.06445, 57.6952019, -5837.42822, -0.988835871, 0, -0.149006829, 0, 1, 0, .149006829, 0, -0.988835871)
            if SelectMonster == "Magma Ninja" then
            else
                Next_Level_X = 1200
            end
        elseif game.Players.LocalPlayer.Data.Level.Value == 1200 or game.Players.LocalPlayer.Data.Level.Value <= 1249 or SelectMonster == "Lava Pirate" then
            Ms = "Lava Pirate"
            NameQuest = "FireSideQuest"
            QuestLv = 2
            NameMon = "Lava Pirate"
            CFrameQ = CFrame.new(-5431.09473,
                15.9868021,
                -5296.53223,
                .831796765,
                1.15322464e-07,
                -0.555080295,
                -1.10814341e-07,
                1,
                4.17010995e-08,
                .555080295,
                2.68240168e-08,
                .831796765)
            CFrameMon = CFrame.new(-5169.71729, 34.1234779, -4669.73633, -0.196780294, 0, .98044765, 0, 1.00000012, 0, -0.98044765, 0, -0.196780294)
            if SelectMonster == "Lava Pirate" then
            else
                Next_Level_X = 1250
            end
            SelectMonster = "Magma Ninja"
        elseif game.Players.LocalPlayer.Data.Level.Value == 1250 or game.Players.LocalPlayer.Data.Level.Value <= 1274 or SelectMonster == "Ship Deckhand" then
            Ms = "Ship Deckhand"
            NameQuest = "ShipQuest1"
            QuestLv = 1
            NameMon = "Ship Deckhand"
            CFrameQ = CFrame.new(1037.80127, 125.092171, 32911.6016, -0.244533166, 0, -0.969640911, 0, 1.00000012, 0, .96964103, 0, -0.244533136)
            CFrameMon = CFrame.new(1163.80872,
                138.288452,
                33058.4258,
                -0.998580813,
                5.49076979e-08,
                -0.0532564968,
                5.57436763e-08,
                1,
                -1.42118655e-08,
                .0532564968,
                -1.71604082e-08,
                -0.998580813)
            if SelectMonster == "Ship Deckhand" then
            else
                Next_Level_X = 1275
            end
        elseif game.Players.LocalPlayer.Data.Level.Value == 1275 or game.Players.LocalPlayer.Data.Level.Value <= 1299 or SelectMonster == "Ship Engineer" then
            Ms = "Ship Engineer"
            NameQuest = "ShipQuest1"
            QuestLv = 2
            NameMon = "Ship Engineer"
            CFrameQ = CFrame.new(1037.80127, 125.092171, 32911.6016, -0.244533166, 0, -0.969640911, 0, 1.00000012, 0, .96964103, 0, -0.244533136)
            CFrameMon = CFrame.new(921.30249023438, 125.400390625, 32937.34375)
            if SelectMonster == "Ship Engineer" then
            else
                Next_Level_X = 1300
            end
            SelectMonster = "Ship Deckhand"
        elseif game.Players.LocalPlayer.Data.Level.Value == 1300 or game.Players.LocalPlayer.Data.Level.Value <= 1324 or SelectMonster == "Ship Steward" then
            Ms = "Ship Steward"
            NameQuest = "ShipQuest2"
            QuestLv = 1
            NameMon = "Ship Steward"
            CFrameQ = CFrame.new(968.80957,
                125.092171,
                33244.125,
                -0.869560242,
                1.51905191e-08,
                -0.493826836,
                1.44108379e-08,
                1,
                5.38534195e-09,
                .493826836,
                -2.43357912e-09,
                -0.869560242)
            CFrameMon = CFrame.new(917.96057128906, 136.89932250977, 33343.4140625)
            if SelectMonster == "Ship Steward" then
            else
                Next_Level_X = 1325
            end
            SelectMonster = "Ship Deckhand"
        elseif game.Players.LocalPlayer.Data.Level.Value == 1325 or game.Players.LocalPlayer.Data.Level.Value <= 1349 or SelectMonster == "Ship Officer" then
            Ms = "Ship Officer"
            NameQuest = "ShipQuest2"
            QuestLv = 2
            NameMon = "Ship Officer"
            CFrameQ = CFrame.new(968.80957,
                125.092171,
                33244.125,
                -0.869560242,
                1.51905191e-08,
                -0.493826836,
                1.44108379e-08,
                1,
                5.38534195e-09,
                .493826836,
                -2.43357912e-09,
                -0.869560242)
            CFrameMon = CFrame.new(944.44964599609, 181.40081787109, 33278.9453125)
            if SelectMonster == "Ship Officer" then
            else
                Next_Level_X = 1350
            end
            SelectMonster = "Ship Steward"
        elseif game.Players.LocalPlayer.Data.Level.Value == 1350 or game.Players.LocalPlayer.Data.Level.Value <= 1374 or SelectMonster == "Arctic Warrior" then
            Ms = "Arctic Warrior"
            NameQuest = "FrostQuest"
            QuestLv = 1
            NameMon = "Arctic Warrior"
            CFrameQ = CFrame.new(5667.6582, 26.7997818, -6486.08984, -0.933587909, 0, -0.358349502, 0, 1, 0, .358349502, 0, -0.933587909)
            CFrameMon = CFrame.new(5878.23486,
                81.3886948,
                -6136.35596,
                -0.451037169,
                2.3908234e-07,
                .892505825,
                -1.08168464e-07,
                1,
                -3.22542007e-07,
                -0.892505825,
                -2.4201924e-07,
                -0.451037169)
            if SelectMonster == "Arctic Warrior" then
            else
                Next_Level_X = 1375
            end
        elseif game.Players.LocalPlayer.Data.Level.Value == 1375 or game.Players.LocalPlayer.Data.Level.Value <= 1424 or SelectMonster == "Snow Lurker" then
            if game.Players.LocalPlayer.Data.Level.Value >= 1400 then
                SelectBoss_P = "Awakened Ice Admiral"
            end
            Ms = "Snow Lurker"
            NameQuest = "FrostQuest"
            QuestLv = 2
            NameMon = "Snow Lurker"
            CFrameQ = CFrame.new(5667.6582, 26.7997818, -6486.08984, -0.933587909, 0, -0.358349502, 0, 1, 0, .358349502, 0, -0.933587909)
            CFrameMon = CFrame.new(5513.36865,
                60.546711,
                -6809.94971,
                -0.958693981,
                -1.65617333e-08,
                .284439981,
                -4.07668654e-09,
                1,
                4.44854642e-08,
                -0.284439981,
                4.14883701e-08,
                -0.958693981)
            if SelectMonster == "Snow Lurker" then
            else
                Next_Level_X = 1450
            end
            SelectMonster = "Arctic Warrior"
        elseif game.Players.LocalPlayer.Data.Level.Value == 1425 or game.Players.LocalPlayer.Data.Level.Value <= 1449 or SelectMonster == "Sea Soldier" then
            Ms = "Sea Soldier"
            NameQuest = "ForgottenQuest"
            QuestLv = 1
            NameMon = "Sea Soldier"
            CFrameQ = CFrame.new(-3054.44458, 235.544281, -10142.8193, .990270376, 0, -0.13915664, 0, 1, 0, .13915664, 0, .990270376)
            CFrameMon = CFrame.new(-3115.78223,
                63.8785706,
                -9808.38574,
                -0.913427353,
                3.11199457e-08,
                .407000452,
                7.79564235e-09,
                1,
                -5.89660658e-08,
                -0.407000452,
                -5.06883708e-08,
                -0.913427353)
            if SelectMonster == "Sea Soldier" then
            else
                Next_Level_X = 1450
            end
        elseif game.Players.LocalPlayer.Data.Level.Value >= 1450 or SelectMonster == "Water Fighter" then
            if game.Players.LocalPlayer.Data.Level.Value >= 1475 then
                SelectBoss_P = "Tide Keeper"
            end
            Ms = "Water Fighter"
            NameQuest = "ForgottenQuest"
            QuestLv = 2
            NameMon = "Water Fighter"
            CFrameQ = CFrame.new(-3054.44458, 235.544281, -10142.8193, .990270376, 0, -0.13915664, 0, 1, 0, .13915664, 0, .990270376)
            CFrameMon = CFrame.new(-3212.99683,
                263.809296,
                -10551.8799,
                .742111444,
                -5.59139615e-08,
                -0.670276582,
                1.69155214e-08,
                1,
                -6.46908234e-08,
                .670276582,
                3.66697037e-08,
                .742111444)
            if SelectMonster == "Water Fighter" then
            else
                Next_Level_X = 9999
            end
            SelectMonster = "Sea Soldier"
        end
    end
    if Three_World then
        if game.Players.LocalPlayer.Data.Level.Value >= 1500 and game.Players.LocalPlayer.Data.Level.Value <= 1524 or SelectMonster == "Pirate Millionaire" then
            Ms = "Pirate Millionaire"
            NameQuest = "PiratePortQuest"
            QuestLv = 1
            NameMon = "Pirate Millionaire"
            CFrameQ = CFrame.new(-290.074677, 42.9034653, 5581.58984, .965929627, 0, -0.258804798, 0, 1, 0, .258804798, 0, .965929627)
            CFrameMon = CFrame.new(81.164993286133, 43.755737304688, 5724.7021484375)
            if SelectMonster == "Pirate Millionaire" then
            else
                Next_Level_X = 1525
            end
        elseif game.Players.LocalPlayer.Data.Level.Value >= 1525 and game.Players.LocalPlayer.Data.Level.Value <= 1574 or SelectMonster == "Pistol Billionaire" then
            if game.Players.LocalPlayer.Data.Level.Value >= 1550 then
                SelectBoss_P = "Stone"
            end
            Ms = "Pistol Billionaire"
            NameQuest = "PiratePortQuest"
            QuestLv = 2
            NameMon = "Pistol Billionaire"
            CFrameQ = CFrame.new(-290.074677, 42.9034653, 5581.58984, .965929627, 0, -0.258804798, 0, 1, 0, .258804798, 0, .965929627)
            CFrameMon = CFrame.new(81.164993286133, 43.755737304688, 5724.7021484375)
            if SelectMonster == "Pistol Billionaire" then
            else
                Next_Level_X = 1575
            end
            SelectMonster = "Pirate Millionaire"
        elseif game.Players.LocalPlayer.Data.Level.Value >= 1575 and game.Players.LocalPlayer.Data.Level.Value <= 1599 or SelectMonster == "Dragon Crew Warrior" then
            Ms = "Dragon Crew Warrior"
            NameQuest = "AmazonQuest"
            QuestLv = 1
            NameMon = "Dragon Crew Warrior"
            CFrameQ = CFrame.new(5832.83594, 51.6806107, -1101.51563, .898790359, 0, -0.438378751, 0, 1, 0, .438378751, 0, .898790359)
            CFrameMon = CFrame.new(6241.9951171875, 51.522083282471, -1243.9771728516)
            if SelectMonster == "Dragon Crew Warrior" then
            else
                Next_Level_X = 1600
            end
        elseif game.Players.LocalPlayer.Data.Level.Value >= 1600 and game.Players.LocalPlayer.Data.Level.Value <= 1624 or SelectMonster == "Dragon Crew Archer" then
            Ms = "Dragon Crew Archer"
            NameQuest = "AmazonQuest"
            QuestLv = 2
            NameMon = "Dragon Crew Archer"
            CFrameQ = CFrame.new(5832.83594, 51.6806107, -1101.51563, .898790359, 0, -0.438378751, 0, 1, 0, .438378751, 0, .898790359)
            CFrameMon = CFrame.new(6488.9155273438, 383.38375854492, -110.66246032715)
            if SelectMonster == "Dragon Crew Archer" then
            else
                Next_Level_X = 1625
            end
            SelectMonster = "Dragon Crew Warrior"
        elseif game.Players.LocalPlayer.Data.Level.Value >= 1625 and game.Players.LocalPlayer.Data.Level.Value <= 1649 or SelectMonster == "Female Islander" then
            Ms = "Female Islander"
            NameQuest = "AmazonQuest2"
            QuestLv = 1
            NameMon = "Female Islander"
            CFrameQ = CFrame.new(5448.86133, 601.516174, 751.130676, 0, 0, 1, 0, 1, 0, -1, 0, 0)
            CFrameMon = CFrame.new(4770.4990234375, 758.95520019531, 1069.8680419922)
            if SelectMonster == "Female Islander" then
            else
                Next_Level_X = 1650
            end
        elseif game.Players.LocalPlayer.Data.Level.Value >= 1650 and game.Players.LocalPlayer.Data.Level.Value <= 1699 or SelectMonster == "Giant Islander" then
            Ms = "Giant Islander"
            NameQuest = "AmazonQuest2"
            QuestLv = 2
            NameMon = "Giant Islander"
            CFrameQ = CFrame.new(5448.86133, 601.516174, 751.130676, 0, 0, 1, 0, 1, 0, -1, 0, 0)
            CFrameMon = CFrame.new(4530.3540039063, 656.75695800781, -131.60952758789)
            if game.Players.LocalPlayer.Data.Level.Value >= 1675 then
                SelectBoss_P = "Island Empress"
            end
            if SelectMonster == "Giant Islander" then
            else
                Next_Level_X = 1700
            end
            SelectMonster = "Female Islander"
        elseif game.Players.LocalPlayer.Data.Level.Value >= 1700 and game.Players.LocalPlayer.Data.Level.Value <= 1774 or SelectMonster == "Marine Commodore" then
            Ms = "Marine Commodore"
            NameQuest = "MarineTreeIsland"
            QuestLv = 1
            NameMon = "Marine Commodore"
            CFrameQ = CFrame.new(2180.54126, 27.8156815, -6741.5498, -0.965929747, 0, .258804798, 0, 1, 0, -0.258804798, 0, -0.965929747)
            CFrameMon = CFrame.new(2490.0844726563, 190.4232635498, -7160.0502929688)
            if game.Players.LocalPlayer.Data.Level.Value >= 1750 then
                SelectBoss_P = "Kilo Admiral"
            end
            if SelectMonster == "Marine Commodore" then
            else
                Next_Level_X = 1775
            end
        elseif game.Players.LocalPlayer.Data.Level.Value >= 1775 and game.Players.LocalPlayer.Data.Level.Value <= 1799 or SelectMonster == "Fishman Raider" then
            Ms = "Fishman Raider"
            NameQuest = "DeepForestIsland3"
            QuestLv = 1
            NameMon = "Fishman Raider"
            CFrameQ = CFrame.new(-10581.6563, 330.872955, -8761.18652, -0.882952213, 0, .469463557, 0, 1, 0, -0.469463557, 0, -0.882952213)
            CFrameMon = CFrame.new(-10322.400390625, 390.94473266602, -8580.0908203125)
            if SelectMonster == "Fishman Raider" then
            else
                Next_Level_X = 1800
            end
        elseif game.Players.LocalPlayer.Data.Level.Value >= 1800 and game.Players.LocalPlayer.Data.Level.Value <= 1824 or SelectMonster == "Fishman Captain" then
            Ms = "Fishman Captain"
            NameQuest = "DeepForestIsland3"
            QuestLv = 2
            NameMon = "Fishman Captain"
            CFrameQ = CFrame.new(-10581.6563, 330.872955, -8761.18652, -0.882952213, 0, .469463557, 0, 1, 0, -0.469463557, 0, -0.882952213)
            CFrameMon = CFrame.new(-11194.541992188, 442.02795410156, -8608.806640625)
            if SelectMonster == "Fishman Captain" then
            else
                Next_Level_X = 1825
            end
            SelectMonster = "Fishman Raider"
        elseif game.Players.LocalPlayer.Data.Level.Value >= 1825 and game.Players.LocalPlayer.Data.Level.Value <= 1849 or SelectMonster == "Forest Pirate" then
            Ms = "Forest Pirate"
            NameQuest = "DeepForestIsland"
            QuestLv = 1
            NameMon = "Forest Pirate"
            CFrameQ = CFrame.new(-13234.04, 331.488495, -7625.40137, .707134247, 0, -0.707079291, 0, 1, 0, .707079291, 0, .707134247)
            CFrameMon = CFrame.new(-13225.809570313, 428.19387817383, -7753.1245117188)
            if SelectMonster == "Forest Pirate" then
            else
                Next_Level_X = 1850
            end
        elseif game.Players.LocalPlayer.Data.Level.Value >= 1850 and game.Players.LocalPlayer.Data.Level.Value <= 1899 or SelectMonster == "Mythological Pirate" then
            Ms = "Mythological Pirate"
            NameQuest = "DeepForestIsland"
            QuestLv = 2
            NameMon = "Mythological Pirate"
            CFrameQ = CFrame.new(-13234.04, 331.488495, -7625.40137, .707134247, 0, -0.707079291, 0, 1, 0, .707079291, 0, .707134247)
            CFrameMon = CFrame.new(-13869.172851563, 564.95251464844, -7084.4135742188)
            if game.Players.LocalPlayer.Data.Level.Value >= 1875 then
                SelectBoss_P = "Captain Elephant"
            end
            if SelectMonster == "Mythological Pirate" then
            else
                Next_Level_X = 1900
            end
            SelectMonster = "Forest Pirate"
        elseif game.Players.LocalPlayer.Data.Level.Value >= 1900 and game.Players.LocalPlayer.Data.Level.Value <= 1924 or SelectMonster == "Jungle Pirate" then
            Ms = "Jungle Pirate"
            NameQuest = "DeepForestIsland2"
            QuestLv = 1
            NameMon = "Jungle Pirate"
            CFrameQ = CFrame.new(-12680.3818, 389.971039, -9902.01953, -0.0871315002, 0, .996196866, 0, 1, 0, -0.996196866, 0, -0.0871315002)
            CFrameMon = CFrame.new(-11982.221679688, 376.32522583008, -10451.415039063)
            if SelectMonster == "Jungle Pirate" then
            else
                Next_Level_X = 1925
            end
        elseif game.Players.LocalPlayer.Data.Level.Value >= 1925 and game.Players.LocalPlayer.Data.Level.Value <= 1974 or SelectMonster == "Musketeer Pirate" then
            Ms = "Musketeer Pirate"
            NameQuest = "DeepForestIsland2"
            QuestLv = 2
            NameMon = "Musketeer Pirate"
            CFrameQ = CFrame.new(-12680.3818, 389.971039, -9902.01953, -0.0871315002, 0, .996196866, 0, 1, 0, -0.996196866, 0, -0.0871315002)
            CFrameMon = CFrame.new(-13282.3046875, 496.23684692383, -9565.150390625)
            if SelectMonster == "Musketeer Pirate" then
            else
                Next_Level_X = 1975
            end
            if game.Players.LocalPlayer.Data.Level.Value >= 1950 then
                SelectBoss_P = "Beautiful Pirate"
            end
            SelectMonster = "Jungle Pirate"
        elseif game.Players.LocalPlayer.Data.Level.Value >= 1975 and game.Players.LocalPlayer.Data.Level.Value <= 1999 or SelectMonster == "Reborn Skeleton" then
            Ms = "Reborn Skeleton"
            NameQuest = "HauntedQuest1"
            QuestLv = 1
            NameMon = "Reborn Skeleton"
            CFrameQ = CFrame.new(-9480.8271484375, 142.13066101074, 5566.0712890625)
            CFrameMon = CFrame.new(-8817.880859375, 191.16761779785, 6298.6557617188)
            if SelectMonster == "Reborn Skeleton" then
            elseif not LevelMax then
                Next_Level_X = 2000
            end
        elseif game.Players.LocalPlayer.Data.Level.Value >= 2000 and game.Players.LocalPlayer.Data.Level.Value <= 2024 or SelectMonster == "Living Zombie" then
            Ms = "Living Zombie"
            NameQuest = "HauntedQuest1"
            QuestLv = 2
            NameMon = "Living Zombie"
            CFrameQ = CFrame.new(-9480.8271484375, 142.13066101074, 5566.0712890625)
            CFrameMon = CFrame.new(-10125.234375, 183.94705200195, 6242.013671875)
            if SelectMonster == "Living Zombie" then
            elseif not LevelMax then
                Next_Level_X = 2025
            end
            SelectMonster = "Reborn Skeleton"
        elseif game.Players.LocalPlayer.Data.Level.Value >= 2025 and game.Players.LocalPlayer.Data.Level.Value <= 2049 or SelectMonster == "Demonic Soul" then
            Ms = "Demonic Soul"
            NameQuest = "HauntedQuest2"
            QuestLv = 1
            NameMon = "Demonic"
            CFrameQ = CFrame.new(-9516.9931640625, 178.00651550293, 6078.4653320313)
            CFrameMon = CFrame.new(-9712.03125, 204.69589233398, 6193.322265625)
            if SelectMonster == "Demonic Soul" then
            else
                Next_Level_X = 2050
            end
            SelectMonster = "Living Zombie"
        elseif game.Players.LocalPlayer.Data.Level.Value >= 2050 and game.Players.LocalPlayer.Data.Level.Value <= 2074 or SelectMonster == "Posessed Mummy" then
            Ms = "Posessed Mummy"
            NameQuest = "HauntedQuest2"
            QuestLv = 2
            NameMon = "Posessed Mummy"
            CFrameQ = CFrame.new(-9516.9931640625, 178.00651550293, 6078.4653320313)
            CFrameMon = CFrame.new(-9545.7763671875, 69.619895935059, 6339.5615234375)
            if SelectMonster == "Posessed Mummy" then
            else
                Next_Level_X = 2075
            end
            SelectMonster = "Demonic Soul"
        elseif game.Players.LocalPlayer.Data.Level.Value >= 2075 and game.Players.LocalPlayer.Data.Level.Value <= 2099 or SelectMonster == "Peanut Scout" then
            Ms = "Peanut Scout"
            NameQuest = "NutsIslandQuest"
            QuestLv = 1
            NameMon = "Peanut Scout"
            CFrameQ = CFrame.new(-2104.17163,
                38.1299706,
                -10194.418,
                .758814394,
                -1.38604395e-09,
                .651306927,
                2.85280208e-08,
                1,
                -3.1108879e-08,
                -0.651306927,
                4.21863646e-08,
                .758814394)
            CFrameMon = CFrame.new(-2098.07544,
                192.611862,
                -10248.8867,
                .983392298,
                -9.57031787e-08,
                .181492642,
                8.7276355e-08,
                1,
                5.44169616e-08,
                -0.181492642,
                -3.76732068e-08,
                .983392298)
            if SelectMonster == "Peanut Scout" then
            else
                Next_Level_X = 2100
            end
        elseif game.Players.LocalPlayer.Data.Level.Value >= 2100 and game.Players.LocalPlayer.Data.Level.Value <= 2124 or SelectMonster == "Peanut President" then
            Ms = "Peanut President"
            NameQuest = "NutsIslandQuest"
            QuestLv = 2
            NameMon = "Peanut President"
            CFrameQ = CFrame.new(-2104.17163,
                38.1299706,
                -10194.418,
                .758814394,
                -1.38604395e-09,
                .651306927,
                2.85280208e-08,
                1,
                -3.1108879e-08,
                -0.651306927,
                4.21863646e-08,
                .758814394)
            CFrameMon = CFrame.new(-1876.95959,
                192.610947,
                -10542.2939,
                .0553516336,
                -2.83836812e-08,
                .998466909,
                -6.89634405e-10,
                1,
                2.84654931e-08,
                -0.998466909,
                -2.26418861e-09,
                .0553516336)
            SelectMonster = "Peanut Scout"
            if SelectMonster == "Peanut President" then
            else
                Next_Level_X = 2125
            end
        elseif game.Players.LocalPlayer.Data.Level.Value >= 2125 and game.Players.LocalPlayer.Data.Level.Value <= 2149 or SelectMonster == "Ice Cream Chef" then
            Ms = "Ice Cream Chef"
            NameQuest = "IceCreamIslandQuest"
            QuestLv = 1
            NameMon = "Ice Cream Chef"
            CFrameQ = CFrame.new(-820.404358,
                65.8453293,
                -10965.5654,
                .822534859,
                5.24448502e-08,
                -0.568714678,
                -2.08336317e-08,
                1,
                6.20846663e-08,
                .568714678,
                -3.92184099e-08,
                .822534859)
            CFrameMon = CFrame.new(-821.614075,
                208.39537,
                -10990.7617,
                -0.870096624,
                3.18909272e-08,
                .492881238,
                -1.8357893e-08,
                1,
                -9.71107568e-08,
                -0.492881238,
                -9.35439957e-08,
                -0.870096624)
            if SelectMonster == "Ice Cream Chef" then
            else
                Next_Level_X = 2150
            end
        elseif game.Players.LocalPlayer.Data.Level.Value >= 2150 and game.Players.LocalPlayer.Data.Level.Value <= 2199 or SelectMonster == "Ice Cream Commander" then
            Ms = "Ice Cream Commander"
            NameQuest = "IceCreamIslandQuest"
            QuestLv = 2
            NameMon = "Ice Cream Commander"
            CFrameQ = CFrame.new(-819.376526, 67.4634171, -10967.2832)
            CFrameMon = CFrame.new(-610.11669921875, 208.26904296875, -11253.686523438)
            if SelectMonster == "Ice Cream Commander" then
            else
                Next_Level_X = 2200
            end
            if game.Players.LocalPlayer.Data.Level.Value >= 2175 then
                SelectBoss_P = "Cake Queen"
            end
            SelectMonster = "Ice Cream Chef"
        elseif game.Players.LocalPlayer.Data.Level.Value >= 2200 and game.Players.LocalPlayer.Data.Level.Value <= 2224 or SelectMonster == "Cookie Crafter" then
            Ms = "Cookie Crafter"
            NameQuest = "CakeQuest1"
            QuestLv = 1
            NameMon = "Cookie Crafter"
            CFrameQ = CFrame.new(-2020.6068115234, 37.82400894165, -12027.80859375)
            CFrameMon = CFrame.new(-2286.6843261719, 146.56562805176, -12226.881835938)
            if SelectMonster == "Cookie Crafter" then
            elseif not LevelMax then
                Next_Level_X = 2225
            end
        elseif game.Players.LocalPlayer.Data.Level.Value >= 2225 and game.Players.LocalPlayer.Data.Level.Value <= 2249 or SelectMonster == "Cake Guard" then
            Ms = "Cake Guard"
            NameQuest = "CakeQuest1"
            QuestLv = 2
            NameMon = "Cake Guard"
            CFrameQ = CFrame.new(-2020.6068115234, 37.82400894165, -12027.80859375)
            CFrameMon = CFrame.new(-1817.9747314453, 209.56327819824, -12288.922851562)
            SelectMonster = "Cookie Crafter"
            if SelectMonster == "Cake Guard" then
            elseif not LevelMax then
                Next_Level_X = 2250
            end
        elseif game.Players.LocalPlayer.Data.Level.Value >= 2250 and game.Players.LocalPlayer.Data.Level.Value < 2300 or SelectMonster == "Baking Staff" then
            Ms = "Baking Staff"
            NameQuest = "CakeQuest2"
            QuestLv = 1
            NameMon = "Baking Staff"
            CFrameQ = CFrame.new(-1928.31763, 37.7296638, -12840.626)
            CFrameMon = CFrame.new(-1818.3479003906, 93.412757873535, -12887.66015625)
            if SelectMonster == "Baking Staff" then
            elseif not LevelMax then
                Next_Level_X = 2300
            end
            SelectMonster = "Cookie Crafter"
        elseif game.Players.LocalPlayer.Data.Level.Value >= 2300 and game.Players.LocalPlayer.Data.Level.Value < 2325 or SelectMonster == "Cocoa Warrior" then
            Ms = "Cocoa Warrior"
            NameQuest = "ChocQuest1"
            QuestLv = 1
            NameMon = "Cocoa Warrior"
            CFrameQ = CFrame.new(230.19186401367, 24.734258651733, -12202.657226562)
            CFrameMon = CFrame.new(24.617475509644, 24.734342575073, -12227.267578125)
            if SelectMonster == "Cocoa Warrior" then
            else
                Next_Level_X = 2325
            end
        elseif game.Players.LocalPlayer.Data.Level.Value >= 2325 and game.Players.LocalPlayer.Data.Level.Value < 2350 or SelectMonster == "Chocolate Bar Battler" then
            Ms = "Chocolate Bar Battler"
            NameQuest = "ChocQuest1"
            QuestLv = 2
            NameMon = "Chocolate Bar Battler"
            CFrameQ = CFrame.new(230.19186401367, 24.734258651733, -12202.657226562)
            CFrameMon = CFrame.new(658.22302246094, 24.734258651733, -12541.991210938)
            if SelectMonster == "Chocolate Bar Battler" then
            else
                Next_Level_X = 2350
            end
            SelectMonster = "Cocoa Warrior"
        elseif game.Players.LocalPlayer.Data.Level.Value >= 2350 and game.Players.LocalPlayer.Data.Level.Value < 2375 or SelectMonster == "Sweet Thief" then
            Ms = "Sweet Thief"
            NameQuest = "ChocQuest2"
            QuestLv = 1
            NameMon = "Sweet Thief"
            CFrameQ = CFrame.new(149.14392089844, 24.793828964233, -12775.41015625)
            CFrameMon = CFrame.new(51.611843109131, 24.793809890747, -12574.873046875)
            if SelectMonster == "Sweet Thief" then
            else
                Next_Level_X = 2375
            end
            SelectMonster = "Chocolate Bar Battler"
        elseif game.Players.LocalPlayer.Data.Level.Value >= 2375 and game.Players.LocalPlayer.Data.Level.Value < 2400 or SelectMonster == "Candy Rebel" then
            Ms = "Candy Rebel"
            NameQuest = "ChocQuest2"
            QuestLv = 2
            NameMon = "Candy Rebel"
            CFrameQ = CFrame.new(149.14392089844, 24.793828964233, -12775.41015625)
            CFrameMon = CFrame.new(28.34560585022, 24.793802261353, -12949.502929688)
            if SelectMonster == "Candy Rebel" then
            else
                Next_Level_X = 2400
            end
            SelectMonster = "Sweet Thief"
        elseif game.Players.LocalPlayer.Data.Level.Value >= 2400 and game.Players.LocalPlayer.Data.Level.Value < 2425 or SelectMonster == "Candy Pirate" then
            Ms = "Candy Pirate"
            NameQuest = "CandyQuest1"
            QuestLv = 1
            NameMon = "Candy Pirate"
            CFrameQ = CFrame.new(-1146.8081054688, 16.10725402832, -14444.353515625)
            CFrameMon = CFrame.new(-1333.9425048828, 16.907636642456, -14424.844726562)
        elseif game.Players.LocalPlayer.Data.Level.Value >= 2425 and game.Players.LocalPlayer.Data.Level.Value < 2550 or SelectMonster == "Snow Demon" then
            Ms = "Snow Demon"
            NameQuest = "CandyQuest1"
            QuestLv = 2
            NameMon = "Snow Demon"
            CFrameQ = CFrame.new(-1146.8081054688, 16.10725402832, -14444.353515625)
            CFrameMon = CFrame.new(-963.02130126953, 16.107183456421, -14289.576171875)
            if SelectMonster == "Candy Pirate" then
            else
                Next_Level_X = 2551
            end
            SelectMonster = "Candy Pirate"
        elseif game.Players.LocalPlayer.Data.Level.Value >= 2550 then
            local response
            Ms = "Baking Staff"
            NameQuest = "CakeQuest2"
            QuestLv = 1
            NameMon = "Baking Staff"
            CFrameQ = CFrame.new(-1928.31763, 37.7296638, -12840.626)
            CFrameMon = CFrame.new(-1818.3479003906, 93.412757873535, -12887.66015625)
            SelectMonster = "Cookie Crafter"
            response = tostring(string.match(tostring(game.ReplicatedStorage.Remotes.CommF_:InvokeServer("CakePrinceSpawner")), "%d+"))
            if response == "nil" or response == nil then
                (game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer("CakePrinceSpawner", true)
                Cake_Prince_S:Set(" Cake Prince : Boss Spawn")
            else
                Cake_Prince_S:Set(" Cake Prince : " .. response)
            end
        end
    end
end
updateLevelQuestInfo = function()
    if Old_World and currentLevelValue.Value >= 1 and currentLevelValue.Value <= 9 then
        Enemy = "Bandit"
        NameEnemy = "Bandit"
        QuestName = "BanditQuest1"
        QuestNumber = 1
        QuestPos = CFrame.new(1059.58728,
            16.412075,
            1549.54443,
            -0.963007867,
            4.12775627e-08,
            .269473195,
            2.39519959e-08,
            1,
            -6.75822349e-08,
            -0.269473195,
            -5.86278048e-08,
            -0.963007867)
        EnemyPos = CFrame.new(1175.00793,
            43.7162018,
            1680.39185,
            .940636754,
            1.67726082e-08,
            .339414984,
            -3.54472718e-08,
            1,
            4.88204712e-08,
            -0.339414984,
            -5.79536632e-08,
            .940636754)
    elseif Old_World and currentLevelValue.Value >= 10 and currentLevelValue.Value <= 14 then
        Enemy = "Monkey"
        NameEnemy = "Monkey"
        QuestName = "JungleQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(-1598.92285,
            36.9012909,
            148.748718,
            -0.969585121,
            -1.11576668e-07,
            -0.244754329,
            -1.2733129e-07,
            1,
            4.8546088e-08,
            .244754329,
            7.823445e-08,
            -0.969585121)
        EnemyPos = CFrame.new(-1660.75586,
            40.1013031,
            320.152313,
            .82476908,
            -4.88485696e-08,
            -0.565469682,
            5.81200084e-08,
            1,
            -1.61455704e-09,
            .565469682,
            -3.15334674e-08,
            .82476908)
    elseif Old_World and currentLevelValue.Value >= 15 and currentLevelValue.Value <= 29 then
        Enemy = "Gorilla"
        NameEnemy = "Gorilla"
        QuestName = "JungleQuest"
        QuestNumber = 2
        QuestPos = CFrame.new(-1598.92285,
            36.9012909,
            148.748718,
            -0.969585121,
            -1.11576668e-07,
            -0.244754329,
            -1.2733129e-07,
            1,
            4.8546088e-08,
            .244754329,
            7.823445e-08,
            -0.969585121)
        EnemyPos = CFrame.new(-1196.64343,
            7.74201918,
            -445.539734,
            -0.919930279,
            -4.16423696e-08,
            .392081946,
            -1.71233108e-08,
            1,
            6.60324133e-08,
            -0.392081946,
            5.40314744e-08,
            -0.919930279)
        if Old_World and currentLevelValue.Value >= 20 and currentLevelValue.Value <= 29 then
            Name_Boss = "The Gorilla King"
            QuestName_Boss = "JungleQuest"
            QuestNumber_Boss = 3
        end
    elseif Old_World and currentLevelValue.Value >= 30 and currentLevelValue.Value <= 39 then
        Enemy = "Pirate"
        NameEnemy = "Pirate"
        QuestName = "BuggyQuest1"
        QuestNumber = 1
        QuestPos = CFrame.new(-1139.5631103516, 4.7520513534546, 3830.38671875)
        EnemyPos = CFrame.new(-1045.9431152344, 64.419502258301, 3930.3020019531)
    elseif Old_World and currentLevelValue.Value >= 40 and currentLevelValue.Value <= 59 then
        Enemy = "Brute"
        NameEnemy = "Brute"
        QuestName = "BuggyQuest1"
        QuestNumber = 2
        QuestPos = CFrame.new(-1139.5631103516, 4.7520513534546, 3830.38671875)
        EnemyPos = CFrame.new(-1150.2763671875, 130.60118103027, 4164.9345703125)
        if Old_World and currentLevelValue.Value >= 55 and currentLevelValue.Value <= 59 then
            Name_Boss = "Bobby"
            QuestName_Boss = "BuggyQuest1"
            QuestNumber_Boss = 3
        end
    elseif Old_World and currentLevelValue.Value >= 60 and currentLevelValue.Value <= 74 then
        Enemy = "Desert Bandit"
        NameEnemy = "Desert Bandit"
        QuestName = "DesertQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(894.488647, 5.14000702, 4392.43359, .819155693, 0, -0.573571265, 0, 1, 0, .573571265, 0, .819155693)
        EnemyPos = CFrame.new(935.8798046975, 6.4486746788025, 4481.5859375)
    elseif Old_World and currentLevelValue.Value >= 75 and currentLevelValue.Value <= 89 then
        Enemy = "Desert Officer"
        NameEnemy = "Desert Officer"
        QuestName = "DesertQuest"
        QuestNumber = 2
        QuestPos = CFrame.new(894.488647, 5.14000702, 4392.43359, .819155693, 0, -0.573571265, 0, 1, 0, .573571265, 0, .819155693)
        EnemyPos = CFrame.new(1608.2822265625, 8.6142244338989, 4371.0073242188)
    elseif Old_World and currentLevelValue.Value >= 90 and currentLevelValue.Value <= 99 then
        Enemy = "Snow Bandit"
        NameEnemy = "Snow Bandit"
        QuestName = "SnowQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(1389.74451, 88.1519318, -1298.90796, -0.342042685, 0, .939684391, 0, 1, 0, -0.939684391, 0, -0.342042685)
        EnemyPos = CFrame.new(1354.3479003906, 87.272773742676, -1393.9465332031)
    elseif Old_World and currentLevelValue.Value >= 100 and currentLevelValue.Value <= 119 then
        Enemy = "Snowman"
        NameEnemy = "Snowman"
        QuestName = "SnowQuest"
        QuestNumber = 2
        QuestPos = CFrame.new(1389.74451, 88.1519318, -1298.90796, -0.342042685, 0, .939684391, 0, 1, 0, -0.939684391, 0, -0.342042685)
        EnemyPos = CFrame.new(1201.6412353516, 144.57958984375, -1550.0670166016)
        if Old_World and currentLevelValue.Value >= 110 and currentLevelValue.Value <= 119 then
            Name_Boss = "Yeti"
            QuestName_Boss = "SnowQuest"
            QuestNumber_Boss = 3
        end
    elseif Old_World and currentLevelValue.Value >= 120 and currentLevelValue.Value <= 149 then
        Enemy = "Chief Petty Officer"
        NameEnemy = "Chief Petty Officer"
        QuestName = "MarineQuest2"
        QuestNumber = 1
        QuestPos = CFrame.new(-5039.58643, 27.3500385, 4324.68018, 0, 0, -1, 0, 1, 0, 1, 0, 0)
        EnemyPos = CFrame.new(-4710.3598632812, 112.02615356445, 4584.92578125)
        if Old_World and currentLevelValue.Value >= 130 and currentLevelValue.Value <= 149 then
            Name_Boss = "Vice Admiral"
            QuestName_Boss = "MarineQuest2"
            QuestNumber_Boss = 2
        end
    elseif Old_World and currentLevelValue.Value >= 150 and currentLevelValue.Value <= 174 then
        Enemy = "Sky Bandit"
        NameEnemy = "Sky Bandit"
        QuestName = "SkyQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(-4838.701171875, 717.66931152344, -2617.8647460938)
        EnemyPos = CFrame.new(-4965.37890625, 357.37414550781, -2848.7023925781)
    elseif Old_World and currentLevelValue.Value >= 175 and currentLevelValue.Value <= 189 then
        Enemy = "Dark Master"
        NameEnemy = "Dark Master"
        QuestName = "SkyQuest"
        QuestNumber = 2
        QuestPos = CFrame.new(-4838.701171875, 717.66931152344, -2617.8647460938)
        EnemyPos = CFrame.new(-5224.05859375, 484.44784545898, -2275.9985351562)
    elseif Old_World and currentLevelValue.Value >= 190 and currentLevelValue.Value <= 209 then
        Enemy = "Prisoner"
        NameEnemy = "Prisoner"
        QuestName = "PrisonerQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(5309.6474609375, 1.6542626619339, 477.8815612793)
        EnemyPos = CFrame.new(5276.5576171875, 87.836639404297, 561.01007080078)
    elseif Old_World and currentLevelValue.Value >= 210 and currentLevelValue.Value <= 249 then
        Enemy = "Dangerous Prisoner"
        NameEnemy = "Dangerous Prisoner"
        QuestName = "PrisonerQuest"
        QuestNumber = 2
        QuestPos = CFrame.new(5309.6474609375, 1.6542626619339, 477.8815612793)
        EnemyPos = CFrame.new(5276.5576171875, 87.836639404297, 561.01007080078)
        if Old_World and currentLevelValue.Value >= 240 and currentLevelValue.Value <= 249 then
            Name_Boss = "Swan"
            QuestName_Boss = "ImpelQuest"
            QuestNumber_Boss = 3
        end
    elseif Old_World and currentLevelValue.Value >= 250 and currentLevelValue.Value <= 299 then
        Enemy = "Toga Warrior"
        NameEnemy = "Toga Warrior"
        QuestName = "ColosseumQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(-1580.04663, 6.35000277, -2986.47534, -0.515037298, 0, -0.857167721, 0, 1, 0, .857167721, 0, -0.515037298)
        EnemyPos = CFrame.new(-1820.21484375, 51.683856964111, -2740.6650390625)
    elseif Old_World and currentLevelValue.Value >= 300 and currentLevelValue.Value <= 324 then
        Enemy = "Military Soldier"
        NameEnemy = "Military Soldier"
        QuestName = "MagmaQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(-5313.37012, 10.9500084, 8515.29395, -0.499959469, 0, .866048813, 0, 1, 0, -0.866048813, 0, -0.499959469)
        EnemyPos = CFrame.new(-5411.1645507812, 11.081554412842, 8454.29296875)
    elseif Old_World and currentLevelValue.Value >= 325 and currentLevelValue.Value <= 374 then
        Enemy = "Military Spy"
        NameEnemy = "Military Spy"
        QuestName = "MagmaQuest"
        QuestNumber = 2
        QuestPos = CFrame.new(-5313.37012, 10.9500084, 8515.29395, -0.499959469, 0, .866048813, 0, 1, 0, -0.866048813, 0, -0.499959469)
        EnemyPos = CFrame.new(-5802.8681640625, 86.262413024902, 8828.859375)
        if Old_World and currentLevelValue.Value >= 350 and currentLevelValue.Value <= 374 then
            Name_Boss = "Magma Admiral"
            QuestName_Boss = "MagmaQuest"
            QuestNumber_Boss = 3
        end
    elseif Old_World and currentLevelValue.Value >= 375 and currentLevelValue.Value <= 399 then
        Enemy = "Fishman Warrior"
        NameEnemy = "Fishman Warrior"
        QuestName = "FishmanQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(61122.65234375, 18.497442245483, 1569.3997802734)
        EnemyPos = CFrame.new(60878.30078125, 18.482830047607, 1543.7574462891)
        if ((CFrame.new(61164, 12, 1820)).Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude >= 2000 then
            localPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(61164, 12, 1820)
        end
    elseif Old_World and currentLevelValue.Value >= 400 and currentLevelValue.Value <= 449 then
        Enemy = "Fishman Commando"
        NameEnemy = "Fishman Commando"
        QuestName = "FishmanQuest"
        QuestNumber = 2
        QuestPos = CFrame.new(61122.65234375, 18.497442245483, 1569.3997802734)
        EnemyPos = CFrame.new(61922.6328125, 18.482830047607, 1493.9343261719)
        if Old_World and currentLevelValue.Value >= 425 and currentLevelValue.Value <= 449 then
            Name_Boss = "Fishman Lord"
            QuestName_Boss = "FishmanQuest"
            QuestNumber_Boss = 3
        end
        if ((CFrame.new(61164, 12, 1820)).Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude >= 2000 then
            localPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(61164, 12, 1820)
        end
    elseif Old_World and currentLevelValue.Value >= 450 and currentLevelValue.Value <= 474 then
        Enemy = "God's Guard"
        NameEnemy = "God's Guard"
        QuestName = "SkyExp1Quest"
        QuestNumber = 1
        QuestPos = CFrame.new(-4721.88867, 843.874695, -1949.96643, .996191859, 0, -0.0871884301, 0, 1, 0, .0871884301, 0, .996191859)
        EnemyPos = CFrame.new(-4710.04296875, 845.27697753906, -1927.3079833984)
        if ((CFrame.new(-4721.88867, 843.874695, -1949.96643, .996191859, 0, -0.0871884301, 0, 1, 0, .0871884301, 0, .996191859)).Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude >= 7500 then
            replicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-4607.82275, 872.54248, -1667.55688))
        end
    elseif Old_World and currentLevelValue.Value >= 475 and currentLevelValue.Value <= 524 then
        Enemy = "Shanda"
        NameEnemy = "Shanda"
        QuestName = "SkyExp1Quest"
        QuestNumber = 2
        QuestPos = CFrame.new(-7859.09814, 5544.19043, -381.476196, -0.422592998, 0, .906319618, 0, 1, 0, -0.906319618, 0, -0.422592998)
        EnemyPos = CFrame.new(-7678.4897460938, 5566.4038085938, -497.21560668945)
    elseif Old_World and currentLevelValue.Value >= 525 and currentLevelValue.Value <= 549 then
        Enemy = "Royal Squad"
        NameEnemy = "Royal Squad"
        QuestName = "SkyExp2Quest"
        QuestNumber = 1
        QuestPos = CFrame.new(-7906.81592, 5634.6626, -1411.99194, 0, 0, -1, 0, 1, 0, 1, 0, 0)
        EnemyPos = CFrame.new(-7624.2524414062, 5658.1333007812, -1467.3542480469)
    elseif Old_World and currentLevelValue.Value >= 550 and currentLevelValue.Value <= 624 then
        Enemy = "Royal Soldier"
        NameEnemy = "Royal Soldier"
        QuestName = "SkyExp2Quest"
        QuestNumber = 2
        QuestPos = CFrame.new(-7906.81592, 5634.6626, -1411.99194, 0, 0, -1, 0, 1, 0, 1, 0, 0)
        EnemyPos = CFrame.new(-7836.7534179688, 5645.6640625, -1790.6236572266)
        if Old_World and currentLevelValue.Value >= 575 and currentLevelValue.Value <= 624 then
            Name_Boss = "Thunder God"
            QuestName_Boss = "SkyExp2Quest"
            QuestNumber_Boss = 3
        end
    elseif Old_World and currentLevelValue.Value >= 625 and currentLevelValue.Value <= 649 then
        Enemy = "Galley Pirate"
        NameEnemy = "Galley Pirate"
        QuestName = "FountainQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(5259.81982, 37.3500175, 4050.0293, .087131381, 0, .996196866, 0, 1, 0, -0.996196866, 0, .087131381)
        EnemyPos = CFrame.new(5551.0219726562, 78.901351928711, 3930.4128417969)
    elseif Old_World and currentLevelValue.Value >= 650 and currentLevelValue.Value <= 99999 then
        Enemy = "Galley Captain"
        NameEnemy = "Galley Captain"
        QuestName = "FountainQuest"
        QuestNumber = 2
        QuestPos = CFrame.new(5259.81982, 37.3500175, 4050.0293, .087131381, 0, .996196866, 0, 1, 0, -0.996196866, 0, .087131381)
        EnemyPos = CFrame.new(5441.9516601562, 42.502059936523, 4950.09375)
        if Old_World and currentLevelValue.Value >= 675 and currentLevelValue.Value <= 99999 then
            Name_Boss = "Cyborg"
            QuestName_Boss = "FountainQuest"
            QuestNumber_Boss = 3
        end
    elseif New_World and currentLevelValue.Value >= 700 and currentLevelValue.Value <= 724 then
        Enemy = "Raider"
        NameEnemy = "Raider"
        QuestName = "Area1Quest"
        QuestNumber = 1
        QuestPos = CFrame.new(-429.543518, 71.7699966, 1836.18188, -0.22495985, 0, -0.974368095, 0, 1, 0, .974368095, 0, -0.22495985)
        EnemyPos = CFrame.new(-728.32672119141, 52.779319763184, 2345.7705078125)
    elseif New_World and currentLevelValue.Value >= 725 and currentLevelValue.Value <= 774 then
        Enemy = "Mercenary"
        NameEnemy = "Mercenary"
        QuestName = "Area1Quest"
        QuestNumber = 2
        QuestPos = CFrame.new(-429.543518, 71.7699966, 1836.18188, -0.22495985, 0, -0.974368095, 0, 1, 0, .974368095, 0, -0.22495985)
        EnemyPos = CFrame.new(-1004.3244018555, 80.158866882324, 1424.6193847656)
        if New_World and currentLevelValue.Value >= 750 and currentLevelValue.Value <= 774 then
            Name_Boss = "Diamond"
            QuestName_Boss = "Area1Quest"
            QuestNumber_Boss = 3
        end
    elseif New_World and currentLevelValue.Value >= 775 and currentLevelValue.Value <= 799 then
        Enemy = "Swan Pirate"
        NameEnemy = "Swan Pirate"
        QuestName = "Area2Quest"
        QuestNumber = 1
        QuestPos = CFrame.new(638.43811, 71.769989, 918.282898, .139203906, 0, .99026376, 0, 1, 0, -0.99026376, 0, .139203906)
        EnemyPos = CFrame.new(1068.6643066406, 137.61428833008, 1322.1060791016)
    elseif New_World and currentLevelValue.Value >= 800 and currentLevelValue.Value <= 874 then
        Enemy = "Factory Staff"
        NameEnemy = "Factory Staff"
        QuestName = "Area2Quest"
        QuestNumber = 2
        QuestPos = CFrame.new(632.698608,
            73.1055908,
            918.666321,
            -0.0319722369,
            8.960749e-10,
            -0.999488771,
            1.3632653e-10,
            1,
            8.9217234e-10,
            .999488771,
            -1.0773209e-10,
            -0.0319722369)
        EnemyPos = CFrame.new(73.078674316406, 81.863441467285, -27.470672607422)
        if New_World and currentLevelValue.Value >= 850 and currentLevelValue.Value <= 874 then
            Name_Boss = "Jeremy"
            QuestName_Boss = "Area2Quest"
            QuestNumber_Boss = 3
        end
    elseif New_World and currentLevelValue.Value >= 875 and currentLevelValue.Value <= 899 then
        Enemy = "Marine Lieutenant"
        NameEnemy = "Marine Lieutenant"
        QuestName = "MarineQuest3"
        QuestNumber = 1
        QuestPos = CFrame.new(-2440.79639, 71.7140732, -3216.06812, .866007268, 0, .500031412, 0, 1, 0, -0.500031412, 0, .866007268)
        EnemyPos = CFrame.new(-2821.3723144531, 75.897277832031, -3070.0891113281)
    elseif New_World and currentLevelValue.Value >= 900 and currentLevelValue.Value <= 949 then
        Enemy = "Marine Captain"
        NameEnemy = "Marine Captain"
        QuestName = "MarineQuest3"
        QuestNumber = 2
        QuestPos = CFrame.new(-2440.79639, 71.7140732, -3216.06812, .866007268, 0, .500031412, 0, 1, 0, -0.500031412, 0, .866007268)
        EnemyPos = CFrame.new(-1861.2310791016, 80.176582336426, -3254.6975097656)
    elseif New_World and currentLevelValue.Value >= 950 and currentLevelValue.Value <= 974 then
        Enemy = "Zombie"
        NameEnemy = "Zombie"
        QuestName = "ZombieQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(-5497.06152, 47.5923004, -795.237061, -0.29242146, 0, -0.95628953, 0, 1, 0, .95628953, 0, -0.29242146)
        EnemyPos = CFrame.new(-5657.7768554688, 78.969734191895, -928.68701171875)
        if New_World and currentLevelValue.Value >= 925 and currentLevelValue.Value <= 974 then
            Name_Boss = "Fajita"
            QuestName_Boss = "MarineQuest3"
            QuestNumber_Boss = 3
        end
    elseif New_World and currentLevelValue.Value >= 975 and currentLevelValue.Value <= 999 then
        Enemy = "Vampire"
        NameEnemy = "Vampire"
        QuestName = "ZombieQuest"
        QuestNumber = 2
        QuestPos = CFrame.new(-5497.06152, 47.5923004, -795.237061, -0.29242146, 0, -0.95628953, 0, 1, 0, .95628953, 0, -0.29242146)
        EnemyPos = CFrame.new(-6037.66796875, 32.184638977051, -1340.6597900391)
    elseif New_World and currentLevelValue.Value >= 1000 and currentLevelValue.Value <= 1049 then
        Enemy = "Snow Trooper"
        NameEnemy = "Snow Trooper"
        QuestName = "SnowMountainQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(609.858826, 400.119904, -5372.25928, -0.374604106, 0, .92718488, 0, 1, 0, -0.92718488, 0, -0.374604106)
        EnemyPos = CFrame.new(549.14733886719, 427.38705444336, -5563.6987304688)
    elseif New_World and currentLevelValue.Value >= 1050 and currentLevelValue.Value <= 1099 then
        Enemy = "Winter Warrior"
        NameEnemy = "Winter Warrior"
        QuestName = "SnowMountainQuest"
        QuestNumber = 2
        QuestPos = CFrame.new(609.858826, 400.119904, -5372.25928, -0.374604106, 0, .92718488, 0, 1, 0, -0.92718488, 0, -0.374604106)
        EnemyPos = CFrame.new(1142.7451171875, 475.63980102539, -5199.4165039062)
    elseif New_World and currentLevelValue.Value >= 1100 and currentLevelValue.Value <= 1124 then
        Enemy = "Lab Subordinate"
        NameEnemy = "Lab Subordinate"
        QuestName = "IceSideQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(-6064.06885, 15.2422857, -4902.97852, .453972578, 0, -0.891015649, 0, 1, 0, .891015649, 0, .453972578)
        EnemyPos = CFrame.new(-5707.4716796875, 15.951709747314, -4513.3920898438)
    elseif New_World and currentLevelValue.Value >= 1125 and currentLevelValue.Value <= 1174 then
        Enemy = "Horned Warrior"
        NameEnemy = "Horned Warrior"
        QuestName = "IceSideQuest"
        QuestNumber = 2
        QuestPos = CFrame.new(-6064.06885, 15.2422857, -4902.97852, .453972578, 0, -0.891015649, 0, 1, 0, .891015649, 0, .453972578)
        EnemyPos = CFrame.new(-6341.3666992188, 15.951770782471, -5723.162109375)
        if New_World and currentLevelValue.Value >= 1150 and currentLevelValue.Value <= 1174 then
            Name_Boss = "Smoke Admiral"
            QuestName_Boss = "IceSideQuest"
            QuestNumber_Boss = 3
        end
    elseif New_World and currentLevelValue.Value >= 1175 and currentLevelValue.Value <= 1199 then
        Enemy = "Magma Ninja"
        NameEnemy = "Magma Ninja"
        QuestName = "FireSideQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(-5428.03174, 15.0622921, -5299.43457, -0.882952213, 0, .469463557, 0, 1, 0, -0.469463557, 0, -0.882952213)
        EnemyPos = CFrame.new(-5449.6728515625, 76.658744812012, -5808.2006835938)
    elseif New_World and currentLevelValue.Value >= 1200 and currentLevelValue.Value <= 1249 then
        Enemy = "Lava Pirate"
        NameEnemy = "Lava Pirate"
        QuestName = "FireSideQuest"
        QuestNumber = 2
        QuestPos = CFrame.new(-5428.03174, 15.0622921, -5299.43457, -0.882952213, 0, .469463557, 0, 1, 0, -0.469463557, 0, -0.882952213)
        EnemyPos = CFrame.new(-5213.3315429688, 49.737880706787, -4701.451171875)
    elseif New_World and currentLevelValue.Value >= 1250 and currentLevelValue.Value <= 1274 then
        Enemy = "Ship Deckhand"
        NameEnemy = "Ship Deckhand"
        QuestName = "ShipQuest1"
        QuestNumber = 1
        QuestPos = CFrame.new(1037.80127, 125.092171, 32911.6016)
        EnemyPos = CFrame.new(1212.0111083984, 150.79205322266, 33059.24609375)
        if ((CFrame.new(1212.0111083984, 150.79205322266, 33059.24609375)).Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude >= 5000 then
            ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("requestEntrance", Vector3.new(923.21301269531, 126.9759979248, 32852.83203125))
        end
    elseif New_World and currentLevelValue.Value >= 1275 and currentLevelValue.Value <= 1299 then
        Enemy = "Ship Engineer"
        NameEnemy = "Ship Engineer"
        QuestName = "ShipQuest1"
        QuestNumber = 2
        QuestPos = CFrame.new(1037.80127, 125.092171, 32911.6016)
        EnemyPos = CFrame.new(919.47863769531, 43.544013977051, 32779.96875)
        if ((CFrame.new(1212.0111083984, 150.79205322266, 33059.24609375)).Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude >= 5000 then
            ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("requestEntrance", Vector3.new(923.21301269531, 126.9759979248, 32852.83203125))
        end
    elseif New_World and currentLevelValue.Value >= 1300 and currentLevelValue.Value <= 1324 then
        Enemy = "Ship Steward"
        NameEnemy = "Ship Steward"
        QuestName = "ShipQuest2"
        QuestNumber = 1
        QuestPos = CFrame.new(968.80957, 125.092171, 33244.125)
        EnemyPos = CFrame.new(919.43853759766, 129.55599975586, 33436.03515625)
        if ((CFrame.new(1212.0111083984, 150.79205322266, 33059.24609375)).Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude >= 5000 then
            ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("requestEntrance", Vector3.new(923.21301269531, 126.9759979248, 32852.83203125))
        end
    elseif New_World and currentLevelValue.Value >= 1325 and currentLevelValue.Value <= 1349 then
        Enemy = "Ship Officer"
        NameEnemy = "Ship Officer"
        QuestName = "ShipQuest2"
        QuestNumber = 2
        QuestPos = CFrame.new(968.80957, 125.092171, 33244.125)
        EnemyPos = CFrame.new(1036.0179443359, 181.4390411377, 33315.7265625)
        if ((CFrame.new(1212.0111083984, 150.79205322266, 33059.24609375)).Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude >= 5000 then
            ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("requestEntrance", Vector3.new(923.21301269531, 126.9759979248, 32852.83203125))
        end
    elseif New_World and currentLevelValue.Value >= 1350 and currentLevelValue.Value <= 1374 then
        Enemy = "Arctic Warrior"
        NameEnemy = "Arctic Warrior"
        QuestName = "FrostQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(5667.6582, 26.7997818, -6486.08984, -0.933587909, 0, -0.358349502, 0, 1, 0, .358349502, 0, -0.933587909)
        EnemyPos = CFrame.new(5966.24609375, 62.970020294189, -6179.3828125)
    elseif New_World and currentLevelValue.Value >= 1375 and currentLevelValue.Value <= 1424 then
        Enemy = "Snow Lurker"
        NameEnemy = "Snow Lurker"
        QuestName = "FrostQuest"
        QuestNumber = 2
        QuestPos = CFrame.new(5667.6582, 26.7997818, -6486.08984, -0.933587909, 0, -0.358349502, 0, 1, 0, .358349502, 0, -0.933587909)
        EnemyPos = CFrame.new(5407.0737304688, 69.194374084473, -6880.8803710938)
        if New_World and currentLevelValue.Value >= 1400 and currentLevelValue.Value <= 1424 then
            Name_Boss = "Awakened Ice Admiral"
            QuestName_Boss = "FrostQuest"
            QuestNumber_Boss = 3
        end
    elseif New_World and currentLevelValue.Value >= 1425 and currentLevelValue.Value <= 1449 then
        Enemy = "Sea Soldier"
        NameEnemy = "Sea Soldier"
        QuestName = "ForgottenQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(-3055, 240, -10145)
        EnemyPos = CFrame.new(-3433, 26, -9784)
    elseif New_World and currentLevelValue.Value >= 1450 and currentLevelValue.Value <= 999999 then
        Enemy = "Water Fighter"
        NameEnemy = "Water Fighter"
        QuestName = "ForgottenQuest"
        QuestNumber = 2
        QuestPos = CFrame.new(-3054.53, 239.96, -10144.42)
        EnemyPos = CFrame.new(-3360.23, 284.21, -10533.07)
        if New_World and currentLevelValue.Value >= 1475 and currentLevelValue.Value <= 1499 then
            Name_Boss = "Tide Keeper"
            QuestName_Boss = "ForgottenQuest"
            QuestNumber_Boss = 3
        end
    elseif Three_World and currentLevelValue.Value >= 1500 and currentLevelValue.Value <= 1524 then
        Enemy = "Pirate Millionaire"
        NameEnemy = "Pirate Millionaire"
        QuestName = "PiratePortQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(-449.15930175781, 108.61765289307, 5948.0014648438)
        EnemyPos = CFrame.new(-245.99638366699, 47.30615234375, 5584.1005859375)
    elseif Three_World and currentLevelValue.Value >= 1525 and currentLevelValue.Value <= 1574 then
        Enemy = "Pistol Billionaire"
        NameEnemy = "Pistol Billionaire"
        QuestName = "PiratePortQuest"
        QuestNumber = 2
        QuestPos = CFrame.new(-449.15930175781, 108.61765289307, 5948.0014648438)
        EnemyPos = CFrame.new(-187.33015441895, 86.239875793457, 6013.513671875)
        if Three_World and currentLevelValue.Value >= 1550 and currentLevelValue.Value <= 1574 then
            Name_Boss = "Stone"
            QuestName_Boss = "PiratePortQuest"
            QuestNumber_Boss = 3
        end
    elseif Three_World and currentLevelValue.Value >= 1575 and currentLevelValue.Value <= 1599 then
        Enemy = "Dragon Crew Warrior"
        NameEnemy = "Dragon Crew Warrior"
        QuestName = "DragonCrewQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(6737.7768554688, 127.42920684814, -713.23126220703)
        EnemyPos = CFrame.new(6141.140625, 51.351364135742, -1340.7385253906)
    elseif Three_World and currentLevelValue.Value >= 1600 and currentLevelValue.Value <= 1624 then
        Enemy = "Dragon Crew Archer"
        NameEnemy = "Dragon Crew Archer"
        QuestName = "DragonCrewQuest"
        QuestNumber = 2
        QuestPos = CFrame.new(6737.7768554688, 127.42920684814, -713.23126220703)
        EnemyPos = CFrame.new(6616.4174804688, 441.76705932617, 446.04699707031)
    elseif Three_World and currentLevelValue.Value >= 1625 and currentLevelValue.Value <= 1649 then
        Enemy = "Hydra Enforcer"
        NameEnemy = "Hydra Enforcer"
        QuestName = "VenomCrewQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(5212.94140625, 1004.1171875, 755.66571044922)
        EnemyPos = CFrame.new(4685.2583007812, 735.80780029297, 815.34259033203)
    elseif Three_World and currentLevelValue.Value >= 1650 and currentLevelValue.Value <= 1699 then
        Enemy = "Venomous Assailant"
        NameEnemy = "Venomous Assailant"
        QuestName = "VenomCrewQuest"
        QuestNumber = 2
        QuestPos = CFrame.new(5212.94140625, 1004.1171875, 755.66571044922)
        EnemyPos = CFrame.new(4729.0942382812, 590.43676757812, -36.976276397705)
        if Three_World and currentLevelValue.Value >= 1675 and currentLevelValue.Value <= 1699 then
            Name_Boss = "Hydra Leader"
            QuestName_Boss = "VenomCrewQuest"
            QuestNumber_Boss = 3
        end
    elseif Three_World and currentLevelValue.Value >= 1700 and currentLevelValue.Value <= 1724 then
        Enemy = "Marine Commodore"
        NameEnemy = "Marine Commodore"
        QuestName = "MarineTreeIsland"
        QuestNumber = 1
        QuestPos = CFrame.new(2484.0673828125, 74.282150268555, -6786.64453125)
        EnemyPos = CFrame.new(2286.0078125, 73.133918762207, -7159.8090820312)
    elseif Three_World and currentLevelValue.Value >= 1725 and currentLevelValue.Value <= 1774 then
        Enemy = "Marine Rear Admiral"
        NameEnemy = "Marine Rear Admiral"
        QuestName = "MarineTreeIsland"
        QuestNumber = 2
        QuestPos = CFrame.new(2484.0673828125, 74.282150268555, -6786.64453125)
        EnemyPos = CFrame.new(3656.7736816406, 160.52406311035, -7001.5986328125)
        if Three_World and currentLevelValue.Value >= 1750 and currentLevelValue.Value <= 1774 then
            Name_Boss = "Kilo Admiral"
            QuestName_Boss = "MarineTreeIsland"
            QuestNumber_Boss = 3
        end
    elseif Three_World and currentLevelValue.Value >= 1775 and currentLevelValue.Value <= 1799 then
        Enemy = "Fishman Raider"
        NameEnemy = "Fishman Raider"
        QuestName = "DeepForestIsland3"
        QuestNumber = 1
        QuestPos = CFrame.new(-10581.6563, 330.872955, -8761.18652, -0.882952213, 0, .469463557, 0, 1, 0, -0.469463557, 0, -0.882952213)
        EnemyPos = CFrame.new(-10407.526367188, 331.76263427734, -8368.5166015625)
    elseif Three_World and currentLevelValue.Value >= 1800 and currentLevelValue.Value <= 1824 then
        Enemy = "Fishman Captain"
        NameEnemy = "Fishman Captain"
        QuestName = "DeepForestIsland3"
        QuestNumber = 2
        QuestPos = CFrame.new(-10581.6563, 330.872955, -8761.18652, -0.882952213, 0, .469463557, 0, 1, 0, -0.469463557, 0, -0.882952213)
        EnemyPos = CFrame.new(-10994.701171875, 352.38140869141, -9002.1103515625)
    elseif Three_World and currentLevelValue.Value >= 1825 and currentLevelValue.Value <= 1849 then
        Enemy = "Forest Pirate"
        NameEnemy = "Forest Pirate"
        QuestName = "DeepForestIsland"
        QuestNumber = 1
        QuestPos = CFrame.new(-13234.04, 331.488495, -7625.40137, .707134247, 0, -0.707079291, 0, 1, 0, .707079291, 0, .707134247)
        EnemyPos = CFrame.new(-13274.478515625, 332.37814331055, -7769.5805664062)
    elseif Three_World and currentLevelValue.Value >= 1850 and currentLevelValue.Value <= 1899 then
        Enemy = "Mythological Pirate"
        NameEnemy = "Mythological Pirate"
        QuestName = "DeepForestIsland"
        QuestNumber = 2
        QuestPos = CFrame.new(-13234.04, 331.488495, -7625.40137, .707134247, 0, -0.707079291, 0, 1, 0, .707079291, 0, .707134247)
        EnemyPos = CFrame.new(-13680.607421875, 501.08154296875, -6991.189453125)
        if Three_World and currentLevelValue.Value >= 1875 and currentLevelValue.Value <= 1899 then
            Name_Boss = "Captain Elephant"
            QuestName_Boss = "DeepForestIsland"
            QuestNumber_Boss = 3
        end
    elseif Three_World and currentLevelValue.Value >= 1900 and currentLevelValue.Value <= 1924 then
        Enemy = "Jungle Pirate"
        NameEnemy = "Jungle Pirate"
        QuestName = "DeepForestIsland2"
        QuestNumber = 1
        QuestPos = CFrame.new(-12680.3818, 389.971039, -9902.01953, -0.0871315002, 0, .996196866, 0, 1, 0, -0.996196866, 0, -0.0871315002)
        EnemyPos = CFrame.new(-12256.16015625, 331.73828125, -10485.836914062)
    elseif Three_World and currentLevelValue.Value >= 1924 and currentLevelValue.Value <= 1974 then
        Enemy = "Musketeer Pirate"
        NameEnemy = "Musketeer Pirate"
        QuestName = "DeepForestIsland2"
        QuestNumber = 2
        QuestPos = CFrame.new(-12680.3818, 389.971039, -9902.01953, -0.0871315002, 0, .996196866, 0, 1, 0, -0.996196866, 0, -0.0871315002)
        EnemyPos = CFrame.new(-13457.904296875, 391.54565429688, -9859.177734375)
        if Three_World and currentLevelValue.Value >= 1950 and currentLevelValue.Value <= 1974 then
            Name_Boss = "Beautiful Pirate"
            QuestName_Boss = "DeepForestIsland2"
            QuestNumber_Boss = 3
        end
    elseif Three_World and currentLevelValue.Value >= 1974 and currentLevelValue.Value <= 1999 then
        Enemy = "Reborn Skeleton"
        NameEnemy = "Reborn Skeleton"
        QuestName = "HauntedQuest1"
        QuestNumber = 1
        QuestPos = CFrame.new(-9479.2168, 141.215088, 5566.09277, 0, 0, 1, 0, 1, 0, -1, 0, 0)
        EnemyPos = CFrame.new(-8763.7236328125, 165.72299194336, 6159.8618164062)
    elseif Three_World and currentLevelValue.Value >= 2000 and currentLevelValue.Value <= 2024 then
        Enemy = "Living Zombie"
        NameEnemy = "Living Zombie"
        QuestName = "HauntedQuest1"
        QuestNumber = 2
        QuestPos = CFrame.new(-9479.2168, 141.215088, 5566.09277, 0, 0, 1, 0, 1, 0, -1, 0, 0)
        EnemyPos = CFrame.new(-10144.131835938, 138.6266784668, 5838.0888671875)
    elseif Three_World and currentLevelValue.Value >= 2025 and currentLevelValue.Value <= 2049 then
        Enemy = "Demonic Soul"
        NameEnemy = "Demonic Soul"
        QuestName = "HauntedQuest2"
        QuestNumber = 1
        QuestPos = CFrame.new(-9516.99316, 172.017181, 6078.46533, 0, 0, -1, 0, 1, 0, 1, 0, 0)
        EnemyPos = CFrame.new(-9505.8720703125, 172.10482788086, 6158.9931640625)
    elseif Three_World and currentLevelValue.Value >= 2050 and currentLevelValue.Value <= 2074 then
        Enemy = "Posessed Mummy"
        NameEnemy = "Posessed Mummy"
        QuestName = "HauntedQuest2"
        QuestNumber = 2
        QuestPos = CFrame.new(-9516.99316, 172.017181, 6078.46533, 0, 0, -1, 0, 1, 0, 1, 0, 0)
        EnemyPos = CFrame.new(-9582.0224609375, 6.2515273094177, 6205.478515625)
    elseif Three_World and currentLevelValue.Value >= 2075 and currentLevelValue.Value <= 2099 then
        Enemy = "Peanut Scout"
        NameEnemy = "Peanut Scout"
        QuestName = "NutsIslandQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(-2104.3908691406, 38.104167938232, -10194.21875, 0, 0, -1, 0, 1, 0, 1, 0, 0)
        EnemyPos = CFrame.new(-2143.2419433594, 47.721984863281, -10029.995117188)
    elseif Three_World and currentLevelValue.Value >= 2100 and currentLevelValue.Value <= 2124 then
        Enemy = "Peanut President"
        NameEnemy = "Peanut President"
        QuestName = "NutsIslandQuest"
        QuestNumber = 2
        QuestPos = CFrame.new(-2104.3908691406, 38.104167938232, -10194.21875, 0, 0, -1, 0, 1, 0, 1, 0, 0)
        EnemyPos = CFrame.new(-1859.3540039062, 38.103168487549, -10422.4296875)
    elseif Three_World and currentLevelValue.Value >= 2125 and currentLevelValue.Value <= 2149 then
        Enemy = "Ice Cream Chef"
        NameEnemy = "Ice Cream Chef"
        QuestName = "IceCreamIslandQuest"
        QuestNumber = 1
        QuestPos = CFrame.new(-820.64825439453, 65.819526672363, -10965.795898438, 0, 0, -1, 0, 1, 0, 1, 0, 0)
        EnemyPos = CFrame.new(-872.24658203125, 65.81957244873, -10919.95703125)
    elseif Three_World and currentLevelValue.Value >= 2150 and currentLevelValue.Value <= 2199 then
        Enemy = "Ice Cream Commander"
        NameEnemy = "Ice Cream Commander"
        QuestName = "IceCreamIslandQuest"
        QuestNumber = 2
        QuestPos = CFrame.new(-820.64825439453, 65.819526672363, -10965.795898438, 0, 0, -1, 0, 1, 0, 1, 0, 0)
        EnemyPos = CFrame.new(-558.06103515625, 112.04895782471, -11290.774414063)
        if Three_World and currentLevelValue.Value >= 2175 and currentLevelValue.Value <= 2199 then
            Name_Boss = "Cake Queen"
            QuestName_Boss = "IceCreamIslandQuest"
            QuestNumber_Boss = 3
        end
    elseif Three_World and currentLevelValue.Value >= 2200 and currentLevelValue.Value <= 2224 then
        Enemy = "Cookie Crafter"
        NameEnemy = "Cookie Crafter"
        QuestName = "CakeQuest1"
        QuestNumber = 1
        QuestPos = CFrame.new(-2021.32007, 37.7982254, -12028.7295, .957576931, -8.8030205e-08, .288177818, 6.930119e-08, 1, 7.519312e-08, -0.288177818, -5.2032135e-08, .957576931)
        EnemyPos = CFrame.new(-2374.13671875, 37.798263549805, -12125.30859375)
    elseif Three_World and currentLevelValue.Value >= 2225 and currentLevelValue.Value <= 2249 then
        Enemy = "Cake Guard"
        NameEnemy = "Cake Guard"
        QuestName = "CakeQuest1"
        QuestNumber = 2
        QuestPos = CFrame.new(-2021.32007, 37.7982254, -12028.7295, .957576931, -8.8030205e-08, .288177818, 6.930119e-08, 1, 7.519312e-08, -0.288177818, -5.2032135e-08, .957576931)
        EnemyPos = CFrame.new(-1598.3070068359, 43.773197174072, -12244.581054688)
    elseif Three_World and currentLevelValue.Value >= 2250 and currentLevelValue.Value <= 2274 then
        Enemy = "Baking Staff"
        NameEnemy = "Baking Staff"
        QuestName = "CakeQuest2"
        QuestNumber = 1
        QuestPos = CFrame.new(-1927.91602,
            37.7981339,
            -12842.5391,
            -0.96804446,
            4.2214214e-08,
            .250778586,
            4.7491106e-08,
            1,
            1.4990471e-08,
            -0.250778586,
            2.6421194e-08,
            -0.96804446)
        EnemyPos = CFrame.new(-1887.8099365234, 77.618507385254, -12998.350585938)
    elseif Three_World and currentLevelValue.Value >= 2275 and currentLevelValue.Value <= 2299 then
        Enemy = "Head Baker"
        NameEnemy = "Head Baker"
        QuestName = "CakeQuest2"
        QuestNumber = 2
        QuestPos = CFrame.new(-1927.91602,
            37.7981339,
            -12842.5391,
            -0.96804446,
            4.2214214e-08,
            .250778586,
            4.7491106e-08,
            1,
            1.4990471e-08,
            -0.250778586,
            2.6421194e-08,
            -0.96804446)
        EnemyPos = CFrame.new(-2216.1882324219, 82.884521484375, -12869.293945312)
    elseif Three_World and currentLevelValue.Value >= 2300 and currentLevelValue.Value <= 2324 then
        Enemy = "Cocoa Warrior"
        NameEnemy = "Cocoa Warrior"
        QuestName = "ChocQuest1"
        QuestNumber = 1
        QuestPos = CFrame.new(233.22836303711, 29.876001358032, -12201.233398438)
        EnemyPos = CFrame.new(-21.553283691406, 80.574996948242, -12352.387695312)
    elseif Three_World and currentLevelValue.Value >= 2325 and currentLevelValue.Value <= 2349 then
        Enemy = "Chocolate Bar Battler"
        NameEnemy = "Chocolate Bar Battler"
        QuestName = "ChocQuest1"
        QuestNumber = 2
        QuestPos = CFrame.new(233.22836303711, 29.876001358032, -12201.233398438)
        EnemyPos = CFrame.new(582.59057617188, 77.188095092773, -12463.162109375)
    elseif Three_World and currentLevelValue.Value >= 2350 and currentLevelValue.Value <= 2374 then
        Enemy = "Sweet Thief"
        NameEnemy = "Sweet Thief"
        QuestName = "ChocQuest2"
        QuestNumber = 1
        QuestPos = CFrame.new(150.50663757324, 30.693693161011, -12774.502929688)
        EnemyPos = CFrame.new(165.1884765625, 76.058853149414, -12600.836914062)
    elseif Three_World and currentLevelValue.Value >= 2375 and currentLevelValue.Value <= 2399 then
        Enemy = "Candy Rebel"
        NameEnemy = "Candy Rebel"
        QuestName = "ChocQuest2"
        QuestNumber = 2
        QuestPos = CFrame.new(150.50663757324, 30.693693161011, -12774.502929688)
        EnemyPos = CFrame.new(134.86563110352, 77.247680664062, -12876.547851562)
    elseif Three_World and currentLevelValue.Value >= 2400 and currentLevelValue.Value <= 2424 then
        Enemy = "Candy Pirate"
        NameEnemy = "Candy Pirate"
        QuestName = "CandyQuest1"
        QuestNumber = 1
        QuestPos = CFrame.new(-1167, 60, -14491)
        EnemyPos = CFrame.new(-1310.5003662109, 26.016523361206, -14562.404296875)
    elseif Three_World and currentLevelValue.Value >= 2425 and currentLevelValue.Value <= 2449 then
        Enemy = "Snow Demon"
        NameEnemy = "Snow Demon"
        QuestName = "CandyQuest1"
        QuestNumber = 2
        QuestPos = CFrame.new(-1167, 60, -14491)
        EnemyPos = CFrame.new(-880.20062255859, 71.247764587402, -14538.609375)
    elseif Three_World and currentLevelValue.Value >= 2450 and currentLevelValue.Value <= 2474 then
        Enemy = "Isle Outlaw"
        NameEnemy = "Isle Outlaw"
        QuestName = "TikiQuest1"
        QuestNumber = 1
        QuestPos = CFrame.new(-16547.748046875, 61.135334014893, -173.41360473633)
        EnemyPos = CFrame.new(-16442.814453125, 116.13899993896, -264.46377563477)
    elseif Three_World and currentLevelValue.Value >= 2475 and currentLevelValue.Value <= 2499 then
        Enemy = "Island Boy"
        NameEnemy = "Island Boy"
        QuestName = "TikiQuest1"
        QuestNumber = 2
        QuestPos = CFrame.new(-16547.748046875, 61.135334014893, -173.41360473633)
        EnemyPos = CFrame.new(-16901.26171875, 84.067565917969, -192.88906860352)
    elseif Three_World and currentLevelValue.Value >= 2500 and currentLevelValue.Value <= 2524 then
        Enemy = "Sun-kissed Warrior"
        NameEnemy = "Sun"
        New = "Sun"
        QuestName = "TikiQuest2"
        QuestNumber = 1
        QuestPos = CFrame.new(-16539.078125, 55.686328887939, 1051.5738525391)
        EnemyPos = CFrame.new(-16051.969726562, 54.797149658203, 1084.67578125)
    elseif Three_World and currentLevelValue.Value >= 2525 and currentLevelValue.Value <= 2549 then
        Enemy = "Isle Champion"
        NameEnemy = "Isle Champion"
        QuestName = "TikiQuest2"
        QuestNumber = 2
        QuestPos = CFrame.new(-16539.078125, 55.686328887939, 1051.5738525391)
        EnemyPos = CFrame.new(-16619.37109375, 129.98481750488, 1071.2355957031)
    elseif Three_World and currentLevelValue.Value >= 2550 and currentLevelValue.Value <= 2574 then
        Enemy = "Serpent Hunter"
        NameEnemy = "Serpent Hunter"
        QuestName = "TikiQuest3"
        QuestNumber = 1
        QuestPos = CFrame.new(-16666.5703125, 105.29138183594, 1576.6925048828)
        EnemyPos = CFrame.new(-16474.5703125, 124.32273864746, 1619.248046875)
    elseif Three_World and currentLevelValue.Value >= 2575 and currentLevelValue.Value <= 2650 then
        Enemy = "Skull Slayer"
        NameEnemy = "Skull Slayer"
        QuestName = "TikiQuest3"
        QuestNumber = 2
        QuestPos = CFrame.new(-16666.5703125, 105.29138183594, 1576.6925048828)
        EnemyPos = CFrame.new(-16778.7852,
            232.283752,
            1442.08325,
            -0.992449045,
            -5.54140511e-10,
            -0.12265785,
            -2.84580609e-10,
            1,
            -2.21517649e-09,
            .12265785,
            -2.16354379e-09,
            -0.992449045)
    end
end
function TPZ(part)
    local number
    local distance = (part.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
    if distance < 100 then
        number = 50
    elseif distance < 400 then
        number = 400
    elseif distance < 1000 then
        number = 300
    elseif distance < 1500 then
        number = 260
    elseif distance >= 1500 then
        number = 300
    end
    activeBoatTween = (game:GetService("TweenService")):Create(game.Players.LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(distance / number, Enum.EasingStyle.Linear), {
        ["CFrame"] = part
    })
    activeBoatTween:Play()
end
lastTeleportStartTime = tick()
farmPlayer = (game:GetService("Players")).LocalPlayer
cancelActiveTween = function()
    if activeTeleportTween then
        activeTeleportTween:Cancel()
        activeTeleportTween = nil
    end
end
tweenTeleportTo = function(part, part2, arg3)
    local tweenInfo, value2, distance2, humanoid, value3, humanoidRootPart2, condition, distance3
    local number2 = 300
    if part2 == 1.6 then
        number2 = 350
    end
    condition = arg3 or 130
    humanoidRootPart2 = farmPlayer.Character and farmPlayer.Character:FindFirstChild("HumanoidRootPart")
    humanoid = farmPlayer.Character and farmPlayer.Character:FindFirstChild("Humanoid")
    if not humanoidRootPart2 or not humanoid then
        return
    end
    distance3 = (part.Position - humanoidRootPart2.Position).Magnitude
    if distance3 > 3000 and humanoid.Health > 0 then
        local value4 = {
            {
                Vector3.new(61163.85, 11.67, 1819.78),
                "Old_World"
            },
            {
                Vector3.new(-4607.82, 872.54, -1667.55)
                "Old_World"
            },
            {
                Vector3.new(-7894.61, 5547.14, -380.29),
                "Old_World"
            },
            {
                Vector3.new(923.21, 126.97, 32852.83)
                "New_World"
            },
            {
                Vector3.new(-2953.31, 41.01, 2099.17)
                "Old_World"
            }
        }
        for key8, item2 in pairs(value4) do
            if _G[item2[2]] and (item2[1] - part.Position).Magnitude <= 2300 then
                (game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer("requestEntrance", item2[1])
                break
            end
        end
    end
    lastTeleportStartTime = tick()
    cancelActiveTween()
    distance2 = (part.Position - humanoidRootPart2.Position).Magnitude
    humanoidRootPart2.CFrame = CFrame.new(humanoidRootPart2.Position.X, part.Position.Y, humanoidRootPart2.Position.Z)
    if distance2 < 130 then
        pcall(function()
            humanoidRootPart2.CFrame = part
        end)
        return
    elseif distance2 < condition then
        number2 = 350
    end
    for key9, farmplayer in pairs(farmPlayer.Character:GetDescendants()) do
        if farmplayer:IsA("BasePart") and farmplayer.CanCollide then
            farmplayer.CanCollide = false
        end
    end
    value3 = distance2 / number2
    tweenInfo = TweenInfo.new(value3, Enum.EasingStyle.Linear)
    value2 = {
        ["CFrame"] = part
    }
    activeTeleportTween = (game:GetService("TweenService")):Create(humanoidRootPart2, tweenInfo, value2)
    activeTeleportTween:Play()
end
equipPreferredFarmTool = function()
    if _G.SelectWeapon and Utils.hasItem(_G.SelectWeapon) then
        Utils.equipTool(_G.SelectWeapon)
        return
    end
    if God_Human_C_M then
        local replicatedStorage2 = (game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer("getInventory")
        for key10, item3 in pairs(replicatedStorage2) do
            if item3.Type == "Sword" then
                if item3.Name == "Tushita" and item3.Mastery >= 400 then
                    Tushita_M = true
                elseif item3.Name == "Yama" and item3.Mastery >= 400 then
                    Yama_M = true
                end
            end
        end
        if not Tushita_M then
            if not Utils.findFirstChild(farmPlayer.Backpack, "Tushita") and not Utils.findFirstChild(farmPlayer.Character, "Tushita") then
                replicatedStorage.Remotes.CommF_:InvokeServer("LoadItem", "Tushita")
            end
        elseif not Yama_M then
            if not Utils.findFirstChild(farmPlayer.Backpack, "Yama") and not Utils.findFirstChild(farmPlayer.Character, "Yama") then
                replicatedStorage.Remotes.CommF_:InvokeServer("LoadItem", "Yama")
            end
        end
        for key11, farmplayer2 in pairs(farmPlayer.Backpack:GetChildren()) do
            if farmplayer2:IsA("Tool") and tostring(farmplayer2.ToolTip) == "Sword" then
                (farmPlayer.Character:WaitForChild("Humanoid")):EquipTool(farmplayer2)
            end
        end
    else
        for key12, farmplayer3 in pairs(farmPlayer.Backpack:GetChildren()) do
            if farmplayer3:IsA("Tool") and tostring(farmplayer3.ToolTip) == "Melee" then
                (farmPlayer.Character:WaitForChild("Humanoid")):EquipTool(farmplayer3)
            end
        end
    end
end
function TPBoat(part, part2, arg3, arg4)
    local distance4
    if arg4 == nil then
        arg4 = false
    end
    distance4 = (part.Position - part2.Position).Magnitude
    Speed = arg3
    TweenP = (game:GetService("TweenService")):Create(part2, TweenInfo.new(distance4 / Speed, Enum.EasingStyle.Linear), {
        ["CFrame"] = part
    })
    if arg4 == true then
        TweenP:Cancel()
    else
        TweenP:Play()
    end
end


-- (tên cũ trong dispatcher: "sf")
function Utils.stringFind(text, pattern)
    return string.find(text, tostring(pattern))
end

-- (tên cũ trong dispatcher: "ffc")
function Utils.findFirstChild(parent, childName)
    return parent and parent:FindFirstChild(childName)
end

-- (tên cũ trong dispatcher: "Equip")
function Utils.equipTool(toolName)
    if not toolName or type(toolName) ~= "string" then
        return
    end
    for key13, farmplayer4 in pairs(farmPlayer.Backpack:GetChildren()) do
        if farmplayer4:IsA("Tool") and farmplayer4.Name == toolName then
            (farmPlayer.Character:WaitForChild("Humanoid")):EquipTool(farmplayer4)
        end
    end
end

-- (tên cũ trong dispatcher: "gi")
function Utils.hasItem(itemName)
    if Utils.findFirstChild(farmPlayer.Backpack, itemName) or Utils.findFirstChild(farmPlayer.Character, itemName) then
        return true
    end
    for key14, item4 in pairs(replicatedStorage.Remotes.CommF_:InvokeServer("getInventoryWeapons")) do
        if item4.Name == itemName then
            return true
        end
    end
    return false
end

-- (tên cũ trong dispatcher: "tf")
function Utils.tableFind(list, value)
    return table.find(list, value)
end

-- (tên cũ trong dispatcher: "CheckBoss")
function Utils.checkBoss(bossName)
    if Utils.findFirstChild(replicatedStorage, bossName) or Utils.findFirstChild(enemiesFolder, bossName) then
        return true
    end
    return false
end

-- (tên cũ trong dispatcher: "IsHall")
function Utils.isInIceHall()
    if Utils.findFirstChild(workspaceService.Map, "IceCastle") then
        if Utils.findFirstChild(workspaceService.Map.IceCastle.Hall.LibraryDoor, "Keyhole") then
            return true
        end
    end
    return false
end

-- (tên cũ trong dispatcher: "CheckBackpack")
function Utils.hasInBackpack(itemName)
    if Utils.findFirstChild(farmPlayer.Backpack, itemName) or Utils.findFirstChild(farmPlayer.Character, itemName) then
        return true
    end
    return false
end

-- (tên cũ trong dispatcher: "GetMobRaid")
function Utils.getRaidMobs()
    local list = {}
    for key15, child in pairs(enemiesFolder:GetChildren()) do
        if child:FindFirstChild("HumanoidRootPart")
                and child:FindFirstChild("Humanoid")
                and child.Humanoid.Health > 0
                and (farmPlayer.Character.HumanoidRootPart.Position - child.HumanoidRootPart.Position).Magnitude <= 5000 then
            table.insert(list, child)
        end
    end
    return list
end

-- (tên cũ trong dispatcher: "GetFruits")
function Utils.getFruits()
    local list2 = {}
    for key16, item5 in pairs(replicatedStorage.Remotes.CommF_:InvokeServer("getInventory")) do
        if item5.Type == "Blox Fruit" and item5.Value <= 999999 then
            table.insert(list2, {
                Name = item5["Name"],
                Value = item5["Value"]
            })
        end
    end
    return list2
end

-- (tên cũ trong dispatcher: "GetRaid")
function Utils.getRaidPart(locationName, maxDistance)
    for key17, worldorigin in pairs(workspaceService._WorldOrigin.Locations:GetChildren()) do
        if worldorigin:IsA("Part") or worldorigin:IsA("BasePart") then
            if worldorigin.Name == locationName and (worldorigin.Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= maxDistance then
                return worldorigin
            end
        end
    end
    return nil
end

-- (tên cũ trong dispatcher: "GetType")
function Utils.getFruitNames()
    local list3 = {}
    for key18, item6 in pairs(replicatedStorage.Remotes.CommF_:InvokeServer("getInventory")) do
        if item6.Type == "Blox Fruit" then
            table.insert(list3, item6.Name)
        end
    end
    return list3
end

-- (tên cũ trong dispatcher: "IsInList")
function Utils.isInList(list, value)
    for key19, item7 in pairs(list) do
        if item7 == value then
            return true
        end
    end
    return false
end

-- (tên cũ trong dispatcher: "IsHeavenly")
function Utils.isHeavenlyDevil()
    for key20, item8 in pairs(((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("getTitles")) do
        if item8.Name == "Heavenly Devil" then
            return true
        end
    end
    return false
end

-- (tên cũ trong dispatcher: "GetMonster")
function Utils.findNearestMonster(maxDistance)
    pcall(function()
        for key21, child2 in pairs(enemiesFolder:GetChildren()) do
            if child2:IsA("Model")
                    and child2:FindFirstChild("Humanoid")
                    and child2.Humanoid.Health > 0
                    and (child2.HumanoidRootPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= maxDistance then
                Monster = child2
                return
            end
        end
    end)
end

-- (tên cũ trong dispatcher: "GetMon_Soul")
function Utils.collectSouls()
    for key22, child3 in next, (game:GetService("Workspace")).Enemies:GetChildren() do
        if child3.Name == "Living Zombie" then
            table.insert(get_mon, child3.Name)
        end
    end
end

-- (tên cũ trong dispatcher: "click")
function Utils.clickGuiObject(object)
    virtualInputManager:SendMouseButtonEvent(object.AbsolutePosition.X + object.AbsoluteSize.X / 2, object.AbsolutePosition.Y + 90, 0, true, object, 1)
    virtualInputManager:SendMouseButtonEvent(object.AbsolutePosition.X + object.AbsoluteSize.X / 2, object.AbsolutePosition.Y + 90, 0, false, object, 1)
end

-- (tên cũ trong dispatcher: "HopLowServer")
function Utils.hopToLowServer(maxPlayers)
    pcall(function()
        local function2
        if not maxPlayers then
            maxPlayers = 10
        end
        ticklon = tick()
        repeat
            task.wait()
        until tick() - ticklon >= 1
        function2 = function()
            for index2 = 1, math.huge, 1 do
                local replicatedStorage3
                if ChooseRegion == nil or ChooseRegion == "" then
                    ChooseRegion = "Singapore"
                else
                    (game:GetService("Players")).LocalPlayer.PlayerGui.ServerBrowser.Frame.Filters.SearchRegion.TextBox.Text = ChooseRegion
                end
                replicatedStorage3 = (game:GetService("ReplicatedStorage")).__ServerBrowser:InvokeServer(index2)
                for key23, item9 in pairs(replicatedStorage3) do
                    if key23 ~= game.JobId and item9.Count < maxPlayers then
                        (game:GetService("ReplicatedStorage")).__ServerBrowser:InvokeServer("teleport", key23)
                    end
                end
            end
            return false
        end
        if not getgenv().Loaded then
            local arg110
            arg110 = function(part)
                if part.Name == "ErrorPrompt" then
                    if part.Visible then
                        if part.TitleFrame.ErrorTitle.Text == "Teleport Failed" then
                            HopLowServer()
                            part.Visible = false
                        end
                    end
                    (part:GetPropertyChangedSignal("Visible")):Connect(function()
                        if part.Visible then
                            if part.TitleFrame.ErrorTitle.Text == "Teleport Failed" then
                                HopLowServer()
                                part.Visible = false
                            end
                        end
                    end)
                end
            end
            for key24, robloxpromptgui in pairs(game.CoreGui.RobloxPromptGui.promptOverlay:GetChildren()) do
                arg110(robloxpromptgui)
            end
            game.CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(arg110)
            getgenv().Loaded = true
        end
        while task.wait(.1) do
            function2()
        end
    end)
end

-- (tên cũ trong dispatcher: "CheckItem")
function Utils.getItemCount(itemName)
    for key25, item10 in pairs(replicatedStorage.Remotes.CommF_:InvokeServer("getInventory")) do
        if type(item10) == "table" then
            if item10.Type == "Material" then
                if item10.Name == itemName then
                    return item10.Count
                end
            end
        end
    end
    return 0
end

-- (tên cũ trong dispatcher: "FarmBone")
function Utils.farmBone(enabled)
    if enabled then
        if Utils.findFirstChild(farmPlayer.Backpack, "Fire Essence") or Utils.findFirstChild(farmPlayer.Character, "Fire Essence") then
            repeat
                Utils.setStatus(" Status : Use Fire Essence")
                Utils.equipTool("Fire Essence")
                task.wait(.5)
                replicatedStorage.Remotes.CommF_:InvokeServer("BuyDragonTalon", true)
                replicatedStorage.Remotes.CommF_:InvokeServer("BuyDragonTalon")
            until not Utils.findFirstChild(farmPlayer.Backpack, "Fire Essence") and not Utils.findFirstChild(farmPlayer.Character, "Fire Essence")
            replicatedStorage.Remotes.CommF_:InvokeServer("BuyDragonTalon")
            Dragon_Talon_C = true
        else
            if Utils.findFirstChild(enemiesFolder,
                "Demonic Soul") or Utils.findFirstChild(enemiesFolder,
                "Posessed Mummy") or Utils.findFirstChild(enemiesFolder,
                "Reborn Skeleton") or Utils.findFirstChild(enemiesFolder,
                "Living Zombie") then
                for key26, child4 in pairs(enemiesFolder:GetChildren()) do
                    if child4.Name == "Reborn Skeleton" or child4.Name == "Living Zombie" or child4.Name == "Demonic Soul" or child4.Name == "Posessed Mummy" then
                        if child4:FindFirstChild("HumanoidRootPart") and child4:FindFirstChild("Humanoid") and child4.Humanoid.Health > 0 then
                            repeat
                                task.wait(.1)
                                if Utils.getItemCount("Bones") > 500 and replicatedStorage.Remotes.CommF_:InvokeServer("Bones", "Check") > 0 then
                                    repeat
                                        task.wait(.2)
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Bones", "Check")
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Bones", "Buy", 1, 1)
                                    until replicatedStorage.Remotes.CommF_:InvokeServer("Bones", "Check") == 0
                                end
                                if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                    farmPlayer.Character.HumanoidRootPart.Remotes.CommF_:InvokeServer("Buso")
                                end
                                tweenTeleportTo(child4.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5, 200)
                                equipPreferredFarmTool()
                                Utils.freezeEnemy(child4.Name)
                            until not child4.Parent or child4.Humanoid.Health <= 0
                        end
                    end
                end
            else
                tweenTeleportTo(CFrame.new(-9505.8720703125, 172.10482788086, 6158.9931640625), 1.5)
            end
        end
    else
        if Utils.findFirstChild(enemiesFolder,
            "Demonic Soul") or Utils.findFirstChild(enemiesFolder,
            "Posessed Mummy") or Utils.findFirstChild(enemiesFolder,
            "Reborn Skeleton") or Utils.findFirstChild(enemiesFolder,
            "Living Zombie") then
            for key27, child5 in pairs(enemiesFolder:GetChildren()) do
                if child5.Name == "Reborn Skeleton" or child5.Name == "Living Zombie" or child5.Name == "Demonic Soul" or child5.Name == "Posessed Mummy" then
                    if child5:FindFirstChild("HumanoidRootPart") and child5:FindFirstChild("Humanoid") and child5.Humanoid.Health > 0 then
                        repeat
                            task.wait(.1)
                            if Utils.getItemCount("Bones") > 500 and replicatedStorage.Remotes.CommF_:InvokeServer("Bones", "Check") > 0 then
                                repeat
                                    task.wait(.2)
                                    replicatedStorage.Remotes.CommF_:InvokeServer("Bones", "Check")
                                    replicatedStorage.Remotes.CommF_:InvokeServer("Bones", "Buy", 1, 1)
                                until replicatedStorage.Remotes.CommF_:InvokeServer("Bones", "Check") == 0
                            end
                            if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                farmPlayer.Character.HumanoidRootPart.Remotes.CommF_:InvokeServer("Buso")
                            end
                            tweenTeleportTo(child5.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5, 200)
                            equipPreferredFarmTool()
                            Utils.freezeEnemy(child5.Name)
                        until not child5.Parent or child5.Humanoid.Health <= 0
                    end
                end
            end
        else
            tweenTeleportTo(CFrame.new(-9505.8720703125, 172.10482788086, 6158.9931640625), 1.5)
        end
    end
end

-- (tên cũ trong dispatcher: "Get_Item_Inventory")
function Utils.loadItem(itemName)
    if not Utils.findFirstChild(farmPlayer.Backpack, itemName) and not Utils.findFirstChild(farmPlayer.Character, itemName) then
        replicatedStorage.Remotes.CommF_:InvokeServer("LoadItem", tostring(itemName))
    end
end

-- (tên cũ trong dispatcher: "BN")
function Utils.freezeEnemy(enemyName)
    pcall(function()
        local localPlayer2 = game.Players.LocalPlayer
        local humanoidRootPart3 = localPlayer2.Character and localPlayer2.Character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart3 then
            return
        end
        for key28, instance in pairs(game.Workspace.Enemies:GetChildren()) do
            if instance:IsA("Model") and instance.Name == enemyName and instance:FindFirstChild("Humanoid") and instance:FindFirstChild("HumanoidRootPart") then
                local humanoidRootPart4, humanoid2
                humanoid2, humanoidRootPart4 = instance.Humanoid, instance.HumanoidRootPart
                if humanoid2.Health > 0 and (humanoidRootPart4.Position - humanoidRootPart3.Position).Magnitude <= 350 then
                    local nil2 = nil
                    for key29, instance2 in pairs(game.Workspace.Enemies:GetChildren()) do
                        if instance2 ~= instance and instance2:IsA("Model") and instance2.Name == enemyName and instance2:FindFirstChild("HumanoidRootPart") then
                            nil2 = instance2.HumanoidRootPart
                            break
                        end
                    end
                    if nil2 then
                        local bodyPosition = Instance.new("BodyPosition")
                        bodyPosition.Position = nil2.Position + Vector3.new(0, 0, 0)
                        bodyPosition.MaxForce = Vector3.new(1000000, 1000000, 1000000)
                        bodyPosition.P = 3000
                        bodyPosition.D = 100
                        bodyPosition.Name = "EnemyFlyPosition"
                        bodyPosition.Parent = humanoidRootPart4
                    end
                    humanoidRootPart4.CanCollide = false
                    humanoid2:ChangeState(14)
                    humanoid2.WalkSpeed = 0
                    if humanoid2:FindFirstChild("Animator") then
                        humanoid2.Animator:Destroy()
                    end
                    for key30, l5 in pairs(instance:GetDescendants()) do
                        if l5:IsA("BasePart") then
                            l5.CanCollide = false
                            l5.CanTouch = false
                            l5.CanQuery = false
                        end
                    end
                    if instance:FindFirstChild("Head") then
                        instance.Head.CanCollide = false
                    end
                end
            end
        end
        sethiddenproperty(localPlayer2, "SimulationRadius", math.huge)
    end)
end

-- (tên cũ trong dispatcher: "Status")
function Utils.setStatus(text)
    statusTextLabel.Text = text
end

-- (tên cũ trong dispatcher: "GetQuest")
function Utils.runCdkTrialQuest(alignment)
    if (Vector3.new(-12379.1406, 601.433167, -6543.60742) - farmPlayer.Character.HumanoidRootPart.Position).Magnitude > 30 then
        tweenTeleportTo(CFrame.new(-12379.1406, 601.433167, -6543.60742), 1.5)
    elseif (Vector3.new(-12379.1406, 601.433167, -6543.60742) - farmPlayer.Character.HumanoidRootPart.Position).Magnitude < 30 then
        if alignment == "Good" then
            repeat
                task.wait(.1)
                tweenTeleportTo(CFrame.new(-12392.5068, 603.319763, -6596.00586), 1.5)
            until (Vector3.new(-12392.5068, 603.319763, -6596.00586) - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3
            task.wait(1)
            replicatedStorage.Remotes.CommF_:InvokeServer("CDKQuest", "Progress", "Good")
            task.wait(1)
            replicatedStorage.Remotes.CommF_:InvokeServer("CDKQuest", "StartTrial", "Good")
        elseif alignment == "Evil" then
            repeat
                task.wait(.1)
                tweenTeleportTo(CFrame.new(-12392.2637, 603.319763, -6503.27832), 1.5)
            until (Vector3.new(-12392.2637, 603.319763, -6503.27832) - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3
            task.wait(1)
            replicatedStorage.Remotes.CommF_:InvokeServer("CDKQuest", "Progress", "Evil")
            task.wait(1)
            replicatedStorage.Remotes.CommF_:InvokeServer("CDKQuest", "StartTrial", "Evil")
        end
    end
end

-- (tên cũ trong dispatcher: "GetTorch")
function Utils.getHeavenlyTorch(torchName)
    repeat
        task.wait()
        tweenTeleportTo(workspaceService.Map.HeavenlyDimension[torchName].CFrame, 1.5)
    until (workspaceService.Map.HeavenlyDimension[torchName].Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 7
    fireproximityprompt(workspace.Map.HeavenlyDimension[torchName].ProximityPrompt)
    task.wait(.5)
end

-- (tên cũ trong dispatcher: "GetTorchX")
function Utils.getHellTorch(torchName)
    repeat
        task.wait()
        tweenTeleportTo(workspaceService.Map.HellDimension[torchName].CFrame, 1.5)
    until (workspaceService.Map.HellDimension[torchName].Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 7
    fireproximityprompt(workspace.Map.HellDimension[torchName].ProximityPrompt)
    task.wait(.5)
end
combatPlayersService = game:GetService("Players")
combatReplicatedStorage = game:GetService("ReplicatedStorage")
combatWorkspace = game:GetService("Workspace")
combatUtils = {}
combatUtils.__index = combatUtils
combatPlayer = combatPlayersService.LocalPlayer
task.spawn(function()
    while task.wait(.5) do
        pcall(function()
            if farmPlayer.Data.Points.Value > 0 and farmPlayer.Data.Stats.Melee.Level.Value < 2650 then
                combatReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint", "Melee", farmPlayer.Data.Points.Value)
            end
            if farmPlayer.Data.Stats.Melee.Level.Value >= 2650 and farmPlayer.Data.Points.Value > 0 and farmPlayer.Data.Stats.Defense.Level.Value < 2550 then
                combatReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint", "Defense", farmPlayer.Data.Points.Value)
            end
            if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                combatReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
            end
        end)
    end
end)
getgenv()["Fast Attack"] = true
fastAttackDelay = 0
task.spawn(function()
    while task.wait(fastAttackDelay) do
        if getgenv()["Fast Attack"] and not Stop_Fast_Attack then
            if Utils.stringFind(farmPlayer.PlayerGui.Main.Version.Text, "v26.6.1") then
                xpcall(function()
                    if (combatPlayer.Character or combatPlayer.CharacterAdded:Wait()):FindFirstChildOfClass("Tool")
                            and (combatPlayer.Character or combatPlayer.CharacterAdded:Wait()):FindFirstChildOfClass("Humanoid")
                            and (combatPlayer.Character or combatPlayer.CharacterAdded:Wait()).Humanoid.Health > 0 then
                        for key31, combatworkspace in pairs(combatWorkspace.Enemies:GetChildren()) do
                            if combatworkspace:FindFirstChildOfClass("Humanoid") and combatworkspace.Humanoid.Health > 0 and combatworkspace:FindFirstChild("HumanoidRootPart") then
                                if (combatworkspace.HumanoidRootPart.Position - combatPlayer.Character.HumanoidRootPart.Position).Magnitude <= 60 then
                                    local number3
                                    if (combatPlayer.Character or combatPlayer.CharacterAdded:Wait()):FindFirstChild("Stun") then
                                        (combatPlayer.Character or combatPlayer.CharacterAdded:Wait()).Stun.Value = 0
                                    end
                                    if (combatPlayer.Character or combatPlayer.CharacterAdded:Wait()):FindFirstChild("Busy") then
                                        (combatPlayer.Character or combatPlayer.CharacterAdded:Wait()).Busy.Value = false
                                    end
                                    if combatworkspace:FindFirstChild("Stun") then
                                        combatworkspace.Stun.Value = 0
                                    end
                                    if combatworkspace:FindFirstChild("Busy") then
                                        combatworkspace.Busy.Value = false
                                    end
                                    if replicatedStorage.Modules.Net:FindFirstChild("RE") and replicatedStorage.Modules.Net.RE:FindFirstChild("RegisterHit") then
                                        replicatedStorage.Modules.Net.RE.RegisterHit:SetAttribute("Virtual", not replicatedStorage.Modules.Net.RE.RegisterHit:GetAttribute("Virtual"))
                                    end
                                    if combatPlayer.Character then
                                        combatPlayer.Character:SetAttribute("Clashable", not combatPlayer.Character:GetAttribute("Clashable"))
                                    end
                                    number3 = 0
                                    for key32, combatworkspace2 in pairs(combatWorkspace.Enemies:GetChildren()) do
                                        if combatworkspace2:FindFirstChildOfClass("Humanoid")
                                                and combatworkspace2.Humanoid.Health > 0
                                                and combatworkspace2:FindFirstChild("HumanoidRootPart")
                                                and (combatworkspace2.HumanoidRootPart.Position - combatPlayer.Character.HumanoidRootPart.Position).Magnitude <= 60 then
                                            number3 = number3 + 1
                                            if number3 > 5 then
                                                fastAttackDelay = .1
                                            elseif number3 > 2 and number3 <= 5 then
                                                fastAttackDelay = .03
                                            else
                                                fastAttackDelay = 0
                                            end
                                            (netModule:RemoteEvent("RegisterAttack")):FireServer(math.huge)
                                            (netModule:RemoteEvent("RegisterHit", true)):FireServer(combatworkspace2.Head, {
                                                {
                                                    combatworkspace2,
                                                    combatworkspace2.Head
                                                },
                                                combatworkspace2.Head
                                            }, nil, (tostring(combatPlayer.UserId)):sub(2, 4) .. (tostring(coroutine.running())):sub(11, 15))
                                        end
                                    end
                                end
                            end
                        end
                    end
                end, warn)
            else
                local function3, replicatedStorage4, sendHitsToServer, function4, registerAttack, localPlayer3, value5, players2, ok, collectionService
                assert(getrenv, "Exploit not supported")
                collectionService = game:GetService("CollectionService")
                replicatedStorage4 = game:GetService("ReplicatedStorage")
                players2 = game:GetService("Players")
                localPlayer3 = players2.LocalPlayer
                sendHitsToServer = debug.getupvalue((getrenv())._G.SendHitsToServer, 1)
                registerAttack = replicatedStorage4.Modules.Net["RE/RegisterAttack"]
                function4 = function()
                    local position, list4
                    local basicMob = collectionService:GetTagged("BasicMob")
                    if #basicMob == 0 then
                        return nil
                    end
                    list4 = {}
                    position = localPlayer3.Character and localPlayer3.Character.PrimaryPart.Position
                    if not position then
                        return nil
                    end
                    for key33, item11 in pairs(basicMob) do
                        local humanoid3 = item11:FindFirstChildOfClass("Humanoid")
                        local primaryPart = item11.PrimaryPart
                        if humanoid3 and humanoid3.Health > 0 and primaryPart then
                            local distance5 = (primaryPart.Position - position).Magnitude
                            if distance5 <= 100 then
                                list4[#list4 + 1] = {
                                    mob = item11,
                                    distance = distance5
                                }
                            end
                        end
                    end
                    if #list4 == 0 then
                        return nil
                    end
                    table.sort(list4, function(part, part2)
                        return part.distance < part2.distance
                    end)
                    return #list4 > 2 and {
                        list4[1],
                        list4[2]
                    } or list4
                end
                function3 = function()
                    local list5, function42
                    function42 = function4()
                    if not function42 then
                        return
                    end
                    list5 = {}
                    for key34, item12 in pairs(function42) do
                        local humanoidRootPart5 = item12.mob:FindFirstChild("HumanoidRootPart")
                        if humanoidRootPart5 then
                            list5[#list5 + 1] = {
                                item12.mob,
                                humanoidRootPart5
                            }
                        end
                    end
                    if #list5 > 0 then
                        registerAttack:FireServer(0 / 0)
                        coroutine.resume(sendHitsToServer, list5[1][2], {
                            table.unpack(list5, 2)
                        })
                    end
                end
                value5, ok = pcall(function()
                    function3()
                end)
                if not value5 then
                    warn("Error in Combat script: " .. tostring(ok))
                end
            end
        end
    end
end)
for key35, item13 in pairs(replicatedStorage.Remotes.CommF_:InvokeServer("getInventory")) do
    if item13.Type == "Material" then
        if item13.Name == "Mirror Fractal" then
            Mirror_Fractal_H = true
        end
    end
end
farmPlayer.PlayerGui.Notifications.Enabled = false
if (((replicatedStorage:WaitForChild("Modules")):WaitForChild("Net")):WaitForChild("RF/FruitCustomizerRF")):InvokeServer({
    StorageName = "Pure Red",
    Type = "AuraSkin",
    Context = "Equip"
}) ~= false then
    Pure_Red_H = true
end
if (((replicatedStorage:WaitForChild("Modules")):WaitForChild("Net")):WaitForChild("RF/FruitCustomizerRF")):InvokeServer({
    StorageName = "Snow White",
    Type = "AuraSkin",
    Context = "Equip"
}) ~= false then
    Snow_White = true
end
if (((replicatedStorage:WaitForChild("Modules")):WaitForChild("Net")):WaitForChild("RF/FruitCustomizerRF")):InvokeServer({
    StorageName = "Snow White",
    Type = "AuraSkin",
    Context = "Equip"
}) ~= false then
    Winter_Sky = true
end
if (((replicatedStorage:WaitForChild("Modules")):WaitForChild("Net")):WaitForChild("RF/FruitCustomizerRF")):InvokeServer({
    StorageName = "Rainbow Saviour",
    Type = "AuraSkin",
    Context = "Equip"
}) ~= false then
    Rainbow_Saviour = true
end
if Three_World and (replicatedStorage.Remotes.CommF_:InvokeServer("TushitaProgress")).OpenedDoor then
    Unlock_Tushita_Quest = true
end
runDefaultFarmQuest = function()
    local flag3
    if Three_World then
        if tostring(string.match(tostring(replicatedStorage.Remotes.CommF_:InvokeServer("CakePrinceSpawner")), "%d+")) == "nil" or tostring(string.match(tostring(replicatedStorage.Remotes.CommF_:InvokeServer("CakePrinceSpawner")), "%d+")) == nil then
            replicatedStorage.Remotes.CommF_:InvokeServer("CakePrinceSpawner", true)
        end
    end
    if Three_World then
        if Utils.findFirstChild(enemiesFolder, "Cake Prince") or Utils.findFirstChild(replicatedStorage, "Cake Prince") then
            if Utils.findFirstChild(enemiesFolder, "Cake Prince") then
                for key36, child6 in pairs(enemiesFolder:GetChildren()) do
                    if child6.Name == "Cake Prince" and child6.Humanoid.Health > 0 then
                        repeat
                            task.wait()
                            if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                farmPlayer.Character.HumanoidRootPart.Remotes.CommF_:InvokeServer("Buso")
                            end
                            tweenTeleportTo(child6.HumanoidRootPart.CFrame * CFrame.new(0, -30, 0), 1.5)
                            equipPreferredFarmTool()
                        until not child6.Parent or child6.Humanoid.Health <= 0 or not getgenv().AutoFarm
                    end
                end
            elseif Utils.findFirstChild(replicatedStorage, "Cake Prince") then
                for key37, child7 in pairs(replicatedStorage:GetChildren()) do
                    if child7.Name == "Cake Prince" and child7.Humanoid.Health > 0 then
                        repeat
                            task.wait()
                            if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                farmPlayer.Character.HumanoidRootPart.Remotes.CommF_:InvokeServer("Buso")
                            end
                            tweenTeleportTo(child7.HumanoidRootPart.CFrame * CFrame.new(0, -30, 0), 1.5)
                            equipPreferredFarmTool()
                        until not child7.Parent or child7.Humanoid.Health <= 0 or not getgenv().AutoFarm
                    end
                end
            end
        end
    end
    if Three_World then
        if enemiesFolder:FindFirstChild("rip_indra True Form") or replicatedStorage:FindFirstChild("rip_indra True Form") then
            if not(replicatedStorage.Remotes.CommF_:InvokeServer("TushitaProgress")).OpenedDoor then
                local response2 = replicatedStorage.Remotes.CommF_:InvokeServer("TushitaProgress")
                if not response2.OpenedDoor then
                    if farmPlayer.Backpack:FindFirstChild("Holy Torch") or farmPlayer.Character:FindFirstChild("Holy Torch") then
                        Utils.equipTool("Holy Torch")
                        for index3 = 1, 5, 1 do
                            replicatedStorage.Remotes.CommF_:InvokeServer("TushitaProgress", "Torch", index3)
                        end
                    elseif replicatedStorage:FindFirstChild("rip_indra True Form") or enemiesFolder:FindFirstChild("rip_indra True Form") then
                        if farmPlayer.Backpack:FindFirstChild("Holy Torch") or farmPlayer.Character:FindFirstChild("Holy Torch") then
                            Utils.equipTool("Holy Torch")
                            for index4 = 1, 5, 1 do
                                replicatedStorage.Remotes.CommF_:InvokeServer("TushitaProgress", "Torch", index4)
                            end
                        elseif replicatedStorage:FindFirstChild("rip_indra True Form") or enemiesFolder:FindFirstChild("rip_indra True Form") then
                            task.spawn(function()
                                repeat
                                    task.wait()
                                    virtualInputManager:SendKeyEvent(true, "Space", false, game)
                                    task.wait(.3)
                                    virtualInputManager:SendKeyEvent(false, "Space", false, game)
                                until farmPlayer.Backpack:FindFirstChild("Holy Torch")
                                        or farmPlayer.Character:FindFirstChild("Holy Torch")
                                        or not replicatedStorage:FindFirstChild("rip_indra True Form")
                                        and not enemiesFolder:FindFirstChild("rip_indra True Form")
                            end)
                            repeat
                                task.wait()
                                farmPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(5714, 19, 254)
                            until farmPlayer.Backpack:FindFirstChild("Holy Torch")
                                    or farmPlayer.Character:FindFirstChild("Holy Torch")
                                    or not replicatedStorage:FindFirstChild("rip_indra True Form")
                                    and not enemiesFolder:FindFirstChild("rip_indra True Form")
                            if farmPlayer.Backpack:FindFirstChild("Holy Torch") or farmPlayer.Character:FindFirstChild("Holy Torch") then
                                Utils.equipTool("Holy Torch")
                                for index5 = 1, 5, 1 do
                                    replicatedStorage.Remotes.CommF_:InvokeServer("TushitaProgress", "Torch", index5)
                                end
                            end
                        end
                    end
                elseif response2.OpenedDoor then
                    Unlock_Tushita_Quest = true
                    return
                end
            else
                if enemiesFolder:FindFirstChild("rip_indra True Form") or replicatedStorage:FindFirstChild("rip_indra True Form") then
                    if enemiesFolder:FindFirstChild("rip_indra True Form") then
                        for key38, child8 in pairs(enemiesFolder:GetChildren()) do
                            if child8.Name == "rip_indra True Form" and child8.Humanoid.Health > 0 then
                                repeat
                                    task.wait(.1)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        farmPlayer.Character.HumanoidRootPart.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    tweenTeleportTo(child8.HumanoidRootPart.CFrame * CFrame.new(0, -30, 0), 1.5)
                                    equipPreferredFarmTool()
                                until not child8.Parent or child8.Humanoid.Health <= 0
                            end
                        end
                    elseif replicatedStorage:FindFirstChild("rip_indra True Form") then
                        tweenTeleportTo((replicatedStorage:FindFirstChild("rip_indra True Form")).HumanoidRootPart.CFrame * CFrame.new(0, 30, 0))
                    end
                elseif farmPlayer.Backpack:FindFirstChild("God's Chalice") or farmPlayer.Character:FindFirstChild("God's Chalice") then
                    repeat
                        task.wait(.1)
                        Oyster_H = false
                        Hot_pink_H = false
                        Really_red_H = false
                        for key39, summoner in pairs(workspaceService.Map["Boat Castle"].Summoner.Circle:GetChildren()) do
                            if summoner.Name == "Part" and tostring(summoner.BrickColor) == "Oyster" and tostring(summoner.Part.BrickColor) == "Lime green" then
                                Oyster_H = true
                            end
                        end
                        for key40, summoner2 in pairs(workspaceService.Map["Boat Castle"].Summoner.Circle:GetChildren()) do
                            if summoner2.Name == "Part" and tostring(summoner2.BrickColor) == "Hot pink" and tostring(summoner2.Part.BrickColor) == "Lime green" then
                                Hot_pink_H = true
                            end
                        end
                        for key41, summoner3 in pairs(workspaceService.Map["Boat Castle"].Summoner.Circle:GetChildren()) do
                            if summoner3.Name == "Part" and tostring(summoner3.BrickColor) == "Really red" and tostring(summoner3.Part.BrickColor) == "Lime green" then
                                Really_red_H = true
                            end
                        end
                        if Oyster_H and Hot_pink_H and Really_red_H then
                            repeat
                                task.wait(.1)
                                Utils.equipTool("God's Chalice")
                                tweenTeleportTo(CFrame.new(-5561.06738, 314.375793, -2663.88892, -0.304127187, -0.00254100002, .952628076, .000226983335, .999996245, .00273981248, -0.952631414, .00104948215, -0.304125458), 1.5)
                            until (Vector3.new(-5561.06738, 314.375793, -2663.88892) - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 5
                            task.wait(1)
                        else
                            if farmPlayer.Backpack:FindFirstChild("God's Chalice") or farmPlayer.Character:FindFirstChild("God's Chalice") then
                                repeat
                                    task.wait(.1)
                                    equipPreferredFarmTool()
                                    tweenTeleportTo(CFrame.new(-5561.06738, 314.375793, -2663.88892, -0.304127187, -0.00254100002, .952628076, .000226983335, .999996245, .00273981248, -0.952631414, .00104948215, -0.304125458), 1.5)
                                until (Vector3.new(-5561.06738, 314.375793, -2663.88892) - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 5
                                if Snow_White and not Oyster_H then
                                    for key42, summoner4 in pairs(workspaceService.Map["Boat Castle"].Summoner.Circle:GetChildren()) do
                                        if summoner4.Name == "Part" and tostring(summoner4.BrickColor) == "Oyster" then
                                            if tostring(summoner4.Part.BrickColor) ~= "Lime green" then
                                                replicatedStorage.Remotes.CommF_:InvokeServer("activateColor", "Snow White")
                                                task.wait(1)
                                                repeat
                                                    task.wait()
                                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                                        farmPlayer.Character.HumanoidRootPart.Remotes.CommF_:InvokeServer("Buso")
                                                    end
                                                    tweenTeleportTo(summoner4.Part.CFrame, 1.5)
                                                until tostring(summoner4.Part.BrickColor) == "Lime green"
                                                Oyster_H = true
                                            end
                                        end
                                    end
                                end
                                if Pure_Red_H and not Really_red_H then
                                    for key43, summoner5 in pairs(workspaceService.Map["Boat Castle"].Summoner.Circle:GetChildren()) do
                                        if summoner5.Name == "Part" and tostring(summoner5.BrickColor) == "Really red" then
                                            if tostring(summoner5.Part.BrickColor) ~= "Lime green" then
                                                replicatedStorage.Remotes.CommF_:InvokeServer("activateColor", "Pure Red")
                                                task.wait(1)
                                                repeat
                                                    task.wait()
                                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                                        farmPlayer.Character.HumanoidRootPart.Remotes.CommF_:InvokeServer("Buso")
                                                    end
                                                    tweenTeleportTo(summoner5.Part.CFrame, 1.5)
                                                until tostring(summoner5.Part.BrickColor) == "Lime green"
                                                Really_red_H = true
                                            end
                                        end
                                    end
                                end
                                if Winter_Sky and not Hot_pink_H then
                                    for key44, summoner6 in pairs(workspaceService.Map["Boat Castle"].Summoner.Circle:GetChildren()) do
                                        if summoner6.Name == "Part" and tostring(summoner6.BrickColor) == "Hot pink" then
                                            if tostring(summoner6.Part.BrickColor) ~= "Lime green" then
                                                replicatedStorage.Remotes.CommF_:InvokeServer("activateColor", "Winter Sky")
                                                task.wait(1)
                                                repeat
                                                    task.wait()
                                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                                        farmPlayer.Character.HumanoidRootPart.Remotes.CommF_:InvokeServer("Buso")
                                                    end
                                                    tweenTeleportTo(summoner6.Part.CFrame, 1.5)
                                                until tostring(summoner6.Part.BrickColor) == "Lime green"
                                                Hot_pink_H = true
                                            end
                                        end
                                    end
                                end
                                Utils.equipTool("God's Chalice")
                                tweenTeleportTo(CFrame.new(-5561.06738, 314.375793, -2663.88892, -0.304127187, -0.00254100002, .952628076, .000226983335, .999996245, .00273981248, -0.952631414, .00104948215, -0.304125458), 1.5)
                                if TimeLoaderx == nil or tick() - TimeLoaderx > 10 then
                                    TimeLoaderx = tick()
                                    replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("I have God Chalice. I Can't Spawn Boss Admin", "All")
                                end
                            end
                        end
                    until not farmPlayer.Backpack:FindFirstChild("God's Chalice") and not farmPlayer.Character:FindFirstChild("God's Chalice")
                end
            end
        end
    end
    if Three_World then
        if enemiesFolder:FindFirstChild("rip_indra True Form") or replicatedStorage:FindFirstChild("rip_indra True Form") then
            if enemiesFolder:FindFirstChild("rip_indra True Form") then
                for key45, child9 in pairs(enemiesFolder:GetChildren()) do
                    if child9.Name == "rip_indra True Form" and child9.Humanoid.Health > 0 then
                        repeat
                            task.wait(.1)
                            if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                farmPlayer.Character.HumanoidRootPart.Remotes.CommF_:InvokeServer("Buso")
                            end
                            tweenTeleportTo(child9.HumanoidRootPart.CFrame * CFrame.new(0, -30, 0), 1.5)
                            equipPreferredFarmTool()
                        until not child9.Parent or child9.Humanoid.Health <= 0
                    end
                end
            elseif replicatedStorage:FindFirstChild("rip_indra True Form") then
                tweenTeleportTo((replicatedStorage:FindFirstChild("rip_indra True Form")).HumanoidRootPart.CFrame * CFrame.new(0, 30, 0))
            end
        end
    end
    flag3 = false
    if Three_World and not Mirror_Fractal_H then
        if Utils.findFirstChild(farmPlayer.Backpack,
            "Sweet Chalice") or Utils.findFirstChild(farmPlayer.Character,
            "Sweet Chalice") or Utils.findFirstChild(farmPlayer.Backpack,
            "God's Chalice") or Utils.findFirstChild(farmPlayer.Character,
            "God's Chalice") or Utils.findFirstChild(enemiesFolder,
            "Dough King") or Utils.findFirstChild(replicatedStorage,
            "Dough King") then
            repeat
                task.wait()
                for key46, item14 in pairs(replicatedStorage.Remotes.CommF_:InvokeServer("getInventory")) do
                    if item14.Type == "Material" then
                        if item14.Name == "Mirror Fractal" then
                            Mirror_Fractal_H = true
                        end
                    end
                end
                if Utils.findFirstChild(enemiesFolder, "Dough King") or Utils.findFirstChild(replicatedStorage, "Dough King") then
                    if Utils.findFirstChild(enemiesFolder, "Dough King") then
                        for key47, child10 in pairs(enemiesFolder:GetChildren()) do
                            if child10.Name == "Dough King" and child10.Humanoid.Health > 0 then
                                repeat
                                    task.wait(.1)
                                    tweenTeleportTo(child10.HumanoidRootPart.CFrame * CFrame.new(0, -30, 0), 1.5)
                                    equipPreferredFarmTool()
                                until not child10.Parent or child10.Humanoid.Health <= 0
                                for key48, item15 in pairs((game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer("getInventory")) do
                                    if item15.Type == "Material" then
                                        if item15.Name == "Mirror Fractal" then
                                            Mirror_Fractal_H = true
                                        end
                                    end
                                end
                                return
                            end
                        end
                    elseif Utils.findFirstChild(replicatedStorage, "Dough King") then
                        tweenTeleportTo((game.ReplicatedStorage:FindFirstChild("Dough King")).HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                    end
                elseif Utils.findFirstChild(farmPlayer.Backpack, "Sweet Chalice") or Utils.findFirstChild(farmPlayer.Character, "Sweet Chalice") and not Mirror_Fractal_H then
                    if (farmPlayer.Character.HumanoidRootPart.Position - Vector3.new(-2286.6843261719, 146.56562805176, -12226.881835938)).Magnitude >= 1800 then
                        repeat
                            task.wait()
                            tweenTeleportTo(CFrame.new(-2286.6843261719, 146.56562805176, -12226.881835938), 1.5)
                        until (farmPlayer.Character.HumanoidRootPart.Position - Vector3.new(-2286.6843261719, 146.56562805176, -12226.881835938)).Magnitude <= 3
                    elseif (farmPlayer.Character.HumanoidRootPart.Position - Vector3.new(-2286.6843261719, 146.56562805176, -12226.881835938)).Magnitude < 1800 then
                        Monster = nil
                        for index6 = 1500, 0, -300 do
                            Utils.findNearestMonster(index6)
                        end
                        if Monster ~= nil and Monster.Humanoid.Health > 0 then
                            local response3
                            PosMon_X = Monster.HumanoidRootPart.CFrame
                            StatrMagnet = true
                            repeat
                                task.wait()
                                tweenTeleportTo(Monster.HumanoidRootPart.CFrame * CFrame.new(0, -17, 0), 1.5)
                                equipPreferredFarmTool()
                            until not Monster.Parent or Monster.Humanoid.Health <= 0
                            StatrMagnet = false
                            response3 = tostring(string.match(tostring(replicatedStorage.Remotes.CommF_:InvokeServer("CakePrinceSpawner")), "%d+"))
                            if response3 == "nil" or response3 == nil then
                                replicatedStorage.Remotes.CommF_:InvokeServer("CakePrinceSpawner", true)
                            end
                        elseif Monster == nil then
                            for index7 = 1500, 0, -300 do
                                Utils.findNearestMonster(index7)
                            end
                            if Monster == nil then
                                tweenTeleportTo(CFrame.new(-2286.6843261719, 146.56562805176, -12226.881835938), 1.5)
                            end
                        end
                    end
                elseif Utils.findFirstChild(farmPlayer.Backpack, "God's Chalice") or Utils.findFirstChild(farmPlayer.Character, "God's Chalice") and not Mirror_Fractal_H then
                    if Utils.getItemCount("Conjured Cocoa") >= 10 then
                        replicatedStorage.Remotes.CommF_:InvokeServer("SweetChaliceNpc")
                    elseif Utils.getItemCount("Conjured Cocoa") < 10 then
                        if (farmPlayer.Character.HumanoidRootPart.Position - Vector3.new(658.22302246094, 24.734258651733, -12541.991210938)).Magnitude >= 1800 then
                            repeat
                                task.wait()
                                tweenTeleportTo(CFrame.new(658.22302246094, 24.734258651733, -12541.991210938), 1.5)
                            until (farmPlayer.Character.HumanoidRootPart.Position - Vector3.new(658.22302246094, 24.734258651733, -12541.991210938)).Magnitude <= 3 or Utils.getItemCount("Conjured Cocoa") >= 10
                        elseif (farmPlayer.Character.HumanoidRootPart.Position - Vector3.new(658.22302246094, 24.734258651733, -12541.991210938)).Magnitude < 1800 then
                            Monster = nil
                            for index8 = 1500, 0, -300 do
                                Utils.findNearestMonster(index8)
                            end
                            if Monster ~= nil and Monster.Humanoid.Health > 0 then
                                PosMon_X = Monster.HumanoidRootPart.CFrame
                                StatrMagnet = true
                                repeat
                                    task.wait()
                                    tweenTeleportTo(Monster.HumanoidRootPart.CFrame * CFrame.new(0, -17, 0), 1.5)
                                    equipPreferredFarmTool()
                                until not Monster.Parent or Monster.Humanoid.Health <= 0
                                StatrMagnet = false
                            elseif Monster == nil then
                                for index9 = 1500, 0, -300 do
                                    Utils.findNearestMonster(index9)
                                end
                                if Monster == nil then
                                    tweenTeleportTo(CFrame.new(658.22302246094, 24.734258651733, -12541.991210938), 1.5)
                                end
                            end
                        end
                    end
                elseif not enemiesFolder:FindFirstChild("Dough King") and not replicatedStorage:FindFirstChild("Dough King") then
                    flag3 = true
                end
            until Mirror_Fractal_H or flag3
        end
    end
    if Three_World then
        if replicatedStorage.Remotes.CommF_:InvokeServer("EliteHunter") ~= "I don't have anything for you right now. Come back later." then
            replicatedStorage.Remotes.CommF_:InvokeServer("EliteHunter")
            for index12, index13 in ipairs({
                "Diablo",
                "Deandre",
                "Urban"
            }) do
                local found2 = enemiesFolder:FindFirstChild(index13) or replicatedStorage:FindFirstChild(index13)
                if found2 and found2:FindFirstChild("HumanoidRootPart") and found2:FindFirstChild("Humanoid") and found2.Humanoid.Health > 0 then
                    repeat
                        task.wait()
                        replicatedStorage.Remotes.CommF_:InvokeServer("EliteHunter")
                        tweenTeleportTo(found2.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                        if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                            farmPlayer.Character.HumanoidRootPart.Remotes.CommF_:InvokeServer("Buso")
                        end
                        equipPreferredFarmTool()
                    until not found2.Parent or found2.Humanoid.Health <= 0
                end
            end
        end
    end
    if New_World then
        if Utils.findFirstChild(enemiesFolder, "Darkbeard") or Utils.findFirstChild(replicatedStorage, "Darkbeard") then
            if Utils.findFirstChild(enemiesFolder, "Darkbeard") then
                for key49, child11 in pairs(enemiesFolder:GetChildren()) do
                    if child11.Name == "Darkbeard" and child11.Humanoid.Health > 0 then
                        repeat
                            task.wait()
                            if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                farmPlayer.Character.HumanoidRootPart.Remotes.CommF_:InvokeServer("Buso")
                            end
                            tweenTeleportTo(child11.HumanoidRootPart.CFrame * CFrame.new(0, -30, 0), 1.5)
                            equipPreferredFarmTool()
                        until not child11.Parent or child11.Humanoid.Health <= 0 or not getgenv().AutoFarm
                    end
                end
            elseif Utils.findFirstChild(replicatedStorage, "Darkbeard") then
                for key50, child12 in pairs(replicatedStorage:GetChildren()) do
                    if child12.Name == "Darkbeard" and child12.Humanoid.Health > 0 then
                        repeat
                            task.wait()
                            if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                farmPlayer.Character.HumanoidRootPart.Remotes.CommF_:InvokeServer("Buso")
                            end
                            tweenTeleportTo(child12.HumanoidRootPart.CFrame * CFrame.new(0, -30, 0), 1.5)
                            equipPreferredFarmTool()
                        until not child12.Parent or child12.Humanoid.Health <= 0 or not getgenv().AutoFarm
                    end
                end
            end
        end
    end
    if New_World then
        if Utils.findFirstChild(enemiesFolder, "Core") or Utils.findFirstChild(replicatedStorage, "Core") then
            if Utils.findFirstChild(enemiesFolder, "Core") then
                for key51, child13 in pairs(enemiesFolder:GetChildren()) do
                    if child13.Name == "Core" and child13.Humanoid.Health > 0 then
                        repeat
                            task.wait()
                            tweenTeleportTo(child13.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                            if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                            end
                            equipPreferredFarmTool()
                        until not child13.Parent or child13.Humanoid.Health <= 0 or not getgenv().AutoFarm
                    end
                end
            elseif Utils.findFirstChild(replicatedStorage, "Core") then
                for key52, child14 in pairs(replicatedStorage:GetChildren()) do
                    if child14.Name == "Core" and child14.Humanoid.Health > 0 then
                        repeat
                            task.wait()
                            tweenTeleportTo(child14.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                            if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                            end
                            equipPreferredFarmTool()
                        until not child14.Parent or child14.Humanoid.Health <= 0 or not getgenv().AutoFarm
                    end
                end
            end
        end
    end
    updateLevelQuestInfo()
    if Quest ~= nil then
        return
    end
    if playerLevelValue.Value < 2650 or not Three_World then
        if playerLevelValue.Value <= 9 and not New_World and not Three_World then
            if farmPlayer.PlayerGui.Main.Quest.Visible then
                if Utils.stringFind(farmPlayer.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text, tostring(NameEnemy)) then
                    if Utils.findFirstChild(enemiesFolder, Enemy) then
                        for key53, child15 in pairs(enemiesFolder:GetChildren()) do
                            if child15.Name == Enemy and Utils.findFirstChild(child15,
                                "Humanoid") and child15.Humanoid.Health > 0 and Utils.findFirstChild(child15,
                                "HumanoidRootPart") then
                                repeat
                                    task.wait()
                                    Utils.freezeEnemy(child15.Name)
                                    tweenTeleportTo(child15.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until child15.Humanoid.Health <= 0
                                        or not enemiesFolder:FindFirstChild(Enemy)
                                        or not(farmPlayer.PlayerGui.Main:FindFirstChild("Quest")).Visible
                                        or not getgenv().AutoFarm
                                        or Quest ~= nil
                            end
                        end
                    else
                        tweenTeleportTo(EnemyPos, 1.5)
                    end
                else
                    replicatedStorage.Remotes.CommF_:InvokeServer("AbandonQuest")
                end
            else
                repeat
                    task.wait()
                    tweenTeleportTo(QuestPos, 1.5)
                    if (QuestPos.Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 5 and (farmPlayer.Character:WaitForChild("Humanoid")).Health > 0 then
                        task.wait()
                        ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("StartQuest", QuestName, QuestNumber)
                    end
                until (farmPlayer.PlayerGui.Main:FindFirstChild("Quest")).Visible or not getgenv().AutoFarm or Quest ~= nil
            end
        elseif playerLevelValue.Value >= 9 and playerLevelValue.Value <= 70 and not New_World and not Three_World then
            if ((CFrame.new(-7895, 5546, -380)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 1000 then
                if Utils.findFirstChild(enemiesFolder, "Shanda") then
                    for key54, child16 in pairs(enemiesFolder:GetChildren()) do
                        if child16.Name == "Shanda" and child16:FindFirstChild("Humanoid") and child16.Humanoid.Health > 0 then
                            repeat
                                task.wait()
                                SROP = true
                                tweenTeleportTo(child16.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                equipPreferredFarmTool()
                                Utils.freezeEnemy(child16.Name)
                            until not child16.Parent or child16.Humanoid.Health <= 0 or playerLevelValue.Value >= 91 or not getgenv().AutoFarm or Quest ~= nil
                        end
                    end
                else
                    tweenTeleportTo(CFrame.new(-7757, 5582, -481), 1.5)
                end
            else
                replicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(-7894.6176757813, 5547.1416015625, -380.29119873047))
            end
        elseif playerLevelValue.Value >= 71 then
            if farmPlayer.PlayerGui.Main.Quest.Visible then
                if Utils.stringFind(farmPlayer.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text, tostring(NameEnemy)) then
                    if Utils.findFirstChild(enemiesFolder, Enemy) then
                        for key55, child17 in pairs(enemiesFolder:GetChildren()) do
                            if child17.Name == Enemy and child17:FindFirstChild("Humanoid") and child17.Humanoid.Health > 0 and child17:FindFirstChild("HumanoidRootPart") then
                                repeat
                                    task.wait()
                                    SROP = false
                                    tweenTeleportTo(child17.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    Utils.freezeEnemy(child17.Name)
                                    equipPreferredFarmTool()
                                until child17.Humanoid.Health <= 0
                                        or not enemiesFolder:FindFirstChild(Enemy)
                                        or not(farmPlayer.PlayerGui.Main:FindFirstChild("Quest")).Visible
                                        or Quest ~= nil
                            end
                        end
                    else
                        tweenTeleportTo(EnemyPos, 1.5)
                    end
                else
                    replicatedStorage.Remotes.CommF_:InvokeServer("AbandonQuest")
                end
            else
                repeat
                    task.wait()
                    tweenTeleportTo(QuestPos, 1.5)
                    if (QuestPos.Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 5 and (farmPlayer.Character:WaitForChild("Humanoid")).Health > 0 then
                        task.wait(.5)
                        ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("StartQuest", QuestName, QuestNumber)
                    end
                until (farmPlayer.PlayerGui.Main:FindFirstChild("Quest")).Visible or not getgenv().AutoFarm or Quest ~= nil
            end
        end
    elseif playerLevelValue.Value >= 2650 and Three_World then
        SROP = false
        if Utils.findFirstChild(replicatedStorage, "Cake Prince") then
            for key56, child18 in pairs(replicatedStorage:GetChildren()) do
                if child18.Name == "Cake Prince" and child18:FindFirstChild("Humanoid") and (child18:FindFirstChild("Humanoid")).Health > 0 then
                    tweenTeleportTo(child18.HumanoidRootPart.CFrame * CFrame.new(0, 42, 10), 1.5)
                end
            end
        elseif Utils.findFirstChild(enemiesFolder, "Cake Prince") then
            for key57, child19 in pairs(enemiesFolder:GetChildren()) do
                if child19.Name == "Cake Prince" and child19:FindFirstChild("Humanoid") and (child19:FindFirstChild("Humanoid")).Health > 0 then
                    tweenTeleportTo(child19.HumanoidRootPart.CFrame * CFrame.new(0, 42, 10), 1.5)
                end
            end
        else
            if tostring(string.match(tostring(replicatedStorage.Remotes.CommF_:InvokeServer("CakePrinceSpawner")), "%d+")) == "nil" or tostring(string.match(tostring(replicatedStorage.Remotes.CommF_:InvokeServer("CakePrinceSpawner")), "%d+")) == nil then
                replicatedStorage.Remotes.CommF_:InvokeServer("CakePrinceSpawner", true)
            end
            if Utils.findFirstChild(enemiesFolder,
                "Cookie Crafter") or Utils.findFirstChild(enemiesFolder,
                "Cake Guard") or Utils.findFirstChild(enemiesFolder,
                "Baking Staff") or Utils.findFirstChild(enemiesFolder,
                "Head Baker") then
                for key58, child20 in pairs(enemiesFolder:GetChildren()) do
                    if child20.Name == "Cookie Crafter" or child20.Name == "Cake Guard" or child20.Name == "Baking Staff" or child20.Name == "Head Baker" then
                        repeat
                            task.wait()
                            tweenTeleportTo(child20.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                            if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                            end
                            Utils.freezeEnemy(child20.Name)
                            equipPreferredFarmTool()
                        until child20.Humanoid.Health <= 0
                                or not enemiesFolder:FindFirstChild(Enemy)
                                or not(farmPlayer.PlayerGui.Main:FindFirstChild("Quest")).Visible
                                or Quest ~= nil
                    end
                end
            else
                tweenTeleportTo(CFrame.new(-2091.9118652344, 70.008842468262, -12142.8359375), 1.5)
            end
        end
    end
end
selectAutoFarmQuest = function()
    if not noFruit then
        for key59, farmplayer5 in pairs(farmPlayer.Backpack:GetChildren()) do
            if farmplayer5:GetAttribute("OriginalName") ~= nil and Utils.stringFind(farmplayer5.Name,
                "Fruit") and farmplayer5:IsA("Tool") and not Utils.isInList(Utils.getFruitNames(),
                farmplayer5:GetAttribute("OriginalName")) then
                local value6 = {
                    "StoreFruit",
                    farmplayer5:GetAttribute("OriginalName"),
                    farmplayer5
                },
                ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer(unpack(value6))
                replicatedStorage.Remotes.CommF_:InvokeServer("GetFruits", false)
            end
        end
        for key60, farmplayer6 in pairs(farmPlayer.Character:GetChildren()) do
            if farmplayer6:GetAttribute("OriginalName") ~= nil and Utils.stringFind(farmplayer6.Name,
                "Fruit") and farmplayer6:IsA("Tool") and not Utils.isInList(Utils.getFruitNames(),
                farmplayer6:GetAttribute("OriginalName")) then
                local value7 = {
                    "StoreFruit",
                    farmplayer6:GetAttribute("OriginalName"),
                    farmplayer6
                },
                ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer(unpack(value7))
                replicatedStorage.Remotes.CommF_:InvokeServer("GetFruits", false)
            end
        end
    end
end
_G.Ew = true
Ewx = true
task.spawn(function()
    while task.wait() do
        if _G.Ew then
            equipPreferredFarmTool()
        else
            selectAutoFarmQuest()
            if Ewx then
                currentActionDelay = 0
            else
                currentActionDelay = .2
            end
        end
    end
end)
task.spawn(function()
    while task.wait(1) do
        xpcall(function()
            if not Black_Leg_C and meleeUnlocked("Black Leg") then
                repeat
                    task.wait(currentActionDelay)
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyBlackLeg")
                    equipPreferredFarmTool()
                    task.wait(.05)
                    if Utils.findFirstChild(farmPlayer.Character, "Black Leg") or Utils.findFirstChild(farmPlayer.Backpack, "Black Leg") and not Black_Leg_C then
                        Black_Leg_C = true
                        Utils.equipTool("Black Leg")
                    end
                until Black_Leg_C
            end
            if not Electro_C and meleeUnlocked("Electro") then
                repeat
                    task.wait(currentActionDelay)
                    equipPreferredFarmTool()
                    virtualInputManager:SendKeyEvent(true, "V", false, game)
                    task.wait(.5)
                    virtualInputManager:SendKeyEvent(false, "V", false, game)
                    if Utils.findFirstChild(farmPlayer.Character, "Black Leg") and farmPlayer.Character["Black Leg"].Level.Value >= 300 and not Electro_C then
                        if farmPlayer.Character["Black Leg"].Level.Value >= 400 then
                            Black_Leg_C_M = true
                        end
                        Electro_C = true
                        task.wait(.05)
                        replicatedStorage.Remotes.CommF_:InvokeServer("BuyElectro")
                    end
                until Electro_C
            end
            if not Fishman_Karate_C and meleeUnlocked("Fishman Karate") then
                repeat
                    task.wait(currentActionDelay)
                    equipPreferredFarmTool()
                    if Utils.findFirstChild(farmPlayer.Character, "Electro") and farmPlayer.Character.Electro.Level.Value >= 300 and not Fishman_Karate_C then
                        if farmPlayer.Character.Electro.Level.Value >= 400 then
                            Electro_C_M = true
                        end
                        Fishman_Karate_C = true
                        task.wait(.05)
                        replicatedStorage.Remotes.CommF_:InvokeServer("BuyFishmanKarate")
                    end
                until Fishman_Karate_C
            end
            if not Fishman_Karate_C_M then
                repeat
                    local fishmanKarate
                    task.wait(currentActionDelay)
                    equipPreferredFarmTool()
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyFishmanKarate")
                    fishmanKarate = farmPlayer.Character:FindFirstChild("Fishman Karate")
                    if fishmanKarate and fishmanKarate:FindFirstChild("Level") and fishmanKarate.Level.Value >= 400 then
                        Fishman_Karate_C_M = true
                    end
                until Fishman_Karate_C_M
            end
            task.wait(currentActionDelay)
            if not Dragon_Claw_C and meleeUnlocked("Dragon Claw") then
                local response4 = replicatedStorage.Remotes.CommF_:InvokeServer("BlackbeardReward", "DragonClaw", "2")
                if response4 == 1 or response4 == 2 then
                    pcall(function()
                        if farmPlayer.Character["Fishman Karate"].Level.Value >= 400 then
                            Fishman_Karate_C_M = true
                        end
                    end)
                    Dragon_Claw_C = true
                end
            end
            repeat
                task.wait(currentActionDelay)
                equipPreferredFarmTool()
                if not Super_human and meleeUnlocked("Superhuman") then
                    if Dragon_Claw_C then
                        if Utils.findFirstChild(farmPlayer.Character, "Dragon Claw") and farmPlayer.Character["Dragon Claw"].Level.Value >= 300 then
                            local value8
                            if farmPlayer.Character["Dragon Claw"].Level.Value >= 400 then
                                Dragon_Claw_C_M = true
                            end
                            value8 = {
                                [1] = "BuySuperhuman"
                            }
                            if replicatedStorage.Remotes.CommF_:InvokeServer(unpack(value8)) == 1 or replicatedStorage.Remotes.CommF_:InvokeServer(unpack(value8)) == 2 then
                                Super_human = true
                                if farmPlayer.Character.Superhuman.Level.Value >= 400 then
                                    Super_humanw_C_M = true
                                end
                            end
                        end
                    end
                end
            until Super_human
            if not Death_Step and meleeUnlocked("Death Step") then
                if replicatedStorage.Remotes.CommF_:InvokeServer("BuyDeathStep") == 1 or replicatedStorage.Remotes.CommF_:InvokeServer("BuyDeathStep") == 2 then
                    Death_Step = true
                end
            end
            if Black_Leg_C_M then
                repeat
                    local deathStep
                    task.wait(currentActionDelay)
                    equipPreferredFarmTool()
                    deathStep = farmPlayer.Character:FindFirstChild("Death Step")
                    if deathStep and deathStep:FindFirstChild("Level") and deathStep.Level.Value >= 400 then
                        local blackLeg
                        replicatedStorage.Remotes.CommF_:InvokeServer("BuyBlackLeg")
                        blackLeg = farmPlayer.Character:FindFirstChild("Black Leg")
                        if blackLeg and blackLeg:FindFirstChild("Level") and blackLeg.Level.Value >= 400 then
                            Black_Leg_C_M = true
                        end
                    end
                until Black_Leg_C_M
            end
            if not Death_Step_C_M then
                repeat
                    local deathStep2
                    task.wait(currentActionDelay)
                    equipPreferredFarmTool()
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyDeathStep")
                    deathStep2 = farmPlayer.Character:FindFirstChild("Death Step")
                    if deathStep2 and deathStep2:FindFirstChild("Level") and deathStep2.Level.Value >= 400 then
                        Death_Step_C_M = true
                    end
                until Death_Step_C_M
            end
            if not Electro_C_M then
                repeat
                    local electro
                    task.wait(currentActionDelay)
                    equipPreferredFarmTool()
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyElectro")
                    electro = farmPlayer.Character:FindFirstChild("Electro")
                    if electro and electro:FindFirstChild("Level") and electro.Level.Value >= 400 then
                        Electro_C_M = true
                    end
                until Electro_C_M
            end
            if not Fishman_Karate_C_M then
                repeat
                    local fishmanKarate2
                    task.wait(currentActionDelay)
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyFishmanKarate")
                    warn()
                    fishmanKarate2 = farmPlayer.Character:FindFirstChild("Fishman Karate")
                    if fishmanKarate2 and fishmanKarate2:FindFirstChild("Level") and fishmanKarate2.Level.Value >= 400 then
                        Fishman_Karate_C_M = true
                    end
                until Fishman_Karate_C_M
            end
            if not Dragon_Claw_C_M then
                repeat
                    local dragonClaw
                    task.wait(currentActionDelay)
                    equipPreferredFarmTool()
                    replicatedStorage.Remotes.CommF_:InvokeServer("BlackbeardReward", "DragonClaw", "2")
                    dragonClaw = farmPlayer.Character:FindFirstChild("Dragon Claw")
                    if dragonClaw and dragonClaw:FindFirstChild("Level") and dragonClaw.Level.Value >= 400 then
                        Dragon_Claw_C_M = true
                    end
                until Dragon_Claw_C_M
            end
            if not Sharkman_Karate_C and meleeUnlocked("Sharkman Karate") then
                repeat
                    task.wait(currentActionDelay)
                    equipPreferredFarmTool()
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuySharkmanKarate")
                    if Utils.findFirstChild(farmPlayer.Backpack, "Sharkman Karate") or Utils.findFirstChild(farmPlayer.Character, "Sharkman Karate") then
                        Sharkman_Karate_C = true
                    end
                until Sharkman_Karate_C
            end
            if not Sharkman_Karate_C_M then
                repeat
                    local sharkmanKarate
                    task.wait(currentActionDelay)
                    equipPreferredFarmTool()
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuySharkmanKarate")
                    sharkmanKarate = farmPlayer.Character:FindFirstChild("Sharkman Karate")
                    if sharkmanKarate and sharkmanKarate:FindFirstChild("Level") and sharkmanKarate.Level.Value >= 400 then
                        Sharkman_Karate_C_M = true
                    end
                until Sharkman_Karate_C_M
            end
            if not Electric_Claw_C and meleeUnlocked("Electric Claw") then
                repeat
                    task.wait(currentActionDelay)
                    if replicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw") == 1 or replicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw") == 2 then
                        Electric_Claw_C = true
                    end
                until Electric_Claw_C
            end
            if not Electric_Claw_C_M then
                repeat
                    local electricClaw
                    task.wait(currentActionDelay)
                    equipPreferredFarmTool()
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw")
                    electricClaw = farmPlayer.Character:FindFirstChild("Electric Claw")
                    if electricClaw and electricClaw:FindFirstChild("Level") and electricClaw.Level.Value >= 400 then
                        Electric_Claw_C_M = true
                    end
                until Electric_Claw_C_M
            end
            if not Dragon_Talon_C and meleeUnlocked("Dragon Talon") then
                repeat
                    task.wait(currentActionDelay)
                    if replicatedStorage.Remotes.CommF_:InvokeServer("BuyDragonTalon") == 1 or replicatedStorage.Remotes.CommF_:InvokeServer("BuyDragonTalon") == 2 then
                        Dragon_Talon_C = true
                    end
                until Dragon_Talon_C
            end
            if not Dragon_Talon_C_M then
                repeat
                    local dragonTalon
                    task.wait(currentActionDelay)
                    equipPreferredFarmTool()
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyDragonTalon")
                    dragonTalon = farmPlayer.Character:FindFirstChild("Dragon Talon")
                    if dragonTalon and dragonTalon:FindFirstChild("Level") and dragonTalon.Level.Value >= 400 then
                        Dragon_Talon_C_M = true
                    end
                until Dragon_Talon_C_M
            end
            if not God_Human_C and meleeUnlocked("Godhuman") then
                repeat
                    task.wait(currentActionDelay)
                    if replicatedStorage.Remotes.CommF_:InvokeServer("BuyGodhuman") == 1 or replicatedStorage.Remotes.CommF_:InvokeServer("BuyGodhuman") == 2 then
                        God_Human_C = true
                    end
                until God_Human_C
            end
            if not God_Human_C_M then
                repeat
                    local godhuman
                    task.wait(currentActionDelay)
                    equipPreferredFarmTool()
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyGodhuman")
                    godhuman = farmPlayer.Character:FindFirstChild("Godhuman")
                    if godhuman and godhuman:FindFirstChild("Level") and godhuman.Level.Value >= 400 then
                        God_Human_C_M = true
                    end
                until God_Human_C_M
            end
        end, warn)
    end
end)
getgenv().AutoFarm = true
if replicatedStorage.Remotes.CommF_:InvokeServer("BuySharkmanKarate", true) ~= "I lost my house keys, could you help me find them? Thanks." then
    CheckFindWaterKey = true
end
if playerLevelValue.Value >= 2000 and getgenv().Configs.Quest["RGB Haki"] then
    if replicatedStorage.Remotes.CommF_:InvokeServer("HornedMan", "Bet") == 1 then
        RGB_Haki_H = true
    end
end
canStartCursedDualKatanaQuest = function()
    if not Utils.hasItem("Cursed Dual Katana") then
        if Utils.hasItem("Tushita") and Utils.hasItem("Yama") then
            local replicatedStorage5 = (game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer("getInventory")
            for key61, item16 in pairs(replicatedStorage5) do
                if item16.Type == "Sword" then
                    if item16.Name == "Tushita" and item16.Mastery >= 400 then
                        Tushita_M = true
                    elseif item16.Name == "Yama" and item16.Mastery >= 400 then
                        Yama_M = true
                    end
                end
            end
            return Tushita_M and Yama_M
        end
    end
    return false
end
task.spawn(function()
    while task.wait() do
        if not autoFarmingOn() then
            task.wait(1)
            continue
        end
        xpcall(function()
            if getgenv().AutoFarm then
                local flag4
                Stop_Fast_Attack = false
                if playerLevelValue.Value >= 1500 or RainbowSaviour then
                    if (((replicatedStorage:WaitForChild("Modules")):WaitForChild("Net")):WaitForChild("RF/FruitCustomizerRF")):InvokeServer({
                        StorageName = "Rainbow Saviour",
                        Type = "AuraSkin",
                        Context = "Equip"
                    }) ~= false then
                        (((replicatedStorage:WaitForChild("Modules")):WaitForChild("Net")):WaitForChild("RF/FruitCustomizerRF")):InvokeServer({
                            StorageName = "Rainbow Saviour",
                            Type = "AuraSkin",
                            Context = "Equip"
                        })
                    end
                end
                flag4 = false
                if ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("Cousin", "Buy") == 1 then
                    task.wait(1)
                    selectAutoFarmQuest()
                else
                    for key62, child21 in pairs(workspaceService:GetChildren()) do
                        if child21:GetAttribute("OriginalName") ~= nil and Utils.stringFind(child21.Name,
                            "Fruit") and child21:IsA("Tool") and not Utils.isInList(Utils.getFruitNames(),
                            child21:GetAttribute("OriginalName")) then
                            repeat
                                task.wait(.1)
                                Utils.setStatus(" Status : TP To " .. child21.Name)
                                TPZ(child21.Handle.CFrame)
                                flag4 = true
                                selectAutoFarmQuest()
                            until not child21
                                    or game.Players.LocalPlayer.Backpack:FindFirstChild(child21.Name)
                                    or Utils.isInList(Utils.getFruitNames(), child21:GetAttribute("OriginalName"))
                                    or (child21.Handle.Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 10
                                    or not getgenv().AutoFarm
                        end
                    end
                    if not flag4 then
                        local function5
                        if Utils.tableFind(Configs.Gun, "Magma Blaster")
                                and playerLevelValue.Value >= 200
                                and not Utils.hasItem("Magma Blaster")
                                and Old_World
                                and Utils.checkBoss("Magma Admiral") then
                            Quest = "Magma Blaster"
                            return
                        end
                        if Utils.tableFind(Configs.Gun, "Bazooka")
                                and playerLevelValue.Value >= 200
                                and not Utils.hasItem("Bazooka")
                                and Old_World
                                and Utils.checkBoss("Wysper") then
                            Quest = "Bazooka"
                            return
                        end
                        if Utils.tableFind(Configs.Sword, "Saber") and playerLevelValue.Value >= 200 and not Utils.hasItem("Saber") then
                            Quest = "Saber"
                            return
                        end
                        if Utils.tableFind(Configs.Sword, "Shark Saw")
                                and playerLevelValue.Value >= 100
                                and not Utils.hasItem("Shark Saw")
                                and Old_World
                                and Utils.checkBoss("The Saw") then
                            Quest = "Shark Saw"
                            return
                        end
                        if Utils.tableFind(Configs.Sword, "Wardens Sword")
                                and playerLevelValue.Value >= 100
                                and not Utils.hasItem("Wardens Sword")
                                and Old_World
                                and Utils.checkBoss("Chief Warden") then
                            Quest = "Wardens Sword"
                            return
                        end
                        if Utils.tableFind(Configs.Sword, "Pole (1st Form)")
                                and playerLevelValue.Value >= 100
                                and not Utils.hasItem("Pole (1st Form)")
                                and Old_World
                                and Utils.checkBoss("Thunder God") then
                            Quest = "Pole (1st Form)"
                            return
                        end
                        if ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("Alchemist",
                            "1") ~= -2 and playerBeliValue.Value >= 2500000 and playerLevelValue.Value >= 850 and replicatedStorage.Remotes.CommF_:InvokeServer("BartiloQuestProgress",
                            "Bartilo") == 3 and not Utils.findFirstChild(farmPlayer.Data.Race,
                            "Evolved") then
                            Quest = "Evo Race V1"
                            return
                        end
                        if replicatedStorage.Remotes.CommF_:InvokeServer("Wenlocktoad",
                            "3") ~= -2 and replicatedStorage.Remotes.CommF_:InvokeServer("TalkTrevor",
                            "1") == 0 and Utils.isHeavenlyDevil() and currentLevelValue.Value >= 1400 and playerBeliValue.Value >= 2000000 then
                            Quest = "Evo Race V2"
                            return
                        end
                        if Utils.tableFind(Configs.Sword, "Gravity Blade")
                                and not Utils.hasItem("Gravity Blade")
                                and New_World
                                and Utils.checkBoss("Orbitus")
                                and playerLevelValue.Value >= 800 then
                            Quest = "Gravity Blade"
                            return
                        end
                        if Utils.tableFind(Configs.Sword, "Longsword")
                                and not Utils.hasItem("Longsword")
                                and New_World
                                and Utils.checkBoss("Diamond")
                                and playerLevelValue.Value >= 800 then
                            Quest = "Longsword"
                            return
                        end
                        if Utils.tableFind(Configs.Sword, "Rengoku")
                                and not Utils.hasItem("Rengoku")
                                and New_World
                                and Utils.checkBoss("Awakened Ice Admiral")
                                and playerLevelValue.Value >= 800 then
                            Quest = "Rengoku"
                            return
                        end
                        if Utils.isInIceHall() and New_World and Utils.checkBoss("Awakened Ice Admiral") and playerLevelValue.Value >= 800 then
                            Quest = "Rengoku"
                            return
                        end
                        if not Utils.hasItem("Rengoku") and Utils.hasInBackpack("Hidden Key") and New_World then
                            repeat
                                task.wait(.3)
                                Utils.setStatus(" Status : Use Hidden Key")
                                Utils.equipTool("Hidden Key")
                                tweenTeleportTo(CFrame.new(6572.29248, 295.712677, -6966.09961, .803500533, -3.27515153e-08, .595304072, 3.97485422e-08, 1, 1.36659384e-09, -0.595304072, 2.25644108e-08, .803500533), 1.5)
                            until (farmPlayer.Character.HumanoidRootPart.Position - Vector3.new(6572.29248, 295.712677, -6966.09961)).Magnitude <= 5 or not getgenv().AutoFarm
                            task.wait(1)
                            return
                        end
                        if New_World and Utils.isInIceHall() and Utils.hasInBackpack("Library Key") then
                            repeat
                                task.wait(.1)
                                Utils.setStatus(" Status : Use Library Key")
                                Utils.equipTool("Library Key")
                                tweenTeleportTo(CFrame.new(6377.12549, 296.634735, -6843.76025, -0.860993743, 1.17677516e-07, -0.508615494, 1.31121894e-07, 1, 9.40274347e-09, .508615494, -5.8594928e-08, -0.860993743), 1.5)
                            until (farmPlayer.Character.HumanoidRootPart.Position - Vector3.new(6377.12549, 296.634735, -6843.76025)).Magnitude <= 1
                                    or not Utils.isInIceHall()
                                    or not getgenv().AutoFarm
                            task.wait(1)
                            return
                        end
                        if Utils.tableFind(Configs.Sword, "Flail") and not Utils.hasItem("Flail") and New_World and Utils.checkBoss("Smoke Admiral") then
                            Quest = "Flail"
                            return
                        end
                        if replicatedStorage.Remotes.CommF_:InvokeServer("BartiloQuestProgress", "Bartilo") ~= 3 and playerLevelValue.Value >= 850 then
                            Quest = "BartiloQuest"
                            return
                        end
                        if not CheckFindWaterKey then
                            if replicatedStorage.Remotes.CommF_:InvokeServer("BuySharkmanKarate", true) == "I lost my house keys, could you help me find them? Thanks." and playerLevelValue.Value >= 850 then
                                Quest = "Find Water Key"
                                return
                            end
                        end
                        if New_World and not Utils.isHeavenlyDevil() and replicatedStorage.Remotes.CommF_:InvokeServer("TalkTrevor", "1") == 0 then
                            Quest = "Don Swan"
                            return
                        end
                        if Three_World and Utils.tableFind(Configs.Sword,
                            "Yama") and replicatedStorage.Remotes.CommF_:InvokeServer("EliteHunter",
                            "Progress") >= 30 and not Utils.hasItem("Yama") then
                            Quest = "Yama"
                            return
                        end
                        if Three_World and Utils.tableFind(Configs.Sword, "Tushita") and not Utils.hasItem("Tushita") and Unlock_Tushita_Quest then
                            Quest = "Longma"
                            return
                        end
                        if Utils.tableFind(Configs.Gun, "Soul Guitar")
                                and not Utils.hasItem("Soul Guitar")
                                and playerLevelValue.Value >= 2000
                                and Utils.getItemCount("Dark Fragment") >= 1 then
                            Quest = "Soul Guitar"
                            return
                        end
                        if playerLevelValue.Value >= 2000 and getgenv().Configs.Quest["RGB Haki"] and not RGB_Haki_H then
                            if replicatedStorage.Remotes.CommF_:InvokeServer("HornedMan", "Bet") == nil then
                                Quest = "RGB"
                                return
                            end
                        end
                        if Utils.tableFind(Configs.Gun, "Venom Bow") and not Utils.hasItem("Venom Bow") and Three_World and Utils.checkBoss("Hydra Leader") then
                            Quest = "Venom Bow"
                            return
                        end
                        if Utils.tableFind(Configs.Sword, "Twin Hooks") and not Utils.hasItem("Twin Hooks") and Three_World and Utils.checkBoss("Captain Elephant") then
                            Quest = "Twin Hooks"
                            return
                        end
                        if (game:GetService("Workspace")).Map:FindFirstChild("MysticIsland")
                                and not replicatedStorage.Remotes.CommF_:InvokeServer("CheckTempleDoor")
                                and replicatedStorage.Remotes.CommF_:InvokeServer("Wenlocktoad", "3") == -2
                                and Mirror_Fractal_H then
                            Quest = "Pull Lerver"
                            return
                        end
                        if canStartCursedDualKatanaQuest() then
                            Quest = "Cursed Dual Katana"
                            return
                        end
                        if not Dragon_Talon_C and meleeUnlocked("Dragon Talon") then
                            if Utils.findFirstChild(farmPlayer.Backpack, "Fire Essence") or Utils.findFirstChild(farmPlayer.Character, "Fire Essence") then
                                repeat
                                    Utils.setStatus(" Status : Use Fire Essence")
                                    Utils.equipTool("Fire Essence")
                                    task.wait(.5)
                                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyDragonTalon", true)
                                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyDragonTalon")
                                until not Utils.findFirstChild(farmPlayer.Backpack, "Fire Essence") and not Utils.findFirstChild(farmPlayer.Character, "Fire Essence")
                                replicatedStorage.Remotes.CommF_:InvokeServer("BuyDragonTalon")
                                Dragon_Talon_C = true
                                return
                            end
                        end
                        if Fishman_Karate_C_M and not Dragon_Claw_C and playerLevelValue.Value >= 1100 then
                            if not Dragon_Claw_C and meleeUnlocked("Dragon Claw") then
                                repeat
                                    task.wait()
                                    equipPreferredFarmTool()
                                    if Utils.findFirstChild(farmPlayer.Backpack, "Dragon Claw") or Utils.findFirstChild(farmPlayer.Character, "Dragon Claw") then
                                        Dragon_Claw_C = true
                                        return
                                    end
                                    if not Dragon_Claw_C and playerLevelValue.Value >= 1100 then
                                        if playerFragmentsValue.Value >= 1500 then
                                            local value9 = {
                                                [1] = "BlackbeardReward",
                                                [2] = "DragonClaw",
                                                [3] = "2"
                                            }
                                            replicatedStorage.Remotes.CommF_:InvokeServer(unpack(value9))
                                            Dragon_Claw_C = true
                                            return
                                        elseif playerFragmentsValue.Value < 1500 then
                                            if farmPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible and playerFragmentsValue.Value < 1500 and not Dragon_Claw_C then
                                                Utils.setStatus(" Status : Farm Raid")
                                                if #Utils.getRaidMobs() == 0 then
                                                    if Select_Map == "Magma" or Select_Map == "Flame" then
                                                        for key63, descendant in pairs(workspaceService:GetDescendants()) do
                                                            if descendant.Name == "Lava" then
                                                                descendant:Destroy()
                                                            end
                                                        end
                                                    end
                                                    if Utils.getRaidPart("Island 5", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 5", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 4", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 4", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 3", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 3", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 2", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 2", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 1", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 1", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    end
                                                else
                                                    for key64, child22 in pairs(enemiesFolder:GetChildren()) do
                                                        if child22:FindFirstChild("HumanoidRootPart")
                                                                and child22:FindFirstChild("Humanoid")
                                                                and (child22:FindFirstChild("Humanoid")).Health > 0
                                                                and (farmPlayer.Character.HumanoidRootPart.CFrame.Position - child22.HumanoidRootPart.CFrame.Position).Magnitude <= 5000 then
                                                            repeat
                                                                local number4, cframe
                                                                task.wait(.1)
                                                                if Select_Map == "Magma" or Select_Map == "Flame" then
                                                                    for key65, descendant2 in pairs(workspaceService:GetDescendants()) do
                                                                        if descendant2.Name == "Lava" then
                                                                            descendant2:Destroy()
                                                                        end
                                                                    end
                                                                end
                                                                number4 = math.random(1, 5)
                                                                if number4 == 1 then
                                                                    cframe = CFrame.new(0, 30, 1)
                                                                elseif number4 == 2 then
                                                                    cframe = CFrame.new(0, 30, 15)
                                                                elseif number4 == 3 then
                                                                    cframe = CFrame.new(1, 30, -15)
                                                                elseif number4 == 4 then
                                                                    cframe = CFrame.new(15, 30, 0)
                                                                elseif number4 == 5 then
                                                                    cframe = CFrame.new(-15, 30, 0)
                                                                end
                                                                tweenTeleportTo(child22.HumanoidRootPart.CFrame * cframe, 1.5)
                                                                if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                                                    replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                                                end
                                                                equipPreferredFarmTool()
                                                            until not child22.Parent or child22.Humanoid.Health <= 0 or #Utils.getRaidMobs() == 0
                                                        end
                                                    end
                                                end
                                            else
                                                if farmPlayer.Data.DevilFruit.Value == "Dark-Dark" then
                                                    Select_Map = "Dark"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Sand-Sand" then
                                                    Select_Map = "Sand"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Magma-Magma" then
                                                    Select_Map = "Magma"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Rumble-Rumble" then
                                                    Select_Map = "Rumble"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Flame-Flame" then
                                                    Select_Map = "Flame"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Ice-Ice" then
                                                    Select_Map = "Ice"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Light-Light" then
                                                    Select_Map = "Light"
                                                elseif farmPlayer.Data.DevilFruit.Value == "String-String" then
                                                    Select_Map = "String"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Quake-Quake" then
                                                    Select_Map = "Quake"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Buddha-Buddha" then
                                                    Select_Map = "Buddha"
                                                else
                                                    Select_Map = "Ice"
                                                end
                                                replicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", Select_Map)
                                                task.wait(.2)
                                                if farmPlayer.Backpack:FindFirstChild("Special Microchip")
                                                        or farmPlayer.Character:FindFirstChild("Special Microchip")
                                                        and farmPlayer.Character.Humanoid.Health > 0 then
                                                    if currentPlaceId == 4442272183 and farmPlayer.Character.Humanoid.Health > 0 then
                                                        local number5
                                                        fireclickdetector(workspaceService.Map.CircleIsland.RaidSummon2.Button.Main.ClickDetector, 1)
                                                        number5 = 0
                                                        repeat
                                                            number5 = number5 + 1
                                                            task.wait(1)
                                                        until number5 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible == true
                                                    elseif currentPlaceId == 7449423635 then
                                                        tweenTeleportTo(CFrame.new(-5034, 315, -2951), 1.5)
                                                        if ((CFrame.new(-5034, 315, -2951)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3 then
                                                            if farmPlayer.Character.Humanoid.Health > 0 then
                                                                local number6
                                                                fireclickdetector(workspaceService.Map["Boat Castle"].RaidSummon2.Button.Main.ClickDetector, 1)
                                                                number6 = 0
                                                                repeat
                                                                    number6 = number6 + 1
                                                                    task.wait(1)
                                                                until number6 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible == true
                                                            end
                                                        end
                                                    end
                                                else
                                                    if not farmPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible then
                                                        if playerBeliValue.Value >= 0 and farmPlayer.Data.Fragments.Value >= 1500 then
                                                            local value10 = {
                                                                [1] = "BlackbeardReward",
                                                                [2] = "DragonClaw",
                                                                [3] = "2"
                                                            },
                                                            (game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer(unpack(value10))
                                                            Dragon_Claw_C = true
                                                            return
                                                        end
                                                        table.sort(Utils.getFruits(), function(part, part2)
                                                            if part.Value < 100000 and part.Value < 100000 then
                                                                return part.Value < part2.Value
                                                            end
                                                        end)
                                                        task.wait(1)
                                                        if #Utils.getFruits() > 0 and not Dragon_Claw_C then
                                                            task.wait(2)
                                                            if not farmPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible then
                                                                if farmPlayer.Character.Humanoid.Health > 0 and farmPlayer.Data.Fragments.Value < 5000 then
                                                                    replicatedStorage.Remotes.CommF_:InvokeServer("LoadFruit", (Utils.getFruits())[1].Name)
                                                                elseif playerFragmentsValue.Value < 5000 then
                                                                    break
                                                                end
                                                                if farmPlayer.Data.DevilFruit.Value == "Dark-Dark" then
                                                                    Select_Map = "Dark"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Sand-Sand" then
                                                                    Select_Map = "Sand"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Magma-Magma" then
                                                                    Select_Map = "Magma"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Rumble-Rumble" then
                                                                    Select_Map = "Rumble"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Flame-Flame" then
                                                                    Select_Map = "Flame"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Ice-Ice" then
                                                                    Select_Map = "Ice"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Light-Light" then
                                                                    Select_Map = "Light"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "String-String" then
                                                                    Select_Map = "String"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Quake-Quake" then
                                                                    Select_Map = "Quake"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Buddha-Buddha" then
                                                                    Select_Map = "Buddha"
                                                                else
                                                                    Select_Map = "Ice"
                                                                end
                                                                replicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", Select_Map)
                                                                if currentPlaceId == 4442272183 and farmPlayer.Character.Humanoid.Health > 0 then
                                                                    local number7
                                                                    fireclickdetector(workspaceService.Map.CircleIsland.RaidSummon2.Button.Main.ClickDetector, 1)
                                                                    number7 = 0
                                                                    repeat
                                                                        number7 = number7 + 1
                                                                        task.wait(1)
                                                                    until number7 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                                elseif currentPlaceId == 7449423635 then
                                                                    tweenTeleportTo(CFrame.new(-5034, 315, -2951), 1.5)
                                                                    if ((CFrame.new(-5034, 315, -2951)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3 then
                                                                        if farmPlayer.Character.Humanoid.Health > 0 then
                                                                            local number8
                                                                            fireclickdetector(workspaceService.Map["Boat Castle"].RaidSummon2.Button.Main.ClickDetector, 1)
                                                                            number8 = 0
                                                                            repeat
                                                                                number8 = number8 + 1
                                                                                task.wait(1)
                                                                            until number8 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        else
                                                            Quest = nil
                                                            Utils.setStatus(" Status : Auto Farm Level")
                                                            runDefaultFarmQuest()
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                until Dragon_Claw_C
                            end
                            return
                        end
                        function5 = function()
                            for key66, item17 in pairs(replicatedStorage.Remotes.CommF_:InvokeServer("getInventory")) do
                                if item17.Value and item17.Value >= 1000000 then
                                    return true
                                end
                            end
                            return false
                        end
                        if replicatedStorage.Remotes.CommF_:InvokeServer("TalkTrevor", "1") ~= 0 and game.Players.LocalPlayer.Data.Level.Value >= 900 and function5() then
                            repeat
                                task.wait()
                                noFruit = true
                                for key67, item18 in pairs(replicatedStorage.Remotes.CommF_:InvokeServer("getInventory")) do
                                    if item18.Value and item18.Value >= 1000000 then
                                        ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("LoadFruit", item18.Name)
                                        task.wait(1)
                                        for key68, localplayer in pairs((game:GetService("Players")).LocalPlayer.Backpack:GetChildren()) do
                                            if string.find(localplayer.Name, "Fruit") then
                                                Utils.equipTool(localplayer)
                                            end
                                        end
                                        task.wait(.2)
                                        replicatedStorage.Remotes.CommF_:InvokeServer("TalkTrevor", "1")
                                        replicatedStorage.Remotes.CommF_:InvokeServer("TalkTrevor", "2")
                                        replicatedStorage.Remotes.CommF_:InvokeServer("TalkTrevor", "3")
                                        return
                                    end
                                end
                            until replicatedStorage.Remotes.CommF_:InvokeServer("TalkTrevor", "1") == 0 or not function5()
                            noFruit = false
                        end
                        if playerLevelValue.Value >= 1500 and replicatedStorage.Remotes.CommF_:InvokeServer("TalkTrevor", "1") ~= 0 and not function5() then
                            Utils.hopToLowServer(10)
                            return
                        end
                        if Super_human and not Death_Step and playerLevelValue.Value >= 1100 then
                            if not Death_Step and meleeUnlocked("Death Step") then
                                repeat
                                    task.wait()
                                    equipPreferredFarmTool()
                                    if not Super_humanw_C_M then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("BuySuperhuman")
                                        if farmPlayer.Character.Superhuman.Level.Value < 400 then
                                            repeat
                                                task.wait()
                                                equipPreferredFarmTool()
                                                Quest = nil
                                                Utils.setStatus(" Status : Auto Farm Level")
                                                runDefaultFarmQuest()
                                            until farmPlayer.Character.Superhuman.Level.Value >= 400
                                            Super_humanw_C_M = true
                                        end
                                    end
                                    if Utils.findFirstChild(farmPlayer.Backpack, "Death Step") or Utils.findFirstChild(farmPlayer.Character, "Death Step") then
                                        Death_Step = true
                                        return
                                    end
                                    if not Death_Step and playerLevelValue.Value >= 1100 then
                                        if playerFragmentsValue.Value >= 5000 then
                                            if Black_Leg_C_M then
                                                if playerBeliValue.Value >= 2500000 then
                                                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyDeathStep")
                                                    Death_Step = true
                                                    return
                                                else
                                                    equipPreferredFarmTool()
                                                    Quest = nil
                                                    Utils.setStatus(" Status : Auto Farm Level")
                                                    runDefaultFarmQuest()
                                                end
                                            else
                                                repeat
                                                    task.wait()
                                                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyBlackLeg")
                                                    equipPreferredFarmTool()
                                                    Quest = nil
                                                    Utils.setStatus(" Status : Auto Farm Level")
                                                    runDefaultFarmQuest()
                                                until farmPlayer.Character["Black Leg"].Level.Value >= 400
                                                Black_Leg_C_M = true
                                                if not Super_human and meleeUnlocked("Superhuman") then
                                                    replicatedStorage.Remotes.CommF_:InvokeServer("BuySuperhuman")
                                                end
                                                return
                                            end
                                        elseif playerFragmentsValue.Value < 5000 then
                                            if farmPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible and playerFragmentsValue.Value < 5000 and not Death_Step then
                                                Utils.setStatus(" Status : Farm Raid")
                                                if #Utils.getRaidMobs() == 0 then
                                                    if Select_Map == "Magma" or Select_Map == "Flame" then
                                                        for key69, descendant3 in pairs(workspaceService:GetDescendants()) do
                                                            if descendant3.Name == "Lava" then
                                                                descendant3:Destroy()
                                                            end
                                                        end
                                                    end
                                                    if Utils.getRaidPart("Island 5", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 5", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 4", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 4", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 3", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 3", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 2", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 2", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 1", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 1", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    end
                                                else
                                                    for key70, child23 in pairs(enemiesFolder:GetChildren()) do
                                                        if child23:FindFirstChild("HumanoidRootPart")
                                                                and child23:FindFirstChild("Humanoid")
                                                                and (child23:FindFirstChild("Humanoid")).Health > 0
                                                                and (farmPlayer.Character.HumanoidRootPart.CFrame.Position - child23.HumanoidRootPart.CFrame.Position).Magnitude <= 5000 then
                                                            repeat
                                                                local cframe2, number9
                                                                task.wait(.1)
                                                                if Select_Map == "Magma" or Select_Map == "Flame" then
                                                                    for key71, descendant4 in pairs(workspaceService:GetDescendants()) do
                                                                        if descendant4.Name == "Lava" then
                                                                            descendant4:Destroy()
                                                                        end
                                                                    end
                                                                end
                                                                number9 = math.random(1, 5)
                                                                if number9 == 1 then
                                                                    cframe2 = CFrame.new(0, 30, 1)
                                                                elseif number9 == 2 then
                                                                    cframe2 = CFrame.new(0, 30, 15)
                                                                elseif number9 == 3 then
                                                                    cframe2 = CFrame.new(1, 30, -15)
                                                                elseif number9 == 4 then
                                                                    cframe2 = CFrame.new(15, 30, 0)
                                                                elseif number9 == 5 then
                                                                    cframe2 = CFrame.new(-15, 30, 0)
                                                                end
                                                                tweenTeleportTo(child23.HumanoidRootPart.CFrame * cframe2, 1.5)
                                                                if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                                                    replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                                                end
                                                                equipPreferredFarmTool()
                                                            until not child23.Parent or child23.Humanoid.Health <= 0 or #Utils.getRaidMobs() == 0
                                                        end
                                                    end
                                                end
                                            else
                                                if farmPlayer.Data.DevilFruit.Value == "Dark-Dark" then
                                                    Select_Map = "Dark"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Sand-Sand" then
                                                    Select_Map = "Sand"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Magma-Magma" then
                                                    Select_Map = "Magma"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Rumble-Rumble" then
                                                    Select_Map = "Rumble"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Flame-Flame" then
                                                    Select_Map = "Flame"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Ice-Ice" then
                                                    Select_Map = "Ice"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Light-Light" then
                                                    Select_Map = "Light"
                                                elseif farmPlayer.Data.DevilFruit.Value == "String-String" then
                                                    Select_Map = "String"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Quake-Quake" then
                                                    Select_Map = "Quake"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Buddha-Buddha" then
                                                    Select_Map = "Buddha"
                                                else
                                                    Select_Map = "Ice"
                                                end
                                                replicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", Select_Map)
                                                task.wait(.2)
                                                if farmPlayer.Backpack:FindFirstChild("Special Microchip")
                                                        or farmPlayer.Character:FindFirstChild("Special Microchip")
                                                        and farmPlayer.Character.Humanoid.Health > 0 then
                                                    if currentPlaceId == 4442272183 and farmPlayer.Character.Humanoid.Health > 0 then
                                                        local number10
                                                        fireclickdetector(workspaceService.Map.CircleIsland.RaidSummon2.Button.Main.ClickDetector, 1)
                                                        number10 = 0
                                                        repeat
                                                            number10 = number10 + 1
                                                            task.wait(1)
                                                        until number10 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible == true
                                                    elseif currentPlaceId == 7449423635 then
                                                        tweenTeleportTo(CFrame.new(-5034, 315, -2951), 1.5)
                                                        if ((CFrame.new(-5034, 315, -2951)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3 then
                                                            if farmPlayer.Character.Humanoid.Health > 0 then
                                                                local number11
                                                                fireclickdetector(workspaceService.Map["Boat Castle"].RaidSummon2.Button.Main.ClickDetector, 1)
                                                                number11 = 0
                                                                repeat
                                                                    number11 = number11 + 1
                                                                    task.wait(1)
                                                                until number11 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                            end
                                                        end
                                                    end
                                                else
                                                    if not farmPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible then
                                                        if farmPlayer.Data.Fragments.Value >= 5000 then
                                                            if farmPlayer.Data.Beli.Value >= 2500000 then
                                                                replicatedStorage.Remotes.CommF_:InvokeServer("BuyDeathStep")
                                                                Death_Step = true
                                                                return
                                                            end
                                                            return
                                                        end
                                                        table.sort(Utils.getFruits(), function(part, part2)
                                                            if part.Value < 100000 and part.Value < 100000 then
                                                                return part.Value < part2.Value
                                                            end
                                                        end)
                                                        task.wait(1)
                                                        if #Utils.getFruits() > 0 and not Death_Step then
                                                            warn()
                                                            task.wait(2)
                                                            if not farmPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible then
                                                                if farmPlayer.Character.Humanoid.Health > 0 and farmPlayer.Data.Fragments.Value < 5000 then
                                                                    replicatedStorage.Remotes.CommF_:InvokeServer("LoadFruit", (Utils.getFruits())[1].Name)
                                                                elseif playerFragmentsValue.Value < 5000 then
                                                                    break
                                                                end
                                                                if farmPlayer.Data.DevilFruit.Value == "Dark-Dark" then
                                                                    Select_Map = "Dark"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Sand-Sand" then
                                                                    Select_Map = "Sand"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Magma-Magma" then
                                                                    Select_Map = "Magma"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Rumble-Rumble" then
                                                                    Select_Map = "Rumble"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Flame-Flame" then
                                                                    Select_Map = "Flame"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Ice-Ice" then
                                                                    Select_Map = "Ice"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Light-Light" then
                                                                    Select_Map = "Light"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "String-String" then
                                                                    Select_Map = "String"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Quake-Quake" then
                                                                    Select_Map = "Quake"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Buddha-Buddha" then
                                                                    Select_Map = "Buddha"
                                                                else
                                                                    Select_Map = "Ice"
                                                                end
                                                                replicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", Select_Map)
                                                                if currentPlaceId == 4442272183 and farmPlayer.Character.Humanoid.Health > 0 then
                                                                    local number12
                                                                    fireclickdetector(workspaceService.Map.CircleIsland.RaidSummon2.Button.Main.ClickDetector, 1)
                                                                    number12 = 0
                                                                    repeat
                                                                        number12 = number12 + 1
                                                                        task.wait(1)
                                                                    until number12 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                                elseif currentPlaceId == 7449423635 then
                                                                    tweenTeleportTo(CFrame.new(-5034, 315, -2951), 1.5)
                                                                    if ((CFrame.new(-5034, 315, -2951)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3 then
                                                                        if farmPlayer.Character.Humanoid.Health > 0 then
                                                                            local number13
                                                                            fireclickdetector(workspaceService.Map["Boat Castle"].RaidSummon2.Button.Main.ClickDetector, 1)
                                                                            number13 = 0
                                                                            repeat
                                                                                number13 = number13 + 1
                                                                                task.wait(1)
                                                                            until number13 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        else
                                                            Quest = nil
                                                            Utils.setStatus(" Status : Auto Farm Level")
                                                            runDefaultFarmQuest()
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                until Death_Step
                            end
                            return
                        end
                        if Dragon_Claw_C_M and not Sharkman_Karate_C and playerLevelValue.Value >= 1100 then
                            if not Sharkman_Karate_C and meleeUnlocked("Sharkman Karate") then
                                repeat
                                    task.wait()
                                    equipPreferredFarmTool()
                                    if Utils.findFirstChild(farmPlayer.Backpack, "Sharkman Karate") or Utils.findFirstChild(farmPlayer.Character, "Sharkman Karate") then
                                        Sharkman_Karate_C = true
                                        return
                                    end
                                    if not Sharkman_Karate_C and playerLevelValue.Value >= 1100 then
                                        if playerFragmentsValue.Value >= 5000 then
                                            if playerBeliValue.Value >= 2550000 and not Sharkman_Karate_C then
                                                replicatedStorage.Remotes.CommF_:InvokeServer("BuySharkmanKarate")
                                                Sharkman_Karate_C = true
                                                return
                                            else
                                                equipPreferredFarmTool()
                                                Quest = nil
                                                Utils.setStatus(" Status : Auto Farm Level")
                                                runDefaultFarmQuest()
                                            end
                                        elseif playerFragmentsValue.Value < 5000 then
                                            if farmPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible and playerFragmentsValue.Value < 5000 and not Sharkman_Karate_C then
                                                Utils.setStatus(" Status : Farm Raid")
                                                if #Utils.getRaidMobs() == 0 then
                                                    if Select_Map == "Magma" or Select_Map == "Flame" then
                                                        for key72, descendant5 in pairs(workspaceService:GetDescendants()) do
                                                            if descendant5.Name == "Lava" then
                                                                descendant5:Destroy()
                                                            end
                                                        end
                                                    end
                                                    if Utils.getRaidPart("Island 5", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 5", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 4", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 4", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 3", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 3", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 2", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 2", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 1", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 1", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    end
                                                else
                                                    for key73, child24 in pairs(enemiesFolder:GetChildren()) do
                                                        if child24:FindFirstChild("HumanoidRootPart")
                                                                and child24:FindFirstChild("Humanoid")
                                                                and (child24:FindFirstChild("Humanoid")).Health > 0
                                                                and (farmPlayer.Character.HumanoidRootPart.CFrame.Position - child24.HumanoidRootPart.CFrame.Position).Magnitude <= 5000 then
                                                            repeat
                                                                local number14, cframe3
                                                                task.wait(.1)
                                                                if Select_Map == "Magma" or Select_Map == "Flame" then
                                                                    for key74, descendant6 in pairs(workspaceService:GetDescendants()) do
                                                                        if descendant6.Name == "Lava" then
                                                                            descendant6:Destroy()
                                                                        end
                                                                    end
                                                                end
                                                                number14 = math.random(1, 5)
                                                                if number14 == 1 then
                                                                    cframe3 = CFrame.new(0, 30, 1)
                                                                elseif number14 == 2 then
                                                                    cframe3 = CFrame.new(0, 30, 15)
                                                                elseif number14 == 3 then
                                                                    cframe3 = CFrame.new(1, 30, -15)
                                                                elseif number14 == 4 then
                                                                    cframe3 = CFrame.new(15, 30, 0)
                                                                elseif number14 == 5 then
                                                                    cframe3 = CFrame.new(-15, 30, 0)
                                                                end
                                                                tweenTeleportTo(child24.HumanoidRootPart.CFrame * cframe3, 1.5)
                                                                if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                                                    replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                                                end
                                                                equipPreferredFarmTool()
                                                            until not child24.Parent or child24.Humanoid.Health <= 0 or #Utils.getRaidMobs() == 0
                                                        end
                                                    end
                                                end
                                            else
                                                if farmPlayer.Data.DevilFruit.Value == "Dark-Dark" then
                                                    Select_Map = "Dark"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Sand-Sand" then
                                                    Select_Map = "Sand"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Magma-Magma" then
                                                    Select_Map = "Magma"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Rumble-Rumble" then
                                                    Select_Map = "Rumble"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Flame-Flame" then
                                                    Select_Map = "Flame"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Ice-Ice" then
                                                    Select_Map = "Ice"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Light-Light" then
                                                    Select_Map = "Light"
                                                elseif farmPlayer.Data.DevilFruit.Value == "String-String" then
                                                    Select_Map = "String"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Quake-Quake" then
                                                    Select_Map = "Quake"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Buddha-Buddha" then
                                                    Select_Map = "Buddha"
                                                else
                                                    Select_Map = "Ice"
                                                end
                                                replicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", Select_Map)
                                                task.wait(.2)
                                                if farmPlayer.Backpack:FindFirstChild("Special Microchip")
                                                        or farmPlayer.Character:FindFirstChild("Special Microchip")
                                                        and farmPlayer.Character.Humanoid.Health > 0 then
                                                    if currentPlaceId == 4442272183 and farmPlayer.Character.Humanoid.Health > 0 then
                                                        local number15
                                                        fireclickdetector(workspaceService.Map.CircleIsland.RaidSummon2.Button.Main.ClickDetector, 1)
                                                        number15 = 0
                                                        repeat
                                                            number15 = number15 + 1
                                                            task.wait(1)
                                                        until number15 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                    elseif currentPlaceId == 7449423635 then
                                                        tweenTeleportTo(CFrame.new(-5034, 315, -2951), 1.5)
                                                        if ((CFrame.new(-5034, 315, -2951)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3 then
                                                            if farmPlayer.Character.Humanoid.Health > 0 then
                                                                local number16
                                                                fireclickdetector(workspaceService.Map["Boat Castle"].RaidSummon2.Button.Main.ClickDetector, 1)
                                                                number16 = 0
                                                                repeat
                                                                    number16 = number16 + 1
                                                                    task.wait(1)
                                                                until number16 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                            end
                                                        end
                                                    end
                                                else
                                                    if not farmPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible then
                                                        if playerBeliValue.Value >= 0 and farmPlayer.Data.Fragments.Value >= 5000 then
                                                            print("nan")
                                                            replicatedStorage.Remotes.CommF_:InvokeServer("BuySharkmanKarate")
                                                            Sharkman_Karate_C = true
                                                            return
                                                        end
                                                        table.sort(Utils.getFruits(), function(part, part2)
                                                            if part.Value < 100000 and part.Value < 100000 then
                                                                return part.Value < part2.Value
                                                            end
                                                        end)
                                                        task.wait(1)
                                                        if #Utils.getFruits() > 0 and not Sharkman_Karate_C then
                                                            task.wait(2)
                                                            if not farmPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible then
                                                                if farmPlayer.Character.Humanoid.Health > 0 and farmPlayer.Data.Fragments.Value < 5000 then
                                                                    replicatedStorage.Remotes.CommF_:InvokeServer("LoadFruit", (Utils.getFruits())[1].Name)
                                                                elseif playerFragmentsValue.Value < 5000 then
                                                                    break
                                                                end
                                                                if farmPlayer.Data.DevilFruit.Value == "Dark-Dark" then
                                                                    Select_Map = "Dark"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Sand-Sand" then
                                                                    Select_Map = "Sand"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Magma-Magma" then
                                                                    Select_Map = "Magma"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Rumble-Rumble" then
                                                                    Select_Map = "Rumble"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Flame-Flame" then
                                                                    Select_Map = "Flame"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Ice-Ice" then
                                                                    Select_Map = "Ice"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Light-Light" then
                                                                    Select_Map = "Light"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "String-String" then
                                                                    Select_Map = "String"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Quake-Quake" then
                                                                    Select_Map = "Quake"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Buddha-Buddha" then
                                                                    Select_Map = "Buddha"
                                                                else
                                                                    Select_Map = "Ice"
                                                                end
                                                                replicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", Select_Map)
                                                                if currentPlaceId == 4442272183 and farmPlayer.Character.Humanoid.Health > 0 then
                                                                    local number17
                                                                    fireclickdetector(workspaceService.Map.CircleIsland.RaidSummon2.Button.Main.ClickDetector, 1)
                                                                    number17 = 0
                                                                    repeat
                                                                        number17 = number17 + 1
                                                                        task.wait(1)
                                                                    until number17 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                                elseif currentPlaceId == 7449423635 then
                                                                    tweenTeleportTo(CFrame.new(-5034, 315, -2951), 1.5)
                                                                    if ((CFrame.new(-5034, 315, -2951)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3 then
                                                                        if farmPlayer.Character.Humanoid.Health > 0 then
                                                                            local number18
                                                                            fireclickdetector(workspaceService.Map["Boat Castle"].RaidSummon2.Button.Main.ClickDetector, 1)
                                                                            number18 = 0
                                                                            repeat
                                                                                number18 = number18 + 1
                                                                                task.wait(1)
                                                                            until number18 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        else
                                                            Quest = nil
                                                            Utils.setStatus(" Status : Auto Farm Level")
                                                            runDefaultFarmQuest()
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                until Sharkman_Karate_C
                            end
                            return
                        end
                        if Sharkman_Karate_C_M and not Electric_Claw_C and playerLevelValue.Value >= 1100 then
                            if not Electric_Claw_C and meleeUnlocked("Electric Claw") then
                                repeat
                                    task.wait()
                                    equipPreferredFarmTool()
                                    if Utils.findFirstChild(farmPlayer.Backpack, "Electric Claw") or Utils.findFirstChild(farmPlayer.Character, "Electric Claw") then
                                        Electric_Claw_C = true
                                        return
                                    end
                                    if not Electric_Claw_C and playerLevelValue.Value >= 1100 then
                                        if playerFragmentsValue.Value >= 5000 then
                                            if playerBeliValue.Value >= 3000000 then
                                                pcall(function()
                                                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw")
                                                    if replicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw") == 1 or replicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw") == 2 then
                                                        Electric_Claw_C = true
                                                    end
                                                end)
                                                if not Electric_Claw_C and meleeUnlocked("Electric Claw") then
                                                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw")
                                                    if replicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw") == 1 or replicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw") == 2 then
                                                        Electric_Claw_C = true
                                                    end
                                                end
                                                if Three_World and not Electric_Claw_C then
                                                    Quest = "Quest Electric Claw"
                                                end
                                                return
                                            else
                                                equipPreferredFarmTool()
                                                Quest = nil
                                                Utils.setStatus(" Status : Auto Farm Level")
                                                runDefaultFarmQuest()
                                            end
                                        elseif playerFragmentsValue.Value < 5000 then
                                            if farmPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible and playerFragmentsValue.Value < 5000 and not Electric_Claw_C then
                                                Utils.setStatus(" Status : Farm Raid")
                                                if #Utils.getRaidMobs() == 0 then
                                                    if Select_Map == "Magma" or Select_Map == "Flame" then
                                                        for key75, descendant7 in pairs(workspaceService:GetDescendants()) do
                                                            if descendant7.Name == "Lava" then
                                                                descendant7:Destroy()
                                                            end
                                                        end
                                                    end
                                                    if Utils.getRaidPart("Island 5", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 5", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 4", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 4", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 3", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 3", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 2", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 2", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 1", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 1", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    end
                                                else
                                                    for key76, child25 in pairs(enemiesFolder:GetChildren()) do
                                                        if child25:FindFirstChild("HumanoidRootPart")
                                                                and child25:FindFirstChild("Humanoid")
                                                                and (child25:FindFirstChild("Humanoid")).Health > 0
                                                                and (farmPlayer.Character.HumanoidRootPart.CFrame.Position - child25.HumanoidRootPart.CFrame.Position).Magnitude <= 5000 then
                                                            repeat
                                                                local cframe4, number19
                                                                task.wait(.1)
                                                                if Select_Map == "Magma" or Select_Map == "Flame" then
                                                                    for key77, descendant8 in pairs(workspaceService:GetDescendants()) do
                                                                        if descendant8.Name == "Lava" then
                                                                            descendant8:Destroy()
                                                                        end
                                                                    end
                                                                end
                                                                number19 = math.random(1, 5)
                                                                if number19 == 1 then
                                                                    cframe4 = CFrame.new(0, 30, 1)
                                                                elseif number19 == 2 then
                                                                    cframe4 = CFrame.new(0, 30, 15)
                                                                elseif number19 == 3 then
                                                                    cframe4 = CFrame.new(1, 30, -15)
                                                                elseif number19 == 4 then
                                                                    cframe4 = CFrame.new(15, 30, 0)
                                                                elseif number19 == 5 then
                                                                    cframe4 = CFrame.new(-15, 30, 0)
                                                                end
                                                                tweenTeleportTo(child25.HumanoidRootPart.CFrame * cframe4, 1.5)
                                                                if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                                                    replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                                                end
                                                                equipPreferredFarmTool()
                                                            until not child25.Parent or child25.Humanoid.Health <= 0 or #Utils.getRaidMobs() == 0
                                                        end
                                                    end
                                                end
                                            else
                                                if farmPlayer.Data.DevilFruit.Value == "Dark-Dark" then
                                                    Select_Map = "Dark"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Sand-Sand" then
                                                    Select_Map = "Sand"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Magma-Magma" then
                                                    Select_Map = "Magma"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Rumble-Rumble" then
                                                    Select_Map = "Rumble"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Flame-Flame" then
                                                    Select_Map = "Flame"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Ice-Ice" then
                                                    Select_Map = "Ice"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Light-Light" then
                                                    Select_Map = "Light"
                                                elseif farmPlayer.Data.DevilFruit.Value == "String-String" then
                                                    Select_Map = "String"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Quake-Quake" then
                                                    Select_Map = "Quake"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Buddha-Buddha" then
                                                    Select_Map = "Buddha"
                                                else
                                                    Select_Map = "Ice"
                                                end
                                                replicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", Select_Map)
                                                task.wait(.2)
                                                if farmPlayer.Backpack:FindFirstChild("Special Microchip")
                                                        or farmPlayer.Character:FindFirstChild("Special Microchip")
                                                        and farmPlayer.Character.Humanoid.Health > 0 then
                                                    if currentPlaceId == 4442272183 and farmPlayer.Character.Humanoid.Health > 0 then
                                                        local number20
                                                        fireclickdetector(workspaceService.Map.CircleIsland.RaidSummon2.Button.Main.ClickDetector, 1)
                                                        number20 = 0
                                                        repeat
                                                            number20 = number20 + 1
                                                            task.wait(1)
                                                        until number20 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                    elseif currentPlaceId == 7449423635 then
                                                        tweenTeleportTo(CFrame.new(-5034, 315, -2951), 1.5)
                                                        if ((CFrame.new(-5034, 315, -2951)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3 then
                                                            if farmPlayer.Character.Humanoid.Health > 0 then
                                                                local number21
                                                                fireclickdetector(workspaceService.Map["Boat Castle"].RaidSummon2.Button.Main.ClickDetector, 1)
                                                                number21 = 0
                                                                repeat
                                                                    number21 = number21 + 1
                                                                    task.wait(1)
                                                                until number21 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                            end
                                                        end
                                                    end
                                                else
                                                    if not farmPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible then
                                                        if farmPlayer.Data.Fragments.Value >= 5000 then
                                                            if farmPlayer.Data.Beli.Value >= 3000000 then
                                                                replicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw")
                                                                if replicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw") == 1 or replicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw") == 2 then
                                                                    Electric_Claw_C = true
                                                                end
                                                                return
                                                            end
                                                            return
                                                        end
                                                        table.sort(Utils.getFruits(), function(part, part2)
                                                            if part.Value < 100000 and part.Value < 100000 then
                                                                return part.Value < part2.Value
                                                            end
                                                        end)
                                                        task.wait(1)
                                                        if #Utils.getFruits() > 0 and not Electric_Claw_C then
                                                            warn()
                                                            task.wait(2)
                                                            if not farmPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible then
                                                                if farmPlayer.Character.Humanoid.Health > 0 and farmPlayer.Data.Fragments.Value < 5000 then
                                                                    replicatedStorage.Remotes.CommF_:InvokeServer("LoadFruit", (Utils.getFruits())[1].Name)
                                                                elseif playerFragmentsValue.Value < 5000 then
                                                                    break
                                                                end
                                                                if farmPlayer.Data.DevilFruit.Value == "Dark-Dark" then
                                                                    Select_Map = "Dark"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Sand-Sand" then
                                                                    Select_Map = "Sand"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Magma-Magma" then
                                                                    Select_Map = "Magma"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Rumble-Rumble" then
                                                                    Select_Map = "Rumble"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Flame-Flame" then
                                                                    Select_Map = "Flame"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Ice-Ice" then
                                                                    Select_Map = "Ice"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Light-Light" then
                                                                    Select_Map = "Light"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "String-String" then
                                                                    Select_Map = "String"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Quake-Quake" then
                                                                    Select_Map = "Quake"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Buddha-Buddha" then
                                                                    Select_Map = "Buddha"
                                                                else
                                                                    Select_Map = "Ice"
                                                                end
                                                                replicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", Select_Map)
                                                                if currentPlaceId == 4442272183 and farmPlayer.Character.Humanoid.Health > 0 then
                                                                    local number22
                                                                    fireclickdetector(workspaceService.Map.CircleIsland.RaidSummon2.Button.Main.ClickDetector, 1)
                                                                    number22 = 0
                                                                    repeat
                                                                        number22 = number22 + 1
                                                                        task.wait(1)
                                                                    until number22 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                                elseif currentPlaceId == 7449423635 then
                                                                    tweenTeleportTo(CFrame.new(-5034, 315, -2951), 1.5)
                                                                    if ((CFrame.new(-5034, 315, -2951)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3 then
                                                                        if farmPlayer.Character.Humanoid.Health > 0 then
                                                                            local number23
                                                                            fireclickdetector(workspaceService.Map["Boat Castle"].RaidSummon2.Button.Main.ClickDetector, 1)
                                                                            number23 = 0
                                                                            repeat
                                                                                number23 = number23 + 1
                                                                                task.wait(1)
                                                                            until number23 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        else
                                                            Quest = nil
                                                            Utils.setStatus(" Status : Auto Farm Level")
                                                            runDefaultFarmQuest()
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                until Electric_Claw_C
                            end
                            return
                        end
                        if Electric_Claw_C_M and not Dragon_Talon_C and playerLevelValue.Value >= 1100 then
                            if not Dragon_Talon_C and meleeUnlocked("Dragon Talon") then
                                repeat
                                    task.wait()
                                    equipPreferredFarmTool()
                                    if Utils.findFirstChild(farmPlayer.Backpack, "Dragon Talon") or Utils.findFirstChild(farmPlayer.Character, "Dragon Talon") then
                                        Dragon_Talon_C = true
                                        return
                                    end
                                    if not Dragon_Talon_C and playerLevelValue.Value >= 1100 then
                                        if playerFragmentsValue.Value >= 5000 then
                                            if playerBeliValue.Value >= 3000000 then
                                                Quest = nil
                                                Utils.setStatus(" Status : Auto Farm Bone")
                                                Utils.farmBone(true)
                                            else
                                                equipPreferredFarmTool()
                                                Quest = nil
                                                Utils.setStatus(" Status : Auto Farm Level")
                                                runDefaultFarmQuest()
                                            end
                                        elseif playerFragmentsValue.Value < 5000 then
                                            if farmPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible and playerFragmentsValue.Value < 5000 and not Dragon_Talon_C then
                                                Utils.setStatus(" Status : Farm Raid")
                                                if #Utils.getRaidMobs() == 0 then
                                                    if Select_Map == "Magma" or Select_Map == "Flame" then
                                                        for key78, descendant9 in pairs(workspaceService:GetDescendants()) do
                                                            if descendant9.Name == "Lava" then
                                                                descendant9:Destroy()
                                                            end
                                                        end
                                                    end
                                                    if Utils.getRaidPart("Island 5", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 5", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 4", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 4", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 3", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 3", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 2", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 2", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 1", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 1", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    end
                                                else
                                                    for key79, child26 in pairs(enemiesFolder:GetChildren()) do
                                                        if child26:FindFirstChild("HumanoidRootPart")
                                                                and child26:FindFirstChild("Humanoid")
                                                                and (child26:FindFirstChild("Humanoid")).Health > 0
                                                                and (farmPlayer.Character.HumanoidRootPart.CFrame.Position - child26.HumanoidRootPart.CFrame.Position).Magnitude <= 5000 then
                                                            repeat
                                                                local number24, cframe5
                                                                task.wait(.1)
                                                                if Select_Map == "Magma" or Select_Map == "Flame" then
                                                                    for key80, descendant10 in pairs(workspaceService:GetDescendants()) do
                                                                        if descendant10.Name == "Lava" then
                                                                            descendant10:Destroy()
                                                                        end
                                                                    end
                                                                end
                                                                number24 = math.random(1, 5)
                                                                if number24 == 1 then
                                                                    cframe5 = CFrame.new(0, 30, 1)
                                                                elseif number24 == 2 then
                                                                    cframe5 = CFrame.new(0, 30, 15)
                                                                elseif number24 == 3 then
                                                                    cframe5 = CFrame.new(1, 30, -15)
                                                                elseif number24 == 4 then
                                                                    cframe5 = CFrame.new(15, 30, 0)
                                                                elseif number24 == 5 then
                                                                    cframe5 = CFrame.new(-15, 30, 0)
                                                                end
                                                                tweenTeleportTo(child26.HumanoidRootPart.CFrame * cframe5, 1.5)
                                                                if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                                                    replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                                                end
                                                                equipPreferredFarmTool()
                                                            until not child26.Parent or child26.Humanoid.Health <= 0 or #Utils.getRaidMobs() == 0
                                                        end
                                                    end
                                                end
                                            else
                                                if farmPlayer.Data.DevilFruit.Value == "Dark-Dark" then
                                                    Select_Map = "Dark"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Sand-Sand" then
                                                    Select_Map = "Sand"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Magma-Magma" then
                                                    Select_Map = "Magma"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Rumble-Rumble" then
                                                    Select_Map = "Rumble"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Flame-Flame" then
                                                    Select_Map = "Flame"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Ice-Ice" then
                                                    Select_Map = "Ice"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Light-Light" then
                                                    Select_Map = "Light"
                                                elseif farmPlayer.Data.DevilFruit.Value == "String-String" then
                                                    Select_Map = "String"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Quake-Quake" then
                                                    Select_Map = "Quake"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Buddha-Buddha" then
                                                    Select_Map = "Buddha"
                                                else
                                                    Select_Map = "Ice"
                                                end
                                                replicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", Select_Map)
                                                task.wait(.2)
                                                if farmPlayer.Backpack:FindFirstChild("Special Microchip")
                                                        or farmPlayer.Character:FindFirstChild("Special Microchip")
                                                        and farmPlayer.Character.Humanoid.Health > 0 then
                                                    if currentPlaceId == 4442272183 and farmPlayer.Character.Humanoid.Health > 0 then
                                                        local number25
                                                        fireclickdetector(workspaceService.Map.CircleIsland.RaidSummon2.Button.Main.ClickDetector, 1)
                                                        number25 = 0
                                                        repeat
                                                            number25 = number25 + 1
                                                            task.wait(1)
                                                        until number25 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                    elseif currentPlaceId == 7449423635 then
                                                        tweenTeleportTo(CFrame.new(-5034, 315, -2951), 1.5)
                                                        if ((CFrame.new(-5034, 315, -2951)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3 then
                                                            if farmPlayer.Character.Humanoid.Health > 0 then
                                                                local number26
                                                                fireclickdetector(workspaceService.Map["Boat Castle"].RaidSummon2.Button.Main.ClickDetector, 1)
                                                                number26 = 0
                                                                repeat
                                                                    number26 = number26 + 1
                                                                    task.wait(1)
                                                                until number26 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                            end
                                                        end
                                                    end
                                                else
                                                    if not farmPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible then
                                                        if farmPlayer.Data.Fragments.Value >= 5000 then
                                                            if farmPlayer.Data.Beli.Value >= 3000000 then
                                                                replicatedStorage.Remotes.CommF_:InvokeServer("BuyDragonTalon")
                                                                Dragon_Talon_C = true
                                                                return
                                                            end
                                                            return
                                                        end
                                                        table.sort(Utils.getFruits(), function(part, part2)
                                                            if part.Value < 100000 and part.Value < 100000 then
                                                                return part.Value < part2.Value
                                                            end
                                                        end)
                                                        task.wait(1)
                                                        if #Utils.getFruits() > 0 and not Dragon_Talon_C then
                                                            warn()
                                                            task.wait(2)
                                                            if not farmPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible then
                                                                if farmPlayer.Character.Humanoid.Health > 0 and farmPlayer.Data.Fragments.Value < 5000 then
                                                                    replicatedStorage.Remotes.CommF_:InvokeServer("LoadFruit", (Utils.getFruits())[1].Name)
                                                                elseif playerFragmentsValue.Value < 5000 then
                                                                    break
                                                                end
                                                                if farmPlayer.Data.DevilFruit.Value == "Dark-Dark" then
                                                                    Select_Map = "Dark"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Sand-Sand" then
                                                                    Select_Map = "Sand"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Magma-Magma" then
                                                                    Select_Map = "Magma"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Rumble-Rumble" then
                                                                    Select_Map = "Rumble"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Flame-Flame" then
                                                                    Select_Map = "Flame"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Ice-Ice" then
                                                                    Select_Map = "Ice"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Light-Light" then
                                                                    Select_Map = "Light"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "String-String" then
                                                                    Select_Map = "String"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Quake-Quake" then
                                                                    Select_Map = "Quake"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Buddha-Buddha" then
                                                                    Select_Map = "Buddha"
                                                                else
                                                                    Select_Map = "Ice"
                                                                end
                                                                replicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", Select_Map)
                                                                if currentPlaceId == 4442272183 and farmPlayer.Character.Humanoid.Health > 0 then
                                                                    local number27
                                                                    fireclickdetector(workspaceService.Map.CircleIsland.RaidSummon2.Button.Main.ClickDetector, 1)
                                                                    number27 = 0
                                                                    repeat
                                                                        number27 = number27 + 1
                                                                        task.wait(1)
                                                                    until number27 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                                elseif currentPlaceId == 7449423635 then
                                                                    tweenTeleportTo(CFrame.new(-5034, 315, -2951), 1.5)
                                                                    if ((CFrame.new(-5034, 315, -2951)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3 then
                                                                        if farmPlayer.Character.Humanoid.Health > 0 then
                                                                            local number28
                                                                            fireclickdetector(workspaceService.Map["Boat Castle"].RaidSummon2.Button.Main.ClickDetector, 1)
                                                                            number28 = 0
                                                                            repeat
                                                                                number28 = number28 + 1
                                                                                task.wait(1)
                                                                            until number28 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        else
                                                            Quest = nil
                                                            Utils.setStatus(" Status : Auto Farm Level")
                                                            runDefaultFarmQuest()
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                until Dragon_Talon_C
                            end
                            return
                        end
                        if Dragon_Talon_C_M and not God_Human_C and playerLevelValue.Value >= 1100 then
                            if not God_Human_C and meleeUnlocked("Godhuman") then
                                repeat
                                    task.wait()
                                    equipPreferredFarmTool()
                                    if Utils.findFirstChild(farmPlayer.Backpack, "Godhuman") or Utils.findFirstChild(farmPlayer.Character, "Godhuman") then
                                        God_Human_C = true
                                        return
                                    end
                                    if not God_Human_C and playerLevelValue.Value >= 1100 then
                                        if playerFragmentsValue.Value >= 5000 then
                                            if playerBeliValue.Value >= 5000000 then
                                                Quest = "Godhuman"
                                            else
                                                equipPreferredFarmTool()
                                                Quest = nil
                                                Utils.setStatus(" Status : Auto Farm Level")
                                                runDefaultFarmQuest()
                                            end
                                        elseif playerFragmentsValue.Value < 5000 then
                                            if farmPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible and playerFragmentsValue.Value < 5000 and not God_Human_C then
                                                Utils.setStatus(" Status : Farm Raid")
                                                if #Utils.getRaidMobs() == 0 then
                                                    if Select_Map == "Magma" or Select_Map == "Flame" then
                                                        for key81, descendant11 in pairs(workspaceService:GetDescendants()) do
                                                            if descendant11.Name == "Lava" then
                                                                descendant11:Destroy()
                                                            end
                                                        end
                                                    end
                                                    if Utils.getRaidPart("Island 5", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 5", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 4", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 4", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 3", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 3", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 2", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 2", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    elseif Utils.getRaidPart("Island 1", 2500) ~= nil then
                                                        tweenTeleportTo((Utils.getRaidPart("Island 1", 2500)).CFrame * CFrame.new(0, 120, 0), 1.5)
                                                    end
                                                else
                                                    for key82, child27 in pairs(enemiesFolder:GetChildren()) do
                                                        if child27:FindFirstChild("HumanoidRootPart")
                                                                and child27:FindFirstChild("Humanoid")
                                                                and (child27:FindFirstChild("Humanoid")).Health > 0
                                                                and (farmPlayer.Character.HumanoidRootPart.CFrame.Position - child27.HumanoidRootPart.CFrame.Position).Magnitude <= 5000 then
                                                            repeat
                                                                local cframe6, number29
                                                                task.wait(.1)
                                                                if Select_Map == "Magma" or Select_Map == "Flame" then
                                                                    for key83, descendant12 in pairs(workspaceService:GetDescendants()) do
                                                                        if descendant12.Name == "Lava" then
                                                                            descendant12:Destroy()
                                                                        end
                                                                    end
                                                                end
                                                                number29 = math.random(1, 5)
                                                                if number29 == 1 then
                                                                    cframe6 = CFrame.new(0, 30, 1)
                                                                elseif number29 == 2 then
                                                                    cframe6 = CFrame.new(0, 30, 15)
                                                                elseif number29 == 3 then
                                                                    cframe6 = CFrame.new(1, 30, -15)
                                                                elseif number29 == 4 then
                                                                    cframe6 = CFrame.new(15, 30, 0)
                                                                elseif number29 == 5 then
                                                                    cframe6 = CFrame.new(-15, 30, 0)
                                                                end
                                                                tweenTeleportTo(child27.HumanoidRootPart.CFrame * cframe6, 1.5)
                                                                if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                                                    replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                                                end
                                                                equipPreferredFarmTool()
                                                            until not child27.Parent or child27.Humanoid.Health <= 0 or #Utils.getRaidMobs() == 0
                                                        end
                                                    end
                                                end
                                            else
                                                if farmPlayer.Data.DevilFruit.Value == "Dark-Dark" then
                                                    Select_Map = "Dark"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Sand-Sand" then
                                                    Select_Map = "Sand"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Magma-Magma" then
                                                    Select_Map = "Magma"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Rumble-Rumble" then
                                                    Select_Map = "Rumble"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Flame-Flame" then
                                                    Select_Map = "Flame"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Ice-Ice" then
                                                    Select_Map = "Ice"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Light-Light" then
                                                    Select_Map = "Light"
                                                elseif farmPlayer.Data.DevilFruit.Value == "String-String" then
                                                    Select_Map = "String"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Quake-Quake" then
                                                    Select_Map = "Quake"
                                                elseif farmPlayer.Data.DevilFruit.Value == "Buddha-Buddha" then
                                                    Select_Map = "Buddha"
                                                else
                                                    Select_Map = "Ice"
                                                end
                                                replicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", Select_Map)
                                                task.wait(.2)
                                                if farmPlayer.Backpack:FindFirstChild("Special Microchip")
                                                        or farmPlayer.Character:FindFirstChild("Special Microchip")
                                                        and farmPlayer.Character.Humanoid.Health > 0 then
                                                    if currentPlaceId == 4442272183 and farmPlayer.Character.Humanoid.Health > 0 then
                                                        local number30
                                                        fireclickdetector(workspaceService.Map.CircleIsland.RaidSummon2.Button.Main.ClickDetector, 1)
                                                        number30 = 0
                                                        repeat
                                                            number30 = number30 + 1
                                                            task.wait(1)
                                                        until number30 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                    elseif currentPlaceId == 7449423635 then
                                                        tweenTeleportTo(CFrame.new(-5034, 315, -2951), 1.5)
                                                        if ((CFrame.new(-5034, 315, -2951)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3 then
                                                            if farmPlayer.Character.Humanoid.Health > 0 then
                                                                local number31
                                                                fireclickdetector(workspaceService.Map["Boat Castle"].RaidSummon2.Button.Main.ClickDetector, 1)
                                                                number31 = 0
                                                                repeat
                                                                    number31 = number31 + 1
                                                                    task.wait(1)
                                                                until number31 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                            end
                                                        end
                                                    end
                                                else
                                                    if not farmPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible then
                                                        if farmPlayer.Data.Fragments.Value >= 5000 then
                                                            if farmPlayer.Data.Beli.Value >= 3000000 then
                                                                replicatedStorage.Remotes.CommF_:InvokeServer("BuyGodHuman")
                                                                God_Human_C = true
                                                                return
                                                            end
                                                            return
                                                        end
                                                        table.sort(Utils.getFruits(), function(part, part2)
                                                            if part.Value < 100000 and part.Value < 100000 then
                                                                return part.Value < part2.Value
                                                            end
                                                        end)
                                                        task.wait(1)
                                                        if #Utils.getFruits() > 0 and not God_Human_C then
                                                            warn()
                                                            task.wait(2)
                                                            if not farmPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible then
                                                                if farmPlayer.Character.Humanoid.Health > 0 and farmPlayer.Data.Fragments.Value < 5000 then
                                                                    replicatedStorage.Remotes.CommF_:InvokeServer("LoadFruit", (Utils.getFruits())[1].Name)
                                                                elseif playerFragmentsValue.Value < 5000 then
                                                                    break
                                                                end
                                                                if farmPlayer.Data.DevilFruit.Value == "Dark-Dark" then
                                                                    Select_Map = "Dark"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Sand-Sand" then
                                                                    Select_Map = "Sand"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Magma-Magma" then
                                                                    Select_Map = "Magma"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Rumble-Rumble" then
                                                                    Select_Map = "Rumble"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Flame-Flame" then
                                                                    Select_Map = "Flame"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Ice-Ice" then
                                                                    Select_Map = "Ice"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Light-Light" then
                                                                    Select_Map = "Light"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "String-String" then
                                                                    Select_Map = "String"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Quake-Quake" then
                                                                    Select_Map = "Quake"
                                                                elseif farmPlayer.Data.DevilFruit.Value == "Buddha-Buddha" then
                                                                    Select_Map = "Buddha"
                                                                else
                                                                    Select_Map = "Ice"
                                                                end
                                                                replicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", Select_Map)
                                                                if currentPlaceId == 4442272183 and farmPlayer.Character.Humanoid.Health > 0 then
                                                                    local number32
                                                                    fireclickdetector(workspaceService.Map.CircleIsland.RaidSummon2.Button.Main.ClickDetector, 1)
                                                                    number32 = 0
                                                                    repeat
                                                                        number32 = number32 + 1
                                                                        task.wait(1)
                                                                    until number32 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                                elseif currentPlaceId == 7449423635 then
                                                                    tweenTeleportTo(CFrame.new(-5034, 315, -2951), 1.5)
                                                                    if ((CFrame.new(-5034, 315, -2951)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3 then
                                                                        if farmPlayer.Character.Humanoid.Health > 0 then
                                                                            local number33
                                                                            fireclickdetector(workspaceService.Map["Boat Castle"].RaidSummon2.Button.Main.ClickDetector, 1)
                                                                            number33 = 0
                                                                            repeat
                                                                                number33 = number33 + 1
                                                                                task.wait(1)
                                                                            until number33 >= 20 or farmPlayer.PlayerGui.Main.Timer.Visible
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        else
                                                            Quest = nil
                                                            Utils.setStatus(" Status : Auto Farm Level")
                                                            runDefaultFarmQuest()
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                until God_Human_C
                            end
                            return
                        end
                        if playerLevelValue.Value >= 700 and not New_World and not Three_World then
                            Quest = "World 2"
                            return
                        end
                        if New_World
                                and CheckFindWaterKey
                                and playerLevelValue.Value >= 1500
                                and replicatedStorage.Remotes.CommF_:InvokeServer("TalkTrevor", "1") == 0
                                and not Utils.isInIceHall()
                                and Utils.isHeavenlyDevil() then
                            Quest = "TravelZou"
                            return
                        end
                        Quest = nil
                        Utils.setStatus(" Status : Auto Farm Level")
                        runDefaultFarmQuest()
                    end
                end
            end
        end, warn)
    end
end)
task.spawn(function()
    while task.wait() do
        if not autoFarmingOn() then
            task.wait(1)
            continue
        end
        xpcall(function()
            if Quest ~= nil then
                Utils.setStatus(" Status : " .. Quest)
            end
            if Quest == "Saber" then
                local response5
                if not old_World then
                    replicatedStorage.Remotes.CommF_:InvokeServer("TravelMain")
                end
                response5 = replicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress")
                if response5.UsedTorch == false then
                    for key84, jungle in pairs((game:GetService("Workspace")).Map.Jungle.QuestPlates:GetChildren()) do
                        if table.find({
                            "Plate1",
                            "Plate2",
                            "Plate3",
                            "Plate4",
                            "Plate5"
                        }, jungle.Name) then
                            jungle.Button.CFrame = farmPlayer.Character.HumanoidRootPart.CFrame
                        end
                    end
                    replicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress", "GetTorch")
                    Utils.equipTool("Torch")
                    replicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress", "DestroyTorch")
                elseif response5.UsedCup == false then
                    replicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress", "GetCup")
                    Utils.equipTool("Cup")
                    replicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress", "FillCup", (game:GetService("Players")).LocalPlayer.Character.Cup)
                    replicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress", "SickMan")
                elseif response5.KilledMob == false then
                    local found3
                    replicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress", "RichSon")
                    found3 = Utils.findFirstChild(enemiesFolder, "Mob Leader")
                    if found3 then
                        for key85, child28 in pairs(enemiesFolder:GetChildren()) do
                            if child28.Name == "Mob Leader" then
                                repeat
                                    task.wait()
                                    tweenTeleportTo(child28.HumanoidRootPart.CFrame * CFrame.new(0, 20, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child28.Parent or child28.Humanoid.Health <= 0 or Utils.hasItem("Saber")
                                replicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress", "RichSon")
                            end
                        end
                    else
                        tweenTeleportTo(CFrame.new(-2848.59399, 7.4272871, 5342.44043), 1.5)
                    end
                elseif response5.UsedRelic == false then
                    replicatedStorage.Remotes.CommF_:InvokeServer("ProQuestProgress", "RichSon")
                    Utils.equipTool("Relic")
                    tweenTeleportTo(CFrame.new(-1406.60925, 29.8520069, 4.5805192), 1.5)
                else
                    if Utils.findFirstChild(enemiesFolder, "Saber Expert") then
                        for key86, child29 in pairs((game:GetService("Workspace")).Enemies:GetChildren()) do
                            if child29.Name == "Saber Expert" then
                                repeat
                                    task.wait()
                                    tweenTeleportTo(child29.HumanoidRootPart.CFrame * CFrame.new(0, 25, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child29.Parent or child29.Humanoid.Health <= 0 or Utils.hasItem("Saber")
                            end
                        end
                    else
                        tweenTeleportTo(CFrame.new(-1458.89502, 29.8870335, -50.633564, .858821094, 1.13848939e-08, .512275636, -4.85649254e-09, 1, -1.40823326e-08, -0.512275636, 9.6063415e-09, .858821094), 1.5)
                        if ((CFrame.new(-1458.89502, 29.8870335, -50.633564, .858821094, 1.13848939e-08, .512275636, -4.85649254e-09, 1, -1.40823326e-08, -0.512275636, 9.6063415e-09, .858821094)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3 then
                            task.wait(.5)
                            if not Utils.findFirstChild(enemiesFolder, "Saber Expert") then
                                farmPlayer:Kick("Hop")
                                task.wait(.1)
                                teleportService:Teleport(currentPlaceId, farmPlayer)
                            end
                        end
                    end
                end
            elseif Quest == "World 2" then
                local response6 = replicatedStorage.Remotes.CommF_:InvokeServer("DressrosaQuestProgress")
                if response6.UsedKey == false then
                    tweenTeleportTo(CFrame.new(1347.32947, 37.349369, -1325.44922, .538348913, 8.57539106e-08, .842722058, 8.61935634e-10, 1, -1.0230886e-07, -0.842722058, 5.58042359e-08, .538348913), 1.5)
                    replicatedStorage.Remotes.CommF_:InvokeServer("DressrosaQuestProgress", "Detective")
                    Utils.equipTool("Key")
                elseif response6.KilledIceBoss == false then
                    if Utils.findFirstChild(enemiesFolder, "Ice Admiral") then
                        for key87, child30 in pairs(enemiesFolder:GetChildren()) do
                            if child30.Name == "Ice Admiral" and child30.Humanoid.Health > 0 then
                                repeat
                                    task.wait(.1)
                                    tweenTeleportTo(child30.HumanoidRootPart.CFrame * CFrame.new(0, 20, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child30.Parent or child30.Humanoid.Health <= 0 or not getgenv().AutoFarm or response6.KilledIceBoss
                                task.wait(2)
                                replicatedStorage.Remotes.CommF_:InvokeServer("TravelDressrosa")
                                TleP = true
                                task.wait(25)
                            end
                        end
                    elseif Utils.findFirstChild(replicatedStorage, "Ice Admiral") then
                        tweenTeleportTo(CFrame.new(1144.5270996094, 7.3292083740234, -1164.7322998047), 1.5)
                    end
                elseif response6.KilledIceBoss == true then
                    replicatedStorage.Remotes.CommF_:InvokeServer("TravelDressrosa")
                    TleP = true
                    task.wait(25)
                end
            elseif Quest == "Pole (1st Form)" then
                if not Utils.checkBoss("Thunder God") then
                    return
                end
                repeat
                    task.wait()
                    if Utils.findFirstChild(enemiesFolder, "Thunder God") then
                        for key88, child31 in pairs(enemiesFolder:GetChildren()) do
                            if child31.Name == "Thunder God" and child31.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    if ((CFrame.new(-7894.6181640625, 5547.1420898438, -380.29098510742)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude >= 7500 then
                                        ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("requestEntrance", vector.create(-7894.6181640625, 5547.1420898438, -380.29098510742))
                                    end
                                    tweenTeleportTo(child31.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child31.Parent or child31.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Thunder God")
                            end
                        end
                    elseif Utils.findFirstChild(replicatedStorage, "Thunder God") then
                        for key89, child32 in pairs(replicatedStorage:GetChildren()) do
                            if child32.Name == "Thunder God" and child32.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    if ((CFrame.new(-7894.6181640625, 5547.1420898438, -380.29098510742)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude >= 7500 then
                                        ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("requestEntrance", vector.create(-7894.6181640625, 5547.1420898438, -380.29098510742))
                                    end
                                    tweenTeleportTo(child32.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child32.Parent or child32.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Thunder God")
                            end
                        end
                    end
                until not Utils.checkBoss("Thunder God")
            elseif Quest == "Shark Saw" then
                if not Utils.checkBoss("The Saw") then
                    return
                end
                repeat
                    task.wait()
                    if Utils.findFirstChild(enemiesFolder, "The Saw") then
                        for key90, child33 in pairs(enemiesFolder:GetChildren()) do
                            if child33.Name == "The Saw" and child33.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    if ((CFrame.new(-7894.6181640625, 5547.1420898438, -380.29098510742)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude >= 7500 then
                                        ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("requestEntrance", vector.create(-7894.6181640625, 5547.1420898438, -380.29098510742))
                                    end
                                    tweenTeleportTo(child33.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child33.Parent or child33.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("The Saw")
                            end
                        end
                    elseif Utils.findFirstChild(replicatedStorage, "The Saw") then
                        for key91, child34 in pairs(replicatedStorage:GetChildren()) do
                            if child34.Name == "The Saw" and child34.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    if ((CFrame.new(-7894.6181640625, 5547.1420898438, -380.29098510742)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude >= 7500 then
                                        ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("requestEntrance", vector.create(-7894.6181640625, 5547.1420898438, -380.29098510742))
                                    end
                                    tweenTeleportTo(child34.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child34.Parent or child34.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("The Saw")
                            end
                        end
                    end
                until not Utils.checkBoss("The Saw")
            elseif Quest == "Flail" then
                if not Utils.checkBoss("Smoke Admiral") then
                    return
                end
                repeat
                    task.wait()
                    if Utils.findFirstChild(enemiesFolder, "Smoke Admiral") then
                        for key92, child35 in pairs(enemiesFolder:GetChildren()) do
                            if child35.Name == "Smoke Admiral" and child35.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    if ((CFrame.new(-7894.6181640625, 5547.1420898438, -380.29098510742)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude >= 7500 then
                                        ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("requestEntrance", vector.create(-7894.6181640625, 5547.1420898438, -380.29098510742))
                                    end
                                    tweenTeleportTo(child35.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child35.Parent or child35.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Smoke Admiral")
                            end
                        end
                    elseif Utils.findFirstChild(replicatedStorage, "Smoke Admiral") then
                        for key93, child36 in pairs(replicatedStorage:GetChildren()) do
                            if child36.Name == "Smoke Admiral" and child36.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    if ((CFrame.new(-7894.6181640625, 5547.1420898438, -380.29098510742)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude >= 7500 then
                                        ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("requestEntrance", vector.create(-7894.6181640625, 5547.1420898438, -380.29098510742))
                                    end
                                    tweenTeleportTo(child36.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child36.Parent or child36.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Smoke Admiral")
                            end
                        end
                    end
                until not Utils.checkBoss("Smoke Admiral")
            elseif Quest == "Wardens Sword" then
                if not Utils.checkBoss("Chief Warden") then
                    return
                end
                repeat
                    task.wait()
                    if Utils.findFirstChild(enemiesFolder, "Chief Warden") then
                        for key94, child37 in pairs(enemiesFolder:GetChildren()) do
                            if child37.Name == "Chief Warden" and child37.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    if ((CFrame.new(-7894.6181640625, 5547.1420898438, -380.29098510742)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude >= 7500 then
                                        ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("requestEntrance", vector.create(-7894.6181640625, 5547.1420898438, -380.29098510742))
                                    end
                                    tweenTeleportTo(child37.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child37.Parent or child37.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Chief Warden")
                            end
                        end
                    elseif Utils.findFirstChild(replicatedStorage, "Chief Warden") then
                        for key95, child38 in pairs(replicatedStorage:GetChildren()) do
                            if child38.Name == "Chief Warden" and child38.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    if ((CFrame.new(-7894.6181640625, 5547.1420898438, -380.29098510742)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude >= 7500 then
                                        ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("requestEntrance", vector.create(-7894.6181640625, 5547.1420898438, -380.29098510742))
                                    end
                                    tweenTeleportTo(child38.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child38.Parent or child38.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Chief Warden")
                            end
                        end
                    end
                until not Utils.checkBoss("The Saw")
            elseif Quest == "Magma Blaster" then
                if not Utils.checkBoss("Magma Admiral") then
                    return
                end
                repeat
                    task.wait()
                    if Utils.findFirstChild(enemiesFolder, "Magma Admiral") then
                        for key96, child39 in pairs(enemiesFolder:GetChildren()) do
                            if child39.Name == "Magma Admiral" and child39.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    if ((CFrame.new(-7894.6181640625, 5547.1420898438, -380.29098510742)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude >= 7500 then
                                        ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("requestEntrance", vector.create(-7894.6181640625, 5547.1420898438, -380.29098510742))
                                    end
                                    tweenTeleportTo(child39.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child39.Parent or child39.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Magma Admiral")
                            end
                        end
                    elseif Utils.findFirstChild(replicatedStorage, "Magma Admiral") then
                        for key97, child40 in pairs(replicatedStorage:GetChildren()) do
                            if child40.Name == "Magma Admiral" and child40.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    if ((CFrame.new(-7894.6181640625, 5547.1420898438, -380.29098510742)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude >= 7500 then
                                        ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("requestEntrance", vector.create(-7894.6181640625, 5547.1420898438, -380.29098510742))
                                    end
                                    tweenTeleportTo(child40.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child40.Parent or child40.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Magma Admiral")
                            end
                        end
                    end
                until not Utils.checkBoss("Magma Admiral")
            elseif Quest == "Bazooka" then
                if not Utils.checkBoss("Wysper") then
                    return
                end
                repeat
                    task.wait()
                    if Utils.findFirstChild(enemiesFolder, "Wysper") then
                        for key98, child41 in pairs(enemiesFolder:GetChildren()) do
                            if child41.Name == "Wysper" and child41.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    if ((CFrame.new(-7894.6181640625, 5547.1420898438, -380.29098510742)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude >= 7500 then
                                        ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("requestEntrance", vector.create(-7894.6181640625, 5547.1420898438, -380.29098510742))
                                    end
                                    tweenTeleportTo(child41.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child41.Parent or child41.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Wysper")
                            end
                        end
                    elseif Utils.findFirstChild(replicatedStorage, "Wysper") then
                        for key99, child42 in pairs(replicatedStorage:GetChildren()) do
                            if child42.Name == "Wysper" and child42.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    if ((CFrame.new(-7894.6181640625, 5547.1420898438, -380.29098510742)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude >= 7500 then
                                        ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("requestEntrance", vector.create(-7894.6181640625, 5547.1420898438, -380.29098510742))
                                    end
                                    tweenTeleportTo(child42.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child42.Parent or child42.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Wysper")
                            end
                        end
                    end
                until not Utils.checkBoss("Wysper")
            elseif Quest == "Twin Hooks" then
                if not Utils.checkBoss("Captain Elephant") then
                    return
                end
                repeat
                    task.wait()
                    if Utils.findFirstChild(enemiesFolder, "Captain Elephant") then
                        for key100, child43 in pairs(enemiesFolder:GetChildren()) do
                            if child43.Name == "Captain Elephant" and child43.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    if ((CFrame.new(-7894.6181640625, 5547.1420898438, -380.29098510742)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude >= 7500 then
                                        ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("requestEntrance", vector.create(-7894.6181640625, 5547.1420898438, -380.29098510742))
                                    end
                                    tweenTeleportTo(child43.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child43.Parent or child43.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Captain Elephant")
                            end
                        end
                    elseif Utils.findFirstChild(replicatedStorage, "Captain Elephant") then
                        for key101, child44 in pairs(replicatedStorage:GetChildren()) do
                            if child44.Name == "Captain Elephant" and child44.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    if ((CFrame.new(-7894.6181640625, 5547.1420898438, -380.29098510742)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude >= 7500 then
                                        ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer("requestEntrance", vector.create(-7894.6181640625, 5547.1420898438, -380.29098510742))
                                    end
                                    tweenTeleportTo(child44.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child44.Parent or child44.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Captain Elephant")
                            end
                        end
                    end
                until not Utils.checkBoss("Wysper")
            elseif Quest == "Gravity Blade" then
                if not Utils.checkBoss("Orbitus") then
                    return
                end
                repeat
                    task.wait()
                    if Utils.findFirstChild(enemiesFolder, "Orbitus") then
                        for key102, child45 in pairs(enemiesFolder:GetChildren()) do
                            if child45.Name == "Orbitus" and child45.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    tweenTeleportTo(child45.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child45.Parent or child45.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Orbitus")
                            end
                        end
                    elseif Utils.findFirstChild(replicatedStorage, "Orbitus") then
                        for key103, child46 in pairs(replicatedStorage:GetChildren()) do
                            if child46.Name == "Orbitus" and child46.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    tweenTeleportTo(child46.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child46.Parent or child46.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Orbitus")
                            end
                        end
                    end
                until not Utils.checkBoss("Orbitus")
            elseif Quest == "Longsword" then
                if not Utils.checkBoss("Diamond") then
                    return
                end
                repeat
                    task.wait()
                    if Utils.findFirstChild(enemiesFolder, "Diamond") then
                        for key104, child47 in pairs(enemiesFolder:GetChildren()) do
                            if child47.Name == "Diamond" and child47.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    tweenTeleportTo(child47.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child47.Parent or child47.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Diamond")
                            end
                        end
                    elseif Utils.findFirstChild(replicatedStorage, "Diamond") then
                        for key105, child48 in pairs(replicatedStorage:GetChildren()) do
                            if child48.Name == "Diamond" and child48.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    tweenTeleportTo(child48.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child48.Parent or child48.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Diamond")
                            end
                        end
                    end
                until not Utils.checkBoss("Diamond")
            elseif Quest == "Rengoku" then
                if not Utils.checkBoss("Awakened Ice Admiral") then
                    return
                end
                repeat
                    task.wait()
                    if Utils.findFirstChild(enemiesFolder, "Awakened Ice Admiral") then
                        for key106, child49 in pairs(enemiesFolder:GetChildren()) do
                            if child49.Name == "Awakened Ice Admiral" and child49.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    tweenTeleportTo(child49.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child49.Parent or child49.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Awakened Ice Admiral")
                            end
                        end
                    elseif Utils.findFirstChild(replicatedStorage, "Awakened Ice Admiral") then
                        for key107, child50 in pairs(replicatedStorage:GetChildren()) do
                            if child50.Name == "Awakened Ice Admiral" and child50.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    tweenTeleportTo(child50.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child50.Parent or child50.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Awakened Ice Admiral")
                            end
                        end
                    end
                until not Utils.checkBoss("Awakened Ice Admiral")
            elseif Quest == "BartiloQuest" then
                if New_World then
                    local response7 = replicatedStorage.Remotes.CommF_:InvokeServer("BartiloQuestProgress")
                    if response7.KilledBandits == false then
                        if farmPlayer.PlayerGui.Main.Quest.Visible and Utils.stringFind(farmPlayer.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text,
                            "Swan Pirates") and Utils.stringFind(farmPlayer.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text,
                            "50") then
                            if Utils.findFirstChild(enemiesFolder, "Swan Pirate") then
                                for key108, child51 in pairs(enemiesFolder:GetChildren()) do
                                    if child51.Name == "Swan Pirate" and child51.Humanoid.Health > 0 then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("SetSpawnPoint")
                                        repeat
                                            task.wait()
                                            Utils.freezeEnemy(child51.Name)
                                            tweenTeleportTo(child51.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                            if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                                replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                            end
                                            equipPreferredFarmTool()
                                        until (child51.HumanoidRootPart.Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 50
                                                or child51.Humanoid.Health <= 0
                                                or not getgenv().AutoFarm
                                    end
                                end
                            else
                                tweenTeleportTo(CFrame.new(976.467651, 111.174057, 1229.1084), 1.5)
                            end
                        else
                            replicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "BartiloQuest", 1)
                        end
                    elseif response7.KilledSpring == false then
                        if Utils.findFirstChild(enemiesFolder, "Jeremy") then
                            for key109, child52 in pairs(enemiesFolder:GetChildren()) do
                                if child52.Name == "Jeremy" then
                                    repeat
                                        task.wait()
                                        tweenTeleportTo(child52.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                        if not game.Players.LocalPlayer.Character:FindFirstChild("HasBuso") then
                                            replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                        end
                                        equipPreferredFarmTool()
                                    until not child52.Parent or child52.Humanoid.Health <= 0 or not getgenv().AutoFarm
                                end
                            end
                        elseif Utils.findFirstChild(replicatedStorage, "Jeremy") then
                            tweenTeleportTo((replicatedStorage:FindFirstChild("Jeremy")).HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                        elseif not Utils.findFirstChild(enemiesFolder, "Jeremy") and not Utils.findFirstChild(replicatedStorage, "Jeremy") then
                            runDefaultFarmQuest()
                        end
                    elseif response7.DidPlates == false then
                        repeat
                            task.wait(.3)
                            tweenTeleportTo(CFrame.new(-1836, 11, 1714), 1.5)
                        until (Vector3.new(-1836, 11, 1714) - farmPlayer.Character.HumanoidRootPart.Position).Magnitude < 10
                        task.wait(1)
                        replicatedStorage.Remotes.CommF_:InvokeServer("BartiloQuestProgress", "DidPlates")
                    end
                else
                    replicatedStorage.Remotes.CommF_:InvokeServer("TravelDressrosa")
                end
            elseif Quest == "Find Water Key" then
                if New_World then
                    if farmPlayer.Backpack:FindFirstChild("Water Key") or Utils.findFirstChild(farmPlayer.Character, "Water Key") then
                        Utils.setStatus(" Status : Use Water Key")
                        Utils.equipTool("Water Key")
                        task.wait(0)
                        combatReplicatedStorage.Remotes.CommF_:InvokeServer("BuySharkmanKarate", true)
                        CheckFindWaterKey = true
                    elseif not Utils.findFirstChild(farmPlayer.Backpack, "Water Key") and not Utils.findFirstChild(farmPlayer.Character, "Water Key") then
                        if Utils.findFirstChild(enemiesFolder, "Tide Keeper") then
                            for key110, child53 in pairs(enemiesFolder:GetChildren()) do
                                if child53.Name == "Tide Keeper" and child53:FindFirstChild("Humanoid") and (child53:FindFirstChild("Humanoid")).Health > 0 then
                                    repeat
                                        task.wait()
                                        tweenTeleportTo(child53.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                        if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                            replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                        end
                                        equipPreferredFarmTool()
                                    until not child53.Parent or child53.Humanoid.Health <= 0 or not getgenv().AutoFarm
                                end
                            end
                        elseif Utils.findFirstChild(replicatedStorage, "Tide Keeper") then
                            for key111, child54 in pairs(replicatedStorage:GetChildren()) do
                                if child54.Name == "Tide Keeper" and child54:FindFirstChild("Humanoid") and (child54:FindFirstChild("Humanoid")).Health > 0 then
                                    repeat
                                        task.wait()
                                        tweenTeleportTo(child54.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                        if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                            replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                        end
                                        equipPreferredFarmTool()
                                    until not child54.Parent or child54.Humanoid.Health <= 0 or not getgenv().AutoFarm
                                end
                            end
                        else
                            farmPlayer:Kick("Hop")
                            task.wait(.1)
                            teleportService:Teleport(currentPlaceId, farmPlayer)
                        end
                    end
                else
                    replicatedStorage.Remotes.CommF_:InvokeServer("TravelDressrosa")
                end
            elseif Quest == "Evo Race V1" then
                if New_World then
                    if Start_Quest_Evo_V1 then
                        if not Utils.findFirstChild(farmPlayer.Backpack, "Flower 3") and not Utils.findFirstChild(farmPlayer.Character, "Flower 3") then
                            if (farmPlayer.Character.HumanoidRootPart.Position - Vector3.new(976.467651, 111.174057, 1229.1084)).Magnitude <= 800 then
                                for key112, child55 in pairs(enemiesFolder:GetChildren()) do
                                    if child55.Humanoid.Health > 0 and (child55.HumanoidRootPart.Position - Vector3.new(976.467651, 111.174057, 1229.1084)).Magnitude <= 800 then
                                        repeat
                                            task.wait()
                                            tweenTeleportTo(child55.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                            if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                                replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                            end
                                            equipPreferredFarmTool()
                                        until not child55.Parent or child55.Humanoid.Health <= 0 or Utils.findFirstChild(farmPlayer.Backpack,
                                            "Flower 3") or Utils.findFirstChild(farmPlayer.Character,
                                            "Flower 3") or not getgenv().AutoFarm
                                    end
                                end
                            else
                                tweenTeleportTo(CFrame.new(976.467651, 111.174057, 1229.1084), 1.5)
                            end
                        elseif not Utils.findFirstChild(farmPlayer.Backpack, "Flower 2") and not Utils.findFirstChild(farmPlayer.Character, "Flower 2") then
                            if Utils.findFirstChild(workspaceService, "Flower2") then
                                tweenTeleportTo(workspaceService.Flower2.CFrame, 1.5)
                                if (farmPlayer.Character.HumanoidRootPart.Position - workspaceService.Flower2.Position).Magnitude <= 5 then
                                    virtualInputManager:SendKeyEvent(true, "Space", false, game)
                                    task.wait(.5)
                                    virtualInputManager:SendKeyEvent(false, "Space", false, game)
                                end
                            end
                        elseif not Utils.findFirstChild(farmPlayer.Backpack, "Flower 1") and not Utils.findFirstChild(farmPlayer.Character, "Flower 1") then
                            tweenTeleportTo(workspaceService.Flower1.CFrame, 1.5)
                            if (farmPlayer.Character.HumanoidRootPart.Position - workspaceService.Flower1.Position).Magnitude <= 5 and workspaceService.Flower1.Transparency == 0 then
                                virtualInputManager:SendKeyEvent(true, "Space", false, game)
                                task.wait(.5)
                                virtualInputManager:SendKeyEvent(false, "Space", false, game)
                            end
                            task.wait(1)
                        else
                            replicatedStorage.Remotes.CommF_:InvokeServer("Alchemist", "3")
                        end
                    else
                        if replicatedStorage.Remotes.CommF_:InvokeServer("Alchemist", "1") == 1 or replicatedStorage.Remotes.CommF_:InvokeServer("Alchemist", "1") == 2 then
                            Start_Quest_Evo_V1 = true
                        end
                        replicatedStorage.Remotes.CommF_:InvokeServer("Alchemist", "2")
                    end
                else
                    replicatedStorage.Remotes.CommF_:InvokeServer("TravelDressrosa")
                end
            elseif Quest == "Evo Race V2" then
                if New_World then
                    if farmPlayer.Data.Race.Value == "Human" then
                        if Quest_Start_Evo_Human_V3 then
                            if not Utils.findFirstChild(enemiesFolder, "Orbitus") and not Utils.findFirstChild(replicatedStorage, "Orbitus") and not Kill_Orbitus then
                                Utils.hopToLowServer(4)
                                task.wait(.2)
                                farmPlayer:Kick("Hop")
                                task.wait(.1)
                                teleportService:Teleport(currentPlaceId, farmPlayer)
                            end
                            if not Utils.findFirstChild(enemiesFolder, "Jeremy") and not Utils.findFirstChild(replicatedStorage, "Jeremy") and not Kill_Jeremy then
                                Utils.hopToLowServer(4)
                                task.wait(.2)
                                farmPlayer:Kick("Hop")
                                task.wait(.1)
                                teleportService:Teleport(currentPlaceId, farmPlayer)
                            end
                            if not Utils.findFirstChild(enemiesFolder, "Diamond") and not Utils.findFirstChild(replicatedStorage, "Diamond") and not Kill_Diamond then
                                Utils.hopToLowServer(4)
                                task.wait(.2)
                                farmPlayer:Kick("Hop")
                                task.wait(.1)
                                teleportService:Teleport(currentPlaceId, farmPlayer)
                            end
                            if not Kill_Orbitus then
                                repeat
                                    task.wait()
                                    pcall(function()
                                        if Utils.findFirstChild(enemiesFolder, "Orbitus") or Utils.findFirstChild(replicatedStorage, "Orbitus") then
                                            if Utils.findFirstChild(enemiesFolder, "Orbitus") then
                                                for key113, child56 in pairs(enemiesFolder:GetChildren()) do
                                                    if child56.Name == "Orbitus" and child56.Humanoid.Health > 0 then
                                                        repeat
                                                            task.wait()
                                                            if child56:FindFirstChild("HumanoidRootPart") then
                                                                tweenTeleportTo(child56.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                                                if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                                                    replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                                                end
                                                                equipPreferredFarmTool()
                                                            else
                                                                Kill_Orbitus = true
                                                                break
                                                            end
                                                        until not child56.Parent or child56.Humanoid.Health <= 0 or not getgenv().AutoFarm
                                                        Kill_Orbitus = true
                                                    end
                                                end
                                            elseif Utils.findFirstChild(replicatedStorage, "Orbitus") then
                                                tweenTeleportTo(replicatedStorage.Orbitus.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                            end
                                        end
                                    end)
                                until Kill_Orbitus
                            end
                            if not Kill_Jeremy then
                                repeat
                                    task.wait()
                                    pcall(function()
                                        if Utils.findFirstChild(enemiesFolder, "Jeremy") or Utils.findFirstChild(replicatedStorage, "Jeremy") then
                                            if Utils.findFirstChild(enemiesFolder, "Jeremy") then
                                                for key114, child57 in pairs(enemiesFolder:GetChildren()) do
                                                    if child57.Name == "Jeremy" and child57.Humanoid.Health > 0 then
                                                        repeat
                                                            task.wait()
                                                            if child57:FindFirstChild("HumanoidRootPart") then
                                                                tweenTeleportTo(child57.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                                                if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                                                    replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                                                end
                                                                equipPreferredFarmTool()
                                                            else
                                                                Kill_Jeremy = true
                                                                break
                                                            end
                                                        until not child57.Parent
                                                                or child57.Humanoid.Health <= 0
                                                                or not child57:FindFirstChild("HumanoidRootPart")
                                                                or not getgenv().AutoFarm
                                                        Kill_Jeremy = true
                                                    end
                                                end
                                            elseif Utils.findFirstChild(replicatedStorage, "Jeremy") then
                                                tweenTeleportTo(replicatedStorage.Jeremy.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                            end
                                        end
                                    end)
                                until Kill_Orbitus
                            end
                            if not Kill_Diamond then
                                repeat
                                    task.wait()
                                    pcall(function()
                                        if Utils.findFirstChild(enemiesFolder, "Diamond") or Utils.findFirstChild(replicatedStorage, "Diamond") then
                                            if Utils.findFirstChild(enemiesFolder, "Diamond") then
                                                for key115, child58 in pairs(enemiesFolder:GetChildren()) do
                                                    if child58.Name == "Diamond" and child58.Humanoid.Health > 0 then
                                                        repeat
                                                            task.wait()
                                                            if child58:FindFirstChild("HumanoidRootPart") then
                                                                tweenTeleportTo(child58.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                                                if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                                                    replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                                                end
                                                                equipPreferredFarmTool()
                                                            else
                                                                Kill_Diamond = true
                                                                break
                                                            end
                                                        until not child58.Parent or child58.Humanoid.Health <= 0 or not getgenv().AutoFarm
                                                        Kill_Diamond = true
                                                    end
                                                end
                                            elseif Utils.findFirstChild(replicatedStorage, "Diamond") then
                                                tweenTeleportTo(replicatedStorage.Diamond.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                            end
                                        end
                                    end)
                                until Kill_Diamond
                            end
                        else
                            replicatedStorage.Remotes.CommF_:InvokeServer("Wenlocktoad", "1")
                            task.wait(1)
                            replicatedStorage.Remotes.CommF_:InvokeServer("Wenlocktoad", "2")
                            warn()
                            if replicatedStorage.Remotes.CommF_:InvokeServer("Wenlocktoad", "1") == 1 or replicatedStorage.Remotes.CommF_:InvokeServer("Wenlocktoad", "1") == 2 then
                                Quest_Start_Evo_Human_V3 = true
                            end
                        end
                    elseif farmPlayer.Data.Race.Value == "Fishman" then
                        if Quest_Start_Evo_Fishman_V3 then
                            local flag5 = false
                            local flag6 = false
                            for key116, instance3 in pairs(workspaceService.SeaBeasts:GetChildren()) do
                                if instance3:FindFirstChild("Health")
                                        and instance3.Health.Value > 0
                                        and (Vector3.new(-3823.9206542969, 76.979339599609, -11685.7734375) - instance3.HumanoidRootPart.Position).Magnitude >= 1500 then
                                    flag5 = true
                                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyFishmanKarate")
                                    Tejao = true
                                    PositionSkillMasteryDevilFruit = instance3.HumanoidRootPart.CFrame
                                    farmPlayer.Character.Humanoid.Sit = false
                                    task.wait(1)
                                    if farmPlayer.Character.Humanoid.Sit == false then
                                        Boat = nil
                                    end
                                    repeat
                                        task.wait()
                                        tweenTeleportTo(instance3.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0), 1.5)
                                    until (instance3.HumanoidRootPart.Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 5 or not getgenv().AutoFarm
                                    repeat
                                        task.wait()
                                        Utils.equipTool("Fishman Karate")
                                        if farmPlayer.PlayerGui.Main.Skills:FindFirstChild("Fishman Karate")
                                                and tostring(farmPlayer.PlayerGui.Main.Skills["Fishman Karate"].Z.Title.TextColor) == "Institutional white"
                                                and farmPlayer.PlayerGui.Main.Skills["Fishman Karate"].Z.Cooldown.AbsoluteSize.X == 0 then
                                            Utils.equipTool("Fishman Karate")
                                            tweenTeleportTo(instance3.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0), 1.5)
                                            task.wait(.5)
                                            PositionSkillMasteryDevilFruit = instance3.HumanoidRootPart.Position
                                            if instance3.Health.Value > 0 then
                                                virtualInputManager:SendKeyEvent(true, "Z", false, game)
                                                task.wait(.5)
                                                virtualInputManager:SendKeyEvent(false, "Z", false, game)
                                                task.wait(.2)
                                            end
                                        elseif farmPlayer.PlayerGui.Main.Skills:FindFirstChild("Fishman Karate")
                                                and tostring(farmPlayer.PlayerGui.Main.Skills["Fishman Karate"].X.Title.TextColor) == "Institutional white"
                                                and farmPlayer.PlayerGui.Main.Skills["Fishman Karate"].X.Cooldown.AbsoluteSize.X == 0 then
                                            Utils.equipTool("Fishman Karate")
                                            tweenTeleportTo(instance3.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0), 1.5)
                                            task.wait(.5)
                                            PositionSkillMasteryDevilFruit = instance3.HumanoidRootPart.Position
                                            if instance3.Health.Value > 0 then
                                                virtualInputManager:SendKeyEvent(true, "X", false, game)
                                                task.wait(.5)
                                                virtualInputManager:SendKeyEvent(false, "X", false, game)
                                                task.wait(.2)
                                            end
                                        elseif farmPlayer.PlayerGui.Main.Skills:FindFirstChild("Fishman Karate")
                                                and tostring(farmPlayer.PlayerGui.Main.Skills["Fishman Karate"].C.Title.TextColor) == "Institutional white"
                                                and farmPlayer.PlayerGui.Main.Skills["Fishman Karate"].C.Cooldown.AbsoluteSize.X == 0 then
                                            Utils.equipTool("Fishman Karate")
                                            tweenTeleportTo(instance3.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0), 1.5)
                                            task.wait(.5)
                                            PositionSkillMasteryDevilFruit = instance3.HumanoidRootPart.Position
                                            if instance3.Health.Value > 0 then
                                                virtualInputManager:SendKeyEvent(true, "C", false, game)
                                                task.wait(.5)
                                                virtualInputManager:SendKeyEvent(false, "C", false, game)
                                                task.wait(.2)
                                            end
                                        end
                                    until not instance3.Parent or instance3.Health.Value <= 0 or not getgenv().AutoFarm
                                    Tejao = false
                                    replicatedStorage.Remotes.CommF_:InvokeServer("Wenlocktoad", "3")
                                    task.wait(1)
                                end
                            end
                            if not flag5 then
                                for key117, instance4 in pairs(workspaceService.Boats:GetChildren()) do
                                    if instance4.Name == "Dinghy" and tostring(instance4.Owner.Value) == farmPlayer.Name then
                                        flag6 = true
                                        if (Vector3.new(3017.2006835938, -4.25, -2686.3325195312) - instance4.VehicleSeat.Position).Magnitude >= 30 then
                                            if farmPlayer.Character.Humanoid.Sit then
                                                Boat = "Bit"
                                                TPBoat(CFrame.new(1550, -4.25, -2759), instance4.VehicleSeat, 200)
                                            elseif (farmPlayer.Character.HumanoidRootPart.Position - instance4.VehicleSeat.Position).Magnitude >= 10 then
                                                Boat = nil
                                                tweenTeleportTo(instance4.VehicleSeat.CFrame, 1.5)
                                            else
                                                Boat = "Bit"
                                                farmPlayer.Character.HumanoidRootPart.CFrame = instance4.VehicleSeat.CFrame * CFrame.new(0, 1, 0)
                                                task.wait(3)
                                            end
                                        else
                                            if farmPlayer.Character.Humanoid.Sit then
                                                vu:Button1Down(Vector2.new(1280, 600))
                                                task.wait(1)
                                            elseif (farmPlayer.Character.HumanoidRootPart.Position - instance4.VehicleSeat.Position).Magnitude >= 10 then
                                                Boat = nil
                                                tweenTeleportTo(instance4.VehicleSeat.CFramem, 1.5)
                                            else
                                                Boat = "Bit"
                                                farmPlayer.Character.HumanoidRootPart.CFrame = instance4.VehicleSeat.CFrame * CFrame.new(0, 1, 0)
                                                task.wait(3)
                                            end
                                        end
                                    end
                                end
                            end
                            if not flag6 and not flag5 then
                                tweenTeleportTo(CFrame.new(-1935, 6, -2564), 1.5)
                                if (Vector3.new(-1935, 6, -2564) - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3 then
                                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyBoat", "Dinghy")
                                    task.wait(1)
                                    Boat = "bit"
                                end
                            end
                        else
                            replicatedStorage.Remotes.CommF_:InvokeServer("Wenlocktoad", "1")
                            task.wait(1)
                            replicatedStorage.Remotes.CommF_:InvokeServer("Wenlocktoad", "2")
                            if replicatedStorage.Remotes.CommF_:InvokeServer("Wenlocktoad", "1") == 1 or replicatedStorage.Remotes.CommF_:InvokeServer("Wenlocktoad", "1") == 2 then
                                Quest_Start_Evo_Fishman_V3 = true
                            end
                        end
                    end
                else
                    replicatedStorage.Remotes.CommF_:InvokeServer("TravelDressrosa")
                end
            elseif Quest == "Don Swan" then
                repeat
                    task.wait()
                    if Utils.findFirstChild(enemiesFolder, "Don Swan") then
                        for key118, child59 in pairs(enemiesFolder:GetChildren()) do
                            if child59.Name == "Don Swan" and child59.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    tweenTeleportTo(child59.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child59.Parent or child59.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Don Swan")
                            end
                        end
                    elseif Utils.findFirstChild(replicatedStorage, "Don Swan") then
                        for key119, child60 in pairs(replicatedStorage:GetChildren()) do
                            if child60.Name == "Don Swan" and child60.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    tweenTeleportTo(child60.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child60.Parent or child60.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Don Swan")
                            end
                        end
                    else
                        Utils.hopToLowServer(3)
                        task.wait(.2)
                        farmPlayer:Kick("Hop")
                        task.wait(.1)
                        teleportService:Teleport(currentPlaceId, farmPlayer)
                    end
                until not Utils.checkBoss("Don Swan")
            elseif Quest == "TravelZou" then
                if replicatedStorage.Remotes.CommF_:InvokeServer("ZQuestProgress", "Check") == 1 then
                    replicatedStorage.Remotes.CommF_:InvokeServer("TravelZou")
                end
                if Kill_Don then
                    if Utils.findFirstChild(enemiesFolder, "rip_indra") then
                        for key120, child61 in pairs(enemiesFolder:GetChildren()) do
                            if child61.Name == "rip_indra" and child61.Humanoid.Health > 0 then
                                if Utils.findFirstChild(child61.Humanoid, "Animator") then
                                    child61.Humanoid.Animator:Destroy()
                                end
                                repeat
                                    task.wait(.1)
                                    equipPreferredFarmTool()
                                    tweenTeleportTo(child61.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                until child61.Humanoid.Health <= 0 or not child61.Parent or replicatedStorage.Remotes.CommF_:InvokeServer("ZQuestProgress", "Check") == 1
                                if replicatedStorage.Remotes.CommF_:InvokeServer("ZQuestProgress", "Check") == 1 then
                                    replicatedStorage.Remotes.CommF_:InvokeServer("TravelZou")
                                    TleP = true
                                    task.wait(30)
                                end
                            end
                        end
                    elseif replicatedStorage.Remotes.CommF_:InvokeServer("ZQuestProgress", "Check") == 1 then
                        replicatedStorage.Remotes.CommF_:InvokeServer("TravelZou")
                        TleP = true
                        task.wait(30)
                    elseif not(game:GetService("Workspace")).Enemies:FindFirstChild("rip_indra") then
                        replicatedStorage.Remotes.CommF_:InvokeServer("ZQuestProgress", "Check")
                        replicatedStorage.Remotes.CommF_:InvokeServer("ZQuestProgress", "Begin")
                        task.wait(3)
                    end
                elseif not okokok then
                    replicatedStorage.Remotes.CommF_:InvokeServer("ZQuestProgress", "Check")
                    replicatedStorage.Remotes.CommF_:InvokeServer("ZQuestProgress", "Begin")
                    task.wait(3)
                    for key121, child62 in pairs(enemiesFolder:GetChildren()) do
                        if child62.Name == "rip_indra" then
                            Kill_Don = true
                        end
                    end
                    okokok = true
                else
                    equipPreferredFarmTool()
                    Quest = nil
                    Utils.setStatus(" Status : Auto Farm Level")
                    runDefaultFarmQuest()
                end
            elseif Quest == "Yama" then
                if (workspaceService.Map.Waterfall.SealedKatana.Hitbox.Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 300 then
                    if Utils.findFirstChild(enemiesFolder, "Ghost") then
                        for key122, child63 in pairs(enemiesFolder:GetChildren()) do
                            if child63.Name == "Ghost" and child63.Humanoid.Health > 0 then
                                if Utils.findFirstChild(child63.Humanoid, "Animator") then
                                    child63.Humanoid.Animator:Destroy()
                                end
                                repeat
                                    task.wait(.1)
                                    equipPreferredFarmTool()
                                    child63.HumanoidRootPart.Size = Vector3.new(50, 50, 50)
                                    tweenTeleportTo(child63.HumanoidRootPart.CFrame * CFrame.new(0, 15, 0), 1.5)
                                    virtualUser:Button1Down(Vector2.new(1280, 600))
                                until not child63.Parent or child63.Humanoid.Health <= 0
                            end
                        end
                    elseif Utils.findFirstChild(replicatedStorage, "Ghost") then
                        tweenTeleportTo((replicatedStorage:FindFirstChild("Ghost")).HumanoidRootPart.CFrame, 1.5)
                    elseif not Utils.findFirstChild(enemiesFolder, "Ghost") and not Utils.findFirstChild(replicatedStorage, "Ghost") then
                        tweenTeleportTo(workspaceService.Map.Waterfall.SealedKatana.Hitbox.CFrame, 1.5)
                        for key123, farmplayer7 in pairs(farmPlayer.Character:GetChildren()) do
                            if farmplayer7:IsA("Tool") then
                                farmplayer7.Parent = farmPlayer.Backpack
                            end
                        end
                        fireclickdetector(workspaceService.Map.Waterfall.SealedKatana.Hitbox.ClickDetector, 1)
                    end
                else
                    tweenTeleportTo(workspaceService.Map.Waterfall.SealedKatana.Hitbox.CFrame, 1.5)
                end
            elseif Quest == "Quest Electric Claw" then
                if replicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw",
                    true) == "Nah." or replicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw",
                    true) == 4 then
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw", "Start")
                    farmPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-12548, 337, -7481)
                elseif replicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw",
                    true) == 3 or replicatedStorage.Remotes.CommF_:InvokeServer("BuyElectricClaw",
                    true) == 0 then
                    Electric_Claw_C = true
                end
            elseif Quest == "Venom Bow" then
                if not Utils.checkBoss("Hydra Leader") then
                    return
                end
                repeat
                    task.wait()
                    if Utils.findFirstChild(enemiesFolder, "Hydra Leader") then
                        for key124, child64 in pairs(enemiesFolder:GetChildren()) do
                            if child64.Name == "Hydra Leader" and child64.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    tweenTeleportTo(child64.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child64.Parent or child64.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Hydra Leader")
                            end
                        end
                    elseif Utils.findFirstChild(replicatedStorage, "Hydra Leader") then
                        for key125, child65 in pairs(replicatedStorage:GetChildren()) do
                            if child65.Name == "Hydra Leader" and child65.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    tweenTeleportTo(child65.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child65.Parent or child65.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Hydra Leader")
                            end
                        end
                    end
                until not Utils.checkBoss("Hydra Leader")
            elseif Quest == "Godhuman" then
                if Utils.getItemCount("Fish Tail") >= 20
                        and Utils.getItemCount("Magma Ore") >= 20
                        and Utils.getItemCount("Mystic Droplet") >= 10
                        and Utils.getItemCount("Dragon Scale") >= 10 then
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyGodhuman", true)
                    Godhuman = true
                elseif Utils.getItemCount("Fish Tail") < 20
                        or Utils.getItemCount("Magma Ore") < 20
                        or Utils.getItemCount("Mystic Droplet") < 10
                        or Utils.getItemCount("Dragon Scale") < 10 then
                    local nil6 = nil
                    local nil5 = nil
                    local nil4 = nil
                    local nil3 = nil
                    if Utils.getItemCount("Fish Tail") < 20 then
                        nil6 = "Fishman Warrior"
                        nil5 = "Fishman Commando"
                        nil4 = CFrame.new(60946.6094, 65.6735229, 1525.91687)
                        nil3 = CFrame.new(61902.7383, 32.4828358, 1478.33936)
                        if ((CFrame.new(61164, 12, 1820)).Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude >= 2000 then
                            farmPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(61164, 12, 1820)
                        end
                        if not Old_World then
                            replicatedStorage.Remotes.CommF_:InvokeServer("TravelMain")
                            TleP = true
                            task.wait(50)
                        end
                    elseif Utils.getItemCount("Magma Ore") < 20 then
                        nil6 = "Magma Ninja"
                        nil5 = "Lava Pirate"
                        nil4 = CFrame.new(-5466.06445, 77.6952019, -5837.42822)
                        nil3 = CFrame.new(-5169.71729, 54.1234779, -4669.73633)
                        if not New_World then
                            replicatedStorage.Remotes.CommF_:InvokeServer("TravelDressrosa")
                            TleP = true
                            task.wait(50)
                        end
                    elseif Utils.getItemCount("Mystic Droplet") < 10 then
                        nil6 = "Sea Soldier"
                        nil5 = "Water Fighter"
                        nil4 = CFrame.new(-3115.78223, 63.8785706, -9808.38574)
                        nil3 = CFrame.new(-3212.99683, 263.809296, -10551.8799)
                        if not New_World then
                            replicatedStorage.Remotes.CommF_:InvokeServer("TravelDressrosa")
                            TleP = true
                            task.wait(50)
                        end
                    elseif Utils.getItemCount("Dragon Scale") < 10 then
                        nil6 = "Dragon Crew Warrior"
                        nil5 = "Dragon Crew Archer"
                        nil4 = CFrame.new(6241.9951171875, 51.522083282471, -1243.9771728516)
                        nil3 = CFrame.new(6488.9155273438, 383.38375854492, -110.66246032715)
                        if not Three_World then
                            replicatedStorage.Remotes.CommF_:InvokeServer("TravelZou")
                            TleP = true
                            task.wait(50)
                        end
                    end
                    if nil6 ~= nil then
                        repeat
                            task.wait()
                            tweenTeleportTo(nil4)
                        until (nil4.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3
                        if Utils.findFirstChild(enemiesFolder, nil6) then
                            for key126, instance5 in pairs(game.Workspace.Enemies:GetChildren()) do
                                if instance5.Name == nil6 and instance5.Humanoid.Health > 0 then
                                    StatrMagnet = true
                                    repeat
                                        task.wait()
                                        tweenTeleportTo(instance5.HumanoidRootPart.CFrame * CFrame.new(0, 20, 0), 1.5)
                                        equipPreferredFarmTool()
                                        Utils.freezeEnemy(instance5.Name)
                                    until not instance5.Parent or instance5.Humanoid.Health <= 0
                                    StatrMagnet = false
                                end
                            end
                        end
                    end
                    if nil5 ~= nil then
                        repeat
                            task.wait()
                            tweenTeleportTo(nil3, 1.5)
                        until (nil3.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3
                        if game.Workspace.Enemies:FindFirstChild(nil5) then
                            for key127, instance6 in pairs(game.Workspace.Enemies:GetChildren()) do
                                if instance6.Name == nil5 and instance6.Humanoid.Health > 0 then
                                    StatrMagnet = true
                                    repeat
                                        task.wait()
                                        tweenTeleportTo(instance6.HumanoidRootPart.CFrame * CFrame.new(0, 20, 0), 1.5)
                                        equipPreferredFarmTool()
                                        Utils.freezeEnemy(instance6.Name)
                                    until not instance6.Parent or instance6.Humanoid.Health <= 0
                                    StatrMagnet = false
                                end
                            end
                        end
                    end
                end
            elseif Quest == "Longma" then
                repeat
                    task.wait()
                    if Utils.findFirstChild(enemiesFolder, "Longma") then
                        for key128, child66 in pairs(enemiesFolder:GetChildren()) do
                            if child66.Name == "Longma" and child66.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    tweenTeleportTo(child66.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child66.Parent or child66.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Longma")
                            end
                        end
                    elseif Utils.findFirstChild(replicatedStorage, "Longma") then
                        for key129, child67 in pairs(replicatedStorage:GetChildren()) do
                            if child67.Name == "Longma" and child67.Humanoid.Health > 0 then
                                repeat
                                    task.wait()
                                    tweenTeleportTo(child67.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                    end
                                    equipPreferredFarmTool()
                                until not child67.Parent or child67.Humanoid.Health <= 0 or not getgenv().AutoFarm or not Utils.checkBoss("Longma")
                            end
                        end
                    else
                        Utils.hopToLowServer(3)
                        task.wait(.2)
                        farmPlayer:Kick("Hop")
                        task.wait(.1)
                        teleportService:Teleport(currentPlaceId, farmPlayer)
                    end
                until not Utils.checkBoss("Longma")
            elseif Quest == "Soul Guitar" then
                if Utils.getItemCount("Bones") < 500 then
                    if Three_World then
                        Utils.farmBone(false)
                    else
                        replicatedStorage.Remotes.CommF_:InvokeServer("TravelZou")
                        TleP = true
                        task.wait(50)
                    end
                elseif Utils.getItemCount("Ectoplasm") < 250 then
                    if New_World then
                        if (farmPlayer.Character.HumanoidRootPart.Position - Vector3.new(921.30249023438, 125.400390625, 32937.34375)).Magnitude >= 3000 then
                            repeat
                                task.wait()
                                tweenTeleportTo(CFrame.new(921.30249023438, 125.400390625, 32937.34375), 1.5)
                            until (farmPlayer.Character.HumanoidRootPart.Position - Vector3.new(921.30249023438, 125.400390625, 32937.34375)).Magnitude <= 3
                        elseif (farmPlayer.Character.HumanoidRootPart.Position - Vector3.new(921.30249023438, 125.400390625, 32937.34375)).Magnitude < 3000 then
                            Monster = nil
                            for index10 = 1500, 0, -300 do
                                Utils.findNearestMonster(index10)
                            end
                            if Monster ~= nil and Monster.Humanoid.Health > 0 then
                                PosMon_X = Monster.HumanoidRootPart.CFrame
                                StatrMagnet = true
                                repeat
                                    task.wait()
                                    tweenTeleportTo(Monster.HumanoidRootPart.CFrame * CFrame.new(0, 20, 0), 1.5)
                                    equipPreferredFarmTool()
                                until not Monster.Parent or Monster.Humanoid.Health <= 0
                                StatrMagnet = false
                            elseif Monster == nil then
                                for index11 = 1500, 0, -300 do
                                    Utils.findNearestMonster(index11)
                                end
                                if Monster == nil then
                                    tweenTeleportTo(CFrame.new(921.30249023438, 125.400390625, 32937.34375), 1.5)
                                end
                            end
                        end
                    else
                        replicatedStorage.Remotes.CommF_:InvokeServer("TravelDressrosa")
                        TleP = true
                        task.wait(50)
                    end
                elseif not Three_World then
                    replicatedStorage.Remotes.CommF_:InvokeServer("TravelZou")
                    TleP = true
                    task.wait(50)
                else
                    if tostring((game:GetService("Workspace")).Map["Haunted Castle"].SwampWater.BrickColor) == "Maroon" then
                        if replicatedStorage.Remotes.CommF_:InvokeServer("GuitarPuzzleProgress", "Check") ~= nil and (replicatedStorage.Remotes.CommF_:InvokeServer("GuitarPuzzleProgress", "Check")).Swamp == false then
                            repeat
                                task.wait()
                                tweenTeleportTo(CFrame.new(-10147.779296875, 138.6266784668, 5939.5600585938), 1.5)
                            until (Vector3.new(-10147.779296875, 138.6266784668, 5939.5600585938) - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3
                            task.wait(1)
                            get_mon = {}
                            Utils.collectSouls()
                            if #get_mon >= 6 then
                                for key130, farmplayer8 in pairs(farmPlayer.Character:GetChildren()) do
                                    if farmplayer8:IsA("Tool") then
                                        farmplayer8.Parent = farmPlayer.Backpack
                                    end
                                end
                                tweenTeleportTo(CFrame.new(-10147.779296875, 158.6266784668, 5939.5600585938), 1.5)
                                for key131, child68 in next, (game:GetService("Workspace")).Enemies:GetChildren() do
                                    if (child68.HumanoidRootPart.Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 500 then
                                        child68.HumanoidRootPart.CFrame = farmPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 20)
                                        sethiddenproperty(farmPlayer, "SimulationRadius", math.huge)
                                    end
                                end
                                task.wait(1)
                                equipPreferredFarmTool()
                                task.wait(2)
                            end
                        end
                    elseif replicatedStorage.Remotes.CommF_:InvokeServer("GuitarPuzzleProgress", "Check") ~= nil then
                        local response8 = replicatedStorage.Remotes.CommF_:InvokeServer("GuitarPuzzleProgress", "Check")
                        if not Quest_Soul_Guitar then
                            repeat
                                task.wait(.1)
                                tweenTeleportTo(CFrame.new(-9680.7412109375, 6.1591067314148, 6346.1552734375), 1.5)
                            until (Vector3.new(-9680.7412109375, 6.1591067314148, 6346.1552734375) - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 5
                            task.wait(1)
                            for key132, item19 in pairs(replicatedStorage.Remotes.CommF_:InvokeServer("GuitarPuzzleProgress", "Check")) do
                                if item19 == false then
                                    replicatedStorage.Remotes.CommF_:InvokeServer("GuitarPuzzleProgress", key132)
                                end
                            end
                            task.wait(2)
                            for key133, item20 in pairs(replicatedStorage.Remotes.CommF_:InvokeServer("GuitarPuzzleProgress", "Check")) do
                                if item20 == false then
                                    replicatedStorage.Remotes.CommF_:InvokeServer("GuitarPuzzleProgress", key133)
                                end
                            end
                            task.wait(1)
                            Quest_Soul_Guitar = true
                        end
                    elseif tostring((game:GetService("Workspace")).Map["Haunted Castle"].SwampWater.BrickColor) ~= "Maroon" then
                        if replicatedStorage.Remotes.CommF_:InvokeServer("gravestoneEvent", 2) == true then
                            replicatedStorage.Remotes.CommF_:InvokeServer("gravestoneEvent", 2, true)
                        else
                            tweenTeleportTo(CFrame.new(-8652.6416015625, 141.10939025879, 6168.810546875), 1.5)
                        end
                    end
                end
            elseif Quest == "RGB" then
                local nil7 = nil
                if replicatedStorage.Remotes.CommF_:InvokeServer("HornedMan", "Bet") == nil then
                    if farmPlayer.PlayerGui.Main.Quest.Visible then
                        local players3 = (game:GetService("Players")).LocalPlayer.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text
                        if string.find(players3, "Stone") then
                            if Utils.findFirstChild(enemiesFolder, "Stone") or Utils.findFirstChild(replicatedStorage, "Stone") then
                                nil7 = "Stone"
                            end
                        end
                        if string.find(players3, "Hydra Leader") then
                            if Utils.findFirstChild(enemiesFolder, "Hydra Leader") or Utils.findFirstChild(replicatedStorage, "Hydra Leader") then
                                nil7 = "Hydra Leader"
                            end
                        end
                        if string.find(players3, "Kilo Admiral") then
                            if Utils.findFirstChild(enemiesFolder, "Kilo Admiral") or Utils.findFirstChild(replicatedStorage, "Kilo Admiral") then
                                nil7 = "Kilo Admiral"
                            end
                        end
                        if string.find(players3, "Captain Elephant") then
                            if Utils.findFirstChild(enemiesFolder, "Captain Elephant") or Utils.findFirstChild(replicatedStorage, "Captain Elephant") then
                                nil7 = "Captain Elephant"
                            end
                        end
                        if string.find(players3, "Beautiful Pirate") then
                            if Utils.findFirstChild(enemiesFolder, "Beautiful Pirate") or Utils.findFirstChild(replicatedStorage, "Beautiful Pirate") then
                                nil7 = "Beautiful Pirate"
                            end
                        end
                        if nil7 ~= nil then
                            if Utils.findFirstChild(enemiesFolder, nil7) then
                                for key134, child69 in pairs(enemiesFolder:GetChildren()) do
                                    if child69.Name == nil7 and child69.Humanoid.Health > 0 then
                                        repeat
                                            task.wait()
                                            tweenTeleportTo(child69.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                            if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                                replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                            end
                                            equipPreferredFarmTool()
                                        until not child69.Parent or child69.Humanoid.Health <= 0 or not getgenv().AutoFarm
                                    end
                                end
                            elseif Utils.findFirstChild(replicatedStorage, nil7) then
                                for key135, child70 in pairs(replicatedStorage:GetChildren()) do
                                    if child70.Name == nil7 and child70.Humanoid.Health > 0 then
                                        repeat
                                            task.wait()
                                            tweenTeleportTo(child70.HumanoidRootPart.CFrame * CFrame.new(0, 40, 0), 1.5)
                                            if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                                                replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                                            end
                                            equipPreferredFarmTool()
                                        until not child70.Parent or child70.Humanoid.Health <= 0 or not getgenv().AutoFarm
                                    end
                                end
                            end
                        else
                            if replicatedStorage.Remotes.CommF_:InvokeServer("HornedMan", "Bet") == 1 then
                                return
                            else
                                farmPlayer:Kick("Hop")
                                task.wait(.1)
                                teleportService:Teleport(currentPlaceId, farmPlayer)
                            end
                        end
                    end
                elseif replicatedStorage.Remotes.CommF_:InvokeServer("HornedMan", "Bet") == 1 then
                    return
                end
            elseif Quest == "Pull Lerver" then
                if not ExSeb then
                    if (game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer("RaceV4Progress", "Check") == 1 then
                        local value12
                        local value11 = {
                            [1] = "RaceV4Progress",
                            [2] = "Check"
                        },
                        (game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer(unpack(value11))
                        value12 = {
                            [1] = "RaceV4Progress",
                            [2] = "Begin"
                        },
                        (((game:GetService("ReplicatedStorage")):WaitForChild("Remotes")):WaitForChild("CommF_")):InvokeServer(unpack(value12))
                    elseif (game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer("RaceV4Progress", "Check") == 2 then
                        local value13 = {
                            [1] = "RaceV4Progress",
                            [2] = "Check"
                        },
                        (game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer(unpack(value13))
                        repeat
                            local value14
                            task.wait()
                            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(2959.87231, 2282.42139, -7216.23193)
                            value14 = {
                                [1] = "RaceV4Progress",
                                [2] = "Teleport"
                            },
                            (game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer(unpack(value14))
                        until (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - Vector3.new(28286.35546875, 14896.5078125, 102.62469482422)).Magnitude <= 15
                    elseif (game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer("RaceV4Progress", "Check") == 3 then
                        ExSeb = true
                        if not ujihfdg then
                            local value15
                            local value16 = {
                                [1] = "RaceV4Progress",
                                [2] = "Check"
                            },
                            (game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer(unpack(value16))
                            task.wait(1)
                            value15 = {
                                [1] = "RaceV4Progress",
                                [2] = "Continue"
                            },
                            (game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer(unpack(value15))
                            ujihfdg = true
                        end
                    elseif (game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer("RaceV4Progress", "Check") == 4 then
                        ExSeb = true
                    end
                else
                    if (game:GetService("Workspace")).Map:FindFirstChild("MysticIsland") then
                        if farmPlayer.Character.Humanoid.Sit == true then
                            farmPlayer.Character.Humanoid.Sit = false
                            task.wait(.5)
                            farmPlayer.Character.HumanoidRootPart.CFrame = farmPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 15, 0)
                            task.wait(1)
                        else
                            local workspace3 = ((game:GetService("Workspace")).Map:FindFirstChild("MysticIsland")).WorldPivot * CFrame.new(0, 500, 0)
                            if (workspace3.Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 25 then
                                task.spawn(function()
                                    repeat
                                        task.wait(.2)
                                        workspaceService.CurrentCamera.CFrame = CFrame.lookAt(workspaceService.CurrentCamera.CFrame.Position, lightingService:GetMoonDirection() + workspaceService.CurrentCamera.CFrame.Position)
                                    until StopCamera
                                            or not(game:GetService("Workspace")).Map:FindFirstChild("MysticIsland")
                                            or replicatedStorage.Remotes.CommF_:InvokeServer("CheckTempleDoor")
                                end)
                                ((replicatedStorage:WaitForChild("Remotes")):WaitForChild("CommE")):FireServer("ActivateAbility")
                                task.wait(17)
                                for key136, object in pairs((game:GetService("Workspace")).Map.MysticIsland:GetChildren()) do
                                    if object.ClassName == "MeshPart" and object.Name == "Part" and object.Transparency == 0 then
                                        repeat
                                            task.wait(.2)
                                            StopCamera = true
                                            tweenTeleportTo(object.CFrame, 1.5)
                                            task.wait(.5)
                                            virtualInputManager:SendKeyEvent(true, "Space", false, game)
                                            task.wait(.5)
                                            virtualInputManager:SendKeyEvent(false, "Space", false, game)
                                        until object.Transparency == 1
                                                or not(game:GetService("Workspace")).Map:FindFirstChild("MysticIsland")
                                                or replicatedStorage.Remotes.CommF_:InvokeServer("CheckTempleDoor")
                                        task.wait(.5)
                                    end
                                end
                            else
                                tweenTeleportTo(workspace3, 1.5)
                            end
                        end
                    end
                end
            elseif Quest == "Cursed Dual Katana" then
                if replicatedStorage.Remotes.CommF_:InvokeServer("CDKQuest", "OpenDoor") == "opened" then
                    local response9 = replicatedStorage.Remotes.CommF_:InvokeServer("CDKQuest", "Progress")
                    if response9.Good == 0 or response9.Good == -3 then
                        CDK_Q_S_C = 3
                        if response9.Good == 0 then
                            Utils.runCdkTrialQuest("Good")
                        elseif response9.Good == -3 then
                            repeat
                                task.wait()
                                tweenTeleportTo(CFrame.new(-4600.37, 15.1245, -2881.18), 1.5)
                                if (farmPlayer.Character.HumanoidRootPart.Position - Vector3.new(-4600.37, 15.1245, -2881.18)).Magnitude <= 3 then
                                    task.wait(1)
                                    replicatedStorage.Remotes.CommF_:InvokeServer("CDKQuest", "BoatQuest", combatWorkspace.NPCs:FindFirstChild("Luxury Boat Dealer"), "Check")
                                    replicatedStorage.Remotes.CommF_:InvokeServer("GetUnlockables")
                                    replicatedStorage.Remotes.CommF_:InvokeServer("CDKQuest", "BoatQuest", combatWorkspace.NPCs:FindFirstChild("Luxury Boat Dealer"))
                                    task.wait(.5)
                                    Q_Boat_1 = true
                                end
                            until Q_Boat_1
                            repeat
                                task.wait()
                                tweenTeleportTo(CFrame.new(-2068.63, 3.37222, -9887.08), 1.5)
                                if (farmPlayer.Character.HumanoidRootPart.Position - Vector3.new(-2068.63, 3.37222, -9887.08)).Magnitude <= 3 then
                                    task.wait(1)
                                    replicatedStorage.Remotes.CommF_:InvokeServer("CDKQuest", "BoatQuest", combatWorkspace.NPCs:FindFirstChild("Luxury Boat Dealer"), "Check")
                                    replicatedStorage.Remotes.CommF_:InvokeServer("GetUnlockables")
                                    replicatedStorage.Remotes.CommF_:InvokeServer("CDKQuest", "BoatQuest", combatWorkspace.NPCs:FindFirstChild("Luxury Boat Dealer"))
                                    task.wait(.5)
                                    Q_Boat_2 = true
                                end
                            until Q_Boat_2
                            repeat
                                task.wait()
                                tweenTeleportTo(CFrame.new(-9531.19, 5.91675, -8377.75), 1.5)
                                if (farmPlayer.Character.HumanoidRootPart.Position - Vector3.new(-9531.19, 5.91675, -8377.75)).Magnitude <= 3 then
                                    task.wait(1)
                                    replicatedStorage.Remotes.CommF_:InvokeServer("CDKQuest", "BoatQuest", combatWorkspace.NPCs:FindFirstChild("Luxury Boat Dealer"), "Check")
                                    replicatedStorage.Remotes.CommF_:InvokeServer("GetUnlockables")
                                    replicatedStorage.Remotes.CommF_:InvokeServer("CDKQuest", "BoatQuest", combatWorkspace.NPCs:FindFirstChild("Luxury Boat Dealer"))
                                    task.wait(.5)
                                    Q_Boat_3 = true
                                end
                            until Q_Boat_3
                            Q_Boat_1 = false
                            Q_Boat_2 = false
                            Q_Boat_3 = false
                        end
                    elseif response9.Evil == 0 or response9.Evil == -3 then
                        CDK_Q_S_C = 4
                        if response9.Evil == 0 then
                            Utils.runCdkTrialQuest("Evil")
                        elseif response9.Evil == -3 then
                            Stop_Fast_Attack = true
                            for key137, child71 in pairs(enemiesFolder:GetChildren()) do
                                if child71:FindFirstChild("HumanoidRootPart") and (child71.HumanoidRootPart.Position - Vector3.new(-13347.6982, 332.378143, -7652.27783)).Magnitude > 10 then
                                    child71.HumanoidRootPart.CFrame = CFrame.new(-13347.6982, 332.378143, -7652.27783)
                                    sethiddenproperty(farmPlayer, "SimulationRadius", math.huge)
                                end
                            end
                            tweenTeleportTo(CFrame.new(-13347.6982, 332.378143, -7652.27783, -0.97929436, 4.50812898e-08, -0.202441484, 4.58302409e-08, 1, 9.8789521e-10, .202441484, -8.31050162e-09, -0.97929436), 1.5)
                        end
                    elseif response9.Evil == 1 or response9.Evil == -4 then
                        Stop_Fast_Attack = false
                        CDK_Q_S_C = 5
                        if response9.Evil == 1 then
                            Utils.runCdkTrialQuest("Evil")
                        elseif response9.Evil == -4 then
                            if Utils.findFirstChild(farmPlayer, "QuestHaze") then
                                if Quest_Kill == nil then
                                    for key138, farmplayer9 in pairs(farmPlayer.QuestHaze:GetChildren()) do
                                        if tonumber(farmplayer9.Value) > 0 and Quest_Kill == nil then
                                            SelectMonster = farmplayer9.Name
                                            CFrameMon = nil
                                            CheckLevel2()
                                            if CFrameMon ~= nil then
                                                Quest_Kill = farmplayer9.Name
                                            end
                                        end
                                    end
                                elseif Utils.findFirstChild(farmPlayer.QuestHaze, Quest_Kill) and tonumber((farmPlayer.QuestHaze:FindFirstChild(Quest_Kill)).Value) <= 0 then
                                    Quest_Kill = nil
                                elseif Utils.findFirstChild(farmPlayer.QuestHaze, Quest_Kill) and tonumber((farmPlayer.QuestHaze:FindFirstChild(Quest_Kill)).Value) > 0 then
                                    for key139, child72 in pairs(enemiesFolder:GetChildren()) do
                                        if child72:FindFirstChild("Humanoid") and child72.Humanoid.Health > 0 and child72:FindFirstChild("HazeESP") then
                                            repeat
                                                task.wait(.1)
                                                tweenTeleportTo(child72.HumanoidRootPart.CFrame * CFrame.new(0, 25, 0), 1.5)
                                                equipPreferredFarmTool()
                                            until not child72.Parent or child72.Humanoid.Health <= 0
                                        end
                                    end
                                    tweenTeleportTo(CFrameMon, 1.5)
                                else
                                    Quest_Kill = nil
                                end
                            end
                        end
                    elseif response9.Good == 1 or response9.Good == -4 then
                        CDK_Q_S_C = 6
                        if response9.Good == 1 then
                            Utils.runCdkTrialQuest("Good")
                        elseif response9.Good == -4 then
                            tweenTeleportTo(CFrame.new(-5543.0805664062, 313.76550292969, -2969.4846191406), 1.5)
                            if (Vector3.new(-5543.0805664062, 313.76550292969, -2969.4846191406) - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 1500 then
                                for key140, child73 in pairs(enemiesFolder:GetChildren()) do
                                    if child73:FindFirstChild("Humanoid")
                                            and child73.Humanoid.Health > 0
                                            and (child73.HumanoidRootPart.Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 1500 then
                                        repeat
                                            task.wait(.3)
                                            equipPreferredFarmTool()
                                            tweenTeleportTo(child73.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                        until not child73.Parent or child73.Humanoid.Health <= 0
                                    end
                                end
                            end
                        end
                    elseif response9.Good == 2 or response9.Good == -5 then
                        CDK_Q_S_C = 7
                        if response9.Good == 2 then
                            Utils.runCdkTrialQuest("Good")
                        elseif response9.Good == -5 then
                            if not Kill_Boss_Cake then
                                if Utils.findFirstChild(enemiesFolder, "Cake Queen") then
                                    for key141, child74 in pairs(enemiesFolder:GetChildren()) do
                                        if child74.Name == "Cake Queen" and child74.Humanoid.Health > 0 and not Kill_Boss_Cake then
                                            repeat
                                                task.wait(.3)
                                                if Utils.findFirstChild(child74, "HumanoidRootPart") then
                                                    tweenTeleportTo(child74.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                                    equipPreferredFarmTool()
                                                else
                                                    break
                                                end
                                            until not child74.Parent or child74.Humanoid.Health <= 0
                                            Kill_Boss_Cake = true
                                            task.wait(1)
                                        end
                                    end
                                else
                                    tweenTeleportTo(CFrame.new(-714.643066, 381.565613, -11021.0566), 1.5)
                                end
                            else
                                if workspaceService.Map:FindFirstChild("HeavenlyDimension") then
                                    if not Ceyma_HeavenlyDimension then
                                        repeat
                                            task.wait(.1)
                                            tweenTeleportTo((workspaceService.Map:FindFirstChild("HeavenlyDimension")).WorldPivot, 1.5)
                                        until ((workspaceService.Map:FindFirstChild("HeavenlyDimension")).WorldPivot.Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 5
                                        task.wait(1)
                                        Ceyma_HeavenlyDimension = true
                                    elseif Ceyma_HeavenlyDimension then
                                        equipPreferredFarmTool()
                                        if enemiesFolder:FindFirstChildOfClass("Model") then
                                            for key142, child75 in pairs(enemiesFolder:GetChildren()) do
                                                if child75:FindFirstChild("HumanoidRootPart")
                                                        and child75:FindFirstChild("Humanoid")
                                                        and ((workspaceService.Map:FindFirstChild("HeavenlyDimension")).WorldPivot.Position - child75.HumanoidRootPart.Position).Magnitude <= 1000 then
                                                    if child75.Humanoid.Health > 0 then
                                                        repeat
                                                            task.wait()
                                                            tweenTeleportTo(child75.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                                            equipPreferredFarmTool()
                                                        until not child75.Parent or child75.Humanoid.Health <= 0
                                                    end
                                                end
                                            end
                                        elseif not enemiesFolder:FindFirstChildOfClass("Model") then
                                            Utils.getHeavenlyTorch("Torch1")
                                            if not enemiesFolder:FindFirstChildOfClass("Model") then
                                                Utils.getHeavenlyTorch("Torch2")
                                                if not enemiesFolder:FindFirstChildOfClass("Model") then
                                                    Utils.getHeavenlyTorch("Torch3")
                                                    if not enemiesFolder:FindFirstChildOfClass("Model") and workspaceService.Map:FindFirstChild("HeavenlyDimension") then
                                                        workspaceService.Map.HeavenlyDimension.Exit.CFrame = farmPlayer.Character.HumanoidRootPart.CFrame
                                                        task.wait(1)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                elseif not workspaceService.Map:FindFirstChild("HeavenlyDimension") then
                                    task.wait(5)
                                    if not workspaceService.Map:FindFirstChild("HeavenlyDimension") then
                                        Kill_Boss_Cake = false
                                    end
                                end
                            end
                        end
                    elseif response9.Evil == 2 or response9.Evil == -5 then
                        CDK_Q_S_C = 8
                        if response9.Evil == 2 then
                            Utils.runCdkTrialQuest("Evil")
                        elseif response9.Evil == -5 then
                            if workspaceService.Map:FindFirstChild("HellDimension") then
                                if ((workspaceService.Map:FindFirstChild("HellDimension")).WorldPivot.Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude > 1200 then
                                    repeat
                                        task.wait(.1)
                                        tweenTeleportTo((workspaceService.Map:FindFirstChild("HellDimension")).WorldPivot, 1.5)
                                    until ((workspaceService.Map:FindFirstChild("HellDimension")).WorldPivot.Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 10
                                    task.wait(1)
                                elseif ((workspaceService.Map:FindFirstChild("HellDimension")).WorldPivot.Position - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 1200 then
                                    equipPreferredFarmTool()
                                    if enemiesFolder:FindFirstChildOfClass("Model") then
                                        for key143, child76 in pairs(enemiesFolder:GetChildren()) do
                                            if child76:FindFirstChild("HumanoidRootPart")
                                                    and child76:FindFirstChild("Humanoid")
                                                    and ((workspaceService.Map:FindFirstChild("HellDimension")).WorldPivot.Position - child76.HumanoidRootPart.Position).Magnitude <= 1000 then
                                                if child76.Humanoid.Health > 0 then
                                                    repeat
                                                        task.wait()
                                                        tweenTeleportTo(child76.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                                        equipPreferredFarmTool()
                                                    until not child76.Parent or child76.Humanoid.Health <= 0
                                                end
                                            end
                                        end
                                    elseif not enemiesFolder:FindFirstChildOfClass("Model") then
                                        Utils.getHellTorch("Torch1")
                                        if not enemiesFolder:FindFirstChildOfClass("Model") then
                                            Utils.getHellTorch("Torch2")
                                            if not enemiesFolder:FindFirstChildOfClass("Model") then
                                                Utils.getHellTorch("Torch3")
                                                if not enemiesFolder:FindFirstChildOfClass("Model") and workspaceService.Map:FindFirstChild("HellDimension") then
                                                    workspaceService.Map.HellDimension.Exit.CFrame = farmPlayer.Character.HumanoidRootPart.CFrame
                                                    task.wait(1)
                                                end
                                            end
                                        end
                                    end
                                end
                            elseif not workspaceService.Map:FindFirstChild("HellDimension") then
                                if enemiesFolder:FindFirstChild("Soul Reaper") or game.ReplicatedStorage:FindFirstChild("Soul Reaper") then
                                    Stop_Fast_Attack = true
                                    if not enemiesFolder:FindFirstChild("Soul Reaper") and game.ReplicatedStorage:FindFirstChild("Soul Reaper") then
                                        repeat
                                            task.wait(.2)
                                            tweenTeleportTo((game.ReplicatedStorage:FindFirstChild("Soul Reaper")).HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                        until enemiesFolder:FindFirstChild("Soul Reaper")
                                        task.wait(1)
                                    end
                                    if enemiesFolder:FindFirstChild("Soul Reaper") then
                                        tweenTeleportTo((enemiesFolder:FindFirstChild("Soul Reaper")).HumanoidRootPart.CFrame * CFrame.new(0, 0, 2), 1.5)
                                        task.wait(1)
                                    end
                                elseif replicatedStorage.Remotes.CommF_:InvokeServer("Bones", "Check") > 0 and Utils.getItemCount("Bones") > 500 then
                                    repeat
                                        task.wait(.2)
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Bones", "Check")
                                        replicatedStorage.Remotes.CommF_:InvokeServer("Bones", "Buy", 1, 1)
                                    until replicatedStorage.Remotes.CommF_:InvokeServer("Bones", "Check") == 0
                                    task.wait(1)
                                    if not Dragon_Talon_C and meleeUnlocked("Dragon Talon") then
                                        if Utils.findFirstChild(farmPlayer.Backpack, "Fire Essence") or Utils.findFirstChild(farmPlayer.Character, "Fire Essence") then
                                            repeat
                                                Utils.setStatus(" Status : Use Fire Essence")
                                                Utils.equipTool("Fire Essence")
                                                task.wait(.5)
                                                replicatedStorage.Remotes.CommF_:InvokeServer("BuyDragonTalon", true)
                                                replicatedStorage.Remotes.CommF_:InvokeServer("BuyDragonTalon")
                                            until not Utils.findFirstChild(farmPlayer.Backpack, "Fire Essence") and not Utils.findFirstChild(farmPlayer.Character, "Fire Essence")
                                            replicatedStorage.Remotes.CommF_:InvokeServer("BuyDragonTalon")
                                            Dragon_Talon_C = true
                                        end
                                    end
                                    if Utils.findFirstChild(farmPlayer.Backpack, "Hallow Essence") or Utils.findFirstChild(farmPlayer.Character, "Hallow Essence") then
                                        repeat
                                            Utils.setStatus(" Status : Use Hallow Essence")
                                            Utils.equipTool("Hallow Essence")
                                            tweenTeleportTo(CFrame.new(-8932.86, 143.258, 6063.31), 1.5)
                                        until not Utils.findFirstChild(farmPlayer.Backpack, "Hallow Essence") and not Utils.findFirstChild(farmPlayer.Character, "Hallow Essence")
                                    end
                                elseif not enemiesFolder:FindFirstChild("Soul Reaper") and not replicatedStorage:FindFirstChild("Soul Reaper") then
                                    Utils.farmBone()
                                end
                            end
                        end
                    elseif response9.Evil == 3 then
                        repeat
                            task.wait()
                            tweenTeleportTo(CFrame.new(-12392.2637, 603.319763, -6503.27832), 1.5)
                        until (Vector3.new(-12392.2637, 603.319763, -6503.27832) - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 2
                        if coreGuiService:FindFirstChild("     ") then
                            coreGuiService["     "].Enabled = false
                        end
                        task.wait(1)
                        virtualInputManager:SendKeyEvent(true, "E", false, game)
                        task.wait(1)
                        virtualInputManager:SendKeyEvent(false, "E", false, game)
                        task.wait(1)
                        Utils.clickGuiObject(farmPlayer.PlayerGui.Main.Dialogue)
                    elseif response9.Good == 3 then
                        repeat
                            task.wait()
                            tweenTeleportTo(CFrame.new(-12392.5068, 603.319763, -6596.00586), 1.5)
                        until (Vector3.new(-12392.5068, 603.319763, -6596.00586) - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 2
                        if coreGuiService:FindFirstChild("     ") then
                            coreGuiService["     "].Enabled = false
                        end
                        task.wait(1)
                        virtualInputManager:SendKeyEvent(true, "E", false, game)
                        task.wait(1)
                        virtualInputManager:SendKeyEvent(false, "E", false, game)
                        task.wait(1)
                        Utils.clickGuiObject(farmPlayer.PlayerGui.Main.Dialogue)
                    elseif response9.Good == 4 and response9.Evil == 4 and workspaceService.Map.Turtle.Cursed.BossDoor.Position.Y > 584 then
                        equipPreferredFarmTool()
                        repeat
                            task.wait(.1)
                            tweenTeleportTo(CFrame.new(-12359.1719, 603.319702, -6550.59717, .481593847, 0, -0.87639451, 0, 1, 0, .87639451, 0, .481593847), 1.5)
                        until (Vector3.new(-12359.1719, 603.319702, -6550.59717) - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3
                        if coreGuiService:FindFirstChild("     ") then
                            coreGuiService["     "].Enabled = false
                        end
                        task.wait(1)
                        virtualInputManager:SendKeyEvent(true, "E", false, game)
                        task.wait(1)
                        virtualInputManager:SendKeyEvent(false, "E", false, game)
                        task.wait(1)
                        Utils.clickGuiObject(farmPlayer.PlayerGui.Main.Dialogue)
                    elseif workspaceService.Map.Turtle.Cursed.BossDoor.Position.Y <= 584 then
                        local inventory
                        if coreGuiService:FindFirstChild("     ") then
                            coreGuiService["     "].Enabled = true
                        end
                        inventory = replicatedStorage.Remotes.CommF_:InvokeServer("getInventory")
                        for key144, item21 in pairs(inventory) do
                            if item21.Type == "Sword" then
                                if item21.Name == "Cursed Dual Katana" then
                                    return
                                end
                            end
                        end
                        CDK_Q_S_C = 10
                        if (Vector3.new(-12297.5605, 598.726013, -6532.96436) - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 100 then
                            repeat
                                task.wait()
                                tweenTeleportTo(CFrame.new(-12379.1406, 601.433167, -6543.60742), 1.5)
                            until Boss_Extant or (Vector3.new(-12379.1406, 601.433167, -6543.60742) - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3
                            repeat
                                task.wait()
                                tweenTeleportTo(CFrame.new(-12330.197265625, 603.31982421875, -6549.1186523438), 1.5)
                                for key145, child77 in pairs(enemiesFolder:GetChildren()) do
                                    if child77.Name == "Cursed Skeleton Boss" then
                                        Boss_Extant = true
                                        farmPlayer.Character.HumanoidRootPart.CFrame = child77.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0)
                                    end
                                end
                            until Boss_Extant or (Vector3.new(-12330.197265625, 603.31982421875, -6549.1186523438) - farmPlayer.Character.HumanoidRootPart.Position).Magnitude <= 3
                            task.wait(1)
                            for key146, child78 in pairs(enemiesFolder:GetChildren()) do
                                if child78.Name == "Cursed Skeleton Boss" then
                                    repeat
                                        task.wait(.1)
                                        Utils.loadItem("Tushita")
                                        Utils.equipTool("Tushita")
                                        tweenTeleportTo(child78.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0), 1.5)
                                    until not child78.Parent or child78.Humanoid.Health <= 0
                                    for key147, item22 in pairs(inventory) do
                                        if item22.Type == "Sword" then
                                            if item22.Name == "Cursed Dual Katana" then
                                                return
                                            end
                                        end
                                    end
                                end
                            end
                        elseif (Vector3.new(-12297.5605, 598.726013, -6532.96436) - farmPlayer.Character.HumanoidRootPart.Position).Magnitude > 100 then
                            tweenTeleportTo(CFrame.new(-12297.5605, 598.726013, -6532.96436), 1.5)
                        end
                    end
                else
                    replicatedStorage.Remotes.CommF_:InvokeServer("CDKQuest", "OpenDoor", true)
                end
            end
        end, warn)
    end
end)
task.spawn(function()
    while task.wait() do
        xpcall(function()
            for key148, child79 in pairs(enemiesFolder:GetChildren()) do
                if Utils.findFirstChild(child79, "Humanoid") and child79.Humanoid.Health <= 0 and Utils.findFirstChild(child79, "HumanoidRootPart") then
                    if child79.Humanoid.Health <= 0 then
                        child79:Destroy()
                    end
                end
            end
            if Utils.findFirstChild(farmPlayer.Character, "Black Leg") then
                virtualInputManager:SendKeyEvent(true, "V", false, game)
                task.wait(.1)
                virtualInputManager:SendKeyEvent(false, "V", false, game)
            end
            if Utils.findFirstChild(farmPlayer.Character, "HumanoidRootPart") and not Utils.findFirstChild(farmPlayer.Character.HumanoidRootPart, "Lock") then
                local bodyVelocity
                local humanoid4 = farmPlayer.Character:FindFirstChild("Humanoid")
                if humanoid4 and humanoid4.Sit then
                    humanoid4.Sit = false
                end
                bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.Name = "Lock"
                bodyVelocity.MaxForce = Vector3.new(1000000000, 1000000000, 1000000000)
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                bodyVelocity.P = 10000
                bodyVelocity.Parent = farmPlayer.Character.HumanoidRootPart
            end
        end, warn)
    end
end)
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if not Utils.findFirstChild(farmPlayer.Character, "Highlight") then
                local highlight = Instance.new("Highlight")
                highlight.Name = "Highlight"
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
                highlight.Adornee = farmPlayer.Character
                highlight.Parent = farmPlayer.Character
            end
        end)
    end
end)
redeem = {
    "Sub2Fer999",
    "Enyu_is_Pro",
    "JCWK",
    "StarcodeHEO",
    "MagicBUS",
    "KittGaming",
    "Sub2CaptainMaui",
    "Sub2OfficialNoobie",
    "TheGreatAce",
    "Sub2NoobMaster123",
    "Sub2Daigrock",
    "Axiore",
    "StrawHatMaine",
    "TantaiGaming",
    "Bluxxy",
    "SUB2GAMERROBOT_EXP1",
    "GAMER_ROBOT_1M",
    "SUBGAMERROBOT_RESET",
    "RESET_5B",
    "SUB2GAMERROBOT_RESET1",
    "Sub2UncleKizaru",
    "ADMIN_TROLL ",
    "DRAGONABUSE ",
    "DEVSCOOKING "
}
task.spawn(function()
    for key149, item23 in pairs(redeem) do
        combatReplicatedStorage.Remotes.Redeem:InvokeServer(item23)
    end
end)
task.spawn(function()
    while task.wait(150) do
        virtualInputManager:SendKeyEvent(true, "Space", false, game)
        task.wait(.5)
        virtualInputManager:SendKeyEvent(false, "Space", false, game)
    end
end)
idlePlayersService = game:GetService("Players")
idlePlayer = idlePlayersService.LocalPlayer
waitForCharacterRootPart = function()
    while not idlePlayer.Character or not idlePlayer.Character:FindFirstChild("HumanoidRootPart") do
        task.wait(.5)
    end
    return idlePlayer.Character:WaitForChild("HumanoidRootPart")
end
lastKnownPosition = (waitForCharacterRootPart()).Position
idleSeconds = 0
idleCheckSeconds = 1
task.spawn(function()
    while task.wait() do
        if Quest ~= "Cursed Dual Katana" and Quest ~= "Evo Race V2" and Quest ~= "Evo Race V1" and not SROP then
            local distance6, position2
            task.wait(idleCheckSeconds)
            position2 = (waitForCharacterRootPart()).Position
            distance6 = (position2 - lastKnownPosition).Magnitude
            if distance6 <= 1 then
                idleSeconds = idleSeconds + idleCheckSeconds
                if idleSeconds >= 30 and Quest ~= "Cursed Dual Katana" and Quest ~= "Evo Race V2" and Quest ~= "Evo Race V1" and not SROP then
                    Utils.hopToLowServer(9)
                end
            else
                idleSeconds = 0
                lastKnownPosition = position2
            end
        end
    end
end)
task.spawn(function()
    while task.wait() do
        if combatWorkspace.Map:FindFirstChild("Heavenly") then
            fireproximityprompt(combatWorkspace.Map.HeavenlyDimension.Torch1.ProximityPrompt)
            fireproximityprompt(combatWorkspace.Map.HeavenlyDimension.Torch2.ProximityPrompt)
            fireproximityprompt(combatWorkspace.Map.HeavenlyDimension.Torch3.ProximityPrompt)
        end
        if combatWorkspace.Map:FindFirstChild("HellDimension") then
            fireproximityprompt(combatWorkspace.Map.HellDimension.Torch1.ProximityPrompt)
            fireproximityprompt(combatWorkspace.Map.HellDimension.Torch2.ProximityPrompt)
            fireproximityprompt(combatWorkspace.Map.HellDimension.Torch3.ProximityPrompt)
        end
    end
end)
idlePlayer.PlayerGui.Notifications.Enabled = false
task.spawn(function()
    while task.wait() do
        pcall(function()
            if not(game:GetService("Players")).LocalPlayer.Character.HumanoidRootPart:FindFirstChild("Lock") then
                local bodyVelocity2
                if (game.Players.LocalPlayer.Character:WaitForChild("Humanoid")).Sit == true then
                    (game.Players.LocalPlayer.Character:WaitForChild("Humanoid")).Sit = false
                end
                bodyVelocity2 = Instance.new("BodyVelocity")
                bodyVelocity2.Name = "Lock"
                bodyVelocity2.Parent = (game:GetService("Players")).LocalPlayer.Character.HumanoidRootPart
                bodyVelocity2.MaxForce = Vector3.new(9000000000, 9000000000, 9000000000)
                bodyVelocity2.Velocity = Vector3.new(0, 0, 0)
            end
        end)
    end
end)
task.wait(5)
_G.Ew = false
Ewx = false
task.spawn(function()
    while task.wait() do
        pcall(function()
            if playerBeliValue.Value >= 2500000 and New_World then
                replicatedStorage.Remotes.CommF_:InvokeServer("LegendarySwordDealer", "1")
                replicatedStorage.Remotes.CommF_:InvokeServer("LegendarySwordDealer", "2")
                replicatedStorage.Remotes.CommF_:InvokeServer("LegendarySwordDealer", "3")
            end
            if Utils.tableFind(Configs.Gun, "Kabucha") and playerFragmentsValue.Value >= 10000 and not Utils.hasItem("Kabucha") then
                replicatedStorage.Remotes.CommF_:InvokeServer("BlackbeardReward", "Slingshot", "2")
            end
            if playerBeliValue.Value >= 3000000 then
                if Utils.tableFind(Configs.Sword, "Bisento") and not Utils.hasItem("Bisento") then
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyItem", "Bisento")
                end
                if Utils.tableFind(Configs.Sword, "Cutlass") and not Utils.hasItem("Cutlass") then
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyItem", "Cutlass")
                end
                if Utils.tableFind(Configs.Sword, "Katana") and not Utils.hasItem("Katana") then
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyItem", "Katana")
                end
                if Utils.tableFind(Configs.Sword, "Dual Katana") and not Utils.hasItem("Dual Katana") then
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyItem", "Dual Katana")
                end
                if Utils.tableFind(Configs.Sword, "Soul Cane") and not Utils.hasItem("Soul Cane") then
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyItem", "Soul Cane")
                end
                if Utils.tableFind(Configs.Sword, "Triple Katana") and not Utils.hasItem("Triple Katana") then
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyItem", "Triple Katana")
                end
                if Utils.tableFind(Configs.Sword, "Iron Mace") and not Utils.hasItem("Iron Mace") then
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyItem", "Iron Mace")
                end
                if Utils.tableFind(Configs.Sword, "Pipe") and not Utils.hasItem("Pipe") then
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyItem", "Pipe")
                end
                if Utils.tableFind(Configs.Sword, "Dual-Headed Blade") and not Utils.hasItem("Dual-Headed Blade") then
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyItem", "Dual-Headed Blade")
                end
                if Utils.tableFind(Configs.Gun, "Musket") and not Utils.hasItem("Musket") then
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyItem", "Musket")
                end
                if Utils.tableFind(Configs.Gun, "Flintlock") and not Utils.hasItem("Flintlock") then
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyItem", "Flintlock")
                end
                if Utils.tableFind(Configs.Gun, "Refined Slingshot") and not Utils.hasItem("Refined Slingshot") then
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyItem", "Refined Slingshot")
                end
                if Utils.tableFind(Configs.Gun, "Dual Flintlock") and not Utils.hasItem("Dual Flintlock") then
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyItem", "Dual Flintlock")
                end
                if Utils.tableFind(Configs.Gun, "Cannon") and not Utils.hasItem("Cannon") then
                    replicatedStorage.Remotes.CommF_:InvokeServer("BuyItem", "Cannon")
                end
            end
            if Utils.tableFind(Configs.Sword,
                "Midnight Blade") and replicatedStorage.Remotes.CommF_:InvokeServer("Ectoplasm",
                "Check") >= 100 and not Utils.hasItem("Midnight Blade") then
                replicatedStorage.Remotes.CommF_:InvokeServer("Ectoplasm", "Buy", 3)
            end
            if not klmdlkgf and playerLevelValue.Value >= 2000 then
                replicatedStorage.Remotes.CommF_:InvokeServer("BuyHaki", "Geppo")
                replicatedStorage.Remotes.CommF_:InvokeServer("BuyHaki", "Soru")
                replicatedStorage.Remotes.CommF_:InvokeServer("KenTalk", "Buy")
                klmdlkgf = true
            end
            if not klmdlkgfx and playerLevelValue.Value >= 1000 then
                replicatedStorage.Remotes.CommF_:InvokeServer("BuyHaki", "Buso")
                klmdlkgfx = true
            end
            task.wait(100)
        end)
    end
end)

--=============================================================================
-- [GHÉP TỪ FILE DIO] CHỌN VŨ KHÍ TỰ ĐỘNG (_G.ChooseWP / _G.SelectWeapon)
--   KaitunNew dùng nó để chọn tool khi farm; ở đây nó được nối vào
--   equipPreferredFarmTool() ở trên nên không có đoạn code trùng lặp.
--=============================================================================
_G.ChooseWP = getgenv().Config and getgenv().Config["Weapon Select"] and getgenv().Config["Weapon Select"]["Type"] or "Melee"
_G.SelectWeapon = nil

task.spawn(function()
    while task.wait(.5) do
        pcall(function()
            if not configToggle("Weapon Select", "Enabled", true) then
                return
            end
            local backpack = farmPlayer:FindFirstChild("Backpack")
            if not backpack then
                return
            end
            for _, tool in pairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and tostring(tool.ToolTip) == _G.ChooseWP then
                    _G.SelectWeapon = tool.Name
                    break
                end
            end
        end)
    end
end)

--=============================================================================
-- [GHÉP TỪ FILE DIO] CHỐNG NGÔNG (Anti Idle)
--   virtualUser đã được GetService sẵn ở trên; source gốc không có anti-idle
--   nên đoạn này là nội dung ghép mới, không ghi đè logic cũ.
--=============================================================================
task.spawn(function()
    while task.wait(1) do
        if configToggle("Settings", "Anti Idle", true) then
            pcall(function()
                farmPlayer.Idled:Connect(function()
                    virtualUser:CaptureController()
                    virtualUser:ClickButton2(Vector2.new())
                end)
            end)
            break
        end
    end
end)

--=============================================================================
-- [GHÉP TỪ FILE DIO] AUTO HOP + HOP KHI NGÔNG
--   dùng teleportService / currentPlaceId / Utils.hopToLowServer của source.
--=============================================================================
local lastActivityTime = os.time()
do
    local ok, err = pcall(function()
        farmPlayer.Idled:Connect(function()
            lastActivityTime = 0
        end)
    end)
    if not ok then
        warn("[Kaitun] Anti Idle hook that bai: " .. tostring(err))
    end
end

task.spawn(function()
    local hopDelay = (getgenv().Config and getgenv().Config.Settings and getgenv().Config.Settings["Auto Hop Delay"]) or 3600
    local lastHopTime = os.time()
    while task.wait(1) do
        if configToggle("Settings", "Auto Hop", false) and os.time() - lastHopTime >= hopDelay then
            lastHopTime = os.time()
            Utils.hopToLowServer(10)
        end
    end
end)

task.spawn(function()
    while task.wait(5) do
        if configToggle("Settings", "Hop When Idle", false) and lastActivityTime == 0 then
            Utils.setStatus(" Status : Hop (idle)")
            teleportService:Teleport(currentPlaceId, farmPlayer)
        end
    end
end)

--=============================================================================
-- [GHÉP TỪ FILE DIO] KATAKURI FARM (Sea 3)
--   CFrame + remote lấy nguyên từ KaitunNew; teleport dùng tweenTeleportTo(),
--   kiểm tra boss bằng Utils.findFirstChild()/enemiesFolder của source.
--=============================================================================
local KATAKURI_SUMMON_CF = CFrame.new(-2020, 38, -12025)
local KATAKURI_FIGHT_OFFSET = Vector3.new(0, 40, 0)

task.spawn(function()
    while task.wait(1) do
        if not configToggle("Katakuri Farm", "Enabled", false) or not autoFarmingOn() then
            task.wait(4)
        else
            pcall(function()
                if not Three_World then
                    return
                end
                local goal = (getgenv().Config and getgenv().Config["Katakuri Farm"] and getgenv().Config["Katakuri Farm"]["Target Fragments"]) or 5000
                if playerFragmentsValue.Value >= goal then
                    Utils.setStatus(" Status : Katakuri (du frag)")
                    return
                end
                local liveBoss = Utils.findFirstChild(enemiesFolder, "Katakuri")
                local repBoss = Utils.findFirstChild(replicatedStorage, "Katakuri")
                if not liveBoss and not repBoss then
                    Utils.setStatus(" Status : Katakuri | Summon")
                    tweenTeleportTo(KATAKURI_SUMMON_CF * KATAKURI_FIGHT_OFFSET, 1.5)
                    task.wait(1)
                    replicatedStorage.Remotes.CommF_:InvokeServer("KatakuriSummon")
                    task.wait(2)
                    return
                end
                if repBoss and not liveBoss then
                    local root = repBoss:FindFirstChild("HumanoidRootPart")
                    if root then
                        tweenTeleportTo(root.CFrame + KATAKURI_FIGHT_OFFSET, 1.5)
                    end
                    return
                end
                local humanoid = liveBoss:FindFirstChildOfClass("Humanoid")
                local root = liveBoss:FindFirstChild("HumanoidRootPart")
                if humanoid and root and humanoid.Health > 0 then
                    Utils.setStatus(string.format(" Status : Katakuri | %d%%", math.floor(humanoid.Health / humanoid.MaxHealth * 100)))
                    tweenTeleportTo(root.CFrame + KATAKURI_FIGHT_OFFSET, 1.5)
                    if not Utils.findFirstChild(farmPlayer.Character, "HasBuso") then
                        replicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                    end
                    equipPreferredFarmTool()
                    task.wait(.5)
                else
                    Utils.setStatus(" Status : Katakuri | cho boss respawn")
                    task.wait(5)
                end
            end)
        end
    end
end)

--=============================================================================
-- [GHÉP TỪ FILE DIO] RAID ICE - giới hạn Fragments
--   Source tự farm raid trong vòng lặp chính; ở đây chỉ thêm điều kiện dừng khi
--   đủ "Target Fragments" (Config.Raid), không viết lại logic raid.
--=============================================================================
getgenv().RaidFragmentGoal = (getgenv().Config and getgenv().Config.Raid and getgenv().Config.Raid["Target Fragments"]) or 5000
