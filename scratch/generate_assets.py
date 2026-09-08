import os
import math
from PIL import Image, ImageDraw, ImageFilter, ImageFont

OBJECTS_DIR = 'assets/images/objects'
GROCERIES_DIR = 'assets/images/groceries'
os.makedirs(OBJECTS_DIR, exist_ok=True)
os.makedirs(GROCERIES_DIR, exist_ok=True)

CANVAS_SIZE = 512

def create_base_canvas():
    return Image.new('RGBA', (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))

def add_shadow(img, offset=(0, 16), blur=14, color=(0, 0, 0, 45)):
    shadow = Image.new('RGBA', img.size, (0, 0, 0, 0))
    alpha = img.split()[-1]
    shadow_mask = Image.new('RGBA', img.size, color)
    shadow.paste(shadow_mask, offset, mask=alpha)
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    final_img = Image.new('RGBA', img.size, (0, 0, 0, 0))
    final_img.paste(shadow, (0, 0))
    final_img.paste(img, (0, 0), mask=alpha)
    return final_img

def draw_rose():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Stem & Leaves
    d.line([(256, 270), (256, 440)], fill=(46, 125, 50), width=16)
    d.polygon([(256, 350), (340, 310), (320, 360)], fill=(56, 142, 60))
    d.polygon([(256, 380), (180, 340), (200, 390)], fill=(46, 125, 50))
    # Rose Petals
    d.ellipse([170, 140, 342, 290], fill=(211, 47, 47))
    d.ellipse([190, 150, 322, 260], fill=(229, 57, 53))
    d.ellipse([210, 170, 302, 240], fill=(198, 40, 40))
    d.ellipse([225, 185, 287, 225], fill=(239, 83, 80))
    d.arc([200, 160, 310, 270], start=30, end=150, fill=(183, 28, 28), width=6)
    return add_shadow(img)

def draw_glasses():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Left Lens Frame
    d.rounded_rectangle([90, 200, 230, 300], radius=35, outline=(62, 39, 35), width=14, fill=(236, 239, 241, 160))
    # Right Lens Frame
    d.rounded_rectangle([282, 200, 422, 300], radius=35, outline=(62, 39, 35), width=14, fill=(236, 239, 241, 160))
    # Bridge
    d.arc([220, 210, 292, 260], start=180, end=360, fill=(62, 39, 35), width=12)
    # Temples
    d.line([(96, 215), (50, 180)], fill=(78, 52, 46), width=10)
    d.line([(416, 215), (462, 180)], fill=(78, 52, 46), width=10)
    # Lens glint
    d.line([(120, 220), (170, 275)], fill=(255, 255, 255, 200), width=8)
    d.line([(312, 220), (362, 275)], fill=(255, 255, 255, 200), width=8)
    return add_shadow(img)

def draw_camera():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Body
    d.rounded_rectangle([100, 180, 412, 380], radius=24, fill=(38, 50, 56))
    d.rounded_rectangle([190, 140, 322, 190], radius=12, fill=(55, 71, 79))
    # Grip / details
    d.rounded_rectangle([120, 200, 170, 360], radius=10, fill=(69, 90, 100))
    d.ellipse([360, 155, 385, 180], fill=(229, 57, 53)) # shutter
    d.ellipse([130, 155, 155, 180], fill=(255, 179, 0)) # dial
    # Lens
    d.ellipse([200, 200, 360, 360], fill=(33, 33, 33), outline=(176, 190, 197), width=10)
    d.ellipse([225, 225, 335, 335], fill=(21, 101, 192), outline=(13, 71, 161), width=6)
    d.ellipse([245, 245, 280, 280], fill=(255, 255, 255, 180)) # reflex
    return add_shadow(img)

def draw_umbrella():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Canopy
    d.pieslice([100, 110, 412, 420], start=180, end=360, fill=(21, 101, 192))
    # Scallops at bottom of canopy
    for i in range(4):
        x1 = 100 + i * 78
        x2 = x1 + 78
        d.pieslice([x1, 250, x2, 280], start=0, end=180, fill=(0, 0, 0, 0))
    # Shaft & Handle
    d.line([(256, 100), (256, 390)], fill=(120, 144, 156), width=10)
    d.arc([220, 370, 260, 420], start=0, end=180, fill=(93, 64, 55), width=12)
    # Tip
    d.polygon([(256, 80), (250, 115), (262, 115)], fill=(120, 144, 156))
    return add_shadow(img)

