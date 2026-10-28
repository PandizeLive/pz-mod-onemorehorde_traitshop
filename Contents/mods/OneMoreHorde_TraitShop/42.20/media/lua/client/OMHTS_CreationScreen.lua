if isServer() then return end

require("OptionScreens/CharacterCreationProfession")
local Prestige = require("OMHTS_Prestige")
local Screen = {}
-- CharacterCreationProfession uses this spacing as a file-local constant.
local UI_BORDER_SPACING = 10
local active
local enteredWorld = false
local connection = 0
local initialState
local originalPoints = CharacterCreationProfession.PointToSpend
local originalRender = CharacterCreationProfession.render
local originalCreate = CharacterCreationProfession.create

---@param self CharacterCreationProfession
---@return nil
function CharacterCreationProfession:create()
    originalCreate(self)
    local extra = getTextManager():getFontHeight(UIFont.Small) + 4
    self.topOfLists = self.topOfLists + extra
    self.listboxProf:setY(self.listboxProf:getY() + extra)
    self.listboxProf:setHeight(self.listboxProf:getHeight() - extra)
    self.listboxTrait:setY(self.listboxTrait:getY() + extra)
    self.listboxTraitSelected:setY(self.listboxTraitSelected:getY() + extra)
end

---@nodiscard
---@return string
---@return number
local function identity()
    local slot = 0
    if CoopCharacterCreation and CoopCharacterCreation.instance then
        slot = CoopCharacterCreation.instance.playerIndex
    end
    if isClient() then
        local username = getClientUsername()
        if slot > 0 and CoopUserName and CoopUserName.instance then
            username = CoopUserName.instance:getUserName()
        end
        return "user:" .. #username .. ":" .. username .. ":" .. slot, slot
    end
    return "local:" .. slot, slot
end

---@param panel CharacterCreationProfession
---@return table
function Screen.context(panel)
    local account, slot = identity()
    local descriptor = MainScreen.instance.desc
    local context = panel.omhPrestige
    if not context or context.account ~= account or context.descriptor ~= descriptor or context.connection ~= connection then
        context = { account = account, descriptor = descriptor, tag = Prestige.tag(account),
            nextRequest = 0, revision = -1, connection = connection }
        panel.omhPrestige = context
        if isClient() and not enteredWorld then
            local data = initialState
            if data and data.schema == 1 and data.ready == true and type(data.bonuses) == "table" then
                local bonus = data.bonuses[account]
                if bonus == nil then
                    bonus = 0
                end
                if Prestige.counter(bonus) then
                    context.bonus = bonus
                    print("[OMH Trait Shop] creation Prestige from connection; slot=" .. slot .. "; bonus=" .. bonus)
                end
            end
            if data and context.bonus == nil then
                context.unavailable = true
                print("[OMH Trait Shop] connection Prestige unavailable; verify matching client/server versions and server state")
            end
        elseif not isClient() then
            context.bonus = 0
            if not MainScreen.instance.createWorld or (CoopCharacterCreation and CoopCharacterCreation.instance) then
                local reader = getFileReader(Prestige.localPath(slot), false)
                if reader then
                    local value = tonumber(reader:readLine())
                    reader:close()
                    if Prestige.counter(value) then
                        context.bonus = value
                    end
                end
            end
        end
    end
    active = context
    if isClient() and enteredWorld and context.bonus == nil and getTimestampMs() >= context.nextRequest then
        context.nextRequest = getTimestampMs() + 2000
        ModData.request(context.tag)
    end
    return context
end

---@param tag string
---@param data table|boolean
---@return nil
function Screen.receive(tag, data)
    if not enteredWorld or not active or tag ~= active.tag then return end
    if data == false then
        if active.revision < 0 then
            active.bonus = 0
        end
        return
    end
    if type(data) ~= "table" or data.schema ~= 1 or not Prestige.counter(data.bonus)
        or not Prestige.counter(data.revision) or data.revision < active.revision then return end
    active.revision = data.revision
    active.bonus = data.bonus
end

---@param self CharacterCreationProfession
---@return number
function CharacterCreationProfession:PointToSpend()
    local context = Screen.context(self)
    local bonus = context.bonus
    if bonus == nil then
        bonus = 0
    end
    return originalPoints(self) + bonus
end

---@param self CharacterCreationProfession
---@return nil
function CharacterCreationProfession:render()
    originalRender(self)
    local context = Screen.context(self)
    local label
    if context.bonus == nil then
        local key = "UI_OMHTS_PrestigeLoading"
        if context.unavailable then
            key = "UI_OMHTS_PrestigeUnavailable"
        end
        self.playButton:setEnable(false)
        self.playButton:setTooltip(getText(key))
        label = getText(key)
    else
        label = getText("UI_OMHTS_CreationPrestige", tostring(context.bonus))
    end
    self:drawTextCentre(label, self.width / 2, UI_BORDER_SPACING + getTextManager():getFontHeight(UIFont.Large) + 3,
        231 / 255, 180 / 255, 40 / 255, 1, UIFont.Small)
end

---@return nil
local function onConnected()
    -- Native ConnectToServerState fires this only after loadInitialState.
    initialState = CGlobalObjects.registerSystem(Prestige.SYSTEM):getModData()
    connection = connection + 1
    enteredWorld = false
end

---@return nil
local function onGameStart()
    enteredWorld = true
end

---@return nil
local function onDisconnect()
    connection = connection + 1
    enteredWorld = false
    active = nil
    initialState = nil
end

Events.OnConnected.Add(onConnected)
Events.OnGameStart.Add(onGameStart)
Events.OnDisconnect.Add(onDisconnect)
Events.OnReceiveGlobalModData.Add(Screen.receive)
return Screen
