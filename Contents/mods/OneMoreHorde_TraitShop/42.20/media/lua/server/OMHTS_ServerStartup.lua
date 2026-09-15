if isClient() then return end

local TraitShop = require("OMHTS_Bootstrap")

---@return nil
local function onServerStarted()
    print("[OMH Trait Shop] v" .. TraitShop.VERSION
        .. " dedicated server started; checkpoint " .. TraitShop.CHECKPOINT)
end

Events.OnServerStarted.Add(onServerStarted)
