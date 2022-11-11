local __namespace, __module = ...

local Addon = __module.Addon --- @class Addon
local Array = __module.Array --- @class Array
local useSavedVariable = Addon.useSavedVariable
local useProxySetting = Addon.useProxySetting

local globalDB = "QuestTTSGlobalDB"
local category, layout = Settings.RegisterVerticalLayoutCategory(__namespace)

local module = {
  readTitle = useProxySetting(
    category, "Read the quest title", globalDB, "readTitle", true
  ),
  readObjective = useProxySetting(
    category, "Read the quest objective", globalDB, "readObjective", true
  ),
  voice1 = useProxySetting(
    category, "Voice for male npcs", globalDB, "voice1",
    Enum.TtsVoiceType.Standard
  ),
  voice2 = useProxySetting(
    category, "Voice for female npcs", globalDB, "voice2",
    Enum.TtsVoiceType.Standard
  ),
  voice3 = useProxySetting(
    category, "Voice for other gender npcs", globalDB, "voice3",
    Enum.TtsVoiceType.Standard
  ),
  autoReadQuest = useProxySetting(
    category, "Auto read quest text", globalDB, "autoReadQuest", false
  ),
  autoReadGossip = useProxySetting(
    category, "Auto read gossip text", globalDB, "autoReadGossip", false
  ),

  alert = useSavedVariable(globalDB, "alert", 0),
}

Settings.CreateCheckBox(category, module.readTitle.proxy, "")
Settings.CreateCheckBox(category, module.readObjective.proxy, "")
Settings.CreateCheckBox(category, module.autoReadQuest.proxy, "")
Settings.CreateCheckBox(category, module.autoReadGossip.proxy, "")

local function GetVoiceOptions()
  local toRet = Settings.CreateControlTextContainer()

  Array.new(C_VoiceChat.GetTtsVoices()):forEach(
    function(voice)
      toRet:Add(voice.voiceID, voice.name)
    end
  )

  return toRet:GetData()
end

Settings.CreateDropDown(category, module.voice1.proxy, GetVoiceOptions, "")
Settings.CreateDropDown(category, module.voice2.proxy, GetVoiceOptions, "")
Settings.CreateDropDown(category, module.voice3.proxy, GetVoiceOptions, "")

layout:AddInitializer(
  CreateSettingsButtonInitializer(
    "Speed / volume settings", "Open TTS settings", function()
      ToggleTextToSpeechFrame()
    end, ""
  )
)

layout:AddInitializer(
  Settings.CreatePanelInitializer(
    "ColorblindSelectorTemplate", {}
  )
);

Settings.RegisterAddOnCategory(category)

__module.settings = module