def draw_key():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Golden key
    # Head
    d.ellipse([90, 200, 220, 330], fill=(255, 179, 0), outline=(255, 143, 0), width=8)
    d.ellipse([125, 235, 185, 295], fill=(0, 0, 0, 0), outline=(255, 143, 0), width=6)
    # Shaft
    d.rounded_rectangle([200, 245, 410, 285], radius=6, fill=(255, 179, 0), outline=(255, 143, 0), width=4)
    # Teeth
    d.rectangle([340, 280, 365, 335], fill=(255, 179, 0))
    d.rectangle([385, 280, 410, 320], fill=(255, 179, 0))
    return add_shadow(img)

def draw_tea_cup():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Saucer
    d.ellipse([110, 330, 402, 400], fill=(224, 224, 224), outline=(189, 189, 189), width=6)
    d.ellipse([130, 340, 382, 390], fill=(245, 245, 245))
    # Handle
    d.arc([310, 210, 410, 310], start=-90, end=90, fill=(224, 224, 224), width=18)
    # Cup
    d.pieslice([160, 160, 352, 352], start=0, end=180, fill=(250, 250, 250), outline=(207, 216, 220), width=6)
    d.ellipse([160, 140, 352, 190], fill=(121, 85, 72), outline=(207, 216, 220), width=6) # Tea surface
    # Steam
    d.arc([220, 80, 250, 130], start=180, end=360, fill=(189, 189, 189, 150), width=6)
    d.arc([270, 70, 300, 120], start=180, end=360, fill=(189, 189, 189, 150), width=6)
    return add_shadow(img)

def draw_clock():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Outer ring
    d.ellipse([100, 100, 412, 412], fill=(238, 238, 238), outline=(66, 66, 66), width=18)
    d.ellipse([125, 125, 387, 387], fill=(255, 255, 255))
    # Hour ticks
    for hour in range(12):
        angle = hour * 30 * math.pi / 180
        x1 = 256 + 110 * math.cos(angle)
        y1 = 256 + 110 * math.sin(angle)
        x2 = 256 + 120 * math.cos(angle)
        y2 = 256 + 120 * math.sin(angle)
        d.line([(x1, y1), (x2, y2)], fill=(33, 33, 33), width=6)
    # Hands (10:10)
    d.line([(256, 256), (190, 190)], fill=(33, 33, 33), width=12) # hour
    d.line([(256, 256), (320, 160)], fill=(33, 33, 33), width=8)  # min
    d.line([(256, 256), (256, 350)], fill=(229, 57, 53), width=4) # second
    d.ellipse([244, 244, 268, 268], fill=(229, 57, 53))
    return add_shadow(img)

def draw_book():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Book Cover
    d.polygon([(110, 340), (245, 390), (245, 160), (110, 110)], fill=(21, 101, 192))
    d.polygon([(402, 340), (267, 390), (267, 160), (402, 110)], fill=(25, 118, 210))
    # Spine & Pages
    d.polygon([(125, 330), (245, 375), (245, 170), (125, 125)], fill=(255, 253, 231))
    d.polygon([(387, 330), (267, 375), (267, 170), (387, 125)], fill=(255, 253, 231))
    # Lines on pages
    for y in range(190, 320, 24):
        d.line([(145, y - 20), (230, y + 10)], fill=(189, 189, 189), width=3)
        d.line([(282, y + 10), (367, y - 20)], fill=(189, 189, 189), width=3)
    return add_shadow(img)

def draw_apple():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Stem
    d.line([(256, 120), (270, 180)], fill=(93, 64, 55), width=10)
    # Leaf
    d.polygon([(265, 135), (320, 115), (295, 160)], fill=(76, 175, 80))
    # Body
    d.ellipse([135, 165, 285, 385], fill=(229, 57, 53))
    d.ellipse([227, 165, 377, 385], fill=(211, 47, 47))
    d.ellipse([160, 190, 210, 270], fill=(255, 138, 128, 140)) # glint
    return add_shadow(img)

def draw_banana():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    d.arc([110, 80, 420, 390], start=30, end=170, fill=(253, 216, 53), width=65)
    d.arc([125, 100, 400, 370], start=30, end=170, fill=(255, 238, 88), width=35)
    # Ends
    d.ellipse([345, 140, 375, 170], fill=(109, 76, 65))
    d.ellipse([140, 330, 170, 360], fill=(109, 76, 65))
    return add_shadow(img)

