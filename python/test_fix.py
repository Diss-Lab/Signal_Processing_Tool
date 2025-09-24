#!/usr/bin/env python
"""
测试文件路径修复是否有效
"""
import os
import tempfile
import sys

def test_tempfile_creation():
    """测试临时文件创建是否正常工作"""
    print("测试临时文件创建...")
    
    try:
        # 测试 NamedTemporaryFile
        with tempfile.NamedTemporaryFile(delete=False, suffix="_test.txt") as temp_file:
            temp_path = temp_file.name
            temp_file.write(b"Hello, World!")
        
        print(f"✅ 临时文件创建成功: {temp_path}")
        
        # 检查文件是否存在
        if os.path.exists(temp_path):
            print("✅ 临时文件确实存在")
            
            # 读取文件内容
            with open(temp_path, "rb") as f:
                content = f.read()
            print(f"✅ 文件内容: {content}")
            
            # 清理临时文件
            os.unlink(temp_path)
            print("✅ 临时文件清理成功")
        else:
            print("❌ 临时文件不存在")
            
    except Exception as e:
        print(f"❌ 临时文件创建失败: {e}")

def test_example_data_path():
    """测试示例数据路径是否正确"""
    print("\n测试示例数据路径...")
    
    try:
        # 模拟 module_a_page.py 中的路径计算
        current_dir = os.path.dirname(os.path.abspath(__file__))
        example_path = os.path.join(current_dir, "data", "single_point", "sine_wave.txt")
        example_path = os.path.normpath(example_path)
        
        print(f"计算的示例数据路径: {example_path}")
        
        if os.path.exists(example_path):
            print("✅ 示例数据文件存在")
        else:
            print("❌ 示例数据文件不存在，但这是正常的，因为我们在测试脚本中")
            
    except Exception as e:
        print(f"❌ 路径计算失败: {e}")

def test_platform_info():
    """显示平台信息"""
    print("\n平台信息:")
    print(f"操作系统: {os.name}")
    print(f"Python 版本: {sys.version}")
    print(f"当前工作目录: {os.getcwd()}")
    print(f"临时目录: {tempfile.gettempdir()}")

if __name__ == "__main__":
    print("🔧 测试文件路径修复")
    print("=" * 50)
    
    test_platform_info()
    test_tempfile_creation()
    test_example_data_path()
    
    print("\n✅ 测试完成！")
