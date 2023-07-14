/****** Script for SelectTopNRows command from SSMS  ******/
SELECT *
  FROM [Final_Project].[dbo].[campaign_table]
go



-- change into date format
alter table campaign_table 
alter column START_DAY date

alter table campaign_table 
alter column END_DAY date
go

-- Created new table with all null values
ALTER TABLE campaign_table add is_invalid_date nvarchar(10);
go

--a.	 Add is_invalid_date column which indicates True or False based on the condition where start_day is greater than end_day.
Update campaign_table
SET is_invalid_date =(
CASE WHEN START_DAY > END_DAY THEN 
    'True'
ELSE 
    'False'
END
)
go


-- b.	Create start_datekey and end_datekey with yyyymmdd format based on start_day and end_day.
alter table campaign_table add START_DAY_KEY varchar(max)

update campaign_table set
START_DAY_KEY = convert(varchar, START_DAY, 112) from campaign_table
--
alter table campaign_table add END_DAY_KEY varchar(max)

update campaign_table set
END_DAY_KEY = convert(varchar, END_DAY, 112) from campaign_table


-- c.	Normalize campaign_table into 2 tables.
-- created 2 seaprate tables from campaign_table named as Decription_no & Campaign
-- Created 1 st table names as Description_no
 drop view if exists V_description_no 
 go
 create View V_description_no as
select  Description from campaign_table group by DESCRIPTION having count(*) > 1;
go

 drop table if exists Description_no
 create table Description_no(DescCamp_id bigint primary key,DESCRIPTION nvarchar(20))
 go

  insert into Description_no(DescCamp_id,DESCRIPTION) 
  (select case when DESCRIPTION = 'TypeA' then '1'
  when DESCRIPTION = 'TypeB' then '2' 
  when DESCRIPTION = 'TypeC'then '3' else null end
  DescCamp_id , DESCRIPTION from V_description_no)
go

  select * from Description_no

--
-- Created 2nd table names as Campaign
drop table if exists Campaign
Create table Campaign(household_key bigint,CAMPAIGN bigint,START_DAY date,END_DAY date,
						is_invalid_date nvarchar(10),START_DAY_KEY varchar(max), END_DAY_KEY varchar(max), 
						DescCamp_id bigint FOREIGN KEY REFERENCES Description_no(DescCamp_id))
go

insert into Campaign(household_key, CAMPAIGN, START_DAY, END_DAY, is_invalid_date, START_DAY_KEY, END_DAY_KEY, DescCamp_id) 
(select household_key,CAMPAIGN,START_DAY,END_DAY, is_invalid_date, START_DAY_KEY, END_DAY_KEY,
case when DESCRIPTION = 'TypeA' then '1'
  when DESCRIPTION = 'TypeB' then '2' 
  when DESCRIPTION = 'TypeC'then '3' else null end
  DescCamp_id from campaign_table)
go

select * from Campaign
select * from Description_no

go


-- d.	Combine coupon and coupon_redempt tables into one Coupon table.
with cte as (SELECT 
 c1.CAMPAIGN, c1.COUPON_UPC, c1.PRODUCT_ID,c2.household_key,c2.DAY
  FROM coupon c1
   full JOIN coupon_redempt c2
    ON c1.CAMPAIGN = c2.CAMPAIGN
	and c1.COUPON_UPC = c2.COUPON_UPC )
select * into Coupon_Table from cte


--
--3.	Find/ Create all the primary keys and foreign keys.
-- hh_demographic
-- 
ALTER TABLE [hh_demographic] alter column household_key bigint NOT NULL
go
Alter table [dbo].[hh_demographic] add primary key (household_key);

--product
-- 
ALTER TABLE [dbo].[product] alter column PRODUCT_ID bigint NOT NULL
go
Alter table [dbo].[product] add  primary key (PRODUCT_ID);
--

--

--coupon redempt
Alter table [dbo].[coupon_redempt] add foreign key ([household_key]) references [hh_demographic] ([household_key])

--coupon table
Alter table [dbo].[Coupon_Table] add foreign key ([household_key]) references [hh_demographic] ([household_key])
Alter table [dbo].[Coupon_Table] add foreign key (PRODUCT_ID) references [product] (PRODUCT_ID)
--coupon
Alter table [dbo].[coupon] add foreign key (PRODUCT_ID) references [product] (PRODUCT_ID)

--casual table
Alter table [dbo].[causal_data] add foreign key (PRODUCT_ID) references [product] (PRODUCT_ID)

-- transaction
Alter table [dbo].[transaction_data] add foreign key ([household_key]) references [hh_demographic] ([household_key])

Alter table [dbo].[transaction_data] add foreign key (PRODUCT_ID) references [product] (PRODUCT_ID)


select count(a.household_key) from campaign_table a join coupon b on a.CAMPAIGN=b.CAMPAIGN

-- campaign_table
ALTER TABLE [dbo].[campaign_table] alter column household_key bigint NOT NULL
go
Alter table [dbo].[campaign_table] add foreign key ([household_key]) references [hh_demographic] ([household_key])


-- handled orphan keys [transaction_data]
insert into hh_demographic (household_key) 
(select distinct household_key from [transaction_data] where household_key not in (select household_key from hh_demographic))
--Transaction data
ALTER TABLE [dbo].[transaction_data] alter column PRODUCT_ID bigint NOT NULL
go
ALTER TABLE [dbo].[transaction_data] alter column [BASKET_ID] bigint NOT NULL
go
Alter table [dbo].[transaction_data] add  primary key (PRODUCT_ID, BASKET_ID);


-- handled orphan keys campaign
insert into hh_demographic (household_key) 
(select distinct household_key from campaign where household_key not in (select household_key from hh_demographic))

--campaign
Alter table [dbo].[Campaign] add foreign key ([household_key]) references [hh_demographic] ([household_key])
