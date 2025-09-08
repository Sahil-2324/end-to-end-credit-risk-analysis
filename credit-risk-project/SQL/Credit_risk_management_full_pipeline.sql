-- Creating a database
CREATE DATABASE credit_risk;
USE credit_risk;

-- Creating table for workspace
CREATE TABLE credit_data (
    Id INT,
    SeriousDlqin2yrs TINYINT,
    RevolvingUtilizationOfUnsecuredLines DECIMAL(18,10),
    age INT,
    NumberOfTime30_59DaysPastDueNotWorse INT,
    DebtRatio DECIMAL(18,10),
    MonthlyIncome BIGINT NULL,
    NumberOfOpenCreditLinesAndLoans INT,
    NumberOfTimes90DaysLate INT,
    NumberRealEstateLoansOrLines INT,
    NumberOfTime60_89DaysPastDueNotWorse INT,
    NumberOfDependents INT NULL
);

-- Loading the .csv(dataset) file into MYSQL
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/cs-training.csv'
INTO TABLE credit_data
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    Id,
    SeriousDlqin2yrs,
    RevolvingUtilizationOfUnsecuredLines,
    age,
    NumberOfTime30_59DaysPastDueNotWorse,
    DebtRatio,
    @MonthlyIncome,
    NumberOfOpenCreditLinesAndLoans,
    NumberOfTimes90DaysLate,
    NumberRealEstateLoansOrLines,
    NumberOfTime60_89DaysPastDueNotWorse,
    @NumberOfDependents
)
SET
    MonthlyIncome = CASE 
                      WHEN TRIM(REPLACE(REPLACE(@MonthlyIncome, '\r', ''), '"', '')) IN ('NA','') 
                      THEN NULL 
                      ELSE TRIM(REPLACE(REPLACE(@MonthlyIncome, '\r', ''), '"', '')) 
                    END,
    NumberOfDependents = CASE 
                      WHEN TRIM(REPLACE(REPLACE(@NumberOfDependents, '\r', ''), '"', '')) IN ('NA','') 
                      THEN NULL 
                      ELSE TRIM(REPLACE(REPLACE(@NumberOfDependents, '\r', ''), '"', '')) 
                    END;

-- Checking if dataset is loaded properly 
SELECT * FROM credit_data LIMIT 10;

-- Checking for NULL values
SELECT 
    COUNT(*) AS total_rows,
    SUM(MonthlyIncome IS NULL) AS null_monthly_income,
    SUM(NumberOfDependents IS NULL) AS null_dependents
FROM credit_data;

-- total rows and default rate
SELECT COUNT(*) AS total_rows,
       SUM(SeriousDlqin2yrs) AS total_defaults,
       ROUND(100 * AVG(SeriousDlqin2yrs), 3) AS default_pct
FROM credit_data;

-- show first 10 rows to sanity-check column ordering
SELECT * FROM credit_data LIMIT 10;

-- column types / structure
SHOW COLUMNS FROM credit_data;

-- count NULLs per column
SELECT
  SUM(CASE WHEN RevolvingUtilizationOfUnsecuredLines IS NULL THEN 1 ELSE 0 END) AS miss_rev_util,
  SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS miss_age,
  SUM(CASE WHEN DebtRatio IS NULL THEN 1 ELSE 0 END) AS miss_debtratio,
  SUM(CASE WHEN MonthlyIncome IS NULL THEN 1 ELSE 0 END) AS miss_monthlyincome,
  SUM(CASE WHEN NumberOfDependents IS NULL THEN 1 ELSE 0 END) AS miss_dependents
FROM credit_data;

-- simple numeric summary (min, max, avg)
SELECT
  MIN(age) AS min_age, MAX(age) AS max_age, ROUND(AVG(age),2) AS avg_age,
  MIN(RevolvingUtilizationOfUnsecuredLines) AS min_rev, MAX(RevolvingUtilizationOfUnsecuredLines) AS max_rev,
  ROUND(AVG(RevolvingUtilizationOfUnsecuredLines),4) AS avg_rev,
  MIN(DebtRatio) AS min_dr, MAX(DebtRatio) AS max_dr, ROUND(AVG(DebtRatio),4) AS avg_dr,
  MIN(MonthlyIncome) AS min_inc, MAX(MonthlyIncome) AS max_inc, ROUND(AVG(MonthlyIncome),2) AS avg_inc
