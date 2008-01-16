#!/usr/bin/env perl
use IO::Socket::Telnet;
use Term::ReadKey;
use Errno 'EAGAIN';

# connect to server {{{
my $socket = new IO::Socket::Telnet(PeerAddr => 'nethack.alt.org',
                                    PeerPort => 23,
                                    Proto => 'tcp');
die "Could not create socket: $!\n" unless $socket;
$socket->blocking(0);

# telnet negotiation...
print {$socket} "\xFF\xFB\x18\xFF\xFA\x18\x0xterm-color\xFF\xF0\xFF\xFC\x20\xFF\xFC\x23\xFF\xFC\x27\xFF\xFE\x03\xFF\xFB\x01\xFF\xFD\x05\xFF\xFB\x21\xFF\xFB\x1F\xFF\xFA\x1F\x00\x50\x00\x18\xFF\xF0";
# }}}
# set up character-based input mode, autoflush {{{
ReadMode 3;
END { ReadMode 0 }
$| = 1;
# }}}

sub read_keyboard # {{{
{
    ReadKey 0.05;
} # }}}
sub read_socket # {{{
{
    # the reason this is so complicated is because packets can be broken up
    # we can't detect this perfectly, but it's only an issue if an escape code
    # is broken into two parts, and we can check for that
    my $from_server;

    ITER: for (1..100)
    {
        defined $socket->recv($_, 4096, 0) or do
        {
            next ITER if $! == EAGAIN; # would block
            die $!;
        };

        # need to store what we read
        $from_server .= $_;

        # check for broken escape code or DEC string
        if (/ \e \[? [0-9;]* \z /x || m/ \x0e [^\x0f]* \z /x)
        {
            next ITER;
        }

        return $from_server;
    }
} # }}}
sub toserver # {{{
{
    my $text = shift;
    print {$socket} $text;
} # }}}
sub toscreen # {{{
{
    my $text = shift;
    print $text;
} # }}}

# main loop {{{
while (1)
{
    if (defined(my $input = read_keyboard()))
    {
        $input = "E-  Elbereth\n" if $input eq "\ce"; # ^E writes Elbereth
        toserver $input;
    }

    if (defined(my $output = read_socket()))
    {
        $output =~ s/Elbereth/\e[35mElbereth\e[m/g; # color E purple
        toscreen $output;
    }
} # }}}

