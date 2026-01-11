#!/usr/bin/env python3
"""
PWA 图标生成脚本

使用 Pillow 生成 AI漫导 的 PWA 图标文件
生成的文件：
- web/favicon.png (64x64)
- web/icons/icon-192.png (192x192)
- web/icons/icon-512.png (512x512)
"""

import os
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("错误: 需要安装 Pillow 库")
    print("请运行: pip install Pillow")
    sys.exit(1)

# 设置输出编码（Windows兼容）
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

# 项目根目录
PROJECT_ROOT = Path(__file__).parent.parent

# 主题色 #8B5CF6 (紫色)
PRIMARY_COLOR = (139, 92, 246)  # #8B5CF6
WHITE = (255, 255, 255)
DARK_PURPLE = (99, 59, 215)  # 深紫色用于阴影

# 输出路径
OUTPUT_PATHS = {
    'favicon': PROJECT_ROOT / 'web' / 'favicon.png',
    'icon192': PROJECT_ROOT / 'web' / 'icons' / 'icon-192.png',
    'icon512': PROJECT_ROOT / 'web' / 'icons' / 'icon-512.png',
}


def create_icon(size: int, show_text: bool = True) -> Image.Image:
    """
    创建图标图像
    
    Args:
        size: 图标尺寸
        show_text: 是否显示文字（小尺寸不显示）
    """
    # 创建图像（RGBA模式支持透明背景）
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 计算圆角矩形的参数
    padding = size // 8  # 边距
    corner_radius = size // 6  # 圆角半径
    
    # 绘制带圆角的背景
    box = [
        padding,
        padding,
        size - padding,
        size - padding
    ]
    
    # 绘制背景矩形（带圆角效果，使用简单的矩形近似）
    draw.rounded_rectangle(box, radius=corner_radius, fill=PRIMARY_COLOR)
    
    # 添加渐变效果（通过绘制多个矩形）
    if size >= 192:
        for i in range(5):
            alpha = 30 - i * 5
            overlay = Image.new('RGBA', (size, size), (0, 0, 0, 0))
            overlay_draw = ImageDraw.Draw(overlay)
            overlay_box = [
                padding + i,
                padding + i,
                size - padding - i,
                size - padding - i
            ]
            overlay_draw.rounded_rectangle(
                overlay_box,
                radius=corner_radius - i,
                fill=(*PRIMARY_COLOR, alpha)
            )
            img = Image.alpha_composite(img, overlay)
    
    # 绘制电影胶片图标（简化的设计）
    if size >= 192:
        # 绘制简化的胶片图标
        film_width = size // 3
        film_height = size // 2
        film_x = (size - film_width) // 2
        film_y = (size - film_height) // 2 - size // 16
        
        # 胶片主体
        film_box = [
            film_x,
            film_y,
            film_x + film_width,
            film_y + film_height
        ]
        draw.rounded_rectangle(film_box, radius=size // 30, fill=WHITE)
        
        # 胶片孔（左右各两个）
        hole_size = size // 12
        hole_y1 = film_y + film_height // 3
        hole_y2 = film_y + film_height * 2 // 3
        
        # 左侧孔
        draw.ellipse([film_x - hole_size, hole_y1 - hole_size // 2,
                     film_x, hole_y1 + hole_size // 2], fill=WHITE)
        draw.ellipse([film_x - hole_size, hole_y2 - hole_size // 2,
                     film_x, hole_y2 + hole_size // 2], fill=WHITE)
        
        # 右侧孔
        draw.ellipse([film_x + film_width, hole_y1 - hole_size // 2,
                     film_x + film_width + hole_size, hole_y1 + hole_size // 2], fill=WHITE)
        draw.ellipse([film_x + film_width, hole_y2 - hole_size // 2,
                     film_x + film_width + hole_size, hole_y2 + hole_size // 2], fill=WHITE)
        
        # 胶片内容（两个矩形）
        content_width = film_width // 3
        content_height = film_height * 2 // 3
        content_x1 = film_x + film_width // 6
        content_x2 = film_x + film_width * 2 // 3
        content_y = film_y + film_height // 6
        
        draw.rectangle([content_x1, content_y,
                       content_x1 + content_width, content_y + content_height],
                      fill=DARK_PURPLE)
        draw.rectangle([content_x2, content_y,
                       content_x2 + content_width, content_y + content_height],
                      fill=DARK_PURPLE)
    
    # 添加文字（仅在大尺寸图标上）
    if show_text and size >= 192:
        try:
            # 尝试使用系统字体
            font_size = size // 8
            try:
                # Windows
                font = ImageFont.truetype("arial.ttf", font_size)
            except:
                try:
                    # macOS/Linux
                    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
                except:
                    # 使用默认字体
                    font = ImageFont.load_default()
            
            text = "AI"
            # 获取文字尺寸
            bbox = draw.textbbox((0, 0), text, font=font)
            text_width = bbox[2] - bbox[0]
            text_height = bbox[3] - bbox[1]
            
            # 文字位置（图标底部）
            text_x = (size - text_width) // 2
            text_y = size - size // 4 - text_height // 2
            
            # 绘制文字阴影
            draw.text((text_x + 2, text_y + 2), text, font=font, fill=DARK_PURPLE)
            # 绘制文字
            draw.text((text_x, text_y), text, font=font, fill=WHITE)
        except Exception as e:
            # 如果字体加载失败，跳过文字
            print(f"警告: 无法加载字体，跳过文字 ({e})")
    
    return img


def generate_icons():
    """生成所有图标文件"""
    print("开始生成 PWA 图标...")
    print(f"项目根目录: {PROJECT_ROOT}")
    
    # 确保输出目录存在
    (PROJECT_ROOT / 'web' / 'icons').mkdir(parents=True, exist_ok=True)
    
    # 生成各个尺寸的图标
    icons = [
        (64, OUTPUT_PATHS['favicon'], False),  # favicon 不显示文字
        (192, OUTPUT_PATHS['icon192'], True),
        (512, OUTPUT_PATHS['icon512'], True),
    ]
    
    for size, output_path, show_text in icons:
        print(f"\n生成 {size}x{size} 图标: {output_path.relative_to(PROJECT_ROOT)}")
        
        # 创建图标
        icon = create_icon(size, show_text)
        
        # 保存图标
        icon.save(output_path, 'PNG', optimize=True)
        
        # 获取文件大小
        file_size = output_path.stat().st_size
        file_size_kb = file_size / 1024
        print(f"[OK] 已生成 ({file_size_kb:.2f} KB)")
    
    print("\n所有图标生成完成！")
    print("\n生成的文件：")
    for name, path in OUTPUT_PATHS.items():
        if path.exists():
            size_kb = path.stat().st_size / 1024
            print(f"  [OK] {path.relative_to(PROJECT_ROOT)} ({size_kb:.2f} KB)")
    
    print("\n提示：这些是占位图标。建议后续使用专业设计工具创建更精美的图标。")


if __name__ == '__main__':
    try:
        generate_icons()
    except Exception as e:
        print(f"[ERROR] 错误: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
