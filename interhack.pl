#!/usr/bin/perl
package Interhack;
use IO::Socket::INET;
use Term::ReadKey;

# connect to server {{{
my $socket = new IO::Socket::INET(PeerAddr => 'sporkhack.nineball.org',
                                  PeerPort => 23,
                                  Proto => 'tcp');
die "Could not create socket: $!\n" unless $socket;
$socket->blocking(0);

my $IAC = chr(255);
my $SB = chr(250);
my $SE = chr(240);
my $WILL = chr(251);
my $WONT = chr(252);
my $DO = chr(253);
my $DONT = chr(254);
my $TTYPE = chr(24);
my $TSPEED = chr(32);
my $XDISPLOC = chr(35);
my $NEWENVIRON = chr(39);
my $IS = chr(0);
my $GOAHEAD = chr(3);
my $ECHO = chr(1);
my $NAWS = chr(31);
my $STATUS = chr(5);
my $LFLOW = chr(33);

print {$socket} "$IAC$WILL$TTYPE"
               ."$IAC$SB$TTYPE${IS}xterm-color$IAC$SE"
               ."$IAC$WONT$TSPEED"
               ."$IAC$WONT$XDISPLOC"
               ."$IAC$WONT$NEWENVIRON"
               ."$IAC$DONT$GOAHEAD"
               ."$IAC$WILL$ECHO"
               ."$IAC$DO$STATUS"
               ."$IAC$WILL$LFLOW"
               ."$IAC$WILL$NAWS"
               ."$IAC$SB$NAWS$IS".chr(80).$IS.chr(24)."$IAC$SE";
# }}}
# set up character-based input mode {{{
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

        # cut it and release
        last ITER;
    }

    return $from_nao;
} # }}}

while (1)
{
    if (defined(my $input = read_keyboard()))
    {
        $input = "E-  Elbereth\n" if $input eq "\ce";
        print $socket $input;
    }

    if (defined(my $output = read_socket()))
    {
        $output =~ s/cat/dog/g;
        print $output;
    }
}

