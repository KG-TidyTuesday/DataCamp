
###########################################################################
# Improving Query Performance in SQL Server
###########################################################################
# Chapter 1: 
###########################################################################

###################################################################################################
# Instructions:
# Change all SQL syntax (clauses, operators, and functions) to UPPERCASE.
#  Make sure all SQL syntax begins on a new line.
# Add an indent to the calculated BMI column and OR statement.

SELECT PlayerName, 
        Country,
        ROUND(Weight_kg/SQUARE(Height_cm/100),2) BMI
    FROM Players 
    WHERE Country = 'USA'
         OR Country = 'Canada'
    ORDER BY BMI;

###################################################################################################
# Instructions:
# Create a comment block on lines 1 and 4.
# Add the above comment to the block.
# Comment out the ORDER BY statement and add Order by not required comment on the same line.
# Add ; directly after 'Canada' to indicate the new ending of the query.
#####################################################################################################
/*
Returns the Body Mass Index (BMI) for all North American players from the 2017-2018 NBA season


*/
SELECT PlayerName, Country,
    ROUND(Weight_kg/SQUARE(Height_cm/100),2) BMI 
FROM Players 
WHERE Country = 'USA'
    OR Country = 'Canada';
--ORDER BY BMI; Order by not required



-- Your friend's query
-- First attempt, contains erros and incosistent formaating;

/*select PlayerName, p.Country,sum(ps.TotalPoints) 
AS TotalPoints  
FROM PlayerStats ps inner join Players On ps.PlayerName = p.PlayerName
WHERE p.Country = 'New Zeeland'
Group 
by PlayerName, Country
order by Country;
*/


-- Seconf attempt - errors corrected and formatting fixed
-- Your query
SELECT p.PlayerName, p.Country,
		SUM(ps.TotalPoints) AS TotalPoints  
    FROM PlayerStats ps 
    INNER JOIN Players p
    	ON ps.PlayerName = p.PlayerName
    WHERE p.Country = 'New Zealand'
    GROUP BY p.PlayerName, p.Country;

#################################################################################
# Aliasing
################################################################################

SELECT Team, 
   ROUND(AVG(BMI),2) AS AvgTeamBMI -- Alias the new column
FROM PlayerStats AS ps -- Alias PlayerStats table
INNER JOIN
		(SELECT PlayerName, Country,
			Weight_kg/SQUARE(Height_cm/100) BMI
		 FROM Players) AS  p -- Alias the sub-query
             -- Alias the joining columns
	ON ps.PlayerName = p.PlayerName 
GROUP BY Team
HAVING AVG(BMI) >= 25;


#################################################################################
# Query Order
################################################################################

/*
Returns earthquakes in New Zealand with a magnitude of 7.5 or more
*/
SELECT Date, Place, NearestPop, Magnitude
    FROM Earthquakes
    WHERE Country = 'NZ'
    	AND Magnitude >= 7.5
    ORDER BY Magnitude DESC;

/*
Location of the epicenter of earthquakes with a 9+ magnitude
*/

-- Replace City with the correct column name
SELECT n.CountryName AS Country
	,e.NearestPop AS ClosestCity
    ,e.Date
    ,e.Magnitude
FROM Nations AS n
INNER JOIN Earthquakes AS e
	ON n.Code2 = e.Country
WHERE e.Magnitude >= 9
ORDER BY e.Magnitude DESC;

##############################################################################################
# Chapter 2: where condition
##############################################################################################

-- Second query

-- Add the new column to the select statement
SELECT PlayerName, 
       Team, 
       Position, 
       AvgRebounds -- Add the new column
FROM
     -- Sub-query starts here                             
	(SELECT 
      PlayerName, 
      Team, 
      Position,
      -- Calculate average total rebounds
     (DRebound+ORebound)/CAST(GamesPlayed AS numeric) AS AvgRebounds
	 FROM PlayerStats) tr
WHERE AvgRebounds >= 12; -- Filter rows

###################################################################################################

SELECT PlayerName, 
      Country, 
      College, 
      DraftYear, 
      DraftNumber 
FROM Players
-- WHERE UPPER(LEFT(College,5)) LIKE 'LOU%'
WHERE College LIKE 'Louisiana%'; -- Add the wildcard filter

