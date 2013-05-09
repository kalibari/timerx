#! /usr/bin/perl -W

use warnings;
use strict;
use POSIX;
use Gtk3 '-init';
use XML::Simple qw(:strict);
use Glib qw/TRUE FALSE/;

my $debug=0;

if ($ARGV[0]){
	if ("$ARGV[0]" =~"debug"){
		print "sub argv: debug mode\n";
		$debug=1;
	}
}


my $prognam="timerx";
my $version='0.33';
my $replace_config=0;
my $home=$ENV{"HOME"};

my $xml;
my $run_program;
my $time_spin_box_value;
my $event_value;

my $config_version;
my $directory_bin=getcwd;
my $directory_config="$home/.config/$prognam";
my $poweroff_cmd;
my $icon_file;
my $sound_file;

get_system_shutdown_cmd();
read_xml_file();

if ($debug==1){print "start $prognam\n";}
my @child_pids;

my $mainpid=getpid();
if ($debug==1){print "mainpid: $mainpid\n";}

my $localtime_in_seconds=0;
my $endtime_in_seconds=0;
my $duration_in_seconds=0;
my $entrytime_in_seconds=0;

my $fraction_loop1=0;
my $fraction_loop2=0;
my $fraction_steps=0;

my $enable_glib_timeout=0;

local $SIG{CHLD} ='IGNORE';
local $SIG{ALRM} = \&alarm_start;
local $SIG{USR1} = \&set_progress;
local $SIG{USR2} = \&event;

my $spacing8=8;

# Icon
my $pixbuf = Gtk3::Gdk::Pixbuf->new_from_file("$directory_bin/$icon_file");

# Window 1
my $window1 = Gtk3::Window->new('toplevel');
$window1->set_title($prognam);
$window1->set_position("center");
$window1->signal_connect(destroy => \&quit);
$window1->signal_connect(delete_event => \&quit);
$window1->set_border_width(10);
$window1->set_size_request(600, 100);
$window1->set_default_size(600, 200);
$window1->set_icon($pixbuf);


# Radio Box
my $sleep_box_pseudo = Gtk3::RadioButton->new_with_label_from_widget(undef, "0");
$sleep_box_pseudo->set_active(1);

my $sleep_box_15 = Gtk3::RadioButton->new_with_label_from_widget($sleep_box_pseudo, "15              ");
$sleep_box_15->signal_connect (toggled => \&rb_toggled, 15);

my $sleep_box_30 = Gtk3::RadioButton->new_with_label_from_widget($sleep_box_pseudo, "30              ");
$sleep_box_30->signal_connect (toggled => \&rb_toggled, 30);

my $sleep_box_45 = Gtk3::RadioButton->new_with_label_from_widget($sleep_box_pseudo, "45              ");
$sleep_box_45->signal_connect (toggled => \&rb_toggled, 45);

my $sleep_box_60 = Gtk3::RadioButton->new_with_label_from_widget($sleep_box_pseudo, "60              ");
$sleep_box_60->signal_connect (toggled => \&rb_toggled, 60);

my $sleep_box_75 = Gtk3::RadioButton->new_with_label_from_widget($sleep_box_pseudo, "75              ");
$sleep_box_75->signal_connect (toggled => \&rb_toggled, 75);

my $sleep_box_90 = Gtk3::RadioButton->new_with_label_from_widget($sleep_box_pseudo, "90              ");
$sleep_box_90->signal_connect (toggled => \&rb_toggled, 90);

my $sleep_box_105 = Gtk3::RadioButton->new_with_label_from_widget($sleep_box_pseudo, "105             ");
$sleep_box_105->signal_connect (toggled => \&rb_toggled, 105);

my $sleep_box_120 = Gtk3::RadioButton->new_with_label_from_widget($sleep_box_pseudo, "120             ");
$sleep_box_120->signal_connect (toggled => \&rb_toggled, 120);

