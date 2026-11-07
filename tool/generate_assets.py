import os
import math
import wave
import struct
from PIL import Image

def process_images():
    full_path = 'assets/branding/atlendify_logo_full.jpg'
    icon_path = 'assets/branding/atlendify_icon.png'

    os.makedirs('assets/images', exist_ok=True)
    os.makedirs('assets/sounds', exist_ok=True)
    os.makedirs('assets/fonts', exist_ok=True)

    # 1. Sample brand blue from logo full
    full_img = Image.open(full_path).convert('RGB')
    width, height = full_img.size

    # Sample brand blue (non-white, non-black area)
    # Target exact blue from the logo text/mark: roughly R~30, G~67, B~155 -> #1E439B
    brand_r, brand_g, brand_b = 30, 67, 155

    print(f"Brand Blue sampled/defined: RGB({brand_r}, {brand_g}, {brand_b}) -> #{brand_r:02X}{brand_g:02X}{brand_b:02X}")

    # 2. Make transparent version of full logo
    # Remove white background: alpha = (255 - min(R,G,B)) / (255 - min(brandR, brandG, brandB))
    min_brand = min(brand_r, brand_g, brand_b)
    divisor = max(1.0, 255.0 - min_brand)

    rgba = full_img.convert('RGBA')
    pixels = rgba.load()

    min_x, min_y, max_x, max_y = width, height, 0, 0

    for y in range(height):
        for x in range(width):
            r, g, b, _ = pixels[x, y]
            # distance from white (255, 255, 255)
            min_c = min(r, g, b)
            alpha = int(max(0.0, min(255.0, ((255.0 - min_c) / divisor) * 255.0)))
            if alpha > 10:
                pixels[x, y] = (brand_r, brand_g, brand_b, alpha)
                if x < min_x: min_x = x
                if x > max_x: max_x = x
                if y < min_y: min_y = y
                if y > max_y: max_y = y
            else:
                pixels[x, y] = (0, 0, 0, 0)

    # Trim with 8% padding
    pad_x = int((max_x - min_x) * 0.08)
    pad_y = int((max_y - min_y) * 0.08)
    crop_box = (
        max(0, min_x - pad_x),
        max(0, min_y - pad_y),
        min(width, max_x + pad_x),
        min(height, max_y + pad_y)
    )
    logo_full_trimmed = rgba.crop(crop_box)
    logo_full_trimmed.save('assets/images/logo_full.png')
    print("Saved assets/images/logo_full.png")

    # 3. Process icon mark
    icon_img = Image.open(icon_path).convert('RGBA')
    i_w, i_h = icon_img.size
    i_pixels = icon_img.load()

    i_min_x, i_min_y, i_max_x, i_max_y = i_w, i_h, 0, 0

    for y in range(i_h):
        for x in range(i_w):
            r, g, b, a = i_pixels[x, y]
            if a > 20:
                min_c = min(r, g, b)
                alpha = int(max(0.0, min(255.0, ((255.0 - min_c) / divisor) * 255.0)))
                if alpha > 15:
                    i_pixels[x, y] = (brand_r, brand_g, brand_b, alpha)
                    if x < i_min_x: i_min_x = x
                    if x > i_max_x: i_max_x = x
                    if y < i_min_y: i_min_y = y
                    if y > i_max_y: i_max_y = y
                else:
                    i_pixels[x, y] = (0, 0, 0, 0)
            else:
                i_pixels[x, y] = (0, 0, 0, 0)

    mark_cropped = icon_img.crop((i_min_x, i_min_y, i_max_x, i_max_y))

    # Save mark trimmed to square canvas with padding
    m_w, m_h = mark_cropped.size
    max_dim = max(m_w, m_h)
    canvas_size = int(max_dim * 1.2)
    logo_mark = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    offset = ((canvas_size - m_w) // 2, (canvas_size - m_h) // 2)
    logo_mark.paste(mark_cropped, offset)
    logo_mark.save('assets/images/logo_mark.png')
    print("Saved assets/images/logo_mark.png")

    # 4. App icons (1024x1024)
    # icon_full.png: 1024x1024, white bg, mark 62% of canvas
    icon_full = Image.new('RGBA', (1024, 1024), (255, 255, 255, 255))
    target_mark_size = int(1024 * 0.62)
    aspect = m_w / m_h
    if aspect > 1:
        rw = target_mark_size
        rh = int(target_mark_size / aspect)
    else:
        rh = target_mark_size
        rw = int(target_mark_size * aspect)

    resized_mark = mark_cropped.resize((rw, rh), Image.Resampling.LANCZOS)
    pos_x = (1024 - rw) // 2
    pos_y = (1024 - rh) // 2
    icon_full.paste(resized_mark, (pos_x, pos_y), resized_mark)
    icon_full.save('assets/images/icon_full.png')
    print("Saved assets/images/icon_full.png")

    # Adaptive foreground (safe zone 66%)
    android_fg = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    target_fg_size = int(1024 * 0.55)
    if aspect > 1:
        rw = target_fg_size
        rh = int(target_fg_size / aspect)
    else:
        rh = target_fg_size
        rw = int(target_fg_size * aspect)
    resized_fg_mark = mark_cropped.resize((rw, rh), Image.Resampling.LANCZOS)
    pos_x = (1024 - rw) // 2
    pos_y = (1024 - rh) // 2
    android_fg.paste(resized_fg_mark, (pos_x, pos_y), resized_fg_mark)
    android_fg.save('assets/images/android_foreground.png')
    print("Saved assets/images/android_foreground.png")

    # Monochrome icon (white mark on transparent)
    mono_mark = Image.new('RGBA', (rw, rh), (0, 0, 0, 0))
    mono_pixels = mono_mark.load()
    ref_pixels = resized_fg_mark.load()
    for y in range(rh):
        for x in range(rw):
            _, _, _, a = ref_pixels[x, y]
            mono_pixels[x, y] = (255, 255, 255, a)

    mono_icon = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    mono_icon.paste(mono_mark, (pos_x, pos_y), mono_mark)
    mono_icon.save('assets/images/android_monochrome.png')
    print("Saved assets/images/android_monochrome.png")

    # Notification status icons in drawable folders
    drawable_densities = [
        ('drawable-mdpi', 24),
        ('drawable-hdpi', 36),
        ('drawable-xhdpi', 48),
        ('drawable-xxhdpi', 72),
        ('drawable-xxxhdpi', 96),
    ]

    for dir_name, size in drawable_densities:
        target_dir = os.path.join('android', 'app', 'src', 'main', 'res', dir_name)
        os.makedirs(target_dir, exist_ok=True)
        stat_icon = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        # scale mark into size
        s_w = int(size * 0.8)
        s_h = int((size * 0.8) / aspect) if aspect > 1 else int(size * 0.8)
        s_mark = mark_cropped.resize((max(1, s_w), max(1, s_h)), Image.Resampling.LANCZOS)

        # turn white
        s_pixels = s_mark.load()
        for y in range(s_mark.height):
            for x in range(s_mark.width):
                _, _, _, a = s_pixels[x, y]
                s_pixels[x, y] = (255, 255, 255, a)

        px = (size - s_mark.width) // 2
        py = (size - s_mark.height) // 2
        stat_icon.paste(s_mark, (px, py), s_mark)
        stat_icon.save(os.path.join(target_dir, 'ic_stat_atlendify.png'))

    # res/raw/keep.xml
    raw_dir = os.path.join('android', 'app', 'src', 'main', 'res', 'raw')
    os.makedirs(raw_dir, exist_ok=True)
    with open(os.path.join(raw_dir, 'keep.xml'), 'w') as f:
        f.write('<resources xmlns:tools="http://schemas.android.com/tools" tools:keep="@drawable/ic_stat_atlendify"/>\n')
    print("Saved notification status icons & keep.xml")

def generate_audio():
    sample_rate = 44100

    def write_wav(filename, samples):
        with wave.open(filename, 'w') as f:
            f.setnchannels(1)
            f.setsampwidth(2)
            f.setframerate(sample_rate)
            for s in samples:
                val = int(max(-32768, min(32767, s * 32767)))
                f.writeframes(struct.pack('<h', val))

    # present.wav: short rising two-tone (440Hz -> 880Hz, 150ms total)
    samples_present = []
    dur = 0.08
    n_samples = int(sample_rate * dur)
    for i in range(n_samples):
        t = i / sample_rate
        samples_present.append(0.5 * math.sin(2 * math.pi * 523.25 * t) * (1 - i / n_samples))
    for i in range(n_samples):
        t = i / sample_rate
        samples_present.append(0.5 * math.sin(2 * math.pi * 880.00 * t) * (1 - i / n_samples))
    write_wav('assets/sounds/present.wav', samples_present)
    print("Generated assets/sounds/present.wav")

    # late.wav: double beep (600Hz, 80ms, 40ms pause, 600Hz, 80ms)
    samples_late = []
    dur_beep = 0.08
    n_beep = int(sample_rate * dur_beep)
    for i in range(n_beep):
        t = i / sample_rate
        samples_late.append(0.5 * math.sin(2 * math.pi * 659.25 * t) * (1 - i / n_beep))
    n_pause = int(sample_rate * 0.04)
    samples_late.extend([0.0] * n_pause)
    for i in range(n_beep):
        t = i / sample_rate
        samples_late.append(0.5 * math.sin(2 * math.pi * 659.25 * t) * (1 - i / n_beep))
    write_wav('assets/sounds/late.wav', samples_late)
    print("Generated assets/sounds/late.wav")

    # error.wav: low buzz (180Hz square-ish, 200ms)
    samples_error = []
    dur_err = 0.20
    n_err = int(sample_rate * dur_err)
    for i in range(n_err):
        t = i / sample_rate
        s = 0.4 * (1.0 if math.sin(2 * math.pi * 180.0 * t) > 0 else -1.0)
        samples_error.append(s * (1 - i / n_err))
    write_wav('assets/sounds/error.wav', samples_error)
    print("Generated assets/sounds/error.wav")

if __name__ == '__main__':
    process_images()
    generate_audio()
