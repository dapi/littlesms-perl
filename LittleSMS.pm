=begin

Класс для работы с сервисом LittleSMS.ru

Функции:
 - отправка SMS
 - запрос баланса

@author Данил Письменный <danil@orionet.ru>

Взял пример с PHP класса http://github.com/pycmam/littlesms/blob/master/LittleSMS.class.php
от Рустама Миниахметова <pycmam@gmail.com>


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


# use vars qw(
#              @ISA
#              @EXPORT
#           );

# @ISA = qw(Exporter);

# ( $VERSION ) = '$Revision: 1.8 $ ' =~ /\$Revision:\s+([^\s]+)/;

# @EXPORT = qw(config
#              setConfig);



  # protected
  # $user = null,
  # $key = null,
  # $testMode = 0,
  # $url = 'littlesms.ru/api/',
  # $useSSL = true;


=begin

Конструктор

@param string $user
@param string $key
@param integer $testMode

=cut
  
sub new {
  my ($class, $user, $key, $test, $useSSL, $url) = @_;
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


=begin

Отправить SMS

@param string|array $recipients
@param string $message
@return boolean

=cut

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


=begin

Запросить баланс
@return boolean|float

=cut

sub  getBalance {
  my ( $self ) = @_;
  my $response = $self->makeRequest('balance');
  return $response->{status} eq 'success' ? $response->{balance} : undef;
}


=begin

Отправить запрос

@param string $function
@param array $params
@return stdClass

=cut


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
    return decode_json( $content );
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