FROM credit_data
WHERE Id IS NOT NULL;

-- find suspicious / extreme rows
SELECT Id, age, MonthlyIncome, DebtRatio, RevolvingUtilizationOfUnsecuredLines
FROM credit_data
WHERE age < 18 OR age > 100 OR RevolvingUtilizationOfUnsecuredLines > 10 OR DebtRatio > 50
LIMIT 50;

-- in the upper query we noticed DebtRation values way too large compared to what we’d normally expect (like your example of 2.3)
-- to correct it we operated some other queries

-- MIN,MAX,AVG value
SELECT 
    MIN(DebtRatio) AS min_ratio,
    MAX(DebtRatio) AS max_ratio,
    AVG(DebtRatio) AS avg_ratio
FROM credit_data;

-- median value
WITH ranked AS (
    SELECT 
        DebtRatio,
        ROW_NUMBER() OVER (ORDER BY DebtRatio) AS rn,
        COUNT(*) OVER () AS cnt
    FROM credit_data
)
SELECT AVG(DebtRatio) AS median_ratio
FROM ranked
WHERE rn IN (FLOOR((cnt + 1) / 2), CEIL((cnt + 1) / 2));

-- cheking for extreme DebtRatio values
SELECT COUNT(*) AS extreme_cases
FROM credit_data
WHERE DebtRatio > 1000 ; 

-- UPDATE credit_data
SET SQL_SAFE_UPDATES = 0;

UPDATE credit_data
SET DebtRatio = 100
WHERE DebtRatio > 100;
-- SET SQL_SAFE_UPDATES = 1; -- optional, turn it back on

-- checking for negative values
SELECT COUNT(*) AS cnt
FROM credit_data
WHERE DebtRatio < 0;

-- checking for missing income values
SELECT COUNT(*) AS missing_income
FROM credit_data
WHERE MonthlyIncome IS NULL;

SELECT COUNT(*) AS missing_debt
FROM credit_data
WHERE DebtRatio IS NULL; -- we did found 29731 NULL values 

-- checking the median value
WITH ranked AS (
    SELECT 
        MonthlyIncome,
        ROW_NUMBER() OVER (ORDER BY MonthlyIncome) AS rn,
        COUNT(*) OVER () AS cnt
    FROM credit_data
    WHERE MonthlyIncome IS NOT NULL
)
SELECT AVG(MonthlyIncome) AS median_income
FROM ranked
WHERE rn IN (FLOOR((cnt + 1) / 2), CEIL((cnt + 1) / 2)); -- the median value was 5400.0000

-- we updated the NULL values with median value 
UPDATE credit_data
SET MonthlyIncome = 5400.0000
WHERE MonthlyIncome IS NULL;

-- checking if there is any NULL values left 
SELECT COUNT(*) AS missing_income
FROM credit_data
WHERE MonthlyIncome IS NULL;

-- creating derived features and explore trends

-- Age groups
ALTER TABLE credit_data
ADD COLUMN AgeGroup VARCHAR(10);

UPDATE credit_data
SET AgeGroup = CASE
    WHEN Age < 30 THEN 'Young'
    WHEN Age BETWEEN 30 AND 50 THEN 'Middle'
    ELSE 'Senior'
END;

-- High debt flag
ALTER TABLE credit_data
ADD COLUMN HighDebtFlag TINYINT;

UPDATE credit_data
SET HighDebtFlag = CASE WHEN DebtRatio > 50 THEN 1 ELSE 0 END;

-- Income buckets
ALTER TABLE credit_data
ADD COLUMN IncomeGroup VARCHAR(10);

UPDATE credit_data
SET IncomeGroup = CASE
    WHEN MonthlyIncome < 3000 THEN 'Low'
    WHEN MonthlyIncome BETWEEN 3000 AND 7000 THEN 'Medium'
    ELSE 'High'
END;

-- Exploratory analysis queries

