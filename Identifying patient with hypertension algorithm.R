knitr::opts_chunk$set(echo = TRUE, message = FALSE)
library(DT)
library(tidyverse)
library(magrittr)
library(bigrquery)
library(caret)
library(stringr)
library(purrr)

con <- DBI::dbConnect(drv = bigquery(),
                      project = "learnclinicaldatascience", dataset = "course3_data", billing = "learnclinicaldatascience" # or your billing project if different
)

hypertension_goldstandard <- tbl(con, "hypertension_goldstandard") %>%
select(SUBJECT_ID, HYPERTENSION)%>%
collect()

## Diagnosis based flag
htn_dx <- tbl(con, "mimic3_demo.DIAGNOSES_ICD") %>%
  filter(ICD9_CODE %in% c("4010", "4011", "4019"))%>%
  select(SUBJECT_ID)%>%
  distinct()%>%
  collect()%>%
  mutate(dx_flag= 1)
  

## Prescription based flag
antihypertensives <- tbl(con, "D_ANTIHYPERTENSIVES")  %>%
  select(DRUG) %>%
  collect() %>%
  mutate(drug= tolower(DRUG))

prescription_raw <- tbl(con, "mimic3_demo.PRESCRIPTIONS")%>%
  select(SUBJECT_ID, DRUG)%>%
  collect()%>%
  mutate(drug= tolower(DRUG))
 
prescription <- prescription_raw %>%
  filter(drug %in% antihypertensives$drug)%>%
  distinct(SUBJECT_ID)%>%
  mutate(rx_flag= 1)


## Vital based flags
# Systolic and diastolic itemids
sbp_ids <- c(51, 455, 220179, 220050)
dbp_ids <- c(8368, 8441, 220180, 220051) 

bp <- tbl(con, "mimic3_demo.CHARTEVENTS")%>%
  filter(ITEMID %in% c(sbp_ids, dbp_ids))%>%
  select(SUBJECT_ID, ITEMID, VALUENUM)%>%
  collect()%>% 
  filter(!is.na(VALUENUM))

#Flag based on frequency of elevated readings
bp_flagged <- bp %>%
  mutate(bp_type= case_when(ITEMID %in% sbp_ids ~ "SBP", ITEMID %in% dbp_ids ~ "DBP"), 
elevated= case_when(ITEMID %in% sbp_ids & VALUENUM >= 140 ~ 1,
  ITEMID %in% dbp_ids & VALUENUM >= 90 ~ 1, TRUE ~0)) %>%
  filter(elevated==1)%>%
  count(SUBJECT_ID, bp_type)%>%
  filter(n >=2)%>%
  pivot_wider(names_from= bp_type, values_from = n, values_fill = 0)%>%
  filter(SBP >=2 | DBP>=2)%>%
  mutate(vitals_flag =1) %>%
  select(SUBJECT_ID, vitals_flag)

## Combine all flags with gold standard
combined_flags<- hypertension_goldstandard %>%
  left_join(htn_dx, by="SUBJECT_ID") %>%
  left_join(prescription, by="SUBJECT_ID") %>%
  left_join(bp_flagged, by="SUBJECT_ID") %>%
  mutate(across(c(dx_flag, rx_flag, vitals_flag), ~replace_na(.,0)))

#Algorithm 1: Diagnosis only
combined_flags<-combined_flags%>%
  mutate(alg_dx= dx_flag)

#Algorithm 2: Rx only
combined_flags<-combined_flags%>%
  mutate(alg_rx= rx_flag)

#Algorithm 3: Diagnosis + Rx
combined_flags<-combined_flags%>%
  mutate(alg_dx_rx= if_else(dx_flag==1 & rx_flag ==1,1,0))

#Algorithm 4: Vitals + Rx
combined_flags<-combined_flags%>%
  mutate(alg_vitals_rx= if_else(vitals_flag==1 & rx_flag ==1,1,0)) 

#Evaluation function
evaluate_algorithm <- function(data, prediction_col){
  pred <- factor(data[[prediction_col]], levels = c(0,1))
  actual <- factor(data$HYPERTENSION, levels = c(0,1))
  
  cm_table <- table(Predicted=pred , Actual= actual)
  cm <- confusionMatrix(pred, actual, positive = "1")
  
  TP <- cm_table["1", "1"]
  FP <- cm_table["1", "0"]
  FN <- cm_table["0", "1"]
  TN <- cm_table["0", "0"]
  
    return(list(confusion_matrix= cm_table,
         sensitivity=cm$byClass["Sensitivity"],
         specificity=cm$byClass["Specificity"],
         PPV= cm$byClass["Pos Pred Value"],
         NPV=cm$byClass["Neg Pred Value"],
         TP = TP,
         FP= FP,
         FN= FN,
         TN= TN))
         }

#Evaluate all algorithms
eval_dx <- evaluate_algorithm(combined_flags, "alg_dx")
eval_rx <- evaluate_algorithm(combined_flags, "alg_rx")
eval_dx_rx <- evaluate_algorithm(combined_flags, "alg_dx_rx")
eval_vitals_rx <- evaluate_algorithm(combined_flags, "alg_vitals_rx")



results <- tibble(
  Algorithm=c("Diagnosis only","Drugs only","Diagnosis + Drugs","Vitals + Drugs"),
  TP=c(eval_dx$TP, eval_rx$TP, eval_dx_rx$TP, eval_vitals_rx$TP),
  FP=c(eval_dx$FP, eval_rx$FP, eval_dx_rx$FP, eval_vitals_rx$FP),
  FN=c(eval_dx$FN, eval_rx$FN, eval_dx_rx$FN, eval_vitals_rx$FN),
  TN=c(eval_dx$TN, eval_rx$TN, eval_dx_rx$TN, eval_vitals_rx$TN),
  
  Sensitivity=c(eval_dx$sensitivity, eval_rx$sensitivity, eval_dx_rx$sensitivity, eval_vitals_rx$sensitivity),
  Specificity=c(eval_dx$specificity, eval_rx$specificity, eval_dx_rx$specificity, eval_vitals_rx$specificity),
  PPV=c(eval_dx$PPV, eval_rx$PPV, eval_dx_rx$PPV, eval_vitals_rx$PPV),
  NPV=c(eval_dx$NPV, eval_rx$NPV, eval_dx_rx$NPV, eval_vitals_rx$NPV)
  )
print(results)






