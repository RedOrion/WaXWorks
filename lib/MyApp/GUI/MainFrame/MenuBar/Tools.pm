use v5.14;

package MyApp::GUI::MainFrame::MenuBar::Tools {
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MENU);

    use MyApp::GUI::Dialog::LogViewer;
    use MyApp::GUI::Dialog::PodViewer;

    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Menu';
    with 'MyApp::Roles::Menu';

    has 'itm_logview'       => (is => 'rw', isa => 'Wx::MenuItem',  lazy_build => 1);
    has 'itm_podview'       => (is => 'rw', isa => 'Wx::MenuItem',  lazy_build => 1);
    has 'itm_testsound'     => (is => 'rw', isa => 'Wx::MenuItem',  lazy_build => 1);
    has 'itm_start_throb'   => (is => 'rw', isa => 'Wx::MenuItem',  lazy_build => 1);
    has 'itm_end_throb'     => (is => 'rw', isa => 'Wx::MenuItem',  lazy_build => 1);



    sub FOREIGNBUILDARGS {#{{{
        return;
    }#}}}
    sub BUILD {
        my $self = shift;

        $self->Append( $self->itm_logview       );
        $self->Append( $self->itm_podview       );
        #$self->Append( $self->itm_testsound     );
        #$self->Append( $self->itm_start_throb   );
        #$self->Append( $self->itm_end_throb     );

        $self->_set_events;
        return $self;
    }

    sub _build_itm_logview {#{{{
        my $self = shift;
        my $lv = Wx::MenuItem->new(
            $self, -1,
            '&Log Viewer',
            "Open the Log Viewer",
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
        return $lv;
    }#}}}
    sub _build_itm_podview {#{{{
        my $self = shift;
        return Wx::MenuItem->new(
            $self, -1,
            '&Pod Viewer',
            'Pod Viewer',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _build_itm_start_throb {#{{{
        my $self = shift;
        return Wx::MenuItem->new(
            $self, -1,
            '&Start Throbber',
            'Start Throbber',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _build_itm_end_throb {#{{{
        my $self = shift;
        return Wx::MenuItem->new(
            $self, -1,
            '&End Throbber',
            'End Throbber',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _build_itm_testsound {#{{{
        my $self = shift;

        ### Works on Windows, but not Ubuntu.  At least not with my setup; 
        ### could be a re-install will fix.

        return Wx::MenuItem->new(
            $self, -1,
            '&Test Sound',
            'Test Sound',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_MENU( wxTheApp->GetTopWindow,  $self->itm_logview,      sub{$self->OnLogViewer(@_)} );
        EVT_MENU( wxTheApp->GetTopWindow,  $self->itm_podview,      sub{$self->OnPodViewer(@_)} );
        EVT_MENU( wxTheApp->GetTopWindow,  $self->itm_testsound,    sub{$self->OnTestSound(@_)} );
        EVT_MENU( wxTheApp->GetTopWindow,  $self->itm_start_throb,  sub{$self->OnStartThrob(@_)} );
        EVT_MENU( wxTheApp->GetTopWindow,  $self->itm_end_throb,    sub{$self->OnEndThrob(@_)} );
        return 1;
    }#}}}

    sub OnLogViewer {#{{{
        my $self = shift;

        ### Determine starting point of LogViewer window
        my $frame_pos   = wxTheApp->GetTopWindow->GetPosition();
        my $dialog_pos  = Wx::Point->new( $frame_pos->x + 30, $frame_pos->y + 30 );
        my $log_viewer  = MyApp::GUI::Dialog::LogViewer->new( position => $dialog_pos );
        return 1;
    }#}}}
    sub OnPodViewer {#{{{
        my $self = shift;

        ### Determine starting point of PodViewer window
        my $frame_pos   = wxTheApp->GetTopWindow->GetPosition();
        my $dialog_pos  = Wx::Point->new( $frame_pos->x + 30, $frame_pos->y + 30 );
        my $pod_viewer  = MyApp::GUI::Dialog::PodViewer->new(
                                position => $dialog_pos,
                                size => Wx::Size->new(700, 600),
                            );
        return 1;
    }#}}}
    sub OnTestSound {#{{{
        my $self = shift;

        my $file = wxTheApp->get_wav( 'two_tones_up.wav' );
        my $sound = Wx::Sound->new($file);
        unless( $sound->IsOk ) {
            wxTheApp->poperr("Sound is not OK");
            return;
        }
        $sound->Play();

        return 1;
    }#}}}
    sub OnStartThrob {#{{{
        my $self = shift;
        wxTheApp->throb_start();
        return 1;
    }#}}}
    sub OnEndThrob {#{{{
        my $self = shift;
        wxTheApp->throb_end();
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=head1 NAME

MyApp::GUI::MainFrame::MenuBar::Tools - Tools menu

=head1 SYNOPSIS

Assuming C<$self> is a Wx::MenuBar:

 $tools_menu = MyApp::GUI::MainFrame::MenuBar::Tools->new();
 $self->Append( $tools_menu, "&Tools" );

=head1 COMPONENTS

=over 4

=item * Log Viewer

Opens a L<MyApp::GUI::Dialog::LogViewer> dialog.

=item * Pod Viewer

Opens a L<MyApp::GUI::Dialog::PodViewer> frame.

=item * Test Sound

Plays a short test sound.  Works on Windows, not on (my, at least) Ubuntu.

=item * Start Throbber

Starts the throbber gauge in the status bar.  Does nothing if it's already 
been started.

=item * End Throbber

Stops the throbber gauge in the status bar.  Does nothing if the throbber is 
not currently throbbing.  Throb.

=back