my $sleep_box_135 = Gtk3::RadioButton->new_with_label_from_widget($sleep_box_pseudo, "135             ");
$sleep_box_135->signal_connect (toggled => \&rb_toggled, 135);

my $sleep_box_150 = Gtk3::RadioButton->new_with_label_from_widget($sleep_box_pseudo, "150             ");
$sleep_box_150->signal_connect (toggled => \&rb_toggled, 150);

my $sleep_box_165 = Gtk3::RadioButton->new_with_label_from_widget($sleep_box_pseudo, "165             ");
$sleep_box_165->signal_connect (toggled => \&rb_toggled, 165);

my $sleep_box_180 = Gtk3::RadioButton->new_with_label_from_widget($sleep_box_pseudo, "180             ");
$sleep_box_180->signal_connect (toggled => \&rb_toggled, 180);

# Grid 1
my $grid1 = Gtk3::Grid->new;
$grid1->attach($sleep_box_15, 0, 0, 1, 1);
$grid1->attach($sleep_box_30, 1, 0, 1, 1);
$grid1->attach($sleep_box_45, 2, 0, 1, 1);
$grid1->attach($sleep_box_60, 3, 0, 1, 1);

$grid1->attach($sleep_box_75,  0, 1, 1, 1);
$grid1->attach($sleep_box_90,  1, 1, 1, 1);
$grid1->attach($sleep_box_105, 2, 1, 1, 1);
$grid1->attach($sleep_box_120, 3, 1, 1, 1);

$grid1->attach($sleep_box_135, 0, 2, 1, 1);
$grid1->attach($sleep_box_150, 1, 2, 1, 1);
$grid1->attach($sleep_box_165, 2, 2, 1, 1);
$grid1->attach($sleep_box_180, 3, 2, 1, 1);

# Spin Box
# -> IBUS-WARNING **: Unable to connect to ibus
my $adjust = Gtk3::Adjustment->new(0, 0, 999, 1, 0, 0);
my $time_spin = Gtk3::SpinButton->new($adjust, 1, 1);
$time_spin->set_digits(0);
$time_spin->signal_connect(value_changed => \&time_spin_box);

# Horizontale Box 2
my $hbox2 = Gtk3::Box->new("horizontal", $spacing8);
$hbox2->pack_start($time_spin, 0,0,0);

# Vertical Box 5
my $vbox5 = Gtk3::Box->new("vertical", $spacing8);
$vbox5->pack_start($grid1, 0,0,0);
$vbox5->pack_start($hbox2, 0,0,0);

# Combobox
my $combobox1 = Gtk3::ComboBoxText->new("choose");
$combobox1->prepend_text("run_command");
$combobox1->prepend_text("shutdown");
$combobox1->prepend_text("alarm");
#$combobox1->get_active_text("test1");
#$combobox1->append_text("test2");
#$combobox1->insert_text (4, "test3");
#$combobox1->popdown(1);
$combobox1->popup(1);
if ($event_value=~"run_command"){$combobox1->set_active(2);}
elsif ($event_value=~"shutdown"){$combobox1->set_active(1);}
elsif ($event_value=~"alarm"){$combobox1->set_active(0);}
$combobox1->signal_connect(changed => \&cb_changed, "cb1");

# Entry Time
my $entry_time = Gtk3::Entry->new();
$entry_time->set_max_length(5);
$entry_time->set_text($time_spin_box_value);
$entry_time->signal_connect(changed => \&entry_time_changed, "etc1");

# Start Button
my $startbutton = Gtk3::Button->new("START");
$startbutton->signal_connect(clicked => \&start_button);

# Stop Button
my $stopbutton = Gtk3::Button->new("STOP");
$stopbutton->signal_connect(clicked => \&stop_button);
$stopbutton->set_sensitive(0);

# Entry command
my $entry_command = Gtk3::Entry->new();

# Horizontale Box 4
my $hbox4 = Gtk3::Box->new("horizontal", $spacing8);
$hbox4->pack_start($combobox1, 1,1,0);
$hbox4->pack_start($entry_time, 1,1,0);
$hbox4->pack_start($startbutton, 1,1,0);
$hbox4->pack_start($stopbutton, 1,1,0);

