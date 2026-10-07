BANKING CUSTOMER AND LOAN ANALYSIS 
SQL PORTFOLIO

Objective: The purpose of this analysis is to help the company better understand who the banks customers are, how much money do customers hold and what accounts do they use. To analyse how are customers using the bank, and track the banks lending performance, whether borrowers are paying reliably, and where might there be a risk.  

Tools:
SQL Server / SSMS

Author: MS MNYONI, CHANTEL

1. DATA OVERVIEW

-- Check number of Customers
SELECT COUNT(*) AS [Total Customers]
FROM Customers;

-- Check number of Accounts
SELECT COUNT(*) AS [Total Accounts]
FROM Accounts;

-- Check number of Transactions
SELECT COUNT(*) AS [Total Transactions]
FROM Transactions;

-- Check number of Loans
SELECT COUNT(*) AS [Total Loans]
FROM Loans;

-- Check number of Loan Payments
SELECT COUNT (*) AS [Total Loan Payments]
FROM LoanPayments;

2. DATA QUALITY CHECK

-- Check for accounts with no matching customerID
SELECT
    A.AccountID,
    C.CustomerID
FROM Accounts AS A
LEFT JOIN Customers AS C
    ON a.customerid = c.customerid
WHERE C.CustomerID IS NULL;

-- Check for accounts with invaild balances
SELECT
    AccountID,
    AccountBalance
FROM Accounts
WHERE AccountBalance < 0;

-- Check for transactions with no matching customerID
SELECT
    T.TransactionID,
    C.CustomerID
FROM Transactions AS T
LEFT JOIN Accounts AS A
    ON t.accountid = a.customerid
JOIN Customers AS C
    ON c.customerid = a.customerid
WHERE C.CustomerID IS NULL;

-- Check for transactions with invaild amounts
SELECT
    TransactionID,
    Amount
FROM Transactions
WHERE Amount <= 0;

-- Check for duplicate transactions
SELECT 
    TransactionID, 
    COUNT(TransactionID) AS NumberOfTransactions
FROM Transactions
GROUP BY TransactionID
HAVING COUNT(TransactionID) > 1;

-- Check for duplicate accounts
SELECT AccountID, COUNT(*) AS NumberOfAccounts
FROM Accounts
GROUP BY AccountID
HAVING COUNT(*) > 1;

-- Check for customers
SELECT CustomerID, COUNT(*) AS NumberOfCustomers
FROM Customers
GROUP BY CustomerID
HAVING COUNT(*) > 1;

-- Check for duplicate loans
SELECT LoanID, COUNT(*) AS NumberOfLoans
FROM Loans
GROUP BY LoanID
HAVING COUNT(*) > 1;

-- Check for duplicate loan payments
SELECT PaymentID, COUNT(*) AS NumberOfLoanPayments
FROM LoanPayments
GROUP BY PaymentID
HAVING COUNT(*) > 1;

-- Check for invaild interest rates
SELECT 
    LoanID, 
    InterestRate 
FROM Loans 
WHERE InterestRate <= 0; 

-- Check for loans with no matching customerID
SELECT
    L.LoanID,
    C.CustomerID
FROM Loans AS L
LEFT JOIN Customers AS C
    ON c.customerid = l.customerid
WHERE C.CustomerID IS NULL;

-- Loan payments with no matching loan
SELECT
    LP.PaymentID,
    LP.LoanID
FROM LoanPayments AS LP
LEFT JOIN Loans AS L
    ON LP.LoanID = L.LoanID
WHERE L.LoanID IS NULL;

-- Check for invalid loan amounts
SELECT
    LoanID,
    LoanAmount
FROM Loans
WHERE LoanAmount <= 0;

4. CUSTOMERS

-- What is the average customer age by gender
SELECT
    Gender,
    AVG(Age) AS AverageAge
FROM Customers 
GROUP BY Gender;

-- What is the total income by employment status
SELECT
    EmploymentStatus,
    SUM(Income) AS TotalIncome
FROM Customers
GROUP BY EmploymentStatus
ORDER BY TotalIncome DESC;

-- What is the average customer income by city
SELECT
    City,
    AVG(Income) AS AverageIncome
