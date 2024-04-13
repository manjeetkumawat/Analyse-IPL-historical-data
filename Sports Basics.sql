

create database SportsBasics

-----1.Top 10 batsmen based on past 3 years total runs scored.

select Top 10 batsmanName ,Sum(runs) as [TotalRun] 
from [fact_bating_summary]
Group by batsmanName 
order by Sum(runs) Desc

--select * from [fact_bating_summary]
--select * from dim_match_summary

-----2.Top 10 batsmen based on past 3 years strike rate (min 60 balls faced in each season)

;WITH PlayerStats AS (
    SELECT 
        batsmanName,
        AVG(Runs) AS AvgRuns,
        AVG(Balls) AS AvgBalls,
        SUM(Runs) AS TotalRuns,
        SUM(Balls) AS TotalBalls
    FROM 
        [fact_bating_summary]
    GROUP BY 
        batsmanName
    
),

QualifiedPlayers AS (
    SELECT 
        batsmanName
    FROM 
        PlayerStats
		Group by batsmanName
    Having 
       Avg(TotalBalls) >= 60 
),

TopBatsmen AS (
    SELECT 
        ps.batsmanName,
        AVG(ps.TotalRuns) / AVG(ps.TotalBalls) * 100 AS StrikeRate
    FROM 
        PlayerStats ps
    INNER JOIN 
        QualifiedPlayers qp ON ps.batsmanName = qp.batsmanName
    GROUP BY 
        ps.batsmanName
)

SELECT TOP 10
    tb.batsmanName,
    p.[name], 
    tb.StrikeRate
FROM 
    TopBatsmen tb
INNER JOIN 
    dim_players p ON tb.batsmanName = p.Name
ORDER BY 
    tb.StrikeRate DESC;


-----3.Top 10 batsmen based on past 3 years batting average. (min 60 balls faced in each season)

;WITH PlayerStats AS (
    SELECT 
        batsmanName,
        AVG(Runs) AS AvgRuns,
        AVG(Balls) AS AvgBalls,
        SUM(Runs) AS TotalRuns,
        SUM(Balls) AS TotalBalls
    FROM 
        [fact_bating_summary]	
    GROUP BY 
        batsmanName
),

QualifiedPlayers AS (
    SELECT 
        batsmanName
    FROM 
        PlayerStats
		Group by batsmanName
    having 
        AVG(TotalBalls) >= 60 -- Minimum 60 balls faced on average in each season
),

TopBatsmen AS (
    SELECT 
        ps.batsmanName,
        AVG(ps.AvgRuns) AS BattingAverage
    FROM 
        PlayerStats ps
    INNER JOIN 
        QualifiedPlayers qp ON ps.batsmanName = qp.batsmanName
    GROUP BY 
        ps.batsmanName
)

SELECT TOP 10
    tb.batsmanName,
    p.Name, -- Assuming there's a table for player details
    tb.BattingAverage
FROM 
    TopBatsmen tb
INNER JOIN 
    dim_players p ON tb.batsmanName = p.Name
ORDER BY 
    tb.BattingAverage DESC;


-----4.Top 5 batsmen based on past 3 years boundary % (fours and sixes).

;WITH PlayerBoundaryStats AS (
    SELECT 
        batsmanName,
        SUM(CASE WHEN _4s = 4 THEN 1 ELSE 0 END) AS Fours,
        SUM(CASE WHEN _6s = 6 THEN 1 ELSE 0 END) AS Sixes,
        COUNT(balls) AS TotalBalls
    FROM 
        fact_bating_summary
    GROUP BY 
        batsmanName
),

TopBatsmen AS (
    SELECT top 5 
        pbs.batsmanName,
        (pbs.Fours + pbs.Sixes) * 100.0 / pbs.TotalBalls AS BoundaryPercentage
    FROM 
        PlayerBoundaryStats pbs
    ORDER BY 
        BoundaryPercentage DESC

)

SELECT 
    tb.batsmanName,
    p.Name,
    tb.BoundaryPercentage
FROM 
    TopBatsmen tb
INNER JOIN 
    dim_players p ON tb.batsmanName = p.name
ORDER BY 
    tb.BoundaryPercentage DESC;

--select * from dim_match_summary

-----5.Top 2 teams with the highest number of wins achieved by chasing targets over the past 3 years.

;WITH MatchWins AS (
    SELECT 
        team2 as [name],
        COUNT(*) AS Wins
    FROM 
        dim_match_summary
    WHERE 
        winner in (team2) -- Team won the match
    GROUP BY 
        team2
),
--select * from MatchWins

TopTeams AS (
    SELECT 
        [name],
        Wins,
        RANK() OVER (ORDER BY Wins DESC) AS Rank
    FROM 
        MatchWins
)

select [name],Wins from TopTeams where Rank <= 2 order by Wins DESC

------6.Top 4 teams based on past 3 years winning %.