def draw_water_bottle():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Cap
    d.rounded_rectangle([226, 90, 286, 130], radius=6, fill=(13, 71, 161))
    # Neck
    d.rectangle([236, 130, 276, 165], fill=(66, 165, 245, 180))
    # Main Bottle Body
    d.rounded_rectangle([180, 165, 332, 425], radius=24, fill=(100, 181, 246, 190), outline=(33, 150, 243), width=5)
    # Water level
    d.rounded_rectangle([190, 220, 322, 415], radius=16, fill=(33, 150, 243, 160))
    # Grip ridges
    for y in [270, 310, 350]:
        d.line([(200, y), (312, y)], fill=(255, 255, 255, 160), width=4)
    return add_shadow(img)

def draw_handbag():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Handle
    d.arc([170, 100, 342, 270], start=180, end=360, fill=(93, 64, 55), width=16)
    # Bag Body
    d.polygon([(140, 230), (372, 230), (402, 410), (110, 410)], fill=(141, 110, 99))
    d.polygon([(140, 230), (372, 230), (380, 280), (132, 280)], fill=(109, 76, 65))
    # Clasp
    d.rounded_rectangle([236, 270, 276, 305], radius=6, fill=(255, 215, 0))
    return add_shadow(img)

def draw_cap():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Dome
    d.pieslice([130, 160, 382, 380], start=180, end=360, fill=(25, 118, 210))
    # Brim/Peak
    d.pieslice([80, 260, 260, 340], start=90, end=270, fill=(13, 71, 161))
    # Top button
    d.ellipse([244, 150, 268, 174], fill=(13, 71, 161))
    # Front logo mark
    d.line([(230, 210), (256, 185), (282, 210)], fill=(255, 255, 255), width=6)
    return add_shadow(img)

def draw_pencil():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Diagonal pencil
    # Shaft
    d.polygon([(170, 350), (350, 170), (380, 200), (200, 380)], fill=(255, 193, 7))
    # Eraser & Ferrule
    d.polygon([(350, 170), (385, 135), (415, 165), (380, 200)], fill=(239, 154, 154))
    d.polygon([(340, 180), (360, 160), (380, 180), (360, 200)], fill=(176, 190, 197))
    # Tip & Lead
    d.polygon([(170, 350), (200, 380), (130, 420)], fill=(255, 224, 178))
    d.polygon([(145, 405), (155, 415), (130, 420)], fill=(33, 33, 33))
    return add_shadow(img)

def draw_radio():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Antenna
    d.line([(140, 180), (100, 90)], fill=(120, 144, 156), width=6)
    # Body
    d.rounded_rectangle([100, 180, 412, 380], radius=18, fill=(121, 85, 72), outline=(93, 64, 55), width=8)
    # Speaker grille
    d.ellipse([130, 210, 260, 340], fill=(62, 39, 35))
    for r in [20, 35, 50]:
        d.ellipse([195 - r, 275 - r, 195 + r, 275 + r], outline=(141, 110, 99), width=3)
    # Frequency dial & knobs
    d.rounded_rectangle([290, 210, 380, 260], radius=6, fill=(255, 248, 225))
    d.line([(335, 215), (335, 255)], fill=(229, 57, 53), width=4)
    d.ellipse([300, 285, 335, 320], fill=(62, 39, 35))
    d.ellipse([345, 285, 380, 320], fill=(62, 39, 35))
    return add_shadow(img)

def draw_toothbrush():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Handle
    d.rounded_rectangle([140, 320, 360, 365], radius=14, fill=(3, 169, 244))
    d.rounded_rectangle([330, 300, 420, 350], radius=10, fill=(2, 136, 209))
    # Bristles
    for x in range(340, 415, 12):
        d.line([(x, 300), (x, 240)], fill=(255, 255, 255), width=8)
    # Grip pads
    d.ellipse([210, 332, 260, 352], fill=(255, 255, 255))
    return add_shadow(img)

