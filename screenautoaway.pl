#!/usr/bin/env perl
use Purple;
use strict;
use warnings;

our %PLUGIN_INFO = (
 perl_api_version		=> 2,
 name				=> 'screen autoaway',
 version			=> '$Revision: 1.1 $',
 summary			=> 'perl plugin to make you away when screen detached',
 description		=> 'it makes you away when you are not there, hopefully.',
 author			=> 'Dmitry Sukhodoyev <raven428@gmail.com>',
 url				=> 'http://pidgin.im/',
 load				=> 'plugin_load',
 unload			=> 'plugin_unload',
 prefs_info			=> 'plugin_prefs_cb'
);
my $check_period = 1;

sub plugin_init {
 return %PLUGIN_INFO;
}

sub plugin_periodic {
 my $plugin = shift();
 $check_period = Purple::Prefs::get_string('/plugins/core/perl_screen_autoaway/string_check_period');
 $check_period = 1 if($check_period < 1);
 $check_period = 999 if($check_period > 999);
 Purple::Prefs::set_string('/plugins/core/perl_screen_autoaway/string_check_period', $check_period)
  if ($check_period != Purple::Prefs::get_string('/plugins/core/perl_screen_autoaway/string_check_period'));
 my $screen_socket_path = Purple::Prefs::get_string('/plugins/core/perl_screen_autoaway/string_screen_socket_path');
 unless(-d($screen_socket_path)) {
  Purple::Debug::info('screen_autoaway', "directory [$screen_socket_path] not found. doing nothing.\n");
 } else {
  my $screen_socket_file = $screen_socket_path . '/S-' . $ENV{'USER'} . '/' . $ENV{'STY'};
  unless(-p($screen_socket_file)) {
   Purple::Debug::info('screen_autoaway', "screen socket [$screen_socket_file] not found. doing nothing.\n");
  } else {
   my(
    $dev,$ino,$mode,$nlink,$uid,
    $gid,$rdev,$size,$atime,$mtime,
    $ctime,$blksize,$blocks
   ) = stat($screen_socket_file);
   my $detached = 0;
   $detached = 1 if(($mode & 64) == 0);
#   Purple::Debug::info('screen_autoaway', "detached: [$detached]\n");
   my @accounts = Purple::Accounts::get_all();
   foreach my $account(@accounts) {
    if ($account->is_connected()) {
     my $status = $account->get_active_status();
     my $status_name = lc($status->get_name());
     my $account_name = $account->get_username();
#     Purple::Debug::info('screen_autoaway', "[$account_name] status [$status_name]\n");
     if($detached) {
      if ($status_name ne "away") {
#       Purple::Debug::info('screen_autoaway', "screen detached, but account [$account_name] is [$status_name].\n");
       $account->set_status('away', 1);
#       Purple::Debug::info('screen_autoaway', "account [$account_name] set to away.\n");
      } else {
#       Purple::Debug::info('screen_autoaway', "screen detached, and account [$account_name] is [$status_name].\n");
      }
     } else {
      if ($status_name eq "away") {
#       Purple::Debug::info('screen_autoaway', "screen not detached, but account [$account_name] is [$status_name].\n");
       $account->set_status('available', 1);
#       Purple::Debug::info('screen_autoaway', "account [$account_name] set to available.\n");
      } else {
#       Purple::Debug::info('screen_autoaway', "screen not detached, and account [$account_name] is [$status_name].\n");
      }
     };
    } else {
#     Purple::Debug::info('screen_autoaway', $account->get_username() . " disconnected. doing nothing.\n");
    };
   };
  };
 };

 Purple::timeout_add($plugin, $check_period, \&plugin_periodic, $plugin);
 Purple::Debug::info('screen_autoaway', "plugin_periodic executed.\n");
}

sub plugin_load {
 my $plugin = shift();
 Purple::Prefs::add_none('/plugins/core/perl_screen_autoaway');
 Purple::Prefs::add_string('/plugins/core/perl_screen_autoaway/string_check_period', $check_period);
 Purple::Prefs::add_string('/plugins/core/perl_screen_autoaway/string_screen_socket_path', '/tmp/screens');
 Purple::timeout_add($plugin, $check_period, \&plugin_periodic, $plugin);
 Purple::Debug::info('screen_autoaway', "plugin loaded with interval [$check_period] seconds.\n");
}

sub plugin_prefs_cb {
 my $frame = Purple::PluginPref::Frame->new();
 my $ppref;
 $ppref = Purple::PluginPref->new_with_name_and_label(
  '/plugins/core/perl_screen_autoaway/string_screen_socket_path',
  'screen socket path'
 );
 $ppref->set_type(2);
 $ppref->set_max_length(1);
 $frame->add($ppref);
 $ppref = Purple::PluginPref->new_with_name_and_label(
  '/plugins/core/perl_screen_autoaway/string_check_period',
  'check period'
 );
 $ppref->set_type(2);
 $ppref->set_max_length(250);
 $frame->add($ppref);
 Purple::Debug::info('screen_autoaway',"prefs end\n");
 return $frame;
}

sub plugin_unload {
 my $plugin = shift();
 Purple::Debug::info('screen_autoaway',"plugin removed.\n");
}
