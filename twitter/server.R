#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
server <- function(input, output) {
    
    sentiment.final <- reactive({
        # Scrapping tweet
        print(input$searchTweet)
        print(input$maxTweet)
        tweet.results <- searchTwitter(input$searchTweet, n = input$maxTweet, lang = "en")
        tweet.df <- twListToDF(tweet.results)
        tweet.df <- data.frame(tweet.df['text'])
        # Membersihkan character yang tidak diperlukan
        tweet.df$text = str_replace_all(tweet.df$text, "[\\.\\,\\;]+", " ")
        tweet.df$text = str_replace_all(tweet.df$text, "http\\w+", "")
        tweet.df$text = str_replace_all(tweet.df$text, "@\\w+", " ")
        tweet.df$text = str_replace_all(tweet.df$text, "[[:punct:]]", " ")
        tweet.df$text = str_replace_all(tweet.df$text, "[[:digit:]]", " ")
        tweet.df$text = str_replace_all(tweet.df$text, "^ ", " ")
        tweet.df$text = str_replace_all(tweet.df$text, "[<].*[>]", " ")
        
        sentiment.score <- sentiment(tweet.df$text)
        sentiment.score <- sentiment.score %>% group_by(element_id) %>% summarise(sentiment = mean(sentiment))
        
        tweet.df$polarity <- sentiment.score$sentiment
        tweet.final <- tweet.df[, c('text', 'polarity')]
        
        tweet.final <- tweet.final[tweet.final$polarity != 0, ]
        tweet.final$sentiment <- ifelse(tweet.final$polarity < 0, "Negative", "Positive")
        tweet.final$sentiment <- as.factor(tweet.final$sentiment)
        
        tweet.balanced <- upSample(x = tweet.final$text, y = tweet.final$sentiment)
        names(tweet.balanced) <- c('text', 'sentiment')
        
        tweet.final$id <- seq(1, nrow(tweet.final))
        
        # Document Term Matrix
        get.dtm <- function(text.col, id.col, input.df, weighting) {
            
            # removing emoticon
            input.df$text <- gsub("[^\x01-\x7F]", "", input.df$text)
            
            # preprocessing text
            corpus <- VCorpus(DataframeSource(input.df))
            corpus <- tm_map(corpus, removePunctuation)
            corpus <- tm_map(corpus, removeNumbers)
            corpus <- tm_map(corpus, stripWhitespace)
            corpus <- tm_map(corpus, removeWords, stopwords("english"))
            corpus <- tm_map(corpus, content_transformer(tolower))
            
            dtm <- DocumentTermMatrix(corpus, control = list(weighting = weighting))
            return(list(
                "termMatrix" = dtm,
                "corpus" = corpus
            ))
        }
        
        colnames(tweet.final)[4] <- "doc_id"
        dtm <- get.dtm('text', 'id', tweet.final, "weightTfIdf")
        corpus <- dtm$corpus
        dtm <- dtm$termMatrix
        dtm.mat <- as.matrix(dtm)
        
        # Using Naive Bayes
        model <- naive_bayes(x = dtm.mat, y = tweet.final$sentiment, usekernel = TRUE)
        
        # predict using model
        preds <- predict(model, newdata = dtm.mat, type = "class")
        
        return(list(
            "tweet_final" = tweet.final,
            "prior" = model$prior,
            "word" = corpus
        ))
    })
    
    #output
    x <- reactive({
        x <- c(sentiment.final()$prior[['Negative']], sentiment.final()$prior[['Positive']])
    })
    labels <- c("Negative", "Positive")
    output$piePlot <- renderPlot({
        pie3D(x(), labels = labels, explode = 0.1, main = "Perbandingan Sentiment dalam Bentuk Pie")
    })
    output$negative <- renderText(
        paste("Negative : ", 
              toString(floor(sentiment.final()$prior[['Negative']] * 100)), "%", sep = "")
    )
    output$positive <- renderText(
        paste("Positive : ", 
              toString(floor(sentiment.final()$prior[['Positive']] * 100)),  "%", sep = "")
    )
    output$wordCount <- renderPlot({
        wordcloud(
            sentiment.final()$word,
            random.offer = 'F',
            max.words = 1000,
            col = rainbow(1000),
            main="wordCount",
        )
    })
    sentimentPerTweet <- reactive({
        sentimentPerTweet <- sentiment.final()$tweet_final %>% select('text', 'sentiment')
    })
    
    output$tableSentiment <- renderTable(
        sentimentPerTweet()
    )
}