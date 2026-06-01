function cleanupAgent(appData)
% skill 模式完成后清理
    appData.agentB_status = 'idle';
    appData.agentB_mode = '';
    appData.agentB_currentTask = '';
    appData.agentB_messages = {};
    appData.agentB_round = 0;
    appData.agentB_remark = '';

    if ~isempty(appData.agentB_statusTimer) && isvalid(appData.agentB_statusTimer)
        if strcmp(appData.agentB_statusTimer.Running, 'on')
            stop(appData.agentB_statusTimer);
        end
        delete(appData.agentB_statusTimer);
        appData.agentB_statusTimer = [];
    end
    if ~isempty(appData.agentB_fig) && isvalid(appData.agentB_fig)
        delete(appData.agentB_fig);
        appData.agentB_fig = [];
    end

