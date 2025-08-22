-- @ScriptType: ModuleScript
-- CoinCollectorModule - COMPLETE FIXED VERSION with setupGrabItem function
-- Place this ModuleScript in ReplicatedStorage or ServerStorage
--finally it sync

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")
local DataStoreService = game:GetService("DataStoreService")

local CoinCollectorModule = {}

-- Game Settings
CoinCollectorModule.COIN_SPAWN_RATE = 2 -- seconds between coin spawns
CoinCollectorModule.MAX_COINS = 20 -- maximum coins on map at once
CoinCollectorModule.COIN_VALUE = 10 -- points per coin
CoinCollectorModule.MAGIC_KEY_MULTIPLIER = 3 -- x3 points for magic key
CoinCollectorModule.MAGIC_KEY_SPAWN_CHANCE = 0.0100 -- 1% chance (0.01)
CoinCollectorModule.GAME_DURATION = 120 -- 120 seconds
CoinCollectorModule.MAP_SIZE = 100 -- size of the play area
CoinCollectorModule.GAME_LABEL = "MOONCAKE" -- Default to MOONCAKE
CoinCollectorModule.INSTRUCTION_SEC = 5 -- seconds for instructions

-- DataStore Setup
local playerDataStore = DataStoreService:GetDataStore("CoinCollectorData")
local leaderboardStore = DataStoreService:GetOrderedDataStore("CoinCollectorLeaderboard")

-- Game State (will be managed by main script)
CoinCollectorModule.gameActive = false
CoinCollectorModule.gameTimeLeft = CoinCollectorModule.GAME_DURATION
CoinCollectorModule.coins = {} -- Tracks ALL collectible items (mooncakes + magic keys)
CoinCollectorModule.playerScores = {}
CoinCollectorModule.playerData = {} -- Store persistent player data
CoinCollectorModule.gameTimerConnection = nil
CoinCollectorModule.coinSpawnerConnection = nil
CoinCollectorModule.grabItem = CoinCollectorModule.GAME_LABEL

-- DataStore Functions
function CoinCollectorModule.savePlayerData(player)
	if not CoinCollectorModule.playerData[player] then
		return
	end

	local success, error = pcall(function()
		local dataToSave = {
			totalScore = CoinCollectorModule.playerData[player].totalScore or 0,
			gamesPlayed = CoinCollectorModule.playerData[player].gamesPlayed or 0,
			coinsCollected = CoinCollectorModule.playerData[player].coinsCollected or 0,
			bestScore = CoinCollectorModule.playerData[player].bestScore or 0,
			magicKeysFound = CoinCollectorModule.playerData[player].magicKeysFound or 0,
			lastPlayed = os.time()
		}
		playerDataStore:SetAsync(player.UserId, dataToSave)
	end)

	if not success then
		warn("Failed to save data for " .. player.Name .. ": " .. tostring(error))
	end
end

function CoinCollectorModule.loadPlayerData(player)
	local success, data = pcall(function()
		return playerDataStore:GetAsync(player.UserId)
	end)

	if success and data then
		CoinCollectorModule.playerData[player] = {
			totalScore = data.totalScore or 0,
			gamesPlayed = data.gamesPlayed or 0,
			coinsCollected = data.coinsCollected or 0,
			bestScore = data.bestScore or 0,
			magicKeysFound = data.magicKeysFound or 0,
			lastPlayed = data.lastPlayed or 0
		}
	else
		-- New player or failed to load
		CoinCollectorModule.playerData[player] = {
			totalScore = 0,
			gamesPlayed = 0,
			coinsCollected = 0,
			bestScore = 0,
			magicKeysFound = 0,
			lastPlayed = 0
		}
		if not success then
			warn("Failed to load data for " .. player.Name .. ": " .. tostring(data))
		end
	end
end

function CoinCollectorModule.updateLeaderboard(player, score)
	local success, error = pcall(function()
		leaderboardStore:SetAsync(player.UserId, score)
	end)

	if not success then
		warn("Failed to update leaderboard for " .. player.Name .. ": " .. tostring(error))
	end
end

