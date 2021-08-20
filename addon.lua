local addon = CreateFrame("Frame")

local frames = {
  QuestTTSPlayButton1 = nil,
  QuestTTSPlayButton2 = nil,
  QuestTTSPlayButton3 = nil,
  QuestTTSPlayButton4 = nil,
}

local state = {
  isPlaying = false,
}

function addon:Init()
  addon:SetScript("OnEvent", addon.OnEvent)
  addon:RegisterEvent("VOICE_CHAT_TTS_PLAYBACK_FINISHED")
  addon:RegisterEvent("VOICE_CHAT_TTS_PLAYBACK_FAILED")

  frames.QuestTTSPlayButton1 = frames:InitQuestTTSPlayButton(QuestMapFrame.DetailsFrame, 18, 30, "questlog")
  frames.QuestTTSPlayButton2 = frames:InitQuestTTSPlayButton(QuestFrame, -10, -30, "")
  frames.QuestTTSPlayButton3 = frames:InitQuestTTSPlayButton(GossipFrame, -10, -30, "gossip")
  frames.QuestTTSPlayButton4 = frames:InitQuestTTSPlayButton(addon:ImmersionGetFrame(), -59, -17, "immersion")
end

function addon:OnEvent(event)
  if event == "VOICE_CHAT_TTS_PLAYBACK_FINISHED" or event == "VOICE_CHAT_TTS_PLAYBACK_FAILED" then
    state.isPlaying = false
    frames.QuestTTSPlayButton1:Update()
    frames.QuestTTSPlayButton2:Update()
    frames.QuestTTSPlayButton3:Update()
    frames.QuestTTSPlayButton4:Update()
  end
end

function addon:ReadQuest(source)
  if state.isPlaying then
    addon:TTSStop()
    return
  end

  local text = ""

  if (source == "questlog") then
    local title = C_QuestLog.GetTitleForQuestID(QuestMapFrame_GetFocusedQuestID())
    local description, objective = GetQuestLogQuestText()
    text = title .. "\n" .. description .. "\n" .. objective
  elseif (source == "gossip" or (source == "immersion" and addon:ImmersionIsGossip()) ) then
    local info = C_GossipInfo.GetText()
    text = info
  elseif (QuestFrameRewardPanel:IsShown()) then
    -- local title = GetTitleText()
    local reward = GetRewardText()
    text = reward
  elseif (QuestFrameProgressPanel:IsShown()) then
    -- local title = GetTitleText()
    local progress = GetProgressText()
    text = progress
  else
    local title = GetTitleText()
    local description = GetQuestText()
    local objective = GetObjectiveText()
    text = title .. "\n" .. description .. "\n" .. objective
  end

  addon:TTSPlay(addon:CleanText(text))
end

function addon:CleanText(text)
  local toRet = text

  toRet = toRet:gsub("<", ""):gsub(">", "")

  return toRet
end

function addon:TTSPlay(text)
  state.isPlaying = true
  TextToSpeech_Speak(text, TextToSpeech_GetSelectedVoice("standard"))
  frames.QuestTTSPlayButton1:Update()
  frames.QuestTTSPlayButton2:Update()
  frames.QuestTTSPlayButton3:Update()
  frames.QuestTTSPlayButton4:Update()
end

function addon:TTSStop()
  state.isPlaying = false
  C_VoiceChat.StopSpeakingText()
  frames.QuestTTSPlayButton1:Update()
  frames.QuestTTSPlayButton2:Update()
  frames.QuestTTSPlayButton3:Update()
  frames.QuestTTSPlayButton4:Update()
end

function addon:ImmersionGetFrame()
  if (ImmersionFrame and ImmersionFrame.TalkBox and ImmersionFrame.TalkBox.MainFrame) then
    return ImmersionFrame.TalkBox.MainFrame
  end

  return -1
end

function addon:ImmersionIsGossip()
  return ImmersionFrame.TalkBox.MainFrame.Indicator:GetTexture():find("GossipGossipIcon")
end

function frames:InitQuestTTSPlayButton(parent, x, y, fromQuestLog)
  if (parent == -1) then
    return {
      Update = function() end
    }
  end

  local button = CreateFrame("Button", nil, parent)
  button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
  button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  button:SetPoint("TOPRIGHT", x, y)
  button:SetWidth(22)
  button:SetHeight(22)
  button:RegisterForClicks("LeftButtonUp", "RightButtonDown");
  button:SetScript("OnClick", function(_, event)
    if event == "RightButton" then
      InterfaceOptionsAccessibilityPanelConfigureTextToSpeechButton_OnClick()
    else
      addon:ReadQuest(fromQuestLog)
    end
  end)
  button.Update = function()
    if state.isPlaying then
      button:SetNormalTexture("Interface\\TimeManager\\PauseButton")
    else
      button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    end
  end

  return button
end

addon:Init()