######################################################################################################
# Filtering with HAVING
########################################################################################################
# Do not use having to filter individual or ungrouped rows
# use where to filter individual rows and having for a numeric filter on grouped rows
# Having can only be applied to a numeric column in an aggrigate function filter
#######################################################################################################

SELECT Country, COUNT(*) CountOfPlayers
FROM Players
-- Add the filter condition
WHERE Country
-- Fill in the missing countries
	IN ('Argentina','Brazil','Dominican Republic'
        ,'Puerto Rico')
GROUP BY Country;

##############################################################################################
SELECT Team, 
	SUM(TotalPoints) AS TotalPFPoints
FROM PlayerStats
-- Filter for only rows with power forwards
WHERE Position = 'PF'
GROUP BY Team
-- Filter for total points greater than 3000
HAVING SUM(TotalPoints) > 3000;


SELECT latitude, -- Y location coordinate column
       longitude, -- X location coordinate column
	   magnitude , -- Earthquake strength column
	   depth, -- Earthquake depth column
	   NearestPop -- Nearest city column
FROM Earthquakes
WHERE Country = 'PG' -- Papua New Guinea country code
	OR Country = 'ID'; -- Indonesia country code

###################################################################################

SELECT TOP 10 -- Limit the number of rows to ten
      Latitude,
      Longitude,
	  Magnitude,
	  Depth,
	  NearestPop
FROM Earthquakes
WHERE Country = 'PG'
	OR Country = 'ID'
ORDER BY Depth ; -- Order results from shallowest to deepest

#######################################################################################


SELECT TOP 25 PERCENT -- Limit rows to the upper quartile
       Latitude,
       Longitude,
	   Magnitude,
	   Depth,
	   NearestPop
FROM Earthquakes
WHERE Country = 'PG'
	OR Country = 'ID'
ORDER BY Magnitude DESC; -- Order the results

########################################################################################
# Managing duplicates
########################################################################################



SELECT DISTINCT(NearestPop),-- Remove duplicate city
		Country
FROM Earthquakes
WHERE Magnitude >= 8 -- Add filter condition 
	AND NearestPop IS NOT NULL
ORDER BY NearestPop;

#  You can use DISTINCT() to remove duplicate rows.
#  If you want to apply an aggregate function DISTINCT() is not required 
#  and you can just use GROUP BY instead.


#############################################################################################
#  UNION and UNION ALL
#############################################################################################

SELECT NearestPop, 
       Country, 
       Count(NearestPop) NumEarthquakes -- Number of cities
FROM Earthquakes
WHERE Magnitude >= 8
	AND Country IS NOT NULL
GROUP BY Country, NearestPop -- Group columns
ORDER BY NumEarthquakes DESC;


SELECT CityName AS NearCityName, -- City name column
	   CountryCode
	FROM Cities
UNION -- Append queries
	SELECT Capital AS NearCityName, -- Nation capital column
       Code2 AS CountryCode
	FROM Nations;

######################################################################################
SELECT CityName AS NearCityName,
	   CountryCode
FROM Cities

UNION ALL -- Append queries

SELECT Capital AS NearCityName,
       Code2 AS CountryCode  -- Country code column
FROM Nations;

# UNION ALL returns more rows than UNION because it does not remove duplicates.
#  Therefore, duplicate rows were

# Even queries you think that are good may return unwanted duplicate rows. 
# Before starting a project in SQL make sure you have a good understanding of
# what the database contains and ensure you perform a thorough interrogation of the data sets 
# you will be using.


########################################################################################################################
# Chapter 3: Sub-Queries
########################################################################################################
# Uncorrelated sub-query
# A sub-query is another query within a query. 
# The sub-query returns its results to an outer query to be processed.

#################################################################################################
# Sub-quieries used in WHERE
################################################################################################

SELECT UNStatisticalRegion,
       CountryName 
FROM Nations
WHERE Code2 -- Country code for outer query 
         IN (SELECT Country -- Country code for sub-query
             FROM Earthquakes
             WHERE depth >=  400 ) -- Depth filter
ORDER BY UNStatisticalRegion;

#  In uncorrelated sub-queries, the sub-query does not reference the outer query
#  and therefore can run independently of the outer query.

