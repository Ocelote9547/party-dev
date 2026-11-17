from PIL import Image, ImageDraw, ImageFont
import os

def main():
    W, H = 1024, 1024
    cx, cy = W // 2, H // 2
    radius = 400

    bg = (2, 11, 18)
    teal = (37, 230, 208)
    dark = (2, 11, 18)

    img = Image.new('RGB', (W, H), bg)
    draw = ImageDraw.Draw(img)

    draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=teal)

    font_size = 500
    try:
        font = ImageFont.truetype("arial.ttf", font_size)
    except:
        try:
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
        except:
            font = ImageFont.load_default()

    text = 'P'
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = cx - tw // 2 - bbox[0]
    ty = cy - th // 2 - bbox[1]

    draw.text((tx, ty), text, fill=dark, font=font)

    out_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'icon')
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, 'icon.png')

    img.save(out_path, 'PNG')
    print(f'Icon created at {out_path}')

if __name__ == '__main__':
    main()
