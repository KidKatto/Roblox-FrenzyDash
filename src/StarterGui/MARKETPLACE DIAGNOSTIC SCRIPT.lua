-- QUICK MARKETPLACE DIAGNOSTIC SCRIPT
-- Place this as a LocalScript in StarterGui to test if your marketplace is working
-- This will show you exactly what's happening with your marketplace setup
-- does it sync?

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

-- Wait a moment for other scripts to load
wait(3)

print("🔍 MARKETPLACE DIAGNOSTIC STARTING...")

-- Test 1: Check if MarketplaceHandler exists
local marketplaceHandler = _G.MarketplaceHandler
if marketplaceHandler then
	print("✅ MarketplaceHandler found!")
	if marketplaceHandler.getDeveloperProducts then
		local products = marketplaceHandler.getDeveloperProducts()
		print("📦 Developer Products configured:")
		for name, id in pairs(products) do
			print("  - " .. name .. ": " .. id)
		end
	end
else
	_G.MarketplaceHandler = require("MarketplaceHandler") 
	print("❌ MarketplaceHandler NOT FOUND")
	print("   → Check if MarketplaceScript.lua is in ServerScriptService")
end

-- Test 2: Check if GamePassHandler exists
local gamePassHandler = _G.GamePassHandler
if gamePassHandler then
	print("✅ GamePassHandler found!")
	if gamePassHandler.playerGamePasses and gamePassHandler.playerGamePasses[player] then
		print("🎮 Your GamePasses:")
		for passName, owned in pairs(gamePassHandler.playerGamePasses[player]) do
			print("  - " .. passName .. ": " .. tostring(owned))
		end
	end
else
	print("❌ GamePassHandler NOT FOUND")
	print("   → Check if GamePassHandlerScript.lua is in ServerScriptService")
end

-- Test 3: Check if Store GUI exists
local playerGui = player:WaitForChild("PlayerGui")
local storeGui = playerGui:FindFirstChild("StoreGUI")
if storeGui then
	print("✅ Store GUI found!")
	local storeButton = storeGui:FindFirstChild("StoreButton")
	if storeButton then
		print("🛒 Store button exists and ready")
	else
		print("⚠️ Store button missing")
	end
else
	print("❌ Store GUI NOT FOUND")
	print("   → Check if StoreMenuGUIScript.lua is in StarterGui as LocalScript")
end

-- Test 4: Check if CoinCollectorModule exists
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local success, coinModule = pcall(function()
	return ReplicatedStorage:WaitForChild("CoinCollectorModule", 5)
end)

if success and coinModule then
	print("✅ CoinCollectorModule found in ReplicatedStorage!")
	local requiredModule = require(coinModule)
	print("🎮 Game Label: " .. requiredModule.GAME_LABEL)
	print("💰 Magic Key Multiplier: x" .. requiredModule.MAGIC_KEY_MULTIPLIER)
else
	print("❌ CoinCollectorModule NOT FOUND in ReplicatedStorage")
	print("   → Make sure CoinCollectorModule.lua is in ReplicatedStorage as ModuleScript")
end

-- Test 5: Test a simple product purchase
local testProductId = 3378102552 -- Coffee product
print("🧪 Testing product purchase prompt...")

spawn(function()
	wait(5) -- Wait 5 seconds then test

	local success, error = pcall(function()
		MarketplaceService:PromptProductPurchase(player, testProductId)
		print("✅ Successfully prompted purchase for product " .. testProductId)
	end)

	if not success then
		print("❌ Failed to prompt purchase: " .. tostring(error))
		print("   → This might mean the Product ID " .. testProductId .. " is invalid")
		print("   → Or the product doesn't belong to this game")
	end
end)

-- Test 6: Show summary
spawn(function()
	wait(6)
	print("\n🎯 DIAGNOSTIC SUMMARY:")
	print("1. MarketplaceHandler: " .. (marketplaceHandler and "✅ Working" or "❌ Missing"))
	print("2. GamePassHandler: " .. (gamePassHandler and "✅ Working" or "❌ Missing"))  
	print("3. Store GUI: " .. (storeGui and "✅ Working" or "❌ Missing"))
	print("4. CoinCollectorModule: " .. (success and "✅ Working" or "❌ Missing"))

	print("\n🔧 NEXT STEPS:")
	if not marketplaceHandler then
		print("• Place MarketplaceScript.lua in ServerScriptService as Script")
	end
	if not gamePassHandler then
		print("• Place GamePassHandlerScript.lua in ServerScriptService as Script")
	end
	if not storeGui then
		print("• Place StoreMenuGUIScript.lua in StarterGui as LocalScript")
	end
	if not success then
		print("• Place CoinCollectorModule.lua in ReplicatedStorage as ModuleScript")
	end

	print("• Replace 'YourUsernameHere' with your actual Roblox username")
	print("• Verify your Developer Product IDs are correct")
	print("• Test in a published game, not just Studio")

	-- Show a visible message to the player
	pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = "🔍 Marketplace diagnostic complete! Check Output (F9) for results.";
			Color = Color3.fromRGB(0, 200, 255);
		})
	end)
end)