function CoinCollectorModule.getTopPlayers(count)
	local success, pages = pcall(function()
		return leaderboardStore:GetSortedAsync(false, count or 10)
	end)

	if success then
		local topPlayers = {}
		local currentPage = pages:GetCurrentPage()

		for rank, data in ipairs(currentPage) do
			local userId = data.key
			local score = data.value

			-- Get player name
			local playerName = "Unknown"
			local nameSuccess, name = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)

			if nameSuccess then
				playerName = name
			end

			table.insert(topPlayers, {
				rank = rank,
				name = playerName,
				score = score,
				userId = userId
			})
		end

		return topPlayers
	else
		warn("Failed to get leaderboard: " .. tostring(pages))
		return {}
	end
end

-- Show x3 points effect when magic key is collected
function CoinCollectorModule.showMultiplierEffect(player, points)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end

	-- Create BillboardGui for the multiplier effect
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(4, 0, 2, 0)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.Parent = character.HumanoidRootPart

	-- Main frame for the effect
	local effectFrame = Instance.new("Frame")
	effectFrame.Size = UDim2.new(1, 0, 1, 0)
	effectFrame.BackgroundTransparency = 1
	effectFrame.Parent = billboardGui

	-- X3 multiplier text
	local multiplierLabel = Instance.new("TextLabel")
	multiplierLabel.Size = UDim2.new(1, 0, 0.6, 0)
	multiplierLabel.Position = UDim2.new(0, 0, 0, 0)
	multiplierLabel.BackgroundTransparency = 1
	multiplierLabel.Text = "✨ x3 MAGIC! ✨"
	multiplierLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	multiplierLabel.TextScaled = true
	multiplierLabel.Font = Enum.Font.SourceSansBold
	multiplierLabel.TextStrokeTransparency = 0
	multiplierLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	multiplierLabel.Parent = effectFrame

	-- Points text
	local pointsLabel = Instance.new("TextLabel")
	pointsLabel.Size = UDim2.new(1, 0, 0.4, 0)
	pointsLabel.Position = UDim2.new(0, 0, 0.6, 0)
	pointsLabel.BackgroundTransparency = 1
	pointsLabel.Text = "+" .. points .. " POINTS!"
	pointsLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
	pointsLabel.TextScaled = true
	pointsLabel.Font = Enum.Font.SourceSans
	pointsLabel.TextStrokeTransparency = 0
	pointsLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	pointsLabel.Parent = effectFrame

	-- Scale and fade animations
	local scaleInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local scaleTween = TweenService:Create(effectFrame, scaleInfo, {Size = UDim2.new(1.5, 0, 1.5, 0)})

	local floatInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local floatTween = TweenService:Create(billboardGui, floatInfo, {StudsOffset = Vector3.new(0, 8, 0)})

	local fadeInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeTween = TweenService:Create(multiplierLabel, fadeInfo, {TextTransparency = 1})
	local fadePointsTween = TweenService:Create(pointsLabel, fadeInfo, {TextTransparency = 1})

	-- Play animations
	scaleTween:Play()
	delay(0.5, function()
		floatTween:Play()
		fadeTween:Play()
		fadePointsTween:Play()
	end)

	-- Clean up after animation
	delay(2.5, function()
		if billboardGui and billboardGui.Parent then
			billboardGui:Destroy()
		end
	end)
end

-- Show lucky magic key notification
function CoinCollectorModule.showMagicKeyNotification(player)
	local playerGui = player:WaitForChild("PlayerGui")

	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MagicKeyNotification"
	screenGui.Parent = playerGui

	-- Notification Frame
	local notificationFrame = Instance.new("Frame")
	notificationFrame.Size = UDim2.new(0, 400, 0, 80)
	notificationFrame.Position = UDim2.new(0.5, -200, 0.1, 0)
	notificationFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	notificationFrame.BackgroundTransparency = 0.1
	notificationFrame.BorderSizePixel = 0
	notificationFrame.Parent = screenGui

	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = notificationFrame

	-- Notification Text
	local notificationText = Instance.new("TextLabel")
	notificationText.Size = UDim2.new(1, 0, 1, 0)
	notificationText.Position = UDim2.new(0, 0, 0, 0)
	notificationText.BackgroundTransparency = 1
	notificationText.Text = "🗝️ LUCKY! MAGIC KEY SPAWNED! 🗝️"
	notificationText.TextColor3 = Color3.fromRGB(0, 0, 0)
	notificationText.TextScaled = true
	notificationText.Font = Enum.Font.SourceSansBold
	notificationText.Parent = notificationFrame

	-- Shimmer effect
	local shimmerTween = TweenService:Create(
		notificationFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{BackgroundColor3 = Color3.fromRGB(255, 255, 0)}
	)
	shimmerTween:Play()

	-- Scale animation
	local scaleTween = TweenService:Create(
		notificationFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 420, 0, 90)}
	)
	scaleTween:Play()

	-- Auto-remove after 3 seconds
	delay(3, function()
		if screenGui and screenGui.Parent then
			local fadeTween = TweenService:Create(
				notificationFrame,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Size = UDim2.new(0, 0, 0, 0),
					BackgroundTransparency = 1
				}
			)
			fadeTween:Play()
			fadeTween.Completed:Connect(function()
				screenGui:Destroy()
			end)
		end
	end)
