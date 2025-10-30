classdef timefreq_analyzer < handle
    % 时频分析器 - 统一的时频分析模块
    % 
    % 功能:
    %   - 计算短时傅里叶变换(STFT)
    %   - 时频图平滑处理
    %   - 时频峰值检测
    %
    % 使用示例:
    %   [S, F, T] = timefreq_analyzer.compute_stft(signal, fs);
    %   S_smooth = timefreq_analyzer.smooth_spectrogram(S);
    %
    % 版本: 1.0
    % 作者: 重构团队
    % 日期: 2024
    
    methods (Static)
        function [S, F, T] = compute_stft(signal, fs, options)
            % 计算短时傅里叶变换
            %
            % 输入:
            %   signal - 输入信号 (列向量)
            %   fs - 采样频率 (Hz)
            %   options - 可选参数结构体
            %       .window_type - 窗函数类型 'hann', 'hamming', 'blackman' (默认: 'hann')
            %       .window_length - 窗长度 (默认: signal_length/20)
            %       .overlap - 重叠率 0-1 (默认: 0.75)
            %       .nfft - FFT点数 (默认: 自动计算)
            %       .freq_unit - 频率单位 'Hz'或'kHz' (默认: 'kHz')
            %       .time_offset - 时间偏移量 (秒) (默认: 0)
            %
            % 输出:
            %   S - 时频矩阵 (复数)
            %   F - 频率向量
            %   T - 时间向量
            
            % 参数验证 - 修复：移除依赖其他参数的默认值
            arguments
                signal (:,1) double
                fs (1,1) double {mustBePositive}
                options.window_type (1,:) char {mustBeMember(options.window_type, ...
                    {'hann','hamming','blackman','rectwin'})} = 'hann'
                options.window_length (1,1) double = 0  % 0表示使用自动计算
                options.overlap (1,1) double {mustBeInRange(options.overlap,0,1)} = 0.75
                options.nfft (1,1) double = 0  % 0表示使用自动计算
                options.freq_unit (1,:) char {mustBeMember(options.freq_unit,{'Hz','kHz'})} = 'kHz'
                options.time_offset (1,1) double = 0
            end
            
            try
                % 自动计算窗长度（如果未指定）
                if options.window_length == 0
                    window_length = round(length(signal) / 20);
                else
                    window_length = options.window_length;
                end
                
                % 确保窗长度不超过信号长度
                window_length = min(window_length, length(signal));
                
                % 自动计算NFFT（如果未指定）
                if options.nfft == 0
                    nfft = max(256, 2^nextpow2(window_length));
                else
                    nfft = options.nfft;
                end
                
                % 计算重叠点数
                overlap_points = round(window_length * options.overlap);
                
                % 创建窗函数
                switch options.window_type
                    case 'hann'
                        window = hann(window_length);
                    case 'hamming'
                        window = hamming(window_length);
                    case 'blackman'
                        window = blackman(window_length);
                    case 'rectwin'
                        window = rectwin(window_length);
                end
                
                % 计算STFT
                [S, F, T] = spectrogram(signal, window, overlap_points, nfft, fs);
                
                % 应用时间偏移
                T = T + options.time_offset;
                
                % 转换频率单位
                if strcmp(options.freq_unit, 'kHz')
                    F = F / 1000;
                end
                
                % 转换时间单位为微秒
                T = T * 1e6;
                
            catch ME
                error('timefreq_analyzer:compute_stft', ...
                      'STFT计算失败: %s\n信号长度: %d, 采样率: %.2f MHz', ...
                      ME.message, length(signal), fs/1e6);
            end
        end
        
        function S_smooth = smooth_spectrogram(S, options)
            % 平滑时频图
            %
            % 输入:
            %   S - 时频矩阵 (可以是复数或幅值)
            %   options - 可选参数
            %       .sigma - 高斯滤波器标准差 (默认: 1.0)
            %       .method - 平滑方法 'gaussian' 或 'none' (默认: 'gaussian')
            %
            % 输出:
            %   S_smooth - 平滑后的时频矩阵
            
            arguments
                S (:,:) double
                options.sigma (1,1) double {mustBePositive} = 1.0
                options.method (1,:) char {mustBeMember(options.method,{'gaussian','none'})} = 'gaussian'
            end
            
            if strcmp(options.method, 'none')
                S_smooth = S;
                return;
            end
            
            try
                % 如果是复数，提取幅值
                if ~isreal(S)
                    S_magnitude = abs(S);
                else
                    S_magnitude = S;
                end
                
                % 应用高斯平滑
                if size(S_magnitude, 1) > 3 && size(S_magnitude, 2) > 3
                    if exist('imgaussfilt', 'file')
                        S_smooth = imgaussfilt(S_magnitude, options.sigma);
                    else
                        % 备用方法：使用conv2进行平滑
                        kernel_size = max(3, ceil(3 * options.sigma));
                        if mod(kernel_size, 2) == 0
                            kernel_size = kernel_size + 1;
                        end
                        
                        % 创建高斯核
                        [X, Y] = meshgrid(-(kernel_size-1)/2:(kernel_size-1)/2);
                        kernel = exp(-(X.^2 + Y.^2) / (2 * options.sigma^2));
                        kernel = kernel / sum(kernel(:));
                        
                        S_smooth = conv2(S_magnitude, kernel, 'same');
                    end
                else
                    S_smooth = S_magnitude;
                end
                
            catch ME
                warning('timefreq_analyzer:smooth_spectrogram', ...
                        '平滑失败: %s, 返回原始数据', ME.message);
                S_smooth = abs(S);
            end
        end
        
        function peak_info = find_timefreq_peaks(S, F, T, options)
            % 查找时频图峰值
            %
            % 输入:
            %   S - 时频矩阵 (复数或幅值)
            %   F - 频率向量
            %   T - 时间向量
            %   options - 可选参数
            %       .num_peaks - 返回峰值数量 (默认: 2)
            %       .exclude_range - 排除范围 [freq_%, time_%] (默认: [0.05, 0.05])
            %
            % 输出:
            %   peak_info - 峰值信息结构体数组
            %       .frequency - 峰值频率
            %       .time - 峰值时间
            %       .magnitude - 峰值幅值
            %       .freq_idx - 频率索引
            %       .time_idx - 时间索引
            
            arguments
                S (:,:) double
                F (:,1) double
                T (1,:) double
                options.num_peaks (1,1) double {mustBePositive, mustBeInteger} = 2
                options.exclude_range (1,2) double = [0.05, 0.05]
            end
            
            try
                % 提取幅值
                if ~isreal(S)
                    S_magnitude = abs(S);
                else
                    S_magnitude = S;
                end
                
                % 初始化输出
                peak_info = struct('frequency', {}, 'time', {}, 'magnitude', {}, ...
                                  'freq_idx', {}, 'time_idx', {});
                
                % 查找全局最大值
                [max_val, max_idx] = max(S_magnitude(:));
                [max_freq_idx, max_time_idx] = ind2sub(size(S_magnitude), max_idx);
                
                peak_info(1).frequency = F(max_freq_idx);
                peak_info(1).time = T(max_time_idx);
                peak_info(1).magnitude = max_val;
                peak_info(1).freq_idx = max_freq_idx;
                peak_info(1).time_idx = max_time_idx;
                
                % 查找第二大峰值（排除第一个峰值周围区域）
                if options.num_peaks >= 2
                    S_temp = S_magnitude;
                    
                    % 计算排除范围
                    freq_exclude = max(1, round(size(S_temp, 1) * options.exclude_range(1)));
                    time_exclude = max(1, round(size(S_temp, 2) * options.exclude_range(2)));
                    
                    % 排除区域
                    freq_start = max(1, max_freq_idx - freq_exclude);
                    freq_end = min(size(S_temp, 1), max_freq_idx + freq_exclude);
                    time_start = max(1, max_time_idx - time_exclude);
                    time_end = min(size(S_temp, 2), max_time_idx + time_exclude);
                    
                    S_temp(freq_start:freq_end, time_start:time_end) = 0;
                    
                    % 查找第二大峰值
                    [second_max_val, second_max_idx] = max(S_temp(:));
                    [second_freq_idx, second_time_idx] = ind2sub(size(S_temp), second_max_idx);
                    
                    peak_info(2).frequency = F(second_freq_idx);
                    peak_info(2).time = T(second_time_idx);
                    peak_info(2).magnitude = second_max_val;
                    peak_info(2).freq_idx = second_freq_idx;
                    peak_info(2).time_idx = second_time_idx;
                end
                
            catch ME
                warning('timefreq_analyzer:find_timefreq_peaks', ...
                        '峰值查找失败: %s', ME.message);
            end
        end
        
        function info_str = format_peak_info(peak_info, format_type)
            % 格式化峰值信息为字符串
            %
            % 输入:
            %   peak_info - 峰值信息结构体数组
            %   format_type - 格式类型 'simple' 或 'detailed' (默认: 'simple')
            %
            % 输出:
            %   info_str - 格式化的字符串
            
            if nargin < 2
                format_type = 'simple';
            end
            
            if isempty(peak_info)
                info_str = 'No peaks detected';
                return;
            end
            
            switch format_type
                case 'simple'
                    if length(peak_info) == 1
                        info_str = sprintf('Peak: (%.1f μs, %.1f kHz)', ...
                                          peak_info(1).time, peak_info(1).frequency);
                    else
                        info_str = sprintf('Peak 1: (%.1f μs, %.1f kHz)\nPeak 2: (%.1f μs, %.1f kHz)', ...
                                          peak_info(1).time, peak_info(1).frequency, ...
                                          peak_info(2).time, peak_info(2).frequency);
                    end
                    
                case 'detailed'
                    lines = cell(length(peak_info), 1);
                    for i = 1:length(peak_info)
                        lines{i} = sprintf('Peak %d:\n  Time: %.1f μs\n  Freq: %.1f kHz\n  Mag: %.2e', ...
                                          i, peak_info(i).time, peak_info(i).frequency, ...
                                          peak_info(i).magnitude);
                    end
                    info_str = strjoin(lines, '\n\n');
                    
                otherwise
                    error('timefreq_analyzer:format_peak_info', ...
                          'Unknown format type: %s', format_type);
            end
        end
        
        function S_dB = magnitude_to_dB(S, options)
            % 将幅值转换为分贝
            %
            % 输入:
            %   S - 时频矩阵 (复数或幅值)
            %   options - 可选参数
            %       .reference - 参考值 (默认: 1.0)
            %       .floor - 最小值（避免log(0)） (默认: eps)
            %
            % 输出:
            %   S_dB - 分贝表示的时频矩阵
            
            arguments
                S (:,:) double
                options.reference (1,1) double {mustBePositive} = 1.0
                options.floor (1,1) double {mustBePositive} = eps
            end
            
            % 提取幅值
            if ~isreal(S)
                S_magnitude = abs(S);
            else
                S_magnitude = S;
            end
            
            % 转换为分贝
            S_dB = 20 * log10(S_magnitude + options.floor);
        end
    end
end
