
-- DATA PREPARATION AND UNDERSTANDING

-- Q1. What is the total number of rows in each of the 3 tables in the database?

	SELECT COUNT(customer_Id)
	FROM Customer

	SELECT count(prod_cat_code) 
	FROM prod_cat_info

	SELECT COUNT(transaction_id)
	FROM Transactions

-- Q2. What is the total number of transactions that have a return?

	SELECT COUNT(DISTINCT transaction_id)
	FROM Transactions
	WHERE Qty < 0

/* Q3. As you would have noticed, the dates provided across the datasets are not in a correct format. As first steps, pls convert the date variables into valid date 
	   formats before proceeding ahead. */

	   ALTER TABLE Transactions
	   ALTER COLUMN tran_date DATE

-- Q4. What is the time range of the transaction data available for analysis? Show the output in number of days, months and years simultaneously in different columns.

	SELECT DATEDIFF(DAY, MIN(tran_date), MAX(tran_date)) [DAYS] 
	FROM Transactions 

	SELECT DATEDIFF(MONTH, MIN(tran_date), MAX(tran_date)) [MONTHS] 
	FROM Transactions

	SELECT DATEDIFF(YEAR, MIN(tran_date), MAX(tran_date)) [YEARS] 
	FROM Transactions

-- Q5. Which product category does the sub-category �DIY� belong to?

	SELECT prod_cat
	FROM prod_cat_info 
	WHERE prod_subcat = 'DIY'

-- DATA ANALYSIS

-- Q1. Which channel is most frequently used for transactions?

	SELECT TOP 1 Store_type, COUNT(Store_type) [FREQUENCY]
	FROM Transactions 
	GROUP BY Store_type 
	Order by [FREQUENCY] DESC

-- Q2. What is the count of Male and Female customers in the database?
	
	SELECT COUNT(DISTINCT customer_Id)[MALES] 
	FROM Customer
	WHERE Gender = 'M'
	SELECT COUNT(DISTINCT customer_Id)[FEMALES] 
	FROM Customer
	WHERE Gender = 'F'

-- Q3. From which city do we have the maximum number of customers and how many?

	SELECT TOP 1 city_code, COUNT(customer_Id) [COUNT_CUSTOMERS] 
	FROM Customer
	GROUP BY city_code
	ORDER BY [COUNT_CUSTOMERS] DESC

-- Q4. How many sub-categories are there under the Books category?

	SELECT COUNT(Prod_subcat) [SUB_CATEGORIES] 
	FROM prod_cat_info
	GROUP BY prod_cat
	HAVING prod_cat = 'Books'

-- Q5. What is the maximum quantity of products ever ordered?

	SELECT MAX(qty) [MAXIMUM] 
	FROM Transactions

-- Q6. What is the net total revenue generated in categories Electronics and Books?

	SELECT SUM(total_amt) [NET_REVENUE]
	FROM Transactions AS T INNER JOIN prod_cat_info AS P 
	ON T.prod_cat_code = P.prod_cat_code AND T.prod_subcat_code = P.prod_sub_cat_code
	WHERE P.prod_cat IN('Electronics', 'Books')

-- Q7. How many customers have >10 transactions with us, excluding returns?
 
	SELECT COUNT(cust_id) [NO._OF_CUST] 
	FROM(
			SELECT (cust_id) 
			FROM Transactions
			GROUP BY cust_id
			HAVING COUNT(transaction_id)>10
		 )	T1
		 
-- Q8. What is the combined revenue earned from the �Electronics� & �Clothing� categories, from �Flagship stores�?

	SELECT SUM(total_amt) [REVENUE] 
	FROM Transactions AS T INNER JOIN prod_cat_info AS P
	ON T.prod_cat_code = P.prod_cat_code AND T.prod_subcat_code = P.prod_sub_cat_code
	WHERE Store_type = 'Flagship store' AND prod_cat IN('Electronics', 'Clothing')
	
