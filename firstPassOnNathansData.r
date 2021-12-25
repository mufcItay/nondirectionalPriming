
library(tidyverse);
library(ggplot2);

df <- read.table('data/data_long.tsv', sep = '\t', header = TRUE)

df <- df %>%
  filter(cue != 'no' & cor==1) %>%
  mutate( cue = factor(cue),
          cong = ifelse(cong=='cong',1,0)) %>%
  rename(subj_id=suj) %>%
  group_by(subj_id) %>%
  mutate(trial_number = seq(1,n()))

df %>%
  group_by(subj_id,cue,cong) %>%
  summarise(median_RT=median(rt)) %>%
  spread(cong,median_RT,sep='') %>%
  rowwise() %>%
  mutate(congruency_effect=cong0-cong1) %>%
  ggplot(aes(x=congruency_effect)) +
  geom_histogram() +
  facet_wrap(~cue,nrow=3)

