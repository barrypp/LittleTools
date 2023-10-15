import os
import re
import time
from datetime import datetime, timedelta
from pathlib import Path

import piexif

info = re.compile(r'\(v([0-9]+)\) - p([0-9]+)')
#info = re.compile(r' - c([0-9]+).+ - p([0-9]+)')
p = Path('data3')
count = 0

for x in p.rglob('*.*'):
    #
    i = info.search(x.name)
    hour = int(i.group(1))
    num = int(i.group(2))
    t = datetime(2019,1,1) + timedelta(seconds=num,hours=hour)
    #
    if x.suffix == '.jpg':
        exif_dict = piexif.load(str(x))
        exif_dict['Exif'][piexif.ExifIFD.DateTimeDigitized] = t.strftime('%Y:%m:%d %H:%M:%S')
        exif_dict['Exif'][piexif.ExifIFD.DateTimeOriginal] = t.strftime('%Y:%m:%d %H:%M:%S')
        piexif.insert(piexif.dump(exif_dict), str(x))
    #
    os.utime(x,(t.timestamp(),t.timestamp()))
    #  
    count += 1
    print(count,x.name)