#################################################################################################
# Sub-quieries used in SELECT
################################################################################################
SELECT UNContinentRegion,
       CountryName, 
        (SELECT AVG(Magnitude) -- Add average magnitude
        FROM Earthquakes e 
         	  -- Add country code reference
        WHERE n.Code2 = e.Country) AS AverageMagnitude 
FROM Nations n
ORDER BY UNContinentRegion DESC, 
         AverageMagnitude DESC;

#  In correlated sub-queries, the outer query is referenced in the sub-query. 
# In this example, Code2, from the Nations table, is referenced in the sub-query.

#################################################################################################
# Sub-quieries used in SELECT
################################################################################################
SELECT
	n.CountryName,
	 (SELECT MAX(c.Pop2017) -- Add 2017 population column
	 FROM Cities AS c 
                       -- Outer query country code column
	 WHERE c.CountryCode = n.Code2) AS BiggestCity
FROM Nations AS n; -- Outer query table


SELECT n.CountryName, 
       c.BiggestCity 
FROM Nations AS n
INNER JOIN -- Join the Nations table and sub-query
    (SELECT CountryCode, 
     MAX(Pop2017) AS BiggestCity 
     FROM Cities
     GROUP BY CountryCode) AS c
ON n.Code2 = c.CountryCode; -- Add the joining columns

# Sub-queries and INNER JOIN's can be used to return the same results.
#  However, in practice large, complex queries may contain lots of sub-queries, 
# many of which could be re-written as INNER JOIN's to improve performance.

###########################################################################################################
# Presence and absence
######################################################################################################


SELECT Capital
FROM Nations -- Table with capital cities

INTERSECT-- Add the operator to compare the two queries

SELECT NearestPop -- Add the city name column
FROM Earthquakes;

#################################################################################

SELECT Code2-- Add the country code column
FROM Nations

EXCEPT -- Add the operator to compare the two queries

SELECT Country 
FROM Earthquakes; -- Table with country codes

##################################################################################
SELECT CountryName 
FROM Nations -- Table from Earthquakes database

INTERSECT -- Operator for the intersect between tables

SELECT Country
FROM Players; -- Table from NBA Season 2017-2018 database

##################################################################
# Alternative methods
#####################################################################

-- First attempt
SELECT CountryName,
       Pop2017, -- 2017 country population
	   Capital, -- Capital city	   
       WorldBankRegion
FROM Nations
WHERE Capital IN -- Add the operator to compare queries
        (SELECT NearestPop 
	     FROM Earthquakes);

################################################################
-- Second attempt
SELECT CountryName,   
	   Capital,
       Pop2016, -- 2016 country population
       WorldBankRegion
     FROM Nations AS n
     WHERE EXISTS -- Add the operator to compare queries
	  (SELECT 1
	   FROM Earthquakes AS e
	   WHERE n.Capital = e.NearestPop); -- Columns being compared

# IN and EXISTS are the appropriate operators to use here. 
# Their advantage over INTERSECT is that the results can contain any column
# from the outer query in any order, the population column appears after the capital city column now.


SELECT WorldBankRegion,
       CountryName
FROM Nations
WHERE Code2 NOT IN -- Add the operator to compare queries
	(SELECT CountryCode -- Country code column
	 FROM Cities);


SELECT WorldBankRegion,
       CountryName,
	   Code2,
       Capital, -- Country capital column
	   Pop2017
FROM Nations AS n
WHERE NOI EXISTS -- Add the operator to compare queries
	(SELECT 1
	 FROM Cities AS c
	 WHERE n.Code2 = c.CountryCode); -- Columns being compared

#######################################################################################
SELECT WorldBankRegion,
       CountryName,
	   Code2,
       Capital, -- Country capital column
	   Pop2017
FROM Nations AS n
WHERE NOT EXISTS -- Add the operator to compare queries
	(SELECT 1
	 FROM Cities AS c
	 WHERE n.Code2 = c.CountryCode); -- Columns being compared

###############################################################################

SELECT WorldBankRegion,
       CountryName,
       Capital -- Capital city name column
FROM Nations
WHERE Capital NOT IN
	(SELECT NearestPop -- City name column
     FROM Earthquakes);


SELECT WorldBankRegion,
       CountryName,
       Capital
