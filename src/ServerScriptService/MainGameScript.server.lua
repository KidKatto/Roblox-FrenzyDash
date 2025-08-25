-- @ScriptType: Script
-- Enhanced Main Coin Collector Game Script with Marketplace Integration
-- Place this script in ServerScriptService 
-- Make sure CoinCollectorModule is placed in ReplicatedStorage or ServerStorage

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import the CoinCollectorModule (adjust path as needed)
local CoinCollectorModule = require(ReplicatedStorage:WaitForChild("CoinCollectorModule"))

-- Add missing countdown constant
CoinCollectorModule.COUNTDOWN_SEC = CoinCollectorModule.COUNTDOWN_SEC or 3 -- 3 second countdown after instructions
CoinCollectorModule.INSTRUCTION_SEC = CoinCollectorModule.INSTRUCTION_SEC or 5 -- Default instruction time

-- Wait for GamePass Handler to load (it sets up _G.GamePassHandler)
local GamePassHandler = nil
spawn(function()
	while not _G.GamePassHandler do
		wait(0.1)
	end
	GamePassHandler = _G.GamePassHandler
	print("🔗 GamePass Handler connected to main script!")
end)

-- Wait for MarketplaceHandler to load (it sets up _G.MarketplaceHandler)
local MarketplaceHandler = nil
spawn(function()
	while not _G.MarketplaceHandler do
		wait(0.1)
	end
	MarketplaceHandler = _G.MarketplaceHandler
	print("💰 MarketplaceHandler connected to main script!")
end)

-- Enhanced setupGrabItem that includes game pass bonuses
local originalSetupGrabItem = CoinCollectorModule.setupGrabItem
CoinCollectorModule.setupGrabItem = function(grabItem, isMagicKey)
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
		local TweenService = game:GetService("TweenService")
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
	local TweenService = game:GetService("TweenService")
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

	-- ENHANCED Collision detection with game pass bonuses
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

				-- APPLY GAME PASS BONUSES HERE
				if GamePassHandler and GamePassHandler.handleCoinCollection then
					points = GamePassHandler.handleCoinCollection(player, points, isMagicKey)
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
	local Debris = game:GetService("Debris")
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

-- Start the game with marketplace integration
local function startGame()
	if CoinCollectorModule.gameActive then
		print("Game is already running!")
		return
	end

	-- Update game settings based on active game passes
	if GamePassHandler and GamePassHandler.updateGameSettings then
		GamePassHandler.updateGameSettings()
	end

	-- Show instructions and countdown first
	CoinCollectorModule.showGameStart()

	-- Wait for instructions and countdown to finish (5 seconds instructions + countdown seconds + 1 second "GO!")
	task.wait(CoinCollectorModule.COUNTDOWN_SEC + CoinCollectorModule.INSTRUCTION_SEC + 1)
	
	CoinCollectorModule.gameActive = true
	CoinCollectorModule.gameTimeLeft = CoinCollectorModule.GAME_DURATION

	-- Reset current game scores only
	for player, score in pairs(CoinCollectorModule.playerScores) do
		if score and score.Parent then
			score.Value = 0
		end
	end

	-- Clear existing coins
	for i = #CoinCollectorModule.coins, 1, -1 do
		local coin = CoinCollectorModule.coins[i]
		if coin and coin.Parent then
			coin:Destroy()
		end
		CoinCollectorModule.coins[i] = nil
	end

	print(`🎮 ${CoinCollectorModule.GAME_LABEL} COLLECTOR STARTED! Collect items for ` .. CoinCollectorModule.GAME_DURATION .. " seconds!")

	-- Show game start notification to all players
	if _G.SendNotificationToAllPlayers then
		_G.SendNotificationToAllPlayers("ChatMessage", {
			text = `🎮 ${CoinCollectorModule.GAME_LABEL} Collector game has started! Good luck!`,
			color = Color3.fromRGB(0, 255, 100)
		})
	end

	-- Game timer using RunService for better reliability
	local lastTime = tick()
	CoinCollectorModule.gameTimerConnection = RunService.Heartbeat:Connect(function()
		if not CoinCollectorModule.gameActive then
			return
		end

		local currentTime = tick()
		local deltaTime = currentTime - lastTime
		lastTime = currentTime

		CoinCollectorModule.gameTimeLeft = CoinCollectorModule.gameTimeLeft - deltaTime

		if CoinCollectorModule.gameTimeLeft <= 0 then
			endGame()
		elseif math.floor(CoinCollectorModule.gameTimeLeft) % 30 == 0 and math.floor(CoinCollectorModule.gameTimeLeft) ~= CoinCollectorModule.GAME_DURATION then
			print("⏰ " .. math.floor(CoinCollectorModule.gameTimeLeft) .. " seconds remaining!")
		end

		-- Show warning when less than 30 seconds remain
		local timeLeft = math.floor(CoinCollectorModule.gameTimeLeft)
		if timeLeft == 10 or timeLeft == 5 or timeLeft == 3 or timeLeft == 2 or timeLeft == 1 then
			CoinCollectorModule.showTimeWarning(timeLeft)
		end
	end)

	-- Coin spawner using proper interval tracking
	local coinSpawnTimer = 0
	CoinCollectorModule.coinSpawnerConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if not CoinCollectorModule.gameActive then
			return
		end

		coinSpawnTimer = coinSpawnTimer + deltaTime
		if coinSpawnTimer >= CoinCollectorModule.COIN_SPAWN_RATE then
			CoinCollectorModule.createGrabItem()
			coinSpawnTimer = 0
		end
	end)