# Vertical Box 2
my $vbox2 = Gtk3::Box->new("vertical", $spacing8);
$vbox2->pack_start($hbox4, 0,0,0);
$vbox2->pack_start($entry_command, 0,0,0);


# Progress Bar 1
my $progress1 = Gtk3::ProgressBar->new;
$progress1->set_orientation("horizontal");
$progress1->set_inverted(0);
$progress1->set_fraction(0.0);

# Separator 1
my $sep1 = Gtk3::Separator->new("horizontal");

# Separator 1
my $sep2 = Gtk3::Separator->new("horizontal");

# Vertical Box 3
my $vbox3 = Gtk3::Box->new("vertical", $spacing8);
$vbox3->pack_start($sep1, 0,0,0);
$vbox3->pack_start($progress1, 0,0,0);
$vbox3->pack_start($sep2, 0,0,0);

# Frame 1
my $frame1 = new Gtk3::Frame("time in minutes:");
$frame1->add($vbox5);

# Frame 2
my $frame2 = new Gtk3::Frame("event:");
$frame2->add($vbox2);

# Frame 3
my $frame3 = new Gtk3::Frame("time to event:");
$frame3->add($vbox3);

# Vertikale Box 1
my $vbox1 = Gtk3::VBox->new( 0, 1 );
$vbox1->add($frame1);
$vbox1->add($frame2);
$vbox1->add($frame3);

$window1->add($vbox1);
$window1->show_all();

entry_time_changed();
set_gui_start();


Gtk3->main();


sub event {
	if ($debug==1){print "sub event start\n";}

	my $pid=getpid();
	if ($debug==1){print "sub event mainpid: $mainpid pid: $pid\n";}

	killall_childs();

	if ($debug==1){print "sub event todo: $event_value\n";}

	if ($event_value=~"alarm"){
		if ($debug==1){print "sub event sound_file: $directory_bin/$sound_file\n";}
		system("aplay --start-delay=400 $directory_bin/$sound_file &");
	}
	elsif ($event_value=~"shutdown"){
		if ($debug==1){print "sub event poweroff_cmd: $poweroff_cmd\n";}
		system("$poweroff_cmd &");
	}
	elsif ($event_value=~"run_command"){
		if ($debug==1){print "sub event run_command: $run_program\n";}
		system("$run_program &");
	}

	time_spin_box();
	set_gui_start();
	if ($debug==1){print "sub event end\n";}
	return;
}


sub set_progress{
	if ($debug==1){print "sub set_progress start\n";}

	my $pid=getpid();
	if ($debug==1){print "sub set_progress mainpid: $mainpid pid: $pid\n";}

	my $old_fraction;
	my $new_fraction;

	if ($fraction_loop1>0){
		# 10s
		$fraction_loop1=$fraction_loop1-1;
		if ($debug==1){print "sub set_progress fraction_loop1: $fraction_loop1\n";}
		$old_fraction=$progress1->get_fraction;
		$new_fraction=$old_fraction-($fraction_steps*10);
	}
	elsif ($fraction_loop2>0){
		# 1s
		$fraction_loop2=$fraction_loop2-1;
		if ($debug==1){print "sub set_progress fraction_loop2: $fraction_loop2\n";}
		$old_fraction=$progress1->get_fraction;
		$new_fraction=$old_fraction-($fraction_steps);
	}


	if ($new_fraction<0.00000001){
		if ($debug==1){print "sub set_progress set new_fraction 0\n";}
		$new_fraction=0;
	}
	elsif ($new_fraction>1){
		if ($debug==1){print "sub set_progress set new_fraction 1\n";}
		$new_fraction=1;
	}

	if ($debug==1){print "sub set_progress new_fraction: $new_fraction\n";}
	$progress1->set_fraction($new_fraction);

	if ($debug==1){print "sub set_progress end\n";}
	return;
}


