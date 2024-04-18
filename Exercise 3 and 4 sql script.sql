--Exercie 3
--First I changed the column names on the countries table:

ALTER TABLE countries
RENAME COLUMN "Birthrate" TO birthrate;

ALTER TABLE countries
RENAME COLUMN "Deathrate" TO deathrate;

ALTER TABLE countries
RENAME COLUMN "Agriculture" TO agriculture;

ALTER TABLE countries
RENAME COLUMN "Industry" TO industry;

ALTER TABLE countries
RENAME COLUMN "Service" TO service;

ALTER TABLE countries
RENAME COLUMN "Country" TO country;

ALTER TABLE countries
RENAME COLUMN "Region" TO region;

ALTER TABLE countries
RENAME COLUMN "Population" TO population;

ALTER TABLE countries
RENAME COLUMN "Climate" TO climate;

ALTER TABLE countries
RENAME COLUMN pop_density TO pop_density_sq_mi;

ALTER TABLE countries
RENAME COLUMN "Area (sq. mi.)" TO area_sq_mi;

ALTER TABLE countries
RENAME COLUMN "Coastline (coast/area ratio)" TO coastline_ratio;

ALTER TABLE countries
RENAME COLUMN "Net migration" TO net_migration;

ALTER TABLE countries
RENAME COLUMN "Infant mortality (per 1000 births)" TO infant_mortality;

ALTER TABLE countries
RENAME COLUMN "GDP ($ per capita)" TO gdp_percapita;

ALTER TABLE countries
RENAME COLUMN "Literacy (%)" TO literacy_perc;

ALTER TABLE countries
RENAME COLUMN "Phones (per 1000)" TO phones_perthousands;

ALTER TABLE countries
RENAME COLUMN "Arable (%)" TO arable_perc;

ALTER TABLE countries
RENAME COLUMN "Crops (%)" TO crops_perc;

ALTER TABLE countries
RENAME COLUMN "Other (%)" TO other_perc;

--Removed the space at the end of the country name in the contry column in the countries database.
 
UPDATE countries
SET country = RTRIM(country);

--Created a new column to store the first day of the year-week in date format, as the year week values to date format as these were stored as text.

ALTER TABLE covid_data
ADD COLUMN year_week_date date;
 
UPDATE covid_data
SET year_week_date = TO_DATE(year_week, 'IYYY-IW');

--Create view query:
CREATE VIEW covid_cases_per_country AS
SELECT 
    c.country, c.region, c.population, c.area_sq_mi,
    c.pop_density_sq_mi, c.coastline_ratio,
    c.net_migration, c.infant_mortality,
    c.gdp_percapita, c.literacy_perc, c.phones_perthousands, c.arable_perc,
    c.crops_perc, c.other_perc, c.climate, c.birthrate, c.deathrate,
    c.agriculture, c.industry, c.service, o.weekly_count, 
SUM (o.cumulative_count) OVER (
ORDER BY year_week_date
ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
) AS cumulative_number_for_14_days_of_COVID_19_cases_per_100000,
o.year_week, o.year_week_date
FROM 
countries c
JOIN 
covid_data o
ON
c.country = o.country
WHERE
o.indicator = 'cases'
ORDER BY year_week_date;

--Exercise 4

--Point 1 What is the country with the highest number of Covid-19 cases per 100 000 Habitants at 31/07/2020
--Here I had to further alter the column types to accomplish the exercise. Converted the weekly_count, cumulative_count and pop_density_sq_mi to numeric formats and then I had to recreate the view. 
ALTER TABLE covid_data
ALTER COLUMN weekly_count TYPE integer
 

ALTER TABLE covid_data
ALTER COLUMN cumulative_count TYPE integer

ALTER TABLE covid_data
ALTER COLUMN pop_density_sq_mi TYPE double precision;

--SELECT query:
SELECT
    country,
    SUM(cumulative_number_for_14_days_of_COVID_19_cases_per_100000) AS total_cases_per_100k_hab
FROM covid_cases_per_country
WHERE year_week_date <= '2020-07-27'
GROUP BY country
ORDER BY total_cases_per_100k_hab DESC
LIMIT 1;

--Point 2 What is the top 10 countries with the lowest number of Covid-19 cases per 100 000 Habitants at 31/07/2020? 

SELECT
    country,
    SUM(cumulative_number_for_14_days_of_COVID_19_cases_per_100000) AS total_cases_per_100k_hab
FROM covid_cases_per_country
WHERE year_week_date <= '2020-07-27'
GROUP BY country
ORDER BY total_cases_per_100k_hab ASC
LIMIT 10;

--Point 3 What is the top 10 countries with the highest number of cases among the top 20 richest countries (by GDP per capita)?

WITH top20_gdpcountries AS (
	SELECT
    	country,
    	SUM(weekly_count) AS total_cases, 
		MAX(gdp_percapita) as gdp_percapita
	FROM covid_cases_per_country
	GROUP BY country
	ORDER BY gdp_percapita DESC 
	LIMIT 20
)
SELECT 
	country,
	total_cases,
	gdp_percapita
FROM top20_gdpcountries
ORDER BY total_cases DESC
LIMIT 10;

--Point 4 List all the regions with the number of cases per million of inhabitants and display information on population density, for 31/07/2020. 
--For this query I had to transform the values of the pop_density_sq_mi column as they were comma separated values. I used the following queries to create a new column with the transformed values with “.” as their decimal separator. 

ALTER TABLE countries
ADD COLUMN pop_density_numeric numeric;
 
UPDATE countries
SET pop_density_numeric = REPLACE(pop_density_sq_mi, ',', '.')::numeric;
 
ALTER TABLE countries 
DROP COLUMN pop_density_sq_mi;
 
ALTER TABLE countries
RENAME COLUMN pop_density_numeric TO pop_density_sq_mi;

SELECT
    region,
    SUM(cumulative_number_for_14_days_of_covid_19_cases_per_100000) * 10 AS cases_per_million,
    SUM (pop_density_sq_mi) AS population_density
FROM
    covid_cases_per_country
WHERE
    year_week = '2020-31'
GROUP BY
    region
ORDER BY
    cases_per_million DESC;
--Point 5 Query the data to find duplicated records.
--For the covid data table I was able to run two queries using the following considerations:
/*1st query includes the columns country, weekly_count, cumulative_count, rate_14_day and year_week. 
It brings back 532 duplicate rows.*/

WITH covid_data_duplicates AS (
	SELECT country, weekly_count, cumulative_count, rate_14_day, year_week, COUNT(*) AS duplicate_count
	FROM covid_data
	GROUP BY country, weekly_count, cumulative_count, rate_14_day, year_week
	HAVING COUNT(*) > 1
)
SELECT 
	SUM(duplicate_count) AS total_duplicates
FROM covid_data_duplicates;

/* 2nd query only considers columns country, weekly_count and year week. 
It brings back 592 duplicate rows. To which I think is mostly influenced by weekly_counts 
with null values and some of them with actual duplicate counts for the same week 
(submitting the same weekly count record more than once). 
I consider this query to be the most accurate as the other columns: 
cumulative_count and rate_14_day are derived from the column weekly_count. */

WITH covid_data_duplicates AS (
	SELECT country, weekly_count, year_week, COUNT(*) AS duplicate_count
	FROM covid_data
	GROUP BY country, weekly_count, year_week
	HAVING COUNT(*) > 1
)
SELECT 
SUM(duplicate_count) AS total_duplicates
FROM covid_data_duplicates;
