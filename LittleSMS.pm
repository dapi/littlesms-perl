=head1 NAME

LittleSMS - Perl модуль для работы с сервисом LittleSMS.ru

=head1 SYNOPSIS

  use LittleSMS;

  my $l = LittleSMS->new(@ARGV);  # login, key, useSSL, test, api_url

  print "Мой баланс: ", $l->getBalance(), "\n";

  print $l->sendSMS('79033781228','test message') ? "Успешно отправлено!\n" : "Ошибка!\n";

  print "На счету осталось: $l->{response}->{balance}\n";
  

=head1 DESCRIPTION

Функции:
 - отправка SMS
 - запрос баланса

=head2 Methods

=over 4

=item * LittleSMS->new(login, key, useSSL, test, api_url)

Все параметры, кроме login и key, указывать не обязательно. А api_url
даже не нужно.

=item * $l->getBalance()

Возвращает баланс.

=item * $object->sendSMS(телефон, сообщение)

Отправляет сообщение и возвращает true в случае удачи.

=item * $object->makeRequest(function, parameters)

- function - Строка с именем функции (balance или send)
- parameters - hashref на параметры запроса. См: https://littlesms.ru/doc

=back

=head1 AUTHOR

@author Данил Письменный <danil@orionet.ru>

Взял пример с PHP класса http://github.com/pycmam/littlesms/blob/master/LittleSMS.class.php
от Рустама Миниахметова <pycmam@gmail.com>

=head1 COPYRIGHT

Модуль представляется "как есть", без гарантий.

Copyright 2010.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

https://littlesms.ru/doc

=cut


package LittleSMS;
use strict;
use warnings;

use WWW::Curl::Easy;
use LWP::Curl;
use URI::Escape;
use Digest::MD5 qw(md5_hex);
use Digest::SHA1 qw(sha1_hex);
use JSON::XS;
use PHP::HTTPBuildQuery qw(http_build_query);

use vars qw(
             @SORTED_PARAMS
          );

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
  return $self;
}



sub sendSMS {
  my ($self, $recipients, $message) = @_;
  
  my $response = $self->
    makeRequest( 'send',
                 {
                  recipients => $recipients,
                  message => $message,
                  test => $self->{test},
                 }
               );
  
  return $response->{status} eq 'success';  
}


sub  getBalance {
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
    #return $curl->{status};
    return $self->{response} = decode_json( $content );
  } else {
    croak("An error happened: Host $url");
  }
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
