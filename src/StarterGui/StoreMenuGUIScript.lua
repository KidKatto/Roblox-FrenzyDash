-- @ScriptType: LocalScript
-- IMPROVED Store Menu GUI - Better MarketplaceHandler Integration
-- Place this LocalScript in StarterGui
-- sync?

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Store Configuration - Replace these with your actual GamePass IDs
local GAME_PASSES = {
	{
		id = 1413395225, 
		name = "Speed Boost",
		description = "Permanent 1.5x walking speed! 🏃",
		price = 200,
		icon = "🏃",
		color = Color3.fromRGB(0, 191, 255),
		type = "gamepass"
	},
	{
		id = 1405345153,
		name = "Lucky Charm",
		description = "2x Magic Key spawn chance! 🍀",
		price = 300,
		icon = "🍀",
		color = Color3.fromRGB(50, 205, 50),
		type = "gamepass"
	},	
	{
		id = 1413555385,
		name = "VIP Status",
		description = "Get VIP status and special recognition! ⭐",
		price = 500,
		icon = "⭐",
		color = Color3.fromRGB(255, 215, 0),
		type = "gamepass"
	}
}

-- Developer Products Configuration - Replace with your actual Developer Product IDs
local DEVELOPER_PRODUCTS = {
	{
		id = 3378102552,
		name = "Buy Developer Coffee",
		description = "Support the developer with a coffee! ☕",
		price = 25,
		icon = "☕",
		color = Color3.fromRGB(139, 69, 19),
		type = "product"
	},
	{
		id = 3378083377,
		name = "Instant Magic Key",
		description = "Spawn a Magic Key in the current game! 🗝️",
		price = 15,
		icon = "🗝️",
		color = Color3.fromRGB(255, 215, 0),
		type = "product"
	},
	{
		id = 3378077493,
		name = "Speedy Boots",
		description = "Get 2x speed for 10 minutes! 🚀",
		price = 20,
		icon = "🚀",
		color = Color3.fromRGB(255, 69, 0),
		type = "product"
	}
}

-- Combine all items for the store
local ALL_STORE_ITEMS = {}
for _, item in ipairs(GAME_PASSES) do
	table.insert(ALL_STORE_ITEMS, item)
end
for _, item in ipairs(DEVELOPER_PRODUCTS) do
	table.insert(ALL_STORE_ITEMS, item)
end

-- MarketplaceHandler connection with better error handling
local MarketplaceHandler = nil
local handlerConnectionAttempts = 0
local maxConnectionAttempts = 60 -- 30 seconds at 0.5 second intervals

-- Improved MarketplaceHandler connection
local function connectToMarketplaceHandler()
	spawn(function()
		print("🔄 Attempting to connect to MarketplaceHandler...")

		while not MarketplaceHandler and handlerConnectionAttempts < maxConnectionAttempts do
			wait(0.5)
			handlerConnectionAttempts = handlerConnectionAttempts + 1

			if _G.MarketplaceHandler then
				if _G.MarketplaceHandler.isReady and _G.MarketplaceHandler.isReady() then
					MarketplaceHandler = _G.MarketplaceHandler
					print("✅ Store GUI successfully connected to MarketplaceHandler!")
					break
				else
					print("⚠️ MarketplaceHandler exists but not ready yet...")
				end
			end
		end

		if not MarketplaceHandler then
			warn("❌ Failed to connect to MarketplaceHandler after " .. maxConnectionAttempts .. " attempts")
			warn("❌ Make sure MarketplaceScript is running in ServerScriptService!")
		end
	end)
end

-- Start connection attempt
connectToMarketplaceHandler()

-- Safe SetCore function with comprehensive error handling
local function safeSetCore(coreType, data)
	spawn(function()
		local success, errorMsg = pcall(function()
			StarterGui:SetCore(coreType, data)
		end)

		if not success then
			warn("SetCore failed for " .. coreType .. ": " .. tostring(errorMsg))
			-- Fallback: use print for important messages
			if coreType == "ChatMakeSystemMessage" then
				print("[STORE MESSAGE] " .. (data.Text or tostring(data)))
			end
		end
	end)
end

-- Function to check MarketplaceHandler status
local function checkHandlerStatus()
	if not MarketplaceHandler then
		safeSetCore("ChatMakeSystemMessage", {
			Text = "⚠️ Store Error: MarketplaceHandler not connected. Please wait or rejoin.";
			Color = Color3.fromRGB(255, 100, 100);
		})
		return false
	end
	return true
