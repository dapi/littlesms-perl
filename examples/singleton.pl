#!/usr/bin/perl

use LittleSMS;
$LittleSMS::DEBUG=1;


use Data::Dumper;

# Запускать так:
#
# > singleton.pl LOGIN KEY
#

my $telefon = НОМЕР;


new LittleSMS(@ARGV);                     # login, key, useSSL, test, api_url

print "Мой баланс: ", sms()->getBalance(), "\n";

#sms()->setBalanceControl( 100, $telefon); # Установить контроль

sms()->setSender('smstest'); # Максимум 11 символов


sms()->sendSMS($telefon, 'Тестовое сообщение #2');    # Если на этом вызове сервис
                                          # вернул указанный в контроле
                                          # баланс, то автоматически на
                                          # телефон админа отправится
                                          # установленное ранее сообщение.

print "На счету осталось:", sms()->response('balance'), "\n";

print Dumper(sms()->response());

my $ids = sms()->response('messages_id');

my $mr;

# // запрос статуса сообщения
do {
  my $result = sms()->checkStatus($ids);
  my $id = (keys %{$result->{messages}})[0];  
  
  $mr = $result->{messages}->{$id};

  print "Status of message $id is: '$mr'\n";
  
  sleep 1;
  
} while ($mr ne 'sent');

