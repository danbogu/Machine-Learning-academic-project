source("functions_part1.R")
library("plyr")
library("tidyverse")
library("corrplot")
library("ggplot2")
library("gridExtra")
library("ggpubr")
library("DataExplorer")
library("Amelia")
#library(ModelMetrics)

# Data load ---------------------------------------------------------------

preds<-read.csv(file="preds_sample.csv") %>% as_tibble()
train<-read.csv(file="Xy_train.csv") %>% as_tibble()
test<-read.csv(file="X_test.csv") %>% as_tibble()

# Basic data exploration ---------------------------------------------------------------

introduce(train) # general intro to the data
missmap(train) # no missing values
anyNA(train) #False
anyNA(test) #False

#Features:
categorial_fetures <- c("gender","cp","fbs","restecg","exang","thal","ca","slope")
numerical_features <- c("age", "trestbps", "chol", "thalach", "oldpeak")

train <- update_columns(train, c("y", categorial_fetures), 
                        as.factor)


# target label prior prob -------------------------------------

ggplot(train, aes(x = y)) +
  geom_bar()

y_prior <- sum(train$y == 1) / nrow(train)
y_prior # balanced data


# Feature distributions -------------------------------------------------------

train %>% 
  select(numerical_features)  %>%
  plot_histogram()
#age has extreme values that make it's distribution off - need to fix


train %>% 
  select(categorial_fetures) %>%
  plot_bar()
#no categorical features with high cardinality which is good

# Fix abnormal ages -------------------------------------------------------

train_low_ages <- train %>% 
  filter(age < 80) #remove abnormanl samples


###Linear model
age_lm <- lm(age~.-id, train_low_ages) 
summary(age_lm) #we dont have too many significant vars. low R-sqr.
####Make categorial vars as factors

train_high_ages <- train %>% 
  filter(age > 80) 

###Predictions:
train_high_ages$age <- predict(age_lm, newdata = train_high_ages)

train_v2 <- rbind(train_low_ages, train_high_ages)



# Distrubition across test / train sets -------------------------------------------------------

grouped_data <- train_v2 %>% 
  select(-y) %>%
  mutate(type = "train") %>%
  rbind(test %>% 
          mutate(type = "test"))


ggarrange(
ggplot(grouped_data, aes(x = age)) +
  geom_density(aes(fill = type), alpha = 0.5),

ggplot(grouped_data, aes(x = trestbps)) +
  geom_density(aes(fill = type), alpha = 0.5),

ggplot(grouped_data, aes(x = oldpeak)) +
  geom_density(aes(fill = type), alpha = 0.5),

ggplot(grouped_data, aes(x = thalach)) +
  geom_density(aes(fill = type), alpha = 0.5),

ggplot(grouped_data, aes(x = chol)) +
  geom_density(aes(fill = type), alpha = 0.5))

ggarrange(
ggplot(grouped_data, aes(x = type)) +
  geom_bar(aes(fill = gender), position = "fill", alpha = 0.5),

ggplot(grouped_data, aes(x = type)) +
  geom_bar(aes(fill = cp), position = "fill", alpha = 0.5),

ggplot(grouped_data, aes(x = type)) +
  geom_bar(aes(fill = fbs), position = "fill", alpha = 0.5),

ggplot(grouped_data, aes(x = type)) +
  geom_bar(aes(fill = restecg), position = "fill", alpha = 0.5),

ggplot(grouped_data, aes(x = type)) +
  geom_bar(aes(fill = exang), position = "fill", alpha = 0.5),

ggplot(grouped_data, aes(x = type)) +
  geom_bar(aes(fill = thal), position = "fill", alpha = 0.5),

ggplot(grouped_data, aes(x = type)) +
  geom_bar(aes(fill = ca), position = "fill", alpha = 0.5),

ggplot(grouped_data, aes(x = type)) +
  geom_bar(aes(fill = slope), position = "fill", alpha = 0.5)
)  



# Correlation with target variable ----------------------------------------
ggarrange(
risk_plot(category_risk_df(train_v2$y == 1,
                           train_v2$age,
                           prior = y_prior), 
          prior = y_prior, class_labels =c("true","false")),

ggplot(train_v2, aes(x = age, fill = y)) +
  geom_density(alpha = 0.5),

#age sepeates nicely between the two classes, and has higher likelihood for 0 as age increases (until 61)

risk_plot(category_risk_df(train_v2$y == 1,
                           train_v2$trestbps,
                           prior = y_prior), 
          prior = y_prior, class_labels =c("true","false")),
ggplot(train_v2, aes(x = trestbps, fill = y)) +
  geom_density(alpha = 0.5)
)

#resting blood preassure does not seperate well between classes 

ggarrange(
risk_plot(category_risk_df(train_v2$y == 1,
                           train_v2$chol,
                           prior = y_prior), 
          prior = y_prior, class_labels =c("true","false")),
ggplot(train_v2, aes(x = chol, fill = y)) +
  geom_density(alpha = 0.5),

#cholestrol does not seperate too well by itself - maybe as a combination with other features?

risk_plot(category_risk_df(train_v2$y == 1,
                           train_v2$oldpeak,
                           prior = y_prior), 
          prior = y_prior, class_labels =c("true","false")),
ggplot(train_v2, aes(x = oldpeak, fill = y)) +
  geom_density(alpha = 0.5))

#pldpeak (ST depression induced by exercise) looks very correlative with class and seperates well - high values likelihood for 0 is larger


ggarrange(
risk_plot(category_risk_df(train_v2$y == 1,
                           train_v2$thalach,
                           prior = y_prior), 
          prior = y_prior, class_labels =c("true","false")),
ggplot(train_v2, aes(x = thalach, fill = y)) +
  geom_density(alpha = 0.5))

