SELECT* FROM customer_journey
SELECT* FROM customer_reviews
SELECT* FROM customers
SELECT* FROM engagement_data
SELECT* FROM geography
SELECT* FROM products

#2.Data Extraction & Transformation (SQL & Python):
----Write SQL queries to extract relevant data----

A. Extract Customer Details with their Latest Review:

#This query will give you customer details along with their most recent review.
SELECT c.CustomerID, c.CustomerName, c.Email, r.ReviewText, r.Rating, r.ReviewDate
FROM customers c
JOIN customer_reviews r ON c.CustomerID = r.CustomerID
WHERE r.ReviewDate = (
    SELECT MAX(r2.ReviewDate) 
    FROM customer_reviews r2
    WHERE r2.CustomerID = c.CustomerID
);
B.Get Products with Average Ratings:
#This will help you find the average rating of each product.
SELECT p.ProductName, p.Category, ROUND(AVG(r.Rating), 2) AS AverageRating
FROM products p
JOIN customer_reviews r ON p.ProductID = r.ProductID
GROUP BY p.ProductName, p.Category
ORDER BY AverageRating DESC;

C. Find Top 5 Products with Highest Engagement:
#This query shows the top 5 products with the highest engagement based on likes.
SELECT p.ProductName, e.ContentType, SUM(e.Likes) AS TotalLikes, SUM(e.ViewsClicksCombined) AS TotalViews
FROM products p
JOIN engagement_data e ON p.ProductID = e.ProductID
GROUP BY p.ProductName, e.ContentType
ORDER BY TotalLikes DESC
LIMIT 5;

D. Extract Customer Journey with Action Counts:
#Useful for tracking how customers interact with different products at various stages.
SELECT c.CustomerName, j.ProductID, j.Stage, COUNT(j.Action) AS ActionCount
FROM customer_journey j
JOIN customers c ON j.CustomerID = c.CustomerID
GROUP BY c.CustomerName, j.ProductID, j.Stage
ORDER BY ActionCount DESC;

E. Identify Geographic Regions with Highest Sales:
#This will display which regions have the highest customer interactions.
SELECT g.Country, g.City, COUNT(j.CustomerID) AS TotalCustomers
FROM customer_journey j
JOIN customers c ON j.CustomerID = c.CustomerID
JOIN geography g ON c.GeographyID = g.GeographyID
GROUP BY g.Country, g.City
ORDER BY TotalCustomers DESC;
3.Customer Journey & Engagement Analysis (SQL):
----Identify drop-off points in the customer journey----
 A. Count Customers at Each Stage:
 #This will show how many customers are present at each stage:
 SELECT Stage, COUNT(DISTINCT CustomerID) AS CustomerCount
FROM customer_journey
GROUP BY Stage
ORDER BY CustomerCount DESC;
B. Calculate Stage-wise Conversion Rates:
#This query helps you calculate the conversion rate from one stage to the next:
SELECT a.Stage AS CurrentStage, 
       b.Stage AS NextStage,
       COUNT(DISTINCT a.CustomerID) AS CurrentStageCount,
       COUNT(DISTINCT b.CustomerID) AS NextStageCount,
       ROUND((COUNT(DISTINCT b.CustomerID) / COUNT(DISTINCT a.CustomerID)) * 100, 2) AS ConversionRate
FROM customer_journey a
LEFT JOIN customer_journey b 
    ON a.CustomerID = b.CustomerID 
    AND a.VisitDate < b.VisitDate
GROUP BY a.Stage, b.Stage
ORDER BY a.Stage;

C.Analyze Drop-Offs Region-Wise:
If you want to check where most drop-offs are happening geographically:
 SELECT c.Stage, g.Country, COUNT(DISTINCT c.CustomerID) AS DropOffCount
FROM customer_journey c
JOIN customers cu ON c.CustomerID = cu.CustomerID
JOIN geography g ON cu.GeographyID = g.GeographyID
GROUP BY c.Stage, g.Country
ORDER BY DropOffCount DESC;

----Find common actions leading to successful conversions----
A.Identify What a Successful Conversion Means:
#Usually, the final stage like "Purchase" or "Order Completed" is considered a successful conversion.
SELECT DISTINCT CustomerID
FROM customer_journey
WHERE Stage = 'Checkout';

B.Track the Customer Journey
#Extract all actions taken by successfully converted customers using a simple join
SELECT c.CustomerID, c.Stage, c.Action, c.VisitDate
FROM customer_journey c
JOIN (
    SELECT DISTINCT CustomerID
    FROM customer_journey
    WHERE Stage = 'Checkout'
) s ON c.CustomerID = s.CustomerID
ORDER BY c.CustomerID, c.VisitDate;
C.Find Common Actions
# we can group by Action and calculate how frequently each action occurs among converted customers.
SELECT c.Action, COUNT(*) AS ActionFrequency
FROM customer_journey c
JOIN (
    SELECT DISTINCT CustomerID
    FROM customer_journey
    WHERE Stage = 'Checkout'
) s ON c.CustomerID = s.CustomerID
GROUP BY c.Action
ORDER BY ActionFrequency DESC;

