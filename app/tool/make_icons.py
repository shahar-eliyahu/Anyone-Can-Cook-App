"""App icon and splash images from the official logo (docs/branding/logo.png).

Run from app/ with Pillow and numpy:  python tool/make_icons.py

The logo is a full square: a hat and crossed utensils on a soft blue gradient. The
utensils reach ~0.39 of the size from the centre, past Android's adaptive safe circle
(0.306), so the adaptive icon is built in two layers:
  * background: the logo's own gradient (left/right edge colours per row, blended);
  * foreground: the hat and utensils separated from that known background (soft alpha,
    the glow kept), scaled so everything stays inside the safe circle.
The monochrome layer (Android 13+ themed icons) is the same silhouette in white. iOS and
legacy Android icons use the logo itself: their shapes never cut into the content.
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

APP = Path(__file__).resolve().parents[1]
LOGO = APP.parent / "docs" / "branding" / "logo.png"
RES = APP / "android" / "app" / "src" / "main" / "res"
IOS = APP / "ios" / "Runner" / "Assets.xcassets"

SAFE_RADIUS = 0.30  # of the 108dp canvas; Android's safe zone is 0.306
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}

logo = Image.open(LOGO).convert("RGB")
src = np.asarray(logo).astype(float)
H, W, _ = src.shape

# Known background: per row, a blend of the left and right edge colours.
left = src[:, 2:12].mean(axis=1)
right = src[:, W - 12:W - 2].mean(axis=1)
t = np.linspace(0, 1, W)[None, :, None]
bg = left[:, None, :] * (1 - t) + right[:, None, :] * t
diff = np.sqrt(((src - bg) ** 2).sum(axis=2))

# Soft alpha (dither noise stays out, the glow comes in partly) and un-mixed colour.
alpha = np.clip((diff - 10) / 70, 0, 1)
# Only the hat and utensils: blocks that are mostly content, grown by a margin for the glow.
B = 16
blocks = alpha[: H // B * B, : W // B * B].reshape(H // B, B, W // B, B).mean(axis=(1, 3)) > 0.35
grown = blocks.copy()
for _ in range(3):
    g = grown.copy()
    g[1:] |= grown[:-1]; g[:-1] |= grown[1:]; g[:, 1:] |= grown[:, :-1]; g[:, :-1] |= grown[:, 1:]
    grown = g
region = np.zeros((H, W), bool)
region[: H // B * B, : W // B * B] = np.kron(grown, np.ones((B, B), bool))
alpha = alpha * region
safe = np.maximum(alpha, 1e-3)[..., None]
fg = np.clip(bg + (src - bg) / safe, 0, 255)
fg_rgba = np.dstack([fg, alpha * 255]).astype("uint8")
mono_alpha = np.clip((diff - 40) / 40, 0, 1) * region

# Scale so the farthest solid content point fits the safe circle.
ys, xs = np.nonzero(alpha > 0.5)
reach = (np.sqrt((xs - W / 2) ** 2 + (ys - H / 2) ** 2) / W).max()
scale = min(1.0, SAFE_RADIUS / reach)
print(f"content reach {reach:.3f} of the size; adaptive foreground scale {scale:.3f}")


def layer(img: Image.Image, px: int) -> Image.Image:
    """[img] scaled by [scale] and centred on a transparent px×px canvas."""
    inner = round(px * scale)
    canvas = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    canvas.alpha_composite(img.resize((inner, inner), Image.LANCZOS), ((px - inner) // 2, (px - inner) // 2))
    return canvas


def gradient(px: int) -> Image.Image:
    """The logo's background gradient at px×px."""
    y = np.linspace(0, H - 1, px)
    lc = np.stack([np.interp(y, np.arange(H), left[:, c]) for c in range(3)], axis=1)
    rc = np.stack([np.interp(y, np.arange(H), right[:, c]) for c in range(3)], axis=1)
    tt = np.linspace(0, 1, px)[None, :, None]
    g = lc[:, None, :] * (1 - tt) + rc[:, None, :] * tt
    return Image.fromarray(np.clip(g, 0, 255).astype("uint8"), "RGB")


def rounded(img: Image.Image, px: int, radius: float) -> Image.Image:
    out = img.resize((px, px), Image.LANCZOS).convert("RGBA")
    mask = Image.new("L", (px * 4, px * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, px * 4 - 1, px * 4 - 1), radius=radius * px * 4, fill=255)
    out.putalpha(mask.resize((px, px), Image.LANCZOS))
    return out


fg_img = Image.fromarray(fg_rgba, "RGBA")
mono_img = Image.fromarray(np.dstack([np.full((H, W, 3), 255), mono_alpha * 255]).astype("uint8"), "RGBA")

for name, d in DENSITIES.items():
    adaptive = round(108 * d)
    out = RES / f"drawable-{name}"
    out.mkdir(parents=True, exist_ok=True)
    layer(fg_img, adaptive).save(out / "ic_launcher_foreground.png", optimize=True)
    layer(mono_img, adaptive).save(out / "ic_launcher_monochrome.png", optimize=True)
    gradient(adaptive).save(out / "ic_launcher_background.png", optimize=True)
    legacy = round(48 * d)
    (RES / f"mipmap-{name}").mkdir(parents=True, exist_ok=True)
    rounded(logo, legacy, 0.18).save(RES / f"mipmap-{name}" / "ic_launcher.png", optimize=True)
    # Splash for Android before 12: the mark on the warm off-white window.
    rounded(logo, round(112 * d), 0.24).save(out / "splash_logo.png", optimize=True)

# iOS: every size in the icon set, no alpha (iOS draws the rounded shape).
import json

icons = IOS / "AppIcon.appiconset"
for entry in json.loads((icons / "Contents.json").read_text())["images"]:
    size = float(entry["size"].split("x")[0]) * float(entry["scale"].rstrip("x"))
    logo.resize((round(size), round(size)), Image.LANCZOS).save(icons / entry["filename"], optimize=True)

# iOS launch screen image: the rounded mark, 112pt.
launch = IOS / "LaunchImage.imageset"
for suffix, k in (("", 1), ("@2x", 2), ("@3x", 3)):
    rounded(logo, 112 * k, 0.24).save(launch / f"LaunchImage{suffix}.png", optimize=True)

# In-app mark (home header, menu, about).
logo.resize((256, 256), Image.LANCZOS).save(APP / "assets" / "branding" / "logo_mark.png", optimize=True)
# Sources kept with the app, as before.
logo.save(APP / "assets" / "icon" / "app_icon.png", optimize=True)
layer(mono_img, 1024).save(APP / "assets" / "icon" / "app_icon_monochrome.png", optimize=True)
print("done")
