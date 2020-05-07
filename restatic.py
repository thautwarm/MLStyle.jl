import sys
import os
ver = sys.argv[1]
from bs4 import BeautifulSoup
def predicate(x: str):
    return x and x.startswith("_static/")
for dirpath, _, files in os.walk(ver):
    for each in files:
        if not each.endswith('.html'):
            continue
        each = os.path.join(dirpath, each)
        with open(each) as f:
            bs = BeautifulSoup(f.read())
            for tag in bs.find_all(attrs={'src': predicate}):
                tag['src'] = "static/" + tag['src'][len("_static/"):]

            for tag in bs.find_all(attrs={'href': predicate}):
                tag['href'] = "static/" + tag['href'][len("_static/"):]
        with open(each, 'w') as f:
            f.write(str(bs))
