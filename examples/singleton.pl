#!/usr/bin/perl

use LittleSMS;
use Data::Dumper;

# Запускать так:
#
# > singleton.pl LOGIN KEY
#

my $telefon = ТЕЛЕФОН;


new LittleSMS(@ARGV);                     # login, key, useSSL, test, api_url

print "Мой баланс: ", sms()->getBalance(), "\n";

# print sms()->sendSMS('НОМЕР','test message') ? "Успешно отправлено!\n" : "Ошибка!\n";
# print "На счету осталось:", sms()->response()->{balance}\n";


sms()->setBalanceControl( 100, $telefon); # Установить контроль
                                          # с сообщенем по-умолчанию


sms()->sendSMS($telefon, 'СООБЩЕНИЕ');    # Если на этом вызове сервис
                                          # вернул указанный в контроле
                                          # баланс, то автоматически на
                                          # телефон админа отправится
                                          # установленное ранее сообщение.

print Dumper(sms()->response());

print "На счету осталось:", sms()->response('balance'), "\n";
