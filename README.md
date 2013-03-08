TimerX V0.3
======
TimerX is a simple countdown / shutdown timer written in Perl. The graphical user interface uses Gtk3. TimerX is a free software under the GPL license. 


Requirements
======
- perl
- perl-Gtk3
- perl-XML-Simple
- alsa-utils


Installation
======
git clone https://github.com/kalibari/timerx.git
cd timerx
./timerx.pl

Description
======
TimerX provides three main functions:
- shutdown
- alarm
- run a command

Keep in mind, that the shutdown will execute immediatly without user confirmation.


Tested on:
- Fedora 18