FROM Customers
GROUP BY City
ORDER BY AverageIncome DESC;

-- How long as the customer been with the bank
SELECT
    CustomerID,
    CustomerSince,
    DATEDIFF(YEAR, CustomerSince, GETDATE()) AS YearsAsCustomer
FROM Customers
ORDER BY DATEDIFF(YEAR, CustomerSince, GETDATE()) DESC;

5. ACCOUNTS

-- What is the total account balance by account type
SELECT
    AccountType,
    SUM(AccountBalance) AS TotalAccountBalance
FROM Accounts
GROUP BY AccountType
ORDER BY TotalAccountBalance DESC;

-- Which employment category has the highest total account balance
SELECT
    C.EmploymentStatus,
    SUM(A.AccountBalance) AS TotalAccountBalance
FROM Customers AS C
    JOIN Accounts AS A
    ON c.customerid = a.customerid
GROUP BY C.EmploymentStatus
ORDER BY TotalAccountBalance DESC;

-- What percentage of accounts are closed 
SELECT 
    SUM( 
    CASE
        WHEN AccountStatus = 'Closed'
        THEN 1
        ELSE 0
    END
    ) * 1.0 / COUNT(*) * 100 AS ClosedAccountsPercentage
FROM Accounts;

6. TRANSACTIONS

-- What is the total transaction amount by transaction type
SELECT
    TransactionType,
    SUM(Amount)AS TotalAmount
FROM Transactions
GROUP BY TransactionType
ORDER BY TotalAmount DESC;

-- What percentage of transactions occur through each channel
SELECT
    Channel,
    COUNT(*) AS ChannelCount,
    COUNT(*) * 1.0 / (SELECT COUNT(*) FROM Transactions) * 100 AS ChannelPercentage
FROM Transactions
GROUP BY Channel
ORDER BY ChannelPercentage DESC;
 

7. LOANS

-- What is the total loan amount by loan type
SELECT
    LoanType,
    SUM(LoanAmount) AS TotalLoanAmount
FROM Loans
GROUP BY LoanType
ORDER BY TotalLoanAmount DESC;

-- What is the average interest rate by loan type
SELECT
    LoanType,
    AVG(InterestRate) AS AverageInterestRate
FROM Loans
GROUP BY LoanType
ORDER BY AverageInterestRate DESC;

-- What percentage of loan applications are approved 
SELECT
    SUM( CASE
        WHEN LoanStatus = 'Approved'
        THEN 1
        ELSE 0
        END
        ) * 1.0 / COUNT(*) * 100 AS PercentageApproved
FROM Loans;

-- What is the total loan application by month
SELECT
    DATENAME(MONTH,ApplicationDate) AS MonthName,
    SUM(LoanAmount) AS TotalLoanAmount
FROM Loans
GROUP BY
    DATENAME(MONTH,ApplicationDate),
    MONTH(ApplicationDate)
ORDER BY
    MONTH(ApplicationDate);

8. LOAN PAYMENTS

-- What is the total amount received from loan payments
SELECT
    SUM(PaymentAmount) AS TotalAmountReceived
FROM LoanPayments;

-- How long does it take between loan application and payment
SELECT
    L.LoanID,
    L.ApplicationDate,
    LP.PaymentDate,
    DATEDIFF(
        DAY,
        L.ApplicationDate,
        LP.PaymentDate
    ) AS DaysToFirstPayment
FROM Loans AS L
JOIN LoanPayments AS LP
    ON L.LoanID = LP.LoanID;

-- Which loan types appear riskiest based on late and missed payments
WITH LoanRisk AS
(
SELECT
    L.LoanType,
    COUNT(*) AS TotalPayments,
    SUM(
        CASE
            WHEN LP.PaymentStatus IN ('Late', 'Missed')
            THEN 1
            ELSE 0
        END
            ) AS RiskPayments
FROM Loans AS L
    JOIN LoanPayments AS LP
        ON L.LoanID = LP.LoanID
GROUP BY L.LoanType
)
SELECT
    LoanType,
    TotalPayments,
    RiskPayments,
    RiskPayments * 1.0 / TotalPayments * 100 AS RiskPercentage
FROM LoanRisk
ORDER BY RiskPercentage DESC;