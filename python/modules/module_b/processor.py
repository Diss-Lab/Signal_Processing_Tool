import numpy as np
import pandas as pd
from scipy import signal
from typing import Tuple, List, Dict, Any, Optional, Union
import os
import sys
import re

# 添加项目根目录到系统路径
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

from utils.signal_utils import SignalUtils
from utils.file_utils import FileUtils

class BScanProcessor:
    """
    B扫描信号处理器，用于处理多个信号文件并生成B扫描图像
    """
    
    def __init__(self):
        """
        初始化B扫描信号处理器
        """
        self.signals = []  # 原始信号数据列表
        self.processed_signals = []  # 处理后的信号数据列表
        self.sampling_rate = None  # 采样率
        self.time_axis = None  # 时间轴
        self.positions = []  # 位置信息
        self.file_paths = []  # 文件路径列表
        self.bscan_data = None  # B扫描数据
        self.signal_utils = SignalUtils()  # 信号处理工具
        self.file_utils = FileUtils()  # 文件处理工具
        
    def read_txt_signal(self, file_path: str) -> Tuple[np.ndarray, float]:
        """
        读取TXT信号文件，返回信号数据和采样率
        
        Args:
            file_path: 文件路径
            
        Returns:
            Tuple[np.ndarray, float]: 信号数据和采样率
        """
        try:
            time_data, signal_data, sampling_rate = FileUtils.read_txt_file(file_path)
            return signal_data, sampling_rate
        except Exception as e:
            print(f"读取TXT信号文件失败: {str(e)}")
            return None, None
    
    def load_from_folder(self, folder_path: str, pattern: str = None) -> bool:
        """
        从文件夹加载多个信号文件
        
        Args:
            folder_path: 文件夹路径
            pattern: 文件名匹配模式，例如 "signal_*.txt"
            
        Returns:
            bool: 是否成功加载
        """
        try:
            # 获取文件夹中的所有TXT文件
            if pattern:
                txt_files = FileUtils.get_files_with_pattern(folder_path, pattern)
            else:
                txt_files = FileUtils.get_files_with_extension(folder_path, ".txt")
            
            if not txt_files:
                print(f"在文件夹 {folder_path} 中未找到匹配的TXT文件")
                return False
            
            # 清空之前的数据
            self.signals = []
            self.processed_signals = []
            self.positions = []
            self.file_paths = []
            
            # 提取位置信息的正则表达式
            position_pattern = r'(\d+(\.\d+)?)'  # 匹配数字（可能包含小数点）
            
            # 加载每个文件
            for file_path in sorted(txt_files):
                signal_data, sampling_rate = self.read_txt_signal(file_path)
                
                if signal_data is not None and sampling_rate is not None:
                    # 保存信号数据和采样率
                    self.signals.append(signal_data)
                    self.processed_signals.append(signal_data.copy())  # 初始化处理后的数据为原始数据
                    self.file_paths.append(file_path)
                    
                    # 设置采样率（假设所有文件的采样率相同）
                    if self.sampling_rate is None:
                        self.sampling_rate = sampling_rate
                        # 创建时间轴
                        self.time_axis = np.arange(len(signal_data)) / self.sampling_rate
                    
                    # 尝试从文件名中提取位置信息
                    file_name = os.path.basename(file_path)
                    position_match = re.search(position_pattern, file_name)
                    if position_match:
                        position = float(position_match.group(1))
                    else:
                        # 如果无法从文件名提取位置，则使用索引作为位置
                        position = len(self.positions)
                    
                    self.positions.append(position)
            
            if not self.signals:
                print(f"无法从文件夹 {folder_path} 中加载有效的信号数据")
                return False
            
            # 确保位置是按顺序排列的
            sorted_indices = np.argsort(self.positions)
            self.positions = [self.positions[i] for i in sorted_indices]
            self.signals = [self.signals[i] for i in sorted_indices]
            self.processed_signals = [self.processed_signals[i] for i in sorted_indices]
            self.file_paths = [self.file_paths[i] for i in sorted_indices]
            
            print(f"成功从文件夹 {folder_path} 加载了 {len(self.signals)} 个信号文件")
            return True
        except Exception as e:
            print(f"从文件夹 {folder_path} 加载文件时出错: {str(e)}")
            return False
    
    def reset_processing(self) -> None:
        """
        重置处理，将处理后的数据恢复为原始数据
        """
        if self.signals:
            self.processed_signals = [signal.copy() for signal in self.signals]
            self.bscan_data = None
    
    def apply_bandpass_filter(self, lowcut: float, highcut: float, order: int = 4) -> None:
        """
        对所有信号应用带通滤波器
        
        Args:
            lowcut: 低截止频率
            highcut: 高截止频率
            order: 滤波器阶数
        """
        if self.processed_signals and self.sampling_rate is not None:
            for i in range(len(self.processed_signals)):
                self.processed_signals[i] = SignalUtils.apply_bandpass_filter(
                    self.processed_signals[i], lowcut, highcut, self.sampling_rate, order
                )
            # 清除之前的B扫描数据，因为信号已经改变
            self.bscan_data = None
    
    def apply_lowpass_filter(self, cutoff: float, order: int = 4) -> None:
        """
        对所有信号应用低通滤波器
        
        Args:
            cutoff: 截止频率
            order: 滤波器阶数
        """
        if self.processed_signals and self.sampling_rate is not None:
            for i in range(len(self.processed_signals)):
                self.processed_signals[i] = SignalUtils.apply_lowpass_filter(
                    self.processed_signals[i], cutoff, self.sampling_rate, order
                )
            # 清除之前的B扫描数据，因为信号已经改变
            self.bscan_data = None
    
    def apply_highpass_filter(self, cutoff: float, order: int = 4) -> None:
        """
        对所有信号应用高通滤波器
        
        Args:
            cutoff: 截止频率
            order: 滤波器阶数
        """
        if self.processed_signals and self.sampling_rate is not None:
            for i in range(len(self.processed_signals)):
                self.processed_signals[i] = SignalUtils.apply_highpass_filter(
                    self.processed_signals[i], cutoff, self.sampling_rate, order
                )
            # 清除之前的B扫描数据，因为信号已经改变
            self.bscan_data = None
    
    def apply_median_filter(self, kernel_size: int = 5) -> None:
        """
        对所有信号应用中值滤波器
        
        Args:
            kernel_size: 核大小
        """
        if self.processed_signals:
            for i in range(len(self.processed_signals)):
                self.processed_signals[i] = SignalUtils.apply_median_filter(
                    self.processed_signals[i], kernel_size
                )
            # 清除之前的B扫描数据，因为信号已经改变
            self.bscan_data = None
    
    def apply_savgol_filter(self, window_length: int = 11, polyorder: int = 3) -> None:
        """
        对所有信号应用Savitzky-Golay滤波器
        
        Args:
            window_length: 窗口长度
            polyorder: 多项式阶数
        """
        if self.processed_signals:
            for i in range(len(self.processed_signals)):
                self.processed_signals[i] = SignalUtils.apply_savgol_filter(
                    self.processed_signals[i], window_length, polyorder
                )
            # 清除之前的B扫描数据，因为信号已经改变
            self.bscan_data = None
    
    def normalize_signals(self) -> None:
        """
        归一化所有信号
        """
        if self.processed_signals:
            for i in range(len(self.processed_signals)):
                self.processed_signals[i] = SignalUtils.normalize_signal(self.processed_signals[i])
            # 清除之前的B扫描数据，因为信号已经改变
            self.bscan_data = None
    
    def create_bscan(self, normalize: bool = True, envelope: bool = False, method: str = 'hilbert') -> np.ndarray:
        """
        创建B扫描图像数据
        
        Args:
            normalize: 是否归一化每个信号
            envelope: 是否计算包络
            method: 包络计算方法，'hilbert'或'peak'
            
        Returns:
            np.ndarray: B扫描图像数据，形状为 (位置数, 时间点数)
        """
        if not self.processed_signals:
            print("没有可用的信号数据来创建B扫描图像")
            return None
        
        # 获取信号长度（假设所有信号长度相同）
        signal_length = len(self.processed_signals[0])
        
        # 创建B扫描数据矩阵
        bscan_data = np.zeros((len(self.processed_signals), signal_length))
        
        for i, signal_data in enumerate(self.processed_signals):
            # 如果信号长度不一致，则调整为最短长度
            if len(signal_data) != signal_length:
                signal_length = min(signal_length, len(signal_data))
                bscan_data = bscan_data[:, :signal_length]
                signal_data = signal_data[:signal_length]
            
            # 处理信号
            processed_signal = signal_data.copy()
            
            # 计算包络（如果需要）
            if envelope:
                processed_signal = SignalUtils.compute_envelope(processed_signal, method)
            
            # 归一化（如果需要）
            if normalize:
                processed_signal = SignalUtils.normalize_signal(processed_signal)
            
            # 添加到B扫描数据矩阵
            bscan_data[i, :] = processed_signal
        
        self.bscan_data = bscan_data
        return bscan_data
    
    def get_signal_at_position(self, position_index: int) -> Tuple[np.ndarray, np.ndarray]:
        """
        获取指定位置的信号
        
        Args:
            position_index: 位置索引
            
        Returns:
            Tuple[np.ndarray, np.ndarray]: 时间轴和信号数据
        """
        if not self.processed_signals or position_index < 0 or position_index >= len(self.processed_signals):
            print(f"位置索引 {position_index} 超出范围")
            return None, None
        
        return self.time_axis, self.processed_signals[position_index]
    
    def get_signal_at_time(self, time_index: int) -> Tuple[np.ndarray, np.ndarray]:
        """
        获取指定时间点的所有位置的信号
        
        Args:
            time_index: 时间索引
            
        Returns:
            Tuple[np.ndarray, np.ndarray]: 位置轴和信号数据
        """
        if not self.processed_signals or self.bscan_data is None:
            print("没有可用的B扫描数据")
            return None, None
        
        if time_index < 0 or time_index >= self.bscan_data.shape[1]:
            print(f"时间索引 {time_index} 超出范围")
            return None, None
        
        return np.array(self.positions), self.bscan_data[:, time_index]
    
    def save_to_mat(self, output_path: str) -> bool:
        """
        保存B扫描数据到MAT文件
        
        Args:
            output_path: 输出文件路径
            
        Returns:
            bool: 是否成功保存
        """
        if not self.processed_signals or self.bscan_data is None:
            print("没有可用的B扫描数据可保存")
            return False
        
        try:
            # 准备要保存的数据
            data_dict = {
                'bscan_data': self.bscan_data,
                'time': self.time_axis,
                'positions': np.array(self.positions),
                'fs': self.sampling_rate,
                'signals': np.array(self.processed_signals),
                'original_signals': np.array(self.signals)
            }
            
            # 使用FileUtils保存到MAT文件
            FileUtils.save_to_mat(output_path, **data_dict)
            print(f"B扫描数据已成功保存到 {output_path}")
            return True
        except Exception as e:
            print(f"保存到MAT文件 {output_path} 时出错: {str(e)}")
            return False
    
    def load_from_mat(self, file_path: str) -> bool:
        """
        从MAT文件加载B扫描数据
        
        Args:
            file_path: 文件路径
            
        Returns:
            bool: 是否成功加载
        """
        try:
            # 使用FileUtils加载MAT文件
            data_dict = FileUtils.read_mat_file(file_path)
            
            if data_dict is not None and 'bscan_data' in data_dict:
                self.bscan_data = data_dict['bscan_data']
                
                # 加载其他数据（如果存在）
                if 'time' in data_dict:
                    self.time_axis = data_dict['time']
                
                if 'positions' in data_dict:
                    self.positions = data_dict['positions'].tolist()
                
                if 'fs' in data_dict:
                    self.sampling_rate = data_dict['fs']
                
                if 'signals' in data_dict:
                    self.processed_signals = [signal for signal in data_dict['signals']]
                
                if 'original_signals' in data_dict:
                    self.signals = [signal for signal in data_dict['original_signals']]
                else:
                    # 如果没有原始信号，则使用处理后的信号作为原始信号
                    self.signals = [signal.copy() for signal in self.processed_signals]
                
                print(f"B扫描数据已成功从 {file_path} 加载")
                return True
            else:
                print(f"MAT文件 {file_path} 中缺少必要的数据字段")
                return False
        except Exception as e:
            print(f"加载MAT文件 {file_path} 时出错: {str(e)}")
            return False