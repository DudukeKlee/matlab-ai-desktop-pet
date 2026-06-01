# matlab-ai-desktop-pet

用 MATLAB 写的 AI 桌面宠物：主角叫 **Neuro（牛肉）**，有个妹妹叫 **Evil**。两个 Agent 通过大语言模型协作完成对话、屏幕操作、TTS 语音播放等。

## 特性

- **对话**：接入任何 OpenAI 协议兼容的大模型（GPT、Claude、DeepSeek 等）
- **立绘系统**：角色立绘 + 状态图（感叹号 / 问号 / 哈气 …），按情绪自动切换
- **技能系统**：AI 可以截屏、点击屏幕、输入文字。可自行扩展更多技能（见 `skills/_template.m`）
- **双 Agent**：复杂任务可以让 Neuro 召唤妹妹 Evil 处理（`skill` 阻塞模式 / `thinking` 后台模式）
- **TTS 语音**：可选接入本地 GPT-SoVITS 服务
- **翻译**：可选用 DeepSeek 等模型把中文回复翻译成英文（配合英文 TTS）

## 运行环境

- MATLAB R2021a 及以上（用到了 `uifigure` 等较新组件）
- Java 运行时（MATLAB 自带，用于截屏、模拟点击）
- Windows（主开发环境；其它平台理论可用，部分技能可能需要微调）
- 任一 OpenAI 协议兼容的 LLM API key

## 快速开始

1. 克隆仓库：

   ```bash
   git clone https://github.com/<你的用户名>/matlab-ai-desktop-pet.git
   ```

2. 配置 API key：

   ```bash
   cp config/settings.example.json config/settings.json
   ```

   打开 `config/settings.json`，把以下字段改成你的：
   - `ai.apiKey` `ai.baseURL` `ai.model` —— 主对话模型（Neuro）
   - `agentB.apiKey` `agentB.baseURL` `agentB.model` —— 副 Agent（Evil）
   - `translator.apiKey` —— 可选，启用翻译时填

3. 在 MATLAB 里打开项目目录，运行：

   ```matlab
   main
   ```

## 可选：TTS 语音

如果想让 Neuro 开口说话，需要在本机跑一个 [GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS) 推理服务，监听 `http://localhost:5000`。

不启用 TTS 也能正常聊天，把窗口里的"启用语音"勾掉即可。

## 项目结构

```
matlab-ai-desktop-pet/
├── main.m                  入口
├── config/
│   └── settings.example.json   配置模板（真实 settings.json 已 gitignore）
├── src/
│   ├── ui/                 主窗口 / 配置窗口
│   ├── ai/                 LLM 请求 / 回复解析 / 翻译
│   ├── agent/              Agent B（Evil）相关
│   ├── skill/              技能调度
│   ├── image/              立绘切换
│   ├── tts/                TTS 调用
│   └── utils/              AppData / 配置读写等
├── skills/                 可被 AI 调用的 .m 技能
└── images/                 立绘资源（character / agent / status）
```

## 回复格式（AI 协议）

每条回复必须用 `---` 分隔正文和控制块：

```
正文（聊天内容）
---
[emotion:立绘名]
[status:状态图名]      // 可选
[angle:0~180]          // 可选，配合 status
[skill:JSON 或留空]
```

技能调用必须按顺序：`get_skills` → `skill_detail` → `use_skill`，防止 AI 编造技能名。

## License

MIT
