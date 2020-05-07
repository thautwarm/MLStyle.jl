cd docs
bash make.sh
CUR="`git branch | grep \"*\" | cut -c 2-`"
echo $CUR
VER="`python version.py`"
echo $VER
cd ../
git checkout gh-pages
rm -rf ./$VER/
mv -T ./sphinx-docs ./$VER/
git add -A
git commit -m "docs update, version $VER"
git push origin gh-pages
git checkout $CUR