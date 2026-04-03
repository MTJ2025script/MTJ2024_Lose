-- ============================================================
--  MTJ Los - Datenbankeinrichtung
--  Fuehre dieses SQL auf deiner ESX-Datenbank aus
-- ============================================================

-- Los-Items in die ESX items-Tabelle eintragen
INSERT IGNORE INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
    ('mtj_los_silber', 'Silber Los',  1, 0, 1),
    ('mtj_los_gold',   'Gold Los',    1, 0, 1),
    ('mtj_los_platin', 'Platin Los',  1, 1, 1);

-- ============================================================
--  Optional: Items in esx_shops eintragen
--  (Wenn du esx_shops oder einen kompatiblen Shop nutzt)
-- ============================================================

-- Beispiel: Shop mit ID 1 (Convenience Store / Kiosk)
-- Passe shop_id und position an deinen Server an!
-- INSERT INTO `shop_items` (`shop_id`, `item`, `price`) VALUES
--     (1, 'mtj_los_silber', 500),
--     (1, 'mtj_los_gold',   2500),
--     (1, 'mtj_los_platin', 10000);
