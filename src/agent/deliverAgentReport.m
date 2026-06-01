function deliverAgentReport(appData)
% deliverAgentReport - 汇报 B 的结果给 A

    try
        appData.sendBtn.Enable = 'off';

        task = appData.agentB_currentTask;
        result = appData.agentB_result;
        success = appData.agentB_success;
        remark = appData.agentB_remark;

        % 发给 A 的是 B 的评价
        if ~isempty(remark)
            msg = sprintf(['[Agent 汇报] 你之前派发的任务"%s"已%s。%s 对你说："%s"。' ...
                           '请用你的语气回应她，并简短告诉用户任务情况。'], ...
                task, ternary(success, '完成', '失败'), appData.config.agentB.name, remark);
        else
            if success
                msg = sprintf(['[Agent 汇报] 你之前派发的任务"%s"已完成。结果: %s。' ...
                               '请用你的语气简短告诉用户。'], task, result);
            else
                msg = sprintf(['[Agent 汇报] 你之前派发的任务"%s"失败了。原因: %s。' ...
                               '请用你的语气告诉用户。'], task, result);
            end
        end

        appData.messages{end+1} = struct('role', 'user', 'content', msg);

        % 停止关窗 timer（如果还没触发）
        if ~isempty(appData.agentB_closeTimer)
            try
                if isvalid(appData.agentB_closeTimer)
                    stop(appData.agentB_closeTimer);
                    delete(appData.agentB_closeTimer);
                end
            catch
            end
            appData.agentB_closeTimer = [];
        end

        % 重置 B 状态（但不关窗，等 A 回复完再关）
        appData.agentB_status = 'idle';
        appData.agentB_mode = '';
        appData.agentB_currentTask = '';
        appData.agentB_result = '';
        appData.agentB_remark = '';
        appData.agentB_success = false;
        appData.agentB_messages = {};
        appData.agentB_round = 0;
        appData.agentB_pendingClose = true;  % 标记等 A 回复完后关窗

        % 触发 A 回复
        if ~isempty(appData.triggerAILoop) && isa(appData.triggerAILoop, 'function_handle')
            appData.triggerAILoop();
        else
            appData.sendBtn.Enable = 'on';
            closeAgentWindow(appData);
        end
    catch ME
        warning('汇报失败: %s', ME.message);
        appData.sendBtn.Enable = 'on';
        closeAgentWindow(appData);
    end
end

function closeAgentWindow(appData)
    if ~isempty(appData.agentB_fig) && isvalid(appData.agentB_fig)
        delete(appData.agentB_fig);
        appData.agentB_fig = [];
    end
    appData.agentB_pendingClose = false;
end

function out = ternary(cond, a, b)
    if cond
        out = a;
    else
        out = b;
    end
end
