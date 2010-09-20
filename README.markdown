
Пример использования:

	use LittleSMS;

	my $l = LittleSMS->new( ЛОГИН, КЛЮЧ );
        
        $l->setBalanceControl( 100, НОМЕР_АДМИНА, 'Пора пополнять баланс' );

	my $balance = $l->getBalance();
        
	$l->sendSMS( НОМЕР, СООБЩЕНИЕ ); 


Более подробная документация:

	> perldoc LittleSMS
        

* [Примеры](examples/)
* (http://littlesms.ru/doc/)
* [PHP-модуль](http://github.com/pycmam/littlesms)


Автор:

Данил Письменный (http://dapi.ru)
