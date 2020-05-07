cd docs && bash make.sh
CUR=git branch | grep "*" | cut -c 2-
VER=python docs/version.py
git checkout gh-pages
git add -A
git commit -m "docs update, version $VER"
git push origin gh-pages
git checkout $CUR