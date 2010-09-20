# -*- coding: utf-8 -*-

=encoding utf-8

=head1 NAME

LittleSMS - Perl модуль для работы с сервисом LittleSMS.ru

=head1 SYNOPSIS

  use LittleSMS;

  my $l = LittleSMS->new(@ARGV);  # login, key, useSSL, test, api_url

  print "Мой баланс: ", $l->getBalance(), "\n";

  print $l->sendSMS('79033781228','test message') ? "Успешно отправлено!\n" : "Ошибка!\n";

  print "На счету осталось: $l->{response}->{balance}\n";



После инициализации обьекта LittleSMS можно использовать как
Singleton: 

  new LittleSMS(@ARGV);  # login, key, useSSL, test, api_url

  sms()->getBalance(); 
  sms()->sendSMS(...);


=head1 DESCRIPTION

Функции:
 - отправка SMS
 - запрос баланса

=head2 Methods:

=over 6

=item LittleSMS->new(login, key, useSSL, test, api_url)

Все параметры, кроме login и key, указывать не обязательно. А api_url
даже не нужно.

=item sms()

Singleton вызов обьекта. Возможно после только после его
инициализации. Например:

  new LittleSMS(@ARGV);  # login, key, useSSL, test, api_url

  sms()->getBalance();


=item $object->getBalance()

Возвращает баланс.

=item $object->sendSMS(телефон, сообщение)

Отправляет сообщение и возвращает true в случае удачи. Можно указывать
массив телефонов для массовой рассылки:

   $object->sendSMS([ номер1, номер2, номер3 ], сообщение)


=item $object->makeRequest(function, parameters)

- function - Строка с именем функции (balance или send)
- parameters - hashref на параметры запроса. См: https://littlesms.ru/doc


=item $object->setBalanceControl( сумма, телефон, [сообщение] )

Устанавливает значение баланса при котором на указанный телефон
отправляется сообщение. Баланс проверяется автоматически каждый раз
после вызова sendSMS.

  # Установить контроль с сообщенем по-умолчанию

  sms()->setBalanceControl( 100, '77777777777');


  # Определить свое сообщение

  sms()->setBalanceControl( 100, '77777777777', 'Кранты, пора платить в LittleSMS');


  # Отменить контроль.

  sms()->setBalanceControl( 0 );

=item $object->response([key])

Возвращает поседний ответ вызова makeRequest(), то есть и после
getBalance и после sendSMS. В случае вызова без ключа возвращает весь HASH
ответа, в случае вызова с ключем возвращает значение ключа.

  sms()->sendSMS('НОМЕР','test message') ? "Успешно отправлено!\n" : "Ошибка!\n";
  print "На счету осталось:", sms()->response('balance');


=back

=head1 AUTHOR

Данил Письменный <danil@orionet.ru> http://dapi.ru/

Взял пример с PHP класса http://github.com/pycmam/littlesms/blob/master/LittleSMS.class.php
от Рустама Миниахметова <pycmam@gmail.com>

=head1 COPYRIGHT

Модуль представляется "как есть", без гарантий.

Copyright 2010.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

https://littlesms.ru/doc

Github repo for this module: http://github.com/dapi/littlesms-perl


=cut


package LittleSMS;
use strict;
use warnings;

use WWW::Curl::Easy;
use URI::Escape;
use Digest::MD5 qw(md5_hex);
use Digest::SHA1 qw(sha1_hex);
use JSON::XS;

use Exporter;
use base qw(Exporter);

use vars qw(
             @EXPORT
             @SORTED_PARAMS
             $INSTANCE
             $VERSION
          );

$VERSION = '0.3';


@EXPORT = qw(sms);

@SORTED_PARAMS = qw(user recipients message test sign);


sub new {
  my ($class, $user, $key, $useSSL, $test, $url) = @_;
  my $self =  bless {
                     user => $user,
                     key => $key,
                     useSSL => defined $useSSL ? $useSSL : 1,
                     test => $test || 0,
                     url => $url || 'littlesms.ru/api/'
                    }, $class;
  # print STDERR "$user/$key/$useSSL/$test/$url\n";
  return $INSTANCE=$self;
}

