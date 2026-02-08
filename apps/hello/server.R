library(shiny)
library(ggplot2)

# Server 逻辑 - 显示欢迎图和环境信息
shinyServer(function(input, output) {
  
  # 使用 ggplot2 创建欢迎图
  output$welcomePlot <- renderPlot({
    # 创建欢迎文字数据
    welcome_data <- data.frame(
      x = c(1, 1, 1),
      y = c(3, 2, 1),
      label = c("Welcome to", "WangLabCSU", "Research Portal"),
      size = c(8, 12, 6),
      color = c("#667eea", "#764ba2", "#4a5568")
    )
    
    # 创建装饰性数据点
    set.seed(42)
    n_points <- 50
    decor_data <- data.frame(
      x = runif(n_points, 0, 2),
      y = runif(n_points, 0, 4),
      alpha = runif(n_points, 0.1, 0.4)
    )
    
    ggplot() +
      # 背景装饰点
      geom_point(data = decor_data, aes(x = x, y = y, alpha = alpha),
                 color = "#667eea", size = 3) +
      # 欢迎文字
      geom_text(data = welcome_data, 
                aes(x = x, y = y, label = label, size = size, color = color),
                fontface = "bold", family = "sans") +
      scale_size(range = c(10, 25), guide = "none") +
      scale_color_identity() +
      scale_alpha(guide = "none") +
      coord_cartesian(xlim = c(0, 2), ylim = c(0, 4)) +
      theme_void() +
      theme(
        plot.background = element_rect(fill = "transparent", color = NA),
        panel.background = element_rect(fill = "transparent", color = NA)
      )
  }, bg = "transparent")
  
  # 显示 R 环境信息，包括 renv 配置
  output$envInfo <- renderPrint({
    cat("R version:", R.version.string, "\n\n")
    
    # 检查 renv
    renv_installed <- requireNamespace("renv", quietly = TRUE)
    cat("renv installed:", renv_installed, "\n")
    
    if (renv_installed) {
      cat("renv version:", as.character(packageVersion("renv")), "\n")
    }
    
    # 检查 RENV_PATHS_ROOT
    renv_root <- Sys.getenv("RENV_PATHS_ROOT")
    cat("\nRENV_PATHS_ROOT:", ifelse(renv_root == "", "(not set)", renv_root), "\n")
    
    # 检查 renv-libs 目录
    if (renv_root != "" && dir.exists(renv_root)) {
      cat("renv-libs directory exists: YES\n")
      # 列出目录内容
      dirs <- list.dirs(renv_root, recursive = FALSE, full.names = FALSE)
      if (length(dirs) > 0) {
        cat("Contents:", paste(head(dirs, 5), collapse = ", "), "\n")
      } else {
        cat("Contents: (empty)\n")
      }
    } else if (renv_root != "") {
      cat("renv-libs directory exists: NO\n")
    }
    
    cat("\nLibrary paths:\n")
    for (lib in .libPaths()) {
      cat("  -", lib, "\n")
    }
  })
})