end

-- Create leaderstats with persistent data
function CoinCollectorModule.createLeaderstats(player)
	-- Load player data first
	CoinCollectorModule.loadPlayerData(player)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Current game score
	local score = Instance.new("IntValue")
	score.Name = "Score"
	score.Value = 0
	score.Parent = leaderstats

	-- Total score across all games
	local totalScore = Instance.new("IntValue")
	totalScore.Name = "Total"
	totalScore.Value = CoinCollectorModule.playerData[player].totalScore
	totalScore.Parent = leaderstats

	-- Best single game score
	local bestScore = Instance.new("IntValue")
	bestScore.Name = "Best"
	bestScore.Value = CoinCollectorModule.playerData[player].bestScore
	bestScore.Parent = leaderstats

	-- Games played
	local gamesPlayed = Instance.new("IntValue")
	gamesPlayed.Name = "Games"
	gamesPlayed.Value = CoinCollectorModule.playerData[player].gamesPlayed
	gamesPlayed.Parent = leaderstats

	-- Magic keys found (hidden stat)
	local magicKeys = Instance.new("IntValue")
	magicKeys.Name = "MagicKeys"
	magicKeys.Value = CoinCollectorModule.playerData[player].magicKeysFound
	magicKeys.Parent = leaderstats

	CoinCollectorModule.playerScores[player] = score
end

-- Create default coin as fallback
function CoinCollectorModule.createDefaultCoin()
	local coin = Instance.new("Part")
	coin.Name = "Coin"
	coin.Shape = Enum.PartType.Cylinder
	coin.Material = Enum.Material.SmoothPlastic
	coin.BrickColor = BrickColor.new("Bright orange")
	coin.Size = Vector3.new(0.5, 4, 4)
	coin.Anchored = true
	coin.CanCollide = false

	-- Add the texture to both faces of the cylinder
	local decalFront = Instance.new("Decal")
	decalFront.Name = "FrontDecal"
	decalFront.Face = Enum.NormalId.Left
	decalFront.Texture = "rbxassetid://101050942999274"
	decalFront.Transparency = 0
	decalFront.Parent = coin

	local decalBack = Instance.new("Decal")
	decalBack.Name = "BackDecal"
	decalBack.Face = Enum.NormalId.Right
	decalBack.Texture = "rbxassetid://101050942999274"
	decalBack.Transparency = 0
	decalBack.Parent = coin

	print("🪙 Created default coin as fallback")
	return coin
end

-- Create regular collectible item based on GAME_LABEL
function CoinCollectorModule.createRegularItem()
	local grabItem

	if CoinCollectorModule.GAME_LABEL == "MOONCAKE" then
		-- Create mooncake MeshPart with error handling
		local success, mooncakeTemplate = pcall(function()
			return ReplicatedStorage:WaitForChild("MooncakeMeshPart", 5) -- 5 second timeout
		end)

		if success and mooncakeTemplate then
			local mooncake = mooncakeTemplate:Clone()
			mooncake.Name = "MoonCake"
			mooncake.Anchored = true
			mooncake.CanCollide = false
			grabItem = mooncake
			print("✅ Successfully created MOONCAKE")
		else
			print("❌ MooncakeMeshPart not found in ReplicatedStorage, creating default coin")
			grabItem = CoinCollectorModule.createDefaultCoin()
		end

	elseif CoinCollectorModule.GAME_LABEL == "ICECREAM" then
		-- Future ice cream implementation
		local success, iceCreamTemplate = pcall(function()
			return ReplicatedStorage:WaitForChild("IceCreamMeshPart", 5)
		end)

		if success and iceCreamTemplate then
			local iceCream = iceCreamTemplate:Clone()
			iceCream.Name = "IceCream"
			iceCream.Anchored = true
			iceCream.CanCollide = false
			grabItem = iceCream
		else
			print("❌ IceCreamMeshPart not found, creating default coin")
			grabItem = CoinCollectorModule.createDefaultCoin()
		end

	elseif CoinCollectorModule.GAME_LABEL == "DONUT" then
		-- Future donut implementation
		local success, donutTemplate = pcall(function()
			return ReplicatedStorage:WaitForChild("DonutMeshPart", 5)
		end)

		if success and donutTemplate then
			local donut = donutTemplate:Clone()
			donut.Name = "Donut"
			donut.Anchored = true
			donut.CanCollide = false
			grabItem = donut
		else
			print("❌ DonutMeshPart not found, creating default coin")
			grabItem = CoinCollectorModule.createDefaultCoin()
		end
	else
		-- Default coin implementation
		grabItem = CoinCollectorModule.createDefaultCoin()
	end

	if grabItem then
		CoinCollectorModule.setupGrabItem(grabItem, false) -- false = not a magic key
	else
		print("❌ Failed to create grab item!")
	end
