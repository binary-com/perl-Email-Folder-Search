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
throws_ok { $mailbox->get_email_by_address_subject() } qr/Need email address and subject regexp/, 'test arguments';
throws_ok { $mailbox->get_email_by_address_subject(email => $address) } qr/Need email address and subject regexp/, 'test arguments';
throws_ok { $mailbox->get_email_by_address_subject(email => $address, subject => $subject) } qr/Need email address and subject regexp/,
    'test arguments';
throws_ok { $mailbox->get_email_by_address_subject(subject => qr/$subject/) } qr/Need email address and subject regexp/, 'test arguments';
my %msg;
lives_ok { %msg = $mailbox->get_email_by_address_subject(email => 'nosuch@email.com', subject => qr/hello/) } 'get email';
ok { !%msg, "get a blank message" };

lives_ok { %msg = $mailbox->get_email_by_address_subject(email => $address, subject => qr/$subject/) } 'get email';
like($msg{body}, qr/$body/, 'get correct email');
$mailbox->clear();
ok(-z $folder_path, "mailbox truncated");

{
    $mailbox->{timeout} = 3;
    local $SIG{ALRM} = sub { send_email() };
    alarm(2);
    lives_ok { $mailbox->get_email_by_address_subject(email => 'nosuch@email.com', subject => qr/hello/) }
    'will wait "timeout" secouds for new email';
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
        copy "$Bin/test.mailbox", $folder_path;
    };

}
