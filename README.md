# Predicting-FIFA-player-market-value
Used regularization techniques Lasso and Ridge to determine the most accurate model 

I started the analysis by using histograms and boxplots to visualize the distributions of the dataset. 
Then, I transformed variables using different methods: 
  1. Identified highly skewed variables and took their log (for eg: Goalkeeping and Weekly Salary) 
  2. Created dummy variables for categorical data (Preferred foot)
  3. Plotted the correlation of all variables to identify highly correlated variables and discarded some of them.

For feature selection, I built the full model which contains all the dependent variables (already transformed and cleaned) 
Checked for the significance levels and multicollinearity for each variable and dropped variables of no or little significance
Also removed some variables with high multicollinearity.
Then created the reduced model and ensured that all variables were significant and there was no strong multicollinearity.

For model selection, applied ridge and lasso regularization terms to the reduced model (glmnet function)
Then used cross validation (cv.glmnet function) to find out the optimal lambda for each regularization. 
Next chose the lasso regularization based on AICc and BIC values.
To evaluate model accuracy, split the dataset into test (20%) and train(80%) and predicted the market values using our test data.

Conclusion:
1. For model improvement, could add another parameter like ‘Player_Popularity’ as a dummy variable to indicate how popularity of certain player (For eg: Lionel Messi) could also lead to a higher market value
2. normalizing the dependant variable could lead to better predictions for outliers in the dataset
3. another option could be adding multiple layers of lasso regression to existing model to arrive at the least number of ideal variables to predict the player market value