end

-- Create magic key (always uses MagicKeyMeshPart regardless of GAME_LABEL)
function CoinCollectorModule.createMagicKey()
	local success, magicKeyTemplate = pcall(function()
		return ReplicatedStorage:WaitForChild("MagicKeyMeshPart", 5) -- 5 second timeout
	end)

	if success and magicKeyTemplate then
		local magicKey = magicKeyTemplate:Clone()
		magicKey.Name = "MagicKey"
		magicKey.Anchored = true
		magicKey.CanCollide = false

		CoinCollectorModule.setupGrabItem(magicKey, true) -- true = is a magic key
		print("🗝️ Successfully created MAGIC KEY")
	else
		print("❌ MagicKeyMeshPart not found in ReplicatedStorage, creating default coin as magic key")
		-- Fallback to default coin but with magic key properties
		local fallbackMagicKey = CoinCollectorModule.createDefaultCoin()
		fallbackMagicKey.Name = "MagicKey"
		fallbackMagicKey.BrickColor = BrickColor.new("Bright yellow") -- Make it golden
		CoinCollectorModule.setupGrabItem(fallbackMagicKey, true)
	end
end

-- CRITICAL MISSING FUNCTION - setupGrabItem
function CoinCollectorModule.setupGrabItem(grabItem, isMagicKey)
	if not grabItem then
		warn("❌ setupGrabItem called with nil grabItem!")
		return
	end

	print("🔧 Setting up " .. (isMagicKey and "Magic Key" or CoinCollectorModule.GAME_LABEL) .. "...")

	-- Add glow effect (stronger for magic key)
	local pointLight = Instance.new("PointLight")
	if isMagicKey then
		pointLight.Color = Color3.fromRGB(255, 215, 0) -- Golden glow for magic key
		pointLight.Brightness = 2
		pointLight.Range = 15

		-- Add extra sparkle effect for magic key
		local sparkleGui = Instance.new("BillboardGui")
		sparkleGui.Size = UDim2.new(3, 0, 3, 0)
		sparkleGui.Parent = grabItem

		local sparkleLabel = Instance.new("TextLabel")
		sparkleLabel.Size = UDim2.new(1, 0, 1, 0)
		sparkleLabel.BackgroundTransparency = 1
		sparkleLabel.Text = "✨🗝️✨"
		sparkleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		sparkleLabel.TextScaled = true
		sparkleLabel.Font = Enum.Font.SourceSansBold
		sparkleLabel.Parent = sparkleGui

		-- Sparkle animation
		local sparkleTween = TweenService:Create(
			sparkleLabel,
			TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{TextTransparency = 0.3}
		)
		sparkleTween:Play()
	else
		pointLight.Color = Color3.fromRGB(255, 200, 100) -- Regular glow
		pointLight.Brightness = 0.5
		pointLight.Range = 10
	end
	pointLight.Parent = grabItem

	-- Random position
	local x = math.random(-CoinCollectorModule.MAP_SIZE/2, CoinCollectorModule.MAP_SIZE/2)
	local z = math.random(-CoinCollectorModule.MAP_SIZE/2, CoinCollectorModule.MAP_SIZE/2)
	local y = math.random(1, 10)
	grabItem.Position = Vector3.new(x, y, z)

	-- Add spinning animation (faster for magic key)
	local spinSpeed = isMagicKey and 1 or 2
	local spinTween = TweenService:Create(
		grabItem,
		TweenInfo.new(spinSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{Rotation = grabItem.Rotation + Vector3.new(0, 360, 0)}
	)
	spinTween:Play()

	-- Add floating animation (more dramatic for magic key)
	local floatHeight = isMagicKey and 8 or 5
	local floatSpeed = isMagicKey and 2 or 3
	local floatTween = TweenService:Create(
		grabItem,
		TweenInfo.new(floatSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Position = grabItem.Position + Vector3.new(0, floatHeight, 0)}
	)
	floatTween:Play()

	-- Collision detection with game pass bonuses
	local connection
	connection = grabItem.Touched:Connect(function(hit)
		local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid and CoinCollectorModule.gameActive then
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player and CoinCollectorModule.playerScores[player] and CoinCollectorModule.playerData[player] then
				local points = CoinCollectorModule.COIN_VALUE

				-- Apply magic key multiplier
				if isMagicKey then
					points = points * CoinCollectorModule.MAGIC_KEY_MULTIPLIER
					CoinCollectorModule.playerData[player].magicKeysFound = CoinCollectorModule.playerData[player].magicKeysFound + 1

					-- Update magic keys leaderstats
					local leaderstats = player:FindFirstChild("leaderstats")
					if leaderstats and leaderstats:FindFirstChild("MagicKeys") then
						leaderstats.MagicKeys.Value = CoinCollectorModule.playerData[player].magicKeysFound
					end

					-- Show special multiplier effect
					CoinCollectorModule.showMultiplierEffect(player, points)
					print("🗝️ " .. player.Name .. " found a MAGIC KEY! +" .. points .. " points!")
				else
					print("🎯 " .. player.Name .. " collected a " .. CoinCollectorModule.GAME_LABEL .. "! +" .. points .. " points!")
				end

				-- Apply game pass bonuses if available
				if _G.GamePassHandler and _G.GamePassHandler.handleCoinCollection then
					points = _G.GamePassHandler.handleCoinCollection(player, points, isMagicKey)
				end

				-- Award points
				CoinCollectorModule.playerScores[player].Value = CoinCollectorModule.playerScores[player].Value + points

				-- Update persistent data
				CoinCollectorModule.playerData[player].coinsCollected = CoinCollectorModule.playerData[player].coinsCollected + 1

				-- Create collection effect
				local effect = grabItem:Clone()
				effect.Size = effect.Size * 1.5
				effect.Transparency = 0.5
				effect.Parent = workspace

				-- Clean up effect clones
				if effect:FindFirstChild("FrontDecal") then effect.FrontDecal:Destroy() end
				if effect:FindFirstChild("BackDecal") then effect.BackDecal:Destroy() end
				if effect:FindFirstChild("PointLight") then effect.PointLight:Destroy() end
				if effect:FindFirstChild("BillboardGui") then effect.BillboardGui:Destroy() end

				-- Effect animation
				local effectSize = isMagicKey and effect.Size * 3 or effect.Size * 2
				local effectHeight = isMagicKey and 15 or 10
				local effectTween = TweenService:Create(
					effect,
					TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Size = effectSize,
						Transparency = 1,
						Position = effect.Position + Vector3.new(0, effectHeight, 0)
					}
				)
				effectTween:Play()
				effectTween.Completed:Connect(function()
					if effect and effect.Parent then
						effect:Destroy()
					end
				end)

				-- Remove item from tracking array
				for i, trackedItem in ipairs(CoinCollectorModule.coins) do
					if trackedItem == grabItem then
						table.remove(CoinCollectorModule.coins, i)
						print("🗑️ Removed " .. (isMagicKey and "Magic Key" or CoinCollectorModule.GAME_LABEL) .. " from tracking. Remaining items: " .. #CoinCollectorModule.coins)
						break
					end
				end

				-- Cleanup
				connection:Disconnect()
				spinTween:Cancel()
				floatTween:Cancel()
				grabItem:Destroy()
			end
		end
	end)

	grabItem.Parent = workspace
	table.insert(CoinCollectorModule.coins, grabItem)
	print("✅ " .. (isMagicKey and "Magic Key" or CoinCollectorModule.GAME_LABEL) .. " added to world. Total items: " .. #CoinCollectorModule.coins .. "/" .. CoinCollectorModule.MAX_COINS)

	-- Auto-remove item after time (magic key lasts longer)
	local lifetime = isMagicKey and 45 or 30
	Debris:AddItem(grabItem, lifetime)

	-- Add cleanup for when Debris removes the item
	spawn(function()
		wait(lifetime)
		-- Double-check and remove from tracking if still exists
		for i, trackedItem in ipairs(CoinCollectorModule.coins) do
			if trackedItem == grabItem then
				table.remove(CoinCollectorModule.coins, i)
				print("🕒 " .. (isMagicKey and "Magic Key" or CoinCollectorModule.GAME_LABEL) .. " expired and removed. Remaining items: " .. #CoinCollectorModule.coins)
				break
			end
		end
	end)
end

-- Main function to create collectible items (determines if it's a regular item or magic key)
function CoinCollectorModule.createGrabItem()
	local currentItemCount = #CoinCollectorModule.coins
	print("🎯 Spawn attempt: Current items = " .. currentItemCount .. "/" .. CoinCollectorModule.MAX_COINS .. ", Game active = " .. tostring(CoinCollectorModule.gameActive))

	if currentItemCount >= CoinCollectorModule.MAX_COINS then
		print("⚠️ Max items reached (" .. CoinCollectorModule.MAX_COINS .. "), skipping spawn")
		return 
	end

	if not CoinCollectorModule.gameActive then
		print("⚠️ Game not active, skipping spawn")
		return 
	end

	-- Check for magic key spawn
	local randomChance = math.random()
	local spawnMagicKey = randomChance <= CoinCollectorModule.MAGIC_KEY_SPAWN_CHANCE

	if spawnMagicKey then
		-- Notify all players about the lucky spawn
		for _, player in pairs(Players:GetPlayers()) do
			CoinCollectorModule.showMagicKeyNotification(player)
		end
		print("🗝️ LUCKY MAGIC KEY SPAWNED! Chance: " .. randomChance .. " ≤ " .. CoinCollectorModule.MAGIC_KEY_SPAWN_CHANCE .. " (" .. (currentItemCount + 1) .. "/" .. CoinCollectorModule.MAX_COINS .. " items)")
		CoinCollectorModule.createMagicKey()
	else
		-- Always spawn regular item
		print("📦 Spawning regular " .. CoinCollectorModule.GAME_LABEL .. " (" .. (currentItemCount + 1) .. "/" .. CoinCollectorModule.MAX_COINS .. " items)")
		CoinCollectorModule.createRegularItem()
	end
end

-- Missing GUI Functions - Adding these now

-- Show game instructions and countdown
function CoinCollectorModule.showGameStart()
	for _, player in pairs(Players:GetPlayers()) do
		local playerGui = player:WaitForChild("PlayerGui")

		-- Remove any existing start display
		local existingStart = playerGui:FindFirstChild("GameStart")
		if existingStart then
			existingStart:Destroy()
		end

		-- Create ScreenGui
		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "GameStart"
		screenGui.Parent = playerGui

		-- Main Frame
		local mainFrame = Instance.new("Frame")
		mainFrame.Size = UDim2.new(0, 600, 0, 450)
		mainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
		mainFrame.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
		mainFrame.BackgroundTransparency = 0.1
		mainFrame.BorderSizePixel = 0
		mainFrame.Parent = screenGui

		-- Corner rounding
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 20)
		corner.Parent = mainFrame

		-- Title
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, 0, 0, 80)
		titleLabel.Position = UDim2.new(0, 0, 0, 20)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = string.format("⭐ %s COLLECTOR⭐",CoinCollectorModule.GAME_LABEL)
		titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		titleLabel.TextScaled = true
		titleLabel.Font = Enum.Font.SourceSansBold
		titleLabel.Parent = mainFrame

		-- Instructions
		local instructionsLabel = Instance.new("TextLabel")
		instructionsLabel.Size = UDim2.new(1, -40, 0, 140)
		instructionsLabel.Position = UDim2.new(0, 20, 0, 110)
		instructionsLabel.BackgroundTransparency = 1
		instructionsLabel.Text = `🎯 OBJECTIVE: Collect as many {CoinCollectorModule.GAME_LABEL} as possible!\n\n🏃 Walk or run into {CoinCollectorModule.GAME_LABEL} to collect them\n💰 Each {CoinCollectorModule.GAME_LABEL} = ` .. CoinCollectorModule.COIN_VALUE .. " points\n🗝️ LUCKY MAGIC KEYS = " .. (CoinCollectorModule.COIN_VALUE * CoinCollectorModule.MAGIC_KEY_MULTIPLIER) .. " points (x" .. CoinCollectorModule.MAGIC_KEY_MULTIPLIER .. ")\n⏰ You have " .. CoinCollectorModule.GAME_DURATION .. " seconds!"
		instructionsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		instructionsLabel.TextScaled = true
		instructionsLabel.Font = Enum.Font.SourceSans
		instructionsLabel.TextWrapped = true
		instructionsLabel.Parent = mainFrame

		-- Countdown Label
		local countdownLabel = Instance.new("TextLabel")
		countdownLabel.Size = UDim2.new(1, 0, 0, 100)
		countdownLabel.Position = UDim2.new(0, 0, 0, 280)
		countdownLabel.BackgroundTransparency = 1
		countdownLabel.Text = "Get Ready!"
		countdownLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		countdownLabel.TextScaled = true
		countdownLabel.Font = Enum.Font.SourceSansBold
		countdownLabel.Parent = mainFrame

		-- Animate the display
		mainFrame.Size = UDim2.new(0, 0, 0, 0)
		local expandTween = TweenService:Create(
			mainFrame,
			TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, 600, 0, 450)}
		)
		expandTween:Play()

		-- Countdown sequence
		local countdownNumbers = { "5", "4", "3", "2", "1", "GO!"}
		local currentCount = 1
		CoinCollectorModule.COUNTDOWN_SEC= #countdownNumbers

		delay(CoinCollectorModule.INSTRUCTION_SEC , function() -- Wait 5 seconds before countdown
			local function showCountdown()
				if currentCount <= #countdownNumbers then
					countdownLabel.Text = countdownNumbers[currentCount]

					-- Special styling for "GO!"
					if countdownNumbers[currentCount] == "GO!" then
						countdownLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
						countdownLabel.Text = "🚀 GO! 🚀"
					end

					-- Scale animation for countdown
					countdownLabel.Size = UDim2.new(1, 0, 0, 50)
					local scaleTween = TweenService:Create(
						countdownLabel,
						TweenInfo.new(0.8, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
						{Size = UDim2.new(1, 0, 0, 100)}
					)
					scaleTween:Play()

					currentCount = currentCount + 1

					if currentCount <= #countdownNumbers then
						delay(1, showCountdown)
					else
						-- Remove display after "GO!"
						delay(1, function()
							if screenGui and screenGui.Parent then
								local fadeTween = TweenService:Create(
									mainFrame,
									TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
									{
										Size = UDim2.new(0, 0, 0, 0),
										BackgroundTransparency = 1
									}
								)
								fadeTween:Play()
								fadeTween.Completed:Connect(function()
									screenGui:Destroy()
								end)
							end
						end)
					end
				end
			end
			showCountdown()
		end)
	end
end


-- Show time warning when game is about to end
function CoinCollectorModule.showTimeWarning(timeLeft)
	local Players = game:GetService("Players")

	for _, player in pairs(Players:GetPlayers()) do
		pcall(function()
			local playerGui = player:WaitForChild("PlayerGui")

			-- Create warning GUI
			local screenGui = Instance.new("ScreenGui")
			screenGui.Name = "TimeWarning"
			screenGui.Parent = playerGui

			-- Warning frame
			local warningFrame = Instance.new("Frame")
			warningFrame.Size = UDim2.new(0, 300, 0, 80)
			warningFrame.Position = UDim2.new(0.5, -150, 0.2, 0)
			warningFrame.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
			warningFrame.BackgroundTransparency = 0.1
			warningFrame.BorderSizePixel = 0
			warningFrame.Parent = screenGui

			-- Corner rounding
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 10)
			corner.Parent = warningFrame

			-- Warning text
			local warningText = Instance.new("TextLabel")
			warningText.Size = UDim2.new(1, 0, 1, 0)
			warningText.BackgroundTransparency = 1
			warningText.Text = "⚠️ " .. timeLeft .. " SECONDS LEFT! ⚠️"
			warningText.TextColor3 = Color3.fromRGB(255, 255, 255)
			warningText.TextScaled = true
			warningText.Font = Enum.Font.SourceSansBold
			warningText.Parent = warningFrame

			-- Pulse animation
			local pulseTween = TweenService:Create(
				warningFrame,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 2, true),
				{Size = UDim2.new(0, 320, 0, 90)}
			)
			pulseTween:Play()

			-- Auto-remove after 2 seconds
			delay(2, function()
				if screenGui and screenGui.Parent then
					screenGui:Destroy()
				end
			end)
		end)
	end
