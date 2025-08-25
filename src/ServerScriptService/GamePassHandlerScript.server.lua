-- @ScriptType: Script
-- Enhanced GamePass Handler - Better integration with Developer Products
-- Place this script in ServerScriptService
-- works
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Import the CoinCollectorModule
local CoinCollectorModule = require(ReplicatedStorage:WaitForChild("CoinCollectorModule"))

-- GamePass Configuration - Replace these with your actual GamePass IDs
local GAME_PASS_IDS = {
	BUY_ME_COFFEE = 1404855921,   	-- donation
	LUCKY_CHARM = 1405345153,     	-- 2x Magic Key spawn chance
	DONATE_4_FUN = 1405584482,     	-- donation
	SPEED_BOOST = 1413395225,		-- permanent 1.5x walk speed
	VIP_STATUS = 1413555385			-- VIP status and tag
}

-- Store player game pass ownership
local playerGamePasses = {}

-- Function to check if a player owns a game pass
local function playerOwnsGamePass(player, gamePassId)
	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
	end)
	return success and hasPass
end

-- Function to load all game passes for a player
local function loadPlayerGamePasses(player)
	if not playerGamePasses[player] then
		playerGamePasses[player] = {}
	end

	for passName, passId in pairs(GAME_PASS_IDS) do
		playerGamePasses[player][passName] = playerOwnsGamePass(player, passId)
		if playerGamePasses[player][passName] then
			print("✅ " .. player.Name .. " owns " .. passName .. " game pass")
		end
	end
end

