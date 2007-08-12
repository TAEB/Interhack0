#!/usr/bin/perl
use IO::Socket::INET;
use Term::ReadKey;

# connect to server {{{
my $socket = new IO::Socket::INET(PeerAddr => 'nethack.alt.org',
                                  PeerPort => 23,
                                  Proto => 'tcp');
die "Could not create socket: $!\n" unless $socket;
$socket->blocking(0);

# telnet negotiation...
print {$socket} "\xFF\xFB\x18\xFF\xFA\x18\x0xterm-color\xFF\xF0\xFF\xFC\x20\xFF\xFC\x23\xFF\xFC\x27\xFF\xFE\x3\xFF\xFB\x1\xFF\xFD\x5\xFF\xFB\x21\xFF\xFB\x1F\xFF\xFA\x1F\x0\x50\x0\x18\xFF\xF0";
# }}}
# set up character-based input mode, autoflush {{{
ReadMode 3;
END { ReadMode 0 }
$| = 1;
# }}}

sub read_socket # {{{
{
    # the reason this is so complicated is because packets can be broken up
    # we can't detect this perfectly, but it's only an issue if an escape code
    # is broken into two parts, and we can check for that
    my $from_nao;

    ITER: for (1..100)
    {
        # would block
        next ITER
            unless defined(recv($socket, $_, 4096, 0));

        # 0 = error
        if (length == 0)
        {
            ReadMode 0;
            exit;
        }

        # need to store what we read
        $from_nao .= $_;

        # check for broken escape code or DEC string
        if (/ \e \[? [0-9;]* \z /x || m/ \x0e [^\x0f]* \z /x)
        {
            next ITER;
        }

        return $from_nao;
    }
} # }}}

while (1)
{
    if (defined(my $input = ReadKey 0.05))
    {
        $input = "E-  Elbereth\n" if $input eq "\ce"; # ^E writes Elbereth
        print $socket $input;
    }

    if (defined(my $output = read_socket()))
    {
        $output =~ s/Elbereth/\e[35mElbereth\e[m/g; # color E purple
        print $output;
    }
}

