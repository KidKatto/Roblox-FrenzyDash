-- @ScriptType: Script  
-- FIXED MarketplaceScript - Updated magic key creation
-- Place this script in ServerScriptService
--works
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Wait for dependencies
local CoinCollectorModule = require(ReplicatedStorage:WaitForChild("CoinCollectorModule"))

-- Wait for GamePass Handler to be available
local GamePassHandler = nil
spawn(function()
	while not _G.GamePassHandler do
		wait(0.1)
	end
	GamePassHandler = _G.GamePassHandler
	print("💰 MarketplaceScript connected to GamePass Handler!")
end)

-- Developer Product Configuration - Replace with your actual IDs
local DEVELOPER_PRODUCTS = {
	BUY_COFFEE = 3378102552,        -- Donation product
	MAGIC_KEY_SPAWN = 3378083377,   -- Spawn magic key instantly
	SPEED_BOOST_TEMP = 3378077493   -- Temporary speed boost for 10 minutes
}

-- Store temporary boosts for players
local playerTempBoosts = {}

-- FIXED: Function to create a magic key using the module's function
local function createMagicKeyForProduct()
	-- Check if game is active and has space
	if not CoinCollectorModule.gameActive then
		return false, "Game is not currently active"
	end

	if #CoinCollectorModule.coins >= CoinCollectorModule.MAX_COINS then
		return false, "Maximum items on map reached"
	end

	-- Use the module's createMagicKey function directly
	CoinCollectorModule.createMagicKey()

	return true, "Magic Key spawned successfully!"
end

-- Function to show multiplier effect for speed boost
local function showSpeedBoostEffect(player)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end

	-- Create BillboardGui for the speed boost effect
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(4, 0, 2, 0)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.Parent = character.HumanoidRootPart

	-- Main frame for the effect
	local effectFrame = Instance.new("Frame")
	effectFrame.Size = UDim2.new(1, 0, 1, 0)
	effectFrame.BackgroundTransparency = 1
	effectFrame.Parent = billboardGui

	-- Speed boost text
	local multiplierLabel = Instance.new("TextLabel")
	multiplierLabel.Size = UDim2.new(1, 0, 0.6, 0)
	multiplierLabel.Position = UDim2.new(0, 0, 0, 0)
	multiplierLabel.BackgroundTransparency = 1
	multiplierLabel.Text = "🚀 2X SPEED! 🚀"
	multiplierLabel.TextColor3 = Color3.fromRGB(255, 69, 0)
	multiplierLabel.TextScaled = true
	multiplierLabel.Font = Enum.Font.SourceSansBold
	multiplierLabel.TextStrokeTransparency = 0
	multiplierLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	multiplierLabel.Parent = effectFrame

	-- Duration text
	local durationLabel = Instance.new("TextLabel")
	durationLabel.Size = UDim2.new(1, 0, 0.4, 0)
	durationLabel.Position = UDim2.new(0, 0, 0.6, 0)
	durationLabel.BackgroundTransparency = 1
	durationLabel.Text = "10 MINUTES!"
	durationLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
	durationLabel.TextScaled = true
	durationLabel.Font = Enum.Font.SourceSans
	durationLabel.TextStrokeTransparency = 0
	durationLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	durationLabel.Parent = effectFrame

	-- Scale and fade animations
	local scaleInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local scaleTween = TweenService:Create(effectFrame, scaleInfo, {Size = UDim2.new(1.5, 0, 1.5, 0)})

	local floatInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local floatTween = TweenService:Create(billboardGui, floatInfo, {StudsOffset = Vector3.new(0, 8, 0)})

	local fadeInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeTween = TweenService:Create(multiplierLabel, fadeInfo, {TextTransparency = 1})
	local fadePointsTween = TweenService:Create(durationLabel, fadeInfo, {TextTransparency = 1})

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

