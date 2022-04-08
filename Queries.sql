--Drill down and Roll up (2 queries, Eric)

--Drill down (drilling down from Region to Country):
Select count (*), F.death_rate_per_1000, C.region, C.continent, C.short_name, D.year_num
From fact_table as F, date as D, country as C
Where F.country_key = C.country_key and F.date_key = D.date_key and D.year_num = '2018'
Group by (F.death_rate_per_1000, D.year_num, C.region, C.continent, C.short_name)
Order by F.death_rate_per_1000, C.region, C.continent, C.short_name;

--Roll up (rolling up from Day to Year):
Select count (*), F.birth_rate_per_1000, C.short_name, D.day_num, D.month_num, D.quarter, D.year_num
From fact_table as F, date as D, country as C
Where F.country_key = C.country_key and F.date_key = D.date_key and D.year_num = '2018'
Group by F.birth_rate_per_1000, C.short_name, rollup (D.day_num, D.month_num, D.quarter, D.year_num)
Order by D.day_num, D.month_num, D.quarter, D.year_num;


--Slice (1 query, Radhika)

--Contrast life expectancy of different countries (filter on year):
SELECT D.year_num, C.country_code, F.life_expectancy_at_birth
FROM fact_table as F, date as D, country as C
WHERE F.country_key = C.country_key and F.date_key = D.date_key and D.year_num = 2016
GROUP BY (D.year_num, C.country_code, F.life_expectancy_at_birth)
ORDER BY F.life_expectancy_at_birth


--Dice (2 queries, Chris)

--Contrast average HDI between countries with percent population in urban areas < 80% and primary school enrollment percentage < 90% (dice on population and education):
select short_name, avg(human_development_index)
from fact_table, country, education, population
where
country.country_key = fact_table.country_key and
education.education_key = fact_table.education_key and
population.population_key = fact_table.population_key and
percent_demographics_in_urban < 80 and
school_enrollment_primary_percentage_gross < 90
group by short_name;

--Contrast average GDP between countries with a total unemployment percentage < 8% and at least 95% of the population with access to basic drinking water (dice on economy and quality of life):
select short_name, avg(gdp)
from fact_table, country, economy, quality_of_life
where
country.country_key = fact_table.country_key and
economy.economy_key = fact_table.economy_key and
quality_of_life.quality_of_life_key = fact_table.quality_of_life_key and
total_unemployment_percentage < 8 and
access_at_least_drinking_basic_water_percentage > 95
group by short_name;


--Combined Operations (4 queries, Eric 1, Chris 1, Radhika 2)

--Compare GDP between Canada and Nicaragua in 2019 (drill down and dice):
Select count (*), F.gdp, C.region, C.continent, C.short_name, D.year_num
From fact_table as F, date as D, country as C
Where F.country_key = C.country_key and F.date_key = D.date_key and D.year_num = '2019' and (C.short_name = 'Canada' or C.short_name = 'Nicaragua')
Group by (F.gdp, D.year_num, C.region, C.continent, C.short_name);

--Compare life expectancy at birth of different regions (rollup and slice):
SELECT D.year_num, C.region, F.life_expectancy_at_birth
FROM fact_table as F, date as D, country as C
WHERE F.country_key = C.country_key and F.date_key = D.date_key and D.year_num = 2016
GROUP BY (D.year_num, C.country_code, F.life_expectancy_at_birth), ROLLUP (C.region, C.country_code)
ORDER BY (F.life_expectancy_at_birth)

--Compare average HDI of countries in Latin America and the Middle East (Rollup and Slice):
select region, short_name, avg(human_development_index)
from fact_table, country
where
fact_table.country_key = country.country_key and
(region = 'Latin America & Caribbean' or region = 'Middle East & North Africa')
group by rollup(region, short_name)
order by region, short_name;

--Death rate per 1000 of countries with mortality_cvd_cancer_diabetes_crd_30_to_70_year_olds_percentage > 15 past 2010 (Rollup and Dice):
SELECT DISTINCT D.year_num, C.region, F.death_rate_per_1000
FROM fact_table F, country C, date D, health H
WHERE F.date_key = D.date_key and F.country_key = C.country_key and
H.health_key = F.health_key and H.mortality_cvd_cancer_diabetes_crd_30_to_70_year_olds_percentage > 15
and D.year_num > 2010
group by (D.year_num, C.region, F.death_rate_per_1000), ROLLUP (c.region, c.country_code)
order by (F.death_rate_per_1000);


--Iceberg (1 query, Eric)

--Countries with at least a 0.6 Human Development Index:
select distinct year_num, short_name, human_development_index
from fact_table, date, country
where
date.date_key = fact_table.date_key and
country.country_key = fact_table.country_key and
human_development_index >= 0.6
order by short_name, year_num


--Windowing (1 query, Chris)

--Compare the life expectancy at birth of countries with the average of countries in the same region (for every day):
select region, short_name, life_expectancy_at_birth,
avg(life_expectancy_at_birth) over (partition by region) as avg_life_expectancy
from fact_table, country
where
country.country_key = fact_table.country_key;


--Window clause (1 query, Radhika)

--Accumulated average of GDP per country over time:
select DISTINCT year_num, country_code, gdp, avg(gdp) over W as rolling_avg_gdp
from fact_table F, date D, country C
where F.date_key = D.date_key and F.country_key = C.country_key
window W as (partition by country_code order by year_num)
order by country_code, year_num;
