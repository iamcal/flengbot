SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

CREATE TABLE IF NOT EXISTS `mybot_links` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `date_first` int(10) unsigned NOT NULL,
  `month_first` date NOT NULL,
  `url` varchar(255) NOT NULL,
  `who_first` varchar(255) NOT NULL,
  `num_refs` int(10) unsigned NOT NULL,
  `tweeted` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `url` (`url`),
  KEY `tweeted` (`tweeted`,`date_first`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 ;

CREATE TABLE IF NOT EXISTS `flengbot_messages` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `date_create` int(10) unsigned NOT NULL,
  `user` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `scanned` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `user` (`user`,`date_create`),
  KEY `scanned` (`scanned`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 ;

CREATE TABLE IF NOT EXISTS `flengbot_users` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `user` varchar(255) NOT NULL,
  `nickname` varchar(255) NOT NULL,
  `subscribed` tinyint(3) unsigned NOT NULL,
  `block_send` tinyint(4) NOT NULL,
  `block_recv` tinyint(4) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `user` (`user`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 ;