;WITH TeamWins AS (
    SELECT 
        Winner,
        COUNT(*) AS TotalMatches,
        SUM(CASE WHEN Winner in (team1,team2) THEN 1 ELSE 0 END) AS Wins
    FROM 
        dim_match_summary
    WHERE 
        MatchDate >= DATEADD(YEAR, -3, GETDATE()) 
    GROUP BY 
        Winner
),

TeamWinPercentages AS (
    SELECT 
        TW.Winner,
        TW.TotalMatches,
        TW.Wins,
        (TW.Wins * 100.0) / TW.TotalMatches AS WinPercentage
    FROM 
        TeamWins TW
)

select top 4 winner,WinPercentage from TeamWinPercentages 
order by WinPercentage desc


--select * from fact_bowling_summary

-------7.Top 10 bowlers based on past 3 years total wickets taken.

;WITH BowlerWickets AS (
    SELECT 
        bowlerName,
        COUNT(*) AS TotalWickets
    FROM 
        fact_bowling_summary
    GROUP BY 
        bowlerName
)

SELECT TOP 10
    
    p.[Name], 
    bw.TotalWickets
FROM 
    BowlerWickets bw
INNER JOIN 
    dim_players p ON bw.bowlerName = p.[Name]
ORDER BY 
    bw.TotalWickets DESC;

-------8.Top 10 bowlers based on past 3 years bowling average. (min 60 balls bowled in each season)

;WITH BowlerStats AS (
    SELECT 
        B.bowlerName,
        AVG(runs) AS AvgRuns,
        Sum(Overs*6) AS AvgBalls
    FROM 
        fact_bowling_summary B
		Inner join dim_match_summary M ON B.match_id=M.match_id
    WHERE 
        MatchDate >= DATEADD(YEAR, -3, GETDATE()) 
    GROUP BY 
        B.bowlerName
    HAVING 
        COUNT(DISTINCT YEAR(MatchDate)) >= 3
),

QualifiedBowlers AS (
    SELECT 
        bowlerName
    FROM 
        BowlerStats
		Group by bowlerName
    Having 
        AVG(AvgBalls) >= 60 
		
),

TopBowlers AS (
    SELECT 
        bs.bowlerName,
        AVG(bs.AvgRuns) AS BowlingAverage
    FROM 
        BowlerStats bs
    INNER JOIN 
        QualifiedBowlers qb ON bs.bowlerName = qb.bowlerName
    GROUP BY 
        bs.bowlerName
)

SELECT TOP 10
    bowlerName, 
    tb.BowlingAverage
FROM 
    TopBowlers tb
ORDER BY 
    tb.BowlingAverage ASC;

-------9.Top 10 bowlers based on past 3 years economy rate. (min 60 balls bowled in each season)

;WITH BowlerEconomy AS (
    SELECT 
        B.bowlerName,
        SUM(Runs) AS TotalRuns,
        SUM(Overs*6) AS TotalBalls
    FROM 
        fact_bowling_summary B
		Inner join dim_match_summary M ON B.match_id=M.match_id
    WHERE 
        MatchDate >= DATEADD(YEAR, -3, GETDATE()) 
    GROUP BY 
        bowlerName
),

QualifiedBowlers AS (
    SELECT 
        bowlerName
    FROM 
        BowlerEconomy
    WHERE 
        TotalBalls >= 60 * 3 
),

TopBowlers AS (
    SELECT 
        be.bowlerName,
        (be.TotalRuns * 6.0) / be.TotalBalls AS EconomyRate
    FROM 
        BowlerEconomy be
    INNER JOIN 
        QualifiedBowlers qb ON be.bowlerName = qb.bowlerName
)

SELECT TOP 10
    tb.bowlerName,
    tb.EconomyRate
FROM 
    TopBowlers tb
ORDER BY 
    tb.EconomyRate ASC;

-------10.Top 5 bowlers based on past 3 years dot ball %.

;WITH BowlerDotBalls AS (
    SELECT 
        bowlerName,
        Sum(overs*6) AS TotalBalls,
        SUM(_0s) AS DotBalls
    FROM 
        fact_bowling_summary B
		Inner join dim_match_summary M ON B.match_id=M.match_id
    WHERE 
        MatchDate >= DATEADD(YEAR, -3, GETDATE()) 
    GROUP BY 
        bowlerName
),

TopBowlers AS (
    SELECT 
        bdb.bowlerName,
        (bdb.DotBalls * 100.0) / bdb.TotalBalls AS DotBallPercentage
    FROM 
        BowlerDotBalls bdb
    WHERE 
        bdb.TotalBalls >= 60 * 3 
)

SELECT TOP 5
    tb.bowlerName,
    tb.DotBallPercentage
FROM 
    TopBowlers tb
ORDER BY 
    tb.DotBallPercentage DESC;


------Winner and runner-up

