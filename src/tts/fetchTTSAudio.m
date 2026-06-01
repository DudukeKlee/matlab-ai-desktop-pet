function [y, fs] = fetchTTSAudio(config, text)
% fetchTTSAudio - 调用 GPT-SoVITS 获取音频数据（不播放）
%   返回: y - 音频数据, fs - 采样率

    y = [];
    fs = 0;

    if isempty(strtrim(text))
        return;
    end

    baseUrl = config.tts.url;
    lang = config.tts.language;

    encodedText = char(java.net.URLEncoder.encode(text, 'UTF-8'));
    encodedLang = char(java.net.URLEncoder.encode(lang, 'UTF-8'));
    fullUrl = sprintf('%s?text=%s&text_language=%s', baseUrl, encodedText, encodedLang);

    options = weboptions('ContentType', 'binary', 'Timeout', 120);
    audioData = webread(fullUrl, options);

    tempDir = fullfile(getProjectRoot(), 'temp');
    if ~exist(tempDir, 'dir')
        mkdir(tempDir);
    end
    tempFile = fullfile(tempDir, 'tts_output.wav');

    fid = fopen(tempFile, 'wb');
    fwrite(fid, audioData);
    fclose(fid);

    [y, fs] = audioread(tempFile);
end
