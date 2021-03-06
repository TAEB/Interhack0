#!/usr/bin/env perl
use strict;
use IO::Socket::Telnet;
use Term::ReadKey;
use Errno 'EAGAIN';

# connect to server
my $server = shift || 'nethack.alt.org';
my $socket = IO::Socket::Telnet->new(
    PeerAddr => $server,
    Proto    => 'tcp',
);
die "Could not create socket: $!\n" unless $socket;
$socket->blocking(0);

# telnet negotiation...
to_server("\xFF\xFB\x18\xFF\xFA\x18\x00xterm-color\xFF\xF0\xFF\xFC\x20\xFF\xFC\x23\xFF\xFC\x27\xFF\xFE\x03\xFF\xFB\x01\xFF\xFD\x05\xFF\xFB\x21\xFF\xFB\x1F\xFF\xFA\x1F\x00\x50\x00\x18\xFF\xF0");

# set up character-based input mode
ReadMode 3;
END { ReadMode 0 }

# autoflush output
$| = 1;

sub read_keyboard {
    ReadKey 0.05;
}

sub read_socket {
    # the reason this is so complicated is because packets can be broken up
    # we can't detect this perfectly, but it's only an issue if an escape code
    # is broken into two parts, and we can check for that
    my $from_server;

    ITER: for (1..100) {
        defined $socket->recv($_, 4096, 0) or do {
            next ITER if $! == EAGAIN; # would block
            die $!; # some other error
        };

        # need to store what we read
        $from_server .= $_;

        # if we got a broken escape code or DEC string, try again
        if (/ \e \[? [0-9;]* \z /x || m/ \x0e [^\x0f]* \z /x) {
            next ITER;
        }

        return $from_server;
    }
}

sub to_server {
    my $text = shift;
    print {$socket} $text;
}

sub to_screen {
    my $text = shift;
    print $text;
}


# main loop
while (1) {
    if (defined(my $input = read_keyboard)) {
        $input = "E-  Elbereth\n" if $input eq "\ce"; # ^E writes Elbereth
        to_server($input);
    }

    if (defined(my $output = read_socket)) {
        $output =~ s/Elbereth/\e[35mElbereth\e[m/g; # color E purple
        to_screen($output);
    }
}

