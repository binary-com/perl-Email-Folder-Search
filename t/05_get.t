use strict;
use warnings;

use Test::More;
use Test::Exception;
use Mail::Sender;
use Try::Tiny;
use FindBin qw($Bin);
use File::Copy qw(copy);

#to insure the mailbox file not exist
BEGIN {
    $ENV{MAILBOX_PATH} = '/tmp/test.mailbox';
    use_ok('Email::Folder::Search', qw());
    is($Email::Folder::Search::mailbox, $ENV{MAILBOX_PATH}, "mailbox is set by env");
    unlink $Email::Folder::Search::mailbox;
    ok(!-e $Email::Folder::Search::mailbox, "mailbox not exist yet");
}

BEGIN {
    use_ok('Email::Folder::Search', qw(get_email_by_address_subject clear_mailbox));
}

my $mailbox = $Email::Folder::Search::mailbox;
ok(-e $mailbox, "mailbox created");
my $address = 'test@test.com';
my $subject = "test mail sender";
my $body    = "hello, this is just for test";

$Email::Folder::Search::timeout = 0;
send_email();
#test arguments
throws_ok { get_email_by_address_subject() } qr/Need email address and subject regexp/, 'test arguments';
throws_ok { get_email_by_address_subject(email => $address) } qr/Need email address and subject regexp/, 'test arguments';
throws_ok { get_email_by_address_subject(email => $address, subject => $subject) } qr/Need email address and subject regexp/, 'test arguments';
throws_ok { get_email_by_address_subject(subject => qr/$subject/) } qr/Need email address and subject regexp/, 'test arguments';
my %msg;
lives_ok { %msg = get_email_by_address_subject(email => 'nosuch@email.com', subject => qr/hello/) } 'get email';
ok { !%msg, "get a blank message" };

lives_ok { %msg = get_email_by_address_subject(email => $address, subject => qr/$subject/) } 'get email';
like($msg{body}, qr/$body/, 'get correct email');
clear_mailbox();
ok(-z $mailbox, "mailbox truncated");

{
    $Email::Folder::Search::timeout = 3;
    local $SIG{ALRM} = sub { send_email() };
    alarm(2);
    lives_ok { get_email_by_address_subject(email => 'nosuch@email.com', subject => qr/hello/) } 'will wait "timeout" secouds for new email';
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
        copy "$Bin/test.mailbox", $mailbox;
    };

}
