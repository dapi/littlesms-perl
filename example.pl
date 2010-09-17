#!/usr/bin/perl
use LittleSMS;

# Использовать так:
#
# > example.pl LOGIN KEY
#

my $l = LittleSMS->new(@ARGV);  # login, key, test, useSSL, api_url

print "Мой баланс:" , $l->getBalance(), "\n";

# print $l->sendSMS('77777777','testmessage');



