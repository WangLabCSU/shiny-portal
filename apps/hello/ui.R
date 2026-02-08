library(shiny)

# 简洁漂亮的 WangLabCSU 团队 Landing Page
shinyUI(fluidPage(
  tags$head(
    tags$style(HTML("
      body {
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        min-height: 100vh;
        margin: 0;
      }
      .main-container {
        max-width: 1000px;
        margin: 0 auto;
        padding: 40px 20px;
      }
      .hero-card {
        background: white;
        border-radius: 20px;
        padding: 50px;
        box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        text-align: center;
      }
      .lab-title {
        font-size: 48px;
        font-weight: 700;
        color: #2d3748;
        margin-bottom: 10px;
        letter-spacing: -1px;
      }
      .lab-subtitle {
        font-size: 20px;
        color: #718096;
        margin-bottom: 30px;
      }
      .description {
        font-size: 16px;
        color: #4a5568;
        line-height: 1.8;
        margin-bottom: 30px;
        max-width: 600px;
        margin-left: auto;
        margin-right: auto;
      }
      .research-areas {
        display: flex;
        justify-content: center;
        flex-wrap: wrap;
        gap: 10px;
        margin: 30px 0;
      }
      .research-tag {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        padding: 8px 20px;
        border-radius: 25px;
        font-size: 14px;
        font-weight: 500;
      }
      .github-btn {
        display: inline-block;
        background: #24292e;
        color: white;
        padding: 15px 40px;
        border-radius: 30px;
        text-decoration: none;
        font-size: 16px;
        font-weight: 600;
        margin-top: 20px;
        transition: transform 0.2s, box-shadow 0.2s;
      }
      .github-btn:hover {
        transform: translateY(-2px);
        box-shadow: 0 10px 30px rgba(0,0,0,0.3);
        text-decoration: none;
        color: white;
      }
      .footer {
        margin-top: 40px;
        color: rgba(255,255,255,0.8);
        font-size: 14px;
      }
      .info-panel {
        background: #f7fafc;
        border-radius: 15px;
        padding: 20px;
        margin-top: 30px;
        text-align: left;
      }
      .info-title {
        font-size: 14px;
        font-weight: 600;
        color: #2d3748;
        margin-bottom: 10px;
      }
      .welcome-plot {
        margin: 30px 0;
        padding: 20px;
        background: linear-gradient(135deg, #f5f7fa 0%, #e4e8ec 100%);
        border-radius: 15px;
      }
      .welcome-plot h3 {
        color: #2d3748;
        margin-bottom: 20px;
      }
    "))
  ),
  
  div(class = "main-container",
    div(class = "hero-card",
      h1(class = "lab-title", "WangLabCSU"),
      p(class = "lab-subtitle", "Computational Biology & Bioinformatics"),
      
      p(class = "description", 
        "We are a research team at Central South University (CSU) dedicated to advancing computational biology, bioinformatics, and data science. Our mission is to develop innovative computational methods and tools for understanding complex biological systems."),
      
      div(class = "research-areas",
        div(class = "research-tag", "Cancer Genomics"),
        div(class = "research-tag", "Single-cell Analysis"),
        div(class = "research-tag", "Multi-omics Integration"),
        div(class = "research-tag", "Machine Learning")
      ),
      
      # Welcome Plot
      div(class = "welcome-plot",
        h3("Welcome to Our Lab!"),
        plotOutput("welcomePlot", height = "300px")
      ),
      
      tags$a(href = "https://github.com/WangLabCSU", 
             class = "github-btn",
             target = "_blank",
             "Visit Our GitHub"),
      
      # R Environment Info Panel
      div(class = "info-panel",
        div(class = "info-title", "R Environment Info"),
        verbatimTextOutput("envInfo")
      )
    ),
    
    div(class = "footer",
      p("© 2025 WangLabCSU | Central South University")
    )
  )
))
