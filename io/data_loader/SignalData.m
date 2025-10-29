classdef SignalData < handle
    % 标准信号数据结构类
    % 
    % 功能:
    %   - 统一存储A/B/C模块的信号数据
    %   - 提供标准化的数据访问接口
    %   - 支持时间范围提取
    %
    % 数据格式标准:
    %   data: m×n×t 矩阵
    %   - 单点(A模块): 1×1×t
    %   - B扫(B模块): 1×m×t
    %   - 波场(C模块): m×n×t
    %
    % 使用示例:
    %   sig_data = SignalData(raw_data, time, fs, 'single_point');
    %   signal = sig_data.get_point(1, 1);
    %
    % 版本: 1.0
    % 作者: 重构团队
    % 日期: 2024
    
    properties
        data         % m×n×t 矩阵 - 标准化3D数据
        time         % t×1 向量 - 时间轴
        fs           % 采样频率 (Hz)
        metadata     % 元数据结构体
    end
    
    methods
        function obj = SignalData(raw_data, time, fs, data_type)
            % 构造函数
            %
            % 输入:
            %   raw_data - 原始数据（可以是各种格式）
            %   time - 时间向量
            %   fs - 采样频率
            %   data_type - 数据类型: 'single_point', 'bscan', 'wavefield', 'auto'
            
            % 参数验证
            arguments
                raw_data double
                time (:,1) double
                fs (1,1) double {mustBePositive}
                data_type (1,:) char {mustBeMember(data_type, ...
                    {'single_point','bscan','wavefield','auto'})} = 'auto'
            end
            
            % 自动检测数据类型
            if strcmp(data_type, 'auto')
                data_type = obj.detect_data_type(raw_data);
            end
            
            % 标准化数据格式
            obj.data = obj.standardize_format(raw_data, data_type);
            obj.time = time(:);
            obj.fs = fs;
            
            % 设置元数据
            [m, n, t] = size(obj.data);
            obj.metadata = struct();
            obj.metadata.type = data_type;
            obj.metadata.dimensions = [m, n, t];
            obj.metadata.duration = (time(end) - time(1));
            obj.metadata.num_points = m * n;
            obj.metadata.source = 'unknown';
            obj.metadata.created = datetime('now');
        end
        
        function signal = get_point(obj, m, n)
            % 获取指定位置的信号
            %
            % 输入:
            %   m - 行索引
            %   n - 列索引
            %
            % 输出:
            %   signal - 该位置的时域信号 (t×1向量)
            
            arguments
                obj
                m (1,1) double {mustBePositive, mustBeInteger}
                n (1,1) double {mustBePositive, mustBeInteger}
            end
            
            [max_m, max_n, ~] = size(obj.data);
            
            if m > max_m || n > max_n
                error('SignalData:get_point', ...
                      'Index out of bounds. Data size: %dx%d, requested: (%d,%d)', ...
                      max_m, max_n, m, n);
            end
            
            signal = squeeze(obj.data(m, n, :));
        end
        
        function new_obj = apply_time_range(obj, start_time, end_time)
            % 提取时间范围
            %
            % 输入:
            %   start_time - 开始时间 (秒)
            %   end_time - 结束时间 (秒)
            %
            % 输出:
            %   new_obj - 新的SignalData对象（包含选定时间范围）
            
            arguments
                obj
                start_time (1,1) double
                end_time (1,1) double
            end
            
            if start_time >= end_time
                error('SignalData:apply_time_range', 'Start time must be less than end time');
            end
            
            % 找到时间索引
            time_idx = (obj.time >= start_time) & (obj.time <= end_time);
            
            if sum(time_idx) == 0
                error('SignalData:apply_time_range', 'No data points in specified time range');
            end
            
            % 创建新对象
            new_data = obj.data(:, :, time_idx);
            new_time = obj.time(time_idx);
            
            new_obj = SignalData(new_data, new_time, obj.fs, obj.metadata.type);
            new_obj.metadata.source = [obj.metadata.source, '_time_filtered'];
        end
        
        function summary_str = get_summary(obj)
            % 获取数据摘要字符串
            %
            % 输出:
            %   summary_str - 摘要信息字符串
            
            [m, n, t] = size(obj.data);
            
            summary_str = sprintf(['Signal Data Summary:\n', ...
                                   '  Type: %s\n', ...
                                   '  Dimensions: %d × %d × %d\n', ...
                                   '  Points: %d\n', ...
                                   '  Sampling Rate: %.2f MHz\n', ...
                                   '  Duration: %.2f μs\n', ...
                                   '  Time Range: %.2f ~ %.2f μs'], ...
                                  obj.metadata.type, m, n, t, ...
                                  obj.metadata.num_points, ...
                                  obj.fs / 1e6, ...
                                  obj.metadata.duration * 1e6, ...
                                  obj.time(1) * 1e6, obj.time(end) * 1e6);
        end
        
        function success = validate(obj)
            % 验证数据完整性
            %
            % 输出:
            %   success - 是否通过验证
            
            success = true;
            
            try
                % 检查数据维度
                [m, n, t] = size(obj.data);
                if t ~= length(obj.time)
                    warning('SignalData:validate', 'Time dimension mismatch');
                    success = false;
                end
                
                % 检查是否有NaN或Inf
                if any(isnan(obj.data(:))) || any(isinf(obj.data(:)))
                    warning('SignalData:validate', 'Data contains NaN or Inf values');
                    success = false;
                end
                
                % 检查采样率
                if obj.fs <= 0
                    warning('SignalData:validate', 'Invalid sampling rate');
                    success = false;
                end
                
                % 检查时间向量
                if any(diff(obj.time) <= 0)
                    warning('SignalData:validate', 'Time vector is not monotonically increasing');
                    success = false;
                end
                
            catch ME
                warning('SignalData:validate', 'Validation error: %s', ME.message);
                success = false;
            end
        end
    end
    
    methods (Static, Access = private)
        function data_type = detect_data_type(raw_data)
            % 自动检测数据类型
            %
            % 输入:
            %   raw_data - 原始数据
            %
            % 输出:
            %   data_type - 检测到的数据类型
            
            dims = size(raw_data);
            
            if length(dims) == 2
                % 2D数据
                if dims(1) == 1 || dims(2) == 1
                    % 单个信号
                    data_type = 'single_point';
                else
                    % 假设是B扫描格式（多个文件×时间点）
                    data_type = 'bscan';
                end
            elseif length(dims) == 3
                % 3D数据
                if dims(1) == 1 && dims(2) == 1
                    data_type = 'single_point';
                elseif dims(1) == 1 || dims(2) == 1
                    data_type = 'bscan';
                else
                    data_type = 'wavefield';
                end
            else
                error('SignalData:detect_data_type', 'Unsupported data format');
            end
        end
        
        function standardized_data = standardize_format(raw_data, data_type)
            % 标准化数据格式为 m×n×t
            %
            % 输入:
            %   raw_data - 原始数据
            %   data_type - 数据类型
            %
            % 输出:
            %   standardized_data - 标准化后的3D数据
            
            dims = size(raw_data);
            
            switch data_type
                case 'single_point'
                    % 确保格式为 1×1×t
                    if length(dims) == 2
                        if dims(1) == 1
                            % 行向量: 1×t -> 1×1×t
                            standardized_data = reshape(raw_data, [1, 1, dims(2)]);
                        else
                            % 列向量: t×1 -> 1×1×t
                            standardized_data = reshape(raw_data, [1, 1, dims(1)]);
                        end
                    elseif length(dims) == 3
                        % 已经是3D，确保前两维是1
                        if dims(1) ~= 1 || dims(2) ~= 1
                            standardized_data = reshape(raw_data, [1, 1, numel(raw_data)]);
                        else
                            standardized_data = raw_data;
                        end
                    else
                        error('SignalData:standardize_format', 'Invalid single_point data format');
                    end
                    
                case 'bscan'
                    % 确保格式为 1×m×t
                    if length(dims) == 2
                        % 假设是 m×t 格式
                        standardized_data = reshape(raw_data, [1, dims(1), dims(2)]);
                    elseif length(dims) == 3
                        % 已经是3D
                        if dims(1) == 1
                            standardized_data = raw_data;
                        elseif dims(2) == 1
                            % m×1×t -> 1×m×t
                            standardized_data = permute(raw_data, [2, 1, 3]);
                        else
                            error('SignalData:standardize_format', 'Invalid bscan data format');
                        end
                    else
                        error('SignalData:standardize_format', 'Invalid bscan data format');
                    end
                    
                case 'wavefield'
                    % 确保是 m×n×t 格式
                    if length(dims) ~= 3
                        error('SignalData:standardize_format', 'Wavefield data must be 3D');
                    end
                    standardized_data = raw_data;
                    
                otherwise
                    error('SignalData:standardize_format', 'Unknown data type: %s', data_type);
            end
        end
    end
end
