#!perl

use strict;
use warnings;
use Test::More;
use Module::Build;

eval "use Net::SNMP";
plan skip_all => "Net::SNMP required for testing Net::SNMP::Mixin module"
  if $@;

eval "use Net::SNMP::Mixin";
plan skip_all =>
  "Net::SNMP::Mixin required for testing Net::SNMP::Mixin module"
  if $@;

plan tests => 28;
#plan 'no_plan';

my $builder        = Module::Build->current;
my $snmp_agent     = $builder->notes('snmp_agent');
my $snmp_community = $builder->notes('snmp_community');
my $snmp_version   = $builder->notes('snmp_version');

SKIP: {
  skip '-> no live tests', 28, unless $snmp_agent;

  my ( $session, $error ) = Net::SNMP->session(
    hostname  => $snmp_agent,
    community => $snmp_community || 'public',
    version   => $snmp_version || '2c',
  );

  ok( !$error, 'got snmp session for live tests' );
  isa_ok( $session, 'Net::SNMP' );

  isa_ok( $session->mixer('Net::SNMP::Mixin::IpRouteTable'), 'Net::SNMP' );
  ok( $session->can('get_ip_route_entries'),
    'can $session->get_ip_route_entries' );


  eval { $session->init_mixins };
  ok( !$@, 'init_mixins successful' );

  eval { $session->init_mixins(1) };
  ok( !$@, 'already initalized but reload forced' );

  eval { $session->init_mixins };
  like(
    $@,
    qr/already initalized and reload not forced/i,
    'already initalized and reload not forced'
  );

  eval { Net::SNMP->init_mixins };
  like(
    $@,
    qr/pure instance method called as class method/i,
    'pure instance method called as class method'
  );

  my ($ip_route_table);
  eval { $ip_route_table = $session->get_ip_route_entries };
  ok( !$@, 'get_ip_route_entries' );

  undef $session;

  # nonblockin tests
  ( $session, $error ) = Net::SNMP->session(
    hostname    => $snmp_agent,
    community   => $snmp_community || 'public',
    version   => $snmp_version || '2c',
    nonblocking => 1,
  );

  ok( !$error, 'got snmp session for live tests' );
  isa_ok( $session, 'Net::SNMP' );

  isa_ok( $session->mixer('Net::SNMP::Mixin::IpRouteTable'), 'Net::SNMP' );
  ok( $session->can('get_ip_route_entries'),
    'can $session->get_ip_route_entries' );

  eval { $session->init_mixins };
  snmp_dispatcher();
  ok( !$@, 'init_mixins successful' );

  eval { $session->init_mixins(1) };
  snmp_dispatcher();
  ok( !$@, 'already initalized but reload forced' );

  eval { $ip_route_table = $session->get_ip_route_entries };
  ok( !$@, 'get_ip_route_entries' );

  undef $session;

  # tests with wrong community
  ( $session, $error ) = Net::SNMP->session(
    hostname  => $snmp_agent,
    community => '_foo_bar_bazz_yazz_%_',
    version   => $snmp_version || '2c',
    timeout   => 1,
    retries   => 0,
  );

  ok( !$error, 'got snmp session for live tests' );
  isa_ok( $session, 'Net::SNMP' );

  isa_ok( $session->mixer('Net::SNMP::Mixin::IpRouteTable'), 'Net::SNMP' );
  ok( $session->can('get_ip_route_entries'),
    'can $session->get_ip_route_entries' );

  eval { $session->init_mixins };
  like(
    $session->errors,
    qr/No response from remote host/i,
    'No response from remote host'
  );

  eval { $ip_route_table = $session->get_ip_route_entries };
  like( $@, qr/not initialized/, 'not initialized' );

  undef $session;

  # nonblocking tests with wrong community
  ( $session, $error ) = Net::SNMP->session(
    hostname    => $snmp_agent,
    community   => '_foo_bar_bazz_yazz_%_',
    version   => $snmp_version || '2c',
    timeout     => 1,
    retries     => 0,
    nonblocking => 1,
  );

  ok( !$error, 'got snmp session for live tests' );
  isa_ok( $session, 'Net::SNMP' );

  isa_ok( $session->mixer('Net::SNMP::Mixin::IpRouteTable'), 'Net::SNMP' );
  ok( $session->can('get_ip_route_entries'),
    'can $session->get_ip_route_entries' );


  eval { $session->init_mixins };
  snmp_dispatcher();
  like(
    $session->errors,
    qr/No response from remote host/i,
    'No response from remote host'
  );

  eval { $ip_route_table = $session->get_ip_route_entries };
  like( $@, qr/not initialized/, 'not initialized' );

}

# vim: ft=perl sw=2
