#!/usr/bin/env python3
"""
Generate SkillBridge handshake logo icons in various sizes.
Uses the primary brand color (#2D9B6F) with a white handshake icon.
"""

from PIL import Image, ImageDraw
from typing import Tuple

# Brand colors from app_sidebar.dart
PRIMARY_COLOR: Tuple[int, int, int] = (45, 155, 111)  # #2D9B6F
WHITE: Tuple[int, int, int] = (255, 255, 255)

def draw_handshake(
    draw: ImageDraw.ImageDraw,
    x: float,
    y: float,
    size: float,
    color: Tuple[int, int, int],
) -> None:
    """Draw a handshake icon at the given position."""
    # Handshake is made of two arms meeting in the middle
    line_width = max(2, int(size * 0.08))
    
    # Left arm (from upper-left to center)
    x1: float = x - size * 0.25
    y1: float = y - size * 0.15
    x2: float = x
    y2: float = y
    draw.line([(x1, y1), (x2, y2)], fill=color, width=line_width)
    
    # Right arm (from upper-right to center)
    x3: float = x + size * 0.25
    y3: float = y - size * 0.15
    draw.line([(x3, y3), (x2, y2)], fill=color, width=line_width)
    
    # Left hand circle
    hand_radius = int(size * 0.12)
    draw.ellipse(
        [(x1 - hand_radius, y1 - hand_radius), (x1 + hand_radius, y1 + hand_radius)],
        fill=color
    )
    
    # Right hand circle
    draw.ellipse(
        [(x3 - hand_radius, y3 - hand_radius), (x3 + hand_radius, y3 + hand_radius)],
        fill=color
    )
    
    # Center circle where hands meet
    center_radius = int(size * 0.1)
    draw.ellipse(
        [(x - center_radius, y - center_radius), (x + center_radius, y + center_radius)],
        fill=color
    )

def create_logo(
    size: int,
    output_path: str,
    with_rounded_corners: bool = False,
    corner_radius_ratio: float = 0.25,
) -> None:
    """Create a logo of the given size."""
    # Create image with background color
    img = Image.new('RGB', (size, size), PRIMARY_COLOR)
    draw = ImageDraw.Draw(img, 'RGBA')
    
    # Draw rounded corners if needed
    if with_rounded_corners:
        corner_radius = int(size * corner_radius_ratio)
        # Create a mask for rounded corners
        mask = Image.new('L', (size, size), 0)
        mask_draw = ImageDraw.Draw(mask)
        mask_draw.rounded_rectangle(
            [(0, 0), (size, size)],
            radius=corner_radius,
            fill=255
        )
        # Apply rounded corners by creating new image
        output = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        img_rgba = img.convert('RGBA')
        output.paste(img_rgba, mask=mask)
        img = output.convert('RGB')
    
    # Draw the handshake icon in the center
    draw = ImageDraw.Draw(img)
    center_x: int = size // 2
    center_y: int = size // 2
    icon_size: int = int(size * 0.55)
    
    draw_handshake(draw, center_x, center_y, icon_size, WHITE)
    
    # Save the image
    img.save(output_path, 'PNG')
    print(f"Created: {output_path}")

# Generate all required logos
base_path = 'web/icons/'

# Standard icons
create_logo(192, f'{base_path}Icon-192.png', with_rounded_corners=True, corner_radius_ratio=0.2)
create_logo(512, f'{base_path}Icon-512.png', with_rounded_corners=True, corner_radius_ratio=0.15)

# Maskable icons (for Android adaptive icons) - no rounded corners, full bleed
create_logo(192, f'{base_path}Icon-maskable-192.png', with_rounded_corners=False)
create_logo(512, f'{base_path}Icon-maskable-512.png', with_rounded_corners=False)

# Favicon (small size, more rounded)
create_logo(32, 'web/favicon.png', with_rounded_corners=True, corner_radius_ratio=0.3)

print("\nAll logos generated successfully!")
print("✓ web/icons/Icon-192.png")
print("✓ web/icons/Icon-512.png")
print("✓ web/icons/Icon-maskable-192.png")
print("✓ web/icons/Icon-maskable-512.png")
print("✓ web/favicon.png")
