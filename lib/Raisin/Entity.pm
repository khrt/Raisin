package Raisin::Entity;

use strict;
use warnings;

use parent 'Exporter';

use Carp;
use DDP;
use feature 'say';

our @EXPORT = qw(present);

sub import {
    my $class = shift;
    $class->export_to_level(1, @_);
}

my %STORAGE;

sub present {
    my ($name, $data, %params) = @_;

    my $proc_data;

    if ($params{with}) {
        my $entity = $params{with};
        $proc_data = $entity->compile($data);
    }
    else {
        # DBIx::Class
        if (ref($data) eq 'DBIx::Class::ResultSet') {
            while (my $i = $data->next) {
                push @$proc_data, _present_dbix($i);
            }
        }
        else {
            $proc_data = $data;
        }
    }

    $STORAGE{$name} = $proc_data;

    \%STORAGE;
}

sub _present_dbix {
    my $rc = shift;
    my %data = map { $_ => $rc->$_ } keys %{ $rc->columns_info };
    \%data;
}

###

sub compile {
    my ($class, $data) = @_;

    say "with: $class --";
#    p @class::EXPOSE;
#    p @class::KEYS;

    my $proc;

    if (ref($data) eq 'DBIx::Class::ResultSet') {
        while (my $i = $data->next) {

            my %d = map {
                my $key = $_->{alias} || $_->{name};
                my $column = $_->{name};

                my $value = do {
                    if (my $r = $_->{runtime}) {
                        $r->($i);
                    }
                    else {
                        $i->$column;
                    }
                };

                if (my $c = $_->{condition}) {
                    $c->($i) ? ($key => $value) : ();
                }
                else {
                    ($key => $value);
                }
            } @class::EXPOSE;

            push @$proc, \%d;
        }
    }
    else {

    }

    $proc;
}

sub expose {
    my ($class, $name, @params) = @_;

    # expose 'user_name'
    #? expose 'text', documentation { ... }
    # expose 'ip', if { ... }
    #? expose 'contact_info', sub {
    #?   expose :phone
    #?   expose :address, using Entity::Address
    #? }
    # expose :digest, sub {
    #   my $item = shift;
    #   hexhash($item->name);
    # }
    # expose 'user_name', as 'name';

    #say "*** $name";
    push(@class::KEYS, $name);

    my $runtime;

    if (scalar(@params) % 2) {
        $runtime = ref($params[-1]) eq 'CODE' ? delete($params[-1]) : undef;
    }

    my %params = @params;

    #push(@class::EXPOSE, $name);
    push @class::EXPOSE, {
        name => $name,
        alias => $params{as},
        documentation => $params{documentation},
        runtime => $runtime,
        condition => $params{if},
    };

    #p $class::EXPOSE[-1];
    #say '~~~';
}

sub documentation {
    my $doc = shift;
}

sub if {
    my $sub = shift;
}

1;

__END__

=head1 NAME

Raisin::Entity - simple Facade to use with your API

=head1 DESCRIPTION

=head1 KEYWORDS

=head2 expose

=cut