sub alarm_start {
	if ($debug==1){print "sub alarm_start start\n";}
	# send SIGUSR2 because this is a child
	system("kill -SIGUSR2 $mainpid");
	if ($debug==1){print "sub alarm_start end\n";}
}


sub get_system_shutdown_cmd{
	if ($debug==1){print "sub get_system_shutdown_cmd start\n";}

	# Fedora release 15 (Lovelock)
	# Fedora release 15 (Lovelock)
	# Fedora release 15 (Lovelock)

	# Fedora release 16 (Verne)
	# Fedora release 16 (Verne)
	# Fedora release 16 (Verne)

	# Fedora release 17 (Beefy Miracle)
	# NAME=Fedora
	# VERSION="17 (Beefy Miracle)"
	# ID=fedora
	# VERSION_ID=17
	# PRETTY_NAME="Fedora 17 (Beefy Miracle)"
	# ANSI_COLOR="0;34"
	# CPE_NAME="cpe:/o:fedoraproject:fedora:17"
	# Fedora release 17 (Beefy Miracle)
	# Fedora release 17 (Beefy Miracle)

	# Fedora release 18 (Spherical Cow)
	# NAME=Fedora
	# VERSION="18 (Spherical Cow)"
	# ID=fedora
	# VERSION_ID=18
	# PRETTY_NAME="Fedora 18 (Spherical Cow)"
	# ANSI_COLOR="0;34"
	# CPE_NAME="cpe:/o:fedoraproject:fedora:18"
	# Fedora release 18 (Spherical Cow)
	# Fedora release 18 (Spherical Cow)

	# DISTRIB_ID=Ubuntu
	# DISTRIB_RELEASE=11.10
	# DISTRIB_CODENAME=oneiric
	# DISTRIB_DESCRIPTION="Ubuntu oneiric (development branch)"

	# DISTRIB_ID=Ubuntu
	# DISTRIB_RELEASE=12.04
	# DISTRIB_CODENAME=precise
	# DISTRIB_DESCRIPTION="Ubuntu precise (development branch)"

	# DISTRIB_ID=Ubuntu
	# DISTRIB_RELEASE=12.10
	# DISTRIB_CODENAME=quantal
	# DISTRIB_DESCRIPTION="Ubuntu 12.10"
	# NAME="Ubuntu"
	# VERSION="12.10, Quantal Quetzal"
	# ID=ubuntu
	# ID_LIKE=debian
	# PRETTY_NAME="Ubuntu quantal (12.10)"
	# VERSION_ID="12.10"

	my $distributor;
	my $release;

	my @check = `cat /etc/*-release`;

	foreach my $check (@check){
		if ($check=~/(.*) release (\d+)/){
			$distributor = $1;
			$release = $2;
		}
		if ($check=~/DISTRIB_ID=(.*)/){
			$distributor = $1;
		}
		if  ($check=~/DISTRIB_RELEASE=(.*)/){
			$release = $1;
		}
	}

	if ($distributor=~/Fedora/){
		$poweroff_cmd='systemctl poweroff';
	}
	elsif ($distributor=~/Ubuntu/){
		$poweroff_cmd='dbus-send --session --type=method_call --print-reply --dest=org.gnome.SessionManager /org/gnome/SessionManager org.gnome.SessionManager.RequestShutdown';
	}
	else{
		$poweroff_cmd='sudo shutdown -h now';
	}

	if ($debug==1){print "sub get_system_shutdown_cmd end\n";}
	return;
}


sub refresh_localtime_in_seconds{
	if ($debug==1){print "sub refresh_localtime_in_seconds start\n";}

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$localtime_in_seconds=($hour*60*60)+($min*60)+$sec;
	if ($debug==1){print "sub refresh_localtime_in_seconds localtime_in_seconds: $localtime_in_seconds\n";}

	if ($debug==1){print "sub refresh_localtime_in_seconds end\n";}
	return;
}


