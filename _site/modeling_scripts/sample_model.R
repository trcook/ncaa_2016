# this is a sample modeling scirpt

# expects training_data 
model<-glm(Team1win~Daynum,data=training_data,family='binomial')

xvalidate<-data.table(test_data[,.(Team1,Team2,Season,Team1win)],yhat=round(predict(model,test_data,type = 'response')))

xvalidate[yhat!=Team1win,.N]/xvalidate[,.N]
# about 40% accuracy in cross validation

