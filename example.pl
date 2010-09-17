#!/usr/bin/perl

use LittleSMS;

# Запускать так:
#
# > example.pl LOGIN KEY
#

my $l = LittleSMS->new(@ARGV);  # login, key, useSSL, test, api_url

print "Мой баланс: ", $l->getBalance(), "\n";

print $l->sendSMS('79033781228','test message') ? "Успешно отправлено!\n" : "Ошибка!\n";

print "На счету осталось: $l->{response}->{balance}\n";


