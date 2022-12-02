### ------------------- EDS 222 Final Project ------------------- ###
### Identifying key traits in Hawaiian fish to predict risk of extinction ###

# Load libraries
library(rfishbase)
library(tidyverse)
library(janitor)
library(jsonlite)
library(rredlist)
library(broom)

# Set data export location
datadir <- "/Users/elkewindschitl/Documents/MEDS/eds-222/final-proj/data"

### ------------------------ Stats Analysis ------------------------  ###

tidy_fish_data <- read_csv(file.path(datadir, "hi_tidy_fish_data.csv"))

# Here I look at each piece individually, then combine them together later

rm_len_na <- tidy_fish_data %>% 
  filter(!length_cm == "NA")

# Graph length vs is of concern
gg_len <- ggplot(data = rm_len_na, aes(x = length_cm, y = is_of_concern)) +
  geom_jitter(width = 0, height = 0.05, alpha = 0.8, col = "#38b6ba") +
  labs(x = "Species average length", y = "Listed as a concern") +
  theme_minimal()
gg_len

# Log regression length
mod_length <- glm(is_of_concern ~ length_cm, 
                  data = rm_len_na, 
                  family = "binomial")
summary(mod_length)

# Plot with regression
len_data_space <- gg_len +
  geom_smooth(method = "glm", 
              se = FALSE, color = "#545454", 
              method.args = list(family = "binomial"))
len_data_space





# Run this again, but remove large values to evaluate robustness
rm_outliers <- rm_len_na %>% 
  filter(length_cm <= 1000)

# Graph length vs is of concern
gg_rm_out <- ggplot(data = rm_outliers, aes(x = length_cm, y = is_of_concern)) +
  geom_jitter(width = 0, height = 0.05, alpha = 0.8, col = "#38b6ba") +
  labs(x = "Species average length", y = "Listed as a concern") +
  theme_minimal()
gg_rm_out

# Log regression length
mod_rm_out <- glm(is_of_concern ~ length_cm, 
                  data = rm_outliers, 
                  family = "binomial")
summary(mod_rm_out)

# Plot with regression
len_rm_out_plot <- gg_len +
  geom_smooth(method = "glm", 
              se = FALSE, color = "#545454", 
              method.args = list(family = "binomial"))
len_rm_out_plot






# Make bins
len_breaks <- rm_len_na %>%
  pull(length_cm) %>%
  quantile(probs = 0:10/10)

len_binned_space <- len_data_space + 
  stat_summary_bin(
    fun = "mean", color = "red", 
    geom = "line", breaks = len_breaks
  )

len_binned_space

# Compute fitter probabilities, then graph
length_plus <- mod_length %>%
  augment(type.predict = "response") %>%
  mutate(y_hat = .fitted)
ggplot(length_plus, aes(x = length_cm, y = y_hat)) +
  geom_point() +
  geom_line() +
  scale_y_continuous("Probabilities of being threatened", 
                     limits = c(0,1))

# Compute odds scale and graph it
length_plus <- length_plus %>% 
  mutate(odds_hat = y_hat / (1 - y_hat)) %>% 
  filter(length_cm <= 1000) # remove outliers for graphing
ggplot(length_plus, aes(x = length_cm, y = odds_hat)) +
  geom_point() + 
  geom_line() + 
  scale_y_continuous("Odds of being threatened")

# Pull B1
len_b1 <- mod_length$coefficients[2]
len_odds_ratio <- exp(len_b1)
print(paste0("The model suggests that each additional cm in length is associated with a ",
             round(len_odds_ratio, 1), "% increase in the odds of being threatened"))

# Compute log-odds and graph it
length_plus <- length_plus %>% 
  mutate(log_odds_hat = log(odds_hat))
ggplot(length_plus, aes(x = length_cm, y = log_odds_hat)) +
  geom_point() + 
  geom_line() + 
  scale_y_continuous("Log(odds) of being threatened")

# Create confusion matrix to see how well the model performed
length_plus <- augment(mod_length, type.predict = "response") %>%
  mutate(threatened_hat = round(.fitted)) %>%
  select(is_of_concern, length_cm, .fitted, threatened_hat)
l_tab <- length_plus %>%
  select(is_of_concern, threatened_hat) %>%
  table()
l_tab

acc <- (l_tab[1,1] + l_tab[2,2]) / nrow(length_plus) * 100
print(paste0("The accuracy of this model was ", round(acc), "%")) # BUT it seems to be more accurate in predicting species that are not actually of concern. Species that are actually threatened have poorer prediction rates... how important is this?






