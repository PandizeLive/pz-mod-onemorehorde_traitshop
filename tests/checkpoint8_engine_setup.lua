local Ownership = require("OMH_Phase4Ownership")
local Persistence = require("OMH_Phase3Persistence")
local ExtensionRuntime = require("OMH_ExtensionRuntime")
local runtimeReady = true
local registry = {}
local Engine = { extensions = ExtensionRuntime, signalEliminationIfReady = function() end }
local function getHordeData(zombie) return zombie.data end
local function matchesRuntime(data, runtime) return data.OMHEventId == runtime.event.eventId end
local function forgetHibernationSnapshot() end
local function getWorldAgeHours() return testWorldHours end
local function wholeNumber(value, default) return value or default end
