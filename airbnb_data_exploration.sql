---- Finding trends in NY airbnb data, mainly exploring the effects of seasonality and differences between the boroughs/counties on pricing and review data. ----

select * from airbnb_data
limit 100;

----  Listing volumes ----                          

-- Listings per borough

select 
borough, count(*) as listings from airbnb_data
group by borough

-- Listing volumes per year

select
extract(year from last_review) as year,
count(*) as listings 
from airbnb_data
where extract(year from last_review) < 2024
group by extract(year from last_review)
order by 1 asc ;




---- Finding average review score and price information per New York borough ----

-- Overall price averages

select
avg(price) as avg_price,
min(price) as min_price,
max(price) as max_price,
percentile_cont(0.5) within group (order by price) as median_price
from airbnb_data;

-- Review scores and prices per borough

select 
avg(review_rate_number) as avg_review_score,
avg(price) as avg_price, borough 
from airbnb_data
group by borough
order by 2 desc;

-- Cost per review star in each borough (finding best value for money)

select 
(avg(price) / avg(review_rate_number)) as cost_per_review_star,
borough from airbnb_data
group by borough
order by 1 asc;

---- Finding if verification status affects price ----

select
avg(price), borough, host_identity_verified
from airbnb_data
group by borough, host_identity_verified;







---- Seasonality analysis ----

-- Bookings per month (using last review date as booking date proxy, though it may not be a valid representation)
select
extract(month from last_review) as month, 
count(*) as bookings
from airbnb_data
where last_review is not null
group by month
order by month asc;

-- Pricing per month and year

select
extract(month from last_review) as month,
extract(year from last_review) as year,
round(avg(price), 2) as avg_price
from airbnb_data
where last_review is not null
and extract(year from last_review) < 2024
group by month, year
order by month, year asc;

-- Bookings per season

select
case
	when extract(month from last_review) in (12, 1, 2) then 'Winter' 
	when extract(month from last_review) in (3, 4, 5) then 'Spring'
	when extract(month from last_review) in (6, 7, 8) then 'Summer'
	else 'Autumn'
end as season,
count(*) as bookings
from airbnb_data
group by season
order by 2 desc;

-- Pricing per season and year
select
    case
	when extract(month from last_review) in (12, 1, 2) then 'Winter' 
	when extract(month from last_review) in (3, 4, 5) then 'Spring'
	when extract(month from last_review) in (6, 7, 8) then 'Summer'
	else 'Autumn'
end as season,
extract(year from last_review) as year,
round(avg(price), 2) as avg_price
from airbnb_data
where last_review is not null
and extract(year from last_review) < 2024
group by season, year
order by 1, 2 asc

-- Yearly price changes

select
extract(year from last_review) as year,
round(avg(price), 2) as avg_price
from airbnb_data
where last_review is not null
and extract(year from last_review) < 2024
group by year

select
	year,
	avg_price,
	lag(avg_price) over (order by year) as prev_year_avg_price,
	(avg_price - lag(avg_price) over (order by year)) as price_change,
	round(
		((avg_price - lag(avg_price) over (order by year)) / lag(avg_price) over (order by year))
	 * 100, 2) as price_change_percentage
from 	
(select
extract(year from last_review) as year,
round(avg(price), 2) as avg_price
from airbnb_data
where last_review is not null
and extract(year from last_review) < 2024
group by year
) yearly_price_averages

		  	  


-- Yearly price changes compared to inflation and HPI using a cte and join

create table InflationHousing_data 
(year int,
 Inflation_US_WorldBank decimal,
 HPI_appreciation_FreddieMac decimal
 );
 
 copy InflationHousing_data 
 from 'C:\Program Files\PostgreSQL\16\data\inflation_data.csv'
 delimiter ','
 csv header; 



with price_change_cte as
	(select
	year,
	avg_price,
	lag(avg_price) over (order by year) as prev_year_avg_price,
	(avg_price - lag(avg_price) over (order by year)) as price_change,
	round(
		((avg_price - lag(avg_price) over (order by year)) / lag(avg_price) over (order by year))
	 * 100, 2) as price_change_percentage
	from 	
		(select
		extract(year from last_review) as year,
		round(avg(price), 2) as avg_price
		from airbnb_data
		where last_review is not null
		and extract(year from last_review) < 2024
		group by year
		) yearly_price_averages
	)
select 
pcc.year,
pcc.price_change_percentage,
ihd.inflation_us_worldbank,
ihd.hpi_appreciation_freddiemac
from price_change_cte as pcc
join inflationhousing_data as ihd
on pcc.year=ihd.year
order by pcc.year
	


