function updateAgentStatus(appData)
    if isempty(appData.agentB_fig) || ~isvalid(appData.agentB_fig)
        return;
    end
    s2 = getappdata(appData.agentB_fig, 'statusLabel2');
    if isempty(s2) || ~isvalid(s2), return; end
    s2.Text = sprintf('模式: %s · 轮次: %d/%d', ...
        appData.agentB_mode, appData.agentB_round, appData.config.agentB.maxRounds);
end