# Add reef association to the model
tidy_no_na <- rm_len_na %>% 
  filter(!coral_reefs == "NA")

len_reef_mod <- glm(is_of_concern ~ length_cm + reef_associated,
                    data = tidy_no_na,
                    family = "binomial")
len_reef_mod
print(paste0("Fish that are reef associated see their odds of being threatened decrease by a factor of ", -round(len_reef_mod$coefficients[3], 2), " after controlling for length"))

# Create confusion matrix to see how well the model performed
length_reef_plus <- augment(len_reef_mod, type.predict = "response") %>%
  mutate(threatened_hat = round(.fitted)) %>%
  select(is_of_concern, length_cm, reef_associated, .fitted, threatened_hat)
l_r_tab <- length_reef_plus %>%
  select(is_of_concern, threatened_hat) %>%
  table()
l_r_tab # Adding reef did nothing





# Add endemism to the original length model
len_end_mod <- glm(is_of_concern ~ length_cm + is_endemic,
                   data = rm_len_na,
                   family = "binomial")
summary(len_end_mod)
print(paste0("Fish that are endemic see their odds of being threatened increase by a factor of ", round(len_end_mod$coefficients[3], 2), " after controlling for length"))

# Create confusion matrix to see how well the model performed
length_end_plus <- augment(len_end_mod, type.predict = "response") %>%
  mutate(threatened_hat = round(.fitted)) %>%
  select(is_of_concern, length_cm, is_endemic, .fitted, threatened_hat)
l_e_tab <- length_end_plus %>%
  select(is_of_concern, threatened_hat) %>%
  table()
l_e_tab # Adding endemism did nothing








rm_ra_na <- tidy_fish_data %>% 
  filter(!coral_reefs == "NA")

# Plot reef associated vs is of concern 
gg_reef <- ggplot(data = rm_ra_na, aes(x = reef_associated, y = is_of_concern)) +
  geom_jitter(width = 0.05, height = 0.05, alpha = 0.8, col = "#38b6ba") +
  labs(x = "Reef Associated", y = "Listed as a concern") +
  theme_minimal()
gg_reef

# Log regression reefs -- does this even make sense to do?
mod_reef <- glm(is_of_concern ~ reef_associated, 
                data = rm_ra_na, 
                family = "binomial")
summary(mod_reef)

# Plot endemism vs is of concern
gg_status <- ggplot(data = tidy_fish_data, aes(x = is_endemic, y = is_of_concern)) +
  geom_jitter(width = 0.05, height = 0.05, alpha = 0.8, col = "#38b6ba") +
  labs(x = "Endemic", y = "Listed as a concern") +
  theme_minimal()
gg_status

# Log regression of endemism -- does this even make sense to do?
mod_status <- glm(is_of_concern ~ is_endemic, 
                  data = tidy_fish_data, 
                  family = "binomial")
summary(mod_status)

# I don't think these last two are correct... ask!!!

# Combining it all together (even though)
mod <- glm(is_of_concern ~ length_cm + reef_associated + is_endemic,
           data = tidy_no_na,
           family = "binomial")
summary(mod)

# Pull out all coefficients
b0 <- mod$coefficients[1] #Intercept
b1 <- mod$coefficients[2] #Length
b2 <- mod$coefficients[3] #Reef Associated
b3 <- mod$coefficients[4] #Endemic

# Run some test probabilities 
equ <- b0 + b1 * 700  + b2 + b3
p_700_1_1 <- (exp(equ)) / (1 + exp(equ))

equ20 <- b0 + b1 * 20  + b2 + b3
p_20_1_1 <- (exp(equ20)) / (1 + exp(equ20))

equ450 <- b0 + b1 * 450  + b2 + b3
p_450_1_1 <- (exp(equ450)) / (1 + exp(equ450))

# Write a function for testing probabilities
threat_prob <- function(b0, b1, b2, b3, len, reef, end) {
  equ <- b0 + b1 * len + b2 * reef + b3 * end
  prob <- (exp(equ)) / (1 + exp(equ))
  print(prob)
}
# Test
threat_prob(b0, b1, b2, b3, 700, 1, 1)
threat_prob(b0, b1, b2, b3, 20, 1, 1)
threat_prob(b0, b1, b2, b3, 450, 1, 1)

# Attempt some t-tests???
t.test(is_of_concern ~ reef_associated, data = rm_ra_na)
t.test(is_of_concern ~ is_endemic, data = tidy_fish_data)











