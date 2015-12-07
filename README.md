TimerX
======
TimerX is a simple countdown / shutdown timer written in Perl. The graphical user interface uses Gtk3. TimerX is a free software under the GPL license.


Version
======
Current Version is 0.40


Requirements
======
- perl
- perl-Gtk3
- perl-XML-Simple
- alsa-utils


Installation
======

Install Dependencies
Ubuntu + Debian:
apt-get install perl alsa-utils libgtk3-perl libxml-simple-perl

Fedora:
yum install perl alsa-utils perl-Gtk3 perl-XML-Simple

Install TimerX:
git clone https://github.com/kalibari/timerx.git
mv timerx /opt/
chmod 0770 /opt/timerx/timerx.pl
cp /opt/timerx/timerx.desktop /usr/share/applications/
desktop-file-install /usr/share/applications/timerx.desktop


Description
======
TimerX provides three main functions:
- shutdown
- alarm
- run a command

Keep in mind, that the shutdown will execute immediatly without user confirmation.


Tested on:
- Fedora 18
- Ubuntu 12.10
- Debian 8
