local Config = {}
Config.keys = { "ZombieXP", "PlayerKillXP", "DayXP", "NightXP", "HordeZombieXP", "HordeSurvivedXP" }
Config.defaults = { ZombieXP = 2, PlayerKillXP = 75, DayXP = 0, NightXP = 25,
    HordeZombieXP = 5, HordeSurvivedXP = 100, PlayerKillCooldownDays = 2 }

---@nodiscard
---@return boolean
function Config.hasHordeNight()
    return getActivatedMods():contains("OneMoreHorde_HordeNight")
end

---@nodiscard
---@param mode number
---@param key string
---@return boolean
function Config.visible(mode, key)
    if key == "PlayerKillCooldownDays" then return mode == 1 or mode == 4 end
    if mode == 4 then return true end
    if key == "ZombieXP" or key == "PlayerKillXP" then return mode == 1 end
    if key == "DayXP" or key == "NightXP" then return mode == 2 end
    if key == "HordeZombieXP" or key == "HordeSurvivedXP" then return mode == 3 end
    return false
end

---@nodiscard
---@return table
function Config.read()
    local values = { mode = 4, horde = Config.hasHordeNight(), ready = false, cycle = SandboxVars.DayNightCycle }
    if values.horde then
        values.mode = 3
    end
    local options = SandboxVars.OMHTraitShop
    if type(options) ~= "table" then return values end
    local mode = options.RewardMode
    if type(mode) ~= "number" or mode < 1 or mode > 4 or mode ~= math.floor(mode) then return values end
    values.mode = mode
    for key in pairs(Config.defaults) do
        local value = options[key]
        local limit = 100000
        if key == "PlayerKillCooldownDays" then
            limit = 365
        end
        if type(value) ~= "number" or value < 0 or value > limit or value ~= math.floor(value) then return values end
        values[key] = value
    end
    values.ready = true
    return values
end

---@nodiscard
---@param values table
---@param key string
---@return number
function Config.amount(values, key)
    if not values.ready or not Config.visible(values.mode, key) then return 0 end
    if (key == "DayXP" or key == "NightXP") and values.cycle ~= 1 then return 0 end
    if key == "HordeZombieXP" or key == "HordeSurvivedXP" then return 0 end
    return values[key]
end

---@param options SandboxOptions
---@return nil
function Config.applyDefault(options)
    local option = options:getOptionByName("OMHTraitShop.RewardMode")
    if not option then return end
    local mode = 4
    if Config.hasHordeNight() then
        mode = 3
    end
    option:setValue(mode)
    option:setDefaultToCurrentValue()
end

Config.applyDefault(getSandboxOptions())
return Config
