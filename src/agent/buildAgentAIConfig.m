function aiConfig = buildAgentAIConfig(config)
% 把 agentB 配置包装成 sendAIRequest 需要的格式
    aiConfig = struct();
    aiConfig.ai.baseURL = config.agentB.baseURL;
    aiConfig.ai.model = config.agentB.model;
    aiConfig.ai.apiKey = config.agentB.apiKey;
end