def draw_candle():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Flame
    d.polygon([(256, 110), (230, 170), (282, 170)], fill=(255, 167, 38))
    d.ellipse([240, 140, 272, 180], fill=(255, 235, 59))
    # Wick
    d.line([(256, 170), (256, 200)], fill=(33, 33, 33), width=6)
    # Pillar Candle Body
    d.rounded_rectangle([190, 200, 322, 420], radius=12, fill=(255, 248, 225), outline=(255, 224, 178), width=6)
    # Wax drip
    d.polygon([(220, 200), (220, 260), (235, 260), (235, 200)], fill=(255, 248, 225))
    return add_shadow(img)

def draw_plant():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Pot
    d.polygon([(170, 280), (342, 280), (320, 420), (192, 420)], fill=(216, 67, 21))
    d.rounded_rectangle([155, 260, 357, 290], radius=6, fill=(191, 54, 12))
    # Leaves
    d.pieslice([180, 110, 280, 260], start=180, end=360, fill=(76, 175, 80))
    d.pieslice([232, 110, 332, 260], start=180, end=360, fill=(56, 142, 60))
    d.pieslice([206, 80, 306, 230], start=180, end=360, fill=(129, 199, 132))
    return add_shadow(img)

def draw_spoon():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Head
    d.ellipse([140, 100, 260, 240], fill=(207, 216, 220), outline=(144, 164, 174), width=6)
    d.ellipse([155, 115, 245, 225], fill=(236, 239, 241))
    # Handle
    d.line([(215, 225), (360, 420)], fill=(176, 190, 197), width=18)
    return add_shadow(img)

def draw_rice_bowl():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Rice mound
    d.ellipse([140, 150, 372, 300], fill=(255, 255, 255), outline=(224, 224, 224), width=4)
    for _ in range(12):
        d.ellipse([180 + (_ * 14) % 160, 180 + (_ * 17) % 60, 192 + (_ * 14) % 160, 188 + (_ * 17) % 60], fill=(238, 238, 238))
    # Ceramic bowl
    d.pieslice([130, 180, 382, 420], start=0, end=180, fill=(69, 90, 100))
    d.rounded_rectangle([210, 390, 302, 420], radius=4, fill=(55, 71, 79))
    return add_shadow(img)

def draw_basket():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Handle
    d.arc([160, 90, 352, 300], start=180, end=360, fill=(141, 110, 99), width=16)
    # Basket Body
    d.polygon([(120, 240), (392, 240), (362, 410), (150, 410)], fill=(215, 158, 80))
    # Woven pattern
    for x in range(150, 380, 30):
        d.line([(x, 240), (x - 20, 410)], fill=(156, 102, 38), width=5)
    for y in range(270, 410, 35):
        d.line([(130, y), (380, y)], fill=(156, 102, 38), width=5)
    return add_shadow(img)

def draw_shoe():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Sole
    d.rounded_rectangle([100, 350, 420, 390], radius=8, fill=(224, 224, 224), outline=(158, 158, 158), width=4)
    # Shoe Body
    d.polygon([(110, 350), (140, 230), (240, 230), (350, 300), (410, 350)], fill=(121, 85, 72))
    d.ellipse([140, 215, 230, 260], fill=(62, 39, 35))
    # Laces
    for y in range(260, 320, 18):
        d.line([(220, y), (270, y)], fill=(255, 255, 255), width=5)
    return add_shadow(img)

def draw_scarf():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Loop
    d.ellipse([150, 130, 362, 260], fill=(198, 40, 40), outline=(183, 28, 28), width=6)
    # Tails
    d.polygon([(200, 220), (250, 220), (240, 410), (190, 410)], fill=(229, 57, 53))
    d.polygon([(260, 220), (310, 220), (330, 380), (280, 380)], fill=(211, 47, 47))
    # Stripes
    for y in [270, 330, 370]:
        d.line([(195, y), (245, y)], fill=(255, 248, 225), width=8)
    return add_shadow(img)

def draw_wallet():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Leather Wallet
    d.rounded_rectangle([110, 160, 402, 360], radius=20, fill=(109, 76, 65), outline=(78, 52, 46), width=8)
    d.line([(110, 250), (402, 250)], fill=(78, 52, 46), width=6)
    # Clasp/Strap
    d.rounded_rectangle([320, 230, 390, 275], radius=10, fill=(93, 64, 55))
    d.ellipse([360, 243, 380, 263], fill=(255, 215, 0))
    return add_shadow(img)

def draw_comb():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Spine
    d.rounded_rectangle([100, 180, 412, 230], radius=12, fill=(141, 110, 99))
    # Teeth
    for x in range(120, 395, 14):
        d.line([(x, 230), (x, 340)], fill=(141, 110, 99), width=7)
    return add_shadow(img)

