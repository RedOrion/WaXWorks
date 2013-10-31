use v5.14;

package MyApp::GUI::MainFrame {
    use Data::Dumper::GUI;
    use English qw( -no_match_vars );
    use IO::All;
    use Moose;
    use Wx qw( :everything );
    use Wx::Event qw(EVT_CLOSE EVT_SIZE);
    
    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Frame';
    with 'MyApp::Roles::Platform';

    use MyApp::GUI::MainFrame::MenuBar;
    use MyApp::GUI::MainFrame::StatusBar;

    has 'border_size' => (
        is      => 'ro', 
        isa     => 'Int',
        default => 10,
        documentation => q{
            The amount of space used to separate components from the edges of the 
            dialog.
            This isn't "automatic" - any windows that touch the edge of the frame 
            need to set a border of this size between themselves and the frame 
            edge.
        }
    );
    has 'initial_centered' => (
        is          => 'ro',
        isa         => 'Bool',
        default     => 1,
    );
    has 'initial_height' => (
        is          => 'ro',
        isa         => 'Int',
        default     => 600,
    );
    has 'initial_width' => (
        is          => 'ro',
        isa         => 'Int',
        default     => 800,
    );
    has 'menu_bar' => (
        is          => 'rw',
        isa         => 'MyApp::GUI::MainFrame::MenuBar',
        lazy_build  => 1,
    );
    has 'status_bar' => (
        is          => 'rw',
        isa         => 'MyApp::GUI::MainFrame::StatusBar',
        lazy_build  => 1,
    );
    #############
    has 'szr_main' => (
        is          => 'rw',
        isa         => 'Wx::Sizer',
        lazy_build  => 1,
    );

    sub FOREIGNBUILDARGS {#{{{
        my $self = shift;
        my %args = @_;

        return(
            undef,
            -1,
            wxTheApp->GetAppName(),     # Window title
            wxDefaultPosition,
            wxDefaultSize,
            wxDEFAULT_FRAME_STYLE,
            "MainFrame",                # Window name
        );
    }#}}}
    sub BUILD {
        my $self = shift;

        $self->Show(0);
        $self->SetSize( Wx::Size->new($self->initial_width, $self->initial_height) );
        $self->Centre( wxBOTH ) if $self->initial_centered;

        ### The SplashScreen, if used, automatically starts as the TopWindow 
        ### since it's the first window created.
        ###
        ### MyApp.pm is setting this MainFrame as the top window, but it can't 
        ### do so until this constructor completes and returns the MainFrame 
        ### object.
        ###
        ### However, while building the MainFrame object, we're building the  
        ### menubar (as part of this MainFrame).  That menubar wants to 
        ### display a Dialog (Edit... Preferences, and likely any other 
        ### Dialogs it may end up wanting to open) whose position is relative 
        ### to the TopWindow (which is currently still set as the 
        ### SplashScreen).
        ###
        ### So set ourselves as the TopWindow now to keep from confusing the 
        ### MenuBar.
        wxTheApp->SetTopWindow($self);

        ### Add the textual menu bar to the top
        $self->SetMenuBar( $self->menu_bar );

        ### Add frame content elements
        # $self->szr_main->Add($self->txt_test, 1, wxEXPAND, 0);

        ### Create the status bar, and set the second pane to be the one that 
        ### receives helpstring text generated by menu selections.  -1 turns 
        ### off helpstring display altogether.
        $self->SetStatusBar( $self->status_bar );
        $self->SetStatusBarPane(1);

        $self->SetSizer($self->szr_main);
        $self->_set_events;
        $self->Show(1);
        return $self;
    }

    sub _build_menu_bar {#{{{
        my $self = shift;
        my $mb = MyApp::GUI::MainFrame::MenuBar->new( parent => $self );
        return $mb;
    }#}}}
    sub _build_status_bar {#{{{
        my $self = shift;
        my $sb = MyApp::GUI::MainFrame::StatusBar->new( frame => $self, caption => wxTheApp->GetAppName );
        return $sb;
    }#}}}
    sub _build_szr_main {#{{{
        my $self = shift;

        return $self->build_sizer($self, wxVERTICAL, 'Main');
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_CLOSE(      $self,  sub{$self->OnClose(@_)}     );
        EVT_SIZE(       $self,  sub{$self->OnResize(@_)}    );
    }#}}}

    sub OnClose {#{{{
        my $self    = shift;
        my $frame   = shift;    # same as $self
        my $event   = shift;    # Wx::CloseEvent

        $event->Skip;
    }#}}}
    sub OnResize {#{{{
        my $self    = shift;
        my $frame   = shift;
        my $event   = shift;

        $self->status_bar->init();
        $self->szr_main->SetMinSize( $self->GetClientSize->width, -1 ); 
        $self->Layout;

        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=head1 NAME

MyApp::GUI::MainFrame - Main frame of MyApp application

=head1 SYNOPSIS

 $frame = MyApp::GUI::MainFrame->new();
 wxTheApp->SetTopWindow( $frame );

=head1 DESCRIPTION

The main frame of your application.  By default, this main frame displays a 
Notepad-like text editor, but that exists mainly for example purposes.  You're 
encouraged to rip the editor-y bits out altogether and replace them with 
something useful.

=head1 COMPONENTS

=head2 L<MyApp::GUI::MainFrame::MenuBar>

=head2 L<MyApp::GUI::MainFrame::StatusBar>

=head1 METHODS

=head2 Contstructor - new

=over 4

=item * ARGS

Arguments are passed to the constructor as a hash.

=over 8

=item * optional boolean - C<initial_centered>

Whether the frame should be created in the center of the display.  Defaults to true.

=item * optional integer - C<initial_height>

Starting height of the frame, in pixels.  Defaults to 800.

=item * optional integer - C<initial_width>

Starting width of the frame, in pixels.  Defaults to 600.

=back

=item * RETURNS

=over 8

=item * C<MyApp::GUI::MainFrame> object

=back

=back

