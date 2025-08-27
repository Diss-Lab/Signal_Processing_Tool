classdef wave_data_processor < handle
    % 波场数据处理器 - 处理MAT文件
    
    methods (Static)
        function [success, processed_data] = process_single_mat_file(mat_file_path, grid_params)
            % 处理单个MAT文件
            % 输入: mat_file_path - MAT文件路径, grid_params - 网格参数结构体
            % 输出: success - 是否成功, processed_data - 处理后的数据结构体
            
            success = false;
            processed_data = struct();
            
            try
                % 加载MAT文件
                loaded_data = load(mat_file_path);
                field_names = fieldnames(loaded_data);
                fprintf('文件变量: %s\n', strjoin(field_names, ', '));
                
                % 检查数据格式并处理不同的MAT文件结构
                if isfield(loaded_data, 'data_xyt') && isfield(loaded_data, 'data_time')
                    % 标准格式：data_xyt 和 data_time
                    data_xyt = loaded_data.data_xyt;
                    data_time = loaded_data.data_time;
                    
                    % 计算采样频率
                    if isfield(loaded_data, 'fs')
                        fs = loaded_data.fs;
                    else
                        dt = mean(diff(data_time));
                        fs = 1 / dt;
                    end
                    
                elseif isfield(loaded_data, 'x') && isfield(loaded_data, 'y')
                    % 原始数据格式：x 为时间序列(1×N)，y 为振动数据(M×N)
                    x_data = loaded_data.x;  % 1×N 时间序列
                    y_data = loaded_data.y;  % M×N 振动数据
                    
                    fprintf('原始数据尺寸: x=%s, y=%s\n', mat2str(size(x_data)), mat2str(size(y_data)));
                    
                    % 确保x是行向量
                    if size(x_data, 1) > size(x_data, 2)
                        x_data = x_data';
                    end
                    data_time = x_data;
                    
                    % 计算采样频率
                    if length(data_time) > 1
                        dt = mean(diff(data_time));
                        fs = 1 / dt;
                    else
                        error('时间数据点数不足');
                    end
                    
                    % 验证数据尺寸
                    [M, N] = size(y_data);
                    if N ~= length(data_time)
                        error('时间序列长度与振动数据不匹配: 时间点=%d, 数据列数=%d', length(data_time), N);
                    end
                    
                    % 验证网格参数
                    expected_points = grid_params.n * grid_params.m;
                    if M ~= expected_points
                        warning('数据点数(%d)与网格参数(%d×%d=%d)不匹配', M, grid_params.n, grid_params.m, expected_points);
                        % 调整网格参数以匹配数据
                        if mod(M, grid_params.n) == 0
                            grid_params.m = M / grid_params.n;
                            fprintf('自动调整网格高度为: %d\n', grid_params.m);
                        elseif mod(M, grid_params.m) == 0
                            grid_params.n = M / grid_params.m;
                            fprintf('自动调整网格宽度为: %d\n', grid_params.n);
                        else
                            error('无法将%d个数据点重排为%d×%d网格', M, grid_params.n, grid_params.m);
                        end
                    end
                    
                    % 重塑数据
                    fprintf('开始重塑数据: %d个点 -> %d×%d网格\n', M, grid_params.m, grid_params.n);
                    data_xyt = wave_data_processor.reshape_wave_data(y_data, grid_params);
                    
                else
                    error('未知的MAT文件格式。期望变量: (data_xyt, data_time) 或 (x, y)。找到: %s', ...
                          strjoin(field_names, ', '));
                end
                
                % 保存处理后的数据
                [filepath, ~, ~] = fileparts(mat_file_path);
                save_path = fullfile(filepath, 'data.mat');
                
                % 保存时包含网格参数
                m = grid_params.m;
                n = grid_params.n;
                save(save_path, 'data_xyt', 'data_time', 'fs', 'm', 'n');
                
                % 返回处理结果
                processed_data.data_xyt = data_xyt;
                processed_data.data_time = data_time;
                processed_data.fs = fs;
                processed_data.m = grid_params.m;
                processed_data.n = grid_params.n;
                
                success = true;
                fprintf('数据处理完成，保存到: %s\n', save_path);
                fprintf('最终数据尺寸: %s\n', mat2str(size(data_xyt)));
                
            catch ME
                fprintf('处理MAT文件失败: %s\n', ME.message);
                fprintf('错误位置: %s\n', ME.stack(1).name);
            end
        end
        
        function data_xyt = reshape_wave_data(y_data, grid_params)
            % 重塑波场数据
            % 输入: y_data - 原始振动数据 (M×N), grid_params - 网格参数
            % 输出: data_xyt - 重塑后的3D数据 (m×n×N)
            
            [M, N] = size(y_data);
            m = grid_params.m;
            n = grid_params.n;
            
            fprintf('重塑数据: %d×%d -> %d×%d×%d\n', M, N, m, n, N);
            
            % 初始化输出矩阵
            data_xyt = zeros(m, n, N);
            
            % 进度条
            h_wait = waitbar(0, 'Reshaping wave data...');
            
            try
                % 重塑数据 - 将每个时间点的M个空间点重排为m×n网格
                for time_index = 1:N
                    % 获取当前时间点的所有空间点数据
                    spatial_data = y_data(:, time_index);  % M×1
                    
                    % 重塑为网格 (先按列填充，然后转置)
                    reshaped_data = reshape(spatial_data, n, m)';  % m×n
                    
                    % 对偶数行进行翻转（扫描路径补偿）
                    for row = 1:m
                        if mod(row, 2) == 0
                            reshaped_data(row, :) = fliplr(reshaped_data(row, :));
                        end
                    end
                    
                    data_xyt(:, :, time_index) = reshaped_data;
                    
                    if mod(time_index, 100) == 0 || time_index == N
                        waitbar(time_index/N, h_wait, sprintf('Processing time point %d/%d', time_index, N));
                    end
                end
                
                close(h_wait);
                
            catch ME
                if exist('h_wait', 'var') && ishandle(h_wait)
                    close(h_wait);
                end
                rethrow(ME);
            end
        end
        
        function result = validate_grid_params(grid_params, data_size)
            % 验证网格参数
            % 输入: grid_params - 网格参数, data_size - 数据尺寸
            % 输出: result - 验证结果结构体
            
            result = struct();
            result.valid = true;
            result.message = '';
            
            expected_size = grid_params.n * grid_params.m;
            
            if data_size ~= expected_size
                result.valid = false;
                result.message = sprintf('Grid size mismatch. Expected %d points (n=%d, m=%d), got %d points.', ...
                                        expected_size, grid_params.n, grid_params.m, data_size);
            else
                result.message = 'Grid parameters are valid';
            end
        end
    end
end
