classdef filter_engine < handle
    % 滤波器引擎 - 统一的信号滤波模块
    % 
    % 功能:
    %   - 应用各种类型的滤波器（无滤波、高通、低通、带通）
    %   - 验证滤波器参数
    %   - 支持单信号和3D波场数据滤波
    %
    % 使用示例:
    %   filtered = filter_engine.apply(signal, 'bandpass', params);
    %   result = filter_engine.validate_params(params);
    %
    % 版本: 1.0
    % 作者: 重构团队
    % 日期: 2024
    
    methods (Static)
        function filtered = apply(signal, filter_type, params)
            % 应用滤波器到信号
            %
            % 输入:
            %   signal - 输入信号 (列向量)
            %   filter_type - 滤波器类型: 'none', 'highpass', 'lowpass', 'bandpass'
            %   params - 参数结构体
            %       .low_freq - 低频截止频率 (Hz)
            %       .high_freq - 高频截止频率 (Hz)
            %       .order - 滤波器阶数 (默认: 4)
            %       .fs - 采样频率 (Hz)
            %
            % 输出:
            %   filtered - 滤波后的信号
            
            % 参数验证
            arguments
                signal (:,1) double
                filter_type (1,:) char {mustBeMember(filter_type, ...
                    {'none','highpass','lowpass','bandpass'})}
                params (1,1) struct
            end
            
            % 无滤波直接返回
            if strcmp(filter_type, 'none')
                filtered = signal;
                return;
            end
            
            % 检查必要参数
            if ~isfield(params, 'fs') || params.fs <= 0
                error('filter_engine:apply', 'Valid sampling frequency (fs) is required');
            end
            
            % 设置默认阶数
            if ~isfield(params, 'order')
                params.order = 4;
            end
            
            % 修复：使用结构体方式调用validate_params
            validation = filter_engine.validate_params(params, struct('strict', false));
            if ~validation.valid
                error('filter_engine:apply', validation.message);
            end
            
            try
                % 计算奈奎斯特频率
                nyquist = params.fs / 2;
                
                % 根据滤波器类型设计滤波器
                switch filter_type
                    case 'highpass'
                        % 高通滤波器
                        low_norm = params.low_freq / nyquist;
                        low_norm = max(0.001, min(0.999, low_norm));
                        [b, a] = butter(params.order, low_norm, 'high');
                        
                    case 'lowpass'
                        % 低通滤波器
                        high_norm = params.high_freq / nyquist;
                        high_norm = max(0.001, min(0.999, high_norm));
                        [b, a] = butter(params.order, high_norm, 'low');
                        
                    case 'bandpass'
                        % 带通滤波器
                        low_norm = params.low_freq / nyquist;
                        high_norm = params.high_freq / nyquist;
                        
                        % 确保频率在有效范围内
                        low_norm = max(0.001, min(0.999, low_norm));
                        high_norm = max(0.001, min(0.999, high_norm));
                        
                        [b, a] = butter(params.order, [low_norm, high_norm], 'bandpass');
                end
                
                % 应用滤波器（使用零相位滤波）
                filtered = filtfilt(b, a, signal);
                
            catch ME
                warning('filter_engine:apply', ...
                        'Filter application failed: %s. Returning original signal.', ME.message);
                filtered = signal;
            end
        end
        
        function filtered_data = apply_3d(data_xyt, filter_type, params, show_progress)
            % 对3D波场数据应用滤波器
            %
            % 输入:
            %   data_xyt - 3D波场数据 (m×n×t)
            %   filter_type - 滤波器类型
            %   params - 参数结构体
            %   show_progress - 是否显示进度条 (默认: true)
            %
            % 输出:
            %   filtered_data - 滤波后的3D数据
            
            if nargin < 4
                show_progress = true;
            end
            
            % 无滤波直接返回
            if strcmp(filter_type, 'none')
                filtered_data = data_xyt;
                return;
            end
            
            [m_size, n_size, t_size] = size(data_xyt);
            filtered_data = zeros(size(data_xyt));
            
            % 进度条
            h_wait = [];
            if show_progress
                h_wait = waitbar(0, 'Applying filter to wave field...');
            end
            
            try
                total_points = m_size * n_size;
                processed_points = 0;
                
                for i = 1:m_size
                    for j = 1:n_size
                        % 提取单点信号
                        signal = squeeze(data_xyt(i, j, :));
                        
                        % 应用滤波
                        filtered_signal = filter_engine.apply(signal, filter_type, params);
                        
                        % 保存滤波后的信号
                        filtered_data(i, j, :) = filtered_signal;
                        
                        % 更新进度
                        processed_points = processed_points + 1;
                        if show_progress && ~isempty(h_wait) && ishandle(h_wait)
                            waitbar(processed_points/total_points, h_wait);
                        end
                    end
                end
                
                if show_progress && ~isempty(h_wait) && ishandle(h_wait)
                    close(h_wait);
                end
                
            catch ME
                if show_progress && ~isempty(h_wait) && ishandle(h_wait)
                    close(h_wait);
                end
                warning('filter_engine:apply_3d', ...
                        'Filter application failed: %s. Returning original data.', ME.message);
                filtered_data = data_xyt;
            end
        end
        
        function result = validate_params(params, varargin)
            % 验证滤波器参数
            %
            % 输入:
            %   params - 参数结构体
            %       .low_freq - 低频截止频率 (Hz)
            %       .high_freq - 高频截止频率 (Hz)
            %       .fs - 采样频率 (Hz)
            %       .order - 滤波器阶数 (可选)
            %   varargin - 可选参数（可以是结构体或名称-值对）
            %       strict - 严格模式 (默认: true)
            %
            % 输出:
            %   result - 验证结果结构体
            %       .valid - 是否有效
            %       .message - 验证消息
            
            % 处理可选参数
            p = inputParser;
            addParameter(p, 'strict', true, @islogical);
            
            % 解析输入
            if nargin > 1
                if isstruct(varargin{1})
                    % 如果第一个参数是结构体
                    opts = varargin{1};
                    if isfield(opts, 'strict')
                        parse(p, 'strict', opts.strict);
                    else
                        parse(p);
                    end
                else
                    % 如果是名称-值对
                    parse(p, varargin{:});
                end
            else
                parse(p);
            end
            
            strict_mode = p.Results.strict;
            
            result = struct('valid', true, 'message', 'Parameters are valid');
            
            % 检查必要字段
            if ~isfield(params, 'fs')
                result.valid = false;
                result.message = 'Sampling frequency (fs) is required';
                return;
            end
            
            % 计算奈奎斯特频率
            nyquist = params.fs / 2;
            
            % 验证采样频率
            if params.fs <= 0
                result.valid = false;
                result.message = 'Sampling frequency must be positive';
                return;
            end
            
            % 验证低频截止频率
            if isfield(params, 'low_freq')
                if params.low_freq <= 0
                    result.valid = false;
                    result.message = 'Low frequency must be positive';
                    return;
                end
                
                % 修复：宽松模式允许接近但不等于奈奎斯特频率
                if strict_mode
                    if params.low_freq >= nyquist
                        result.valid = false;
                        result.message = sprintf('Low frequency must be less than Nyquist frequency (%.1f Hz)', nyquist);
                        return;
                    end
                else
                    if params.low_freq >= nyquist * 0.999
                        result.valid = false;
                        result.message = sprintf('Low frequency too close to Nyquist frequency (%.1f Hz)', nyquist);
                        return;
                    end
                end
            end
            
            % 验证高频截止频率
            if isfield(params, 'high_freq')
                if params.high_freq <= 0
                    result.valid = false;
                    result.message = 'High frequency must be positive';
                    return;
                end
                
                % 修复：宽松模式
                if strict_mode
                    if params.high_freq >= nyquist
                        result.valid = false;
                        result.message = sprintf('High frequency must be less than Nyquist frequency (%.1f Hz)', nyquist);
                        return;
                    end
                else
                    if params.high_freq >= nyquist * 0.999
                        result.valid = false;
                        result.message = sprintf('High frequency too close to Nyquist frequency (%.1f Hz)', nyquist);
                        return;
                    end
                end
            end
            
            % 验证频率范围
            if isfield(params, 'low_freq') && isfield(params, 'high_freq')
                if params.low_freq >= params.high_freq
                    result.valid = false;
                    result.message = 'Low frequency must be less than high frequency';
                    return;
                end
            end
            
            % 验证滤波器阶数
            if isfield(params, 'order')
                if params.order < 1 || params.order ~= round(params.order)
                    result.valid = false;
                    result.message = 'Filter order must be a positive integer';
                    return;
                end
            end
        end
        
        function filter_types = get_filter_types()
            % 返回所有支持的滤波器类型
            %
            % 输出:
            %   filter_types - 滤波器类型cell数组
            
            filter_types = {'none', 'highpass', 'lowpass', 'bandpass'};
        end
        
        function filter_names = get_filter_names()
            % 返回所有滤波器的显示名称（用于UI）
            %
            % 输出:
            %   filter_names - 滤波器显示名称cell数组
            
            filter_names = {'No Filter', 'High Pass', 'Low Pass', 'Band Pass'};
        end
        
        function filter_type = name_to_type(filter_name)
            % 将显示名称转换为滤波器类型
            %
            % 输入:
            %   filter_name - 滤波器显示名称
            %
            % 输出:
            %   filter_type - 滤波器类型字符串
            
            names = filter_engine.get_filter_names();
            types = filter_engine.get_filter_types();
            
            idx = find(strcmp(names, filter_name), 1);
            if ~isempty(idx)
                filter_type = types{idx};
            else
                filter_type = 'none';
            end
        end
        
        function filter_name = type_to_name(filter_type)
            % 将滤波器类型转换为显示名称
            %
            % 输入:
            %   filter_type - 滤波器类型字符串
            %
            % 输出:
            %   filter_name - 滤波器显示名称
            
            types = filter_engine.get_filter_types();
            names = filter_engine.get_filter_names();
            
            idx = find(strcmp(types, filter_type), 1);
            if ~isempty(idx)
                filter_name = names{idx};
            else
                filter_name = 'No Filter';
            end
        end
        
        function info_str = format_filter_info(filter_type, params)
            % 格式化滤波器信息为字符串
            %
            % 输入:
            %   filter_type - 滤波器类型
            %   params - 参数结构体
            %
            % 输出:
            %   info_str - 格式化的字符串
            
            filter_name = filter_engine.type_to_name(filter_type);
            
            switch filter_type
                case 'none'
                    info_str = 'No Filter Applied';
                    
                case 'highpass'
                    info_str = sprintf('%s Filter\nCutoff: %.1f kHz\nOrder: %d', ...
                                      filter_name, params.low_freq/1000, params.order);
                    
                case 'lowpass'
                    info_str = sprintf('%s Filter\nCutoff: %.1f kHz\nOrder: %d', ...
                                      filter_name, params.high_freq/1000, params.order);
                    
                case 'bandpass'
                    info_str = sprintf('%s Filter\nRange: %.1f - %.1f kHz\nOrder: %d', ...
                                      filter_name, params.low_freq/1000, params.high_freq/1000, params.order);
                    
                otherwise
                    info_str = 'Unknown Filter';
            end
        end
    end
end
