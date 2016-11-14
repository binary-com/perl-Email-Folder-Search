package Email::Folder::Search;

# ABSTRACT: wait and fetch search from mailbox file

=head1 NAME

Email::Folder::Search

=head1 DESCRIPTION

Search email from mailbox file. This module is mainly to test that the emails are received or not.

=head1 SYNOPSIS

    use Email::Folder::Search qw(get_email_by_address_subject clear_mailbox);
    $Email::Folder::Search::mailbox = '/var/spool/mbox';
    my %msg = get_email_by_address_subject(email => 'hello@test.com', subject => qr/this is a subject/);
    clear_mailbox();

=cut

=head1 Functions

=cut

use strict;
use warnings;
use Email::Folder;
use Encode qw(decode);

use base qw(Exporter);

our @EXPORT_OK = qw(get_email_by_address_subject clear_mailbox);

our $VERSION = '0.01';

=head2 $mailbox

The path of mailbox file.

=cut

=head2 $timeout

The seconds that get_email_by_address_subject will wait if the email cannot be found.

=cut

# mailbox is set in the chef postfix part and travis-script/setup-postfix
our $mailbox = $ENV{MAILBOX_PATH} || "/tmp/default.mailbox";
our $timeout = 3;

=head2 get_email_by_address_subject

get email by address and subject(regexp)

=cut

sub get_email_by_address_subject {
    my %cond = @_;

    die 'Need email address and subject regexp' unless $cond{email} && $cond{subject} && ref($cond{subject}) eq 'Regexp';

    my $email          = $cond{email};
    my $subject_regexp = $cond{subject};

    my %msg;
    #mailbox maybe late, so we wait 3 seconds
    WAIT: for (0 .. $timeout) {
        my $folder = Email::Folder->new($mailbox);

        MSG: while (my $tmsg = $folder->next_message) {
            my $address = $tmsg->header('To');
            #my $address = $to[0]->address();
            my $subject = $tmsg->header('Subject');
            if ($subject =~ /=\?UTF\-8/) {
                $subject = decode('MIME-Header', $subject);
            }

            if ($address eq $email && $subject =~ $subject_regexp) {
                $msg{body}    = $tmsg->body;
                $msg{address} = $address;
                $msg{subject} = $subject;
                last WAIT;
            }
        }
        sleep 1;
    }
    return %msg;
}

sub import {
    my @exported = @_;
    #to be sure there is the mailbox file so that I needn't check it again in the loop
    open(my $fh, '>>', $mailbox) || die "cannot create mailbox";
    close($fh);
    __PACKAGE__->export_to_level(1, @exported);
    return;
}

=head2 clear_mailbox

=cut

sub clear_mailbox {
    truncate $mailbox, 0;
    return;
}

1;