def draw_mug():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Handle
    d.arc([300, 190, 410, 330], start=-90, end=90, fill=(38, 166, 154), width=20)
    # Body
    d.rounded_rectangle([130, 150, 340, 380], radius=16, fill=(0, 150, 136), outline=(0, 121, 107), width=6)
    d.ellipse([130, 130, 340, 180], fill=(0, 121, 107))
    d.ellipse([145, 140, 325, 170], fill=(121, 85, 72)) # Coffee inside
    return add_shadow(img)

def draw_lamp():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Shade
    d.polygon([(180, 120), (332, 120), (382, 250), (130, 250)], fill=(255, 238, 88), outline=(253, 216, 53), width=6)
    # Pole & Base
    d.line([(256, 250), (256, 380)], fill=(120, 144, 156), width=14)
    d.ellipse([180, 370, 332, 420], fill=(90, 107, 124))
    return add_shadow(img)

def draw_bell():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Bell dome
    d.pieslice([140, 120, 372, 360], start=180, end=360, fill=(255, 193, 7), outline=(255, 160, 0), width=8)
    d.rounded_rectangle([120, 320, 392, 360], radius=12, fill=(255, 179, 0))
    # Clapper
    d.ellipse([236, 350, 276, 390], fill=(255, 143, 0))
    # Handle top
    d.ellipse([236, 90, 276, 130], fill=(255, 160, 0))
    return add_shadow(img)

def draw_watch():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Straps
    d.rounded_rectangle([200, 70, 312, 440], radius=10, fill=(78, 52, 46))
    # Dial
    d.ellipse([160, 160, 352, 352], fill=(255, 255, 255), outline=(255, 215, 0), width=16)
    # Hands
    d.line([(256, 256), (220, 220)], fill=(33, 33, 33), width=8)
    d.line([(256, 256), (310, 256)], fill=(33, 33, 33), width=6)
    d.ellipse([248, 248, 264, 264], fill=(229, 57, 53))
    return add_shadow(img)

def draw_sweater():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Torso
    d.polygon([(160, 170), (352, 170), (370, 400), (142, 400)], fill=(92, 107, 115))
    # Sleeves
    d.polygon([(160, 170), (80, 270), (120, 300), (160, 230)], fill=(74, 85, 104))
    d.polygon([(352, 170), (432, 270), (392, 300), (352, 230)], fill=(74, 85, 104))
    # Collar
    d.pieslice([206, 130, 306, 210], start=0, end=180, fill=(255, 255, 255))
    return add_shadow(img)

# ----------------- GROCERIES -----------------

def draw_rice():
    return draw_rice_bowl()

def draw_dal():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([140, 160, 372, 300], fill=(255, 193, 7))
    for _ in range(16):
        d.ellipse([170 + (_ * 17) % 170, 180 + (_ * 19) % 70, 184 + (_ * 17) % 170, 192 + (_ * 19) % 70], fill=(255, 160, 0))
    d.pieslice([130, 190, 382, 420], start=0, end=180, fill=(120, 144, 156))
    return add_shadow(img)

def draw_wheat():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Stalk
    d.line([(256, 100), (256, 420)], fill=(255, 213, 79), width=8)
    for y in range(120, 330, 30):
        d.ellipse([210, y, 256, y + 25], fill=(255, 193, 7))
        d.ellipse([256, y - 10, 302, y + 15], fill=(255, 179, 0))
    return add_shadow(img)

def draw_salt():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Shaker
    d.rounded_rectangle([180, 170, 332, 410], radius=24, fill=(236, 239, 241, 200), outline=(207, 216, 220), width=6)
    # Metal Cap with holes
    d.rounded_rectangle([200, 110, 312, 170], radius=12, fill=(176, 190, 197))
    for x in [225, 256, 287]:
        d.ellipse([x - 4, 136, x + 4, 144], fill=(69, 90, 100))
    d.text((236, 260), "SALT", fill=(90, 107, 124))
    return add_shadow(img)

def draw_sugar():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Sugar bag
    d.polygon([(160, 140), (352, 140), (372, 410), (140, 410)], fill=(255, 255, 255), outline=(176, 190, 197), width=6)
    d.rounded_rectangle([190, 220, 322, 330], radius=12, fill=(225, 245, 254))
    d.text((226, 260), "SUGAR", fill=(2, 119, 189))
    return add_shadow(img)