-- Q9. What is the total revenue generated from �Male� customers in �Electronics� category? Output should display total revenue by prod sub-cat.
	
	SELECT DISTINCT prod_subcat, sum(total_amt) [TOTAL REVENUE] 
	FROM Transactions AS T INNER JOIN prod_cat_info AS P
	ON T.prod_subcat_code = P.prod_sub_cat_code INNER JOIN Customer AS C
	ON T.cust_id = C.customer_Id
	WHERE prod_cat = 'Electronics' AND gender = 'M'
	GROUP BY P.prod_subcat
	
-- Q10. What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?
  
	SELECT T1.prod_subcat, [PERCENT_SALES], [PERCENT_RETURNS] 
	FROM
	(	SELECT TOP 5 prod_subcat, SUM(qty) / (SELECT SUM(qty) 
		FROM Transactions) * 0.01 [PERCENT_SALES] 
	FROM Transactions T INNER JOIN prod_cat_info P
	ON T.prod_cat_code = P.prod_cat_code AND T.prod_subcat_code = P.prod_sub_cat_code
	GROUP BY prod_sub_cat_code, prod_subcat
	ORDER BY SUM(qty) DESC)T1 INNER JOIN
	(	SELECT  prod_subcat, SUM(qty) / (SELECT SUM(qty) * 0.01 
		FROM Transactions 
		WHERE qty < 0) [PERCENT_RETURNS]
	FROM Transactions T2 INNER JOIN  prod_cat_info P
	ON T2.prod_subcat_code = P.prod_sub_cat_code
	WHERE qty < 0
	GROUP BY prod_subcat
	) T
	ON T1.prod_subcat = t.prod_subcat
	ORDER BY [PERCENT_SALES], [PERCENT_RETURNS] DESC	

-- Q11. For all customers aged between 25 to 35 years find what is the net total revenue generated by these consumers in last 30 days of transactions from max 
-- transaction date available in the data?
 
	SELECT SUM(total_amt) [NET REVENUE] 
	FROM Customer AS C INNER JOIN Transactions AS T 
	ON C.customer_Id = T.cust_id
	WHERE DATEDIFF(YEAR, DOB, GETDATE()) BETWEEN 25 AND 35 AND tran_date > (DATEADD(DAY, -30, (SELECT MAX(tran_date) FROM transactions)))

-- Q12. Which product category has seen the max value of returns in the last 3 months of transaction?
 
	SELECT TOP 1 prod_cat, SUM(qty) [QUANTITY] 
	FROM Transactions AS T INNER JOIN prod_cat_info AS PC
	ON PC.prod_cat_code = T.prod_cat_code
	WHERE tran_date >= DATEADD(MONTH, -3, (SELECT MAX(tran_date) FROM Transactions)) AND qty < 0
	GROUP BY prod_cat
	ORDER BY [QUANTITY] DESC

-- Q13. Which store-type sells the maximum products; by value of sales amount and by quantity sold?
 
	SELECT TOP 1 Store_type, SUM(total_amt) [AMOUNT], SUM(qty) [QUANTITY] 
	FROM Transactions 
	GROUP BY Store_type
	ORDER BY [AMOUNT] DESC, [QUANTITY] DESC

-- Q14. What are the categories for which average revenue is above the overall average.

	SELECT prod_cat 
	FROM Transactions AS T INNER JOIN prod_cat_info AS PC
	ON T.prod_cat_code = PC.prod_cat_code
	GROUP BY prod_cat
	HAVING AVG(total_amt) > (SELECT AVG(total_amt) FROM Transactions)

-- Q15. Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold.

	WITH cte6 AS
	(	SELECT TOP 5 prod_cat_code 
		FROM Transactions
		GROUP BY prod_cat_code
		ORDER BY SUM(qty) DESC
	)
	SELECT prod_subcat, AVG(total_amt) [AVERAGE_REVENUE], SUM(total_amt) [TOTAL_REVENUE] 
	FROM Transactions T INNER JOIN prod_cat_info PC 
	ON T.prod_subcat_code = PC.prod_sub_cat_code
	WHERE T.prod_cat_code IN(SELECT * FROM cte6)
	GROUP BY prod_subcat
	
	

  









