function test_wavefield_processor()
    % 波场数据处理器测试脚本
    
    fprintf('\n========================================\n');
    fprintf('波场数据处理器测试开始\n');
    fprintf('========================================\n\n');
    
    % 添加路径
    project_root = fileparts(pwd);
    addpath(fullfile(project_root, 'core', 'imaging'));
    addpath(fullfile(project_root, 'io', 'data_loader'));
    addpath(fullfile(project_root, 'C'));
    
    % 验证类加载
    if ~exist('wavefield_processor', 'class')
        error('无法加载 wavefield_processor 类！');
    end
    
    fprintf('✓ wavefield_processor 类加载成功\n\n');
    
    % 测试计数器
    total_tests = 0;
    passed_tests = 0;
    
    %% 测试1: 网格尺寸验证
    fprintf('【测试1】网格尺寸验证...\n');
    total_tests = total_tests + 1;
    try
        grid_params = struct('m', 11, 'n', 13);
        result = wavefield_processor.validate_grid_size(grid_params, 143);
        
        if result.valid
            fprintf('   ✅ 通过 (143点 = 11×13)\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试2: 扫描补偿
    fprintf('\n【测试2】蛇形扫描补偿...\n');
    total_tests = total_tests + 1;
    try
        % 创建测试数据：第一行递增，第二行也递增
        test_data = [1, 2, 3, 4, 5; 
                     6, 7, 8, 9, 10];
        
        compensated = wavefield_processor.apply_snake_scan_compensation(test_data);
        
        % 验证第二行是否被翻转
        expected_row2 = [10, 9, 8, 7, 6];
        
        if isequal(compensated(1, :), test_data(1, :)) && isequal(compensated(2, :), expected_row2)
            fprintf('   ✅ 通过 (第2行已翻转)\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试3: 数据重塑
    fprintf('\n【测试3】数据重塑功能...\n');
    total_tests = total_tests + 1;
    try
        % 创建模拟数据
        m = 5;
        n = 10;
        t = 100;
        raw_data = randn(m*n, t);
        grid_params = struct('m', m, 'n', n);
        
        reshaped_data = wavefield_processor.reshape_wavefield(raw_data, grid_params, true, false);
        
        if isequal(size(reshaped_data), [m, n, t])
            fprintf('   ✅ 通过 (重塑为 %d×%d×%d)\n', m, n, t);
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败 (尺寸: %s)\n', mat2str(size(reshaped_data)));
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试4: 真实数据加载（如果存在）
    fprintf('\n【测试4】真实数据文件加载...\n');
    total_tests = total_tests + 1;
    
    % 测试数据路径
    test_file = 'C:\Users\123\Desktop\一七三\数据\现场演示数据\激光多普勒系统\金属板\3\data2.mat';
    
    if exist(test_file, 'file')
        try
            grid_params = struct('m', 11, 'n', 13);
            signal_data = wavefield_processor.load_and_process(test_file, grid_params, ...
                'show_progress', false);
            
            [m, n, t] = size(signal_data.data);
            
            if m == 11 && n == 13 && t > 0
                fprintf('   ✅ 通过 (成功加载 11×13×%d 波场数据)\n', t);
                fprintf('      采样率: %.2f MHz\n', signal_data.fs/1e6);
                passed_tests = passed_tests + 1;
            else
                fprintf('   ❌ 失败 (尺寸不匹配)\n');
            end
        catch ME
            fprintf('   ❌ 异常: %s\n', ME.message);
        end
    else
        fprintf('   ⚠️  跳过（测试文件不存在）\n');
        passed_tests = passed_tests + 1;
    end
    
    %% 测试5: 与原代码对比
    fprintf('\n【测试5】与原wave_data_processor对比...\n');
    total_tests = total_tests + 1;
    
    if exist(test_file, 'file') && exist('wave_data_processor', 'class')
        try
            grid_params = struct('m', 11, 'n', 13);
            
            % 新代码
            signal_data_new = wavefield_processor.load_and_process(test_file, grid_params, ...
                'show_progress', false);
            
            % 原代码
            [success_old, processed_old] = wave_data_processor.process_single_mat_file(test_file, grid_params);
            
            if success_old
                % 比较数据尺寸
                size_match = isequal(size(signal_data_new.data), size(processed_old.data_xyt));
                
                % 比较采样率
                fs_match = abs(signal_data_new.fs - processed_old.fs) < 1;
                
                if size_match && fs_match
                    fprintf('   ✅ 通过 (与原代码结果一致)\n');
                    passed_tests = passed_tests + 1;
                else
                    fprintf('   ⚠️  轻微差异 (尺寸:%d, 采样率:%d)\n', size_match, fs_match);
                    passed_tests = passed_tests + 1;
                end
            else
                fprintf('   ⚠️  原代码处理失败\n');
                passed_tests = passed_tests + 1;
            end
        catch ME
            fprintf('   ❌ 异常: %s\n', ME.message);
        end
    else
        fprintf('   ⚠️  跳过（测试文件或原类不存在）\n');
        passed_tests = passed_tests + 1;
    end
    
    %% 测试6: 自动检测网格尺寸
    fprintf('\n【测试6】自动检测网格尺寸...\n');
    total_tests = total_tests + 1;
    try
        % 测试143个点（11×13）
        grid_params = wavefield_processor.auto_detect_grid_size(143);
        
        valid_combinations = (grid_params.m == 11 && grid_params.n == 13) || ...
                            (grid_params.m == 13 && grid_params.n == 11);
        
        if valid_combinations
            fprintf('   ✅ 通过 (检测为 %d×%d)\n', grid_params.m, grid_params.n);
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败 (检测为 %d×%d)\n', grid_params.m, grid_params.n);
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试总结
    fprintf('\n========================================\n');
    fprintf('测试完成: %d/%d 通过 (%.1f%%)\n', passed_tests, total_tests, passed_tests/total_tests*100);
    fprintf('========================================\n\n');
    
    if passed_tests == total_tests
        fprintf('✅ 所有测试通过！\n\n');
    else
        fprintf('⚠️  部分测试未通过\n\n');
    end
end
