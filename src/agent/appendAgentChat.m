function appendAgentChat(appData, text)
    if isempty(appData.agentB_chatDisplay) || ~isvalid(appData.agentB_chatDisplay)
        return;
    end
    current = appData.agentB_chatDisplay.Value;
    if ~iscell(current), current = {current}; end
    current{end+1} = text;
    if numel(current) > 200
        current = current(end-199:end);
    end
    appData.agentB_chatDisplay.Value = current;
    scroll(appData.agentB_chatDisplay, 'bottom');
end