end

-- Show winner display at game end
function CoinCollectorModule.showWinnerDisplay(winnerName, winnerScore)
	local Players = game:GetService("Players")

	for _, player in pairs(Players:GetPlayers()) do
		pcall(function()
			local playerGui = player:WaitForChild("PlayerGui")

			-- Create winner display GUI
			local screenGui = Instance.new("ScreenGui")
			screenGui.Name = "WinnerDisplay"
			screenGui.Parent = playerGui

			-- Main frame
			local mainFrame = Instance.new("Frame")
			mainFrame.Size = UDim2.new(0, 500, 0, 250)
			mainFrame.Position = UDim2.new(0.5, -250, 0.5, -125)
			mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			mainFrame.BackgroundTransparency = 0.1
			mainFrame.BorderSizePixel = 0
			mainFrame.Parent = screenGui

			-- Corner rounding
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 15)
			corner.Parent = mainFrame

			-- Game Over title
			local titleLabel = Instance.new("TextLabel")
			titleLabel.Size = UDim2.new(1, 0, 0.3, 0)
			titleLabel.Position = UDim2.new(0, 0, 0, 0)
			titleLabel.BackgroundTransparency = 1
			titleLabel.Text = "🎮 GAME OVER! 🎮"
			titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			titleLabel.TextScaled = true
			titleLabel.Font = Enum.Font.SourceSansBold
			titleLabel.Parent = mainFrame

			-- Winner announcement
			local winnerLabel = Instance.new("TextLabel")
			winnerLabel.Size = UDim2.new(1, -20, 0.4, 0)
			winnerLabel.Position = UDim2.new(0, 10, 0.3, 0)
			winnerLabel.BackgroundTransparency = 1
			if winnerName and winnerScore then
				winnerLabel.Text = "🏆 WINNER: " .. winnerName .. "\n" .. winnerScore .. " Points!"
				winnerLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
			else
				winnerLabel.Text = "🎮 No winner this round!\nBetter luck next time!"
				winnerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			end
			winnerLabel.TextScaled = true
			winnerLabel.Font = Enum.Font.SourceSans
			winnerLabel.Parent = mainFrame

			-- Next game info
			local nextGameLabel = Instance.new("TextLabel")
			nextGameLabel.Size = UDim2.new(1, 0, 0.3, 0)
			nextGameLabel.Position = UDim2.new(0, 0, 0.7, 0)
			nextGameLabel.BackgroundTransparency = 1
			nextGameLabel.Text = "Next game starts in 10 seconds!"
			nextGameLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
			nextGameLabel.TextScaled = true
			nextGameLabel.Font = Enum.Font.SourceSans
			nextGameLabel.Parent = mainFrame

			-- Celebration animation for winner
			if winnerName then
				local celebrationTween = TweenService:Create(
					winnerLabel,
					TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{TextColor3 = Color3.fromRGB(255, 255, 0)}
				)
				celebrationTween:Play()
			end

			-- Auto-remove after 8 seconds (before next game starts)
			delay(8, function()
				if screenGui and screenGui.Parent then
					local fadeInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					local fadeTween = TweenService:Create(mainFrame, fadeInfo, {BackgroundTransparency = 1})
					local titleFade = TweenService:Create(titleLabel, fadeInfo, {TextTransparency = 1})
					local winnerFade = TweenService:Create(winnerLabel, fadeInfo, {TextTransparency = 1})
					local nextFade = TweenService:Create(nextGameLabel, fadeInfo, {TextTransparency = 1})

					fadeTween:Play()
					titleFade:Play()
					winnerFade:Play()
					nextFade:Play()

					fadeTween.Completed:Connect(function()
						if screenGui and screenGui.Parent then
							screenGui:Destroy()
						end
					end)
				end
			end)
		end)
	end
end

return CoinCollectorModule