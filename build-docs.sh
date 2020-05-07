cd docs
bash make.sh
CUR="`git branch | grep \"*\" | cut -c 2-`"
echo $CUR
VER="`python version.py`"
echo $VER
cd ../
git checkout gh-pages
rm -rf ./$VER/
rm -rf ./static
mv -T ./sphinx-docs ./$VER/
python restatic.py $VER
# mv -T ./$VER/_static ./$VER/static
git add -A
git commit -m "docs update, version $VER"
git push origin gh-pages
git checkout $CUR