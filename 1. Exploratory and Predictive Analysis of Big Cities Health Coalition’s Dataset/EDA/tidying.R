library(tidyverse)
bchi <- read_csv("../Data/BCHI-dataset_2019-03-04.csv")

# Removing extra Rows that are not needed.

bchi <- bchi[1:7]
names(bchi)

# Tidying up the data
bchi <- bchi %>%
  mutate(Num = row_number())
bchi
bchi_tidy <- bchi %>%
  spread(Indicator, Value)
head(bchi_tidy)

# Removing Years 2017 and 2018
bchi_tidy2 <- bchi_tidy %>%
  filter(!Year == '2017') %>%
  filter(!Year == '2018')

bchi_tidy2 %>%
  ggplot(aes(`Year`, `Heart Disease Mortality Rate (Age-Adjusted; Per 100,000 people)`)) + geom_col() + coord_flip()

names(bchi_tidy2)
  
