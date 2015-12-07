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

Install Dependencies (Ubuntu + Debian):<br />
apt-get install perl alsa-utils libgtk3-perl libxml-simple-perl<br />

Install Dependencies (Fedora):<br />
yum install perl alsa-utils perl-Gtk3 perl-XML-Simple<br />

Install TimerX:<br />
git clone https://github.com/kalibari/timerx.git<br />
mv timerx /opt/<br />
chmod 0770 /opt/timerx/timerx.pl<br />
cp /opt/timerx/timerx.desktop /usr/share/applications/<br />
desktop-file-install /usr/share/applications/timerx.desktop<br />


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