end

-- Create the main store GUI
local function createStoreGUI()
	-- Remove existing store GUI if it exists
	local existingStore = playerGui:FindFirstChild("StoreGUI")
	if existingStore then
		existingStore:Destroy()
	end

	-- Main ScreenGui
	local storeGui = Instance.new("ScreenGui")
	storeGui.Name = "StoreGUI"
	storeGui.ResetOnSpawn = false
	storeGui.Parent = playerGui

	-- Store Button (Toggle)
	local storeButton = Instance.new("TextButton")
	storeButton.Name = "StoreButton"
	storeButton.Size = UDim2.new(0, 70, 0, 90)
	storeButton.Position = UDim2.new(0, 10, 0.5, -45)
	storeButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	storeButton.BorderSizePixel = 0
	storeButton.Text = "🛒\nSTORE"
	storeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	storeButton.TextScaled = true
	storeButton.Font = Enum.Font.SourceSansBold
	storeButton.Parent = storeGui

	-- Store button corner
	local storeButtonCorner = Instance.new("UICorner")
	storeButtonCorner.CornerRadius = UDim.new(0, 12)
	storeButtonCorner.Parent = storeButton

	-- Status indicator on store button
	local statusIndicator = Instance.new("Frame")
	statusIndicator.Name = "StatusIndicator"
	statusIndicator.Size = UDim2.new(0, 12, 0, 12)
	statusIndicator.Position = UDim2.new(1, -15, 0, 3)
	statusIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red by default
	statusIndicator.BorderSizePixel = 0
	statusIndicator.Parent = storeButton

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0, 6)
	statusCorner.Parent = statusIndicator

	-- Function to update status indicator
	local function updateStatusIndicator()
		if MarketplaceHandler then
			statusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green = connected
		else
			statusIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red = disconnected
		end
	end

	-- Store Panel (Initially hidden)
	local storePanel = Instance.new("Frame")
	storePanel.Name = "StorePanel"
	storePanel.Size = UDim2.new(0, 0, 0.85, 0) -- Start collapsed
	storePanel.Position = UDim2.new(0, 90, 0.075, 0)
	storePanel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	storePanel.BackgroundTransparency = 0.1
	storePanel.BorderSizePixel = 0
	storePanel.ClipsDescendants = true
	storePanel.Parent = storeGui

	-- Store panel corner
	local storePanelCorner = Instance.new("UICorner")
	storePanelCorner.CornerRadius = UDim.new(0, 15)
	storePanelCorner.Parent = storePanel

	-- Title Section Frame
	local titleFrame = Instance.new("Frame")
	titleFrame.Name = "TitleFrame"
	titleFrame.Size = UDim2.new(1, 0, 0, 80)
	titleFrame.Position = UDim2.new(0, 0, 0, 0)
	titleFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	titleFrame.BorderSizePixel = 0
	titleFrame.Parent = storePanel

	-- Title frame corner (only top corners)
	local titleFrameCorner = Instance.new("UICorner")
	titleFrameCorner.CornerRadius = UDim.new(0, 15)
	titleFrameCorner.Parent = titleFrame

	-- Store Title
	local storeTitle = Instance.new("TextLabel")
	storeTitle.Name = "StoreTitle"
	storeTitle.Size = UDim2.new(1, -100, 1, 0)
	storeTitle.Position = UDim2.new(0, 20, 0, 0)
	storeTitle.BackgroundTransparency = 1
	storeTitle.Text = "🛒 GAME STORE"
	storeTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	storeTitle.TextScaled = true
	storeTitle.Font = Enum.Font.SourceSansBold
	storeTitle.TextXAlignment = Enum.TextXAlignment.Left
	storeTitle.Parent = titleFrame

	-- Close Button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 50, 0, 50)
	closeButton.Position = UDim2.new(1, -65, 0, 15)
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.Parent = titleFrame

	-- Close button corner
	local closeButtonCorner = Instance.new("UICorner")
	closeButtonCorner.CornerRadius = UDim.new(0, 10)
	closeButtonCorner.Parent = closeButton

	-- Connection Status Panel
	local statusPanel = Instance.new("Frame")
	statusPanel.Name = "StatusPanel"
	statusPanel.Size = UDim2.new(1, -20, 0, 30)
	statusPanel.Position = UDim2.new(0, 10, 0, 85)
	statusPanel.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	statusPanel.BorderSizePixel = 0
	statusPanel.Parent = storePanel

	local statusPanelCorner = Instance.new("UICorner")
	statusPanelCorner.CornerRadius = UDim.new(0, 5)
	statusPanelCorner.Parent = statusPanel

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, -10, 1, 0)
	statusLabel.Position = UDim2.new(0, 5, 0, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "🔄 Connecting to MarketplaceHandler..."
	statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.SourceSans
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = statusPanel

	-- Function to update status label
	local function updateStatusLabel()
		if MarketplaceHandler then
			statusLabel.Text = "✅ Store Ready - All features available!"
			statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
		else
			statusLabel.Text = "⚠️ MarketplaceHandler disconnected - Some features may not work"
			statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		end
	end

	-- Category Tabs Frame
	local tabFrame = Instance.new("Frame")
	tabFrame.Name = "TabFrame"
	tabFrame.Size = UDim2.new(1, 0, 0, 50)
	tabFrame.Position = UDim2.new(0, 0, 0, 125)
	tabFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	tabFrame.BorderSizePixel = 0
	tabFrame.Parent = storePanel

	-- All Items Tab
	local allTab = Instance.new("TextButton")
	allTab.Name = "AllTab"
	allTab.Size = UDim2.new(0.33, -5, 1, -10)
	allTab.Position = UDim2.new(0, 5, 0, 5)
	allTab.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	allTab.BorderSizePixel = 0
	allTab.Text = "ALL ITEMS"
	allTab.TextColor3 = Color3.fromRGB(255, 255, 255)
	allTab.TextScaled = true
	allTab.Font = Enum.Font.SourceSansBold
	allTab.Parent = tabFrame

	local allTabCorner = Instance.new("UICorner")
	allTabCorner.CornerRadius = UDim.new(0, 8)
	allTabCorner.Parent = allTab

	-- GamePasses Tab
	local gamePassTab = Instance.new("TextButton")
	gamePassTab.Name = "GamePassTab"
	gamePassTab.Size = UDim2.new(0.33, -5, 1, -10)
	gamePassTab.Position = UDim2.new(0.33, 2.5, 0, 5)
	gamePassTab.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	gamePassTab.BorderSizePixel = 0
	gamePassTab.Text = "GAME PASSES"
	gamePassTab.TextColor3 = Color3.fromRGB(200, 200, 200)
	gamePassTab.TextScaled = true
	gamePassTab.Font = Enum.Font.SourceSans
	gamePassTab.Parent = tabFrame

	local gamePassTabCorner = Instance.new("UICorner")
	gamePassTabCorner.CornerRadius = UDim.new(0, 8)
	gamePassTabCorner.Parent = gamePassTab

	-- Products Tab
	local productsTab = Instance.new("TextButton")
	productsTab.Name = "ProductsTab"
	productsTab.Size = UDim2.new(0.33, -5, 1, -10)
	productsTab.Position = UDim2.new(0.66, 0, 0, 5)
	productsTab.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	productsTab.BorderSizePixel = 0
	productsTab.Text = "PRODUCTS"
	productsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
	productsTab.TextScaled = true
	productsTab.Font = Enum.Font.SourceSans
	productsTab.Parent = tabFrame

	local productsTabCorner = Instance.new("UICorner")
	productsTabCorner.CornerRadius = UDim.new(0, 8)
	productsTabCorner.Parent = productsTab

	-- Scroll Frame for items
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ItemScroll"
	scrollFrame.Size = UDim2.new(1, -20, 1, -195)
	scrollFrame.Position = UDim2.new(0, 10, 0, 185)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be calculated
	scrollFrame.Parent = storePanel

	-- UI List Layout for scroll frame
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 10)
	listLayout.Parent = scrollFrame

	-- Track current tab and store state
	local currentTab = "all"
	local storeOpen = false

	-- Function to toggle store
	local function toggleStore()
		storeOpen = not storeOpen

		local targetSize = storeOpen and UDim2.new(0, 420, 0.85, 0) or UDim2.new(0, 0, 0.85, 0)
		local targetTransparency = storeOpen and 0.1 or 1

		local tween = TweenService:Create(
			storePanel,
			TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{
				Size = targetSize,
				BackgroundTransparency = targetTransparency
			}
		)
		tween:Play()

		-- Update button appearance
		if storeOpen then
			storeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
			storeButton.Text = "◀\nHIDE"
		else
			storeButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
			storeButton.Text = "🛒\nSTORE"
		end
	end

	-- Function to update tab appearance
	local function updateTabAppearance(selectedTab)
		-- Reset all tabs
		allTab.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
		allTab.TextColor3 = Color3.fromRGB(200, 200, 200)
		allTab.Font = Enum.Font.SourceSans

		gamePassTab.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
		gamePassTab.TextColor3 = Color3.fromRGB(200, 200, 200)
		gamePassTab.Font = Enum.Font.SourceSans

		productsTab.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
		productsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
		productsTab.Font = Enum.Font.SourceSans

		-- Highlight selected tab
		if selectedTab == "all" then
			allTab.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
			allTab.TextColor3 = Color3.fromRGB(255, 255, 255)
			allTab.Font = Enum.Font.SourceSansBold
		elseif selectedTab == "gamepasses" then
			gamePassTab.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
			gamePassTab.TextColor3 = Color3.fromRGB(255, 255, 255)
			gamePassTab.Font = Enum.Font.SourceSansBold
		elseif selectedTab == "products" then
			productsTab.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
			productsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
			productsTab.Font = Enum.Font.SourceSansBold
		end
	end

	-- Function to check if player owns a game pass
	local function checkGamePassOwnership(gamePassId)
		local success, hasPass = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
		end)
		return success and hasPass
	end

	-- IMPROVED: Function to prompt game pass purchase with better error handling
	local function promptGamePassPurchase(gamePassId)
		print("🎫 Attempting GamePass purchase for ID:", gamePassId)

		local success, errorMsg = pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, gamePassId)
		end)

		if not success then
			warn("❌ Failed to prompt GamePass purchase: " .. tostring(errorMsg))
			safeSetCore("ChatMakeSystemMessage", {
				Text = "⚠️ Store Error: Could not open GamePass purchase prompt. Please try again.";
				Color = Color3.fromRGB(255, 100, 100);
			})
		else
			print("✅ Successfully prompted GamePass purchase for ID:", gamePassId)
		end
	end

	-- IMPROVED: Function to prompt developer product purchase with better error handling
	local function promptProductPurchase(productId)
		print("🛍️ Attempting Developer Product purchase for ID:", productId)

		if not checkHandlerStatus() then
			return
		end

		-- Use the MarketplaceHandler's improved promptPurchase function
		MarketplaceHandler.promptPurchase(player, productId)
	end

	-- Function to create a store item
	local function createStoreItem(itemData, index)
		local isGamePass = itemData.type == "gamepass"
		local hasPass = isGamePass and checkGamePassOwnership(itemData.id)

		-- Main item frame
		local itemFrame = Instance.new("Frame")
		itemFrame.Name = itemData.type .. "Item" .. index
		itemFrame.Size = UDim2.new(1, 0, 0, 130)
		itemFrame.BackgroundColor3 = hasPass and Color3.fromRGB(50, 100, 50) or Color3.fromRGB(40, 40, 50)
		itemFrame.BorderSizePixel = 0
		itemFrame.LayoutOrder = index
		itemFrame.Parent = scrollFrame

		-- Item corner
		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 10)
		itemCorner.Parent = itemFrame

		-- Type indicator badge
		local typeBadge = Instance.new("Frame")
		typeBadge.Size = UDim2.new(0, 80, 0, 25)
		typeBadge.Position = UDim2.new(0, 10, 0, 5)
		typeBadge.BackgroundColor3 = isGamePass and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(255, 140, 0)
		typeBadge.BorderSizePixel = 0
		typeBadge.Parent = itemFrame

		local typeBadgeCorner = Instance.new("UICorner")
		typeBadgeCorner.CornerRadius = UDim.new(0, 5)
		typeBadgeCorner.Parent = typeBadge

		local typeLabel = Instance.new("TextLabel")
		typeLabel.Size = UDim2.new(1, 0, 1, 0)
		typeLabel.BackgroundTransparency = 1
		typeLabel.Text = isGamePass and "PASS" or "ITEM"
		typeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		typeLabel.TextScaled = true
		typeLabel.Font = Enum.Font.SourceSansBold
		typeLabel.Parent = typeBadge

		-- Icon frame
		local iconFrame = Instance.new("Frame")
		iconFrame.Size = UDim2.new(0, 80, 0, 80)
		iconFrame.Position = UDim2.new(0, 15, 0, 35)
		iconFrame.BackgroundColor3 = itemData.color
		iconFrame.BorderSizePixel = 0
		iconFrame.Parent = itemFrame

		-- Icon corner
		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(0, 10)
		iconCorner.Parent = iconFrame

		-- Icon text/emoji
		local iconImage = Instance.new("TextLabel")
		iconImage.Size = UDim2.new(1, 0, 1, 0)
		iconImage.BackgroundTransparency = 1
		iconImage.Text = hasPass and "✓" or itemData.icon
		iconImage.TextColor3 = Color3.fromRGB(255, 255, 255)
		iconImage.TextScaled = true
		iconImage.Font = Enum.Font.SourceSansBold
		iconImage.Parent = iconFrame

		-- Title label
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, -110, 0, 35)
		titleLabel.Position = UDim2.new(0, 105, 0, 15)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = itemData.name
		titleLabel.TextColor3 = hasPass and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 255, 255)
		titleLabel.TextScaled = true
		titleLabel.Font = Enum.Font.SourceSansBold
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.Parent = itemFrame

		-- Description label
		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -110, 0, 50)
		descLabel.Position = UDim2.new(0, 105, 0, 45)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = itemData.description
		descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		descLabel.TextScaled = true
		descLabel.Font = Enum.Font.SourceSans
		descLabel.TextWrapped = true
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.Parent = itemFrame

		-- Purchase/Status button
		local purchaseButton = Instance.new("TextButton")
		purchaseButton.Size = UDim2.new(0, 90, 0, 35)
		purchaseButton.Position = UDim2.new(1, -100, 0, 85)
		purchaseButton.BorderSizePixel = 0
		purchaseButton.TextScaled = true
		purchaseButton.Font = Enum.Font.SourceSansBold
		purchaseButton.Parent = itemFrame

		-- Purchase button corner
		local purchaseCorner = Instance.new("UICorner")
		purchaseCorner.CornerRadius = UDim.new(0, 8)
		purchaseCorner.Parent = purchaseButton

		-- Configure button based on type and ownership
		if hasPass then
			purchaseButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
			purchaseButton.TextColor3 = Color3.fromRGB(0, 100, 0)
			purchaseButton.Text = "OWNED ✓"
			purchaseButton.Active = false
		else
			if isGamePass then
				purchaseButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
				purchaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
				purchaseButton.Text = "R$ " .. itemData.price

				-- GamePass purchase functionality
				purchaseButton.MouseButton1Click:Connect(function()
					promptGamePassPurchase(itemData.id)
				end)
			else
				-- Developer Product - check if handler is available
				if MarketplaceHandler then
					purchaseButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
					purchaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
					purchaseButton.Text = "R$ " .. itemData.price
				else
					purchaseButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
					purchaseButton.TextColor3 = Color3.fromRGB(150, 150, 150)
					purchaseButton.Text = "UNAVAILABLE"
				end

				-- Developer Product purchase functionality
				purchaseButton.MouseButton1Click:Connect(function()
					promptProductPurchase(itemData.id)
				end)
			end

			-- Hover effects for purchasable items (only if active)
			if MarketplaceHandler or isGamePass then
				purchaseButton.MouseEnter:Connect(function()
					local hoverColor = isGamePass and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 180, 0)
					local hoverTween = TweenService:Create(
						purchaseButton,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad),
						{BackgroundColor3 = hoverColor}
					)
					hoverTween:Play()
				end)

				purchaseButton.MouseLeave:Connect(function()
					local normalColor = isGamePass and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(255, 140, 0)
					if not MarketplaceHandler and not isGamePass then
						normalColor = Color3.fromRGB(100, 100, 100)
					end
					local unhoverTween = TweenService:Create(
						purchaseButton,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad),
						{BackgroundColor3 = normalColor}
					)
					unhoverTween:Play()
				end)
			end
		end

		-- Owned indicator overlay
		if hasPass then
			local ownedOverlay = Instance.new("Frame")
			ownedOverlay.Size = UDim2.new(1, 0, 1, 0)
			ownedOverlay.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			ownedOverlay.BackgroundTransparency = 0.9
			ownedOverlay.BorderSizePixel = 0
			ownedOverlay.Parent = itemFrame

			local ownedCorner = Instance.new("UICorner")
			ownedCorner.CornerRadius = UDim.new(0, 10)
			ownedCorner.Parent = ownedOverlay
		end
	end

	-- Function to populate items based on current tab
	local function populateItems()
		-- Clear existing items
		for _, child in ipairs(scrollFrame:GetChildren()) do
			if child:IsA("Frame") and child ~= listLayout then
				child:Destroy()
			end
		end

		local itemsToShow = {}
		if currentTab == "all" then
			itemsToShow = ALL_STORE_ITEMS
		elseif currentTab == "gamepasses" then
			itemsToShow = GAME_PASSES
		elseif currentTab == "products" then
			itemsToShow = DEVELOPER_PRODUCTS
		end

		-- Create items
		for i, itemData in ipairs(itemsToShow) do
			createStoreItem(itemData, i)
		end

		-- Calculate canvas size for scroll frame
		local totalHeight = (#itemsToShow * 130) + ((#itemsToShow - 1) * 10) + 20
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
	end

	-- Tab switching functionality
	local function switchTab(newTab)
		currentTab = newTab
		updateTabAppearance(newTab)
		populateItems()
	end

	-- Connect tab buttons
	allTab.MouseButton1Click:Connect(function()
		switchTab("all")
	end)

	gamePassTab.MouseButton1Click:Connect(function()
		switchTab("gamepasses")
	end)

	productsTab.MouseButton1Click:Connect(function()
		switchTab("products")
	end)

	-- Connect main buttons
	storeButton.MouseButton1Click:Connect(function()
		toggleStore()
	end)

	closeButton.MouseButton1Click:Connect(function()
		toggleStore()
	end)

	-- Store button hover effects
	storeButton.MouseEnter:Connect(function()
		local hoverTween = TweenService:Create(
			storeButton,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad),
			{Size = UDim2.new(0, 75, 0, 95)}
		)
		hoverTween:Play()
	end)

	storeButton.MouseLeave:Connect(function()
		local unhoverTween = TweenService:Create(
			storeButton,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad),
			{Size = UDim2.new(0, 70, 0, 90)}
		)
		unhoverTween:Play()
	end)

	-- Close store when ESC is pressed
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == Enum.KeyCode.Escape and storeOpen then
			toggleStore()
		end
	end)

	-- Function to refresh store display
	local function refreshStore()
		updateStatusIndicator()
		updateStatusLabel()
		populateItems()
	end

	-- Initialize store with all items
	updateTabAppearance("all")
	populateItems()
	updateStatusIndicator()
	updateStatusLabel()

	-- Monitor MarketplaceHandler connection status
	spawn(function()
		while true do
			wait(2) -- Check every 2 seconds
			local previousStatus = MarketplaceHandler ~= nil

			-- Check if handler became available
			if not MarketplaceHandler and _G.MarketplaceHandler then
				if _G.MarketplaceHandler.isReady and _G.MarketplaceHandler.isReady() then
					MarketplaceHandler = _G.MarketplaceHandler
					print("✅ MarketplaceHandler connection restored!")
					refreshStore()
				end
			end

			-- Update indicators if status changed
			if (MarketplaceHandler ~= nil) ~= previousStatus then
				updateStatusIndicator()
				updateStatusLabel()
				-- Refresh product buttons if handler status changed
				if currentTab == "all" or currentTab == "products" then
					populateItems()
				end
			end
		end
	end)

	-- Refresh store when game passes are purchased
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, gamePassId, wasPurchased)
		if plr == player and wasPurchased then
			-- Show purchase success message
			safeSetCore("ChatMakeSystemMessage", {
				Text = "🎉 GamePass purchase successful! Thank you for your support!";
				Color = Color3.fromRGB(0, 255, 100);
			})

			-- Refresh the store GUI to show owned status
			wait(1) -- Brief delay to ensure the purchase is processed
			populateItems()
		end
	end)

	print("🛒 Improved Store GUI created successfully!")
	print("📦 " .. #GAME_PASSES .. " Game Passes and " .. #DEVELOPER_PRODUCTS .. " Developer Products loaded")
	print("🔄 MarketplaceHandler connection status: " .. (MarketplaceHandler and "Connected" or "Disconnected"))
end

-- Initialize the store GUI
createStoreGUI()

-- Handle character respawning
player.CharacterAdded:Connect(function()
	wait(1) -- Wait a moment for other GUIs to load
	createStoreGUI()
end)

print("🛒 IMPROVED Store Menu GUI Script loaded successfully!")
print("🎯 Configured " .. #GAME_PASSES .. " GamePasses and " .. #DEVELOPER_PRODUCTS .. " Developer Products")
print("⚠️ Make sure MarketplaceScript is running in ServerScriptService!")
print("🔧 Connection attempts: " .. handlerConnectionAttempts .. "/" .. maxConnectionAttempts)
print("✅ Improved error handling and connection monitoring active!")
print("🆘 Check the status indicator on the store button for connection status!")