use v5.14;

package MyApp::Model::SearchIndex::Help {
    use File::Slurp;
    use HTML::Strip;
    use HTML::TreeBuilder::XPath;
    use Moose;
    use MyApp::Model::Container;
    use Path::Class;
    use Try::Tiny;
    extends 'MyApp::Model::SearchIndex';

    has 'bb'  => (
        is          => 'ro',
        isa         => 'MyApp::Model::Container',  
        lazy        => 1,
        default     => sub{ MyApp::Model::Container->new(name => 'update help') },
        handles => {
            resolve => 'resolve',
        }
    );
    has 'html_dir'  => (
        is          => 'ro',
        isa         => 'Path::Class::Dir',  
        lazy        => 1,
        default     => sub{ Path::Class::dir( $_[0]->resolve(service => '/Directory/doc/html') ) },
    );
    has 'kandi'  => (
        is          => 'ro',
        isa         => 'HTML::Strip',  
        lazy        => 1,
        default     => sub{ HTML::Strip->new() },
    );
    has 'summary_length' => (
        is          => 'rw',
        isa         => 'Int', 
        default     => 120
    );
    has 'xpath' => (
        is          => 'ro',
        isa         => 'HTML::TreeBuilder::XPath',
        lazy_build  => 1,
        handles     => {
            findnodes   => 'findnodes',
        }
    );

    around 'BUILDARGS' => sub {#{{{
        my $orig    = shift;
        my $class   = shift;

        ### There's a minor chicken-and-egg issue here.
        ###
        ### This module specifically relates to app help documentation, so it 
        ### shouldn't have to be passed the location of that docu, especially 
        ### since it's being defined elsewhere (our main Bread::Board 
        ### container).
        ###
        ### However, since this is a model, we can't get at that container via 
        ### wxTheApp, and since we're currently in BUILDARGS, we also can't 
        ### yet get at the container that will eventually become one of our 
        ### own attributes.
        ###
        ### So we're solving that by instantiating our own Bread::Board here 
        ### so we can dig the location of the index out of it.

        my $bb = MyApp::Model::Container->new(name => 'update help');
        return {
            index_directory => $bb->resolve(service => '/Directory/doc/html_idx')
        }
    };#}}}
    sub BUILD {
        my $self = shift;
        $self->add_field('filename');
        $self->add_field('summary');
        return $self;
    }

    sub _build_xpath {#{{{
        my $self = shift;
        return HTML::TreeBuilder::XPath->new();
    }#}}}

    sub clean_text {#{{{
        my $self = shift;
        my $text = shift;
        $text = " $text";
        $text =~ s/[\r\n]/ /g;
        $text =~ s/\s{2,}/ /g;
        $text =~ s/\s+$//;
        return $text;
    }#}}}
    sub get_doc_summary {#{{{
        my $self  = shift;

        my @nodeset = $self->findnodes('/html/body/*');
        my $summary  = q{};
        NODE:
        for my $n(@nodeset) {
            next if $n->getName =~ /^h/i;   # skip headers
            $summary .= $self->clean_text($n->getValue);
            last NODE if length $summary > $self->summary_length;
        }
        $summary = substr $summary, 0, $self->summary_length;
        return $summary;
    }#}}}
    sub get_doc_title {#{{{
        my $self = shift;
        my $title = $self->xpath->findvalue("/html/body/h1")  || 'No Title';
        return $title;
    }#}}}
    sub reset {#{{{
        my $self = shift;
        ### The tree must be deleted (to avoid memory leaks) and then 
        ### destroyed between parses.
        $self->xpath->delete;
        $self->clear_xpath;
    }#}}}
    sub slurp {#{{{
        my $self     = shift;
        my $filename = shift;
        return File::Slurp::slurp( $filename );
    }#}}}
    sub strip {#{{{
        my $self    = shift;
        my $content = shift;
        my $stripped = $self->kandi->parse($content);
        $self->kandi->eof;
        return $stripped;
    }#}}}
    sub xparse {#{{{
        my $self    = shift;
        my $content = shift;

        ### The help "html" files are really just templates; the wrapper is 
        ### handling the opening and closing tags.  But the missing tags are 
        ### going to give XPath fits, so fake some up.
        $content = "<html><body>$content</body></html>";
        $self->xpath->parse($content);
        $self->xpath->eof();
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;

__END__

=head1 NAME

MyApp::Model::SearchIndex::Help - A SearchIndex with HTML parsing helpers, for 
local application help documents.

=head1 SYNOPSIS

 $help = MyApp::Model::SearchIndex::Help->new();

 ### The HTML help file to parse
 $file = "filename.html";

 $html_content = $help->slurp( $file );
 $help->xparse($html_content);

 $title       = $help->get_doc_title()              || 'No Title';
 $summary     = $help->get_doc_summary()            || 'No Summary';
 $raw_content = $help->strip($html_content);
 $help->reset;

Add the document to the existing index...

 $help->add_docs([
  filename    => $file,
  title       => $title,
  summary     => $summary,
  content     => $raw_content,
 ]);

...or completely overwrite the existing index

 $help->replace_docs([
  filename    => $file,
  title       => $title,
  summary     => $summary,
  content     => $raw_content,
 ]);

=head1 DESCRIPTION

MyApp::Model::SearchableIndex::Help extends L<MyApp::Model::SearchableIndex> 
with the awareness of dealing specifically with the HTML help documents used 
in this app.

=head1 SCHEMA

MyApp::Model::SearchableIndex::Help creates the following fields in the 
index's schema:

=over 4

=item * filename

=item * title

=item * summary

=item * content

=back

=head1 METHODS

These are in addition to what's provided by L<MyApp::Model::SearchableIndex>.

=head2 CONSTRUCTOR - new

=over 4

=item * ARGS

=over 8

=item * none

=back

=item * RETURNS

=over 8

=item * MyApp::Model::SearchableIndex::Help object

=back

=back

=head2 get_doc_title

=over 4

=item * ARGS

=over 8

=item * none

=back

=item * RETURNS

=over 8

=item * scalar - Contents of the document's E<lt>H1E<gt> tag; undef if no such 
tag is found.

=back

=back

Requires that L</xparse> be called first.

=head2 get_doc_summary

=over 4

=item * ARGS

=over 8

=item * none

=back

=item * RETURNS

=over 8

=item * scalar - The first N characters of the document, skipping the contents 
of any header tags.  N is defined by the summary_length attribute, which 
defaults to 120.

=back

=back

Requires that L</xparse> be called first.

=head2 reset

=over 4

=item * ARGS

=over 8

=item * none

=back

=item * RETURNS

=over 8

=item * nothing

=back

=back

Cleans up the state of helper parsers after finishing with a document, to  
prepare for parsing the next.

This I<must be called> after you're finished with each document.

=head2 slurp

=over 4

=item * ARGS

=over 8

=item * scalar - Name of the file to be slurped

=back

=item * RETURNS

=over 8

=item * scalar - Contents of the file

=back

=back

=head2 strip

=over 4

=item * ARGS

=over 8

=item * scalar - HTML content (NOT a filename) to be stripped

=back

=item * RETURNS

=over 8

=item * scalar - The content passed in with HTML tags removed

=back

=back

See also L</reset>.

=head2 xparse

=over 4

=item * ARGS

=over 8

=item * scalar - file to be parsed

=back

=item * RETURNS

=over 8

=item * nothing

=back

=back

Must be called before either L</get_doc_title> or L</get_doc_summary> to build 
the tree to be parsed.

See also L</reset>.
