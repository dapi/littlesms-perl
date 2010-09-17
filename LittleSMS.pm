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
                 [
                  recipients => $recipients,
                  message => $message,
                  test => $self->{test},
                 ]
               );
  
  return $response->status == 'success';
  
}


=begin

Запросить баланс
@return boolean|float

=cut

sub  getBalance {
  my ( $self ) = @_;
  my $response = $self->makeRequest('balance');
  return $response->status == 'success' ? $response->balance : undef;
}


=begin

Отправить запрос

@param string $function
@param array $params
@return stdClass

=cut


sub makeRequest {
  my ( $self, $function, $params ) = @_;
  
  # $params = array_merge(array('user' => $self->user), $params);
  $params->{user} = $self->{user};
  $params->{test} = $self->{test};
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
    return decode_json( $content );
  } else {
    croak("An error happened: Host $url");
  }
  
  # return decode_json( $curl->post($url, \%params) );
}

=begin

Сгенерировать подпись

@param array $params
@return string

=cut

sub sort_params {
  my ( $h, $escape ) = @_;  
  my @params;
  foreach (@SORTED_PARAMS) {
    if (exists $h->{$_}) {
      my $v = $escape ? uri_escape($h->{$_}) : $h->{$_} ;
      push @params, "$_=$v";
    }
  }
  return @params;
}

sub generateSign {
  my ( $self, $h ) = @_;

  my $gs = join( '', sort_params($h) );
  
  print STDERR "generateSign: $gs\n";

  $gs =  md5_hex( sha1_hex ($gs . $self->{key}) );
  print STDERR "sign: $gs\n";
  
  return $gs
}


sub build_query {
  my ( $h ) = @_;
  
  my $post_string = join('&', sort_params( $h, 1 ));

  print STDERR "post_string: $post_string\n";
 # $post_string =  http_build_query($h);
  # print STDERR "php_build_query: ".http_build_query($h);
  
  return $post_string;
  
    # $url         = encode($url)         if $self->{auto_encode};
  # $post_string = encode($post_string) if $self->{auto_encode};  
}

1;
