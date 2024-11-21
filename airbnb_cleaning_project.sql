---- Creating Table ----

Create Table AirBNB_Data 
(id int,
 listing_name varchar(5000),
 host_id bigint,
 host_identity_verified varchar(50),
 host_name varchar(50),
 neighbourhood_group varchar(50),
 neighbourhood varchar(50),
 lat numeric,
 long numeric,
 country varchar(50),
 country_code varchar(5),
 instant_bookable varchar(10),
 cancellation_policy varchar(20),
 room_type varchar(50),
 Construction_year int,
 price varchar(50),
 service_fee varchar(50),
 minimum_nights int,
 number_of_reviews int,
 last_review date,
 reviews_per_month decimal,
 review_rate_number smallint,
 calculated_host_listings_count smallint,
 availability_365 smallint,
 house_rules varchar(5000)
 );
 
 COPY AirBNB_Data
 FROM 'C:\Program Files\PostgreSQL\16\data\Airbnbdata.csv'
 DELIMITER ','
 CSV HEADER; 
 
 -- Replacing '~' with ',' as opposite was done in Excel for CSV import
update airbnb_data
set 
price = replace(price , '~',','), 
service_fee = replace(service_fee, '~',','),
neighbourhood = replace(neighbourhood, '~',','),
listing_name = replace(listing_name, '~',',') ,
house_rules = replace(house_rules, '~',',');

select * from airbnb_data;



---- Converting monetary columns from text to integer data types ----

-- Remove empty spaces, commas and '$', then change to integer


update airbnb_data
set 
price = replace(replace(replace(price, '$', ''), ' ', ''),',',''),
service_fee = replace(replace(replace(service_fee, '$', ''), ' ', ''), ',', '');


alter table airbnb_data
alter column price type int using price::int,
alter column service_fee type int using service_fee::int;


---- Removing typos in neighbourhood_group and populating the null values ----

-- Removing typos
select distinct 
case 
when neighbourhood_group ilike '%man%' then 'Manhattan'
when neighbourhood_group ilike '%broo%' then 'Brooklyn'
else neighbourhood_group
end as borough
from airbnb_data;

update airbnb_data
set neighbourhood_group = 
case 
when neighbourhood_group ilike '%man%' then 'Manhattan'
when neighbourhood_group ilike '%broo%' then 'Brooklyn'
else neighbourhood_group
end;

alter table airbnb_data
rename column neighbourhood_group to borough;

-- populating nulls

select a.id, a.neighbourhood, a.borough, b.id, b.neighbourhood, b.borough, coalesce(a.borough, b.borough) as updated_borough
from airbnb_data as a
join airbnb_data as b 
on a.neighbourhood=b.neighbourhood
where a.id <> b.id
and a.borough is null

update airbnb_data as a
set borough = coalesce(a.borough, b.borough)
from airbnb_data as b 
where a.neighbourhood=b.neighbourhood
and a.id <> b.id
and a.borough is null;



--changing null host identity verification values to unconfirmed status


select host_identity_verified, coalesce(host_identity_verified, 'unconfirmed')
from airbnb_data
where host_identity_verified is null

update airbnb_data
set host_identity_verified = coalesce(host_identity_verified, 'unconfirmed')




---- Removing duplicate rows ----

--Finding rows
with rankingcte as (
select *, 
row_number() over(
partition by  
	id,
	host_id,
	listing_name,
	price,
	house_rules 
	order by id
	) as rownumber
from airbnb_data)

select * from rankingcte
where rownumber > 1
order by id asc;

--Deleting rows
with rankingcte as (
select ctid, 
row_number() over(
partition by  
	id,
	host_id,
	listing_name,
	price,
	house_rules 
	order by id
	) as rownumber
from airbnb_data)

delete from airbnb_data
where ctid in (
select ctid	
from rankingcte
where rownumber > 1);



---- Deleting redundant columns ----

alter table airbnb_data
drop column country,
drop column country_code; 