-- Function to apply speed boost (considering both permanent and temporary)
local function applySpeedBoost(player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local baseSpeed = 16
	local finalSpeed = baseSpeed

	-- Check for permanent speed boost from game pass
	if playerGamePasses[player] and playerGamePasses[player].SPEED_BOOST then
		finalSpeed = baseSpeed * 1.5 -- 24
		print("🏃 Applied permanent speed boost to " .. player.Name .. " (1.5x)")
	end

	-- Check for temporary speed boost from developer products
	if _G.PlayerTempBoosts and _G.PlayerTempBoosts.hasTemporarySpeedBoost(player) then
		finalSpeed = baseSpeed * 2 -- 32 (temporary overrides permanent if active)
		print("🚀 Applied temporary speed boost to " .. player.Name .. " (2x)")
	end

	humanoid.WalkSpeed = finalSpeed
end

-- Function to apply VIP effects
local function applyVIPEffects(player)
	if playerGamePasses[player] and playerGamePasses[player].VIP_STATUS then
		-- Add VIP tag to leaderstats
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local vipTag = leaderstats:FindFirstChild("VIP")
			if not vipTag then
				local vipValue = Instance.new("StringValue")
				vipValue.Name = "VIP"
				vipValue.Value = "⭐VIP⭐"
				vipValue.Parent = leaderstats
				print("⭐ Applied VIP tag to " .. player.Name)
			end
		end

		-- Add special VIP chat tag (if possible)
		pcall(function()
			local ChatService = require(game:GetService("ServerScriptService"):WaitForChild("ChatServiceRunner"):WaitForChild("ChatService"))
			local speaker = ChatService:GetSpeaker(player.Name)
			if speaker then
				speaker:SetExtraData("Tags", {{TagText = "VIP", TagColor = Color3.fromRGB(255, 215, 0)}})
			end
		end)

		-- Add VIP particle effect
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local existingEffect = character.HumanoidRootPart:FindFirstChild("VIPEffect")
			if not existingEffect then
				local attachment = Instance.new("Attachment")
				attachment.Name = "VIPEffect"
				attachment.Parent = character.HumanoidRootPart

				-- Golden sparkles for VIP
				local sparkles = Instance.new("ParticleEmitter")
				sparkles.Texture = "rbxassetid://241650934"
				sparkles.Lifetime = NumberRange.new(0.8, 1.2)
				sparkles.Rate = 10
				sparkles.SpreadAngle = Vector2.new(360, 360)
				sparkles.Speed = NumberRange.new(2, 4)
				sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
				sparkles.Size = NumberSequence.new{
					NumberSequenceKeypoint.new(0, 0.1),
					NumberSequenceKeypoint.new(0.5, 0.3),
					NumberSequenceKeypoint.new(1, 0)
				}
				sparkles.Parent = attachment
				print("✨ Added VIP particle effect to " .. player.Name)
			end
		end
	end
end

-- Function to check if any player has a game pass
local function anyPlayerHasGamePass(gamePassType)
	for player, gamePasses in pairs(playerGamePasses) do
		if player.Parent and gamePasses and gamePasses[gamePassType] then
			return true
		end
	end
	return false
end

-- Function to modify coin collection with game pass bonuses
local function applyGamePassBonuses(player, originalPoints, isMagicKey)
	local bonusPoints = originalPoints
	local effectsToShow = {}

	-- Apply 2x points multiplier (if we had this game pass)
	-- if playerGamePasses[player] and playerGamePasses[player].DOUBLE_POINTS then
	--     bonusPoints = bonusPoints * 2
	--     table.insert(effectsToShow, "💰 2X POINTS!")
	--     print("💰 " .. player.Name .. " has 2x Points! Doubled from " .. originalPoints .. " to " .. bonusPoints)
	-- end

	-- VIP players get a small bonus
	if playerGamePasses[player] and playerGamePasses[player].VIP_STATUS then
		bonusPoints = math.floor(bonusPoints * 1.1) -- 10% bonus for VIPs
		table.insert(effectsToShow, "⭐ VIP BONUS!")
		print("⭐ " .. player.Name .. " has VIP bonus! Points: " .. originalPoints .. " -> " .. bonusPoints)
	end

	-- Show bonus effects
	if #effectsToShow > 0 then
		spawn(function()
			local character = player.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				local billboardGui = Instance.new("BillboardGui")
				billboardGui.Size = UDim2.new(2, 0, 1, 0)
				billboardGui.StudsOffset = Vector3.new(0, 5, 0)
				billboardGui.Parent = character.HumanoidRootPart

				local effectLabel = Instance.new("TextLabel")
				effectLabel.Size = UDim2.new(1, 0, 1, 0)
				effectLabel.BackgroundTransparency = 1
				effectLabel.Text = table.concat(effectsToShow, " ")
				effectLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
				effectLabel.TextScaled = true
				effectLabel.Font = Enum.Font.SourceSansBold
				effectLabel.TextStrokeTransparency = 0
				effectLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
				effectLabel.Parent = billboardGui

				-- Animate the effect
				local fadeInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				local fadeTween = TweenService:Create(effectLabel, fadeInfo, {TextTransparency = 1})
				local floatTween = TweenService:Create(billboardGui, fadeInfo, {StudsOffset = Vector3.new(0, 10, 0)})

				floatTween:Play()
				fadeTween:Play()

				wait(1.5)
				if billboardGui and billboardGui.Parent then
					billboardGui:Destroy()
				end
			end
		end)
	end

	return bonusPoints
end

-- Store original values
local originalMagicKeyChance = CoinCollectorModule.MAGIC_KEY_SPAWN_CHANCE
local originalGameDuration = CoinCollectorModule.GAME_DURATION

-- Function to update game settings based on active game passes
local function updateGameSettings()
	-- Update magic key spawn chance
	if anyPlayerHasGamePass("LUCKY_CHARM") then
		CoinCollectorModule.MAGIC_KEY_SPAWN_CHANCE = originalMagicKeyChance * 2
		print("🍀 Lucky Charm active! Magic key chance: " .. CoinCollectorModule.MAGIC_KEY_SPAWN_CHANCE .. " (" .. (CoinCollectorModule.MAGIC_KEY_SPAWN_CHANCE * 100) .. "%)")
	else
		CoinCollectorModule.MAGIC_KEY_SPAWN_CHANCE = originalMagicKeyChance
	end

	-- Could add other game modifications here based on game passes
	-- Example: Extended time, more coins, different spawn rates, etc.
end

-- Create custom coin collection handler
local function handleCoinCollection(player, points, isMagicKey)
	if playerGamePasses[player] then
		local bonusPoints = applyGamePassBonuses(player, points, isMagicKey)
		return bonusPoints
	end
	return points
end

-- Function to handle character-based effects
local function onCharacterAdded(player, character)
	-- Wait a moment for character to fully load
	wait(1)

	-- Apply speed boost (considering both permanent and temporary)
	applySpeedBoost(player)

	-- Apply VIP effects
	applyVIPEffects(player)

	-- Monitor for temporary boost changes
	spawn(function()
		while character.Parent do
			wait(5) -- Check every 5 seconds
			applySpeedBoost(player) -- This will handle the priority system
		end
	end)
end

-- Store reference to apply bonus points and other functions
_G.GamePassHandler = {
	applyGamePassBonuses = applyGamePassBonuses,
	handleCoinCollection = handleCoinCollection,
	updateGameSettings = updateGameSettings,
	anyPlayerHasGamePass = anyPlayerHasGamePass,
	playerGamePasses = playerGamePasses,
	applySpeedBoost = applySpeedBoost,
	applyVIPEffects = applyVIPEffects,
	loadPlayerGamePasses = loadPlayerGamePasses
}

-- Player management
Players.PlayerAdded:Connect(function(player)
	-- Load game passes
	loadPlayerGamePasses(player)
	updateGameSettings()

	-- Apply effects when character spawns
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end)

-- Handle players already in game
for _, player in ipairs(Players:GetPlayers()) do
	loadPlayerGamePasses(player)
	updateGameSettings()

	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

-- Clean up when players leave
Players.PlayerRemoving:Connect(function(player)
	if playerGamePasses[player] then
		playerGamePasses[player] = nil
	end
	updateGameSettings() -- Update settings when players leave
end)

-- Handle game pass purchases in real-time
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if wasPurchased then
		print("🎉 " .. player.Name .. " purchased game pass ID: " .. gamePassId)

		-- Reload player's game passes
		loadPlayerGamePasses(player)
		updateGameSettings()

		-- Apply effects immediately if character exists
		if player.Character then
			onCharacterAdded(player, player.Character)
		end

		-- Show purchase confirmation message to all players
		for _, p in pairs(Players:GetPlayers()) do
			pcall(function()
				local StarterGui = game:GetService("StarterGui")
				StarterGui:SetCore("ChatMakeSystemMessage", {
					Text = "🎉 " .. player.Name .. " purchased a GamePass! Thank you for your support!";
					Color = Color3.fromRGB(0, 255, 100);
				})
			end)
		end
	end
end)

