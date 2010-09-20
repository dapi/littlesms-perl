#!/usr/bin/perl

use LittleSMS;

# Запускать так:
#
# > example.pl LOGIN KEY
#

new LittleSMS(@ARGV);  # login, key, useSSL, test, api_url

print "Мой баланс: ", sms()->getBalance(), "\n";

# print sms()->sendSMS('НОМЕР','test message') ? "Успешно отправлено!\n" : "Ошибка!\n";
# print "На счету осталось: $l->{response}->{balance}\n";


