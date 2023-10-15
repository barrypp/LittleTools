import os
import re
from pathlib import Path

p = Path('data6')
info1 = re.compile(r'Biomega ([0-9]+)')
info2 = re.compile(r'Biomega-([0-9]+)')

for x in p.rglob('*.*'):
    i1 = info1.search(str(x.parent))
    i2 = info2.search(x.name)
    vol = i1.group(1)
    page = i2.group(1)
    print(x,p/('Biomega-v'+vol+'-p'+page+x.suffix))
    x.rename(p/('Biomega-v'+vol+'-p'+page+x.suffix))
    