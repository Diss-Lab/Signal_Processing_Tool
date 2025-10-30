function run_tests()
    % 快速测试运行脚本
    % 自动初始化路径并运行所有测试
    
    fprintf('\n========================================\n');
    fprintf('信号处理工具 - 自动化测试\n');
    fprintf('========================================\n\n');
    
    % 初始化项目路径
    fprintf('步骤1: 初始化项目路径...\n');
    init_project();
    
    fprintf('\n步骤2: 运行测试脚本...\n');
    fprintf('========================================\n\n');
    
    % 切换到tests目录
    project_root = fileparts(mfilename('fullpath'));
    tests_dir = fullfile(project_root, 'tests');
    
    if exist(tests_dir, 'dir')
        cd(tests_dir);
        
        % 运行FFT分析器测试
        test_signal_plotter();
        
        % 返回项目根目录
        cd(project_root);
    else
        error('测试目录不存在: %s', tests_dir);
    end
    
    fprintf('\n所有测试执行完毕！\n');
end
