#########################################################################
#  OpenKore - Network subsystem
#  This module contains functions for sending messages to the server.
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################
# pRO (Philippines)
# Servertype overview: https://openkore.com/wiki/ServerType
package Network::Send::pRO;

use strict;
use base qw(Network::Send::ServerType0);

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);

	my %handlers = qw(
		actor_action 0437
		skill_use 0438
		character_move 035F
		sync 0360
		actor_look_at 0361
		item_take 0362
		item_drop 0363
		storage_item_add 0364
		storage_item_remove 0365
		skill_use_location 0366
		actor_info_request 0368
		actor_name_request 0369
		buy_bulk_buyer 0819
		buy_bulk_request 0817
		buy_bulk_closeShop 0815
		buy_bulk_openShop 0811
		item_list_window_selected 07E4
		map_login 0436
		party_join_request_by_name 02C4
		friend_request 0202
		homunculus_command 022D
		storage_password 023B
		buy_bulk_vender 0801
		party_setting 07D7
		send_equip 0998
		master_login 0A76
		game_login 0275
		char_create 0067
		rodex_open_mailbox 0AC0
		rodex_refresh_maillist 0AC1
	);

	$self->{packet_lut}{$_} = $handlers{$_} for keys %handlers;

	return $self;
}

sub reconstruct_master_login {
	my ($self, $args) = @_;

	$args->{ip} = '192.168.0.2' unless exists $args->{ip}; # gibberish
	$args->{mac} = '111111111111' unless exists $args->{mac}; # gibberish
	$args->{mac_hyphen_separated} = join '-', $args->{mac} =~ /(..)/g;
	$args->{isGravityID} = 0 unless exists $args->{isGravityID};

	if (exists $args->{password}) {
		for (Digest::MD5->new) {
			$_->add($args->{password});
			$args->{password_md5} = $_->clone->digest;
			$args->{password_md5_hex} = $_->hexdigest;
		}

		my $key = pack('C32', (0x06, 0xA9, 0x21, 0x40, 0x36, 0xB8, 0xA1, 0x5B, 0x51, 0x2E, 0x03, 0xD5, 0x34, 0x12, 0x00, 0x06, 0x06, 0xA9, 0x21, 0x40, 0x36, 0xB8, 0xA1, 0x5B, 0x51, 0x2E, 0x03, 0xD5, 0x34, 0x12, 0x00, 0x06));
		my $chain = pack('C32', (0x3D, 0xAF, 0xBA, 0x42, 0x9D, 0x9E, 0xB4, 0x30, 0xB4, 0x22, 0xDA, 0x80, 0x2C, 0x9F, 0xAC, 0x41, 0x3D, 0xAF, 0xBA, 0x42, 0x9D, 0x9E, 0xB4, 0x30, 0xB4, 0x22, 0xDA, 0x80, 0x2C, 0x9F, 0xAC, 0x41));
		my $in = pack('a32', $args->{password});
		my $rijndael = Utils::Rijndael->new;
		$rijndael->MakeKey($key, $chain, 32, 32);
		$args->{password_rijndael} = $rijndael->Encrypt($in, undef, 32, 0);
	}
}

1;