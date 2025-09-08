# Credit Risk Analysis Project  

## 📌 Overview  
This project demonstrates an **end-to-end Credit Risk Analysis workflow** using **SQL, Python, and Tableau**. 
The main objective is to clean and transform raw credit data, generate insights through exploratory plots, and present key findings in an interactive Tableau dashboard.  

---

## 🛠️ Tech Stack  
- **SQL (MySQL)** → Data cleaning, feature engineering, risk summary  
- **Python (Pandas, Matplotlib)** → Exploratory Data Analysis & plots  
- **Tableau** → Interactive dashboards for visualization  

---

## 📂 Project Structure  
credit-risk-project/
│
├── sql/ # SQL scripts
│ └── Credit_risk_management_full_pipeline.sql
│
├── python/ # Python EDA & plots
│ ├── eda_plots.ipynb
│ └── requirements.txt
│
├── tableau/ # Tableau dashboards
│ ├── dashboard.png
│ └── tableau_public_link
│
├── data/ # Sample datasets
| ├── credit_data_raw.csv
| └── credit_data_clean.csv
|
├── README.md  

---

## 🔹 Step 1: SQL (Full Pipeline)  
All raw data was imported into MySQL and transformed using one **end-to-end pipeline script**:  
- Data Cleaning  
- Feature Engineering (age groups, income buckets, debt ratio buckets)  
- Risk Summary Table  

➡️ SQL Script: [`Credit_risk_management_full_pipeline.sql`](sql/Credit_risk_management_full_pipeline.sql)  

---

## 🔹 Step 2: Python (Exploratory Plots)  
Python was used for simple EDA and plotting:  
- Age distribution  
- Income vs Default Rate  
- Debt Ratio vs Default Rate  
- Risk category bar charts  

➡️ Notebook: [`eda_plots.ipynb`](python/eda_plots.ipynb)  

---

## 🔹 Step 3: Tableau (Interactive Dashboard)  
The final findings were presented in an interactive Tableau dashboard:  
- **Default Rate by Age Bucket**  
- **Default vs Non-Default Customers**  
- **Age vs Default Rate**
- **Risk_Score vs Default Rate & Customer Count**
- **Default Rate by Debt Ratio Bucket**
- **HighDebtFlag vs Default Rate**
- **IncomeGroup vs Default Rate**
- **Age vs Default Rate & Customer Count**
- **Risk_Score vs IncomeGroup**

📊 Dashboard Screenshot:  
![Dashboard](tableau/dashboard.png)  

🌐 Tableau Public Link: [Click Here]([your_tableau_link_here](https://public.tableau.com/views/CustomerCreditRiskAnalysisDefaultProbabilityInsights/Dashboard1?:language=en-US&:sid=&:display_count=n&:origin=viz_share_link))  

---

## 🚀 How to Run  
1. Import the dataset into MySQL and run:  
   ```sql
   SOURCE sql/Credit_risk_management_full_pipeline.sql;
   
2. Run Python notebook for EDA plots:
pip install -r python/requirements.txt
jupyter notebook python/eda_plots.ipynb

3. Open Tableau dashboard locally or view the published version.

Author -
Sahil
Gmail - sahilranga03@gmail.com
LinkdIn - https://www.linkedin.com/in/sahil-ranga-192675220/
