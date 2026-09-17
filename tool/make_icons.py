from pathlib import Path
from PIL import Image, ImageDraw
import json

def icon(path, size):
 scale=4
 im=Image.new('RGB',(size*scale,size*scale),'#080909')
 d=ImageDraw.Draw(im)
 points=[(.57,.13),(.25,.55),(.47,.55),(.41,.87),(.77,.42),(.54,.42)]
 d.polygon([(int(x*size*scale),int(y*size*scale)) for x,y in points], fill='#B8E8C5')
 im.resize((size,size),Image.Resampling.LANCZOS).save(path)

for folder,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
 icon(Path(f'android/app/src/main/res/mipmap-{folder}/ic_launcher.png'),size)
folder=Path('ios/Runner/Assets.xcassets/AppIcon.appiconset')
for item in json.loads((folder/'Contents.json').read_text())['images']:
 if 'filename' in item:
  size=round(float(item['size'].split('x')[0])*float(item['scale'].replace('x','')))
  icon(folder/item['filename'],size)
for path in Path('web/icons').glob('*.png'):
 icon(path,512 if '512' in path.name else 192)
icon(Path('web/favicon.png'),32)

# Keep source text portable across Windows, macOS, and the Supabase SQL editor.
for folder in ['lib','test','config','supabase']:
 for path in Path(folder).rglob('*'):
  if path.suffix in ['.dart','.json','.sql']:
   path.write_text(path.read_text(encoding='utf-8-sig'), encoding='utf-8')
