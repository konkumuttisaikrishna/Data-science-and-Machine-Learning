CREATE TABLE IF NOT EXISTS OLYMPICS_HISTORY
(
    id INT,
    name VARCHAR(200),
    sex  VARCHAR(200),
    age   VARCHAR(200),
    height VARCHAR(200),
    weight VARCHAR(200),
    team   VARCHAR(200),
    noc    VARCHAR(200),
    games  VARCHAR(200),
    year    INT,
    season   VARCHAR(200),
    city     VARCHAR(200),
    sport    VARCHAR(200),
    event    VARCHAR(200),
    medal    VARCHAR(200)
);
-- 1.How many olympics games have been held?
select count(distinct games) total_olympic_games from olympics_history;

-- 2.List down all Olympics games held so far.
select distinct oh.year,oh.season,oh.city from olympics_history oh
order by year;

-- 3.Mention the total no of nations who participated in each olympics game?
select games,count(distinct region) from olympics_history oh
join noc_regions no
on oh.noc = no.noc
group by games
order by games;

-- 4.Which year saw the highest and lowest no of countries participating in olympics
select * from olympics_history;
with total_countries as
(
select games,count(distinct region) region from olympics_history oh
join noc_regions no
on oh.noc = no.noc
group by games)
select distinct concat(first_value(games) over(order by region),'-',
first_value(region) over(order by region) ) as lowest_countries,
concat(first_value(games) over(order by region desc),'-',
first_value(region) over(order by region desc) ) as highest_countries
from total_countries;

-- 5.Which nation has participated in all of the olympic games
with total_countries as
(
select count(distinct games) total_olympic_games from olympics_history),
country as
(select region country,count(distinct games) total_participant_games from olympics_history oh
join noc_regions no
on oh.noc = no.noc
group by region
order by total_participant_games desc)
select country,total_participant_games from country c
join total_countries t
on c.total_participant_games = t.total_olympic_games;

-- 6. Identify the sport which was played in all summer olympics.
with t1 as
(select count(distinct games) as total_summer_games from olympics_history
where season = 'summer'),
t2 as
( select distinct sport,games
from olympics_history
where season='summer'
order by games
),
t3 as(
select sport,count(games) as no_of_games
from t2 group by sport)
select sport,total_summer_games,no_of_games from t1
join t3
on t1.total_summer_games = t3.no_of_games;

-- 7. Which Sports were just played only once in the olympics.
with t1 as(
select distinct games,sport
from olympics_history),
t2 as
(
select sport,count(1) as no_of_games from t1
group by sport)
select t2.*,t1.games
from t2
join t1
on t1.sport = t2.sport
where t2.no_of_games = 1
order by t1.sport;

-- 8. Fetch the total no of sports played in each olympic games.

select games,count(distinct sport) no_of_sports
from olympics_history
group by games
order by no_of_sports desc;

-- 9. Fetch oldest athletes to win a gold medal
with t1 as(
select name,sex,case when age = 'NA' then 0 else age END as age,team,games,city,sport,event,medal from olympics_history),
t2 as(
select *,rank() over(order by age desc) rnk from t1
where medal = 'Gold')
select * from t2
where rnk =1;

-- 10. Find the Ratio of male and female athletes participated in all olympic games.
SELECT
    SUM(CASE WHEN sex = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN sex = 'F' THEN 1 ELSE 0 END) AS female_count,
    SUM(CASE WHEN sex = 'M' THEN 1 ELSE 0 END) / SUM(CASE WHEN sex = 'F' THEN 1 ELSE 0 END) AS male_to_female_ratio
FROM
    olympics_history;

-- 11.Fetch the top 5 athletes who have won the most gold medals.
with t1 as(
select name,count(1) as total_medals 
from olympics_history
where medal = 'gold'
group by name
order by count(1) desc),
t2 as
(select *,dense_rank() over(order by total_medals desc) as rnk
from t1)
select name,total_medals from t2
where rnk <= 5;

