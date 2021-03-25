getwd()

data <- read.csv('FIFA_Player_List.csv')
head(data)

#data preprocessing
overall.score <- data$Overall.Score
potential.socre <- data$Potential.Score
market.value <- data$Market.Value
weekly.salary <- data$Weekly.Salary
height <- data$Height
weight <- data$Weight
age <- data$Age
preferred.foot <- ifelse(data$Preferred.Foot == 'Left',1,0) #left = 1, right = 0
ball.skills <- data$Ball.Skills
defence <- data$Defence
mental <- data$Mental
passing <- data$Passing
physical <- data$Physical
shooting <- data$Shooting
goalkeeping <- data$Goalkeeping

data.copy1 <- cbind(data[2:8], preferred.foot, data[10:16])
head(data.copy1)

#visualization
par(mar=c(1,1,1,1))

par(mfrow = c(3,5))
#check for distribution
for (i in 1:15){
  hist(data.copy1[[i]], pch = 10, cex = .2)
}
#skewed: market value, weekly salary, ball skills, physical
#unbalanced: preferred foot, goalkeeping


#check for outliers: market value, weekly salary,mental, passing, physical,goalkeeping

for (i in 1:15){
  boxplot(data.copy1[[i]], pch = 10, cex = .2,axes = FALSE)
}

par(mfrow = c(1,1))

#correction
library(corrplot)
cor.all <- cor(data.copy1, method = 'spearman')
corrplot(cor.all, tl.col = "black", method = c("square"))


#multicollinearity
library(car)
fullmodel <- lm(market.value ~ preferred.foot + overall.score + potential.socre + weekly.salary + height + weight
   + age + ball.skills + defence + mental + passing  + shooting + goalkeeping)

summary(fullmodel)
vif <- vif(fullmodel)
multicollnearity <- vif[which(vif > 10)]

#remove variables of high multicollinearity (ball.skills, passing) 
#and remove insignificant variables: potential.score, height, passing, shooting, preferred foot
model.1 <- lm(market.value ~ overall.score + weekly.salary + weight +mental
                + age + defence + physical + goalkeeping)
summary(model.1)
#compared with the full model, the r^2 and ad.r^2 do not change too much

#variable transformation

log.market.value <- log(market.value)
log.weekly.salary <- log(weekly.salary)
log.physical <- log(physical)

model.2 <- lm(log.market.value ~ overall.score + log.weekly.salary + weight +mental
              + age + defence + goalkeeping)
summary(model.2)
#r^2 = 0.9656, ad.r^2 = 0.9656

#regularization
library(glmnet)
data.copy2 <- cbind(overall.score, log.weekly.salary, weight, age, defence, log.physical, goalkeeping)

#data.cpoy2 is the data we use for model selection

sum(abs(coef(model.2)[-1]))

#ridge
par(mfrow = c(1, 2))
model.ridge <- glmnet(data.copy2, log.market.value, alpha = 0)
summary(model.ridge)

plot(model.ridge, xvar = "lambda", label = TRUE)

#10 folds cross validation -- find the best lambda
ridge.cv <- cv.glmnet(data.copy2, log.market.value, alpha = 0)
par(mfrow = c(1, 1))
plot(ridge.cv)
optimal.lambda.ridge <- ridge.cv$lambda.min
optimal.lambda.ridge

model.ridge.opt <- glmnet(data.copy2, log.market.value, alpha = 0, lambda = optimal.lambda.ridge)
coef(model.ridge.opt)

#lasso
model.lasso <- glmnet(data.copy2, log.market.value, alpha = 1)
summary(model.lasso)

plot(model.lasso, xvar = "lambda", label = TRUE)

#10 folds cross validation -- find the best lambda
lasso.cv <- cv.glmnet(data.copy2, log.market.value, alpha = 1)
par(mfrow = c(1, 1))
plot(lasso.cv)
optimal.lambda.lasso <- lasso.cv$lambda.min
optimal.lambda.lasso

model.lasso.opt <- glmnet(data.copy2, log.market.value, alpha = 1, lambda = optimal.lambda.lasso)
coef(model.lasso.opt)


#### Ridge 
tLL <- model.ridge.opt$nulldev - deviance(model.ridge.opt)
k <- model.ridge.opt$df
n <- model.ridge.opt$nobs
AICc.r <- -tLL+2*k+2*k*(k+1)/(n-k-1)
BIC.r<-log(n)*k - tLL
AICc.r
BIC.r

#### Lasso
tLL <- model.lasso.opt$nulldev - deviance(model.lasso.opt)
k <- model.lasso.opt$df
n <- model.lasso.opt$nobs
AICc.l <- -tLL+2*k+2*k*(k+1)/(n-k-1)
BIC.l<-log(n)*k - tLL
AICc.l
BIC.l

AICc.r > AICc.l
BIC.r > BIC.l

################# Normalization
# dat <- data.frame(x = rnorm(10, 30, .2), y = runif(10, 3, 5))
# scaled.dat <- scale(dat)
# 
# # check that we get mean of 0 and sd of 1
# colMeans(scaled.dat)  # faster version of apply(scaled.dat, 2, mean)
# apply(scaled.dat, 2, sd)
#################

data.copy3 <- as.data.frame(data.copy2)
data.copy3$market.value <- log(market.value)

set.seed(1)
row.number <- sample(1:nrow(data.copy3), 0.8*nrow(data.copy3))
train = data.copy3[row.number,]
test = data.copy3[-row.number,]
dim(train)
dim(test)

## Train
model.lasso.opt.train <- glmnet(as.matrix(train[,1:7]), train$market.value, alpha = 1, lambda = optimal.lambda.lasso)
coef(model.lasso.opt.train)

#### Lasso
tLL <- model.lasso.opt.train$nulldev - deviance(model.lasso.opt.train)
k <- model.lasso.opt.train$df
n <- model.lasso.opt.train$nobs
AICc.l.train <- -tLL+2*k+2*k*(k+1)/(n-k-1)

AICc.l.train

predictions <- predict(model.lasso.opt.train, newx = as.matrix(test[,1:7]))
nrow(test$market.value)

test$predictions <- predictions
test$resid <- test$market.value  - test$predictions
test$std_error <- plotrix::std.error(test$predictions)

mselasso <- mean((test$market.value  - test$predictions)^2)

plot(test$resid, col = 'blue', type = 'p')

plot(test$market.value, test$predictions, col = 'blue')

plot(test$std_error, col = 'blue')

