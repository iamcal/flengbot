#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;

use Net::Jabber qw( Client );
use DBI;

$|++;
$ENV{TZ} = 'PST8PDT';

my $config = {
	'name'		=> 'MY BOT',		# public name of bot
	'jabber_user'	=> '',			# jabber username
	'jabber_pass'	=> '',			# jabber password
	'jabber_res'	=> '',			# jabber 'resource' (any string will do)
	'jabber_server'	=> 'jabber.org',	# jabber server hostname
	'jabber_port'	=> '5222',		# jabber server port
	'db_host'	=> 'localhost',		# mysql host
	'db_name'	=> 'mybot',		# mysql database name
	'db_user'	=> 'root',		# mysql username
	'db_pass'	=> '',			# mysql password
	'db_port'	=> '3306',		# mysql port
	'db_prefix'	=> 'mybot',		# mysql table name prefix
};

#############################################################################################

my $dsn = "DBI:mysql:database=$config->{db_name};host=$config->{db_host};port=$config->{db_port}";
my $dbh = undef;

&recon();

sub recon{
	if ($dbh){
		return if $dbh->ping;
	}
	$dbh = DBI->connect($dsn, $config->{db_user}, $config->{db_pass});
	print &d() . " DBH: ". Dumper $dbh;
}

my $cli;

while (1){
	$cli = Net::Jabber::Client->new();

	$cli->SetCallBacks(
		'message'	=> \&got_message,
		'receive'	=> \&got_xml,
		'presence'	=> \&got_presence,
	);


	my $status = $cli->Connect(
		'hostname'	=> $config->{jabber_server},
		port		=> $config->{jabber_port},
		connectiontype	=> 'tcpip',
		tls		=> 1,
		timeout		=> 10
	);

	if (!(defined($status))){

		print &d() . " failed to connect - waiting 30 seconds\n";
		print &d() . " error: ";
		print Dumper $cli->GetErrorCode();
		$cli->Disconnect();
		#print Dumper $cli;
		#exit;
		sleep(30);
		next;
	}else{

		print &d() . " connected\n";
	}

	my @auth = $cli->AuthSend(
		'username'	=> $config->{jabber_user},
		'password'	=> $config->{jabber_pass},
		'resource'	=> $config->{jabber_res},
	);

	if (@auth && $auth[0] eq "ok"){

		print &d() . " authed\n";
	}else{
		print &d() . " auth failed - waiting 3 seconds\n";
		$cli->Disconnect();
		sleep(3);
		next;
	}

	$cli->PresenceSend();

	print &d() . " presence sent\n";

	while (1){
		my $ret = $cli->Process(1);
		#print "ret: $ret\n";
		last unless defined $ret;
	};

	$cli->Disconnect();

	print &d() . " disconncted - reconnecting now...\n";
}

sub got_message {

	my ($session_id, $message) = @_;

	if ($message->GetType() eq 'error'){
		my $code = $message->GetErrorCode();
		my $error = $message->GetError();
		my $xml = $message->{TREE}->GetXML();

		if ($code == 503){
			my $from = $message->GetFrom();
			#print "Failed to send to $from (503)\n";
			return;
		}

		print "Got error $code : $error\n";
		print $xml."\n";
		#print Dumper $message;
		return;
	}

	unless ($message->GetType() eq 'chat'){
		print "bad message type: ".$message->GetType()."\n";
		#print Dumper $message;
		return;
	}

	my $from = $message->GetFrom();
	my $body = $message->GetBody();

	my ($user, $crap) = split '/', $from;

	my $body_clean = lc $body;
	$body_clean =~ s/^\s*(.*?)\s*$/$1/;

	if ($body_clean eq ''){
		#print "empty message body\n";
		return;
	}

	#
	#
	#

	#print "got a message from $user\n";
	#print "message: $body\n";

	print "$user: $body\n";

	&recon();


	#
	# step 1 - are they a subscriber?
	#

	my $sth = $dbh->prepare("SELECT * FROM $config->{db_prefix}_users WHERE user=? AND subscribed=1");
	$sth->execute($user);

	if (!$sth->rows){

		if ($body_clean eq 'start'){

			my $sth2 = $dbh->prepare("INSERT INTO $config->{db_prefix}_users (user, nickname, subscribed) VALUES (?, ?, 1) ON DUPLICATE KEY UPDATE subscribed=1");
			$sth2->execute($user, $user);

			$cli->MessageSend(
				to	=> $user,
				body	=> "you're now subscribed to $config->{name}. type 'stop' to unsubscribe",
			);

			return;
		}else{

			$cli->MessageSend(
				to	=> $user,
				body	=> "we don't know $user yet - type 'start' to subscribe to $config->{name}",
			);

			return;
		}
	}

	my $user_row = $sth->fetchrow_hashref();	


	#
	# step 2 - we know this user - check for commands
	#

	if ($body_clean eq 'stop'){

		my $sth5 = $dbh->prepare("UPDATE $config->{db_prefix}_users SET subscribed=0 WHERE user=?");
		$sth5->execute($user);

		$cli->MessageSend(
			to	=> $user,
			body	=> "you've been unsubscribed from $config->{name}. goodbye!",
		);

		return;
	}


	#
	# is this an auto-reply?
	#

	if ($body =~ m/\(Autoreply\)/){

		return;
	}


	#
	# user blocked from sending?
	#

	if ($user_row->{block_send}){

		$cli->MessageSend(
			to	=> $user,
			body	=> $user_row->{nickname}.': '.$body,
		);
		print "blocked message from $user\n";
		return;
	}



	#
	# step 3 - nothing special, so broadcast it
	#

	my $sth4 = $dbh->prepare("INSERT INTO $config->{db_prefix}_messages (date_create, user, message) VALUES (?,?,?)");
	$sth4->execute(time(), $user, $body);

	my $sth3 = $dbh->prepare("SELECT * FROM $config->{db_prefix}_users WHERE subscribed=1 AND block_recv=0");
	$sth3->execute();

	while (my $row = $sth3->fetchrow_hashref()){

		my $to = $user_row->{nickname};

		#print "\t sending to $row->{user}...\n";

		$cli->MessageSend(
			to	=> $row->{user},
			body	=> $to.': '.$body,
		);
	}
}

sub d {
	my $a = `date +"%F %T"`;
	chomp $a;
	return $a;
}

sub got_xml {

	my ($session_id, $xml) = @_;

	# uncomment this to debug stuff - it shows all incoming xml
	#print "XML: $xml\n";
}

sub got_presence {

	my ($session_id, $message) = @_;

	my $from = $message->GetFrom();
	my ($user, $crap) = split '/', $from;

	my $us = $config->{jabber_user}.'@'.$config->{jabber_server};

	if ($user eq $us){

		my $type = $message->GetType();

		if ($type ne 'available' && $type ne ''){

			print "Inisiting we're online...\n";
			$cli->PresenceSend();
		}
	}
}
