classdef AppData < handle
    properties
        config
        mainFig
        configFig
        characterImg
        statusImg
        chatDisplay
        inputField
        sendBtn
        ttsToggle
        messages
        stateTimer
        statusTimer
        onConfigUpdated
        onLayoutUpdate    % 布局刷新回调
        % GIF
        gifTimer
        gifFrames
        gifFrameIndex
        % Agent B
        agentB_status        % 'idle' / 'working' / 'done_pending'
        agentB_mode          % 'skill' / 'thinking'
        agentB_currentTask
        agentB_messages
        agentB_round
        agentB_result
        agentB_remark
        agentB_success
        agentB_fig
        agentB_chatDisplay
        agentB_characterImg
        agentB_statusImg
        agentB_statusTimer
        agentB_statusLabel
        agentB_loopTimer
        agentB_stateTimer
        agentB_pendingStart  % thinking 模式等待 A 空闲后启动
        agentB_closeTimer    % thinking 模式完成后关窗 timer
        agentB_pendingClose  % 等 A 回复完后关闭 B 窗口
        % 汇报
        reportCheckTimer
        triggerAILoop        % 函数句柄
        % 请求锁
        isWebBusy
    end

    methods
        function obj = AppData()
            obj.config = struct();
            obj.messages = {};
            obj.gifFrames = {};
            obj.gifFrameIndex = 1;
            obj.agentB_status = 'idle';
            obj.agentB_mode = '';
            obj.agentB_currentTask = '';
            obj.agentB_messages = {};
            obj.agentB_round = 0;
            obj.agentB_result = '';
            obj.agentB_remark = '';
            obj.agentB_success = false;
            obj.agentB_pendingStart = false;
            obj.agentB_pendingClose = false;
            obj.isWebBusy = false;
        end
    end
end
