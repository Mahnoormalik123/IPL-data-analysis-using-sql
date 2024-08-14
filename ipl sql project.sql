CREATE DATABASE ipl;
USE ipl;
CREATE TABLE matches (
    match_id INT PRIMARY KEY,
    season VARCHAR(50),
    city VARCHAR(50),
    date DATE,
    team1 VARCHAR(50),
    team2 VARCHAR(50),
    toss_winner VARCHAR(50),
    toss_decision VARCHAR(10),
    result VARCHAR(10),
    dl_applied INT,
    winner VARCHAR(50),
    win_by_runs INT,
    win_by_wickets INT,
    player_of_match VARCHAR(50),
    venue VARCHAR(100),
    umpire1 VARCHAR(50),
    umpire2 VARCHAR(50),
    umpire3 VARCHAR(50)
);
CREATE TABLE deliveries (
    match_id INT,
    inning INT,
    batting_team VARCHAR(50),
    bowling_team VARCHAR(50),
    over_number INT,  -- over ko change karke over_number kar diya
    ball INT,
    batsman VARCHAR(50),
    non_striker VARCHAR(50),
    bowler VARCHAR(50),
    is_super_over INT,
    wide_runs INT,
    bye_runs INT,
    legbye_runs INT,
    noball_runs INT,
    penalty_runs INT,
    batsman_runs INT,
    extra_runs INT,
    total_runs INT
);
SELECT * FROM matches LIMIT 10;
SELECT * FROM deliveries LIMIT 10;

--  TOP 5 PLAYERS WITH THE MOST PLAYER OF THE MATCH AWARDS?
SELECT player_of_match, COUNT(*) AS awards_count
FROM matches
GROUP BY player_of_match
ORDER BY awards_count DESC
LIMIT 5;

-- Count of matches won by each team in each season
SELECT season, winner, COUNT(*) AS matches_won
FROM matches
WHERE winner IS NOT NULL
GROUP BY season, winner
ORDER BY season, matches_won DESC;

-- Average strike rate of all batsmen
SELECT batsman, 
       SUM(batsman_runs) / SUM(balls_faced) * 100 AS strike_rate
FROM (
    SELECT batsman, 
           SUM(batsman_runs) AS batsman_runs, 
           COUNT(*) AS balls_faced
    FROM deliveries
    GROUP BY batsman
) AS batting_stats
WHERE balls_faced > 0
GROUP BY batsman;

-- Number of matches won by each team batting first vs. batting second
SELECT
    team1 AS team,
    SUM(CASE WHEN winner = team1 THEN 1 ELSE 0 END) AS wins_batting_first,
    SUM(CASE WHEN winner = team2 THEN 1 ELSE 0 END) AS wins_batting_second
FROM matches
GROUP BY team1
UNION ALL
SELECT
    team2 AS team,
    SUM(CASE WHEN winner = team1 THEN 1 ELSE 0 END) AS wins_batting_first,
    SUM(CASE WHEN winner = team2 THEN 1 ELSE 0 END) AS wins_batting_second
FROM matches
GROUP BY team2;

-- Batsman with highest strike rate having minimum 200 runs scored
SELECT batsman,
       strike_rate
FROM (
    SELECT batsman,
           SUM(batsman_runs) / SUM(balls_faced) * 100 AS strike_rate,
           SUM(batsman_runs) AS batsman_runs
    FROM (
        SELECT batsman,
               SUM(batsman_runs) AS batsman_runs,
               COUNT(*) AS balls_faced
        FROM deliveries
        GROUP BY batsman
    ) AS batting_stats
    WHERE batsman_runs >= 200 AND balls_faced > 0
    GROUP BY batsman
) AS final_stats
ORDER BY strike_rate DESC
LIMIT 1;

-- Number of times each batsman has been dismissed by the bowler with name 'Rashid Khan'
SELECT batsman, COUNT(*) AS dismissals_by_bowler
FROM deliveries
WHERE bowler = 'Rashid Khan' AND player_dismissed IS NOT NULL
GROUP BY batsman;