sub entry_time_changed {
	if ($debug==1){print "sub entry_time_changed start\n";}
	my $erg=read_entry_time_box();
	if ($erg){
		refresh_duration_in_seconds();
		set_time_to_event();
	}
	if ($debug==1){print "sub entry_time_changed end\n";}
	return;
}


sub set_time_to_event{
	if ($debug==1){print "sub set_time_to_event start\n";}

	refresh_duration_in_seconds();
	my $calc_time=$duration_in_seconds;

	my $hour=$calc_time/60/60;
	$hour=int($hour);
	if ($hour>0){
		$calc_time=$calc_time-($hour*60*60);
	}
	my $min=$calc_time/60;
	$min=int($min);
	if ($min>0){
		$calc_time=$calc_time-($min*60);
	}
	my $sec=$calc_time;

	if ($hour<=9){
		$hour="0$hour";
	}
	if ($min<=9){
		$min="0$min";
	}
	if ($sec<=9){
		$sec="0$sec";
	}

	if ($enable_glib_timeout == 1){
		$progress1->set_text("$hour:$min:$sec");
	}

	return $enable_glib_timeout;
}


sub refresh_duration_in_seconds{
	if ($debug==1){print "sub refresh_duration_in_seconds start\n";}

	refresh_localtime_in_seconds();

	if ($endtime_in_seconds<$localtime_in_seconds){
		$endtime_in_seconds=1440*60+$endtime_in_seconds;
	}
	if ($debug==1){print "sub refresh_duration_in_seconds endtime_in_seconds: $endtime_in_seconds\n";}

	$duration_in_seconds=$endtime_in_seconds-$localtime_in_seconds;
	if ($debug==1){print "sub refresh_duration_in_seconds duration_in_seconds: $duration_in_seconds\n";}

	if ($debug==1){print "sub refresh_duration_in_seconds end\n";}
	return;
}


sub refresh_entry_time {
	if ($debug==1){print "sub refresh_entry_time start\n";}

	if ($debug==1){print "sub refresh_entry_time entrytime_in_seconds: $entrytime_in_seconds\n";}

	my $hour=int($entrytime_in_seconds/60/60);
	my $sec=$entrytime_in_seconds-($hour*60*60);
	my $min=int($sec/60);

	if ($hour<=9){
		$hour="0$hour";
	}
	elsif ($hour>=24){
		$hour=$hour-24;
	}
	if ($min<=9){
		$min="0$min";
	}

	if ($debug==1){print "sub refresh_entry_time hour:$hour min $min\n";}

	if ($entry_time){
		$entry_time->set_text("$hour:$min");
		$time_spin_box_value="$hour:$min";
	}
	if ($debug==1){print "sub refresh_entry_time end\n";}
	return;
}


sub read_entry_time_box {
	if ($debug==1){print "sub read_entry_time_box start\n";}

	my $e_time = $entry_time->get_text();
	if ($debug==1){print "sub read_entry_time_box e_time: $e_time\n";}


	my @time=split(/:/,$e_time);

	my $hour=$time[0];
	my $min=$time[1];

	if ((($hour>=0) and ($hour<24)) and (($min>=0) and ($min<60))){
		$endtime_in_seconds=($hour*60*60)+($min*60);
		if ($debug==1){print "sub read_entry_time_box return 1 end\n";}
		return 1;
	}
	else{
		if ($debug==1){print "sub read_entry_time_box return 0 end\n";}
		return 0;
	}

}


sub set_entry_command_box{
	if ($debug==1){print "sub set_entry_command_box start\n";}

	if ($debug==1){print "sub set_entry_command_box todo_value: $event_value\n";}

	if ($event_value=~"run_command"){
		$entry_command->set_sensitive(1);
	}
	elsif ($event_value=~"alarm"){
		$entry_command->set_sensitive(0);
	}
	elsif ($event_value=~"shutdown"){
		$entry_command->set_sensitive(0);
	}
	if ($debug==1){print "sub set_entry_command_box end\n";}
	return;
}