WITH MatchWins AS (
    SELECT 
        CASE 
            WHEN Team1 = Winner THEN Team1
            ELSE Team2
        END AS TeamID,
        COUNT(*) AS Wins
    FROM 
        dim_match_summary
    WHERE 
        MatchDate >= DATEADD(YEAR, -3, GETDATE()) 
    GROUP BY 
        CASE 
            WHEN Team1 = Winner THEN Team1
            ELSE Team2
        END
),

TotalMatches AS (
    SELECT 
        Team1 AS TeamID,
        COUNT(*) AS TotalMatches
    FROM 
        dim_match_summary
    WHERE 
        MatchDate >= DATEADD(YEAR, -3, GETDATE()) 
    GROUP BY 
        Team1

    UNION ALL

    SELECT 
        Team2 AS TeamID,
        COUNT(*) AS TotalMatches
    FROM 
        dim_match_summary
    WHERE 
        MatchDate >= DATEADD(YEAR, -3, GETDATE())
    GROUP BY 
        Team2
),

WinPercentages AS (
    SELECT 
        tm.TeamID,
        CASE 
            WHEN TM.TotalMatches = 0 THEN 0
            ELSE CAST(MW.Wins AS FLOAT) / TM.TotalMatches * 100
        END AS WinPercentage
    FROM 
        MatchWins MW
    INNER JOIN 
        TotalMatches TM ON MW.TeamID = TM.TeamID
)

SELECT TOP 4
    wp.TeamID,
    wp.WinPercentage
FROM 
    WinPercentages wp

ORDER BY 
    wp.WinPercentage DESC;


---------Orange Cap and Purple Cap
-- Orange Cap (Leading Run-scorer)
WITH PlayerRuns AS (
    SELECT 
        batsmanName,
        SUM(Runs) AS TotalRuns
    FROM 
        fact_bating_summary

    GROUP BY 
        batsmanName
)

SELECT TOP 1
    pr.batsmanName,
    pr.TotalRuns AS RunsScored
FROM 
    PlayerRuns pr

ORDER BY 
    pr.TotalRuns DESC;

-- Purple Cap (Leading Wicket-taker)
WITH PlayerWickets AS (
    SELECT 
        bowlerName,
        SUM(Wickets) AS TotalWickets
    FROM 
        fact_bowling_summary B
    GROUP BY 
        bowlerName
)

SELECT Top 1
    pw.bowlerName,
    pw.TotalWickets AS WicketsTaken
FROM 
    PlayerWickets pw
ORDER BY 
    pw.TotalWickets DESC;

----------Top 4 qualifying teams

WITH MatchWins AS (
    SELECT 
        CASE 
            WHEN Team1 = Winner THEN Team1
            ELSE Team2
        END AS TeamID,
        COUNT(*) AS Wins
    FROM 
        dim_match_summary
    WHERE 
        MatchDate >= DATEADD(YEAR, -3, GETDATE()) -- Considering past 3 years
    GROUP BY 
        CASE 
            WHEN Team1 = Winner THEN Team1
            ELSE Team2
        END
),

TotalMatches AS (
    SELECT 
        Team1 AS TeamID,
        COUNT(*) AS TotalMatches
    FROM 
        dim_match_summary
    WHERE 
        MatchDate >= DATEADD(YEAR, -3, GETDATE()) -- Considering past 3 years
    GROUP BY 
        Team1

    UNION ALL

    SELECT 
        Team2 AS TeamID,
        COUNT(*) AS TotalMatches
    FROM 
        dim_match_summary
    WHERE 
        MatchDate >= DATEADD(YEAR, -3, GETDATE()) -- Considering past 3 years
    GROUP BY 
        Team2
),

WinPercentages AS (
    SELECT 
        tm.TeamID,
        CASE 
            WHEN TM.TotalMatches = 0 THEN 0
            ELSE CAST(MW.Wins AS FLOAT) / TM.TotalMatches * 100
        END AS WinPercentage
    FROM 
        MatchWins MW
    INNER JOIN 
        TotalMatches TM ON MW.TeamID = TM.TeamID
)

SELECT TOP 4
    wp.TeamID,
    wp.WinPercentage
FROM 
    WinPercentages wp

ORDER BY 
    wp.WinPercentage DESC;

------------AllRounders

WITH AllRounders AS (
    SELECT 
     
        p.Name,
        AVG(bd.Runs) AS BattingAverage,
        AVG(bd.Balls) AS BattingStrikeRate,
        AVG(bowd.Runs) AS BowlingAverage,
        AVG(bowd.Wickets) AS BowlingStrikeRate
    FROM 
        dim_players p
    JOIN 
        fact_bating_summary bd ON p.name = bd.batsmanName
    JOIN 
        fact_bowling_summary bowd ON p.name= bowd.bowlerName
    GROUP BY 
        p.Name
)
SELECT Top 3
    Name,
    BattingAverage,
    BattingStrikeRate,
    BowlingAverage,
    BowlingStrikeRate,
    (BattingAverage + BowlingAverage) AS CombinedScore
FROM 
    AllRounders
ORDER BY 
    CombinedScore DESC