-- 12.Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
with t1 as
(select name,team,count(1) as total_medals
from olympics_history
where medal in ('gold','silver','bronze')
group by name,team
order by count(1) desc),
t2 as
( select *,dense_rank() over(order by total_medals desc) as rnk
from t1)
select name,team,total_medals from t2
where rnk <=5;

-- 13.Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
with t1 as
(
select n.region country,count(medal) total_no_of_medals from olympics_history oh
join noc_regions n
on oh.noc = n.noc
where medal <> 'na'
group by region
order by total_no_of_medals desc),
t2 as
( select *,rank() over(order by total_no_of_medals desc) as rnk from t1)
select * from t2
where rnk <=5;

-- 14.List down total gold, silver and bronze medals won by each country.

with cte as (select nr.region,oh.medal from olympics_history as oh join noc_regions as nr on oh.noc = nr.noc)
select region as country,
sum(case when medal='gold' then 1 else 0  end) as gold_medal,
sum(case when medal='silver' then 1 else 0 end) as silver_medal,
sum(case when medal='bronze' then 1 else 0 end)as bronze_medal
from cte
group by country
order by gold_medal desc;

-- 15.List down total gold, silver and bronze medals won by each country corresponding to each olympic games.

with cte as (select oh.games,nr.region,oh.medal from olympics_history as oh join noc_regions as nr on oh.noc = nr.noc)
select games,region as country,
sum(case when medal='gold' then 1 else 0  end) as gold_medal,
sum(case when medal='silver' then 1 else 0 end) as silver_medal,
sum(case when medal='bronze' then 1 else 0 end)as bronze_medal
from cte
group by games,country
order by games ;

-- 16.Identify which country won the most gold, most silver and most bronze medals in each olympic games.
with cte as(select t1.NOC,t1.games,t2.region,t1.medal from olympics_history as t1 join noc_regions as t2 on t1.NOC=t2.NOC),
cte2 as(select region,games,sum(case when medal in ('Gold','Silver','Bronze') then 1 else 0 end) as medal,
sum(case when medal='Gold' then 1 else 0 end) as gold,
sum(case when medal='Silver' then 1 else 0 end) as silver,
sum(case when medal='Bronze' then 1 else 0 end) as bronze
from cte group by 1,2)
select distinct games,concat(first_value(region) over(partition by games order by gold desc)
, ' - '
, first_value(gold) over(partition by games order by gold desc)) as Max_Gold,
concat(first_value(region) over(partition by games order by silver desc)
, ' - '
, first_value(silver) over(partition by games order by silver desc)) as Max_Silver,
concat(first_value(region) over(partition by games order by bronze desc)
, ' - '
, first_value(bronze) over(partition by games order by bronze desc)) as Max_Bronze
from cte2 order by 1;


-- 17.Which countries have never won gold medal but have won silver/bronze medals?
with t1 as(
select  nr.region as country,medal
from olympics_history oh
join noc_regions nr
on oh.noc = nr.noc
where medal <> 'NA'),
t2 as (
select country,sum( case when medal="gold" then 1 else 0 end) as gold,
sum( case when medal="silver" then 1 else 0 end) as silver,
sum( case when medal="bronze" then 1 else 0 end) as bronze
from t1
group by country)
select country,gold,silver,bronze from t2
where gold = 0 and silver >= 0 and bronze >= 0
order by silver ,bronze desc ;


-- 18.In which Sport/event, India has won highest medals.
with t1 as
(
select team,sport,count(medal) total_medal from olympics_history
where team = "india" and medal <> "na"
group by team,sport),
t2 as(
select sport,total_medal,rank() over(order by total_medal desc) as rnk
from t1)
select sport,total_medal
from t2
where rnk =1;


-- 19. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games
with t1 as(
select team,sport,games,count(medal) total_medal from olympics_history
where team = "india" and medal <> "na"
group by team,sport,games)
select * from t1 
where sport = "hockey"
order by total_medal desc;






