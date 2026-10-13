/* =====================================================================
   EXERCICE ETL - "Givre & Co" (chaîne de glaciers en Belgique)
   Script 01 : base applicative (OLTP) + données simulées (année 2025)
   ---------------------------------------------------------------------
   - Les données sont générées de façon DÉTERMINISTE (hash MD5) :
     chaque exécution produit exactement les mêmes lignes.
   - Les ventes suivent la saison et quelques vraies périodes de chaleur
     de l'été 2025 -> la corrélation avec la météo réelle (API) se voit.
   - Durée d'exécution : quelques secondes à ~1 minute.
   ===================================================================== */

USE master;
GO
IF DB_ID('GlacierApp') IS NOT NULL
BEGIN
    ALTER DATABASE GlacierApp SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GlacierApp;
END
GO
CREATE DATABASE GlacierApp;
GO
USE GlacierApp;
GO
SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------------
   1. TABLES
   --------------------------------------------------------------------- */
CREATE TABLE dbo.categorie (
    categorie_id   INT           NOT NULL PRIMARY KEY,
    nom            NVARCHAR(50)  NOT NULL
);

CREATE TABLE dbo.produit (
    produit_id     INT           NOT NULL PRIMARY KEY,
    code           VARCHAR(10)   NOT NULL UNIQUE,
    nom            NVARCHAR(100) NOT NULL,
    categorie_id   INT           NULL REFERENCES dbo.categorie(categorie_id),
    prix_unitaire  DECIMAL(6,2)  NOT NULL,          -- prix ACTUEL du catalogue
    actif          BIT           NOT NULL DEFAULT 1
);

CREATE TABLE dbo.magasin (
    magasin_id     INT           NOT NULL PRIMARY KEY,
    nom            NVARCHAR(100) NOT NULL,
    adresse        NVARCHAR(200) NOT NULL,
    code_postal    VARCHAR(10)   NULL,
    ville          NVARCHAR(100) NOT NULL,
    pays           NVARCHAR(50)  NOT NULL,
    date_ouverture DATE          NOT NULL,
    actif          BIT           NOT NULL DEFAULT 1
);

CREATE TABLE dbo.client (
    client_id        INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    nom              NVARCHAR(50)  NOT NULL,
    prenom           NVARCHAR(50)  NOT NULL,
    email            NVARCHAR(150) NULL,
    date_naissance   DATE          NULL,
    code_postal      VARCHAR(10)   NULL,
    date_inscription DATE          NOT NULL
);

CREATE TABLE dbo.commande (
    commande_id    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    magasin_id     INT           NOT NULL REFERENCES dbo.magasin(magasin_id),
    client_id      INT           NULL     REFERENCES dbo.client(client_id),
    date_commande  DATETIME2(0)  NOT NULL,
    statut         VARCHAR(10)   NOT NULL CHECK (statut IN ('PAYEE','ANNULEE')),
    mode_paiement  VARCHAR(10)   NOT NULL
);

CREATE TABLE dbo.ligne_commande (
    ligne_id       INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    commande_id    INT           NOT NULL REFERENCES dbo.commande(commande_id),
    produit_id     INT           NOT NULL REFERENCES dbo.produit(produit_id),
    quantite       INT           NOT NULL,
    prix_unitaire  DECIMAL(6,2)  NOT NULL,          -- prix AU MOMENT de la vente
    remise_pct     DECIMAL(5,2)  NOT NULL DEFAULT 0 -- 10.00 = 10 %
);
GO

/* ---------------------------------------------------------------------
   2. DONNÉES DE RÉFÉRENCE
   --------------------------------------------------------------------- */
INSERT INTO dbo.categorie (categorie_id, nom) VALUES
 (1, N'Glaces'),
 (2, N'Sorbets'),
 (3, N'Gaufres & crêpes'),
 (4, N'Boissons chaudes'),
 (5, N'Boissons fraîches'),
 (6, N'Milkshakes');

