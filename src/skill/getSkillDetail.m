function detail = getSkillDetail(config, skillName)
% getSkillDetail - 获取指定 skill 的详细描述
%   config: 配置结构体
%   skillName: 技能名称
%   返回: 描述字符串

    if isempty(config.skills) || numel(config.skills) == 0
        detail = sprintf('未找到技能 "%s"，当前没有可用技能。', skillName);
        return;
    end

    for i = 1:numel(config.skills)
        if strcmp(config.skills(i).name, skillName)
            detail = sprintf('技能 "%s": %s', skillName, config.skills(i).description);
            return;
        end
    end

    detail = sprintf('未找到名为 "%s" 的技能。', skillName);
end
