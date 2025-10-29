classdef wavefield_processor < handle
    % 波场数据处理器 - 统一的波场数据加载和处理模块
    % 
    % 功能:
    %   - 加载MAT格式的波场数据
    %   - 自动检测数据格式
    %   - 应用扫描路径补偿（蛇形扫描）
    %   - 数据格式标准化
    %
    % 使用示例:
    %   signal_data = wavefield_processor.load_and_process('data.mat', struct('m', 11, 'n', 13));
    %
    % 版本: 1.0
    % 作者: 重构团队
    % 日期: 2024
    
    methods (Static)
        function signal_data = load_and_process(mat_file_path, grid_params, options)
            % 加载并处理波场MAT文件
            %
            % 输入:
            %   mat_file_path - MAT文件路径
            %   grid_params - 网格参数结构体
            %       .m - 网格高度（行数）
            %       .n - 网格宽度（列数）
            %   options - 可选参数
            %       .apply_scan_compensation - 是否应用扫描补偿 (默认: true)
            %       .show_progress - 是否显示进度条 (默认: true)
            %
            % 输出:
            %   signal_data - SignalData对象
            
            arguments
                mat_file_path (1,:) char
                grid_params (1,1) struct
                options.apply_scan_compensation (1,1) logical = true
                options.show_progress (1,1) logical = true
            end
            
            % 验证文件存在
            if ~exist(mat_file_path, 'file')
                error('wavefield_processor:load_and_process', 'File not found: %s', mat_file_path);
            end
            
            % 验证网格参数
            if ~isfield(grid_params, 'm') || ~isfield(grid_params, 'n')
                error('wavefield_processor:load_and_process', 'Grid parameters must contain m and n fields');
            end
            
            try
                % 加载MAT文件
                loaded_data = load(mat_file_path);
                
                % 自动检测并解析数据格式
                [data_xyt, data_time, fs] = wavefield_processor.parse_mat_data(loaded_data, grid_params, options);
                
                % 创建SignalData对象
                signal_data = SignalData(data_xyt, data_time, fs, 'wavefield');
                signal_data.metadata.source = mat_file_path;
                signal_data.metadata.grid_params = grid_params;
                signal_data.metadata.scan_compensated = options.apply_scan_compensation;
                
                fprintf('✓ 成功加载波场数据: %s (网格: %d×%d)\n', mat_file_path, grid_params.m, grid_params.n);
                
            catch ME
                error('wavefield_processor:load_and_process', ...
                      'Failed to process %s: %s', mat_file_path, ME.message);
            end
        end
        
        function [data_xyt, data_time, fs] = parse_mat_data(loaded_data, grid_params, options)
            % 解析MAT文件数据
            %
            % 支持格式:
            %   格式A: data_xyt + data_time + fs (已处理格式)
            %   格式B: x (时间) + y (数据) (原始格式)
            
            if isfield(loaded_data, 'data_xyt') && isfield(loaded_data, 'data_time')
                % 格式A: 已处理格式
                data_xyt = loaded_data.data_xyt;
                data_time = loaded_data.data_time;
                
                if isfield(loaded_data, 'fs')
                    fs = loaded_data.fs;
                else
                    fs = 1 / mean(diff(data_time));
                end
                
                % 验证尺寸
                [m_actual, n_actual, ~] = size(data_xyt);
                if m_actual ~= grid_params.m || n_actual ~= grid_params.n
                    warning('wavefield_processor:parse_mat_data', ...
                           'Grid size mismatch. Expected %d×%d, got %d×%d', ...
                           grid_params.m, grid_params.n, m_actual, n_actual);
                end
                
            elseif isfield(loaded_data, 'x') && isfield(loaded_data, 'y')
                % 格式B: x为时间，y为原始数据
                data_time = loaded_data.x;
                raw_data = loaded_data.y;
                
                % 计算采样频率
                fs = 1 / (data_time(2) - data_time(1));
                
                % 验证数据尺寸
                validation = wavefield_processor.validate_grid_size(grid_params, size(raw_data, 1));
                if ~validation.valid
                    warning('wavefield_processor:parse_mat_data', validation.message);
                end
                
                % 重塑数据
                data_xyt = wavefield_processor.reshape_wavefield(raw_data, grid_params, ...
                    options.apply_scan_compensation, options.show_progress);
                
            else
                % 未知格式
                field_names = fieldnames(loaded_data);
                error('wavefield_processor:parse_mat_data', ...
                      'Unknown MAT file format. Expected variables: (data_xyt, data_time) or (x, y). Found: %s', ...
                      strjoin(field_names, ', '));
            end
        end
        
        function data_xyt = reshape_wavefield(raw_data, grid_params, apply_scan_compensation, show_progress)
            % 重塑波场数据为标准3D格式
            %
            % 输入:
            %   raw_data - 原始数据 (num_points × time_points)
            %   grid_params - 网格参数
            %   apply_scan_compensation - 是否应用扫描补偿
            %   show_progress - 是否显示进度条
            %
            % 输出:
            %   data_xyt - 重塑后的3D数据 (m × n × time_points)
            
            m = grid_params.m;
            n = grid_params.n;
            [~, t] = size(raw_data);
            
            % 初始化输出矩阵
            data_xyt = zeros(m, n, t);
            
            % 进度条
            h_wait = [];
            if show_progress
                h_wait = waitbar(0, 'Reshaping wave field data...');
            end
            
            try
                % 逐时间点重塑数据
                for time_idx = 1:t
                    % 提取当前时间点的数据
                    displacement = raw_data(:, time_idx);
                    
                    % 重塑为m×n网格
                    reshaped_data = reshape(displacement, n, m)';
                    
                    % 应用扫描路径补偿（蛇形扫描）
                    if apply_scan_compensation
                        reshaped_data = wavefield_processor.apply_snake_scan_compensation(reshaped_data);
                    end
                    
                    data_xyt(:, :, time_idx) = reshaped_data;
                    
                    % 更新进度条
                    if show_progress && ~isempty(h_wait) && ishandle(h_wait)
                        waitbar(time_idx/t, h_wait);
                    end
                end
                
                if show_progress && ~isempty(h_wait) && ishandle(h_wait)
                    close(h_wait);
                end
                
            catch ME
                if show_progress && ~isempty(h_wait) && ishandle(h_wait)
                    close(h_wait);
                end
                rethrow(ME);
            end
        end
        
        function compensated_data = apply_snake_scan_compensation(grid_data)
            % 应用蛇形扫描路径补偿
            %
            % 对偶数行进行翻转，因为扫描仪采用蛇形路径：
            % 行1: →→→→→
            % 行2: ←←←←←
            % 行3: →→→→→
            % ...
            %
            % 输入:
            %   grid_data - m×n网格数据
            %
            % 输出:
            %   compensated_data - 补偿后的数据
            
            compensated_data = grid_data;
            [m, ~] = size(grid_data);
            
            % 对偶数行进行翻转
            for row = 1:m
                if mod(row, 2) == 0
                    compensated_data(row, :) = fliplr(grid_data(row, :));
                end
            end
        end
        
        function result = validate_grid_size(grid_params, data_size)
            % 验证网格参数与数据尺寸
            %
            % 输入:
            %   grid_params - 网格参数 (m, n)
            %   data_size - 数据点数
            %
            % 输出:
            %   result - 验证结果结构体
            %       .valid - 是否有效
            %       .message - 验证消息
            
            result = struct();
            result.valid = true;
            result.message = '';
            
            expected_size = grid_params.m * grid_params.n;
            
            if data_size ~= expected_size
                result.valid = false;
                result.message = sprintf('Grid size mismatch. Expected %d points (m=%d, n=%d), got %d points', ...
                                        expected_size, grid_params.m, grid_params.n, data_size);
            else
                result.message = sprintf('Grid parameters valid: %d×%d = %d points', ...
                                        grid_params.m, grid_params.n, expected_size);
            end
        end
        
        function grid_params = auto_detect_grid_size(data_size)
            % 自动检测网格尺寸（尝试最接近的矩形）
            %
            % 输入:
            %   data_size - 数据点数
            %
            % 输出:
            %   grid_params - 自动检测的网格参数
            
            % 找到最接近的因数分解
            sqrt_size = sqrt(data_size);
            
            % 从sqrt附近开始搜索
            for n = round(sqrt_size):-1:1
                if mod(data_size, n) == 0
                    m = data_size / n;
                    grid_params = struct('m', m, 'n', n);
                    fprintf('自动检测网格尺寸: %d×%d\n', m, n);
                    return;
                end
            end
            
            % 如果无法完美分解，使用最接近的
            n = round(sqrt_size);
            m = ceil(data_size / n);
            grid_params = struct('m', m, 'n', n);
            warning('wavefield_processor:auto_detect_grid_size', ...
                   '无法完美分解 %d 个点。使用近似网格: %d×%d', data_size, m, n);
        end
        
        function success = save_processed_data(signal_data, output_path)
            % 保存处理后的波场数据
            %
            % 输入:
            %   signal_data - SignalData对象
            %   output_path - 输出文件路径（可选，默认为源文件同目录data.mat）
            
            if nargin < 2
                % 默认保存路径
                source_file = signal_data.metadata.source;
                [filepath, ~, ~] = fileparts(source_file);
                output_path = fullfile(filepath, 'data.mat');
            end
            
            try
                % 提取数据
                data_xyt = signal_data.data;
                data_time = signal_data.time;
                fs = signal_data.fs;
                m = signal_data.metadata.dimensions(1);
                n = signal_data.metadata.dimensions(2);
                
                % 保存
                save(output_path, 'data_xyt', 'data_time', 'fs', 'm', 'n');
                
                fprintf('✓ 波场数据已保存: %s\n', output_path);
                success = true;
                
            catch ME
                warning('wavefield_processor:save_processed_data', ...
                       'Failed to save data: %s', ME.message);
                success = false;
            end
        end
        
        function info_str = get_wavefield_info(signal_data)
            % 获取波场信息摘要
            %
            % 输入:
            %   signal_data - SignalData对象
            %
            % 输出:
            %   info_str - 信息字符串
            
            [m, n, t] = size(signal_data.data);
            
            info_str = sprintf(['Wave Field Information:\n', ...
                               '  Grid Size: %d × %d\n', ...
                               '  Total Points: %d\n', ...
                               '  Time Points: %d\n', ...
                               '  Sampling Rate: %.2f MHz\n', ...
                               '  Duration: %.2f μs\n', ...
                               '  Time Range: %.2f ~ %.2f μs\n', ...
                               '  Scan Compensated: %s'], ...
                              m, n, m*n, t, ...
                              signal_data.fs / 1e6, ...
                              signal_data.metadata.duration * 1e6, ...
                              signal_data.time(1) * 1e6, signal_data.time(end) * 1e6, ...
                              mat2str(signal_data.metadata.scan_compensated));
        end
    end
end
