function check_project()
    % 项目完整性检查工具
    % 检查所有关键文件、类和依赖关系
    
    fprintf('\n========================================\n');
    fprintf('Signal Processing Tool - 项目完整性检查\n');
    fprintf('========================================\n\n');
    
    % 切换到项目根目录
    project_root = fileparts(mfilename('fullpath'));
    cd(project_root);
    
    % 初始化路径
    try
        init_project();
    catch ME
        fprintf('❌ 路径初始化失败: %s\n', ME.message);
        return;
    end
    
    total_checks = 0;
    passed_checks = 0;
    
    %% 1. 检查核心类文件
    fprintf('【1】检查核心类文件...\n');
    core_classes = {
        'fft_analyzer', 'core/signal_analysis';
        'timefreq_analyzer', 'core/signal_analysis';
        'filter_engine', 'core/filtering';
        'SignalData', 'io/data_loader';
        'txt_loader', 'io/data_loader';
        'wavefield_processor', 'core/imaging';
        'signal_plotter', 'ui/visualizers'
    };
    
    for i = 1:size(core_classes, 1)
        total_checks = total_checks + 1;
        class_name = core_classes{i, 1};
        location = core_classes{i, 2};
        
        if exist(class_name, 'class')
            fprintf('   ✅ %s\n', class_name);
            passed_checks = passed_checks + 1;
        else
            fprintf('   ❌ %s (期望位置: %s)\n', class_name, location);
        end
    end
    
    %% 2. 检查主界面文件
    fprintf('\n【2】检查主界面文件...\n');
    main_files = {
        'ui/main/ReadA.m', 'ReadA';
        'ui/main/ReadB.m', 'ReadB';
        'ui/main/ReadC.m', 'ReadC';
        'main_launcher.m', 'main_launcher'
    };
    
    for i = 1:size(main_files, 1)
        total_checks = total_checks + 1;
        file_path = fullfile(project_root, main_files{i, 1});
        func_name = main_files{i, 2};
        
        if exist(file_path, 'file')
            fprintf('   ✅ %s\n', func_name);
            passed_checks = passed_checks + 1;
        else
            fprintf('   ❌ %s (期望路径: %s)\n', func_name, main_files{i, 1});
        end
    end
    
    %% 3. 检查关键功能
    fprintf('\n【3】检查关键功能可用性...\n');
    
    % 测试FFT分析器
    total_checks = total_checks + 1;
    try
        test_signal = randn(1000, 1);
        [freq, mag] = fft_analyzer.compute(test_signal, 1e6);
        if ~isempty(freq) && ~isempty(mag)
            fprintf('   ✅ FFT分析功能\n');
            passed_checks = passed_checks + 1;
        else
            fprintf('   ❌ FFT分析功能\n');
        end
    catch ME
        fprintf('   ❌ FFT分析功能: %s\n', ME.message);
    end
    
    % 测试滤波器
    total_checks = total_checks + 1;
    try
        test_signal = randn(1000, 1);
        % 修复: 使用更合理的频率范围，远离奈奎斯特频率
        params = struct('fs', 1e6, 'low_freq', 100e3, 'high_freq', 400e3, 'order', 4);
        filtered = filter_engine.apply(test_signal, 'bandpass', params);
        if length(filtered) == length(test_signal)
            fprintf('   ✅ 滤波器功能\n');
            passed_checks = passed_checks + 1;
        else
            fprintf('   ❌ 滤波器功能\n');
        end
    catch ME
        fprintf('   ❌ 滤波器功能: %s\n', ME.message);
    end
    
    % 测试SignalData
    total_checks = total_checks + 1;
    try
        test_signal = randn(1000, 1);
        test_time = (0:999)' / 1e6;
        sig_data = SignalData(test_signal, test_time, 1e6, 'single_point');
        if ~isempty(sig_data.get_point(1, 1))
            fprintf('   ✅ SignalData类\n');
            passed_checks = passed_checks + 1;
        else
            fprintf('   ❌ SignalData类\n');
        end
    catch ME
        fprintf('   ❌ SignalData类: %s\n', ME.message);
    end
    
    %% 4. 检查文档文件
    fprintf('\n【4】检查文档文件...\n');
    doc_files = {
        'README.md';
        'docs/progress_tracker.md';
        'docs/architecture.md'
    };
    
    for i = 1:length(doc_files)
        total_checks = total_checks + 1;
        doc_path = fullfile(project_root, doc_files{i});
        
        if exist(doc_path, 'file')
            fprintf('   ✅ %s\n', doc_files{i});
            passed_checks = passed_checks + 1;
        else
            fprintf('   ⚠️  %s (可选)\n', doc_files{i});
            passed_checks = passed_checks + 1;  % 文档文件标记为可选
        end
    end
    
    %% 5. 检查启动脚本
    fprintf('\n【5】检查启动脚本...\n');
    startup_files = {
        'start.m';
        'init_project.m'
    };
    
    for i = 1:length(startup_files)
        total_checks = total_checks + 1;
        file_path = fullfile(project_root, startup_files{i});
        
        if exist(file_path, 'file')
            fprintf('   ✅ %s\n', startup_files{i});
            passed_checks = passed_checks + 1;
        else
            fprintf('   ❌ %s\n', startup_files{i});
        end
    end
    
    %% 总结报告
    fprintf('\n========================================\n');
    fprintf('检查完成: %d/%d 通过 (%.1f%%)\n', ...
            passed_checks, total_checks, passed_checks/total_checks*100);
    fprintf('========================================\n\n');
    
    if passed_checks == total_checks
        fprintf('✅ 项目完整性检查通过！\n');
        fprintf('   所有关键组件都已就位并可正常工作。\n\n');
        fprintf('快速启动:\n');
        fprintf('   方法1: 运行 start\n');
        fprintf('   方法2: 运行 main_launcher\n');
        fprintf('   方法3: 直接运行 ReadA, ReadB 或 ReadC\n\n');
    else
        failed_count = total_checks - passed_checks;
        fprintf('⚠️  检查发现 %d 个问题\n', failed_count);
        fprintf('   请检查上述失败项并修复。\n\n');
    end
    
    % 显示版本信息
    fprintf('版本信息:\n');
    fprintf('   项目: Signal Processing Tool\n');
    fprintf('   版本: v2.0 (重构版)\n');
    fprintf('   架构: 模块化 + 插件式\n');
    fprintf('   模块: A (单点分析), B (B扫分析), C (波场分析)\n\n');
end