#thalach (maximum heart rate achieved) looks like a very good feature sepearting between classes

#Categorical features

ggarrange(
(risk_plot(category_risk_df(train_v2$y == 1,
                           train_v2$gender,
                           prior = y_prior), 
          prior = y_prior, class_labels =c("true","false")) + labs(x = "gender")),
#gender looks like a good seperator, females are more likely to get class 1

(risk_plot(category_risk_df(train_v2$y == 1,
                           train_v2$cp,
                           prior = y_prior), 
          prior = y_prior, class_labels =c("true","false")) + labs(x = "cp")),
#cp different catrgories look like a good sepeator, but we can see it's not ordinal in nature 

(risk_plot(category_risk_df(train_v2$y == 1,
                           train_v2$fbs,
                           prior = y_prior), 
          prior = y_prior, class_labels =c("true","false")) + labs(x = "fbs")),

#fbs does not look like a good seperator between classes


(risk_plot(category_risk_df(train_v2$y == 1,
                           train_v2$restecg,
                           prior = y_prior), 
          prior = y_prior, class_labels =c("true","false")) + labs(x = "restecg"))
#restecg looks like a good seperator but risk is not linear

)

ggarrange(
risk_plot(category_risk_df(train_v2$y == 1,
                           train_v2$exang,
                           prior = y_prior), 
          prior = y_prior, class_labels =c("true","false")) + labs(x = "exang"),
#good feature, ordinal in risk

risk_plot(category_risk_df(train_v2$y == 1,
                           train_v2$slope,
                           prior = y_prior), 
          prior = y_prior, class_labels =c("true","false")) + labs(x = "slope"),
#good feature, ordinal in risk

risk_plot(category_risk_df(train_v2$y == 1,
                           train_v2$ca,
                           prior = y_prior), 
          prior = y_prior, class_labels =c("true","false")) + labs(x = "ca"),
#good feature, ordinal in risk (except 4 which is "missing" value)

risk_plot(category_risk_df(train_v2$y == 1,
                           train_v2$thal,
                           prior = y_prior), 
          prior = y_prior, class_labels =c("true","false")) + labs(x = "thal")
#categories have different risk, but the risk is not ordinal
)


# Scatter plots - two variable correlations with target -------------------

ggarrange(
  ggplot(train_v2, aes(x = trestbps, y = chol)) +
    geom_point(aes(color = y)),
  #high chol & high trestbps >> higher likelihood for 0
  
  ggplot(train_v2, aes(x = trestbps, y = oldpeak)) +
    geom_point(aes(color = y)),
  
  #high oldpeak & high trestbps >> higher likelihood for 0
  
  ggplot(train_v2, aes(x = trestbps, y = thalach)) +
    geom_point(aes(color = y)),
  
  #low thalach & low trestbps >> higher likelihood for 0
  
  ggplot(train_v2, aes(x = age, y = chol)) +
    geom_point(aes(color = y)))

#high age and high chol >> higher likelihood for 0

# information gain --------------------------------------------------------

#Information gain (IG) measures how much “information” a feature gives us about the class.

features_ig <- c(age = calc_info_gain(train_v2$y, train_v2$age),
                 thal = calc_info_gain(train_v2$y, train_v2$thal),
                 trestbps = calc_info_gain(train_v2$y, train_v2$trestbps),
                 ca = calc_info_gain(train_v2$y, train_v2$ca),
                 slope = calc_info_gain(train_v2$y, train_v2$slope),
                 exang = calc_info_gain(train_v2$y, train_v2$exang),
                 restecg = calc_info_gain(train_v2$y, train_v2$restecg),
                 fbs = calc_info_gain(train_v2$y, train_v2$fbs),
                 cp = calc_info_gain(train_v2$y, train_v2$cp),
                 gender = calc_info_gain(train_v2$y, train_v2$gender),
                 chol = calc_info_gain(train_v2$y, train_v2$chol),
                 oldpeak = calc_info_gain(train_v2$y, train_v2$oldpeak),
                 thalach = calc_info_gain(train_v2$y, train_v2$thalach)) %>% 
  enframe(name = "feature", value = "IG") %>%
  arrange(desc(IG))

features_ig

# Correlations ------------------------------------------------------------

train_v2 %>% 
  select(numerical_features) %>% 
  cor() %>% 
  corrplot()

# thalach vs. oldpeak are a bit correlated:
#When the max pulse is higher, the depression in the ST segment is lower


# Data cleanup ------------------------------------------------------------


#fbs have low information gain metric and also from the  plot look not very indicative, 
#so we can consider dropping it from the model

#we can also consider discretising chol feature based on external knowledge, making it a bit more relevant for the model

weak_features <- c("trestbps")

train_v3 <- train_v2 %>% 
  mutate(chol_disc = case_when(chol < 200 ~ 0,
                               chol < 240 ~ 1,
                               TRUE ~ 2),
         trestbps_disc = case_when(trestbps < 90 ~ 0,
                                   trestbps < 140 ~ 1,
                                   trestbps < 180 ~ 2,
                                   TRUE ~ 3
                                   )) %>%
  select(-weak_features)


ggarrange(
risk_plot(category_risk_df(train_v3$y == 1,
                           train_v3$chol_disc,
                           prior = y_prior), 
          prior = y_prior, class_labels =c("true","false")) + labs(x = "chol_disc"),

risk_plot(category_risk_df(train_v3$y == 1,
                           train_v3$trestbps_disc,
                           prior = y_prior), 
          prior = y_prior, class_labels =c("true","false")) + labs(x = "trestbps_disc")
)
  
calc_info_gain(train_v3$y, train_v3$trestbps_disc)
calc_info_gain(train_v3$y, train_v3$chol_disc)