----Calculate average duration per stage for engagement insights----
#To calculate the average duration per stage for engagement insights using SQL, you can use the following query:
SELECT Stage, 
       ROUND(AVG(Duration), 2) AS AvgDuration
FROM customer_journey
GROUP BY Stage
ORDER BY AvgDuration DESC;

4.Customer Reviews Analysis (SQL & Python):
----Identify highest-rated and lowest-rated products using SQL----
A.Highest-Rated Products:
SELECT p.ProductID, p.ProductName, AVG(r.Rating) AS AvgRating
FROM products p
JOIN customer_reviews r ON p.ProductID = r.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY AvgRating DESC
LIMIT 5;  -- Top 5 highest-rated products

B. Lowest-Rated Products:
SELECT p.ProductID, p.ProductName, AVG(r.Rating) AS AvgRating
FROM products p
JOIN customer_reviews r ON p.ProductID = r.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY AvgRating ASC
LIMIT 5;  -- Top 5 lowest-rated products

5.Marketing Effectiveness (SQL):
----Calculate customer retention rate----
A.Define the Time Period
#Since you prefer quarterly retention rates, choose a start and end date for the quarter. For example:
Start Date: '2024-01-01'
End Date: '2024-03-31'
B.Initial Customers (Start of the Period):
SELECT COUNT(DISTINCT CustomerID) AS StartCustomers
FROM customer_journey
WHERE VisitDate < '2024-01-01';

C.Remaining Customers (End of the Period):
SELECT COUNT(DISTINCT CustomerID) AS EndCustomers
FROM customer_journey
WHERE VisitDate <= '2024-03-31';

D.New Customers (During the Period):
SELECT COUNT(DISTINCT c.CustomerID) AS NewCustomers
FROM customer_journey c
WHERE VisitDate BETWEEN '2024-01-01' AND '2024-03-31'
AND NOT EXISTS (
    SELECT 1 FROM customer_journey cj
    WHERE cj.CustomerID = c.CustomerID
    AND cj.VisitDate < '2024-01-01'
);

E.Calculate the Retention Rate
SELECT 
    ROUND(((EndCustomers - NewCustomers) / StartCustomers) * 100, 2) AS RetentionRate
FROM (
    SELECT 
        (SELECT COUNT(DISTINCT CustomerID) FROM customer_journey WHERE VisitDate < '2024-01-01') AS StartCustomers,
        (SELECT COUNT(DISTINCT CustomerID) FROM customer_journey WHERE VisitDate <= '2024-03-31') AS EndCustomers,
        (SELECT COUNT(DISTINCT c.CustomerID)
         FROM customer_journey c
         WHERE VisitDate BETWEEN '2024-01-01' AND '2024-03-31'
         AND NOT EXISTS (
             SELECT 1 FROM customer_journey cj
             WHERE cj.CustomerID = c.CustomerID
             AND cj.VisitDate < '2024-01-01'
         )
        ) AS NewCustomers
) AS Metrics;

----Compare repeat vs. first-time buyers----

A.Identify First-Time Buyers
#First-time buyers are customers who have made only one purchase.
SELECT CustomerID
FROM customer_journey
GROUP BY CustomerID
HAVING COUNT(DISTINCT ProductID) = 1;

B. Identify Repeat Buyers
#Repeat buyers are customers who have made more than one purchase.
SELECT CustomerID
FROM customer_journey
GROUP BY CustomerID
HAVING COUNT(DISTINCT ProductID) > 1;

C.Compare First-Time vs. Repeat Buyers
#You can combine both results using a CASE statement for a clearer comparison.
SELECT 
    CustomerID,
    COUNT(DISTINCT ProductID) AS TotalProductsPurchased,
    CASE
        WHEN COUNT(DISTINCT ProductID) = 1 THEN 'First-Time Buyer'
        ELSE 'Repeat Buyer'
    END AS BuyerType
FROM customer_journey
GROUP BY CustomerID;

----Find best-performing products per region----
#This Queries will give you the best-performing products based on customer ratings per region.

SELECT g.Country, g.City, p.ProductName, AVG(r.Rating) AS AvgRating
FROM customer_reviews r
JOIN customers c ON r.CustomerID = c.CustomerID
JOIN geography g ON c.GeographyID = g.GeographyID
JOIN products p ON r.ProductID = p.ProductID
GROUP BY g.Country, g.City, p.ProductName
ORDER BY g.Country, g.City, AvgRating DESC;













