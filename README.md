# NAME

[![Build Status](https://travis-ci.org/binary-com/perl-Email-Folder-Search.svg?branch=master)](https://travis-ci.org/binary-com/perl-Email-Folder-Search) 
[![codecov](https://codecov.io/gh/binary-com/perl-Email-Folder-Search/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-Email-Folder-Search)

Email::Folder::Search

# DESCRIPTION

Search email from mailbox file. This module is mainly to test that the emails are received or not.

# SYNOPSIS

    use Email::Folder::Search qw(get_email_by_address_subject clear_mailbox);
    my %msg = get_email_by_address_subject(email => 'hello@test.com', subject => qr/this is a subject/);
    clear_mailbox();

# Functions

## get\_email\_by\_address\_subject

get email by address and subject(regexp)

## clear\_mailbox
