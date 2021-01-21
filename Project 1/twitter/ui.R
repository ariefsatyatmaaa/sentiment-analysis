#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

ui <- dashboardPage(
    
    dashboardHeader(title = "Sentimen Analysis"
    ),
    
    dashboardSidebar(
        width = 300,
        textInput(
            "searchTweet",
            "Masukkan topic yang dicari",
            "blackpink",
        ),
        sliderInput("maxTweet",
                    "Jumlah tweet yang akan dianalisis",
                    min = 100,
                    max = 500,
                    value = 100
        ),
        fluidPage(
            submitButton(text="Analysis Now!")
        )
    ),
    dashboardBody(
        fluidRow(
            box(
                title = "Sentimen Tweets",
                solidHeader = T,
                width = 12,
                collapsible = T,
                tableOutput("tableSentiment")
            ),
        ),
        fluidRow(
            box(title = "Wordcloud",
                solidHeader = T,
                width = 12,
                collapsible = T,
                plotOutput("wordCount")
            ),
        ),
        fluidRow(
            box(title = "Percentage",
                textOutput("positive"),
                textOutput("negative"),
                solidHeader = T,
                width = 12,
                collapsible = T,
                plotOutput("piePlot"),
            ),
        ),
    )
)