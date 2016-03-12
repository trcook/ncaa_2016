# this is a sample modeling scirpt

# expects training_data 
model<-glm(Team1win~Daynum,data=training_data,family='binomial')


#different modeling strategies
m1 <- train(win~Team1Seed+Team2Seed+Team1team.survscores+Team2team.survscores+Team1RPI+Team2RPI+Team1SOS+Team2SOS+Team1SOS+Team2SOS+Team1orank+Team2orank+Team1pagerank+Team2pagerank+Team1powerScore+Team2powerScore, data=training_data, method="glm")
m2 <- train(win~Team1Seed+Team2Seed+Team1team.survscores+Team2team.survscores+Team1RPI+Team2RPI+Team1SOS+Team2SOS+Team1SOS+Team2SOS+Team1orank+Team2orank+Team1pagerank+Team2pagerank+Team1powerScore+Team2powerScore, data=training_data, method="rf")
m3 <- train(win~Team1Seed+Team2Seed+Team1team.survscores+Team2team.survscores+Team1RPI+Team2RPI+Team1SOS+Team2SOS+Team1SOS+Team2SOS+Team1orank+Team2orank+Team1pagerank+Team2pagerank+Team1powerScore+Team2powerScore, data=training_data, method="glm")
m4 <- train(win~Team1Seed+Team2Seed+Team1team.survscores+Team2team.survscores+Team1RPI+Team2RPI+Team1SOS+Team2SOS+Team1SOS+Team2SOS+Team1orank+Team2orank+Team1pagerank+Team2pagerank+Team1powerScore+Team2powerScore, data=training_data, method="glm")
m5 <- train(win~Team1Seed+Team2Seed+Team1team.survscores+Team2team.survscores+Team1RPI+Team2RPI+Team1SOS+Team2SOS+Team1SOS+Team2SOS+Team1orank+Team2orank+Team1pagerank+Team2pagerank+Team1powerScore+Team2powerScore, data=training_data, method="glm")
m6 <- train(win~Team1Seed+Team2Seed+Team1team.survscores+Team2team.survscores+Team1RPI+Team2RPI+Team1SOS+Team2SOS+Team1SOS+Team2SOS+Team1orank+Team2orank+Team1pagerank+Team2pagerank+Team1powerScore+Team2powerScore, data=training_data, method="glm")

list.of.models <- list(m1, m2) #, m3, m4, m5, m6

predict.funk <- function(x){
  df <- data.frame(pred = predict(x, type="prob")[,2])
  df <- rename(df, c(pred = paste(x$method)))
  return(df)
}

mod.preds <- lapply(list.of.models, predict.funk) #predict winning for each model
df <- do.call("cbind", mod.preds)

#final blended model??
model <- train(win~., data=df, method="glm")

xvalidate<-data.table(test_data[,.(Team1,Team2,Season,Team1win)],yhat=round(predict(model,test_data,type = 'response')))

xvalidate[yhat!=Team1win,.N]/xvalidate[,.N]
# about 40% accuracy in cross validation