-- Function to process developer product purchases
local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

	-- If player left the game, we can't process the purchase
	if not player then
		print("⚠️ Player left game before purchase could be processed")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId
	local purchaseId = receiptInfo.PurchaseId

	print("💰 Processing purchase for " .. player.Name .. " - Product ID: " .. productId)

	-- Handle different developer products
	if productId == DEVELOPER_PRODUCTS.BUY_COFFEE then
		-- Donation product - just thank the player
		print("☕ " .. player.Name .. " bought coffee! Thank you for the donation!")

		-- Show thank you message to all players
		for _, p in pairs(Players:GetPlayers()) do
			pcall(function()
				local StarterGui = game:GetService("StarterGui")
				StarterGui:SetCore("ChatMakeSystemMessage", {
					Text = "☕ " .. player.Name .. " bought the developer coffee! Thanks for the support!";
					Color = Color3.fromRGB(255, 215, 0);
				})
			end)
		end

		return Enum.ProductPurchaseDecision.PurchaseGranted

	elseif productId == DEVELOPER_PRODUCTS.MAGIC_KEY_SPAWN then
		-- Spawn Magic Key instantly (only if game is active)
		local success, message = createMagicKeyForProduct()

		if success then
			print("🗝️ " .. player.Name .. " spawned a Magic Key!")

			-- Notify all players about the magic key
			for _, p in pairs(Players:GetPlayers()) do
				-- Show the magic key notification
				CoinCollectorModule.showMagicKeyNotification(p)

				-- Also show chat message
				pcall(function()
					game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
						Text = "🗝️ " .. player.Name .. " spawned a Magic Key! Find it quickly!";
						Color = Color3.fromRGB(255, 215, 0);
					})
				end)
			end
		else
			-- Cannot spawn - inform player
			print("❌ Cannot spawn Magic Key: " .. message)

			-- Notify the player
			pcall(function()
				local StarterGui = game:GetService("StarterGui")
				StarterGui:SetCore("ChatMakeSystemMessage", {
					Text = "❌ " .. message .. " Please try again when a game is active.";
					Color = Color3.fromRGB(255, 100, 100);
				})
			end)

			-- Return NotProcessedYet so they can retry
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		return Enum.ProductPurchaseDecision.PurchaseGranted

	elseif productId == DEVELOPER_PRODUCTS.SPEED_BOOST_TEMP then
		-- Give temporary speed boost for 10 minutes
		if not playerTempBoosts[player] then
			playerTempBoosts[player] = {}
		end

		playerTempBoosts[player].speedBoost = true
		playerTempBoosts[player].speedBoostExpiry = tick() + 600 -- 10 minutes expiry

		-- Apply speed boost immediately if player has character
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = 32 -- 2x speed boost
				print("🏃 Applied temporary speed boost to " .. player.Name)
			end
		end

		-- Show special effect
		showSpeedBoostEffect(player)

		print("🏃 " .. player.Name .. " purchased temporary speed boost!")

		-- Notify the player
		pcall(function()
			local StarterGui = game:GetService("StarterGui")
			StarterGui:SetCore("ChatMakeSystemMessage", {
				Text = "🚀 Speed Boost activated! 2x speed for 10 minutes!";
				Color = Color3.fromRGB(0, 255, 100);
			})
		end)

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Unknown product ID
	warn("❌ Unknown product ID: " .. productId .. " for player " .. player.Name)
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Set the ProcessReceipt callback
MarketplaceService.ProcessReceipt = processReceipt

-- Function to apply temporary boosts when character spawns
local function applyTemporaryBoosts(player)
	if playerTempBoosts[player] then
		local currentTime = tick()

		-- Apply speed boost if it exists and hasn't expired
		if playerTempBoosts[player].speedBoost and 
			playerTempBoosts[player].speedBoostExpiry and 
			currentTime < playerTempBoosts[player].speedBoostExpiry then

			local character = player.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = 32 -- 2x speed
					print("🏃 Restored temporary speed boost to " .. player.Name)
				end
			end
		else
			-- Clean up expired boosts
			if playerTempBoosts[player].speedBoost and 
				playerTempBoosts[player].speedBoostExpiry and 
				currentTime >= playerTempBoosts[player].speedBoostExpiry then
				playerTempBoosts[player].speedBoost = nil
				playerTempBoosts[player].speedBoostExpiry = nil
				print("⏰ Speed boost expired for " .. player.Name)
			end
		end
	end
