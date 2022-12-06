local __namespace, __module = ...

local Addon = __module.Addon --- @class Addon
local Array = __module.Array --- @class Array
local useSavedVariable = Addon.useSavedVariable

local globalDB = "QuestTTSGlobalDB"

local module = {
  readTitle = useSavedVariable(globalDB, "readTitle", true),
  readObjective = useSavedVariable(globalDB, "readObjective", true),
  voice1 = useSavedVariable(globalDB, "voice1", Enum.TtsVoiceType.Standard),
  voice2 = useSavedVariable(globalDB, "voice2", Enum.TtsVoiceType.Standard),
  voice3 = useSavedVariable(globalDB, "voice3", Enum.TtsVoiceType.Standard),
  voiceSpeed = useSavedVariable(globalDB, "voiceSpeed", 0),
  voiceVolume = useSavedVariable(globalDB, "voiceVolume", 100),
  autoReadQuest = useSavedVariable(globalDB, "autoReadQuest", false),
  autoReadGossip = useSavedVariable(globalDB, "autoReadGossip", false),
  skipRecentText = useSavedVariable(globalDB, "skipRecentText", false),
  autoStopRead = useSavedVariable(globalDB, "autoStopRead", true),
  hookAutoTurnIn = useSavedVariable(globalDB, "hookAutoTurnIn", false),
  alert = useSavedVariable(globalDB, "alert", 0),
}

__module.Settings = module