-- Count of defaulters vs non-defaulters
SELECT SeriousDlqin2yrs AS Loan_status, COUNT(*) AS cnt
FROM credit_data
GROUP BY SeriousDlqin2yrs;

-- Average DebtRatio by LoanStatus
SELECT SeriousDlqin2yrs AS LoanStatus, AVG(DebtRatio) AS avg_debt
FROM credit_data
GROUP BY SeriousDlqin2yrs;

-- Average MonthlyIncome by LoanStatus
SELECT SeriousDlqin2yrs AS LoanStatus, AVG(MonthlyIncome) AS avg_income
FROM credit_data
GROUP BY SeriousDlqin2yrs;

-- HighDebtFlag vs default status
SELECT HighDebtFlag, SeriousDlqin2yrs AS LoanStatus, COUNT(*) AS cnt
FROM credit_data
GROUP BY HighDebtFlag, SeriousDlqin2yrs;

-- Count of defaulters by AgeGroup
SELECT AgeGroup, SeriousDlqin2yrs AS LoanStatus, COUNT(*) AS cnt
FROM credit_data
GROUP BY AgeGroup, SeriousDlqin2yrs;

-- Count by IncomeGroup
SELECT IncomeGroup, SeriousDlqin2yrs AS LoanStatus, COUNT(*) AS cnt
FROM credit_data
GROUP BY IncomeGroup, SeriousDlqin2yrs;

-- Average DebtToIncomeRatio by default status
SELECT SeriousDlqin2yrs AS LoanStatus, AVG(DebtToIncomeRatio) AS avg_ratio
FROM credit_data
GROUP BY SeriousDlqin2yrs;

-- adding a new table to the dataset
ALTER TABLE credit_data
ADD COLUMN DebtToIncomeRatio FLOAT;

UPDATE credit_data
SET DebtToIncomeRatio = CAST(DebtRatio AS SIGNED) / CAST(MonthlyIncome AS SIGNED)
WHERE MonthlyIncome <> 0;

-- checking how many MonthlyIncome is zero
SELECT COUNT(*) AS zero_income
FROM credit_data
WHERE MonthlyIncome = 0;

UPDATE credit_data
SET DebtToIncomeRatio = 9999
WHERE MonthlyIncome = 0;

SELECT MonthlyIncome, DebtRatio, DebtToIncomeRatio
FROM credit_data
LIMIT 20;

-- Now that our data is clean and all features are ready, the next steps are focused on exploratory analysis and insights to  understand credit risk patterns

-- Step 1: Explore default distribution
-- Count of defaulters vs non-defaulters
SELECT SeriousDlqin2yrs AS LoanStatus, COUNT(*) AS cnt
FROM credit_data
GROUP BY SeriousDlqin2yrs; -- This shows how many borrowers defaulted (1) vs safe (0).

-- Step 2: Check DebtToIncomeRatio vs Default
-- Average DebtToIncomeRatio by default status
SELECT SeriousDlqin2yrs AS LoanStatus, AVG(DebtToIncomeRatio) AS avg_ratio
FROM credit_data
GROUP BY SeriousDlqin2yrs;

-- High-risk borrowers count by default
SELECT 
	CASE 
		WHEN DebtToIncomeRatio > 50 THEN 'High' ELSE 'Normal' END AS RiskLevel,
			SeriousDlqin2yrs AS LoanStatus,
			COUNT(*) AS cnt
FROM credit_data
GROUP BY RiskLevel, SeriousDlqin2yrs; # This shows whether higher debt ratios are linked to default.

-- Step 3: Explore other features vs Default
-- AgeGroup vs Default
SELECT AgeGroup, SeriousDlqin2yrs AS LoanStatus, COUNT(*) AS cnt
FROM credit_data
GROUP BY AgeGroup, SeriousDlqin2yrs;

-- IncomeGroup vs Default
SELECT IncomeGroup, SeriousDlqin2yrs AS LoanStatus, COUNT(*) AS cnt
FROM credit_data
GROUP BY IncomeGroup, SeriousDlqin2yrs;

-- HighDebtFlag vs Default
SELECT HighDebtFlag, SeriousDlqin2yrs AS LoanStatus, COUNT(*) AS cnt
FROM credit_data
GROUP BY HighDebtFlag, SeriousDlqin2yrs;