FROM Nations
WHERE Capital NOT IN
	(SELECT NearestPop
     FROM Earthquakes
     WHERE NearestPop IS NOT NULL); -- filter condition


##################################################################################################
# One major issue with using NOT IN is the way it handles NULL values.
# If the columns in the sub-query being evaluated for a non-match contain NULL values,
#  no results are returned. A workaround to get the query working correctly is to
#  use IS NOT NULL in a WHERE filter condition in the sub-query.
#############################################################################################



-- Initial query
SELECT TeamName,
       TeamCode,
	   City
FROM Teams AS t -- Add table
WHERE EXISTS -- Operator to compare queries
      (SELECT 1 
	  FROM Earthquakes AS e -- Add table
	  WHERE t.City = e.NearestPop);

-- Second query
SELECT t.TeamName,
       t.TeamCode,
	   t.City,
	   e.Date,
	   e.Place, -- Place description
	   e.Country -- Country code
FROM Teams AS t
INNER JOIN Earthquakes AS e -- Operator to compare tables
	  ON t.City = e.NearestPop


-- First attempt
SELECT c.CustomerID,
       c.CompanyName,
	   c.ContactName,
	   c.ContactTitle,
	   c.Phone 
FROM Customers c
LEFT OUTER JOIN Orders o -- Joining operator
	ON c.CustomerID = o.CustomerID -- Joining columns
WHERE c.Country = 'France';


-- Second attempt
SELECT c.CustomerID,
       c.CompanyName,
	   c.ContactName,
	   c.ContactTitle,
	   c.Phone 
FROM Customers c
LEFT OUTER JOIN Orders o
	ON c.CustomerID = o.CustomerID
WHERE c.Country = 'France'
	AND o.CustomerID IS NULL; -- Filter condition

###########################################################################################################
# Chapter 4: Time Statistics
########################################################################################################


SET STATISTICS TIME ON -- Turn the time command on


-- Query 1
SELECT * 
FROM Teams
-- Sub-query 1
WHERE City IN -- Sub-query filter operator
      (SELECT CityName 
       FROM Cities) -- Table from Earthquakes database
-- Sub-query 2
   AND City IN -- Sub-query filter operator
	   (SELECT CityName 
	    FROM Cities
		WHERE CountryCode IN ('US','CA'))
-- Sub-query 3
    AND City IN -- Sub-query filter operator
        (SELECT CityName 
         FROM Cities
	     WHERE Pop2017 >2000000);


###################################################################################

-- Query 2
SELECT * 
FROM Teams AS t
WHERE EXISTS -- Sub-query filter operator
	(SELECT 1 
     FROM Cities AS c
     WHERE t.City = c.CityName-- Columns being compared
        AND c.CountryCode IN ('US','CA')
          AND c.Pop2017 > 2000000);

SET STATISTICS TIME OFF

###############################################################################
# Page read Statistics
###############################################################################

SET STATISTICS IO ON-- Turn the IO command on

-- Example 1
SELECT CustomerID,
       CompanyName,
       (SELECT COUNT(*) 
	    FROM Orders AS o -- Add table
		WHERE c.CustomerID = o.CustomerID) CountOrders
FROM Customers AS c
WHERE CustomerID IN -- Add filter operator
       (SELECT CustomerID 
	    FROM Orders 
		WHERE ShipCity IN
            ('Berlin','Bern','Bruxelles','Helsinki',
			'Lisboa','Madrid','Paris','London'));



-- Example 2
SELECT c.CustomerID,
       c.CompanyName,
       COUNT(o.CustomerID)
FROM Customers AS c
INNER JOIN Orders AS o -- Join operator
    ON c.CustomerID = o.CustomerID
WHERE o.ShipCity IN -- Shipping destination column
     ('Berlin','Bern','Bruxelles','Helsinki',
	 'Lisboa','Madrid','Paris','London')
GROUP BY c.CustomerID,
         c.CompanyName;

##################################################################################################
# INDEXES
###################################################################################################


-- Query 1
SELECT *
FROM Cities
WHERE CountryCode = 'RU' -- Country code
		OR CountryCode = 'CN'-- Country code

-- Query 2
SELECT *
FROM Cities
WHERE CountryCode IN ('JM','NZ') -- Country codes










