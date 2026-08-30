# options(shiny.maxRequestSize = 1024 * 1024^2)  # 设置最大上传文件大小为 1024MB
# # options(shiny.autoreload = TRUE) # 有改动即自动更新,不是更新选项的,是更新js啥的
# options(bitmapType = "cairo") # Linux 服务器用 Cairo 引擎来画图
# pdf(NULL) # 把找不到屏幕、偷偷摸摸生成的图扔进黑洞

options(PERCEPTIONx.cache_root = "/databases/perceptionx_db")
#remotes::install_git("https://ghfast.top/https://github.com/WangLabCSU/PERCEPTIONx")
library(PERCEPTIONx)
run_perception_app()