-- Average percentage of boundaries hit by each batsman
SELECT batsman,
       AVG((fours + sixes) / balls_faced * 100) AS avg_boundaries_percentage
FROM (
    SELECT batsman,
           SUM(CASE WHEN batsman_runs = 4 THEN 1 ELSE 0 END) AS fours,
           SUM(CASE WHEN batsman_runs = 6 THEN 1 ELSE 0 END) AS sixes,
           COUNT(*) AS balls_faced
    FROM deliveries
    GROUP BY batsman
) AS boundary_stats
WHERE balls_faced > 0
GROUP BY batsman;

-- Calculate the average number of boundaries hit by each team in each season
SELECT season,
       batting_team,
       AVG(total_boundaries) AS avg_boundaries
FROM (
    SELECT m.season,
           CASE 
               WHEN d.batting_team = m.team1 THEN m.team1 
               ELSE m.team2 
           END AS batting_team,
           SUM(CASE WHEN d.batsman_runs = 4 THEN 1 ELSE 0 END) +
           SUM(CASE WHEN d.batsman_runs = 6 THEN 1 ELSE 0 END) AS total_boundaries
    FROM deliveries d
    JOIN matches m ON d.match_id = m.id
    GROUP BY m.season, 
             CASE 
                 WHEN d.batting_team = m.team1 THEN m.team1 
                 ELSE m.team2 
             END
) AS team_info
GROUP BY season, batting_team;


-- Highest Partnership (Runs) for Each Team in Each Season
SELECT m.season,
       d.batting_team,
       MAX(partnership_runs) AS highest_partnership
FROM (
    SELECT m.season,
           CASE 
               WHEN d.batting_team = m.team1 THEN m.team1 
               ELSE m.team2 
           END AS batting_team,
           SUM(d.batsman_runs) AS partnership_runs
    FROM deliveries d
    JOIN matches m ON d.match_id = m.id
    GROUP BY m.season, d.match_id, d.inning, d.batting_team
) AS partnerships
GROUP BY m.season, batting_team;

--  How Many Extras (Wides & No-Balls) Were Bowled by Each Team in Each Match
SELECT d.match_id,
       d.batting_team,
       SUM(d.wide_runs + d.noball_runs) AS total_extras
FROM deliveries d
GROUP BY d.match_id, d.batting_team;

-- Which Bowler Has the Best Bowling Figures (Most Wickets Taken) in a Single Match?
SELECT d.match_id,
       d.bowler,
       COUNT(d.player_dismissed) AS total_wickets
FROM deliveries d
WHERE d.player_dismissed IS NOT NULL
GROUP BY d.match_id, d.bowler
ORDER BY total_wickets DESC
LIMIT 1;

-- How Many Matches Resulted in a Win for Each Team in Each City
SELECT m.city,
       m.winner,
       COUNT(*) AS matches_won
FROM matches m
GROUP BY m.city, m.winner;

-- How Many Times Did Each Team Win the Toss in Each Season
SELECT m.season,
       m.toss_winner,
       COUNT(*) AS toss_wins
FROM matches m
GROUP BY m.season, m.toss_winner;

-- How Many Matches Did Each Player Win the "Player of the Match" Award?
SELECT m.player_of_match,
       COUNT(*) AS awards_won
FROM matches m
GROUP BY m.player_of_match;

-- WHAT IS THE AVERAGE NUMBER OF RUNS SCORED IN EACH OVER OF THE INNINGS IN EACH MATCH?
SELECT match_id, 
       inning, 
       `over`,   
       SUM(total_runs) AS total_runs
FROM deliveries
GROUP BY match_id, inning, `over`;

-- Which Team Has the Highest Total Score in a Single Match?
SELECT match_id,
       batting_team,
       SUM(total_runs) AS total_score
FROM deliveries
GROUP BY match_id, batting_team
ORDER BY total_score DESC
LIMIT 1;

-- Which Batsman Has Scored the Most Runs in a Single Match?
SELECT match_id,
       batsman,
       SUM(batsman_runs) AS total_runs
FROM deliveries
GROUP BY match_id, batsman
ORDER BY total_runs DESC
LIMIT 1;