-- Admin commands for testing game passes
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if player.Name == "YourUsernameHere" then -- Replace with your username
			local command = message:lower()

			if command == "/testgamepasses" then
				print("🧪 Testing game pass ownership for " .. player.Name .. ":")
				for passName, passId in pairs(GAME_PASS_IDS) do
					local hasPass = playerGamePasses[player] and playerGamePasses[player][passName]
					print("  " .. passName .. " (" .. passId .. "): " .. tostring(hasPass))
				end

			elseif command == "/reloadpasses" then
				loadPlayerGamePasses(player)
				updateGameSettings()
				if player.Character then
					onCharacterAdded(player, player.Character)
				end
				print("🔄 Reloaded game passes for " .. player.Name)

			elseif command == "/vipeffects" then
				applyVIPEffects(player)
				print("⭐ Applied VIP effects to " .. player.Name)

			elseif command == "/speedboost" then
				applySpeedBoost(player)
				print("🏃 Applied speed boost to " .. player.Name)

			elseif command == "/gamesettings" then
				print("🎮 Current game settings:")
				print("  Magic Key Chance: " .. CoinCollectorModule.MAGIC_KEY_SPAWN_CHANCE .. " (" .. (CoinCollectorModule.MAGIC_KEY_SPAWN_CHANCE * 100) .. "%)")
				print("  Game Duration: " .. CoinCollectorModule.GAME_DURATION)
				print("  Lucky Charm Active: " .. tostring(anyPlayerHasGamePass("LUCKY_CHARM")))

			elseif command == "/tempboosts" then
				if _G.PlayerTempBoosts then
					local boosts = _G.PlayerTempBoosts.getPlayerBoosts(player)
					print("⚡ Temporary boosts for " .. player.Name .. ":")
					if _G.PlayerTempBoosts.hasTemporarySpeedBoost(player) then
						print("  Temporary Speed Boost: ACTIVE")
					else
						print("  Temporary Speed Boost: None")
					end
				else
					print("❌ PlayerTempBoosts not available")
				end

			elseif command == "/refresheffects" then
				if player.Character then
					onCharacterAdded(player, player.Character)
					print("🔄 Refreshed all effects for " .. player.Name)
				else
					print("❌ No character found")
				end

			elseif command == "/checkspeed" then
				local character = player.Character
				if character then
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						print("🏃 Current speed for " .. player.Name .. ": " .. humanoid.WalkSpeed)
						print("  Permanent boost: " .. tostring(playerGamePasses[player] and playerGamePasses[player].SPEED_BOOST))
						if _G.PlayerTempBoosts then
							print("  Temporary boost: " .. tostring(_G.PlayerTempBoosts.hasTemporarySpeedBoost(player)))
						end
					end
				end
			end
		end
	end)
end)

-- Update settings periodically in case of changes
spawn(function()
	while true do
		wait(30) -- Check every 30 seconds
		updateGameSettings()
	end
end)

-- Monitor temporary boosts and refresh speed accordingly
spawn(function()
	while true do
		wait(10) -- Check every 10 seconds
		for player, _ in pairs(playerGamePasses) do
			if player and player.Parent and player.Character then
				applySpeedBoost(player) -- This handles the priority system
			end
		end
	end
end)

print("🎮 Enhanced GamePass Handler loaded!")
print("🛒 Available GamePasses:")
for passName, passId in pairs(GAME_PASS_IDS) do
	print("  - " .. passName .. " (ID: " .. passId .. ")")
end
print("📝 Remember to replace GamePass IDs with your actual ones!")
print("🔧 Game settings will be updated automatically based on player ownership")
print("⚡ Integrated with temporary boost system from MarketplaceScript")