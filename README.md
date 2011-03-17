Flengbot
========

Flengbot is a simple/crappy Jabber bot for small groups.
Messages sent to the bot are re-broadcast to all online subscribers.
Messages are also logged to a database, where they are parsed (offline) for links.
These links are presented on <a href="http://flengbot.com/">flengbot.com</a>.


Installation
------------

You'll need some perl modules to get started (assuming you already have perl installed):

    perl -MCPAN -e 'install Net::Jabber'
    perl -MCPAN -e 'install DBD::mysql'

After you have the modules (and their dependencies) installed, you need to create your database.
The <code>schema.sql</code> file will do this for you:

    mysql -u root -p -D database_name < schema.sql

You'll need a Jabber account for the bot to use.
GMail or jabber.org are both good candidates, although they both have reliability issues fairly often.
If you're a serious nerd, consider running your own Jabber server.

Next, edit the settings at the top of <code>bot.pl</code> and enter your own Jabber and MySQL settings.

Finally, run the bot using <code>perl bot.pl</code>.
You might want to run it behind <code>screen</code> once you've confirmed it's working.


Usage
-----

To subscribe to the bot, add it to your contacts and send it a message.
It will explain that you need to send <code>start</code> to it to start subscribing.
Sending <code>stop</code> will stop your subscription.
Any other messages are sent to all subscribers (including yourself).

Nicknames can be set in the users table in the database - they default to your Jabber ID.


Missing bits
------------

This first pass only contains the bot and schema.
The cron task to extract links from the log are missing.
The web portions required to show links and stats are also missing.
I'll add these at some point when they get cleaned up.

Flengbot has been online (in this incarnation) for about 3 years, handling over 50 thousand messages.
It might be ugly, but it mostly works.