INSERT INTO dbo.produit (produit_id, code, nom, categorie_id, prix_unitaire, actif) VALUES
 ( 1, 'GL-VAN', N'Cornet vanille',          1, 2.80, 1),
 ( 2, 'GL-CHO', N'Cornet chocolat',         1, 2.80, 1),
 ( 3, 'GL-SPE', N'Cornet spéculoos',        1, 3.00, 1),
 ( 4, 'GL-PIS', N'Cornet pistache',         1, 3.20, 1),
 ( 5, 'GL-CUP', N'Coupe 3 boules',          1, 6.50, 1),
 ( 6, 'SO-FRA', N'Sorbet fraise',           2, 2.80, 1),
 ( 7, 'SO-CIT', N'Sorbet citron',           2, 2.80, 1),
 ( 8, 'SO-MAN', N'Sorbet mangue',           2, 3.00, 1),
 ( 9, 'GA-LIE', N'Gaufre de Liège',         3, 3.50, 1),
 (10, 'GA-BRU', N'Gaufre de Bruxelles',     3, 4.50, 1),
 (11, 'CR-SUC', N'Crêpe au sucre',          3, 3.00, 1),
 (12, 'BC-CAF', N'Café',                    4, 2.50, 1),
 (13, 'BC-CHO', N'Chocolat chaud',          4, 3.50, 1),
 (14, 'BF-EAU', N'Eau 50cl',                5, 2.00, 1),
 (15, 'BF-LIM', N'Limonade maison',         5, 3.50, 1),
 (16, 'MS-VAN', N'Milkshake vanille',       6, 5.00, 1),
 (17, 'MS-FRA', N'Milkshake fraise',        6, 5.00, 1),
 (18, 'GL-MOI', N'  glace du mois ',     NULL, 3.50, 1),   -- pas de catégorie, nom mal saisi
 (19, 'GL-RHU', N'Cornet rhum-raisin',      1, 3.00, 0);   -- retiré de la carte fin mars

INSERT INTO dbo.magasin (magasin_id, nom, adresse, code_postal, ville, pays, date_ouverture, actif) VALUES
 ( 1, N'Givre & Co - Grand-Place', N'Rue du Marché aux Herbes 25', '1000', N'Bruxelles',     N'Belgique', '2019-03-15', 1),
 ( 2, N'Givre & Co - Carré',       N'Place du Marché 15',          '4000', N'LIEGE ',        N'Belgique', '2020-04-01', 1),
 ( 3, N'Givre & Co - Namur',       N'Rue de Fer 30',               NULL,   N'Namur',         N'Belgique', '2021-05-01', 1),
 ( 4, N'Givre & Co - Gent',        N'Veldstraat 50',               '9000', N'Gent',          N'Belgique', '2022-03-20', 1),
 ( 5, N'Givre & Co - Digue',       N'Albert I-Promenade 40',       '8400', N'Oostende',      N'Belgique', '2018-04-01', 1),
 ( 6, N'Givre & Co - Zoute',       N'Lippenslaan 100',             '8300', N'knokke heist',  N'Belgique', '2023-04-01', 1),
 ( 7, N'Givre & Co - Charleroi',   N'Rue de la Montagne 20',       '6000', N'Charleroi',     N'Belgique', '2025-04-12', 1),
 (99, N'MAGASIN TEST (ne pas utiliser)', N'Rue du Test 1',         '0000', N'Test',          N'Belgique', '2024-01-01', 0);
GO

/* ---------------------------------------------------------------------
   3. OUTILS DE GÉNÉRATION (supprimés en fin de script)
   --------------------------------------------------------------------- */
