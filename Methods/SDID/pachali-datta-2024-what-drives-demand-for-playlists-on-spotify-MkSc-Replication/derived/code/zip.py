# Zip files
from zipfile import ZipFile 
import zipfile
import os

try:
    import zlib
    compression = zipfile.ZIP_DEFLATED
except:
    compression = zipfile.ZIP_STORED

modes = { zipfile.ZIP_DEFLATED: 'deflated',
          zipfile.ZIP_STORED:   'stored',
          }



path = '../export/'
try:
    os.mkdir(path)
except:
    1+1

with ZipFile(path+'platformpower.zip', 'w') as zip:
    for f in ['promotions.csv', 'promotions.pdf',
              'panel.csv', 'panel.pdf',
              'playlists.csv', 'playlists.pdf', 
              'playlist-categories.csv', 'playlist-categories.pdf',
              'top_artists.csv', 'top_artists.pdf',
              'top_artists_placements.csv', 'top_artists_placements.pdf',
              'placements-selected-only.csv', 'placements-selected-only.pdf']: 
        print('zipping ' + f + '...\n')
        zip.write(path+f, os.path.basename(f), compress_type=compression)
