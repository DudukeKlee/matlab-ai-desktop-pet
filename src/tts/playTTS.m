function playTTS(config, text)
% playTTS - 调用 GPT-SoVITS 合成语音并播放

    if isempty(strtrim(text))
        return;
    end

    baseUrl = config.tts.url;
    lang = config.tts.language;

    encodedText = urlencode(text);
    encodedLang = urlencode(lang);
    fullUrl = sprintf('%s?text=%s&text_language=%s', baseUrl, encodedText, encodedLang);

    try
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
        player = audioplayer(y, fs);
        playblocking(player);
    catch ME
        warning('TTS 调用出错: %s', ME.message);
    end
end

function encoded = urlencode(str)
    encoded = char(java.net.URLEncoder.encode(str, 'UTF-8'));
end
