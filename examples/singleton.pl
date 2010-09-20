#!/usr/bin/perl

use LittleSMS;

# Запускать так:
#
# > singleton.pl LOGIN KEY
#

new LittleSMS(@ARGV);  # login, key, useSSL, test, api_url

print "Мой баланс: ", sms()->getBalance(), "\n";

# print sms()->sendSMS('НОМЕР','test message') ? "Успешно отправлено!\n" : "Ошибка!\n";
# print "На счету осталось:", sms()->response()->{balance}\n";


sms()->setBalanceControl( 197.5, '77777777777'); # Установить контроль
                                                 # с сообщенем по-умолчанию


sms()->sendSMS('77777777777', 'СООБЩЕНИЕ'); # Если на этом вызове сервис
                                            # вернул указанный в контроле
                                            # баланс, то автоматически на
                                            # телефон админа отправится
                                            # установленное ранее сообщение.

print "На счету осталось:", sms()->response('balance');
