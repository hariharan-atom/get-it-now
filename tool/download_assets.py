import urllib.request, concurrent.futures
from pathlib import Path
assets = {
 'assets/fonts/Epilogue.ttf': 'https://raw.githubusercontent.com/google/fonts/main/ofl/epilogue/Epilogue%5Bwght%5D.ttf',
 'assets/fonts/DMSans.ttf': 'https://raw.githubusercontent.com/google/fonts/main/ofl/dmsans/DMSans%5Bopsz,wght%5D.ttf',
 'assets/fonts/Epilogue-OFL.txt': 'https://raw.githubusercontent.com/google/fonts/main/ofl/epilogue/OFL.txt',
 'assets/fonts/DMSans-OFL.txt': 'https://raw.githubusercontent.com/google/fonts/main/ofl/dmsans/OFL.txt',
 'assets/products/avocado.jpg': 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=600&h=600&fit=crop&q=85',
 'assets/products/strawberries.jpg': 'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=600&h=600&fit=crop&q=85',
 'assets/products/bananas.jpg': 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=600&h=600&fit=crop&q=85',
 'assets/products/bread.jpg': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&h=600&fit=crop&q=85',
 'assets/products/milk.jpg': 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=600&h=600&fit=crop&q=85',
 'assets/products/eggs.jpg': 'https://images.unsplash.com/photo-1518569656558-1f25e69d93d7?w=600&h=600&fit=crop&q=85',
 'assets/products/tomatoes.jpg': 'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?w=600&h=600&fit=crop&q=85',
 'assets/products/oranges.jpg': 'https://images.unsplash.com/photo-1547514701-42782101795e?w=600&h=600&fit=crop&q=85',
}
def download(item):
 path,url=item
 try:
  urllib.request.urlretrieve(url,path)
  print(path,Path(path).stat().st_size)
 except Exception as e: print('FAILED',path,str(e))
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool: list(pool.map(download,assets.items()))
