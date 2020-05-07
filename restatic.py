import sys
import os
ver, orig, target = sys.argv[1:4]
from bs4 import BeautifulSoup
def predicate(x: str):
    return x and x.startswith(orig)
for dirpath, _, files in os.walk(ver):
    for each in files:
        if not each.endswith('.html'):
            continue
        each = os.path.join(dirpath, each)
        with open(each) as f:
            bs = BeautifulSoup(f.read())
            for tag in bs.find_all(attrs={'src': predicate}):
                tag['src'] = target + tag['src'][len(orig):]

            for tag in bs.find_all(attrs={'href': predicate}):
                tag['href'] = target + tag['href'][len(orig):]
        with open(each, 'w') as f:
            f.write(str(bs))
