/* =====================================================================
   EXERCICE ETL - "Givre & Co"
   Script 02 : entrepôt de données (schéma en étoile)
   ---------------------------------------------------------------------
   dim_date     : créée ET remplie ici (fournie)
   dim_magasin  : à remplir par l'ETL (GlacierApp + API Nominatim)
   dim_produit  : à remplir par l'ETL (GlacierApp + API OpenAI)
   fait_vente   : à remplir par l'ETL (GlacierApp + API Open-Meteo)
   ===================================================================== */

USE master;
GO
IF DB_ID('GlacierDW') IS NOT NULL
BEGIN
    ALTER DATABASE GlacierDW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GlacierDW;
END
GO
CREATE DATABASE GlacierDW;
GO
USE GlacierDW;
GO
SET NOCOUNT ON;
GO

/* ---------------------------------------------------------------------
   DIMENSION DATE (fournie)
   --------------------------------------------------------------------- */
CREATE TABLE dbo.dim_date (
    date_key        INT           NOT NULL PRIMARY KEY,   -- AAAAMMJJ, ex. 20250714
    date_complete   DATE          NOT NULL UNIQUE,
    jour            TINYINT       NOT NULL,
    mois            TINYINT       NOT NULL,
    nom_mois        NVARCHAR(10)  NOT NULL,
    trimestre       TINYINT       NOT NULL,
    annee           SMALLINT      NOT NULL,
    semaine_iso     TINYINT       NOT NULL,
    jour_semaine    TINYINT       NOT NULL,               -- 1 = lundi ... 7 = dimanche
    nom_jour        NVARCHAR(10)  NOT NULL,
    est_weekend     BIT           NOT NULL,
    est_ferie       BIT           NOT NULL,               -- jours fériés légaux belges
    saison          NVARCHAR(10)  NOT NULL
);
GO

;WITH n AS (
    SELECT TOP (DATEDIFF(DAY, '2024-01-01', '2026-12-31') + 1)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS i
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
), d AS (
    SELECT DATEADD(DAY, i, CAST('2024-01-01' AS DATE)) AS dt FROM n
), calc AS (
    SELECT dt,
           (DATEDIFF(DAY, '19000101', dt) % 7) + 1 AS js,     -- indépendant de SET DATEFIRST / LANGUAGE
           MONTH(dt) * 100 + DAY(dt)               AS mmdd
    FROM d
)
INSERT INTO dbo.dim_date
SELECT YEAR(dt) * 10000 + MONTH(dt) * 100 + DAY(dt),
       dt,
       DAY(dt),
       MONTH(dt),
       CHOOSE(MONTH(dt), N'janvier', N'février', N'mars', N'avril', N'mai', N'juin',
                         N'juillet', N'août', N'septembre', N'octobre', N'novembre', N'décembre'),
       DATEPART(QUARTER, dt),
       YEAR(dt),
       DATEPART(ISO_WEEK, dt),
       js,
       CHOOSE(js, N'lundi', N'mardi', N'mercredi', N'jeudi', N'vendredi', N'samedi', N'dimanche'),
       CASE WHEN js >= 6 THEN 1 ELSE 0 END,
       CASE WHEN mmdd IN (101, 501, 721, 815, 1101, 1111, 1225) THEN 1
            WHEN dt IN ('2024-04-01', '2024-05-09', '2024-05-20',     -- lundi de Pâques, Ascension, lundi de Pentecôte
                        '2025-04-21', '2025-05-29', '2025-06-09',
                        '2026-04-06', '2026-05-14', '2026-05-25') THEN 1
            ELSE 0 END,
       CASE WHEN mmdd >= 1221 OR mmdd < 321 THEN N'hiver'
            WHEN mmdd < 621                 THEN N'printemps'
            WHEN mmdd < 923                 THEN N'été'
            ELSE                                 N'automne' END
FROM calc;
GO

/* ---------------------------------------------------------------------
   DIMENSION MAGASIN (à remplir)
   --------------------------------------------------------------------- */
CREATE TABLE dbo.dim_magasin (
    magasin_key     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,  -- clé de substitution
    magasin_id      INT            NOT NULL UNIQUE,          -- clé métier (GlacierApp)
    nom             NVARCHAR(100)  NOT NULL,
    adresse         NVARCHAR(200)  NOT NULL,
    code_postal     VARCHAR(10)    NULL,
    ville           NVARCHAR(100)  NOT NULL,                 -- nettoyée (casse, accents, espaces)
    region          NVARCHAR(100)  NULL,                     -- Nominatim : address.state
    latitude        DECIMAL(9,6)   NULL,                     -- Nominatim : lat
    longitude       DECIMAL(9,6)   NULL,                     -- Nominatim : lon
    est_cotier      BIT            NOT NULL DEFAULT 0,
    date_ouverture  DATE           NOT NULL
);
GO

/* ---------------------------------------------------------------------
   DIMENSION PRODUIT (à remplir)
   --------------------------------------------------------------------- */
CREATE TABLE dbo.dim_produit (
    produit_key     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    produit_id      INT            NOT NULL UNIQUE,
    code            VARCHAR(10)    NOT NULL,
    nom             NVARCHAR(100)  NOT NULL,
    categorie       NVARCHAR(50)   NOT NULL,                 -- si absente : déduite via OpenAI
    type_produit    NVARCHAR(10)   NOT NULL,                 -- 'Froid' / 'Chaud'
    prix_catalogue  DECIMAL(6,2)   NOT NULL,
    allergenes      NVARCHAR(200)  NULL,                     -- OpenAI, ex. 'lait, gluten'
    est_vegan       BIT            NULL,                     -- OpenAI
    est_actif       BIT            NOT NULL
);
GO

/* ---------------------------------------------------------------------
   TABLE DE FAITS (à remplir)
   grain : 1 ligne = 1 produit vendu dans 1 magasin sur 1 jour
   --------------------------------------------------------------------- */
CREATE TABLE dbo.fait_vente (
    date_key          INT            NOT NULL REFERENCES dbo.dim_date(date_key),
    magasin_key       INT            NOT NULL REFERENCES dbo.dim_magasin(magasin_key),
    produit_key       INT            NOT NULL REFERENCES dbo.dim_produit(produit_key),
    -- mesures de vente
    quantite          INT            NOT NULL,
    nb_commandes      INT            NOT NULL,   -- nb de commandes distinctes contenant le produit
    montant_brut      DECIMAL(12,2)  NOT NULL,   -- SUM(quantite * prix_unitaire)
    montant_remise    DECIMAL(12,2)  NOT NULL,   -- SUM(quantite * prix_unitaire * remise_pct / 100)
    montant_net       DECIMAL(12,2)  NOT NULL,   -- brut - remise
    -- contexte météo du jour au magasin (Open-Meteo)
    temp_max          DECIMAL(4,1)   NULL,
    temp_min          DECIMAL(4,1)   NULL,
    precipitation_mm  DECIMAL(5,1)   NULL,
    CONSTRAINT PK_fait_vente PRIMARY KEY (date_key, magasin_key, produit_key)
);
GO

SELECT COUNT(*) AS nb_jours, MIN(date_complete) AS du, MAX(date_complete) AS au FROM dbo.dim_date;
GO
