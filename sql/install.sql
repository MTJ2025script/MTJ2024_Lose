-- ============================================================
--  MTJ Los – Datenbankinstallation
--  Fuehre dieses SQL einmalig auf deiner ESX-Datenbank aus.
-- ============================================================

-- ── Los-Items in die ESX items-Tabelle eintragen ───────────
INSERT IGNORE INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
    ('mtj_los_silber', 'Silber Los',  1, 0, 1),
    ('mtj_los_gold',   'Gold Los',    1, 0, 1),
    ('mtj_los_platin', 'Platin Los',  1, 1, 1);

-- ── Ticket-Konfiguration (Admin-Tablet speichert hier) ─────
CREATE TABLE IF NOT EXISTS `mtj_los_tickets` (
    `id`          INT           AUTO_INCREMENT PRIMARY KEY,
    `item_name`   VARCHAR(64)   UNIQUE NOT NULL,
    `label`       VARCHAR(128)  NOT NULL,
    `ticket_bg`   VARCHAR(128)  DEFAULT '',
    `shop_price`  INT           DEFAULT 500,
    `active`      TINYINT(1)    DEFAULT 1,
    `created_at`  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── Preis-Konfiguration ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS `mtj_los_prizes` (
    `id`          INT           AUTO_INCREMENT PRIMARY KEY,
    `ticket_id`   INT           NOT NULL,
    `type`        VARCHAR(16)   NOT NULL DEFAULT 'nothing',
    `label`       VARCHAR(128)  NOT NULL,
    `image`       VARCHAR(128)  DEFAULT '',
    `chance`      INT           DEFAULT 10,
    `amount`      INT           DEFAULT 0,
    `item_name`   VARCHAR(64)   DEFAULT '',
    `weapon`      VARCHAR(64)   DEFAULT '',
    `ammo`        INT           DEFAULT 0,
    `car_model`   VARCHAR(64)   DEFAULT '',
    INDEX `idx_ticket_id` (`ticket_id`),
    FOREIGN KEY (`ticket_id`) REFERENCES `mtj_los_tickets`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── Gewinn-Verlauf (fuer Statistiken) ──────────────────────
CREATE TABLE IF NOT EXISTS `mtj_los_history` (
    `id`                  INT           AUTO_INCREMENT PRIMARY KEY,
    `player_identifier`   VARCHAR(64)   NOT NULL,
    `player_name`         VARCHAR(128)  NOT NULL,
    `ticket_item`         VARCHAR(64)   NOT NULL,
    `prize_type`          VARCHAR(16)   NOT NULL,
    `prize_label`         VARCHAR(128)  NOT NULL,
    `scratched_at`        TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_identifier`   (`player_identifier`),
    INDEX `idx_scratched_at` (`scratched_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── Optional: Items in esx_shops eintragen ─────────────────
-- INSERT INTO `shop_items` (`shop_id`, `item`, `price`) VALUES
--     (1, 'mtj_los_silber', 500),
--     (1, 'mtj_los_gold',   2500),
--     (1, 'mtj_los_platin', 10000);