end

-- Function to clean up expired temporary boosts
local function cleanupExpiredBoosts()
	local currentTime = tick()

	for player, boosts in pairs(playerTempBoosts) do
		if boosts.speedBoost and boosts.speedBoostExpiry and currentTime >= boosts.speedBoostExpiry then
			boosts.speedBoost = nil
			boosts.speedBoostExpiry = nil

			-- Reset speed if player is still in game
			if player and player.Parent then
				local character = player.Character
				if character then
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						-- Check if player has permanent speed boost from game pass
						local hasPermSpeedBoost = GamePassHandler and 
							GamePassHandler.playerGamePasses[player] and 
							GamePassHandler.playerGamePasses[player].SPEED_BOOST

						humanoid.WalkSpeed = hasPermSpeedBoost and 24 or 16
						print("⏰ Temporary speed boost expired for " .. player.Name .. " - reset to " .. humanoid.WalkSpeed)
					end
				end
			end
		end
	end
end

-- Global access for temporary boosts (used by other scripts if needed)
_G.PlayerTempBoosts = {
	getPlayerBoosts = function(player)
		return playerTempBoosts[player] or {}
	end,

	hasTemporarySpeedBoost = function(player)
		if not playerTempBoosts[player] then return false end
		local currentTime = tick()
		return playerTempBoosts[player].speedBoost and 
			playerTempBoosts[player].speedBoostExpiry and 
			currentTime < playerTempBoosts[player].speedBoostExpiry
	end,

	getRemainingSpeedBoostTime = function(player)
		if not playerTempBoosts[player] or not playerTempBoosts[player].speedBoostExpiry then
			return 0
		end
		local currentTime = tick()
		local remaining = playerTempBoosts[player].speedBoostExpiry - currentTime
		return math.max(0, remaining)
	end
}

-- Handle player events
Players.PlayerAdded:Connect(function(player)
	-- Apply temporary boosts when character spawns
	player.CharacterAdded:Connect(function()
		wait(1) -- Wait for character to fully load
		applyTemporaryBoosts(player)
	end)
end)

-- Handle players already in game
for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		applyTemporaryBoosts(player)
	end
end

-- Clean up when players leave
Players.PlayerRemoving:Connect(function(player)
	if playerTempBoosts[player] then
		playerTempBoosts[player] = nil
	end
end)

-- Periodic cleanup of expired boosts (every 30 seconds)
spawn(function()
	while true do
		wait(30)
		cleanupExpiredBoosts()
	end
end)

-- Handle PromptPurchase requests from the store GUI
local function promptPurchase(player, productId)
	local success, error = pcall(function()
		MarketplaceService:PromptProductPurchase(player, productId)
	end)

	if not success then
		warn("Failed to prompt purchase for product " .. productId .. ": " .. tostring(error))

		-- Show error message to player
		pcall(function()
			local StarterGui = game:GetService("StarterGui")
			StarterGui:SetCore("ChatMakeSystemMessage", {
				Text = "⚠️ Store Error: Could not open purchase prompt. Please try again.";
				Color = Color3.fromRGB(255, 100, 100);
			})
		end)
	else
		print("💳 Prompted purchase for product " .. productId .. " to " .. player.Name)
	end
end

-- Store the prompt function globally so the store GUI can access it
_G.MarketplaceHandler = {
	promptPurchase = promptPurchase,
	getDeveloperProducts = function()
		return DEVELOPER_PRODUCTS
	end,
	getPlayerBoosts = function(player)
		return playerTempBoosts[player] or {}
	end,
	createMagicKey = createMagicKeyForProduct
}

print("💰 FIXED MarketplaceScript loaded!")
print("💳 Developer Products configured:")
for productName, productId in pairs(DEVELOPER_PRODUCTS) do
	print("  - " .. productName .. " (ID: " .. productId .. ")")
end
print("🔧 Remember to replace product IDs with your actual ones!")
print("📋 ProcessReceipt callback is set and ready!")
print("🔗 Global MarketplaceHandler created for GUI integration")