def draw_cooking_oil():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Cap
    d.rounded_rectangle([236, 90, 276, 130], radius=6, fill=(255, 179, 0))
    # Bottle
    d.rounded_rectangle([180, 150, 332, 420], radius=20, fill=(255, 249, 196, 200), outline=(255, 213, 79), width=6)
    d.rounded_rectangle([190, 190, 322, 410], radius=14, fill=(255, 214, 0, 180)) # Golden Oil
    return add_shadow(img)

def draw_mango():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([160, 140, 360, 390], fill=(255, 179, 0))
    d.ellipse([180, 150, 330, 350], fill=(255, 193, 7))
    d.ellipse([270, 190, 360, 330], fill=(244, 81, 30, 150)) # Red blush
    # Stem & leaf
    d.line([(256, 110), (256, 150)], fill=(93, 64, 55), width=8)
    d.polygon([(256, 125), (310, 105), (290, 145)], fill=(76, 175, 80))
    return add_shadow(img)

def draw_orange():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([135, 145, 377, 387], fill=(255, 143, 0))
    d.ellipse([150, 160, 362, 372], fill=(255, 167, 38))
    # Leaf
    d.polygon([(256, 120), (300, 95), (280, 140)], fill=(76, 175, 80))
    return add_shadow(img)

def draw_coconut():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Shell
    d.ellipse([130, 140, 382, 392], fill=(109, 76, 65))
    # Cut half inside
    d.ellipse([170, 170, 350, 350], fill=(255, 255, 255), outline=(141, 110, 99), width=14)
    d.ellipse([210, 210, 310, 310], fill=(236, 239, 241))
    return add_shadow(img)

def draw_cabbage():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([130, 130, 382, 382], fill=(102, 187, 106))
    d.arc([160, 160, 352, 352], start=45, end=225, fill=(165, 214, 167), width=16)
    d.arc([170, 170, 342, 342], start=180, end=360, fill=(200, 230, 201), width=14)
    return add_shadow(img)

def draw_peas():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Pod
    d.arc([100, 150, 420, 380], start=160, end=350, fill=(76, 175, 80), width=65)
    # Peas inside
    for x in range(170, 350, 45):
        d.ellipse([x, 230, x + 38, 268], fill=(139, 195, 74), outline=(56, 142, 60), width=3)
    return add_shadow(img)

def draw_garlic():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Bulb
    d.ellipse([150, 200, 362, 390], fill=(250, 250, 250), outline=(224, 224, 224), width=6)
    # Segments
    d.arc([170, 200, 310, 390], start=120, end=240, fill=(207, 216, 220), width=6)
    d.arc([202, 200, 342, 390], start=-60, end=60, fill=(207, 216, 220), width=6)
    # Root tip
    d.polygon([(256, 150), (245, 205), (267, 205)], fill=(215, 204, 200))
    return add_shadow(img)

def draw_sugarcane():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    for offset in [0, 45]:
        d.rounded_rectangle([210 + offset, 100, 255 + offset, 420], radius=10, fill=(104, 159, 56))
        for y in [160, 230, 300, 370]:
            d.line([(210 + offset, y), (255 + offset, y)], fill=(255, 235, 59), width=8)
    return add_shadow(img)

def draw_milk():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Bottle
    d.rounded_rectangle([180, 160, 332, 420], radius=24, fill=(255, 255, 255), outline=(207, 216, 220), width=6)
    d.rounded_rectangle([220, 110, 292, 160], radius=8, fill=(30, 136, 229))
    d.rounded_rectangle([190, 250, 322, 330], radius=8, fill=(187, 222, 251))
    d.text((230, 280), "MILK", fill=(13, 71, 161))
    return add_shadow(img)

def draw_bread():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Loaf top
    d.ellipse([120, 160, 392, 270], fill=(161, 136, 127))
    # Loaf bottom
    d.rounded_rectangle([140, 220, 372, 380], radius=16, fill=(215, 204, 200), outline=(141, 110, 99), width=6)
    # Slits
    d.line([(200, 190), (230, 230)], fill=(121, 85, 72), width=6)
    d.line([(260, 190), (290, 230)], fill=(121, 85, 72), width=6)
    return add_shadow(img)

def draw_tea():
    return draw_tea_cup()

