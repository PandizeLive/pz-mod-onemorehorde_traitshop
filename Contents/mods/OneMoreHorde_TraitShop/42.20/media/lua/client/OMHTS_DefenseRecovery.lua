if isServer() then return end
local Evidence = require("OMHTS_InjuryEvidence")

---@param module string Namespace
---@param command string Server recovery query
---@param message table Target and bounded opaque receipt
---@return nil
local function receive(module, command, message)
    if not isClient() or module ~= "OMHTS_DefenseRecovery" or command ~= "Check"
        or type(message) ~= "table" or type(message.id) ~= "number"
        or type(message.token) ~= "string" or #message.token > 128 then return end
    for i = 0, 3 do
        local player = getSpecificPlayer(i)
        if player and player:getOnlineID() == message.id and not player:isDead() then
            sendClientCommand(player, "OMHTS_DefenseRecovery", "Checked", {
                token = message.token, recovered = Evidence.recovered(player)})
            return
        end
    end
end

Events.OnServerCommand.Add(receive)
return {receive = receive}
