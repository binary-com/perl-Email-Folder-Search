use strict;
use warnings;

use Test::More;
use Test::Exception;
use Mail::Sender;
use Try::Tiny;
use FindBin qw($Bin);
use File::Copy qw(copy);

BEGIN {
    use_ok('Email::Folder::Search');
}

my $folder_path = '/tmp/default.mailbox';

my $mailbox = Email::Folder::Search->new($folder_path, timeout => 0);
ok(open(my $fh, ">", $folder_path), "mailbox created");
close($fh);
my $address = 'test@test.com';
my $subject = "test mail sender";
my $body    = "hello, this is just for test";

send_email();
#test arguments
throws_ok { $mailbox->search() } qr/Need email address and subject regexp/, 'test arguments';
throws_ok { $mailbox->search(email => $address) } qr/Need email address and subject regexp/, 'test arguments';
throws_ok { $mailbox->search(email => $address, subject => $subject) } qr/Need email address and subject regexp/, 'test arguments';
throws_ok { $mailbox->search(subject => qr/$subject/) } qr/Need email address and subject regexp/, 'test arguments';
my @msgs;
lives_ok { @msgs = $mailbox->search(email => 'nosuch@email.com', subject => qr/hello/) } 'get email';
ok { !@msgs, "get a blank message" };

lives_ok { @msgs = $mailbox->search(email => $address, subject => qr/$subject/) } 'get email';
like($msgs[0]{body}, qr/$body/, 'get correct email');
$mailbox->clear();
ok(-z $folder_path, "mailbox truncated");

{
    $mailbox->{timeout} = 3;
    local $SIG{ALRM} = sub { send_email(); send_email(); };
    alarm(2);
    lives_ok { @msgs = $mailbox->search(email => $address, subject => qr/$subject/) } 'will wait "timeout" secouds for new email';
    is(scalar(@msgs), 2, "got 2 mails");
}

done_testing;

sub send_email {
    #send email
    try {
        Mail::Sender->new({
                smtp      => 'localhost',
                from      => "travis",
                to        => $address,
                ctype     => 'text/html',
                charset   => 'UTF-8',
                encoding  => "quoted-printable",
                on_errors => 'die',
            }
            )->Open({
                subject => $subject,
            })->SendEnc($body)->Close();
    }
    catch {
        open(my $fh1, ">>", $folder_path)        || die "Cannot open file $folder_path";
        open(my $fh2, "<",  "$Bin/test.mailbox") || die "Cannot open file $Bin/test.mailbox";
        while (<$fh2>) {
            print $fh1 $_;
        }
        close($fh1);
        close($fh2);
    };

}