def draw_coffee():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Handle
    d.arc([300, 200, 390, 310], start=-90, end=90, fill=(141, 110, 99), width=18)
    # Cup
    d.pieslice([150, 170, 342, 362], start=0, end=180, fill=(238, 238, 238), outline=(189, 189, 189), width=6)
    d.ellipse([150, 150, 342, 200], fill=(62, 39, 35))
    # Saucer
    d.ellipse([120, 340, 372, 390], fill=(224, 224, 224))
    return add_shadow(img)

def draw_biscuits():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # 2 round biscuits
    d.ellipse([130, 170, 290, 330], fill=(255, 183, 77), outline=(239, 108, 0), width=6)
    d.ellipse([230, 210, 390, 370], fill=(255, 204, 128), outline=(239, 108, 0), width=6)
    # Dots
    for cx, cy in [(210, 250), (310, 290)]:
        for dx in [-20, 0, 20]:
            for dy in [-20, 0, 20]:
                d.ellipse([cx + dx - 3, cy + dy - 3, cx + dx + 3, cy + dy + 3], fill=(230, 81, 0))
    return add_shadow(img)

def draw_eggs():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # 2 Eggs
    d.ellipse([140, 190, 270, 370], fill=(255, 236, 179), outline=(255, 213, 79), width=6)
    d.ellipse([240, 170, 370, 350], fill=(255, 248, 225), outline=(255, 224, 178), width=6)
    return add_shadow(img)

def draw_potato():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([130, 180, 382, 340], fill=(188, 143, 85), outline=(141, 110, 99), width=6)
    for x, y in [(190, 230), (270, 210), (320, 260), (230, 290)]:
        d.arc([x, y, x + 20, y + 10], start=0, end=180, fill=(109, 76, 65), width=4)
    return add_shadow(img)

def draw_tomato():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Body
    d.ellipse([130, 160, 382, 390], fill=(229, 57, 53))
    # Glint
    d.ellipse([170, 190, 210, 260], fill=(255, 138, 128, 140))
    # Green Calyx
    d.polygon([(256, 150), (220, 120), (240, 160)], fill=(56, 142, 60))
    d.polygon([(256, 150), (292, 120), (272, 160)], fill=(56, 142, 60))
    d.polygon([(256, 150), (256, 100), (266, 150)], fill=(46, 125, 50))
    return add_shadow(img)

def draw_onion():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    d.ellipse([140, 180, 372, 380], fill=(171, 71, 188))
    # Top shoot
    d.polygon([(256, 110), (236, 190), (276, 190)], fill=(123, 31, 162))
    # Lines
    for x in [200, 256, 312]:
        d.arc([x - 20, 180, x + 20, 380], start=-90, end=90, fill=(142, 36, 170), width=4)
    return add_shadow(img)

def draw_carrot():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Carrot body
    d.polygon([(180, 160), (332, 160), (256, 420)], fill=(245, 124, 0))
    # Ridges
    for y in [220, 280, 340]:
        d.line([(230, y), (280, y)], fill=(230, 81, 0), width=4)
    # Green leafy top
    d.line([(256, 160), (230, 90)], fill=(76, 175, 80), width=10)
    d.line([(256, 160), (256, 80)], fill=(56, 142, 60), width=10)
    d.line([(256, 160), (282, 90)], fill=(76, 175, 80), width=10)
    return add_shadow(img)

def draw_brinjal():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Eggplant body
    d.ellipse([170, 170, 342, 410], fill=(74, 20, 140))
    # Calyx & Stem
    d.polygon([(256, 100), (256, 170), (270, 100)], fill=(46, 125, 50))
    d.polygon([(210, 180), (256, 210), (302, 180), (256, 150)], fill=(56, 142, 60))
    return add_shadow(img)

def draw_green_chilli():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    d.arc([110, 120, 400, 390], start=30, end=170, fill=(46, 125, 50), width=50)
    # Cap & Stem
    d.ellipse([325, 160, 365, 200], fill=(27, 94, 32))
    d.line([(345, 160), (370, 130)], fill=(27, 94, 32), width=8)
    return add_shadow(img)

def draw_spinach():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    d.pieslice([140, 110, 290, 380], start=150, end=330, fill=(46, 125, 50))
    d.pieslice([220, 110, 370, 380], start=210, end=390, fill=(56, 142, 60))
    d.line([(256, 240), (256, 420)], fill=(139, 195, 74), width=12)
    return add_shadow(img)

