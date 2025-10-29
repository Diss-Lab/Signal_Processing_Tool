classdef fft_analyzer < handle
    % FFT分析器 - 统一的FFT计算和峰值检测模块
    % 
    % 功能:
    %   - 计算信号的FFT
    %   - 查找频率峰值
    %   - 格式化峰值信息
    %
    % 使用示例:
    %   [freq, mag, phase] = fft_analyzer.compute(signal, fs);
    %   peaks = fft_analyzer.find_peaks(freq, mag);
    %
    % 版本: 1.0
    % 作者: 重构团队
    % 日期: 2024
    
    methods (Static)
        function [freq_vector, magnitude, phase] = compute(signal, fs, options)
            % 计算FFT
            %
            % 输入:
            %   signal - 输入信号 (列向量)
            %   fs - 采样频率 (Hz)
            %   options - 可选参数结构体
            %       .single_sided - 是否返回单边频谱 (默认: true)
            %       .normalized - 是否归一化 (默认: false)
            %       .freq_unit - 频率单位 'Hz'或'kHz' (默认: 'kHz')
            %
            % 输出:
            %   freq_vector - 频率向量
            %   magnitude - 幅值
            %   phase - 相位 (弧度)
            
            % 参数验证
            arguments
                signal (:,1) double
                fs (1,1) double {mustBePositive}
                options.single_sided (1,1) logical = true
                options.normalized (1,1) logical = false
                options.freq_unit (1,:) char {mustBeMember(options.freq_unit,{'Hz','kHz'})} = 'kHz'
            end
            
            try
                % 计算FFT
                N = length(signal);
                Y = fft(signal);
                
                % 生成频率向量 (Hz)
                freq_vector = (0:N-1) * fs / N;
                
                % 计算幅值和相位
                magnitude = abs(Y);
                phase = angle(Y);
                
                % 归一化
                if options.normalized
                    magnitude = magnitude / N;
                end
                
                % 单边频谱
                if options.single_sided
                    freq_vector = freq_vector(1:floor(N/2));
                    magnitude = magnitude(1:floor(N/2));
                    phase = phase(1:floor(N/2));
                    
                    % 单边频谱幅值需要乘2 (除了直流分量)
                    if ~options.normalized
                        magnitude(2:end) = 2 * magnitude(2:end);
                    end
                end
                
                % 转换频率单位
                if strcmp(options.freq_unit, 'kHz')
                    freq_vector = freq_vector / 1000;
                end
                
            catch ME
                error('fft_analyzer:compute', ...
                      'FFT计算失败: %s\n输入信号长度: %d, 采样率: %.2f MHz', ...
                      ME.message, length(signal), fs/1e6);
            end
        end
        
        function peaks = find_peaks(freq_vector, magnitude, config)
            % 查找频率峰值
            %
            % 输入:
            %   freq_vector - 频率向量
            %   magnitude - 幅值向量
            %   config - 配置结构体 (可选)
            %       .min_peak_height - 最小峰值高度 (默认: max*0.1)
            %       .min_peak_distance - 最小峰值间距 (默认: auto)
            %       .num_peaks - 返回峰值数量 (默认: 2)
            %
            % 输出:
            %   peaks - 峰值结构体数组
            %       .frequency - 峰值频率
            %       .magnitude - 峰值幅值
            %       .index - 峰值索引
            
            % 默认配置
            if nargin < 3 || isempty(config)
                config = struct();
            end
            
            if ~isfield(config, 'min_peak_height')
                config.min_peak_height = max(magnitude) * 0.1;
            end
            
            if ~isfield(config, 'min_peak_distance')
                config.min_peak_distance = max(10, round(length(magnitude) / 100));
            end
            
            if ~isfield(config, 'num_peaks')
                config.num_peaks = 2;
            end
            
            % 初始化输出
            peaks = struct('frequency', {}, 'magnitude', {}, 'index', {});
            
            try
                % 查找峰值
                [peak_values, peak_locs] = findpeaks(magnitude, ...
                    'MinPeakHeight', config.min_peak_height, ...
                    'MinPeakDistance', config.min_peak_distance, ...
                    'SortStr', 'descend');
                
                % 限制峰值数量
                num_found = min(length(peak_values), config.num_peaks);
                
                % 构建峰值结构体
                for i = 1:num_found
                    peaks(i).frequency = freq_vector(peak_locs(i));
                    peaks(i).magnitude = peak_values(i);
                    peaks(i).index = peak_locs(i);
                end
                
            catch ME
                % 如果findpeaks不可用或失败，返回最大值点
                warning('fft_analyzer:find_peaks', ...
                        'Peak detection failed: %s. Returning max value only.', ME.message);
                
                [max_val, max_idx] = max(magnitude);
                peaks(1).frequency = freq_vector(max_idx);
                peaks(1).magnitude = max_val;
                peaks(1).index = max_idx;
            end
        end
        
        function peak_info_str = format_peak_info(peaks, format_type)
            % 格式化峰值信息为字符串
            %
            % 输入:
            %   peaks - 峰值结构体数组 (来自find_peaks)
            %   format_type - 格式类型 'simple' 或 'detailed' (默认: 'simple')
            %
            % 输出:
            %   peak_info_str - 格式化的字符串
            
            if nargin < 2
                format_type = 'simple';
            end
            
            if isempty(peaks)
                peak_info_str = 'No peaks detected';
                return;
            end
            
            switch format_type
                case 'simple'
                    % 简单格式: "Peak: 100.0 kHz"
                    if length(peaks) == 1
                        peak_info_str = sprintf('Peak: %.1f kHz', peaks(1).frequency);
                    else
                        freq_strs = arrayfun(@(p) sprintf('%.1f', p.frequency), peaks, 'UniformOutput', false);
                        peak_info_str = sprintf('Peaks: %s kHz', strjoin(freq_strs, ', '));
                    end
                    
                case 'detailed'
                    % 详细格式: 包含幅值信息
                    lines = cell(length(peaks), 1);
                    for i = 1:length(peaks)
                        if i == 1
                            lines{i} = sprintf('Highest Peak: %.1f kHz (Mag: %.2e)', ...
                                             peaks(i).frequency, peaks(i).magnitude);
                        else
                            lines{i} = sprintf('Peak %d: %.1f kHz (Mag: %.2e)', ...
                                             i, peaks(i).frequency, peaks(i).magnitude);
                        end
                    end
                    peak_info_str = strjoin(lines, '\n');
                    
                otherwise
                    error('fft_analyzer:format_peak_info', 'Unknown format type: %s', format_type);
            end
        end
        
        function validate_input(signal, fs)
            % 验证输入参数
            %
            % 输入:
            %   signal - 信号向量
            %   fs - 采样频率
            %
            % 抛出错误如果验证失败
            
            if isempty(signal)
                error('fft_analyzer:validate_input', 'Input signal is empty');
            end
            
            if ~isvector(signal)
                error('fft_analyzer:validate_input', 'Input signal must be a vector');
            end
            
            if any(isnan(signal)) || any(isinf(signal))
                error('fft_analyzer:validate_input', 'Input signal contains NaN or Inf values');
            end
            
            if fs <= 0
                error('fft_analyzer:validate_input', 'Sampling frequency must be positive');
            end
        end
    end
end
