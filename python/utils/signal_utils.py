import numpy as np
from scipy import signal
from scipy.fft import fft, fftfreq
from typing import Tuple, List, Dict, Any, Optional, Union

class SignalUtils:
    """
    信号处理工具类，提供各种信号处理功能
    """
    
    @staticmethod
    def butter_bandpass(lowcut: float, highcut: float, fs: float, order: int = 4) -> Tuple[np.ndarray, np.ndarray]:
        """
        设计巴特沃斯带通滤波器
        
        Args:
            lowcut: 低截止频率
            highcut: 高截止频率
            fs: 采样率
            order: 滤波器阶数
            
        Returns:
            Tuple[np.ndarray, np.ndarray]: 滤波器系数(b, a)
        """
        nyq = 0.5 * fs
        low = lowcut / nyq
        high = highcut / nyq
        
        # 确保归一化频率在0-1之间
        low = max(0.0, min(low, 0.99))
        high = max(0.01, min(high, 0.99))
        
        # 确保低截止频率小于高截止频率
        if low >= high:
            low = max(0.0, high - 0.01)
        
        b, a = signal.butter(order, [low, high], btype='band')
        return b, a
    
    @staticmethod
    def butter_lowpass(cutoff: float, fs: float, order: int = 4) -> Tuple[np.ndarray, np.ndarray]:
        """
        设计巴特沃斯低通滤波器
        
        Args:
            cutoff: 截止频率
            fs: 采样率
            order: 滤波器阶数
            
        Returns:
            Tuple[np.ndarray, np.ndarray]: 滤波器系数(b, a)
        """
        nyq = 0.5 * fs
        normal_cutoff = cutoff / nyq
        
        # 确保归一化频率在0-1之间
        normal_cutoff = max(0.01, min(normal_cutoff, 0.99))
        
        b, a = signal.butter(order, normal_cutoff, btype='low')
        return b, a
    
    @staticmethod
    def butter_highpass(cutoff: float, fs: float, order: int = 4) -> Tuple[np.ndarray, np.ndarray]:
        """
        设计巴特沃斯高通滤波器
        
        Args:
            cutoff: 截止频率
            fs: 采样率
            order: 滤波器阶数
            
        Returns:
            Tuple[np.ndarray, np.ndarray]: 滤波器系数(b, a)
        """
        nyq = 0.5 * fs
        normal_cutoff = cutoff / nyq
        
        # 确保归一化频率在0-1之间
        normal_cutoff = max(0.01, min(normal_cutoff, 0.99))
        
        b, a = signal.butter(order, normal_cutoff, btype='high')
        return b, a
    
    @staticmethod
    def apply_filter(x: np.ndarray, b: np.ndarray, a: np.ndarray) -> np.ndarray:
        """
        应用滤波器
        
        Args:
            x: 输入信号
            b: 滤波器分子系数
            a: 滤波器分母系数
            
        Returns:
            np.ndarray: 滤波后的信号
        """
        return signal.filtfilt(b, a, x)
    
    @staticmethod
    def apply_bandpass_filter(x: np.ndarray, lowcut: float, highcut: float, fs: float, order: int = 4) -> np.ndarray:
        """
        应用带通滤波器
        
        Args:
            x: 输入信号
            lowcut: 低截止频率
            highcut: 高截止频率
            fs: 采样率
            order: 滤波器阶数
            
        Returns:
            np.ndarray: 滤波后的信号
        """
        b, a = SignalUtils.butter_bandpass(lowcut, highcut, fs, order)
        return SignalUtils.apply_filter(x, b, a)
    
    @staticmethod
    def apply_lowpass_filter(x: np.ndarray, cutoff: float, fs: float, order: int = 4) -> np.ndarray:
        """
        应用低通滤波器
        
        Args:
            x: 输入信号
            cutoff: 截止频率
            fs: 采样率
            order: 滤波器阶数
            
        Returns:
            np.ndarray: 滤波后的信号
        """
        b, a = SignalUtils.butter_lowpass(cutoff, fs, order)
        return SignalUtils.apply_filter(x, b, a)
    
    @staticmethod
    def apply_highpass_filter(x: np.ndarray, cutoff: float, fs: float, order: int = 4) -> np.ndarray:
        """
        应用高通滤波器
        
        Args:
            x: 输入信号
            cutoff: 截止频率
            fs: 采样率
            order: 滤波器阶数
            
        Returns:
            np.ndarray: 滤波后的信号
        """
        b, a = SignalUtils.butter_highpass(cutoff, fs, order)
        return SignalUtils.apply_filter(x, b, a)
    
    @staticmethod
    def apply_median_filter(x: np.ndarray, kernel_size: int = 5) -> np.ndarray:
        """
        应用中值滤波器
        
        Args:
            x: 输入信号
            kernel_size: 核大小
            
        Returns:
            np.ndarray: 滤波后的信号
        """
        return signal.medfilt(x, kernel_size)
    
    @staticmethod
    def apply_savgol_filter(x: np.ndarray, window_length: int = 11, polyorder: int = 3) -> np.ndarray:
        """
        应用Savitzky-Golay滤波器
        
        Args:
            x: 输入信号
            window_length: 窗口长度
            polyorder: 多项式阶数
            
        Returns:
            np.ndarray: 滤波后的信号
        """
        return signal.savgol_filter(x, window_length, polyorder)
    
    @staticmethod
    def compute_fft(x: np.ndarray, fs: float) -> Tuple[np.ndarray, np.ndarray]:
        """
        计算FFT
        
        Args:
            x: 输入信号
            fs: 采样率
            
        Returns:
            Tuple[np.ndarray, np.ndarray]: 频率和幅值
        """
        n = len(x)
        # 计算FFT
        fft_result = fft(x)
        # 计算频率轴
        freqs = fftfreq(n, 1/fs)
        # 只取正频率部分
        pos_mask = freqs >= 0
        freqs = freqs[pos_mask]
        fft_result = 2.0/n * np.abs(fft_result[pos_mask])
        
        return freqs, fft_result
    
    @staticmethod
    def compute_stft(x: np.ndarray, fs: float, nperseg: int = 256, noverlap: int = None) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
        """
        计算短时傅里叶变换（STFT）
        
        Args:
            x: 输入信号
            fs: 采样率
            nperseg: 每个段的长度
            noverlap: 重叠的点数
            
        Returns:
            Tuple[np.ndarray, np.ndarray, np.ndarray]: 频率、时间和STFT结果
        """
        if noverlap is None:
            noverlap = nperseg // 2
        
        f, t, Zxx = signal.stft(x, fs=fs, nperseg=nperseg, noverlap=noverlap)
        return f, t, np.abs(Zxx)
    
    @staticmethod
    def normalize_signal(x: np.ndarray) -> np.ndarray:
        """
        归一化信号
        
        Args:
            x: 输入信号
            
        Returns:
            np.ndarray: 归一化后的信号
        """
        return x / np.max(np.abs(x))
    
    @staticmethod
    def compute_envelope(x: np.ndarray, method: str = 'hilbert') -> np.ndarray:
        """
        计算信号包络
        
        Args:
            x: 输入信号
            method: 方法，'hilbert'或'peak'
            
        Returns:
            np.ndarray: 信号包络
        """
        if method == 'hilbert':
            # 使用希尔伯特变换计算包络
            analytic_signal = signal.hilbert(x)
            envelope = np.abs(analytic_signal)
        elif method == 'peak':
            # 使用峰值检测计算包络
            peaks, _ = signal.find_peaks(np.abs(x))
            envelope = np.zeros_like(x)
            envelope[peaks] = np.abs(x[peaks])
            # 使用插值填充非峰值点
            for i in range(len(x)):
                if i not in peaks:
                    # 找到最近的左右峰值
                    left_peaks = peaks[peaks < i]
                    right_peaks = peaks[peaks > i]
                    
                    if len(left_peaks) > 0 and len(right_peaks) > 0:
                        left_peak = left_peaks[-1]
                        right_peak = right_peaks[0]
                        # 线性插值
                        envelope[i] = envelope[left_peak] + (envelope[right_peak] - envelope[left_peak]) * \
                                     (i - left_peak) / (right_peak - left_peak)
                    elif len(left_peaks) > 0:
                        envelope[i] = envelope[left_peaks[-1]]
                    elif len(right_peaks) > 0:
                        envelope[i] = envelope[right_peaks[0]]
        else:
            raise ValueError(f"不支持的方法: {method}，请使用'hilbert'或'peak'")
        
        return envelope
    
    @staticmethod
    def compute_snr(signal: np.ndarray, noise: np.ndarray) -> float:
        """
        计算信噪比
        
        Args:
            signal: 信号
            noise: 噪声
            
        Returns:
            float: 信噪比（dB）
        """
        signal_power = np.mean(signal ** 2)
        noise_power = np.mean(noise ** 2)
        snr = 10 * np.log10(signal_power / noise_power)
        return snr