-- Pseudo-aléatoire déterministe dans [0,1[ à partir d'une graine texte
CREATE FUNCTION dbo.fn_alea (@graine VARCHAR(100))
RETURNS FLOAT
WITH SCHEMABINDING
AS
BEGIN
    RETURN (CAST(SUBSTRING(HASHBYTES('MD5', @graine), 1, 4) AS INT) & 2147483647) / 2147483648.0;
END
GO

-- Table de nombres 1..400
SELECT TOP (400) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
INTO #nums
FROM sys.all_objects a CROSS JOIN sys.all_objects b;

-- Paramètres de fréquentation par magasin
CREATE TABLE #param_magasin (magasin_id INT PRIMARY KEY, base FLOAT, cotier BIT);
INSERT INTO #param_magasin VALUES
 (1, 40, 0), (2, 28, 0), (3, 20, 0), (4, 30, 0), (5, 25, 1), (6, 22, 1), (7, 18, 0);

-- Produits tirables : groupe F (froid) / C (chaud), rang = popularité
CREATE TABLE #tirage (groupe CHAR(1), rang INT, produit_id INT);
INSERT INTO #tirage VALUES
 ('F', 1, 1), ('F', 2, 2), ('F', 3, 3), ('F', 4, 6), ('F', 5, 14), ('F', 6, 5),
 ('F', 7, 7), ('F', 8, 15), ('F', 9, 18), ('F',10, 4), ('F',11, 16), ('F',12, 8),
 ('F',13, 17), ('F',14, 19),
 ('C', 1, 9), ('C', 2, 12), ('C', 3, 13), ('C', 4, 10), ('C', 5, 11);

/* ---------------------------------------------------------------------
   4. CLIENTS (200 porteurs de carte de fidélité)
   --------------------------------------------------------------------- */
;WITH prenoms AS (
    SELECT p, ROW_NUMBER() OVER (ORDER BY p) AS i FROM (VALUES
     (N'Emma'),(N'Louis'),(N'Olivia'),(N'Arthur'),(N'Louise'),(N'Noah'),(N'Alice'),
     (N'Jules'),(N'Mila'),(N'Adam'),(N'Lina'),(N'Victor'),(N'Elena'),(N'Lucas'),
     (N'Nora'),(N'Liam'),(N'Sofia'),(N'Mohamed'),(N'Fien'),(N'Lars')) v(p)
), noms AS (
    SELECT nm, ROW_NUMBER() OVER (ORDER BY nm) AS i FROM (VALUES
     (N'Peeters'),(N'Janssens'),(N'Maes'),(N'Jacobs'),(N'Mertens'),(N'Willems'),
     (N'Claes'),(N'Goossens'),(N'Wouters'),(N'Dubois'),(N'Lambert'),(N'Dupont'),
     (N'Martin'),(N'Simon'),(N'Leclercq'),(N'Laurent'),(N'Renard'),(N'Lejeune'),
     (N'El Amrani'),(N'Nguyen')) v(nm)
), combi AS (
    SELECT TOP (200) p.p AS prenom, n.nm AS nom, CONCAT(p.i, '-', n.i) AS k
    FROM prenoms p CROSS JOIN noms n
    ORDER BY dbo.fn_alea(CONCAT('cli', p.i, '-', n.i))
)
INSERT INTO dbo.client (nom, prenom, email, date_naissance, code_postal, date_inscription)
SELECT nom,
       prenom,
       CASE WHEN dbo.fn_alea(CONCAT('em', k)) < 0.12 THEN NULL
            ELSE LOWER(CONCAT(prenom, '.', REPLACE(nom, ' ', ''), '@exemple.be')) END,
       CASE WHEN dbo.fn_alea(CONCAT('dn0', k)) < 0.08 THEN NULL
            ELSE DATEADD(DAY, CAST(dbo.fn_alea(CONCAT('dn', k)) * 21000 AS INT), '1950-01-01') END,
       CHOOSE(1 + CAST(dbo.fn_alea(CONCAT('cp', k)) * 7 AS INT),
              '1000', '4000', '5000', '9000', '8400', '8300', '6000'),
       DATEADD(DAY, CAST(dbo.fn_alea(CONCAT('di', k)) * 2190 AS INT), '2019-01-01')
FROM combi
ORDER BY k;

/* ---------------------------------------------------------------------
   5. "MÉTÉO" INTERNE AU GÉNÉRATEUR (non stockée)
      température ressentie approximative pour chaque jour de 2025
   --------------------------------------------------------------------- */
;WITH jours AS (
    SELECT DATEADD(DAY, n - 1, CAST('2025-01-01' AS DATE)) AS d
    FROM #nums WHERE n <= 365
)
SELECT d,
       DATEDIFF(DAY, '19000101', d) % 7 AS jsem,         -- 0 = lundi ... 6 = dimanche
       11.0 - 7.5 * COS(2 * PI() * (DATEPART(DAYOFYEAR, d) - 20) / 365.0)
       + ( ( dbo.fn_alea(CONCAT('t', d))
           + dbo.fn_alea(CONCAT('t', DATEADD(DAY, -1, d)))
           + dbo.fn_alea(CONCAT('t', DATEADD(DAY, -2, d))) ) / 3.0 - 0.5 ) * 12
       + CASE WHEN d BETWEEN '2025-06-30' AND '2025-07-02' THEN 9     -- canicule début juillet
              WHEN d BETWEEN '2025-08-11' AND '2025-08-15' THEN 7     -- vague de chaleur mi-août
              WHEN d BETWEEN '2025-06-19' AND '2025-06-21' THEN 5
              ELSE 0 END AS t,
       CASE WHEN dbo.fn_alea(CONCAT('pl', d)) < 0.33 THEN 1 ELSE 0 END AS pluie
INTO #jour
FROM jours
WHERE d <= '2025-12-31';

/* ---------------------------------------------------------------------
   6. COMMANDES
   --------------------------------------------------------------------- */
;WITH mj AS (
    SELECT m.magasin_id, j.d, j.t,
           CAST(ROUND(
               p.base
             * (0.25 + 0.75 * CASE WHEN j.t < 0 THEN 0 WHEN j.t > 35 THEN 1.4 ELSE j.t / 25.0 END)
             * CASE WHEN j.jsem >= 5 THEN 1.35 ELSE 1.0 END
             * CASE WHEN j.pluie = 1 THEN 0.70 ELSE 1.0 END
             * CASE WHEN p.cotier = 1
                    THEN (0.4 + 1.2 * CASE WHEN j.t < 5 THEN 0 WHEN j.t > 23 THEN 1 ELSE (j.t - 5) / 18.0 END)
                       * CASE WHEN MONTH(j.d) IN (7, 8) THEN 1.3 ELSE 1.0 END
                    ELSE 1.0 END
             * (0.85 + 0.30 * dbo.fn_alea(CONCAT('var', m.magasin_id, '|', j.d)))
           , 0) AS INT) AS nb_cmd
    FROM dbo.magasin m
    JOIN #param_magasin p ON p.magasin_id = m.magasin_id
    CROSS JOIN #jour j
    WHERE j.d >= m.date_ouverture
      AND NOT (MONTH(j.d) = 1 AND DAY(j.d) = 1)
      AND NOT (MONTH(j.d) = 12 AND DAY(j.d) = 25)
      AND NOT (m.magasin_id = 5 AND MONTH(j.d) = 1)          -- Oostende fermé en janvier
      AND NOT (m.magasin_id = 6 AND MONTH(j.d) IN (1, 2))    -- Knokke fermé janv.-févr.
), base_cmd AS (
    SELECT mj.magasin_id, mj.d, mj.t, nb.n,
           DATEADD(MINUTE,
                   660 + CAST(FLOOR(dbo.fn_alea(CONCAT('h', mj.magasin_id, '|', mj.d, '|', nb.n)) * 600) AS INT),
                   CAST(mj.d AS DATETIME2(0))) AS date_commande
    FROM mj
    JOIN #nums nb ON nb.n <= CASE WHEN mj.nb_cmd < 3 THEN 3 ELSE mj.nb_cmd END
)
SELECT ROW_NUMBER() OVER (ORDER BY date_commande, magasin_id, n) AS commande_id,
       magasin_id, d, t, n, date_commande
INTO #cmd
FROM base_cmd;

SELECT c.commande_id, c.magasin_id, c.d, c.t, c.date_commande,
       CASE WHEN dbo.fn_alea(CONCAT('cl', c.commande_id)) < 0.35
            THEN 1 + CAST(FLOOR(dbo.fn_alea(CONCAT('cl2', c.commande_id)) * 200) AS INT) END AS client_id,
       CASE WHEN dbo.fn_alea(CONCAT('st', c.commande_id)) < 0.03 THEN 'ANNULEE' ELSE 'PAYEE' END AS statut,
       CASE WHEN r.mp < 0.50 THEN 'CARTE'
            WHEN r.mp < 0.80 THEN 'MOBILE'
            ELSE 'CASH' END AS mode_paiement,
       CASE WHEN r.nl < 0.55 THEN 1
            WHEN r.nl < 0.85 THEN 2
            WHEN r.nl < 0.97 THEN 3
            ELSE 4 END AS nb_lignes
INTO #cmd2
FROM #cmd c
CROSS APPLY (SELECT dbo.fn_alea(CONCAT('mp', c.commande_id)) AS mp,
                    dbo.fn_alea(CONCAT('nl', c.commande_id)) AS nl) r;

SET IDENTITY_INSERT dbo.commande ON;
INSERT INTO dbo.commande (commande_id, magasin_id, client_id, date_commande, statut, mode_paiement)
SELECT commande_id, magasin_id, client_id, date_commande, statut, mode_paiement
FROM #cmd2
ORDER BY commande_id;
SET IDENTITY_INSERT dbo.commande OFF;

/* ---------------------------------------------------------------------
   7. LIGNES DE COMMANDE
   --------------------------------------------------------------------- */
;WITH lig AS (
    SELECT c.commande_id, c.d, c.t, c.client_id, l.n AS ligne_no,
           dbo.fn_alea(CONCAT('g', c.commande_id, '|', l.n)) AS rg,
           dbo.fn_alea(CONCAT('p', c.commande_id, '|', l.n)) AS rp,
           dbo.fn_alea(CONCAT('q', c.commande_id, '|', l.n)) AS rq,
           dbo.fn_alea(CONCAT('r', c.commande_id, '|', l.n)) AS rr
    FROM #cmd2 c
    JOIN #nums l ON l.n <= c.nb_lignes
), choix AS (
    SELECT lig.*,
           CASE WHEN lig.rg < CASE WHEN (lig.t - 2) / 22.0 < 0.15 THEN 0.15
                                   WHEN (lig.t - 2) / 22.0 > 0.92 THEN 0.92
                                   ELSE (lig.t - 2) / 22.0 END
                THEN 'F' ELSE 'C' END AS groupe
    FROM lig
), prod AS (
    SELECT ch.*,
           CASE WHEN tr.produit_id = 18 AND ch.d <  '2025-05-01' THEN 1   -- glace du mois lancée en mai
                WHEN tr.produit_id = 19 AND ch.d >= '2025-04-01' THEN 2   -- rhum-raisin retiré fin mars
                ELSE tr.produit_id END AS produit_id
    FROM choix ch
    CROSS APPLY (SELECT COUNT(*) AS nb FROM #tirage x WHERE x.groupe = ch.groupe) g
    JOIN #tirage tr
      ON tr.groupe = ch.groupe
     AND tr.rang = 1 + CAST(FLOOR(POWER(ch.rp, 1.4) * g.nb) AS INT)
)
INSERT INTO dbo.ligne_commande (commande_id, produit_id, quantite, prix_unitaire, remise_pct)
SELECT pr.commande_id,
       pr.produit_id,
       CASE WHEN pr.rq < 0.70 THEN 1 WHEN pr.rq < 0.92 THEN 2 WHEN pr.rq < 0.98 THEN 3 ELSE 4 END,
       p.prix_unitaire
         - CASE WHEN p.categorie_id IN (1, 2) AND pr.d < '2025-06-01' THEN 0.20 ELSE 0 END,  -- hausse de prix au 1er juin
       CASE WHEN pr.client_id IS NOT NULL AND pr.rr < 0.25 THEN 10.00 ELSE 0 END           -- remise fidélité
FROM prod pr
JOIN dbo.produit p ON p.produit_id = pr.produit_id
ORDER BY pr.commande_id, pr.ligne_no;

/* ---------------------------------------------------------------------
   8. COMMANDES DE TEST (magasin 99) - à exclure lors de l'ETL
   --------------------------------------------------------------------- */
DECLARE @test TABLE (commande_id INT);

INSERT INTO dbo.commande (magasin_id, client_id, date_commande, statut, mode_paiement)
OUTPUT inserted.commande_id INTO @test
SELECT 99, NULL, DATEADD(HOUR, 10, CAST(DATEADD(DAY, n * 23, CAST('2025-01-06' AS DATE)) AS DATETIME2(0))), 'PAYEE', 'CASH'
FROM #nums WHERE n <= 15;

INSERT INTO dbo.ligne_commande (commande_id, produit_id, quantite, prix_unitaire, remise_pct)
SELECT t.commande_id, 5, 99, 0.01, 0
FROM @test t;

/* ---------------------------------------------------------------------
   9. NETTOYAGE
   --------------------------------------------------------------------- */
DROP TABLE #nums, #param_magasin, #tirage, #jour, #cmd, #cmd2;
GO
DROP FUNCTION dbo.fn_alea;
GO

/* ---------------------------------------------------------------------
   10. CONTRÔLE RAPIDE
   --------------------------------------------------------------------- */
SELECT 'client' AS table_name, COUNT(*) AS nb FROM dbo.client
UNION ALL SELECT 'commande', COUNT(*) FROM dbo.commande
UNION ALL SELECT 'ligne_commande', COUNT(*) FROM dbo.ligne_commande;

SELECT m.ville, DATENAME(MONTH, c.date_commande) AS mois, MONTH(c.date_commande) AS m, COUNT(*) AS nb_commandes
FROM dbo.commande c JOIN dbo.magasin m ON m.magasin_id = c.magasin_id
WHERE c.magasin_id = 1
GROUP BY m.ville, DATENAME(MONTH, c.date_commande), MONTH(c.date_commande)
ORDER BY m;
GO