sub time_spin_box {
	if ($debug==1){print "sub time_spin_box start\n";}

	refresh_localtime_in_seconds();

	my $add_seconds=($time_spin->get_value())*60;
	if ($debug==1){print "sub time_spin_box add_seconds: $add_seconds\n";}

	$entrytime_in_seconds=$localtime_in_seconds+$add_seconds;
	if ($debug==1){print "sub time_spin_box entrytime_in_seconds: $entrytime_in_seconds\n";}

	refresh_entry_time();
	read_entry_time_box();		# ->endtime_in_s

	refresh_duration_in_seconds();
	set_time_to_event();

	if ($debug==1){print "sub time_spin_box end\n";}
	return;
}


sub cb_changed {
	my ($widget, $cb) = @_;

	if ($debug==1){print "sub cb_changed start\n";}
	if ($debug==1){print "sub cb_changed cb: $cb\n";}

	$event_value = $combobox1->get_active_text();
	if ($debug==1){print "sub cb_changed todo: $event_value\n";}

	set_entry_command_box();

	if ($debug==1){print "sub cb_changed end\n";}
	return;
}


sub rb_toggled {
	my ($widget, $rb) = @_;

	if ($debug==1){print "sub rb_toggled start\n";}
	if ($debug==1){print "rb: $rb\n";}

	$time_spin->set_value($rb);
	$time_spin->update;

	if ($debug==1){print "sub rb_toggled end\n";}
	return;
}


sub set_gui_busy  {
	if ($debug==1){print "sub set_gui_busy start\n";}
	$startbutton->set_sensitive(0);
	$sleep_box_15->set_sensitive(0);
	$sleep_box_30->set_sensitive(0);
	$sleep_box_45->set_sensitive(0);
	$sleep_box_60->set_sensitive(0);
	$sleep_box_75->set_sensitive(0);
	$sleep_box_90->set_sensitive(0);
	$sleep_box_105->set_sensitive(0);
	$sleep_box_120->set_sensitive(0);
	$sleep_box_135->set_sensitive(0);
	$sleep_box_150->set_sensitive(0);
	$sleep_box_165->set_sensitive(0);
	$sleep_box_180->set_sensitive(0);
	$time_spin->set_sensitive(0);
	$entry_command->set_sensitive(0);
	$combobox1->set_sensitive(0);
	$stopbutton->set_sensitive(1);
	$progress1->set_fraction(1);
	$entry_time->set_editable(0);
	$enable_glib_timeout=0;
	$progress1->set_text("");
	if ($debug==1){print "sub set_gui_busy start\n";}
	return;
}


sub set_gui_start {
	if ($debug==1){print "sub set_gui_start start\n";}
	$startbutton->set_sensitive(1);
	$sleep_box_15->set_sensitive(1);
	$sleep_box_30->set_sensitive(1);
	$sleep_box_45->set_sensitive(1);
	$sleep_box_60->set_sensitive(1);
	$sleep_box_75->set_sensitive(1);
	$sleep_box_90->set_sensitive(1);
	$sleep_box_105->set_sensitive(1);
	$sleep_box_120->set_sensitive(1);
	$sleep_box_135->set_sensitive(1);
	$sleep_box_150->set_sensitive(1);
	$sleep_box_165->set_sensitive(1);
	$sleep_box_180->set_sensitive(1);
	$time_spin->set_sensitive(1);
	$combobox1->set_sensitive(1);
	$stopbutton->set_sensitive(0);
	$entry_time->set_editable(1);

	$enable_glib_timeout=1;
	Glib::Timeout->add (1000, \&set_time_to_event, undef, 0);
	$progress1->set_fraction(0);
	$progress1->set_show_text(TRUE);

	$entry_command->set_text($run_program);
	set_entry_command_box();
	if ($debug==1){print "sub set_gui_start end\n";}
	return;
}


