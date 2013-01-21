package HTML::TabbedExamples::Generate;

use strict;
use warnings;

our $VERSION = '0.0.1';

use MooX 'late';

use CGI ();
use Text::VimColor;

use Carp ();

has _default_syntax => (is => 'ro', isa => 'Str', init_arg => 'default_syntax');
has _main_pre_css_classes => (is => 'ro', isa => 'ArrayRef[Str]',
    default => sub {
        return [qw(code)];
    },
    init_arg => 'main_pre_css_classes',
);

sub _calc_post_code
{
    my $self = shift;
    my $ex_spec = shift;

    my $pre_code = $ex_spec->{code};

    if ($ex_spec->{no_syntax})
    {
        return "<pre>\n" . CGI::escapeHTML($pre_code) . "</pre>\n";
    }
    else
    {
        my $syntax = ($ex_spec->{syntax} || $self->_default_syntax);

        my $code = <<"EOF";
#!/usr/bin/perl

use strict;
use warnings;

$pre_code
EOF

        my $tvc = Text::VimColor->new(
            string => \$code,
            filetype => $syntax,
        );

        return
            qq|<pre class="|
                . join(' ', map { CGI::escapeHTML($_) }
                    @{$self->_main_pre_css_classes}, $syntax
                )
            . qq|">\n|
            . ($tvc->html() =~ s{(class=")syn}{$1}gr)
            . qq|\n</pre>\n|
            ;

    }
}

sub render
{
    my ($self, $args) = @_;

    my $examples = $args->{'examples'};
    my $id_base = $args->{'id_base'};

    my $ret_string = '';

    my @lis;
    my @codes;

    foreach my $ex_spec (@$examples)
    {
        my $id = $id_base . '__' . $ex_spec->{id};
        my $label = $ex_spec->{label};

        my $esc_id = CGI::escapeHTML($id);
        my $esc_label = CGI::escapeHTML($label);

        my $post_code = $self->_calc_post_code($ex_spec);

        push @lis, qq[<li><a href="#$esc_id">$esc_label</a></li>\n];
        push @codes, qq[<div id="$esc_id">$post_code</div>];
    }

    return
        qq{<div class="tabs">\n}
            . qq{<ul>\n}
                . join("\n", @lis)
            . qq{\n</ul>\n}
            . join("\n", @codes) .
        qq{</div>\n}
        ;
}

sub html_with_title
{
    my ($self, $args) = @_;

    my $id_base = $args->{'id_base'}
        or Carp::confess("id_base not specified.");
    my $title = $args->{'title'}
        or Carp::confess("title not specified.");

    return
        qq[<h3 id="] . CGI::escapeHTML($id_base)
        . qq[">] . CGI::escapeHTML($title) . qq[</h3>\n\n]
        . $self->render($args)
        ;
}

1;

=encoding utf-8

=head1 NAME

HTML::TabbedExamples::Generate - generate syntax-highlighted examples for
codes with a markup compatible with jQueryUI's tab widgets.

=head1 METHODS

=head2 my $obj = HTML::TabbedExamples::Generate->new({ default_syntax => "perl", main_pre_css_classes => [qw( code my_example1 )]})

Returns a new object with a default_syntax for the examples, and some classes
to add for the main pre tag. Default C<'main_pre_css_classes'> value is only
the class C<'code'>.

=head2 my $html_markup_string = $obj->render({ examples => \@examples, id_base => 'my_example_id'})

Renders some examples. C<'id_base'> is the prefix to prepend to the classes’
IDs. C<'examples'> points to an array-ref of examples, which are hash-refs
cotnaining:

=over 4

=item * label

The tab's label.

=item * no_syntax

If true, disable syntax highlighting.

=item * syntax

If true, override the default_syntax

=back

=head2 my $html_markup_string = $obj->html_with_title({ title => 'My title to escape', %ARGS })

Same arguments as render() with the addition of C<'title'> which is a title
to be placed inside an C<< <h3>..</h3> >> tag, which will be escaped.
Returns the complete markup.

=cut