end

-- End the game and save data
function endGame()
	if not CoinCollectorModule.gameActive then
		return
	end

	print("🔥 Ending game...")
	CoinCollectorModule.gameActive = false

	-- Disconnect game loops
	if CoinCollectorModule.gameTimerConnection then
		CoinCollectorModule.gameTimerConnection:Disconnect()
		CoinCollectorModule.gameTimerConnection = nil
	end

	if CoinCollectorModule.coinSpawnerConnection then
		CoinCollectorModule.coinSpawnerConnection:Disconnect()
		CoinCollectorModule.coinSpawnerConnection = nil
	end

	-- Clear remaining coins
	for i = #CoinCollectorModule.coins, 1, -1 do
		local coin = CoinCollectorModule.coins[i]
		if coin and coin.Parent then
			coin:Destroy()
		end
		CoinCollectorModule.coins[i] = nil
	end

	-- Update player data and save
	local winner = nil
	local highScore = 0
	local gameResults = {}

	for player, score in pairs(CoinCollectorModule.playerScores) do
		if player and player.Parent and score and score.Parent and score.Value and CoinCollectorModule.playerData[player] then
			local currentScore = score.Value

			-- Store game result
			table.insert(gameResults, {
				player = player,
				score = currentScore,
				name = player.Name
			})

			-- Update persistent data
			CoinCollectorModule.playerData[player].gamesPlayed = CoinCollectorModule.playerData[player].gamesPlayed + 1
			CoinCollectorModule.playerData[player].totalScore = CoinCollectorModule.playerData[player].totalScore + currentScore

			if currentScore > CoinCollectorModule.playerData[player].bestScore then
				CoinCollectorModule.playerData[player].bestScore = currentScore
			end

			-- Update leaderstats display
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local totalScore = leaderstats:FindFirstChild("Total")
				local bestScore = leaderstats:FindFirstChild("Best")
				local gamesPlayed = leaderstats:FindFirstChild("Games")

				if totalScore then totalScore.Value = CoinCollectorModule.playerData[player].totalScore end
				if bestScore then bestScore.Value = CoinCollectorModule.playerData[player].bestScore end
				if gamesPlayed then gamesPlayed.Value = CoinCollectorModule.playerData[player].gamesPlayed end
			end

			-- Save data to DataStore
			CoinCollectorModule.savePlayerData(player)

			-- Update leaderboard with best score
			CoinCollectorModule.updateLeaderboard(player, CoinCollectorModule.playerData[player].bestScore)

			-- Find winner
			if currentScore > highScore then
				highScore = currentScore
				winner = player
			end
		end
	end

	-- Sort results for display
	table.sort(gameResults, function(a, b) return a.score > b.score end)

	-- Show game end notification
	if winner and winner.Name then
		print("🏆 GAME OVER! Winner: " .. winner.Name .. " with " .. highScore .. " points!")
		CoinCollectorModule.showWinnerDisplay(winner.Name, highScore)

		-- Show results to all players
		if _G.SendNotificationToAllPlayers then
			_G.SendNotificationToAllPlayers("ChatMessage", {
				text = "🏆 Winner: " .. winner.Name .. " with " .. highScore .. " points!",
				color = Color3.fromRGB(255, 215, 0)
			})
		end
	else
		print("🎮 GAME OVER! No winner this round.")
		CoinCollectorModule.showWinnerDisplay(nil, nil)
	end

	-- Wait before next game
	task.wait(10)
	if not CoinCollectorModule.gameActive then
		print("🚀 Starting next game...")
		startGame()
	end
end 

-- Handle players already in the game
for _, player in ipairs(Players:GetPlayers()) do
	CoinCollectorModule.createLeaderstats(player)
end