sub stop_button {
	if ($debug==1){print "sub stop_button start\n";}
	killall_childs();
	set_gui_start();
	set_time_to_event();
	if ($debug==1){print "sub stop_button end\n";}
	return;
}


sub read_xml_file {
	if ($debug==1){print "sub read_xml_file start\n";}

	if (!(-d $directory_config)){
		if ($debug==1){print "sub read_xml_file create directory directory_config: $directory_config\n";}
		system("mkdir -p $directory_config");
	}

	if (!-f "$directory_config/config"){
		system("touch $directory_config/config");
		create_xml_file();
	}


	my $write_a_new_xml=0;


	my $xs = new XML::Simple(KeyAttr => { set=>'name' }, ForceArray => [ 'set','version','bin','cmd','file','program','value' ], suppressempty => '');

	my $xml = eval {
		$xs->XMLin("$directory_config/config");
	};
	if($@){
		create_xml_file();
		$xml = $xs->XMLin("$directory_config/config");
	}


	$config_version=$xml->{set}->{config}->{version}->[0];

	my $compare_a=int($version * 10) /10;
	my $compare_b=int($config_version * 10) /10;
	if ($debug==1){print "sub read_xml_file compare_a: $compare_a compare_b: $compare_b\n";}


	if ((!$config_version) or ($compare_a>$compare_b) or ($replace_config==1)){
		# create a new xml file
		system("rm -I $directory_config/config");
		system("touch $directory_config/config");
		create_xml_file();
		$xml = $xs->XMLin("$directory_config/config");
		$config_version=$xml->{set}->{config}->{version}->[0];
	}


	$directory_bin=$xml->{set}->{directory}->{bin}->[0];
	if ($debug==1){print "sub read_xml_file directory_bin: $directory_bin\n";}

	$poweroff_cmd=$xml->{set}->{poweroff}->{cmd}->[0];
	if ($debug==1){print "sub read_xml_file poweroff_cmd: $poweroff_cmd\n";}

	$icon_file=$xml->{set}->{icon}->{file}->[0];
	if ($debug==1){print "sub read_xml_file icon_file: $icon_file\n";}

	$sound_file=$xml->{set}->{sound}->{file}->[0];
	if ($debug==1){print "sub read_xml_file sound_file: $sound_file\n";}

	$time_spin_box_value=$xml->{set}->{time_spin_box}->{value}->[0];
	if ($debug==1){print "sub read_xml_file set_time_spin_box: $time_spin_box_value\n";}

	$event_value=$xml->{set}->{todo}->{value}->[0];
	if ($debug==1){print "sub read_xml_file todo: $event_value\n";}

	$run_program=$xml->{set}->{run}->{program}->[0];
	if ($debug==1){print "sub read_xml_file run_program: $run_program\n";}

	return;
}


sub create_xml_file{

	if ($debug==1){print "sub create_xml_file start\n";}

	system("rm -I $directory_config/config");
	system("touch $directory_config/config");

	my $xml_default = {
		set => [
			{	name     => "config",
				version  => [ $version ],
			},
			{	name     => "directory",
				bin      => [ $directory_bin ],
			},
			{	name     => "poweroff",
				cmd      => [ $poweroff_cmd ],
			},
			{	name     => "icon",
				file     => [ "timerx.png" ],
			},
			{	name     => "sound",
				file     => [ "alert.wav" ],
			},
			{	name     => "run",
				program  => [ $run_program ],
			},
			{	name     => "time_spin_box",
				value    => [ "00:00" ],
			},
			{	name     => "todo",
				value    => [ "alarm" ],
			},
		]
	};

	print XMLout($xml_default, RootName => "config",  KeyAttr => { set => 'name' });

	if (open(LOG, "> $directory_config/config")){
		print LOG XMLout($xml_default, RootName => "config",  KeyAttr => { set => 'name' });
		close(LOG);
	}
	else{
		die "Error sub write_xml_file cannot open file: $directory_config/config\n";
	}
	return;
}


