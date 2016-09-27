cd ~
cd ppi18n
# get latest code
echo ""
echo "==== get latest strings: start ==="
git checkout master
git fetch
git pull
GIT_NUMBER=`git rev-list head | sort | wc -l | awk '{print $1}'`
echo "GIT_NUMBER:"${GIT_NUMBER}
echo "=== get latest strings: finish ==="
echo ""

echo "==== git commit: start ==="
git add .
git commit -m "ios language"
git push
echo "==== git commit: finish ==="
echo ""
cd ~

source ~/sync_uplive_strings/sync_uplive_strings.sh