Players.PlayerAdded:Connect(function(player)
	CoinCollectorModule.createLeaderstats(player)
end)

Players.PlayerRemoving:Connect(function(player)
	-- Save data before player leaves
	if CoinCollectorModule.playerData[player] then
		CoinCollectorModule.savePlayerData(player)
	end

	-- Clean up references
	if CoinCollectorModule.playerScores[player] then
		CoinCollectorModule.playerScores[player] = nil
	end
	if CoinCollectorModule.playerData[player] then
		CoinCollectorModule.playerData[player] = nil
	end
end)

-- Enhanced admin commands (for testing)
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "YourUsernameHere" then -- Replace with your Roblox username
			local command = message:lower()

			if command == "/startgame" then
				if not CoinCollectorModule.gameActive then
					startGame()
					print("Admin started the game!")
				else
					print("Game is already running!")
				end

			elseif command == "/endgame" then
				if CoinCollectorModule.gameActive then
					endGame()
					print("Admin ended the game!")
				else
					print("No game is currently running!")
				end

			elseif command == "/spawncoin" then
				if CoinCollectorModule.gameActive then
					CoinCollectorModule.createGrabItem()
					print("Admin spawned a coin!")
				else
					print("Cannot spawn coin - no game running!")
				end

			elseif command == "/spawnkey" then
				if CoinCollectorModule.gameActive then
					CoinCollectorModule.createMagicKey()
					print("Admin spawned a magic key!")
				else
					print("Cannot spawn key - no game running!")
				end

			elseif command == "/status" then
				if CoinCollectorModule.gameActive then
					print("Game active. Time left: " .. math.floor(CoinCollectorModule.gameTimeLeft) .. " seconds. Coins: " .. #CoinCollectorModule.coins)
				else
					print("No game currently running.")
				end

				-- Show marketplace status
				if GamePassHandler then
					print("🎮 GamePass Status:")
					print("  Magic Key Chance: " .. (CoinCollectorModule.MAGIC_KEY_SPAWN_CHANCE * 100) .. "%")
					print("  Game Duration: " .. CoinCollectorModule.GAME_DURATION .. " seconds")
				end

				if MarketplaceHandler then
					print("💰 MarketplaceHandler: Connected")
					if _G.PlayerTempBoosts then
						local boosts = _G.PlayerTempBoosts.getPlayerBoosts(player)
						print("  Temporary boosts: " .. (next(boosts) and "Active" or "None"))
					end
				else
					print("💰 MarketplaceHandler: Not connected")
				end

			elseif command == "/leaderboard" then
				local topPlayers = CoinCollectorModule.getTopPlayers(5)
				print("🏆 TOP 5 LEADERBOARD:")
				for _, playerInfo in ipairs(topPlayers) do
					print(playerInfo.rank .. ". " .. playerInfo.name .. " - " .. playerInfo.score .. " points")
				end

			elseif command == "/teststore" then
				print("🛒 Testing store integration...")
				print("  GamePassHandler: " .. (GamePassHandler and "✅ Connected" or "❌ Not found"))
				print("  MarketplaceHandler: " .. (MarketplaceHandler and "✅ Connected" or "❌ Not found"))
				print("  PlayerTempBoosts: " .. (_G.PlayerTempBoosts and "✅ Available" or "❌ Not found"))
			end
		end
	end)
end)

-- Periodic data saving (every 5 minutes)
spawn(function()
	while true do
		wait(300) -- 5 minutes
		for player, data in pairs(CoinCollectorModule.playerData) do
			if player and player.Parent then
				CoinCollectorModule.savePlayerData(player)
			end
		end
		print("💾 Periodic data save completed")
	end
end)

-- Show leaderboard periodically (every 2 minutes when no game is active)
spawn(function()
	while true do
		wait(120) -- 2 minutes
		if not CoinCollectorModule.gameActive then
			local topPlayers = CoinCollectorModule.getTopPlayers(3)
			if #topPlayers > 0 then
				print("🏆 CURRENT TOP 3 LEADERBOARD:")
				for _, playerInfo in ipairs(topPlayers) do
					print(playerInfo.rank .. ". " .. playerInfo.name .. " - " .. playerInfo.score .. " points")
				end
			end
		end
	end
end)

-- Initialize the game
print("🎮 Enhanced Coin Collector Game with Full Marketplace Integration Loaded!")
print("💾 DataStore integration active - player data will be saved!")
print("🛒 GamePass integration active - waiting for GamePass Handler...")
print("💰 Developer Products integration active - waiting for MarketplaceHandler...")
print("⏰ Game will start in 5 seconds...")

-- Auto-start the game
task.wait(5)
print("🚀 Starting first game...")
startGame()