sub write_xml_file{
	if ($debug==1){print "sub write_xml_file start\n";}

	$xml->{set}->{config}->{version}->[0]=$config_version;
	$xml->{set}->{directory}->{bin}->[0]=$directory_bin;
	$xml->{set}->{poweroff}->{cmd}->[0]=$poweroff_cmd;
	$xml->{set}->{icon}->{file}->[0]=$icon_file;
	$xml->{set}->{sound}->{file}->[0]=$sound_file;
	$xml->{set}->{run}->{program}->[0]=$run_program;
	$xml->{set}->{time_spin_box}->{value}->[0]=$time_spin_box_value;
	$xml->{set}->{todo}->{value}->[0]=$event_value;

	print XMLout($xml, RootName => "config",  KeyAttr => { set => 'name' });

	if (open(CONFIG, "> $directory_config/config")){
		print CONFIG XMLout($xml, RootName => "config",  KeyAttr => { set => 'name' });
		close(CONFIG);
	}
	else{
		die "Error sub write_xml_file cannot open file: $directory_config/config\n";
	}

	if ($debug==1){print "sub write_xml_file end\n";}
	return;
}


sub start_button{
	if ($debug==1){print "sub start_button start\n";}

	$run_program=$entry_command->get_text();
	my $erg=read_entry_time_box();
	write_xml_file();


	if ($erg){

		set_gui_busy();
		refresh_duration_in_seconds();

		if ($duration_in_seconds<20){
			$fraction_loop1=0;
			$fraction_loop2=$duration_in_seconds;
			if ($debug==1){print "sub start_button fraction_loop1: $fraction_loop1\n";}
			if ($debug==1){print "sub start_button fraction_loop2: $fraction_loop2\n";}
		}
		if ($duration_in_seconds>=20){
			$fraction_loop2=($duration_in_seconds%10);
			$fraction_loop2=$fraction_loop2+10;
			$fraction_loop1=($duration_in_seconds-$fraction_loop2)/10;
			if ($debug==1){print "sub start_button fraction_loop1: $fraction_loop1\n";}
			if ($debug==1){print "sub start_button fraction_loop2: $fraction_loop2\n";}
		}



		# Illegal division by zero
		if ($duration_in_seconds>0){

			$fraction_steps=1/$duration_in_seconds;
			if ($debug==1){print "sub start_button fraction_steps: $fraction_steps\n";}

			my $kidpid = fork();
			if ($kidpid!=0){
				push (@child_pids,$kidpid);
			}

			if (not defined $kidpid){
				die "cannot fork: !";
			}
			elsif ($kidpid==0){
				start_fork();
				exit(0);
			}
		}
	}
	else{
		if ($debug==1){print "sub start_button erg: 0\n";}
	}

	return;
}


sub start_fork{
	if ($debug==1){print "sub start_fork start\n";}

	alarm($duration_in_seconds);
	if ($debug==1){print "sub start_fork duration_in_seconds: $duration_in_seconds\n";}


	while ($fraction_loop1>0){
		sleep 10;
		if ($debug==1){print "sub start_fork fraction_loop1: $fraction_loop1\n";}
		$fraction_loop1=$fraction_loop1-1;
		system("kill -SIGUSR1 $mainpid");
	}

	while ($fraction_loop2>0){
		sleep 1;
		$fraction_loop2=$fraction_loop2-1;
		if ($debug==1){print "sub start_fork fraction_loop2: $fraction_loop2\n";}
		system("kill -SIGUSR1 $mainpid");
	}

	if ($debug==1){print "sub start_fork end\n";}
	exit;
}


sub killall_childs {

	foreach my $child_pid (@child_pids){
		my $exists = kill 0, $child_pid;
		if ($exists){
			if ($debug==1){print "Kill child process child_pid: $child_pid\n";}
			system("kill $child_pid");
		}
	}
}


sub quit {
	if ($debug==1){print "sub quit\n";}
	killall_childs();
	Gtk3->main_quit();
	if ($debug==1){print "sub quit: bye\n";}
	exit;
}

__END__
