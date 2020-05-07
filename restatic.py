import sys
import os
ver = sys.argv[1]
# from bs4 import BeautifulSoup
# def predicate(x: str):
#     return x and "_static/" in x
# for dirpath, _, files in os.walk(ver):
#     for each in files:
#         if not each.endswith('.html'):
#             continue
#         each = os.path.join(dirpath, each)
#         with open(each) as f:
#             bs = BeautifulSoup(f.read())
#             for tag in bs.find_all(attrs={'src': predicate}):
#                 tag['src'] = tag['src'].replace("_static/", "static/")

#             for tag in bs.find_all(attrs={'href': predicate}):
#                 tag['href'] = tag['href'].replace("_static/", "static/")
#         with open(each, 'w') as f:
#             f.write(str(bs))

with open(f'{ver}/_static/bootstrap-sphinx.css') as f:
    src = f.read()

with open(f'{ver}/_static/bootstrap-sphinx.css', 'w') as f:
    f.write(src.replace("Readable", 'readable'))