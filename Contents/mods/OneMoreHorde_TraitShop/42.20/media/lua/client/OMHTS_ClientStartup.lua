if isServer() then return end

local TraitShop = require("OMHTS_Bootstrap")

---@return nil
local function onGameStart()
    print("[OMH Trait Shop] v" .. TraitShop.VERSION
        .. " client game started; checkpoint " .. TraitShop.CHECKPOINT)
end

Events.OnGameStart.Add(onGameStart)