-- Now we will see summary stats to understand the data before jumping into risk analysis
-- Average monthly income and debt ratio
SELECT 
    ROUND(AVG(MonthlyIncome), 2) AS avg_income,
    ROUND(AVG(DebtRatio), 4) AS avg_debt_ratio,
    ROUND(AVG(DebtToIncomeRatio), 4) AS avg_dti
FROM credit_data;

-- Income distribution
SELECT IncomeGroup, COUNT(*) AS cnt
FROM credit_data
GROUP BY IncomeGroup
ORDER BY IncomeGroup;

-- Age distribution
SELECT AgeGroup, COUNT(*) AS cnt
FROM credit_data
GROUP BY AgeGroup
ORDER BY AgeGroup;

-- Debt flag distribution
SELECT HighDebtFlag, COUNT(*) AS cnt
FROM credit_data
GROUP BY HighDebtFlag;

-- Now we will try to analyze default patterns 
# Here our goal is:
# See how defaults (SeriousDlqin2yrs = 1) vary across groups (age, income, debt)
# Spot the highest-risk groups

# Default rate by age group
SELECT 
    AgeGroup,
    SUM(CASE WHEN SeriousDlqin2yrs = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS default_rate
FROM credit_data
GROUP BY AgeGroup
ORDER BY default_rate DESC;

# Default rate by income group
SELECT 
    IncomeGroup,
    SUM(CASE WHEN SeriousDlqin2yrs = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS default_rate
FROM credit_data
GROUP BY IncomeGroup
ORDER BY default_rate DESC;

# Default rate by high debt flag
SELECT 
    HighDebtFlag,
    SUM(CASE WHEN SeriousDlqin2yrs = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS default_rate
FROM credit_data
GROUP BY HighDebtFlag;

# Debt-to-income ratio and defaults (continuous view)
SELECT 
    ROUND(DebtToIncomeRatio, 2) AS dti_band,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN SeriousDlqin2yrs = 1 THEN 1 ELSE 0 END) AS defaults,
    SUM(CASE WHEN SeriousDlqin2yrs = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS default_rate
FROM credit_data
GROUP BY ROUND(DebtToIncomeRatio, 2)
HAVING COUNT(*) > 50   -- ignore tiny groups
ORDER BY default_rate DESC
LIMIT 20;

-- there was some issue in high debt flag so we updated it
UPDATE credit_data
SET HighDebtFlag = CASE 
    WHEN DebtRatio <= 1 THEN 0   -- low debt
    WHEN DebtRatio <= 5 THEN 1   -- medium debt
    ELSE 2                       -- high debt
END;

-- Building a simple Risk Scorecard
SELECT 
    SeriousDlqin2yrs AS LoanStatus,
    
    -- Age score
    CASE 
        WHEN Age < 25 THEN 30
        WHEN Age BETWEEN 25 AND 40 THEN 15
        ELSE 5
    END AS age_score,

    -- Income score
    CASE 
        WHEN MonthlyIncome < 3000 THEN 30
        WHEN MonthlyIncome BETWEEN 3000 AND 8000 THEN 15
        ELSE 5
    END AS income_score,

    -- Debt flag score
    CASE 
        WHEN HighDebtFlag = 1 THEN 40
        ELSE 10
    END AS debt_score,

    -- Final risk score
    ( 
      CASE 
        WHEN Age < 25 THEN 30
        WHEN Age BETWEEN 25 AND 40 THEN 15
        ELSE 5
      END 
      +
      CASE 
        WHEN MonthlyIncome < 3000 THEN 30
        WHEN MonthlyIncome BETWEEN 3000 AND 8000 THEN 15
        ELSE 5
      END
      +
      CASE 
        WHEN HighDebtFlag = 1 THEN 40
        ELSE 10
      END
    ) AS total_score

FROM credit_data
LIMIT 20;

-- Validate & Analyze the Scoring System
# Now we’ll check if the risk score actually separates risky customers from safe ones

-- What we’ll do:
# Bin customers by score ranges (e.g., 20–30, 31–40, 41–50, etc.)
# Calculate default rate (AVG(SeriousDlqin2yrs)) per bin
# If the score is working, higher bins should show higher default rates

SELECT 
    CASE 
        WHEN total_score BETWEEN 20 AND 30 THEN '20-30'
        WHEN total_score BETWEEN 31 AND 40 THEN '31-40'
        WHEN total_score BETWEEN 41 AND 50 THEN '41-50'
        WHEN total_score BETWEEN 51 AND 60 THEN '51-60'
        WHEN total_score BETWEEN 61 AND 70 THEN '61-70'
        WHEN total_score BETWEEN 71 AND 80 THEN '71-80'
        ELSE '81+' 
    END AS score_bin,
    COUNT(*) AS total_customers,
    AVG(SeriousDlqin2yrs) * 100 AS default_rate
FROM (
    SELECT 
        SeriousDlqin2yrs,
        ( 
          CASE WHEN Age < 25 THEN 30
               WHEN Age BETWEEN 25 AND 40 THEN 15
               ELSE 5 END
          +
          CASE WHEN MonthlyIncome < 3000 THEN 30
               WHEN MonthlyIncome BETWEEN 3000 AND 8000 THEN 15
               ELSE 5 END
          +
          CASE WHEN HighDebtFlag = 1 THEN 40
               ELSE 10 END
        ) AS total_score
    FROM credit_data
) t
GROUP BY score_bin
ORDER BY score_bin;

-- We’re now at the Risk Labeling stage.
# We’ll assign risk categories (Low, Medium, High) based on the total_score we already created.
SELECT 
    SeriousDlqin2yrs AS LoanStatus,
    Age,
    MonthlyIncome,
    DebtToIncomeRatio,
    HighDebtFlag,

    -- Total Score (same logic as before)
    (
      CASE WHEN Age < 25 THEN 30
           WHEN Age BETWEEN 25 AND 40 THEN 15
           ELSE 5 END
      +
      CASE WHEN MonthlyIncome < 3000 THEN 30
           WHEN MonthlyIncome BETWEEN 3000 AND 8000 THEN 15
           ELSE 5 END
      +
      CASE WHEN HighDebtFlag = 1 THEN 40 ELSE 10 END
    ) AS total_score,

    -- Risk Label
    CASE
        WHEN (
          CASE WHEN Age < 25 THEN 30
               WHEN Age BETWEEN 25 AND 40 THEN 15
               ELSE 5 END
          +
          CASE WHEN MonthlyIncome < 3000 THEN 30
               WHEN MonthlyIncome BETWEEN 3000 AND 8000 THEN 15
               ELSE 5 END
          +
          CASE WHEN HighDebtFlag = 1 THEN 40 ELSE 10 END
        ) >= 70 THEN 'High Risk'
        
        WHEN (
          CASE WHEN Age < 25 THEN 30
               WHEN Age BETWEEN 25 AND 40 THEN 15
               ELSE 5 END
          +
          CASE WHEN MonthlyIncome < 3000 THEN 30
               WHEN MonthlyIncome BETWEEN 3000 AND 8000 THEN 15
               ELSE 5 END
          +
          CASE WHEN HighDebtFlag = 1 THEN 40 ELSE 10 END
        ) BETWEEN 40 AND 69 THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS risk_label

FROM credit_data
LIMIT 20;

-- Default Rate by Risk Label
WITH scored AS (
    SELECT 
        SeriousDlqin2yrs AS LoanStatus,
        (
          CASE WHEN Age < 25 THEN 30
               WHEN Age BETWEEN 25 AND 40 THEN 15
               ELSE 5 END
          +
          CASE WHEN MonthlyIncome < 3000 THEN 30
               WHEN MonthlyIncome BETWEEN 3000 AND 8000 THEN 15
               ELSE 5 END
          +
          CASE WHEN HighDebtFlag = 1 THEN 40 ELSE 10 END
        ) AS total_score
    FROM credit_data
)
SELECT
    CASE
        WHEN total_score >= 70 THEN 'High Risk'
        WHEN total_score BETWEEN 40 AND 69 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_label,
    COUNT(*) AS total_customers,
    SUM(LoanStatus) AS total_defaults,
    ROUND(100.0 * SUM(LoanStatus) / COUNT(*), 2) AS default_rate_percent
FROM scored
GROUP BY risk_label
ORDER BY default_rate_percent DESC;

-- Cross-Check Risk Labels vs Age & Income
# We want to be sure our RiskLabel is consistent. For example:
# Are High Risk customers really defaulting at higher rates than Medium/Low?
# Does this pattern hold across age groups and income brackets?

-- Default rate by RiskLabel & AgeGroup
SELECT 
    RiskLabel,
    AgeGroup,
    COUNT(*) AS Total_Customers,
    SUM(SeriousDlqin2yrs) AS Defaults,
    ROUND(SUM(SeriousDlqin2yrs) * 100.0 / COUNT(*), 2) AS DefaultRatePct
FROM (
    SELECT  
        CASE
            WHEN SeriousDlqin2yrs = 1 
                 OR (NumberOfTimes90DaysLate >= 2 
                     OR NumberOfTime60_89DaysPastDueNotWorse >= 2) 
                 OR DebtRatio > 1 
                 OR RevolvingUtilizationOfUnsecuredLines > 0.8
            THEN 'High Risk'
            WHEN SeriousDlqin2yrs = 0 
                 AND (NumberOfTime30_59DaysPastDueNotWorse >= 1 
                      OR NumberOfTime60_89DaysPastDueNotWorse = 1)
            THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS RiskLabel,

        CASE 
            WHEN age < 30 THEN '<30'
            WHEN age BETWEEN 30 AND 39 THEN '30s'
            WHEN age BETWEEN 40 AND 49 THEN '40s'
            WHEN age BETWEEN 50 AND 59 THEN '50s'
            WHEN age BETWEEN 60 AND 69 THEN '60s'
            WHEN age >= 70 THEN '70+'
        END AS AgeGroup,

        SeriousDlqin2yrs
    FROM credit_data
) AS derived
GROUP BY RiskLabel, AgeGroup
ORDER BY RiskLabel, AgeGroup
LIMIT 0, 1000;

-- query that breaks down risk by AgeGroup × IncomeGroup
SELECT  
    CASE
        WHEN SeriousDlqin2yrs = 1  
             OR (NumberOfTimes90DaysLate >= 2  
                 OR NumberOfTime60_89DaysPastDueNotWorse >= 2)  
             OR DebtRatio > 1  
             OR RevolvingUtilizationOfUnsecuredLines > 0.8
        THEN 'High Risk'
        WHEN SeriousDlqin2yrs = 0  
             AND (NumberOfTime30_59DaysPastDueNotWorse >= 1  
                  OR NumberOfTime60_89DaysPastDueNotWorse = 1)
        THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS RiskLabel,

    CASE 
        WHEN age < 30 THEN '<30'
        WHEN age BETWEEN 30 AND 39 THEN '30s'
        WHEN age BETWEEN 40 AND 49 THEN '40s'
        WHEN age BETWEEN 50 AND 59 THEN '50s'
        WHEN age BETWEEN 60 AND 69 THEN '60s'
        WHEN age >= 70 THEN '70+'
    END AS AgeGroup,

    CASE
        WHEN MonthlyIncome IS NULL THEN 'Unknown'
        WHEN MonthlyIncome < 3000 THEN 'Low'
        WHEN MonthlyIncome BETWEEN 3000 AND 7000 THEN 'Medium'
        WHEN MonthlyIncome > 7000 THEN 'High'
    END AS IncomeGroup,

    COUNT(*) AS Total_Customers,
    SUM(SeriousDlqin2yrs) AS Defaults,
    ROUND(SUM(SeriousDlqin2yrs) * 100.0 / COUNT(*), 2) AS DefaultRatePct

FROM credit_data
GROUP BY 
    CASE
        WHEN SeriousDlqin2yrs = 1  
             OR (NumberOfTimes90DaysLate >= 2  
                 OR NumberOfTime60_89DaysPastDueNotWorse >= 2)  
             OR DebtRatio > 1  
             OR RevolvingUtilizationOfUnsecuredLines > 0.8
        THEN 'High Risk'
        WHEN SeriousDlqin2yrs = 0  
             AND (NumberOfTime30_59DaysPastDueNotWorse >= 1  
                  OR NumberOfTime60_89DaysPastDueNotWorse = 1)
        THEN 'Medium Risk'
        ELSE 'Low Risk'
    END,
    CASE 
        WHEN age < 30 THEN '<30'
        WHEN age BETWEEN 30 AND 39 THEN '30s'
        WHEN age BETWEEN 40 AND 49 THEN '40s'
        WHEN age BETWEEN 50 AND 59 THEN '50s'
        WHEN age BETWEEN 60 AND 69 THEN '60s'
        WHEN age >= 70 THEN '70+'
    END,
    CASE
        WHEN MonthlyIncome IS NULL THEN 'Unknown'
        WHEN MonthlyIncome < 3000 THEN 'Low'
        WHEN MonthlyIncome BETWEEN 3000 AND 7000 THEN 'Medium'
        WHEN MonthlyIncome > 7000 THEN 'High'
    END
ORDER BY RiskLabel, AgeGroup, IncomeGroup;

-- Check if Medium Risk (or Low Risk) buckets really have zero defaults in our segmentation
CREATE TABLE risk_segments AS
SELECT
    Id,
    SeriousDlqin2yrs,
    age,
    CASE
        WHEN SeriousDlqin2yrs = 1 
             AND (NumberOfTimes90DaysLate > 0 OR NumberOfTime60_89DaysPastDueNotWorse > 0) 
             THEN 'High Risk'
        WHEN SeriousDlqin2yrs = 1 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS Risk_Label
FROM credit_data;

SELECT
    CASE
        WHEN SeriousDlqin2yrs = 1 THEN 'Default'
        ELSE 'No Default'
    END AS Default_Status,
    COUNT(*) AS Count_Records
FROM credit_data
WHERE SeriousDlqin2yrs = 1
  AND Id IN (
      SELECT Id
      FROM risk_segments
      WHERE Risk_Label = 'Medium Risk'
  )
GROUP BY Default_Status;

-- the SQL code to extend our risk_segments table into a master table with:
# Risk_Label (High / Medium / Low Risk)
# Age_Bucket (<30, 30s, 40s, etc.)
# DebtRatio_Bucket (Low / Medium / High)

CREATE TABLE risk_master AS
SELECT
    c.Id,
    
    -- Risk Segments
    CASE
        WHEN c.RevolvingUtilizationOfUnsecuredLines > 1 
             OR c.DebtRatio > 1 THEN 'High Risk'
        WHEN c.NumberOfTimes90DaysLate > 2 THEN 'High Risk'
        WHEN c.NumberOfTime30_59DaysPastDueNotWorse > 3 
             OR c.NumberOfTime60_89DaysPastDueNotWorse > 2 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS Risk_Label,
    
    -- Age Buckets
    CASE
        WHEN c.age < 30 THEN '<30'
        WHEN c.age BETWEEN 30 AND 39 THEN '30s'
        WHEN c.age BETWEEN 40 AND 49 THEN '40s'
        WHEN c.age BETWEEN 50 AND 59 THEN '50s'
        WHEN c.age BETWEEN 60 AND 69 THEN '60s'
        ELSE '70+'
    END AS Age_Bucket,
    
    -- Debt Ratio Buckets
    CASE
        WHEN c.DebtRatio < 0.2 THEN 'Low'
        WHEN c.DebtRatio < 0.6 THEN 'Medium'
        ELSE 'High'
    END AS DebtRatio_Bucket,
    
    -- Default Flag
    CASE 
        WHEN c.SeriousDlqin2yrs = 1 THEN 1
        ELSE 0
    END AS Default_Flag

FROM credit_data c;

-- Distribution & Risk-Default Check
# Risk segment distribution
SELECT Risk_Label, COUNT(*) AS Count_Records
FROM risk_master
GROUP BY Risk_Label
ORDER BY Risk_Label;

# Default rates by risk segment
SELECT 
    Risk_Label,
    SUM(Default_Flag) AS Total_Defaults,
    COUNT(*) AS Total_Records,
    ROUND(SUM(Default_Flag) * 100.0 / COUNT(*), 2) AS Default_Rate_Percent
FROM risk_master
GROUP BY Risk_Label;

# Default rates by age bucket
SELECT 
    Age_Bucket,
    SUM(Default_Flag) AS Total_Defaults,
    COUNT(*) AS Total_Records,
    ROUND(SUM(Default_Flag) * 100.0 / COUNT(*), 2) AS Default_Rate_Percent
FROM risk_master
GROUP BY Age_Bucket
ORDER BY Age_Bucket;

-- We can now test how different buckets behave with respect to default flag
# Debt Ratio vs Default
SELECT 
    DebtRatio_Bucket,
    SUM(Default_Flag) AS Total_Defaults,
    COUNT(*) AS Total_Records,
    ROUND(SUM(Default_Flag) * 100.0 / COUNT(*), 2) AS Default_Rate_Percent
FROM risk_master
GROUP BY DebtRatio_Bucket;

-- Now we will try do some advanced correlation and feature-interaction analysis, We’ll use your risk_master table to explore which factors truly drive defaults.
# Risk_Label + Age_Bucket vs Default Rate. This checks if age impacts default differently across risk segments.
SELECT 
    Risk_Label,
    Age_Bucket,
    COUNT(*) AS Total_Customers,
    SUM(Default_Flag) AS Total_Defaults,
    ROUND(SUM(Default_Flag)*100.0/COUNT(*),2) AS Default_Rate_Percent
FROM risk_master
GROUP BY Risk_Label, Age_Bucket
ORDER BY FIELD(Risk_Label,'High Risk','Medium Risk','Low Risk'), Age_Bucket;

-- Risk_Label + DebtRatio_Bucket vs Default Rate. See if debt ratio increases default probability differently in each risk segment.
SELECT 
    Risk_Label,
    DebtRatio_Bucket,
    COUNT(*) AS Total_Customers,
    SUM(Default_Flag) AS Total_Defaults,
    ROUND(SUM(Default_Flag)*100.0/COUNT(*),2) AS Default_Rate_Percent
FROM risk_master
GROUP BY Risk_Label, DebtRatio_Bucket
ORDER BY FIELD(Risk_Label,'High Risk','Medium Risk','Low Risk'),
         FIELD(DebtRatio_Bucket,'Low','Medium','High');
         
-- Age_Bucket + DebtRatio_Bucket vs Default Rate. Find high-risk clusters by age + debt ratio combination.         
SELECT 
    Age_Bucket,
    DebtRatio_Bucket,
    COUNT(*) AS Total_Customers,
    SUM(Default_Flag) AS Total_Defaults,
    ROUND(SUM(Default_Flag)*100.0/COUNT(*),2) AS Default_Rate_Percent
FROM risk_master
GROUP BY Age_Bucket, DebtRatio_Bucket
ORDER BY Age_Bucket,
         FIELD(DebtRatio_Bucket,'Low','Medium','High');

-- HighDebtFlag + Risk_Label vs Default Rate. Check how high debt impacts default in each risk segment.
SELECT
    DebtRatio_Bucket AS HighDebtFlag,
    Risk_Label,
    COUNT(*) AS Total_Customers,
    SUM(Default_Flag) AS Total_Defaults,
    ROUND(SUM(Default_Flag)*100.0/COUNT(*),2) AS Default_Rate_Percent
FROM risk_master
GROUP BY DebtRatio_Bucket, Risk_Label
ORDER BY Risk_Label, DebtRatio_Bucket;

-- This is our final summary table 
CREATE TABLE risk_summary AS
SELECT
    Risk_Label,
    Age_Bucket,
    DebtRatio_Bucket,
    COUNT(*) AS Total_Customers,
    SUM(Default_Flag) AS Total_Defaults,
    ROUND(SUM(Default_Flag)*100.0/COUNT(*),2) AS Default_Rate_Percent
FROM risk_master
GROUP BY Risk_Label, Age_Bucket, DebtRatio_Bucket
ORDER BY FIELD(Risk_Label,'High Risk','Medium Risk','Low Risk'),
         Age_Bucket,
         FIELD(DebtRatio_Bucket,'Low','Medium','High');