sub sms {
  $INSTANCE
}

sub sendSMS {
  # my $self = UNIVERSAL::isa($_[0], 'LittleSMS') ? shift : SMS();

  my ($self, $recipients, $message, $dont_check ) = @_;
  
  my $response = $self->
    makeRequest( 'send',
                 {
                  recipients => ref($recipients)=~/ARRAY/ ? join(',',@$recipients) : $recipients,
                  message => $message,
                  test => $self->{test},
                  balance_control => {}
                 }
               );

  $self->checkBalance($response) unless $dont_check;

  
  return $response->{status} eq 'success';  
}

sub setBalanceControl {
  my ( $self, $balance, $number, $message ) = @_;
  my $bc = $self->{balance_control};
  if ($balance>0) {
    $bc->{balance} = $balance;
    $bc->{number} = $number if $number;
    $bc->{message} = $message || $bc->{message} || "Баланс на LittleSMS опустился до $balance руб.";
    die "Не указан номер для контроля баланса" unless $bc->{number};    
  } else {
    $bc->{balance} = 0; # Отключить контроль баланса;
    
  }
  $self->{balance_control}=$bc;
  
}


sub getBalance {
  my ( $self ) = @_;
  my $response = $self->makeRequest('balance');
  return $response->{status} eq 'success' ? $response->{balance} : undef;
}


sub makeRequest {
  my ( $self, $function, $params ) = @_;
  $params = {} unless $params;
  $params->{user} = $self->{user};
  $params->{sign} = $self->generateSign($params);
  
  my $url = ($self->{useSSL} ? 'https://' : 'http://') . $self->{url} . $function;

  my $curl = new WWW::Curl::Easy;
  
  $curl->setopt( CURLOPT_URL,  $url );
  $curl->setopt( CURLOPT_HEADER, 1 );


  if ($self->{useSSL}) {
    $curl->setopt( CURLOPT_SSL_VERIFYPEER, 0 );
    $curl->setopt( CURLOPT_SSL_VERIFYHOST, 0 );
  }

  $curl->setopt( CURLOPT_POSTFIELDS, build_query( $params ) );
  $curl->setopt( CURLOPT_POST, 1 );   # $curl->setopt( CURLOPT_HTTPGET,    0 );
  

  my $content = "";
  open( my $fileb, ">", \$content );
  $curl->setopt( CURLOPT_WRITEDATA, $fileb );
  
  if ( $curl->perform == 0 ) {
    $content=~s/(\n|.)+\n//i; # Удаляем заголовок
    return $self->{response} = decode_json( $content );
  } else {
    croak("An error happened: Host $url");
  }
}

sub response {
  my ($self, $key) = @_;
  $key ? $self->{response}->{$key} : $self->{response};
}



#
# Private methods:
#

sub checkBalance {
  my ( $self, $response ) = @_;
  $self->balance_control()->{status} = 0;
  return undef unless $response && $self->balance_control('balance');

  if ($response->{balance}==$self->balance_control('balance')) {
    $self->sendSMS( $self->balance_control('number'), $self->balance_control('message'), 1 );
    $self->balance_control()->{sent} += 1;
    $self->balance_control()->{status} = 1;
  }
  
}

sub balance_control {
  my ($self, $key ) = @_;
  $key ? $self->{balance_control}->{$key} : $self->{balance_control};
}

sub generateSign {
  my ( $self, $h ) = @_;
  my @params;
  foreach (@SORTED_PARAMS) {
      push @params, $h->{$_} if exists $h->{$_};
  }
   md5_hex( sha1_hex (join( '', @params ) . $self->{key}) );
}


sub build_query {
  my ( $h ) = @_;
  my @params;
  foreach (@SORTED_PARAMS) {
    push @params, "$_=".uri_escape($h->{$_})
      if exists $h->{$_}
    }
  join('&', @params);
}

1;