def draw_corn():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Cob
    d.rounded_rectangle([200, 130, 312, 390], radius=40, fill=(255, 238, 88), outline=(253, 216, 53), width=6)
    # Kernels
    for y in range(160, 370, 24):
        for x in range(215, 300, 24):
            d.ellipse([x - 6, y - 6, x + 6, y + 6], fill=(255, 179, 0))
    # Husk
    d.polygon([(160, 250), (210, 400), (200, 280)], fill=(129, 199, 132))
    d.polygon([(352, 250), (302, 400), (312, 280)], fill=(102, 187, 106))
    return add_shadow(img)

def draw_honey():
    img = create_base_canvas()
    d = ImageDraw.Draw(img)
    # Pot
    d.ellipse([140, 180, 372, 390], fill=(255, 179, 0), outline=(245, 124, 0), width=8)
    # Lid
    d.rounded_rectangle([190, 140, 322, 190], radius=10, fill=(121, 85, 72))
    # Honey dipper dripping
    d.rounded_rectangle([220, 250, 292, 310], radius=6, fill=(255, 238, 88))
    d.text((236, 270), "HONEY", fill=(191, 54, 12))
    return add_shadow(img)


# Generation mapping
OBJECT_GENERATORS = {
    'rose.png': draw_rose,
    'glasses.png': draw_glasses,
    'camera.png': draw_camera,
    'umbrella.png': draw_umbrella,
    'key.png': draw_key,
    'tea_cup.png': draw_tea_cup,
    'clock.png': draw_clock,
    'book.png': draw_book,
    'apple.png': draw_apple,
    'banana.png': draw_banana,
    'water_bottle.png': draw_water_bottle,
    'handbag.png': draw_handbag,
    'cap.png': draw_cap,
    'pencil.png': draw_pencil,
    'radio.png': draw_radio,
    'toothbrush.png': draw_toothbrush,
    'candle.png': draw_candle,
    'plant.png': draw_plant,
    'spoon.png': draw_spoon,
    'rice_bowl.png': draw_rice_bowl,
    'basket.png': draw_basket,
    'shoe.png': draw_shoe,
    'scarf.png': draw_scarf,
    'wallet.png': draw_wallet,
    'comb.png': draw_comb,
    'mug.png': draw_mug,
    'lamp.png': draw_lamp,
    'bell.png': draw_bell,
    'watch.png': draw_watch,
    'sweater.png': draw_sweater,
}

GROCERY_GENERATORS = {
    'rice.png': draw_rice,
    'dal.png': draw_dal,
    'wheat.png': draw_wheat,
    'salt.png': draw_salt,
    'sugar.png': draw_sugar,
    'cooking_oil.png': draw_cooking_oil,
    'banana.png': draw_banana,
    'apple.png': draw_apple,
    'mango.png': draw_mango,
    'orange.png': draw_orange,
    'coconut.png': draw_coconut,
    'cabbage.png': draw_cabbage,
    'peas.png': draw_peas,
    'garlic.png': draw_garlic,
    'sugarcane.png': draw_sugarcane,
    'milk.png': draw_milk,
    'bread.png': draw_bread,
    'tea.png': draw_tea,
    'coffee.png': draw_coffee,
    'biscuits.png': draw_biscuits,
    'eggs.png': draw_eggs,
    'potato.png': draw_potato,
    'tomato.png': draw_tomato,
    'onion.png': draw_onion,
    'carrot.png': draw_carrot,
    'brinjal.png': draw_brinjal,
    'green_chilli.png': draw_green_chilli,
    'spinach.png': draw_spinach,
    'corn.png': draw_corn,
    'honey.png': draw_honey,
}

print("Generating 30 Object Assets...")
for filename, gen_fn in OBJECT_GENERATORS.items():
    path = os.path.join(OBJECT_DIR := OBJECTS_DIR, filename)
    img = gen_fn()
    img.save(path, 'PNG')
print(f"Generated {len(OBJECT_GENERATORS)} objects.")

print("Generating 30 Grocery Assets...")
for filename, gen_fn in GROCERY_GENERATORS.items():
    path = os.path.join(GROCERIES_DIR, filename)
    img = gen_fn()
    img.save(path, 'PNG')
print(f"Generated {len(GROCERY_GENERATORS)} groceries.")
