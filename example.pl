#!/usr/bin/perl
use LittleSMS;

# Использовать так:
#
# > example.pl LOGIN KEY
#

my $lsms = LittleSMS->new(@ARGV);  # login, key, test, useSSL, api_url

$lsms->getBalance();
$lsms->sendSMS('7907777777','testmessage');



