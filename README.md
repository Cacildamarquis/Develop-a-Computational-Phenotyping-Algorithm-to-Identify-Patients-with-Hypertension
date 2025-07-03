Hypertension Computational Phenotyping (MIMIC-III + BigQuery)
Project Overview
-This project applies computational phenotyping techniques to develop, test, and validate multiple algorithms for identifying patients with hypertension using the MIMIC-III dataset on Google BigQuery. The goal is to simulate real-world data science workflows used in clinical research and healthcare analytics.

Why This Matters?
-Hypertension is a leading risk factor for cardiovascular diseases and remains underdiagnosed in clinical settings. This project demonstrates how data scientists can extract meaningful clinical phenotypes from Electronic Health Record (EHR) data using structured fields like diagnoses, prescriptions, and vital signs.

Objectives:
 Test two or more individual data types (e.g., diagnosis codes, medications, blood pressure measurements)
 Apply two or more manipulations on each data type (e.g., filtering, grouping, temporal logic)
 Combine data types to create more robust algorithms
 Generate 2x2 confusion matrices and calculate evaluation metrics:
 Sensitivity
 Specificity
 Positive Predictive Value (PPV)
 Negative Predictive Value (NPV)
 Select and justify the final phenotyping algorithm based on performance, complexity, and portability

Clinical Data Sources (Google BigQuery)
Table	Description
course3_data.hypertension_goldstandard	Manually validated gold standard labels
course3_data.D_ANTIHYPERTENSIVES	Lookup table of antihypertensive medications
mimic3_demo	Clinical data tables (e.g., DIAGNOSES_ICD, PRESCRIPTIONS, CHARTEVENTS)

Clinical Definition
Hypertension Criteria (JNC 7 Guidelines): Systolic BP ≥ 140 mmHg on 2+ occasions, Diastolic BP ≥ 90 mmHg on 2+ occasions
ICD-9 Codes Used: 401.0 Malignant, 401.1 Benign, 401.9 Unspecified
Common Therapies (via D_ANTIHYPERTENSIVES): Beta-blockers, ACE inhibitors, ARBs, calcium channel blockers, etc.

Evaluation Metrics
Each tested algorithm was evaluated using:
 2x2 Confusion Matrix
 Sensitivity: True Positive Rate
 Specificity: True Negative Rate
 PPV: Probability patient with positive result has hypertension
 NPV: Probability patient with negative result does not have hypertension
 
Presentation Slide Deck outlining:
 Data types and manipulations used
 All tested algorithms and their evaluation metrics
 Confusion matrices
 Final chosen algorithm with justification
 Discussion on algorithm complexity and generalizability

Tools & Technologies:
 SQL (Google BigQuery)
 MIMIC-III Clinical Database
 Gold Standard Annotation
 Computational Phenotyping
 Evaluation Metrics in R

Final Outcome
 Selected and justified a high-performing computational phenotyping algorithm based on multiple EHR-derived signals. Demonstrated ability to design, implement, and evaluate rule-based    patient identification models using real-world clinical data.
