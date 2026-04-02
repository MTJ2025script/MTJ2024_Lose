-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  MTJ2024 Rubbellose – SQL Datenbank-Schema                             ║
-- ║  © Copyright 2024 MTJ2024                                              ║
-- ║  Importiere diese Datei in deine Datenbank (z.B. via HeidiSQL/phpMyAdmin)║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- ── Jackpot-Tabelle ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `mtj_lose_jackpot` (
    `id`            INT(1)          NOT NULL DEFAULT 1,
    `betrag`        BIGINT(20)      NOT NULL DEFAULT 10000,
    `letzter_gewinner` VARCHAR(60)  DEFAULT NULL,
    `letzter_gewinn_datum` TIMESTAMP DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO `mtj_lose_jackpot` (`id`, `betrag`) VALUES (1, 10000);

-- ── Verlauf-Tabelle ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `mtj_lose_verlauf` (
    `id`            INT(11)         NOT NULL AUTO_INCREMENT,
    `identifier`    VARCHAR(60)     NOT NULL,
    `spielername`   VARCHAR(60)     NOT NULL,
    `los_typ`       VARCHAR(30)     NOT NULL,
    `einsatz`       INT(11)         NOT NULL DEFAULT 0,
    `gewinn_name`   VARCHAR(100)    NOT NULL DEFAULT 'Niete',
    `gewinn_betrag` INT(11)         NOT NULL DEFAULT 0,
    `gewinn_typ`    VARCHAR(20)     NOT NULL DEFAULT 'nichts',
    `ist_jackpot`   TINYINT(1)      NOT NULL DEFAULT 0,
    `datum`         TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_identifier` (`identifier`),
    KEY `idx_datum` (`datum`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Spieler-Statistik-Tabelle ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `mtj_lose_stats` (
    `identifier`        VARCHAR(60)     NOT NULL,
    `spielername`       VARCHAR(60)     NOT NULL DEFAULT '',
    `gesamt_kaeufe`     INT(11)         NOT NULL DEFAULT 0,
    `gesamt_ausgaben`   BIGINT(20)      NOT NULL DEFAULT 0,
    `gesamt_gewinne`    BIGINT(20)      NOT NULL DEFAULT 0,
    `jackpot_gewinne`   INT(11)         NOT NULL DEFAULT 0,
    `verluste_serie`    INT(11)         NOT NULL DEFAULT 0,
    `kaeufe_heute`      INT(11)         NOT NULL DEFAULT 0,
    `letzter_kauf`      TIMESTAMP       DEFAULT NULL,
    `letzter_gross_gewinn` TIMESTAMP    DEFAULT NULL,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── ESX Items eintragen (fuehre dies NUR aus wenn du oxmysql/ESX nutzt) ──────
-- INSERT IGNORE INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
--     ('mtj_los_standard', 'Standard Rubbellos',  1, 0, 1),
--     ('mtj_los_silber',   'Silber Rubbellos',     1, 0, 1),
--     ('mtj_los_gold',     'Gold Rubbellos',       1, 0, 1),
--     ('mtj_los_diamant',  'Diamant Rubbellos',    1, 1, 1);
