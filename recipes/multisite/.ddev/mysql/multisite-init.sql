-- Creates extra databases for the multisite recipe.
-- Runs once when the DB volume is first initialised.
-- Grants the standard DDEV user ('db'@'%') full access.

CREATE DATABASE IF NOT EXISTS `db_site1`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS `db_site2`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

GRANT ALL PRIVILEGES ON `db_site1`.* TO 'db'@'%';
GRANT ALL PRIVILEGES ON `db_site2`.* TO 'db'@'%';

FLUSH PRIVILEGES;
