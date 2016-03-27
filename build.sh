hexo clean
hexo g -d
cd ./public #生成的静态页面会存储在public目录下
#git init
git add --all .
git commit -m "Travis CI Auto Builder" #自动构建后的内容将全部以此信息提交
git push --quiet --force https://$DEPLOY_REPO@github.com/magicse7en/magicse7en.github.io.git master  #自动构建后的内容将全部以此信息提交
#curl --connect-timeout 20 --max-time 30 -s http://远端服务器URL/webhook.php?_=${NOTIFY_TOKEN} #服务器Webhook 将在下文介绍
